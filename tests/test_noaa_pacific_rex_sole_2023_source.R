root <- "."
stock_id <- "noaa_pacific_coast_rex_sole"
assessment_id <- "noaa_pacific_coast_rex_sole_2023"
candidate_id <- "NOAA:10059"

read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = classes)
}

stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "region", "ocean"))
assessments <- read_columns("database/assessments.csv", c("assessment_id",
  "stock_id", "assessment_year", "terminal_year", "estimate_terminal_year",
  "model_family", "model_version", "is_current", "is_applied",
  "framework_url",
  "inputs_status", "outputs_status", "assumptions_status"))
candidates <- read_columns("discovery/candidates.csv", c("candidate_id",
  "matched_stock_id", "match_status", "import_status"))
units <- read_columns("discovery/inventory_units.csv", c("unit_key",
  "matched_stock_id", "import_status"))
selected <- read_columns("discovery/selected_batch_15_2026.csv", c(
  "candidate_id", "curation_status"))
inputs <- read_columns("database/inputs.csv", c("assessment_id", "type",
  "measure", "basis", "value", "unit", "year", "age", "fleet", "survey",
  "sex", "season", "sampling_time", "source_type", "source_reference",
  "notes", "observation_id", "sample_size", "length_bin_lower",
  "length_bin_upper"))
outputs <- read_columns("database/outputs.csv", c("assessment_id", "type",
  "measure", "value", "unit", "year", "age", "fleet", "sex", "se",
  "lwr", "upr", "source_type", "source_reference", "notes"))
assumptions <- read_columns("database/assumptions.csv", c("assessment_id",
  "component", "setting", "value", "source_reference", "notes"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
selected_case <- selected[selected$candidate_id == candidate_id, , drop = FALSE]
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]

get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure, type = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10059",
  stock$scientific_name == "Glyptocephalus zachirus",
  stock$ocean == "Northeast Pacific",
  stock$region == "U.S. West Coast",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2023",
  assessment$terminal_year == "2022",
  assessment$estimate_terminal_year == "2034",
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.21",
  is.na(assessment$framework_url),
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  all(assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial",
  nrow(selected_case) == 1L,
  selected_case$curation_status == "partial_source_import",
  nrow(assumptions) == 11L,
  nrow(get_input("catch_biomass")) == 107L,
  nrow(get_input("catch_se")) == 107L,
  setequal(get_input("catch_biomass")$fleet,
    c("FISHERY_current", "FISHERY_historical")),
  range(as.integer(get_input("catch_biomass")$year))[1] == 1916L,
  range(as.integer(get_input("catch_biomass")$year))[2] == 2022L,
  all(get_input("catch_biomass")$unit == "metric tonnes"),
  nrow(get_input("relative_biomass_index")) == 28L,
  nrow(get_input("log_index_sd")) == 28L,
  setequal(unique(get_input("relative_biomass_index")$survey),
    c("SURVEY1", "SURVEY2", "SURVEY3")),
  all(is.na(get_input("relative_biomass_index")$sampling_time)),
  nrow(get_input("discard_fraction")) == 20L,
  nrow(get_input("discard_fraction_cv")) == 20L,
  nrow(get_input("frequency_at_length")) == 3120L,
  nrow(get_input("frequency_at_age")) == 6052L,
  setequal(as.integer(get_input("frequency_at_age")$age), 1:34),
  length(unique(get_input("frequency_at_age")$observation_id)) == 178L,
  length(unique(get_input("frequency_at_length")$observation_id)) == 104L,
  sum(grepl("negative fleet rows are excluded", get_input("frequency_at_age")$notes,
    fixed = TRUE)) == 884L,
  all(nzchar(inputs$source_reference)),
  !any(inputs$measure %in% c("catch_at_age", "index_at_age", "numbers_at_age",
    "weight_at_age", "maturity_at_age")),
  nrow(get_output("total_biomass")) == 139L,
  nrow(get_output("spawning_output")) == 139L,
  nrow(get_output("recruitment")) == 139L,
  nrow(get_output("numbers_at_age", "population")) == 139L * 2L * 35L,
  nrow(get_output("fishing_mortality_at_age")) == 139L * 2L * 2L * 35L,
  nrow(get_output("natural_mortality_at_age")) == 139L * 2L * 35L,
  nrow(get_output("weight_at_age")) == 139L * 2L * 35L,
  nrow(get_output("maturity_at_age")) == 70L,
  all(as.integer(get_output("numbers_at_age")$year) %in% 1896:2034),
  setequal(as.integer(get_output("numbers_at_age")$age), 0:34),
  all(is.na(get_output("numbers_at_age")$se)),
  all(abs(as.numeric(get_output("natural_mortality_at_age")$value) - 0.186207) < 1e-7),
  sum(!is.na(get_output("spawning_output")$lwr)) == 11L,
  sum(!is.na(get_output("recruitment")$lwr)) == 11L,
  all(get_output("spawning_output")$unit == "eggs"),
  all(get_output("spawning_output")$source_type[
    as.integer(get_output("spawning_output")$year) %in% 2013:2023] == "official_table"),
  nrow(get_output("total_numbers")) == 139L,
  all(is.na(get_output("total_numbers")$se)),
  all(nzchar(outputs$year)),
  all(nzchar(outputs$source_reference)),
  all(grepl("not an estimated M trajectory",
    get_output("natural_mortality_at_age")$notes, fixed = TRUE))
)

n_at_age <- get_output("numbers_at_age", "population")
summed_n <- aggregate(as.numeric(n_at_age$value),
  list(year = as.integer(n_at_age$year)), sum)
total_n <- get_output("total_numbers")
total_n <- total_n[match(summed_n$year, as.integer(total_n$year)), , drop = FALSE]
stopifnot(max(abs(summed_n$x - as.numeric(total_n$value))) < 1e-6)

review <- paste(readLines("discovery/source_reviews/noaa_pacific_rex_sole_2023.md",
  warn = FALSE), collapse = "\n")
stopifnot(
  grepl("canonical database contains this stock and its 2023 assessment", review, fixed = TRUE),
  !grepl("canonical database has no matching stock record", review, fixed = TRUE),
  grepl("source import is recorded in the canonical database", review, fixed = TRUE),
  grepl("no observed catch-at-age series", review, fixed = TRUE),
  grepl("Neither group is an age-specific abundance index", review, fixed = TRUE),
  grepl("Natural mortality is fixed at 0.186207", review, fixed = TRUE),
  grepl("spawning quantity is egg production", review, fixed = TRUE)
)

cat("NOAA Pacific Coast Rex Sole source coverage, units, status, outputs, and provenance checks passed.\n")
