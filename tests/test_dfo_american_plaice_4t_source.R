source("R/read_database.R")

x <- read_assessment("dfo_american_plaice_4t_2016")
stock <- x$stocks[x$stocks$stock_id == "ck_dfo_platessoides_4t", , drop = FALSE]
events <- x$assessments[x$assessments$stock_id == stock$stock_id, , drop = FALSE]
i <- x$inputs
o <- x$outputs

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "4T",
  stock$scientific_name == "Hippoglossoides platessoides",
  stock$common_name == "American plaice",
  nrow(events) == 2L,
  events$is_current[events$assessment_id == "dfo_american_plaice_4t_2016"],
  !events$is_current[events$assessment_id == "dfo_american_plaice_4t_2024_indicators"],
  events$inputs_status[events$assessment_id == "dfo_american_plaice_4t_2016"] == "complete",
  events$outputs_status[events$assessment_id == "dfo_american_plaice_4t_2016"] == "partial"
)

catch <- i[i$type == "catch" & i$measure == "numbers_at_age", , drop = FALSE]
rv <- i[!is.na(i$survey) & i$survey == "DFO Research Vessel Trawl Survey", , drop = FALSE]
sentinel <- i[!is.na(i$survey) & i$survey == "Mobile Gear Sentinel Survey", , drop = FALSE]
weight <- i[i$type == "weight" & i$measure == "weight_at_age", , drop = FALSE]
maturity <- i[i$type == "maturity" & i$measure == "maturity_at_age", , drop = FALSE]
stopifnot(
  nrow(catch) == 40L * 13L,
  identical(sort(unique(catch$year)), 1976:2015),
  identical(sort(unique(catch$age)), 4:16),
  all(catch$unit == "thousand fish"),
  all(catch$fleet == "Commercial fishery"),
  nrow(rv) == 39L * 13L,
  !any(rv$year == 2003),
  all(rv$sampling_time == 0.75),
  all(rv$unit == "thousand fish"),
  nrow(sentinel) == 13L * 13L,
  identical(sort(unique(sentinel$year)), 2003:2015),
  all(sentinel$sampling_time == 0.75),
  nrow(weight) == 40L * 13L,
  weight$value[weight$year == 2003 & weight$age == 16] == 0,
  weight$value[weight$year == 1976 & weight$age == 4] == 0.047,
  nrow(maturity) == 40L * 13L,
  all(maturity$value >= 0 & maturity$value <= 1),
  maturity$value[maturity$year == 1976 & maturity$age == 4] == 0.350,
  identical(
    maturity$value[maturity$year == 2012][order(maturity$age[maturity$year == 2012])],
    maturity$value[maturity$year == 2015][order(maturity$age[maturity$year == 2015])]
  )
)

n <- o[o$measure == "numbers_at_age", , drop = FALSE]
total <- o[o$measure == "total_numbers", , drop = FALSE]
recruitment <- o[o$measure == "recruitment", , drop = FALSE]
ssb <- o[o$measure == "SSB", , drop = FALSE]
F <- o[o$measure == "fishing_mortality_at_age", , drop = FALSE]
M <- o[o$measure == "natural_mortality_at_age", , drop = FALSE]
stopifnot(
  nrow(n) == 40L * 13L,
  n$value[n$year == 2015 & n$age == 16] == 804,
  nrow(total) == 40L,
  nrow(recruitment) == 40L,
  all(recruitment$type == "recruitment"),
  recruitment$value[recruitment$year == 2015] == 528392,
  total$value[total$year == 2015] == sum(n$value[n$year == 2015]),
  all(is.na(total$se)), all(is.na(recruitment$se)),
  nrow(ssb) == 40L,
  identical(sort(ssb$year), 1976:2015),
  all(ssb$source_type == "digitized"),
  ssb$value[ssb$year == 1976] > 420000,
  ssb$value[ssb$year == 1976] < 440000,
  ssb$value[ssb$year == 2015] == 55023,
  all(is.finite(ssb$lwr) & is.finite(ssb$upr)),
  all(ssb$lwr <= ssb$value & ssb$value <= ssb$upr),
  nrow(F[F$age_group == "4-9", , drop = FALSE]) == 40L,
  nrow(F[F$age_group == "10+", , drop = FALSE]) == 33L,
  max(F$year[F$age_group == "10+"]) == 2008L,
  nrow(M[M$age_group == "4-9", , drop = FALSE]) >= 35L,
  nrow(M[M$age_group == "10+", , drop = FALSE]) == 40L,
  all(is.na(c(F$age, M$age))),
  all(c(F$age_group, M$age_group) %in% c("4-9", "10+")),
  all(F$source_type == "digitized"),
  all(M$source_type == "digitized"),
  all(F$value >= 0 & F$value <= 1),
  all(M$value >= 0 & M$value <= 1),
  all(is.finite(M$lwr) & is.finite(M$upr)),
  all(M$lwr <= M$value & M$value <= M$upr),
  all(is.na(F$lwr) & is.na(F$upr)),
  M$value[M$age_group == "4-9" & M$year == 1976] > 0.64,
  M$value[M$age_group == "4-9" & M$year == 1976] < 0.71,
  M$value[M$age_group == "10+" & M$year == 2015] > 0.70,
  M$value[M$age_group == "10+" & M$year == 2015] < 0.80
)

indicator <- read_assessment("dfo_american_plaice_4t_2024_indicators")
stopifnot(
  nrow(indicator$outputs) == 1L,
  indicator$outputs$measure == "relative_biomass_index",
  indicator$outputs$year == 2024,
  indicator$outputs$value == 1.25,
  indicator$outputs$unit == "kg/tow"
)

cat("4T American plaice source coverage, provenance, and output checks passed.\n")
