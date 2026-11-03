source("R/read_database.R")

database <- read_database()
source_data <- read_assessment("ices_cod_western_baltic_2025", database)
stock <- source_data$stocks
assessment <- source_data$assessment
assumptions <- source_data$assumptions
inputs <- source_data$inputs
outputs <- source_data$outputs

rows <- function(x, type, measure) {
  x[x$type == type & x$measure == measure, , drop = FALSE]
}

surface <- function(x, type, measure, years = 1985:2025, ages = 0:7) {
  z <- rows(x, type, measure)
  stopifnot(!anyDuplicated(paste(z$year, z$age)))
  out <- matrix(NA_real_, length(years), length(ages),
    dimnames = list(as.character(years), as.character(ages))
  )
  i <- cbind(match(as.integer(z$year), years), match(as.integer(z$age), ages))
  out[i] <- as.numeric(z$value)
  out
}

catch <- rows(inputs, "catch", "numbers_at_age")
catch_weight <- rows(inputs, "catch", "observation_likelihood_weight")
index <- rows(inputs, "index", "numbers_at_age")
m <- surface(inputs, "M", "natural_mortality_at_age")
stock_weight <- surface(inputs, "weight", "weight_at_age")
maturity <- surface(inputs, "maturity", "maturity_at_age")
n <- rows(outputs, "population", "numbers_at_age")
f <- rows(outputs, "mortality", "fishing_mortality_at_age")
f_group <- !is.na(f$age_group) & f$age_group == "5-7"
f_age_zero <- !is.na(f$age) & f$age == 0
recruitment <- rows(outputs, "recruitment", "recruitment")
ssb <- rows(outputs, "biomass", "SSB")
tsb <- rows(outputs, "biomass", "total_biomass")
fbar <- rows(outputs, "mortality", "Fbar")
z <- rows(outputs, "mortality", "total_mortality_at_age")
harvest <- rows(outputs, "mortality", "harvest_rate")
q <- rows(outputs, "catchability", "q")
total_n <- rows(outputs, "population", "total_numbers")

stopifnot(
  nrow(stock) == 1L,
  stock$common_name == "Western Baltic cod",
  stock$authority_stock_id == "cod.27.22-24",
  stock$scientific_name == "Gadus morhua",
  stock$area == "ICES subdivisions 22-24",
  stock$ocean == "Northeast Atlantic",
  stock$region == "Western Baltic",
  assessment$assessment_year == 2025L,
  assessment$terminal_year == 2025L,
  assessment$estimate_terminal_year == 2025L,
  any(assumptions$setting == "terminal_catch_year" & assumptions$value == "2024"),
  assessment$framework_year == 2019L,
  !isTRUE(assessment$is_current), isTRUE(assessment$is_applied),
  assessment$assumptions_status == "complete",
  assessment$inputs_status == "complete",
  assessment$outputs_status == "complete",
  nrow(catch) == 277L,
  identical(sort(unique(as.integer(catch$year))), 1985:2024),
  identical(sort(unique(as.integer(catch$age))), 1:7),
  all(catch$unit == "thousand fish"),
  all(grepl("age 7 is the 7\\+ group", catch$notes)),
  nrow(catch_weight) == nrow(catch),
  all(catch_weight$basis == "relative_scale"),
  all(catch_weight$value[catch_weight$year <= 2019] == 1),
  all(catch_weight$value[catch_weight$year >= 2020] == 0.1),
  nrow(index[index$survey == "BITS Q4", ]) == 130L,
  nrow(index[index$survey == "BITS Q1", ]) == 120L,
  nrow(index[index$survey == "FEJUCS", ]) == 13L,
  all(index$unit == "native survey-index units"),
  all(index$sampling_time[index$survey == "BITS Q4"] == 0.8477816),
  all(index$sampling_time[index$survey == "BITS Q1"] == 0.1653494),
  all(index$sampling_time[index$survey == "FEJUCS"] == 0.85),
  all(is.finite(m)),
  max(abs(m["1985", ] - c(1.318, 0.598, 0.411, 0.324, 0.274, 0.241, 0.218, 0.201))) < 1e-12,
  all(m["1985", ] == m["2025", ]),
  nrow(rows(inputs, "weight", "weight_at_age")) == 41L * 8L,
  nrow(rows(inputs, "maturity", "maturity_at_age")) == 41L * 8L,
  nrow(n) == 327L,
  !any(n$year == 2025 & n$age == 0),
  nrow(f) == 41L * 6L,
  sum(f_group) == 41L,
  all(is.na(f$age[f_group])),
  all(f$value[f_age_zero] == 0),
  nrow(recruitment) == 41L,
  all(recruitment$age == 1L),
  all(recruitment$value == n$value[n$age == 1][match(recruitment$year, n$year[n$age == 1])]),
  nrow(ssb) == 41L,
  nrow(tsb) == 41L,
  nrow(fbar) == 41L,
  all(fbar$age_group == "3-5"),
  nrow(z) == 40L * 5L,
  nrow(harvest) == 40L,
  nrow(q) == 10L,
  nrow(rows(outputs, "catch", "predicted_catch")) == 280L,
  nrow(rows(outputs, "index", "predicted_index")) == 264L,
  identical(sort(as.integer(total_n$year)), 1985:2024),
  all(is.na(total_n$se)),
  abs(total_n$value[total_n$year == 2024] - sum(n$value[n$year == 2024])) < 1e-8,
  abs(recruitment$value[recruitment$year == 2024] - 16542) < 0.5,
  abs(recruitment$value[recruitment$year == 2025] - 26782) < 0.5,
  abs(ssb$value[ssb$year == 2024] - 1714) < 1,
  abs(ssb$value[ssb$year == 2025] - 2452) < 1,
  abs(fbar$value[fbar$year == 2025] - 0.96) < 0.01,
  abs(tsb$value[tsb$year == 2025] - 4689) < 1,
  abs(harvest$value[harvest$year == 1985] - 1.343) < 1e-12,
  all(grepl("no physical scale multiplier", index$notes, fixed = TRUE))
)

review <- paste(readLines("source_reviews/ck_ices_wgbfas_morhua_bs.md", warn = FALSE), collapse = " ")
stopifnot(
  grepl("WBCod2025", review, fixed = TRUE),
  grepl("harvest rate is used instead of F for advice", review, fixed = TRUE),
  grepl("catch observations in 2020–2024", review, fixed = TRUE),
  grepl("FEJUCS", review, fixed = TRUE)
)

cat("Western Baltic cod 2025 source identity, SAM inputs, outputs, units and provenance checks passed.\n")
