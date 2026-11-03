source("R/read_database.R")
record <- read_assessment("ices_herring_west_scotland_ireland_2020")
inputs <- record$inputs
outputs <- record$outputs
select <- function(x, type, measure) x[x$type == type & x$measure == measure, , drop = FALSE]
catch <- select(inputs, "catch", "numbers_at_age")
catch_weight <- select(inputs, "catch_weight", "weight_at_age")
index <- select(inputs, "index", "numbers_at_age")
n_at_age <- select(outputs, "population", "numbers_at_age")
f_at_age <- select(outputs, "mortality", "fishing_mortality_at_age")
fbar <- select(outputs, "mortality", "Fbar")
total_numbers <- select(outputs, "population", "total_numbers")

stopifnot(
  record$stocks$stock_id == "ck_ices_hawg_harengus_cs_6a_7b_7c",
  record$stocks$authority_stock_id == "her.27.6a7bc",
  record$stocks$ocean == "Northeast Atlantic",
  record$assessment$assessment_year == 2020,
  record$assessment$terminal_year == 2019,
  record$assessment$model_family == "SAM (FLSAM)",
  all(unlist(record$assessment[c("assumptions_status", "inputs_status", "outputs_status")]) == "partial"),
  nrow(catch) == 2 * 63 * 9,
  identical(sort(unique(catch$year)), 1957:2019),
  identical(sort(unique(catch$age)), 1:9),
  setequal(unique(catch$fleet), c("Catch 6aN", "Catch 6aS/7bc")),
  all(grepl("inferred", catch$unit, fixed = TRUE)),
  nrow(catch_weight) == 2 * 63 * 9,
  nrow(index) == 661,
  setequal(unique(index$survey), c("MS_HERAS", "IBTS_Q1", "IBTS_Q4")),
  sum(is.na(index$value)) == 21,
  all(index$sampling_time[index$survey == "MS_HERAS"] == 0.545),
  all(index$sampling_time[index$survey == "IBTS_Q1"] == 0.125),
  all(index$sampling_time[index$survey == "IBTS_Q4"] == 0.875),
  nrow(n_at_age) == 63 * 9,
  nrow(f_at_age) == 2 * 63 * 9,
  nrow(fbar) == 63,
  all(fbar$age_group == "3-6"),
  setequal(unique(f_at_age$region), c("ICES Division 6.a North", "ICES divisions 6.a South, 7.b-c")),
  nrow(total_numbers) == 63,
  all(is.na(outputs$se)) && all(is.na(outputs$lwr)) && all(is.na(outputs$upr)),
  nrow(select(inputs, "M", "natural_mortality_at_age")) == 63 * 9,
  !any(outputs$measure == "natural_mortality_at_age"),
  all(grepl("https://doi.org/10.17895/ices.pub.6105", inputs$source_reference, fixed = TRUE)),
  all(grepl("https://doi.org/10.17895/ices.pub.6105", outputs$source_reference, fixed = TRUE)),
  outputs$value[outputs$measure == "SSB" & outputs$year == 2019] == 41978,
  outputs$value[outputs$measure == "Fbar" & outputs$year == 2019] == 0.0814,
  outputs$value[outputs$measure == "recruitment" & outputs$year == 2019] == 708296
)

expected_total <- aggregate(value ~ year, n_at_age, sum)
stopifnot(all(abs(total_numbers$value[match(expected_total$year, total_numbers$year)] -
  expected_total$value) < 1e-8))
cat("West of Scotland/Ireland herring input coverage, source values, units, fixed M, and derived total N passed.\n")
