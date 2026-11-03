root <- "."
source(file.path(root, 'scripts/database/548_import_ices_ling_faroe_5b_2026.R'),
  local = new.env(parent = globalenv()))

database <- file.path(root, 'database')
stocks <- read.csv(file.path(database, 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(database, 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(database, 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(database, 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assumptions <- read.csv(file.path(database, 'assumptions.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
selected <- read.csv(file.path(root, 'discovery/selected_batch_01_2026.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inventory <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
source_review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_ling_faroe_5b_2026.md'), warn = FALSE), collapse = '\n')

stock_id <- 'ices_ling_faroe_5b'
assessment_id <- 'ices_ling_faroe_5b_2026'
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
x <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
y <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
a <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidate[candidate$candidate_id == 'ICES:lin.27.5b', , drop = FALSE]
selected <- selected[selected$candidate_unit_id == stock_id, , drop = FALSE]
inventory <- inventory[inventory$unit_key == paste0('candidate:', stock_id), , drop = FALSE]

input <- function(type, measure = NULL) {
  z <- x[x$type == type, , drop = FALSE]
  if (!is.null(measure)) z <- z[z$measure == measure, , drop = FALSE]
  z
}
output <- function(measure) y[y$measure == measure, , drop = FALSE]
cell <- function(z, year, age, measure = NULL) {
  if (!is.null(measure)) z <- z[z$measure == measure, , drop = FALSE]
  z$value[z$year == year & z$age == age]
}

catch <- input('catch', 'numbers_at_age')
weight <- input('weight', 'weight_at_age')
spring <- input('index', 'relative_abundance_index')
spring_survey <- 'Faroe Plateau spring groundfish survey (G1264)'
summer_survey <- 'Faroe Plateau summer groundfish survey (G3284)'
spring <- spring[spring$survey == spring_survey, , drop = FALSE]
summer <- input('index', 'relative_abundance_index')
summer <- summer[summer$survey == summer_survey, , drop = FALSE]
effort <- input('covariate', 'effort')
maturity <- input('maturity', 'maturity_at_age')
natural_mortality <- input('M', 'natural_mortality_at_age')
recruitment <- output('recruitment')
ssb <- output('SSB')
fbar <- output('Fbar')
total_biomass <- output('total_biomass')
n_at_age <- output('numbers_at_age')
f_at_age <- output('fishing_mortality_at_age')

stopifnot(
  nrow(stock) == 1L, stock$authority_stock_id == 'lin.27.5b',
  stock$scientific_name == 'Molva molva', stock$ocean == 'Northeast Atlantic',
  nrow(assessment) == 1L, assessment$is_current, assessment$is_applied,
  assessment$assessment_year == 2026L, assessment$terminal_year == 2025L,
  assessment$model_version == 'lin.27.5b_wgdeep2026_final',
  all(c(assessment$inputs_status, assessment$outputs_status,
    assessment$assumptions_status) == 'partial'),
  nrow(x) == 1172L, nrow(a) == 13L, nrow(y) == 720L,
  nrow(catch) == 300L, nrow(weight) == 300L,
  nrow(spring) == 224L, nrow(summer) == 270L,
  sum(effort$survey == spring_survey) == 28L,
  sum(effort$survey == summer_survey) == 30L,
  nrow(maturity) == 10L, nrow(natural_mortality) == 10L,
  identical(sort(unique(catch$year)), 1996:2025),
  identical(sort(unique(as.integer(catch$age))), 3:12),
  identical(sort(unique(spring$year)), 1998:2025),
  identical(sort(unique(as.integer(spring$age))), 4:11),
  identical(sort(unique(summer$year)), 1996:2025),
  identical(sort(unique(as.integer(summer$age))), 3:11),
  all(catch$unit == 'thousand fish'),
  all(weight$unit == 'kg per fish'),
  all(weight$basis == 'kg_per_fish'),
  all(grepl('source-based consistency inference', weight$transformation, fixed = TRUE)),
  all(spring$unit == 'Source table index; unit and scale not specified'),
  all(summer$unit == 'Source table index; unit and scale not specified'),
  all(is.na(spring$sampling_time)), all(is.na(summer$sampling_time)),
  all(grepl('no scale adjustment', c(spring$transformation, summer$transformation),
    fixed = TRUE)),
  all(effort$unit == 'Reported effort; unit and definition not specified'),
  all(maturity$value %in% c(0, 0.04, 0.19, 0.5, 0.79, 0.93, 0.98, 1)),
  all(natural_mortality$value == 0.15),
  identical(sort(unique(recruitment$year)), 1996:2025),
  identical(sort(unique(ssb$year)), 1996:2025),
  identical(sort(unique(fbar$year)), 1996:2025),
  identical(sort(unique(as.integer(n_at_age$age))), 3:12),
  identical(sort(unique(as.integer(f_at_age$age))), 3:12),
  all(recruitment$unit == 'thousand fish'), all(n_at_age$unit == 'thousand fish'),
  all(ssb$unit == 'tonnes'), all(total_biomass$unit == 'tonnes'),
  all(fbar$unit == 'per year'), all(f_at_age$unit == 'per year'),
  all(recruitment$lwr <= recruitment$value & recruitment$value <= recruitment$upr),
  all(ssb$lwr <= ssb$value & ssb$value <= ssb$upr),
  all(fbar$lwr <= fbar$value & fbar$value <= fbar$upr),
  all(total_biomass$lwr <= total_biomass$value & total_biomass$value <= total_biomass$upr),
  all(is.na(n_at_age$lwr)), all(is.na(f_at_age$lwr)),
  all(f_at_age$age_group[f_at_age$age == 12L] == '12+'),
  all(n_at_age$age_group[n_at_age$age == 12L] == '12+'),
  abs(cell(catch, 1996, 3) - 4.61) < 1e-12,
  abs(cell(weight, 1996, 3) - 0.437) < 1e-12,
  abs(cell(spring, 1998, 4) - 9.89) < 1e-12,
  abs(cell(summer, 1996, 3) - 11.38) < 1e-12,
  identical(candidate$import_status, 'partial'),
  nrow(selected) == 1L, selected$curation_status == 'partial_source_import',
  nrow(inventory) == 1L, inventory$import_status == 'partial',
  grepl('kg per fish', source_review, fixed = TRUE),
  grepl('Gear-change downweighting', source_review, fixed = TRUE),
  grepl('1,172 inputs', source_review, fixed = TRUE)
)

years <- 1996:2025
for (year in years) {
  numbers <- n_at_age$value[n_at_age$year == year]
  weights <- weight$value[weight$year == year]
  maturity_at_age <- maturity$value[match(weight$age[weight$year == year], maturity$age)]
  stopifnot(length(numbers) == 10L, length(weights) == 10L,
    abs(sum(numbers * weights * maturity_at_age) - ssb$value[ssb$year == year]) /
      ssb$value[ssb$year == year] < 0.001,
    abs(sum(numbers * weights) - total_biomass$value[total_biomass$year == year]) /
      total_biomass$value[total_biomass$year == year] < 0.001,
    cell(n_at_age, year, 3L) == recruitment$value[recruitment$year == year],
    abs(mean(f_at_age$value[f_at_age$year == year & f_at_age$age %in% 6:10]) -
      fbar$value[fbar$year == year]) < 0.001)
}

cat('ICES 2026 Faroes ling source import, year-age coverage, units, and output consistency passed.\n')
