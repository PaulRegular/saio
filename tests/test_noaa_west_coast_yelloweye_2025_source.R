root <- "."
assessment_id <- "noaa_west_coast_yelloweye_2025"
stock_id <- "noaa_west_coast_yelloweye"

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
selected <- read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
inputs <- read_selected(file.path(root, "database", "inputs.csv"), c(
  "assessment_id", "type", "measure", "basis", "year", "age", "value",
  "unit", "sampling_time", "source_type", "source_reference", "sex", "fleet",
  "survey", "observation_id", "length_bin", "length_bin_lower",
  "length_bin_upper", "sample_size", "age_error", "partition", "season", "notes"))
outputs <- read_selected(file.path(root, "database", "outputs.csv"), c(
  "assessment_id", "type", "measure", "year", "age", "value", "unit",
  "se", "lwr", "upr", "source_type", "source_reference", "sex", "fleet",
  "region", "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"),
  c("assessment_id", "component", "setting", "value", "source_reference"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidate[candidate$candidate_id == "NOAA:10426", , drop = FALSE]
selected <- selected[selected$candidate_unit_id == "noaa_stocksmart_10426", , drop = FALSE]
input <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
output <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_west_coast_yelloweye_2025.md"), warn = FALSE), collapse = "\n")
get_input <- function(type, measure) input[input$type == type & input$measure == measure, , drop = FALSE]
get_output <- function(type, measure) output[output$type == type & output$measure == measure, , drop = FALSE]
assumption_value <- function(setting) {
  value <- assumptions$value[assumptions$setting == setting]
  if (length(value) != 1L) stop("Expected one assumption: ", setting)
  value
}

catch_biomass <- get_input("catch", "total_biomass")
catch_numbers <- get_input("catch", "total_numbers")
index <- input[input$type == "index" & input$measure %in%
  c("relative_abundance_index", "relative_biomass_index"), , drop = FALSE]
index_sd <- get_input("index", "log_index_sd")
length_comp <- input[input$measure == "frequency_at_length", , drop = FALSE]
age_comp <- input[input$measure == "frequency_at_age", , drop = FALSE]
native_spawn <- get_output("biomass", "spawning_output")
coastwide_spawn <- native_spawn[native_spawn$region == "U.S. West Coast", , drop = FALSE]
total_n <- get_output("population", "total_numbers")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10426",
  stock$scientific_name == "Sebastes ruberrimus",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2024,
  assessment$estimate_terminal_year == 2036,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  selected$curation_status == "partial_source_import",
  all(!is.na(output$source_reference) & nzchar(output$source_reference)),
  nrow(catch_biomass) == 816L,
  nrow(catch_numbers) == 136L,
  min(as.integer(input$year[input$type == "catch"])) == 1889L,
  max(as.integer(input$year[input$type == "catch"])) == 2024L,
  all(catch_biomass$unit == "metric tonnes"),
  all(catch_numbers$unit == "native SS3 numbers (multiplier not stated)"),
  length(unique(catch_biomass$fleet)) == 6L,
  length(unique(catch_numbers$fleet)) == 1L,
  nrow(index) == 150L,
  nrow(index_sd) == 150L,
  length(unique(index$survey)) == 8L,
  all(index_sd$basis == "log_scale"),
  all(index_sd$unit == "log-scale standard error"),
  all(is.finite(as.numeric(index$sampling_time))),
  all(abs(as.numeric(index$sampling_time) -
    (as.numeric(sub("^month ", "", index$season)) - 1) / 12) < 1e-10),
  nrow(length_comp) == 354L * 33L,
  length(unique(length_comp$observation_id)) == 354L,
  all(length_comp$length_bin %in% seq(10, 74, 2)),
  nrow(age_comp) == 2213L * 66L,
  length(unique(age_comp$observation_id)) == 2213L,
  all(as.integer(age_comp$age) %in% 0:65),
  all(!is.na(age_comp$sample_size)),
  all(!is.na(age_comp$age_error)),
  any(grepl("Negative signed fleet code", age_comp$notes, fixed = TRUE)),
  any(grepl("conditional age-at-length", age_comp$notes, fixed = TRUE)),
  any(grepl("marginal age composition", age_comp$notes, fixed = TRUE)),
  !any(input$measure %in% c("numbers_at_age", "index_by_age_group", "maturity_at_age")),
  nrow(get_output("population", "numbers_at_age")) == (296L + 148L) * 101L,
  nrow(get_output("biomass", "biomass_at_age")) == (296L + 148L) * 101L,
  nrow(get_output("mortality", "natural_mortality_at_age")) == 296L * 101L,
  nrow(get_output("mortality", "fishing_mortality_at_age")) == 1036L * 101L,
  nrow(get_output("catch", "numbers_at_age")) == 1036L * 101L,
  nrow(get_output("biology", "weight_at_age")) == 148L * 101L,
  nrow(total_n) == 148L,
  all(is.na(get_output("population", "numbers_at_age")$se)),
  all(get_output("population", "numbers_at_age")$unit == "thousand fish"),
  all(get_output("mortality", "natural_mortality_at_age")$unit == "per year"),
  all(abs(as.numeric(get_output("mortality", "natural_mortality_at_age")$value) - 0.0439034) < 1e-8),
  abs(sum(as.numeric(native_spawn$value[native_spawn$year == "2025" &
    native_spawn$region %in% c("California", "Oregon/Washington")])) - 477.63) < 0.02,
  nrow(coastwide_spawn[coastwide_spawn$year == "2025", , drop = FALSE]) == 1L,
  abs(as.numeric(coastwide_spawn$value[coastwide_spawn$year == "2025"]) - 477.63) < 0.02,
  as.numeric(coastwide_spawn$lwr[coastwide_spawn$year == "2025"]) == 384,
  as.numeric(coastwide_spawn$upr[coastwide_spawn$year == "2025"]) == 571,
  grepl("Table 20", coastwide_spawn$source_reference[coastwide_spawn$year == "2025"], fixed = TRUE),
  all(is.na(native_spawn$lwr[native_spawn$region != "U.S. West Coast"])),
  all(is.na(native_spawn$upr[native_spawn$region != "U.S. West Coast"])),
  all(is.na(get_output("population", "total_numbers")$se)),
  assumption_value("natural_mortality") == "Fixed M = 0.0439034 per year",
  grepl("not observed weight-at-age inputs", review, fixed = TRUE),
  grepl("spawning output is not relabelled as SSB", review, ignore.case = TRUE)
)

cat("NOAA West Coast Yelloweye 2025 source coverage, units, outputs, and provenance checks passed.\n")
