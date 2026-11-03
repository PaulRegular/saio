root <- "."
stock_id <- 'dfo_sgsl_winter_flounder_4t'
full_id <- 'dfo_sgsl_winter_flounder_2017'
update_id <- 'dfo_sgsl_winter_flounder_2024_indicators'

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidates <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
full <- assessments[assessments$assessment_id == full_id, , drop = FALSE]
update <- assessments[assessments$assessment_id == update_id, , drop = FALSE]
x <- inputs[inputs$assessment_id == full_id, , drop = FALSE]
y <- outputs[outputs$assessment_id == full_id, , drop = FALSE]
z <- outputs[outputs$assessment_id == update_id, , drop = FALSE]
candidate <- candidates[!is.na(candidates$candidate_unit_id) &
  candidates$candidate_unit_id == stock_id, , drop = FALSE]
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == stock_id, , drop = FALSE]

catch_numbers <- x[x$type == 'catch' & x$measure == 'numbers_at_age', , drop = FALSE]
catch_composition <- x[x$type == 'catch' & x$measure == 'proportion_at_age', , drop = FALSE]
survey_numbers <- x[x$type == 'index' & x$measure == 'numbers_at_age', , drop = FALSE]
survey_composition <- x[x$type == 'index' & x$measure == 'proportion_at_age', , drop = FALSE]
survey_biomass <- x[x$type == 'index' & x$measure == 'total_biomass', , drop = FALSE]
landings <- x[x$type == 'catch' & x$measure == 'landings_biomass', , drop = FALSE]
maturity <- x[x$type == 'maturity' & x$measure == 'maturity_at_age', , drop = FALSE]
weight <- x[x$type == 'weight' & x$measure == 'weight_at_age', , drop = FALSE]

sum_by_year <- function(data) tapply(data$value, data$year, sum)
catch_sums <- sum_by_year(catch_composition)
survey_sums <- sum_by_year(survey_composition)
source_cache <- file.path(root, 'source_cache', 'discovery_dfo_4t_winter_flounder_2019')
manifest <- read.csv(file.path(source_cache, 'sources.csv'), stringsAsFactors = FALSE)
source_paths <- file.path(source_cache, manifest$file)

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == 'Pseudopleuronectes americanus',
  stock$ocean == 'Northwest Atlantic',
  nrow(full) == 1L,
  full$is_current,
  full$terminal_year == 2016L,
  full$inputs_status == 'partial',
  full$outputs_status == 'partial',
  nrow(update) == 1L,
  !update$is_current,
  update$is_applied,
  identical(sort(unique(catch_numbers$year)), 1973:2016),
  identical(sort(unique(survey_numbers$year)), 1973:2016),
  identical(sort(unique(as.integer(catch_numbers$age))), 2:12),
  identical(sort(unique(as.integer(survey_numbers$age))), 2:12),
  nrow(catch_numbers) == 44L * 11L,
  nrow(catch_composition) == 44L * 11L,
  nrow(survey_numbers) == 44L * 11L,
  nrow(survey_composition) == 44L * 11L,
  catch_numbers$value[catch_numbers$year == 1973 & catch_numbers$age == 4] == 72,
  catch_numbers$value[catch_numbers$year == 2016 & catch_numbers$age == 12] == 4,
  survey_numbers$value[survey_numbers$year == 1973 & survey_numbers$age == 2] == 387,
  survey_numbers$value[survey_numbers$year == 2016 & survey_numbers$age == 12] == 14,
  all(abs(catch_sums - 1) < 1e-10),
  all(abs(survey_sums - 1) < 1e-10),
  all(catch_numbers$unit == 'thousand fish'),
  all(survey_numbers$unit == 'thousand fish'),
  all(catch_composition$source_type == 'reconstructed_source_input'),
  all(survey_composition$source_type == 'reconstructed_source_input'),
  any(catch_composition$value == 0),
  nrow(landings) == 44L,
  identical(sort(landings$year), 1973:2016),
  landings$value[landings$year == 1984] == 149,
  landings$value[landings$year == 2016] == 191.9,
  nrow(survey_biomass) == 44L,
  identical(sort(survey_biomass$year), 1973:2016),
  all(survey_biomass$source_type == 'digitized'),
  all(survey_biomass$unit == 'kg/tow'),
  all(survey_biomass$sampling_time == 0.71),
  abs(mean(survey_biomass$value[survey_biomass$year %in% 1974:1983]) - 17.4) < 1,
  abs(survey_biomass$value[survey_biomass$year == 2016] - 1.1) < 0.1,
  nrow(weight) == 44L * 11L,
  weight$value[weight$year == 1973 & weight$age == 2] == 0.046,
  weight$value[weight$year == 2016 & weight$age == 12] == 0.446,
  all(weight$survey == 'September RV survey'),
  all(weight$unit == 'kg/fish'),
  !any(x$type == 'catch_weight' & x$measure == 'catch_weight_at_age'),
  nrow(maturity) == 44L * 11L,
  maturity$value[maturity$year == 1973 & maturity$age == 2] == 0.054,
  maturity$value[maturity$year == 2016 & maturity$age == 2] == 0.251,
  all(maturity$value >= 0 & maturity$value <= 1),
  all(maturity$unit == 'proportion'),
  y$value[y$measure == 'SSB' & y$year == 2016] == 76270,
  y$value[y$measure == 'total_abundance' & y$year == 2016] == 3.05,
  all(y$unit[y$measure %in% c('total_abundance', 'recruitment')] == 'billion fish'),
  identical(sort(y$age[y$measure == 'recruitment']), c(2L, 3L)),
  all(y$se[!is.na(y$se)] >= 0),
  all(is.na(y$se) & is.na(y$lwr) & is.na(y$upr)),
  !any(y$measure %in% c('numbers_at_age', 'fishing_mortality_at_age',
    'natural_mortality_at_age')),
  z$value[z$measure == 'relative_biomass_index' & z$year == 2024] == 1.38,
  z$value[z$measure == 'LRP'] == 3.82,
  z$value[z$measure == 'USR'] == 7.64,
  candidate$import_status == 'partial',
  unit$import_status == 'partial',
  nrow(manifest) == 2L,
  all(file.exists(source_paths)),
  all(file.info(source_paths)$size == manifest$bytes),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  file.exists(file.path(root, 'scripts', 'database',
    '544_import_dfo_sgsl_winter_flounder_4t_2017.R')),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'dfo_sgsl_winter_flounder_4t_2017.md'))
)

cat('DFO NAFO 4T winter flounder source checks passed.\n')
