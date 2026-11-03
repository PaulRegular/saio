root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/433_screen_noaa_cowcod_southern_california_2019.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10443', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache/discovery_noaa_cowcod_southern_california_2019')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}
model <- file.path(cache, 'model_files')
dat <- readLines(file.path(model, 'cowcod2019.dat'), warn = FALSE)
report <- readLines(file.path(model, 'Report.sso'), warn = FALSE)
review <- paste(readLines(file.path(root, 'discovery/source_reviews',
  'noaa_cowcod_southern_california_2019.md'), warn = FALSE), collapse = '\n')
signatures <- vapply(paths, function(path) rawToChar(readBin(path, 'raw', n = 2L)), character(1L))

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '10443',
  candidate$scientific_name == 'Sebastes levis',
  candidate$assessment_area == 'Southern California',
  candidate$candidate_unit_id == 'noaa_cowcod_southern_california',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  grepl('not direct catch numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.088 per year', candidate$mortality_evidence, fixed = TRUE),
  grepl('2018 terminal data year', candidate$notes, fixed = TRUE),
  nrow(sources) == 3L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(toupper(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_on == '2026-10-30'),
  startsWith(signatures[1L], '%P'),
  startsWith(signatures[2L], 'PK'),
  startsWith(signatures[3L], '%P'),
  any(grepl('#_CPUE_and_surveyabundance_observations', dat, fixed = TRUE)),
  any(grepl('#_N_age_bins', dat, fixed = TRUE)),
  all(vapply(c('NUMBERS_AT_AGE', 'F_AT_AGE', 'CATCH_AT_AGE'),
    function(section) any(grepl(section, report, fixed = TRUE)), logical(1L))),
  grepl('not a direct catch-at-age likelihood', review, fixed = TRUE),
  grepl('Spawning output is in eggs', review, fixed = TRUE),
  !any(stocks$authority_stock_id == '10443', na.rm = TRUE),
  !any(stocks$stock_id == candidate$candidate_unit_id),
  !any(assessments$stock_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id)
)

cat('NOAA Southern California cowcod source-screening checks passed.\n')
