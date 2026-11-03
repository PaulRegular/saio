source("R/read_database.R")
source_data <- read_assessment("ices_cod_celtic_sea_2026")
inputs <- source_data$inputs
outputs <- source_data$outputs

catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
commercial <- inputs[inputs$measure == "relative_biomass_index", ]
vast <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
stock_weight <- inputs[inputs$type == "weight" & inputs$measure == "weight_at_age", ]
catch_weight <- inputs[inputs$type == "catch_weight" & inputs$measure == "weight_at_age", ]
discard_weight <- inputs[inputs$measure == "discard_weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
mortality <- inputs[inputs$type == "M" & inputs$measure == "natural_mortality_at_age", ]
landings_fraction <- inputs[inputs$measure == "landings_fraction_at_age", ]
fraction_f <- inputs[inputs$measure == "fraction_F_before_spawning", ]
fraction_m <- inputs[inputs$measure == "fraction_M_before_spawning", ]
n <- outputs[outputs$measure == "numbers_at_age", ]
f <- outputs[outputs$measure == "fishing_mortality_at_age", ]
ssb <- outputs[outputs$measure == "SSB", ]
tsb <- outputs[outputs$measure == "total_biomass", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
fbar <- outputs[outputs$measure == "Fbar", ]
total_n <- outputs[outputs$measure == "total_numbers", ]
predicted_catch <- outputs[outputs$measure == "predicted_catch", ]
predicted_index <- outputs[outputs$measure == "predicted_index", ]

stopifnot(
  source_data$stocks$common_name == "Celtic Sea cod",
  source_data$stocks$authority_stock_id == "cod.27.7e-k",
  source_data$stocks$area == "ICES divisions 7.e-k",
  source_data$stocks$ocean == "Northeast Atlantic",
  source_data$assessment$assessment_year == 2026,
  source_data$assessment$terminal_year == 2025,
  source_data$assessment$framework_year == 2020,
  source_data$assessment$is_current,
  source_data$assessment$is_applied,
  source_data$assessment$assumptions_status == "complete",
  source_data$assessment$inputs_status == "complete",
  source_data$assessment$outputs_status == "complete",
  all(is.finite(inputs$value)),
  nrow(catch) == 46L * 7L - 48L,
  identical(sort(unique(catch$year)), 1980:2025),
  identical(sort(unique(catch$age)), 1:7),
  all(is.finite(catch$value)),
  !any(catch$age %in% 1:2 & catch$year <= 2003),
  all(catch$unit == "thousand fish"),
  nrow(commercial) == 24L,
  all(is.na(commercial$age)),
  identical(sort(unique(commercial$year)), 2002:2025),
  all(commercial$basis == "index_scale"),
  all(commercial$unit == "kg per hour"),
  all(commercial$survey == "FR_OTDEF Q2+3+4"),
  nrow(vast) == 23L * 3L - 1L,
  identical(sort(unique(vast$year)), 2003:2025),
  identical(sort(unique(vast$age)), 1:3),
  all(is.finite(vast$value)),
  !any(vast$year == 2025 & vast$age == 3),
  all(vast$survey == "VAST_IGFS_EVHOE"),
  all(vast$basis == "index_scale"),
  all(vast$sampling_time == 0.855),
  nrow(stock_weight) == 46L * 7L,
  nrow(catch_weight) == 46L * 7L,
  nrow(discard_weight) == 46L * 7L - 46L,
  all(is.finite(discard_weight$value)),
  nrow(maturity) == 46L * 7L,
  setequal(unique(maturity$value), c(0, 0.54, 0.93, 1)),
  nrow(mortality) == 7L,
  all(is.na(mortality$year)),
  identical(sort(mortality$age), 1:7),
  identical(mortality$value[order(mortality$age)], c(0.501, 0.330, 0.264, 0.233, 0.211, 0.211, 0.211)),
  nrow(landings_fraction) == 46L * 7L,
  all(landings_fraction$value >= 0 & landings_fraction$value <= 1),
  all(fraction_f$value == 0),
  all(fraction_m$value == 0),
  nrow(n) == 46L * 7L,
  nrow(f) == 46L * 7L,
  all(n$type == "population"),
  all(f$type == "mortality"),
  all(n$age_group[n$age == 7] == "7+"),
  all(f$age_group[f$age == 7] == "7+"),
  all(is.finite(n$se) & n$se > 0),
  all(is.finite(f$se) & f$se > 0),
  max(abs(f$value[f$year == 2025 & f$age == 6] - f$value[f$year == 2025 & f$age == 7])) == 0,
  nrow(ssb) == 46L,
  nrow(tsb) == 46L,
  nrow(recruitment) == 46L,
  nrow(fbar) == 46L,
  all(ssb$lwr < ssb$value & ssb$value < ssb$upr),
  all(tsb$lwr < tsb$value & tsb$value < tsb$upr),
  all(recruitment$lwr < recruitment$value & recruitment$value < recruitment$upr),
  all(fbar$lwr < fbar$value & fbar$value < fbar$upr),
  abs(ssb$value[ssb$year == 2025] - 98.94244) < 1e-4,
  abs(tsb$value[tsb$year == 2025] - 251.3871) < 1e-3,
  abs(recruitment$value[recruitment$year == 2025] - 183.1951) < 1e-4,
  abs(fbar$value[fbar$year == 2025] - 1.434834) < 1e-5,
  nrow(total_n) == 46L,
  all(total_n$source_type == "derived_source_output"),
  all(is.na(total_n$se)),
  isTRUE(all.equal(total_n$value[total_n$year == 2025], sum(n$value[n$year == 2025]), tolerance = 1e-12)),
  nrow(predicted_catch) == 46L * 7L,
  sum(predicted_index$survey == "FR_OTDEF Q2+3+4") == 24L,
  sum(predicted_index$survey == "VAST_IGFS_EVHOE") == 23L * 3L,
  all(inputs$year[!is.na(inputs$year)] <= 2025),
  all(outputs$year[!is.na(outputs$year)] <= 2025),
  !anyDuplicated(paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey, inputs$year, inputs$age)),
  !anyDuplicated(paste(outputs$measure, outputs$year, outputs$age, outputs$survey))
)

review <- readLines("source_reviews/ices_cod_celtic_sea_2026.md", warn = FALSE)
review_text <- gsub("\\s+", " ", paste(review, collapse = " "))
stopifnot(
  grepl("returned HTTP 401", review_text, fixed = TRUE),
  grepl("commercial LPUE index is aggregate", review_text, fixed = TRUE),
  grepl("age-1 recruitment", review_text, fixed = TRUE)
)

cat("Celtic Sea cod source identity, coverage, units, provenance and output checks passed.\n")
