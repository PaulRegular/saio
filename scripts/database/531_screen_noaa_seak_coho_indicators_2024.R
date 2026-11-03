root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

source_urls <- paste(
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10339',
  'https://www.adfg.alaska.gov/FedAidPDFs/ROP.CF.1J.2023.04.pdf',
  'https://www.fisheries.noaa.gov/species/coho-salmon/science',
  'https://www.adfg.alaska.gov/index.cfm?adfg=commercialbyareasoutheast.salmon_research_hughsmith',
  'https://www.adfg.alaska.gov/index.cfm?adfg=commercialbyareasoutheast.salmon_research_bernersriver',
  sep = '; ')

review <- data.frame(
  candidate_id = c('NOAA:10959', 'NOAA:10960', 'NOAA:10961'),
  candidate_unit_id = c('noaa_coho_berners_river',
    'noaa_coho_ford_arm_lake_discontinued', 'noaa_coho_hugh_smith_lake'),
  match_status = rep('new', 3L),
  screening_status = rep('screened', 3L),
  eligibility = rep('ineligible', 3L),
  import_status = rep('not_started', 3L),
  catch_age_evidence = c(
    'The 2024 status determination tables report aggregate total catch, total run, target catch and productive capacity through 2024. They do not report catch numbers-at-age. Coded-wire-tag recoveries and age samples support aggregate stock contribution estimates, not a catch-at-age input likelihood.',
    'NOAA reports that assessment of this fourth long-term indicator stock was discontinued in 2016. The remaining Stock SMART record is historical and is outside the current assessment-unit screen.',
    'The 2024 status determination tables report aggregate total catch, total run, target catch and productive capacity through 2024. They do not report catch numbers-at-age. Coded-wire-tag recoveries and age samples support aggregate stock contribution estimates, not a catch-at-age input likelihood.'),
  survey_age_evidence = c(
    'Berners River escapement is estimated from standardized surveys. The reviewed assessment reports aggregate abundance/run quantities, not age-specific survey abundance observations.',
    'No current assessment was located after the stock assessment program ended in 2016; age-specific index evidence is not applicable to a current assessment unit.',
    'Hugh Smith Lake uses weir counts and mark-recapture for escapement. The 2024 assessment reports aggregate run and escapement quantities, not an age-specific survey abundance index.'),
  weights_evidence = c(
    'ADF&G monitoring collects length and weight from subsampled fish, but the reviewed NOAA production assessment does not identify a run-matched weight-at-age input surface.',
    'The discontinued historical assessment record does not provide a current run-matched weight-at-age input.',
    'ADF&G monitoring collects length and weight from subsampled fish, but the reviewed NOAA production assessment does not identify a run-matched weight-at-age input surface.'),
  maturity_evidence = c(
    'No run-matched maturity-at-age input is reported in the 2024 production assessment.',
    'No current assessment or run-matched maturity-at-age input is available for this discontinued assessment unit.',
    'No run-matched maturity-at-age input is reported in the 2024 production assessment.'),
  mortality_evidence = c(
    'The slanted hockey-stick assessment reports aggregate fishing-mortality rates and escapement productivity measures, not age-specific F or M surfaces.',
    'No current age-specific mortality process is estimated for this discontinued historical unit.',
    'The slanted hockey-stick assessment reports aggregate fishing-mortality rates and escapement productivity measures, not age-specific F or M surfaces.'),
  timing_evidence = rep(
    'The status determination uses annual run and harvest summaries. No fractional within-year timing for an age-specific abundance index is specified.',
    3L),
  output_evidence = c(
    'The 2024 report provides total run, harvest-rate, escapement, and productive-capacity series through 2024. It does not report annual abundance-at-age, fishing-mortality-at-age, or recruitment-at-age.',
    'No current production outputs are reported after assessment was discontinued in 2016.',
    'The 2024 report provides total run, harvest-rate, escapement, and productive-capacity series through 2024. It does not report annual abundance-at-age, fishing-mortality-at-age, or recruitment-at-age.'),
  detailed_source_url = rep(source_urls, 3L),
  review_date = rep('2026-11-02', 3L),
  decision_reason = c(
    'Ineligible for the age-disaggregated set: the current assessment is a slanted hockey-stick run/harvest analysis with aggregate catch and escapement summaries. Available age samples are monitoring data for escapement and are not reported as age-specific catch or abundance likelihood inputs.',
    'Not a current assessment unit: NOAA states that the Ford Arm coho assessment program was eliminated in 2016. Keep the Stock SMART row as a discontinued historical inventory identity; do not create a current canonical stock or assessment record.',
    'Ineligible for the age-disaggregated set: the current assessment is a slanted hockey-stick run/harvest analysis with aggregate catch and escapement summaries. Available age samples are monitoring data for escapement and are not reported as age-specific catch or abundance likelihood inputs.'),
  notes = c(
    'NOAA identifies Berners River as one of three current full Southeast Alaska coho indicator stocks. The official 2024 status determination includes updated data through 2024; the assessment table is aggregate, not an age-structured population surface.',
    'The official 2024 NOAA report says assessment of Ford Arm Lake, a fourth long-term indicator stock, was eliminated in 2016 because of state budget cuts. This row is retained for audit completeness but is excluded from current-unit counts and canonical data work.',
    'NOAA identifies Hugh Smith Lake as one of three current full Southeast Alaska coho indicator stocks. The official 2024 status determination includes updated data through 2024; the assessment table is aggregate, not an age-structured population surface.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (any(review$candidate_unit_id %in%
    register$candidate_unit_id[!register$candidate_id %in% review$candidate_id]))
  stop('A reviewed candidate unit is already assigned to another inventory row.',
    call. = FALSE)

blank <- function(x) is.na(x) || !nzchar(x)
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
  reviewed <- old$match_status == review$match_status[i] &&
    old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
    old$import_status == 'not_started' &&
    identical(unit, as.character(review$candidate_unit_id[i]))
  if (!initial && !reviewed)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  for (name in setdiff(names(review), 'candidate_id'))
    register[[name]][row_index] <- review[[name]][i]
  same <- all(vapply(names(register), function(name) {
    x <- register[[name]][row_index]
    y <- old[[name]]
    if (is.na(x)) is.na(y) else !is.na(y) &&
      identical(as.character(x), as.character(y))
  }, logical(1L)))
  if (!same && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened three NOAA Southeast Alaska coho inventory records using the 2024 status determination.\n')
