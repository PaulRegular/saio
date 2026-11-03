root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_ices_greater_silver_smelt_123a4_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:aru.27.123a4'
unit_id <- 'ices_greater_silver_smelt_123a4'

files <- c(
  'ICES_stock_graphs_2026_key_22376.html',
  'ICES_source_data_2026_key_22376.html',
  'ICES_advice_2026_record_6155.html',
  'ICES_request_2024_SPiCT_benchmark.pdf',
  'Scotland_North_Sea_GSS_FMP_2026_assessment.html')
urls <- c(
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22376',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22376',
  'https://asd.ices.dk/viewAdvice/6155',
  'https://www.ices.dk/advice/Advice-activities/2024_%20attachements/Norway_request_greater_silver_smelt.pdf',
  'https://www.gov.scot/publications/north-sea-greater-silver-smelt-fisheries-management-plan/pages/10/')
expected_hashes <- c(
  '3c75d023021b468c63a76d63e4b1eb71ee1581bf7bc6c17f04924456f237d129',
  'd7f4d898cdd98ed0b102092090f4e47a50fd3ad5de1d1012d033615ce7d7c2c1',
  '1496cd9b6b9916adcead95a3a05bb8c3b128b5235488257a74eb1aa92bb6c22d',
  '9c1798674a5c7b6ec1c64895b8e96147d72edd3f6dff0cf67315fc869a72f2fc',
  '384490c7196427d26a2e82da6a754893bcab9cd51cd0115d1515fc97ce68c3f5')

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

stock_source <- paste(readLines(paths[2], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[2], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- paste(readLines(paths[3], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
fmp <- paste(readLines(paths[5], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!all(vapply(c(
    'lblStockCode">aru.27.123a4</span>', 'lblYear">2026</span>',
    'lblKey">22376</span>', 'lblStockSizeDescription">B/Bmsy</span>',
    'lblFishingPressureDescription">F/Fmsy</span>', 'lblFAge"></span>',
    'lblFLength"></span>'), grepl, logical(1L), x = stock_source, fixed = TRUE)) ||
    !all(vapply(c('Year', 'SSB', 'Landings', 'Discards', 'Low F', 'High F'),
      grepl, logical(1L), x = source_data, fixed = TRUE)) ||
    !grepl('SPiCT', fmp, ignore.case = TRUE) || !grepl('biennial', fmp, ignore.case = TRUE) ||
    !grepl('Argentina silus', advice, fixed = TRUE))
  stop('Cached sources do not verify the current aggregate ICES assessment.', call. = FALSE)

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
if (is.na(row) || register$official_stock_id[row] != 'aru.27.123a4' ||
    register$scientific_name[row] != 'Argentina silus' ||
    register$inventory_assessment_year[row] != 2026 ||
    register$assessment_area[row] != 'Arctic Ocean, Barents Sea, Greater North Sea, Norwegian Sea')
  stop('The ICES inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'aru.27.123a4', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The ICES unit identifier conflicts with a canonical or candidate record.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('The ICES candidate has a conflicting prior review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'ineligible'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The current 2026 advice uses a SPiCT surplus-production assessment and the published source table reports aggregate annual SSB, landings, discards, and F summaries. It does not provide catch numbers-at-age or age compositions as model inputs. This describes the current assessment record, not whether age samples exist elsewhere.')
register$survey_age_evidence[row] <- paste0(
  'The Scottish Government 2026 fisheries management plan describes the current assessment as using a biennial acoustic survey biomass index. The reviewed official advice and Standard Graphs sources do not report age-specific survey abundance or index compositions.')
register$weights_evidence[row] <- paste0(
  'The current SPiCT assessment does not use or report an age-specific population surface. No weight-at-age input is reported in the reviewed current assessment sources; this is not evidence that biological samples do not exist.')
register$maturity_evidence[row] <- paste0(
  'The current SPiCT assessment does not use or report an age-specific population surface. No maturity-at-age input is reported in the reviewed current assessment sources; this is not evidence that biological samples do not exist.')
register$mortality_evidence[row] <- paste0(
  'The current assessment reports aggregate fishing pressure relative to Fmsy (F/Fmsy), not F-at-age or estimated M-at-age. The reviewed current sources do not identify an age-specific natural-mortality input.')
register$timing_evidence[row] <- paste0(
  'The current assessment uses an aggregate biennial acoustic biomass index. The reviewed sources do not provide a fractional-year timing for an age-specific survey observation.')
register$output_evidence[row] <- paste0(
  'The 2026 ICES Standard Graphs record labels stock-size and fishing-pressure indicators B/Bmsy and F/Fmsy; its annual source table reports SSB, landings, discards, and F with lower/upper values. The labels and units need source-specific interpretation; none is an age-specific population or mortality surface.')
register$detailed_source_url[row] <- paste(urls, collapse = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'Ineligible for the age-disaggregated comparison set. The latest official assessment located is the 2026 ICES Category 2 SPiCT surplus-production assessment, based on aggregate catch/landings and a biennial acoustic biomass index; its published outputs are aggregate biomass and fishing-pressure indicators. It does not provide the age-specific inputs or population and mortality outputs required for an age-structured comparison. Do not substitute older trend-based advice or use biological samples unrelated to the current assessment to fill this gap.')
register$notes[row] <- paste0(
  'The ICES code aru.27.123a4 identifies Greater silver smelt in subareas 1, 2, and 4 and division 3.a; this is distinct from other Argentina silus area units in the inventory. The ICES request documents the SPiCT benchmark and the 2026 official sources identify the current assessment. Retrieved source files, URLs, dates, byte sizes, and SHA-256 checksums are recorded in source_cache/discovery_ices_greater_silver_smelt_123a4_2026/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES Greater silver smelt (aru.27.123a4; 2026) as ineligible for the age-disaggregated set; no canonical numerical records were added.\n')

