root <- '.'
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

codes <- c('ICES:rju.27.9a', 'ICES:rju.27.8ab', 'ICES:rju.27.8c',
  'ICES:rjm.27.8', 'ICES:rjm.27.9a', 'ICES:rjh.27.9a', 'ICES:rjn.27.9a',
  'ICES:rjc.27.8abd', 'ICES:rjc.27.8c', 'ICES:rjc.27.9a')
expected_units <- c('ices_undulate_ray_9a', 'ices_undulate_ray_8ab',
  'ices_undulate_ray_8c', 'ices_spotted_ray_8', 'ices_spotted_ray_9a',
  'ices_blonde_ray_9a', 'ices_cuckoo_ray_9a', 'ices_thornback_ray_8abd',
  'ices_thornback_ray_8c', 'ices_thornback_ray_9a')
rows <- match(codes, register$candidate_id)
stopifnot(!anyNA(rows), !anyDuplicated(rows))
screened <- register[rows, , drop = FALSE]
stopifnot(
  identical(as.character(screened$candidate_unit_id), expected_units),
  identical(as.character(screened$detailed_source_url), c(
    'https://asd.ices.dk/viewAdvice/3771',
    'https://asd.ices.dk/viewAdvice/3782',
    'https://asd.ices.dk/viewAdvice/3783',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25871',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25904',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25848',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25865',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25854',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25835',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25858')),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'),
  identical(as.character(screened$output_evidence), c(
    'The official record provides No stock-size output and Catch advice only; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides No stock-size output and Catch advice only; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides No stock-size output and Catch advice only; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Aggregate biomass index and Length-based fishing-pressure proxy; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Landings only and No fishing-pressure series reported; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Aggregate biomass index and Length-based fishing-pressure proxy; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Relative exploitable-biomass indicator and Relative fishing-pressure indicator; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Relative biomass and Fishing pressure relative to FMSY; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Relative biomass and Fishing pressure relative to FMSY; it does not publish N-at-age, F-at-age, or M-at-age surfaces.',
    'The official record provides Relative biomass and Fishing pressure relative to FMSY; it does not publish N-at-age, F-at-age, or M-at-age surfaces.')),
  all(!expected_units %in% stocks$stock_id),
  all(!expected_units %in% assessments$assessment_id),
  all(!expected_units %in% inputs$assessment_id),
  all(!expected_units %in% outputs$assessment_id)
)

cache <- file.path(root, 'source_cache', 'discovery_ices_bay_biscay_elasmobranchs_2026')
manifest_path <- file.path(cache, 'sources.csv')
review_path <- file.path(root, 'discovery', 'source_reviews',
  'ices_bay_biscay_elasmobranchs_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('does not establish that no biological age samples exist', review, fixed = TRUE),
  grepl('F-at-age and F-at-length fields are blank', review, fixed = TRUE),
  grepl('rjm.27.8', review, fixed = TRUE),
  grepl('rjc.27.9a', review, fixed = TRUE)
)

if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  cached <- file.path(cache, manifest$file)
  stopifnot(
    nrow(manifest) == 10L,
    all(file.exists(cached)),
    all(file.info(cached)$size == manifest$bytes),
    all(manifest$retrieved_on == '2026-10-30'),
    all(nchar(manifest$sha256) == 64L)
  )
}

cat('ICES Bay of Biscay elasmobranch identity, published-output, and no-import checks passed.\n')
