root <- '.'
candidate_id <- 'ICES:rjh.27.7e'
unit_id <- 'ices_blonde_ray_7e'
cache <- file.path(root, 'source_cache', 'discovery_ices_blonde_ray_7e_2024')
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
advice <- paste(readLines(file.path(cache, 'ICES_Advice_2024_text.txt'), warn = FALSE), collapse = ' ')
wgef <- gsub('[[:space:]]+', ' ', paste(readLines(file.path(cache,
  'WGEF_2024_page_483.txt'), warn = FALSE), collapse = ' '))
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$official_stock_id == 'rjh.27.7e',
  candidate$scientific_name == 'Raja brachyura',
  as.character(candidate$inventory_assessment_year) == '2024',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('Assessment type No assessment', advice, fixed = TRUE),
  grepl('Input data Landings data', advice, fixed = TRUE),
  grepl('Category 5 stock using landings data', wgef, fixed = TRUE),
  grepl('no reliable survey trend for this stock', wgef, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  nrow(manifest) == 2L,
  all(file.exists(file.path(root, manifest$file))),
  all(file.info(file.path(root, manifest$file))$size == manifest$bytes),
  !any(tolower(stocks$authority_stock_id) == 'rjh.27.7e', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('ICES blonde ray 7.e identity, no-assessment evidence, and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '401_screen_ices_blonde_ray_7e_2024.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
