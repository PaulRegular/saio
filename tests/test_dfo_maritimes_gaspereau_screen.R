register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'DFO:Maritimes:Gaspereau', , drop = FALSE]
progress <- read.csv('discovery/inventory_progress.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
maritimes <- progress[progress$organization == 'DFO' &
  progress$source_region == 'Maritimes', , drop = FALSE]
units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- 'discovery/source_reviews/dfo_maritimes_gaspereau.md'
cache <- 'source_cache/discovery_dfo_maritimes_gaspereau_2026'
manifest_path <- file.path(cache, 'sources.csv')

stopifnot(nrow(row) == 1L,
  is.na(row$candidate_unit_id), is.na(row$scientific_name),
  row$match_status == 'ambiguous', row$screening_status == 'screened',
  row$eligibility == 'unresolved', row$import_status == 'not_started',
  row$review_date == '2026-10-30',
  all(vapply(row[c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
    'maturity_evidence', 'mortality_evidence', 'timing_evidence', 'output_evidence')],
    function(x) !is.na(x) && nzchar(x), logical(1L))),
  grepl('two species', row$decision_reason, fixed = TRUE),
  grepl('Research Document', row$decision_reason, fixed = TRUE),
  !any(units$candidate_ids == row$candidate_id, na.rm = TRUE),
  nrow(maritimes) == 1L, maritimes$inventory_rows == 42L,
  maritimes$matched == 6L, maritimes$new == 10L,
  maritimes$ambiguous == 3L, maritimes$identity_unreviewed == 23L,
  maritimes$eligible == 2L, maritimes$excluded == 32L,
  maritimes$eligibility_unresolved == 8L,
  maritimes$screening_complete == 42L,
  maritimes$screening_not_started == 0L,
  file.exists(review))

if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  stopifnot(nrow(manifest) == 7L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    any(grepl('40604470.pdf', manifest$url, fixed = TRUE)),
    any(grepl('work-plan-travail-2025-26-eng.html', manifest$url, fixed = TRUE)),
    any(grepl('wp-pt-eng.html', manifest$url, fixed = TRUE)))
}
cat('DFO Maritimes Gaspereau identity and source-screening checks passed.\n')
