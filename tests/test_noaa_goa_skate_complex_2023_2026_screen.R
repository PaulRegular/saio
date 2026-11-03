root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:11005', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_skate_complex_2023_2026.md'), warn = FALSE), collapse = '\n')
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_skates_2023_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_goa_other_skates',
  row$scientific_name == 'Bathyraja spp.',
  row$assessment_area == 'Gulf of Alaska (Other skates group)',
  row$inventory_assessment_year == 2023L,
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  identical(register$candidate_unit_id[match(c('NOAA:10727', 'NOAA:10730'),
    register$candidate_id)], c('noaa_goa_big_skate', 'noaa_goa_longnose_skate')),
  grepl('not numbers-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('rather than age-specific', row$survey_age_evidence, fixed = TRUE),
  grepl('M = 0.1', row$mortality_evidence, fixed = TRUE),
  grepl('pre-dissemination', row$output_evidence, fixed = TRUE),
  nrow(manifest) == 3L,
  identical(manifest$file, c('goa_skates_safe_2023.pdf',
    'goa_groundfish_safe_intro_2024.pdf', 'goa_skates_safe_2026.pdf')),
  all(file.exists(file.path(cache, manifest$file))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(manifest$retrieval_date == '2026-11-02'),
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L,
  grepl('2023 operational assessment', review, fixed = TRUE),
  grepl('not been formally disseminated', review, fixed = TRUE),
  grepl('within-year timing fraction', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input, or output records were added', review, fixed = TRUE)
)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  !any(stocks$scientific_name %in% c('Beringraja binoculata', 'Raja rhina'), na.rm = TRUE),
  !any(grepl('noaa_goa_other_skates', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_goa_other_skates', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_goa_other_skates', outputs$assessment_id, fixed = TRUE))
)
cat('NOAA Gulf of Alaska skate source-screen checks passed.\n')
