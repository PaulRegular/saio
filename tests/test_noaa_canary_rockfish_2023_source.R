root <- "."
assessment_id <- "noaa_canary_rockfish_2023"
stock_id <- "noaa_canary_rockfish_pacific_coast"

read_selected <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}
stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidate <- read_selected(file.path(root, "discovery", "candidates.csv"),
  c("candidate_id", "matched_stock_id", "import_status", "catch_age_evidence",
    "survey_age_evidence", "mortality_evidence"))
selected <- read_selected(file.path(root, "discovery", "selected_batch_01_2026.csv"),
  c("candidate_unit_id", "curation_status"))
inputs <- read_selected(file.path(root, "database", "inputs.csv"), c(
  "assessment_id", "type", "measure", "basis", "year", "age", "value",
  "unit", "sampling_time", "source_type", "source_reference", "sex", "fleet",
  "survey", "observation_id", "sample_size", "age_error", "notes", "season",
  "length_bin", "length_bin_lower", "length_bin_upper"))
outputs <- read_selected(file.path(root, "database", "outputs.csv"), c(
  "assessment_id", "type", "measure", "year", "age", "value", "unit",
  "se", "lwr", "upr", "source_type", "source_reference", "sex", "fleet", "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"),
  c("assessment_id", "component", "setting", "value", "source_reference", "notes"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidate[candidate$candidate_id == "NOAA:10415", , drop = FALSE]
selected <- selected[selected$candidate_unit_id == "noaa_stocksmart_10415", , drop = FALSE]
input <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
output <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_canary_rockfish_pacific_coast.md"), warn = FALSE), collapse = "\n")
get_input <- function(type, measure) input[input$type == type & input$measure == measure, , drop = FALSE]
get_output <- function(type, measure) output[output$type == type & output$measure == measure, , drop = FALSE]
setting <- function(name) assumptions$value[assumptions$setting == name]

catch <- get_input("catch", "total_biomass")
index <- input[input$type == "index" & input$measure %in%
  c("relative_biomass_index", "relative_abundance_index"), , drop = FALSE]
index_sd <- get_input("index", "log_index_sd")
age_comp <- input[input$measure == "frequency_at_age", , drop = FALSE]
length_comp <- input[input$measure == "frequency_at_length", , drop = FALSE]
recruitment <- get_output("recruitment", "recruitment")
spawning <- get_output("biomass", "spawning_output")
total_n <- get_output("population", "total_numbers")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10415",
  stock$scientific_name == "Sebastes pinniger",
  stock$ocean == "Northeast Pacific",
  stock$region == "U.S. West Coast",
  sum(stocks$authority_stock_id == "10415", na.rm = TRUE) == 1L,
  nrow(assessment) == 1L,
  assessment$assessment_year == 2023L,
  assessment$terminal_year == 2022L,
  assessment$estimate_terminal_year == 2034L,
  all(assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  selected$curation_status == "partial_source_import",
  nrow(catch) == 1965L,
  min(as.integer(catch$year)) == 1892L,
  max(as.integer(catch$year)) == 2022L,
  length(unique(catch$fleet)) == 15L,
  all(catch$unit == "metric tonnes"),
  all(grepl("landings plus dead discards", catch$notes, fixed = TRUE)),
  nrow(index) == 178L,
  nrow(index_sd) == 178L,
  length(unique(index$survey)) == 16L,
  all(as.numeric(index$sampling_time) == 0.5),
  all(grepl("month 7", index$season, fixed = TRUE)),
  any(grepl("unit code 1", index$unit, fixed = TRUE)),
  any(grepl("unit code 32", index$unit, fixed = TRUE)),
  all(index_sd$basis == "log_scale"),
  all(index_sd$unit == "log-scale standard error"),
  nrow(age_comp) > 0L,
  length(unique(sub("-(female|male|combined)$", "", age_comp$observation_id))) == 3829L,
  setequal(as.integer(age_comp$age), 1:35),
  min(as.integer(age_comp$year)) == 1980L,
  max(as.integer(age_comp$year)) == 2022L,
  all(as.integer(age_comp$age_error) %in% 1:8),
  length(unique(sub("-(female|male|combined)$", "", length_comp$observation_id))) == 606L,
  all(as.integer(length_comp$length_bin) %in% seq(12, 66, 2)),
  any(grepl("conditional age-at-length", input$notes, ignore.case = TRUE)),
  any(grepl("Native signed year was negative", input$notes, fixed = TRUE)),
  any(grepl("Native signed fleet code was negative", input$notes, fixed = TRUE)),
  !any(input$measure %in% c("numbers_at_age", "catch_at_age", "index_at_age")),
  all(nzchar(output$source_reference)),
  nrow(get_output("population", "numbers_at_age")) == 286L * 41L,
  nrow(get_output("biomass", "biomass_at_age")) == 286L * 41L,
  nrow(get_output("mortality", "natural_mortality_at_age")) == 286L * 41L,
  nrow(get_output("mortality", "fishing_mortality_at_age")) == 4290L * 41L,
  nrow(get_output("catch", "numbers_at_age")) == 4290L * 41L,
  nrow(get_output("biology", "weight_at_age")) == 286L * 41L,
  nrow(get_output("biology", "maturity_at_age")) == 82L,
  all(as.integer(get_output("biology", "maturity_at_age")$year) == 2022L),
  setequal(as.integer(get_output("population", "numbers_at_age")$age), 0:40),
  setequal(as.integer(total_n$year), 1892:2034),
  all(is.na(total_n$se)),
  all(total_n$unit == "thousand fish"),
  all(abs(as.numeric(get_output("mortality", "natural_mortality_at_age")$value[
    get_output("mortality", "natural_mortality_at_age")$sex == "female"]) - 0.0779404) < 1e-7),
  all(abs(as.numeric(get_output("mortality", "natural_mortality_at_age")$value[
    get_output("mortality", "natural_mortality_at_age")$sex == "male"]) - 0.0643) < 1e-9),
  nrow(recruitment) == 143L,
  sum(!is.na(recruitment$lwr) & !is.na(recruitment$upr)) == 11L,
  all(as.numeric(recruitment$lwr[!is.na(recruitment$lwr)]) <=
    as.numeric(recruitment$value[!is.na(recruitment$lwr)])),
  all(as.numeric(recruitment$upr[!is.na(recruitment$upr)]) >=
    as.numeric(recruitment$value[!is.na(recruitment$upr)])),
  nrow(spawning[!is.na(spawning$lwr) & !is.na(spawning$upr), , drop = FALSE]) == 1L,
  abs(as.numeric(spawning$value[spawning$year == "2023"]) - 2808.87) < 0.02,
  abs(as.numeric(spawning$lwr[spawning$year == "2023"]) - 2050.19) < 0.02,
  abs(as.numeric(spawning$upr[spawning$year == "2023"]) - 3567.55) < 0.02,
  !any(output$measure == "SSB"),
  setting("natural_mortality") == "One age-constant scalar per sex; female estimated and male fixed at 0.0643 per year",
  grepl("not catch-at-age or standardized age-specific survey indices", review, fixed = TRUE),
  grepl("spawning output is not SSB", review, ignore.case = TRUE)
)

cat("NOAA Canary Rockfish 2023 source coverage, units, outputs, and provenance checks passed.\n")
