Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
e <- new.env(parent = globalenv())
sys.source("scripts/database/649_import_ices_four_spot_megrim_8c9a_2026.R", envir = e)

num <- function(x) as.numeric(x)
age_discard <- e$inputs[e$inputs$measure == "discard_numbers_at_age", ]
catch_inputs <- e$inputs[e$inputs$measure %in% c("landings_biomass", "discard_biomass", "catch_biomass"), ]
mortality <- e$inputs[e$inputs$measure == "natural_mortality_at_age", ]
maturity <- e$inputs[e$inputs$measure == "maturity_at_age", ]
recruitment <- e$outputs[e$outputs$measure == "recruitment", ]
ssb <- e$outputs[e$outputs$measure == "SSB", ]
fbar <- e$outputs[e$outputs$measure == "Fbar", ]
historical <- e$outputs[e$outputs$scenario == "" & e$outputs$measure %in%
  c("recruitment", "SSB", "total_biomass", "Fbar", "expected_catch_biomass"), ]

value_at <- function(data, year, age) {
  num(data$value[data$year == year & data$age == age])
}

stopifnot(
  e$assessment$assessment_year == "2026", e$assessment$terminal_year == "2025",
  e$assessment$estimate_terminal_year == "2026",
  e$assessment$inputs_status == "partial", e$assessment$outputs_status == "partial",
  nrow(age_discard) == 320L,
  identical(sort(unique(as.integer(age_discard$year))), 1986:2025),
  identical(sort(unique(as.integer(age_discard$age))), 0:7),
  sum(is.na(num(age_discard$value))) == 5L,
  all(age_discard$fleet == "Spanish trawlers"),
  all(age_discard$unit == "thousand fish"),
  value_at(age_discard, 1986, 0) == 1289,
  value_at(age_discard, 1994, 0) == 678,
  value_at(age_discard, 1997, 0) == 256,
  value_at(age_discard, 2025, 1) == 65,
  nrow(catch_inputs) == 120L,
  num(catch_inputs$value[catch_inputs$measure == "landings_biomass" & catch_inputs$year == 2025]) == 689,
  num(catch_inputs$value[catch_inputs$measure == "discard_biomass" & catch_inputs$year == 2025]) == 36,
  num(catch_inputs$value[catch_inputs$measure == "catch_biomass" & catch_inputs$year == 2025]) == 725,
  nrow(mortality) == 7L, identical(sort(as.integer(mortality$age)), 0:6),
  all(num(mortality$value) == 0.2),
  grepl("age 6 is the Annex's 6+ group", mortality$notes[mortality$age == 6], fixed = TRUE),
  nrow(maturity) == 6L, identical(num(maturity$value), c(0, 0.05, 0.32, 0.83, 0.98, 1)),
  grepl("age 5 is the 5+ group", maturity$notes[maturity$age == 5], fixed = TRUE),
  nrow(e$outputs[e$outputs$measure == "recruitment" & e$outputs$year <= 2025, ]) == 40L,
  nrow(e$outputs[e$outputs$measure == "SSB" & e$outputs$year <= 2025, ]) == 40L,
  nrow(e$outputs[e$outputs$measure == "total_biomass" & e$outputs$year <= 2025, ]) == 40L,
  nrow(e$outputs[e$outputs$measure == "Fbar" & e$outputs$year <= 2025, ]) == 40L,
  nrow(historical) == 200L,
  all(is.finite(num(recruitment$lwr[recruitment$year <= 2025]))),
  all(is.finite(num(recruitment$upr[recruitment$year <= 2025]))),
  all(is.finite(num(ssb$lwr[ssb$year <= 2025]))),
  all(is.finite(num(ssb$upr[ssb$year <= 2025]))),
  all(is.finite(num(fbar$lwr[fbar$year <= 2025]))),
  all(is.finite(num(fbar$upr[fbar$year <= 2025]))),
  all(is.na(num(e$outputs$se))),
  num(fbar$value[fbar$year == 2026]) == 0.058,
  num(ssb$value[ssb$year == 2027]) == 17466,
  identical(num(recruitment$value[recruitment$age == 1 & recruitment$year %in% c(2026, 2027)]),
    c(21243, 21243)),
  num(e$outputs$value[e$outputs$measure == "expected_catch_biomass" & e$outputs$year == 2026]) == 819,
  e$xml_version == "ldb.27.8c9a_2026_26018_20261112010501",
  grepl("90%", e$assumptions$value[e$assumptions$setting == "interval_definition"], fixed = TRUE),
  e$register$import_status[e$candidate_row] == "partial",
  e$inventory$import_status[e$inventory_row] == "partial",
  e$selected$curation_status[e$selected_row] == "partial_source_import",
  e$selected$candidate_unit_id[e$selected_row] == e$stock_id
)

cat("ICES four-spot megrim 2026 source test passed.\n")
