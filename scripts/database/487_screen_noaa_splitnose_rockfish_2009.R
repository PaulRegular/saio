root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_splitnose_rockfish_2009')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10564'
unit_id <- 'noaa_pacific_splitnose_rockfish_coastwide'
files <- c('assessment.pdf', 'star_review.pdf', 'stock_structure_review_2025.pdf',
  'groundfish_safe_2025.pdf', 'ssc_minutes_2025.pdf')
urls <- c(
  'https://www.pcouncil.org/documents/2009/10/status-of-the-u-s-splitnose-rockfish-sebastes-diploproa-resource-in-2009-october-28-2009.pdf',
  'https://www.pcouncil.org/documents/2009/05/splitnose-rockfish-star-panel-report-may-2009.pdf',
  'https://www.pcouncil.org/documents/2025/02/h-6-attachment-3-stock-structure-literature-review.pdf',
  'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/',
  'https://www.pcouncil.org/documents/2025/12/ssc-sept-2025-minutes-adopted-final.pdf/')
revisions <- c(
  'PFMC final 2009 assessment; model data through 2008',
  'PFMC STAR review, May 4-8 2009',
  'PFMC stock-structure literature review, February 2025',
  'PFMC Pacific Coast Groundfish SAFE, July 2025; assessment summary',
  'PFMC Scientific and Statistical Committee adopted September 2025 minutes')
paths <- file.path(cache, files)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA splitnose rockfish sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
source_rows <- match(files, sources$file)
if (anyNA(source_rows)) stop('A cached NOAA source is missing from its manifest.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)),
  dates = all(sources$retrieved_on[source_rows] == '2026-10-31'))
if (!all(source_valid)) stop('Cached NOAA source manifest failed verification.', call. = FALSE)

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (!file.exists(stocksmart_path)) stop('The cached Stock SMART inventory is required.', call. = FALSE)
stocksmart <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart)
metadata <- stocksmart$stock_assessment_summary
metadata <- metadata[metadata$stock_id == 10564, , drop = FALSE]
if (nrow(metadata) != 1L || metadata$scientific_name != 'Sebastes diploproa' ||
    metadata$assessment_year != 2009L || metadata$last_data_year != 2008L ||
    metadata$stock_area != 'Pacific Coast' || metadata$review_result != 'Full acceptance' ||
    metadata$model_version != '3.02E')
  stop('Cached Stock SMART metadata no longer confirms the reviewed 2009 run.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != '10564' ||
    register$scientific_name[row] != 'Sebastes diploproa' ||
    register$assessment_area[row] != 'Pacific Coast' ||
    register$inventory_assessment_year[row] != 2009L ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('NOAA splitnose rockfish inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10564', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$stock_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical splitnose rockfish records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2009 base model uses reconstructed fishery removals and length compositions, not fishery age compositions.',
    'California trawl age observations from 1980-1981 and 1983-1985 were converted to conditional age-at-length data,',
    'but were excluded from the base model after double-read comparisons showed highly inconsistent ageing; they were',
    'retained only for a sensitivity run. No accepted-run fishery catch-at-age series is reported.'),
  survey_age_evidence = paste('NWFSC shelf-slope survey conditional age-at-length data by sex and year were included for 2003-2008.',
    'AFSC triennial age data (1977, 1980, 1989) were generated but excluded from the base model because age precision',
    'and ageing-error information were inadequate; they appear only in sensitivity analyses. The assessment uses four',
    'aggregate survey biomass-index series, not directly fitted age-specific abundance indices.'),
  weights_evidence = paste('The report estimates sex-specific weight-length relationships from NWFSC shelf-slope samples',
    '(1,787 females and 1,962 males): female W=0.00002*L^3.0139 and male W=0.00002*L^2.9684, with W in kg and fork',
    'length in cm. Growth-at-age is estimated by sex. No observed annual weight-at-age matrix is reported.'),
  maturity_evidence = paste('Female maturity-at-length is estimated logistically from Oregon/California fishery data and the',
    'AFSC slope survey: L50=21.84 cm and slope coefficient beta=-0.5683. The source notes sparse maturity information; no',
    'observed annual maturity-at-age matrix is reported.'),
  mortality_evidence = 'Natural mortality is fixed at M=0.048 per year for females and males in the base model.',
  timing_evidence = paste('The model is annual and uses four surveys and three fisheries. The report does not establish',
    'within-year fractional timing values for those observations; timing remains unresolved.'),
  output_evidence = paste('The 2009 report provides annual fitted numbers-at-age by sex and aggregate spawning output,',
    'recruitment, depletion, and fishing/exploitation results. These are fitted outputs and do not replace missing',
    'accepted-run fishery age inputs.'),
  detailed_source_url = paste(c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10564', urls),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The 2009 assessment, using data through 2008, remains the latest full production run: the 2025',
    'SAFE and September 2025 SSC minutes still list 2009 as the most recent assessment, and the PFMC stock-structure',
    'review identifies it as the 2009 coastwide benchmark. Although the assessment has survey conditional age-at-length',
    'and fitted numbers-at-age, its fishery age compositions were rejected from the base model and kept only for a',
    'sensitivity run. The accepted base therefore lacks fishery catch-at-age inputs required for this age-disaggregated',
    'source set.'),
  notes = paste('One coastwide U.S. Pacific Coast assessment unit is used; north/south management apportionments do not',
    'establish separate biological assessment units. The 2009 report contains many model outputs but no source-supported',
    'accepted-run fishery catch-at-age. No canonical stock, assessment, input, or output records were added and no tinyAM',
    'translation was attempted. Official sources and provenance are cached in',
    'source_cache/discovery_noaa_splitnose_rockfish_2009/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' && register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible' &&
  register$import_status[row] == 'not_started'
if (!initial && !reviewed) stop('NOAA splitnose rockfish candidate row has a conflicting review state.', call. = FALSE)

for (name in names(review)) register[[name]][row] <- review[[name]]
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts/database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}
cat('Screened NOAA Pacific Coast splitnose rockfish as ineligible for age-disaggregated source curation; canonical data remain unchanged.\n')
