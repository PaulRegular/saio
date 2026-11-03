root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_pacific_grenadier_2010')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'
candidate_id <- 'NOAA:10526'
unit_id <- 'noaa_pacific_coast_pacific_grenadier'

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
  na.strings = c('', 'NA'), check.names = FALSE)
required <- c('noaa_tm_swfc_460_db_sra_2010.pdf',
  'pacific_coast_groundfish_safe_2024_published_2025.pdf')
if (anyDuplicated(manifest$file[!is.na(manifest$file) & nzchar(manifest$file)]) ||
    !all(required %in% manifest$file[manifest$status == 'downloaded']))
  stop('The Pacific grenadier source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached Pacific grenadier source failed provenance validation: ', file,
      call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[as.character(stocksmart$stock_id) == '10526', , drop = FALSE]
if (nrow(assessment) != 1L || as.character(assessment$assessment_id) != '11870' ||
    assessment$assessment_year != 2010L || assessment$last_data_year != 2009L ||
    assessment$science_center != 'NWFSC / SWFSC' ||
    assessment$jurisdiction != 'PFMC' || assessment$assessment_model != 'DB-SRA' ||
    assessment$review_result != 'Full acceptance')
  stop('Stock SMART metadata no longer matches the reviewed Pacific grenadier record.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) ||
    sum(candidates$candidate_id == candidate_id) != 1L)
  stop('Expected one unique NOAA Pacific grenadier candidate row.', call. = FALSE)
i <- match(candidate_id, candidates$candidate_id)
row <- data.frame(
  candidate_unit_id = unit_id,
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2010 PFMC assessment reconstructs catch for an aggregated grenadier complex because market records are unspecified and species-composition data were unavailable. It provides no Pacific grenadier catch-at-age series.',
  survey_age_evidence = 'The 2010 DB-SRA assessment is catch-based and provides no age-specific survey index. The 2024 Groundfish SAFE, published in 2025, provides current stock context but no Pacific grenadier age-indexed population observations.',
  weights_evidence = 'The 2010 report assumes grenadier species have life-history attributes similar to Pacific grenadier, but it does not provide a model input series of Pacific grenadier weight-at-age.',
  maturity_evidence = 'No Pacific grenadier maturity-at-age input series was identified for the 2010 aggregate DB-SRA assessment or in the reviewed 2024 Groundfish SAFE.',
  mortality_evidence = 'The DB-SRA uses life-history assumptions for a catch-based yield analysis; it does not estimate an age-specific natural-mortality surface for the Pacific grenadier stock.',
  timing_evidence = 'The reviewed production assessment has no age-specific survey likelihood, so survey timing for such an index is unavailable.',
  output_evidence = 'The 2010 report presents sustainable-yield/OFL results for a grenadier complex, not Pacific grenadier-specific N-at-age, F-at-age, SSB, or recruitment outputs.',
  detailed_source_url = paste(
    'https://swfsc-publications.fisheries.noaa.gov/publications/TM/SWFSC/NOAA-TM-NMFS-SWFSC-460.pdf;',
    'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/;',
    'https://www.fisheries.noaa.gov/resource/tool-app/stock-smart'),
  review_date = today,
  decision_reason = 'NOAA Stock SMART identifies the 2010 DB-SRA through 2009 as the latest detailed assessment for Stock 10526 and records full acceptance. The primary report states that species-specific grenadier catch could not be apportioned, so DB-SRA was applied to aggregate grenadier catch as a complex using Pacific grenadier life-history attributes. The current Groundfish SAFE does not identify a newer age-structured production assessment. Age-disaggregated inputs and species-specific population outputs are not available; exclude this current PFMC stock from the age-disaggregated set.',
  notes = paste0('NOAA Stock SMART ID 10526 is the current PFMC Pacific grenadier management stock (Coryphaenoides acrolepis), coastwide. The 2010 assessed unit is the aggregate grenadier complex and is not a species-specific fit. It is a new stock identity relative to the canonical database; no canonical records were added.'),
  stringsAsFactors = FALSE)

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
  if (!pristine) stop('Unexpected existing NOAA Pacific grenadier review state.',
    call. = FALSE)
  for (n in names(row)) candidates[[n]][i] <- row[[n]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:10526 Pacific grenadier as a new, ineligible U.S. unit.\n')
