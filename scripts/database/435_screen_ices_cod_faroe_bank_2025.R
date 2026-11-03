root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_cod_faroe_bank_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:cod.27.5b2'
unit_id <- 'ices_cod_faroe_bank'

files <- c('ICES_Advice_2025_cod.27.5b2.pdf', 'ICES_SAG_source_data_2025.html')
urls <- c(
  'https://www.hav.fo/wp-content/uploads/2025/11/ICES-Toskur-a-Foroyabanka.pdf',
  'https://sg.ices.dk/ViewSourceData.aspx?key=21243')
revisions <- c(
  'ICES Advice 2025, Faroe ecoregion, assessment year 2025, stock assessment key 21243; ICES DOI 10.17895/ices.advice.27202572',
  'ICES Standard Graphs source data, assessment year 2025, stock assessment key 21243')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)))
  stop('Cache the reviewed ICES advice and source-data page before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
pdf_signature <- readBin(paths[1L], 'raw', n = 4L)
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    any(sources$retrieved_on[source_rows] != '2026-10-30') ||
    !identical(toupper(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(rawToChar(pdf_signature), '%PDF'))
  stop('Cached ICES sources differ from their provenance manifest.', call. = FALSE)

source_data <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('cod.27.5b2', source_data, fixed = TRUE) ||
    !grepl('<span id="lblYear">2025</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblKey">21243</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblStockSizeDescription">B_index</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblStockSizeUnits">kg/hr</span>', source_data, fixed = TRUE) ||
    !grepl('Low SSB', source_data, fixed = TRUE) ||
    !grepl('High SSB', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE))
  stop('Cached ICES source data do not match the reviewed 2025 aggregate-index record.',
    call. = FALSE)

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
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row] != 'cod.27.5b2' ||
    register$scientific_name[row] != 'Gadus morhua' ||
    any(tolower(stocks$authority_stock_id) == 'cod.27.5b2', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('Faroe Bank cod identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current 2025 ICES advice identifies landings as the catch input; it does not',
    'describe catch-at-age or a fishery age-composition likelihood.'),
  survey_age_evidence = paste('The advice uses an aggregate Faroese summer groundfish-trawl biomass index in kg/hour.',
    'The spring survey and mean length frequencies are listed as indicators, not age-specific abundance inputs.'),
  weights_evidence = 'The category 3 index advice does not report age-specific weight inputs.',
  maturity_evidence = 'The category 3 index advice does not report maturity-at-age inputs.',
  mortality_evidence = 'The category 3 index advice does not report age-specific mortality or a population-process model.',
  timing_evidence = paste('The biomass indicator is from the Faroese summer survey; no age-structured observation timing',
    'is specified for this index-based advice method.'),
  output_evidence = paste('The official sources report catch and an aggregate survey biomass index with uncertainty bounds,',
    'but no comparable annual N-at-age, F-at-age, M-at-age, SSB, or recruitment series.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest official assessment used for 2026 advice is the 2025 category 3 assessment.',
    'ICES describes the assessment as a survey biomass index applying the category 3 rb rule, with landings and',
    'an aggregate summer survey index as inputs. The linked Standard Graphs source record identifies biomass',
    'index as the stock-size measure and provides no age-specific F or population time series. This stock unit is ineligible for',
    'the age-disaggregated assessment set; this finding concerns the assessment inputs, not whether age samples',
    'may exist elsewhere.'),
  notes = paste('Faroe Bank (Subdivision 5.b.2) is a distinct ICES assessment unit from Faroe Plateau cod',
    '(Subdivision 5.b.1), which is already represented in the canonical database. No exact canonical stock match',
    'or verified Charbonneau–Keith match was found. The official ICES advice PDF and ICES Standard Graphs source',
    'page, including retrieval dates and checksums, are cached under',
    'source_cache/discovery_ices_cod_faroe_bank/. No canonical data were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('Faroe Bank cod candidate already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES Faroe Bank cod as ineligible for age-disaggregated inputs and outputs.\n')
