root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen_review <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/493_screen_ices_ray_method_group_2026.R'),
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

ids <- c('ICES:sho.27.89a', 'ICES:rjc.27.3a47d', 'ICES:rjh.27.4bc7d',
  'ICES:rjn.27.3a4', 'ICES:rjn.27.678abd', 'ICES:rjm.27.7ae-h',
  'ICES:rjc.27.7afg', 'ICES:syt.27.67')
unit_ids <- c('ices_sho_27_89a', 'ices_rjc_27_3a47d', 'ices_rjh_27_4bc7d',
  'ices_rjn_27_3a4', 'ices_rjn_27_678abd', 'ices_rjm_27_7ae_h',
  'ices_rjc_27_7afg', 'ices_syt_27_67')
screened <- candidates[match(ids, candidates$candidate_id), , drop = FALSE]
units_screened <- units[match(unit_ids, units$candidate_unit_id), , drop = FALSE]
source_review <- file.path(root, 'discovery/source_reviews/ices_ray_method_group_2026.md')

stopifnot(nrow(screened) == length(ids),
  identical(screened$candidate_unit_id, unit_ids),
  all(screened$organization == 'ICES'),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'),
  all(is.na(screened$matched_stock_id)),
  all(vapply(screened[c('catch_age_evidence', 'survey_age_evidence',
    'weights_evidence', 'maturity_evidence', 'mortality_evidence',
    'timing_evidence', 'output_evidence', 'detailed_source_url',
    'decision_reason', 'notes')], function(x) all(!is.na(x) & nzchar(x)),
    logical(1L))),
  all(units_screened$inventory_entries == 1L),
  !any(screened$official_stock_id %in% stocks$authority_stock_id),
  !any(unit_ids %in% assessments$stock_id),
  !any(unit_ids %in% inputs$assessment_id),
  !any(unit_ids %in% outputs$assessment_id),
  file.exists(source_review),
  file.exists(file.path(root, 'source_cache/discovery_ices_ray_method_group_2026/sources.csv')),
  all(vapply(ids, function(id) grepl(sub('^ICES:', '', id),
    paste(readLines(source_review, warn = FALSE), collapse = ' '), fixed = TRUE),
    logical(1L))))

cat('ICES ray and dogfish identity, source, eligibility, and no-import checks passed.\n')
