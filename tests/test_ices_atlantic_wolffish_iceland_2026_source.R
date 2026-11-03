source("R/read_database.R")

database <- read_database()
x <- read_assessment("ices_atlantic_wolffish_iceland_2026", database)
inputs <- x$inputs
outputs <- x$outputs

stopifnot(
  x$stocks$stock_id == "ices_atlantic_wolffish_iceland_5a",
  x$stocks$authority_stock_id == "caa.27.5a",
  x$stocks$scientific_name == "Anarhichas lupus",
  x$stocks$ocean == "Northeast Atlantic",
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2025L,
  x$assessment$estimate_terminal_year == 2026L,
  x$assessment$model_family == "SAM",
  x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
landings <- inputs[inputs$type == "catch" & inputs$measure == "landings_biomass", ]
catch_weights <- inputs[inputs$type == "catch_weight", ]
stock_weights <- inputs[inputs$type == "weight", ]
maturity <- inputs[inputs$type == "maturity", ]
spring <- inputs[!is.na(inputs$survey) & inputs$survey == "Icelandic spring groundfish survey (IS-SMB)", ]
autumn <- inputs[!is.na(inputs$survey) & inputs$survey == "Icelandic autumn groundfish survey (IS-SMH)", ]
natural_mortality <- inputs[inputs$type == "M", ]

stopifnot(
  nrow(catch) == 390L,
  identical(sort(unique(catch$year)), c(1979L, 1980L, 1998L:2025L)),
  identical(sort(unique(as.integer(catch$age))), 4:16),
  !any(catch$year %in% 1981:1997),
  catch$value[catch$year == 1979L & catch$age == 4L] == 2.104,
  all(catch$unit == "thousand fish"),
  all(grepl("Age 16 is the 16\\+ plus group", catch$notes)),
  nrow(landings) == 17L,
  identical(sort(unique(landings$year)), 1981:1997),
  landings$value[landings$year == 1981L] == 8621,
  landings$value[landings$year == 1997L] == 11736,
  all(landings$unit == "tonnes"),
  all(landings$source_type == "reconstructed_source_input"),
  all(grepl("does not reconcile directly", landings$notes)),
  nrow(catch_weights) == 611L,
  catch_weights$value[catch_weights$year == 1979L & catch_weights$age == 4L] == 1054,
  all(catch_weights$unit == "g/fish"),
  nrow(stock_weights) == 611L,
  stock_weights$value[stock_weights$year == 1979L & stock_weights$age == 4L] == 76,
  all(stock_weights$unit == "g/fish"),
  nrow(maturity) == 611L,
  maturity$value[maturity$year == 1979L & maturity$age == 4L] == 0.007,
  all(maturity$sex == "female"),
  all(maturity$value >= 0 & maturity$value <= 1),
  nrow(spring) == 533L,
  identical(sort(unique(spring$year)), 1985:2025),
  identical(sort(unique(as.integer(spring$age))), 4:16),
  spring$value[spring$year == 1985L & spring$age == 4L] == 0.483,
  all(spring$basis == "index_scale"),
  all(spring$sampling_time == 0.17),
  nrow(autumn) == 338L,
  identical(sort(unique(autumn$year)), 2000:2025),
  autumn$value[autumn$year == 2000L & autumn$age == 4L] == 0.168,
  all(autumn$basis == "index_scale"),
  all(autumn$sampling_time == 0.83),
  all(grepl("2011 row is retained", autumn$notes[autumn$year == 2011L])),
  nrow(natural_mortality) == 13L,
  identical(sort(as.integer(natural_mortality$age)), 4:16),
  all(natural_mortality$value == 0.15),
  all(natural_mortality$basis == "per_year")
)

numbers <- outputs[outputs$type == "population" & outputs$measure == "numbers_at_age", ]
f_at_age <- outputs[outputs$measure == "fishing_mortality_at_age", ]
ssb <- outputs[outputs$measure == "SSB", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
fbar <- outputs[outputs$measure == "Fbar", ]

stopifnot(
  nrow(numbers) == 624L,
  identical(sort(unique(numbers$year)), 1979:2026),
  identical(sort(unique(as.integer(numbers$age))), 4:16),
  numbers$value[numbers$year == 1979L & numbers$age == 4L] == 19013,
  all(numbers$unit == "thousand fish"),
  nrow(f_at_age) == 611L,
  identical(sort(unique(f_at_age$year)), 1979:2025),
  identical(sort(unique(as.integer(f_at_age$age))), 4:16),
  f_at_age$value[f_at_age$year == 1979L & f_at_age$age == 10L] == 0.162,
  all(f_at_age$unit == "per year"),
  all(is.na(numbers$se) & is.na(numbers$lwr) & is.na(numbers$upr)),
  all(is.na(f_at_age$se) & is.na(f_at_age$lwr) & is.na(f_at_age$upr)),
  nrow(ssb) == 48L,
  ssb$value[ssb$year == 1979L] == 14739,
  ssb$lwr[ssb$year == 1979L] == 12864,
  ssb$upr[ssb$year == 1979L] == 16888,
  all(is.na(ssb$se)),
  nrow(recruitment) == 48L,
  recruitment$age[recruitment$year == 1979L] == 4L,
  recruitment$value[recruitment$year == 1979L] == 19013,
  recruitment$lwr[recruitment$year == 1979L] == 15767,
  recruitment$upr[recruitment$year == 1979L] == 22926,
  nrow(fbar) == 47L,
  identical(sort(unique(fbar$year)), 1979:2025),
  all(fbar$age_group == "10-15"),
  fbar$value[fbar$year == 1979L] == 0.373,
  fbar$lwr[fbar$year == 1979L] == 0.281,
  fbar$upr[fbar$year == 1979L] == 0.496,
  all(is.na(fbar$se)),
  !any(outputs$measure == "natural_mortality_at_age")
)

candidate <- read.csv(
  "discovery/candidates.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)
candidate <- candidate[candidate$candidate_id == "ICES:caa.27.5a", ]
selected <- read.csv(
  "discovery/selected_batch_01_2026.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)
selected <- selected[selected$candidate_id == "ICES:caa.27.5a", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import"
)

cat("Icelandic Atlantic wolffish 2026 source coverage, units, caveats, and outputs passed.\n")
