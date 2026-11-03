root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_pollack_3a4_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:pol.27.3a4'
unit_id <- 'ices_pollack_3a4'

files <- c('ICES_stock_graphs_2024_key_19286.html',
  'ICES_source_data_2024_key_19286.html', 'ICES_advice_2024_record_3768.html')
urls <- c('https://standardgraphs.ices.dk/ViewCharts.aspx?key=19286',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19286',
  'https://asd.ices.dk/viewAdvice/3768')
expected_hashes <- c(
  'f9e71c8de93930bb2eb130a8c5d448e2f1cafd5becd05fcedee6cf1e29d45578',
  '680141c833af6763f3e869c0319cb9a3f6b5957bd94a3b66f025d2d9bf06cf4a',
  '77ba15ca3ef3068cc8fc1294415618afff4631e18b66d8be2e988773572088f3')

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached ICES source.', call. = FALSE)
  hashes
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_rows <- match(files, manifest$file)
paths <- file.path(cache, files)
if (nrow(manifest) != length(files) || anyNA(manifest_rows) || anyDuplicated(manifest$file) ||
    !identical(as.character(manifest$url[manifest_rows]), urls) || any(!file.exists(paths)) ||
    any(manifest$retrieved_on[manifest_rows] != '2026-10-30') ||
    !identical(as.character(manifest$sha256[manifest_rows]), expected_hashes) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(unname(vapply(paths, sha256_file, character(1L))), expected_hashes))
  stop('The cached ICES sources do not match their manifest.', call. = FALSE)

graphs <- paste(readLines(paths[1], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[2], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- paste(readLines(paths[3], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('pol.27.3a4', graphs, fixed = TRUE) || !grepl('19286', graphs, fixed = TRUE) ||
    !grepl('id="lblYear">2024</span>', source_data, fixed = TRUE) ||
    !grepl('>Year</th><th scope="col">Landings</th><th scope="col">Discards</th>',
      source_data, fixed = TRUE) ||
    !grepl('1977</td>', source_data, fixed = TRUE) ||
    !grepl('2023</td>', source_data, fixed = TRUE) ||
    !grepl('pol.27.3a4', advice, fixed = TRUE) ||
    !grepl('Stock Category</div>\\s*<div[^>]*>5</div>', advice, perl = TRUE))
  stop('Cached sources do not verify the ICES pollack identity, category, and aggregate-only table.',
    call. = FALSE)

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
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || register$official_stock_id[row] != 'pol.27.3a4' ||
    register$scientific_name[row] != 'Pollachius pollachius' ||
    register$inventory_assessment_year[row] != 2024 ||
    register$assessment_area[row] != 'Greater North Sea')
  stop('The ICES pollack inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'pol.27.3a4', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The ICES pollack unit identifier conflicts with a canonical or candidate record.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('The ICES pollack candidate has a conflicting prior review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'ineligible'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The latest ICES advice record is assessment year 2024, category 5, with advice applicable through 2027. Its official source-data table reports annual landings and discards in tonnes (1977-2023); it does not report catch numbers-at-age or catch age compositions.')
register$survey_age_evidence[row] <- paste0(
  'The current category-5 advice and source-data page do not report an age-specific survey index or survey age composition for the assessment.')
register$weights_evidence[row] <- paste0(
  'The current advice-linked assessment source does not report weight-at-age inputs; the published source table contains landings and discards rather than age-specific population data.')
register$maturity_evidence[row] <- paste0(
  'The current advice-linked assessment source does not report maturity-at-age inputs. This does not establish whether biological samples exist outside the current assessment.')
register$mortality_evidence[row] <- paste0(
  'The 2024 advice record classifies this assessment as category 5. The reviewed current sources do not report age-specific fishing mortality, natural mortality, or an age-structured population model.')
register$timing_evidence[row] <- paste0(
  'The current advice-linked data table reports no age-specific survey observation for which within-year timing can be specified.')
register$output_evidence[row] <- paste0(
  'The 2024 Standard Graphs source table reports landings and discards through 2023. It does not provide a verified comparable population trajectory or N-at-age, F-at-age, or M-at-age outputs for this unit.')
register$detailed_source_url[row] <- paste(urls, collapse = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'Ineligible for the age-disaggregated comparison set. The latest advice-linked assessment located is ICES assessment year 2024, category 5; its official source-data page reports only annual landings and discards, not the age-disaggregated inputs or population and mortality outputs required for comparison. The advice remains applicable through 2027. This screen concerns the current assessment sources and does not assert that age samples are absent elsewhere. No canonical numerical data were added.')
register$notes[row] <- paste0(
  'ICES unit pol.27.3a4 is pollack in Subarea 4 and Division 3.a, distinct from pollack in subareas 6-7. The 2024 advice record remains active for advice through 2027; its source-data table ends in 2023. URLs, retrieval date, revisions, file sizes, and SHA-256 hashes are recorded in source_cache/discovery_ices_pollack_3a4_2024/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES pollack (pol.27.3a4; 2024) as ineligible for age-disaggregated comparison; no canonical numerical records were added.\n')
