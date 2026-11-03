root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)
candidate_id <- 'ICES:usk.27.5a14'
unit_id <- 'ices_tusk_5a14'
row <- match(candidate_id, register$candidate_id)
stopifnot(!is.na(row))
screened <- register[row, , drop = FALSE]
stopifnot(
  screened$official_stock_id == 'usk.27.5a14',
  screened$scientific_name == 'Brosme brosme',
  screened$inventory_assessment_year == 2026L,
  screened$candidate_unit_id == unit_id,
  screened$match_status == 'new',
  screened$screening_status == 'screened',
  screened$eligibility == 'unresolved',
  screened$import_status == 'not_started',
  grepl('SAM', screened$catch_age_evidence, fixed = TRUE),
  grepl('no corresponding catch weight-at-age data from Subarea 14', screened$catch_age_evidence, fixed = TRUE),
  grepl('age-disaggregated Icelandic spring SMB indices', screened$survey_age_evidence, fixed = TRUE),
  grepl('maturity-at-age is derived from autumn-survey', screened$maturity_evidence, fixed = TRUE),
  grepl('0.15 per year', screened$mortality_evidence, fixed = TRUE),
  grepl('Fbar ages 7-10', screened$output_evidence, fixed = TRUE),
  grepl('Eligibility remains unresolved', screened$decision_reason, fixed = TRUE),
  grepl('Do not infer a complete 5.a+14', screened$decision_reason, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'usk.27.5a14', na.rm = TRUE),
  all(!unit_id %in% stocks$stock_id),
  all(!unit_id %in% assessments$assessment_id),
  all(!unit_id %in% inputs$assessment_id),
  all(!unit_id %in% outputs$assessment_id)
)

review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_tusk_5a14_2026.md'), warn = FALSE), collapse = ' ')
stopifnot(
  grepl('combined 5.a+14 unit', review, fixed = TRUE),
  grepl('2026 is a forecast', review, fixed = TRUE),
  grepl('no attached file', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input, or output records were added.', review, fixed = TRUE)
)

cache <- file.path(root, 'source_cache', 'discovery_ices_tusk_5a14_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- c('MFRI_tusk_2026_technical_report.html', 'MFRI_tusk_2026_advice.html',
  'MFRI_tusk_2023_technical_report.pdf', 'ICES_WKICEMP_2022_benchmark.pdf',
  'ICES_stock_graphs_2026_key_22530.html', 'ICES_source_data_2026_key_22530.html',
  'ICES_advice_2026_record_7219.html', 'ICES_stock_annex_2023_metadata.json')
stopifnot(nrow(manifest) == length(files), !anyDuplicated(manifest$file),
  all(files %in% manifest$file), all(file.exists(file.path(cache, files))),
  all(file.info(file.path(cache, files))$size == manifest$bytes[match(files, manifest$file)]),
  all(manifest$retrieved_on[match(files, manifest$file)] == '2026-10-30'),
  all(nchar(manifest$sha256[match(files, manifest$file)]) == 64L))

cat('ICES tusk unit identity, area-specific evidence gap, source provenance, and no-import checks passed.\n')
