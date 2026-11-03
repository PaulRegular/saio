root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/448_screen_ices_seabass_8c9a_2025.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:bss.27.8c9a', , drop = FALSE]
neighbor <- register[register$candidate_id == 'ICES:bss.27.8ab', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_seabass_8c9a_2025')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
advice <- paste(readLines(file.path(cache, 'ICES_2025_advice.html'), warn = FALSE), collapse = ' ')
source_data <- paste(readLines(file.path(cache, 'SAG_2025_source_data.html'), warn = FALSE), collapse = ' ')
stock_xml <- paste(readLines(file.path(cache, 'SAG_2025_stock.xml'), warn = FALSE), collapse = ' ')
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
  candidate$official_stock_id == 'bss.27.8c9a',
  candidate$scientific_name == 'Dicentrarchus labrax',
  candidate$candidate_unit_id == 'ices_seabass_8c9a',
  candidate$assessment_area == 'Divisions 8.c and 9.a (southern Bay of Biscay and Atlantic Iberian waters)',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  neighbor$candidate_unit_id == 'ices_seabass_8ab',
  candidate$candidate_unit_id != neighbor$candidate_unit_id,
  grepl('Category 5', candidate$decision_reason, fixed = TRUE),
  grepl('306 tonnes', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == 4L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  grepl('bss.27.8c9a', advice, fixed = TRUE),
  grepl('StockCategory>5', stock_xml, fixed = TRUE),
  grepl('306 tonnes', advice, fixed = TRUE),
  grepl('Landings', source_data, fixed = TRUE),
  grepl('1978', source_data, fixed = TRUE),
  grepl('2024', source_data, fixed = TRUE),
  grepl('<Fage></Fage>', stock_xml, fixed = TRUE),
  grepl('<RecruitmentAge></RecruitmentAge>', stock_xml, fixed = TRUE),
  grepl('<ModelType>None</ModelType>', stock_xml, fixed = TRUE),
  !grepl('<StockSize>[^<]+</StockSize>', stock_xml),
  !grepl('<Recruitment>[^<]+</Recruitment>', stock_xml),
  !grepl('<FishingPressure>[^<]+</FishingPressure>', stock_xml),
  !any(tolower(stocks$authority_stock_id) == 'bss.27.8c9a', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_seabass_8c9a'),
  !any(inputs$assessment_id == 'ices_seabass_8c9a'),
  !any(outputs$assessment_id == 'ices_seabass_8c9a'),
  file.exists(file.path(root, 'discovery/source_reviews/ices_seabass_8c9a_2025.md'))
)

cat('ICES 2025 seabass 8.c/9.a identity, category-5 screen, provenance, and discovery-only checks passed.\n')
