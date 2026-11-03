root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_bay_biscay_elasmobranchs_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

screens <- data.frame(
  candidate_id = c(
    'ICES:rju.27.9a', 'ICES:rju.27.8ab', 'ICES:rju.27.8c',
    'ICES:rjm.27.8', 'ICES:rjm.27.9a', 'ICES:rjh.27.9a',
    'ICES:rjn.27.9a', 'ICES:rjc.27.8abd', 'ICES:rjc.27.8c',
    'ICES:rjc.27.9a'),
  unit_id = c(
    'ices_undulate_ray_9a', 'ices_undulate_ray_8ab', 'ices_undulate_ray_8c',
    'ices_spotted_ray_8', 'ices_spotted_ray_9a', 'ices_blonde_ray_9a',
    'ices_cuckoo_ray_9a', 'ices_thornback_ray_8abd', 'ices_thornback_ray_8c',
    'ices_thornback_ray_9a'),
  scientific_name = c(
    rep('Raja undulata', 3), rep('Raja montagui', 2), 'Raja brachyura',
    'Leucoraja naevus', rep('Raja clavata', 3)),
  year = c(2024L, 2024L, 2024L, rep(2026L, 7)),
  file = c(
    'rju_27_9a_advice_2024.html', 'rju_27_8ab_advice_2024.html',
    'rju_27_8c_advice_2024.html', 'rjm_27_8_source_data_2026.html',
    'rjm_27_9a_source_data_2026.html', 'rjh_27_9a_source_data_2026.html',
    'rjn_27_9a_source_data_2026.html', 'rjc_27_8abd_source_data_2026.html',
    'rjc_27_8c_source_data_2026.html', 'rjc_27_9a_source_data_2026.html'),
  source_key = c('3771', '3782', '3783', '25871', '25904', '25848', '25865',
    '25854', '25835', '25858'),
  source_url = c(
    'https://asd.ices.dk/viewAdvice/3771',
    'https://asd.ices.dk/viewAdvice/3782',
    'https://asd.ices.dk/viewAdvice/3783',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25871',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25904',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25848',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25865',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25854',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25835',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25858'),
  data_category = c('6', '6', '6', '3', '5', '3', '2.11', '2.11', '2', '2'),
  stock_size = c(
    'No stock-size output', 'No stock-size output', 'No stock-size output',
    'Aggregate biomass index', 'Landings only', 'Aggregate biomass index',
    'Relative exploitable-biomass indicator', 'Relative biomass',
    'Relative biomass', 'Relative biomass'),
  fishing_pressure = c(
    rep('Catch advice only', 3),
    'Length-based fishing-pressure proxy', 'No fishing-pressure series reported',
    'Length-based fishing-pressure proxy', 'Relative fishing-pressure indicator',
    rep('Fishing pressure relative to FMSY', 3)),
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  } else {
    result <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', result[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest_path <- file.path(cache, 'sources.csv')
if (!file.exists(manifest_path)) stop('The reviewed ICES source manifest is missing.', call. = FALSE)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
source_paths <- file.path(cache, screens$file)
manifest_rows <- match(screens$file, manifest$file)
if (anyNA(manifest_rows) || any(!file.exists(source_paths)))
  stop('The local cache is missing one or more reviewed ICES source pages.', call. = FALSE)
if (any(as.character(manifest$url[manifest_rows]) != screens$source_url) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(source_paths)$size)) ||
    !identical(tolower(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(source_paths, sha256_file, character(1L)))))
  stop('The cached ICES source pages do not match their manifest.', call. = FALSE)

source_text <- lapply(source_paths, function(path)
  paste(readLines(path, warn = FALSE, encoding = 'UTF-8'), collapse = ' '))
for (i in seq_len(nrow(screens))) {
  text <- source_text[[i]]
  if (screens$year[i] == 2024L) {
    expected <- c(sub('^ICES:', '', screens$candidate_id[i]), 'Assessment Year',
      '2024', 'Stock Category')
    category_is_six <- grepl('Stock Category</div>[[:space:]]*<div[^>]*>6</div>',
      text, perl = TRUE)
  } else {
      expected <- c(paste0('lblStockCode">', sub('^ICES:', '', screens$candidate_id[i]), '</span>'),
        paste0('lblYear">', screens$year[i], '</span>'), 'lblFAge"></span>',
        'lblFLength"></span>')
    category_is_six <- TRUE
  }
  if (!category_is_six || !all(vapply(expected, grepl, logical(1L), x = text, fixed = TRUE)))
    stop('Cached ICES source does not verify ', screens$candidate_id[i], '.', call. = FALSE)
}

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
rows <- match(screens$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(screens$candidate_id) || anyDuplicated(screens$unit_id) ||
    anyDuplicated(register$candidate_id[rows]))
  stop('Expected one register row and one unit key per screened ICES stock.', call. = FALSE)
if (any(register$scientific_name[rows] != screens$scientific_name) ||
    any(register$official_stock_id[rows] != sub('^ICES:', '', screens$candidate_id)))
  stop('ICES stock identity in the candidate register does not match the current stock codes.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) %in% tolower(sub('^ICES:', '', screens$candidate_id)),
    na.rm = TRUE))
  stop('At least one ICES stock code already appears in the canonical database.', call. = FALSE)
if (any(screens$unit_id %in% c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    na.rm = TRUE) || any(screens$unit_id %in% register$candidate_unit_id[-rows], na.rm = TRUE))
  stop('A candidate unit key conflicts with an existing record.', call. = FALSE)

review_values <- lapply(seq_len(nrow(screens)), function(i) {
  is_survey_index <- screens$candidate_id[i] %in% c(
    'ICES:rjm.27.8', 'ICES:rjh.27.9a', 'ICES:rjn.27.9a',
    'ICES:rjc.27.8abd', 'ICES:rjc.27.8c', 'ICES:rjc.27.9a')
  list(
    candidate_unit_id = screens$unit_id[i],
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = if (screens$year[i] == 2024L) {
      'The 2024 ICES advice is category 6 and presents catch or landings advice at stock level; it does not report a catch-at-age input or population-at-age output.'
    } else {
      'The current advice-linked source reports aggregate landings or catches; no age-specific catch or catch-composition series is presented in the published assessment data.'
    },
    survey_age_evidence = if (is_survey_index) {
      paste0('The 2026 ICES graph reports ', screens$stock_size[i],
        ' at stock level, not an age-specific abundance index.')
    } else if (screens$stock_size[i] == 'Landings only') {
      'The 2026 ICES source reports landings only and no age-specific survey-abundance series.'
    } else {
      'The 2024 advice-linked record does not report an age-specific survey index.'
    },
    weights_evidence = 'No age-specific weight-at-age series is reported in the advice-linked record; an underlying assessment input could not be verified from the published tables reviewed.',
    maturity_evidence = 'No maturity-at-age surface is reported in the advice-linked record; an underlying assessment input could not be verified from the published tables reviewed.',
    mortality_evidence = paste0('The published pressure measure is ', screens$fishing_pressure[i],
      '; no F-at-age or M-at-age series is reported.'),
    timing_evidence = 'The advice-linked source does not provide a fractional within-year timing for an age-specific abundance observation.',
    output_evidence = paste0('The official record provides ', screens$stock_size[i],
      ' and ', screens$fishing_pressure[i],
      '; it does not publish N-at-age, F-at-age, or M-at-age surfaces.'),
    detailed_source_url = screens$source_url[i],
    review_date = '2026-10-30',
    decision_reason = paste0('Ineligible for the current age-disaggregated assessment screen: the latest advice-linked public record reports ',
      screens$stock_size[i], ' and does not provide verifiable age-specific input or N/F/M-at-age output surfaces. ',
      'This is a limit of the currently available assessment record, not evidence that biological age samples do not exist.'),
    notes = paste0('The official ICES stock code and assessment year were checked against the advice page or 2026 Standard Graphs source data. ',
      'Cached page URLs, retrieval date, source revision, file size, and SHA-256 are recorded in ',
      'source_cache/discovery_ices_bay_biscay_elasmobranchs_2026/sources.csv. ',
      'No canonical stock, assessment, input, or output records were added.')
  )
})

is_initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
is_reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == screens$unit_id &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (any(!is_initial & !is_reviewed))
  stop('At least one candidate has a conflicting prior review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_along(rows)) {
    if (is_initial[i] || is_reviewed[i]) {
      for (field in names(review_values[[i]])) register[[field]][rows[i]] <- review_values[[i]][[field]]
      replace_candidate_register_row(register_path, rows[i], register[rows[i], , drop = FALSE],
        screens$candidate_id[i])
    }
  }
}

cat('Screened ten ICES Bay of Biscay and Iberian elasmobranch units as ineligible for age-disaggregated comparison.\n')
