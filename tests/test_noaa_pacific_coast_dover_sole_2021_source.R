root <- "."
assessment_id <- "noaa_pacific_coast_dover_sole_2021"
stock_id <- "noaa_pacific_coast_dover_sole"
candidate_unit_id <- "noaa_stocksmart_10022"

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
  c("candidate_id", "matched_stock_id", "match_status", "import_status"))
inventory <- read_selected(file.path(root, "discovery", "inventory_units.csv"),
  c("unit_key", "matched_stock_id", "import_status"))
selected <- read_selected(file.path(root, "discovery", "selected_batch_01_2026.csv"),
  c("candidate_unit_id", "curation_status"))
input <- read_selected(file.path(root, "database", "inputs.csv"), c(
  "assessment_id", "type", "measure", "basis", "year", "age", "value",
  "unit", "year_basis", "sampling_time", "source_reference", "observation_id",
  "sample_size", "age_error", "fleet", "survey", "sex", "season", "notes",
  "length_bin", "length_bin_lower", "length_bin_upper", "partition"))
output <- read_selected(file.path(root, "database", "outputs.csv"), c(
  "assessment_id", "type", "measure", "year", "age", "value", "unit",
  "se", "lwr", "upr", "source_type", "source_reference", "sex", "fleet",
  "notes"))
assumptions <- read_selected(file.path(root, "database", "assumptions.csv"),
  c("assessment_id", "component", "setting", "value", "source_reference"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidate[candidate$candidate_id == "NOAA:10022", , drop = FALSE]
inventory <- inventory[inventory$unit_key == paste0("candidate:", candidate_unit_id), , drop = FALSE]
selected <- selected[selected$candidate_unit_id == candidate_unit_id, , drop = FALSE]
input <- input[input$assessment_id == assessment_id, , drop = FALSE]
output <- output[output$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
get_input <- function(measure) input[input$measure == measure, , drop = FALSE]
get_output <- function(measure, type = NULL) {
  z <- output[output$measure == measure, , drop = FALSE]
  if (!is.null(type)) z <- z[z$type == type, , drop = FALSE]
  z
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10022",
  stock$scientific_name == "Microstomus pacificus",
  stock$ocean == "Northeast Pacific",
  stock$region == "U.S. West Coast",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2020L,
  assessment$estimate_terminal_year == 2032L,
  assessment$model_version == "3.30.16.02",
  isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  all(assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  candidate$matched_stock_id == stock_id, candidate$match_status == "new",
  candidate$import_status == "partial", inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  selected$curation_status == "partial_source_import",
  nrow(input) == 69354L, nrow(output) == 105042L, nrow(assumptions) == 28L,
  nrow(get_input("landings_biomass")) == 220L,
  nrow(get_input("catch_se")) == 220L,
  nrow(get_input("relative_abundance_index")) == 35L,
  nrow(get_input("log_index_sd")) == 35L,
  nrow(get_input("discard_fraction")) == 44L,
  nrow(get_input("discard_fraction_cv")) == 44L,
  nrow(get_input("mean_body_weight")) == 36L,
  nrow(get_input("mean_body_weight_cv")) == 36L,
  nrow(get_input("ageing_error_sd")) == 122L,
  setequal(as.numeric(get_input("ageing_error_sd")$age), seq(0.5, 60.5, 1)),
  all(is.na(get_input("ageing_error_sd")$year) |
    !nzchar(get_input("ageing_error_sd")$year)),
  all(is.na(get_input("ageing_error_sd")$year_basis) |
    !nzchar(get_input("ageing_error_sd")$year_basis)),
  !any(input$measure %in% c("numbers_at_age", "index_at_age", "maturity_at_age", "weight_at_age")),
  all(get_input("landings_biomass")$unit == "metric tonnes"),
  all(get_input("relative_abundance_index")$basis == "index_scale"),
  all(get_input("relative_abundance_index")$sampling_time >= 0 &
    get_input("relative_abundance_index")$sampling_time < 1),
  setequal(as.integer(get_input("frequency_at_age")$age), 1:60),
  setequal(as.integer(get_input("frequency_at_length")$length_bin), seq(8, 60, 2)),
  length(unique(sub("-(female|male|combined)$", "",
    get_input("frequency_at_age")$observation_id))) == 925L,
  length(unique(sub("-(female|male|combined)$", "",
    get_input("frequency_at_length")$observation_id))) == 175L,
  any(grepl("sex code 0 is a combined-sex sample", input$notes, fixed = TRUE)),
  any(grepl("not an independent observation", input$notes, fixed = TRUE)),
  all(nzchar(input$source_reference)), all(nzchar(output$source_reference)),
  nrow(get_output("total_biomass")) == 122L,
  nrow(get_output("summary_biomass_age3plus")) == 122L,
  nrow(get_output("spawning_biomass")) == 122L,
  nrow(get_output("recruitment")) == 122L,
  nrow(get_output("numbers_at_age", "population")) == 244L * 61L,
  nrow(get_output("numbers_at_age", "catch")) == 488L * 61L,
  nrow(get_output("biomass_at_age")) == 244L * 61L,
  nrow(get_output("natural_mortality_at_age")) == 2L * 61L,
  nrow(get_output("fishing_mortality_at_age")) == 488L * 61L,
  nrow(get_output("weight_at_age")) == 244L * 61L,
  nrow(get_output("maturity_at_age")) == 122L,
  nrow(get_output("total_numbers")) == 122L,
  setequal(as.integer(get_output("numbers_at_age")$age), 0:60),
  setequal(as.integer(get_output("numbers_at_age")$year), 1911:2032),
  all(is.na(get_output("numbers_at_age")$se)),
  all(get_output("total_numbers")$source_type == "derived_source_output"),
  all(is.na(get_output("total_numbers")$se)),
  sum(!is.na(get_output("spawning_biomass")$lwr)) == 11L,
  sum(!is.na(get_output("recruitment")$lwr)) == 11L,
  abs(as.numeric(get_output("spawning_biomass")$value[
    get_output("spawning_biomass")$year == "2021"]) - 232065) < 1,
  abs(as.numeric(get_output("spawning_biomass")$lwr[
    get_output("spawning_biomass")$year == "2021"]) - 154153) < 1,
  abs(as.numeric(get_output("spawning_biomass")$upr[
    get_output("spawning_biomass")$year == "2021"]) - 309978) < 1,
  abs(as.numeric(get_output("recruitment")$value[
    get_output("recruitment")$year == "2021"]) - 209596) < 1,
  abs(as.numeric(get_output("recruitment")$lwr[
    get_output("recruitment")$year == "2021"]) - 103213) < 1,
  abs(as.numeric(get_output("recruitment")$upr[
    get_output("recruitment")$year == "2021"]) - 425629) < 1
)

male_m <- get_output("natural_mortality_at_age")
stopifnot(
  all(is.na(male_m$year)),
  all(abs(as.numeric(male_m$value[male_m$sex == "female"]) - 0.108) < 1e-8),
  all(abs(as.numeric(male_m$value[male_m$sex == "male"]) - 0.11398) < 1e-5)
)

numbers <- get_output("numbers_at_age", "population")
biomass <- get_output("biomass_at_age")
weights <- get_output("weight_at_age")
key <- function(x) paste(x$year, x$sex, x$age, sep = "|")
biomass <- biomass[match(key(numbers), key(biomass)), , drop = FALSE]
weights <- weights[match(key(numbers), key(weights)), , drop = FALSE]
stopifnot(
  !anyNA(biomass$value), !anyNA(weights$value),
  max(abs(as.numeric(numbers$value) * as.numeric(weights$value) -
    as.numeric(biomass$value)) / pmax(1, as.numeric(biomass$value))) < 0.01
)
total_n <- aggregate(as.numeric(numbers$value), list(year = numbers$year), sum)
reported_n <- get_output("total_numbers")
reported_n <- reported_n[match(total_n$year, reported_n$year), , drop = FALSE]
stopifnot(max(abs(total_n$x - as.numeric(reported_n$value))) < 1e-6)

review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_pacific_coast_dover_sole.md"), warn = FALSE), collapse = "\n")
stopifnot(
  grepl("220 retained-catch observations", review, fixed = TRUE),
  grepl("925 age-composition records", review, fixed = TRUE),
  grepl("No age-specific abundance index is present", review, fixed = TRUE),
  grepl("Tables ii and iii provide 95% intervals", review, fixed = TRUE)
)
cat("NOAA Pacific Coast Dover Sole 2021 source coverage, scale, outputs, and provenance checks passed.\n")
