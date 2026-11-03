root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root,
  'scripts/database/354_screen_ices_whiting_89a_2026.R'))
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
candidate <- register[register$candidate_id == 'ICES:whg.27.89a', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_whiting_89a_2026')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
local_rows <- !startsWith(sources$file, '..')
report_row <- !local_rows
paths <- file.path(cache, sources$file[local_rows])
report <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026', 'ICES_WGBIE_2026.pdf')
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_whiting_89a',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('Category 3.2', candidate$decision_reason, fixed = TRUE),
  grepl('F age field is blank', candidate$output_evidence, fixed = TRUE),
  nrow(sources) == 5L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes[local_rows]),
  all(tolower(sources$sha256[local_rows]) ==
    vapply(paths, sha256_file, character(1L))),
  file.exists(report),
  file.info(report)$size == sources$bytes[report_row],
  tolower(sha256_file(report)) == tolower(sources$sha256[report_row]),
  all(sources$retrieved_utc == '2026-10-30'),
  !any(stocks$authority_stock_id == 'whg.27.89a', na.rm = TRUE),
  !any(assessments$assessment_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id),
  file.exists(file.path(root,
    'discovery/source_reviews/ices_whiting_89a_2026.md'))
)

cat('ICES whiting source-screening checks passed.\n')
