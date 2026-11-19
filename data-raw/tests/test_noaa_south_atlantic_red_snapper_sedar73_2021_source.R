assessment_id <- "noaa_south_atlantic_red_snapper_sedar73_2021"

read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE)
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  stopifnot(status == 0L, length(rows) > 0L)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
current <- assessments[
  assessments$assessment_id == "noaa_south_atlantic_red_snapper_2024", , drop = FALSE
]

input_value <- function(measure, year, fleet = "", survey = "") {
  fleet_match <- if (nzchar(fleet)) inputs$fleet == fleet else is.na(inputs$fleet)
  survey_match <- if (nzchar(survey)) inputs$survey == survey else is.na(inputs$survey)
  rows <- inputs[inputs$measure == measure & inputs$year == year &
    fleet_match & survey_match, , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  as.numeric(rows$value)
}
output_value <- function(measure, year, age = NA_real_) {
  rows <- outputs[outputs$measure == measure & outputs$year == year, , drop = FALSE]
  if (!is.na(age)) rows <- rows[rows$age == age, , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  as.numeric(rows$value)
}

stopifnot(
  nrow(assessment) == 1L,
  assessment$stock_id == "noaa_south_atlantic_red_snapper",
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2019L,
  assessment$is_current %in% c("FALSE", "0"),
  assessment$is_applied %in% c("TRUE", "1"),
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(current) == 1L,
  current$assessment_year == 2024L,
  current$terminal_year == 2023L,
  current$is_current %in% c("TRUE", "1"),
  current$inputs_status == "partial",
  current$outputs_status == "partial",
  nrow(inputs) == 450L,
  nrow(assumptions) == 17L,
  nrow(outputs) == 4550L,
  sum(inputs$measure == "relative_abundance_index") > 0L,
  sum(inputs$measure == "abundance_index_cv") ==
    sum(inputs$measure == "relative_abundance_index"),
  all(is.na(inputs$age)),
  all(inputs$year >= 1950L & inputs$year <= 2019L),
  all(outputs$year >= 1950L & outputs$year <= 2019L),
  sum(outputs$measure == "numbers_at_age") == 70L * 20L,
  sum(outputs$measure == "biomass_at_age") == 70L * 20L,
  sum(outputs$measure == "fishing_mortality_at_age") == 70L * 20L,
  sum(outputs$measure == "total_numbers") == 70L,
  sum(outputs$measure == "recruitment") == 70L,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  input_value("landings_biomass", 1950L, fleet = "Commercial handline") == 368.657,
  input_value("relative_abundance_index", 1993L, survey = "Commercial handline") == 1.09,
  input_value("abundance_index_cv", 1993L, survey = "Commercial handline") == 0.2,
  output_value("numbers_at_age", 1950L, age = 1L) == 436.87,
  output_value("total_numbers", 1950L) == 2422.24,
  output_value("recruitment", 1950L) == 436.87,
  output_value("fishing_mortality_at_age", 1950L, age = 1L) == 0.003,
  output_value("SSB", 1950L) == 1342193,
  all(grepl("SEDAR 73 Stock Assessment Report", inputs$source_reference, fixed = TRUE)),
  all(grepl("SEDAR 73 Stock Assessment Report", outputs$source_reference, fixed = TRUE))
)
