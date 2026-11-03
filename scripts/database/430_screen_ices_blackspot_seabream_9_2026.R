root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_blackspot_seabream_9_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:sbr.27.9'
unit_id <- 'ices_blackspot_seabream_9'

files <- c('ICES_advice_2026_record_7185.html',
  'ICES_stock_graphs_2026_key_23734.html', 'ICES_source_data_2026_key_23734.html',
  'ICES_WKBSS3_2025_report.pdf', 'ICES_sbr_27_9_2026_working_documents.pdf',
  'ICES_WKBSS3_figshare_metadata.json')
urls <- c('https://asd.ices.dk/viewAdvice/7185',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23734',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23734',
  'https://ndownloader.figshare.com/files/53956517',
  'https://ndownloader.figshare.com/files/61400587',
  'https://api.figshare.com/v2/articles/28443992')
expected_hashes <- c(
  'bc652c8fa5d30fc0741aaf17902e589e30b15c6bac7185b17735a515fb78ffd0',
  '962592fc9771e0eafc09453a6cf550fd9ca4589d159b4e9181894e19d61f28e9',
  '1b4c8566d53f0b223c7547d0c02e265b2ee06919be18c3235a2466d9a4c1e622',
  '5aa118b0bcf8cb035fe02b5929f5b56968052d789a837b64ecad20ec54937a34',
  'db58f70d3e90e65cd4e3b2e195ac03e1d6564e309d94b0df92c4c0e7f1b1d0b4',
  'c00171402a9a05d213302dfd0190dbb04dc1986d2b3cc2c46e344e7f25f84e67')

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

advice <- paste(readLines(paths[1], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
graphs <- paste(readLines(paths[2], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[3], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('sbr.27.9', advice, fixed = TRUE) ||
    !grepl('>2026</div>', advice, fixed = TRUE) ||
    !grepl('Stock Category</div>\\s*<div[^>]*>3</div>', advice, perl = TRUE) ||
    !grepl('sbr.27.9', graphs, fixed = TRUE) || !grepl('23734', graphs, fixed = TRUE) ||
    !grepl('id="lblYear" class="text">2026</span>', graphs, fixed = TRUE) ||
    !grepl('sbr.27.9', source_data, fixed = TRUE) ||
    !grepl('id="lblYear">2026</span>', source_data, fixed = TRUE) ||
    !grepl('<th scope="col">Year</th><th scope="col">Landings</th>', source_data, fixed = TRUE) ||
    !grepl('2003</td>', source_data, fixed = TRUE) ||
    !grepl('2025</td>', source_data, fixed = TRUE))
  stop('Cached ICES sources do not verify the 2026 blackspot seabream advice and landings series.',
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
if (is.na(row) || register$official_stock_id[row] != 'sbr.27.9' ||
    register$scientific_name[row] != 'Pagellus bogaraveo' ||
    register$inventory_assessment_year[row] != 2026 ||
    register$assessment_area[row] != 'Bay of Biscay and the Iberian Coast, Oceanic Northeast Atlantic')
  stop('The ICES blackspot seabream inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'sbr.27.9', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The ICES blackspot seabream unit identifier conflicts with a canonical or candidate record.',
    call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('The ICES blackspot seabream candidate has a conflicting prior review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'ineligible'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The latest 2026 Standard Graphs source table reports aggregate landings for 2003-2025. The latest detailed model documentation located is the 2025 WKBSS3 benchmark with input data through 2023; its final SS3 model uses landings and length compositions, and explicitly states that no age data are available. It reports no catch-at-age or catch age compositions.')
register$survey_age_evidence[row] <- paste0(
  'The 2025 WKBSS3 model uses a standardized Portuguese polyvalent-fleet CPUE index for 2000-2023, but no age-specific survey index or age compositions. The latest 2026 source table provides landings only.')
register$weights_evidence[row] <- paste0(
  'The 2025 WKBSS3 base-case specification says empirical weight-at-age is unavailable (EmpiricalWAA=0); the length-weight relationship was borrowed from the GFCM Strait of Gibraltar model.')
register$maturity_evidence[row] <- paste0(
  'The 2025 WKBSS3 model borrowed its maturity ogive from the GFCM Strait of Gibraltar assessment because maturity and age data were unavailable for the Portuguese and northern Spanish coasts.')
register$mortality_evidence[row] <- paste0(
  'The 2025 WKBSS3 model used an age-specific natural mortality curve derived from the GFCM model (M=0.275 scaled to age 4); this is a model assumption, not an age-specific observation for Subarea 9.')
register$timing_evidence[row] <- paste0(
  'The 2025 report specifies spawn_month=6. The CPUE series is from a commercial fleet segment; no age-specific survey observation or within-year survey timing was reported.')
register$output_evidence[row] <- paste0(
  'The 2025 WKBSS3 benchmark reports aggregate recruitment, SSB, and F time series with uncertainty for its SS3 run. Its stock-specific working document labels the output as a 2024 WKBSS3 SS3 run. The current 2026 SSB chart panel is empty and its source-data table contains aggregate landings only; no current 2026 N-at-age, F-at-age, or M-at-age output was recovered.')
register$detailed_source_url[row] <- paste(urls, collapse = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'Ineligible for the age-disaggregated comparison set. The latest official advice is assessment year 2026, category 3, with advice for 2027-2028; the advice-linked source table reports aggregate landings. The detailed 2025 WKBSS3 SS3 benchmark is an earlier run (data through 2023) and explicitly reports that age data are unavailable; it fits length compositions and a CPUE index, with borrowed biological assumptions. This does not assert that unreviewed age samples do not exist elsewhere. No canonical numerical data were added.')
register$notes[row] <- paste0(
  'The 2025 WKBSS3 report and its sbr.27.9 working document provide detailed earlier SS3 model documentation and aggregate outputs, but are not treated as the 2026 advice run. The benchmark explicitly states that no age data are available for the Portuguese/northern Spanish assessment area; it uses length compositions and borrowed biology. The 2026 advice-linked Standard Graphs table reports landings only. URLs, revisions, retrieval date, file sizes, and SHA-256 hashes are in source_cache/discovery_ices_blackspot_seabream_9_2026/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES blackspot seabream in Subarea 9 as ineligible for the age-disaggregated comparison set; no canonical numerical records were added.\n')
