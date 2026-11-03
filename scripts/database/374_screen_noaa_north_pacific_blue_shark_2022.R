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
assessment <- stocksmart[stocksmart$stock_id == 11686L &
  stocksmart$assessment_id == 13026L, , drop = FALSE]
if (nrow(assessment) != 1L || assessment$assessment_year != 2022L ||
    assessment$last_data_year != 2020L || assessment$science_center != 'PIFSC' ||
    assessment$review_result != 'Full acceptance' || assessment$assessment_model != 'SS' ||
    assessment$final_assessment_report_1 !=
      'STOCK ASSESSMENT AND FUTURE PROJECTIONS OF BLUE SHARKS IN THE NORTH PACIFIC OCEAN THROUGH 2020') {
  stop('The pinned NOAA Stock SMART snapshot does not match the reviewed North Pacific blue shark record.',
    call. = FALSE)
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

candidate_id <- 'NOAA:11686'
candidate_unit_id <- 'noaa_blue_shark_north_pacific'
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L) {
  stop('North Pacific blue shark candidate is missing or duplicated.', call. = FALSE)
}
if (!identical(register$scientific_name[row], 'Prionace glauca') ||
    !identical(register$stock_name[row], 'Blue shark - North Pacific') ||
    !identical(register$assessment_area[row], 'North Pacific')) {
  stop('North Pacific blue shark inventory identity does not match Stock SMART.', call. = FALSE)
}
if (!is.na(register$matched_stock_id[row]) && nzchar(register$matched_stock_id[row])) {
  stop('A North Pacific blue shark candidate has a canonical match requiring review.', call. = FALSE)
}
if (any(stocks$scientific_name == 'Prionace glauca' &
    grepl('North Pacific', paste(stocks$area, stocks$region), ignore.case = TRUE), na.rm = TRUE)) {
  stop('A North Pacific blue shark canonical stock already exists; review before updating.',
    call. = FALSE)
}
if (any(grepl('North Pacific blue shark', c(assessments$assessment_id, inputs$assessment_id,
    outputs$assessment_id), ignore.case = TRUE), na.rm = TRUE)) {
  stop('Unexpected North Pacific blue shark canonical records found; review before updating.',
    call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == candidate_unit_id, na.rm = TRUE)) {
  stop('Candidate unit key already belongs to another inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2022 assessment uses annual total catch for multiple fleets from 1971-2020; fleet catches are mostly metric tons, with three Hawaii fleets in thousands of fish. No catch-at-age likelihood is documented.',
  survey_age_evidence = 'The model uses annual CPUE abundance indices from 1976-2020 and sex-specific length compositions from 1979-2020. Inputs are not age-specific indices or age compositions.',
  weights_evidence = 'Biological inputs support size- and age-structured population calculations, but no recoverable weight-at-age observation series is documented for the model likelihood.',
  maturity_evidence = 'The assessment incorporates updated reproductive life-history information; no maturity-at-age input series is used as an observation likelihood.',
  mortality_evidence = 'The fully integrated SS3 model is age- and sex-structured and estimates annual fishing mortality and spawning-stock biomass; natural mortality and recruitment assumptions are biological model inputs.',
  timing_evidence = 'Catch, CPUE and length-composition data are annual. No age-specific survey index with fractional-year timing is used.',
  output_evidence = 'The official report provides annual aggregate SSB, fishing mortality and age-0 recruitment, management quantities, projections, and ensemble uncertainty. Numeric N-at-age and F-at-age output arrays were not located in the public report or Stock SMART record.',
  detailed_source_url = paste(
    'https://isc.fra.go.jp/pdf/ISC22/ISC22_ANNEX12_Stock_Assessment_for_Blue_Shark.pdf',
    'https://isc.fra.go.jp/pdf/SHARK/ISC22_SHARK_2/ISC_22_SHARKWG_2_4.pdf',
    'https://isc.fra.go.jp/recommendation/isc22/isc22_blueshark.html',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11686', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest fully accepted PIFSC entry is the 2022 ISC benchmark assessment through 2020. Its SS3 population is age- and sex-structured, but likelihood inputs are catch totals, CPUE and length compositions rather than age-disaggregated observations.',
    'Annual age-specific population output arrays were not located, so it does not meet the current candidate-set evidence threshold.'),
  notes = paste(
    'The North Pacific ISC stock is distinct from NOAA:10689 North Atlantic blue shark and the South Pacific stock.',
    'NOAA Stock SMART ID 11686 links to ISC Annex 12, adopted in 2022. No canonical stock, assessment, input, or output records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- identical(as.character(register$match_status[row]), review$match_status) &&
  identical(as.character(register$screening_status[row]), review$screening_status) &&
  identical(as.character(register$eligibility[row]), review$eligibility) &&
  identical(ifelse(is.na(register$candidate_unit_id[row]), '', register$candidate_unit_id[row]),
    review$candidate_unit_id)
if (!initial && !reviewed) stop('North Pacific blue shark has an unexpected prior review state.',
  call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  for (name in names(review)) register[[name]][row] <- review[[name]]
  tmp <- tempfile(fileext = '.csv')
  write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}

cat('Screened NOAA Stock SMART 11686 against the fully accepted 2022 ISC North Pacific blue shark assessment; it is ineligible for the age-disaggregated candidate set.\n')