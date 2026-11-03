source("R/read_database.R")
x <- read_assessment("nefsc_cod_georges_bank_2024")
i <- x$inputs; o <- x$outputs
catch <- i[i$type == "catch", ]; m <- i[i$type == "M", ]
ssb <- o[o$measure == "SSB" & o$source_type == "official_table", ]
r <- o[o$measure == "recruitment" & o$source_type == "official_table", ]
f <- o[o$measure == "fishing_mortality_at_age" & o$source_type == "official_table", ]
stopifnot(
  x$stocks$stock_id == "nefsc_cod_georges_bank", is.na(x$stocks$charbonneau_id),
  x$stocks$authority == "NOAA-NEFSC", x$stocks$ocean == "Northwest Atlantic",
  grepl("521 and 526", x$stocks$area, fixed = TRUE),
  x$assessment$assessment_year == 2024, x$assessment$terminal_year == 2023,
  x$assessment$estimate_terminal_year == 2023, x$assessment$framework_year == 2023,
  x$assessment$is_current, x$assessment$is_applied, x$assessment$model_family == "WHAM",
  all(x$assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  nrow(i) == 19L, nrow(o) == 138L, nrow(x$assumptions) == 17L,
  identical(catch$year, 2014:2023), all(catch$measure == "total_biomass"),
  all(catch$unit == "tonnes"), catch$value[catch$year == 2023] == 417,
  catch$value[catch$year == 2014] == 1310,
  nrow(m) == 9L, identical(m$age, 1:9), all(m$value == .29), all(is.na(m$year)),
  all(m$basis == "per_year"), all(m$unit == "year^-1"),
  all(m$source_type == "official_document"),
  !any(i$type == "index"), !any(i$measure == "numbers_at_age"),
  !any(i$type %in% c("weight", "maturity")),
  identical(ssb$year, 2014:2023), all(ssb$type == "biomass"),
  ssb$value[ssb$year == 2023] == 2668, ssb$value[ssb$year == 2014] == 4528,
  all(r$type == "recruitment"), all(r$age == 1), all(r$unit == "thousand fish"),
  r$value[r$year == 2023] == 605,
  all(f$age == 9), all(f$age_group == "9+"), f$value[f$year == 2023] == .13,
  all(is.na(o$se)), all(is.na(o$lwr)), all(is.na(o$upr)),
  grepl("90% JOINT", ssb$notes[ssb$year == 2023], fixed = TRUE),
  !any(o$measure %in% c("numbers_at_age", "Fbar", "natural_mortality_at_age")),
  all(o$year <= 2023), all(catch$year <= 2023)
)
a <- x$assumptions
stopifnot(grepl("Decoupled 2DAR1", a$value[a$setting == "process"], fixed = TRUE),
  grepl("switched off", a$value[a$setting == "lognormal_adjustment"], fixed = TRUE),
  grepl("fixed at 1 for ages 1-3", a$value[a$setting == "fall_selectivity"], fixed = TRUE))
legacy <- read_database()$stocks
legacy <- legacy[legacy$stock_id == "ck_nefsc_garmiii_morhua_gb", ]
stopifnot(legacy$charbonneau_id == "NEFSC-GARMIII_morhua_GB", legacy$area == "GB",
  grepl("related current stock_id=nefsc_cod_georges_bank", tolower(legacy$notes), fixed = TRUE))
cat("GB cod official run, revised boundary, fixed M, catch totals, F9+ and non-marginal uncertainty checks passed.\n")
