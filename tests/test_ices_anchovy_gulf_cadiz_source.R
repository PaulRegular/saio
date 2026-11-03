source("R/read_database.R")
x <- read_assessment("ices_anchovy_gulf_cadiz_2025")
i <- x$inputs; o <- x$outputs; a <- x$assumptions
annual <- i[i$type == "catch" & i$measure == "total_biomass", ]
spanish <- i[i$type == "catch" & i$fleet == "Spanish fishery", ]
quarter <- i[i$type == "catch" & i$fleet == "Whole fishery" & i$measure == "numbers_at_age", ]
weights <- i[i$type == "catch_weight", ]
pelago <- i[i$survey == "PELAGO" & i$measure == "total_biomass" & !is.na(i$survey), ]
rec_index <- i[i$survey == "ECOCADIZ-RECLUTAS" & !is.na(i$survey), ]
m <- i[i$type == "M", ]
ssb <- o[o$measure == "SSB", ]; rec <- o[o$measure == "recruitment", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
stopifnot(
  x$stocks$stock_id == "ices_anchovy_gulf_cadiz",
  is.na(x$stocks$charbonneau_id), x$stocks$authority_stock_id == "ane.27.9aS",
  x$stocks$scientific_name == "Engraulis encrasicolus", x$stocks$ocean == "Northeast Atlantic",
  x$assessment$assessment_year == 2025, x$assessment$terminal_year == 2025,
  x$assessment$is_current, x$assessment$is_applied,
  all(x$assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  nrow(i) == 498L, nrow(a) == 16L, nrow(o) == 111L,
  identical(annual$year, 1989:2025), all(annual$unit == "tonnes"),
  annual$value[annual$year == 2025] == 6440,
  nrow(spanish) == 30L * 4L, identical(sort(unique(spanish$year)),1995:2024),
  spanish$value[spanish$year == 2024 & spanish$age == 1] == 587464,
  nrow(quarter) == 16L, all(quarter$year == 2024),
  quarter$value[quarter$season == "Q2" & quarter$age == 1] == 302545,
  sum(quarter$value[quarter$age == 1]) == 589852,
  !any(i$type == "catch" & i$measure == "numbers_at_age" & i$year == 2025, na.rm = TRUE),
  nrow(weights) == 16L, all(weights$year == 2024), all(weights$unit == "g"),
  !any(i$type == "weight"),
  identical(m$value[order(m$age)], c(2.97,1.6,2.48,2.48)), all(is.na(m$year)),
  identical(i$value[i$type == "maturity"], c(0,1,1,1)),
  nrow(pelago) == 27L, pelago$value[pelago$year == 2025] == 60838,
  is.na(pelago$value[pelago$year == 2012]), pelago$value[pelago$year == 2011] == 0,
  !any(pelago$value == 151558, na.rm = TRUE),
  rec_index$value[rec_index$year == 2025] == 20758,
  is.na(rec_index$value[rec_index$year == 2017]), all(rec_index$age == 0),
  all(rec_index$unit == "tonnes"), all(is.na(i$sampling_time)),
  identical(ssb$year,1989:2025), identical(rec$year,1989:2025),
  all(ssb$type == "biomass"), all(rec$type == "recruitment"), all(f$type == "mortality"),
  ssb$value[ssb$year == 2025] == 18730, ssb$value[ssb$year == 2012] == 10584,
  ssb$lwr[ssb$year == 2025] == 11253, ssb$upr[ssb$year == 2025] == 26207,
  all(rec$age == 0), all(rec$season == "Q3"), rec$value[rec$year == 2025] == 11059600,
  all(f$age == 3), f$value[f$year == 2025] == .692,
  is.na(f$lwr[f$year == 2025]), all(is.na(o$se)),
  !any(o$measure %in% c("numbers_at_age", "Fbar", "natural_mortality_at_age", "total_abundance")),
  all(i$year[!is.na(i$year)] <= 2025), all(o$year <= 2025),
  all(grepl("21266", o$source_reference)),
  !any(grepl("mariazuba|MSE reference", i$source_reference))
)
age_counts <- i[i$survey == "PELAGO" & !is.na(i$survey) & i$measure == "numbers_at_age", ]
stopifnot(all(age_counts$unit == "million fish"), nrow(age_counts) == 27L * 5L,
  sum(age_counts$value[age_counts$year == 2014]) == 2891,
  sum(age_counts$value[age_counts$year == 2025]) == 6601,
  all(is.na(age_counts$sample_size)))
legacy <- read_database()$stocks
legacy <- legacy[legacy$stock_id == "ck_ices_wghansa_mordax_sp9a", ]
stopifnot(legacy$charbonneau_id == "ICES-WGHANSA_mordax_SP9a", legacy$area == "SP9a",
  legacy$scientific_name == "Engraulis encrasicolus",
  grepl("historical combined", legacy$common_name, fixed = TRUE),
  grepl("Master.csv names Engraulis mordax", legacy$notes, fixed = TRUE))
cat("Southern anchovy identity, seasonal units, current-vintage provenance, source discrepancies and uncertainty checks passed.\n")
