root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:pol.27.3a4', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_pollack_3a4_2024.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_ices_pollack_3a4_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- c('ICES_stock_graphs_2024_key_19286.html',
  'ICES_source_data_2024_key_19286.html', 'ICES_advice_2024_record_3768.html')

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'pol.27.3a4',
  candidate$scientific_name == 'Pollachius pollachius',
  as.character(candidate$inventory_assessment_year) == '2024',
  candidate$candidate_unit_id == 'ices_pollack_3a4',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('annual landings and discards', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not report catch numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('do not report an age-specific survey', candidate$survey_age_evidence, fixed = TRUE),
  grepl('category 5', candidate$decision_reason, fixed = TRUE),
  grepl('does not assert that age samples are absent elsewhere', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == length(files),
  !anyDuplicated(manifest$file),
  all(files %in% manifest$file),
  all(file.exists(file.path(cache, files))),
  all(file.info(file.path(cache, files))$size == manifest$bytes[match(files, manifest$file)]),
  all(nchar(manifest$sha256[match(files, manifest$file)]) == 64L),
  !any(tolower(stocks$authority_stock_id) == 'pol.27.3a4', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_pollack_3a4', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_pollack_3a4', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_pollack_3a4', na.rm = TRUE),
  grepl('assessment year 2024', review, fixed = TRUE),
  grepl('1977–2023', review, fixed = TRUE),
  grepl('No tinyAM translation was attempted.', review, fixed = TRUE)
)

cat('ICES pollack 3.a4 identity, current advice evidence, provenance, and no-import checks passed.\n')
