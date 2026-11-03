source("R/read_database.R")

database <- read_database()
record <- read_assessment("ices_saithe_faroe_2025", database)
assessment <- record$assessment
stock <- record$stocks
inputs <- record$inputs
outputs <- record$outputs

select_input <- function(type, measure) {
  inputs[inputs$type == type & inputs$measure == measure, , drop = FALSE]
}
select_output <- function(type, measure) {
  outputs[outputs$type == type & outputs$measure == measure, , drop = FALSE]
}
surface <- function(x, years = 1961:2025, ages = 3:15) {
  value <- matrix(NA_real_, length(years), length(ages),
    dimnames = list(as.character(years), as.character(ages)))
  i <- cbind(match(as.integer(x$year), years), match(as.integer(x$age), ages))
  value[i] <- as.numeric(x$value)
  value
}

catch <- select_input("catch", "numbers_at_age")
catch_precision <- select_input("catch", "relative_precision_weight")
index <- select_input("index", "numbers_at_age")
index_numerator <- select_input("index", "index_catch_numbers_at_age")
effort <- select_input("covariate", "effort")
m <- select_input("M", "natural_mortality_at_age")
stock_weight_input <- select_input("weight", "weight_at_age")
catch_weight_input <- select_input("catch_weight", "weight_at_age")
maturity <- select_input("maturity", "maturity_at_age")
n <- select_output("population", "numbers_at_age")
f <- select_output("mortality", "fishing_mortality_at_age")
q <- select_output("catchability", "q")
ssb <- select_output("biomass", "SSB")
tsb <- select_output("biomass", "total_biomass")
fbar <- select_output("mortality", "Fbar")
recruitment <- select_output("recruitment", "recruitment")
total_numbers <- select_output("population", "total_numbers")
pred_catch <- select_output("catch", "predicted_catch")
pred_index <- select_output("index", "predicted_index")
stock_weight <- select_output("biology", "weight_at_age")
fitted_catch_weight <- select_output("biology", "catch_weight_at_age")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "pok.27.5b",
  stock$scientific_name == "Pollachius virens",
  stock$common_name == "Faroe saithe",
  stock$ocean == "Northeast Atlantic",
  isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  assessment$assessment_year == 2025L,
  assessment$terminal_year == 2025L,
  assessment$assumptions_status == "complete",
  assessment$inputs_status == "complete",
  assessment$outputs_status == "complete",
  nrow(catch) == 65L * 13L,
  identical(sort(unique(as.integer(catch$year))), 1961:2025),
  identical(sort(unique(as.integer(catch$age))), 3:15),
  all(catch$unit == "thousand fish"),
  sum(as.numeric(catch$value) == 0) == 28L,
  nrow(catch_precision) == nrow(catch),
  all(as.numeric(catch_precision$value[catch_precision$year < 2025]) == 1),
  all(as.numeric(catch_precision$value[catch_precision$year == 2025]) == 0.5),
  nrow(index) == 496L,
  nrow(index_numerator) == 496L,
  nrow(effort) == 62L,
  identical(sort(unique(index$survey)), c("SpringSurvey", "SummerSurvey")),
  all(index$unit == "fish per effort-hour"),
  all(index$sampling_time[index$survey == "SummerSurvey"] == 0.65),
  all(index$sampling_time[index$survey == "SpringSurvey"] == 0.225),
  all(index$year[index$survey == "SummerSurvey"] %in% 1996:2025),
  all(index$year[index$survey == "SpringSurvey"] %in% 1994:2025),
  effort$unit[effort$survey == "SummerSurvey" & effort$year == 1996] == "hours",
  effort$value[effort$survey == "SummerSurvey" & effort$year == 1996] == 200,
  effort$value[effort$survey == "SpringSurvey" & effort$year == 1994] == 100,
  index$value[index$survey == "SummerSurvey" & index$year == 1996 & index$age == 3] == 1.425,
  index$value[index$survey == "SpringSurvey" & index$year == 1994 & index$age == 3] == 1.18,
  nrow(m) == 13L,
  all(is.na(m$year)),
  identical(sort(as.integer(m$age)), 3:15),
  all(as.numeric(m$value) == 0.2),
  nrow(stock_weight_input) == 64L * 13L,
  nrow(catch_weight_input) == 64L * 13L,
  all(stock_weight_input$year < 2025L),
  all(catch_weight_input$year < 2025L),
  all(is.finite(stock_weight_input$value)),
  all(is.finite(catch_weight_input$value)),
  all(is.finite(as.numeric(stock_weight$value))),
  all(is.finite(as.numeric(fitted_catch_weight$value))),
  nrow(n) == 65L * 13L,
  nrow(f) == 65L * 13L,
  nrow(q) == 16L,
  q$value[q$survey == "SummerSurvey" & q$age == 9] ==
    q$value[q$survey == "SummerSurvey" & q$age == 10],
  q$value[q$survey == "SpringSurvey" & q$age == 9] ==
    q$value[q$survey == "SpringSurvey" & q$age == 10],
  all(is.finite(c(n$value, n$se, f$value, f$se, q$value, q$se))),
  f$age_group[f$age == 15] == "15+",
  nrow(ssb) == 65L,
  nrow(tsb) == 65L,
  nrow(fbar) == 65L,
  nrow(recruitment) == 65L,
  nrow(total_numbers) == 65L,
  all(is.na(total_numbers$se)),
  nrow(pred_catch) == 845L,
  nrow(pred_index) == 496L,
  all(is.finite(c(pred_catch$value, pred_index$value))),
  abs(recruitment$value[recruitment$year == 2025] - 23847) < 1,
  abs(ssb$value[ssb$year == 2025] - 57509) < 1,
  abs(tsb$value[tsb$year == 2025] - 118012) < 1,
  abs(fbar$value[fbar$year == 2025] - 0.48) < 0.001
)

years <- 1961:2025
ages <- 3:15
# Values from cn.dat and survey.dat, checked against fit$data$aux/logobs.
# Off-diagonal cells distinguish year-major and age-major reshaping.
source_cells <- data.frame(
  type = c(rep("catch", 4), rep("index", 8)),
  survey = c(rep("", 4), rep("SummerSurvey", 4), rep("SpringSurvey", 4)),
  year = c(1962, 1961, 1984, 2025, 1997, 1996, 2005, 2025,
    1995, 1994, 2005, 2025),
  age = c(3, 4, 8, 15, 3, 4, 8, 10, 3, 4, 8, 10),
  value = c(562, 379, 273, 0, 6.105, 4.065, 1.425, 0.405,
    1.56, 8.2, 2.34, 0.73)
)
observation_rows <- inputs[inputs$measure == "numbers_at_age", , drop = FALSE]
observation_rows$survey[is.na(observation_rows$survey)] <- ""
observation_key <- function(x) paste(x$type, x$survey, x$year, x$age, sep = "/")
source_match <- match(observation_key(source_cells), observation_key(observation_rows))
stopifnot(
  !anyNA(source_match),
  isTRUE(all.equal(as.numeric(observation_rows$value[source_match]),
    source_cells$value, tolerance = 1e-12))
)

n_surface <- surface(n)
f_surface <- surface(f)
stock_weight_surface <- surface(stock_weight)
maturity_surface <- surface(maturity)
index_key <- paste(index$survey, index$year, index$age, sep = "\r")
numerator_key <- paste(index_numerator$survey, index_numerator$year,
  index_numerator$age, sep = "\r")
effort_key <- paste(effort$survey, effort$year, sep = "\r")
matched_numerator <- match(index_key, numerator_key)
matched_effort <- match(paste(index$survey, index$year, sep = "\r"), effort_key)
stopifnot(
  !anyNA(matched_numerator), !anyNA(matched_effort),
  isTRUE(all.equal(as.numeric(index$value),
    as.numeric(index_numerator$value[matched_numerator]) /
      as.numeric(effort$value[matched_effort]), tolerance = 1e-12)),
  isTRUE(all.equal(unname(rowSums(n_surface)),
    as.numeric(total_numbers$value), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowSums(n_surface * stock_weight_surface)),
    as.numeric(tsb$value), tolerance = 1e-6)),
  isTRUE(all.equal(unname(rowSums(n_surface * stock_weight_surface * maturity_surface)),
    as.numeric(ssb$value), tolerance = 1e-6)),
  isTRUE(all.equal(unname(rowMeans(f_surface[, as.character(4:8), drop = FALSE])),
    as.numeric(fbar$value), tolerance = 1e-8)),
  isTRUE(all.equal(unname(n_surface[, "3"]),
    as.numeric(recruitment$value), tolerance = 1e-8))
)

cat("Faroe saithe 2025 SAM inputs, units, fitted surfaces, and outputs passed.\n")
