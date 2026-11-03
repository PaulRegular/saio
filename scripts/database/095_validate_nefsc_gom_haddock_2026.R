source("scripts/database/002_validate_database.R")

id <- "nefsc_haddock_gulf_of_maine_2026"
a <- assessments[assessments$assessment_id == id, ]
x <- inputs[inputs$assessment_id == id, ]
z <- assumptions[assumptions$assessment_id == id, ]
y <- outputs[outputs$assessment_id == id, ]
years <- 2015:2025

stopifnot(
  nrow(a) == 1L,
  a$stock_id == "ck_nefsc_garmiii_aeglefinus_5y",
  a$assessment_year == 2026L,
  a$terminal_year == 2025L,
  a$estimate_terminal_year == 2031L,
  a$model_family == "WHAM",
  !a$is_current,
  a$is_applied,
  a$inputs_status == "partial",
  a$outputs_status == "partial",
  a$assumptions_status == "partial"
)

expected_catch <- c(1512, 3406, 4894, 3710, 4542, 4810, 4618, 3353, 2734, 2288, 1741)
stopifnot(
  nrow(x) == 11L,
  identical(as.integer(x$year), years),
  identical(as.numeric(x$value), expected_catch),
  all(x$type == "catch"),
  all(x$measure == "total_biomass"),
  all(x$unit == "t"),
  all(x$source_type == "official_table"),
  !any(x$type %in% c("index", "weight", "maturity", "M"))
)

setting <- function(component, name) {
  row <- z[z$component == component & z$setting == name, ]
  stopifnot(nrow(row) == 1L)
  row$value
}
stopifnot(
  nrow(z) == 17L,
  setting("M", "treatment") == "Fixed, age-invariant M = 0.2",
  setting("N", "process") == "2DAR1; recruitment decoupled from ages 2+",
  setting("recruitment", "process") == "AR1 deviations around a time-series mean",
  setting("mortality", "fully_selected_F_ages") == "6-9"
)

expected_ssb <- c(52538, 73129, 71833, 89867, 69187, 42659, 19673, 22117, 14586, 16701, 11339)
expected_f <- c(.046, .070, .095, .052, .072, .130, .280, .190, .274, .213, .223)
expected_recruitment <- c(9613, 10899, 11922, 7369, 4972, 6153, 23209, 22106, 2537, 1022, 1704)
historical <- y[y$year %in% years, ]
ssb <- historical[historical$measure == "SSB", ]
f <- historical[historical$measure == "Fbar", ]
recruitment <- historical[historical$measure == "recruitment", ]
stopifnot(
  nrow(y) == 53L,
  identical(as.integer(ssb$year), years), identical(as.numeric(ssb$value), expected_ssb),
  identical(as.integer(f$year), years), identical(as.numeric(f$value), expected_f),
  all(f$age_group == "6-9"),
  identical(as.integer(recruitment$year), years),
  identical(as.numeric(recruitment$value), expected_recruitment),
  all(is.na(historical$se)), all(is.na(historical$lwr)), all(is.na(historical$upr))
)

projection <- y[y$year %in% 2026:2031, ]
ssb_projection <- projection[projection$measure == "SSB", ]
f_projection <- projection[projection$measure == "Fbar", ]
catch_projection <- projection[projection$measure == "predicted_catch", ]
stopifnot(
  identical(as.numeric(ssb_projection$value), c(9335, 7293, 6229, 6208, 6535, 6799)),
  identical(as.numeric(ssb_projection$lwr), c(4186, 2463, 1944, 1534, 1238, 1047)),
  identical(as.numeric(ssb_projection$upr), c(20816, 21593, 19962, 25117, 34494, 44158)),
  identical(as.numeric(f_projection$value), c(.268, rep(.352, 5))),
  all(f_projection$age_group == "6-9"),
  identical(as.integer(catch_projection$year), 2027:2031),
  identical(as.numeric(catch_projection$value), c(2099, 1618, 1481, 1524, 1599))
)

reference_points <- y[y$measure %in% c("Fmsy", "Bmsy", "msy"), ]
stopifnot(
  nrow(reference_points) == 3L,
  all(is.na(reference_points$year)),
  all(reference_points$source_type == "official_table"),
  !any(y$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  !anyDuplicated(paste(y$measure, y$year, y$age_group, sep = "\034"))
)

message("2026 Gulf of Maine haddock partial data, source values, process descriptions, and projection summaries verified.")
