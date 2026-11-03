root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_ices_bay_biscay_anchovy_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:ane.27.8'
unit_id <- 'ices_bay_biscay_anchovy_8'

files <- c(
  'WGHANSA_2025_Report.pdf',
  'ICES_stock_annex_ane_27_8_2026.pdf',
  'WKBANSP_2024_v2.pdf',
  'WGACEGG_2025_Report.pdf',
  'ICES_stock_graphs_2025_key_21265.html',
  'ICES_source_data_2025_key_21265.html',
  'ICES_advice_2026_record_4005.html')
urls <- c(
  'https://ndownloader.figshare.com/files/62700859',
  'https://ndownloader.figshare.com/files/55501253',
  'https://ndownloader.figshare.com/files/52237436',
  'https://ndownloader.figshare.com/files/62338852',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=21265',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265',
  'https://asd.ices.dk/viewAdvice/4005')
hashes <- c(
  '91a780f00878529c9cee208137a9f9ede22f49ad1a83c5840d1d72395103c6d9',
  '68a47d82ec4b83af0f85d84fcf57d83bc087910f84f2069c363405f93e9a307c',
  '9fc9471287b38cdf6aa74fff872ee06ef55668c32f877061a918506e28e9c95c',
  'b5ed2946e7a28b8f7ce3fd789bd8b77447e42688be8ccae7cf2b08015902a7a3',
  'c962b984d89033ca58d158309250d9375c75b2e7eab6a516233e9e39703e3beb',
  'c618a785eeafba87552f702911c20946a898cc696660bf1a1f4affd22b6c1163',
  'dcc056fc780c06fea66bbab78ac6eb013b18f2bf341a133d0667f72c0cf8fa78')

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
    !identical(as.character(manifest$sha256[manifest_rows]), hashes) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(unname(vapply(paths, sha256_file, character(1L))), hashes))
  stop('The cached ICES sources do not match their manifest.', call. = FALSE)

graphs <- paste(readLines(paths[5], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[6], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- paste(readLines(paths[7], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('ane.27.8', graphs, fixed = TRUE) || !grepl('21265', graphs, fixed = TRUE) ||
    !grepl('2025', graphs, fixed = TRUE) || !grepl('SSB', source_data, ignore.case = TRUE) ||
    !grepl('ane.27.8', advice, fixed = TRUE))
  stop('Cached ICES sources do not verify the current Bay of Biscay anchovy assessment.',
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
if (is.na(row) || register$official_stock_id[row] != 'ane.27.8' ||
    register$scientific_name[row] != 'Engraulis encrasicolus' ||
    register$inventory_assessment_year[row] != 2025 ||
    register$assessment_area[row] != 'Bay of Biscay and the Iberian Coast')
  stop('The ICES anchovy inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'ane.27.8', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The ICES anchovy unit identifier conflicts with a canonical or candidate record.',
    call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'eligible'
if (!initial && !reviewed)
  stop('The ICES anchovy candidate has a conflicting prior review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'eligible'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The 2025 Stock Synthesis assessment uses total catch biomass in tonnes and catch-at-age in thousands of fish by semester for 1987-2025. Catch-at-age covers ages 1, 2, and 3+; age 0 catch is excluded from the model, and age composition is unavailable for the second semester of the assessment year. The 2025 fishery observations are provisional, with documented assumptions for incomplete catches.')
register$survey_age_evidence[row] <- paste0(
  'The 2025 assessment uses PELGAS spring acoustic numbers-at-age 1, 2, and 3+ (2000-2025; missing 2020), BIOMAN spring DEPM numbers-at-age 1, 2, and 3+ (1987-2025; missing 1993, 1996, 1999, 2000), and JUVENA autumn acoustic abundance at age 0 (2003-2025). The spring surveys also provide aggregate SSB indices. Age-specific data and survey descriptions are published in the official report and annex.')
register$weights_evidence[row] <- paste0(
  'The report provides commercial mean weight-at-age in grams by semester (ages 0-5, 1987-2024, with missing values) and stock weight-at-age at spawning from BIOMAN in kilograms, with linear interpolation for missing years. Keep catch and stock weights distinct.')
register$maturity_evidence[row] <- paste0(
  'The official maturity schedule is 0 at age 0 and 1 at ages 1, 2, and 3+.')
register$mortality_evidence[row] <- paste0(
  'Natural mortality is fixed at M0=2.17, M1=0.80, M2=1.20, and M3+=2.26 per year, constant between seasons. Ages 1-2 use published estimates, age 0 is derived using the Gislason relationship, and age 3+ was estimated at the 2024 benchmark and retained.')
register$timing_evidence[row] <- paste0(
  'The model has two seasons (January-June and July-December), spawning on 15 May, and age-0 recruitment settlement on 1 July. BIOMAN and PELGAS are spring surveys represented at spawning time; JUVENA is an autumn survey conducted in September-October.')
register$output_evidence[row] <- paste0(
  'The 2025 report provides annual SSB, recruitment, and apical F with 95% confidence intervals through 2025 (2025 catch is assumed); beginning-of-year N-at-age for ages 0, 1, 2, 3+ through 2024 (thousands of fish); and F-at-age by semester through 2024. Fixed M-at-age is an input, not an estimated output. The official ICES Standard Graphs and source-data pages provide additional aggregate comparison series.')
register$detailed_source_url[row] <- paste(urls, collapse = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'Eligible for source curation in the age-disaggregated assessment set. The latest detailed production assessment located is the 2025 Stock Synthesis run used for 2026 ICES advice. Its report and stock annex verify commercial catch-at-age, three age-specific survey series, catch and stock weights-at-age, maturity and natural-mortality assumptions, timing, and official N-at-age, F-at-age, SSB, recruitment, and apical-F outputs. The assessment-year catch is provisional and age-specific survey/catch series require careful transcription from the official tables and figures; these are documented extraction tasks, not reasons to treat the data as absent.')
register$notes[row] <- paste0(
  'The ICES code ane.27.8 is the Bay of Biscay anchovy unit, distinct from other Engraulis encrasicolus assessment areas. WGHANSA 2025 documents the assessment-year 2025 Stock Synthesis 3.30.22.beta run used for 2026 advice; the 2025 stock annex and 2024 benchmark describe input methods and model configuration. Source URLs, retrieval dates, revisions, byte counts, and SHA-256 checksums are recorded in source_cache/discovery_ices_bay_biscay_anchovy_2025/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES Bay of Biscay anchovy (ane.27.8; 2025) as eligible for source curation; no canonical numerical records were added.\n')