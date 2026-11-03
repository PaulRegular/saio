root <- "."
cache <- file.path(root, 'source_cache', 'noaa_ocean_quahog_2020')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$stock_id) == '10788' &
    as.integer(stocksmart$assessment_id) == 10663L, , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.integer(assessment$assessment_year) != 2020L ||
    as.integer(assessment$last_data_year) != 2019L ||
    as.character(assessment$assessment_model) != 'SS' ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    as.character(assessment$jurisdiction) != 'MAFMC' ||
    as.character(assessment$assessment_type) != 'Operational')
  stop('NOAA Stock SMART metadata do not match the reviewed 2020 ocean quahog update.',
    call. = FALSE)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source_file <- 'OceanQuahogUpdateMT2020.pdf'
source_row <- manifest[manifest$file == source_file, , drop = FALSE]
source_path <- file.path(cache, source_file)
if (nrow(source_row) != 1L || !file.exists(source_path) ||
    !grepl('^[[:xdigit:]]{64}$', source_row$sha256) ||
    source_row$url != paste0('https://www.mafmc.org/s/',
      '8_ocean_quahog_Update_2020_07_27_113541-k6xk.pdf'))
  stop('The official ocean quahog report is missing from cache or provenance.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10788'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one ocean quahog Stock SMART register row.', call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_ocean_quahog_atlantic',
  assessment_area = 'Atlantic Coast; MAFMC ocean quahog stock',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2020 update reports annual commercial assessment catch',
    'in metric tonnes through 2019, with landings and discards by north/south area.',
    'It does not report catch numbers-at-age or age-composition observations.'),
  survey_age_evidence = paste('The report shows NEFSC clam-survey biomass indices for',
    'northern and southern areas through 2016: Research Set-Aside indices in kg per tow',
    'and MCD indices in swept-area numbers, with approximate 90% log-normal intervals.',
    'No age-specific index is reported.'),
  weights_evidence = paste('The 2017 benchmark describes growth and weight-at-length',
    'biology, but the reviewed current assessment products do not provide a recoverable',
    'annual weights-at-age input.'),
  maturity_evidence = paste('The benchmark includes a maturity ogive in the Stock Synthesis',
    'model, but the reviewed 2020 materials do not provide its numeric age-specific',
    'values as an input table.'),
  mortality_evidence = paste('The 2017 benchmark reports natural mortality fixed at 0.02.',
    'The 2020 update carries forward the benchmark model without other changes beyond',
    'updating Stock Synthesis.'),
  timing_evidence = paste('The 2020 report identifies survey series and years but does not',
    'provide a within-year timing fraction for the survey observations.'),
  output_evidence = paste('The 2020 update reports aggregate SSB (3,651 thousand tonnes in',
    '2019), fully selected F (0.005 in 2019), normalized age-3 recruitment summaries,',
    'and aggregate survey fits. It does not report annual N-at-age, F-at-age, or M-at-age.'),
  detailed_source_url = paste(
    'https://www.mafmc.org/s/8_ocean_quahog_Update_2020_07_27_113541-k6xk.pdf;',
    'https://repository.library.noaa.gov/view/noaa/14203/noaa_14203_DS1.pdf;',
    'https://repository.library.noaa.gov/view/noaa/14209'),
  review_date = review_date,
  decision_reason = paste('Ineligible for the age-disaggregated source set: the 2020',
    'operational update uses commercial catch totals, length compositions, and',
    'aggregate biomass indices. Its age-structured Stock Synthesis model does not',
    'provide age-specific observed inputs or the age-specific population outputs',
    'required for this comparison. The 2020 source PDF is marked as a draft working',
    'paper for peer review only, although Stock SMART records Full acceptance and',
    'NOAA still identifies stock status as supported by the 2020 assessment.'),
  notes = paste('NOAA Stock SMART ID 10788; assessment 10663, 2020, last data year',
    '2019. This is the current operational update of the 2017 benchmark located in',
    'the reviewed sources. The benchmark explicitly notes that age data are scarce;',
    'its statistical catch-at-age structure is not evidence of observed catch-at-age',
    'likelihood inputs. No canonical numerical records were added.'),
  stringsAsFactors = FALSE)

current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) &&
    identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    candidates$import_status[i] == 'not_started' &&
    (is.na(candidates$candidate_unit_id[i]) ||
      !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine)
    stop('Unexpected existing review state for NOAA:10788.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA ocean quahog ID 10788 as ineligible for the age-disaggregated candidate set.\n')
