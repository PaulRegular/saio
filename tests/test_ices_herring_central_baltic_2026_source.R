source("R/read_database.R")
x <- read_assessment("ices_herring_central_baltic_2026")
i <- x$inputs
o <- x$outputs
a <- x$assumptions

catch_age <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
catch_total <- i[i$type == "catch" & i$measure == "total_biomass", ]
stock_weight <- i[i$type == "weight" & i$measure == "weight_at_age", ]
catch_weight <- i[i$type == "catch_weight" & i$measure == "weight_at_age", ]
maturity <- i[i$type == "maturity" & i$measure == "maturity_at_age", ]
index <- i[i$type == "index" & i$measure == "numbers_at_age", ]
m_low <- i[i$type == "M" & i$measure == "fixed_mortality_low", ]
m_medium <- i[i$type == "M" & i$measure == "fixed_mortality_medium", ]
m_high <- i[i$type == "M" & i$measure == "fixed_mortality_high", ]
recruitment <- o[o$measure == "recruitment", ]
ssb <- o[o$measure == "SSB", ]
fbar <- o[o$measure == "Fbar", ]
relative_ssb <- o[o$measure == "SSB_relative_to_MSY_Btrigger", ]
relative_f <- o[o$measure == "Fbar_relative_to_FMSY", ]

stopifnot(
  x$stocks$common_name == "Central Baltic herring",
  x$stocks$authority_stock_id == "her.27.25-2932",
  x$stocks$ocean == "Northeast Atlantic",
  x$assessment$assessment_year == 2026,
  x$assessment$terminal_year == 2025,
  x$assessment$estimate_terminal_year == 2026,
  x$assessment$framework_year == 2023,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$assumptions_status == "partial",
  x$assessment$inputs_status == "partial",
  x$assessment$outputs_status == "partial",
  grepl("32455056.v3", x$assessment$assessment_url),
  grepl("23216492", x$assessment$framework_url),
  nrow(catch_age) == 52L * 8L,
  identical(sort(unique(catch_age$year)), 1974:2025),
  identical(sort(unique(catch_age$age)), 1:8),
  all(catch_age$fleet == "commercial"),
  all(catch_age$unit == "thousand fish"),
  catch_age$value[catch_age$year == 1974 & catch_age$age == 1] == 2436300,
  catch_age$value[catch_age$year == 2025 & catch_age$age == 8] == 233601,
  nrow(catch_total) == 122L,
  identical(sort(unique(catch_total$year)), 1904:2025),
  all(catch_total$unit == "tonnes"),
  catch_total$value[catch_total$year == 2025] == 112427,
  grepl("Russian Federation", catch_total$notes[catch_total$year == 2025]),
  nrow(stock_weight) == 123L * 9L,
  nrow(catch_weight) == 123L * 9L,
  identical(sort(unique(stock_weight$year)), 1903:2025),
  identical(sort(unique(stock_weight$age)), 0:8),
  stock_weight$value[stock_weight$year == 1903 & stock_weight$age == 0] == 0.006,
  stock_weight$value[stock_weight$year == 2025 & stock_weight$age == 8] == 0.0553,
  all(stock_weight$unit == "kg per fish"),
  all(catch_weight$fleet == "commercial"),
  identical(stock_weight$value, catch_weight$value),
  nrow(maturity) == 123L * 10L,
  identical(sort(unique(maturity$year)), 1903:2025),
  identical(sort(unique(maturity$age)), 0:9),
  maturity$value[maturity$year == 1903 & maturity$age == 1] == 0.0954,
  maturity$value[maturity$year == 1974 & maturity$age == 1] == 0.0954,
  maturity$value[maturity$year == 1984 & maturity$age == 1] == 0.0872,
  all(is.na(index$sampling_time)),
  nrow(index) == 20L * 9L,
  identical(sort(unique(index$year)), c(2000L, 2006L, 2007L, 2009L:2025L)),
  identical(sort(unique(index$age)), 0:8),
  all(index$survey == "BIAS"),
  all(index$unit == "million fish"),
  index$value[index$year == 2000 & index$age == 1] == 36325,
  index$value[index$year == 2025 & index$age == 8] == 250,
  all(index$value[index$age == 0] == 0),
  nrow(m_low) == 123L * 9L,
  nrow(m_medium) == 123L * 9L,
  nrow(m_high) == 123L * 9L,
  all(m_low$value[m_low$year == 1903] == m_low$value[m_low$year == 1974]),
  all(m_medium$value[m_medium$year == 2025] == m_medium$value[m_medium$year == 2021]),
  all(m_high$value[m_high$year == 1903] == m_high$value[m_high$year == 1974]),
  mean(m_low$value) < mean(m_medium$value),
  mean(m_medium$value) < mean(m_high$value),
  nrow(recruitment) == 123L,
  nrow(ssb) == 123L,
  nrow(fbar) == 122L,
  nrow(relative_ssb) == 123L,
  nrow(relative_f) == 122L,
  recruitment$value[recruitment$year == 2025] == 22543827,
  recruitment$lwr[recruitment$year == 2025] == 11676641,
  recruitment$upr[recruitment$year == 2025] == 44378080,
  ssb$value[ssb$year == 2025] == 951517,
  ssb$lwr[ssb$year == 2025] == 762304,
  ssb$upr[ssb$year == 2025] == 1284996,
  fbar$value[fbar$year == 2025] == 0.143,
  fbar$age_group[fbar$year == 2025] == "3-6",
  !any(fbar$year == 2026),
  relative_ssb$value[relative_ssb$year == 2025] == 0.68,
  relative_f$value[relative_f$year == 2025] == 0.57,
  all(is.na(o$se)),
  all(grepl("central 90%", c(recruitment$notes, ssb$notes, fbar$notes))),
  any(a$component == "catch" & a$setting == "composition_weighting" &
    grepl("Dirichlet-multinomial", a$value)),
  any(a$component == "index" & a$setting == "survey_timing" &
    grepl("fractional timing unknown", a$value)),
  any(a$component == "M" & a$setting == "ensemble_scenarios"),
  !anyDuplicated(paste(i$type, i$measure, i$fleet, i$survey, i$year, i$age, sep = "\034")),
  !anyDuplicated(paste(o$type, o$measure, o$year, o$age, o$age_group, sep = "\034"))
)

cat("Central Baltic herring source identity, inputs, coverage, scenario expansion and output uncertainty passed.\n")
