root <- "."
assessment_id <- "noaa_west_coast_widow_2025"
stock_id <- "noaa_west_coast_widow"

read_selected <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields)); names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}
stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidate <- read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
inputs <- read_selected(file.path(root, "database", "inputs.csv"),
  c("assessment_id", "type", "measure", "basis", "year", "age", "value",
    "unit", "sampling_time", "source_type", "source_reference", "sex", "fleet",
    "survey", "observation_id", "length_bin", "length_bin_lower",
    "length_bin_upper", "sample_size", "age_error", "partition", "season",
    "year_basis", "notes"))
outputs <- read_selected(file.path(root, "database", "outputs.csv"),
  c("assessment_id", "type", "measure", "year", "age", "value", "unit",
    "se", "lwr", "upr", "source_type", "source_reference", "sex", "fleet", "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"),
  c("assessment_id", "component", "setting", "value", "source_reference"))
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidate[candidate$candidate_id == "NOAA:10568", , drop = FALSE]
input <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
output <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
projected_output <- output[as.integer(output$year) > 2024L, , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_west_coast_widow_rockfish.md"), warn = FALSE), collapse = "\n")

catch <- input[input$type == "catch" & input$measure == "total_biomass", , drop = FALSE]
index <- input[input$type == "index" & input$measure %in% c("total_numbers", "total_biomass"), , drop = FALSE]
index_sd <- input[input$type == "index" & input$measure == "log_index_sd", , drop = FALSE]
length_comp <- input[input$measure == "frequency_at_length", , drop = FALSE]
age_comp <- input[input$measure == "frequency_at_age", , drop = FALSE]
get_output <- function(type, measure) output[output$type == type & output$measure == measure, , drop = FALSE]
assumption_value <- function(setting) {
  x <- assumptions$value[assumptions$setting == setting]
  if (length(x) != 1L) stop("Expected one assumption: ", setting)
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10568",
  stock$scientific_name == "Sebastes entomelas",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2024,
  assessment$estimate_terminal_year == 2036,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(catch) == 545L,
  min(as.integer(catch$year)) == 1916L,
  max(as.integer(catch$year)) == 2024L,
  all(catch$unit == "metric tonnes"),
  all(catch$year_basis == "calendar_year"),
  all(catch$source_reference != ""),
  identical(as.numeric(strsplit(assumption_value("catch_se_field"), ", ")[[1L]]),
    c(0.01, 0.1)),
  assumption_value("M_prior") == "Lognormal prior with median 0.10 per year and log-SD 0.31",
  assumption_value("age_at_50_percent_maturity") == "5.47 years",
  assumption_value("steepness") == "0.72 fixed",
  assumption_value("recruitment_SD") == "0.60",
  length(unique(catch$fleet)) == 5L,
  all(catch$value[catch$fleet %in% c("ignore1", "ignore2")] == 0),
  nrow(index) == 90L,
  nrow(index_sd) == 90L,
  length(unique(index$survey)) == 6L,
  identical(unique(index$survey[index$measure == "total_numbers"]), "JuvSurvey"),
  all(index_sd$basis == "log_scale"),
  all(index_sd$unit == "log-scale standard error"),
  all(is.finite(as.numeric(index$sampling_time))),
  all(as.numeric(index$sampling_time) >= 0 & as.numeric(index$sampling_time) < 1),
  all(abs(as.numeric(index$sampling_time) -
    (as.numeric(sub("^month ", "", index$season)) - 1) / 12) < 1e-10),
  nrow(length_comp) == 8025L,
  length(unique(length_comp$observation_id)) == 162L,
  sum(vapply(split(length_comp$sex, length_comp$observation_id),
    function(x) length(unique(x)) == 2L, logical(1L))) == 159L,
  all(length_comp$unit == "source frequency weight"),
  nrow(age_comp) == 30955L,
  length(unique(age_comp$observation_id)) == 616L,
  sum(vapply(split(age_comp$sex, age_comp$observation_id),
    function(x) length(unique(x)) == 2L, logical(1L))) == 139L,
  all(!is.na(age_comp$sample_size)),
  all(!is.na(age_comp$age_error)),
  any(grepl("Negative signed fleet", age_comp$notes, fixed = TRUE)),
  all(age_comp$age %in% as.character(0:40)),
  !any(input$measure %in% c("index_by_age_group", "index_catch_numbers_at_age")),
  nrow(get_output("population", "numbers_at_age")) == 242L * 41L,
  nrow(get_output("biomass", "biomass_at_age")) == 242L * 41L,
  nrow(get_output("mortality", "natural_mortality_at_age")) == 242L * 41L,
  nrow(get_output("mortality", "fishing_mortality_at_age")) == 1210L * 41L,
  nrow(get_output("catch", "numbers_at_age")) == 1210L * 41L,
  nrow(get_output("biology", "weight_at_age")) == 242L * 41L,
  nrow(get_output("population", "total_numbers")) == 121L,
  nrow(get_output("biomass", "spawning_output")) == 121L,
  nrow(projected_output) > 0L,
  all(grepl("FORE", projected_output$notes, fixed = TRUE)),
  all(get_output("population", "numbers_at_age")$unit == "thousand fish"),
  all(get_output("mortality", "natural_mortality_at_age")$unit == "per year"),
  all(is.na(get_output("population", "numbers_at_age")$se)),
  isTRUE(all.equal(
    as.numeric(get_output("population", "total_numbers")$value),
    as.numeric(tapply(as.numeric(get_output("population", "numbers_at_age")$value),
      as.integer(get_output("population", "numbers_at_age")$year), sum))
  )),
  abs(as.numeric(get_output("biomass", "spawning_output")$value[
    get_output("biomass", "spawning_output")$year == "2025"]) - 10571.7) < 0.01,
  as.numeric(get_output("biomass", "spawning_output")$lwr[
    get_output("biomass", "spawning_output")$year == "2025"]) == 5127,
  as.numeric(get_output("biomass", "spawning_output")$upr[
    get_output("biomass", "spawning_output")$year == "2025"]) == 16017,
  all(grepl("billion eggs", get_output("biomass", "spawning_output")$unit)),
  all(as.numeric(get_output("mortality", "natural_mortality_at_age")$value[
    get_output("mortality", "natural_mortality_at_age")$sex == "female"]) == 0.134991),
  all(as.numeric(get_output("mortality", "natural_mortality_at_age")$value[
    get_output("mortality", "natural_mortality_at_age")$sex == "male"]) == 0.14698),
  grepl("version discrepancy", review, ignore.case = TRUE),
  grepl("four survey and two fishery-dependent", review, fixed = TRUE),
  grepl("not a direct age-specific abundance index", review, fixed = TRUE),
  grepl("2025 spawning-output estimate is 10,571.7 billion eggs", review, fixed = TRUE)
)

cat("NOAA Widow Rockfish 2025 source coverage, units, outputs, and provenance checks passed.\n")
