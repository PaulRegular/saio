root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

cache_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), cache_env)
stock_smart <- cache_env$stock_assessment_summary

expected <- data.frame(
  candidate_id = c('NOAA:10670', 'NOAA:10674', 'NOAA:10676', 'NOAA:10677',
    'NOAA:10687', 'NOAA:10692', 'NOAA:10967', 'NOAA:10969',
    'NOAA:12130', 'NOAA:12131', 'NOAA:14141', 'NOAA:14142'),
  assessment_id = c(945, 6751, 7939, 956, 978, 4030, 944, 946, 5342, 5343, 5245, 5246),
  assessment_year = c(2007, 2016, 2018, 2007, 2007, 2013, 2006, 2007, 2011, 2011, 2013, 2013),
  review_result = c('Full acceptance', 'Full acceptance', 'Full acceptance',
    'Full acceptance', 'Full acceptance', 'Remand',
    'Reject - Results too uncertain to be considered adequate',
    'Full acceptance', 'Full acceptance',
    'Reject - Results too uncertain to be considered adequate',
    'Partial acceptance - Status determinations only',
    'Partial acceptance - Status determinations only'),
  model_pattern = c('age-structured production', 'ASCFM', 'Stock Synthesis',
    'age-structured production', 'BSP', 'age-structured production',
    'BSP', 'BSP', 'age-structured production', 'age-structured production',
    'age-structured', 'age-structured'),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(expected))) {
  row <- stock_smart[as.character(stock_smart$stock_id) ==
    sub('^NOAA:', '', expected$candidate_id[i]) &
    stock_smart$assessment_id == expected$assessment_id[i], , drop = FALSE]
  if (nrow(row) != 1L || row$assessment_year != expected$assessment_year[i] ||
      row$review_result != expected$review_result[i] ||
      !grepl(expected$model_pattern[i], row$assessment_model, ignore.case = TRUE)) {
    stop('NOAA Stock SMART identity changed for ', expected$candidate_id[i], '.',
      call. = FALSE)
  }
}

sedar13_url <- paste0('https://sedarweb.org/documents/',
  'sedar-13-final-stock-assessment-report-hms-small-coastal-sharks-',
  'atlantic-sharpnose-shark-bonnethead-shark-blacknose-shark-and-finetooth-shark/')
sedar11_url <- paste0('https://sedarweb.org/documents/',
  'sedar-11-final-stock-assessment-report-large-coastal-sharks-',
  'blacktip-shark-and-sandbar-shark/')
sedar21_atlantic_url <- paste0('https://sedarweb.org/documents/',
  'sedar-21-final-stock-assessment-report-hms-atlantic-blacknose-shark/')
sedar21_gulf_url <- paste0('https://sedarweb.org/documents/',
  'sedar-21-final-stock-assessment-report-hms-gulf-of-mexico-blacknose-shark/')
sedar21_dusky_update_url <- paste0('https://sedarweb.org/documents/',
  '2016-update-sedar-21-hms-dusky-shark/')
sedar21_sandbar_url <- paste0('https://sedarweb.org/documents/',
  'sedar-21-final-stock-assessment-report-hms-sandbar-shark/')
sedar34_sharpnose_url <- paste0('https://sedarweb.org/documents/',
  'sedar-34-final-stock-assessment-report-atlantic-sharpnose-shark/')
sedar34_bonnethead_url <- paste0('https://sedarweb.org/documents/',
  'sedar-34-final-stock-assessment-report-bonnethead-shark/')
sedar54_url <- paste0('https://sedarweb.org/documents/',
  'sedar-54-final-assessment-report-hms-sandbar-shark/')

review_row <- function(id, unit, match_status, catch, survey, weights,
                       maturity, mortality, timing, output, source_url,
                       reason, notes) {
  data.frame(candidate_id = id, candidate_unit_id = unit,
    match_status = match_status, screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = catch, survey_age_evidence = survey,
    weights_evidence = weights, maturity_evidence = maturity,
    mortality_evidence = mortality, timing_evidence = timing,
    output_evidence = output, detailed_source_url = source_url,
    review_date = '2026-11-02', decision_reason = reason,
    notes = notes, stringsAsFactors = FALSE)
}

age_selectivity <- paste(
  'The SEDAR 13 data report says length-frequency observations were converted',
  'to age frequencies using growth curves or age-length keys to estimate',
  'selectivity. They were not fitted as catch-at-age observations.' )
shark_indices <- paste(
  'The reviewed assessment uses aggregate CPUE or relative-effort series.',
  'Length/age samples inform selectivity and do not provide a year-by-age',
  'survey abundance likelihood.' )
life_history_weights <- paste(
  'Growth and length-weight relationships are described as biological inputs,',
  'but a run-specific annual weight-at-age series is not reported as an',
  'observation input. Any age weights would be derived from life-history',
  'equations, not observed weight-at-age samples.' )
life_history_maturity <- paste(
  'Age-specific maturity or fecundity is part of the life-history model and is',
  'reported through the assessment documentation; it is not an observed',
  'age-composition likelihood.' )
life_history_m <- paste(
  'Natural mortality is specified from life-history methods or age-specific',
  'schedules. It is a biological assumption, not an estimated M-at-age series',
  'supported as an independent input observation.' )
annual_timing <- paste(
  'Catch and abundance series are annual or season-specific. The reviewed',
  'assessment documentation does not provide a single source-supported',
  'fractional survey timing that maps to tinyAM.' )

reviews <- rbind(
  review_row('NOAA:10670', 'noaa_atlantic_sharpnose_combined', 'new',
    age_selectivity,
    shark_indices,
    life_history_weights,
    life_history_maturity,
    life_history_m,
    annual_timing,
    'The accepted SEDAR 13 age-structured production assessment reports age-based population and fishing-mortality results, including F-at-age figures. Those fitted outputs do not establish observed age-specific inputs.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10670', sedar13_url, sep = '; '),
    'Ineligible for age-input screening: source age frequencies were used to construct selectivity, not fitted as observed catch-at-age. The assessment output is age structured, but required age-disaggregated observations are absent.',
    'This 2007 Atlantic/Gulf combined unit is crosswalked to the later SEDAR 34 combined Atlantic sharpnose stock. The later Stock SMART region-specific records are status-only entries, not separate accepted regional model fits.'),
  review_row('NOAA:10674', 'noaa_dusky_shark_atlantic_gulf', 'new',
    'The 2016 SEDAR 21 update uses the Age-Structured Catch-Free Model because reported catches and discards are too uncertain. It does not fit catch numbers-at-age.',
    'The update uses relative effort and aggregate CPUE information, not age-specific survey abundance observations.',
    life_history_weights, life_history_maturity,
    'The ASCFM uses life-history mortality and age-specific fecundity assumptions; it is not an estimated M-at-age observation series.',
    annual_timing,
    'The report documents age-structured state and fishing-mortality trajectories, but there is no fitted catch-at-age likelihood and no complete official annual N-at-age/F-at-age table was verified for the update.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10674', sedar21_dusky_update_url, sedar13_url, sep = '; '),
    'Ineligible for age-input screening: the latest full update is explicitly catch-free and relies on relative effort/abundance and life-history information, not catch numbers-at-age.',
    'Stock SMART lists the 2016 update as fully accepted. The 2011 SEDAR 21 assessment is superseded by the update.'),
  review_row('NOAA:10676', 'noaa_sandbar_shark_atlantic_gulf', 'new',
    'The 2018 SEDAR 54 Stock Synthesis assessment uses aggregate catch and length compositions; no catch-at-age likelihood was identified.',
    'The model uses aggregate CPUE indices. Length compositions are fitted; the report does not identify an age-specific survey index or observed age-composition likelihood.',
    'The assessment includes growth and length-weight biological inputs. The report does not provide observed annual weight-at-age inputs.',
    'Maturity-at-age is a fixed life-history component of the Stock Synthesis model, not an observed age-composition input.',
    'Natural mortality is specified as a life-history/model assumption; no age-specific estimated M surface was verified.',
    annual_timing,
    'The accepted age- and length-structured Stock Synthesis assessment reports aggregate biomass, abundance and fishing-mortality results. Public age-specific population tables were not verified.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10676', sedar54_url, sedar21_sandbar_url, sep = '; '),
    'Ineligible for age-input screening: the latest accepted model fits catch, CPUE and length compositions, not observed age-specific data. An age-structured model label alone does not satisfy the input requirement.',
    'SEDAR 54 (2018) is the latest full accepted assessment in the NOAA inventory snapshot; SEDAR 21 is the preceding assessment.'),
  review_row('NOAA:10677', '', 'ambiguous',
    age_selectivity,
    shark_indices,
    life_history_weights,
    life_history_maturity,
    life_history_m,
    annual_timing,
    'The SEDAR 13 model reports age-structured population outputs, but the older combined unit was split into Atlantic and Gulf blacknose assessment units in SEDAR 21.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10677', sedar13_url, sedar21_atlantic_url, sedar21_gulf_url, sep = '; '),
    'The historical 2007 combined assessment is not a current-unit candidate and is ineligible for age-input screening. The 2011 assessment split the unit, so this row cannot be assigned one-to-one to either current stock.',
    'Keep this broad historical row unlinked; NOAA:12130 and NOAA:12131 represent the later Atlantic and Gulf units. Do not count this legacy row as an additional new stock.'),
  review_row('NOAA:10687', 'noaa_finetooth_shark_atlantic_gulf', 'new',
    'The accepted SEDAR 13 finetooth assessment uses catch in numbers by year, not catch numbers-at-age.',
    'Four aggregate CPUE series were available; no age-specific abundance-index likelihood was reported.',
    'The surplus-production model does not use a modelled age-specific weight series.',
    'Age-specific maturity is not part of the fitted surplus-production model input.',
    'The Bayesian surplus-production model estimates aggregate productivity and fishing mortality; no estimated M-at-age surface is used.',
    annual_timing,
    'SEDAR 13 reports annual total abundance and fishing-mortality trajectories for finetooth shark. The model is surplus-production, not age structured.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10687', sedar13_url, sep = '; '),
    'Ineligible: the official finetooth model is a Bayesian surplus-production model using total catch and aggregate CPUE, with no age-specific population model or observed age inputs.',
    'SEDAR 13 assessed finetooth as a distinct species, but its selected model was aggregate BSP rather than an age-structured model.'),
  review_row('NOAA:10692', 'noaa_bonnethead_atlantic_gulf_combined', 'new',
    'The SEDAR 34 assessment uses aggregate catches; age frequencies derived from length data informed selectivity, not a catch-at-age likelihood.',
    'The model uses aggregate CPUE indices. Survey age-frequency observations were not fitted as an age-specific index.',
    life_history_weights,
    'Maturity-at-age and pup production are life-history inputs described in the report.',
    life_history_m,
    'The assessment uses within-year/monthly dynamics, but a single survey fraction for the aggregate indices is not specified for tinyAM conversion.',
    'The report describes an age-structured model and population outputs, but NOAA Stock SMART marks the 2013 model as remanded. It is not a fully accepted age-specific output set.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10692', sedar34_bonnethead_url, sedar13_url, sep = '; '),
    'Ineligible: the age frequencies were used to construct selectivity rather than fitted as observed catch-at-age, and Stock SMART records the 2013 run as remanded.',
    'SEDAR 34 treated Atlantic and Gulf bonnethead as one assessment stock for this cycle and recommended considering a split in a later benchmark.'),
  review_row('NOAA:10967', 'noaa_atlantic_large_coastal_shark_complex', 'new',
    'The 2006 large-coastal-shark-complex assessment uses aggregate catch series; it does not provide species- and age-specific catch likelihood inputs for one stock.',
    'Aggregate CPUE series are used for complex/species status; no age-specific index for a single biological unit is defined.',
    'The complex-level BSP assessment has no single species-specific weight-at-age input.',
    'The complex-level assessment has no single species-specific maturity-at-age input.',
    'The selected complex assessment is Bayesian surplus production and has no M-at-age state.',
    annual_timing,
    'The report provides aggregate abundance and fishing-mortality/status estimates. No single age-specific population output exists for the multi-species complex.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10967', sedar11_url, sep = '; '),
    'Ineligible: the large coastal shark complex is a multi-species management complex assessed with a surplus-production model, not a single age-structured stock.',
    'NOAA Stock SMART marks the 2006 assessment as rejected because results were too uncertain; it is retained here as an inventory record, not treated as an accepted production output.'),
  review_row('NOAA:10969', 'noaa_atlantic_small_coastal_shark_complex', 'new',
    'The 2007 SEDAR 13 complex assessment uses aggregate catch and CPUE; species-specific age frequencies used elsewhere in the project do not constitute a complex catch-at-age likelihood.',
    'The complex is represented by aggregate indices and mixed-species data, not an age-specific abundance index for a single population.',
    'There is no single species-specific weight-at-age surface for the complex assessment.',
    'There is no single species-specific maturity-at-age surface for the complex assessment.',
    'The Stock SMART model is a BSP model; the complex has no M-at-age process.',
    annual_timing,
    'The complex assessment reports aggregate abundance and fishing-mortality outputs. Species-specific age-structured reports are separate units and cannot be substituted for the complex.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10969', sedar13_url, sep = '; '),
    'Ineligible: this inventory row is the multi-species small-coastal-shark complex and the selected model is aggregate BSP; it is not a single age-structured stock.',
    'SEDAR 13 also assessed several constituent species separately. Those species are not additional components of this complex row for the audit count.'),
  review_row('NOAA:12130', 'noaa_blacknose_shark_atlantic', 'new',
    'SEDAR 21 age frequencies from fishery lengths were used to construct selectivity curves; observed catch numbers-at-age were not fitted.',
    'The assessment uses aggregate CPUE and survey series. The reported length/age information is not an age-specific survey likelihood.',
    life_history_weights,
    'Maturity and fecundity at age are included as life-history inputs in the ASPM.',
    'The ASPM uses an age-specific life-history M schedule; it is not estimated from age-specific observations.',
    'The report models monthly fishing and annual abundance. The material reviewed does not provide one fractional timing for the observation series.',
    'The accepted assessment reports age-specific abundance and fishing-mortality results. This does not replace missing observed age-specific inputs.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=12130', sedar21_atlantic_url, sep = '; '),
    'Ineligible for age-input screening: SEDAR 21 uses length/age samples to specify selectivity, not as catch-at-age observations, and reports only aggregate CPUE likelihoods.',
    'This is the Atlantic blacknose unit established in SEDAR 21; keep it separate from the Gulf unit.'),
  review_row('NOAA:12131', 'noaa_blacknose_shark_gulf', 'new',
    'SEDAR 21 age frequencies from fishery lengths were used to construct selectivity curves; observed catch numbers-at-age were not fitted.',
    'The assessment uses aggregate CPUE and survey series. The reported length/age information is not an age-specific survey likelihood.',
    life_history_weights,
    'Maturity and fecundity at age are included as life-history inputs in the ASPM.',
    'The ASPM uses an age-specific life-history M schedule; it is not estimated from age-specific observations.',
    'The report models monthly fishing and annual abundance. The material reviewed does not provide one fractional timing for the observation series.',
    'The SEDAR 21 report presents age-based trajectories, but Stock SMART rejects the Gulf run because results are too uncertain; accepted comparable outputs were not verified.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=12131', sedar21_gulf_url, sep = '; '),
    'Ineligible: the model has no observed catch-at-age likelihood, and NOAA Stock SMART marks the 2011 Gulf blacknose run as rejected for uncertainty.',
    'This Gulf blacknose unit was split from the older broad Atlantic/Gulf inventory row. Retain its rejected assessment status when summarizing outputs.'),
  review_row('NOAA:14141', 'noaa_atlantic_sharpnose_combined', 'ambiguous',
    'Stock SMART classifies this regional entry as status determinations only. SEDAR 34 uses a single combined Atlantic/Gulf assessment and does not fit regional catch-at-age data.',
    'The SEDAR 34 model uses aggregate CPUE indices for the combined stock; the regional inventory entry has no separate accepted age-specific index.',
    life_history_weights,
    life_history_maturity,
    life_history_m,
    annual_timing,
    'This regional Stock SMART record is partial acceptance for status determinations only. SEDAR 34 reports one combined stock, not separate Atlantic age-specific output.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=14141', sedar34_sharpnose_url, sep = '; '),
    'Ineligible: this entry does not represent an independent accepted assessment, and SEDAR 34 explicitly combined Atlantic and Gulf sharpnose as one stock. No regional age-observation likelihood was found.',
    'Crosswalk to the combined Atlantic sharpnose candidate unit, but retain ambiguous match status because NOAA inventory IDs imply regional units while SEDAR 34 used one stock.'),
  review_row('NOAA:14142', 'noaa_atlantic_sharpnose_combined', 'ambiguous',
    'Stock SMART classifies this regional entry as status determinations only. SEDAR 34 uses a single combined Atlantic/Gulf assessment and does not fit regional catch-at-age data.',
    'The SEDAR 34 model uses aggregate CPUE indices for the combined stock; the regional inventory entry has no separate accepted age-specific index.',
    life_history_weights,
    life_history_maturity,
    life_history_m,
    annual_timing,
    'This regional Stock SMART record is partial acceptance for status determinations only. SEDAR 34 reports one combined stock, not separate Gulf age-specific output.',
    paste('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=14142', sedar34_sharpnose_url, sep = '; '),
    'Ineligible: this entry does not represent an independent accepted assessment, and SEDAR 34 explicitly combined Atlantic and Gulf sharpnose as one stock. No regional age-observation likelihood was found.',
    'Crosswalk to the combined Atlantic sharpnose candidate unit, but retain ambiguous match status because NOAA inventory IDs imply regional units while SEDAR 34 used one stock.')
)

for (i in seq_len(nrow(reviews))) {
  id <- reviews$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  blank <- function(x) is.na(x) || !nzchar(x)
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  old_unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
  reviewed <- old$match_status == reviews$match_status[i] &&
    old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
    old$import_status == 'not_started' &&
    identical(old_unit, as.character(reviews$candidate_unit_id[i]))
  if (!initial && !reviewed)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  if (initial) {
    for (name in setdiff(names(reviews), 'candidate_id'))
      register[[name]][row_index] <- reviews[[name]][i]
    if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
      replace_candidate_register_row(register_path, row_index,
        register[row_index, , drop = FALSE], id)
  }
}

cat('Screened 12 NOAA SEDAR shark inventory rows; no new row met the age-input eligibility rule.\n')
