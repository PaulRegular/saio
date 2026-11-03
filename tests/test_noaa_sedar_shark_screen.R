root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:10670', 'NOAA:10674', 'NOAA:10676', 'NOAA:10677',
  'NOAA:10687', 'NOAA:10692', 'NOAA:10967', 'NOAA:10969',
  'NOAA:12130', 'NOAA:12131', 'NOAA:14141', 'NOAA:14142')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
stopifnot(nrow(rows) == length(ids), !anyNA(rows$candidate_id),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  all(!is.na(rows$detailed_source_url) & nzchar(rows$detailed_source_url)),
  all(!is.na(rows$review_date) & rows$review_date == '2026-11-02'),
  rows$match_status[rows$candidate_id == 'NOAA:10677'] == 'ambiguous',
  is.na(rows$candidate_unit_id[rows$candidate_id == 'NOAA:10677']),
  rows$candidate_unit_id[rows$candidate_id == 'NOAA:10670'] ==
    rows$candidate_unit_id[rows$candidate_id == 'NOAA:14141'],
  rows$candidate_unit_id[rows$candidate_id == 'NOAA:14141'] ==
    rows$candidate_unit_id[rows$candidate_id == 'NOAA:14142'],
  all(rows$match_status[rows$candidate_id %in% c('NOAA:14141', 'NOAA:14142')] == 'ambiguous'),
  grepl('catch-free', rows$catch_age_evidence[rows$candidate_id == 'NOAA:10674'], ignore.case = TRUE),
  grepl('length compositions', rows$catch_age_evidence[rows$candidate_id == 'NOAA:10676'], ignore.case = TRUE),
  grepl('reject', rows$output_evidence[rows$candidate_id == 'NOAA:12131'], ignore.case = TRUE),
  grepl('status determinations only', rows$output_evidence[rows$candidate_id == 'NOAA:14141'], ignore.case = TRUE),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_sedar_shark_inventory_2006_2018.md')))

cache <- file.path(root, 'source_cache', 'discovery_noaa_sedar_sharks_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('sedar11_large_coastal_sharks_2006.pdf',
  'sedar13_small_coastal_sharks_2007.pdf',
  'sedar21_atlantic_blacknose_shark_2011.pdf',
  'sedar21_gulf_blacknose_shark_2011.pdf',
  'sedar21_sandbar_shark_2011.pdf',
  'sedar21_dusky_shark_2011.pdf',
  'sedar21_dusky_shark_update_2016.pdf',
  'sedar34_atlantic_sharpnose_shark_2013.pdf',
  'sedar34_bonnethead_shark_2013.pdf',
  'sedar54_sandbar_shark_2018.pdf')
manifest_rows <- manifest[match(required, manifest$file), , drop = FALSE]
stopifnot(nrow(manifest_rows) == length(required), !anyNA(manifest_rows$file),
  all(file.exists(file.path(cache, required))),
  all(grepl('^[[:xdigit:]]{64}$', manifest_rows$sha256)),
  all(manifest_rows$status == 'downloaded'),
  all(manifest_rows$accessed_on == '2026-11-02'))
for (i in seq_along(required)) {
  signature <- readBin(file.path(cache, required[i]), 'raw', n = 4L)
  stopifnot(identical(signature, as.raw(c(0x25, 0x50, 0x44, 0x46))))
}

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
sharpnose <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id ==
  rows$candidate_unit_id[rows$candidate_id == 'NOAA:10670'], , drop = FALSE]
stopifnot(nrow(sharpnose) == 1L,
  sharpnose$inventory_entries == 3L,
  sharpnose$screening_status == 'screened',
  sharpnose$eligibility == 'ineligible',
  grepl('NOAA:10670', sharpnose$candidate_ids, fixed = TRUE),
  grepl('NOAA:14141', sharpnose$candidate_ids, fixed = TRUE),
  grepl('NOAA:14142', sharpnose$candidate_ids, fixed = TRUE))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(noaa$eligible_new) == 75L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L)
