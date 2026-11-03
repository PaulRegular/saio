root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:12149', , drop = FALSE]
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_cobia_atlantic_2020',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'eligible', row$import_status == 'not_started',
  row$inventory_assessment_year == 2020,
  grepl('co23', row$decision_reason, fixed = TRUE),
  grepl('1986-2017', row$notes, fixed = TRUE),
  grepl('ages 1-12', row$notes, fixed = TRUE),
  grepl('1991-2015', row$survey_age_evidence, fixed = TRUE),
  grepl('not representative', row$catch_age_evidence, fixed = TRUE),
  grepl('NOAA:10390', row$notes, fixed = TRUE))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE)
unit <- units[units$candidate_unit_id == 'noaa_cobia_atlantic_2020', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$candidate_ids == 'NOAA:12149', unit$eligibility == 'eligible')

review <- file.path(root, 'discovery', 'source_reviews',
  'noaa_atlantic_cobia_sedar58_2020.md')
stopifnot(file.exists(review),
  grepl('commercial age compositions were not used',
    paste(readLines(review, warn = FALSE), collapse = ' '), ignore.case = TRUE))

cache <- file.path(root, 'source_cache',
  'discovery_noaa_sedar_current_assessments_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
report <- manifest[manifest$file == 'sedar58_atlantic_cobia_2020.pdf', , drop = FALSE]
stopifnot(nrow(report) == 1L, report$status == 'downloaded',
  report$retrieval_date == '2026-11-02',
  grepl('^[[:xdigit:]]{64}$', report$sha256),
  file.exists(file.path(cache, report$file)))
signature <- readBin(file.path(cache, report$file), 'raw', n = 5L)
stopifnot(identical(signature, charToRaw('%PDF-')))
reviewer <- manifest[
  manifest$file == 'sedar58_cie_casey_2020.pdf', , drop = FALSE]
stopifnot(nrow(reviewer) == 1L, reviewer$status == 'downloaded',
  reviewer$retrieval_date == '2026-11-02',
  grepl('^[[:xdigit:]]{64}$', reviewer$sha256),
  file.exists(file.path(cache, reviewer$file)))
reviewer_signature <- readBin(file.path(cache, reviewer$file), 'raw', n = 5L)
stopifnot(identical(reviewer_signature, charToRaw('%PDF-')))
