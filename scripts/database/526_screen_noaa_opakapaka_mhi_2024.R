root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'NOAA:12442'
unit_id <- 'noaa_opakapaka_mhi'
register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), e)
s <- e$stock_assessment_summary
s <- s[as.character(s$stock_id) == '12442', , drop = FALSE]
if (nrow(s) != 1L || s$assessment_id != 8020L || s$assessment_year != 2018L ||
    s$last_data_year != 2016L || s$review_result != 'Full acceptance' ||
    !grepl('Bayesian surplus production model', s$assessment_model, fixed = TRUE))
  stop('The NOAA:12442 Stock SMART assessment identity changed.', call. = FALSE)
if (any(grepl('Pristipomoides filamentosus', stocks$scientific_name, fixed = TRUE), na.rm = TRUE))
  stop('An opakapaka stock is already present in the canonical database.', call. = FALSE)

row <- match(id, register$candidate_id)
if (is.na(row)) stop('NOAA:12442 is absent from the candidate register.', call. = FALSE)
blank <- function(x) is.na(x) || !nzchar(x)
initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && blank(register$candidate_unit_id[row])
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible'
if (!initial && !reviewed) stop('NOAA:12442 has an unexpected prior review state.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'Stock SMART identifies the 2018 fully accepted model as Bayesian surplus production. The 2024 accepted Deep 7 benchmark supplemental opakapaka Stock Synthesis model uses total catch; no catch-at-age likelihood is documented.',
  survey_age_evidence = 'The 2024 supplemental model uses aggregate CPUE and BFISH relative-biomass indices, not age-specific indices or observed age-composition likelihoods.',
  weights_evidence = 'The supplemental Stock Synthesis model uses commercial weight compositions; the reviewed report does not document observed weight-at-age as a model input.',
  maturity_evidence = 'Life-history reproduction information is fixed in the supplemental model; maturity-at-age is not an observed age-specific likelihood input.',
  mortality_evidence = 'Natural mortality is fixed life-history information in the supplemental model; no estimated M-at-age output is reported for this candidate.',
  timing_evidence = 'The 2024 Deep 7 model uses July-June fishing years. Its BFISH observations are aggregate and do not have age-specific timing.',
  output_evidence = 'The accepted assessment reports aggregate biomass, harvest rate and stock status. The reviewed report does not provide stock-specific N-at-age or F-at-age for NOAA:12442.',
  detailed_source_url = paste(
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=12442',
    'https://repository.library.noaa.gov/view/noaa/56878/noaa_56878_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/30604/noaa_30604_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/17252/noaa_17252_DS1.pdf', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = 'The current fully accepted 2024 Deep 7 benchmark includes an auxiliary opakapaka Stock Synthesis model, but it uses total catch, aggregate abundance indices, length compositions and commercial weight compositions; observed age-specific input data are not documented. NOAA reports also describe the 2018 benchmark and 2021 update opakapaka models as Bayesian surplus-production models.',
  notes = 'Stock SMART lists opakapaka separately from the multispecies Deep 7 complex. The 2024 auxiliary species model is not counted as a separate accepted age-structured assessment. Age-related fixed life-history information and aggregate biomass outputs do not establish age-disaggregated input and output coverage. No canonical records were added.'
)
if (initial || reviewed) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], id)
  }
}
cat('Screened NOAA 12442 Main Hawaiian Islands opakapaka; age-disaggregated eligibility is ineligible.\n')
