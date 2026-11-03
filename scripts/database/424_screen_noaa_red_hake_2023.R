root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_red_hake_2023')

stock_ids <- c(10516L, 10517L)
assessment_ids <- c(12885L, 12886L)
stock_names <- c(
  'Red hake - Gulf of Maine / Northern Georges Bank',
  'Red hake - Southern Georges Bank / Mid-Atlantic')
areas <- c('Gulf of Maine / Northern Georges Bank',
  'Southern Georges Bank / Mid-Atlantic')

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
if (nrow(manifest) != 3L || anyDuplicated(manifest$file) ||
    any(manifest$retrieved_on != '2026-10-30'))
  stop('The NOAA red hake source cache manifest is incomplete.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached NOAA red hake source.', call. = FALSE)
  hashes
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$file[i])
  if (!file.exists(path) || !identical(sha256_file(path), tolower(manifest$sha256[i])))
    stop('A cached NOAA red hake source does not match its manifest: ', manifest$file[i], call. = FALSE)
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
latest <- metadata[metadata$assessment_id %in% assessment_ids, , drop = FALSE]
latest <- latest[match(assessment_ids, latest$assessment_id), , drop = FALSE]
if (nrow(latest) != 2L || anyNA(latest$assessment_id) ||
    any(latest$stock_id != stock_ids) || any(latest$assessment_year != 2023) ||
    any(latest$assessment_type != 'Operational') ||
    any(latest$assessment_model != 'Empirical Approach') ||
    any(latest$review_result != 'Full acceptance') ||
    any(latest$stock_name != stock_names))
  stop('The pinned 2023 NOAA red hake Stock SMART records changed.', call. = FALSE)

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

candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- paste0('noaa_red_hake_', stock_ids)
rows <- match(candidate_ids, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) ||
    any(register$official_stock_id[rows] != as.character(stock_ids)) ||
    any(register$scientific_name[rows] != 'Urophycis chuss') ||
    any(register$assessment_area[rows] != areas))
  stop('NOAA red hake inventory identities do not match the pinned Stock SMART records.', call. = FALSE)

if (any(stocks$scientific_name == 'Urophycis chuss', na.rm = TRUE) ||
    any(as.character(stock_ids) %in% stocks$authority_stock_id, na.rm = TRUE))
  stop('A NOAA red hake unit now overlaps a canonical stock identity.', call. = FALSE)
if (any(unit_ids %in% c(register$candidate_unit_id[-rows], assessments$assessment_id,
    inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('A NOAA red hake unit key conflicts with an existing register or database record.', call. = FALSE)

initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == unit_ids &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (any(!initial & !reviewed))
  stop('A NOAA red hake candidate has a conflicting prior review.', call. = FALSE)

source_urls <- paste(
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9037',
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9038',
  'https://repository.library.noaa.gov/view/noaa/70900',
  'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf',
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10516',
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10517',
  sep = '; ')

output_text <- c(
  'The accepted 2023 northern red hake update reports annual swept-area biomass and catch/biomass exploitation rate, not annual N-at-age, SSB, recruitment, or F-at-age. It also reports spring and fall NEFSC survey biomass indices with approximate 90% confidence intervals.',
  'The accepted 2023 southern red hake update reports annual swept-area biomass and catch/biomass exploitation rate, not annual N-at-age, SSB, recruitment, or F-at-age. It also reports spring and fall NEFSC survey biomass indices with approximate 90% confidence intervals.')

for (j in seq_along(rows)) {
  i <- rows[j]
  stock_id <- stock_ids[j]
  register$candidate_unit_id[i] <- unit_ids[j]
  register$matched_stock_id[i] <- ''
  register$match_status[i] <- 'new'
  register$screening_status[i] <- 'screened'
  register$eligibility[i] <- 'ineligible'
  register$import_status[i] <- 'not_started'
  register$catch_age_evidence[i] <- paste0(
    'The accepted 2023 operational assessment is an empirical swept-area biomass method, not an age-structured population model. It uses annual commercial landings, commercial discards and recreational catch totals through 2022; no catch numbers-at-age likelihood input is reported. NOAA Stock SMART identifies the model as Empirical Approach.')
  register$survey_age_evidence[i] <- paste0(
    'The report uses NEFSC spring and fall bottom-trawl biomass indices (kg/tow) and reports length frequencies by survey strata; it does not present age-specific survey abundance inputs. Age compositions required for a multi-age index were not verified in the accepted assessment material.')
  register$weights_evidence[i] <- paste0(
    'The current empirical assessment does not use weight-at-age. The report notes temporal changes in mean weight and length at age, but does not provide a year-by-age weight input series for a multi-age model.')
  register$maturity_evidence[i] <- paste0(
    'Maturity-at-age is not a component of the current empirical swept-area biomass assessment, and no maturity-at-age input series is reported.')
  register$mortality_evidence[i] <- paste0(
    'The assessment reports exploitation as catch divided by swept-area biomass, in percent. This is not an estimated F-at-age series; natural mortality and age-specific fishing mortality are not estimated by the current method.')
  register$timing_evidence[i] <- paste0(
    'The assessment uses spring and fall NEFSC survey indices and combines fall of year t with spring of year t+1 to form a continuous annual swept-area biomass series. It is not an age-specific survey likelihood with within-year survey timing.')
  register$output_evidence[i] <- output_text[j]
  register$detailed_source_url[i] <- source_urls
  register$review_date[i] <- '2026-10-30'
  register$decision_reason[i] <- paste0(
    'Ineligible for the age-disaggregated assessment set. The latest accepted 2023 production update uses an empirical catchability/swept-area biomass method and reports catch, swept-area biomass, exploitation rates, survey biomass indices and length frequencies. The 2023 peer-review panel confirms the method does not estimate annual N-at-age, F-at-age, recruitment or SSB. Earlier AIM/index assessments are superseded by this current production method and are not substituted as if current.')
  register$notes[i] <- paste0(
    'NOAA Stock SMART ID ', stock_id, ' is a distinct U.S. red hake management unit (Urophycis chuss): northern Gulf of Maine/northern Georges Bank for 10516; southern Georges Bank/Mid-Atlantic for 10517. These are separate current units and do not match another canonical Urophycis chuss stock in the database. 2023 assessment and peer-review sources are locally cached under source_cache/discovery_noaa_red_hake_2023/sources.csv. No canonical assessment or numerical records were added.')
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in rows)
    replace_candidate_register_row(register_path, i, register[i, , drop = FALSE],
      register$candidate_id[i])
}

cat('Screened northern and southern NOAA red hake as ineligible for the multi-age assessment set; no canonical numerical records were added.\n')
