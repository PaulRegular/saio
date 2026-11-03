root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_offshore_hake_2023')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'
candidate_id <- 'NOAA:10524'
unit_id <- 'noaa_offshore_hake_us'

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
required <- c('northern_silver_hake_management_track_2023.pdf',
  'small_mesh_multispecies_specs_2024_2026.pdf')
if (anyDuplicated(manifest$file[!is.na(manifest$file) & nzchar(manifest$file)]) ||
    !all(required %in% manifest$file[manifest$status == 'downloaded']) ||
    !all(c('access_denied') %in% manifest$status))
  stop('The offshore hake source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached offshore hake source failed provenance validation: ', file, call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[as.character(stocksmart$stock_id) == '10524', , drop = FALSE]
if (nrow(assessment) != 1L || as.character(assessment$assessment_id) != '2712' ||
    assessment$assessment_year != 2011L || assessment$last_data_year != 2009L ||
    assessment$science_center != 'NEFSC' ||
    assessment$assessment_model != 'AIM and SEINE' ||
    assessment$review_result != 'Reject - Data insufficient for assessment')
  stop('Stock SMART metadata no longer matches the reviewed offshore hake record.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) || sum(candidates$candidate_id == candidate_id) != 1L)
  stop('Expected one unique NOAA offshore hake candidate row.', call. = FALSE)
i <- match(candidate_id, candidates$candidate_id)
row <- data.frame(
  candidate_unit_id = unit_id,
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2011 SAW report describes offshore-hake landings/discards estimated through species-composition methods, but provides no offshore-hake catch-at-age series. Reported age compositions and catch-at-age are for silver hake and cannot be transferred to offshore hake.',
  survey_age_evidence = 'The 2023 silver-hake update uses aggregate survey-biomass indices and says offshore-hake survey information is unreliable for estimating population trends. No offshore-specific age-abundance index or age composition was found.',
  weights_evidence = 'Length-weight relationships support the source species-composition work, but no offshore-hake weight-at-age surface was found.',
  maturity_evidence = 'No offshore-hake maturity-at-age series was found in the reviewed assessment materials.',
  mortality_evidence = 'The 2011 offshore-hake assessment was rejected for insufficient data; the current empirical silver-hake status method does not estimate an offshore-hake age-specific mortality surface.',
  timing_evidence = 'The reviewed sources do not provide an offshore-hake age-structured observation model or survey timing for such an index.',
  output_evidence = 'Stock SMART reports no estimated F or biomass for offshore hake. The 2023 detailed report provides northern silver-hake survey-index and catch-ratio outputs, not offshore-hake N-at-age, F-at-age, SSB, or recruitment.',
  detailed_source_url = paste(
    'https://repository.library.noaa.gov/view/noaa/3766;',
    'https://repository.library.noaa.gov/view/noaa/3778/noaa_3778_DS1.pdf;',
    'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9036;',
    'https://repository.library.noaa.gov/view/noaa/70900;',
    'https://d23h0vhsm26o6d.cloudfront.net/2024-2026-Small-Mesh-Multispecies-Specifications-EA-final.pdf;',
    'https://www.fisheries.noaa.gov/species/silver-hake'),
  review_date = today,
  decision_reason = 'NOAA Stock SMART identifies the latest offshore-hake benchmark as a 2011 assessment through 2009 and records that it was rejected because data were insufficient. The 2023 silver-hake update does not provide a separate offshore-hake population assessment, and NOAA states that information is insufficient for offshore-hake catch limits. Current public sources do not provide offshore-specific age-disaggregated inputs or population outputs; exclude this U.S. unit from the age-disaggregated candidate set.',
  notes = paste0('NOAA Stock SMART ID 10524 is the U.S. Northwest Atlantic offshore-hake unit. The 2011 report estimates species-specific offshore catch using silver/offshore composition methods and discusses silver-hake age compositions; these are not offshore-hake catch-at-age. The 2023 management-track table groups silver/offshore hake, but the detailed report available for this update is northern silver hake and its population results should not be attributed to offshore hake. No canonical data were added.'),
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
  if (!pristine) stop('Unexpected existing NOAA offshore hake review state.', call. = FALSE)
  for (n in names(row)) candidates[[n]][i] <- row[[n]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:10524 offshore hake as a new, ineligible U.S. unit.\n')