root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/449_screen_noaa_greater_amberjack_south_atlantic_2020.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10208', , drop = FALSE]
gulf <- register[register$candidate_id == 'NOAA:10207', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_south_atlantic_greater_amberjack_2020')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_greater_amberjack_south_atlantic_2020.md'), warn = FALSE),
  collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '10208',
  candidate$scientific_name == 'Seriola dumerili',
  candidate$candidate_unit_id == 'noaa_greater_amberjack_south_atlantic',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  nrow(gulf) == 1L,
  gulf$candidate_unit_id == 'noaa_gulf_greater_amberjack',
  candidate$candidate_unit_id != gulf$candidate_unit_id,
  grepl('SEDAR 59', candidate$decision_reason, fixed = TRUE),
  grepl('figure digitization', candidate$decision_reason, fixed = TRUE),
  grepl('2020', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == 8L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  all(manifest$retrieved_on == '2026-10-31'),
  grepl('WP05', candidate$catch_age_evidence, fixed = TRUE),
  grepl('WP11', candidate$catch_age_evidence, fixed = TRUE),
  grepl('year-level annual observations', candidate$timing_evidence, fixed = TRUE),
  grepl('Table 6', candidate$output_evidence, fixed = TRUE),
  grepl('does not tabulate', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == '10208', na.rm = TRUE),
  !any(assessments$stock_id == 'noaa_greater_amberjack_south_atlantic'),
  !any(inputs$assessment_id == 'noaa_greater_amberjack_south_atlantic'),
  !any(outputs$assessment_id == 'noaa_greater_amberjack_south_atlantic')
)

cat('NOAA SEDAR 59 identity, age-input/output screen, source provenance, and discovery-only checks passed.\n')
