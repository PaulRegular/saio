root <- "."
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

ids <- 10483:10494
candidate_ids <- paste0('NOAA:', ids)
unit_ids <- paste0('noaa_chinook_', ids)
rows <- match(candidate_ids, register$candidate_id)
stopifnot(!anyNA(rows), !anyDuplicated(rows))
screened <- register[rows, , drop = FALSE]
stopifnot(
  identical(as.character(screened$candidate_unit_id), unit_ids),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'unresolved'),
  all(screened$import_status == 'not_started'),
  all(screened$review_date == '2026-10-30'),
  all(grepl('Composition Input Data level 4', screened$catch_age_evidence, fixed = TRUE)),
  grepl('Model Category is 2', screened$catch_age_evidence[match(10485, ids)], fixed = TRUE),
  grepl('Model Category is 4', screened$catch_age_evidence[match(10483, ids)], fixed = TRUE),
  all(grepl('age-specific marine survey abundance series', screened$survey_age_evidence, fixed = TRUE)),
  all(grepl('Stock SMART 2026 summary reports B:', screened$output_evidence, fixed = TRUE)),
  all(!unit_ids %in% stocks$stock_id),
  all(!unit_ids %in% assessments$assessment_id),
  all(!unit_ids %in% inputs$assessment_id),
  all(!unit_ids %in% outputs$assessment_id),
  !any(stocks$scientific_name == 'Oncorhynchus tshawytscha')
)

cache <- file.path(root, 'source_cache', 'discovery_noaa_puget_sound_chinook_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
cached <- file.path(cache, manifest$file)
pdf_cached <- cached[grepl('\\.pdf$', manifest$file, ignore.case = TRUE)]
stopifnot(
  nrow(manifest) == 8L,
  all(file.exists(cached)),
  all(file.info(cached)$size == manifest$bytes),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(manifest$retrieved_on[match(c('Preseason_Report_I_2026.pdf',
    'Review_of_2025.pdf', 'StockSMART_DataDictionary.pdf'), manifest$file)] ==
      '2026-10-30'),
  all(startsWith(vapply(pdf_cached, function(path) rawToChar(readBin(path, 'raw', n = 5L)),
    character(1L)), '%PDF-'))
)

review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_west_coast_chinook_2026.md'), warn = FALSE), collapse = ' ')
stopifnot(
  grepl('Composition Input Data is level 4 for all 12', review, fixed = TRUE),
  grepl('Model Category is 4 (VPA) for 11 units', review, fixed = TRUE),
  grepl('generally dominated by age-4 adults', review, fixed = TRUE),
  grepl('eligibility remains **unresolved**', review, fixed = TRUE),
  grepl('No age data, model states, or numeric observations were copied', review, fixed = TRUE)
)

cat('NOAA West Coast Chinook identity, source, unresolved eligibility, cache, and no-import checks passed.\n')
