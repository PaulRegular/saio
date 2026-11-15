root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_blackgill_rockfish_2017_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10404'
source_files <- c('blackgill_2017_update_assessment.pdf',
  'blackgill_2011_benchmark_assessment.pdf',
  'amendment_37_stock_definition_analysis_2026.pdf',
  'pacific_groundfish_fmp_amendment_37_2026.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2018/05/stock-assessment-update-of-blackgill-rockfish-sebastes-melanostomus-in-the-conception-and-monterey-inpfc-areas-for-2017.pdf',
  'https://www.pcouncil.org/documents/2012/11/status-of-the-blackgill-rockfish-sebastes-melanostomus-in-the-conception-and-monterey-inpfc-areas-for-2011.pdf',
  'https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf',
  'https://www.fisheries.noaa.gov/s3/2026-02/fmp-text-am37-01-2026.pdf')
source_revisions <- c(
  'Field and He, 2017 Blackgill Rockfish update, published 2018',
  'Field and Pearson, 2011 benchmark assessment',
  'NOAA/PFMC Amendment 37 Phase 2 stock-definition analysis, 2026',
  'Pacific Coast Groundfish Fishery Management Plan, amended through Amendment 37 (2026)')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA blackgill sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached NOAA blackgill sources differ from the reviewed manifest.', call. = FALSE)

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
  stop('Expected one NOAA blackgill inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10404', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE))
  stop('Screening must not create canonical blackgill assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
current_state <- register$match_status[row] == 'ambiguous' &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
if (register$scientific_name[row] != 'Sebastes melanostomus' ||
    register$inventory_assessment_year[row] != 2019 ||
    (!initial_state && !current_state))
  stop('NOAA blackgill inventory identity or review state conflicts with the source review.', call. = FALSE)

screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = NA_character_,
  organization = 'NOAA',
  official_stock_id = '10404',
  scientific_name = 'Sebastes melanostomus',
  stock_name = 'Blackgill rockfish - Southern California',
  assessment_area = 'Southern California',
  inventory_assessment_year = '2019',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10404',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The 2017 update describes commercial age-composition data carried forward from 2011, but the run-matched numeric inputs were not located. The 2017 update and 2026 federal history also describe the production status differently.',
  survey_age_evidence = 'The report describes NWFSC survey ages used as conditional age-at-length data for growth, not a direct age-specific abundance index. Numeric run-matched inputs were not located.',
  weights_evidence = 'Growth and length-weight assumptions are described in the assessment report; full run-matched biological inputs were not recovered.',
  maturity_evidence = 'The 2017 update uses revised maturity and fecundity information; these differ from SSB in biomass units because spawning output is larval production.',
  mortality_evidence = 'The 2017 report specifies fixed M of 0.063 for females and 0.065 for males, carried forward from 2011.',
  timing_evidence = 'The report describes three fisheries and multiple survey series but does not provide a recoverable run-matched seasonal timing table.',
  output_evidence = 'The report gives aggregate spawning output, recruitment and depletion. Numeric N-at-age/F-at-age model outputs and the run-matched model archive were not located.',
  detailed_source_url = paste(c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10404', source_urls), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'Identity is ambiguous: the NOAA inventory says Southern California, the 2017 assessment models one stock in the Conception and Monterey INPFC areas, and the 2026 FMP defines a Pacific West Coast stock. Eligibility remains unresolved because the 2017 report and 2026 stock-definition analysis differ on the run status and the public run-matched age inputs and age-specific outputs were not located.',
  notes = 'Do not assign this row to a current Pacific West Coast unit or import it until the area crosswalk and 2017 model status are reconciled. See discovery/source_reviews/noaa_blackgill_rockfish_2017.md and the local source cache.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state &&
  !all(vapply(names(screened), function(name)
    identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
csv_line <- function(x) {
  path <- tempfile(fileext = '.csv')
  write.table(x, path, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '', qmethod = 'double')
  raw <- readBin(path, 'raw', n = file.info(path)$size)
  unlink(path)
  charToRaw(sub('\\r?\n$', '', rawToChar(raw), perl = TRUE))
}
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write) {
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Inventory row is out of range.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, csv_line(screened), ending, after), register_path)
}
cat('Screened NOAA:10404 as identity-ambiguous with age-input eligibility unresolved.\n')