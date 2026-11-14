cache <- "source_cache/discovery_noaa_vermilion_sunset_south_2021"
if (!file.exists(file.path(cache, "model_files_2021.zip"))) {
  cat("Southern California Vermilion/Sunset 2021 source test skipped; local cache is unavailable.\n")
} else {
  source_env <- new.env(parent = globalenv())
  old_test_mode <- Sys.getenv("TAM_SOURCE_TEST_MODE", unset = NA_character_)
  Sys.setenv(TAM_SOURCE_TEST_MODE = "1")
  source("scripts/database/673_import_noaa_vermilion_sunset_south_2021.R", local = source_env)
  if (is.na(old_test_mode)) Sys.unsetenv("TAM_SOURCE_TEST_MODE") else
    Sys.setenv(TAM_SOURCE_TEST_MODE = old_test_mode)

  records <- source_env$source_records
  inputs <- records$inputs
  outputs <- records$outputs
  catch <- inputs[inputs$measure %in% c("catch_biomass", "catch_numbers"), , drop = FALSE]
  catch_sd <- inputs[inputs$measure == "log_catch_sd", , drop = FALSE]
  indices <- inputs[inputs$measure == "relative_abundance_index", , drop = FALSE]
  index_sd <- inputs[inputs$measure == "log_index_sd", , drop = FALSE]
  length_data <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
  age_data <- inputs[inputs$measure %in% c("frequency_at_age", "conditional_frequency_at_age"), , drop = FALSE]
  n <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
  b <- outputs[outputs$measure == "biomass_at_age", , drop = FALSE]
  f <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
  m <- outputs[outputs$measure == "natural_mortality_at_age", , drop = FALSE]
  w <- outputs[outputs$measure == "weight_at_age", , drop = FALSE]
  spawning <- outputs[outputs$measure == "spawning_output", , drop = FALSE]
  depletion <- outputs[outputs$measure == "spawning_output_ratio_to_unfished", , drop = FALSE]
  recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]
  total_n <- outputs[outputs$measure == "total_numbers", , drop = FALSE]
  m_parameter <- outputs[outputs$measure == "natural_mortality_average_parameter", , drop = FALSE]

  stopifnot(
    nrow(records$stock) == 1L,
    records$stock$scientific_name == "Sebastes miniatus; Sebastes crocotulus",
    records$stock$ocean == "Northeast Pacific",
    records$stock$area == "U.S. waters off California south of Point Conception",
    records$assessment$assessment_year == 2021L,
    records$assessment$terminal_year == 2020L,
    records$assessment$estimate_terminal_year == 2021L,
    records$assessment$inputs_status == "partial",
    records$assessment$outputs_status == "partial",
    nrow(catch) == 510L,
    sum(catch$measure == "catch_biomass") > 0L,
    sum(catch$measure == "catch_numbers") > 0L,
    all(catch$year >= 1875L & catch$year <= 2020L),
    nrow(catch_sd) == 510L,
    all(catch_sd$value == 0.01),
    nrow(indices) == 71L,
    nrow(index_sd) == 71L,
    length(unique(indices$survey)) == 4L,
    all(indices$sampling_time == 0.5),
    all(index_sd$sampling_time == 0.5),
    nrow(length_data) == 6880L,
    nrow(age_data) == 89602L,
    sum(age_data$measure == "conditional_frequency_at_age") == 84774L,
    sum(age_data$measure == "frequency_at_age") == 4828L,
    all(length_data$basis == "native_frequency"),
    all(age_data$basis == "native_frequency"),
    all(age_data$unit == "fish"),
    all(age_data$sample_size > 0),
    length(unique(age_data$observation_id)) == 631L,
    any(grepl("_y-", age_data$observation_id, fixed = TRUE)),
    any(grepl("_f-", age_data$observation_id, fixed = TRUE)),
    !any(inputs$measure == "numbers_at_age"),
    nrow(n) == 146L * 2L * 71L,
    nrow(b) == 146L * 2L * 71L,
    nrow(f) == 146L * 7L * 2L * 71L,
    nrow(m) == 146L * 2L * 57L,
    all(sort(unique(as.integer(m$age))) == 13:69),
    nrow(w) == 146L * 2L * 71L,
    nrow(total_n) == 146L,
    nrow(spawning) == 147L,
    nrow(depletion) == 11L,
    nrow(recruitment) == 147L,
    all(spawning$unit == "million eggs"),
    !any(outputs$measure == "SSB"),
    spawning$value[spawning$year == 2021L] == 471.178,
    spawning$lwr[spawning$year == 2021L] == 228.525,
    spawning$upr[spawning$year == 2021L] == 713.831,
    recruitment$value[recruitment$year == 2021L] == 736.076,
    recruitment$lwr[recruitment$year == 2021L] == 273,
    recruitment$upr[recruitment$year == 2021L] == 1986,
    depletion$value[depletion$year == 2021L] == 0.482,
    depletion$lwr[depletion$year == 2021L] == 0.256,
    depletion$upr[depletion$year == 2021L] == 0.708,
    nrow(m_parameter) == 1L,
    abs(m_parameter$value - 0.13023) < 1e-6,
    abs(m_parameter$se - 0.0119792) < 1e-7,
    all(nzchar(inputs$source_reference)),
    all(nzchar(outputs$source_reference))
  )
  cat("NOAA Southern California Vermilion/Sunset 2021 source inputs, outputs, intervals, units and gaps passed.\n")
}
