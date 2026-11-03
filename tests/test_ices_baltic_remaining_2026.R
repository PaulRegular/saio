root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

ids <- c('ICES:sal.27.22-31', 'ICES:sal.27.32', 'ICES:trs.27.22-32',
  'ICES:dab.27.22-32', 'ICES:bll.27.22-32')
units_expected <- c('ices_salmon_main_basin_22_31', 'ices_salmon_gulf_finland_32',
  'ices_sea_trout_baltic_22_32', 'ices_dab_baltic_22_32', 'ices_brill_baltic_22_32')
rows <- match(ids, register$candidate_id)
stopifnot(!anyNA(rows), !anyDuplicated(rows))
screened <- register[rows, , drop = FALSE]
stopifnot(
  identical(as.character(screened$candidate_unit_id), units_expected),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  identical(as.character(screened$eligibility),
    c('unresolved', 'unresolved', 'ineligible', 'ineligible', 'ineligible')),
  all(screened$import_status == 'not_started'),
  all(screened$review_date == '2026-10-30'),
  grepl('age-read scales', screened$catch_age_evidence[1], fixed = TRUE),
  grepl('age-read catch samples', screened$catch_age_evidence[2], fixed = TRUE),
  grepl('expert elicitation', screened$decision_reason[2], fixed = TRUE),
  grepl('SPiCT', screened$decision_reason[4], fixed = TRUE),
  grepl('not an age-specific', screened$survey_age_evidence[5], fixed = TRUE),
  identical(as.character(screened$detailed_source_url[1:3]),
    rep('https://doi.org/10.17895/ices.pub.29118545', 3)),
  identical(as.character(screened$detailed_source_url[4:5]),
    rep('https://doi.org/10.17895/ices.pub.32455056', 2)),
  all(!units_expected %in% stocks$stock_id),
  all(!units_expected %in% assessments$assessment_id),
  all(!units_expected %in% inputs$assessment_id),
  all(!units_expected %in% outputs$assessment_id)
)

cache <- file.path(root, 'source_cache', 'discovery_ices_baltic_current_reports_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
cached <- file.path(cache, manifest$file)
stopifnot(
  nrow(manifest) == 3L,
  identical(sort(manifest$file), sort(c('WGBFAS_2026.pdf', 'WGBAST_2025.pdf', 'WGBAST_2026.pdf'))),
  all(file.exists(cached)),
  all(file.info(cached)$size == manifest$bytes),
  all(manifest$retrieved_on == '2026-10-30'),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(startsWith(vapply(cached, function(path) rawToChar(readBin(path, 'raw', n = 5L)),
    character(1L)), '%PDF-'))
)

review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_baltic_flatfish_2026.md'), warn = FALSE), collapse = ' ')
stopifnot(
  grepl('update assessments were conducted', review, fixed = TRUE),
  grepl('age-read catch samples', review, fixed = TRUE),
  grepl('does not establish that biological age samples do not exist', review, fixed = TRUE),
  grepl('WGBFAS_2026.pdf', review, fixed = TRUE),
  grepl('WGBAST_2025.pdf', review, fixed = TRUE)
)

cat('ICES Baltic current assessment identity, evidence, eligibility, cache, and no-import checks passed.\n')
