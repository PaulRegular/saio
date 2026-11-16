root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- normalizePath(file.path(root, "database"), winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

stock_id <- "ices_wit_27_3a47d"
assessment_id <- "ices_wit_27_3a47d_2026"
candidate_id <- "ICES:wit.27.3a47d"
report_url <- "https://doi.org/10.17895/ices.pub.32676345.v2"
framework_url <- "https://doi.org/10.17895/ices.pub.8280"
model_url <- paste0("https://github.com/ices-advice/2026_wit.27.3a47d/tree/",
  "030bc61156d1369af85e77afd8f7c17d1d50ca0a/2026_wit.27.3a47d_assessment")
data_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22534"
manifest_path <- file.path(root, "provenance", assessment_id, "sources.csv")
manifest <- read.csv(manifest_path, colClasses = "character", check.names = FALSE)
manifest$file <- gsub("\\\\", "/", manifest$file)
cache <- file.path(root, "source_cache")

sha256 <- function(path) {
  stream <- file(path, "rb")
  on.exit(close(stream))
  tolower(unclass(as.character(openssl::sha256(stream))))
}
source_paths <- file.path(cache, manifest$file)
if (!all(c("file", "sha256", "bytes") %in% names(manifest)) ||
    any(!file.exists(source_paths)) ||
    any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1L))))) {
  stop("Cached ICES witch sources do not match the reviewed provenance manifest.", call. = FALSE)
}
report_path <- file.path(cache, "shared", "ices_witch_northsea_2026", "wgnssk_witch.txt")
pdf_path <- file.path(cache, "shared", "ices_witch_northsea_2026", "wgnssk_witch.pdf")
report <- readLines(report_path, warn = FALSE, encoding = "UTF-8")

table_lines <- function(table_id) {
  title <- paste0("^\\s*Table ", gsub("\\.", "\\\\.", table_id), "\\.")
  start <- grep(title, report, perl = TRUE)[1L]
  if (is.na(start)) stop("Missing WGNSSK table ", table_id, call. = FALSE)
  next_table <- grep("^\\s*Table 23\\.", report, perl = TRUE)
  next_table <- next_table[next_table > start]
  stop_at <- if (length(next_table)) min(next_table) else length(report) + 1L
  report[seq.int(start + 1L, stop_at - 1L)]
}

parse_number <- function(x) {
  x <- gsub(",", ".", x, fixed = TRUE)
  x <- sub("\\*$", "", x)
  value <- suppressWarnings(as.numeric(x))
  if (!is.finite(value)) stop("Unexpected number in source table: ", x, call. = FALSE)
  value
}

parse_year_matrix <- function(table_id, years, n_values) {
  lines <- table_lines(table_id)
  data_lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\*?\\s", lines, perl = TRUE)]
  rows <- lapply(data_lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    c(year = parse_number(fields[[1L]]), vapply(fields[-1L], parse_number, numeric(1L)))
  })
  if (!length(rows) || any(lengths(rows) != n_values + 1L))
    stop("Unexpected year/value layout in WGNSSK Table ", table_id, call. = FALSE)
  values <- do.call(rbind, rows)
  if (!identical(as.integer(values[, 1L]), as.integer(years)) ||
      any(!is.finite(values)) || any(values[, -1L, drop = FALSE] < 0))
    stop("Unexpected year coverage or values in WGNSSK Table ", table_id, call. = FALSE)
  list(year = as.integer(values[, 1L]), value = values[, -1L, drop = FALSE])
}

parse_fixed_vector <- function(table_id, n_values) {
  lines <- table_lines(table_id)
  rows <- lapply(lines, function(line) {
    fields <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    numeric_fields <- fields[grepl("^[0-9]+(?:\\.[0-9]+)?$", fields, perl = TRUE)]
    if (length(numeric_fields) != n_values) return(numeric())
    vapply(numeric_fields, parse_number, numeric(1L))
  })
  valid <- vapply(rows, length, integer(1L)) == n_values
  if (sum(valid) != 1L) stop("Could not identify one fixed vector in Table ", table_id, call. = FALSE)
  rows[[which(valid)]]
}

parse_indices <- function() {
  pages <- pdftools::pdf_data(pdf_path)
  series <- list(Q1 = data.frame(year = integer(), value = numeric()),
    Q3 = data.frame(year = integer(), value = numeric()))
  for (page in c(13L, 14L, 15L)) {
    tokens <- pages[[page]]
    years <- tokens[grepl("^(19|20)[0-9]{2}$", tokens$text) & tokens$x >= 80 & tokens$x <= 110, ]
    for (i in seq_len(nrow(years))) {
      year <- as.integer(years$text[i])
      row <- tokens[tokens$y == years$y[i], ]
      for (name in c("Q1", "Q3")) {
        xlim <- if (name == "Q1") c(420, 445) else c(445, 480)
        value <- row$text[row$x >= xlim[1L] & row$x < xlim[2L]]
        value <- value[grepl("^[0-9]+(?:[.,][0-9]+)?$", value, perl = TRUE)]
        if (length(value) == 1L) series[[name]] <- rbind(series[[name]],
          data.frame(year = year, value = parse_number(value)))
      }
    }
  }
  series$Q1 <- series$Q1[series$Q1$year %in% 1983:2008, ]
  series$Q3 <- series$Q3[series$Q3$year %in% 1991:2008, ]
  if (!identical(series$Q1$year, 1983:2008) || !identical(series$Q3$year, 1991:2008) ||
      series$Q1$value[1L] != .26 || tail(series$Q1$value, 1L) != .13 ||
      series$Q3$value[1L] != .25 || tail(series$Q3$value, 1L) != .1) {
    stop("The aggregate IBTS indices differ from Table 23.1 or expected model coverage.", call. = FALSE)
  }
  series
}

parse_landings <- function() {
  pages <- pdftools::pdf_data(pdf_path)
  rows <- list()
  for (page in 15:18) {
    tokens <- pages[[page]]
    years <- tokens[grepl("^(19|20)[0-9]{2}\\*?$", tokens$text) & tokens$x >= 80 & tokens$x <= 110, ]
    for (i in seq_len(nrow(years))) {
      year <- as.integer(sub("\\*+$", "", years$text[i]))
      if (!year %in% 1950:2008) next
      row <- tokens[tokens$y == years$y[i], ]
      total <- row$text[row$x >= 395 & row$x < 420]
      total <- total[grepl("^[0-9]+$", total)]
      if (length(total) != 1L) stop("Missing or ambiguous total landings in Table 23.2 for ", year, call. = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(year = year, value = as.numeric(total))
    }
  }
  out <- do.call(rbind, rows)
  out <- out[order(out$year), ]
  if (!identical(out$year, 1950:2008) || anyDuplicated(out$year) ||
      out$value[1L] != 2379 || tail(out$value, 1L) != 1953)
    stop("The historical landings series differs from Table 23.2.", call. = FALSE)
  out
}

catch_numbers <- parse_year_matrix("23.4", 2009:2025, 10L)
landings_weights <- parse_year_matrix("23.5a", 2009:2025, 10L)
discard_weights <- parse_year_matrix("23.5b", 2009:2025, 10L)
catch_weights <- parse_year_matrix("23.5c", 2009:2025, 10L)
stock_weights <- parse_fixed_vector("23.6", 10L)
maturity_source <- parse_fixed_vector("23.7", 12L)
maturity <- c(maturity_source[1:9], .851)
summary <- parse_year_matrix("23.8", 1950:2025, 12L)
f_at_age <- parse_year_matrix("23.9", 1950:2025, 10L)
n_at_age <- parse_year_matrix("23.10", 1950:2025, 10L)
indices <- parse_indices()
landings <- parse_landings()

stopifnot(
  catch_numbers$value[1L, 1L] == 1880573,
  catch_numbers$value[17L, 10L] == 163405,
  landings_weights$value[1L, 1L] == .113,
  catch_weights$value[17L, 10L] == .41,
  identical(unname(stock_weights), c(.0055, .033, .077, .151, .23, .34, .38, .43, .44, .50)),
  identical(unname(maturity), c(0, 0, .114, .136, .275, .376, .428, .524, .631, .851)),
  summary$value[76L, 4L] == 4650,
  summary$value[76L, 7L] == .151,
  summary$value[76L, 10L] == 17783,
  f_at_age$value[76L, 10L] == .21,
  n_at_age$value[76L, 10L] > 0
)

make_rows <- function(table, n, ...) {
  header <- readLines(file.path(database, paste0(table, ".csv")), n = 1L, warn = FALSE)
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  values <- list(...)
  if (length(setdiff(names(values), columns))) stop("Unknown columns for ", table, call. = FALSE)
  out <- as.data.frame(lapply(columns, function(x) rep(NA_character_, n)), check.names = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns && !"assessment_id" %in% names(values))
    out$assessment_id <- assessment_id
  for (name in names(values)) out[[name]] <- rep_len(as.character(values[[name]]), n)
  out
}

fmt <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15L)
age_rows <- function(table, ages, type, measure, basis, unit, fleet = "",
  source_ref, notes, input_type = type) {
  grid <- expand.grid(age = ages, year = table$year, KEEP.OUT.ATTRS = FALSE)
  values <- as.vector(t(table$value))
  make_rows("inputs", nrow(grid), type = input_type, measure = measure, basis = basis,
    fleet = fleet, region = "Subarea 4 and divisions 3.a and 7.d",
    year = grid$year, year_basis = "calendar_year", age = grid$age,
    value = fmt(values), unit = unit, source_type = "official_table",
    source_reference = source_ref, notes = notes)
}

output_age <- function(table, ages, type, measure, unit, source_ref, notes) {
  grid <- expand.grid(age = ages, year = table$year, KEEP.OUT.ATTRS = FALSE)
  values <- as.vector(t(table$value))
  make_rows("outputs", nrow(grid), type = type, measure = measure,
    region = "Subarea 4 and divisions 3.a and 7.d", year = grid$year,
    age = grid$age, age_group = ifelse(grid$age == max(ages), "10+", ""),
    value = fmt(values), unit = unit, source_type = "official_table",
    source_reference = source_ref, notes = notes)
}

report_ref <- function(table, pages) paste0(report_url, "; Table ", table, ", pp. ", pages)
ages <- 1:10
catch_input <- age_rows(catch_numbers, ages, "catch", "numbers_at_age", "numbers",
  "reported count (table multiplier not stated)", fleet = "Total catch",
  source_ref = report_ref("23.4", "1292"),
  notes = "Catch numbers-at-age for 2009-2025. Age 10 represents 10+. Values are transcribed as printed; the report table does not state a numerical multiplier, so no scale conversion is made.")
landings_weight_input <- age_rows(landings_weights, ages, "catch_weight", "weight_at_age", "kg_per_fish",
  "kg per fish", fleet = "Landings", source_ref = report_ref("23.5a", "1292-1293"),
  notes = "Mean landings weight-at-age in kg; age 10 represents 10+.")
discard_weight_input <- age_rows(discard_weights, ages, "catch_weight", "weight_at_age", "kg_per_fish",
  "kg per fish", fleet = "Discards", source_ref = report_ref("23.5b", "1293-1294"),
  notes = "Mean discards weight-at-age in kg; age 10 represents 10+.")
catch_weight_input <- age_rows(catch_weights, ages, "catch_weight", "weight_at_age", "kg_per_fish",
  "kg per fish", fleet = "Total catch", source_ref = report_ref("23.5c", "1294"),
  notes = "Mean catch weight-at-age in kg; age 10 represents 10+.")

constant_age_input <- function(type, measure, basis, value, unit, source_ref, notes) {
  make_rows("inputs", length(ages), type = type, measure = measure, basis = basis,
    region = "Subarea 4 and divisions 3.a and 7.d", age = ages, value = fmt(value),
    unit = unit, source_type = "official_table", source_reference = source_ref, notes = notes)
}
stock_weight_input <- constant_age_input("weight", "weight_at_age", "kg_per_fish",
  stock_weights, "kg per fish", report_ref("23.6", "1294"),
  "Constant stock weight-at-age; age 10 represents 10+.")
maturity_input <- constant_age_input("maturity", "maturity_at_age", "proportion",
  maturity, "proportion", report_ref("23.7", "1294"),
  "Fixed maturity ogive. Reported ages 10-12 are collapsed to the assessment 10+ group using the report's stated mean 0.851.")
mortality_input <- constant_age_input("M", "natural_mortality_at_age", "per_year",
  rep(.2, length(ages)), "per year", paste0(report_url, "; section 23.2.4, p. 1278"),
  "Fixed natural mortality M=0.2 per year at all ages and years; age 10 represents 10+.")

landings_input <- make_rows("inputs", nrow(landings), type = "catch",
  measure = "landings_biomass", basis = "biomass", fleet = "Official total landings",
  region = "Subarea 4 and divisions 3.a and 7.d", year = landings$year,
  year_basis = "calendar_year", value = landings$value, unit = "tonnes",
  source_type = "official_table", source_reference = report_ref("23.2", "1287-1290"),
  notes = "Official total landings, including division 7.d, taken from the report's total column for 1950-2008, the period used by the assessment. The total column is used directly, not recomputed from rounded regional values. This series overlaps the subsequent age-specific catch series and is not an independent observation.")
index_rows <- function(x, survey, season) {
  make_rows("inputs", nrow(x), type = "index", measure = "relative_biomass_index",
    basis = "index_scale", survey = survey, region = "Subarea 4 and divisions 3.a and 7.d",
    season = season, year = x$year, year_basis = "calendar_year", value = x$value,
    unit = "kg per hour", sampling_time = NA_real_, source_type = "official_table",
    source_reference = report_ref("23.1", "1285-1287"),
    notes = paste0("Aggregate fishable-stock biomass index for ", season,
      ". Assessment-used series only (Q1: 1983-2008; Q3: 1991-2008). The table has more recent values but explicitly states that values from 2009 onward are not included in the assessment. Quarter is known; within-quarter sampling timing is not reported, so sampling_time is blank."))
}
q1_input <- index_rows(indices$Q1, "IBTS Q1", "Q1")
q3_input <- index_rows(indices$Q3, "Combined IBTS-BTS Q3", "Q3")
inputs_new <- rbind(catch_input, landings_weight_input, discard_weight_input,
  catch_weight_input, stock_weight_input, maturity_input, mortality_input,
  landings_input, q1_input, q3_input)

summary_output <- function(value_col, low_col, high_col, type, measure, unit,
  age = NA_integer_, age_group = "", note) {
  make_rows("outputs", 76L, type = type, measure = measure,
    region = "Subarea 4 and divisions 3.a and 7.d", year = 1950:2025,
    age = age, age_group = age_group, value = fmt(summary$value[, value_col]),
    lwr = fmt(summary$value[, low_col]), upr = fmt(summary$value[, high_col]),
    unit = unit, source_type = "official_table", source_reference = report_ref("23.8", "1295-1297"),
    notes = note)
}
summary_outputs <- rbind(
  summary_output(1L, 2L, 3L, "recruitment", "recruitment", "thousand fish",
    age = 1L, age_group = "age 1", note = "Estimated age-1 recruitment. Table reports lower and upper 95% confidence bounds."),
  summary_output(4L, 5L, 6L, "biomass", "SSB", "tonnes",
    note = "Estimated spawning-stock biomass at spawning time (1 July). Table reports lower and upper 95% confidence bounds."),
  summary_output(7L, 8L, 9L, "mortality", "Fbar", "per year", age_group = "4-8",
    note = "Estimated mean fishing mortality for ages 4-8. Table reports lower and upper 95% confidence bounds."),
  summary_output(10L, 11L, 12L, "biomass", "total_biomass", "tonnes",
    note = "Estimated total stock biomass. Table reports lower and upper 95% confidence bounds.")
)
F_output <- output_age(f_at_age, ages, "mortality", "fishing_mortality_at_age", "per year",
  report_ref("23.9", "1297-1300"),
  "Estimated fishing mortality-at-age. Age 10 represents 10+. The report states that age information was used only from 2009 onward; earlier estimates are model outputs, not direct age-specific observations. No age-specific uncertainty is tabulated.")
N_output <- output_age(n_at_age, ages, "population", "numbers_at_age", "thousand fish",
  report_ref("23.10", "1300-1303"),
  "Estimated stock numbers-at-age in thousands. Age 10 represents 10+. The report states that age information was used only from 2009 onward; earlier estimates are model outputs, not direct age-specific observations. No age-specific uncertainty is tabulated.")
outputs_new <- rbind(F_output, N_output, summary_outputs)

assumption <- function(component, setting, value, source_ref, notes, survey = "") {
  make_rows("assumptions", 1L, assessment_id = assessment_id, component = component,
    survey = survey, region = "Subarea 4 and divisions 3.a and 7.d", setting = setting,
    value = value, source_reference = source_ref, notes = notes)
}
assumptions_new <- do.call(rbind, list(
  assumption("model", "assessment model", "SAM", model_url, "2026 WGNSSK assessment code is pinned to the reported applied run."),
  assumption("population", "model ages", "1-10+", report_ref("23.4", "1292"), "Age 10 is the plus group."),
  assumption("fishing_mortality", "Fbar ages", "4-8", report_ref("23.8", "1295-1297"), "Summary table defines Fbar as the mean for ages 4-8."),
  assumption("M", "natural mortality", "0.2 per year at all ages and years", report_ref("23.2.4", "1278"), "Fixed M; no annual or age variation is reported."),
  assumption("biology", "maturity ogive", "Fixed by age; 10+ = 0.851", report_ref("23.7", "1294"), "The 10+ value is the report's average across ages 10-12."),
  assumption("biology", "stock weights", "Fixed by age for all years", report_ref("23.6", "1294"), "Age-specific stock weights are treated as constant."),
  assumption("population", "SSB timing", "1 July; 0.5 of F and M before spawning", report_ref("23.4", "1279"), "Report states spawning is at mid-year."),
  assumption("survey", "Q1 aggregate index period", "1983-2008", report_ref("23.1", "1285"), "The assessment uses total biomass indices through 2008; the table's 2009+ values are excluded.", "IBTS Q1"),
  assumption("survey", "Q3 aggregate index period", "1991-2008", report_ref("23.1", "1285"), "The assessment uses total biomass indices through 2008; the table's 2009+ values are excluded.", "Combined IBTS-BTS Q3"),
  assumption("survey", "survey age data", "Q1 and Q3 age-specific index matrices described for 2009-2025; numeric series not recovered", report_ref("23.2.5", "1278-1279"), "The report describes these series but the numeric matrices are absent from the reviewed public report and repository.", "IBTS Q1 and Q3"),
  assumption("catch", "catch-at-age multiplier", "Not stated in Table 23.4", report_ref("23.4", "1292"), "Values are preserved on the printed scale; no multiplier or conversion is inferred."),
  assumption("uncertainty", "summary interval", "95% confidence bounds", report_ref("23.8", "1295"), "Lower and upper bounds are available for recruitment, SSB, Fbar and total stock biomass."),
  assumption("data", "age-specific observations", "2009-2025", report_ref("23.4", "1292"), "Catch-at-age and age-specific model inputs begin in 2009; report notes age information was used only since 2009.")
))

if (nrow(inputs_new) != 813L || nrow(outputs_new) != 1824L || nrow(assumptions_new) != 13L)
  stop("Unexpected ICES witch source row counts.", call. = FALSE)

append_csv <- function(x, path) write.table(x, path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", qmethod = "double")
file_has_assessment <- function(path) {
  status <- system2("rg", c("--quiet", "--regexp", paste0('^"', assessment_id, '",'), shQuote(path)),
    stdout = FALSE, stderr = FALSE)
  if (identical(as.integer(status), 0L)) return(TRUE)
  if (identical(as.integer(status), 1L)) return(FALSE)
  stop("Could not check existing rows in ", path, call. = FALSE)
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
      file_has_assessment(assumptions_path) || file_has_assessment(inputs_path) || file_has_assessment(outputs_path))
    stop("The ICES witch stock or assessment is already present; refusing to append it twice.", call. = FALSE)
  candidate_path <- file.path(root, "database", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$screening_status[ci] != "screened" ||
      candidates$import_status[ci] != "not_started")
    stop("Expected one screened, not-yet-imported ICES witch candidate.", call. = FALSE)
  append_csv(make_rows("stocks", 1L, stock_id = stock_id, charbonneau_id = NA_character_,
    authority = "ICES", authority_stock_id = "wit.27.3a47d", scientific_name = "Glyptocephalus cynoglossus",
    common_name = "Witch flounder", area = "Subarea 4 and divisions 3.a and 7.d",
    region = "Greater North Sea, Skagerrak, Kattegat and eastern English Channel",
    ocean = "Northeast Atlantic", notes = "Current ICES North Sea witch flounder unit."), stocks_path)
  append_csv(make_rows("assessments", 1L, assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
    assessment_type = "assessment", model_family = "SAM", model_version = "stockassessment/TMB",
    is_current = TRUE, is_applied = TRUE, framework_year = 2018L,
    assessment_url = report_url, framework_url = framework_url, data_url = data_url,
    model_url = model_url,
    repository_url = "https://codeload.github.com/ices-advice/2026_wit.27.3a47d/zip/030bc61156d1369af85e77afd8f7c17d1d50ca0a",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "2026 applied SAM assessment. The report provides aggregate indices, catch-at-age and biology, but numerical age-specific survey series and within-quarter timing were not recovered; the catch-at-age multiplier is unstated."), assessments_path)
  append_csv(assumptions_new, assumptions_path)
  append_csv(inputs_new, inputs_path)
  append_csv(outputs_new, outputs_path)
  source(file.path(root, "scripts", "shared", "candidate_register_io.R"), local = TRUE)
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$eligibility[ci] <- "unresolved"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- "WGNSSK 2026 Table 23.4 supplies 2009-2025 numbers-at-age (ages 1-10+); table multiplier is unstated. Table 23.2 supplies model-period aggregate landings in tonnes."
  candidates$survey_age_evidence[ci] <- "Assessment-used aggregate IBTS Q1 index (1983-2008) and combined IBTS-BTS Q3 index (1991-2008) are recoverable from Table 23.1; numerical Q1/Q3 age-index matrices for 2009-2025 are not recovered."
  candidates$weights_evidence[ci] <- "Tables 23.5a-c provide landings, discard and catch weights-at-age in kg for 2009-2025; Table 23.6 gives constant stock weights-at-age."
  candidates$maturity_evidence[ci] <- "Table 23.7 supplies a fixed maturity ogive; 10+ is the reported mean 0.851 for ages 10-12."
  candidates$mortality_evidence[ci] <- "Natural mortality fixed at 0.2 per year for all ages and years."
  candidates$timing_evidence[ci] <- "Surveys are identified by quarter only; no single within-quarter sampling time is reported."
  candidates$output_evidence[ci] <- "Tables 23.8-23.10 provide recruitment, SSB, Fbar, total stock biomass, F-at-age and N-at-age through 2025; summary intervals are 95%."
  candidates$review_date[ci] <- "2026-11-15"
  candidates$decision_reason[ci] <- "A partial current-unit import is supported by detailed English report tables. The survey age series and timing remain unavailable, and catch-at-age scale is not explicitly stated."
  candidates$notes[ci] <- paste(candidates$notes[ci], "Partial report data imported as ices_wit_27_3a47d_2026; survey age-index values and catch-at-age scale remain unresolved.")
  replace_candidate_register_row(candidate_path, ci, candidates[ci, , drop = FALSE], candidate_id)
}

cat("ICES North Sea witch source extraction passed.\n")
cat("Inputs:", nrow(inputs_new), "; outputs:", nrow(outputs_new),
  "; assumptions:", nrow(assumptions_new), ".\n")
if (write_mode) cat("Import written to ", database, ".\n", sep = "")
