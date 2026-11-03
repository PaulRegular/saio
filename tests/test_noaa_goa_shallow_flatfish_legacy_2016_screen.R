root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:11009', , drop = FALSE]
related <- register[register$candidate_id %in% c(
  'NOAA:11803', 'NOAA:10836', 'NOAA:15412', 'NOAA:15413',
  'NOAA:10040', 'NOAA:15414', 'NOAA:15415'), , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_shallow_flatfish_legacy_2016_2026.md'), warn = FALSE), collapse = '\n')
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_shallow_flatfish_2016_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  is.na(row$candidate_unit_id) || !nzchar(row$candidate_unit_id),
  row$scientific_name == paste(c(
    'Pleuronectes quadrituberculatus', 'Isopsetta isolepis', 'Parophrys vetulus',
    'Psettichthys melanostictus', 'Platichthys stellatus', 'Limanda aspera',
    'Lepidopsetta polyxystra', 'Lepidopsetta bilineata'), collapse = '; '),
  row$inventory_assessment_year == 2016L,
  row$match_status == 'ambiguous', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  nrow(related) == 7L,
  all(related$screening_status == 'screened'),
  all(c('noaa_goa_other_shallow_water_flatfish_complex',
    'noaa_goa_northern_rock_sole', 'noaa_goa_southern_rock_sole') %in%
      related$candidate_unit_id),
  nrow(manifest) == 7L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(manifest$retrieval_date == '2026-11-02'),
  grepl('last full rock-sole assessment', review, fixed = TRUE),
  grepl('ambiguous legacy identity', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input, or output rows were added', review, fixed = TRUE),
  sum(progress$inventory_rows) == 905L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_not_started) == 0L,
  sum(progress$screening_complete) == 905L,
  sum(units$inventory_entries) == 775L
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
  !any(grepl('noaa_goa_shallow_flatfish_legacy_2016',
    c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id), fixed = TRUE)),
  !any(grepl('noaa_goa_shallow_flatfish_legacy_2016', stocks$stock_id, fixed = TRUE))
)
cat('NOAA Gulf of Alaska shallow-water-flatfish legacy crosswalk checks passed.\n')
