root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_china_rockfish_2019')
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
required <- c('china_rockfish_assessment_2015.pdf', 'pacific_groundfish_SAFE_2025.pdf',
  'noaa_fy2025_assessment_snapshot.pdf', 'china_rockfish_projection_SAFE_2022.pdf')
if (anyDuplicated(manifest$file) || !all(required %in% manifest$file))
  stop('The China rockfish source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached source failed provenance validation: ', file, call. = FALSE)
}

report <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_china_rockfish_us_pacific_2015.md'), warn = FALSE)
if (!any(grepl('2015 PFMC assessment', report, fixed = TRUE)) ||
    !any(grepl('three separate assessment units', report, fixed = TRUE)) ||
    !any(grepl('catch-only projection', report, fixed = TRUE)))
  stop('The China rockfish source review is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

ids <- c('NOAA:14410', 'NOAA:14430', 'NOAA:14429')
units <- c('noaa_china_rockfish_northern_pacific_coast',
  'noaa_china_rockfish_central_pacific_coast',
  'noaa_china_rockfish_southern_pacific_coast')
areas <- c('Northern', 'Central', 'Southern')
if (!all(ids %in% candidates$candidate_id) || anyDuplicated(candidates$candidate_id))
  stop('Expected unique NOAA China rockfish inventory rows.', call. = FALSE)
if (any(stocks$scientific_name == 'Sebastes nebulosus', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[!candidates$candidate_id %in% ids] %in% units,
      na.rm = TRUE) || any(assessments$stock_id %in% units, na.rm = TRUE))
  stop('China rockfish identities need reconciliation before screening.', call. = FALSE)

rows <- lapply(seq_along(ids), function(j) {
  area <- areas[j]
  list(
    candidate_unit_id = units[j],
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('The official area-specific 2015 SS3 data include annual fishery removals and age compositions. Catch-at-age numbers are not directly supplied and require a documented reconstruction from catches, age/length compositions, and run-matched biological information.'),
    survey_age_evidence = paste0('The assessment uses fishery-dependent abundance indices and age/length compositions. Across the three models there are seven indices (one northern, three central, three southern). No continuous annual age-specific index is directly supplied; reconstruction is conditional on sparse composition coverage.'),
    weights_evidence = paste0('The assessment estimates age-specific growth and documents weight-length relationships; age-specific weights can be derived, with the area and sex-aggregated model basis retained.'),
    maturity_evidence = paste0('Maturity-at-length information is sparse and comes from California and Oregon sources. A maturity-at-age series requires documented derivation and must retain its source limitations.'),
    mortality_evidence = paste0('Post-STAR base models fix natural mortality at 0.07 in all three areas; the central model could not estimate M.'),
    timing_evidence = paste0('The models are annual and use fishery-dependent CPUE indices rather than fishery-independent surveys. Fleet timing must be read from the native area-specific model files during extraction.'),
    output_evidence = paste0('The 2025 SAFE identifies the 2015 assessment as most recent for the ', tolower(area), ' area and reports area-specific official status values. The full 2015 assessment and supporting tables provide model-specific outputs.'),
    detailed_source_url = paste0('https://www.pcouncil.org/documents/2016/04/status-of-china-rockfish-off-the-u-s-pacific-coast-in-2015-april-2016.pdf; ',
      'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/; ',
      'https://www.pcouncil.org/documents/2022/09/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2022.pdf/'),
    review_date = today,
    decision_reason = paste0('Eligible for source curation as a distinct ', tolower(area), ' area model. The 2015 full assessment supplies annual catch, area-specific fishery-dependent indices, age/length compositions, biological relationships, mortality assumptions, and comparable population outputs. Catch-at-age and age-specific index reconstruction are conditional and potentially sparse; this is not a model-readiness decision.'),
    notes = paste0('The NOAA Stock SMART 2019 label is not a newer full assessment: the 2019 action was a catch-only projection based on the 2015 assessment, and the 2025 SAFE still lists 2015 as the most recent assessment. Keep the ', tolower(area), ' model separate from the other two areas. No canonical records were added.')
  )
})

for (j in seq_along(ids)) {
  i <- match(ids[j], candidates$candidate_id)
  row <- rows[[j]]
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
    if (!pristine) stop('Unexpected existing review state for ', ids[j], call. = FALSE)
    for (n in names(row)) candidates[[n]][i] <- row[[n]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], ids[j])
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened three distinct NOAA China rockfish area models as eligible for source curation.\n')
