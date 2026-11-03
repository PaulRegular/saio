root <- "."
cache <- file.path(root, 'source_cache', 'discovery_dfo_wcvi_barkley_sockeye_2024')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'DFO:Pacific:WCVI Barkley Sockeye Salmon'
unit_id <- 'dfo_wcvi_barkley_sockeye_smu'
source_url <- 'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-022-eng.pdf'

if (dir.exists(cache) && length(list.files(cache, pattern = 'Fs70-7-2026-022-eng.pdf$')) > 0L) {
  pdf <- file.path(cache, 'Fs70-7-2026-022-eng.pdf')
  if (!identical(rawToChar(readBin(pdf, 'raw', n = 4L)), '%PDF')) {
    unlink(pdf)
    stop('Removed a non-PDF response saved with a PDF extension; review web-archive response.', call. = FALSE)
  }
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected one DFO Barkley Sockeye inventory row.', call. = FALSE)

review <- list(
  scientific_name = 'Oncorhynchus nerka',
  candidate_unit_id = unit_id,
  match_status = 'new',
  matched_stock_id = NA_character_,
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'West Coast Vancouver Island, Barkley Sound Stock Management Unit (three Conservation Units)',
  catch_age_evidence = paste(
    'The 2024 report says age and stock composition are used in annual run-size',
    'reconstruction for three Conservation Units. It does not document a',
    'catch-at-age likelihood or provide a complete model input series of',
    'catch numbers by age; the age-composition role is part of salmon run',
    'reconstruction rather than an age-structured fishery population model.'
  ),
  survey_age_evidence = paste(
    'The assessment describes fishway counts, spawning-ground surveys, fence',
    'counts, fishery monitoring, lake acoustic and trawl fry surveys, and',
    'smolt ageing samples. It does not report an age-specific marine abundance',
    'index or an aggregate marine survey index paired with age composition.'
  ),
  weights_evidence = paste(
    'No model weight-at-age input is reported. The reviewed response reports',
    'run abundance, escapement, harvest, exploitation rate, and recruits per',
    'spawner, not age-specific population biomass.'
  ),
  maturity_evidence = paste(
    'No maturity-at-age input is reported. Adult spawner counts and',
    'stock-recruit reference points do not provide an age-specific maturity',
    'vector for a marine population model.'
  ),
  mortality_evidence = paste(
    'The response reports exploitation rates and management targets, but no',
    'age-specific fishing-mortality surface or natural-mortality assumption',
    'for an age-structured population model.'
  ),
  timing_evidence = paste(
    'Run-timing curves inform in-season forecasting and management. There is',
    'no marine survey observation series requiring a survey timing fraction.'
  ),
  output_evidence = paste(
    'DFO Science Response 2026/022, the peer-reviewed update of the 2024 assessment, presents time series of harvest, escapement, exploitation',
    'rate, and recruits per spawner for the aggregate SMU and its three CUs,',
    'plus reference points with 80% credible intervals. It does not report',
    'annual N-at-age, F-at-age, or an age-structured biomass surface.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/site/eng/9.962748/publication.html;',
    source_url,
    'https://publications.gc.ca/collections/collection_2024/mpo-dfo/Fs144-68-2024-eng.pdf',
    sep = ' '
  ),
  review_date = '2026-10-31',
  decision_reason = paste(
    'DFO identifies this as the latest 2024 Barkley Sockeye SMU assessment,',
    'but describes an index-based, stock-recruit, forecast, and run-reconstruction',
    'approach. Although age and stock composition enter annual salmon run',
    'reconstruction, the published assessment does not establish the complete',
    'age-specific catch, survey, biological, and mortality inputs or annual',
    '',
    'population translation. Screen ineligible for this age-disaggregated set.'
  ),
  notes = paste(
    'The SMU contains Great Central, Sproat, and Hucuktlis CUs; these remain',
    'components of one assessment unit. The 2026 Science Response says the last',
    'full assessment was in 2012 and the 2024 work was an interim update, but',
    'reports the peer-reviewed 2024 status and revised reference points.',
    'The official PDF is readable through the Government Publications page,',
    'but direct local retrieval returned an archived-page interstitial rather',
    'than the PDF, so it was not cached. No canonical inputs/outputs were added',
    'and was attempted. See',
    'discovery/source_reviews/dfo_wcvi_barkley_sockeye_2024.md.'
  )
)
for (column in names(review)) candidates[[column]][row] <- review[[column]]
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(candidate_path, row,
  candidates[row, , drop = FALSE], candidate_id)

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened the DFO WCVI Barkley Sockeye 2024 inventory row as ineligible for age-structured curation.\n')
