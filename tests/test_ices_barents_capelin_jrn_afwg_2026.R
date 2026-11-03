root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/472_screen_ices_barents_capelin_jrn_afwg_2026.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:cap.27.1-2', , drop = FALSE]
review_path <- file.path(root,
  'discovery/source_reviews/ices_barents_capelin_jrn_afwg_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
review <- gsub('[[:space:]]+', ' ', review)
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'jrn_afwg_barents_capelin',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('million tonnes', candidate$catch_age_evidence, fixed = TRUE),
  grepl('Table 10.4', candidate$survey_age_evidence, fixed = TRUE),
  grepl('not a direct maturity-at-age matrix', candidate$maturity_evidence, fixed = TRUE),
  grepl('JRN-AFWG', candidate$decision_reason, fixed = TRUE),
  grepl('outside ICES', candidate$decision_reason, fixed = TRUE),
  grepl('eligibility unresolved', review, fixed = TRUE),
  grepl('through 2019', review, fixed = TRUE),
  grepl('age 5 and older', review, fixed = TRUE),
  nrow(units[units$unit_key == 'candidate:jrn_afwg_barents_capelin', , drop = FALSE]) == 1L,
  !any(stocks$stock_id == 'jrn_afwg_barents_capelin'),
  !any(assessments$stock_id == 'jrn_afwg_barents_capelin'),
  !any(inputs$assessment_id == 'jrn_afwg_barents_capelin'),
  !any(outputs$assessment_id == 'jrn_afwg_barents_capelin')
)

cat('ICES Barents capelin authority, source coverage, unresolved eligibility, provenance, and no-import checks passed.\n')
