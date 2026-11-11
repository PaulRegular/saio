source("scripts/database/002_validate_database.R")

stock_id <- "ck_nefsc_saw_chrysops_usatl"
a15 <- assessments[assessments$assessment_id == "nefsc_scup_2015", , drop = FALSE]
a25 <- assessments[assessments$assessment_id == "nefsc_scup_2025", , drop = FALSE]
i15 <- inputs[inputs$assessment_id == "nefsc_scup_2015", , drop = FALSE]
i25 <- inputs[inputs$assessment_id == "nefsc_scup_2025" & inputs$source_type != "official_machine_readable", , drop = FALSE]
o15 <- outputs[outputs$assessment_id == "nefsc_scup_2015", , drop = FALSE]
o25 <- outputs[outputs$assessment_id == "nefsc_scup_2025" & outputs$source_type != "official_machine_readable", , drop = FALSE]
metric_value <- function(data, measure, year, field = "value", age = NULL, age_group = NULL) {
  keep <- !is.na(data$measure) & data$measure == measure &
    !is.na(data$year) & as.character(data$year) == as.character(year)
  if (!is.null(age)) keep <- keep & !is.na(data$age) & as.character(data$age) == as.character(age)
  if (!is.null(age_group)) keep <- keep & !is.na(data$age_group) & data$age_group == age_group
  value <- suppressWarnings(as.numeric(data[[field]][keep]))
  stopifnot(length(value) == 1L, !is.na(value))
  value
}

stopifnot(
  stocks$common_name[stocks$stock_id == stock_id] == "Scup",
  nrow(a15) == 1L, nrow(a25) == 1L,
  a15$is_current, a15$is_applied,
  !a25$is_current, a25$is_applied,
  a15$terminal_year == 2014L, a25$terminal_year == 2024L,
  a15$inputs_status == "partial", a25$inputs_status == "partial",
  a15$outputs_status == "partial", a25$outputs_status == "partial",
  a15$assumptions_status == "partial", a25$assumptions_status == "partial"
)

catch_age <- i15[i15$type == "catch" & i15$measure == "numbers_at_age", , drop = FALSE]
catch_biomass <- i15[i15$measure == "total_biomass", , drop = FALSE]
fall_index <- i15[i15$type == "index" & i15$survey == "NEFSC fall trawl survey", , drop = FALSE]
fixed_m <- i15[i15$type == "M" & i15$measure == "natural_mortality_at_age", , drop = FALSE]
weight <- i15[i15$type == "weight" & i15$measure == "weight_at_age", , drop = FALSE]
maturity <- i15[i15$type == "maturity" & i15$measure == "maturity_at_age", , drop = FALSE]
stopifnot(
  nrow(i15) == 2616L + 30L * 12L,
  nrow(catch_age) == 4L * 31L * 11L,
  identical(sort(unique(as.integer(catch_age$year))), 1984:2014),
  identical(sort(unique(as.integer(catch_age$age))), 0:10),
  setequal(unique(catch_age$fleet), c(
    "Commercial landings", "Commercial discards",
    "Recreational landings", "Recreational discards"
  )),
  catch_age$value[catch_age$fleet == "Commercial landings" & catch_age$year == 1984 & catch_age$age == 1] == 2691,
  nrow(catch_biomass) == 18L * 4L + 34L * 4L,
  min(as.integer(catch_biomass$year)) == 1963L,
  max(as.integer(catch_biomass$year)) == 2014L,
  !any(catch_biomass$year %in% 1981:2014 & catch_biomass$fleet == "Distant-water fleet landings"),
  nrow(weight) == 31L * 11L,
  identical(sort(unique(as.integer(weight$year))), 1984:2014),
  identical(sort(unique(as.integer(weight$age))), 0:10),
  all(weight$unit == "kg per fish"),
  nrow(maturity) == 52L * 8L,
  identical(sort(unique(as.integer(maturity$year))), 1963:2014),
  identical(sort(unique(as.integer(maturity$age))), 0:7),
  all(is.na(maturity$age_group) | maturity$age_group == ""),
  all(maturity$unit == "proportion"),
  all(maturity$source_type[maturity$year < 1981] == "reconstructed_source_input"),
  all(maturity$source_type[maturity$year >= 1981] == "official_table"),
  metric_value(weight, "weight_at_age", 1984, age = 0) == 0.034,
  metric_value(weight, "weight_at_age", 2014, age = 10) == 1.575,
  metric_value(maturity, "maturity_at_age", 1963, age = 2) == 0.83,
  metric_value(maturity, "maturity_at_age", 1981, age = 2) == 0.89,
  metric_value(maturity, "maturity_at_age", 2014, age = 7) == 1
)

stopifnot(
  nrow(fall_index) == 31L * 9L,
  identical(sort(unique(as.integer(fall_index$year))), 1984:2014),
  identical(sort(unique(as.integer(fall_index$age))), 0:8),
  all(fall_index$basis == "numbers"),
  all(fall_index$unit == "fish per tow"),
  all(is.na(fall_index$sampling_time) | fall_index$sampling_time == ""),
  metric_value(fall_index, "numbers_at_age", 1984, age = 0) == 50.28,
  metric_value(fall_index, "numbers_at_age", 1986, age = 3) == 0,
  metric_value(fall_index, "numbers_at_age", 1986, age = 4) == 0.01,
  metric_value(fall_index, "numbers_at_age", 2010, age = 7) == 0,
  metric_value(fall_index, "numbers_at_age", 2010, age = 8) == 0.01,
  metric_value(fall_index, "numbers_at_age", 2014, age = 8) == 0.14,
  nrow(fixed_m) == 8L,
  identical(sort(as.integer(fixed_m$age)), 0:7),
  all(as.numeric(fixed_m$value) == 0.20),
  all(fixed_m$unit == "yr-1")
)

ctdeep <- subset(i15, type == "index" & survey == "CTDEEP fall trawl survey")
ctdeep_age <- subset(ctdeep, measure %in% c("numbers_at_age", "index_by_age_group"))
ctdeep_total <- subset(ctdeep, measure == "total_numbers")
ctdeep_sum <- aggregate(value ~ year, ctdeep_age, sum)
stopifnot(
  nrow(ctdeep_age) == 30L * 11L, nrow(ctdeep_total) == 30L,
  identical(sort(unique(as.integer(ctdeep_age$year))), setdiff(1984:2014, 2010L)),
  identical(sort(unique(as.integer(ctdeep_age$age))), 0:10),
  !anyDuplicated(ctdeep_age[c("year", "age")]),
  all(ctdeep_age$measure[ctdeep_age$age < 10L] == "numbers_at_age"),
  all(ctdeep_age$measure[ctdeep_age$age == 10L] == "index_by_age_group"),
  all(grepl("10+", ctdeep_age$notes[ctdeep_age$age == 10L], fixed = TRUE)),
  all(is.na(ctdeep_total$age)),
  all(ctdeep$unit == "fish per tow"), all(ctdeep$basis == "numbers"),
  all(ctdeep$season == "fall"), all(ctdeep$region == "Long Island Sound"),
  all(is.na(ctdeep$sampling_time)), all(ctdeep$source_type == "official_table"),
  all(round(ctdeep_sum$value, 2L) == ctdeep_total$value[match(ctdeep_sum$year, ctdeep_total$year)]),
  metric_value(ctdeep_age, "numbers_at_age", 1984, age = 7) == 0,
  metric_value(ctdeep_age, "numbers_at_age", 2013, age = 0) == 17.74,
  metric_value(ctdeep_age, "index_by_age_group", 2014, age = 10) == 0.03,
  metric_value(ctdeep_total, "total_numbers", 2014) == 182.60,
  sum(assumptions$assessment_id == "nefsc_scup_2015" &
    assumptions$setting == "CTDEEP_fall_index") == 1L
)

stopifnot(
  nrow(i25) == 40L,
  identical(sort(unique(as.integer(i25$year))), 2015:2024),
  all(i25$unit == "metric tons"),
  i25$value[i25$fleet == "Commercial landings" & i25$year == 2015] == 7725
)

stopifnot(
  nrow(o15) == 31L * 19L,
  nrow(o25) == 32L,
  metric_value(o15, "SSB", 2014) == 182915,
  metric_value(o15, "SSB", 2014, field = "lwr") == 153000,
  metric_value(o15, "numbers_at_age", 2014, age_group = "7+") == 134653,
  metric_value(o15, "fishing_mortality_at_age", 2014, age = 3) == 0.127,
  metric_value(o25, "SSB", 2024) == 163470,
  metric_value(o25, "published_terminal_SSB", 2024) == 235613,
  metric_value(o25, "Fbar", 2024, age_group = "age 4 (retrospective-adjusted Ffull)") == 0.098,
  metric_value(o25, "Fbar", 2024, age_group = "age 4 (Ffull)") == 0.167,
  all(o25$source_type[o25$measure == "SSB"] == "official_table")
)

review <- readLines("source_reviews/ck_nefsc_saw_chrysops_usatl.md", warn = FALSE)
stopifnot(any(grepl("S60_BASE_18", review)), any(grepl("rho-adjusted", review)))

message("Scup catch, biology, output records, separation of 2015/2025 values, and partial statuses verified.")
