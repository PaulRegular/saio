Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
e <- new.env(parent = globalenv())
sys.source("scripts/database/648_import_ices_pollack_6_7_2026.R", envir = e)

inputs <- e$inputs
outputs <- e$outputs
num <- function(x) as.numeric(x)
landings <- inputs[inputs$measure == "landings_biomass" & inputs$source_type == "official_machine_readable", ]
mortality <- inputs[inputs$measure == "natural_mortality_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
projected <- inputs[inputs$year == 2026, ]
rec <- outputs[outputs$measure == "recruitment", ]
ssb <- outputs[outputs$measure == "SSB", ]
fbar <- outputs[outputs$measure == "Fbar", ]
advice <- outputs[outputs$measure == "catch_advice", ]

stopifnot(
  nrow(inputs) == 100L, nrow(landings) == 76L, nrow(e$assumptions) == 18L, nrow(outputs) == 234L,
  identical(as.integer(landings$year), 1950:2025),
  all(landings$unit == "tonnes"),
  num(landings$value[landings$year == 2024]) == 706,
  num(landings$value[landings$year == 2025]) == 609,
  nrow(mortality) == 11L, identical(as.integer(mortality$age), 0:10),
  num(mortality$value[mortality$age == 0]) == 0.920,
  num(mortality$value[mortality$age == 10]) == 0.311,
  nrow(maturity) == 11L,
  identical(num(maturity$value), c(0, 0, 0, 0.9, rep(1, 7))),
  all(projected$year_basis == "calendar_year"),
  sum(projected$measure == "landings_biomass") == 1L,
  sum(projected$measure == "catch_biomass") == 1L,
  nrow(rec) == 78L,
  num(rec$value[rec$year == 2026]) == 41404,
  num(rec$value[rec$year == 2027]) == 40624,
  num(rec$lwr[rec$year == 2026]) == 16619,
  num(rec$upr[rec$year == 2026]) == 76779,
  nrow(ssb) == 78L,
  num(ssb$value[ssb$year == 2025]) == 13180,
  num(ssb$value[ssb$year == 2026]) == 15380,
  num(ssb$value[ssb$year == 2027]) == 14534,
  nrow(fbar) == 77L,
  num(fbar$value[fbar$year == 2025]) == 0.150,
  num(fbar$value[fbar$year == 2026]) == 0.29,
  nrow(advice) == 1L, num(advice$value) == 3216, advice$year == 2027L,
  all(outputs$source_type[is.finite(num(outputs$value))] %in%
    c("official_machine_readable", "official_document")),
  !any(inputs$measure %in% c("numbers_at_age", "index_by_age_group", "weight_at_age")),
  grepl("not published", e$assumptions$notes[e$assumptions$setting == "catch_age_data"], fixed = TRUE),
  e$assessment$terminal_year == "2025",
  e$assessment$estimate_terminal_year == "2026",
  e$assessment$inputs_status == "partial",
  e$assessment$outputs_status == "partial",
  e$register$import_status[e$candidate_row] == "partial",
  e$inventory$import_status[e$inventory_row] == "partial",
  e$selected$curation_status[e$selected_row] == "partial_source_import",
  e$xml_version == "pol.27.67_2026_23709_20261112010501"
)
cat("ICES Pollack 2026 source test passed.\n")