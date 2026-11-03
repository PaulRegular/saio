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

codes <- c('ICES:tur.27.22-32', 'ICES:bwp.27.2729-32', 'ICES:bzq.27.2425',
  'ICES:bzq.27.2628', 'ICES:fle.27.21-23')
expected_units <- c('ices_turbot_baltic_22_32', 'ices_baltic_flounder_2729_32',
  'ices_flounder_baltic_2425', 'ices_flounder_baltic_2628',
  'ices_flounder_baltic_21_23')
rows <- match(codes, register$candidate_id)
stopifnot(!anyNA(rows), !anyDuplicated(rows))
screened <- register[rows, , drop = FALSE]
stopifnot(
  identical(as.character(screened$candidate_unit_id), expected_units),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'),
  identical(as.character(screened$detailed_source_url), c(
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22682',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22348',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22345',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22421',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25796')),
  all(grepl('does not establish that biological age samples do not exist',
    screened$decision_reason, fixed = TRUE)),
  all(!expected_units %in% stocks$stock_id),
  all(!expected_units %in% assessments$assessment_id),
  all(!expected_units %in% inputs$assessment_id),
  all(!expected_units %in% outputs$assessment_id)
)

remaining <- register[register$candidate_id %in% c('ICES:sal.27.22-31',
  'ICES:sal.27.32', 'ICES:trs.27.22-32', 'ICES:dab.27.22-32', 'ICES:bll.27.22-32'), ]
stopifnot(
  nrow(remaining) == 5L,
  all(remaining$match_status == 'new'),
  all(remaining$screening_status == 'screened'),
  identical(as.character(remaining$eligibility[match(c('ICES:sal.27.22-31',
    'ICES:sal.27.32', 'ICES:trs.27.22-32', 'ICES:dab.27.22-32',
    'ICES:bll.27.22-32'), remaining$candidate_id)]),
    c('unresolved', 'unresolved', 'ineligible', 'ineligible', 'ineligible'))
)

cache <- file.path(root, 'source_cache', 'discovery_ices_baltic_flatfish_2026')
manifest_path <- file.path(cache, 'sources.csv')
review_path <- file.path(root, 'discovery', 'source_reviews', 'ices_baltic_flatfish_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('latest detailed report', review, fixed = TRUE),
  grepl('does not establish that biological age samples do not exist', review, fixed = TRUE),
  grepl('No canonical numerical records were added.', review, fixed = TRUE)
)

if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  cached <- file.path(cache, manifest$file)
  stopifnot(
    nrow(manifest) == 6L,
    all(file.exists(cached)),
    all(file.info(cached)$size == manifest$bytes),
    all(manifest$retrieved_on == '2026-10-30'),
    all(nchar(manifest$sha256) == 64L)
  )
}

cat('ICES Baltic current-unit identity, source, eligibility, and no-import checks passed.\n')
