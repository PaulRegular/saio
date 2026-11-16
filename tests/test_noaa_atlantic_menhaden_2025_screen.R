root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/noaa_atlantic_menhaden/444_screen_noaa_atlantic_menhaden_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

id <- 'NOAA:11089'
unit_id <- 'noaa_atlantic_menhaden'
candidates <- read.csv(file.path(root, 'database/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidates[candidates$candidate_id == id, , drop = FALSE]
cache <- file.path(root, 'source_cache/noaa_atlantic_menhaden/noaa_atlantic_menhaden_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
review <- paste(readLines(file.path(root,
  'source_reviews/noaa_atlantic_menhaden.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$matched_stock_id == unit_id,
  candidate$match_status == 'matched',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'partial',
  grepl('Tables A2-A5', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not observed survey numbers-at-age', candidate$survey_age_evidence, fixed = TRUE),
  grepl('catch numbers-at-age cannot be reconstructed', candidate$decision_reason, fixed = TRUE),
  grepl('Table 4 supplies 2023 full F', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 3L,
  all(vapply(seq_len(nrow(sources)), function(i) {
    path <- file.path(cache, sources$file[i])
    file.exists(path) && file.info(path)$size == sources$bytes[i] &&
      identical(toupper(sources$sha256[i]), sha256_file(path)) &&
      identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF')
  }, logical(1L))),
  grepl('eligibility for an age-disaggregated comparison remains unresolved',
    review, fixed = TRUE),
  sum(stocks$stock_id == unit_id, na.rm = TRUE) == 1L,
  sum(assessments$assessment_id == paste0(unit_id, '_2025') & assessments$stock_id == unit_id,
    na.rm = TRUE) == 1L
)

cat('NOAA Atlantic menhaden source-screening and partial import checks passed.\n')
