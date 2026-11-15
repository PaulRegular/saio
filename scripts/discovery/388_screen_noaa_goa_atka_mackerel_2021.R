root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_atka_2021_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10465'
candidate_unit_id <- 'noaa_goa_atka_mackerel'
source_files <- c('goa_atka_assessment_2021.pdf', 'goa_atka_chapter_2025.pdf',
  'goa_ssc_report_2025.pdf')
source_urls <- c(
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2021/GOAatka.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=17.+Atka+Mackerel.pdf&p=6850873f-c705-4da7-924a-217c0c38b663.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2025_FINAL.pdf&p=baa66237-f488-4187-8214-2a91fac7a6a1.pdf')
source_revisions <- c('2021 GOA Atka mackerel assessment chapter',
  '2025 GOA SAFE Atka mackerel chapter', 'December 2025 NPFMC SSC report')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA GOA Atka sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA GOA Atka source manifest check failed: ',
  paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (sum(register$candidate_id == candidate_id) != 1L)
  stop('Expected one NOAA GOA Atka inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10465', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE))
  stop('Screening must not create canonical GOA Atka assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved'
current_state <- register$candidate_unit_id[row] == candidate_unit_id &&
  register$match_status[row] == 'new' && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (register$scientific_name[row] != 'Pleurogrammus monopterygius' ||
    register$inventory_assessment_year[row] != 2016 ||
    register$stock_name[row] != 'Atka mackerel - Gulf of Alaska' ||
    (!initial_state && !current_state))
  stop('NOAA GOA Atka inventory identity or review state conflicts with the source review.', call. = FALSE)

screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = 'NOAA',
  official_stock_id = '10465',
  scientific_name = 'Pleurogrammus monopterygius',
  stock_name = 'Atka mackerel - Gulf of Alaska',
  assessment_area = 'Gulf of Alaska',
  inventory_assessment_year = '2016',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10465',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'Sparse otolith samples from fisheries are described, but there is no population assessment model and no age-specific catch likelihood input.',
  survey_age_evidence = 'Sparse survey otolith samples are described; no age-specific abundance index is fitted, and survey biomass estimates are explicitly considered unreliable.',
  weights_evidence = 'Historical growth and weight-length relationships are described, but not as an age-structured model input surface.',
  maturity_evidence = 'Published age and length maturity schedules are referenced; no age-structured population model uses them.',
  mortality_evidence = 'The 2021 chapter assumes M = 0.3; no population-model mortality output is available.',
  timing_evidence = 'Summer survey sampling is described, but the latest accepted assessment does not fit an age-specific survey index.',
  output_evidence = 'The 2021 report and 2025 catch report provide Tier 6 harvest specifications, not fitted age-specific population outputs. Survey biomass is not treated as a reliable abundance output.',
  detailed_source_url = paste(c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10465', source_urls), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'This is a distinct current GOA management unit, separate from BSAI Atka mackerel. The latest accepted full assessment is the 2021 Tier 6 catch-based report; the 2025 operational assessment was not completed. The source explicitly says no population assessment model is used, so sampled ages and life-history tables do not establish age-structured model inputs or comparable age-specific outputs.',
  notes = 'Do not create canonical assessment, input, or output rows from sparse samples or Tier 6 catch limits. See discovery/source_reviews/noaa_goa_atka_mackerel_2021.md and the local source cache.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state && !all(vapply(names(screened), function(name)
  identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
csv_line <- function(x) {
  path <- tempfile(fileext = '.csv')
  write.table(x, path, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '', qmethod = 'double')
  raw <- readBin(path, 'raw', n = file.info(path)$size)
  unlink(path)
  charToRaw(sub('\\r?\\n$', '', rawToChar(raw), perl = TRUE))
}
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write) {
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line) stop('Inventory row is out of range.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, csv_line(screened), ending, after), register_path)
}
cat('Screened NOAA:10465 as one distinct GOA unit, ineligible for age-disaggregated comparison.\n')
