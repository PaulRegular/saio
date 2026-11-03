root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/471_screen_noaa_caribbean_red_hind_sedar35_2014.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
red_hind <- register[register$candidate_id == 'NOAA:10327', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_red_hind_sedar35_2014')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
review <- paste(readLines(file.path(root,
  'source_reviews/noaa_caribbean_red_hind_sedar35.md'), warn = FALSE), collapse = ' ')
review <- gsub('[[:space:]]+', ' ', review)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(red_hind) == 1L,
  red_hind$official_stock_id == '10327',
  red_hind$scientific_name == 'Epinephelus guttatus',
  red_hind$candidate_unit_id == 'noaa_caribbean_red_hind',
  red_hind$match_status == 'new',
  red_hind$screening_status == 'screened',
  red_hind$eligibility == 'ineligible',
  red_hind$import_status == 'not_started',
  grepl('does not provide catch-at-age observations', red_hind$catch_age_evidence,
    fixed = TRUE),
  grepl('not age-specific abundance observations', red_hind$survey_age_evidence, fixed = TRUE),
  grepl('SEDAR 91', red_hind$decision_reason, fixed = TRUE),
  nrow(manifest) == 8L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  all(manifest$retrieved_on == '2026-10-31'),
  grepl('SEDAR 35 is the latest completed red-hind-specific stock assessment located', review,
    fixed = TRUE),
  grepl('SEDAR 91', review, fixed = TRUE),
  grepl('screened **ineligible**', review, fixed = TRUE),
  !any(as.character(stocks$authority_stock_id) == '10327', na.rm = TRUE),
  !any(stocks$stock_id == 'noaa_caribbean_red_hind'),
  !any(assessments$stock_id == 'noaa_caribbean_red_hind'),
  !any(inputs$assessment_id == 'noaa_caribbean_red_hind'),
  !any(outputs$assessment_id == 'noaa_caribbean_red_hind')
)

cat('NOAA Caribbean red-hind identity, assessment recency, ineligibility, provenance, and no-import checks passed.\n')
