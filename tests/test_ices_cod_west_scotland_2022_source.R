source("R/read_database.R")
record <- read_assessment("ices_cod_west_scotland_2022", read_database())
inputs <- record$inputs
outputs <- record$outputs
select <- function(x, type, measure) x[x$type == type & x$measure == measure, ]
catch <- select(inputs, "catch", "numbers_at_age")
index <- select(inputs, "index", "numbers_at_age")
precision <- inputs[inputs$measure == "relative_precision_weight", ]
N <- select(outputs, "population", "numbers_at_age")
F <- select(outputs, "mortality", "fishing_mortality_at_age")
q <- select(outputs, "catchability", "q")
scale <- select(outputs, "catch", "catch_scaling_factor")
stopifnot(
  record$stocks$charbonneau_id == "ICES-WGCSE_morhua_NS6a",
  record$stocks$authority_stock_id == "cod.27.6a",
  record$stocks$ocean == "Northeast Atlantic",
  grepl("Merged into Northern Shelf", record$stocks$notes, fixed = TRUE),
  record$assessment$assessment_year == 2022,
  record$assessment$terminal_year == 2021,
  record$assessment$framework_year == 2020,
  all(unlist(record$assessment[c("assumptions_status", "inputs_status", "outputs_status")]) == "complete"),
  nrow(catch) == 287, nrow(index) == 401,
  identical(sort(unique(catch$year)), 1981:2021),
  identical(sort(unique(catch$age)), 1:7),
  all(is.na(catch$value[catch$year == 2021 & catch$age %in% 1:2])),
  sum(is.na(catch$value)) == 2,
  all(catch$unit == "thousand fish"),
  sum(is.finite(index$value) & index$value > 0) == 372,
  all(index$unit[index$survey == "IRGFS.Q4"] == "fish per minute"),
  all(index$unit[index$survey != "IRGFS.Q4"] == "fish per hour"),
  all(index$sampling_time[index$survey %in% c("WCIBTS.Q1", "SCO.Q1")] == 0.125),
  all(index$sampling_time[index$survey == "IRGFS.Q4"] == 0.855),
  all(index$sampling_time[index$survey %in% c("WCIBTS.Q4", "SCO.Q4")] == 0.875),
  all(precision$value[precision$type == "catch"] == 0.25),
  all(precision$year[precision$type == "catch"] >= 2006),
  nrow(select(inputs, "index", "index_sd")) == 132,
  nrow(select(inputs, "M", "natural_mortality_at_age")) == 287,
  nrow(N) == 287, nrow(F) == 287, nrow(q) == 25,
  identical(scale$year, 1995:2006),
  abs(scale$value[scale$year == 2005] - 3.32099) < 1e-5,
  all(is.finite(c(N$se, F$se, q$se, scale$se))),
  all(grepl("natural-scale delta-method SE", c(N$notes, F$notes, q$notes), fixed = TRUE)),
  all(is.na(select(outputs, "population", "total_numbers")$se))
)
# Off-diagonal source cells protect the year/age mapping.
stopifnot(
  catch$value[catch$year == 1982 & catch$age == 1] == 3634.929,
  catch$value[catch$year == 1981 & catch$age == 2] == 7922.919,
  index$value[index$survey == "WCIBTS.Q1" & index$year == 1985 & index$age == 2] == 2.37,
  index$value[index$survey == "SCO.Q1" & index$year == 2011 & index$age == 2] == 3.295,
  index$value[index$survey == "SCO.Q4" & index$year == 2021 & index$age == 2] == 8.912,
  abs(N$value[N$year == 1981 & N$age == 2] - 19502) < 0.5,
  abs(N$value[N$year == 2021 & N$age == 3] - 878) < 0.5
)
sd <- select(inputs, "index", "index_sd")
key <- function(x) paste(x$year, x$age, x$survey)
at_index <- match(key(sd), key(index))
at_weight <- match(key(sd), key(precision))
valid <- is.finite(sd$value) & is.finite(index$value[at_index]) & index$value[at_index] > 0
stopifnot(!anyNA(at_index), !anyNA(at_weight[valid]),
  max(abs((index$value[at_index][valid] / sd$value[valid])^2 -
    precision$value[at_weight][valid])) < 1e-10)
surface <- function(x) {
  out <- matrix(NA_real_, 41, 7)
  out[cbind(match(x$year, 1981:2021), match(x$age, 1:7))] <- x$value
  out
}
n <- surface(N); f <- surface(F)
sw <- surface(select(inputs, "weight", "weight_at_age"))
mat <- surface(select(inputs, "maturity", "maturity_at_age"))
for (name in c("stockMeanWeight", "natMor")) {
  x <- if (name == "stockMeanWeight") sw else surface(select(inputs, "M", "natural_mortality_at_age"))
  stopifnot(all(x[41, 1:2] == x[40, 1:2]))
}
stopifnot(
  max(abs(rowSums(n * sw * mat) - select(outputs, "biomass", "SSB")$value)) < 1e-6,
  max(abs(rowSums(n * sw) - select(outputs, "biomass", "total_biomass")$value)) < 1e-6,
  max(abs(rowSums(n) - select(outputs, "population", "total_numbers")$value)) < 1e-6,
  max(abs(rowMeans(f[, 2:5]) - select(outputs, "mortality", "Fbar")$value)) < 1e-10,
  max(abs(f[, 4] - f[, 7])) < 1e-12,
  abs(tail(select(outputs, "biomass", "SSB")$value, 1) - 3326.32936) < 1e-5
)
cat("West of Scotland cod 2022 source values, units, missingness and definitions passed.\n")
