root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/470_screen_noaa_caribbean_snappers_sedar26_2011.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
silk <- register[register$candidate_id == 'NOAA:10241', , drop = FALSE]
queen <- register[register$candidate_id == 'NOAA:10247', , drop = FALSE]
cache <- file.path(root,
  'source_cache/discovery_noaa_caribbean_snappers_sedar26_2011')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_caribbean_snappers_sedar26_2011.md'), warn = FALSE),
  collapse = ' ')
review <- gsub('[[:space:]]+', ' ', review)

stopifnot(
  nrow(silk) == 1L,
  silk$official_stock_id == '10241',
  silk$scientific_name == 'Lutjanus vivanus',
  silk$candidate_unit_id == 'noaa_caribbean_silk_snapper',
  silk$match_status == 'new',
  silk$screening_status == 'screened',
  silk$eligibility == 'ineligible',
  silk$import_status == 'not_started',
  nrow(queen) == 1L,
  queen$official_stock_id == '10247',
  queen$scientific_name == 'Etelis oculatus',
  queen$candidate_unit_id == 'noaa_caribbean_queen_snapper',
  queen$match_status == 'new',
  queen$screening_status == 'screened',
  queen$eligibility == 'ineligible',
  queen$import_status == 'not_started',
  silk$candidate_unit_id != queen$candidate_unit_id,
  all(c(silk$assessment_area, queen$assessment_area) ==
    'U.S. Caribbean: Puerto Rico and U.S. Virgin Islands'),
  grepl('catch-at-age estimates were not developed', silk$catch_age_evidence,
    fixed = TRUE),
  grepl('commercial CPUE indices', queen$survey_age_evidence, fixed = TRUE),
  grepl('accurate abundance or biomass', queen$output_evidence, fixed = TRUE),
  grepl('SEDAR 103 is still in progress', queen$decision_reason, fixed = TRUE),
  nrow(manifest) == 7L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  all(manifest$retrieved_on == '2026-10-31'),
  grepl('SEDAR 26 is the latest completed detailed assessment', review, fixed = TRUE),
  grepl('too limited for standard fishery stock-assessment models', review, fixed = TRUE),
  grepl('not canonical database records', review, fixed = TRUE),
  any(units$candidate_unit_id == 'noaa_caribbean_silk_snapper'),
  any(units$candidate_unit_id == 'noaa_caribbean_queen_snapper'),
  !any(as.character(stocks$authority_stock_id) %in% c('10241', '10247'), na.rm = TRUE),
  !any(c('noaa_caribbean_silk_snapper', 'noaa_caribbean_queen_snapper') %in% stocks$stock_id),
  !any(c('noaa_caribbean_silk_snapper', 'noaa_caribbean_queen_snapper') %in% assessments$stock_id),
  !any(c('noaa_caribbean_silk_snapper', 'noaa_caribbean_queen_snapper') %in% inputs$assessment_id),
  !any(c('noaa_caribbean_silk_snapper', 'noaa_caribbean_queen_snapper') %in% outputs$assessment_id)
)

cat('NOAA Caribbean silk- and queen-snapper identity, ineligibility, provenance, and no-import checks passed.\n')
