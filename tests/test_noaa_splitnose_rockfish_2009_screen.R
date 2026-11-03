root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/487_screen_noaa_splitnose_rockfish_2009.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10564', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache', 'discovery_noaa_splitnose_rockfish_2009')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
paths <- file.path(cache, sources$file)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  toupper(hashes)
}
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_splitnose_rockfish_pacific_2009.md'), warn = FALSE), collapse = '\n')
unit_id <- 'noaa_pacific_splitnose_rockfish_coastwide'
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == unit_id, , drop = FALSE]
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '10564',
  candidate$scientific_name == 'Sebastes diploproa',
  candidate$assessment_area == 'Pacific Coast',
  candidate$inventory_assessment_year == 2009L,
  candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('excluded from the base model', candidate$catch_age_evidence, fixed = TRUE),
  grepl('1980-1981 and 1983-1985', candidate$catch_age_evidence, fixed = TRUE),
  grepl('NWFSC shelf-slope', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.048 per year', candidate$mortality_evidence, fixed = TRUE),
  grepl('timing remains unresolved', candidate$timing_evidence, fixed = TRUE),
  grepl('fitted outputs', candidate$output_evidence, fixed = TRUE),
  grepl('sensitivity run', review, fixed = TRUE),
  grepl('one coastwide', review, ignore.case = TRUE),
  nrow(sources) == 5L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  all(toupper(sources$sha256) == vapply(paths, sha256_file, character(1L))),
  all(sources$retrieved_on == '2026-10-31'),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  grepl('NOAA:10564', unit$candidate_ids, fixed = TRUE),
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L,
  sum(noaa$excluded) == 252L,
  sum(noaa$screening_complete) == 432L,
  !any(stocks$authority_stock_id == '10564', na.rm = TRUE),
  !any(stocks$stock_id == unit_id),
  !any(assessments$stock_id == unit_id),
  !any(inputs$assessment_id == unit_id),
  !any(outputs$assessment_id == unit_id)
)

cat('NOAA Pacific Coast splitnose rockfish source-screening checks passed.\n')
