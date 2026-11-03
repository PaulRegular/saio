root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_alaska_aggregates_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-02'

spec <- data.frame(
  stock_id = c('10973', '10974', '11405', '11448', '11803', '11804'),
  assessment_id = c('11254', '13871', '13123', '13122', '13893', '13100'),
  assessment_year = c(2020L, 2024L, 2023L, 2023L, 2024L, 2023L),
  last_data_year = c(2020L, 2024L, 2023L, 2023L, 2024L, 2023L),
  candidate_unit_id = c('noaa_bsai_other_flatfish_complex',
    'noaa_bsai_other_rockfish_complex', 'noaa_alaska_sculpin_complex',
    'noaa_alaska_sculpin_complex',
    'noaa_goa_other_shallow_water_flatfish_complex',
    'noaa_goa_other_rockfish_complex'),
  area = c('Bering Sea and Aleutian Islands', 'Bering Sea and Aleutian Islands',
    'Bering Sea and Aleutian Islands', 'Gulf of Alaska', 'Gulf of Alaska',
    'Gulf of Alaska'),
  stringsAsFactors = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
for (j in seq_len(nrow(spec))) {
  assessment <- stocksmart[as.character(stocksmart$assessment_id) == spec$assessment_id[j], , drop = FALSE]
  if (nrow(assessment) != 1L || as.character(assessment$stock_id) != spec$stock_id[j] ||
      as.integer(assessment$assessment_year) != spec$assessment_year[j] ||
      as.integer(assessment$last_data_year) != spec$last_data_year[j] ||
      as.character(assessment$review_result) != 'Full acceptance' ||
      as.integer(assessment$model_category) != 2L)
    stop('NOAA Stock SMART metadata do not match reviewed stock ', spec$stock_id[j], '.', call. = FALSE)
}

files <- c('BSAI_Other_Flatfish_SAFE_2024.pdf',
  'BSAI_Other_Rockfish_SAFE_2024.pdf', 'GOA_Other_Rockfish_SAFE_2024.pdf',
  'GOA_Shallow_Water_Flatfish_SAFE_2024.pdf',
  'NOAA_Alaska_Sculpin_Ecosystem_Report_2023.pdf',
  'BSAI_SAFE_Introduction_2024.pdf', 'GOA_SAFE_Introduction_2024.pdf',
  'SSC_Final_Report_December_2023.pdf', 'SSC_Final_Report_December_2024.pdf', 'StockSMART_DataDictionary.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) || !all(file.exists(file.path(cache, files))))
  stop('The NOAA Alaska aggregate assessment source cache is incomplete.', call. = FALSE)
source_rows <- manifest[match(files, manifest$file), , drop = FALSE]
if (anyNA(source_rows$sha256) ||
    !all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)) ||
    anyNA(source_rows$url) || anyNA(source_rows$revision))
  stop('Cached source provenance is incomplete.', call. = FALSE)
pdf_headers <- vapply(file.path(cache, files), function(path) {
  con <- file(path, 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_headers)) stop('A cached assessment source is not a PDF.', call. = FALSE)

rows <- list(
  data.frame(candidate_unit_id = spec$candidate_unit_id[1], assessment_area = spec$area[1],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2024 BSAI SAFE describes an index-based complex assessment and does not provide a fishery catch-numbers-at-age series.',
    survey_age_evidence = 'Survey biomass and composition metadata are reported, but the reviewed assessment does not establish an annual age-specific abundance index. Stock SMART composition-input score 1 denotes major gaps and does not establish an age likelihood.',
    weights_evidence = 'An age-specific weight surface for the assessed complex was not verified in the reviewed production report.',
    maturity_evidence = 'An age-specific maturity schedule for the assessed complex was not verified in the reviewed production report.',
    mortality_evidence = 'No age-structured mortality input is used by the index-based complex assessment.',
    timing_evidence = 'Annual bottom-trawl survey biomass is reported.',
    output_evidence = 'The SAFE reports complex-level survey biomass and catch/status quantities, not annual N-at-age, F-at-age, or SSB outputs.',
    detailed_source_url = paste('https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIoflat.pdf',
      'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIintro.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = "Stock SMART's latest listed full-acceptance record is assessment 11254 (2020, data through 2020), but the 2024 SAFE and SSC final report document a newer 2024 operational update. The update incorporates catches and survey biomass and uses REMA for aggregate biomass; the SSC supported its harvest recommendations. The reviewed inputs and outputs do not establish age-specific catch, abundance, biology, or population outputs required for an age-structured comparison.",
    notes = 'Stock SMART lists 2020 as the latest row; the official 2024 update is the more recent production assessment. Alaska plaice and flathead sole are assessed separately after removal from this residual complex; do not treat those species as evidence of age data for the remaining complex.', stringsAsFactors = FALSE),
  data.frame(candidate_unit_id = spec$candidate_unit_id[2], assessment_area = spec$area[2],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2024 BSAI Other Rockfish SAFE does not provide a catch-numbers-at-age input series.',
    survey_age_evidence = 'The assessment estimates exploitable biomass from trawl-survey biomass and observation errors; an annual age-specific abundance index is not reported. Stock SMART composition-input score 1 is not evidence of an age likelihood.',
    weights_evidence = 'Age-specific weights were not identified in the reviewed assessment report.',
    maturity_evidence = 'Age-specific maturity was not identified in the reviewed assessment report.',
    mortality_evidence = 'The survey-based random-effects biomass assessment does not use an age-structured mortality surface.',
    timing_evidence = '',
    output_evidence = 'The report provides complex-level biomass estimates and status information, not N-at-age, F-at-age, or SSB trajectories.',
    detailed_source_url = paste('https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=BSAI+Other+Rockfish++2024.pdf&p=3bf7a4e8-904c-420f-a95f-0efe07afcef2.pdf',
      'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIintro.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = 'The latest reviewed full-acceptance Stock SMART record is assessment 13871 (2024, data through 2024).',
    notes = 'Stock SMART 10974. The official report is the November 2024 Plan Team assessment document.', stringsAsFactors = FALSE),
  data.frame(candidate_unit_id = spec$candidate_unit_id[3], assessment_area = spec$area[3],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2023 sculpin ecosystem report tracks catch and survey trends; it does not provide fishery catch-at-age observations.',
    survey_age_evidence = 'The combined report summarizes survey biomass trends and aggregate catch. Stock SMART composition-input score 2 does not verify an age-specific index used by the report.',
    weights_evidence = 'Age-specific weights for an assessment likelihood were not identified in the ecosystem report.',
    maturity_evidence = 'Age-specific maturity for an assessment likelihood was not identified in the ecosystem report.',
    mortality_evidence = 'The ecosystem report does not fit an age-structured mortality process.',
    timing_evidence = 'Survey trend information is annual; a within-year timing fraction was not reported.',
    output_evidence = 'The report presents ecosystem-component abundance and catch trends, not fitted N-at-age, F-at-age, or SSB outputs.',
    detailed_source_url = paste('https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/sculpin.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2023_FINAL.pdf&p=7b0daa09-749d-4794-9a18-894865bd08d2.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = 'The latest reviewed full-acceptance Stock SMART record is assessment 13123 (2023, data through 2023). The regional entry is covered by a shared BSAI/GOA sculpin ecosystem report, which summarizes survey and catch trends but does not provide age-structured inputs or fitted population outputs.',
    notes = 'Stock SMART 11405. BSAI and GOA sculpin rows 11405 and 11448 share one ecosystem-report candidate unit and must not be counted as two independent assessments.', stringsAsFactors = FALSE),
  data.frame(candidate_unit_id = spec$candidate_unit_id[4], assessment_area = spec$area[4],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2023 sculpin ecosystem report tracks catch and survey trends; it does not provide fishery catch-at-age observations.',
    survey_age_evidence = 'The combined report summarizes survey biomass trends and aggregate catch. Stock SMART composition-input score 2 does not verify an age-specific index used by the report.',
    weights_evidence = 'Age-specific weights for an assessment likelihood were not identified in the ecosystem report.',
    maturity_evidence = 'Age-specific maturity for an assessment likelihood was not identified in the ecosystem report.',
    mortality_evidence = 'The ecosystem report does not fit an age-structured mortality process.',
    timing_evidence = 'Survey trend information is annual; a within-year timing fraction was not reported.',
    output_evidence = 'The report presents ecosystem-component abundance and catch trends, not fitted N-at-age, F-at-age, or SSB outputs.',
    detailed_source_url = paste('https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/sculpin.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2023_FINAL.pdf&p=7b0daa09-749d-4794-9a18-894865bd08d2.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = 'The latest reviewed full-acceptance Stock SMART record is assessment 13122 (2023, data through 2023). The regional entry is covered by a shared BSAI/GOA sculpin ecosystem report, which summarizes survey and catch trends but does not provide age-structured inputs or fitted population outputs.',
    notes = 'Stock SMART 11448. BSAI and GOA sculpin rows 11405 and 11448 share one ecosystem-report candidate unit and must not be counted as two independent assessments.', stringsAsFactors = FALSE),
  data.frame(candidate_unit_id = spec$candidate_unit_id[5], assessment_area = spec$area[5],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2024 GOA shallow-water flatfish update does not provide fishery catch-at-age inputs.',
    survey_age_evidence = 'The current Tier 5 complex uses a random-effects model to estimate biomass from GOA bottom-trawl survey biomass. No age-specific abundance index is provided.',
    weights_evidence = 'Age-specific weights for the complex were not verified in the reviewed current SAFE.',
    maturity_evidence = 'Age-specific maturity for the complex was not verified in the reviewed current SAFE.',
    mortality_evidence = 'The survey-based random-effects biomass method is not an age-structured mortality model.',
    timing_evidence = 'Annual GOA bottom-trawl survey biomass is used; a within-year timing fraction was not verified.',
    output_evidence = 'The report provides complex biomass estimates, not age-specific population outputs or SSB trajectories.',
    detailed_source_url = paste('https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAshallowflat.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+SAFE+Introduction.pdf&p=ab2770e7-ed6f-4a2f-a69d-5cbd0bda1896.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = 'The latest reviewed full-acceptance Stock SMART record is assessment 13893 (2024, data through 2024). The current residual complex is assessed with survey-based biomass methods and does not provide the age-specific inputs or outputs required for an age-structured comparison.',
    notes = 'Stock SMART 11803. The report distinguishes Tier 3 northern and southern rock sole from the residual Tier 5 other shallow-water flatfish complex.', stringsAsFactors = FALSE),
  data.frame(candidate_unit_id = spec$candidate_unit_id[6], assessment_area = spec$area[6],
    matched_stock_id = NA_character_, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The latest detailed GOA Other Rockfish SAFE describes catch updates and survey-based complex methods, not catch-at-age inputs.',
    survey_age_evidence = 'The 2023 full assessment uses survey abundance and random-effects methods for aggregate biomass; no age-specific abundance index was verified.',
    weights_evidence = 'Age-specific weights were not verified for the current residual complex.',
    maturity_evidence = 'Age-specific maturity was not verified for the current residual complex.',
    mortality_evidence = 'The complex uses survey-based biomass methods, not an age-structured mortality process.',
    timing_evidence = 'Annual trawl survey biomass is used; a within-year timing fraction was not verified.',
    output_evidence = 'The official material reports complex biomass and catch/status quantities, not annual N-at-age, F-at-age, or SSB outputs.',
    detailed_source_url = paste('https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=GOA+Other+Rockfish+2024.pdf&p=f71d8d41-5d34-4947-a7a6-e0466e00bc6b.pdf',
      'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+SAFE+Introduction.pdf&p=ab2770e7-ed6f-4a2f-a69d-5cbd0bda1896.pdf', sep = '; '),
    review_date = review_date,
    decision_reason = 'The latest full-acceptance Stock SMART assessment is 13100 (2023, data through 2023); the 2024 update reports catch changes and no new Tier 4/5 model because no new survey data were available. The reviewed biomass assessment does not supply age-structured inputs or outputs.',
    notes = 'Stock SMART 11804. The 2024 report retains the 2023 full assessment as the latest model-based result and separately notes species moved out of the complex.', stringsAsFactors = FALSE)
)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id)) stop('Duplicate candidate identifiers.', call. = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (j in seq_len(nrow(spec))) {
  candidate_id <- paste0('NOAA:', spec$stock_id[j])
  i <- match(candidate_id, candidates$candidate_id)
  if (is.na(i)) stop('Missing NOAA inventory row ', candidate_id, '.', call. = FALSE)
  row <- rows[[j]]
  current <- candidates[i, names(row), drop = FALSE]
  same <- all(vapply(names(row), function(name) {
    x <- current[[name]]; y <- row[[name]]
    if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
  }, logical(1L)))
  if (!same) {
    pristine <- candidates$match_status[i] == 'unreviewed' &&
      candidates$screening_status[i] == 'not_started' &&
      candidates$eligibility[i] == 'unresolved' &&
      candidates$import_status[i] == 'not_started' &&
      (is.na(candidates$candidate_unit_id[i]) || !nzchar(candidates$candidate_unit_id[i]))
    previous_screen <- candidates$candidate_unit_id[i] == row$candidate_unit_id &&
      candidates$match_status[i] == 'new' && candidates$screening_status[i] == 'screened' &&
      candidates$eligibility[i] == 'ineligible' && candidates$import_status[i] == 'not_started'
    if (!pristine && !previous_screen) stop('Unexpected existing review state for ', candidate_id, '.', call. = FALSE)
    for (name in names(row)) candidates[[name]][i] <- row[[name]]
    replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], candidate_id)
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Stock SMART IDs 10973, 10974, 11405, 11448, 11803, and 11804; five distinct candidate units are ineligible for age-structured source curation.\n')
