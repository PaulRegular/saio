source_env <- new.env(parent = globalenv())
old_test_mode <- Sys.getenv("TAM_SOURCE_TEST_MODE", unset = NA_character_)
Sys.setenv(TAM_SOURCE_TEST_MODE = "1")
source("scripts/database/645_import_noaa_cabezon_oregon_2019.R", local = source_env)
if (is.na(old_test_mode)) Sys.unsetenv("TAM_SOURCE_TEST_MODE") else
  Sys.setenv(TAM_SOURCE_TEST_MODE = old_test_mode)

inputs <- source_env$inputs_new
outputs <- source_env$outputs_new
assumptions <- source_env$assumptions_new
catch <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", , drop = FALSE]
catch_se <- inputs[inputs$type == "catch" & inputs$measure == "catch_se", , drop = FALSE]
indices <- inputs[inputs$type == "index" &
  inputs$measure %in% c("relative_biomass_index", "relative_abundance_index"), , drop = FALSE]
index_sd <- inputs[inputs$measure == "log_index_sd", , drop = FALSE]
length_data <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
age_data <- inputs[inputs$measure == "frequency_at_age", , drop = FALSE]
conditional_age <- inputs[inputs$measure == "conditional_frequency_at_age", , drop = FALSE]
m_input <- inputs[inputs$type == "M", , drop = FALSE]
n <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
f <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
m <- outputs[outputs$measure == "natural_mortality_at_age", , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]

stopifnot(
  nrow(inputs) == 20260L,
  nrow(assumptions) == 11L,
  nrow(outputs) == 24795L,
  nrow(catch) == 196L,
  nrow(catch_se) == 196L,
  isTRUE(all.equal(sort(unique(as.integer(catch$year))), 1970:2018)),
  all(catch$unit == "metric tons"),
  nrow(indices) == 68L,
  nrow(index_sd) == 68L,
  length(unique(indices$survey)) == 4L,
  all(indices$sampling_time == 0.5),
  all(index_sd$basis == "log_scale"),
  nrow(length_data) == 7155L,
  nrow(age_data) == 1512L,
  nrow(conditional_age) == 11025L,
  length(unique(sub(":source_fleet.*", "", length_data$observation_id))) == 129L,
  length(unique(sub(":source_fleet.*", "", age_data$observation_id))) == 72L,
  length(unique(sub(":source_fleet.*", "", conditional_age$observation_id))) == 525L,
  all(conditional_age$type == "biology" & !is.na(conditional_age$length_bin_lower) &
    !is.na(conditional_age$length_bin_upper)),
  nrow(m_input) == 40L,
  all(m_input$measure == "natural_mortality_at_age" & is.na(m_input$year)),
  all(m_input$value[m_input$sex == "female"] == 0.24),
  all(abs(m_input$value[m_input$sex == "male"] - 0.279958) < 1e-7),
  nrow(n) == 2058L,
  identical(sort(unique(n$year)), 1970:2018),
  isTRUE(all.equal(sort(unique(as.integer(n$age))), 0:20)),
  all(n$unit == "thousand fish"),
  nrow(f) == 8232L,
  length(unique(f$fleet)) == 4L,
  nrow(m) == 1960L,
  all(m$age <= 19L),
  nrow(ssb) == 50L,
  ssb$value[ssb$year == 2019L] == 177,
  ssb$lwr[ssb$year == 2019L] == 128,
  ssb$upr[ssb$year == 2019L] == 226,
  ssb$scenario[ssb$year == 2019L] == "assessment forecast",
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  any(outputs$type == "catch" & outputs$measure == "catch_numbers_at_age"),
  all(inputs$source_type == "native_model"),
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference)),
  any(grepl("observed catch-numbers-at-age", assumptions$notes, fixed = TRUE)),
  file.exists("provenance/noaa_cabezon_oregon_2019_sources.csv"),
  file.exists("discovery/source_reviews/noaa_cabezon_2019.md")
)

cat("NOAA Oregon cabezon 2019 native source extraction and output checks passed.\n")
