root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_nefsc_fall_2022')
mirror_file <- 'FallMT2022_text_mirror.html'
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
mirror_row <- manifest[manifest$file == mirror_file, , drop = FALSE]
pdf_row <- manifest[manifest$file == 'NOAA_report_pdf', , drop = FALSE]

sha256_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  } else {
    result <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', result[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

mirror_path <- file.path(cache, mirror_file)
if (nrow(mirror_row) != 1L || !file.exists(mirror_path) ||
    mirror_row$url != 'http://science.mq.edu.au/~ross/TaggedPDF/FallMT2022/FallMT2022.html' ||
    mirror_row$retrieved_on != '2026-10-30' ||
    as.numeric(mirror_row$bytes) != file.info(mirror_path)$size ||
    tolower(mirror_row$sha256) != sha256_file(mirror_path) ||
    nrow(pdf_row) != 1L ||
    pdf_row$url != 'https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf' ||
    pdf_row$sha256 != '11d9eaf4e013a953db7586822b577944cc88fa928068bbb51495916607ae7e95')
  stop('The cached NOAA report mirror or remote PDF provenance does not match its manifest.', call. = FALSE)

report_text <- paste(readLines(mirror_path, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
if (!grepl('Northern Monkfish', report_text, ignore.case = TRUE) ||
    !grepl('Southern Monkfish', report_text, ignore.case = TRUE) ||
    !grepl('lack of a reliable aging method', report_text, ignore.case = TRUE) ||
    !grepl('Ismooth', report_text, fixed = TRUE) ||
    !grepl('0.829', report_text, fixed = TRUE) ||
    !grepl('0.646', report_text, fixed = TRUE))
  stop('The cached report mirror is missing the monkfish assessment evidence.', call. = FALSE)

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
metadata <- metadata[order(metadata$stock_id, -as.numeric(metadata$assessment_year),
  metadata$assessment_id, na.last = TRUE), , drop = FALSE]
metadata <- metadata[!duplicated(metadata$stock_id), , drop = FALSE]
latest <- metadata[metadata$stock_id %in% c(10500, 10501), , drop = FALSE]
latest <- latest[match(c(10500, 10501), latest$stock_id), , drop = FALSE]
if (nrow(latest) != 2L || !all(latest$assessment_year == 2022) ||
    !all(latest$assessment_type == 'Operational') ||
    !identical(as.character(latest$assessment_model), c('Plan Ismooth', 'Ismooth')) ||
    !all(latest$review_result == 'Full acceptance') ||
    !all(latest$model_category == 2) ||
    !all(latest$catch_input_data == 5) ||
    !all(latest$abundance_input_data == 3) ||
    !all(latest$biological_input_data == 2) ||
    !all(latest$composition_input_data == 2) ||
    !all(latest$final_assessment_report_1 ==
      'Draft 2022 Monkfish Management Track Assessment Report'))
  stop('NOAA Stock SMART monkfish metadata changed.', call. = FALSE)

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
candidate_ids <- c('NOAA:10500', 'NOAA:10501')
unit_ids <- c('noaa_monkfish_north_10500', 'noaa_monkfish_south_10501')
rows <- match(candidate_ids, register$candidate_id)
if (anyNA(rows) || anyDuplicated(register$candidate_id[rows]) ||
    any(register$scientific_name[rows] != 'Lophius americanus') ||
    anyDuplicated(unit_ids) ||
    any(stocks$scientific_name == 'Lophius americanus', na.rm = TRUE) ||
    any(as.character(stocks$authority_stock_id) %in% c('10500', '10501'), na.rm = TRUE))
  stop('Monkfish identities overlap a canonical stock or candidate identity.', call. = FALSE)

source_rows <- setdiff(which(register$scientific_name == 'Lophius americanus'), rows)
if (length(source_rows))
  stop('Another candidate row already uses the monkfish scientific identity; reconcile it before screening.', call. = FALSE)
if (any(unit_ids %in% c(register$candidate_unit_id[-rows],
    assessments$assessment_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE) ||
    any(candidate_ids %in% c(assessments$assessment_id, inputs$assessment_id,
      outputs$assessment_id), na.rm = TRUE))
  stop('A monkfish candidate or unit identifier already has a canonical/candidate use.', call. = FALSE)

initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == unit_ids &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (!all(initial | reviewed))
  stop('A NOAA monkfish candidate has a conflicting prior review.', call. = FALSE)

assessment_urls <- paste(
  'https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf',
  'https://repository.library.noaa.gov/view/noaa/55264',
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10500',
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10501',
  'http://science.mq.edu.au/~ross/TaggedPDF/FallMT2022/FallMT2022.html',
  sep = '; ')
multipliers <- c('0.829 in the North', '0.646 in the South')

for (j in seq_along(rows)) {
  i <- rows[j]
  register$candidate_unit_id[i] <- unit_ids[j]
  register$matched_stock_id[i] <- ''
  register$match_status[i] <- 'new'
  register$screening_status[i] <- 'screened'
  register$eligibility[i] <- 'ineligible'
  register$import_status[i] <- 'not_started'
  register$catch_age_evidence[i] <- paste0(
    'The 2022 report gives commercial discards, landings, and total assessment catch by year in metric tonnes (2012-2021), but no catch numbers-at-age. The assessment says an analytical age-based assessment was not possible because a reliable aging method was lacking. Stock SMART composition input level 2 does not establish an age-composition likelihood.')
  register$survey_age_evidence[i] <- paste0(
    'The assessment uses aggregate NEFSC spring and fall bottom-trawl survey biomass indices, combined and smoothed for Ismooth; it does not describe an age-specific abundance index.')
  register$weights_evidence[i] <- paste0(
    'The management-track update is an index-based Ismooth method, and the report identifies the lack of a reliable aging method; stock-specific weights-at-age are not reported as model inputs.')
  register$maturity_evidence[i] <- paste0(
    'No age-based population model or maturity-at-age schedule is reported. This does not establish that biological maturity samples are absent.')
  register$mortality_evidence[i] <- paste0(
    'The report does not estimate fishing or natural mortality at age. Ismooth derives a catch multiplier from aggregate catch and smoothed survey indices; stock status and reference points remain unknown.')
  register$timing_evidence[i] <- paste0(
    'The assessment combines the fall survey in year y with the spring survey in year y+1 after scaling each series by its mean. This is an annual aggregate index construction, not within-year timing for an age-specific observation.')
  register$output_evidence[i] <- paste0(
    'The report presents aggregate spring/fall biomass indices and approximate 90% log-normal intervals, total catch, and an Ismooth catch multiplier (', multipliers[j], '). It does not report recruitment or N/F/M-at-age.')
  register$detailed_source_url[i] <- assessment_urls
  register$review_date[i] <- '2026-10-30'
  register$decision_reason[i] <- paste0(
    'The latest official 2022 operational assessment is an Ismooth management-track update because a reliable aging method was unavailable for an analytical assessment. Its model inputs and outputs are aggregate catch and survey indices with catch advice multipliers, not age-disaggregated population inputs or outputs. Ineligible for the age-disaggregated comparison; this does not claim that biological age samples do not exist.')
  register$notes[i] <- paste0(
    'NOAA Stock SMART IDs 10500 and 10501 represent distinct Northern and Southern Monkfish management units, reported in Stock SMART as Goosefish. The latest rows are 2022 operational assessments; Stock SMART labels both rows Full acceptance; its model-category and composition scores are inventory metadata and do not establish an age-structured assessment. The report uses the name Lophius americanus. The official PDF remote checksum and the separately checksummed public HTML text mirror are recorded in the ignored shared cache at source_cache/discovery_noaa_nefsc_fall_2022; the PDF download was denied in this session. The 2022 report updates the 2019 Ismooth/Plan B approach. No canonical numerical records were added.')
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (j in seq_along(rows))
    replace_candidate_register_row(register_path, rows[j], register[rows[j], , drop = FALSE],
      candidate_ids[j])
}
cat('Screened NOAA Northern and Southern Monkfish (10500 and 10501) ineligible for age-disaggregated comparison; no canonical numerical data were added.\n')
