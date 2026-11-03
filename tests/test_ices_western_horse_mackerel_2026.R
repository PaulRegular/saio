root <- "."
candidate_id <- 'ICES:hom.27.2a3a4a5b6a7a-ce-k8'
unit_id <- 'ices_western_horse_mackerel_ne_atlantic'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_western_horse_mackerel_2026.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  candidate$scientific_name == 'Trachurus trachurus',
  grepl('1982-2024, ages 0-15', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-0 recruitment index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('not current-run outputs', candidate$output_evidence, fixed = TRUE),
  grepl('25892', candidate$detailed_source_url, fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$organizations == 'ICES',
  unit$eligibility == 'unresolved',
  !any(stocks$authority_stock_id == candidate_id, na.rm = TRUE),
  !any(stocks$stock_id == unit_id, na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('2026 assessment', review, fixed = TRUE),
  grepl('WGWIDE 2025 report', review, fixed = TRUE),
  grepl('not treated as current-run inputs', review, fixed = TRUE),
  grepl('Tables 7.7.3.1 and 7.7.3.2', review, fixed = TRUE),
  grepl('Division 3.a', review, fixed = TRUE),
  sum(progress$new[progress$organization == 'ICES']) == 90L,
  sum(progress$screening_complete[progress$organization == 'ICES']) == 157L,
  sum(progress$screening_not_started[progress$organization == 'ICES']) == 123L,
  sum(progress$eligibility_unresolved[progress$organization == 'ICES']) == 144L
)

cat('ICES western horse mackerel inventory screen checks passed.\n')
