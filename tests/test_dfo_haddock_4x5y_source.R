source("R/read_database.R")

x <- read_assessment("dfo_haddock_4x5y_2016")
i <- x$inputs
o <- x$outputs
stock <- x$stocks[x$stocks$stock_id == "ck_dfo_aeglefinus_4x5y", ]
events <- x$assessments[x$assessments$stock_id == stock$stock_id, ]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "4X5Y",
  stock$common_name == "Haddock",
  nrow(events) == 2L,
  events$is_current[events$assessment_id == "dfo_haddock_4x5y_2016"],
  !events$is_current[events$assessment_id == "dfo_haddock_4x5y_2024_summary"],
  all(events$inputs_status == "partial"),
  all(events$assumptions_status == "partial"),
  all(events$outputs_status == "partial")
)

catch <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
rv <- i[i$type == "index" & i$measure == "numbers_at_age", ]
m <- i[i$type == "M" & i$measure == "natural_mortality_at_age", ]
stopifnot(
  nrow(catch) == 46L * 16L,
  min(catch$year) == 1970, max(catch$year) == 2015,
  min(catch$age) == 1, max(catch$age) == 16,
  all(catch$unit == "thousand fish"),
  nrow(rv) == 46L * 13L - 1L,
  rv$value[rv$year == 2014 & rv$age == 1] == 168470,
  !any(rv$year == 2015 & rv$age == 2),
  all(rv$sampling_time == 0.5),
  nrow(m) == 31L * 11L,
  all(m$value[m$year < 2000] == 0.2),
  all(m$value[m$year >= 2000 & m$year <= 2004 & m$age %in% 10:11] == 0.3),
  all(m$value[m$year >= 2005 & m$year <= 2009 & m$age %in% 10:11] == 0.6),
  all(m$value[m$year >= 2010 & m$age %in% 10:11] == 0.9)
)

stock_weight <- i[i$type == "weight" & i$measure == "weight_at_age" &
  (is.na(i$year) | !nzchar(i$year_basis)) &
  (is.na(i$survey) | !nzchar(i$survey)), ]
maturity <- i[i$type == "maturity" & i$measure == "maturity_at_age", ]
stopifnot(
  nrow(stock_weight) == 11L,
  nrow(maturity) == 11L,
  identical(stock_weight$value, c(.06, .16, .35, .56, .71, .84, .95, 1.01, 1.11, 1.20, 1.30)),
  identical(maturity$value, c(0, 0, 0, rep(1, 8)))
)

n <- o[o$measure == "numbers_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
ssb <- o[o$measure == "SSB", ]
total <- o[o$measure == "total_numbers", ]
recruitment <- o[o$measure == "recruitment", ]
q <- o[o$measure == "q", ]
terminal <- o[o$measure == "terminal_parameter_numbers_at_age", ]
stopifnot(
  nrow(n) == 32L * 11L,
  nrow(f) == 31L * 11L,
  nrow(ssb) == 32L,
  nrow(total) == 32L,
  nrow(recruitment) == 32L,
  nrow(q) == 10L,
  nrow(terminal) == 10L,
  n$value[n$year == 2016 & n$age == 1] == 18491,
  n$value[n$year == 2016 & n$age == 2] == 60910,
  ssb$value[ssb$year == 2016] == 33770,
  ssb$value[ssb$year == 2015] == 21400,
  total$value[total$year == 2016] == sum(n$value[n$year == 2016]),
  recruitment$value[recruitment$year == 2016] == 18491,
  q$value[q$age == 1] == .495,
  q$se[q$age == 1] == .055,
  all(is.na(total$se)), all(is.na(recruitment$se))
)

summary <- read_assessment("dfo_haddock_4x5y_2024_summary")
stopifnot(
  nrow(summary$outputs) == 1L,
  summary$outputs$measure == "SSB",
  summary$outputs$year == 2022,
  summary$outputs$value == 33531,
  summary$outputs$unit == "t"
)

cat("4X5Y haddock source coverage, provenance, transcription handling, and outputs passed.\n")
