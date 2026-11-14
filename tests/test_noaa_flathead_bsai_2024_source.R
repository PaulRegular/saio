read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}

stock_id <- "noaa_flathead_sole_bsai"
assessment_id <- "noaa_flathead_sole_bsai_2024"
inputs <- read_columns("database/inputs.csv", c("assessment_id", "type", "measure",
  "basis", "value", "unit", "year", "age", "fleet", "survey", "sex",
  "season", "sampling_time", "source_type", "source_reference", "notes",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition"))
outputs <- read_columns("database/outputs.csv", c("assessment_id", "type", "measure",
  "value", "unit", "year", "age", "fleet", "survey", "sex", "region", "season", "age_group", "scenario", "se",
  "source_type", "source_reference", "notes"))
assumptions <- read_columns("database/assumptions.csv", c("assessment_id", "component",
  "setting", "value", "source_reference", "notes"))
assessments <- read_columns("database/assessments.csv", c("assessment_id", "stock_id",
  "assessment_year", "terminal_year", "assessment_type", "model_family",
  "model_version", "inputs_status", "outputs_status", "assumptions_status"))
stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "ocean"))
candidates <- read_columns("discovery/candidates.csv", c("candidate_id", "matched_stock_id",
  "match_status", "import_status"))
selected <- read_columns("discovery/selected_batch_16_2026.csv", c("candidate_id",
  "curation_status", "detailed_source_url"))

inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10015", , drop = FALSE]
selected_case <- selected[selected$candidate_id == "NOAA:10015", , drop = FALSE]
get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure, type = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10015",
  stock$scientific_name == "Hippoglossoides elassodon",
  stock$ocean == "Northeast Pacific",
  grepl("Bering flounder", stock$notes, fixed = TRUE),
  nrow(assessment) == 1L,
  assessment$assessment_year == "2024",
  assessment$terminal_year == "2024",
  assessment$assessment_type == "operational_update",
  assessment$model_version == "3.30.22, Model 18.2c",
  all(c(assessment$inputs_status, assessment$outputs_status,
    assessment$assumptions_status) == "partial"),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(selected_case) == 1L,
  selected_case$curation_status == "partial_source_import",
  grepl("8db5b6c505841aedc4b44c3cac5f85813ddebf94", selected_case$detailed_source_url,
    fixed = TRUE),
  nrow(assumptions) == 20L,
  nrow(get_input("total_biomass")) == 104L,
  nrow(get_input("catch_se")) == 62L,
  sum(get_input("total_biomass")$type == "catch") == 62L,
  sum(get_input("total_biomass")$type == "index") == 42L,
  all(get_input("total_biomass")$unit == "t"),
  range(as.integer(get_input("total_biomass")$year[get_input("total_biomass")$type == "catch"]),
    na.rm = TRUE)[1] == 1964L,
  range(as.integer(get_input("total_biomass")$year[get_input("total_biomass")$type == "catch"]),
    na.rm = TRUE)[2] == 2024L,
  sum(is.na(get_input("total_biomass")$year[get_input("total_biomass")$type == "catch"])) == 1L,
  range(as.integer(get_input("total_biomass")$year[get_input("total_biomass")$type == "index"]),
    na.rm = TRUE)[1] == 1982L,
  range(as.integer(get_input("total_biomass")$year[get_input("total_biomass")$type == "index"]),
    na.rm = TRUE)[2] == 2024L,
  all(get_input("total_biomass")$sampling_time[get_input("total_biomass")$type == "index"] == 0.5),
  nrow(get_input("frequency_at_age")) == 24150L,
  length(unique(get_input("frequency_at_age")$observation_id)) == 1150L,
  all(get_input("frequency_at_age")$type == "index"),
  all(get_input("frequency_at_age")$unit == "source frequency"),
  setequal(as.integer(get_input("frequency_at_age")$age), 1:21),
  all(!is.na(get_input("frequency_at_age")$length_bin_lower)),
  all(!is.na(get_input("frequency_at_age")$length_bin_upper)),
  nrow(get_input("proportion_at_age")) == 2184L,
  nrow(get_input("proportion_at_length")) == 4416L,
  nrow(get_input("natural_mortality_at_age")) == 44L,
  all(as.numeric(get_input("natural_mortality_at_age")$value) == 0.2),
  nrow(get_input("maturity_at_age")) == 22L,
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  !any(inputs$type == "index" & inputs$measure %in% c("numbers_at_age", "index_by_age_group")),
  nrow(get_output("numbers_at_age", "population")) == 62L * 2L * 22L,
  nrow(get_output("fishing_mortality_at_age")) == 62L * 2L * 22L,
  nrow(get_output("biomass_at_age")) == 62L * 2L * 22L,
  nrow(get_output("numbers_at_age", "catch")) == 62L * 2L * 22L,
  nrow(get_output("weight_at_age")) == 62L * 2L * 22L,
  nrow(get_output("total_numbers")) == 62L,
  nrow(get_output("maturity_at_age")) == 22L,
  nrow(get_output("projected_catch")) == 98L,
  all(grepl("2024 management projection \\(Alt [1-7]\\)",
    get_output("projected_catch")$scenario)),
  all(is.na(outputs$se)),
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference)),
  all(grepl("8db5b6c505841aedc4b44c3cac5f85813ddebf94",
    c(inputs$source_reference, outputs$source_reference), fixed = TRUE)),
  all(is.na(get_output("numbers_at_age")$se))
)

n_at_age <- get_output("numbers_at_age", "population")
total_n <- get_output("total_numbers")
summed_n <- aggregate(as.numeric(n_at_age$value),
  list(year = as.integer(n_at_age$year)), sum)
total_n <- total_n[match(summed_n$year, as.integer(total_n$year)), , drop = FALSE]
stopifnot(max(abs(summed_n$x - as.numeric(total_n$value))) < 1e-6)

weight <- get_output("weight_at_age")
biomass_at_age <- get_output("biomass_at_age")
surfaces <- merge(n_at_age[, c("year", "age", "sex", "value")],
  weight[, c("year", "age", "sex", "value")], by = c("year", "age", "sex"),
  suffixes = c("_n", "_weight"))
surfaces <- merge(surfaces,
  biomass_at_age[, c("year", "age", "sex", "value")],
  by = c("year", "age", "sex"))
stopifnot(nrow(surfaces) == 62L * 2L * 22L,
  max(abs(as.numeric(surfaces$value_n) * as.numeric(surfaces$value_weight) -
    as.numeric(surfaces$value))) < 0.3)

year_biomass <- aggregate(as.numeric(biomass_at_age$value),
  list(year = as.integer(biomass_at_age$year)), sum)
total_biomass <- get_output("total_biomass", "biomass")
total_biomass <- total_biomass[match(year_biomass$year,
  as.integer(total_biomass$year)), , drop = FALSE]
stopifnot(max(abs(year_biomass$x - as.numeric(total_biomass$value))) < 1)

annual_ssb <- get_output("SSB", "biomass")
annual_ssb <- annual_ssb[(is.na(annual_ssb$scenario) |
  annual_ssb$scenario == "Stock Synthesis forecast") &
  as.integer(annual_ssb$year) %in% c(2024L, 2025L), , drop = FALSE]
stopifnot(setequal(as.integer(annual_ssb$year), c(2024L, 2025L)),
  abs(as.numeric(annual_ssb$value[annual_ssb$year == "2024"]) - 185493) < 1,
  abs(as.numeric(annual_ssb$value[annual_ssb$year == "2025"]) - 204316) < 1)

output_keys <- c("type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
key <- do.call(paste, c(lapply(outputs[output_keys], function(x)
  ifelse(is.na(x), "", as.character(x))), sep = "\r"))
stopifnot(!anyDuplicated(key))

review <- paste(readLines("discovery/source_reviews/noaa_flathead_bsai.md", warn = FALSE),
  collapse = "\n")
stopifnot(
  grepl("bafa7658d31e0b99fe11d626a58e1c01807c69ee` is an earlier, superseded snapshot",
    review, fixed = TRUE),
  grepl("not age-specific abundance indices", review, fixed = TRUE),
  grepl("one assessment case", review, fixed = TRUE)
)

cat("NOAA BSAI Flathead Sole/Bering Flounder source coverage, units, scenarios, and outputs passed.\n")