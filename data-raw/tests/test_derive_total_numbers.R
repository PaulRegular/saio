source("R/derive_total_numbers.R")

outputs <- data.frame(
  assessment_id = c(rep("example", 16), "example", "example"),
  type = c(rep("population", 18)),
  measure = c(rep("numbers_at_age", 16), "total_numbers", "total_numbers"),
  fleet = "",
  survey = "",
  sex = c(rep(c(rep("female", 4), rep("male", 4)), 2), "combined", "combined"),
  region = "test region",
  season = "",
  year = c(rep(2000, 8), rep(2001, 8), 1999, 1999),
  age = c(rep(1:4, 4), "", ""),
  age_group = c(rep("", 16), "", ""),
  value = c(10, 20, 30, 40, 1, 2, 3, 4, 12, 22, 32, 42, 1, 2, 3, 4, 999, 999),
  se = NA_real_,
  lwr = NA_real_,
  upr = NA_real_,
  unit = "thousand_fish",
  source_type = "official_machine_readable",
  source_reference = "official N-at-age table",
  notes = "",
  stringsAsFactors = FALSE
)

derived <- derive_population_total_numbers(outputs, "example")
stopifnot(
  nrow(derived) == 2L,
  identical(as.integer(derived$year), c(2000L, 2001L)),
  identical(as.numeric(derived$value), c(110, 118)),
  all(derived$sex == "combined"),
  all(derived$source_type == "derived_source_output"),
  all(is.na(derived$se) & is.na(derived$lwr) & is.na(derived$upr)),
  all(grepl("female, male", derived$notes, fixed = TRUE))
)

rerun <- derive_population_total_numbers(rbind(outputs, derived), "example")
stopifnot(nrow(rerun) == 0L, length(attr(rerun, "skipped")) == 0L)

plus_outputs <- outputs[c(1:3, 5:7, 9:11, 13:15), ]
plus_outputs$age_group[c(3, 6, 9, 12)] <- "3+"
plus_totals <- derive_population_total_numbers(plus_outputs, "example")
stopifnot(
  identical(as.numeric(plus_totals$value), c(66, 72)),
  all(grepl("group:3\\+", plus_totals$notes))
)

cat("Derived total-abundance outputs are reproducible and retain missing uncertainty.\n")
