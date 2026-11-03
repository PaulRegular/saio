root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache', 'discovery_ices_sprat_3a4_2026')
candidate <- register[register$candidate_id == 'ICES:spr.27.3a4', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_sprat_3a4_2026.md'), warn = FALSE), collapse = ' ')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_files <- file.path(cache, manifest$file)

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'spr.27.3a4',
  candidate$scientific_name == 'Sprattus sprattus',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$candidate_unit_id == 'ices_sprat_3a4',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('seasonal catch numbers-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-specific IBTS_Q1 observations', candidate$survey_age_evidence, fixed = TRUE),
  grepl('numeric matrix is not in the published repository snapshot',
    candidate$weights_evidence, fixed = TRUE),
  grepl('N-at-age', candidate$output_evidence, fixed = TRUE),
  grepl('eligibility remains', review, fixed = TRUE),
  grepl('unresolved', review, fixed = TRUE),
  nrow(manifest) == 8L,
  !anyDuplicated(manifest$file),
  all(file.exists(manifest_files)),
  all(file.info(manifest_files)$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  !any(tolower(stocks$authority_stock_id) == 'spr.27.3a4', na.rm = TRUE),
  !any(stocks$stock_id == 'ices_sprat_3a4'),
  !any(assessments$assessment_id == 'ices_sprat_3a4'),
  !any(inputs$assessment_id == 'ices_sprat_3a4'),
  !any(outputs$assessment_id == 'ices_sprat_3a4'),
  grepl('omits its referenced numeric input folder', candidate$decision_reason, fixed = TRUE),
  grepl('No canonical stock, assessment, input or output records were added',
    review, fixed = TRUE)
)

cat('ICES sprat 3.a4 identity, age-input evidence, source uncertainty, provenance and no-import checks passed.\n')
