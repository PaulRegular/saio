root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- Sys.getenv("SAIO_DATABASE_DIR", "database")
if (!grepl("^(?:[A-Za-z]:|/)", database)) database <- file.path(root, database)
database <- normalizePath(database, winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
options(scipen = 999)

stock_id <- "ices_sol_27_8ab"
assessment_id <- "ices_sol_27_8ab_2026"
candidate_id <- "ICES:sol.27.8ab"
report_url <- "https://doi.org/10.17895/ices.pub.32790321.v1"
framework_url <- "https://doi.org/10.17895/ices.pub.25471987.v1"
repository_url <- paste0(
  "https://github.com/ices-advice/2026_sol.27.8ab/tree/",
  "e6b6c484f6c50e1199097682ca6b451f8232e235/2026_sol.27.8ab_assessment"
)
cache <- file.path(root, "source_cache", stock_id, assessment_id)
manifest_path <- file.path(root, "data-raw/provenance", assessment_id, "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
manifest$file <- gsub("\\\\", "/", manifest$file)

sha256 <- function(path) {
  stream <- file(path, "rb")
  on.exit(close(stream))
  tolower(unclass(as.character(openssl::sha256(stream))))
}
source_paths <- file.path(cache, manifest$file)
if (!all(c("file", "sha256", "bytes") %in% names(manifest)) ||
  any(!file.exists(source_paths)) ||
  any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
  !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1)))) ||
  !"source_material/wgbie_2026_sole_north.pdf" %in% manifest$file) {
  stop("Cached ICES sole sources do not match the reviewed provenance manifest.", call. = FALSE)
}

pdf_path <- file.path(cache, "source_material", "wgbie_2026_sole_north.pdf")
pdf_pages <- pdftools::pdf_text(pdf_path)
document <- paste(pdf_pages, collapse = "\n")

section <- function(start, end = NULL) {
  lines <- trimws(unlist(strsplit(document, "\n", fixed = TRUE)))
  table_id <- sub("^Table ", "", start)
  table_id <- sub("[:.]$", "", table_id)
  headings <- grep("^Table 7\\.[0-9]+[:.]", lines)
  start_heading <- headings[grepl(paste0("^Table ", table_id, "[:.]"), lines[headings])]
  if (length(start_heading) != 1L) stop("Could not identify one table heading: ", start, call. = FALSE)
  next_heading <- headings[headings > start_heading][1L]
  if (is.na(next_heading)) next_heading <- length(lines) + 1L
  paste(lines[seq.int(start_heading + 1L, next_heading - 1L)], collapse = "\n")
}

number <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  x <- sub("\\*$", "", x)
  value <- suppressWarnings(as.numeric(x))
  if (!is.finite(value)) stop("Non-numeric source table value: ", x, call. = FALSE)
  value
}

parse_year_table <- function(text, years, n_values, name) {
  lines <- trimws(unlist(strsplit(text, "\n", fixed = TRUE)))
  rows <- list()
  current_year <- NA_integer_
  current_values <- character()
  finish <- function() {
    if (is.na(current_year) || !current_year %in% years) return(NULL)
    if (length(current_values) != n_values) {
      stop(name, " year ", current_year, " has ", length(current_values),
        " values; expected ", n_values, ".", call. = FALSE)
    }
    values <- vapply(current_values, number, numeric(1L))
    row <- as.data.frame(as.list(c(year = current_year, values)), check.names = FALSE)
    names(row) <- c("year", paste0("value", seq_along(values)))
    row
  }
  for (line in lines) {
    fields <- strsplit(line, "\\s+")[[1L]]
    if (!length(fields)) next
    starts_year <- grepl("^(19|20)[0-9]{2}$", fields[[1L]])
    if (starts_year) {
      completed <- finish()
      if (!is.null(completed)) rows[[length(rows) + 1L]] <- completed
      current_year <- as.integer(fields[[1L]])
      current_values <- fields[-1L]
      if (!current_year %in% years) {
        current_year <- NA_integer_
        current_values <- character()
      }
    } else if (!is.na(current_year) && length(current_values) < n_values &&
      grepl("^[0-9,.]+\\*?$", fields[[1L]])) {
      current_values <- c(current_values, fields[grepl("^[0-9,.]+\\*?$", fields)])
    }
  }
  completed <- finish()
  if (!is.null(completed)) rows[[length(rows) + 1L]] <- completed
  out <- if (length(rows)) do.call(rbind, rows) else data.frame()
  if (nrow(out) != length(years) || anyDuplicated(out$year) ||
    !identical(as.integer(out$year), as.integer(years))) {
    stop(name, " does not contain exactly the expected years.", call. = FALSE)
  }
  names(out) <- c("year", paste0("value", seq_len(n_values)))
  out
}

parse_fixed_values <- function(text, row_label, n_values) {
  lines <- trimws(unlist(strsplit(text, "\n", fixed = TRUE)))
  line <- lines[startsWith(lines, row_label)]
  if (length(line) != 1L) stop("Could not identify one ", row_label, " row.", call. = FALSE)
  fields <- strsplit(line, "\\s+")[[1L]][-1L]
  if (length(fields) != n_values) stop("Unexpected values in ", row_label, " row.", call. = FALSE)
  vapply(fields, number, numeric(1L))
}

maturity <- parse_fixed_values(section("Table 7.2:", "Table 7.3:"), "Proportion", 7L)
catch_numbers <- parse_year_table(section("Table 7.4.", "Table 7.5."), 1984:2025, 7L, "Table 7.4 catch numbers")
catch_weights <- parse_year_table(section("Table 7.5.", "Table 7.6."), 1984:2025, 7L, "Table 7.5 catch weights")
stock_weights <- parse_year_table(section("Table 7.6.", "Table 7.7"), 1984:2025, 7L, "Table 7.6 stock weights")
bts_indices <- parse_year_table(section("Table 7.7:", "Table 7.8:"), 2007:2025, 6L, "Table 7.7 BTS indices")
trawler_index <- parse_year_table(section("Table 7.8:", "Table 7.9."), 2010:2025, 1L, "Table 7.8 trawler index")
summary <- parse_year_table(section("Table 7.11.", "Table 7.12."), 1984:2025, 11L, "Table 7.11 assessment summary")
F_at_age <- parse_year_table(section("Table 7.14.", "Table 7.15."), 1984:2025, 7L, "Table 7.14 fishing mortality")
N_at_age <- parse_year_table(section("Table 7.15."), 1984:2025, 7L, "Table 7.15 stock numbers")

stopifnot(
  identical(unname(maturity), c(.32, .83, .97, 1, 1, 1, 1)),
  catch_numbers$value1[1L] == 6522,
  catch_numbers$value7[42L] == 1413,
  catch_weights$value1[1L] == .130,
  stock_weights$value7[42L] == .468,
  bts_indices$value1[1L] == 10164744,
  bts_indices$value6[19L] == 431180.53,
  trawler_index$value1[1L] == 28.44413,
  trawler_index$value1[16L] == 17.55664,
  summary$value2[1L] == 26919,
  summary$value5[42L] == 9917,
  summary$value10[42L] == .31,
  F_at_age$value1[1L] == .304,
  F_at_age$value7[42L] == .296,
  N_at_age$value1[1L] == 26919,
  N_at_age$value7[42L] == 5278
)
cat("2025 terminal values: summary recruitment", summary$value2[42L],
  "SSB", summary$value5[42L], "Fbar", summary$value10[42L],
  "F age 8", F_at_age$value7[42L], "N age 8", N_at_age$value7[42L], "\n")

make_rows <- function(table, n, ...) {
  header <- readLines(file.path(database, paste0(table, ".csv")), n = 1L, warn = FALSE)
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  values <- list(...)
  unknown <- setdiff(names(values), columns)
  if (length(unknown)) stop("Unknown ", table, " column: ", paste(unknown, collapse = ", "), call. = FALSE)
  out <- as.data.frame(lapply(columns, function(x) rep(NA_character_, n)), check.names = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns && !"assessment_id" %in% names(values))
    out$assessment_id <- assessment_id
  for (name in names(values)) out[[name]] <- rep_len(as.character(values[[name]]), n)
  out
}

age_rows <- function(surface, ages) {
  grid <- expand.grid(age = ages, year = surface$year, KEEP.OUT.ATTRS = FALSE)
  values <- as.vector(t(as.matrix(surface[-1L])))
  if (length(values) != nrow(grid)) stop("Age surface dimensions do not align.", call. = FALSE)
  list(grid = grid, value = values)
}

input_age <- function(surface, ages, type, measure, basis, unit, notes, source_reference) {
  x <- age_rows(surface, ages)
  make_rows("inputs", nrow(x$grid), type = type, measure = measure, basis = basis,
    fleet = if (type == "catch") "Total catch" else "", survey = "", sex = "",
    region = "Divisions 8.a-b", season = "", year = x$grid$year,
    year_basis = "calendar_year", age = x$grid$age, value = x$value, unit = unit,
    source_type = "official_table", source_reference = source_reference,
    transformation = "", notes = notes)
}

output_age <- function(surface, ages, measure, type, unit, notes, source_reference) {
  x <- age_rows(surface, ages)
  make_rows("outputs", nrow(x$grid), type = type, measure = measure,
    region = "Divisions 8.a-b", year = x$grid$year, age = x$grid$age,
    age_group = ifelse(x$grid$age == max(ages), "8+", ""), value = x$value,
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes)
}

catch_input <- input_age(catch_numbers, 2:8, "catch", "numbers_at_age", "numbers",
  "report table units (multiplier not stated)",
  "Table 7.4 catch numbers at ages 2-8; age 8 is the model plus group. Values are transcribed on the reported scale because the table does not state the multiplier. Do not interpret them as fish or thousands of fish until that scale is verified.",
  paste0(report_url, "; Table 7.4, pp. 341-342"))
catch_weight_input <- input_age(catch_weights, 2:8, "catch_weight", "weight_at_age", "kg_per_fish",
  "kg per fish", "Table 7.5 catch weight-at-age in kg; age 8 is the model plus group.",
  paste0(report_url, "; Table 7.5, pp. 342-343"))
stock_weight_input <- input_age(stock_weights, 2:8, "weight", "weight_at_age", "kg_per_fish",
  "kg per fish", "Table 7.6 stock weight-at-age in kg; age 8 is the model plus group.",
  paste0(report_url, "; Table 7.6, pp. 343-345"))

bts_grid <- expand.grid(age = 2:7, year = 2007:2025, KEEP.OUT.ATTRS = FALSE)
bts_input <- make_rows("inputs", nrow(bts_grid), type = "index", measure = "numbers_at_age",
  basis = "index_scale", survey = "FR-BTS-VIII (B1706)", sex = "", region = "Divisions 8.a-b",
  season = "November-December", year = bts_grid$year, year_basis = "calendar_year",
  age = bts_grid$age, value = as.vector(t(as.matrix(bts_indices[-1L]))),
  unit = "standardized index units (table scale; physical unit not stated)",
  sampling_time = NA_real_, source_type = "official_table",
  source_reference = paste0(report_url, "; Table 7.7, p. 346"), transformation = "",
  notes = "Standardized French BTS-VIII index by age, ages 2-7, 2007-2025. The report does not state a physical unit. The pinned 2026 repository code identifies the survey timing as 11/12 to 1 of the year; sampling_time is left blank because this interval is not a single fraction.")
trawler_input <- make_rows("inputs", 16L, type = "index", measure = "relative_biomass_index",
  basis = "index_scale", survey = "FR-TRAWLER", sex = "", region = "Divisions 8.a-b",
  season = "February", year = 2010:2025, year_basis = "calendar_year", age = NA_integer_,
  value = trawler_index$value1, unit = "standardized fishable-stock-biomass index units (table scale)",
  sampling_time = NA_real_, source_type = "official_table",
  source_reference = paste0(report_url, "; Table 7.8, p. 347"), transformation = "",
  notes = "Standardized French trawler fishable-stock-biomass index. The table does not give a physical unit. The pinned 2026 repository code identifies timing as 0.1 to 2/12 of the year; sampling_time is left blank because this interval is not a single fraction.")

maturity_input <- make_rows("inputs", 7L, type = "maturity", measure = "maturity_at_age",
  basis = "proportion", region = "Divisions 8.a-b", age = 2:8, value = maturity,
  unit = "proportion", source_type = "official_table",
  source_reference = paste0(report_url, "; Table 7.2, p. 340"),
  notes = "Fixed maturity-at-age ogive from Table 7.2; age 8 is the model plus group.")
inputs_new <- rbind(catch_input, catch_weight_input, stock_weight_input,
  bts_input, trawler_input, maturity_input)

summary_rows <- function(estimate, lower, upper, type, measure, unit,
  age = NA_integer_, age_group = "", note) {
  make_rows("outputs", 42L, type = type, measure = measure, region = "Divisions 8.a-b",
    year = summary$year, age = age, age_group = age_group,
    value = summary[[estimate]], lwr = summary[[lower]], upr = summary[[upper]],
    unit = unit, source_type = "official_table",
    source_reference = paste0(report_url, "; Table 7.11, pp. 351-352"), notes = note)
}
summary_outputs <- rbind(
  summary_rows("value2", "value1", "value3", "recruitment", "recruitment", "thousand fish", age = 0L,
    age_group = "age 0", note = "Age-0 recruitment. Table 7.11 Low/High values are 90% confidence limits. The 2025 point estimate is identified as a median re-sampled over 2021-2024."),
  summary_rows("value5", "value4", "value6", "biomass", "SSB", "tonnes",
    note = "Spawning-stock biomass. Table 7.11 Low/High values are 90% confidence limits."),
  summary_rows("value10", "value9", "value11", "mortality", "Fbar", "per year", age_group = "3-7",
    note = "Mean fishing mortality for ages 3-7. Table 7.11 Low/High values are 90% confidence limits.")
)
F_output <- output_age(F_at_age, 2:8, "fishing_mortality_at_age", "mortality", "per year",
  "Table 7.14 estimated fishing mortality at ages 2-8; age 8 is the model plus group. No age-specific uncertainty is tabulated.",
  paste0(report_url, "; Table 7.14, pp. 353-354"))
N_output <- output_age(N_at_age, 2:8, "numbers_at_age", "population", "thousand fish",
  "Table 7.15 estimated stock numbers at age at the start of year. The source scale is 10^-3 fish; age 8 is the model plus group. No age-specific uncertainty is tabulated.",
  paste0(report_url, "; Table 7.15, pp. 355-356"))
outputs_new <- rbind(F_output, N_output, summary_outputs)

assumptions_new <- make_rows("assumptions", 13L,
  assessment_id = assessment_id,
  component = c("model", "population", "population", "fishing_mortality", "M", "M", "catch", "survey", "survey", "survey", "survey", "data", "uncertainty"),
  survey = c("", "", "", "", "", "", "", "FR-BTS-VIII (B1706)", "FR-TRAWLER", "FR-BTS-VIII (B1706)", "FR-TRAWLER", "", ""),
  region = "Divisions 8.a-b",
  setting = c("assessment model", "model ages", "plus group", "Fbar ages", "M vector in Table 7.3", "M vector in section 7.4.2", "catch-at-age scale", "index scale", "index scale", "sampling interval", "sampling interval", "terminal data year", "summary interval level"),
  value = c("SAM", "2-8+", "8+", "3-7", "ages 2-8: 0.13, 0.12, 0.11, 0.10, 0.10, 0.10, 0.09", "ages 2-8: 0.13, 0.12, 0.11, 0.11, 0.10, 0.09, 0.09", "multiplier not stated", "standardized age-specific index; physical unit not stated", "standardized fishable-stock-biomass index; physical unit not stated", "11/12 to 1 of the year", "0.1 to 2/12 of the year", "1984-2025 tables; section 7.4.2 states final data year 2026", "90% confidence intervals in Table 7.11"),
  source_reference = c(repository_url, paste0(report_url, "; section 7.4.2"), paste0(repository_url, "; data.R and model.R"), paste0(report_url, "; section 7.4.2"), paste0(report_url, "; Table 7.3"), paste0(report_url, "; section 7.4.2"), paste0(report_url, "; Table 7.4"), paste0(report_url, "; Table 7.7"), paste0(report_url, "; Table 7.8"), paste0(repository_url, "; data.R"), paste0(repository_url, "; data.R"), paste0(report_url, "; section 7.4.2 and Tables 7.4-7.15"), paste0(report_url, "; Table 7.11")),
  notes = c("The 2026 WGBIE report identifies the applied SAM assessment; native numerical input objects were not present in the public repository archive.", "The assessment code specifies model ages 2-8 with the terminal age grouped.", "The code identifies age 8 as a plus group.", "The assessment summary uses F ages 3-7.", "This vector conflicts with the natural-mortality vector printed in section 7.4.2; the production input cannot be identified from available files.", "This vector conflicts with Table 7.3; the production input cannot be identified from available files.", "The report does not identify a number multiplier. Values are retained exactly as printed and no scale conversion is made.", "Table 7.7 does not state physical units; the index remains on the reported standardized scale.", "Table 7.8 does not state physical units; the index remains on the reported standardized scale.", "The source code gives an interval, so no single sampling_time value is imputed.", "The source code gives an interval, so no single sampling_time value is imputed.", "Assessment tables and outputs end in 2025 but model settings state 2026. The missing run object prevents resolution.", "No SE is reported for the age-specific F and N surfaces; their uncertainty is not inferred."))

row_count <- c(inputs = nrow(inputs_new), outputs = nrow(outputs_new), assumptions = nrow(assumptions_new))
if (row_count[["inputs"]] != 1019L || row_count[["outputs"]] != 714L || row_count[["assumptions"]] != 13L) {
  stop("Unexpected ICES sole source row counts.", call. = FALSE)
}

append_csv <- function(x, path) {
  write.table(x, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double")
}
file_has_assessment <- function(path) {
  pattern <- paste0('^"', assessment_id, '",')
  status <- system2("rg", c("--quiet", "--regexp", pattern, shQuote(path)),
    stdout = FALSE, stderr = FALSE)
  if (identical(as.integer(status), 0L)) return(TRUE)
  if (identical(as.integer(status), 1L)) return(FALSE)
  stop("Could not check existing rows in ", path, ".", call. = FALSE)
}

if (write_mode) {
  stocks_path <- file.path(database, "stocks.csv")
  assessments_path <- file.path(database, "assessments.csv")
  assumptions_path <- file.path(database, "assumptions.csv")
  inputs_path <- file.path(database, "inputs.csv")
  outputs_path <- file.path(database, "outputs.csv")
  stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, check.names = FALSE)
  assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, check.names = FALSE)
  if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id) ||
    file_has_assessment(assumptions_path) || file_has_assessment(inputs_path) || file_has_assessment(outputs_path)) {
    stop("The ICES sole stock or assessment is already present; refusing to append it twice.", call. = FALSE)
  }
  candidate_path <- file.path(root, "database/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$screening_status[ci] != "screened" ||
    candidates$import_status[ci] != "not_started") {
    stop("Expected one screened, not-yet-imported ICES sole candidate.", call. = FALSE)
  }
  append_csv(make_rows("stocks", 1L, stock_id = stock_id, charbonneau_id = NA_character_,
    authority = "ICES", authority_stock_id = "sol.27.8ab", scientific_name = "Solea solea",
    common_name = "Sole", area = "Divisions 8.a-b", region = "Bay of Biscay and the Iberian Coast",
    ocean = "Northeast Atlantic", notes = "Current ICES Bay of Biscay sole unit; distinct from the Irish Sea and North Sea sole records."), stocks_path)
  append_csv(make_rows("assessments", 1L, assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
    assessment_type = "assessment", model_family = "SAM", model_version = "stockassessment/TMB",
    is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
    assessment_url = report_url, framework_url = framework_url, data_url = "",
    model_url = repository_url, repository_url = "https://codeload.github.com/ices-advice/2026_sol.27.8ab/zip/e6b6c484f6c50e1199097682ca6b451f8232e235",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "2026 WGBIE applied SAM assessment. Tables report inputs and outputs through 2025, while section 7.4.2 states final data year 2026. Exact catch scale and production-run M vector remain unresolved; no previous unit or earlier run is substituted."), assessments_path)
  append_csv(assumptions_new, assumptions_path)
  append_csv(inputs_new, inputs_path)
  append_csv(outputs_new, outputs_path)
  source(file.path(root, "data-raw/scripts/shared/candidate_register_io.R"), local = TRUE)
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$eligibility[ci] <- "unresolved"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- "WGBIE 2026 Table 7.4 values for ages 2-8+ and 1984-2025 imported on the printed scale; the multiplier is not stated."
  candidates$survey_age_evidence[ci] <- "Table 7.7 has French BTS VIII standardized indices at ages 2-7 for 2007-2025; Table 7.8 has the French trawler FSB index for 2010-2025. Physical index units are not stated."
  candidates$weights_evidence[ci] <- "Tables 7.5-7.6 provide catch and stock weights at ages 2-8+ in kg for 1984-2025."
  candidates$maturity_evidence[ci] <- "Table 7.2 provides the fixed maturity ogive at ages 2-8+."
  candidates$mortality_evidence[ci] <- "Table 7.3 and section 7.4.2 report different M-at-age vectors; neither is assigned as the production input."
  candidates$timing_evidence[ci] <- "Pinned model code gives BTS VIII timing 11/12 to 1 and trawler timing 0.1 to 2/12; the database timing field is left blank because these are intervals."
  candidates$output_evidence[ci] <- "Tables 7.11, 7.14 and 7.15 provide annual recruitment, SSB, Fbar, F-at-age and N-at-age through 2025; Table 7.11 intervals are 90%."
  candidates$review_date[ci] <- "2026-11-15"
  candidates$decision_reason[ci] <- "A partial current-unit import is supported by detailed report tables. Full scale validation remains unresolved for catch and M, and the model settings disagree on the data terminal year."
  candidates$notes[ci] <- paste(candidates$notes[ci], "Partial report data imported as ices_sol_27_8ab_2026; exact catch multiplier and M input remain unresolved.")
  replace_candidate_register_row(candidate_path, ci, candidates[ci, , drop = FALSE], candidate_id)
}

cat("ICES Bay of Biscay sole source extraction passed.\n")
cat("Inputs:", nrow(inputs_new), "; outputs:", nrow(outputs_new),
  "; assumptions:", nrow(assumptions_new), ".\n")
if (write_mode) cat("Import written to ", database, ".\n", sep = "")
