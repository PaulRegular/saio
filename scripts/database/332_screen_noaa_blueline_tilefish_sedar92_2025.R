root <- "."
cache <- file.path(root, 'source_cache', 'noaa_blueline_tilefish_sedar92_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(cache, 'manifest.csv')

sources <- data.frame(
  file = file.path(cache, c(
    'sedar92_atlantic_blueline_tilefish_report_march2025.pdf',
    'sedar92_atlantic_blueline_tilefish_north_model_only.pdf',
    'sedar92_south_dlm_addendum_may2025.pdf',
    'safmc_ssc_may2025_final_report.pdf'
  )),
  url = c(
    'https://sedarweb.org/documents/sedar-92-atlantic-blueline-tilefish-final-stock-assessment-report/',
    'https://safmc.net/documents/3a_sedar92_atlanticbluelinetilefish_sar_northernmodelonly-pdf/',
    'https://safmc.net/documents/4a_sedar92_report_addendum_2025-5-23-pdf/',
    'https://safmc.net/documents/ssc_may2025_report_final-pdf/'
  ),
  revision = c(
    'SEDAR 92 operational assessment report, March 28 2025; data through 2023; South ASPIC results later rejected',
    'SEDAR 92 final report, northern model only, March 28 2025; south model removed for review',
    'SEDAR 92 Assessment Report Addendum 1, revised May 23 2025; South of Cape Hatteras DLM',
    'SAFMC SSC final report, May 2025; review and management recommendations'
  ),
  stringsAsFactors = FALSE
)
paths <- sources$file
if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the cited SEDAR 92 sources before screening.', call. = FALSE)
}
if (!all(vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L)))) {
  stop('A cached SEDAR 92 source is not a PDF.', call. = FALSE)
}
sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
if (!identical(basename(manifest$file), basename(sources$file)) ||
    !identical(manifest$url, sources$url) ||
    !identical(manifest$revision, sources$revision) ||
    !identical(as.numeric(manifest$bytes), as.numeric(file.info(paths)$size)) ||
    !identical(tolower(manifest$sha256), unname(vapply(paths, sha256_file, character(1L))))) {
  stop('Cached SEDAR 92 source manifest does not match the reviewed files.', call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
south_latest <- stocksmart[stocksmart$stock_id == 10381 &
  stocksmart$assessment_year == 2025, , drop = FALSE]
north_latest <- stocksmart[stocksmart$stock_id == 14922 &
  stocksmart$assessment_year == 2025, , drop = FALSE]
south_prior <- stocksmart[stocksmart$stock_id == 10381 &
  stocksmart$assessment_year == 2017, , drop = FALSE]
north_prior <- stocksmart[stocksmart$stock_id == 14922 &
  stocksmart$assessment_year == 2018, , drop = FALSE]
if (nrow(south_latest) != 1L || south_latest$assessment_id != 13944L ||
    !grepl('Reject', south_latest$review_result, fixed = TRUE) ||
    south_latest$assessment_model != 'ASPIC' ||
    nrow(north_latest) != 1L || north_latest$assessment_id != 13772L ||
    !grepl('Reject', north_latest$review_result, fixed = TRUE) ||
    north_latest$assessment_model != 'DLM Toolkit' ||
    nrow(south_prior) != 1L || south_prior$assessment_id != 7778L ||
    south_prior$assessment_model != 'ASPIC' ||
    nrow(north_prior) != 1L || north_prior$assessment_id != 8902L ||
    !grepl('Catch Only', north_prior$assessment_model, fixed = TRUE)) {
  stop('NOAA Stock SMART run metadata differs from the reviewed snapshot.', call. = FALSE)
}

review_rows <- data.frame(
  candidate_id = c('NOAA:10381', 'NOAA:14922'),
  candidate_unit_id = c('noaa_blueline_tilefish_south_atlantic',
    'noaa_blueline_tilefish_mid_atlantic'),
  scientific_name = rep('Caulolatilus microps', 2L),
  stock_name = c('Blueline tilefish - Southern Atlantic Coast',
    'Blueline tilefish - Mid-Atlantic Coast'),
  assessment_area = c('Southern Atlantic Coast', 'Mid-Atlantic Coast'),
  inventory_assessment_year = rep(2025L, 2L),
  stringsAsFactors = FALSE
)
rows <- match(review_rows$candidate_id, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(candidates$candidate_id[rows]) ||
    any(candidates$scientific_name[rows] != review_rows$scientific_name) ||
    any(candidates$stock_name[rows] != review_rows$stock_name) ||
    any(candidates$assessment_area[rows] != review_rows$assessment_area) ||
    any(as.integer(candidates$inventory_assessment_year[rows]) != 2025L)) {
  stop('Expected the NOAA Stock SMART Southern and Mid-Atlantic blueline tilefish rows.',
    call. = FALSE)
}
if (any(stocks$scientific_name == 'Caulolatilus microps', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-rows] %in% review_rows$candidate_unit_id,
      na.rm = TRUE)) {
  stop('A reviewed blueline tilefish unit conflicts with another canonical or candidate unit.',
    call. = FALSE)
}
assessment_ids <- c('noaa_blueline_tilefish_south_atlantic',
  'noaa_blueline_tilefish_mid_atlantic')
if (any(assessments$assessment_id %in% assessment_ids, na.rm = TRUE) ||
    any(inputs$assessment_id %in% assessment_ids, na.rm = TRUE) ||
    any(outputs$assessment_id %in% assessment_ids, na.rm = TRUE)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}
if (any(!candidates$match_status[rows] %in% c('unreviewed', 'new')) ||
    any(!candidates$screening_status[rows] %in% c('not_started', 'screened'))) {
  stop('A blueline tilefish row already has a conflicting review.', call. = FALSE)
}

common_sources <- c(sources$url,
  'https://safmc.net/events/may-2025-scientific-and-statistical-committee-meeting/',
  'https://www.fisheries.noaa.gov/species/blueline-tilefish')
review <- list(
  data.frame(
    candidate_unit_id = review_rows$candidate_unit_id[1L],
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The latest SEDAR 92 production-era sources (data through 2023) use removals',
      'in weight, aggregate abundance indices for the southern ASPIC assessment,',
      'and, in the replacement DLM analysis, removals, length compositions, and',
      'life-history quantities. Neither model uses catch numbers-at-age or a',
      'fishery age-composition likelihood. Age-based life-history parameters do',
      'not constitute age-disaggregated catch inputs.'),
    survey_age_evidence = paste(
      'SEDAR 92 uses aggregate CPUE indices in the southern ASPIC assessment.',
      'The May 2025 southern DLM analysis does not use an age-specific survey',
      'index; the northern DLM report states that no valid age compositions or',
      'abundance indices were available north of Cape Hatteras.'),
    weights_evidence = paste(
      'The southern DLM uses a weight-length relationship, not an observed',
      'weights-at-age series. No run-specific weights-at-age likelihood input',
      'was identified for the 2025 assessment.'),
    maturity_evidence = paste(
      'The DLM uses length at 50% maturity as a life-history input; the',
      'assessment does not use a maturity-at-age series in an age-structured',
      'population model.'),
    mortality_evidence = paste(
      'The southern DLM uses a scalar natural mortality input (M = 0.17 with',
      'CV 0.24) based on maximum age and the Then et al. relationship. It is not',
      'a fitted age-specific M process.'),
    timing_evidence = paste(
      'The 2025 DLM analyses use removals and broad length summaries; the',
      'sources do not specify a fractional timing for an age-specific survey',
      'observation. The earlier ASPIC model uses aggregate CPUE series.'),
    output_evidence = paste(
      'SEDAR 92 reports aggregate biomass and fishing-mortality results from',
      'the southern ASPIC analysis, but the April 2025 SSC rejected that model',
      'as inadequate for management. The replacement DLM reports TAC',
      'distributions, not population-at-age or F-at-age outputs. NOAA still',
      'cites the 2017 assessment for South Atlantic stock-status estimates.'),
    detailed_source_url = paste(common_sources, collapse = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'Ineligible for the age-disaggregated source set. NOAA Stock SMART lists',
      'the 2025 SEDAR 92 ASPIC run (assessment 13944, terminal year 2023) as',
      'rejected because its results were too uncertain. The South Atlantic SSC',
      'did not recommend the age-aggregated ASPIC model for management and',
      'supported average-catch DLM methods. The May 2025 DLM addendum documents',
      'removals, length compositions, life history, and TAC distributions, with',
      'no age-structured observations or population outputs. The latest',
      'accepted 2017 South Atlantic run was also ASPIC. The assessment unit has',
      'no verified age-disaggregated likelihood inputs.'),
    notes = paste(
      'NOAA Stock SMART 10381 is a distinct South Atlantic management unit;',
      'its species page continues to identify the 2017 assessment for stock',
      'status. SEDAR 92 covers the broader Atlantic stock and separates regions',
      'at Cape Hatteras. Keep this NOAA unit distinct from the separate Mid-',
      'Atlantic Stock SMART unit; do not treat the shared SEDAR report as proof',
      'that the two management units are identical. Run metadata come from the',
      '2026-10-28 cached Stock SMART inventory.'),
    stringsAsFactors = FALSE
  ),
  data.frame(
    candidate_unit_id = review_rows$candidate_unit_id[2L],
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The SEDAR 92 northern analysis uses total removals in weight and annual',
      'commercial length compositions. The report states that no valid age',
      'compositions were available north of Cape Hatteras. No catch-at-age or',
      'age-composition likelihood input was identified.'),
    survey_age_evidence = paste(
      'The SEDAR 92 report states that no valid abundance indices were available',
      'for the northern region. No age-specific survey index is used.'),
    weights_evidence = paste(
      'The DLM uses life-history inputs, including weight-length and growth',
      'parameters, rather than a measured weights-at-age likelihood series.'),
    maturity_evidence = paste(
      'Life-history parameters include length at maturity. No maturity-at-age',
      'series is used by the northern DLM assessment.'),
    mortality_evidence = paste(
      'The DLM includes life-history mortality assumptions but has no fitted',
      'age-specific M process; no mortality-at-age population model was found.'),
    timing_evidence = paste(
      'The assessment does not fit age-specific seasonal survey observations.',
      'No fractional survey timing is applicable to the documented length and',
      'removals inputs.'),
    output_evidence = paste(
      'The north-of-Cape-Hatteras DLM reports catch-limit distributions and',
      'does not provide comparable age-structured abundance, fishing mortality,',
      'or recruitment outputs. Stock SMART lists the 2025 run as rejected due',
      'to insufficient data.'),
    detailed_source_url = paste(common_sources, collapse = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'Ineligible for the age-disaggregated source set. NOAA Stock SMART lists',
      'the 2025 SEDAR 92 DLM Toolkit run (assessment 13772, terminal year 2023)',
      'as rejected because the data were insufficient. The northern report',
      'documents removals, commercial length compositions, and life history,',
      'and explicitly states that valid age compositions and abundance indices',
      'were unavailable. Outputs are management TAC distributions, not annual',
      'population-at-age quantities. The prior 2018 accepted assessment was',
      'also a catch-only DLM Toolkit approach.'),
    notes = paste(
      'NOAA Stock SMART 14922 identifies the Mid-Atlantic Coast management unit.',
      'SEDAR 92 defines a broader northern analysis region from Cape Hatteras to',
      'Massachusetts, while the Mid-Atlantic management area begins north of the',
      'North Carolina/Virginia boundary. Keep the NOAA unit distinct from NOAA',
      'South Atlantic Stock SMART 10381; document this boundary mismatch in any',
      'future extraction. Run metadata come from the 2026-10-28 cached Stock',
      'SMART inventory.'),
    stringsAsFactors = FALSE
  )
)

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path,
    call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) {
    as.raw(c(13L, 10L))
  } else {
    as.raw(10L)
  }
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}
for (j in seq_along(rows)) {
  for (column in names(review[[j]])) candidates[[column]][rows[j]] <- review[[j]][[column]]
  replace_csv_row(candidate_path, rows[j], candidates[rows[j], , drop = FALSE])
}
cat('Screened NOAA South and Mid-Atlantic Blueline Tilefish against SEDAR 92 sources.\n')
