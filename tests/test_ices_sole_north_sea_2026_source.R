root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- file.path(root, "analysis", "comp_assessments", "database")
read_table <- function(name) data.table::fread(
  file.path(database, name), na.strings = c("", "NA"), data.table = FALSE
)

assessment_id <- "ices_sole_north_sea_2026_summary"
assessments <- read_table("assessments.csv")
assumptions <- read_table("assumptions.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
current <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
historical <- assessments[assessments$assessment_id == "ices_sole_north_sea_2025", , drop = FALSE]
source_inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
source_outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
source_assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]

landings <- source_inputs[source_inputs$fleet == "Landings" & source_inputs$type == "catch", ]
discards <- source_inputs[source_inputs$fleet == "Discards" & source_inputs$type == "catch", ]
landings_weight <- source_inputs[source_inputs$measure == "landings_weight_at_age", ]
discard_weight <- source_inputs[source_inputs$measure == "discard_weight_at_age", ]
stock_weight <- source_inputs[source_inputs$measure == "weight_at_age", ]
bts <- source_inputs[source_inputs$survey == "BTS Q3", ]
coast <- source_inputs[source_inputs$survey == "COAST (SNS + DYFS)", ]
n_at_age <- source_outputs[source_outputs$measure == "numbers_at_age", ]
f_at_age <- source_outputs[source_outputs$measure == "fishing_mortality_at_age", ]
total_numbers <- source_outputs[source_outputs$measure == "total_numbers", ]
landings_2025_age10 <- landings$value[landings$year == 2025L & landings$age == 10L]
bts_2025 <- bts$value[bts$year == 2025L]
coast_2025 <- coast$value[coast$year == 2025L]
n_2025_age0 <- n_at_age$value[n_at_age$year == 2025L & n_at_age$age == 0L]
f_2025_age6 <- f_at_age$value[f_at_age$year == 2025L & f_at_age$age == 6L]
total_2025 <- total_numbers$value[total_numbers$year == 2025L]

stopifnot(
  nrow(current) == 1L,
  current$is_current,
  current$is_applied,
  current$assessment_year == 2026L,
  current$terminal_year == 2025L,
  current$estimate_terminal_year == 2026L,
  current$model_family == "Stock Synthesis",
  current$model_version == "3.30.24.2",
  current$inputs_status == "partial",
  current$outputs_status == "partial",
  !historical$is_current,
  current$assessment_url == "https://doi.org/10.17895/ices.pub.32676345",
  nrow(source_inputs) == 3394L,
  nrow(landings) == 69L * 11L,
  nrow(discards) == 24L * 11L,
  setequal(unique(landings$year), 1957:2025),
  setequal(unique(discards$year), 2002:2025),
  setequal(unique(landings$age), 0:10),
  all(landings$age == 0 | landings$age <= 10),
  all(landings$value[landings$age == 0] == 0),
  all(landings$unit == "thousand fish"),
  all(discards$unit == "thousand fish"),
  nrow(landings_weight) == 69L * 11L,
  nrow(discard_weight) == 69L * 11L,
  nrow(stock_weight) == 69L * 11L,
  nrow(source_inputs[source_inputs$type == "maturity", ]) == 11L,
  nrow(source_inputs[source_inputs$type == "M", ]) == 11L,
  nrow(bts) == 36L,
  nrow(coast) == 36L,
  setequal(unique(bts$year), 1990:2025),
  setequal(unique(coast$year), 1990:2025),
  all(bts$sampling_time == 0.625),
  all(coast$sampling_time == 0.625),
  length(landings_2025_age10) == 1L, landings_2025_age10 == 135,
  length(bts_2025) == 1L, abs(bts_2025 - 33987.154) < 0.001,
  length(coast_2025) == 1L, abs(coast_2025 - 1047.489) < 0.001,
  all(is.finite(source_inputs$value)),
  !anyDuplicated(paste(source_inputs$type, source_inputs$measure,
    source_inputs$fleet, source_inputs$survey, source_inputs$year,
    source_inputs$age, sep = "\r")),
  nrow(n_at_age) == 69L * 11L,
  nrow(f_at_age) == 69L * 11L,
  nrow(total_numbers) == 69L,
  setequal(unique(n_at_age$year), 1957:2025),
  setequal(unique(f_at_age$year), 1957:2025),
  setequal(unique(n_at_age$age), 0:10),
  setequal(unique(f_at_age$age), 0:10),
  all(is.na(n_at_age$se) & is.na(n_at_age$lwr) & is.na(n_at_age$upr)),
  all(is.na(f_at_age$se) & is.na(f_at_age$lwr) & is.na(f_at_age$upr)),
  all(is.na(total_numbers$se) & is.na(total_numbers$lwr) & is.na(total_numbers$upr)),
  length(n_2025_age0) == 1L, n_2025_age0 == 3288880,
  length(f_2025_age6) == 1L, f_2025_age6 == 0.051,
  length(total_2025) == 1L, abs(total_2025 - 4589316) < 0.5,
  isTRUE(all.equal(
    total_numbers$value[match(1957:2025, total_numbers$year)],
    aggregate(value ~ year, n_at_age, sum)$value[match(1957:2025, aggregate(value ~ year, n_at_age, sum)$year)]
  )),
  nrow(source_assumptions[source_assumptions$setting == "age_reading_error_matrix", ]) == 1L,
  grepl("Rows 9 and 10 sum to 0.991 and 0.910", source_assumptions$notes[source_assumptions$setting == "age_reading_error_matrix"], fixed = TRUE),
  nrow(source_outputs[source_outputs$measure == "SSB" & source_outputs$year == 2025L, ]) == 1L,
  nrow(source_outputs[source_outputs$measure == "recruitment" & source_outputs$year == 2026L, ]) == 1L,
  !nrow(source_outputs[source_outputs$measure == "Fbar" & source_outputs$year == 2026L, ])
)

cat("North Sea sole 2026 source records passed.\n")
