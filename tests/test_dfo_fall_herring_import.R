root <- "."
env <- new.env(parent = globalenv())
env$write_database <- FALSE
sys.source(
  file.path(root, "scripts", "database", "075_import_dfo_sgsl_fall_herring_2024.R"),
  envir = env
)

stopifnot(
  env$assessment$assessment_id == "dfo_herring_4tvn_fall_2024",
  env$summary_assessment$assessment_id == "dfo_herring_4tvn_fall_2026",
  env$stock$charbonneau_id == "DFO-GSL_harengus_4T-Fall",
  env$assessment$terminal_year == 2023,
  env$summary_assessment$terminal_year == 2025,
  env$same_mobile_as_fixed,
  nrow(env$catch_fixed) == 46L * 3L * 10L,
  nrow(env$catch_mobile) == nrow(env$catch_fixed),
  nrow(env$weight_fixed) == 46L * 3L * 10L,
  identical(sort(unique(env$weight_mobile$year)), 1978:2022),
  identical(sort(unique(env$cpue$year)), 1986:2023),
  identical(sort(unique(env$acoustic$year)), 1994:2023),
  identical(sort(unique(env$rv$year)), 1994:2023),
  all(env$inputs$unit[env$inputs$survey == "4Tmno acoustic survey"] == "thousand fish"),
  all(env$inputs$unit[env$inputs$survey == "DFO multispecies RV survey"] == "mean number per tow"),
  all(is.finite(env$inputs$value)),
  all(is.finite(env$outputs$value)),
  all(grepl(
    "suspected publication transcription error",
    env$inputs$notes[env$inputs$fleet == "Mobile gear" & env$inputs$type == "catch"],
    fixed = TRUE
  )),
  !anyNA(env$outputs$assessment_id),
  !anyDuplicated(env$outputs[c("assessment_id", "measure", "region", "year", "age", "age_group")]),
  nrow(env$outputs[env$outputs$measure == "SSB", ]) == 46L,
  nrow(env$outputs[env$outputs$measure == "recruitment", ]) == 46L,
  nrow(env$outputs[env$outputs$measure == "Fbar", ]) == 184L,
  env$outputs$value[
    env$outputs$measure == "SSB" & env$outputs$year == 1978
  ] == 65435,
  env$summary_output$value == 321000,
  env$summary_output$lwr == 259000,
  env$summary_output$upr == 433000,
  nrow(env$summary_inputs) == 32L,
  all(env$summary_inputs$unit == "tonnes")
)

for (year in 1978:2023) {
  total_n <- env$outputs[
    env$outputs$measure == "total_numbers" &
      env$outputs$age_group == "2-11+" & env$outputs$year == year,
  ]
  total_b <- env$outputs[
    env$outputs$measure == "total_biomass" &
      env$outputs$age_group == "2-11+" & env$outputs$year == year,
  ]
  n_at_age <- env$outputs[
    env$outputs$measure == "numbers_at_age" &
      env$outputs$region == "" & env$outputs$year == year,
  ]
  b_at_age <- env$outputs[
    env$outputs$measure == "biomass_at_age" &
      env$outputs$region == "" & env$outputs$year == year,
  ]
  stopifnot(
    nrow(total_n) == 1L, nrow(total_b) == 1L,
    isTRUE(all.equal(total_n$value, sum(n_at_age$value))),
    isTRUE(all.equal(total_b$value, sum(b_at_age$value)))
  )
}

cat("Southern Gulf fall herring source import tests passed.\n")
