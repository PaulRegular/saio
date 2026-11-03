root <- '.'
candidate_id <- 'ICES:ldb.27.8c9a'
unit_id <- 'ices_four_spot_megrim_8c9a'
cache <- file.path(root, 'source_cache', 'discovery_ices_four_spot_megrim_8c9a_2026')

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_four_spot_megrim_8c9a_2026.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$official_stock_id == 'ldb.27.8c9a',
  candidate$scientific_name == 'Lepidorhombus boscii',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  grepl('ages 0–6+', candidate$catch_age_evidence, fixed = TRUE),
  grepl('G2784', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.05, 0.32, 0.83, 0.98', candidate$maturity_evidence, fixed = TRUE),
  grepl('M = 0.2', candidate$mortality_evidence, fixed = TRUE),
  grepl('F for ages 2–4', candidate$output_evidence, fixed = TRUE),
  grepl('2026 row is a projection', candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$eligibility == 'eligible',
  unit$screening_status == 'screened',
  nrow(manifest) == 3L,
  all(file.exists(file.path(cache, manifest$file))),
  grepl('run-matched numerical catch and survey matrices', review, fixed = TRUE),
  grepl('survey summary lists ages', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'ldb.27.8c9a', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('ICES four-spot megrim identity, age-specific assessment evidence, provenance, and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '398_screen_ices_four_spot_megrim_8c9a_2026.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
