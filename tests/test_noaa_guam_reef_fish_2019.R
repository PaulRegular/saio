root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen_review <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/494_screen_noaa_guam_reef_fish_2019.R'),
  local = screen_review)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

ids <- paste0('NOAA:', c('15110', '15113', '15114', '15130', '15131', '15132',
  '15133', '15134', '15135', '15136', '15137', '15138'))
unit_ids <- paste0('noaa_guam_reef_', sub('^NOAA:', '', ids))
screened <- candidates[match(ids, candidates$candidate_id), , drop = FALSE]
units_screened <- units[match(unit_ids, units$candidate_unit_id), , drop = FALSE]
source_review <- file.path(root, 'discovery/source_reviews/noaa_guam_reef_fish_2019.md')

stopifnot(nrow(screened) == length(ids),
  identical(screened$candidate_unit_id, unit_ids),
  all(screened$organization == 'NOAA'),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'),
  all(is.na(screened$matched_stock_id)),
  all(vapply(screened[c('catch_age_evidence', 'survey_age_evidence',
    'weights_evidence', 'maturity_evidence', 'mortality_evidence',
    'timing_evidence', 'output_evidence', 'detailed_source_url',
    'decision_reason', 'notes')], function(x) all(!is.na(x) & nzchar(x)), logical(1L))),
  all(units_screened$inventory_entries == 1L),
  !any(screened$official_stock_id %in% stocks$authority_stock_id),
  !any(unit_ids %in% assessments$stock_id),
  !any(unit_ids %in% inputs$assessment_id),
  !any(unit_ids %in% outputs$assessment_id),
  all(c('NOAA:15113', 'NOAA:15114', 'NOAA:15133') %in% ids),
  all(grepl('growth-type-group length-based', screened$decision_reason, fixed = TRUE)),
  all(grepl('N-, F-, or M-at-age', screened$output_evidence, fixed = TRUE)),
  file.exists(source_review),
  file.exists(file.path(root, 'source_cache/discovery_noaa_guam_reef_fish_2026/sources.csv')),
  all(vapply(ids, function(id) grepl(sub('^NOAA:', '', id),
    paste(readLines(source_review, warn = FALSE), collapse = ' '), fixed = TRUE), logical(1L))))

cat('NOAA Guam reef-fish identity, source, eligibility, and no-import checks passed.\n')
