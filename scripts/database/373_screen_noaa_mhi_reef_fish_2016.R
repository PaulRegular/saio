root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (sha256_file(stocksmart_path) !=
    'AD47F9EEB240C2E77B2B952809A12C4FA739E3F0D39BEAB283B413FDBAEF76A8') {
  stop('The pinned NOAA Stock SMART snapshot is missing or changed.', call. = FALSE)
}
stocksmart_env <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary

species <- data.frame(
  candidate_id = paste0('NOAA:', c(12452L, 14617L:14623L)),
  candidate_unit_id = c(
    'noaa_mhi_giant_trevally',
    'noaa_mhi_twosaddle_goatfish',
    'noaa_mhi_kumu_goatfish',
    'noaa_mhi_spectacled_parrotfish',
    'noaa_mhi_bullethead_parrotfish',
    'noaa_mhi_regal_parrotfish',
    'noaa_mhi_palenose_parrotfish',
    'noaa_mhi_redlip_parrotfish'
  ),
  scientific_name = c(
    'Caranx ignobilis', 'Parupeneus insularis', 'Parupeneus porphyreus',
    'Chlorurus perspicillatus', 'Chlorurus sordidus', 'Scarus dubius',
    'Scarus psittacus', 'Scarus rubroviolaceus'
  ),
  stock_name = c(
    'Giant trevally - Main Hawaiian Islands',
    'Twosaddle goatfish - Main Hawaiian Islands',
    'Goatfish (Parupeneus porphyreus) - Main Hawaiian Islands',
    'Spectacled parrotfish - Main Hawaiian Islands',
    'Bullethead parrotfish - Main Hawaiian Islands',
    'Regal parrotfish - Main Hawaiian Islands',
    'Palenose parrotfish - Main Hawaiian Islands',
    'Redlip parrotfish - Main Hawaiian Islands'
  ),
  assessment_id = c(8942L, 7181L, 7182L, 7191L, 7190L, 7184L, 7185L, 7186L),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(species))) {
  row <- stocksmart[stocksmart$stock_id == as.integer(sub('NOAA:', '', species$candidate_id[i])) &
    stocksmart$assessment_id == species$assessment_id[i], , drop = FALSE]
  if (nrow(row) != 1L || row$assessment_year != 2017L || row$last_data_year != 2016L ||
      row$science_center != 'PIFSC' || row$review_result != 'Full acceptance' ||
      row$assessment_model != 'Mean length-spawning potential ratio' ||
      row$final_assessment_report_1 != 'Stock Assessment of the Coral Reef Fishes of Hawaii, 2016') {
    stop('The pinned NOAA Stock SMART snapshot does not match the reviewed MHI record: ',
      species$candidate_id[i], call. = FALSE)
  }
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

review_rows <- lapply(seq_len(nrow(species)), function(i) {
  list(
    candidate_unit_id = species$candidate_unit_id[i],
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = 'Fishery-dependent total catch estimates are used; the report does not document catch-at-age input.',
    survey_age_evidence = 'Fishery-independent diver surveys provide abundance and size-composition data; no age-specific abundance index is documented.',
    weights_evidence = 'The assessment uses length-based life-history relationships, not a recoverable weight-at-age input.',
    maturity_evidence = 'Maturity and spawning-potential calculations are based on life-history information and size; no maturity-at-age input is documented.',
    mortality_evidence = 'A length-based model estimates current fishing mortality; life-history assumptions support its age-structured population calculations. No annual age-specific mortality surface is reported.',
    timing_evidence = 'Catch, diver abundance, and size-composition observations are summarized over annual assessment periods; no age-index timing is applicable.',
    output_evidence = 'The report provides fishing mortality, SPR, F30, catch limits and stock-status calculations. It does not provide a comparable annual N-at-age or F-at-age series.',
    detailed_source_url = paste(
      'https://repository.library.noaa.gov/view/noaa/13291',
      paste0('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=',
        sub('NOAA:', '', species$candidate_id[i])), sep = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'The latest fully accepted PIFSC record links this MHI species stock to the 2016 report. Its evidence likelihoods are size-based and aggregate rather than age-disaggregated.',
      'Although an age-structured population calculation derives status metrics internally, the public assessment does not provide the age-specific observations and annual age surfaces required for the current candidate set.'),
    notes = paste(
      'Nadon (2017), PIFSC Technical Memorandum 60, assesses individual reef-fish stocks with data from 2003-2016.',
      'This candidate is one species-specific Main Hawaiian Islands management unit; it is not combined with Guam or other island-area stocks. No canonical assessment, input, or output records were added.')
  )
})
names(review_rows) <- species$candidate_id

rows <- match(species$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows)) stop('MHI reef-fish inventory IDs are missing or duplicated.',
  call. = FALSE)
if (any(!is.na(register$matched_stock_id[rows]) & nzchar(register$matched_stock_id[rows]))) {
  stop('An MHI reef-fish candidate has a canonical stock match requiring review.', call. = FALSE)
}
if (any(register$scientific_name[rows] != species$scientific_name)) {
  stop('An MHI reef-fish scientific name does not match the reviewed source.', call. = FALSE)
}
if (any(stocks$scientific_name %in% species$scientific_name)) {
  stop('A canonical stock already uses an MHI reef-fish scientific name; review before proceeding.',
    call. = FALSE)
}
if (any(grepl('Main Hawaiian Islands', c(assessments$assessment_id, inputs$assessment_id,
    outputs$assessment_id), ignore.case = TRUE), na.rm = TRUE)) {
  stop('Unexpected MHI reef-fish canonical records found; review matching before updating.',
    call. = FALSE)
}
for (i in seq_along(rows)) {
  other_units <- register$candidate_unit_id[-rows[i]]
  if (any(other_units == species$candidate_unit_id[i], na.rm = TRUE)) {
    stop('Candidate unit key already belongs to another inventory row: ',
      species$candidate_unit_id[i], call. = FALSE)
  }
}

initial <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
}, logical(1L))
reviewed <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  review <- review_rows[[species$candidate_id[i]]]
  identical(as.character(register$match_status[row]), review$match_status) &&
    identical(as.character(register$screening_status[row]), review$screening_status) &&
    identical(as.character(register$eligibility[row]), review$eligibility) &&
    identical(ifelse(is.na(register$candidate_unit_id[row]), '', register$candidate_unit_id[row]),
      review$candidate_unit_id)
}, logical(1L))
if (any(!initial & !reviewed)) stop('An MHI reef-fish candidate has an unexpected prior review state.',
  call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && any(initial)) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  for (i in which(initial)) {
    row <- rows[i]
    for (name in names(review_rows[[species$candidate_id[i]]])) {
      register[[name]][row] <- review_rows[[species$candidate_id[i]]][[name]]
    }
    tmp <- tempfile(fileext = '.csv')
    write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
    lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
    unlink(tmp)
  }
  writeLines(lines, register_path, useBytes = TRUE)
}

cat('Screened eight PIFSC Main Hawaiian Islands reef-fish rows from the fully accepted 2016 assessment; all are ineligible for the age-disaggregated candidate set.\n')