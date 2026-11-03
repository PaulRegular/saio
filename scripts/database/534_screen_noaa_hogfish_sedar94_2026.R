root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

common_sources <- paste(
  'https://sedarweb.org/assessments/sedar-94-florida-hogfish/;',
  'https://sedarweb.org/documents/sedar-94-florida-hogfish-west-florida-shelf-stock-east-florida-florida-keys-stock-final-stock-assessment-report/;',
  'https://sedarweb.org/documents/sedar-94-rw-keys-data-methods-results/;',
  'https://sedarweb.org/documents/sedar-94-rw-west-florida-shelf-data-methods-results-presentation-part-1/;',
  'https://sedarweb.org/documents/sedar-94-dw-11-length-and-age-composition-of-florida-hogfish-lachnolaimus-maximus-collected-in-association-with-fishery-dependent-projects/;',
  'https://sedarweb.org/documents/sedar-94-dw-19-indices-of-abundance-for-gulf-and-atlantic-hogfish-lachnolaimus-maximus-using-data-from-multiple-video-surveys/;',
  'https://sedarweb.org/documents/sedar-94-dw-22-standardized-reef-visual-census-indices-for-hogfish-lachnolaimus-maximus-for-southeast-florida-2013-2024-the-florida-keys-1997-2024-and-dry-tortugas-1999-2024/;',
  'https://safmc.net/wp-content/uploads/2025/01/SG-FMP-SAFE-Report-for-html.html;',
  'https://www.fisheries.noaa.gov/southeast/commercial-fishing/2026-preliminary-south-atlantic-commercial-landings',
  sep = ' ')

review <- data.frame(
  candidate_id = c('NOAA:12808', 'NOAA:12809', 'NOAA:12810'),
  candidate_unit_id = c('noaa_hogfish_west_florida',
    'noaa_hogfish_keys_east_florida', 'noaa_hogfish_georgia_north_carolina'),
  match_status = 'new',
  screening_status = 'screened',
  eligibility = c('unresolved', 'unresolved', 'ineligible'),
  import_status = 'not_started',
  catch_age_evidence = c(
    paste('SEDAR 94 is an age-structured Stock Synthesis assessment and uses',
      'conditional age-at-length data, but the available fishery-dependent age',
      'paper summarizes 847 aged fish rather than publishing the run-matched',
      'likelihood arrays. Catch-at-age reconstruction has not been verified.'),
    paste('SEDAR 94 is an age-structured Stock Synthesis assessment and uses',
      'conditional age-at-length data, but the available fishery-dependent age',
      'paper summarizes 847 aged fish rather than publishing the run-matched',
      'likelihood arrays. Catch-at-age reconstruction has not been verified.'),
    paste('The current Georgia-through-North-Carolina unit has no accepted',
      'age-structured production assessment. The latest regional management',
      'review reports an attempted assessment lacked sufficient information; only',
      'landings and a landings-based catch recommendation were available.')
  ),
  survey_age_evidence = c(
    paste('The production assessment uses aggregate video and RVC abundance',
      'indices with length or size-composition information. Its conditional',
      'age-at-length likelihood includes commercial, recreational, and',
      'fishery-independent research sources; these are not age-specific',
      'abundance-index observations. No age-specific survey series or',
      'defensible reconstruction has been verified.'),
    paste('The production assessment uses aggregate video and RVC abundance',
      'indices with length or size-composition information. Its conditional',
      'age-at-length likelihood includes commercial, recreational, and',
      'fishery-independent research sources; these are not age-specific',
      'abundance-index observations. No age-specific survey series or',
      'defensible reconstruction has been verified.'),
    paste('No population abundance index or age-composition likelihood was',
      'located for this current unit; available management information is',
      'landings-based.')
  ),
  weights_evidence = c(
    'SEDAR 94 documents growth, length-weight, and weight-at-age construction; the run-matched numeric biological input vectors have not yet been extracted.',
    'SEDAR 94 documents growth, length-weight, and weight-at-age construction; the run-matched numeric biological input vectors have not yet been extracted.',
    'No run-specific weights-at-age were identified for the current unit.'
  ),
  maturity_evidence = c(
    'The SEDAR 94 base model uses a fixed female age-maturity relationship; exact numeric run inputs have not yet been extracted.',
    'The SEDAR 94 base model uses a fixed female age-maturity relationship; exact numeric run inputs have not yet been extracted.',
    'No age-specific maturity schedule was identified for the current unit.'
  ),
  mortality_evidence = c(
    'SEDAR 94 fixes an age-specific Lorenzen mortality vector derived from the external growth and length-weight relationships; exact numeric run inputs have not yet been extracted.',
    'SEDAR 94 fixes an age-specific Lorenzen mortality vector derived from the external growth and length-weight relationships; exact numeric run inputs have not yet been extracted.',
    'No age-specific natural-mortality assumptions were identified for the current unit.'
  ),
  timing_evidence = c(
    'The assessment is annual and assumes spawning on January 1; survey-specific fractional-year observation timing has not been recovered.',
    'The assessment is annual and assumes spawning on January 1; survey-specific fractional-year observation timing has not been recovered.',
    'No population observation timing applies to the landings-only management information.'
  ),
  output_evidence = c(
    paste('The final report and review presentation show population estimates and',
      'stock-recruitment, spawning-biomass, and fishing-mortality results.',
      'Run-matched numerical N-at-age and F-at-age output tables or files have',
      'not been located in the reviewed public materials.'),
    paste('The final report and review presentation show population estimates and',
      'stock-recruitment, spawning-biomass, and fishing-mortality results.',
      'Run-matched numerical N-at-age and F-at-age output tables or files have',
      'not been located in the reviewed public materials.'),
    'No population or mortality outputs were identified for the current unit; its catch advice is based on landings rather than an age-structured assessment.'
  ),
  detailed_source_url = common_sources,
  review_date = '2026-11-02',
  decision_reason = c(
    paste('Eligibility remains unresolved: SEDAR 94 is a current age-structured',
      'assessment with conditional age-at-length data, but the reviewed public',
      'materials do not provide the run-matched numeric age-at-length inputs or',
      'machine-readable age-specific abundance-index and population-output',
      'series needed to verify a source-ready age-disaggregated dataset.'),
    paste('Eligibility remains unresolved: SEDAR 94 is a current age-structured',
      'assessment with conditional age-at-length data, but the reviewed public',
      'materials do not provide the run-matched numeric age-at-length inputs or',
      'machine-readable age-specific abundance-index and population-output',
      'series needed to verify a source-ready age-disaggregated dataset.'),
    paste('Ineligible for age-disaggregated source curation: the current',
      'Georgia-through-North-Carolina unit has no accepted production assessment',
      'with age-structured inputs or population outputs. SEDAR 94 assesses the',
      'separate West Florida Shelf and Florida Keys/East Florida units.')
  ),
  notes = c(
    paste('The 2018 NOAA inventory label Eastern Gulf of Mexico is represented',
      'by the current West Florida Shelf assessment unit. SEDAR 94 is the latest',
      'benchmark through 2024. No canonical assessment or input/output values',
      'were added. The final report is cached in',
      'source_cache/discovery_noaa_sedar_current_assessments_2026; DW-11, DW-19,',
      'and DW-22 are cached in source_cache/discovery_noaa_hogfish_sedar94_2026.'),
    paste('The 2014 NOAA inventory label Florida Keys / East Florida maps to',
      'the current Florida Keys/East Florida assessment unit. SEDAR 94 is the',
      'latest benchmark through 2024. No canonical assessment or input/output',
      'values were added. The final report is cached in',
      'source_cache/discovery_noaa_sedar_current_assessments_2026; DW-11, DW-19,',
      'and DW-22 are cached in source_cache/discovery_noaa_hogfish_sedar94_2026.'),
    paste('This remains a distinct current management stock, also called',
      'Georgia-through-North-Carolina (GA-NC); it is not one of the two SEDAR 94',
      'assessment units. The NOAA inventory lists a 2014 assessment attempt,',
      'but the latest regional source says a stock assessment lacked sufficient',
      'information. No canonical assessment or values were added.')
  ),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA hogfish candidate identifiers are duplicated.', call. = FALSE)
if (anyDuplicated(review$candidate_unit_id))
  stop('NOAA hogfish assessment units must remain distinct.', call. = FALSE)

blank <- function(x) length(x) != 1L || is.na(x) || !nzchar(x)
is_same <- function(x, y) {
  x <- as.character(x)
  y <- as.character(y)
  length(x) == length(y) && all((is.na(x) & is.na(y)) |
    (!is.na(x) & !is.na(y) & x == y))
}
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  unchanged <- all(vapply(setdiff(names(review), 'candidate_id'),
    function(name) is_same(register[[name]][row_index], review[[name]][i]),
    logical(1L)))
  if (!initial && !unchanged)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  for (name in setdiff(names(review), 'candidate_id'))
    register[[name]][row_index] <- review[[name]][i]
  if (!unchanged && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened three NOAA hogfish inventory rows against current SEDAR 94 and stock-boundary sources.\n')
