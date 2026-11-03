root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'ICES:bss.27.8ab', , drop = FALSE]
cache <- file.path(root, 'source_cache', 'discovery_ices_seabass_8ab_2026')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
xml <- paste(readLines(file.path(cache, 'ICES_StockAssessment_22538.xml'), warn = FALSE),
  collapse = ' ')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- file.path(root, 'discovery', 'source_reviews',
  'ices_seabass_8ab_2026.md')
review_text <- paste(readLines(review, warn = FALSE), collapse = ' ')

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'ices_seabass_8ab',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'eligible',
  row$import_status == 'not_started',
  row$inventory_assessment_year == 2026L,
  grepl('conditional age-at-length', row$catch_age_evidence, fixed = TRUE),
  grepl('ages 1-4', row$survey_age_evidence, fixed = TRUE),
  grepl('87.7611', row$weights_evidence, fixed = TRUE),
  grepl('42.14', row$maturity_evidence, fixed = TRUE),
  grepl('0.840918', row$mortality_evidence, fixed = TRUE),
  grepl('4-15', row$output_evidence, fixed = TRUE),
  grepl('AssessmentYear>2026', xml, fixed = TRUE),
  grepl('StockCode>bss.27.8ab', xml, fixed = TRUE),
  grepl('Fage>4-15', xml, fixed = TRUE),
  grepl('ConfidenceIntervalDefinition>90%', xml, fixed = TRUE),
  nrow(sources) == 10L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(grepl('^[[:xdigit:]]{64}$', sources$sha256)),
  all(sources$retrieved_utc == '2026-10-30'),
  file.exists(review),
  grepl('No canonical database records were added', review_text, fixed = TRUE),
  !any(stocks$authority_stock_id == 'bss.27.8ab', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_seabass_8ab'),
  !any(inputs$assessment_id == 'ices_seabass_8ab'),
  !any(outputs$assessment_id == 'ices_seabass_8ab')
)

cat('ICES Bay of Biscay sea bass source-screening checks passed.\n')
