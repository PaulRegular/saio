root <- '.'
cache <- file.path(root, 'source_cache/discovery_ices_spurdog_nea_2026')
candidate_path <- file.path(root, 'discovery/candidates.csv')
before <- readLines(candidate_path, warn = FALSE)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/457_screen_ices_spurdog_nea_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')
stopifnot(identical(before, readLines(candidate_path, warn = FALSE)))

register <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:dgs.27.nea', , drop = FALSE]
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
}
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_spurdog_nea_2026.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_spurdog_nea',
  candidate$official_stock_id == 'dgs.27.nea',
  candidate$scientific_name == 'Squalus acanthias',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('catch numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age compositions', candidate$survey_age_evidence, fixed = TRUE),
  grepl('terminate in 2025', candidate$output_evidence, fixed = TRUE),
  grepl('2026 production inputs', candidate$decision_reason, fixed = TRUE),
  nrow(sources) == 11L,
  all(file.exists(source_paths)),
  all(file.info(source_paths)$size == sources$bytes),
  all(tolower(sources$sha256) == vapply(source_paths, sha256_file, character(1L))),
  !any(tolower(stocks$authority_stock_id) == 'dgs.27.nea', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_spurdog_nea', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_spurdog_nea', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_spurdog_nea', na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/ices_spurdog_nea_2026.md')),
  grepl('not the NOAA/DFO Northwest Atlantic', review, fixed = TRUE),
  grepl('unresolved age-input eligibility', review, fixed = TRUE),
  grepl('assessment was not updated', review, fixed = TRUE)
)

cat('ICES spurdog dgs.27.nea screening checks passed.\n')
