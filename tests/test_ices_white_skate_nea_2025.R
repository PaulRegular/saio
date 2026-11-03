root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/439_screen_ices_white_skate_nea_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

candidate_id <- 'ICES:rja.27.nea'
candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_dogfish_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source <- sources[sources$file == 'wgef_2025.pdf', , drop = FALSE]
path <- file.path(cache, 'wgef_2025.pdf')
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_white_skate_nea_2025.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_white_skate_nea',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('no commercial catch-composition data', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not appropriate for monitoring abundance', candidate$survey_age_evidence, fixed = TRUE),
  grepl('no exploratory or formal stock assessment has been undertaken', candidate$decision_reason, fixed = TRUE),
  nrow(source) == 1L,
  file.exists(path),
  file.info(path)$size == source$bytes,
  identical(toupper(source$sha256), sha256_file(path)),
  identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'),
  grepl('section 23 (printed pp. 670-674)', source$revision, fixed = TRUE),
  grepl('25.9.5', source$revision, fixed = TRUE),
  grepl('recommended zero catches', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'rja.27.nea', na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% assessments$stock_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% inputs$assessment_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% outputs$assessment_id, na.rm = TRUE)
)

cat('ICES white skate 2025 source-screening checks passed.\n')
