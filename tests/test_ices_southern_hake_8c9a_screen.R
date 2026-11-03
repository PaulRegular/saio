root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root,
  'scripts/database/351_screen_ices_southern_hake_8c9a_2026.R'))
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
candidate <- register[register$candidate_id == 'ICES:hke.27.8c9a', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_southern_hake_8c9a_2026')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- normalizePath(file.path(cache, sources$file), mustWork = TRUE)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(path), 'SHA256'), stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_southern_hake_8c9a',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('length-based', candidate$decision_reason, fixed = TRUE),
  grepl('age-0 recruitment', candidate$output_evidence, fixed = TRUE),
  grepl('1-7', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 5L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_utc == '2026-10-30'),
  any(grepl('ICES_WGBIE_2026.pdf', sources$file, fixed = TRUE)),
  !any(stocks$authority_stock_id == 'hke.27.8c9a', na.rm = TRUE),
  !any(assessments$assessment_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id),
  file.exists(file.path(root,
    'discovery/source_reviews/ices_southern_hake_8c9a_2026.md'))
)

cat('ICES southern hake source-screening checks passed.\n')
