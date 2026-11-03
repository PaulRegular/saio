root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_black_rockfish_2023')
register_path <- file.path(root, 'discovery', 'candidates.csv')
legacy_unit_id <- 'noaa_black_rockfish_pacific_coast_2023'

current_ids <- c(14407L, 14409L, 17194L, 17195L)
current_assessment_ids <- c(12964L, 12965L, 12963L, 12962L)
current_areas <- c('Oregon', 'Washington', 'South of Point Conception',
  'Point Conception / Oregon Border')
current_names <- c('Black rockfish - Oregon', 'Black rockfish - Washington',
  'Black rockfish - South of Point Conception',
  'Black rockfish - Point Conception / Oregon Border')
current_unit_ids <- c('noaa_black_rockfish_oregon_2023',
  'noaa_black_rockfish_washington_2023',
  'noaa_black_rockfish_california_2023',
  'noaa_black_rockfish_california_2023')
old_ids <- c(10402L, 11302L, 14408L)
old_areas <- c('Northern Pacific Coast', 'Southern Pacific Coast', 'California')
unit_ids <- unique(current_unit_ids)

source_files <- c(
  'Black_Rockfish_Washington_2023_assessment.pdf',
  'Black_Rockfish_Oregon_2023_assessment.pdf',
  'Black_Rockfish_California_2023_assessment.pdf',
  'Black_Rockfish_Washington_2023_model_files.zip',
  'Black_Rockfish_Oregon_2023_model_files.zip',
  'Black_Rockfish_California_2023_model_files.zip',
  'Black_Rockfish_2023_STAR_panel.pdf',
  'NOAA_StockSMART_changelog.html')
source_urls <- c(
  'https://www.pcouncil.org/documents/2024/02/status-of-black-rockfish-sebastes-melanops-in-2023-in-state-and-federal-waters-off-washington-state.pdf/',
  'https://www.pcouncil.org/documents/2024/02/status-of-black-rockfish-sebastes-melanops-in-2023-in-state-and-federal-waters-off-oregon.pdf/',
  'https://www.pcouncil.org/documents/g-2-situation-summary-adopt-stock-assessments/g-2-attachment-8-draft-executive-summary-of-status-of-black-rockfish-sebastes-melanops-in-u-s-waters-off-california-in-2023/',
  'https://www.pcouncil.org/documents/black-rockfish-wa-2023-model-files-zip-file/',
  'https://www.pcouncil.org/documents/black-rockfish-or-2023-model-files-zip-file/',
  'https://www.pcouncil.org/documents/black-rockfish-ca-2023-model-files-zip/',
  'https://www.pcouncil.org/documents/2023/11/stock-assessment-review-star-panel-report-for-black-rockfish.pdf/',
  'https://noaa-edab.github.io/stocksmart/news/index.html')
source_revisions <- c(
  'PFMC 2023 Washington assessment, published February 2024',
  'PFMC 2023 Oregon assessment, published February 2024',
  'PFMC G.2 supplemental revised Attachment 8, retrieved 2026-10-30',
  'PFMC Washington 2023 base model files ZIP',
  'PFMC Oregon 2023 base model files ZIP',
  'PFMC California 2023 North and Central base model files ZIP',
  'PFMC Black Rockfish 2023 STAR panel report',
  'NOAA-EDAB Stock SMART changelog; 2023 stock-name entries')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA black rockfish sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), fileEncoding = 'UTF-8-BOM')
source_rows <- match(source_files, basename(sources$file))
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached NOAA black rockfish sources differ from the reviewed manifest: ',
    paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
current_metadata <- metadata[match(current_assessment_ids, metadata$assessment_id), , drop = FALSE]
if (nrow(current_metadata) != 4L || anyNA(current_metadata$assessment_id) ||
    any(current_metadata$stock_id != current_ids) ||
    any(current_metadata$scientific_name != 'Sebastes melanops') ||
    any(current_metadata$stock_name != current_names) ||
    any(current_metadata$stock_area != current_areas) ||
    any(current_metadata$assessment_year != 2023) ||
    any(current_metadata$last_data_year != 2022) ||
    any(current_metadata$itis != 166727) ||
    any(current_metadata$assessment_model != 'SS') ||
    any(current_metadata$review_result != 'Full acceptance'))
  stop('The pinned NOAA black rockfish Stock SMART records changed.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

current_candidate_ids <- paste0('NOAA:', current_ids)
old_candidate_ids <- paste0('NOAA:', old_ids)
current_rows <- match(current_candidate_ids, register$candidate_id)
old_rows <- match(old_candidate_ids, register$candidate_id)
if (anyNA(current_rows) || anyNA(old_rows) || anyDuplicated(c(current_rows, old_rows)) ||
    any(register$official_stock_id[current_rows] != as.character(current_ids)) ||
    any(register$assessment_area[current_rows] != current_areas) ||
    any(register$assessment_area[old_rows] != old_areas) ||
    any(c(register$scientific_name[current_rows], register$scientific_name[old_rows]) !=
      'Sebastes melanops'))
  stop('NOAA black rockfish inventory identities do not match Stock SMART.', call. = FALSE)

if (any(stocks$stock_id %in% current_unit_ids, na.rm = TRUE) ||
    any(as.character(current_ids) %in% stocks$authority_stock_id, na.rm = TRUE))
  stop('A NOAA black rockfish stock is already represented canonically.', call. = FALSE)
if (any(c(unit_ids, legacy_unit_id, paste0('noaa_black_rockfish_', current_ids)) %in%
    c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('Screening must not duplicate or create canonical black rockfish records.', call. = FALSE)

synthetic_row <- which(register$candidate_id == 'NOAA:166727')
if (length(synthetic_row) > 1L)
  stop('The invalid synthetic black rockfish row is duplicated.', call. = FALSE)
if (length(synthetic_row) == 1L &&
    (register$official_stock_id[synthetic_row] != '166727' ||
     register$scientific_name[synthetic_row] != 'Sebastes melanops' ||
     register$candidate_unit_id[synthetic_row] != legacy_unit_id))
  stop('The synthetic black rockfish row does not match the previously screened row.', call. = FALSE)

initial_state <- function(row) {
  register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
}
current_state <- function(row, expected_unit_id) {
  register$match_status[row] == 'new' &&
    register$candidate_unit_id[row] %in% c(expected_unit_id, legacy_unit_id) &&
    register$screening_status[row] == 'screened' &&
    register$eligibility[row] == 'eligible'
}
old_state <- function(row) {
  register$match_status[row] == 'ambiguous' &&
    register$screening_status[row] == 'screened' &&
    register$eligibility[row] == 'ineligible' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
}
if (any(!vapply(seq_along(current_rows), function(j) {
    row <- current_rows[j]
    initial_state(row) || current_state(row, current_unit_ids[j])
  }, logical(1L))) ||
    any(!vapply(old_rows, function(row) initial_state(row) || old_state(row), logical(1L))))
  stop('A NOAA black rockfish inventory row has a conflicting review state.', call. = FALSE)

source_url_text <- paste(source_urls, collapse = '; ')
current_notes <- paste(
  'The 2023 assessment suite covers distinct Washington and Oregon stocks plus the California stock assessed with northern and central sub-area models. NOAA Stock SMART inventory records 14407, 14409, 17194 and 17195 represent those areas; the two California labels are crosswalked to one California stock assessment, not counted as two stocks. The number 166727 in the NOAA-EDAB changelog is the species ITIS taxonomic serial number, not a NOAA Stock SMART stock ID. Stock SMART California labels do not map one-to-one to the model split at Point Arena; retain this crosswalk caveat. No canonical assessment or numerical records were added.')
old_notes <- paste(
  'This older NOAA Stock SMART row does not add a separate current assessment case. IDs 10402 and 11302 are 2007 broad northern/southern Pacific Coast units; ID 14408 is a 2019 California record. Their boundaries are not crosswalked here to the current assessment units. See the source review; do not count these historical rows as current cases.')

set_fields <- function(row, values) {
  for (name in names(values)) register[[name]][row] <<- values[[name]]
}
for (j in seq_along(current_rows)) {
  row <- current_rows[j]
  set_fields(row, list(
    candidate_unit_id = current_unit_ids[j], matched_stock_id = '', match_status = 'new',
    screening_status = 'screened', eligibility = 'eligible', import_status = 'not_started',
    catch_age_evidence = paste('The 2023 Stock Synthesis components use fleet catch data and fishery age/length compositions. Catch-at-age is not supplied as one direct matrix; reconstruct it from native source catches, age/length compositions, and component-specific biology.'),
    survey_age_evidence = paste('Regional abundance-index series and survey age/length compositions are present in the native model inputs. Documented reconstruction is needed for age-indexed observations; aggregate survey indices are not direct age-specific series.'),
    weights_evidence = paste('Sex- and region-specific growth and weight relationships are represented in the native control/data files and generated age tables. Preserve regional model differences.'),
    maturity_evidence = paste('Regional model files contain maturity and fecundity settings. California spawning output is reported in millions of eggs, not mature biomass.'),
    mortality_evidence = paste('Natural-mortality assumptions are specified by regional model and sex; retain component-specific values and estimation settings.'),
    timing_evidence = paste('Fleet and survey timing settings are retained in each region-specific Stock Synthesis model configuration and must be extracted separately.'),
    output_evidence = paste('The 2023 model archives contain sex-specific numeric N-at-age and biomass-at-age. Washington and Oregon model ages are 0-40; northern and central California model ages are 0-50. Spawning output is in millions of eggs.'),
    detailed_source_url = source_url_text, review_date = '2026-10-30',
    decision_reason = paste('Eligible for source curation as part of the 2023 Pacific Coast black rockfish assessment suite. Washington and Oregon are separate state stocks; the two California Stock SMART rows refer to the California assessment, which has northern and central model sub-areas. Preserve each model component and do not count sub-areas as additional stocks. California inventory labels do not map one-to-one to the Point Arena model split.'),
    notes = current_notes))
}
for (row in old_rows) {
  set_fields(row, list(
    candidate_unit_id = '', matched_stock_id = '', match_status = 'ambiguous',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'Historical NOAA area identifier; its boundary is not a one-to-one match to the 2023 assessment components.',
    survey_age_evidence = 'Do not assign current regional survey inputs to this historical identifier.',
    weights_evidence = 'Do not assign current regional weight-at-age inputs to this historical identifier.',
    maturity_evidence = 'Do not assign current regional maturity inputs to this historical identifier.',
    mortality_evidence = 'Do not assign current regional mortality assumptions to this historical identifier.',
    timing_evidence = 'Do not assign current regional timing settings to this historical identifier.',
    output_evidence = 'The 2023 age-specific outputs belong to the current regional model components, not this historical boundary label.',
    detailed_source_url = source_url_text, review_date = '2026-10-30',
    decision_reason = paste('This historical NOAA Stock SMART area record does not map one-to-one to the latest state-specific assessment definitions. Keep it as a historical identity rather than a separate current candidate.'),
    notes = old_notes))
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  if (length(synthetic_row) == 1L) {
    remove_candidate_register_row(register_path, synthetic_row, 'NOAA:166727')
    register <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
  for (candidate_id in c(current_candidate_ids, old_candidate_ids)) {
    row <- match(candidate_id, register$candidate_id)
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
  }
}

cat('Reconciled NOAA black rockfish Stock SMART IDs to the 2023 assessment suite; removed the erroneous ITIS-based candidate row and preserved historical aliases.\n')
