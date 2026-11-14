root <- "."
import <- new.env(parent = globalenv())
source(file.path(root, "scripts/database/644_import_noaa_rougheye_blackspotted_2025.R"),
  local = import)

inputs <- import$input_data
outputs <- import$output_data
assessment <- import$assessment
review <- paste(readLines(file.path(root,
  "discovery/source_reviews/noaa_rougheye_blackspotted_2025.md"), warn = FALSE),
  collapse = " ")
composition_obs <- unique(inputs$observation_id[!is.na(inputs$observation_id)])

stopifnot(
  import$stock$stock_id == "noaa_uswc_rougheye_blackspotted",
  import$stock$ocean == "Northeast Pacific",
  assessment$assessment_year == "2025",
  assessment$terminal_year == "2024",
  assessment$estimate_terminal_year == "2025",
  nrow(inputs) == 216174L,
  sum(inputs$type == "catch" & inputs$measure == "catch_biomass") == 353L,
  sum(inputs$type == "catch" & inputs$measure == "catch_se") == 353L,
  sum(inputs$measure == "relative_biomass_index") == 38L,
  sum(inputs$measure == "log_index_sd") == 38L,
  all(inputs$sampling_time[inputs$measure %in% c(
    "relative_biomass_index", "log_index_sd")] == 0.5),
  sum(inputs$measure == "conditional_frequency_at_age") == 192900L,
  sum(inputs$measure == "frequency_at_age") == 11800L,
  sum(inputs$measure == "frequency_at_length") == 10692L,
  length(unique(inputs$observation_id[inputs$measure == "conditional_frequency_at_age"])) == 1929L,
  length(unique(inputs$observation_id[inputs$measure == "frequency_at_age"])) == 118L,
  length(unique(inputs$observation_id[inputs$measure == "frequency_at_length"])) == 297L,
  identical(sort(unique(as.integer(inputs$age_error[inputs$measure %in% c(
    "conditional_frequency_at_age", "frequency_at_age")]))), 1:7),
  all(inputs$value[inputs$measure %in% c(
    "conditional_frequency_at_age", "frequency_at_age", "frequency_at_length")] >= 0),
  !any(inputs$measure %in% c("catch_numbers", "catch_numbers_at_age")),
  length(composition_obs) == 2344L,
  nrow(outputs) == 562898L,
  sum(outputs$measure == "numbers_at_age") == 37506L,
  sum(outputs$measure == "biomass_at_age") == 37506L,
  sum(outputs$measure == "catch_numbers_at_age") == 225036L,
  sum(outputs$measure == "fishing_mortality_at_age") == 225036L,
  sum(outputs$measure == "natural_mortality_at_age") == 37240L,
  sum(outputs$measure == "total_numbers") == 133L,
  sum(outputs$measure == "total_biomass") == 133L,
  sum(outputs$measure == "recruitment") == 133L,
  sum(outputs$measure == "spawning_output") == 134L,
  sum(outputs$measure == "spawning_output_ratio_to_unfished") == 11L,
  sum(outputs$measure == "recruitment_deviation") == 10L,
  sum(outputs$measure == "fishing_intensity_1_minus_spr") == 10L,
  sum(outputs$measure == "exploitation_rate") == 10L,
  all(outputs$age_group[outputs$measure == "numbers_at_age" & outputs$age == 140] == "140+"),
  !any(outputs$measure == "natural_mortality_at_age" & outputs$age == 140),
  all(outputs$scenario[outputs$measure == "spawning_output" & outputs$year == 2025] == "forecast"),
  all(is.na(outputs$lwr[outputs$measure == "spawning_output" & outputs$year %in% 2015:2025])),
  all(is.finite(outputs$lwr[outputs$measure == "recruitment" & outputs$year %in% 2015:2024])),
  all(is.na(outputs$lwr[outputs$measure == "fishing_intensity_1_minus_spr"])),
  all(is.na(outputs$lwr[outputs$measure == "exploitation_rate"])),
  !any(outputs$measure == "SSB"),
  grepl("conflicting unit label", review, fixed = TRUE),
  grepl("Catch-at-age is not a direct model input", review, fixed = TRUE),
  grepl("3.30.23.1", review, fixed = TRUE),
  grepl("3.30.23.2", review, fixed = TRUE),
  import$candidate_update$import_status == "partial",
  import$inventory_update$import_status == "partial"
)

n2024 <- outputs[outputs$measure == "numbers_at_age" & outputs$year == 2024, ]
total2024 <- outputs[outputs$measure == "total_numbers" & outputs$year == 2024, ]
stopifnot(nrow(total2024) == 1L, abs(sum(n2024$value) - total2024$value) < 1e-8)

cat("NOAA rougheye/blackspotted 2025 source records passed.\n")
