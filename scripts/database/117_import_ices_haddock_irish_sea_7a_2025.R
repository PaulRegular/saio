assessment_id <- "ices_haddock_irish_sea_7a_2025"
advice_id <- "ices_haddock_irish_sea_7a_2026_summary"
stock_id <- "ck_ices_wgcse_aeglefinus_cs7a"
root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", stock_id)
assessment_cache <- file.path(cache, "assessment_2025")
framework_cache <- file.path(cache, "framework")
report_ref <- "https://doi.org/10.17895/ices.pub.32625759"
framework_ref <- "https://doi.org/10.17895/ices.pub.8713"
sag_ref <- "https://sg.ices.dk/ViewSourceData.aspx?key=19850"
advice_ref <- "https://doi.org/10.17895/ices.advice.30932069"

required_files <- file.path(assessment_cache, c(
  "WGCSE_2025_haddock_7a.txt", "ices_sag_2025_haddock_7a.xml",
  "WKIrish2_2016.txt"
))
if (any(!file.exists(required_files))) {
  stop("Cache the pinned ICES report, SAG data and M reference before importing.", call. = FALSE)
}

read_table <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}
append_rows <- function(name, rows, id_column = "assessment_id", id_value = assessment_id) {
  path <- file.path(database, name)
  existing <- read_table(name)
  if (!identical(names(existing), names(rows))) {
    stop("Unexpected columns in ", name, call. = FALSE)
  }
  if (any(existing[[id_column]] == id_value, na.rm = TRUE)) {
    stop("Rows already exist for ", id_value, " in ", name, call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}
format_value <- function(x) {
  ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
}
lines <- readLines(file.path(assessment_cache, "WGCSE_2025_haddock_7a.txt"), warn = FALSE)
matrix_rows <- function(section, years, n_values) {
  rows <- list()
  for (line in section) {
    line <- trimws(line)
    if (!grepl("^(19|20)[0-9]{2}\\*?\\s", line)) next
    fields <- strsplit(line, "\\s+")[[1L]]
    year <- as.integer(sub("\\*$", "", fields[[1L]]))
    values <- fields[-1L]
    if (!year %in% years) next
    if (length(values) != n_values) {
      stop("Unexpected number of table cells for year ", year, ": ", line, call. = FALSE)
    }
    values[values %in% c("-", "NA")] <- NA_character_
    parsed <- suppressWarnings(as.numeric(values))
    if (any(!is.na(values) & !is.finite(parsed))) {
      stop("Non-numeric value in table row: ", line, call. = FALSE)
    }
    rows[[as.character(year)]] <- c(year = year, parsed)
  }
  if (!setequal(names(rows), as.character(years))) {
    stop("Table year coverage does not match the expected years.", call. = FALSE)
  }
  out <- do.call(rbind, rows[as.character(years)])
  storage.mode(out) <- "numeric"
  out
}
table_section <- function(start, end) {
  first <- grep(start, lines, perl = TRUE)
  if (length(first) != 1L) stop("Could not uniquely locate table section: ", start)
  next_line <- grep(end, lines[(first + 1L):length(lines)], perl = TRUE)
  last <- if (length(next_line)) first + next_line[[1L]] - 1L else length(lines)
  lines[first:last]
}
subsection <- function(text, start, end) {
  first <- grep(start, text, perl = TRUE)
  if (length(first) != 1L) stop("Could not uniquely locate subsection: ", start)
  next_line <- grep(end, text[(first + 1L):length(text)], perl = TRUE)
  last <- if (length(next_line)) first + next_line[[1L]] - 1L else length(text)
  text[first:last]
}

stock_rows <- read_table("stocks.csv")
stock_index <- match(stock_id, stock_rows$stock_id)
if (is.na(stock_index) || (!is.na(stock_rows$common_name[[stock_index]]) &&
  nzchar(stock_rows$common_name[[stock_index]]))) {
  stop("Expected an unpopulated Charbonneau-Keith stock row.", call. = FALSE)
}
assessment_rows <- read_table("assessments.csv")
if (any(assessment_rows$assessment_id %in% c(assessment_id, advice_id))) {
  stop("Assessment or advice records already exist.", call. = FALSE)
}

years <- 1993:2024
ages <- 0:5
weight_section <- table_section("Table 9\\.3\\. Haddock in 7\\.a: stock weights-at-age", "Table 9\\.4\\.")
catch_section <- table_section("Table 9\\.4\\. Haddock in 7\\.a: Catch numbers-at-age", "Table 9\\.5\\.")
weight <- matrix_rows(weight_section, years, length(ages))
catch <- matrix_rows(catch_section, years, length(ages))

survey_table <- table_section("Table 9\\.5\\. Haddock in 7\\.a: Available tuning data", "Table 9\\.7\\.")
q1 <- matrix_rows(subsection(survey_table, "NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4"), 1993:2024, 5L)
q4 <- matrix_rows(subsection(survey_table, "NIGFS-WIBTS-Q4", "NIMIK"), 1994:2024, 5L)
mik <- matrix_rows(subsection(survey_table, "NIMIK", "FSP Haddock"), 1994:2024, 1L)
fsp <- matrix_rows(subsection(survey_table, "FSP Haddock", "Proportion mature at age"), 2005:2024, 5L)
maturity <- matrix_rows(subsection(survey_table, "Proportion mature at age", "Table 9\\.7\\."), years, 6L)
if (sum(is.na(q4[, -1L])) != 5L || sum(is.na(mik[, -1L])) != 2L ||
  sum(is.na(fsp[, -1L])) != 5L || any(!is.finite(weight[, -1L])) ||
  any(!is.finite(catch[, -1L])) || any(!is.finite(maturity[, -1L]))) {
  stop("Unexpected missingness in the official source tables.", call. = FALSE)
}

output_section <- table_section("Table 9\\.8\\. Haddock in Division 7\\.a\\. Assessment summary", "Table 9\\.9\\.")
official_output <- matrix_rows(output_section, years, 11L)
if (!identical(dim(official_output), c(length(years), 12L))) {
  stop("Unexpected Table 9.8 dimensions.", call. = FALSE)
}

input_header <- names(read_table("inputs.csv"))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       survey = "", region = "", season = "", sampling_time = NA_real_,
                       source_reference = report_ref, source_type = "official_table",
                       transformation = "Transcribed from the cited ICES table.", notes = "",
                       year_basis = NULL) {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_header)), stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$survey <- rep_len(survey, n)
  out$region <- rep_len(region, n)
  out$season <- rep_len(season, n)
  out$year <- ifelse(is.na(year), "", as.character(rep_len(year, n)))
  if (is.null(year_basis)) year_basis <- ifelse(is.na(year), "", "calendar_year")
  out$year_basis <- rep_len(year_basis, n)
  out$age <- ifelse(is.na(age), "", as.character(rep_len(age, n)))
  out$value <- format_value(rep_len(value, n))
  out$unit <- unit
  out$sampling_time <- ifelse(is.na(sampling_time), "", as.character(rep_len(sampling_time, n)))
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}
to_long <- function(x, ages) {
  out <- expand.grid(age = ages, row = seq_len(nrow(x)))
  out$year <- x[out$row, 1L]
  out$value <- x[cbind(out$row, match(out$age, ages) + 1L)]
  out
}
long_input <- function(x, type, measure, basis, unit, ages, ...) {
  z <- to_long(x, ages)
  input_rows(type, measure, basis, z$year, z$age, z$value, unit, ...)
}
inputs <- rbind(
  long_input(catch, "catch", "numbers_at_age", "numbers", "thousand fish", ages,
    transformation = "Table 9.4 values were recorded on the reported scale; the table does not state the count multiplier.",
    notes = "Thousands of fish is inferred from the reported values and assessment summaries; the original table does not print a unit. 2003 composition was flagged by the report as based on inadequate sampling."),
  long_input(weight, "weight", "weight_at_age", "kg_per_fish", "kg per fish (inferred)", ages,
    transformation = "Copied from Table 9.3.",
    notes = "The report does not print the unit; kg per fish is inferred from the magnitude and stock-weight convention."),
  long_input(maturity, "maturity", "maturity_at_age", "proportion", "proportion", ages,
    transformation = "Copied from Table 9.6; the 5+ column is stored at age 5.",
    notes = "Female maturity at age. Report describes these as survey-based proportions smoothed with LOWESS."),
  input_rows("index", "numbers_at_age", "index_scale", rep(q1[, 1L], each = 5), rep(1:5, times = nrow(q1)), as.vector(t(q1[, -1L])), "survey index (unit unresolved)", survey = "NIGFS-WIBTS-Q1", season = "Q1", sampling_time = 0.2,
    transformation = "Copied from Table 9.5; no multiplier applied.", notes = "The model uses ages 1-4; source table retains ages 1-5. Zero values are preserved."),
  input_rows("index", "numbers_at_age", "index_scale", rep(q4[, 1L], each = 5), rep(0:4, times = nrow(q4)), as.vector(t(q4[, -1L])), "survey index (unit unresolved)", survey = "NIGFS-WIBTS-Q4", season = "Q4", sampling_time = 0.8,
    transformation = "Copied from Table 9.5; missing 2024 observations remain missing.", notes = "The model uses ages 0-3; source table retains ages 0-4."),
  input_rows("index", "numbers_at_age", "index_scale", mik[, 1L], 0L, mik[, 2L], "survey index (unit unresolved)", survey = "NI-MIK", season = "summer", sampling_time = 0.5,
    transformation = "Copied from Table 9.5; NA values retained.", notes = "Age-0 recruitment index; the report describes the survey as June while model settings list month 7."),
  input_rows("index", "numbers_at_age", "index_scale", rep(fsp[, 1L], each = 5), rep(1:5, times = nrow(fsp)), as.vector(t(fsp[, -1L])), "survey index (unit unresolved)", survey = "UK-FSPW", region = "Western Irish Sea", season = "Q1", sampling_time = 0.2,
    transformation = "Copied from Table 9.5; 2014 missing sample remains NA.", notes = "The model uses ages 2-5; source table retains ages 1-5.")
)

m_text <- readLines(file.path(assessment_cache, "WKIrish2_2016.txt"), warn = FALSE)
m_table_line <- grep("Table 6\\.2\\.3\\. Estimates for M as calculated by Gislason et al\\. and Lorenz", m_text)
if (length(m_table_line) != 1L) stop("Could not locate the cited Lorenzen M table.")
m_section <- m_text[m_table_line[[1L]]:min(length(m_text), m_table_line[[1L]] + 35L)]
m_rows <- lapply(m_section, function(line) {
  fields <- strsplit(trimws(line), "\\s+")[[1L]]
  if (length(fields) < 5L || !grepl("^[0-7]$", fields[[1L]])) return(NULL)
  c(age = as.integer(fields[[1L]]), M = as.numeric(fields[[5L]]))
})
m_rows <- do.call(rbind, Filter(Negate(is.null), m_rows))
if (!identical(as.integer(m_rows[, "age"]), 0:7) ||
  !isTRUE(all.equal(as.numeric(m_rows[, "M"]), c(2.44, 0.918, 0.621, 0.494, 0.424, 0.38, 0.35, 0.329)))) {
  stop("Unexpected Lorenzen M values in the cited source.", call. = FALSE)
}
  inputs <- rbind(inputs, input_rows("M", "natural_mortality_at_age", "per_year",
  rep(NA_integer_, 6L), 0:5, as.numeric(m_rows[1:6, "M"]), "per year",
  source_reference = paste0(framework_ref, "; WKIrish2 2016, Table 6.2.3"),
  source_type = "reconstructed_source_input",
  transformation = "Copied ages 0-5 from the 2016 Lorenzen estimates cited as the source method for M in the 2025 assessment.",
  notes = "The 2025 report says M was calculated using Lorenzen (1996) at WKIrish2; the 2017 benchmark selected unscaled Lorenzen estimates. The exact values retained in the 2025 ASAP fit are unavailable, so these older values are a documented approximation, not verified native inputs.", year_basis = ""))

output_header <- names(read_table("outputs.csv"))
output_rows <- function(measure, year, value, unit, age = NA_integer_, age_group = "", lwr = NA_real_, upr = NA_real_, notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)), stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- if (measure == "SSB") "biomass" else if (measure == "recruitment") "recruitment" else if (measure == "Fbar") "mortality" else "catch"
  out$measure <- measure
  out$year <- as.character(year)
  out$age <- ifelse(is.na(age), "", as.character(age))
  if ("age_group" %in% names(out)) out$age_group <- age_group
  out$value <- format_value(value)
  out$unit <- unit
  out$lwr <- format_value(lwr)
  out$upr <- format_value(upr)
  out$source_type <- "official_table"
  out$source_reference <- report_ref
  out$notes <- notes
  out
}
output_notes <- "Table 9.8 point estimate and 95% confidence limits."
outputs <- rbind(
  output_rows("recruitment", years, official_output[, 3L], "thousand fish", age = 0L,
    lwr = official_output[, 2L], upr = official_output[, 4L], notes = output_notes),
  output_rows("SSB", years, official_output[, 6L], "tonnes",
    lwr = official_output[, 5L], upr = official_output[, 7L], notes = output_notes),
  output_rows("Fbar", years, official_output[, 11L], "per year", age_group = "2-4",
    lwr = official_output[, 10L], upr = official_output[, 12L], notes = "Fbar ages 2-4; Table 9.8 reports 95% confidence limits."),
  output_rows("landings", years, official_output[, 8L], "tonnes", notes = "Official assessment summary; not an estimated abundance metric."),
  output_rows("discards", years, official_output[, 9L], "tonnes", notes = "Available from 2007; earlier values reflect limited sampling and are retained as reported.")
)

assumption_header <- names(read_table("assumptions.csv"))
assumption_rows <- function(setting, value, source_reference = report_ref, notes = "") {
  out <- as.data.frame(matrix("", nrow = length(setting), ncol = length(assumption_header)), stringsAsFactors = FALSE)
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- "assessment"
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}
assumptions <- assumption_rows(
  c("model_family", "fbar_ages", "fleet_structure", "fleet_selectivity", "discards", "index_units", "index_months", "index_ages", "index_selectivity", "index_cv_ess", "catch_cv", "catch_effective_sample_size", "recruitment_deviation_cv", "natural_mortality", "maturity"),
  c("Single-fleet ASAP", "2-4", "One combined fleet", "Four time blocks; age-specific/selectivity forms vary by block", "Included in catch; not modelled separately from landings", "Numbers (index multiplier not stated)", "NIGFS-Q1 3; NIGFS-Q4 10; NI-MIK 7; UK-FSPW 3", "Q1 ages 1-4; Q4 ages 0-3; NI-MIK age 0; UK-FSPW ages 2-5", "Q1 double logistic; other age-based indices asymptotic; NI-MIK age 0 only", "Q1/Q4/NI-MIK observed-strata or station CV, lower limit 0.1, ESS 50 with specified recent exceptions; UK-FSPW CV 0.7, ESS 10", "1993-2000 0.175; 2003-2006 0.2; 2007-2019 0.15; 2020 0.175; 2021-2024 0.15", "1993-2000 50; 2003-2006 1; 2007-2019 50; 2020 1; 2021-2022 50; 2023 45; 2024 40", "CV 1", "Lorenzen (1996); exact 2025 ASAP values unavailable", "Annual female maturity-at-age; survey-based proportions smoothed with LOWESS"),
  notes = "Transcribed from the model settings in section 9.2 of the 2025 assessment report. The exact 2025 native ASAP fit/configuration was not recovered; settings are report-documented." )

advice_rows <- read_table("assessments.csv")[FALSE, , drop = FALSE]
advice_rows[1L, ] <- ""
advice_rows$assessment_id <- advice_id
advice_rows$stock_id <- stock_id
advice_rows$assessment_year <- "2026"
advice_rows$terminal_year <- "2026"
advice_rows$estimate_terminal_year <- ""
advice_rows$assessment_type <- "assessment_update"
advice_rows$model_family <- "ICES category 5 advice"
advice_rows$model_version <- "Catch-only advice"
advice_rows$is_current <- "FALSE"
advice_rows$is_applied <- "TRUE"
advice_rows$assessment_url <- advice_ref
advice_rows$assumptions_status <- "partial"
advice_rows$inputs_status <- "not_applicable"
advice_rows$outputs_status <- "partial"
advice_rows$notes <- "Current 2026 category-5 advice; retained separately from the detailed 2025 age-structured ASAP assessment. Catch advice is 586 tonnes in each of 2027 and 2028; no age-structured inputs or stock outputs are provided."
advice_outputs <- output_rows("catch_advice", c(2027L, 2028L), c(586, 586), "tonnes",
  notes = "ICES category-5 catch advice; no age-structured model output.")
advice_outputs$assessment_id <- advice_id
advice_outputs$source_reference <- advice_ref

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = "2025",
  terminal_year = "2024", estimate_terminal_year = "2024", assessment_type = "full_assessment",
  model_family = "ASAP", model_version = "2025 assessment; detailed source report published as WGCSE 2026",
  is_current = "TRUE", is_applied = "TRUE", framework_year = "2017",
  assessment_url = report_ref, framework_url = framework_ref, data_url = sag_ref,
  model_url = "", repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial", notes = "Latest detailed age-structured assessment located; the 2026 advice is a separate category-5 catch-only update. Inputs include Tables 9.3-9.6 and report-documented settings. Native ASAP configuration was unavailable. M values are reconstructed from WKIrish2 2016 Lorenzen estimates and not verified against the final fit. Output tables provide aggregate recruitment, SSB and Fbar only; N-at-age, F-at-age and their uncertainty are unavailable.",
  stringsAsFactors = FALSE
)

stock_rows$common_name[[stock_index]] <- "Irish Sea haddock"
stock_rows$notes[[stock_index]] <- paste(
  stock_rows$notes[[stock_index]],
  "Official detailed 2025 age-structured assessment added as ices_haddock_irish_sea_7a_2025; current 2026 category-5 advice is recorded separately.",
  sep = " "
)
utils::write.table(stock_rows, file.path(database, "stocks.csv"), sep = ",", quote = TRUE, row.names = FALSE, na = "")
append_rows("assessments.csv", assessment_row)
append_rows("assessments.csv", advice_rows, id_value = advice_id)
append_rows("assumptions.csv", assumptions)
append_rows("inputs.csv", inputs)
append_rows("outputs.csv", outputs)
append_rows("outputs.csv", advice_outputs, id_value = advice_id)

message("Imported ", nrow(inputs), " input rows, ", nrow(assumptions),
  " settings, and ", nrow(outputs) + nrow(advice_outputs), " output rows.")
