root <- "."
cache <- file.path(root, "source_cache", "ices_herring_norwegian_spring_2026")
database <- file.path(root, "database")
assessment_id <- "ices_herring_norwegian_spring_2026"
report_url <- "https://doi.org/10.17895/ices.pub.33882730.v1"
benchmark_url <- "https://doi.org/10.17895/ices.pub.29279615"

age_tables <- data.table::fread(
  file.path(cache, "wgwide_2026_age_tables.csv"),
  na.strings = c("", "NA"), data.table = FALSE
)
summary_table <- data.table::fread(
  file.path(cache, "wgwide_2026_summary.csv"),
  na.strings = c("", "NA"), data.table = FALSE
)
if (!all(c("table_id", "year", "age", "value") %in% names(age_tables)) ||
    !identical(as.integer(summary_table$year), 1988:2026)) {
  stop("The cached WGWIDE 2026 table extractions are incomplete.", call. = FALSE)
}
age_tables$year <- as.integer(age_tables$year)
age_tables$age <- as.integer(age_tables$age)
age_tables$value <- suppressWarnings(as.numeric(age_tables$value))

read_age_table <- function(table_id, years, ages) {
  x <- age_tables[age_tables$table_id == table_id &
    age_tables$year %in% years & age_tables$age %in% ages,
    c("table_id", "year", "age", "value"), drop = FALSE]
  expected <- length(years) * length(ages)
  if (nrow(x) != expected || anyDuplicated(x[c("year", "age")]) ||
      !setequal(unique(x$year), years) || !setequal(unique(x$age), ages)) {
    stop("Unexpected year-age coverage in report table ", table_id,
      call. = FALSE)
  }
  x[order(x$year, x$age), , drop = FALSE]
}

input_path <- file.path(database, "inputs.csv")
output_path <- file.path(database, "outputs.csv")
assumption_path <- file.path(database, "assumptions.csv")
assessment_path <- file.path(database, "assessments.csv")
input_header <- names(data.table::fread(input_path, nrows = 0, data.table = FALSE))
output_header <- names(data.table::fread(output_path, nrows = 0, data.table = FALSE))
assumption_header <- names(data.table::fread(assumption_path, nrows = 0, data.table = FALSE))

assessments <- data.table::fread(assessment_path, colClasses = "character", data.table = FALSE)
if (sum(assessments$assessment_id == assessment_id) != 1L) {
  stop("Expected one existing summary-only 2026 assessment record.", call. = FALSE)
}
if (any(data.table::fread(input_path, select = "assessment_id", data.table = FALSE)$assessment_id == assessment_id)) {
  stop("2026 inputs are already present; refusing to duplicate them.", call. = FALSE)
}

append_rows <- function(path, rows) {
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    eol = "\r\n")
}

replace_assessment_rows <- function(path, rows) {
  tmp <- tempfile(pattern = "assessments-", tmpdir = database, fileext = ".csv")
  input <- file(path, open = "r")
  output <- file(tmp, open = "w")
  on.exit({ try(close(input), silent = TRUE); try(close(output), silent = TRUE); unlink(tmp) }, add = TRUE)
  writeLines(readLines(input, n = 1L, warn = FALSE), output, sep = "\r\n", useBytes = TRUE)
  ids <- rows$assessment_id
  repeat {
    lines <- readLines(input, n = 5000L, warn = FALSE)
    if (!length(lines)) break
    for (line in lines) {
      matched <- ids[vapply(ids, function(id) startsWith(line, paste0("\"", id, "\",")), logical(1))]
      if (length(matched)) {
        row <- rows[rows$assessment_id == matched[[1L]], , drop = FALSE]
        utils::write.table(row, output, sep = ",", quote = TRUE,
          row.names = FALSE, col.names = FALSE, na = "", eol = "\r\n")
      } else {
        writeLines(line, output, sep = "\r\n", useBytes = TRUE)
      }
    }
  }
  close(input)
  close(output)
  if (!file.copy(tmp, path, overwrite = TRUE)) stop("Could not update assessment records.", call. = FALSE)
  unlink(tmp)
}

replace_summary_outputs <- function(path, rows, id) {
  tmp <- tempfile(pattern = "outputs-", tmpdir = database, fileext = ".csv")
  input <- file(path, open = "r")
  output <- file(tmp, open = "w")
  on.exit({ try(close(input), silent = TRUE); try(close(output), silent = TRUE); unlink(tmp) }, add = TRUE)
  writeLines(readLines(input, n = 1L, warn = FALSE), output, sep = "\r\n", useBytes = TRUE)
  prefix <- paste0("\"", id, "\",")
  keep_prefix <- paste0("\"", id, "\",\"biomass\",\"total_biomass\",")
  repeat {
    lines <- readLines(input, n = 5000L, warn = FALSE)
    if (!length(lines)) break
    keep <- !startsWith(lines, prefix) | startsWith(lines, keep_prefix)
    writeLines(lines[keep], output, sep = "\r\n", useBytes = TRUE)
  }
  close(input)
  close(output)
  append <- rows
  for (column in c("year", "age", "value", "se", "lwr", "upr")) {
    append[[column]] <- suppressWarnings(as.numeric(append[[column]]))
  }
  utils::write.table(append, tmp, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    eol = "\r\n")
  if (!file.copy(tmp, path, overwrite = TRUE)) stop("Could not update output records.", call. = FALSE)
  unlink(tmp)
}

new_input <- function(type, measure, basis, year = NA_integer_, age = NA_integer_,
                      value, unit, survey = NA_character_, fleet = NA_character_,
                      season = NA_character_, sampling_time = NA_real_,
                      year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
                      source_type = "official_table", source_reference,
                      transformation = "Transcribed from the 2026 official assessment report.",
                      notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(input_header)),
    stringsAsFactors = FALSE)
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$year <- as.character(rep(year, length.out = n))
  out$year_basis <- as.character(rep(year_basis, length.out = n))
  out$age <- as.character(rep(age, length.out = n))
  out$value <- as.character(value)
  out$unit <- unit
  out$survey <- as.character(rep(survey, length.out = n))
  out$fleet <- as.character(rep(fleet, length.out = n))
  out$season <- as.character(rep(season, length.out = n))
  out$sampling_time <- as.character(rep(sampling_time, length.out = n))
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out[!is.na(value), , drop = FALSE]
}

new_output <- function(type, measure, year, value, unit, age = NA_integer_,
                       age_group = NA_character_, lwr = NA_real_, upr = NA_real_,
                       source_type = "official_table", source_reference, notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE)
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(rep(year, length.out = n))
  out$age <- as.character(rep(age, length.out = n))
  out$age_group <- as.character(rep(age_group, length.out = n))
  out$value <- as.character(value)
  out$lwr <- as.character(rep(lwr, length.out = n))
  out$upr <- as.character(rep(upr, length.out = n))
  out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$notes <- notes
  out[!is.na(value), , drop = FALSE]
}

new_assumption <- function(component, setting, value, source_reference, notes = "") {
  out <- as.data.frame(matrix(NA_character_, nrow = 1L,
    ncol = length(assumption_header)), stringsAsFactors = FALSE)
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

source_inputs <- list()
add_age_input <- function(table_id, years, ages, type, measure, basis, unit,
                          reference, year_basis = "calendar_year", notes = "") {
  x <- read_age_table(table_id, years, ages)
  source_inputs[[length(source_inputs) + 1L]] <<- new_input(
    type, measure, basis, x$year, x$age, x$value, unit,
    year_basis = year_basis,
    source_reference = paste(report_url, "Table", table_id),
    notes = notes
  )
}

fit_years <- 1988:2025
model_ages <- 2:12
source_ages <- 2:15
add_age_input("4.4.3.1", fit_years, source_ages, "catch", "numbers_at_age",
  "numbers", "thousand fish", report_url,
  notes = "Source age groups 0-14 and 15+ are retained as ages 0-15; translation combines ages above 12 into 12+.")
add_age_input("4.4.4.1", fit_years, source_ages, "catch_weight", "weight_at_age",
  "kg_per_fish", "kg per fish", report_url,
  notes = "Catch weight at age, reported in the source age groups.")
add_age_input("4.4.4.2", 1988:2026, source_ages, "weight", "weight_at_age",
  "kg_per_fish", "kg per fish", report_url,
  notes = "Annual stock weight at age. The report age group 15+ is stored as age 15.")
add_age_input("4.4.5.1", 1950:2026, source_ages, "maturity", "maturity_at_age",
  "proportion", "proportion", report_url, year_basis = "birth_cohort",
  notes = "Rows are birth cohorts as described in the report; age group 15+ is stored as age 15.")
source_inputs[[length(source_inputs) + 1L]] <- new_input(
  "M", "natural_mortality_at_age", "per_year", NA_integer_, source_ages,
  c(0.9, rep(0.15, length(source_ages) - 1L)), "per year",
  year_basis = NA_character_, source_type = "official_document",
  source_reference = paste(report_url, "section 4.4.6"),
  notes = "The report gives standard M=0.9 at age 2 and M=0.15 at ages 3+. It also refers to annual stock-annex deviations that are not recovered here."
)

add_index <- function(table_id, years, ages, survey, season, timing, unit, note) {
  x <- read_age_table(table_id, years, ages)
  x <- x[!is.na(x$value), , drop = FALSE]
  source_inputs[[length(source_inputs) + 1L]] <<- new_input(
    "index", "numbers_at_age", "numbers", x$year, x$age, x$value, unit,
    survey = survey, season = season, sampling_time = timing,
    source_reference = paste(report_url, "Table", table_id),
    transformation = "Direct age-specific abundance estimate copied from the report table.",
    notes = note
  )
}
add_index("4.4.7.1", c(1988:2008, 2015:2026), 3:12,
  "NASF_1988_2008", "February-March", 0.13, "billion fish",
  "Spawning-ground acoustic survey; the 2015-onward values are stored as a separate series.")
# Reassign post-2014 NASF rows to their separate series.
nasf_index <- source_inputs[[length(source_inputs)]]
nasf_index$survey[nasf_index$year %in% as.character(2015:2026)] <- "NASF_2015_onward"
source_inputs[[length(source_inputs)]] <- nasf_index
add_index("4.4.7.2", 1991:2026, 2L, "IESNS_Barents", "May-June", 0.42,
  "billion fish", "The abundance table lists ages 1-5; the SAM relative-error table supplies age 2 only, so the fitted age-2 input is retained.")
add_index("4.4.7.3", 1996:2026, 3:12, "IESNS_Norwegian_Sea", "May", 0.38,
  "million fish", "International acoustic survey in the Norwegian Sea.")
add_index("4.4.7.4", 2004:2025, 2:3, "BESS", "August-October", 0.75,
  "billion fish", "BESS values are copied from the 2026 report, following the benchmark-recalculated series used for the 2026 assessment.")

add_rse <- function(table_id, years, ages, survey = NA_character_, fleet = NA_character_) {
  x <- read_age_table(table_id, years, ages)
  x <- x[!is.na(x$value), , drop = FALSE]
  source_inputs[[length(source_inputs) + 1L]] <<- new_input(
    if (is.na(survey)) "catch" else "index", "relative_standard_error",
    "relative_scale", x$year, x$age, x$value, "relative standard error",
    survey = survey, fleet = fleet,
    source_reference = paste(report_url, "Table", table_id),
    transformation = "Relative standard errors are retained as published.",
    notes = "Sampling precision for the official assessment input, not an abundance observation."
  )
}
add_rse("4.4.8.1", 1988:2025, 2:12, fleet = "Total catch")
add_rse("4.4.8.2", 1988:2008, 3:12, survey = "NASF_1988_2008")
add_rse("4.4.8.2", 2015:2026, 3:12, survey = "NASF_2015_onward")
add_rse("4.4.8.3", 1991:2026, 2L, survey = "IESNS_Barents")
add_rse("4.4.8.4", 1996:2026, 3:12, survey = "IESNS_Norwegian_Sea")
add_rse("4.4.8.5", 2017:2025, 3:12, survey = "RFID")
inputs <- data.table::rbindlist(source_inputs, use.names = TRUE, fill = TRUE)
if (!identical(names(inputs), input_header) || anyNA(inputs$value)) {
  stop("The generated 2026 input rows do not match the database schema.", call. = FALSE)
}

new_outputs <- list()
n_surface <- read_age_table("4.5.1.2", 1988:2026, model_ages)
f_surface <- read_age_table("4.5.1.3", 1988:2026, model_ages)
new_outputs[[1L]] <- new_output(
  "population", "numbers_at_age", n_surface$year, n_surface$value,
  "million fish", age = n_surface$age,
  age_group = ifelse(n_surface$age == 12L, "12+", NA_character_),
  source_reference = paste(report_url, "Table 4.5.1.2"),
  notes = "Point estimates from the official SAM report table; age-specific uncertainty was not tabulated."
)
new_outputs[[2L]] <- new_output(
  "mortality", "fishing_mortality_at_age", f_surface$year, f_surface$value,
  "per year", age = f_surface$age,
  age_group = ifelse(f_surface$age == 12L, "12+", NA_character_),
  source_reference = paste(report_url, "Table 4.5.1.3"),
  notes = "Point estimates from the official SAM report table; age-specific uncertainty was not tabulated."
)
n_total <- aggregate(value ~ year, n_surface, sum)
new_outputs[[3L]] <- new_output(
  "population", "total_abundance", n_total$year, n_total$value,
  "million fish", source_type = "derived_source_output",
  source_reference = paste(report_url, "Table 4.5.1.2"),
  notes = "Derived by summing reported abundance across ages 2-12+; uncertainty is unavailable."
)
summary <- summary_table
new_outputs[[4L]] <- new_output(
  "recruitment", "recruitment", summary$year, summary$recruitment_millions,
  "million fish", age = 2L, lwr = summary$recruitment_low,
  upr = summary$recruitment_high,
  source_reference = paste(report_url, "Table 4.5.1.4"),
  notes = "Approximate 95% confidence limits; recruitment is at age 2."
)
new_outputs[[5L]] <- new_output(
  "biomass", "SSB", summary$year, summary$ssb_thousand_tonnes,
  "thousand tonnes", lwr = summary$ssb_low, upr = summary$ssb_high,
  source_reference = paste(report_url, "Table 4.5.1.4"),
  notes = "Approximate 95% confidence limits copied from the report."
)
new_outputs[[6L]] <- new_output(
  "catch", "total_biomass", summary$year, summary$catch_tonnes,
  "tonnes", source_reference = paste(report_url, "Table 4.5.1.4"),
  notes = "Annual total catch; catch-at-age remains the key assessment input."
)
new_outputs[[7L]] <- new_output(
  "mortality", "Fbar", summary$year, summary$fbar_5_12,
  "per year", age_group = "5-12+", lwr = summary$fbar_low,
  upr = summary$fbar_high,
  source_reference = paste(report_url, "Table 4.5.1.4"),
  notes = "The report labels the ages 5-12; age 12 is its 12+ model group. Limits are approximate 95% confidence limits."
)
outputs <- data.table::rbindlist(new_outputs, use.names = TRUE, fill = TRUE)
if (!identical(names(outputs), output_header)) {
  stop("The generated 2026 output rows do not match the database schema.", call. = FALSE)
}

assumptions <- data.table::rbindlist(list(
  new_assumption("assessment", "assessment_type", "Annual official assessment", report_url),
  new_assumption("assessment", "model_family", "SAM", report_url),
  new_assumption("assessment", "model_version", "WGWIDE 2026 final assessment; SAM options from WKBMACNSSH 2025", report_url,
    "The report says the 2026 assessment uses the 2025 benchmark model options."),
  new_assumption("assessment", "framework_year", "2025", benchmark_url),
  new_assumption("population", "model_years", "1988-2025", report_url,
    "Catch-at-age is fitted through 2025; N, F, and summary estimates extend through 2026."),
  new_assumption("population", "model_ages", "2-12+", report_url),
  new_assumption("population", "recruitment_age", "2", report_url),
  new_assumption("population", "plus_group_age", "12", report_url),
  new_assumption("catch", "catch_streams", "One aggregate catch-at-age series", report_url),
  new_assumption("catch", "observation_error", "Relative standard errors by year and age", report_url,
    "Values in Table 4.4.8.1 are retained; the 2026 report says other inputs were weighted using the standard relative-error tables."),
  new_assumption("F", "process", "SAM state-space F process; exact transition keys unresolved", benchmark_url,
    "The 2026 report states that 2025 benchmark model options were retained; the native configuration was not recovered."),
  new_assumption("F", "Fbar_ages", "5-12+", report_url,
    "The summary table labels the group ages 5-12; age 12 is the 12+ model group."),
  new_assumption("N", "process", "SAM state-space abundance process; exact transition keys unresolved", benchmark_url,
    "The native configuration was not recovered."),
  new_assumption("M", "natural_mortality", "0.9 at age 2; 0.15 at ages 3+", report_url,
    "Annual stock-annex M deviations are referred to but were not recovered."),
  new_assumption("maturity", "maturity_basis", "Birth cohort by age", report_url),
  new_assumption("weight", "stock_weight", "Annual stock weight-at-age", report_url),
  new_assumption("weight", "catch_weight", "Annual catch weight-at-age", report_url),
  new_assumption("index", "surveys", "NASF, IESNS Barents, IESNS Norwegian Sea, BESS, and RFID", report_url,
    "RFID numerical point estimates remain figure-only; relative errors are tabulated."),
  new_assumption("index", "BESS_weighting", "Benchmark-recalculated index values used in the 2026 assessment", report_url,
    "Permission to use the recalculated BESS index was available for WGWIDE 2026; it had not been available for WGWIDE 2025."),
  new_assumption("index", "IESNS_Barents_model_age", "2", report_url,
    "The table lists ages 1-5, but the SAM relative-error table specifies age 2 only."),
  new_assumption("index", "survey_timing", "Approximate seasonal midpoints", report_url,
    "NASF 0.13; IESNS Barents 0.42; IESNS Norwegian Sea 0.38; BESS 0.75."),
  new_assumption("index", "catchability_structure", "Unknown", benchmark_url,
    "The report refers to benchmark options; native sharing keys were not recovered."),
  new_assumption("uncertainty", "reported_intervals", "Approximate 95% confidence limits for recruitment, SSB, and Fbar", report_url,
    "Age-specific N and F uncertainty is not tabulated; total abundance is derived without uncertainty."),
  new_assumption("assessment", "native_fit", "Not recovered", report_url,
    "The detailed production report and ICES Stock Assessment Graphs provide data, but not the fitted object or full native configuration.")
), use.names = TRUE, fill = TRUE)

assessments$assessment_year[assessments$assessment_id == assessment_id] <- "2026"
assessments$terminal_year[assessments$assessment_id == assessment_id] <- "2025"
assessments$estimate_terminal_year[assessments$assessment_id == assessment_id] <- "2026"
assessments$assessment_type[assessments$assessment_id == assessment_id] <- "annual_assessment"
assessments$model_family[assessments$assessment_id == assessment_id] <- "SAM"
assessments$model_version[assessments$assessment_id == assessment_id] <- "WGWIDE 2026 final assessment; SAM with WKBMACNSSH 2025 options"
assessments$is_current[assessments$assessment_id == assessment_id] <- "TRUE"
assessments$framework_year[assessments$assessment_id == assessment_id] <- "2025"
assessments$assessment_url[assessments$assessment_id == assessment_id] <- report_url
assessments$data_url[assessments$assessment_id == assessment_id] <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25912"
assessments$assumptions_status[assessments$assessment_id == assessment_id] <- "partial"
assessments$inputs_status[assessments$assessment_id == assessment_id] <- "partial"
assessments$outputs_status[assessments$assessment_id == assessment_id] <- "partial"
assessments$notes[assessments$assessment_id == assessment_id] <- paste(
  "Most recent official assessment with detailed inputs and outputs recovered from WGWIDE 2026.",
  "Catch inputs extend through 2025; N, F, and summary estimates through 2026.",
  "Missing numerical RFID index values, annual stock-annex M deviations, full native configuration, and age-specific output uncertainty remain unresolved."
)
previous_id <- "ices_herring_norwegian_spring_2025"
assessments$is_current[assessments$assessment_id == previous_id] <- "FALSE"
assessments$notes[assessments$assessment_id == previous_id] <- paste(
  "Prior official assessment with detailed 2025 report inputs and outputs; superseded by the separate WGWIDE 2026 assessment record."
)

for (x in list(inputs, outputs, assumptions)) {
  if (anyNA(x$assessment_id) || any(x$assessment_id != assessment_id)) {
    stop("Generated rows have an unexpected assessment identifier.", call. = FALSE)
  }
}

replace_assessment_rows(
  assessment_path,
  assessments[assessments$assessment_id %in% c(assessment_id, previous_id), , drop = FALSE]
)
replace_summary_outputs(output_path, outputs, assessment_id)
append_rows(input_path, inputs)
append_rows(assumption_path, assumptions)

cat("Added", nrow(inputs), "2026 input rows and", nrow(outputs),
  "detailed/derived output rows; retained the SAG total-biomass series.\n")
