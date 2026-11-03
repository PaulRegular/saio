root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_yelloweye_2024')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'NOAA:10425'
unit_id <- 'noaa_goa_yelloweye_seo'
files <- c('GOAdsr_2024.pdf', 'ssc_report_dec_2024.pdf', 'npfmc_meeting_8165.html')
paths <- file.path(cache, files)
urls <- c(
  'https://files.npfmc.org/SAFE/2024/GOAdsr.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=dc61bc73-be5c-492f-89b3-a723ea14311d.pdf',
  'https://meetings.npfmc.org/Meeting/Details/8165'
)
revisions <- c(
  '2024 Gulf of Alaska SAFE, Chapter 14, assessment data through 2024; Model 22.2',
  'NPFMC Scientific and Statistical Committee final report, December 2024',
  'NPFMC November 2026 Plan Team schedule and DSR proposed-model agenda'
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 100L))
  stop('Cache the reviewed NOAA sources before screening ', id, '.', call. = FALSE)

sources <- data.frame(file = files, url = urls, retrieval_date = '2026-10-30',
  revision = revisions, bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE)
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  rows <- match(sources$file, previous$file)
  if (anyNA(rows) || !identical(previous$url[rows], sources$url) ||
      !identical(previous$revision[rows], sources$revision) ||
      !identical(tolower(previous$sha256[rows]), sources$sha256))
    stop('Cached NOAA files differ from the reviewed source manifest.', call. = FALSE)
} else {
  write.csv(sources, manifest_path, row.names = FALSE, na = '')
}

summary_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), summary_env)
stocksmart <- summary_env$stock_assessment_summary
stocksmart <- stocksmart[stocksmart$stock_id == 10425, , drop = FALSE]
stocksmart <- stocksmart[order(-as.numeric(stocksmart$assessment_year)), , drop = FALSE]
latest <- stocksmart[1L, , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_year != 2024L ||
    latest$assessment_id != 13892L || latest$review_result != 'Full acceptance' ||
    !grepl('REMA', latest$model_version, fixed = TRUE) ||
    !grepl('Index', latest$assessment_model, fixed = TRUE))
  stop('Cached Stock SMART record does not confirm the screened production run.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id_row <- match(id, candidates$candidate_id)
if (is.na(id_row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[id_row] != '10425' ||
    candidates$scientific_name[id_row] != 'Sebastes ruberrimus' ||
    candidates$inventory_assessment_year[id_row] != 2024L ||
    any(stocks$authority_stock_id == '10425', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-id_row] == unit_id, na.rm = TRUE))
  stop('NOAA yelloweye identity conflicts with the register or database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2024 production assessment uses aggregate catch and',
    'management-area commercial average weights. It does not fit fishery',
    'numbers-at-age; age compositions shown in the report are biological',
    'samples, not catch-at-age likelihood inputs.'),
  survey_age_evidence = paste('The accepted yelloweye model is a spatially stratified',
    'two-index REMA using ADF&G submersible/ROV biomass and standardized IPHC',
    'longline CPUE in kg per hook. Neither index is age-specific.'),
  weights_evidence = paste('Commercial average weights are reported by year and SEO',
    'management unit, but no weight-at-age surface is used by the production',
    'assessment.'),
  maturity_evidence = paste('Maturity-at-age is not used in the index-based REMA',
    'assessment. The report identifies an age-structured model as possible',
    'future work and notes that updated maturity and fecundity information is',
    'still needed.'),
  mortality_evidence = paste('The 2024 report uses M = 0.044 for Tier 5 harvest',
    'reference calculations. Natural mortality is not an estimated age-specific',
    'population process in the REMA assessment.'),
  timing_evidence = paste('The fitted assessment combines annual survey indices;',
    'the source does not define a within-year age-specific observation timing.'),
  output_evidence = paste('The 2024 report provides annual SEO yelloweye biomass',
    'from 1994-2024 with 95% intervals (Model 22.2). It does not report fitted',
    'population numbers-at-age, F-at-age, M-at-age, or recruitment.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Stock SMART identifies the latest completed and',
    'fully accepted run as the 2024 assessment (data through 2024; assessment',
    '13892). Its yelloweye component is an aggregate-index REMA model, not an',
    'age-disaggregated population assessment. The 2026 DSR models were still',
    'proposed for the November Plan Team meeting on the review date. Screen',
    'ineligible for the age-structured inventory; no canonical data were added.'),
  notes = paste('The 2024 chapter assesses seven DSR species in two management',
    'complexes; only yelloweye in the Southeast Outside (SEO) Subdistrict is',
    'modeled with REMA. The other species/areas use Tier 6 maximum catch.',
    'Commercial yelloweye age compositions are included as supporting biology,',
    'not as likelihood observations. The accepted 2024 assessment continues',
    'Model 22.2; catch and survey inputs were updated through 2024 and 2023,',
    'respectively. See the local manifest for cached source URLs and checksums.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][id_row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[id_row] == 'unreviewed' &&
  candidates$screening_status[id_row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('NOAA yelloweye candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][id_row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- id_row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(candidates[id_row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\r?\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

cat('Screened NOAA Gulf of Alaska yelloweye as an aggregate-index assessment.\n')
