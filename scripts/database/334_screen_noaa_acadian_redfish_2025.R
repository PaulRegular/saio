root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_acadian_redfish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

base_url <- paste0(
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?',
  'year=2025&species_id=1&stock_id=6&review_type_id=3'
)
sources <- data.frame(
  file = c(
    '2025_RED_UNIT.zip',
    '2025_RED_UNIT_RPT_2025_09_17_121440.522737.pdf',
    '2025_RED_UNIT_MOD_BaseWHAMCode.R',
    '2025_RED_UNIT_MOD_BaseWHAMInput.DAT',
    '2025_RED_UNIT_FIG_FiguresTables.zip',
    'September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf'
  ),
  url = c(
    paste0(base_url, '&filename=2025_RED_UNIT.zip'),
    paste0(base_url, '&info_type_id=-1&map_type_id=&filename=',
      '2025_RED_UNIT_RPT_2025_09_17_121440.522737.pdf'),
    paste0(base_url, '&info_type_id=3&map_type_id=&filename=',
      '2025_RED_UNIT_MOD_BaseWHAMCode.R'),
    paste0(base_url, '&info_type_id=3&map_type_id=&filename=',
      '2025_RED_UNIT_MOD_BaseWHAMInput.DAT'),
    paste0(base_url, '&info_type_id=1&map_type_id=&filename=',
      '2025_RED_UNIT_FIG_FiguresTables.zip'),
    paste0('https://www.fisheries.noaa.gov/s3/2025-11/',
      'September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf')
  ),
  revision = c(
    '2025 Acadian redfish Management Track SASINF source bundle; production run through 2024',
    '2025 Acadian redfish Management Track report, dated 2025-09-17',
    'Run 5 WHAM code; WHAM 2.1.0.9002 at 47506172e9a55376137501608e645ddae8a574e9',
    'Run 5 WHAM input; 1963-2024, ages 1-25 and 26+',
    'Run 5 WHAM fitted figures and tables; includes projection output beyond 2024',
    'Final September 2025 Management Track peer-review panel report'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed NOAA Acadian redfish sources before screening.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
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
    stop('Cached Acadian redfish source manifest differs from the reviewed files.', call. = FALSE)
} else write.csv(manifest, manifest_path, row.names = FALSE)

bundle <- file.path(cache, 'bundle')
figures <- file.path(cache, 'figures')
required_members <- c(
  file.path(bundle, '2025_RED_UNIT_RPT_2025_09_17_121440.522737.pdf'),
  file.path(bundle, '2025_RED_UNIT_MOD_BaseWHAMCode.R'),
  file.path(bundle, '2025_RED_UNIT_MOD_BaseWHAMInput.DAT'),
  file.path(figures, '2025_RED_UNIT_FIG_BaseWHAMFiguresTables.html')
)
if (any(!file.exists(required_members)))
  stop('Extract the official source and figure archives before screening.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10455 & stocksmart$assessment_id == 14070,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2025L || run$last_data_year != 2024L ||
    run$review_result != 'Full acceptance' ||
    run$stock_name != 'Acadian redfish - Gulf of Maine / Georges Bank')
  stop('NOAA Stock SMART run metadata differs from the cached inventory.', call. = FALSE)

dat <- readLines(file.path(cache, '2025_RED_UNIT_MOD_BaseWHAMInput.DAT'), warn = FALSE)
read_after <- function(label) {
  i <- match(label, dat)
  if (is.na(i) || i == length(dat)) stop('Missing ASAP input field: ', label, call. = FALSE)
  as.numeric(strsplit(trimws(dat[i + 1L]), '[[:space:]]+')[[1L]])
}
if (read_after('# Number of Years') != 62 || read_after('# First Year') != 1963 ||
    read_after('# Number of Ages') != 26 || read_after('# Number of Available Survey Indices') != 2 ||
    !identical(read_after('# Index Month'), c(10.5, 4.5)) ||
    read_after('# Number of Weights at Age Matrices') != 3)
  stop('Run 5 dimensions or timing differ from the reviewed input file.', call. = FALSE)

code <- paste(readLines(file.path(cache, '2025_RED_UNIT_MOD_BaseWHAMCode.R'), warn = FALSE),
  collapse = '\n')
figure_text <- paste(readLines(file.path(figures,
  '2025_RED_UNIT_FIG_BaseWHAMFiguresTables.html'), warn = FALSE), collapse = '\n')
figure_text <- gsub('(?is)<script\\b.*?</script>|<style\\b.*?</style>|<[^>]+>', ' ',
  figure_text, perl = TRUE)
figure_text <- gsub('\\s+', ' ', figure_text, perl = TRUE)
if (!grepl('age_comp = "logistic-normal-ar1-miss0"', code, fixed = TRUE) ||
    !grepl('wham@47506172e9a55376137501608e645ddae8a574e9', code, fixed = TRUE) ||
    !grepl('Abundance at age (1000s)', figure_text, fixed = TRUE) ||
    !grepl('Fishing mortality at age by fleet', figure_text, fixed = TRUE) ||
    !grepl('26+', figure_text, fixed = TRUE))
  stop('Run-specific code or fitted outputs differ from the reviewed source.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10455'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_acadian_redfish_gom_gb'
if (is.na(i) || candidates$scientific_name[i] != 'Sebastes fasciatus' ||
    candidates$stock_name[i] != 'Acadian redfish - Gulf of Maine / Georges Bank' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2025L ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == candidate_unit_id) || any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) || any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA Acadian redfish identity conflicts with the candidate or canonical records.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 Run 5 WHAM input has one commercial trawl fleet with annual total',
    'catch and proportions-at-age for ages 1-25 and 26+ over 1963-2024. The panel',
    'notes gaps in catch-at-age where ageing is incomplete; zeros are handled as',
    'missing in the selected logistic-normal age-composition likelihood. The',
    'native input retains the total and composition components separately.'),
  survey_age_evidence = paste(
    'The model uses aggregate spring and fall abundance indices with age',
    'compositions for the same age grid. The ASAP input specifies survey months',
    '4.5 (spring) and 10.5 (fall); its original index-unit code is 2 for both.',
    'Zeros and missing age compositions require source-faithful handling.'),
  weights_evidence = paste(
    'The run-specific ASAP input contains three weight-at-age matrices and',
    'pointers for fleet and survey use. Retain their native units and matrix',
    'roles when importing; the peer panel confirms the same matrix is used for',
    'catch, SSB and projections.'),
  maturity_evidence = paste(
    'The run-specific input contains maturity-at-age schedules on the 1-25,',
    '26+ grid. The peer panel recommends future assessment of possible changes',
    'in maturity and growth; those are not changes to this 2025 run.'),
  mortality_evidence = paste(
    'Natural mortality is fixed at 0.05 per year at all modeled ages in the',
    'run-specific input. It is not an estimated M process.'),
  timing_evidence = paste(
    'The annual model input sets spring and fall survey months to 4.5 and 10.5.',
    'Keep these native month values and resolve any fractional-year conversion',
    'from the ASAP convention during import; do not substitute spawning timing.'),
  output_evidence = paste(
    'Run 5 fitted tables report abundance-at-age in thousands of fish and',
    'fishing mortality-at-age by fleet, for ages 1-25 and 26+. The output bundle',
    'also reports recruitment and biomass time series and parameter estimates',
    'with standard errors and 95% intervals. Rows after 2024 are projections,',
    'not historical fitted outputs; uncertainty for each N/F age-year cell was',
    'not verified.'),
  detailed_source_url = paste(c(sources$url,
    'https://www.fisheries.noaa.gov/event/peer-review-2025-september-management-track-assessments'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation as a new NOAA Gulf of Maine / Georges Bank',
    'unit. Stock SMART identifies assessment 14070 (2025, data through 2024,',
    'full acceptance). The run-specific SASINF code identifies Run 5 as an',
    'ASAP-like WHAM assessment, and the final peer-review panel found it met',
    'the terms of reference and represented best scientific information',
    'available. Native catch totals and age compositions, aggregate survey',
    'indices and age compositions, age-specific biology, timing, and comparable',
    'N-at-age/F-at-age and aggregate outputs are recoverable. Catch-age gaps and',
    'the exact unit interpretation of native index code 2 remain to be resolved',
    'during import. No canonical numerical records are created by this screen.'),
  notes = paste(
    'The cached Stock SMART summary labels the historical model as ASAP, while',
    'the run-specific SASINF code and 2025 peer review document the 2025',
    'transition to ASAP-like WHAM; use run-specific sources for this assessment.',
    'The species also appears in separate DFO and NAFO redfish units; shared',
    'scientific name does not make those assessment boundaries identical.',
    'The figure bundle includes projections through 2028; only 1963-2024 are',
    'fitted historical years. Source files and SHA-256 values are cached in the',
    'gitignored discovery_noaa_acadian_redfish_2025 folder.')
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
cat('Screened NOAA Acadian redfish (NOAA:10455) as eligible for source curation.\n')
