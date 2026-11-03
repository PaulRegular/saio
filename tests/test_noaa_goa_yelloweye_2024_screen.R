root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/356_screen_noaa_goa_yelloweye_2024.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10425', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_goa_yelloweye_2024')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}
pdf_signatures <- vapply(paths[1:2], function(path) {
  rawToChar(readBin(path, 'raw', n = 5L))
}, character(1L))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_goa_yelloweye_seo',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('two-index REMA', candidate$survey_age_evidence, fixed = TRUE),
  grepl('1994-2024', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 3L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieval_date == '2026-10-30'),
  all(startsWith(pdf_signatures, '%PDF')),
  !any(stocks$authority_stock_id == '10425', na.rm = TRUE),
  !any(assessments$assessment_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id),
  file.exists(file.path(root,
    'discovery/source_reviews/noaa_goa_yelloweye_2024.md'))
)

cat('NOAA Gulf of Alaska yelloweye source-screening checks passed.\n')
