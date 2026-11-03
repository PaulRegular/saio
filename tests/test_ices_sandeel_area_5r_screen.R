Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source('scripts/database/342_screen_ices_sandeel_area_5r_2025.R')

register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:san.sa.5r', , drop = FALSE]
cache <- 'source_cache/discovery_ices_sandeel_area_5r_2025'
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
sha <- vapply(paths, function(path) {
  sha256_file(path)
}, character(1L))
advice <- paste(readLines(paths[match('ICES_Advice_3828.html', sources$file)],
  warn = FALSE), collapse = '\n')
sag <- paste(readLines(paths[match('SAG_19319.html', sources$file)],
  warn = FALSE), collapse = '\n')
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_sandeel_area_5r',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('Category 5.4', candidate$catch_age_evidence, fixed = TRUE),
  grepl('1983-2024', candidate$catch_age_evidence, fixed = TRUE),
  grepl('zero catches', advice, fixed = TRUE),
  grepl('Catches', sag, fixed = TRUE),
  grepl('2024', sag, fixed = TRUE),
  nrow(sources) == 3L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(tolower(sources$sha256) == tolower(unname(sha))),
  !any(stocks$authority_stock_id == 'san.sa.5r', na.rm = TRUE),
  !any(assessments$assessment_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id),
  file.exists('discovery/source_reviews/ices_sandeel_area_5r_2025.md')
)

cat('ICES sandeel Area 5r screening checks passed.\n')
