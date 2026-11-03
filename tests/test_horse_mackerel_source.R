source("R/read_database.R")
database <- read_database()

x <- read_assessment("ices_horse_mackerel_9a_2024", database)
x26 <- read_assessment("ices_horse_mackerel_9a_2026", database)

stopifnot(
  x$stocks$authority_stock_id == "hom.27.9a",
  x$stocks$common_name == "Horse mackerel",
  x$assessment$is_current,
  x$assessment$terminal_year == 2023,
  x$assessment$inputs_status == "partial",
  x$assessment$outputs_status == "partial"
)

catch <- x$inputs[x$inputs$type == "catch" & x$inputs$measure == "numbers_at_age", ]
stopifnot(
  nrow(catch) == 32L * 12L,
  identical(sort(unique(catch$year)), 1992:2023),
  identical(sort(unique(catch$age)), 0:11),
  catch$value[catch$year == 1992 & catch$age == 0] == 11684,
  catch$unit[1] == "thousand fish"
)

ibts <- x$inputs[x$inputs$type == "index" & x$inputs$measure == "numbers_at_age", ]
stopifnot(
  nrow(ibts) == 29L * 12L,
  !any(ibts$year %in% c(2012, 2019, 2020)),
  ibts$value[ibts$year == 1992 & ibts$age == 1] == 488.2,
  all(ibts$sampling_time == 0.8),
  all(ibts$unit == "number per hour")
)

m <- x$inputs[x$inputs$type == "M", ]
m <- m[order(m$age), ]
stopifnot(
  identical(m$age, 0:11),
  isTRUE(all.equal(m$value, c(.62, .45, .35, .29, .25, .22, .20, .18, .17, .16, .15, .14)))
)
maturity <- x$inputs[x$inputs$type == "maturity", ]
stopifnot(
  all(maturity$sex == "female"),
  isTRUE(all.equal(maturity$value, c(0, .12, .39, .76, .93, .99, 1, 1, 1, 1, 1, 1)))
)

dep <- x$inputs[!is.na(x$inputs$survey) &
  x$inputs$survey == "BIOMAN DEPM egg survey" & x$inputs$measure == "total_biomass", ]
stopifnot(
  identical(dep$year, c(2013L, 2016L, 2019L, 2022L)),
  isTRUE(all.equal(dep$value, c(52.91, 148.81, 185.49, 75.26))),
  all(dep$unit == "thousand tonnes")
)

annual <- x$outputs
ssb <- annual[annual$measure == "SSB", ]
recruitment <- annual[annual$measure == "recruitment", ]
fbar <- annual[annual$measure == "Fbar", ]
stopifnot(
  nrow(ssb) == 32L,
  ssb$value[ssb$year == 1992] == 343625,
  ssb$se[ssb$year == 1992] == 343625 * .147,
  recruitment$value[recruitment$year == 1992] == 3213740,
  recruitment$age[1] == 0,
  fbar$value[fbar$year == 1992] == .091,
  all(fbar$age_group == "1-10"),
  !any(annual$measure %in% c("numbers_at_age", "fishing_mortality_at_age"))
)

stopifnot(
  !x26$assessment$is_current,
  x26$assessment$assessment_year == 2026,
  all(x26$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x26$inputs[x26$inputs$measure == "total_biomass", ]) == 34L,
  x26$outputs$value[x26$outputs$measure == "SSB" & x26$outputs$year == 2026] > 0,
  is.na(x26$outputs$value[x26$outputs$measure == "Fbar" & x26$outputs$year == 2026]),
  x26$outputs$unit[x26$outputs$measure == "recruitment"][1] == "thousand fish"
)

cat("Southern horse mackerel source coverage, units, biology, uncertainty, and run separation passed.\n")
