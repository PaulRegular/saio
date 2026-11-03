source("R/read_database.R")

database <- read_database()
source_data <- read_assessment("ices_haddock_faroe_2025", database)
assessment <- source_data$assessment
stock <- source_data$stocks
inputs <- source_data$inputs
outputs <- source_data$outputs

select <- function(x, type, measure) {
  x[x$type == type & x$measure == measure, , drop = FALSE]
}
catch <- select(inputs, "catch", "numbers_at_age")
catch_weight <- select(inputs, "catch", "relative_precision_weight")
index <- select(inputs, "index", "numbers_at_age")
summer_q3 <- index[index$survey == "FO-GFS-Q3", ]
spring_q1 <- index[index$survey == "FO-GFS-Q1", ]
m <- select(inputs, "M", "natural_mortality_at_age")
stock_weight <- select(inputs, "weight", "weight_at_age")
maturity <- select(inputs, "maturity", "maturity_at_age")
n <- select(outputs, "population", "numbers_at_age")
f <- select(outputs, "mortality", "fishing_mortality_at_age")
q <- select(outputs, "catchability", "q")
ssb <- select(outputs, "biomass", "SSB")
tsb <- select(outputs, "biomass", "total_biomass")
fbar <- select(outputs, "mortality", "Fbar")
recruitment <- select(outputs, "recruitment", "recruitment")
total_numbers <- select(outputs, "population", "total_numbers")
pred_catch <- select(outputs, "catch", "predicted_catch")
pred_index <- select(outputs, "index", "predicted_index")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "had.27.5b",
  stock$common_name == "Faroe haddock",
  stock$scientific_name == "Melanogrammus aeglefinus",
  stock$ocean == "Northeast Atlantic",
  isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  assessment$assessment_year == 2025L,
  assessment$terminal_year == 2025L,
  assessment$assumptions_status == "complete",
  assessment$inputs_status == "complete",
  assessment$outputs_status == "complete",
  nrow(catch) == 69L * 10L,
  identical(sort(unique(as.integer(catch$year))), 1957:2025),
  identical(sort(unique(as.integer(catch$age))), 1:10),
  all(catch$unit == "thousand fish"),
  sum(catch$value == 0) == 41L,
  nrow(catch_weight) == nrow(catch),
  all(catch_weight$value[catch_weight$year < 2025] == 1),
  all(catch_weight$value[catch_weight$year == 2025] == 0.5),
  nrow(summer_q3) == 30L * 8L,
  nrow(spring_q1) == 32L * 7L,
  identical(sort(unique(as.integer(summer_q3$year))), 1996:2025),
  identical(sort(unique(as.integer(spring_q1$year))), 1994:2025),
  identical(sort(unique(as.integer(summer_q3$age))), 1:8),
  identical(sort(unique(as.integer(spring_q1$age))), 1:7),
  all(summer_q3$sampling_time == 0.65),
  all(spring_q1$sampling_time == 0.225),
  all(c(summer_q3$unit, spring_q1$unit) == "native survey-index units"),
  nrow(m) == 10L,
  all(is.na(m$year)),
  identical(sort(as.integer(m$age)), 1:10),
  all(m$value == 0.2),
  nrow(n) == 69L * 10L,
  nrow(f) == 69L * 10L,
  nrow(q) == 15L,
  all(is.na(q$year)),
  nrow(q[q$survey == "FO-GFS-Q3", ]) == 8L,
  nrow(q[q$survey == "FO-GFS-Q1", ]) == 7L,
  q$value[q$survey == "FO-GFS-Q3" & q$age == 7] ==
    q$value[q$survey == "FO-GFS-Q3" & q$age == 8],
  q$value[q$survey == "FO-GFS-Q1" & q$age == 6] ==
    q$value[q$survey == "FO-GFS-Q1" & q$age == 7],
  all(is.finite(c(n$value, n$se, f$value, f$se, q$value, q$se))),
  all(f$age_group[f$age == 10] == "10+"),
  nrow(ssb) == 69L,
  nrow(tsb) == 69L,
  nrow(fbar) == 69L,
  nrow(recruitment) == 69L,
  nrow(total_numbers) == 69L,
  all(is.na(total_numbers$se)),
  nrow(pred_catch) == 690L,
  nrow(pred_index) == 464L,
  all(is.finite(c(pred_catch$value, pred_index$value))),
  abs(fbar$value[fbar$year == 2025] - 0.1296438) < 1e-6,
  abs(ssb$value[ssb$year == 2025] - 59250.08) < 0.1,
  abs(recruitment$value[recruitment$year == 2025] - 75509.68) < 0.1
)

years <- 1957:2025
ages <- 1:10
surface <- function(x, year_values = years, age_values = ages) {
  out <- matrix(NA_real_, length(year_values), length(age_values),
    dimnames = list(as.character(year_values), as.character(age_values)))
  i <- cbind(match(as.integer(x$year), year_values), match(as.integer(x$age), age_values))
  out[i] <- as.numeric(x$value)
  out
}
n_surface <- surface(n)
f_surface <- surface(f)
weight_surface <- surface(stock_weight)
maturity_surface <- surface(maturity)
stopifnot(
  isTRUE(all.equal(unname(rowSums(n_surface)),
    as.numeric(total_numbers$value), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowSums(n_surface * weight_surface)),
    as.numeric(tsb$value), tolerance = 1e-6)),
  isTRUE(all.equal(unname(rowSums(n_surface * weight_surface * maturity_surface)),
    as.numeric(ssb$value), tolerance = 1e-6)),
  isTRUE(all.equal(unname(rowMeans(f_surface[, as.character(3:7), drop = FALSE])),
    as.numeric(fbar$value), tolerance = 1e-8)),
  isTRUE(all.equal(unname(n_surface[, "1"]),
    as.numeric(recruitment$value), tolerance = 1e-8))
)

cat("Faroe haddock 2025 SAM data, assumptions, and output checks passed.\n")
