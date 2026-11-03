source("R/read_database.R")

x <- read_assessment("ices_greater_silver_smelt_5b6a_2026")
inputs <- x$inputs
outputs <- x$outputs

catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
catch_weight <- inputs[inputs$type == "catch_weight", ]
stock_weight <- inputs[inputs$type == "weight", ]
maturity <- inputs[inputs$type == "maturity", ]
summer <- inputs[inputs$survey %in% "Faroese summer groundfish survey", ]
deepwater <- inputs[inputs$survey %in% "Faroese deepwater survey", ]
scottish <- inputs[inputs$survey %in% "Scottish MSS Deepwater Slope survey", ]
cpue <- inputs[inputs$survey %in% "Combined Faroese-EU CPUE", ]

expected_catch_gaps <- c(
  "2003|20", "2004|20", "2005|19", "2005|20", "2006|20",
  "2006|21", "2007|19", "2007|21", "2018|20", "2018|21"
)
catch_gaps <- setdiff(
  paste(rep(1995:2025, each = 17L), rep(5:21, times = 31L), sep = "|"),
  paste(catch$year, catch$age, sep = "|")
)

numbers <- outputs[outputs$type == "population" & outputs$measure == "numbers_at_age", ]
f_at_age <- outputs[outputs$measure == "fishing_mortality_at_age", ]
ssb <- outputs[outputs$measure == "SSB", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
fbar <- outputs[outputs$measure == "Fbar", ]

stopifnot(
  x$stocks$stock_id == "ices_greater_silver_smelt_5b6a",
  x$stocks$authority_stock_id == "aru.27.5b6a",
  x$stocks$ocean == "Northeast Atlantic",
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2025L,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(catch) == 517L,
  setequal(catch_gaps, expected_catch_gaps),
  catch$value[catch$year == 1995L & catch$age == 9L] == 2459,
  all(catch$unit == "thousand fish"),
  nrow(catch_weight) == 155L,
  catch_weight$value[catch_weight$year == 1995L & catch_weight$age == 5L] == 0.225,
  nrow(stock_weight) == 155L,
  all(stock_weight$source_type == "reconstructed_source_input"),
  nrow(maturity) == 17L,
  maturity$value[maturity$age == 5L] == 0.13,
  nrow(summer[summer$type == "index", ]) == 224L,
  summer$value[summer$type == "index" & summer$year == 1998L & summer$age == 5L] == 4.317,
  nrow(deepwater[deepwater$type == "index", ]) == 110L,
  identical(sort(unique(deepwater$year[deepwater$type == "index"])), c(2014:2020, 2022:2025)),
  !any(deepwater$year[deepwater$type == "index"] == 2021L),
  deepwater$value[deepwater$type == "index" & deepwater$year == 2014L & deepwater$age == 5L] == 50.9,
  nrow(scottish) == 18L,
  scottish$value[scottish$year == 1998L] == 64.4,
  nrow(cpue) == 21L,
  cpue$value[cpue$year == 2005L] == 13.54,
  nrow(numbers) == 517L,
  identical(sort(unique(numbers$year)), 1995:2025),
  identical(sort(unique(numbers$age)), 5:21),
  numbers$value[numbers$year == 1995L & numbers$age == 9L] == 2459,
  numbers$value[numbers$year == 2025L & numbers$age == 21L] == 575,
  all(numbers$unit == "thousand fish"),
  all(is.na(numbers$se)),
  nrow(f_at_age) == 527L,
  f_at_age$value[f_at_age$year == 1995L & f_at_age$age == 5L] == 0,
  f_at_age$value[f_at_age$year == 2025L & f_at_age$age == 21L] == 0.231,
  all(is.na(f_at_age$se)),
  ssb$value[ssb$year == 2025L] == 104178,
  ssb$lwr[ssb$year == 2025L] == 85061,
  ssb$upr[ssb$year == 2025L] == 127591,
  recruitment$value[recruitment$year == 2025L] == 117734,
  recruitment$age[recruitment$year == 2025L] == 5L,
  fbar$value[fbar$year == 2025L] == 0.188,
  fbar$age_group[fbar$year == 2025L] == "6-14"
)

cat("Greater silver smelt 2026 inputs, report outputs, units, and source gaps passed.\n")
