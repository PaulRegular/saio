root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/346_screen_ices_sprat_67acfk_2025.R'))
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
candidate <- register[register$candidate_id == 'ICES:spr.27.67a-cf-k', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_sprat_67acfk_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- normalizePath(file.path(cache, sources$file), mustWork = TRUE)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(path), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_sprat_celtic_seas',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('Category 5.2', candidate$catch_age_evidence, fixed = TRUE),
  grepl('annual catch series', candidate$catch_age_evidence, fixed = TRUE),
  all(file.exists(paths)),
  all(file.info(paths)$size > 0),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  !any(stocks$authority_stock_id == 'spr.27.67a-cf-k', na.rm = TRUE),
  !any(assessments$assessment_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id),
  file.exists(file.path(root, 'discovery/source_reviews/ices_sprat_celtic_seas_2025.md'))
)

cat('ICES Celtic Seas sprat screening checks passed.\n')
