root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/495_screen_ices_unstarted_non_age_methods_2026.R'),
  local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

codes <- c(
  'raj.27.3a47d', 'rjb.27.3a4', 'rjh.27.4a6', 'rjr.27.23a4', 'dab.27.3a4',
  'bsf.27.nea', 'gag.27.nea', 'jaa.27.10a2', 'usk.27.1-2', 'usk.27.12ac',
  'usk.27.3a45b6a7-912b', 'usk.27.6b', 'ory.27.nea', 'rng.27.5b6712b',
  'raj.27.1012', 'sbr.27.10', 'sck.27.nea', 'ele.2737.nea', 'bsk.27.nea',
  'tsu.27.nea', 'reb.27.14b', 'rjf.27.67', 'rjh.27.7afg', 'rjb.27.67a-ce-k',
  'cyo.27.nea', 'guq.27.nea', 'rng.27.1245a8914ab', 'mur.27.3a47d',
  'ldb.27.7b-k8abd', 'pil.27.7', 'lin.27.346-91214', 'raj.27.67a-ce-k',
  'bli.27.123a4')
candidate_ids <- paste0('ICES:', codes)
unit_ids <- paste0('ices_', gsub('[^a-z0-9]+', '_', tolower(codes)))
candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
screened <- candidates[match(candidate_ids, candidates$candidate_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review_path <- file.path(root, 'discovery/source_reviews/ices_non_age_method_group_2026.md')
cache_path <- file.path(root, 'source_cache/discovery_ices_unstarted_age_audit_2026/sources.csv')
manifest <- read.csv(cache_path, stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')

stopifnot(nrow(screened) == length(codes),
  identical(screened$candidate_unit_id, unit_ids),
  all(screened$organization == 'ICES'), all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'), all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'), all(is.na(screened$matched_stock_id)),
  all(vapply(screened[c('catch_age_evidence', 'survey_age_evidence',
    'weights_evidence', 'maturity_evidence', 'mortality_evidence', 'timing_evidence',
    'output_evidence', 'detailed_source_url', 'decision_reason', 'notes')],
    function(x) all(!is.na(x) & nzchar(x)), logical(1L))),
  length(unique(manifest$official_stock_id)) == length(codes),
  !any(screened$official_stock_id %in% stocks$authority_stock_id),
  !any(unit_ids %in% assessments$stock_id), !any(unit_ids %in% inputs$assessment_id),
  !any(unit_ids %in% outputs$assessment_id),
  grepl('2020', screened$decision_reason[screened$official_stock_id == 'rjb.27.67a-ce-k'],
    fixed = TRUE),
  grepl('No new canonical assessment records', review, fixed = TRUE),
  file.exists(review_path))

cat('ICES unstarted non-age-method identity, source, eligibility, and no-import checks passed.\n')
