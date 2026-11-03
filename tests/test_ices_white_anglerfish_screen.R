root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root,
  'scripts/database/350_screen_ices_white_anglerfish_2026.R'))
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

for (suffix in c('78abd', '8c9a')) {
  code <- paste0('mon.27.', suffix)
  unit <- paste0('ices_white_anglerfish_', suffix)
  candidate <- register[register$candidate_id == paste0('ICES:', code), , drop = FALSE]
  cache <- file.path(root, 'source_cache',
    paste0('discovery_ices_white_anglerfish_', suffix, '_2026'))
  sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
  paths <- file.path(cache, sources$file)
  sha256_file <- function(path) {
    output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
      stdout = TRUE)
    tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
  }
  stopifnot(
    nrow(candidate) == 1L,
    candidate$candidate_unit_id == unit,
    candidate$match_status == 'new',
    candidate$screening_status == 'screened',
    candidate$eligibility == 'ineligible',
    candidate$import_status == 'not_started',
    grepl('ineligible', candidate$decision_reason, fixed = TRUE),
    nrow(sources) == 4L,
    all(file.exists(paths)),
    all(file.info(paths)$size == sources$bytes),
    all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
    all(sources$retrieved_utc == '2026-10-30'),
    !any(stocks$authority_stock_id == code, na.rm = TRUE),
    !any(assessments$assessment_id == unit),
    !any(inputs$assessment_id == unit),
    !any(outputs$assessment_id == unit),
    file.exists(file.path(root, 'discovery', 'source_reviews',
      paste0('ices_white_anglerfish_', suffix, '_2026.md')))
  )
}

shared <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026')
shared_sources <- read.csv(file.path(shared, 'sources.csv'), stringsAsFactors = FALSE)
shared_pdf <- file.path(shared, 'ICES_WGBIE_2026.pdf')
stopifnot(
  file.exists(shared_pdf),
  file.info(shared_pdf)$size == shared_sources$bytes[
    match('ICES_WGBIE_2026.pdf', shared_sources$file)]
)

cat('ICES white anglerfish screening checks passed.\n')
