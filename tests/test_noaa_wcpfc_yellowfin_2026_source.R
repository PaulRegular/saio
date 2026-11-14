read_assessment_lines <- function(path, assessment_id, expected_rows) {
  con <- file(path, open = 'rb')
  on.exit(close(con), add = TRUE)
  prefix <- paste0('"', assessment_id, '",')
  size <- file.info(path)$size
  span <- min(size, 128 * 1024^2)
  repeat {
    offset <- max(0, size - span)
    seek(con, where = offset, origin = 'start')
    if (offset > 0) readLines(con, n = 1L, warn = FALSE)
    lines <- readLines(con, warn = FALSE)
    rows <- lines[startsWith(lines, prefix)]
    if (length(rows) >= expected_rows) break
    if (span >= size) stop('Could not locate all appended assessment rows.')
    span <- min(size, span * 2)
  }
  if (length(rows) != expected_rows) stop('Unexpected count of appended assessment rows.')
  rows
}

read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep('NULL', length(fields))
  names(classes) <- fields
  classes[columns] <- 'character'
  read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
    check.names = FALSE, colClasses = classes)
}

assessment_id <- 'wcpfc_wcpo_yellowfin_2026'
stock_id <- 'wcpfc_wcpo_yellowfin'
inputs <- read_assessment_lines('database/inputs.csv', assessment_id, 332125L)
outputs <- read_assessment_lines('database/outputs.csv', assessment_id, 146963L)
assumptions <- read_assessment_lines('database/assumptions.csv', assessment_id, 19L)
assessments <- read_columns('database/assessments.csv', c(
  'assessment_id', 'stock_id', 'assessment_year', 'terminal_year',
  'estimate_terminal_year', 'is_current', 'is_applied', 'model_family',
  'model_version', 'assumptions_status', 'inputs_status', 'outputs_status'))
stocks <- read_columns('database/stocks.csv', c(
  'stock_id', 'authority', 'authority_stock_id', 'scientific_name',
  'common_name', 'area', 'ocean'))
candidates <- read_columns('discovery/candidates.csv', c(
  'candidate_id', 'matched_stock_id', 'match_status', 'eligibility', 'import_status'))
inventory <- read_columns('discovery/inventory_units.csv', c(
  'unit_key', 'matched_stock_id', 'candidate_unit_id', 'match_status', 'import_status'))

assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == 'NOAA:11694', , drop = FALSE]
unit <- inventory[!is.na(inventory$candidate_unit_id) &
  inventory$candidate_unit_id == stock_id, , drop = FALSE]
input_count <- function(measure) sum(grepl(
  paste0('^"', assessment_id, '","[^"]*","', measure, '",'),
  inputs, perl = TRUE))
output_count <- function(measure) sum(grepl(
  paste0('^"', assessment_id, '","[^"]*","', measure, '",'),
  outputs, perl = TRUE))

missing_cpue <- outputs[grepl(
  '^"wcpfc_wcpo_yellowfin_2026","index","predicted_index",,"36.LL.IDX.5",,"MFCL area 5","model quarter [1-4]",195[23],{7}"relative CPUE index"',
  outputs, perl = TRUE)]
stopifnot(
  nrow(stock) == 1L,
  stock$authority == 'WCPFC / SPC',
  stock$scientific_name == 'Thunnus albacares',
  stock$ocean == 'Western and Central Pacific',
  nrow(assessment) == 1L,
  assessment$assessment_year == '2026',
  assessment$terminal_year == '2024',
  assessment$estimate_terminal_year == '2024',
  assessment$is_current == 'TRUE',
  assessment$is_applied == 'FALSE',
  assessment$model_family == 'MULTIFAN-CL',
  assessment$model_version == 'Diagnostic2026 (MFCL Model 16)',
  assessment$assumptions_status == 'partial',
  assessment$inputs_status == 'partial',
  assessment$outputs_status == 'partial',
  length(assumptions) == 19L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == 'matched',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'partial',
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$match_status == 'matched',
  unit$import_status == 'partial',
  input_count('catch_numbers') + input_count('catch_biomass') == 6773L,
  input_count('relative_abundance_index') == 1452L,
  input_count('frequency_at_length') == 297920L,
  input_count('conditional_frequency_at_age') == 1631L,
  input_count('observation_likelihood_weight') == 1229L,
  input_count('regional_scaling_value') == 1420L,
  input_count('tag_release_frequency_at_length') == 13585L,
  input_count('tag_recapture_count') == 6331L,
  all(grepl(',"native_model",', inputs, fixed = TRUE)),
  all(grepl('^"wcpfc_wcpo_yellowfin_2026","covariate","regional_scaling_value","native_covariate",',
    inputs[grepl('"regional_scaling_value",', inputs, fixed = TRUE)], perl = TRUE)),
  output_count('numbers_at_age') == 58400L,
  output_count('fishing_mortality_at_age') == 17520L,
  output_count('mature_biomass_at_age') == 58400L,
  output_count('natural_mortality_at_age') == 40L,
  output_count('predicted_index') == 1460L,
  length(missing_cpue) == 8L,
  output_count('predicted_catch') == 9125L,
  output_count('spawning_potential_biomass') == 1533L,
  all(grepl(',"native_model",', outputs, fixed = TRUE)),
  file.exists('discovery/source_reviews/noaa_wcpfc_yellowfin_2026.md')
)

cat('WCPFC 2026 WCPO yellowfin source import checks passed.\n')
