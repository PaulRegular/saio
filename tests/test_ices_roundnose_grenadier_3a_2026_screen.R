root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database',
  '447_screen_ices_roundnose_grenadier_3a_2026.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:rng.27.3a', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_roundnose_grenadier_3a_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
advice <- paste(readLines(file.path(cache, 'ICES_2026_advice.html'), warn = FALSE), collapse = ' ')
source_data <- paste(readLines(file.path(cache, 'SAG_2026_source_data.html'), warn = FALSE), collapse = ' ')
stock_xml <- paste(readLines(file.path(cache, 'SAG_2026_stock.xml'), warn = FALSE), collapse = ' ')
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
  candidate$official_stock_id == 'rng.27.3a',
  candidate$scientific_name == 'Coryphaenoides rupestris',
  candidate$candidate_unit_id == 'ices_roundnose_grenadier_3a',
  candidate$assessment_area == 'Division 3.a (Skagerrak, Kattegat)',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('category 3.2', candidate$decision_reason, fixed = TRUE),
  grepl('aggregate B_index', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == 4L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  grepl('rng.27.3a', advice, fixed = TRUE),
  grepl('zero catch in each of the years 2027 and 2028', advice, fixed = TRUE),
  grepl('B_index', source_data, fixed = TRUE),
  grepl('Kilograms per hour', source_data, fixed = TRUE),
  grepl('<StockSizeDescription>B_index</StockSizeDescription>', stock_xml, fixed = TRUE),
  grepl('<Fage></Fage>', stock_xml, fixed = TRUE),
  grepl('<RecruitmentAge></RecruitmentAge>', stock_xml, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'rng.27.3a', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_roundnose_grenadier_3a'),
  !any(inputs$assessment_id == 'ices_roundnose_grenadier_3a'),
  !any(outputs$assessment_id == 'ices_roundnose_grenadier_3a'),
  file.exists(file.path(root,
    'discovery/source_reviews/ices_roundnose_grenadier_3a_2026.md'))
)

cat('ICES 2026 Division 3.a roundnose-grenadier identity, aggregate-index screen, provenance, and discovery-only checks passed.\n')
