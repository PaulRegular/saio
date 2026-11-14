cache <- "source_cache/discovery_noaa_gopher_black_yellow_2019"
if (!file.exists(file.path(cache, "post_model_files_2019.zip"))) {
  cat("Gopher/Black-and-Yellow 2019 cached source test skipped; local cache is unavailable.\n")
} else {

source_env <- new.env(parent = globalenv())
old_test_mode <- Sys.getenv("TAM_SOURCE_TEST_MODE", unset = NA_character_)
Sys.setenv(TAM_SOURCE_TEST_MODE = "1")
source("scripts/database/672_import_noaa_gopher_black_yellow_2019.R", local = source_env)
if (is.na(old_test_mode)) Sys.unsetenv("TAM_SOURCE_TEST_MODE") else
  Sys.setenv(TAM_SOURCE_TEST_MODE = old_test_mode)

records <- source_env$source_records
inputs <- records$inputs
outputs <- records$outputs
assumptions <- records$assumptions
catch <- inputs[inputs$measure == "catch_biomass", , drop = FALSE]
catch_sd <- inputs[inputs$measure == "log_catch_sd", , drop = FALSE]
indices <- inputs[inputs$measure %in% c("relative_abundance_index", "recruitment_index"), , drop = FALSE]
length_data <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
age_data <- inputs[inputs$measure == "conditional_frequency_at_age", , drop = FALSE]
composition_weights <- inputs[inputs$measure == "observation_likelihood_weight", , drop = FALSE]
n <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
f <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
m <- outputs[outputs$measure == "natural_mortality_at_age", , drop = FALSE]
w <- outputs[outputs$measure == "weight_at_age", , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]
depletion <- outputs[outputs$measure == "spawning_output_ratio_to_unfished", , drop = FALSE]

length_example <- length_data[length_data$observation_id == "length_row29_f2_-1959", , drop = FALSE]
age_example <- age_data[age_data$observation_id == "age_row1_f2_1978", , drop = FALSE]
recruit_2018 <- recruitment[recruitment$year == 2018L, , drop = FALSE]
depletion_2019 <- depletion[depletion$year == 2019L, , drop = FALSE]
evaluation_weights <- composition_weights[
  grepl("_-[0-9]{4}$", composition_weights$observation_id), , drop = FALSE]

stopifnot(
  nrow(records$stock) == 1L,
  records$stock$scientific_name == "Sebastes carnatus; Sebastes chrysomelas",
  records$stock$ocean == "Northeast Pacific",
  records$stock$area == "South of 40°10' N latitude (Cape Mendocino to the US-Mexico border)",
  records$assessment$assessment_year == 2019L,
  records$assessment$terminal_year == 2018L,
  records$assessment$estimate_terminal_year == 2019L,
  records$assessment$inputs_status == "partial",
  records$assessment$outputs_status == "partial",
  records$assessment$is_current,
  records$assessment$is_applied,
  nrow(catch) == 309L,
  nrow(catch_sd) == 285L,
  all(catch$unit == "metric tonnes"),
  all(abs(catch_sd$value - 0.01) < 1e-12),
  nrow(indices) == 84L,
  length(unique(indices$survey)) == 6L,
  all(indices$sampling_time == 0.5),
  sum(indices$measure == "recruitment_index") == 18L,
  sum(indices$measure == "relative_abundance_index") == 66L,
  nrow(length_data) == 151L * 37L,
  nrow(age_data) == 362L * 29L,
  all(length_data$basis == "native_frequency"),
  all(age_data$basis == "native_frequency"),
  all(length_data$sample_size > 0),
  all(age_data$sample_size > 0),
  nrow(length_example) == 37L,
  all(length_example$year == 1959L),
  all(grepl("-1959", length_example$observation_id, fixed = TRUE)),
  isTRUE(all.equal(sum(length_example$value), 271)),
  all(length_example$sample_size == 64.498),
  nrow(age_example) == 29L,
  age_example$value[age_example$age == 9L] == 1,
  all(age_example$length_bin_lower == 29L & age_example$length_bin_upper == 29L),
  all(age_example$age_error == 1L),
  nrow(composition_weights) > 0L,
  all(!is.na(inputs$type)),
  all(!is.na(composition_weights$type)),
  all(composition_weights$basis == "relative_scale"),
  all(composition_weights$year > 0L),
  nrow(evaluation_weights) == 15L,
  all(evaluation_weights$year == abs(as.integer(sub(
    ".*_(-[0-9]+)$", "\\1", evaluation_weights$observation_id)))),
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  !any(inputs$type == "index" & inputs$measure == "numbers_at_age"),
  nrow(n) == 103L * 29L,
  nrow(f) == 103L * 3L * 29L,
  length(unique(f$fleet)) == 3L,
  nrow(m) == 103L * 28L,
  nrow(w) == 103L * 29L,
  nrow(ssb) == 104L,
  ssb$value[ssb$year == 2018L] == 552.937,
  ssb$value[ssb$year == 2019L] == 552.482,
  ssb$scenario[ssb$year == 2019L] == "2019 forecast",
  nrow(recruit_2018) == 1L,
  recruit_2018$value == 1432.45,
  recruit_2018$lwr == 664,
  recruit_2018$upr == 3089,
  nrow(depletion_2019) == 1L,
  depletion_2019$value == 43.82,
  depletion_2019$lwr == 33.57,
  depletion_2019$upr == 54.06,
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference)),
  any(grepl("not attached to the mass-scale SpawnBio series", paste(assumptions$value, assumptions$notes), fixed = TRUE))
)

cat("NOAA Gopher/Black-and-Yellow 2019 inputs, output surfaces, timing, units and gaps passed.\n")
}
