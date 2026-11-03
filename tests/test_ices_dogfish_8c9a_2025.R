root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/436_screen_ices_dogfish_8c9a_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:syc.27.8c9a', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_dogfish_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
path <- file.path(cache, 'wgef_2025.pdf')
pdf_source <- sources[sources$file == basename(path), , drop = FALSE]
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_dogfish_8c9a_2025.md'), warn = FALSE), collapse = '\n')
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
  candidate$candidate_unit_id == 'ices_lesser_spotted_dogfish_8c9a',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('length-frequency data', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate survey indices', candidate$survey_age_evidence, fixed = TRUE),
  grepl('2025 WGEF report', candidate$decision_reason, fixed = TRUE),
  nrow(sources) == 2L,
  nrow(pdf_source) == 1L,
  file.exists(path),
  file.info(path)$size == pdf_source$bytes,
  identical(toupper(pdf_source$sha256), sha256_file(path)),
  identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'),
  grepl('new assessment was done in 2025', review, fixed = TRUE),
  grepl('ICES did not receive a request for fishing-opportunity advice', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'syc.27.8c9a', na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% assessments$stock_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% inputs$assessment_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% outputs$assessment_id, na.rm = TRUE)
)

cat('ICES lesser spotted dogfish 2025 source-screening checks passed.\n')
