source("R/read_database.R")

source_data <- read_database()
assessment_ids <- c(
  "nefsc_american_plaice_5yz_2022_run29f4",
  "nefsc_american_plaice_5yz_2024_mt",
  "nefsc_american_plaice_5yz_2026_mt_provisional"
)
assessments <- source_data$assessments[
  source_data$assessments$assessment_id %in% assessment_ids,
  , drop = FALSE
]
inputs <- source_data$inputs
outputs <- source_data$outputs

candidate_id <- assessment_ids[[1L]]
candidate <- assessments[assessments$assessment_id == candidate_id, , drop = FALSE]
stock <- source_data$stocks[
  source_data$stocks$stock_id == candidate$stock_id,
  , drop = FALSE
]
candidate_inputs <- inputs[inputs$assessment_id == candidate_id, , drop = FALSE]
candidate_outputs <- outputs[outputs$assessment_id == candidate_id, , drop = FALSE]

stopifnot(
  nrow(assessments) == 3L,
  nrow(stock) == 1L,
  stock$scientific_name == "Hippoglossoides platessoides",
  stock$common_name == "American plaice",
  stock$area == "5YZ",
  grepl("Gulf of Maine/Georges Bank", stock$notes),
  !isTRUE(candidate$is_current),
  !isTRUE(candidate$is_applied),
  candidate$assessment_type == "research_track_candidate",
  candidate$assumptions_status == "partial",
  candidate$inputs_status == "complete",
  candidate$outputs_status == "complete"
)

catch_total <- candidate_inputs[
  candidate_inputs$type == "catch" & candidate_inputs$measure == "total_numbers",
  , drop = FALSE
]
catch_paa <- candidate_inputs[
  candidate_inputs$type == "catch" & candidate_inputs$measure == "proportion_at_age",
  , drop = FALSE
]
index_total <- candidate_inputs[
  candidate_inputs$type == "index" & candidate_inputs$measure == "total_biomass",
  , drop = FALSE
]
index_paa <- candidate_inputs[
  candidate_inputs$type == "index" & candidate_inputs$measure == "proportion_at_age",
  , drop = FALSE
]
index_sd <- candidate_inputs[
  candidate_inputs$type == "index" & candidate_inputs$measure == "log_index_sd",
  , drop = FALSE
]
M <- candidate_inputs[
  candidate_inputs$type == "M" & candidate_inputs$measure == "natural_mortality_at_age",
  , drop = FALSE
]

catch_sums <- aggregate(value ~ year, catch_paa, sum)
index_sums <- aggregate(value ~ survey + year, index_paa, sum)
stopifnot(
  nrow(catch_total) == 40L,
  identical(sort(unique(catch_total$year)), 1980:2019),
  all(catch_total$unit == "thousand fish"),
  nrow(catch_paa) == 40L * 11L,
  identical(sort(unique(catch_paa$age)), 1:11),
  all(catch_paa$basis == "proportion_numbers"),
  all(abs(catch_sums$value - 1) < 1e-8),
  all(catch_paa$sample_size == 100),
  nrow(index_total) == 80L,
  nrow(index_sd) == 80L,
  nrow(index_paa) == 80L * 11L,
  length(unique(index_paa$survey)) == 4L,
  all(index_total$unit == "kg/tow"),
  all(index_paa$basis == "proportion_numbers"),
  all(index_paa$sample_size == 50),
  all(abs(index_sums$value - 1) < 1e-8),
  nrow(M) == 11L,
  all(M$unit == "per year"),
  all(abs(M$value - 0.3) < 1e-12),
  nrow(candidate_outputs[candidate_outputs$measure == "numbers_at_age", ]) == 40L * 11L,
  nrow(candidate_outputs[candidate_outputs$measure == "fishing_mortality_at_age", ]) == 40L * 11L,
  nrow(candidate_outputs[candidate_outputs$measure == "SSB", ]) == 40L,
  nrow(candidate_outputs[candidate_outputs$measure == "recruitment", ]) == 40L,
  nrow(candidate_outputs[candidate_outputs$measure == "total_numbers", ]) == 40L,
  !any(candidate_outputs$measure == "natural_mortality_at_age"),
  all(is.finite(candidate_outputs$se[candidate_outputs$measure %in% c(
    "numbers_at_age", "fishing_mortality_at_age", "SSB", "recruitment", "Fbar"
  )]))
)

n <- candidate_outputs[candidate_outputs$measure == "numbers_at_age", ]
total_n <- candidate_outputs[candidate_outputs$measure == "total_numbers", ]
recruitment <- candidate_outputs[candidate_outputs$measure == "recruitment", ]
stopifnot(
  all(abs(total_n$value[match(1980:2019, total_n$year)] -
    vapply(1980:2019, function(year) sum(n$value[n$year == year]), numeric(1))) < 1e-8),
  all(recruitment$value[match(1980:2019, recruitment$year)] ==
    n$value[match(paste(1980:2019, 1), paste(n$year, n$age))])
)

summary_2024 <- outputs[outputs$assessment_id == assessment_ids[[2L]], , drop = FALSE]
summary_2026 <- outputs[outputs$assessment_id == assessment_ids[[3L]], , drop = FALSE]
summary_2024_inputs <- inputs[inputs$assessment_id == assessment_ids[[2L]], , drop = FALSE]
summary_2024_landings <- summary_2024_inputs[
  summary_2024_inputs$measure == "landings_biomass", , drop = FALSE
]
summary_2024_discards <- summary_2024_inputs[
  summary_2024_inputs$measure == "discard_biomass", , drop = FALSE
]
summary_2024_catch <- summary_2024_inputs[
  summary_2024_inputs$measure == "total_biomass", , drop = FALSE
]
summary_2024_landings <- summary_2024_landings[order(summary_2024_landings$year), ]
summary_2024_discards <- summary_2024_discards[order(summary_2024_discards$year), ]
summary_2024_catch <- summary_2024_catch[order(summary_2024_catch$year), ]
later <- assessments[match(assessment_ids[2:3], assessments$assessment_id), , drop = FALSE]
stopifnot(
  !later$is_current[[1L]], isTRUE(later$is_applied[[1L]]),
  later$is_current[[2L]], !isTRUE(later$is_applied[[2L]]),
  identical(later$assessment_type[[2L]], "management_track_update"),
  setequal(unique(summary_2024$year), 2014:2023),
  setequal(unique(summary_2026$year[!is.na(summary_2026$year)]), 2015:2025),
  nrow(summary_2024_landings) == 10L,
  nrow(summary_2024_discards) == 10L,
  nrow(summary_2024_catch) == 10L,
  identical(as.integer(summary_2024_landings$year), 2014:2023),
  identical(as.integer(summary_2024_discards$year), 2014:2023),
  identical(as.integer(summary_2024_catch$year), 2014:2023),
  identical(as.numeric(summary_2024_landings$value),
    c(1239, 1231, 1009, 1134, 1087, 970, 597, 631, 699, 1168)),
  identical(as.numeric(summary_2024_discards$value),
    c(92, 86, 108, 102, 109, 78, 74, 71, 58, 77)),
  identical(as.numeric(summary_2024_catch$value),
    c(1331, 1317, 1117, 1235, 1196, 1048, 671, 702, 757, 1244)),
  all(summary_2024_inputs$unit == "metric tonnes"),
  all(summary_2024_inputs$source_type == "official_table"),
  all(summary_2024_inputs$fleet == "Commercial fishery"),
  all(abs(summary_2024_landings$value + summary_2024_discards$value -
    summary_2024_catch$value) <= 1),
  !any(summary_2024$type == "catch"),
  !any(summary_2026$measure == "total_biomass"),
  nrow(summary_2024) == 30L,
  !any(summary_2024$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  !any(summary_2026$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  all(is.na(summary_2024$se)),
  all(is.na(summary_2026$se))
)

cat("NEFSC American plaice 5YZ source coverage, units, status, and derived outputs passed.\n")
