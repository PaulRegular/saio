root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database',
  '445_screen_ices_sandeel_west_scotland_6a_2024.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:san.27.6a', , drop = FALSE]
manifest <- read.csv(file.path(root, 'source_cache/discovery_ices_sandeel_6a_2025/sources.csv'),
  stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'san.27.6a',
  candidate$candidate_unit_id == 'ices_sandeel_west_scotland_6a',
  candidate$assessment_area == 'Division 6.a (West of Scotland)',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('category 6', candidate$catch_age_evidence, ignore.case = TRUE),
  grepl('zero-catch', candidate$decision_reason, ignore.case = TRUE),
  nrow(manifest) == 2L,
  all(file.exists(file.path(root, 'source_cache/discovery_ices_sandeel_6a_2025', manifest$file))),
  all(nchar(manifest$sha256) == 64L),
  any(grepl('2024, 2025, and 2026',
    readLines(file.path(root, 'source_cache/discovery_ices_sandeel_6a_2025/ICES_2024_advice.html'),
      warn = FALSE), fixed = TRUE)),
  !any(tolower(stocks$authority_stock_id) == 'san.27.6a', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_sandeel_west_scotland_6a'),
  !any(inputs$assessment_id == 'ices_sandeel_west_scotland_6a'),
  !any(outputs$assessment_id == 'ices_sandeel_west_scotland_6a')
)

cat('ICES 2024 sandeel identity, category-6 screening, provenance, and discovery-only status passed.\n')
