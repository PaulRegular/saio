stock_id <- "noaa_gag_gulf"
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
candidate_id <- "NOAA:10348"

read_assessment_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  prefix <- paste0('"', id, '",')
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(data.frame())
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  read.csv(text = paste(rows, collapse = "\n"), header = FALSE,
    col.names = header, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv("provenance/noaa_gag_sedar72_2022/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_gag_sedar72_2022.md",
  warn = FALSE), collapse = "\n")
output_key <- paste(outputs$type, outputs$measure, outputs$year, outputs$sex,
  outputs$fleet, outputs$survey, outputs$age, sep = "|")
input_key <- paste(inputs$measure, inputs$year, inputs$fleet, inputs$survey,
  inputs$age, inputs$partition, inputs$unit, sep = "|")
value_at <- function(measure, year, sex = NA_character_, fleet = NA_character_,
                     survey = NA_character_) {
  keep <- outputs$measure == measure & outputs$year == as.character(year)
  if (!is.na(sex)) {
    if (sex == "") keep <- keep & is.na(outputs$sex)
    else keep <- keep & !is.na(outputs$sex) & outputs$sex == sex
  }
  if (!is.na(fleet)) keep <- keep & !is.na(outputs$fleet) & outputs$fleet == fleet
  if (!is.na(survey)) keep <- keep & !is.na(outputs$survey) & outputs$survey == survey
  as.numeric(outputs$value[keep])
}
input_value <- function(measure, year, fleet = NA_character_,
                        partition = NA_character_, survey = NA_character_,
                        age = NA_character_) {
  keep <- inputs$measure == measure & inputs$year == as.character(year)
  if (!is.na(fleet)) keep <- keep & !is.na(inputs$fleet) & inputs$fleet == fleet
  if (!is.na(partition)) keep <- keep & !is.na(inputs$partition) & inputs$partition == partition
  if (!is.na(survey)) keep <- keep & !is.na(inputs$survey) & inputs$survey == survey
  if (!is.na(age)) keep <- keep & !is.na(inputs$age) & inputs$age == age
  as.numeric(inputs$value[keep])
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA Fisheries",
  stock$authority_stock_id == "10348",
  stock$scientific_name == "Mycteroperca microlepis",
  stock$area == "Gulf of Mexico",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2022,
  assessment$terminal_year == 2019,
  assessment$estimate_terminal_year == 2019,
  assessment$model_family == "Stock Synthesis",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 9L,
  nrow(inputs) == 1436L,
  !anyDuplicated(input_key),
  all(inputs$type %in% c("catch", "index", "biology")),
  all(inputs$source_type == "official_table"),
  all(is.na(inputs$age[inputs$type == "catch"])),
  sum(inputs$measure == "landings_numbers") == 171L,
  sum(inputs$measure == "discard_numbers") == 171L,
  sum(inputs$measure == "landings_biomass") == 98L,
  sum(inputs$measure == "relative_abundance_index") == 161L,
  sum(inputs$measure == "log_index_sd") == 161L,
  sum(inputs$measure == "log_catch_sd" & inputs$partition == "landings") == 215L,
  sum(inputs$measure == "log_catch_sd" & inputs$partition == "discards") == 171L,
  all(inputs$basis[inputs$measure %in% c("landings_numbers", "discard_numbers")] == "numbers"),
  all(inputs$basis[inputs$measure == "log_catch_sd"] == "log_scale"),
  all(inputs$unit[inputs$measure == "landings_numbers"] == "fish"),
  all(inputs$unit[inputs$measure == "discard_numbers" &
    inputs$fleet %in% c("Recreational charter", "Recreational headboat",
      "Recreational private + shore")] == "fish"),
  all(inputs$unit[inputs$measure == "discard_numbers" &
    inputs$fleet %in% c("Commercial vertical line + other",
      "Commercial longline")] == "1000 fish"),
  all(inputs$unit[inputs$measure == "log_catch_sd"] == "log-scale standard error"),
  all(inputs$basis[inputs$measure == "landings_biomass"] == "biomass"),
  all(inputs$unit[inputs$measure == "landings_biomass"] == "million pounds gutted weight"),
  all(inputs$unit[inputs$measure == "relative_abundance_index"] == "relative index normalized to mean"),
  all(inputs$unit[inputs$measure == "log_index_sd"] == "log-scale standard error"),
  all(inputs$partition[inputs$measure == "landings_numbers"] == "landings"),
  all(inputs$partition[inputs$measure == "discard_numbers"] == "discards"),
  all(inputs$year[inputs$measure == "landings_numbers"] %in% 1963:2019),
  all(inputs$year[inputs$measure == "discard_numbers"] %in% 1963:2019),
  all(inputs$year[inputs$measure == "log_catch_sd"] %in% 1963:2019),
  all(inputs$year[inputs$measure == "discard_numbers" &
    inputs$fleet %in% c("Recreational charter", "Recreational headboat",
      "Recreational private + shore")] %in% 1981:2019),
  all(inputs$year[inputs$measure == "log_catch_sd" &
    inputs$fleet %in% c("Recreational charter", "Recreational headboat",
      "Recreational private + shore")] %in% 1981:2019),
  input_value("landings_numbers", 1963, "Recreational charter", "landings") == 97585,
  input_value("landings_numbers", 1963, "Recreational headboat", "landings") == 23007,
  input_value("landings_numbers", 1983, "Recreational private + shore", "landings") == 428677,
  input_value("landings_numbers", 2019, "Recreational private + shore", "landings") == 97999,
  input_value("discard_numbers", 1981, "Recreational charter", "discards") == 89783,
  input_value("discard_numbers", 1981, "Recreational headboat", "discards") == 56153,
  input_value("discard_numbers", 2019, "Recreational private + shore", "discards") == 1370264,
  input_value("log_catch_sd", 1981, "Recreational headboat", "landings") == 0.2,
  input_value("log_catch_sd", 1981, "Recreational private + shore", "landings") == 0.383,
  input_value("log_catch_sd", 1981, "Recreational charter", "discards") == 0.844,
  input_value("log_catch_sd", 1981, "Recreational headboat", "discards") == 1.046,
  input_value("landings_biomass", 1963, "Commercial vertical line + other", "landings") == 1.635,
  input_value("landings_biomass", 1979, "Commercial longline", "landings") == 0.001,
  input_value("discard_numbers", 2019, "Commercial vertical line + other", "discards") == 20.621,
  input_value("log_catch_sd", 2019, "Commercial vertical line + other", "discards") == 0.25,
  length(input_value("discard_numbers", 1981, "Commercial vertical line + other", "discards")) == 0L,
  input_value("relative_abundance_index", 1990, fleet = "Commercial vertical line") == 0.31,
  input_value("log_index_sd", 1990, fleet = "Commercial vertical line") == 0.63,
  input_value("relative_abundance_index", 2019, survey = "Age-0 index", age = "0") == 0.595,
  input_value("relative_abundance_index", 2019, survey = "PC video") == 1.383,
  nrow(outputs) == 3510L,
  all(outputs$source_type == "official_table"),
  all(table(output_key) == 1L),
  nrow(outputs[outputs$measure == "expected_landings_biomass", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_landings_numbers", ]) == 269L,
  nrow(outputs[outputs$measure == "mean_landings_weight", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_discard_numbers", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_dead_discard_numbers", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_discard_biomass", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_dead_discard_biomass", ]) == 269L,
  nrow(outputs[outputs$measure == "mean_discard_weight", ]) == 269L,
  nrow(outputs[outputs$measure == "expected_relative_abundance_index", ]) == 161L,
  value_at("expected_landings_biomass", 1963, fleet = "Commercial vertical line + other") == 1.637,
  value_at("expected_landings_numbers", 1963, fleet = "Commercial vertical line + other") == 87.144,
  value_at("expected_relative_abundance_index", 1990, fleet = "Commercial vertical line") == 1.18,
  value_at("expected_relative_abundance_index", 2019, survey = "SEAMAP video") == 0.389,
  nrow(outputs[outputs$measure == "exploitation_rate" &
    outputs$fleet == "All fleets excluding red tide", ]) == 57L,
  nrow(outputs[outputs$measure == "exploitation_rate" &
    outputs$fleet == "All fleets including red tide", ]) == 57L,
  nrow(outputs[outputs$measure == "total_biomass", ]) == 57L,
  nrow(outputs[outputs$measure == "exploitable_abundance" &
    is.na(outputs$sex), ]) == 57L,
  nrow(outputs[outputs$measure == "SSB" & is.na(outputs$sex), ]) == 57L,
  nrow(outputs[outputs$measure == "recruitment", ]) == 57L,
  value_at("total_biomass", 2019, sex = "") == 3636,
  value_at("exploitable_biomass", 2019, sex = "") == 2821,
  value_at("SSB", 2019, sex = "") == 1706,
  value_at("exploitable_abundance", 2019, sex = "") == 1154,
  value_at("recruitment", 2019, sex = "") == 2158,
  value_at("SSB_ratio_to_SSB0", 2019, sex = "") == 0.03,
  value_at("exploitation_rate", 2019, fleet = "All fleets excluding red tide") == 0.374,
  value_at("exploitation_rate", 2005, fleet = "Red tide mortality") == 0.633,
  value_at("exploitation_rate", 2005, fleet = "All fleets including red tide") == 0.960,
  value_at("SSB", 2019, sex = "female") == 1510,
  value_at("SSB", 2019, sex = "male") == 195,
  value_at("exploitable_biomass", 2019, sex = "female") == 2625,
  value_at("exploitable_abundance", 2019, sex = "male") == 20.64,
  value_at("male_to_female_exploitable_abundance_ratio", 2019, sex = "") == 1.8,
  nrow(outputs[outputs$measure == "numbers_at_age", ]) == 0L,
  nrow(outputs[outputs$measure == "fishing_mortality_at_age", ]) == 0L,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 5L,
  !anyDuplicated(manifest$file),
  all(grepl("^source_cache/noaa_gag_sedar72_2022/", manifest$file)),
  all(manifest$retrieved_utc == "2026-11-10"),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  grepl("Tables 6–9", review, fixed = TRUE),
  grepl("1,148 input rows", review, fixed = TRUE),
  grepl("numeric age-composition arrays", review, fixed = TRUE),
  grepl("not labelled as instantaneous F", review, fixed = TRUE)
)

cat("NOAA Gulf gag SEDAR 72 source inputs, outputs, units, run identity, and provenance passed.\n")
