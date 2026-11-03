root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('NOAA:10696', 'NOAA:11403', 'NOAA:10700', 'NOAA:11450')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
stopifnot(nrow(rows) == 4L,
  identical(rows$candidate_unit_id, c('noaa_pacific_sleeper_shark_bsai',
    'noaa_bsai_shark_complex', 'noaa_spiny_dogfish_goa',
    'noaa_goa_shark_complex')),
  all(rows$match_status == 'new'),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  rows$assessment_area[2] == 'Bering Sea / Aleutian Islands',
  rows$assessment_area[4] == 'Gulf of Alaska',
  grepl('catch-only', rows$catch_age_evidence[1], fixed = TRUE),
  grepl('random-effects biomass', rows$catch_age_evidence[3], fixed = TRUE),
  grepl('multi-species', rows$catch_age_evidence[2], fixed = TRUE),
  grepl('Tier 5', rows$decision_reason[3], fixed = TRUE),
  all(grepl('2022/BSAIshark.pdf', rows$detailed_source_url, fixed = TRUE)))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE)
stopifnot(all(vapply(rows$candidate_unit_id, function(id)
  sum(units$candidate_unit_id == id) == 1L, logical(1L))))

review <- file.path(root, 'discovery', 'source_reviews',
  'noaa_alaska_sharks_2022.md')
stopifnot(file.exists(review),
  grepl('2026 groundfish SAFE chapter list',
    paste(readLines(review, warn = FALSE), collapse = ' '), fixed = TRUE),
  grepl('species components and multi-species complexes remain distinct',
    paste(readLines(review, warn = FALSE), collapse = ' '), fixed = TRUE))

cache <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected <- c('noaa_bsai_shark_assessment_2022.pdf',
  'npfmc_bsai_safe_intro_2024.pdf')
sources <- manifest[match(expected, manifest$file), , drop = FALSE]
stopifnot(nrow(sources) == 2L,
  all(sources$retrieved_on == '2026-11-02'),
  all(grepl('^[[:xdigit:]]{64}$', sources$sha256)),
  all(file.exists(file.path(cache, sources$file))),
  identical(readBin(file.path(cache, expected[1]), 'raw', n = 5L),
    charToRaw('%PDF-')),
  identical(readBin(file.path(cache, expected[2]), 'raw', n = 5L),
    charToRaw('%PDF-')))

cat('NOAA Alaska shark candidate screen checks passed.\n')
