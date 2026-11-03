root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_longnose_skate_2019')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify a cached source checksum.', call. = FALSE)
  hash
}
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
required <- c('longnose_skate_assessment_2019.pdf', 'longnose_skate_star_2019.pdf',
  'longnose_skate_supplementary_tables_2019.xlsx', 'longnose_skate_model_files_2019.zip',
  'longnose_skate_available_data_2023.pdf')
if (anyDuplicated(manifest$file) || !all(required %in% manifest$file))
  stop('The Longnose Skate source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached source failed provenance validation: ', file, call. = FALSE)
}

native_data <- file.path(cache, 'model_files', 'LSKT2019_data.ss')
native_control <- file.path(cache, 'model_files', 'LSKT2019_control.ss')
if (!file.exists(native_data) || !file.exists(native_control))
  stop('The official archive lacks the expected Longnose Skate native inputs.', call. = FALSE)
data_lines <- readLines(native_data, warn = FALSE)
if (!any(grepl('^1916\\s+#_styr', data_lines)) ||
    !any(grepl('^2018\\s+#_endyr', data_lines)) ||
    !any(grepl('^24 #_N_age_bins', data_lines)) ||
    !any(grepl('^2004\\s+7\\s+1\\s+0\\s+2\\s+1', data_lines)) ||
    !any(grepl('^2003\\s+7\\s+5\\s+0\\s+0\\s+1', data_lines)) ||
    !any(grepl('^2011\\s+7\\s+5\\s+0\\s+0\\s+2', data_lines)) ||
    !any(grepl('^2012\\s+7\\s+5\\s+0\\s+0\\s+2', data_lines)))
  stop('Native inputs do not match the documented years and conditional age-at-length evidence.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
id <- 'NOAA:10731'
i <- match(id, candidates$candidate_id)
if (is.na(i) || sum(candidates$candidate_id == id) != 1L)
  stop('Expected one NOAA:10731 candidate row.', call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
unit_id <- 'noaa_pacific_coast_longnose_skate'
if (any(stocks$authority_stock_id == '10731', na.rm = TRUE) ||
    any(stocks$scientific_name %in% c('Raja rhina', 'Beringraja rhina'), na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE))
  stop('Longnose Skate identity needs reconciliation before screening.', call. = FALSE)
if (any(assessments$assessment_id == 'noaa_longnose_skate_pacific_2019', na.rm = TRUE))
  stop('Unexpected canonical Longnose Skate assessment already exists.', call. = FALSE)

row <- list(
  candidate_unit_id = unit_id,
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste0('The 2019 SS3 data file gives fishery removals in biomass units over 1916-2018, with current-fishery length compositions in 1995-2018 and one fishery conditional age-at-length sample in 2004 (observed ages 0-23). Annual catch numbers-at-age are not directly supplied; a documented length-by-age reconstruction would be needed and would extend the single fishery age sample across years.'),
  survey_age_evidence = paste0('Five aggregate relative abundance indices are fitted (four biomass and one numbers). NWFSC shelf-slope conditional age-at-length data are available for 2003, 2011 and 2012, ages 0-23. Paired survey length compositions and aggregate indices permit limited index-at-age reconstruction for these sampled years, not a continuous observed age-index series.'),
  weights_evidence = paste0('The model estimates growth by age and fixes a combined-sex weight-length relationship (weight kg, total length cm; W=4.288369e-6*L^3.068629). Weight-at-age can be derived from the fitted growth relationship.'),
  maturity_evidence = paste0('A fixed maturity-at-length ogive was estimated from WCGBT survey samples. Maturity-at-age is derived using the fitted growth relationship; no observed annual maturity-at-age matrix was identified.'),
  mortality_evidence = paste0('Natural mortality is estimated as a scalar with an informative prior; it is not an age-specific mortality input.'),
  timing_evidence = paste0('The assessment is annual. Survey observations are recorded in July and the native model sets survey fleet timing to 0.5.'),
  output_evidence = paste0('The official report provides spawning biomass, total biomass, recruitment, depletion and uncertainty. No complete fitted N-at-age or F-at-age series was recovered; the public native archive contains inputs/control/starter/forecast but no fitted Report.sso.'),
  detailed_source_url = paste0('https://www.pcouncil.org/documents/2019/10/stock-assessment-of-the-longnose-skate-beringraja-rhina-in-state-and-federal-waters-off-california-oregon-and-washington-v-october-21-2019.pdf/; ',
    'https://www.pcouncil.org/documents/longnose-skate-model-files-october-2019/; ',
    'https://www.pcouncil.org/documents/2019/10/longnose-skate-supplementary-tables.xlsx; ',
    'https://www.pcouncil.org/documents/2022/02/e-8-attachment-2-detailed-summary-of-available-data-to-support-west-coast-groundfish-stock-assessments-in-2023.pdf'),
  review_date = today,
  decision_reason = paste0('Eligible for source curation under the documented reconstruction criterion: the official 2019 run includes annual biomass catches and fishery/survey length compositions, run-matched conditional age-at-length observations, biological relationships, five aggregate indices, estimated M and comparable official population outputs. Age samples are sparse, annual catch-at-age and index-at-age are not directly supplied, and any reconstruction must retain those limits. This is a source-curation screen, not a translation-readiness decision.'),
  notes = paste0('New NOAA unit, distinct from Gulf of Alaska longnose skate NOAA:10730 and separate from the Canadian assessment area. U.S. coastwide boundaries run from the U.S.-Canada to the U.S.-Mexico border. Full 2019 assessment terminal year is 2018. No canonical records were added.')
)
current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(n) {
  x <- current[[n]]; y <- row[[n]]
  if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[i]) || !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine) stop('Unexpected existing review state for ', id, call. = FALSE)
  for (n in names(row)) candidates[[n]][i] <- row[[n]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], id)
}
source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:10731 as an eligible source-curation candidate with sparse conditional age-at-length inputs.\n')