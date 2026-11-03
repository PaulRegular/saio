root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_nefsc_skates_2023')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'
ids <- c('NOAA:11036', 'NOAA:11047', 'NOAA:11063', 'NOAA:11071',
  'NOAA:11076', 'NOAA:11080', 'NOAA:11269')
unit_id <- 'noaa_northeast_skate_complex'

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
required <- c('skate_complex_assessment_2023_draft.pdf',
  'skate_pdt_memo_to_ssc_2023.pdf', 'stocksmart_data_dictionary.pdf')
if (anyDuplicated(manifest$file) || !all(required %in% manifest$file))
  stop('The Northeast skate source manifest is incomplete.', call. = FALSE)
for (file in required) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached source failed provenance validation: ', file, call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stock_ids <- sub('^NOAA:', '', ids)
stock_rows <- stocksmart[as.character(stocksmart$stock_id) %in% stock_ids, , drop = FALSE]
stock_rows <- stock_rows[order(stock_rows$stock_id, -as.numeric(stock_rows$assessment_year),
  stock_rows$assessment_id, na.last = TRUE), , drop = FALSE]
stock_rows <- stock_rows[!duplicated(stock_rows$stock_id), , drop = FALSE]
if (nrow(stock_rows) != length(ids) || anyDuplicated(stock_rows$stock_id) ||
    any(as.character(stock_rows$assessment_year) != '2023') ||
    any(as.character(stock_rows$last_data_year) != '2022') ||
    any(stock_rows$assessment_model != 'Index Method') ||
    any(stock_rows$review_result != 'Full acceptance') ||
    any(stock_rows$composition_input_data != 1))
  stop('Stock SMART evidence no longer matches the reviewed skate units.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) || !all(ids %in% candidates$candidate_id))
  stop('Expected unique NOAA Northeast skate inventory rows.', call. = FALSE)
if (any(candidates$candidate_unit_id[!candidates$candidate_id %in% ids] == unit_id, na.rm = TRUE) ||
    any(candidates$matched_stock_id[!is.na(candidates$matched_stock_id)] %in% c(
      'noaa_northeast_skate_complex', stock_ids)))
  stop('Northeast skate identity conflicts with another candidate or canonical stock.', call. = FALSE)

urls <- paste(
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9056;',
  'https://repository.library.noaa.gov/view/noaa/70900/noaa_70900_DS1.pdf;',
  'https://d23h0vhsm26o6d.cloudfront.net/2_231004-Skate-PDT-memo-to-SSC-re-ABCr.pdf;',
  'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf')
rows <- lapply(ids, function(id) {
  data.frame(
    candidate_unit_id = unit_id,
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = 'The 2023 accepted assessment updates catch removals and allocates historical landings among species using trawl-survey species distributions; it does not provide catch numbers-at-age or age-composition likelihood inputs.',
    survey_age_evidence = 'The assessment uses NEFSC survey biomass indices by species (spring for little skate and fall for the other six). Stock SMART classifies the method as Index Method (category 2); Composition Input Data is level 1, which NOAA defines as composition data collected with major gaps and not used in the assessment.',
    weights_evidence = 'No model weight-at-age series is used or reported. Catch and survey summaries are in biomass/weight units, not an age-structured biological surface.',
    maturity_evidence = 'No maturity-at-age input is used or reported. The peer-review report identifies maturity and age information as needed for future understanding of spawning biomass and age-1 prevalence.',
    mortality_evidence = 'The empirical survey-index method does not estimate age-specific natural mortality or a population M surface.',
    timing_evidence = 'The source assessment uses annual survey-index series and does not specify a within-year timing fraction for an age-structured observation equation.',
    output_evidence = 'The peer-review report states that annual F, recruitment and stock biomass could not be estimated under this method. The assessment reports survey indices and catch projections, not N-at-age, F-at-age, M-at-age, recruitment or SSB trajectories.',
    detailed_source_url = urls,
    review_date = today,
    decision_reason = 'The seven NOAA component rows share one assessed and managed Northeast Skate Complex. Its latest accepted 2023 assessment is an empirical survey-index method, not an age-structured population model, and the public assessment evidence does not establish the age-specific inputs and outputs required for the initial comparison set.',
    notes = paste0('NOAA Stock SMART ', id, ' is one of seven species-level records within the Northeast Skate Complex; linked to the shared complex candidate unit to prevent counting one complex assessment seven times. Latest accepted run: 2023, data through 2022. No canonical records were added.'),
    stringsAsFactors = FALSE
  )
})

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
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
    replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], ids[j])
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened seven NOAA species-level inventory rows as one ineligible Northeast Skate Complex unit.\n')