root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/444_screen_noaa_atlantic_menhaden_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

id <- 'NOAA:11089'
unit_id <- 'noaa_atlantic_menhaden'
candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidates[candidates$candidate_id == id, , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_atlantic_menhaden_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_atlantic_menhaden_2025.md'), warn = FALSE), collapse = '\n')
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
  candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('Tables A2-A5', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not observed survey numbers-at-age', candidate$survey_age_evidence, fixed = TRUE),
  grepl('2018-2023', candidate$decision_reason, fixed = TRUE),
  grepl('age-1+ biomass', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 3L,
  all(vapply(seq_len(nrow(sources)), function(i) {
    path <- file.path(cache, sources$file[i])
    file.exists(path) && file.info(path)$size == sources$bytes[i] &&
      identical(toupper(sources$sha256[i]), sha256_file(path)) &&
      identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF')
  }, logical(1L))),
  grepl('not count it as eligible', review, fixed = TRUE),
  !any(stocks$stock_id == unit_id),
  !any(unit_id %in% assessments$stock_id, na.rm = TRUE),
  !any(unit_id %in% inputs$assessment_id, na.rm = TRUE),
  !any(unit_id %in% outputs$assessment_id, na.rm = TRUE)
)

cat('NOAA Atlantic menhaden 2025 source-screening checks passed.\n')
