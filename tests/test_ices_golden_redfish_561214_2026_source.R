source("R/read_database.R")

database <- read_database()
x <- read_assessment("ices_golden_redfish_561214_2026", database)

stopifnot(
  x$stocks$stock_id == "ices_golden_redfish_561214",
  x$stocks$authority_stock_id == "reg.27.561214",
  x$stocks$scientific_name == "Sebastes norvegicus",
  x$stocks$ocean == "Northeast Atlantic",
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2025L,
  x$assessment$estimate_terminal_year == 2026L,
  x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

inputs <- x$inputs
catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
landings <- inputs[inputs$type == "catch" & inputs$measure == "total_biomass", ]
catch_weight <- inputs[inputs$type == "catch_weight" & inputs$measure == "weight_at_age", ]
stock_weight <- inputs[inputs$type == "weight" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$type == "maturity" & inputs$measure == "maturity_at_age", ]
autumn <- inputs[inputs$type == "index" & inputs$survey == "Icelandic autumn groundfish survey (IS-SMH)", ]

stopifnot(
  nrow(catch) == 620L,
  identical(sort(unique(catch$year)), 1995:2025),
  identical(sort(unique(catch$age)), 6:25),
  catch$value[catch$year == 1995L & catch$age == 6L] == 0.063,
  all(catch$unit == "thousand fish"),
  nrow(landings) == 60L,
  landings$value[landings$year == 1966L] == 82589,
  landings$value[landings$year == 2025L] == 43726,
  all(landings$source_type == "reconstructed_source_input"),
  all(grepl("match the MFRI assessment-summary", landings$transformation, fixed = TRUE)),
  nrow(catch_weight) == 1200L,
  catch_weight$value[catch_weight$year == 1966L & catch_weight$age == 6L] == 424,
  all(catch_weight$unit == "g/fish"),
  nrow(stock_weight) == 1200L,
  stock_weight$value[stock_weight$year == 2025L & stock_weight$age == 25L] == 935,
  nrow(maturity) == 800L,
  maturity$value[maturity$year == 1986L & maturity$age == 6L] == 0.056,
  all(maturity$value >= 0 & maturity$value <= 1),
  nrow(autumn) == 599L,
  identical(sort(unique(autumn$year)), 1996:2025),
  identical(sort(unique(autumn$age)), 6:25),
  autumn$value[autumn$year == 2011L & autumn$age == 6L] == 3.08,
  is.na(autumn$sampling_time[autumn$year == 1996L][1]),
  grepl("no October survey", autumn$notes[autumn$year == 2011L & autumn$age == 6L], ignore.case = TRUE),
  !any(grepl("spring", inputs$survey, ignore.case = TRUE), na.rm = TRUE)
)

outputs <- x$outputs
numbers <- outputs[outputs$type == "population" & outputs$measure == "numbers_at_age", ]
f_at_age <- outputs[outputs$type == "mortality" & outputs$measure == "fishing_mortality_at_age", ]
ssb <- outputs[outputs$measure == "SSB", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
fbar <- outputs[outputs$measure == "Fbar", ]
total_biomass <- outputs[outputs$measure == "total_biomass" & outputs$type == "biomass", ]

stopifnot(
  identical(sort(unique(numbers$year)), 1966:2026),
  identical(sort(unique(numbers$age)), 6:25),
  numbers$value[numbers$year == 1966L & numbers$age == 6L] == 165779,
  numbers$value[numbers$year == 2026L & numbers$age == 6L] == 47111,
  identical(sort(unique(f_at_age$year)), 1966:2025),
  identical(sort(unique(f_at_age$age)), 6:25),
  f_at_age$value[f_at_age$year == 2025L & f_at_age$age == 25L] == 0.043,
  identical(sort(unique(ssb$year)), 1966:2026),
  all(is.finite(ssb$lwr) & is.finite(ssb$upr)),
  all(is.na(ssb$se)),
  recruitment$age[recruitment$year == 2025L] == 6L,
  all(fbar$age_group == "9–19"),
  identical(sort(unique(total_biomass$year)), 1966:2026),
  all(c("Model-reported total catches", "Model-reported discards") %in% outputs$fleet)
)

natural_mortality <- x$assumptions[
  x$assumptions$component == "M" & x$assumptions$setting == "natural_mortality",
]
stopifnot(
  nrow(natural_mortality) == 1L,
  grepl("ages 6-24", natural_mortality$value, fixed = TRUE),
  grepl("age 25+", natural_mortality$value, fixed = TRUE)
)

cat("Golden redfish 2026 source coverage, units, transformations, outputs and uncertainty passed.\n")
