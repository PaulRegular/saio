root <- "."
cache <- file.path(root, 'source_cache', 'noaa_golden_tilefish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(cache, 'manifest.csv')

sources <- data.frame(
  file = c(
    'sedar89_south_atlantic_tilefish_updated_2025-09-30.pdf',
    'sedar89_south_atlantic_tilefish_wp03_reproduction_2024.pdf',
    'sedar89_south_atlantic_tilefish_wp06_commercial_age_length_2024.pdf',
    'golden_tilefish_management_track_peer_review_2024-07.pdf',
    'golden_tilefish_mid_atlantic_2024_management_track_assessment_report.pdf',
    'golden_tilefish_mid_atlantic_2024_management_track_input_data.pdf',
    'golden_tilefish_mid_atlantic_2024_management_track_results.pdf',
    'golden_tilefish_mid_atlantic_2024_management_track_model_files.zip'
  ),
  url = c(
    'https://sedarweb.org/documents/sedar-89-golden-tilefish-stock-assessment-report-updated-september-30-2025/',
    'https://sedarweb.org/wp-content/uploads/document-blocks/2024/04/b102241f-6981-4e72-a3db-8b970f15ee45-S89_WP_03_Bubley_et_al_Repro_Final.pdf',
    'https://sedarweb.org/wp-content/uploads/document-blocks/2024/04/17c6c6c6-37b5-4521-bd28-28f731b7207b-S89_WP_06_TIL_Com-length-age-comps_20240418.pdf',
    'https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&filename=2024_Golden_Tilefish_Report_07_02_132018.794267.pdf',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=final_input_data.pdf',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&info_type_id=3&map_type_id=&filename=final_results.pdf',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=29&stock_id=6&review_type_id=3&filename=2024_GT_UNIT.zip'
  ),
  revision = c(
    'SEDAR 89 SAR1-Rev2, updated September 2025; assessment through 2022',
    'SEDAR 89 WP-03, submitted 19 April 2024; reproductive parameters',
    'SEDAR 89 WP-06, submitted 22 April 2024; commercial landings age/length compositions',
    'June 2024 management-track peer-review panel report, published 18 July 2024',
    '2024 Mid-Atlantic management-track assessment report, compiled 2 July 2024; draft label retained',
    '2024 Mid-Atlantic SASINF final input-data report',
    '2024 Mid-Atlantic SASINF final results report',
    '2024 Mid-Atlantic SASINF assessment archive; inventory contents before use'
  ),
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed assessment sources before screening.', call. = FALSE)

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
manifest <- data.frame(file = sources$file, url = sources$url,
  revision = sources$revision, retrieved_utc = '2026-10-30',
  bytes = file.info(paths)$size,
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  stringsAsFactors = FALSE)
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) ||
      !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes)) ||
      !identical(tolower(previous$sha256), manifest$sha256))
    stop('Cached golden tilefish source manifest differs from reviewed files.', call. = FALSE)
} else write.csv(manifest, manifest_path, row.names = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
south_run <- stocksmart[stocksmart$stock_id == 10384 &
  stocksmart$assessment_id == 14290, , drop = FALSE]
mid_run <- stocksmart[stocksmart$stock_id == 10385 &
  stocksmart$assessment_id == 13544, , drop = FALSE]
if (nrow(south_run) != 1L || south_run$assessment_year != 2025L ||
    south_run$last_data_year != 2022L || south_run$review_result != 'Full acceptance' ||
    south_run$assessment_model != 'BAM' ||
    nrow(mid_run) != 1L || mid_run$assessment_year != 2024L ||
    mid_run$last_data_year != 2023L || mid_run$review_result != 'Full acceptance' ||
    mid_run$assessment_model != 'WHAM')
  stop('NOAA Stock SMART run metadata differs from the reviewed snapshot.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  list(
    candidate_id = 'NOAA:10384',
    candidate_unit_id = 'noaa_golden_tilefish_south_atlantic',
    match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2025 SEDAR 89 Rev2 BAM uses fleet removals and age compositions for',
      'commercial handline and longline, with modeled ages 1-20+; recreational',
      'landings are also included. SEDAR89-WP-06 documents commercial age and',
      'length-composition construction. Sample sizes and observed/fitted fleet',
      'composition figures are reported; some annual matrices need digitization.'),
    survey_age_evidence = paste(
      'The BAM fits aggregate commercial longline and fishery-independent MARMAP',
      'longline abundance indices. MARMAP age compositions are also used; the',
      'report provides sample sizes and observed/fitted composition figures.',
      'No directly age-specific abundance index was identified.'),
    weights_evidence = paste(
      'SEDAR 89 Table 6 reports age-specific whole and gutted weights for model',
      'ages 1-20+, alongside length, sex ratio, maturity, egg production and M.'),
    maturity_evidence = paste(
      'SEDAR89-WP-03 documents reproductive sampling and maturity modeling.',
      'The assessment converts female maturity-at-length to age and reports',
      'age-specific maturity and egg production in Table 6.'),
    mortality_evidence = paste(
      'The base model uses fixed age-specific M, with the Lorenzen M-at-age',
      'relationship described in the report and numeric values in Table 6.',
      'Natural-mortality uncertainty is also represented in the MCBE ensemble.'),
    timing_evidence = paste(
      'The model is annual, with numbers-at-age at the start of year and SSB at',
      'peak spawning (15 May, 0.37 year). The annual MARMAP index does not state',
      'a fractional observation time; verify this detail rather than assigning',
      'the spawning date to the survey.'),
    output_evidence = paste(
      'Tables 7-8 report annual abundance-at-age (1000 fish) and biomass-at-age',
      '(mt) for 1972-2022; Table 10 reports annual SSB, recruitment and apical F.',
      'MCBE outputs provide uncertainty for derived assessment quantities.'),
    detailed_source_url = paste(c(sources$url[1:3],
      'https://sedarweb.org/assessments/sedar-89-south-atlantic-tilefish/',
      'https://apps-st.fisheries.noaa.gov/stocksmart/'), collapse = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'Eligible for source curation as a distinct new NOAA South Atlantic unit.',
      'NOAA Stock SMART identifies the latest accepted BAM run as assessment',
      '14290 (2025; terminal year 2022). The public report and SEDAR89-WP-06',
      'document age compositions, catch/abundance inputs and age-specific',
      'biology; the report includes numeric N-at-age and annual outputs.',
      'Age-composition matrices need source extraction/digitization, and MARMAP',
      'fractional observation timing remains to be verified. This is a source',
      'screen only; no canonical assessment data are created.'),
    notes = paste(
      'Keep separate from NOAA:10385 Mid-Atlantic and NOAA:10383 Gulf units.',
      'NOAA identifies three management stocks; the South Atlantic assessment',
      'uses its own regional unit. SEDAR 89 Rev2 describes data through 2022',
      'and uses ages 1-20+.')
  ),
  list(
    candidate_id = 'NOAA:10385',
    candidate_unit_id = 'noaa_golden_tilefish_mid_atlantic',
    match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2024 management-track WHAM assessment uses commercial catch and',
      'catch age compositions for ages 1-10+, with an age-length key developed',
      'for 2009 onward and earlier pooled keys. Commercial discards and',
      'recreational landings were added. SASINF input figures show the annual',
      'catch-composition series; exact arrays need digitization or file recovery.'),
    survey_age_evidence = paste(
      'No fishery-independent abundance index is included in the 2024 model.',
      'The assessment uses annual commercial longline CPUE indices; SASINF shows',
      'three aggregate index series. Catch age compositions provide age data,',
      'but index and catch matrices are published mainly as figures.'),
    weights_evidence = paste(
      'The SASINF final input report shows annual age-specific weights for SSB,',
      'January 1 biomass, catch and each fleet/index, for ages 1-10+. The public',
      'values are chart-based and require extraction.'),
    maturity_evidence = paste(
      'The SASINF final input report plots the maturity-at-age schedule for',
      'ages 1-10+. The exact vector is not tabulated in the reviewed files.'),
    mortality_evidence = paste(
      'Age-specific natural mortality is shown for ages 1-10+ in the final WHAM',
      'input report. The review discusses age-dependent M as a sensitivity;',
      'exact vector construction and values need extraction during curation.'),
    timing_evidence = paste(
      'The model uses annual commercial CPUE indices and no fishery-independent',
      'survey index, so no separate within-year survey fraction is reported.',
      'Preserve the annual index convention and document any timing approximation'),
    output_evidence = paste(
      'The assessment summary reports SSB (mt), fully selected F at age 6, and',
      'age-1 recruitment (thousands) for 2014-2023. SASINF final results show',
      'N-at-age, SSB-at-age, F and recruitment trajectories; aggregate output',
      'CVs are plotted.'),
    detailed_source_url = paste(c(sources$url[4:8],
      'https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php',
      'https://www.fisheries.noaa.gov/species/golden-tilefish',
      'https://www.mafmc.org/safe-report/tilefish'), collapse = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'Eligible for source curation as a distinct new NOAA Mid-Atlantic unit.',
      'Stock SMART identifies the 2024 WHAM assessment (assessment 13544,',
      'terminal year 2023) as fully accepted. The peer-review panel found it',
      'technically sufficient and BSIA for management. NOAA SASINF exposes final',
      'input and results reports with age-structured data and population outputs',
      'for ages 1-10+. Most source series are chart-based and require digitization;',
      'the public report remains labeled draft, a publication-status caveat.'),
    notes = paste(
      'Keep separate from South Atlantic NOAA:10384. The 2024 peer-review report',
      'confirms the management-track run was used for advice, with data through',
      '2023. The SASINF archive contains reports and graphics rather than a',
      'native fitted model/data object; exact input arrays need recovery.')
  )
)

expected_ids <- vapply(review, function(x) x[['candidate_id']], character(1L))
rows <- match(expected_ids, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) ||
    any(candidates$scientific_name[rows] != 'Lopholatilus chamaeleonticeps') ||
    candidates$stock_name[rows[1L]] != 'Tilefish - Southern Atlantic Coast' ||
    candidates$stock_name[rows[2L]] != 'Tilefish - Mid-Atlantic Coast' ||
    as.integer(candidates$inventory_assessment_year[rows[1L]]) != 2025L ||
    as.integer(candidates$inventory_assessment_year[rows[2L]]) != 2024L)
  stop('Expected NOAA Stock SMART South and Mid-Atlantic golden tilefish rows.', call. = FALSE)

unit_ids <- vapply(review, function(x) x[['candidate_unit_id']], character(1L))
if (anyDuplicated(unit_ids) ||
    any(candidates$candidate_unit_id[-rows] %in% unit_ids, na.rm = TRUE) ||
    any(grepl('tilefish', stocks$common_name, ignore.case = TRUE), na.rm = TRUE))
  stop('A golden tilefish unit conflicts with a canonical stock or candidate unit.', call. = FALSE)
if (any(assessments$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(inputs$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(outputs$assessment_id %in% unit_ids, na.rm = TRUE))
  stop('This discovery screen must not create canonical assessment data.', call. = FALSE)

for (j in seq_along(review)) {
  i <- rows[j]
  if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
      !candidates$screening_status[i] %in% c('not_started', 'screened') ||
      !candidates$eligibility[i] %in% c('unresolved', 'eligible'))
    stop('Golden tilefish inventory row has a conflicting review status.', call. = FALSE)
  for (column in names(review[[j]])) candidates[[column]][i] <- review[[j]][[column]]
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- i + 1L
  if (length(line_feeds) < physical_line) stop('Candidate CSV row is out of range.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(candidates[i, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}
cat('Screened NOAA South and Mid-Atlantic golden tilefish sources.\n')