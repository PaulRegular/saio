read_assessment_rows <- function(path, id) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE, encoding = "bytes")
    if (!length(lines)) break
    rows <- c(rows, lines[startsWith(lines, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "
"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "noaa_chilipepper_2025"
stock_id <- "noaa_chilipepper_pacific_coast"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assessments <- read.csv("database/assessments.csv",
  colClasses = "character", check.names = FALSE)
stocks <- read.csv("database/stocks.csv", colClasses = "character", check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv",
  colClasses = "character", check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv",
  colClasses = "character", check.names = FALSE)
batch <- read.csv("discovery/selected_batch_29_2026.csv",
  colClasses = "character", check.names = FALSE)
manifest <- read.csv("provenance/discovery_noaa_chilipepper_2025/sources.csv",
  colClasses = "character", check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:17357", , drop = FALSE]
unit <- inventory[inventory$candidate_unit_id == "noaa_stocksmart_17357", , drop = FALSE]
selection <- batch[batch$candidate_id == "NOAA:17357", , drop = FALSE]
index_obs <- inputs[inputs$type == "index" & startsWith(inputs$observation_id, "CPUE:"), , drop = FALSE]
catch <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", , drop = FALSE]
agecomp <- inputs[inputs$measure == "conditional_frequency_at_age", , drop = FALSE]
lencomp <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
n_at_age <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
total_n <- outputs[outputs$measure == "total_abundance", , drop = FALSE]
forecast_spawn <- outputs[outputs$measure == "spawning_output" & outputs$year == 2025, , drop = FALSE]
forecast_ratio <- outputs[outputs$measure == "SSB_ratio" & outputs$year == 2025, , drop = FALSE]
age_outputs <- outputs[outputs$measure %in% c("numbers_at_age", "biomass_at_age",
  "catch_numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age",
  "total_mortality_at_age"), , drop = FALSE]

stopifnot(
  nrow(stock) == 1L, stock$authority_stock_id == "17357",
  stock$scientific_name == "Sebastes goodei", stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$assessment_year == "2025",
  assessment$terminal_year == "2024", assessment$estimate_terminal_year == "2025",
  assessment$is_current == "TRUE", assessment$is_applied == "TRUE",
  assessment$model_version == "3.30.23.1",
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched", candidate$import_status == "partial",
  nrow(unit) == 1L, unit$matched_stock_id == stock_id,
  unit$match_status == "matched", unit$import_status == "partial",
  nrow(selection) == 1L, selection$curation_status == "partial_source_import",
  nrow(manifest) == 3L, all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  nrow(inputs) == 106870L, nrow(outputs) == 216303L, all(inputs$source_type == "native_model"),
  nrow(catch) == 756L, all(catch$unit == "metric tons"),
  sum(inputs$measure == "log_catch_sd") == 756L,
  nrow(index_obs) == 146L,
  setequal(unique(index_obs$measure), c("relative_biomass_index",
    "spawning_output_index", "recruitment_index")),
  sum(inputs$measure == "log_index_sd") == 146L,
  sum(inputs$measure == "conditional_frequency_at_age") == 91512L,
  sum(inputs$measure == "frequency_at_length") == 13338L,
  all(agecomp$basis == "native_frequency"), all(agecomp$type == "biology"),
  all(agecomp$age %in% 0:35),
  setequal(unique(lencomp$length_bin), seq(8, 60, 2)),
  setequal(unique(agecomp$length_bin_lower), seq(8, 58, 2)),
  setequal(unique(agecomp$length_bin_upper), seq(8, 58, 2)),
  sum(inputs$measure == "age_error_mean_age") == 108L,
  sum(inputs$measure == "ageing_error_sd") == 108L,
  sum(grepl("CPUE:[^:]+:source_year:-", index_obs$observation_id)) == 22L,
  !any(inputs$measure == "numbers_at_age"),
  !any(inputs$measure %in% c("weight_at_age", "maturity_at_age")),
  nrow(n_at_age) == 10800L, setequal(unique(n_at_age$year), 1875:2024),
  setequal(unique(n_at_age$age), 0:35),
  nrow(total_n) == 150L,
  all(is.na(age_outputs$se) & is.na(age_outputs$lwr) & is.na(age_outputs$upr)),
  nrow(forecast_spawn) == 1L, forecast_spawn$value == 9925,
  forecast_spawn$lwr == 6263, forecast_spawn$upr == 13587,
  forecast_spawn$unit == "billion eggs",
  nrow(forecast_ratio) == 1L, forecast_ratio$value == 0.832,
  forecast_ratio$lwr == 0.628, forecast_ratio$upr == 1.037,
  abs(total_n$value[total_n$year == 2024] -
    sum(n_at_age$value[n_at_age$year == 2024])) < 1e-6,
  all(outputs$source_type %in% c("native_model", "derived_source_output", "official_document"))
)

cat("NOAA Chilipepper 2025 source coverage, units, output scales, provenance, and partial-status checks passed.
")


