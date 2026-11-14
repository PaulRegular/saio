Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
e <- new.env(parent = globalenv())
sys.source("scripts/database/650_import_ices_plaice_iceland_5a_2026.R", envir = e)

num <- function(x) as.numeric(x)
catch <- e$inputs[e$inputs$measure == "landings_biomass", , drop = FALSE]
recruitment <- e$outputs[e$outputs$measure == "recruitment", , drop = FALSE]
ssb <- e$outputs[e$outputs$measure == "SSB", , drop = FALSE]
total_biomass <- e$outputs[e$outputs$measure == "total_biomass", , drop = FALSE]
fbar <- e$outputs[e$outputs$measure == "Fbar", , drop = FALSE]
forecast <- e$outputs[!is.na(e$outputs$scenario) &
  e$outputs$scenario == "short_term_forecast", , drop = FALSE]
historical_recruitment <- recruitment[is.na(recruitment$scenario), , drop = FALSE]
historical_ssb <- ssb[is.na(ssb$scenario), , drop = FALSE]
historical_fbar <- fbar[is.na(fbar$scenario), , drop = FALSE]

catch_value <- function(year, fleet) {
  num(catch$value[catch$year == year & catch$fleet == fleet])
}
output_value <- function(data, year) num(data$value[data$year == year])

stopifnot(
  e$stock$stock_id == "ices_plaice_iceland_5a",
  e$stock$authority_stock_id == "ple.27.5a",
  e$stock$ocean == "Northeast Atlantic",
  e$assessment$assessment_year == "2026",
  e$assessment$terminal_year == "2025",
  e$assessment$estimate_terminal_year == "2028",
  e$assessment$assumptions_status == "partial",
  e$assessment$inputs_status == "partial",
  e$assessment$outputs_status == "partial",
  nrow(catch) == 78L,
  identical(sort(unique(as.integer(catch$year))), 2000:2025),
  identical(sort(unique(catch$fleet)), c("Bottom trawl", "Demersal seine", "Other gears")),
  all(catch$unit == "tonnes"),
  catch_value("2000", "Demersal seine") == 3070,
  catch_value("2000", "Bottom trawl") == 1747,
  catch_value("2000", "Other gears") == 442,
  catch_value("2025", "Demersal seine") == 3937,
  catch_value("2025", "Bottom trawl") == 2563,
  catch_value("2025", "Other gears") == 237,
  all(e$inputs$type == "catch"),
  all(e$inputs$measure == "landings_biomass"),
  all(is.na(e$inputs$age)),
  nrow(recruitment) == 49L,
  nrow(ssb) == 49L,
  nrow(total_biomass) == 46L,
  nrow(fbar) == 49L,
  nrow(e$outputs) == 196L,
  max(as.integer(e$outputs$year)) == 2028L,
  output_value(recruitment, "1980") == 26307,
  output_value(ssb, "1980") == 9659,
  output_value(fbar, "1980") == 0.338,
  output_value(recruitment, "2025") == 15626,
  output_value(ssb, "2025") == 21537,
  output_value(fbar, "2025") == 0.234,
  nrow(forecast) == 12L,
  identical(sort(unique(as.integer(forecast$year))), 2026:2028),
  identical(num(forecast$value[forecast$measure == "recruitment"]), c(16589, 16856, 16856)),
  identical(num(forecast$value[forecast$measure == "SSB"]), c(21478, 20566, 19535)),
  identical(num(forecast$value[forecast$measure == "Fbar"]), c(0.261, 0.3, 0.3)),
  identical(num(forecast$value[forecast$measure == "expected_catch_biomass"]), c(7002, 7933, 7508)),
  all(is.na(total_biomass$lwr)),
  all(is.na(total_biomass$upr)),
  all(is.na(e$outputs$se)),
  nrow(historical_recruitment) == 46L,
  nrow(historical_ssb) == 46L,
  nrow(historical_fbar) == 46L,
  all(grepl("90% confidence intervals", historical_recruitment$notes, fixed = TRUE)),
  all(grepl("90% confidence intervals", historical_ssb$notes, fixed = TRUE)),
  all(grepl("90% confidence intervals", historical_fbar$notes, fixed = TRUE)),
  all(fbar$age_group == "5-10"),
  grepl("0.15", e$assumptions$value[e$assumptions$setting == "natural_mortality"], fixed = TRUE),
  grepl("90% confidence intervals", e$assumptions$value[e$assumptions$setting == "interval_definition"], fixed = TRUE),
  e$selected$curation_status[e$selected_row] == "partial_source_import"
)

cat("ICES Icelandic plaice 2026 source test passed.\n")
