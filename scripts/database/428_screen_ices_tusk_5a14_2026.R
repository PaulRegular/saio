root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_tusk_5a14_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:usk.27.5a14'
unit_id <- 'ices_tusk_5a14'

files <- c(
  'MFRI_tusk_2026_technical_report.html',
  'MFRI_tusk_2026_advice.html',
  'MFRI_tusk_2023_technical_report.pdf',
  'ICES_WKICEMP_2022_benchmark.pdf',
  'ICES_stock_graphs_2026_key_22530.html',
  'ICES_source_data_2026_key_22530.html',
  'ICES_advice_2026_record_7219.html',
  'ICES_stock_annex_2023_metadata.json')
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/08_usk_2026_1_techreport_en.html',
  'https://www.hafogvatn.is/static/extras/images/08_usk_2026_1_advice_en.html',
  'https://www.hafogvatn.is/static/extras/images/19-tusk_tr1388162.pdf',
  'https://ndownloader.figshare.com/files/35127877',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22530',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22530',
  'https://asd.ices.dk/viewAdvice/7219',
  'https://api.figshare.com/v2/articles/23599668')
expected_hashes <- c(
  'e91e19f33092947159d4de0821620655cee9f83e8e0a25c7da6328a7813f15d8',
  '6be8e5d4f764fa4440583a836ed7fc1a578be25e0f5d74212512ba76b0268558',
  '85628f81db32d0c679e726b81fb12f93cf285fc18271df46d5a89d334b5eaf83',
  '77a7371bb44ee493ec65de3083e0e70c361fce6a4eb01592738403ff60dee5f7',
  '755acbbecea34663f7d1cad47f96e3e865f6b5c2ccbdf7ffec436e31404548d5',
  '633491a82a87cba183c126b0801b4858c5c417dc7202352f86fc1753c12c7166',
  'd3d8922e315d2b9ca7b51c624ceed4e58d12897fb9ff458332f42bf9c678b26e',
  'ba70686312d87fd40739cf819eeae203d5ffecee74ea594869f23b29c0b0b4a6')

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

report <- tolower(paste(readLines(paths[1], warn = FALSE, encoding = 'UTF-8'), collapse = ' '))
graphs <- paste(readLines(paths[5], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[6], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- paste(readLines(paths[7], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
annex_metadata <- paste(readLines(paths[8], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!all(vapply(c('tusk in ices division 5.a and subarea 14', 'sam assessment',
    'age data are used as input for the sam assessment', 'catch at age from the commercial fishery',
    'age disaggregated indices', 'no data are available from area 14'),
    grepl, logical(1L), x = report, fixed = TRUE)) ||
    !grepl('22530', graphs, fixed = TRUE) || !grepl('usk.27.5a14', graphs, fixed = TRUE) ||
    !grepl('SSB', source_data, ignore.case = TRUE) ||
    !grepl('usk.27.5a14', advice, fixed = TRUE) ||
    !grepl('23599668', annex_metadata, fixed = TRUE))
  stop('Cached sources do not verify the current ICES tusk assessment and area-specific data gap.',
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
if (is.na(row) || register$official_stock_id[row] != 'usk.27.5a14' ||
    register$scientific_name[row] != 'Brosme brosme' ||
    register$inventory_assessment_year[row] != 2026 ||
    register$assessment_area[row] != 'Greenland Sea, Icelandic Waters')
  stop('The ICES tusk inventory identity changed.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'usk.27.5a14', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The ICES tusk unit identifier conflicts with a canonical or candidate record.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!initial && !reviewed)
  stop('The ICES tusk candidate has a conflicting prior review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'unresolved'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The current 2026 MFRI report identifies commercial catch-at-age for Icelandic Division 5.a as an input to SAM and presents catch numbers-at-age and catch biomass-at-age by age/cohort. The report documents no corresponding catch weight-at-age data from Subarea 14. The accessible current report and stock-annex metadata do not establish how the 14 catch is represented in the production model, so age coverage for the full 5.a+14 unit is unresolved.')
register$survey_age_evidence[row] <- paste0(
  'The 2026 report shows age-disaggregated Icelandic spring SMB indices since 1985 and autumn SMH indices since 1996; no age-disaggregated Subarea 14 index was identified. It also describes an April gillnet survey. Exact model-use, age ranges, annual values, and coverage of the full 5.a+14 unit require the current SAM input files or a complete current stock annex.')
register$weights_evidence[row] <- paste0(
  'The report presents commercial catch weight-at-age and spring-survey stock weight-at-age for Icelandic 5.a. It states no catch weight-at-age data are available from area 14. No complete stock-weight series for the full current 5.a+14 unit was verified.')
register$maturity_evidence[row] <- paste0(
  'For Icelandic 5.a, maturity-at-age is derived from autumn-survey maturity-at-length and age-length distributions and is used to calculate spawning biomass. Equivalent age-specific maturity inputs for Subarea 14 were not identified.')
register$mortality_evidence[row] <- paste0(
  'The 2023 MFRI report documents an assumed natural mortality of 0.15 per year for the age groups in the 5.a assessment. The 2026 report refers to the 2023 stock annex for model configuration, but the annex file and current native model configuration were not recovered; the exact 2026 M assumption and its use for Subarea 14 remain to be verified.')
register$timing_evidence[row] <- paste0(
  'The Icelandic SMB survey is conducted in March, SMH in autumn, and the inshore gillnet survey in April. The 2026 report does not provide exact fractional-year observation timing for the current SAM inputs; Subarea 14 age-specific survey timing was not found.')
register$output_evidence[row] <- paste0(
  'The 2026 report and ICES Standard Graphs provide aggregate SSB, recruitment at age 1, total stock biomass, catches, and Fbar ages 7-10 with uncertainty for the current unit. The reviewed current sources do not provide machine-readable N-at-age or F-at-age arrays; available outputs are aggregate rather than age-specific.')
register$detailed_source_url[row] <- paste(urls, collapse = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'Eligibility remains unresolved for the current 2026 ICES unit `usk.27.5a14`. The 2026 assessment is SAM and publicly documents age-structured commercial and Icelandic survey inputs for Division 5.a, plus aggregate official population and fishing-mortality outputs. However, the official unit includes Subarea 14, where the report states catch weight-at-age is unavailable, and the current source set does not establish the 14-area catch-age treatment, biological inputs, or whether those catches are represented in the model. The current stock annex is referenced but its metadata record has no attached file, and no current native model inputs were recovered. Do not infer a complete 5.a+14 age-structured input set from the Iceland-only figures or substitute the 2022 benchmark inputs. Revisit if current run-matched inputs or a complete stock annex become available.')
register$notes[row] <- paste0(
  'This is one current Greenland Sea/Icelandic Waters unit, distinct from ICES Tusk units in other areas. The MFRI 2026 report is the latest detailed source found and is tied to the 2026 ICES advice; the assessment reports historical estimates through 2025 and 2026 as a forecast. The 2022 benchmark and 2023 report provide method context, not current run-matched numerical data. Retrieved source files, URLs, dates, revisions, byte counts, and SHA-256 checksums are recorded in source_cache/discovery_ices_tusk_5a14_2026/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES tusk (usk.27.5a14; 2026) with eligibility unresolved for the combined 5.a+14 unit; no canonical numerical records were added.\n')
