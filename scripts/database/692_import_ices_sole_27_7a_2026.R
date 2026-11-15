root <- normalizePath(".", winslash = "/")
database <- Sys.getenv("SAIO_DATABASE_DIR", "database")
if (!grepl("^(?:[A-Za-z]:|/)", database)) database <- file.path(root, database)
database <- normalizePath(database, winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
stock_id <- "ices_sol_27_7a"
assessment_id <- paste0(stock_id, "_2026")
candidate_id <- "ICES:sol.27.7a"
report_url <- "https://doi.org/10.17895/ices.pub.32625759"
advice_url <- "https://doi.org/10.17895/ices.advice.30932405"
framework_url <- "https://doi.org/10.17895/ices.pub.25471987.v1"
repo_url <- "https://github.com/ices-advice/2026_sol.27.7a/tree/bff4518e75378685700c849a24c5ba9c86e5a575/2026_sol.27.7a_assessment"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22641"
cache <- file.path(root, "source_cache/solea_solea/ices_sol_27_7a_2026")
provenance <- file.path(root, "provenance", assessment_id, "sources.csv")
manifest <- read.csv(provenance, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
sha256 <- function(path) {
  stream <- file(path, "rb")
  on.exit(close(stream))
  tolower(unclass(as.character(openssl::sha256(stream))))
}
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) ||
    any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1)))) ||
    any(!manifest$file %in% c("wgcse_sole_7a.pdf", "repository.zip",
      "sag_22641.html", "sag_charts_22641.html", "ices_advice_30932405.pdf"))) {
  stop("Cached ICES sole sources do not match the reviewed provenance manifest.", call. = FALSE)
}

pdf <- pdftools::pdf_text(file.path(cache, "wgcse_sole_7a.pdf"))
make_rows <- function(table, n, ...) {
  header <- readLines(file.path(database, paste0(table, ".csv")), n = 1L)
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  values <- list(...)
  unknown <- setdiff(names(values), columns)
  if (length(unknown)) stop("Unknown ", table, " column: ", paste(unknown, collapse = ", "), call. = FALSE)
  out <- as.data.frame(lapply(columns, function(x) rep(NA_character_, n)), check.names = FALSE)
  names(out) <- columns
  for (name in names(values)) out[[name]] <- rep_len(as.character(values[[name]]), n)
  out
}

parse_age_surface <- function(pages) {
  lines <- trimws(unlist(strsplit(pdf[pages], "\\n")))
  headers <- grep("^age +[0-9]{4}( +[0-9]{4})*$", lines)
  years_all <- 1970:2025
  ages_all <- c(as.character(1:9), "10+")
  surface <- matrix(NA_real_, length(ages_all), length(years_all),
    dimnames = list(ages_all, as.character(years_all)))
  for (k in seq_along(headers)) {
    h <- headers[k]
    end <- if (k < length(headers)) headers[k + 1L] - 1L else length(lines)
    header <- strsplit(lines[h], " +")[[1L]]
    years <- as.integer(header[-1L])
    rows <- lines[seq.int(h + 1L, end)]
    rows <- rows[grepl("^(10\\+|[1-9]) +", rows)]
    seen_ages <- character()
    for (line in rows) {
      fields <- strsplit(trimws(line), " +")[[1L]]
      age <- fields[1L]
      if (!age %in% ages_all || length(fields) != length(years) + 1L) next
      if (anyDuplicated(years) || age %in% seen_ages) stop("Duplicate age-table row in source PDF.", call. = FALSE)
      seen_ages <- c(seen_ages, age)
      values <- suppressWarnings(as.numeric(fields[-1L]))
      if (any(!is.finite(values))) stop("Non-numeric age table cell in source PDF.", call. = FALSE)
      surface[age, as.character(years)] <- values
    }
    if (!setequal(seen_ages, ages_all)) stop("An age-table block is missing source age rows.", call. = FALSE)
  }
  if (any(!is.finite(surface))) stop("The age table does not cover ages 1-10+ and years 1970-2025.", call. = FALSE)
  surface
}
parse_summary <- function() {
  lines <- trimws(unlist(strsplit(pdf[53:55], "\\n")))
  candidates <- lines[grepl("^[0-9]{4} +", lines)]
  rows <- lapply(candidates, function(line) {
    fields <- strsplit(trimws(line), " +")[[1L]]
    values <- suppressWarnings(as.numeric(fields))
    if (length(values) != 16L) return(NULL)
    values
  })
  rows <- Filter(Negate(is.null), rows)
  out <- do.call(rbind, rows)
  if (is.null(out) || nrow(out) != 56L || !identical(as.integer(out[, 1L]), 1970:2025)) {
    stop("Could not recover the 1970-2025 Table 19.16 summary.", call. = FALSE)
  }
  colnames(out) <- c("year", "R_low", "R", "R_high", "TSB_low", "TSB", "TSB_high",
    "SSB_low", "SSB", "SSB_high", "catch_low", "catch", "catch_high",
    "Fbar_low", "Fbar", "Fbar_high")
  for (prefix in c("R", "TSB", "SSB", "catch", "Fbar")) {
    if (any(out[, paste0(prefix, "_low")] > out[, prefix]) ||
        any(out[, prefix] > out[, paste0(prefix, "_high")])) {
      stop("Invalid low/estimate/high ordering in Table 19.16 for ", prefix, ".", call. = FALSE)
    }
  }
  out
}
summary_table <- parse_summary()
catch_numbers <- parse_age_surface(22:24)
catch_weights <- parse_age_surface(25:27)
stock_weights <- parse_age_surface(29:31)
F_at_age <- parse_age_surface(44:46)
N_at_age <- parse_age_surface(47:49)
SSB_at_age <- parse_age_surface(50:52)

wrapped_age1_years <- c(2015:2020, 2022:2025)
if (!all(abs(N_at_age["1", as.character(setdiff(1970:2025, wrapped_age1_years))] -
    summary_table[setdiff(1970:2025, wrapped_age1_years) - 1969L, "R"]) < 0.5)) {
  stop("Unwrapped age-1 abundance does not match Table 19.16 recruitment.", call. = FALSE)
}
N_at_age["1", ] <- summary_table[, "R"]
N_at_age["2", "2016"] <- 10132
N_at_age["2", "2019"] <- 86744
N_at_age["2", "2021"] <- 54852
N_at_age["3", "2021"] <- 10836
if (catch_numbers["1", "2025"] != 39 || catch_numbers["2", "2025"] != 570 ||
    catch_numbers["10+", "2025"] != 276 || F_at_age["9", "2025"] != 0.134 ||
    F_at_age["10+", "2025"] != 0.134) {
  stop("Key source table cells differ from the visually checked report values.", call. = FALSE)
}

index_lines <- trimws(unlist(strsplit(pdf[33:35], "\\n")))
be_start <- grep("^BE-CBT", index_lines)[1L]
uk_start <- grep("^UK\\(E&W\\)-BTS-Q3", index_lines)[1L]
if (is.na(be_start) || is.na(uk_start) || be_start >= uk_start) stop("Tuning-series headings were not found.", call. = FALSE)
be_lines <- index_lines[seq.int(be_start + 1L, uk_start - 1L)]
be_rows <- be_lines[grepl("^1 +(NA|[0-9]+(?:\\.[0-9]+)?)$", be_lines, perl = TRUE)]
be_values <- vapply(be_rows, function(x) {
  v <- strsplit(trimws(x), " +")[[1L]][2L]
  if (v == "NA") NA_real_ else as.numeric(v)
}, numeric(1L))
if (length(be_values) != 22L) stop("Belgian biomass-index series should cover 2004-2025.", call. = FALSE)
uk_lines <- index_lines[seq.int(uk_start + 1L, length(index_lines))]
uk_rows <- uk_lines[grepl("^1 +", uk_lines)]
uk_fields <- lapply(uk_rows, function(x) strsplit(trimws(x), " +")[[1L]])
uk_fields <- Filter(function(x) length(x) == 11L, uk_fields)
if (length(uk_fields) != 38L) stop("UK survey index should have 38 year rows for 1988-2025.", call. = FALSE)
uk_values <- do.call(rbind, lapply(uk_fields, function(x) {
  values <- suppressWarnings(as.numeric(x[-1L]))
  values[x[-1L] == "NA"] <- NA_real_
  values
}))
colnames(uk_values) <- as.character(1:10)
if (!all(is.na(uk_values[2020L - 1987L, ])) ||
    any(is.finite(uk_values[2020L - 1987L, ]))) {
  stop("The UK survey 2020 missing row was not retained as reported.", call. = FALSE)
}

# Replace age-1 stock numbers with the matching Table 19.16 recruitment values.
N_at_age["1", ] <- summary_table[, "R"]
# The PDF line wraps split the final digits of these four Table 19.14 cells.
N_at_age["2", "2016"] <- 10132
N_at_age["2", "2019"] <- 86744
N_at_age["2", "2021"] <- 54852
N_at_age["3", "2021"] <- 10836

age_labels <- 1:10
age_surface_rows <- c(as.character(1:9), "10+")
model_catch <- catch_numbers
model_catch["1", as.character(1970:2002)] <- NA_real_
catch_grid <- expand.grid(age = age_labels, year = 1970:2025)
make_age_input <- function(surface, type, measure, unit, basis, note, source = report_url,
                           na_notes = NULL) {
  grid <- expand.grid(age = age_labels, year = 1970:2025)
  values <- as.vector(surface[age_surface_rows, as.character(1970:2025), drop = FALSE])
  make_rows("inputs", nrow(grid), assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, region = "Division 7.a (Irish Sea)",
    year = grid$year, year_basis = "calendar_year", age = grid$age, value = values,
    unit = unit, source_type = "official_table", source_reference = source,
    transformation = if (is.null(na_notes)) "" else ifelse(is.na(values), na_notes, ""),
    notes = note)
}
catch_input <- make_age_input(model_catch, "catch", "numbers_at_age", "thousands of fish", "numbers",
  "Table 19.2 catch numbers-at-age. Age 10+ is the assessment plus group. Age-1 values before 2003 are missing because the accepted assessment sets them to NA.",
  na_notes = "Age-1 catch numbers are excluded by the production model for 1970-2002; printed table cells are not used in the likelihood.")
catch_weight_input <- make_age_input(catch_weights, "catch_weight", "weight_at_age", "kg_per_fish", "kg_per_fish",
  "Table 19.3 catch weights-at-age, kg per fish; age 10+ retained as the plus group.")
stock_weight_input <- make_age_input(stock_weights, "weight", "weight_at_age", "kg_per_fish", "kg_per_fish",
  "Table 19.5 stock weights-at-age, kg per fish; age 10+ retained as the plus group.")
M_values <- c(.5971610, .3767715, .3105819, .2814876, .2669404,
  .2589395, .2545753, .2523932, .2509385, .2502112)
M_input <- make_rows("inputs", 10L, assessment_id = assessment_id, type = "M",
  measure = "natural_mortality_at_age", basis = "per_year", region = "Division 7.a (Irish Sea)",
  age = 1:10, value = M_values, unit = "per year", source_type = "official_document",
  source_reference = report_url,
  notes = "Fixed age-specific natural mortality from the 2024 benchmark estimation carried into the 2026 production SAM. Age 10 is 10+.")

survey_years <- 1988:2025
uk_grid <- expand.grid(age = 1:7, year = survey_years)
uk_index <- make_rows("inputs", nrow(uk_grid), assessment_id = assessment_id,
  type = "index", measure = "numbers_at_age", basis = "index_scale",
  survey = "UK(E&W)-BTS-Q3", region = "Division 7.a (Irish Sea)",
  year = uk_grid$year, year_basis = "calendar_year", age = uk_grid$age,
  value = as.vector(t(uk_values[, as.character(1:7), drop = FALSE])),
  unit = "index units; multiplier not stated", sampling_time = .8,
  source_type = "official_table", source_reference = report_url,
  notes = "Table 19.9 UK(E&W)-BTS-Q3 age-based tuning series. Only ages 1-7 are used; age 10 is not part of this survey. Sampling time 0.8 is the midpoint of the reported 0.75-0.85 interval, used by stockassessment setup.sam.data(). 2020 is missing due to COVID-19.")
be_years <- 2004:2025
be_index <- make_rows("inputs", length(be_years), assessment_id = assessment_id,
  type = "index", measure = "spawning_output_index", basis = "index_scale",
  survey = "BE-CBT", region = "Division 7.a (Irish Sea)", year = be_years,
  year_basis = "calendar_year", value = be_values,
  unit = "index units; multiplier not stated", sampling_time = 0,
  source_type = "official_table", source_reference = report_url,
  notes = "Table 19.9 Belgian commercial beam-trawl biomass series, treated as an SSB index in the production SAM. The numeric CV/likelihood weights used by the assessment are not available in the public source files. The 2017-2018 missing rows are retained.")
log_q <- make_rows("outputs", 8L, assessment_id = assessment_id, type = "parameter",
  measure = "log_q", survey = c(rep("UK(E&W)-BTS-Q3", 7), "BE-CBT"),
  age = c(1:7, NA_integer_), value = c(-1.883, -1.523, -1.596, -1.735, -1.832, -1.945, -1.945, -1.646),
  se = c(.109, .070, .072, .077, .097, .103, .103, .110), unit = "log index units",
  source_type = "official_table", source_reference = report_url,
  notes = "Table 19.12 reported log catchability and standard error. The UK age-6 and age-7 q estimates are shared and equal. Standard errors are on the reported log-q scale.")

surface_output <- function(surface, measure, type, unit, note) {
  grid <- expand.grid(age = age_labels, year = 1970:2025)
  values <- as.vector(surface[age_surface_rows, as.character(1970:2025), drop = FALSE])
  make_rows("outputs", nrow(grid), assessment_id = assessment_id, type = type,
    measure = measure, region = "Division 7.a (Irish Sea)", year = grid$year,
    age = grid$age, age_group = ifelse(grid$age == 10, "10+", ""), value = values,
    unit = unit, source_type = "official_table", source_reference = report_url,
    notes = note)
}
N_output <- surface_output(N_at_age, "numbers_at_age", "population", "thousands of fish",
  "Table 19.14 estimated stock numbers at age at the start of year. Age 10+ is the plus group; age-1 values are aligned to Table 19.16 recruitment because the PDF wrapped final digits in Table 19.14.")
F_output <- surface_output(F_at_age, "fishing_mortality_at_age", "mortality", "per year",
  "Table 19.13 estimated fishing mortality at age. Age 10+ is the plus group.")
SSB_age_output <- surface_output(SSB_at_age, "mature_biomass_at_age", "biomass", "tonnes",
  "Table 19.15 spawning-stock biomass at age at the start of year, as reported by ICES.")

summary_output <- rbind(
  make_rows("outputs", 56L, assessment_id = assessment_id, type = "recruitment",
    measure = "recruitment", year = summary_table[, "year"], value = summary_table[, "R"],
    lwr = summary_table[, "R_low"], upr = summary_table[, "R_high"],
    unit = "thousands of fish", source_type = "official_table", source_reference = report_url,
    notes = "Table 19.16 age-1 recruitment; Low/High bounds agree with ICES Standard Graphs 2.5th/97.5th percentiles."),
  make_rows("outputs", 56L, assessment_id = assessment_id, type = "biomass",
    measure = "total_biomass", year = summary_table[, "year"], value = summary_table[, "TSB"],
    lwr = summary_table[, "TSB_low"], upr = summary_table[, "TSB_high"], unit = "tonnes",
    source_type = "official_table", source_reference = report_url,
    notes = "Table 19.16 total stock biomass; Low/High bounds agree with ICES Standard Graphs 2.5th/97.5th percentiles."),
  make_rows("outputs", 56L, assessment_id = assessment_id, type = "biomass",
    measure = "SSB", year = summary_table[, "year"], value = summary_table[, "SSB"],
    lwr = summary_table[, "SSB_low"], upr = summary_table[, "SSB_high"], unit = "tonnes",
    source_type = "official_table", source_reference = report_url,
    notes = "Table 19.16 spawning-stock biomass; Low/High bounds agree with ICES Standard Graphs 2.5th/97.5th percentiles."),
  make_rows("outputs", 56L, assessment_id = assessment_id, type = "catch",
    measure = "predicted_catch", year = summary_table[, "year"], value = summary_table[, "catch"],
    lwr = summary_table[, "catch_low"], upr = summary_table[, "catch_high"], unit = "tonnes",
    source_type = "official_table", source_reference = report_url,
    notes = "Table 19.16 model-estimated catch (not observed landings); Low/High bounds agree with ICES Standard Graphs landings/catch summary interval."),
  make_rows("outputs", 56L, assessment_id = assessment_id, type = "mortality",
    measure = "Fbar", age_group = "3-7", year = summary_table[, "year"],
    value = summary_table[, "Fbar"], lwr = summary_table[, "Fbar_low"],
    upr = summary_table[, "Fbar_high"], unit = "per year", source_type = "official_table",
    source_reference = report_url,
    notes = "Table 19.16 mean fishing mortality ages 3-7. Low/High bounds agree with ICES Standard Graphs 2.5th/97.5th percentiles.")
)
outputs_new <- rbind(N_output, F_output, SSB_age_output, summary_output, log_q)
inputs_new <- rbind(catch_input, catch_weight_input, stock_weight_input, M_input, uk_index, be_index)
assumptions_new <- make_rows("assumptions", 11L,
  assessment_id = assessment_id,
  component = c("model", "population", "fishing_mortality", "fishing_mortality", "catchability", "catchability", "survey", "survey", "observation", "natural_mortality", "biology"),
  survey = c("", "", "", "", "UK(E&W)-BTS-Q3", "BE-CBT", "UK(E&W)-BTS-Q3", "BE-CBT", "Catch and both surveys", "", ""),
  region = "Division 7.a (Irish Sea)",
  setting = c("assessment framework", "recruitment process", "F correlation", "F state indexing", "q state indexing", "index type", "survey ages and timing", "survey timing", "observation correlation", "M estimation", "biological inputs"),
  value = c("SAM through stockassessment/TMB", "Plain random walk on logN at age 1", "AR(1)",
    "keyLogFsta ages 1-10+ = 0,1,2,3,4,5,6,7,8,8", "keyLogFpar ages 1-10+ = 0,1,2,3,4,5,5,-1,-1,-1",
    "Biomass index treated as spawning-stock biomass", "Ages 1-7; sampling interval 0.75-0.85", "Time 0 in Table 19.9",
    "Catch AR(1); UK and Belgian series independent", "Fixed external age-specific vector; not estimated in this assessment",
    "Stock/catch weights and maturity supplied as fixed data"),
  source_reference = c(repo_url, report_url, report_url, report_url, report_url,
    report_url, report_url, report_url, report_url, report_url, report_url),
  notes = c("The 2026 applied assessment is the SAM implementation described in WGCSE 2026 section 19.",
    "The recruitment model is the plain log-abundance random walk shown in Table 19.11.",
    "Table 19.11 specifies AR(1) correlation for F-at-age.",
    "The final two ages share the same F state; unique key indices are retained in the source mapping.",
    "UK q estimates at ages 6 and 7 are shared; Belgian index has its own biomass q.",
    "keyBiomassTreat=0 for BE-CBT; UK survey uses age-based abundance indices.",
    "The midpoint 0.8 is the source interval's center and the time used by setup.sam.data().",
    "No alternative timing is imputed.",
    "Table 19.11 reports AR for catch and ID for UK-BTS-Q3 and BE-CBT.",
    "The numeric fixed M vector is preserved in inputs.csv; values were estimated in the 2024 benchmark from a separate method.",
    "The 2026 revised maturity ogive is described but numeric values are not in the public report/archive; do not substitute an older ogive."))

append_csv <- function(x, path) {
  write.table(x, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", qmethod = "double")
}
if (write_mode) {
  stocks_path <- file.path(database, "stocks.csv")
  assessments_path <- file.path(database, "assessments.csv")
  stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id)) {
    stop("The ICES sole stock or assessment is already present; refusing to append it twice.", call. = FALSE)
  }
  append_csv(make_rows("stocks", 1L, stock_id = stock_id, charbonneau_id = NA_character_,
    authority = "ICES", authority_stock_id = "sol.27.7a", scientific_name = "Solea solea",
    common_name = "Sole", area = "Division 7.a (Irish Sea)", region = "Celtic Seas",
    ocean = "Northeast Atlantic", notes = "Current ICES Irish Sea management unit; do not conflate with other sole stocks."), stocks_path)
  append_csv(make_rows("assessments", 1L, assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
    assessment_type = "assessment", model_family = "SAM", model_version = "stockassessment/TMB",
    is_current = TRUE, is_applied = TRUE, framework_year = 2024L,
    assessment_url = advice_url, framework_url = framework_url, data_url = sag_url,
    model_url = repo_url,
    repository_url = "https://codeload.github.com/ices-advice/2026_sol.27.7a/zip/bff4518e75378685700c849a24c5ba9c86e5a575",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "2026 ICES WGCSE applied SAM assessment used for advice, with data through 2025. Published 2026 WGCSE section 19, cross-checked to ICES Standard Graphs advice key 22641. Detailed source inputs and outputs are incomplete because the revised maturity matrix and Belgian index weights/native fit files were not recovered."), assessments_path)
  append_csv(assumptions_new, file.path(database, "assumptions.csv"))
  append_csv(inputs_new, file.path(database, "inputs.csv"))
  append_csv(outputs_new, file.path(database, "outputs.csv"))

  source(file.path(root, "scripts/discovery/candidate_register_io.R"), local = TRUE)
  candidates_path <- file.path(root, "database/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$screening_status[ci] != "screened") {
    stop("Expected one screened ICES sole candidate.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$eligibility[ci] <- "unresolved"
  candidates$import_status[ci] <- "partial"
  candidates$catch_age_evidence[ci] <- "2026 WGCSE Table 19.2 gives accepted catch numbers-at-age 1-10+ for 1970-2025; the production model excludes age-1 values before 2003."
  candidates$survey_age_evidence[ci] <- "Table 19.9 provides UK(E&W)-BTS-Q3 age-based indices for ages 1-7, 1988-2025 with 2020 missing, plus an unaged Belgian spawning-output index for 2004-2025 with 2017-2018 missing. Belgian CV weights are unavailable."
  candidates$weights_evidence[ci] <- "Tables 19.3 and 19.5 provide catch and stock weights at ages 1-10+ for 1970-2025."
  candidates$maturity_evidence[ci] <- "The 2026 model uses a revised time-varying maturity ogive, but numerical values were not recovered from the report or public repository."
  candidates$mortality_evidence[ci] <- "Fixed M-at-age vector for ages 1-10+ is reported in the 2026 report and carried into the production SAM from the 2024 benchmark method."
  candidates$timing_evidence[ci] <- "UK survey timing is reported as 0.75-0.85 and represented in SAM at midpoint 0.8; Belgian survey timing is 0."
  candidates$output_evidence[ci] <- "Tables 19.13-19.16 provide fitted F-at-age, N-at-age, spawning biomass-at-age, annual recruitment, TSB, SSB, fitted catch and Fbar for 1970-2025. Table 19.16 Low/High bounds match ICES Standard Graphs 2.5th/97.5th percentiles."
  candidates$decision_reason[ci] <- "A partial source import is supported by detailed catch, survey, weight and M inputs and fitted age-specific and aggregate outputs. Full age-data eligibility remains unresolved because the revised production maturity ogive and Belgian observation weights are unavailable."
  candidates$notes[ci] <- paste(candidates$notes[ci], "Partial source data imported as ices_sol_27_7a_2026. No previous stock-area record is substituted; no native fitted object or complete source-data directory was recovered.")
  replace_candidate_register_row(candidates_path, ci, candidates[ci, , drop = FALSE], candidate_id)
}

cat("Verified ICES Irish Sea sole 2026 source import.\n")
cat("Inputs:", nrow(inputs_new), "including catch numbers, catch/stock weights, M, and two survey series.\n")
cat("Outputs:", nrow(outputs_new), "including fitted N/F/SSB-at-age and annual estimates with bounds.\n")
cat("Eligibility remains unresolved because revised maturity and Belgian survey weights are unavailable.\n")
if (write_mode) cat("Import written to", database, "\n")
