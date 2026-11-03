root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database',
  '446_screen_ices_roundnose_grenadier_oceanic_2023.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:rng.27.5a10b12ac14b', , drop = FALSE]
manifest <- read.csv(file.path(root,
  'source_cache/discovery_ices_roundnose_grenadier_oceanic_2023/sources.csv'),
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
  candidate$official_stock_id == 'rng.27.5a10b12ac14b',
  candidate$candidate_unit_id == 'ices_roundnose_grenadier_oceanic',
  candidate$assessment_area == 'Oceanic Northeast Atlantic and northern Reykjanes Ridge',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('category 5', candidate$catch_age_evidence, ignore.case = TRUE),
  grepl('cannot be quantified', candidate$catch_age_evidence, ignore.case = TRUE),
  nrow(manifest) == 1L,
  file.exists(file.path(root,
    'source_cache/discovery_ices_roundnose_grenadier_oceanic_2023/ICES_2023_advice.html')),
  nchar(manifest$sha256) == 64L,
  !any(tolower(stocks$authority_stock_id) == 'rng.27.5a10b12ac14b', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_roundnose_grenadier_oceanic'),
  !any(inputs$assessment_id == 'ices_roundnose_grenadier_oceanic'),
  !any(outputs$assessment_id == 'ices_roundnose_grenadier_oceanic')
)

cat('ICES 2023 roundnose-grenadier identity, category-5 screen, provenance, and discovery-only status passed.\n')
