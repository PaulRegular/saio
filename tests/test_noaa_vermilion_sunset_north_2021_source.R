cache <- "source_cache/discovery_noaa_vermilion_sunset_north_2021"
if (!file.exists(file.path(cache, "model_files_2021.zip"))) {
  cat("Northern California Vermilion/Sunset 2021 source test skipped; local cache is unavailable.\n")
} else {
  source_env <- new.env(parent = globalenv())
  old_test_mode <- Sys.getenv("TAM_SOURCE_TEST_MODE", unset = NA_character_)
  Sys.setenv(TAM_SOURCE_TEST_MODE = "1")
  source("scripts/database/674_import_noaa_vermilion_sunset_north_2021.R", local = source_env)
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

  one_output <- function(x, measure, year, sex = "combined") {
    z <- x[x$measure == measure & x$year == year & x$sex == sex, , drop = FALSE]
    if (nrow(z) != 1L) stop("Expected one output for ", measure, " in ", year, ".")
    z
  }

  stopifnot(
    records$stock$stock_id == "noaa_vermilion_sunset_northern_california",
    records$stock$authority_stock_id == "15335",
    records$stock$scientific_name == "Sebastes miniatus; Sebastes crocotulus",
    records$stock$ocean == "Northeast Pacific",
    records$assessment$assessment_year == 2021L,
    records$assessment$terminal_year == 2020L,
    records$assessment$estimate_terminal_year == 2021L,
    records$assessment$inputs_status == "partial",
    records$assessment$outputs_status == "partial",
    nrow(catch) == 542L,
    sum(catch$measure == "catch_biomass") == 274L,
    sum(catch$measure == "catch_numbers") == 268L,
    all(catch$year >= 1875L & catch$year <= 2020L),
    nrow(catch_sd) == 542L,
    nrow(indices) == 77L,
    nrow(index_sd) == 77L,
    length(unique(indices$survey)) == 5L,
    all(indices$sampling_time == 0.5),
    all(index_sd$sampling_time == 0.5),
    nrow(length_data) == 7192L,
    nrow(age_data) == 31524L,
    sum(age_data$measure == "conditional_frequency_at_age") == 29252L,
    sum(age_data$measure == "frequency_at_age") == 2272L,
    length(unique(length_data$observation_id)) == 205L,
    length(unique(age_data$observation_id)) == 224L,
    all(age_data$sample_size > 0),
    all(age_data$unit == "fish"),
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
    abs(one_output(outputs, "spawning_output", 2021L)$value - 489.439) < 0.001,
    abs(one_output(outputs, "spawning_output", 2021L)$lwr - 263.228) < 0.001,
    abs(one_output(outputs, "spawning_output", 2021L)$upr - 715.650) < 0.001,
    abs(one_output(outputs, "recruitment", 2021L)$value - 371.777) < 0.001,
    one_output(outputs, "recruitment", 2021L)$lwr == 140,
    one_output(outputs, "recruitment", 2021L)$upr == 991,
    abs(one_output(outputs, "spawning_output_ratio_to_unfished", 2021L)$value - 0.427) < 0.001,
    nrow(m_parameter) == 2L,
    setequal(m_parameter$sex, c("female", "male")),
    abs(m_parameter$value[m_parameter$sex == "female"] - 0.0855991) < 1e-6,
    abs(m_parameter$value[m_parameter$sex == "male"] - 0.0804851) < 1e-6,
    all(is.finite(m_parameter$se)),
    source_env$candidate_update$matched_stock_id == records$stock$stock_id,
    source_env$candidate_update$import_status == "partial",
    source_env$inventory_update$matched_stock_id == records$stock$stock_id,
    all(nzchar(inputs$source_reference)),
    all(nzchar(outputs$source_reference))
  )

  cat("NOAA Northern California Vermilion/Sunset 2021 inputs, outputs, uncertainty, units and gaps passed.\n")
}
