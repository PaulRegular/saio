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

codes <- c('ICES:oal.27.8c9a', 'ICES:sos.27.8c9a')
units <- c('ices_senegalese_sole_8c9a', 'ices_sand_sole_8c9a')
rows <- match(codes, register$candidate_id)
stopifnot(!anyNA(rows), !anyDuplicated(rows))
screened <- register[rows, , drop = FALSE]
stopifnot(
  identical(as.character(screened$candidate_unit_id), units),
  identical(as.character(screened$match_status), c('new', 'new')),
  identical(as.character(screened$screening_status), c('screened', 'screened')),
  identical(as.character(screened$eligibility), c('ineligible', 'ineligible')),
  identical(as.character(screened$import_status), c('not_started', 'not_started')),
  identical(as.character(screened$detailed_source_url), c(
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22600',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23772')),
  all(grepl('category 5', screened$decision_reason, fixed = TRUE)),
  all(grepl('not evidence that biological age samples do not exist',
    screened$decision_reason, fixed = TRUE)),
  all(!units %in% stocks$stock_id),
  all(!units %in% assessments$assessment_id),
  all(!units %in% inputs$assessment_id),
  all(!units %in% outputs$assessment_id)
)

cache <- file.path(root, 'source_cache', 'discovery_ices_iberian_sole_indicators_2026')
manifest_path <- file.path(cache, 'sources.csv')
review_path <- file.path(root, 'discovery', 'source_reviews',
  'ices_iberian_sole_indicators_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('does not establish that biological age samples do not exist', review, fixed = TRUE),
  grepl('The species and divisions are distinct units', review, fixed = TRUE),
  grepl('No database inputs, outputs, or assessments were added.', review, fixed = TRUE)
)

if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  cached <- file.path(cache, manifest$file)
  stopifnot(
    nrow(manifest) == 3L,
    all(file.exists(cached)),
    all(file.info(cached)$size == manifest$bytes),
    all(manifest$retrieved_on == '2026-10-30'),
    all(nchar(manifest$sha256) == 64L)
  )
}

cat('ICES Iberian sole identity, source, eligibility, and no-import checks passed.\n')
