root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_bluefish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

base_url <- paste0(
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?',
  'year=2025&species_id=32&stock_id=6&review_type_id=2'
)
base_2022_url <- paste0(
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?',
  'year=2022&species_id=32&stock_id=6&review_type_id=5'
)
sources <- data.frame(
  file = c(
    '2025_BLF_UNIT.zip',
    '2025_BLF_UNIT_RPT_Atlantic_Bluefish_Update_2025_06_10_082854.125567.pdf',
    '2025_BLF_UNIT_FIG_input_data.pdf',
    '2025_BLF_UNIT_FIG_results.pdf',
    '2025_BLF_UNIT_TAB_wham_par_tables.pdf',
    '2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf',
    '2022_BLF_UNIT_1.zip',
    '2022_BLF_UNIT_2.zip',
    'bundle_2022/Bluefish_SAW_SARC_2022_FINAL.pdf',
    'bundle_2022/WP 06 Tyrell etAl 2022 - M.pdf',
    'bundle_2022/WP 08 Wood 2022a - Comm and Rec Data.pdf',
    '2023_04_Medley_Bluefish_Spiny_Dogfish_Review_Report.pdf'
  ),
  url = c(
    paste0(base_url, '&filename=2025_BLF_UNIT.zip'),
    rep(paste0(base_url, '&filename=2025_BLF_UNIT.zip'), 4L),
    'https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf',
    paste0(base_2022_url, '&filename=2022_BLF_UNIT_1.zip'),
    paste0(base_2022_url, '&filename=2022_BLF_UNIT_2.zip'),
    rep(paste0(base_2022_url, '&filename=2022_BLF_UNIT_1.zip'), 3L),
    paste0('https://www.st.nmfs.noaa.gov/Assets/Quality-Assurance/documents/',
      'peer-review-reports/2023/2023_04_Medley_Bluefish_%26_Spiny_Dogfish_Review_Report.pdf')
  ),
  revision = c(
    '2025 Atlantic Bluefish SASINF assessment bundle; data through 2024',
    'Member of the 2025 SASINF bundle; assessment report compiled 2025-06-10',
    'Member of the 2025 SASINF bundle; age compositions and biological inputs plotted',
    'Member of the 2025 SASINF bundle; fitted model output figures',
    'Member of the 2025 SASINF bundle; fitted parameter and population-at-age tables',
    'Final June 2025 management-track peer-review panel report',
    '2022 Atlantic Bluefish Research Track SASINF archive, part 1',
    '2022 Atlantic Bluefish Research Track SASINF archive, part 2',
    'Member of the 2022 Research Track archive; data through 2021',
    'Member of the 2022 Research Track archive; natural-mortality methods',
    'Member of the 2022 Research Track archive; catch, age and weight data',
    'CIE independent peer-review report for the 2022 Bluefish Research Track'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed NOAA Bluefish sources before screening.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', shQuote(path), 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
manifest <- transform(sources, bytes = file.info(paths)$size,
  sha256 = unname(vapply(paths, sha256_file, character(1L))))
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) ||
      !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes)) ||
      !identical(tolower(previous$sha256), manifest$sha256))
    stop('Cached Bluefish source manifest differs from the reviewed files.', call. = FALSE)
} else write.csv(manifest, manifest_path, row.names = FALSE)

bundle_members <- utils::unzip(paths[1L], list = TRUE)$Name
if (!any(grepl('2025_BLF_UNIT_FIG_input_data.pdf$', bundle_members)) ||
    !any(grepl('2025_BLF_UNIT_FIG_results.pdf$', bundle_members)) ||
    any(grepl('(^|/)[^/]+\\.(dat|r|rds|rdata)$', bundle_members, ignore.case = TRUE)))
  stop('2025 SASINF archive contents differ from the reviewed chart/output-only bundle.',
    call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10388 & stocksmart$assessment_id == 13933,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2025L || run$last_data_year != 2024L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'WHAM' ||
    run$stock_name != 'Bluefish - Atlantic Coast')
  stop('NOAA Stock SMART run metadata differs from the cached inventory.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10388'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_bluefish_atlantic_coast'
if (is.na(i) || candidates$scientific_name[i] != 'Pomatomus saltatrix' ||
    candidates$stock_name[i] != 'Bluefish - Atlantic Coast' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2025L ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Pomatomus saltatrix') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) || any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA Bluefish identity conflicts with candidate or canonical records.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The accepted 2025 WHAM update reports annual commercial and recreational',
    'catch totals and plots age-composition proportions by fishery for ages',
    '0-5 and 6+ over 1985-2024. Catch-at-age can be reconstructed as each',
    'fishery total multiplied by its plotted age proportions; source values',
    'require figure digitization, and the exact sample-size series is not in',
    'the SASINF bundle.'),
  survey_age_evidence = paste(
    'The input report plots nine aggregate index series and age compositions',
    'for age-sampled indices on the 0-5 and 6+ grid. Index trends are shown',
    'rescaled, so only relative series can be recovered from the plotted',
    'values without the source arrays; age-indexed values can be reconstructed',
    'from those series and digitized compositions with index-specific q.'),
  weights_evidence = paste(
    'Annual weight-at-age surfaces for the stock, commercial and recreational',
    'fleets, and survey series are plotted for ages 0-5 and 6+. Numeric',
    'matrices are not included in the bundle and require digitization or',
    'recovery from survey/fishery source files.'),
  maturity_evidence = paste(
    'The production input report plots a maturity-at-age schedule for ages',
    '0-5 and 6+; the numeric schedule is not tabulated in the bundle.'),
  mortality_evidence = paste(
    'The accepted 2022 research-track WHAM assessment replaced constant',
    'M=0.2 with age-varying Lorenzen weight-based M. The 2025 update reports',
    'using recent-year M averages for projections, but does not include its',
    'run-specific M vector or input code; carry-forward of the 2022 method',
    'should be verified during source curation.'),
  timing_evidence = paste(
    'The 2025 WHAM assessment is annual and its input bundle does not record',
    'fractional-year observation times. The index names identify the survey',
    'series, but will need survey-season timing from the',
    'underlying survey documentation and must label any annualization as an',
    'approximation.'),
  output_evidence = paste(
    'The 2025 fitted parameter tables report numeric abundance-at-age in',
    'thousands and total and fleet fishing mortality-at-age for ages 0-5 and',
    '6+, annually from 1985-2024. The report also gives aggregate catch/status',
    'outputs, including SSB and age-0 recruitment. Uncertainty for each annual',
    'age-specific output cell is not reported in these tables.'),
  detailed_source_url = paste(c(
    paste0(base_url, '&filename=2025_BLF_UNIT.zip'),
    'https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf',
    paste0(base_2022_url, '&filename=2022_BLF_UNIT_1.zip'),
    paste0(base_2022_url, '&filename=2022_BLF_UNIT_2.zip'),
    'https://www.st.nmfs.noaa.gov/Assets/Quality-Assurance/documents/peer-review-reports/2023/2023_04_Medley_Bluefish_%26_Spiny_Dogfish_Review_Report.pdf'
  ), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation as a new NOAA Atlantic Coast unit. Stock',
    'SMART identifies assessment 13933 (2025, data through 2024, WHAM, full',
    'acceptance), and the final peer-review panel concluded the assessment',
    'met all terms of reference and represented best scientific information',
    'available. The accepted input report contains plotted fleet and survey',
    'age compositions, relative abundance indices, age-specific weights and',
    'maturity; catch totals are reported and age-specific N/F outputs are',
    'numeric. These inputs are source-recoverable by digitization or',
    'documented reconstruction, but are not ready for direct numeric import.'),
  notes = paste(
    'The 2025 SASINF archive contains report, plot, and fitted-table PDFs, but',
    'no run-specific WHAM input file or model code. Figure input pages use',
    'bubble areas to show age proportions; only the survey index trends are',
    'rescaled. The 2022 research-track report and WP06 document the Lorenzen',
    'M method; confirm that the 2025 update retained the same production-run',
    'M assumptions. Exact composition sample sizes and fractional survey',
    'timing were not found. This screen adds no canonical database values.'
  )
)

for (column in names(review)) candidates[[column]][i] <- review[[column]]
bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
line_feeds <- which(bytes == as.raw(10L))
physical_line <- i + 1L
if (length(line_feeds) < physical_line) stop('Candidate CSV row is out of range.', call. = FALSE)
first <- line_feeds[physical_line - 1L] + 1L
last <- line_feeds[physical_line]
ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
tmp <- tempfile(fileext = '.csv')
write.table(candidates[i, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
  col.names = FALSE, quote = TRUE, na = '')
replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
unlink(tmp)
replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
before <- bytes[seq_len(first - 1L)]
after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
cat('Screened NOAA Atlantic Bluefish (NOAA:10388) as eligible for source curation.\n')
