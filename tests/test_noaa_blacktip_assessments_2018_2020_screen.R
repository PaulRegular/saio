root <- "."
read_table <- function(name) read.csv(file.path(root, name), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
canonical_paths <- c(stocks = 'database/stocks.csv',
  assessments = 'database/assessments.csv', assumptions = 'database/assumptions.csv',
  inputs = 'database/inputs.csv', outputs = 'database/outputs.csv')
canonical_before <- tools::md5sum(file.path(root, canonical_paths))

source(file.path(root, 'scripts', 'database',
  '532_screen_noaa_blacktip_assessments_2018_2020.R'))

register <- read_table('discovery/candidates.csv')
ids <- c('NOAA:11026', 'NOAA:11027')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
expected_units <- c('noaa_atlantic_blacktip_shark', 'noaa_gulf_blacktip_shark')
cache <- file.path(root, 'source_cache', 'discovery_noaa_blacktip_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_files <- c('sedar65_atlantic_blacktip_2020.pdf',
  'sedar29_gom_blacktip_2018_update.pdf',
  'sedar29_gom_blacktip_2018_addendum.pdf')
expected_sizes <- c(18761485L, 5074126L, 3240994L)
expected_hashes <- c(
  'A787B8420CF1F90914DC6EB09FBD70C30E069DEDA21D616DE467640E3204C1EA',
  '9C7DF43546143E6217455B5727ABACB6502EA6A02E2CBA06E29F8B7AA29C5449',
  'A179B487B1860AA36FA04363133952979D9B996F47ED82F7F5B975C3F50ED9B3')
manifest_rows <- manifest[match(expected_files, manifest$file), , drop = FALSE]

stopifnot(nrow(rows) == 2L, !anyNA(rows$candidate_id),
  identical(rows$candidate_unit_id, expected_units),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'), all(rows$import_status == 'not_started'),
  all(rows$review_date == '2026-11-02'),
  grepl('SEDAR 65', rows$notes[1], fixed = TRUE),
  grepl('addendum', rows$notes[2], ignore.case = TRUE),
  grepl('length-composition', rows$decision_reason[1], ignore.case = TRUE),
  grepl('no age-composition observations', rows$decision_reason[2], ignore.case = TRUE),
  identical(canonical_before, tools::md5sum(file.path(root, canonical_paths))),
  nrow(manifest_rows) == 3L, !anyNA(manifest_rows$file),
  identical(as.numeric(manifest_rows$bytes), as.numeric(expected_sizes)),
  identical(manifest_rows$sha256, expected_hashes),
  all(manifest_rows$retrieved_on == '2026-11-02'),
  all(nzchar(manifest_rows$source_url)), all(nzchar(manifest_rows$pinned_revision)),
  all(file.exists(file.path(cache, expected_files))),
  all(file.info(file.path(cache, expected_files))$size == expected_sizes),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_blacktip_assessments_2018_2020.md')))

for (file in expected_files) {
  signature <- readBin(file.path(cache, file), 'raw', n = 5L)
  stopifnot(identical(rawToChar(signature), '%PDF-'))
}

progress <- read_table('discovery/inventory_progress.csv')
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
se <- noaa[noaa$source_region == 'SEFSC', , drop = FALSE]
units <- read_table('discovery/inventory_units.csv')
stopifnot(sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L, sum(noaa$screening_not_started) == 0L,
  nrow(se) == 1L, se$inventory_rows == 90L, se$new == 87L,
  se$identity_unreviewed == 0L, se$excluded == 51L,
  se$eligible_new == 18L, se$eligibility_unresolved == 21L,
  se$screening_complete == 90L, se$screening_not_started == 0L,
  nrow(units) == 736L, sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L,
  sum(progress$identity_unlinked_rows) == 130L)

cat('NOAA Atlantic and Gulf blacktip source-screening checks passed.\n')
