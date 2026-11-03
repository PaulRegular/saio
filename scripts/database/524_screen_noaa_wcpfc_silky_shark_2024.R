root <- "."
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_silky_shark_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
expected <- c('WCPFC_SC20-SA-WP-04_2024_Rev2.pdf',
  'WCPFC21-2024-27_Status_of_fisheries_and_stocks_Rev02.pdf',
  'WCPFC_SC14-SA-WP-08a_2018_silky_shark_addendum.pdf',
  'WPFMC_Pelagic_FEP_SAFE_Report_2024.pdf')
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      file.info(path)$size != as.numeric(manifest$bytes[i]))
    stop('A pinned silky shark source is missing or differs from its manifest: ', file, call. = FALSE)
}
e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'), e)
s <- e$stock_assessment_summary
s <- s[as.character(s$stock_id) == '11728', , drop = FALSE]
latest <- s[which.max(as.integer(s$assessment_year)), , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_id != 13564L ||
    latest$assessment_year != 2024L || latest$last_data_year != 2022L ||
    latest$science_center != 'PIFSC' || latest$assessment_model != 'SS' ||
    latest$model_version != 'V.30.22.1' || latest$review_result != 'Full acceptance')
  stop('Stock SMART no longer identifies NOAA:11728 as reviewed.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:11728'
unit_id <- 'wcpfc_wcpo_silky_shark'
row <- which(register$candidate_id == id)
if (length(row) != 1L || register$scientific_name[row] != 'Carcharhinus falciformis' ||
    any(stocks$scientific_name == 'Carcharhinus falciformis', na.rm = TRUE))
  stop('WCPO silky shark identity conflicts with the register or canonical database.', call. = FALSE)
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('WCPO silky shark candidate-unit key conflicts with another candidate.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id, match_status = 'new', screening_status = 'screened',
  eligibility = 'ineligible', import_status = 'not_started',
  catch_age_evidence = paste('The 2024 assessment used reconstructed catch histories and observed length compositions in its Stock Synthesis model; the WCPFC report describes catch-at-length fits, not catch-at-age or age-composition likelihoods. The 2018 WCPO-only addendum likewise used catch, CPUE and aggregated length compositions. Age-structured population dynamics do not supply observed age inputs.'),
  survey_age_evidence = paste('The 2024 assessment used annual standardized fishery CPUE indices as aggregate abundance indices; WCPFC21 identifies 2020 as the latest usable index year. The indices are not age-specific.'),
  weights_evidence = paste('The assessment uses length-based growth and weight biology. No observed or model-input weight-at-age series was verified for the advised assessment.'),
  maturity_evidence = paste('The 2024 report uses life-history assumptions, including maturity at about ages 5-6. No source maturity-at-age observations or complete age-specific input vector was verified.'),
  mortality_evidence = paste('Natural mortality and other life-history quantities enter as model assumptions or priors. The recommended dynamic surplus-production advice does not estimate an age-specific M surface.'),
  timing_evidence = paste('The assessment series are annual; no within-year survey timing fraction applies to the aggregate fishery CPUE indices.'),
  output_evidence = paste('The 2024 report and WCPFC21 review provide aggregate depletion, harvest-rate and catch/status results, with substantial uncertainty and no projections. The integrated Stock Synthesis assessment had unresolved challenges and the LAM was experimental; the report recommends the dynamic surplus-production model as the most robust basis for advice. WPFMC’s 2024 SAFE report says the 2024 assessment did not provide reliable biomass and fishing-mortality estimates relative to MSY and retains the 2018 assessment as a status reference. No age-specific output series from an advised model was recovered.'),
  detailed_source_url = paste('https://meetings.wcpfc.int/node/23088',
    'https://meetings.wcpfc.int/file/16838/download', 'https://meetings.wcpfc.int/node/10691',
    'https://www.wpcouncil.org/wp-content/uploads/2025/07/Pelagic-FEP-SAFE-Report-2024-V2.pdf',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=11728&stockname=Silky+shark+-+Western+and+Central+Pacific', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Ineligible for the age-disaggregated input screen. Stock SMART lists assessment 13564 (2024, data through 2022; Stock Synthesis V.30.22.1) as Full acceptance, while WCPFC’s detailed report recommends the dynamic surplus-production model for management advice because the integrated assessment had unresolved problems and describes LAM as experimental. Inputs are catch histories, aggregate CPUE and length compositions; neither the current run nor the 2018 WCPO-only reference provides verified catch-at-age or age-composition inputs. Age-structured model states do not replace observed age data. WPFMC’s 2024 SAFE report records that the 2024 run did not provide reliable biomass and fishing-mortality estimates relative to MSY and retains the 2018 assessment as a status reference. The current detailed 2024 assessment remains documented; the older run is not used to fill its source gaps.'),
  notes = paste('NOAA Stock SMART ID 11728 maps to the Western and Central Pacific silky shark unit, Carcharhinus falciformis; no matching canonical stock is present. Stock SMART identifies assessment 13564 (2024; data through 2022; PIFSC; SS V.30.22.1; Full acceptance). The WCPFC-SC20 report recommends DSPM for management advice and labels LAM experimental; WCPFC21 documents substantial uncertainty and caution. WPFMC’s 2024 SAFE report says the 2024 assessment did not provide reliable B/F estimates relative to MSY and retains the 2018 assessment as a reference. This difference in assessment status is retained rather than silently resolved. Cached PDFs, retrieval dates, source URLs, sizes and SHA-256 hashes are in source_cache/discovery_noaa_wcpfc_silky_shark_2024/sources.csv. No canonical records were added.')
)
blank_unit <- is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row])
initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' && blank_unit
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('age-disaggregated input screen', register$decision_reason[row], fixed = TRUE)
if (!initial && !reviewed) stop('WCPO silky shark candidate has an unexpected prior review state.', call. = FALSE)
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], id)
  }
}
cat('Screened NOAA 11728 WCPO silky shark as ineligible for age-disaggregated source curation.\n')
