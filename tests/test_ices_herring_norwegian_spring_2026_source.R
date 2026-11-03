source("R/read_database.R")

id <- "ices_herring_norwegian_spring_2026"
old_id <- "ices_herring_norwegian_spring_2025"
database <- read_database()
record <- read_assessment(id, database)
inputs <- record$inputs
outputs <- record$outputs

catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
catch_rse <- inputs[inputs$type == "catch" & inputs$measure == "relative_standard_error", ]
stock_weight <- inputs[inputs$type == "weight" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$type == "maturity" & inputs$measure == "maturity_at_age", ]
n_at_age <- outputs[outputs$measure == "numbers_at_age", ]
f_at_age <- outputs[outputs$measure == "fishing_mortality_at_age", ]

stopifnot(
  record$assessment$is_current,
  record$assessment$assessment_year == 2026,
  record$assessment$terminal_year == 2025,
  record$assessment$estimate_terminal_year == 2026,
  record$assessment$assessment_type == "annual_assessment",
  database$assessments$is_current[database$assessments$assessment_id == old_id] == FALSE,
  record$assessment$inputs_status == "partial",
  identical(sort(unique(as.integer(catch$year))), 1988:2025),
  identical(sort(unique(as.integer(catch$age))), 2:15),
  nrow(catch) == 38L * 14L,
  all(catch$unit == "thousand fish"),
  nrow(catch_rse) == 38L * 11L,
  all(stock_weight$year %in% 1988:2026),
  all(maturity$year_basis == "birth_cohort"),
  setequal(inputs$value[inputs$type == "M" & inputs$age == 2], 0.9),
  setequal(inputs$value[inputs$type == "M" & inputs$age > 2], 0.15),
  all(n_at_age$year %in% 1988:2026),
  all(f_at_age$year %in% 1988:2026),
  nrow(n_at_age) == 39L * 11L,
  nrow(f_at_age) == 39L * 11L,
  outputs$value[outputs$measure == "numbers_at_age" &
    outputs$year == 2026 & outputs$age == 2] == 15270,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2026] == 2931,
  outputs$unit[outputs$measure == "SSB"] == "thousand tonnes",
  outputs$value[outputs$measure == "recruitment" & outputs$year == 2026] == 15270,
  outputs$value[outputs$measure == "total_abundance" & outputs$year == 2026] ==
    sum(n_at_age$value[n_at_age$year == 2026]),
  all(outputs$source_type[outputs$measure == "total_abundance"] == "derived_source_output"),
  all(grepl("33882730", outputs$source_reference[outputs$measure %in% c("SSB", "recruitment")])),
  any(inputs$survey == "NASF_2015_onward" & inputs$year == 2026 &
    inputs$age == 3 & inputs$measure == "numbers_at_age"),
  any(inputs$survey == "IESNS_Barents" & inputs$year == 2026 &
    inputs$age == 2 & inputs$measure == "numbers_at_age"),
  any(inputs$survey == "IESNS_Norwegian_Sea" & inputs$year == 2026 &
    inputs$age == 3 & inputs$measure == "numbers_at_age"),
  any(inputs$survey == "BESS" & inputs$year == 2025 &
    inputs$age == 2 & inputs$measure == "numbers_at_age"),
  all(as.numeric(inputs$sampling_time[!is.na(inputs$survey) & inputs$survey == "NASF_2015_onward" & inputs$measure == "numbers_at_age"]) == 0.13),
  all(as.numeric(inputs$sampling_time[!is.na(inputs$survey) & inputs$survey == "IESNS_Barents" & inputs$measure == "numbers_at_age"]) == 0.42),
  all(as.numeric(inputs$sampling_time[!is.na(inputs$survey) & inputs$survey == "IESNS_Norwegian_Sea" & inputs$measure == "numbers_at_age"]) == 0.38),
  all(as.numeric(inputs$sampling_time[!is.na(inputs$survey) & inputs$survey == "BESS" & inputs$measure == "numbers_at_age"]) == 0.75),
  any(inputs$survey == "RFID" & inputs$measure == "relative_standard_error"),
  !any(!is.na(inputs$survey) & inputs$survey == "RFID" & inputs$measure == "numbers_at_age"),
  !any(outputs$measure == "Fbar" & outputs$year == 2026),
  !any(outputs$type == "catch" & outputs$measure == "total_biomass" &
    outputs$year == 2026),
  any(outputs$type == "biomass" & outputs$measure == "total_biomass" &
    outputs$year == 2026),
  !anyDuplicated(outputs[c("type", "measure", "year", "age", "age_group")])
)

cat("Norwegian spring-spawning herring 2026 source record passed.\n")
