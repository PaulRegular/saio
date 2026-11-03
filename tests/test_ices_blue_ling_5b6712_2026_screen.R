root <- '.'
cache <- file.path(root, 'source_cache/discovery_ices_blue_ling_5b6712_2026')
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/456_screen_ices_blue_ling_5b6712_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:bli.27.5b6712', , drop = FALSE]
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
}
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_blue_ling_5b6712_2026.md'), warn = FALSE),
  collapse = '\n')
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
  candidate$candidate_unit_id == 'ices_blue_ling_5b6712',
  candidate$official_stock_id == 'bli.27.5b6712',
  candidate$scientific_name == 'Molva dypterygia',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('B_index', candidate$output_evidence, fixed = TRUE),
  grepl('length-based fishing-pressure proxy', candidate$output_evidence, fixed = TRUE),
  grepl('advice category 3.2', candidate$decision_reason, fixed = TRUE),
  grepl('all identify assessment key 22623', candidate$notes, fixed = TRUE),
  nrow(sources) == 5L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(tolower(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_on == '2026-10-31'),
  !any(tolower(stocks$authority_stock_id) == 'bli.27.5b6712', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_blue_ling_5b6712', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_blue_ling_5b6712', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_blue_ling_5b6712', na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/ices_blue_ling_5b6712_2026.md')),
  grepl('must not be interpreted as spawning-stock biomass', review, fixed = TRUE),
  grepl('does not establish that age', review, fixed = TRUE)
)

cat('ICES blue ling bli.27.5b6712 screening checks passed.\n')
