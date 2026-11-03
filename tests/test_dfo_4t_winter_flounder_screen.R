root <- "."
candidates <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidates[candidates$candidate_id ==
  'DFO:Gulf:Winter Flounder - NAFO 4T', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == 'candidate:dfo_sgsl_winter_flounder_4t', , drop = FALSE]
selected <- read.csv(file.path(root, 'discovery', 'selected_batch_01_2026.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
selected <- selected[selected$candidate_unit_id == 'dfo_sgsl_winter_flounder_4t', , drop = FALSE]
cache <- file.path(root, 'source_cache', 'discovery_dfo_4t_winter_flounder_2019')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'dfo_sgsl_winter_flounder_4t',
  candidate$scientific_name == 'Pseudopleuronectes americanus',
  candidate$assessment_area == 'NAFO Division 4T, southern Gulf of St. Lawrence',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'partial',
  grepl('ages 2-12+', candidate$catch_age_evidence, fixed = TRUE),
  grepl('numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('ages 2-12+', candidate$survey_age_evidence, fixed = TRUE),
  grepl('kg/fish', candidate$weights_evidence, fixed = TRUE),
  grepl('mature proportions-at-age', candidate$maturity_evidence, fixed = TRUE),
  grepl('five-year', candidate$mortality_evidence, fixed = TRUE),
  grepl('0.71', candidate$timing_evidence, fixed = TRUE),
  grepl('age-2/age-3 recruitment', candidate$output_evidence, fixed = TRUE),
  grepl('no later full assessment', candidate$notes, ignore.case = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'eligible',
  nrow(selected) == 1L,
  selected$curation_status == 'partial_source_import',
  nrow(sources) == 2L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(grepl('^[[:xdigit:]]{64}$', sources$sha256)),
  all(sources$retrieved_utc == '2026-10-30'),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'dfo_sgsl_winter_flounder_4t_2017.md')),
  file.exists(file.path(root, 'scripts', 'database',
    '341_screen_dfo_4t_winter_flounder_2017.R')),
  any(stocks$stock_id == 'dfo_sgsl_winter_flounder_4t'),
  any(assessments$assessment_id == 'dfo_sgsl_winter_flounder_2017'),
  any(assessments$assessment_id == 'dfo_sgsl_winter_flounder_2024_indicators'),
  any(inputs$assessment_id == 'dfo_sgsl_winter_flounder_2017'),
  any(outputs$assessment_id == 'dfo_sgsl_winter_flounder_2017'),
  unit$import_status == 'partial'
)
cat('DFO NAFO 4T winter flounder candidate and import checks passed.\n')
