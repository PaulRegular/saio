root <- "."
assessment_id <- 'noaa_black_rockfish_oregon_2023'
stock_id <- 'noaa_black_rockfish_oregon'

read_selected <- function(path, selected) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep('NULL', length(fields))
  names(classes) <- fields
  classes[selected] <- 'character'
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c('', 'NA'), colClasses = classes)
}

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read_selected(file.path(root, 'database', 'inputs.csv'), c(
  'assessment_id', 'type', 'measure', 'basis', 'year', 'age', 'value', 'unit',
  'sampling_time', 'source_type', 'source_reference', 'sex', 'fleet', 'survey',
  'observation_id', 'length_bin_lower', 'length_bin_upper', 'sample_size',
  'age_error', 'partition'))
outputs <- read_selected(file.path(root, 'database', 'outputs.csv'), c(
  'assessment_id', 'type', 'measure', 'year', 'age', 'age_group', 'value',
  'unit', 'se', 'lwr', 'upr', 'source_type', 'source_reference', 'sex',
  'fleet', 'notes'))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate_row <- candidate[candidate$candidate_id == 'NOAA:14407', , drop = FALSE]
input <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
output <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
source_review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_black_rockfish_oregon_2023.md'), warn = FALSE), collapse = '\n')

catch <- input[input$type == 'catch' & input$measure == 'total_biomass', , drop = FALSE]
index <- input[input$type == 'index' & input$measure %in% c('total_biomass', 'total_numbers'), , drop = FALSE]
index_sd <- input[input$type == 'index' & input$measure == 'log_index_sd', , drop = FALSE]
length_comp <- input[input$measure == 'frequency_at_length', , drop = FALSE]
age_comp <- input[input$measure == 'frequency_at_age', , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == '14407',
  stock$scientific_name == 'Sebastes melanops',
  stock$area == 'Oregon',
  stock$ocean == 'Northeast Pacific',
  nrow(assessment) == 1L,
  assessment$assessment_year == 2023,
  assessment$terminal_year == 2022,
  assessment$estimate_terminal_year == 2034,
  assessment$inputs_status == 'partial',
  assessment$outputs_status == 'partial',
  candidate_row$import_status == 'partial',
  nrow(catch) == 524L,
  all(catch$unit == 'metric tonnes'),
  min(catch$year) == 1892,
  max(catch$year) == 2022,
  nrow(index) == 78L,
  nrow(index_sd) == 78L,
  length(unique(index$survey)) == 6L,
  length(unique(index$unit)) == 2L,
  all(index_sd$basis == 'log_scale'),
  all(index_sd$unit == 'log-scale standard error'),
  nrow(length_comp) == 179L * 28L,
  nrow(age_comp) == 1816L * 41L,
  all(!is.na(age_comp$sample_size)),
  all(!is.na(age_comp$age_error)),
  identical(is.na(age_comp$length_bin_lower), is.na(age_comp$length_bin_upper)),
  !any(input$measure %in% c('numbers_at_age', 'index_by_age_group')),
  any(input$measure == 'frequency_at_length' & input$type == 'index'),
  any(input$measure == 'frequency_at_age' & input$type == 'catch'),
  sum(output$measure == 'numbers_at_age') == 286L * 41L,
  sum(output$measure == 'biomass_at_age') == 286L * 41L,
  sum(output$measure == 'natural_mortality_at_age') == 286L * 41L,
  sum(output$measure == 'fishing_mortality_at_age') == 1144L * 41L,
  sum(output$measure == 'total_numbers') == 143L,
  sum(output$measure == 'spawning_output') == 143L,
  all(is.na(output$se[output$measure %in% c('numbers_at_age', 'biomass_at_age',
    'natural_mortality_at_age', 'fishing_mortality_at_age')])),
  all(output$unit[output$measure == 'numbers_at_age'] == 'thousand fish'),
  all(output$unit[output$measure == 'biomass_at_age'] == 'metric tonnes'),
  all(output$unit[output$measure == 'spawning_output'] == 'billion eggs'),
  all(output$unit[output$measure == 'total_numbers'] == 'thousand fish'),
  output$value[output$measure == 'spawning_output' & output$year == 2023] == 674.102,
  output$lwr[output$measure == 'spawning_output' & output$year == 2023] == 487,
  output$upr[output$measure == 'spawning_output' & output$year == 2023] == 861,
  output$source_type[output$measure == 'spawning_output' & output$year == 2023] == 'official_document',
  all(output$unit[output$measure == 'natural_mortality_at_age' & output$sex == 'female'] == 'per year'),
  all(abs(unique(as.numeric(output$value[output$measure == 'natural_mortality_at_age' & output$sex == 'female'])) - 0.19) < 1e-8),
  all(abs(unique(as.numeric(output$value[output$measure == 'natural_mortality_at_age' & output$sex == 'male'])) - 0.17) < 1e-8),
  grepl('billion eggs', source_review, fixed = TRUE),
  grepl('not age-specific abundance indices', source_review, fixed = TRUE)
)

cat('NOAA Oregon Black Rockfish 2023 source coverage, units, and provenance checks passed.\n')
