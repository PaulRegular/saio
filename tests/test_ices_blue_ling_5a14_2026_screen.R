root <- '.'
cache <- file.path(root, 'source_cache/discovery_ices_blue_ling_2026')
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/361_screen_ices_blue_ling_5a14_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:bli.27.5a14', , drop = FALSE]
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}
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
  candidate$official_stock_id == 'bli.27.5a14',
  candidate$scientific_name == 'Molva dypterygia',
  candidate$candidate_unit_id == 'ices_blue_ling_5a14',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('no reliable age', candidate$catch_age_evidence, ignore.case = TRUE),
  grepl('no reliable weight-at-age', candidate$weights_evidence, ignore.case = TRUE),
  grepl('length-based', candidate$maturity_evidence, fixed = TRUE),
  grepl('M = 0.15', candidate$mortality_evidence, fixed = TRUE),
  grepl('ages 10-20', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 4L,
  all(file.exists(paths)),
  all(file.info(paths)$size > 100L),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  !any(stocks$authority_stock_id == 'bli.27.5a14', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_blue_ling_5a14', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_blue_ling_5a14', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_blue_ling_5a14', na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/ices_blue_ling_5a14_2026.md'))
)

cat('ICES blue ling screening checks passed.\n')
