source("R/read_database.R")

database <- read_database()
source_record <- read_assessment("ices_cod_faroe_plateau_2025", database)

assessment <- source_record$assessment
stock <- source_record$stocks
inputs <- source_record$inputs
outputs <- source_record$outputs
years <- 1959:2025
ages <- 1:10

select_rows <- function(x, type, measure) {
  x[x$type == type & x$measure == measure, , drop = FALSE]
}

surface <- function(x, type, measure, years, ages, survey = NULL) {
  rows <- select_rows(x, type, measure)
  if (!is.null(survey)) rows <- rows[rows$survey == survey, , drop = FALSE]
  stopifnot(!anyDuplicated(paste(rows$year, rows$age)))
  out <- matrix(NA_real_, length(years), length(ages),
    dimnames = list(as.character(years), as.character(ages))
  )
  i <- cbind(match(as.integer(rows$year), years), match(as.integer(rows$age), ages))
  out[i] <- as.numeric(rows$value)
  out
}

catch <- select_rows(inputs, "catch", "numbers_at_age")
index <- select_rows(inputs, "index", "numbers_at_age")
n_age <- select_rows(outputs, "population", "numbers_at_age")
f_age <- select_rows(outputs, "mortality", "fishing_mortality_at_age")
q <- select_rows(outputs, "catchability", "q")
n <- surface(outputs, "population", "numbers_at_age", years, ages)
f <- surface(outputs, "mortality", "fishing_mortality_at_age", years, ages)
stock_weight <- surface(inputs, "weight", "weight_at_age", years, ages)
maturity <- surface(inputs, "maturity", "maturity_at_age", years, ages)
fixed_m <- surface(inputs, "M", "natural_mortality_at_age", years, ages)
ssb <- select_rows(outputs, "biomass", "SSB")
total_biomass <- select_rows(outputs, "biomass", "total_biomass")
fbar <- select_rows(outputs, "mortality", "Fbar")
recruitment <- select_rows(outputs, "recruitment", "recruitment")
total_numbers <- select_rows(outputs, "population", "total_numbers")

stopifnot(
  nrow(stock) == 1L,
  stock$common_name == "Faroe Plateau cod",
  stock$authority_stock_id == "cod.27.5b1",
  stock$scientific_name == "Gadus morhua",
  stock$ocean == "Northeast Atlantic",
  isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  assessment$terminal_year == 2025L,
  assessment$inputs_status == "complete",
  assessment$outputs_status == "complete",
  assessment$assumptions_status == "complete",
  identical(sort(unique(as.integer(catch$year))), years),
  nrow(catch) == 590L,
  setequal(unique(as.integer(catch$age)), 2:10),
  all(catch$unit == "thousand fish"),
  grepl("age 10 is the plus group", catch$notes[1L]),
  nrow(index) == 550L,
  setequal(unique(index$survey), c("FO-GFS-Q1", "FO-GFS-Q3")),
  setequal(unique(as.integer(index$age)), 1:9),
  all(index$unit == "native survey-index units"),
  all(index$sampling_time[index$survey == "FO-GFS-Q3"] == 0.65),
  all(index$sampling_time[index$survey == "FO-GFS-Q1"] == 0.225),
  !nrow(select_rows(inputs, "index", "relative_precision_weight")),
  nrow(n_age) == 67L * 10L,
  nrow(f_age) == 67L * 10L,
  all(is.finite(n_age$value) & is.finite(n_age$se)),
  all(is.finite(f_age$value[f_age$age != 1]) & is.finite(f_age$se[f_age$age != 1])),
  all(f_age$value[f_age$age == 1] == 0),
  all(is.na(f_age$se[f_age$age == 1])),
  all(f_age$age_group[f_age$age == 10] == "10+"),
  nrow(q) == 18L,
  setequal(q$survey, c("FO-GFS-Q1", "FO-GFS-Q3")),
  setequal(as.integer(q$age), 1:9),
  all(is.finite(q$se) & q$se > 0),
  all(is.finite(ssb$lwr) & is.finite(ssb$upr)),
  all(is.finite(total_biomass$lwr) & is.finite(total_biomass$upr)),
  all(is.finite(fbar$lwr) & is.finite(fbar$upr)),
  all(fbar$age_group == "3-7"),
  all(is.na(total_numbers$se)),
  length(unique(as.vector(fixed_m))) == 1L,
  max(abs(fixed_m - 0.2)) < 1e-10,
  all(grepl("Fixed annual natural mortality", select_rows(inputs, "M", "natural_mortality_at_age")$notes))
)

stopifnot(
  isTRUE(all.equal(unname(n[, "1"]), as.numeric(recruitment$value[match(years, recruitment$year)]), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowSums(n)), as.numeric(total_numbers$value[match(years, total_numbers$year)]), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowSums(n * stock_weight)), as.numeric(total_biomass$value[match(years, total_biomass$year)]), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowSums(n * stock_weight * maturity)), as.numeric(ssb$value[match(years, ssb$year)]), tolerance = 1e-8)),
  isTRUE(all.equal(unname(rowMeans(f[, as.character(3:7), drop = FALSE])), as.numeric(fbar$value[match(years, fbar$year)]), tolerance = 1e-8)),
  isTRUE(all.equal(f[, "7"], f[, "8"], tolerance = 1e-12)),
  isTRUE(all.equal(f[, "8"], f[, "9"], tolerance = 1e-12))
)

for (year in c(2024L, 2025L)) {
  row <- as.integer(year - min(years) + 1L)
  stopifnot(
    abs(recruitment$value[recruitment$year == year] - c(7283, 6912)[match(year, c(2024, 2025))]) < 0.5,
    abs(ssb$value[ssb$year == year] - c(17240, 20958)[match(year, c(2024, 2025))]) < 0.5,
    abs(fbar$value[fbar$year == year] - c(0.38, 0.57)[match(year, c(2024, 2025))]) < 0.005,
    is.finite(n[row, "1"])
  )
}

cat("Faroe Plateau cod 2025 SAM inputs, outputs, age mapping, and ICES summary checks passed.\n")
