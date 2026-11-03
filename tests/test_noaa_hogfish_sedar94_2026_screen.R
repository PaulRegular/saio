root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:12808', 'NOAA:12809', 'NOAA:12810')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(rows) == 3L,
  identical(as.character(rows$candidate_unit_id), c(
    'noaa_hogfish_west_florida',
    'noaa_hogfish_keys_east_florida',
    'noaa_hogfish_georgia_north_carolina')),
  all(rows$match_status == 'new'),
  all(rows$screening_status == 'screened'),
  identical(as.character(rows$eligibility), c('unresolved', 'unresolved', 'ineligible')),
  all(rows$import_status == 'not_started'),
  all(rows$review_date == '2026-11-02'),
  grepl('conditional age-at-length likelihood', rows$survey_age_evidence[1], fixed = TRUE),
  grepl('not age-specific', rows$survey_age_evidence[1], fixed = TRUE),
  grepl('sufficient information', rows$catch_age_evidence[3], fixed = TRUE)
)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
stopifnot(!any(stocks$scientific_name == 'Lachnolaimus maximus'))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
sefsc <- noaa[noaa$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$matched) == 28L,
  sum(noaa$new) == 388L,
  sum(noaa$ambiguous) == 14L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(sefsc) == 1L,
  sefsc$inventory_rows == 90L,
  sefsc$new == 87L,
  sefsc$identity_unreviewed == 0L,
  sefsc$excluded == 51L,
  sefsc$eligibility_unresolved == 21L,
  sefsc$screening_complete == 90L,
  sefsc$screening_not_started == 0L
)

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE)
stopifnot(nrow(units) == 736L, sum(units$inventory_entries) == 775L)

review_path <- file.path(root, 'discovery', 'source_reviews',
  'noaa_hogfish_sedar94_2026.md')
stopifnot(file.exists(review_path))
manifest <- read.csv(file.path(root, 'source_cache',
  'discovery_noaa_hogfish_sedar94_2026', 'sources.csv'),
  stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 4L,
  all(grepl('https://', manifest$url, fixed = TRUE)),
  all(grepl('^[0-9A-Fa-f]{64}$', manifest$sha256)),
  all(file.exists(file.path(root, 'source_cache',
    'discovery_noaa_hogfish_sedar94_2026', manifest$file)))
)
