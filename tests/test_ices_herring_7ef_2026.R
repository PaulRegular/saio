root <- '.'
candidate_id <- 'ICES:her.27.7ef'
unit_id <- 'ices_herring_7ef'
cache <- file.path(root, 'source_cache', 'discovery_ices_herring_7ef_2026')
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
report <- file.path(root, manifest$file[1L])
excerpt <- gsub('[[:space:]]+', ' ', paste(readLines(file.path(cache,
  'HAWG_2026_pages_414_419.txt'), warn = FALSE), collapse = ' '))
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
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$official_stock_id == 'her.27.7ef',
  candidate$scientific_name == 'Clupea harengus',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('no catch numbers or weights', candidate$catch_age_evidence, fixed = TRUE),
  grepl('no age-specific survey series', candidate$survey_age_evidence, fixed = TRUE),
  grepl('no assessment', candidate$output_evidence, fixed = TRUE),
  grepl('Category 5', candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  nrow(manifest) == 1L,
  file.exists(report),
  as.numeric(file.info(report)$size) == as.numeric(manifest$bytes[1L]),
  sha256_file(report) == tolower(manifest$sha256[1L]),
  grepl('There is currently no assessment for herring in divisions 7.e-f', excerpt, fixed = TRUE),
  grepl('Category 5, landing', excerpt, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'her.27.7ef', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('ICES herring 7.e-f identity, current method, source integrity, and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '399_screen_ices_herring_7ef_2026.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
