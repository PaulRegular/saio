source("R/read_database.R")

database <- read_database()
x <- read_assessment("ices_cod_west_greenland_offshore_2026", database)
inputs <- x$inputs
outputs <- x$outputs

stopifnot(
  x$stocks$stock_id == "ices_cod_west_greenland_offshore",
  x$stocks$authority_stock_id == "cod.21.1.osc",
  x$stocks$scientific_name == "Gadus morhua",
  x$stocks$ocean == "Northwest Atlantic",
  grepl("West Greenland offshore spawning", x$stocks$common_name),
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2025L,
  x$assessment$estimate_terminal_year == 2025L,
  x$assessment$model_family == "SAM",
  grepl("NWWG26_WOSC_v1", x$assessment$model_version),
  grepl("NWWG26_WOSC_v1/run/model.RData", x$assessment$model_url),
  x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 0L,
  nrow(x$assumptions) == 12L,
  nrow(outputs) == 103L,
  all(outputs$source_type == "official_table"),
  all(grepl("Table 13.3.1", outputs$source_reference, fixed = TRUE))
)

ssb <- outputs[outputs$measure == "SSB", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
fbar <- outputs[outputs$measure == "Fbar", ]
catch <- outputs[outputs$measure == "total_catch", ]

stopifnot(
  nrow(ssb) == 26L,
  identical(sort(unique(ssb$year)), 2000:2025),
  ssb$value[ssb$year == 2000L] == 179,
  ssb$lwr[ssb$year == 2000L] == 66,
  ssb$upr[ssb$year == 2000L] == 487,
  ssb$value[ssb$year == 2025L] == 23227,
  ssb$lwr[ssb$year == 2025L] == 16258,
  ssb$upr[ssb$year == 2025L] == 33184,
  all(ssb$unit == "tonnes"),
  all(is.na(ssb$se)),
  nrow(recruitment) == 26L,
  identical(sort(unique(recruitment$year)), 2000:2025),
  all(recruitment$age == 2L),
  recruitment$value[recruitment$year == 2025L] == 7554,
  recruitment$lwr[recruitment$year == 2025L] == 3140,
  recruitment$upr[recruitment$year == 2025L] == 18170,
  all(recruitment$unit == "thousand fish"),
  all(is.na(recruitment$se)),
  nrow(fbar) == 26L,
  identical(sort(unique(fbar$year)), 2000:2025),
  all(fbar$age_group == "5-8"),
  fbar$value[fbar$year == 2025L] == 0.47,
  fbar$lwr[fbar$year == 2025L] == 0.31,
  fbar$upr[fbar$year == 2025L] == 0.70,
  all(fbar$unit == "per year"),
  all(is.na(fbar$se)),
  nrow(catch) == 25L,
  identical(sort(unique(catch$year)), c(2000L, 2002L:2025L)),
  catch$value[catch$year == 2000L] == 185,
  catch$value[catch$year == 2025L] == 11215,
  all(catch$unit == "tonnes"),
  all(catch$region == "WOSC (NAFO Divisions 1A-1F)"),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"))
)

assumptions <- x$assumptions
fixed_m <- assumptions[assumptions$setting == "natural_mortality", ]
survey_time <- assumptions[assumptions$setting == "sampling_time_fraction_year", ]
stopifnot(
  nrow(fixed_m) == 1L,
  fixed_m$value == "Fixed M = 0.2 per year for all ages",
  nrow(survey_time) == 1L,
  survey_time$value == "unknown"
)

candidate <- read.csv(
  "discovery/candidates.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)
candidate <- candidate[candidate$candidate_id == "ICES:cod.21.1.osc", ]
selected <- read.csv(
  "discovery/selected_batch_01_2026.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)
selected <- selected[selected$candidate_id == "ICES:cod.21.1.osc", ]
review <- readLines(
  "discovery/source_reviews/ices_greenland_cod_identity_2026.md"
)
stopifnot(
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  any(grepl("offshore key 19562", review, fixed = TRUE)),
  any(grepl("no wosc age-specific input arrays were recovered", tolower(review), fixed = TRUE))
)

cat("West Greenland offshore cod partial source coverage, units, provenance, and reported outputs passed.\n")
