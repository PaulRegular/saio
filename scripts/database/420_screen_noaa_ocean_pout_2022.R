root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_ocean_pout_2022')
mirror_file <- 'FallMT2022_text_mirror.html'
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
mirror_row <- manifest[manifest$file == mirror_file, , drop = FALSE]
remote_row <- manifest[manifest$cache_status == 'not_cached_access_denied', , drop = FALSE]

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
    nrow(remote_row) != 1L ||
    remote_row$url != 'https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf' ||
    remote_row$sha256 != '11d9eaf4e013a953db7586822b577944cc88fa928068bbb51495916607ae7e95')
  stop('The cached ocean-pout report mirror or remote provenance does not match its manifest.', call. = FALSE)

report_text <- paste(readLines(mirror_path, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
if (!grepl('Ocean pout', report_text, ignore.case = TRUE) ||
    !grepl('NEFSC', report_text, ignore.case = TRUE) ||
    !grepl('spring', report_text, ignore.case = TRUE) ||
    !grepl('Exploitation Ratio', report_text, ignore.case = TRUE) ||
    !grepl('0.263', report_text, fixed = TRUE))
  stop('The cached report mirror is missing the ocean-pout assessment section.', call. = FALSE)

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
metadata <- metadata[order(metadata$stock_id, -as.numeric(metadata$assessment_year),
  metadata$assessment_id, na.last = TRUE), , drop = FALSE]
metadata <- metadata[!duplicated(metadata$stock_id), , drop = FALSE]
latest <- metadata[metadata$stock_id == 10525, , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_year != 2022 ||
    latest$assessment_type != 'Operational' || latest$assessment_model != 'Index Method' ||
    latest$review_result != 'Full acceptance' ||
    latest$model_category != 2 || latest$composition_input_data != 2 ||
    latest$catch_input_data != 5 || latest$abundance_input_data != 3 ||
    latest$biological_input_data != 2)
  stop('NOAA Stock SMART ocean-pout assessment metadata changed.', call. = FALSE)

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
candidate_id <- 'NOAA:10525'
unit_id <- 'noaa_ocean_pout_10525'
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    any(stocks$scientific_name == 'Zoarces americanus') ||
    any(na.omit(stocks$authority_stock_id) == '10525') ||
    any(c(unit_id, candidate_id) %in% c(assessments$assessment_id, inputs$assessment_id,
      outputs$assessment_id), na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Ocean-pout identity overlaps a canonical record or another candidate unit.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('The NOAA ocean-pout row has a conflicting prior review.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2022 report gives aggregate commercial landings and discards in metric tonnes, with no catch numbers-at-age. NOAA Stock SMART reports Catch Input Data level 5, but that rating describes completeness of total removals, not age disaggregation.',
  survey_age_evidence = 'The 2022 index assessment uses the NEFSC spring bottom-trawl survey biomass index in kg/tow and its three-year moving average; no age-specific abundance index is described.',
  weights_evidence = 'The assessment is index-based and reports no stock weights-at-age. NOAA Stock SMART Biological Input Data level 2 does not establish that age-specific weights were used.',
  maturity_evidence = 'The index-based assessment does not report or use an age-specific maturity schedule; this is not evidence that biological maturity samples are absent.',
  mortality_evidence = 'The assessment reports a fully selected exploitation ratio, not fishing mortality at age; age-specific M is not part of the described index method.',
  timing_evidence = 'The abundance indicator is the NEFSC spring bottom-trawl survey. The index assessment is annual and does not define a within-year age-specific survey observation.',
  output_evidence = 'For 2021 the report gives a biomass proxy of 0.263 kg/tow and an exploitation ratio of 0.234 (catch divided by the three-year average survey index). It does not report recruitment or N/F/M-at-age outputs.',
  detailed_source_url = paste('https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/55264',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10525',
    'https://science.mq.edu.au/~ross/TaggedPDF/FallMT2022/FallMT2022.html', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = 'Screened ineligible for the age-disaggregated set. The latest public operational assessment is an index-based method using aggregate catch and a spring survey biomass index, and it reports no age-specific population inputs or outputs. This does not claim that biological age samples do not exist.',
  notes = 'New candidate linked to NOAA Stock SMART ID 10525; no canonical Zoarces americanus record exists. Stock SMART labels the 2022 operational row Full acceptance; the technical memo says it was not peer-reviewed in the Fall 2022 panel and records it as Level 1 direct delivery. Stock SMART snapshot and source provenance are in the ignored discovery_noaa_stocksmart cache. The official NOAA report PDF checksum is recorded in the NOAA repository record; direct downloads were denied in this session, so a checksummed public HTML text mirror was cached for local reference. No numerical database records were added.'
)
for (field in names(review)) register[[field]][row] <- review[[field]]

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened NOAA ocean pout 10525 ineligible from its 2022 index-based assessment; no age-specific population data were added.\n')
