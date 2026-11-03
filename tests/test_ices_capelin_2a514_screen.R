Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source('scripts/database/344_screen_ices_capelin_2a514_2026.R')

root <- '.'
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidate[candidate$candidate_id == 'ICES:cap.27.2a514', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache', 'discovery_ices_capelin_2a514_2026')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_capelin_iegjm',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('survey-index based', candidate$decision_reason, fixed = TRUE),
  grepl('age-specific', candidate$survey_age_evidence, fixed = TRUE),
  grepl('assessment key 23744', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 4L,
  all(file.exists(paths)),
  all(file.info(paths)$size > 0),
  all(tolower(sources$sha256) == tolower(vapply(paths, sha256_file, character(1L)))),
  !any(stocks$authority_stock_id == 'cap.27.2a514', na.rm = TRUE),
  !any(stocks$stock_id == 'ices_capelin_iegjm'),
  !any(assessments$assessment_id == 'ices_capelin_iegjm'),
  !any(inputs$assessment_id == 'ices_capelin_iegjm'),
  !any(outputs$assessment_id == 'ices_capelin_iegjm'),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'ices_capelin_2a514_2026.md'))
)
cat('ICES IEGJM capelin source-screening checks passed.\n')