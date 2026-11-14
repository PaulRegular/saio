root <- "."
cache <- file.path(root, 'source_cache', 'ices_ane_27_8')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:ane.27.8'
unit_id <- 'ices_bay_biscay_anchovy_8'

files <- c(
  'ices_wghansa_2025_report.pdf',
  'stock_annex.pdf',
  'ices_wgacegg_2025_survey_report.pdf',
  'ices_2025_advice_ane_27_8.pdf',
  'ices_standardgraphs_source_data.html')
urls <- c(
  'https://ndownloader.figshare.com/files/62700859',
  'https://ndownloader.figshare.com/files/55501253',
  'https://ndownloader.figshare.com/files/62338852',
  'https://ndownloader.figshare.com/files/60316331',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265')
hashes <- c(
  '91a780f00878529c9cee208137a9f9ede22f49ad1a83c5840d1d72395103c6d9',
  '68a47d82ec4b83af0f85d84fcf57d83bc087910f84f2069c363405f93e9a307c',
  'b5ed2946e7a28b8f7ce3fd789bd8b77447e42688be8ccae7cf2b08015902a7a3',
  '461bb0e6eb7d8c2e97b853f5585aab920102943e26bb9f7ebc9e2f63b762197f',
  '994a20018912b26b2faa1ad2fb9072c741c47e961b2f5e9c0154dacfdb7ce4c3')

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached ICES source.', call. = FALSE)
  hashes
}

manifest <- read.csv(file.path(root, 'provenance', 'ices_ane_27_8_sources.csv'),
  stringsAsFactors = FALSE)
manifest_paths <- file.path('source_cache', 'ices_ane_27_8', files)
manifest_rows <- match(manifest_paths, manifest$local_file)
paths <- file.path(cache, files)
if (nrow(manifest) != length(files) || anyNA(manifest_rows) || anyDuplicated(manifest$local_file) ||
    !identical(as.character(manifest$source_url[manifest_rows]), urls) || any(!file.exists(paths)) ||
    any(manifest$retrieved_on[manifest_rows] != '2026-11-08') ||
    !identical(tolower(as.character(manifest$sha256[manifest_rows])), hashes) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(unname(vapply(paths, sha256_file, character(1L))), hashes))
  stop('The cached ICES sources do not match their manifest.', call. = FALSE)

source_data <- paste(readLines(paths[5], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('ane.27.8', source_data, fixed = TRUE) ||
    !grepl('21265', source_data, fixed = TRUE) ||
    !grepl('SSB', source_data, ignore.case = TRUE))
  stop('Cached ICES sources do not verify the current Bay of Biscay anchovy assessment.',
    call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || register$official_stock_id[row] != 'ane.27.8' ||
    register$scientific_name[row] != 'Engraulis encrasicolus' ||
    register$inventory_assessment_year[row] != 2025 ||
    register$assessment_area[row] != 'ICES Subarea 8 (Bay of Biscay)')
  stop('The ICES anchovy inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'ane.27.8', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], stocks$stock_id,
      assessments$assessment_id), na.rm = TRUE))
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
  'WGHANSA 2025 Table 2.5.2.1 describes the fitted catch input as biomass and catch-at-age for ages 1, 2, and 3+ by semester, 1987-2025, in tonnes and thousands of fish. Table 2.2.3.2 reports historical catches-at-age by semester through 2024 with finer ages 0-5. The 2025 catch is provisional and the assessment-year second-semester age composition is unavailable.')
register$survey_age_evidence[row] <- paste0(
  'WGHANSA 2025 Table 2.5.1.1 directly supplies BIOMAN and PELGAS total SSB/CV and JUVENA age-0 N0/CV. Table 2.5.2.1 lists BIOMAN and PELGAS numbers-at-age for ages 1, 2, and 3+; historical values are mainly graphical. WGHANSA Table 2.3.1.4 and WGACEGG 2026 Table 4.5 tabulate BIOMAN 2025 age numbers as 4,951, 3,430, and 266 million, summing to the reported 8,647 million population. The assessment configuration specifies thousands, so reconstructing the BIOMAN model input requires a documented x1,000 unit conversion. The JUVENA age-0 numbers are directly available in Table 2.5.1.1; its separate biomass table is not needed to reconstruct them.')
register$weights_evidence[row] <- paste0(
  'WGHANSA 2025 Table 2.2.4.1 reports mean catch weight-at-age by semester through 2024 in grams. Stock weight-at-age at spawning comes from BIOMAN, with linear interpolation for missing years; keep these series distinct.')
register$maturity_evidence[row] <- paste0(
  'WGHANSA 2025 section 2.4.1: maturity is 0 at age 0 and 1 at ages 1, 2, and 3+.')
register$mortality_evidence[row] <- paste0(
  'WGHANSA 2025 section 2.4.2: M0=2.17, M1=0.80, M2=1.20, and M3+=2.26 per year. M0 is back-calculated with the Gislason model; M3+ was estimated at the 2024 benchmark and retained in the 2025 assessment.')
register$timing_evidence[row] <- paste0(
  'The model has two seasons (January-June and July-December), spawning on 15 May, and recruitment settlement on 1 July. BIOMAN and PELGAS are spring surveys; JUVENA is an autumn survey. Confirm the exact model sampling fractions from the stock annex before translating.')
register$output_evidence[row] <- paste0(
  'WGHANSA 2025 Table 2.5.3.2 reports annual SSB, recruitment, and apical F with 95% intervals through 2025; Tables 2.5.3.3 and 2.5.3.4 report F-at-age by semester and beginning-of-year N-at-age through 2024, without intervals. Catch for 2025 is an assumption; M-at-age is fixed input, not an estimated output.')
register$detailed_source_url[row] <- paste(c(
  'https://doi.org/10.17895/ices.pub.29335520.v3',
  'https://doi.org/10.17895/ices.pub.28053440.v2',
  'https://doi.org/10.17895/ices.pub.31353469.v3',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265',
  'https://asd.ices.dk/viewAdvice/4005'), collapse = '; ')
register$review_date[row] <- '2026-11-08'
register$decision_reason[row] <- paste0(
  'The 2025 production run is the active ICES assessment used for 2026 advice. The official report identifies catch-at-age, age-specific BIOMAN and PELGAS series, JUVENA age-0 information, biological inputs, and age-specific outputs. Historical survey series are partly graphical and require value-level source recovery before completeness can be judged; select for source curation without treating graphical descriptions as already imported numerical observations.')
register$notes[row] <- paste0(
  'Run identity: WGHANSA 2025, Stock Synthesis 3.30.22.beta, assessment key 21265, used for 2026 advice. The 2025 report reports BIOMAN 2025 SSB as 145,608 t in its narrative but 157,247 t in Tables 2.3.1.3, 2.3.1.4, and 2.5.1.1; preserve this discrepancy and use the model input table for the fitted series. Source PDFs and Standard Graphs data are cached in source_cache/ices_ane_27_8; checksums and retrieval metadata are in provenance/ices_ane_27_8_sources.csv. No canonical assessment or numerical records are added by this selection checkpoint.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES Bay of Biscay anchovy (ane.27.8; 2025) as eligible for source curation; no canonical numerical records were added.\n')
