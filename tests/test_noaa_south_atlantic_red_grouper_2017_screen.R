root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/469_screen_noaa_south_atlantic_red_grouper_2017.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10332', , drop = FALSE]
gulf <- register[register$candidate_id == 'NOAA:10331', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_red_grouper_sa_2017')
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
  'discovery/source_reviews/noaa_red_grouper_south_atlantic_2017.md'), warn = FALSE),
  collapse = ' ')
review <- gsub('[[:space:]]+', ' ', review)

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '10332',
  candidate$scientific_name == 'Epinephelus morio',
  candidate$candidate_unit_id == 'noaa_red_grouper_south_atlantic',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  nrow(gulf) == 1L,
  gulf$candidate_unit_id == 'noaa_red_grouper_gom',
  candidate$candidate_unit_id != gulf$candidate_unit_id,
  grepl('SEDAR 86', candidate$decision_reason, fixed = TRUE),
  grepl('1976-2015', candidate$output_evidence, fixed = TRUE),
  grepl('16+', candidate$output_evidence, fixed = TRUE),
  grepl('WP05 Table 3', candidate$catch_age_evidence, fixed = TRUE),
  grepl('single within-year fraction', candidate$timing_evidence, fixed = TRUE),
  nrow(manifest) == 6L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  all(manifest$retrieved_on == '2026-10-31'),
  grepl('SEDAR 86 was planned', review, fixed = TRUE),
  grepl('but it was not completed', review, fixed = TRUE),
  grepl('not a canonical database record yet', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == '10332', na.rm = TRUE),
  !any(stocks$stock_id == 'noaa_red_grouper_south_atlantic'),
  !any(assessments$stock_id == 'noaa_red_grouper_south_atlantic'),
  !any(inputs$assessment_id == 'noaa_red_grouper_south_atlantic'),
  !any(outputs$assessment_id == 'noaa_red_grouper_south_atlantic')
)

cat('NOAA South Atlantic red-grouper identity, source evidence, provenance, and discovery-only checks passed.\n')
