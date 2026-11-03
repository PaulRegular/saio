source("R/read_database.R")
source_data <- read_assessment(
  "nefsc_white_hake_2025",
  read_database()
)

inputs <- source_data$inputs
outputs <- source_data$outputs
assessment <- source_data$assessment
assumptions <- source_data$assumptions
recruitment <- subset(assumptions, setting == "recruitment_and_initial_states")
survival <- subset(assumptions, setting == "cohort_survival")
initial <- subset(assumptions, setting == "initial_abundance")
projection_assumptions <- subset(assumptions, component == "projection")
stopifnot(
  nrow(recruitment) == 1L, nrow(survival) == 1L, nrow(initial) == 1L,
  nrow(projection_assumptions) == 2L,
  setequal(projection_assumptions$setting, c("harvest_scenario", "catch_2025")),
  grepl("0.176 yr-1", projection_assumptions$value[
    projection_assumptions$setting == "harvest_scenario"
  ], fixed = TRUE),
  grepl("1,802 metric tons", projection_assumptions$value[
    projection_assumptions$setting == "catch_2025"
  ], fixed = TRUE),
  grepl("steepness fixed at 1", recruitment$value, fixed = TRUE),
  grepl("lambda = 0", recruitment$notes, fixed = TRUE),
  grepl("sum-to-zero fixed-effect", recruitment$notes, fixed = TRUE),
  grepl("deterministic survival", survival$value, fixed = TRUE),
  grepl("not an annual N process", survival$notes, fixed = TRUE),
  grepl("Lambda is 1", initial$notes, fixed = TRUE),
  grepl("CV is 0.2", initial$notes, fixed = TRUE)
)
catch_age <- subset(inputs, type == "catch" & measure == "numbers_at_age")
catch_total <- subset(inputs, type == "catch" & measure == "total_biomass")
catch_cv <- subset(inputs, type == "catch" & measure == "relative_standard_error")
index_age <- subset(inputs, type == "index" & measure == "numbers_at_age")
index_total <- subset(inputs, type == "index" & measure == "total_numbers")
index_cv <- subset(inputs, type == "index" & measure == "relative_standard_error")
M <- subset(inputs, type == "M" & measure == "natural_mortality_at_age")
maturity <- subset(inputs, type == "maturity" & measure == "maturity_at_age")
weights <- subset(inputs, type %in% c("catch_weight", "weight", "start_weight_at_age"))

catch_weight <- inputs[inputs$type == "catch_weight", , drop = FALSE]
catch_number_key <- paste(catch_age$year, catch_age$age)
catch_age_weighted_biomass <- as.numeric(catch_age$value) *
  as.numeric(catch_weight$value[match(catch_number_key, paste(catch_weight$year, catch_weight$age))])
catch_totals_1989_2024 <- as.numeric(catch_total$value[
  match(1989:2024, as.integer(catch_total$year))
])
catch_sums <- tapply(catch_age_weighted_biomass, catch_age$year, sum)

stopifnot(
  source_data$stocks$common_name == "White hake",
  source_data$stocks$authority_stock_id == "GOM/GB",
  assessment$is_current,
  assessment$is_applied,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2024,
  assessment$inputs_status == "complete",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(catch_total) == 62L,
  identical(sort(unique(as.integer(catch_total$year))), 1963:2024),
  nrow(catch_age) == 36L * 9L,
  identical(sort(unique(as.integer(catch_age$year))), 1989:2024),
  all(catch_age$unit == "thousand fish"),
  all(catch_age$sample_size == 58),
  nrow(catch_cv) == 62L,
  all(catch_total$unit == "metric tons"),
  nrow(index_total) == 170L,
  nrow(index_age) == 170L * 9L,
  nrow(index_cv) == 170L,
  length(unique(index_age$survey)) == 5L,
  all(index_age$unit %in% c("number per tow", "number per set")),
  setequal(sort(unique(as.numeric(index_age$sampling_time))), c(.25, .5, .75)),
  nrow(M) == 9L,
  all(as.numeric(M$value) == .2),
  nrow(maturity) == 9L,
  nrow(weights) == 62L * 9L * 3L,
  nrow(outputs[outputs$measure == "SSB", ]) == 66L,
  nrow(outputs[outputs$measure == "Fbar", ]) == 66L,
  all(outputs$age_group[outputs$measure == "Fbar"] == "6-9+"),
  nrow(outputs[outputs$measure == "recruitment", ]) == 62L,
  nrow(outputs[outputs$measure == "predicted_catch", ]) == 4L,
  nrow(outputs[outputs$measure == "numbers_at_age", ]) == 0L,
  nrow(outputs[outputs$measure == "fishing_mortality_at_age", ]) == 0L,
  all(outputs$source_type == "official_table"),
  all(is.finite(as.numeric(outputs$se[outputs$year <= 2024]))),
  all(is.na(as.numeric(outputs$se[outputs$year > 2024]))),
  nrow(outputs[outputs$measure == "SSB" & outputs$year == 2025 &
    outputs$value == 13385 & outputs$lwr == 10960 & outputs$upr == 15861, ]) == 1L,
  nrow(outputs[outputs$measure == "Fbar" & outputs$year == 2025 &
    outputs$value == .144 & outputs$age_group == "6-9+", ]) == 1L,
  nrow(outputs[outputs$measure == "predicted_catch" & outputs$year == 2025 &
    outputs$value == 1802, ]) == 1L,
  nrow(outputs[outputs$measure == "SSB" & outputs$year == 2028 &
    outputs$value == 10219 & outputs$lwr == 8801 & outputs$upr == 11652, ]) == 1L,
  all(outputs$value[outputs$measure == "Fbar" &
    outputs$year %in% 2026:2028] == .176),
  all(grepl("Table 3", outputs$source_reference[outputs$year > 2024], fixed = TRUE)),
  max(abs(catch_sums[as.character(1989:2024)] /
    catch_totals_1989_2024 - 1)) < .03,
  file.exists("source_reviews/ck_nefsc_garmiii_tenuis_gom_gb.md")
)

cat("White Hake 2025 source coverage, units, timings, outputs and provenance passed.\n")
