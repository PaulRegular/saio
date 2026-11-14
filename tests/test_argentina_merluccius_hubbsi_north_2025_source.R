read_source_table <- function(path) utils::read.csv(path,
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock_id <- "argentina_merluccius_hubbsi_north_41s"
assessment_id <- paste0(stock_id, "_2025")
stock <- read_source_table("database/stocks.csv")
stock <- stock[stock$stock_id == stock_id, , drop = FALSE]
assessment <- read_source_table("database/assessments.csv")
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_source_table("database/inputs.csv")
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- read_source_table("database/outputs.csv")
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
assumptions <- read_source_table("database/assumptions.csv")
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- read_source_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == "INIDEP:MERLUCCIUS_HUBBSI_NORTH41", , drop = FALSE]
selection <- read_source_table("discovery/selected_batch_13_2026.csv")
selection <- selection[selection$candidate_id == "INIDEP:MERLUCCIUS_HUBBSI_NORTH41", , drop = FALSE]
unit <- read_source_table("discovery/inventory_units.csv")
unit <- unit[!is.na(unit$candidate_unit_id) & unit$candidate_unit_id == stock_id, , drop = FALSE]

catch_biomass <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", ]
catch_age <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
commercial_weights <- inputs[inputs$measure == "catch_weight_at_age", ]
cpue <- inputs[inputs$measure == "relative_biomass_index", ]
global_age <- inputs[!is.na(inputs$survey) &
  inputs$survey == "Joint global survey (BIP Holmberg / Oca Balda)", ]
age2_index <- inputs[inputs$measure == "recruitment_index" & inputs$age == 2, ]
age1_index <- inputs[inputs$measure == "recruitment_index" & inputs$age == 1, ]
population_weights <- inputs[inputs$type == "weight" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
natural_mortality <- inputs[inputs$measure == "natural_mortality_at_age", ]
scenario_outputs <- outputs[outputs$scenario %in% c("E1", "E2", "E3") &
  outputs$measure %in% c("total_biomass", "spawning_biomass", "recruitment"), ]
cba <- outputs[outputs$measure == "recommended_biological_catch", ]
projected_f <- outputs[outputs$measure == "fishing_mortality_scalar" & outputs$year == 2026, ]
historical_cmp <- outputs[outputs$measure == "maximum_permissible_catch" & outputs$year != 2026, ]
official_limit <- outputs[outputs$measure == "maximum_permissible_catch" & outputs$year == 2026, ]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Merluccius hubbsi",
  stock$authority == "INIDEP",
  stock$ocean == "Southwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2024,
  assessment$estimate_terminal_year == 2024,
  assessment$is_current,
  assessment$is_applied,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 24L,
  nrow(inputs) == 934L,
  nrow(outputs) == 381L,
  nrow(catch_biomass) == 206L,
  nrow(catch_age) == 273L,
  nrow(commercial_weights) == 273L,
  nrow(cpue) == 39L,
  nrow(global_age) == 91L,
  nrow(age2_index) == 5L,
  nrow(age1_index) == 26L,
  nrow(population_weights) == 7L,
  nrow(maturity) == 7L,
  nrow(natural_mortality) == 7L,
  all(natural_mortality$value == 0.3),
  all(population_weights$season == "1 January"),
  all(global_age$sampling_time == 0.75),
  all(age2_index$year_basis == "model_year"),
  all(age2_index$sampling_time == 0),
  all(age1_index$sampling_time[age1_index$season == "spring"] == 0.75),
  all(age1_index$sampling_time[age1_index$season == "autumn"] == 0.417),
  all(is.na(cpue$sampling_time)),
  all(catch_age$unit == "thousand individuals"),
  all(commercial_weights$unit == "kg per fish"),
  all(global_age$unit == "thousand individuals"),
  catch_age$value[catch_age$year == 1986 & catch_age$age == 1] == 3591,
  commercial_weights$value[commercial_weights$year == 1986 & commercial_weights$age == 1] == 0.235,
  global_age$value[global_age$year == 2016 & global_age$age == 1] == 357593,
  nrow(scenario_outputs) == 351L,
  all(sort(unique(scenario_outputs$year)) == 1986:2024),
  outputs$value[outputs$measure == "spawning_biomass" & outputs$scenario == "E2" & outputs$year == 2024] == 128040,
  nrow(cba) == 4L,
  cba$value[cba$scenario == "E2 short term; BR > 150,000 t"] == 40507,
  nrow(projected_f) == 4L,
  nrow(historical_cmp) == 21L,
  nrow(official_limit) == 1L,
  official_limit$value == 28700,
  all(is.na(outputs$se)),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  !any(grepl("_cv$", outputs$measure)),
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  selection$curation_status == "partial_source_import",
  unit$matched_stock_id == stock_id,
  unit$match_status == "matched",
  unit$import_status == "partial"
)

all_country_catch <- catch_biomass[catch_biomass$region == "All countries; total north of 41°S", ]
argentina_catch <- catch_biomass[catch_biomass$region == "Argentina; total north of 41°S", ]
brazil_catch <- catch_biomass[catch_biomass$region == "Brazil; northern-unit catch contribution", ]
uruguay_catch <- catch_biomass[catch_biomass$region == "Uruguay; northern-unit catch contribution", ]
argentina_2000 <- argentina_catch$value[argentina_catch$year == 2000]
brazil_2000 <- brazil_catch$value[brazil_catch$year == 2000]
uruguay_2000 <- uruguay_catch$value[uruguay_catch$year == 2000]
total_2000 <- all_country_catch$value[all_country_catch$year == 2000]
stopifnot(
  argentina_2000 == 19787,
  brazil_2000 == 2260,
  uruguay_2000 == 27197,
  total_2000 == 47210,
  argentina_2000 + brazil_2000 + uruguay_2000 - total_2000 == 2034
)

catch_check <- vapply(1986:2024, function(year) {
  n <- catch_age[catch_age$year == year, ]
  w <- commercial_weights[commercial_weights$year == year, ]
  total <- all_country_catch$value[all_country_catch$year == year]
  sum(n$value[order(n$age)] * w$value[order(w$age)]) / total
}, numeric(1))
stopifnot(max(abs(catch_check - 1)) < 0.002)

cat("INIDEP northern hake source import and coverage passed.\n")
