root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- Sys.getenv("SAIO_DATABASE_DIR", "database")
if (!grepl("^(?:[A-Za-z]:|/)", database)) database <- file.path(root, database)
database <- normalizePath(database, winslash = "/", mustWork = TRUE)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
options(scipen = 999)

stock_id <- "noaa_yellowtail_snapper_11081"
assessment_id <- "noaa_yellowtail_snapper_11081_2025"
candidate_id <- "NOAA:11081"
assessment_url <- "https://sedarweb.org/documents/sedar-96-southeastern-us-yellowtail-snapper-final-stock-assessment-report/"
framework_url <- "https://sedarweb.org/assessments/sedar-64/"
manifest_path <- file.path(root, "provenance", assessment_id, "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
manifest$file <- gsub("\\\\", "/", manifest$file)

sha256 <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  tolower(unclass(as.character(openssl::sha256(con))))
}
cache_path <- file.path(root, "source_cache", manifest$cache_folder)
source_paths <- file.path(cache_path, manifest$file)
if (!all(c("file", "url", "revision", "retrieved_on", "sha256", "bytes", "cache_folder") %in% names(manifest)) ||
    any(!file.exists(source_paths)) || any(as.numeric(manifest$bytes) != file.info(source_paths)$size) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256, character(1L))))) {
  stop("SEDAR 96 source files do not match their provenance manifest.", call. = FALSE)
}
report_path <- source_paths[manifest$file == "sedar96_final_stock_assessment_report.pdf"]
if (length(report_path) != 1L) stop("Expected one SEDAR 96 report in the source manifest.", call. = FALSE)
pages <- pdftools::pdf_text(report_path)

number <- function(x) {
  x <- gsub(",", "", x, fixed = TRUE)
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != 1L || !is.finite(value)) stop("Unexpected table value: ", x, call. = FALSE)
  value
}

input_columns <- names(read.csv(file.path(database, "inputs.csv"), nrows = 0L, check.names = FALSE))
output_columns <- names(read.csv(file.path(database, "outputs.csv"), nrows = 0L, check.names = FALSE))
assumption_columns <- names(read.csv(file.path(database, "assumptions.csv"), nrows = 0L, check.names = FALSE))

input_row <- function(type, measure, basis, value, unit, source_reference,
  fleet = "", survey = "", sex = "", region = "", year = NA_integer_, age = NA_integer_,
  sampling_time = NA_real_, source_type = "official_table", transformation = "",
  notes = "", observation_id = "", sample_size = NA_real_) {
  data.frame(assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = "",
    year = year, year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
    value = value, unit = unit, sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = sample_size, age_error = "", partition = "",
    weight_bin = NA_real_, stringsAsFactors = FALSE, check.names = FALSE)
}

output_row <- function(type, measure, value, unit, source_reference, year,
  fleet = "", sex = "", age = NA_integer_, notes = "") {
  data.frame(assessment_id = assessment_id, type = type, measure = measure, fleet = fleet,
    survey = "", sex = sex, region = "", season = "", year = year, age = age,
    age_group = "", value = value, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = unit, source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = "", stringsAsFactors = FALSE, check.names = FALSE)
}

assumption_row <- function(component, setting, value, source_reference, fleet = "",
  survey = "", sex = "", region = "", notes = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE)
}

inputs_list <- list()
outputs_list <- list()
assumptions_list <- list()
add_input <- function(...) inputs_list[[length(inputs_list) + 1L]] <<- input_row(...)
add_output <- function(...) outputs_list[[length(outputs_list) + 1L]] <<- output_row(...)
add_assumption <- function(...) assumptions_list[[length(assumptions_list) + 1L]] <<- assumption_row(...)

# Table 7: fixed biological schedules and the growth curve used to derive M.
tab7_lines <- trimws(strsplit(pages[[88L]], "\n", fixed = TRUE)[[1L]])
tab7_data <- tab7_lines[grepl("^(?:[0-9]|1[0-9]|20)\\s", tab7_lines, perl = TRUE)]
tab7 <- do.call(rbind, lapply(tab7_data, function(line) {
  fields <- strsplit(line, "\\s+", perl = TRUE)[[1L]]
  if (length(fields) != 4L) stop("Unexpected SEDAR 96 Table 7 row: ", line, call. = FALSE)
  as.numeric(fields)
}))
if (nrow(tab7) != 21L || !identical(as.integer(tab7[, 1L]), 0:20))
  stop("SEDAR 96 Table 7 does not contain ages 0-20.", call. = FALSE)
for (j in seq_len(nrow(tab7))) {
  age <- as.integer(tab7[j, 1L])
  add_input("biology", "growth_length_at_age", "native_covariate", tab7[j, 2L], "cm fork length",
    "SEDAR 96 final report, Table 7", age = age,
    notes = "Predicted length-at-age reported with the external SEDAR 64 growth curve. Retained as the source biological values used to derive the fixed M schedule; not claimed as a direct Stock Synthesis observation.")
  add_input("M", "natural_mortality_at_age", "per_year", tab7[j, 3L], "yr-1",
    "SEDAR 96 final report, Table 7", age = age,
    notes = "Fixed age-specific natural mortality (Mat-age), not estimated in SEDAR 96.")
  add_input("maturity", "maturity_at_age", "proportion", tab7[j, 4L], "proportion",
    "SEDAR 96 final report, Table 7", sex = "female", age = age,
    notes = "Fixed female maturity-at-age schedule carried from SEDAR 64.")
}

# Table 25: aggregate relative indices and their source-reported CVs.
p25 <- pdftools::pdf_data(report_path)[[106L]]
year_tokens <- p25[grepl("^(19|20)[0-9]{2}$", p25$text) & p25$x >= 70 & p25$x <= 105, , drop = FALSE]
index_specs <- data.frame(
  survey = c("Commercial CPUE", "MRIP", "RVC Florida Keys", "RVC Dry Tortugas"),
  index_measure = c("relative_abundance_index", "relative_abundance_index", "relative_biomass_index", "relative_biomass_index"),
  cv_measure = c("abundance_index_cv", "abundance_index_cv", "biomass_index_cv", "biomass_index_cv"),
  region = c("Florida", "Florida", "Florida Keys", "Dry Tortugas"),
  value_low = c(118, 211, 301, 400), value_high = c(164, 255, 349, 450),
  cv_low = c(165, 256, 350, 451), cv_high = c(210, 300, 400, 500),
  stringsAsFactors = FALSE)
index_count <- integer(nrow(index_specs))
index_years <- vector("list", nrow(index_specs))
for (j in seq_len(nrow(year_tokens))) {
  year <- as.integer(year_tokens$text[j])
  if (!year %in% 1991:2023) next
  row <- p25[abs(p25$y - year_tokens$y[j]) <= 1, , drop = FALSE]
  for (k in seq_len(nrow(index_specs))) {
    spec <- index_specs[k, ]
    parse_col <- function(low, high) {
      z <- row[row$x >= low & row$x < high & grepl("^[0-9]+(?:\\.[0-9]+)?$", row$text, perl = TRUE), , drop = FALSE]
      if (!nrow(z)) return(NA_real_)
      if (nrow(z) != 1L) stop("Ambiguous SEDAR 96 Table 25 cell at year ", year, call. = FALSE)
      number(z$text)
    }
    value <- parse_col(spec$value_low, spec$value_high)
    cv <- parse_col(spec$cv_low, spec$cv_high)
    if (xor(is.na(value), is.na(cv))) stop("Incomplete index/CV pair in SEDAR 96 Table 25 for ", spec$survey, " ", year, call. = FALSE)
    if (is.na(value)) next
    index_count[k] <- index_count[k] + 1L
    index_years[[k]] <- c(index_years[[k]], year)
    add_input("index", spec$index_measure, "index_scale", value, "relative index; source scale",
      "SEDAR 96 final report, Table 25", survey = spec$survey, region = spec$region,
      year = year, sampling_time = 0.5,
      notes = "Aggregate relative biomass or abundance index as labelled in Table 25. No physical multiplier is stated; the source scale is retained without conversion. The assessment configuration places observations at mid-year.")
    add_input("index", spec$cv_measure, "relative_scale", cv, "ratio",
      "SEDAR 96 final report, Table 25", survey = spec$survey, region = spec$region,
      year = year, sampling_time = 0.5,
      notes = "Source-reported coefficient of variation for the matching aggregate index; not an absolute standard error.")
  }
}
expected_index_years <- list(1993:2023, 1991:2023, c(1999:2012, 2014L, 2016L, 2018L, 2022L), c(1999L, 2000L, 2004L, 2006L, 2008L, 2010L, 2012L, 2014L, 2016L, 2018L, 2021L, 2023L))
if (!identical(index_years, expected_index_years)) {
  missing_years <- vapply(seq_along(index_years), function(k) paste(setdiff(expected_index_years[[k]], index_years[[k]]), collapse = ","), character(1L))
  stop("Unexpected SEDAR 96 Table 25 coverage: ", paste(missing_years, collapse = "; "), call. = FALSE)
}

# Table 28: annual biomass, abundance, and recruitment summaries.
tab28_lines <- trimws(strsplit(pages[[111L]], "\n", fixed = TRUE)[[1L]])
tab28_rows <- tab28_lines[grepl("^(?:199[2-9]|20[0-2][0-9])\\s", tab28_lines, perl = TRUE)]
tab28 <- do.call(rbind, lapply(tab28_rows, function(line) {
  fields <- strsplit(line, "\\s+", perl = TRUE)[[1L]]
  fields <- vapply(fields, number, numeric(1L))
  if (length(fields) != 9L) stop("Unexpected SEDAR 96 Table 28 row: ", line, call. = FALSE)
  fields
}))
if (nrow(tab28) != 32L || !identical(as.integer(tab28[, 1L]), 1992:2023))
  stop("SEDAR 96 Table 28 does not cover 1992-2023.", call. = FALSE)
for (j in seq_len(nrow(tab28))) {
  year <- as.integer(tab28[j, 1L])
  add_output("biomass", "total_biomass", tab28[j, 2L], "metric tons",
    "SEDAR 96 final report, Table 28", year,
    notes = "Source-reported total biomass; no interval is tabulated.")
  add_output("biomass", "SSB", tab28[j, 4L], "metric tons",
    "SEDAR 96 final report, Table 28", year, sex = "female",
    notes = "Source-reported female spawning stock biomass; no interval is tabulated.")
  add_output("population", "total_abundance", tab28[j, 6L], "1,000 fish",
    "SEDAR 96 final report, Table 28", year,
    notes = "Source-reported abundance in thousands of fish; no interval is tabulated.")
  add_output("recruitment", "recruitment", tab28[j, 7L], "1,000 age-0 fish",
    "SEDAR 96 final report, Table 28", year,
    notes = "Source-reported age-0 recruitment in thousands of fish; no interval is tabulated.")
}

# Table 29: age-4 fleet-combined F and fleet-specific apical F.
tab29_lines <- trimws(strsplit(pages[[112L]], "\n", fixed = TRUE)[[1L]])
tab29_rows <- tab29_lines[grepl("^(?:199[2-9]|20[0-2][0-9])\\s", tab29_lines, perl = TRUE)]
tab29 <- do.call(rbind, lapply(tab29_rows, function(line) {
  fields <- strsplit(line, "\\s+", perl = TRUE)[[1L]]
  fields <- vapply(fields, number, numeric(1L))
  if (length(fields) != 5L) stop("Unexpected SEDAR 96 Table 29 row: ", line, call. = FALSE)
  fields
}))
if (nrow(tab29) != 32L || !identical(as.integer(tab29[, 1L]), 1992:2023))
  stop("SEDAR 96 Table 29 does not cover 1992-2023.", call. = FALSE)
apical_fleets <- c("Commercial", "Headboat", "SRFS MRIP")
for (j in seq_len(nrow(tab29))) {
  year <- as.integer(tab29[j, 1L])
  add_output("mortality", "fishing_mortality_at_age", tab29[j, 2L], "yr-1",
    "SEDAR 96 final report, Table 29", year, age = 4L,
    notes = "Annual instantaneous F on age 4 combined across fleets; this is one age-specific value, not a complete F-at-age surface.")
  for (k in seq_along(apical_fleets)) add_output("mortality", "apical_F", tab29[j, k + 2L], "yr-1",
    "SEDAR 96 final report, Table 29", year, fleet = apical_fleets[k],
    notes = "Annual fleet-specific apical instantaneous F; not F-at-age for all ages.")
}

for (x in c(
  list(assumption_row("population", "model_domain", "1992-2023; age 0-20; one Florida area", "SEDAR 96 final report, assessment description and Tables 7-29", notes = "The report does not identify whether age 20 is a plus group.")),
  list(assumption_row("population", "model_family_version", "Stock Synthesis 3.30.15", "SEDAR 96 final report, model description")),
  list(assumption_row("population", "fishing_fleets", "Commercial; Headboat; SRFS MRIP", "SEDAR 96 final report, Tables 25-29")),
  list(assumption_row("index", "survey_index_series", "Commercial CPUE; MRIP; RVC Florida Keys; RVC Dry Tortugas", "SEDAR 96 final report, Table 25")),
  list(assumption_row("M", "natural_mortality_treatment", "Fixed age-specific Mat-age derived using Lorenzen (2005); target M=0.223 yr-1 for ages 3-20", "SEDAR 96 final report, Table 7", notes = "The report attributes the vector to SEDAR 64 and an external growth model; the vector is captured in inputs.csv.")),
  list(assumption_row("M", "external_growth_parameters", "Linf=42.3 cm fork length; k=0.207 yr-1; t0=-1.636 yr", "SEDAR 96 final report, Table 7")),
  list(assumption_row("biology", "maturity_treatment", "Fixed female maturity-at-age from logistic regression, carried from SEDAR 64", "SEDAR 96 final report, Table 7")),
  list(assumption_row("biology", "length_weight_relationship", "weight_kg = 2.574e-5 * fork_length_cm^2.8797", "SEDAR 96 final report, Table 2", notes = "The model estimates growth; this is the fixed length-weight relationship.")),
  list(assumption_row("index", "observation_timing", "0.5 (July 1)", "SEDAR 96 final report, model data configuration", notes = "The Dry Tortugas survey samples May-July; the model observation timing is mid-year."))
)) assumptions_list[[length(assumptions_list) + 1L]] <- x

francis <- data.frame(
  component = c(rep("length_composition", 5L), rep("age_composition", 3L), "conditional_age_at_length"),
  fleet = c("Commercial", "Headboat", "MRIP SRFS", "", "", "Commercial", "Headboat", "MRIP", ""),
  survey = c("", "", "", "RVC Florida Keys", "RVC Dry Tortugas", "", "", "", "Fishery-independent ages"),
  value = c(0.465232, 0.046876, 0.087468, 0.031747, 0.049979, 0.013936, 0.064705, 0.041647, 0.038818),
  stringsAsFactors = FALSE)
for (j in seq_len(nrow(francis))) add_assumption(francis$component[j], "Francis_weight", as.character(francis$value[j], digits = 7L),
  "SEDAR 96 final report, Table 26", fleet = francis$fleet[j], survey = francis$survey[j],
  notes = "Francis reweighting factor reported for the named composition data; not an observation standard error.")

inputs_new <- do.call(rbind, inputs_list)
outputs_new <- do.call(rbind, outputs_list)
assumptions_new <- do.call(rbind, assumptions_list)
inputs_new <- inputs_new[, input_columns, drop = FALSE]
outputs_new <- outputs_new[, output_columns, drop = FALSE]
assumptions_new <- assumptions_new[, assumption_columns, drop = FALSE]

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
stocks_current <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_current <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks_current$stock_id || assessment_id %in% assessments_current$assessment_id)
  stop("The yellowtail snapper stock or assessment has already been imported.", call. = FALSE)

stocks_new <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA",
  authority_stock_id = "11081", scientific_name = "Ocyurus chrysurus",
  common_name = "Yellowtail snapper - Southern Atlantic Coast / Gulf of Mexico",
  area = "Southeastern U.S. South Atlantic and Gulf of Mexico management stock; SEDAR 96 models Florida waters",
  region = "Southeastern U.S.", ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART 11081 is the single management stock shared by the South Atlantic and Gulf councils. SEDAR 96 is a one-area model for Florida waters.",
  stringsAsFactors = FALSE)
assessments_new_record <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2023L, estimate_terminal_year = 2023L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis", model_version = "3.30.15",
  is_current = TRUE, is_applied = TRUE, framework_year = 2025L,
  assessment_url = assessment_url, framework_url = framework_url, data_url = "",
  model_url = "", repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "2025 operational SEDAR 96 assessment, data through 2023. Verified report tables provide fixed biology, aggregate index/CV series, annual total and SSB, age-0 recruitment, age-4 F, and fleet-apical F. Public materials reviewed do not contain run-matched numeric catch compositions or a full N-at-age/F-at-age surface.",
  stringsAsFactors = FALSE)

candidate_path <- file.path(database, "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- match(candidate_id, candidates$candidate_id)
if (is.na(candidate_row) || candidates$match_status[candidate_row] != "new" || candidates$import_status[candidate_row] != "not_started")
  stop("The yellowtail candidate row is not in its reviewed pre-import state.", call. = FALSE)
candidates_new <- candidates[candidate_row, , drop = FALSE]
candidates_new$matched_stock_id <- stock_id
candidates_new$match_status <- "matched"
candidates_new$import_status <- "partial"
candidates_new$eligibility <- "unresolved"
candidates_new$catch_age_evidence <- "SEDAR 96 Table 7 fixed M and female maturity; Table 25 aggregate indices/CVs; Tables 28-29 population summaries/F outputs imported. Numeric fitted catch compositions are shown only in figures; no run-matched numeric catch-at-age vector was found."
candidates_new$survey_age_evidence <- "SEDAR 96 Table 25 aggregate commercial CPUE, MRIP, Florida Keys RVC biomass, and Dry Tortugas RVC biomass index series with CVs imported. No survey age composition tied to the RVC indices was recovered."
candidates_new$weights_evidence <- "Table 7 predicted fork length-at-age (0-20) imported; model growth is estimated and the fixed length-weight relationship is documented. No run-matched weight-at-age input matrix was recovered."
candidates_new$maturity_evidence <- "Fixed female maturity-at-age for ages 0-20 imported from Table 7."
candidates_new$mortality_evidence <- "Fixed age-specific Mat-age vector for ages 0-20 imported from Table 7; it uses an external Lorenzen derivation."
candidates_new$output_evidence <- "Tables 28-29 import annual total biomass, female SSB, abundance, age-0 recruitment, age-4 F and fleet-specific apical F for 1992-2023. No confidence intervals accompany these tables; annual N-at-age and a complete F-at-age surface are not tabulated."
candidates_new$decision_reason <- "Partial source records added for the latest fully accepted operational SEDAR 96 assessment. Eligibility remains unresolved because model-ready catch compositions, survey age inputs and numerical full N-at-age/F-at-age surfaces were not recovered."
candidates_new$notes <- "The stock is the single Southeast U.S. management unit shared by the South Atlantic and Gulf councils; SEDAR 96 models Florida waters. See source_reviews/noaa_yellowtail_snapper_11081.md for source interpretation and gaps."

append_csv <- function(data, path) {
  cols <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  if (!identical(cols, names(data))) stop("Column mismatch while appending ", path, call. = FALSE)
  write.table(data, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
}
if (write_mode) {
  if (nrow(inputs_new) != 0L && nrow(outputs_new) != 0L) {
    append_csv(stocks_new, stocks_path)
    append_csv(assessments_new_record, assessments_path)
    append_csv(assumptions_new, file.path(database, "assumptions.csv"))
    append_csv(inputs_new, file.path(database, "inputs.csv"))
    append_csv(outputs_new, file.path(database, "outputs.csv"))
    source(file.path(root, "scripts/shared/candidate_register_io.R"))
    replace_candidate_register_row(candidate_path, candidate_row, candidates_new, candidate_id)
  }
  cat("Imported NOAA Yellowtail Snapper SEDAR 96 (2025): ", nrow(inputs_new),
    " input rows, ", nrow(outputs_new), " output rows, and ", nrow(assumptions_new),
    " assumption rows.\n", sep = "")
} else {
  cat("Prepared NOAA Yellowtail Snapper SEDAR 96 (2025): ", nrow(inputs_new),
    " input rows, ", nrow(outputs_new), " output rows, and ", nrow(assumptions_new),
    " assumption rows. Use --write to append verified rows.\n", sep = "")
}





