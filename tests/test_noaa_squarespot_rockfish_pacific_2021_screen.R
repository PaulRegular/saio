root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/434_screen_noaa_squarespot_rockfish_pacific_2021.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10442', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache/discovery_noaa_squarespot_rockfish_pacific_2021')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}
model <- file.path(cache, 'model_files/Squarespot_rockfish_2021_Model_For_Devore')
dat <- readLines(file.path(model, 'SS_LB.dat'), warn = FALSE)
report <- readLines(file.path(model, 'Report.sso'), warn = FALSE)
review <- paste(readLines(file.path(root, 'discovery/source_reviews/noaa_squarespot_rockfish_pacific_2021.md'),
  warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '10442',
  candidate$scientific_name == 'Sebastes hopkinsi',
  candidate$candidate_unit_id == 'noaa_squarespot_rockfish_california',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('not catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not an age-specific abundance index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.133 per year', candidate$mortality_evidence, fixed = TRUE),
  nrow(sources) == 2L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(toupper(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_on == '2026-10-30'),
  any(grepl('#_Catch data', dat, fixed = TRUE)),
  any(grepl('#_CPUE_and_surveyabundance_observations', dat, fixed = TRUE)),
  any(grepl('#_lencomp', dat, fixed = TRUE)),
  !any(grepl('^#_agecomp', dat, ignore.case = TRUE)),
  all(vapply(c('NUMBERS_AT_AGE', 'F_AT_AGE', 'CATCH_AT_AGE'),
    function(section) any(grepl(section, report, fixed = TRUE)), logical(1L))),
  grepl('not an age-disaggregated observation likelihood', review, fixed = TRUE),
  !any(stocks$authority_stock_id == '10442', na.rm = TRUE),
  !any(stocks$stock_id == candidate$candidate_unit_id),
  !any(assessments$stock_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id)
)

cat('NOAA Pacific Coast Squarespot rockfish source-screening checks passed.\n')
