source("scripts/database/677_import_ices_wgnas_2026.R")
wg <- import_ices_wgnas_2026(write = FALSE)

stopifnot(
  identical(sort(wg$stocks$authority_stock_id), c("sal.nac.all", "sal.neac.all")),
  identical(sort(wg$stocks$ocean), c("Northeast Atlantic", "Northwest Atlantic")),
  nrow(wg$stocks) == 2L,
  nrow(wg$assessments) == 2L,
  all(wg$assessments$assessment_year == 2026L),
  all(wg$assessments$terminal_year == 2025L),
  all(wg$assessments$estimate_terminal_year == 2029L),
  nrow(wg$inputs) == 3363L,
  nrow(wg$assumptions) == 80L,
  nrow(wg$outputs) == 7003L,
  all(is.na(wg$inputs$age)),
  all(grepl("^WGNAS2026_", wg$inputs$observation_id)),
  all(wg$inputs$source_type == "official_table"),
  all(wg$outputs$source_type == "official_table"),
  all(wg$outputs$unit == "thousand fish"),
  all(wg$outputs$scenario %in% c("", "Forecast")),
  all(wg$outputs$year <= 2029L),
  any(wg$outputs$measure == "returns"),
  any(wg$outputs$measure == "spawners"),
  any(wg$outputs$measure == "pre_fishery_abundance"),
  !any(wg$outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "SSB", "recruitment"))
)

catch <- wg$inputs[
  wg$inputs$assessment_id == "ices_salmo_salar_nac_2026" &
    wg$inputs$region == "Canada" & wg$inputs$year == 1982L &
    wg$inputs$observation_id == "WGNAS2026_1SW_catch_numbers", , drop = FALSE
]
stopifnot(nrow(catch) == 1L, catch$value == 358000, catch$unit == "fish")

returns <- wg$outputs[
  wg$outputs$assessment_id == "ices_salmo_salar_nac_2026" &
    wg$outputs$measure == "returns" & wg$outputs$region == "LB" &
    wg$outputs$year == 1970L & wg$outputs$age_group == "Small", , drop = FALSE
]
stopifnot(nrow(returns) == 1L, returns$value == 47,
  returns$lwr == 31.9, returns$upr == 70.9)

forecast <- wg$outputs[
  wg$outputs$assessment_id == "ices_salmo_salar_neac_2026" &
    wg$outputs$measure == "pre_fishery_abundance" &
    wg$outputs$region == "N_NEAC" & wg$outputs$year == 2029L &
    wg$outputs$scenario == "Forecast", , drop = FALSE
]
stopifnot(nrow(forecast) >= 1L,
  all(grepl("90% interval", forecast$notes, fixed = TRUE)))

cat("WGNAS 2026 source conversion checks passed.\n")
