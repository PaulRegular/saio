root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_iattc_striped_marlin_2010')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:11073'
unit_id <- 'iattc_northeast_pacific_striped_marlin'

expected_sources <- data.frame(
  source_id = c('iattc_striped_marlin_assessment_2010',
    'iattc_striped_marlin_status_2009'),
  file = c('SAC-01-10_Striped-marlin-assessment.pdf',
    'No-11-2011_Status-of-the-tuna-and-billfish-stocks-in-2009.pdf'),
  url = c(
    'https://www.iattc.org/GetAttachment/5130105a-ad6e-486b-9e42-a206b0638667/SAC-01-10_Striped-marlin-assessment.pdf',
    'https://www.iattc.org/GetAttachment/158a8a63-d94b-4bc5-a1ed-5ac43265f8e9/No-11-2011_Status-of-the-tuna-and-billfish-stocks-in-2009.pdf'
  ),
  retrieved_at = c('2026-10-31', '2026-10-31'),
  bytes = c(804007L, 9406835L),
  sha256 = c(
    '5BF0CC31D4773046214DB14D8FDD52BEBCF7BB6A87FE8784B2ED8F4AFF81D233',
    '561A45D649A9B7E642BC8C72542FC349BACDB510F87937764D9F24B81480403E'
  ),
  pinned_revision = c(
    'IATTC SAC-01-10, assessment data and outlook available in 2010',
    'IATTC Stock Assessment Report No. 11 (2011), striped marlin status through 2009; model information available 30 October 2010'
  ),
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
for (column in names(expected_sources)) {
  actual <- as.character(manifest[[column]])
  expected <- as.character(expected_sources[[column]])
  if (!identical(actual, expected))
    stop('Cached IATTC striped marlin manifest differs in ', column, '.', call. = FALSE)
}
for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      !identical(sha256_file(path), expected_sources$sha256[i]) ||
      !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
    stop('Cached IATTC striped marlin source differs from its manifest: ',
      expected_sources$file[i], call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 11073 &
  stocksmart$assessment_year == 2010, , drop = FALSE]
if (nrow(run) != 1L || run$assessment_id != 5266L ||
    run$last_data_year != 2008L || run$assessment_model != 'SS' ||
    run$review_result != 'Full acceptance' ||
    run$assessment_type != 'Full Update' ||
    run$stock_name != 'Striped marlin - Eastern Pacific')
  stop('NOAA Stock SMART metadata differs from the screened IATTC assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '11073' ||
    candidates$scientific_name[row] != 'Kajikia audax' ||
    candidates$stock_name[row] != 'Striped marlin - Eastern Pacific' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '11073', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Kajikia audax', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('IATTC striped marlin identity conflicts with the candidate register or database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Northeast Pacific (IATTC northern EPO; north of 5 degrees S and east of 145 degrees W)',
  catch_age_evidence = paste(
    'The 2010 assessment uses annual catch/removals by fishery and length compositions.',
    'The detailed IATTC report explicitly says no age-at-length data were available;',
    'no catch-at-age or population age composition was identified.'
  ),
  survey_age_evidence = paste(
    'The model uses standardized aggregate longline CPUE indices. These are fishery',
    'indices, not seasonal surveys, and are not age-specific.'
  ),
  weights_evidence = paste(
    'The report provides a fixed length-weight relationship and growth assumptions,',
    'but no observed age-specific weight input matrix.'
  ),
  maturity_evidence = paste(
    'The assessment assumes 50 percent mature at age 2 and all mature thereafter;',
    'this is a model assumption rather than an observed maturity-at-age input series.'
  ),
  mortality_evidence = 'Natural mortality was fixed at M = 0.5 per year.',
  timing_evidence = paste(
    'Abundance indices are fishery CPUE rather than seasonal surveys; a survey',
    'timing fraction is not applicable.'
  ),
  output_evidence = paste(
    'The report publishes annual spawning biomass and recruitment through 2009,',
    'aggregate stock-status results, fishery F and average F-at-age by period.',
    'Annual N-at-age and annual F-at-age surfaces were not identified.'
  ),
  detailed_source_url = paste(c(expected_sources$url,
    'https://www.fisheries.noaa.gov/species/striped-marlin'), collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'The latest NOAA-listed Eastern Pacific striped marlin assessment is the IATTC',
    '2010 Stock Synthesis run. Its reported population observations are catch, aggregate',
    'CPUE and length compositions; the report explicitly states that no age-at-length',
    'data were available. Length data alone do not verify a defensible catch-at-age',
    'reconstruction, so the unit is ineligible for this age-disaggregated source set.'
  ),
  notes = paste(
    'IATTC describes the unit as the northern EPO/northeast Pacific, bounded north',
    'of 5 degrees S and east of 145 degrees W. The separate NOAA western and central',
    'Pacific striped marlin inventory row is not the same unit. No canonical values',
    'were added and no tinyAM translation was attempted. Reports are cached under',
    'source_cache/discovery_noaa_iattc_striped_marlin_2010/.'
  )
)

current <- lapply(names(review), function(column)
  as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) ||
    !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('NOAA eastern Pacific striped marlin candidate already has a conflicting review state.',
    call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:11073 as a new but ineligible IATTC northeast Pacific striped marlin unit.\n')
