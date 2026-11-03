root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)

fraser <- register[register$candidate_id == 'DFO:Pacific:Fraser Chum Salmon', , drop = FALSE]
inner <- register[register$candidate_id == 'DFO:Pacific:Inner South Coast Chum', , drop = FALSE]
review_path <- file.path(root, 'discovery', 'source_reviews', 'dfo_fraser_chum_2026.md')

stopifnot(
  nrow(fraser) == 1L,
  fraser$candidate_unit_id == 'dfo_fraser_chum_smu',
  fraser$scientific_name == 'Oncorhynchus keta',
  fraser$assessment_area == 'Fraser River Stock Management Unit, British Columbia',
  fraser$inventory_assessment_year == 2026L,
  fraser$match_status == 'new', fraser$screening_status == 'screened',
  fraser$eligibility == 'ineligible', fraser$import_status == 'not_started',
  grepl('not catch numbers-at-age', fraser$catch_age_evidence, fixed = TRUE),
  grepl('aggregate terminal run-size', fraser$survey_age_evidence, fixed = TRUE),
  grepl('1,521,000', fraser$output_evidence, fixed = TRUE),
  grepl('748,000-3,051,000', fraser$output_evidence, fixed = TRUE),
  nrow(inner) == 1L,
  is.na(inner$candidate_unit_id),
  inner$scientific_name == 'Oncorhynchus keta',
  inner$match_status == 'ambiguous', inner$screening_status == 'screened',
  inner$eligibility == 'unresolved', inner$import_status == 'not_started',
  grepl('Fraser and non-Fraser', inner$catch_age_evidence, fixed = TRUE),
  !any(stocks$stock_id == fraser$candidate_unit_id),
  !any(assessments$assessment_id == fraser$candidate_unit_id),
  !any(inputs$assessment_id == fraser$candidate_unit_id),
  !any(outputs$assessment_id == fraser$candidate_unit_id),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('aggregate seasonal run-size estimator, not an age-structured population assessment', review, fixed = TRUE),
  grepl('No annual N-at-age, F-at-age or M-at-age series', review, fixed = TRUE),
  grepl('identity-ambiguous, with eligibility unresolved', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input or output records were added.', review, fixed = TRUE)
)

cache <- file.path(root, 'source_cache', 'discovery_dfo_fraser_chum_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- file.path(cache, manifest$file)
notice <- paste(readLines(files[grepl('inseason_notice', files)], warn = FALSE), collapse = ' ')
stopifnot(
  nrow(manifest) == 2L,
  all(file.exists(files)),
  all(file.info(files)$size == manifest$bytes),
  identical(as.character(manifest$sha256), c(
    '799730465B2320F3E8D40453B6E1FD6BAFD62E0048156EEC0227D59CC9BFA15F',
    'D6B73A26D34C165D8245C75AB33A56395E1040488B113884EC41D52979970AFB'
  )),
  all(manifest$retrieved_on == '2026-10-30'),
  grepl('1,521,000', notice, fixed = TRUE),
  any(grepl('smon-sc-cs-ifmp-pgip-sm-eng.html', manifest$source_url, fixed = TRUE)),
  any(grepl('DOC_ID=371699', manifest$source_url, fixed = TRUE))
)

cat('DFO Fraser Chum identity and current run-size screening checks passed.\n')
