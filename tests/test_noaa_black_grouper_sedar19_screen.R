root <- "."
candidate_id <- 'NOAA:14148'
unit_id <- 'noaa_black_grouper_south_atlantic_gulf'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == unit_id, , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
sefsc <- noaa[noaa$source_region == 'SEFSC', , drop = FALSE]
cache <- file.path(root, 'source_cache', 'discovery_noaa_black_grouper_sedar19')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('SEDAR19_Black_Grouper_Final_Assessment_Report.pdf',
  'SAFMC_Black_Grouper_Management_Procedure_Report_2026.pdf',
  'SEDAR19_DW09_Black_Grouper_Age_Growth_Maturity.pdf')
source_rows <- manifest[match(required, manifest$file), , drop = FALSE]
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), e)
smart <- e$stock_assessment_summary
smart <- smart[as.character(smart$stock_id) == '14148', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_black_grouper_sedar19.md'), warn = FALSE)

stopifnot(nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$scientific_name == 'Mycteroperca bonaci',
  candidate$assessment_area == 'South Atlantic and Gulf of Mexico',
  candidate$match_status == 'new',
  is.na(candidate$matched_stock_id) || candidate$matched_stock_id == '',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  candidate$review_date == '2026-11-02',
  grepl('ASAP2 statistical catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('final accepted index set is unresolved', candidate$survey_age_evidence, fixed = TRUE),
  grepl('1986-2008', candidate$output_evidence, fixed = TRUE),
  grepl('2017 Stock Synthesis effort was suspended', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$match_status == 'new',
  unit$eligibility == 'unresolved',
  unit$screening_status == 'screened',
  unit$candidate_ids == candidate_id,
  nrow(smart) == 1L,
  smart$assessment_id == 5223L,
  smart$assessment_year == 2010L,
  smart$last_data_year == 2008L,
  smart$science_center == 'SEFSC',
  grepl('Age Structured Assessment Program Model', smart$assessment_model, fixed = TRUE),
  smart$model_version == 'Version 2.0.19',
  smart$review_result == 'Full acceptance',
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(sefsc) == 1L,
  sefsc$screening_complete == 90L,
  sefsc$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L,
  nrow(source_rows) == length(required),
  all(file.exists(file.path(cache, required))),
  all(file.info(file.path(cache, required))$size == as.numeric(source_rows$bytes)),
  all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)),
  all(vapply(file.path(cache, required), sha256_file, character(1)) ==
    tolower(source_rows$sha256)),
  any(grepl('2017 Stock Synthesis effort was suspended', review, fixed = TRUE)),
  any(grepl('1986–2008', review, fixed = TRUE)),
  !any(stocks$scientific_name == 'Mycteroperca bonaci', na.rm = TRUE),
  !any(grepl(unit_id, assessments$assessment_id, fixed = TRUE)),
  !any(grepl(unit_id, inputs$assessment_id, fixed = TRUE)),
  !any(grepl(unit_id, outputs$assessment_id, fixed = TRUE)))
cat('NOAA 14148 black grouper source, identity, unresolved eligibility and no-import checks passed.\n')
