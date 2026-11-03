root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_atlantic_salmon_2025')
report_sha512 <- 'b8a424127e22f4f61da6e491b7290ac4fba92b14cca1d511b38c489f14cc9df0a2df5ecea581a1d608062cc7ff9e3da4c25a6343e3be60630e672459d69652fa'
database_sha256 <- 'a372d61fde09ec43c428d31ffcd2fdaca614b66609e4242a9f81dd29b68552be'

database_path <- file.path(cache, 'USASAC_database_2026-05.zip')
if (!file.exists(database_path))
  stop('The NOAA USASAC database snapshot is missing from the source cache.', call. = FALSE)

actual_database_sha256 <- if (.Platform$OS.type == 'windows') {
  result <- system2('certutil.exe', c('-hashfile', normalizePath(database_path), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  if (length(hashes) != 1L) stop('Could not verify the cached USASAC database.', call. = FALSE)
  tolower(hashes)
} else {
  result <- system2('sha256sum', shQuote(database_path), stdout = TRUE)
  sub('[[:space:]].*$', '', result[1L])
}
if (actual_database_sha256 != database_sha256)
  stop('The cached USASAC database checksum does not match its source record.', call. = FALSE)

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
latest <- metadata[metadata$stock_id == 10498, , drop = FALSE]
latest <- latest[order(-as.numeric(latest$assessment_year),
  -as.numeric(latest$assessment_id), na.last = TRUE), , drop = FALSE]
latest <- latest[1L, , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_year != 2024L ||
    latest$last_data_year != 2023L || latest$review_result != 'Full acceptance' ||
    latest$assessment_model != 'Index Method' ||
    latest$scientific_name != 'Salmo salar' || latest$stock_area != 'Gulf of Maine')
  stop('The pinned NOAA Stock SMART row for Gulf of Maine Atlantic salmon changed.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_id <- 'NOAA:10498'
unit_id <- 'noaa_atlantic_salmon_gom'
row_index <- which(register$candidate_id == candidate_id)
if (length(row_index) != 1L || any(stocks$scientific_name == 'Salmo salar', na.rm = TRUE) ||
    any(as.character(stocks$authority_stock_id) == '10498', na.rm = TRUE))
  stop('The NOAA Gulf of Maine salmon identity is missing, duplicated, or already canonicalized.', call. = FALSE)
if (any(register$organization == 'NOAA' & register$scientific_name == 'Salmo salar' &
    register$candidate_id != candidate_id, na.rm = TRUE))
  stop('Another NOAA Atlantic salmon candidate requires identity reconciliation first.', call. = FALSE)
if (any(unit_id %in% c(register$candidate_unit_id[-row_index], assessments$assessment_id,
    inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The Atlantic salmon candidate unit ID already exists.', call. = FALSE)

initial <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved' &
  (is.na(register$candidate_unit_id[row_index]) | !nzchar(register$candidate_unit_id[row_index]))
reviewed <- register$match_status[row_index] == 'new' &
  register$candidate_unit_id[row_index] == unit_id &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'ineligible'
if (!initial && !reviewed)
  stop('The Atlantic salmon candidate has a conflicting prior review.', call. = FALSE)

source_urls <- paste(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10498',
  'https://repository.library.noaa.gov/view/noaa/70571',
  'https://repository.library.noaa.gov/view/noaa/70571/noaa_70571_DS1.pdf',
  'https://www.fisheries.noaa.gov/resource/data/us-atlantic-salmon-assessment-committee-database',
  'https://www.fisheries.noaa.gov/s3/2026-05/usasac_salmon_2026_0.zip',
  'https://www.fisheries.noaa.gov/resource/document/atlantic-salmon-assessments',
  sep = '; ')

register$candidate_unit_id[row_index] <- unit_id
register$matched_stock_id[row_index] <- ''
register$match_status[row_index] <- 'new'
register$screening_status[row_index] <- 'screened'
register$eligibility[row_index] <- 'ineligible'
register$import_status[row_index] <- 'not_started'
register$catch_age_evidence[row_index] <- paste0(
  'The latest Stock SMART entry is an Index Method assessment. USASAC documents adult returns, stocking, egg production and aquaculture, not a managed fishery catch-at-age series. NOAA states directed Atlantic salmon fisheries in U.S. waters are closed and possession is prohibited; monitored bycatch is uncommon and is not the assessment catch series.')
register$survey_age_evidence[row_index] <- paste0(
  'The annual assessment reports observed adult returns at traps and returns estimated from redd counts. It includes selected adult-return and smolt-to-adult rate summaries by sea age and origin, but no independent age-specific survey index used in a population-at-age likelihood.')
register$weights_evidence[row_index] <- paste0(
  'The Index Method / returns monitoring assessment does not report a weight-at-age input. Biological age samples may exist outside this assessment.')
register$maturity_evidence[row_index] <- paste0(
  'The assessment reports adult returns and viability indicators; no maturity-at-age schedule is used to estimate a population-at-age surface.')
register$mortality_evidence[row_index] <- paste0(
  'No fishing mortality-at-age or natural mortality-at-age is estimated. Sea-age return rates are survival indicators and are not F or M estimates.')
register$timing_evidence[row_index] <- paste0(
  'The assessment summarizes annual river returns and smolt cohorts; no within-year survey timing for an age-structured observation likelihood is specified.')
register$output_evidence[row_index] <- paste0(
  'The 2025 USASAC Report 37 reports 1,517 adult returns to the Gulf of Maine DPS in 2024 (1,386 hatchery-origin and 131 naturally reared) and selected sea-age return-rate indicators. These are river-return and viability outputs, not N-at-age, SSB, recruitment, F-at-age or M-at-age surfaces.')
register$detailed_source_url[row_index] <- source_urls
register$review_date[row_index] <- '2026-10-30'
register$decision_reason[row_index] <- paste0(
  'The latest Stock SMART production entry is the 2024 Gulf of Maine Index Method assessment using data through 2023; the latest detailed annual report found is USASAC Report 37 for 2024 activities, published in 2025. It documents river adult returns and age-related survival indicators rather than an age-structured fishery assessment with catch-at-age and population/mortality-at-age outputs. Ineligible for the age-structured comparison. This does not establish that biological age samples are absent.')
register$notes[row_index] <- paste0(
  'NOAA Stock SMART 10498 is the Gulf of Maine Atlantic salmon unit (Salmo salar). The broader ICES North American salmon candidate is not a one-to-one identity match and remains separate. NOAA describes the USASAC database, updated 2026-05-29, as adult-return, adult/juvenile stocking, egg-production and aquaculture records. Its cached ZIP is source_cache/discovery_noaa_atlantic_salmon_2025/USASAC_database_2026-05.zip (SHA-256 ', database_sha256, '). The report PDF has official NOAA repository SHA-512 ', report_sha512, '; direct download returned HTTP 403, but the repository record and PDF text are publicly readable. The MDB could not be schema-inspected because an Access reader is unavailable here. No canonical numerical records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row_index,
    register[row_index, , drop = FALSE], candidate_id)

cat('Screened NOAA Gulf of Maine Atlantic salmon (10498) as ineligible for the age-structured comparison; no canonical numerical data were added.\n')
