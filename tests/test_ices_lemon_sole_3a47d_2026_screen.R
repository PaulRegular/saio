root <- '.'
cache <- file.path(root, 'source_cache/discovery_ices_witch_northsea_2026')
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/362_screen_ices_lemon_sole_3a47d_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:lem.27.3a47d', , drop = FALSE]
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
report <- file.path(cache, 'wgnssk_witch.pdf')
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
  candidate$official_stock_id == 'lem.27.3a47d',
  candidate$scientific_name == 'Microstomus kitt',
  candidate$candidate_unit_id == 'ices_lemon_sole_3a47d',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('SURBAR', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-specific survey index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('relative SSB', candidate$output_evidence, fixed = TRUE),
  nrow(sources[sources$file == 'wgnssk_witch.pdf', , drop = FALSE]) == 1L,
  file.exists(report),
  file.info(report)$size > 1000000L,
  tolower(sources$sha256[sources$file == 'wgnssk_witch.pdf']) == sha256_file(report),
  !any(stocks$authority_stock_id == 'lem.27.3a47d', na.rm = TRUE),
  !any(stocks$scientific_name == 'Microstomus kitt', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_lemon_sole_3a47d', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_lemon_sole_3a47d', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_lemon_sole_3a47d', na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/ices_lemon_sole_3a47d_2026.md'))
)

cat('ICES lemon sole screening checks passed.\n')
