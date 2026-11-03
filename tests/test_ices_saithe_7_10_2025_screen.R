root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/484_screen_ices_saithe_7_10_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

cache <- file.path(root, 'source_cache/discovery_ices_saithe_subareas_7_10_2025')
register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:pok.27.7-10', , drop = FALSE]
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
}
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_saithe_subareas_7_10_2025.md'), warn = FALSE),
  collapse = '\n')
review <- gsub('[[:space:]]+', ' ', review)
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_saithe_subareas_7_10',
  candidate$official_stock_id == 'pok.27.7-10',
  candidate$scientific_name == 'Pollachius virens',
  candidate$inventory_assessment_year == 2025L,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('category 5', candidate$decision_reason, fixed = TRUE),
  grepl('aggregate landings and discards', candidate$catch_age_evidence, fixed = TRUE),
  grepl('146 tonnes', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 5L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_on == '2026-10-31'),
  !any(tolower(stocks$authority_stock_id) == 'pok.27.7-10', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_saithe_subareas_7_10', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_saithe_subareas_7_10', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_saithe_subareas_7_10', na.rm = TRUE),
  grepl('22 annual fish-data rows', review, fixed = TRUE),
  grepl('no age-data table', review, fixed = TRUE),
  grepl('advice limit, not a fitted age-structured population output', review, fixed = TRUE)
)

cat('ICES saithe pok.27.7-10 screening checks passed.\n')
