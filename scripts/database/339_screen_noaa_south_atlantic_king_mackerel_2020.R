root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_south_atlantic_king_mackerel_2020')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c('sedar38_update_report.pdf',
    'south_atlantic_king_mackerel_draft_terms_of_reference_2026.pdf'),
  url = c(
    'https://sedarweb.org/documents/2019-update-sedar-38-update-assessment-report-south-atlantic-king-mackerel/',
    'https://safmc.net/documents/sedar_a3_sow_tors_mar2026-pdf/'
  ),
  revision = c(
    'SEDAR 38 Update South Atlantic report, April 2020; terminal fishing year 2017',
    'Draft South Atlantic King Mackerel terms of reference, February 25, 2026; planned terminal FY 2026-2027'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the SEDAR 38 Update report and current draft terms of reference before screening.',
    call. = FALSE)

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
  previous_rows <- match(previous$file, manifest$file)
  if (anyNA(previous_rows) ||
      !identical(previous$url, manifest$url[previous_rows]) ||
      !identical(previous$revision, manifest$revision[previous_rows]) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes[previous_rows])) ||
      !identical(tolower(previous$sha256), manifest$sha256[previous_rows]))
    stop('Cached SEDAR 38 Update sources differ from the reviewed files.', call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10172 & stocksmart$assessment_id == 10687,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2020L || run$last_data_year != 2017L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'SS' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'King mackerel - Southern Atlantic Coast')
  stop('NOAA Stock SMART metadata differs from the screened South Atlantic run.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10172'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_south_atlantic_king_mackerel'
gulf <- match('NOAA:10171', candidates$candidate_id)
if (is.na(i) || is.na(gulf) ||
    candidates$scientific_name[i] != 'Scomberomorus cavalla' ||
    candidates$stock_name[i] != 'King mackerel - Southern Atlantic Coast' ||
    candidates$assessment_area[i] != 'Southern Atlantic Coast' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2020L ||
    candidates$scientific_name[gulf] != candidates$scientific_name[i] ||
    candidates$assessment_area[gulf] != 'Gulf of Mexico' ||
    candidates$candidate_unit_id[gulf] == candidate_unit_id ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Scomberomorus cavalla') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) ||
    any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA South Atlantic king mackerel identity conflicts with candidate or canonical records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest completed accepted age-structured run located is Stock SMART assessment',
    '10687, the operational SEDAR 38 Update through FY 2017 (March 2017-February 2018).',
    'Commercial handline and gillnet landings are in metric tons; headboat, charter/private,',
    'and tournament landings are in fish numbers. The report lists age-composition years for',
    'handline (1991-2017), charter/private (1986-2017), and tournament (1986-2017), using',
    'conditional age-at-length observations. The report does not provide the numeric,',
    'run-matched observation arrays needed to verify a catch-at-age reconstruction.'),
  survey_age_evidence = paste(
    'The accepted run uses aggregate commercial handline-trolling and recreational headboat',
    'CPUE, plus a fishery-independent SEAMAP age-0 trawl index. The report also shows a',
    'charter/private index for comparison but says it was not included in Stock Synthesis.',
    'These are aggregate indices (the trawl index covers age 0), not a complete age-specific',
    'survey-abundance series. Age observations are conditional age-at-length samples.'),
  weights_evidence = paste(
    'The update reports sex-specific growth parameters carried from SEDAR 38 and length-weight',
    'relationships. It does not tabulate the derived weight-at-age surface, but the reported',
    'parameters appear sufficient for a model-based derivation subject to verifying the SS3',
    'calculation details.'),
  maturity_evidence = paste(
    'The update lists a fixed female maturity ogive as a function of length and fixed fecundity',
    'parameters. A run-matched maturity-at-age series was not located.'),
  mortality_evidence = paste(
    'Natural mortality is fixed by age from age 0 through 11+ in the update. The report gives',
    'the numeric vector: 0.657, 0.247, 0.224, 0.208, 0.195, 0.186, 0.178, 0.172, 0.167,',
    '0.163, 0.160, and 0.157.'),
  timing_evidence = paste(
    'Fishing years run March 1 through February 28 (February 29 in leap years). The report',
    'does not establish fractional within-year timing for the modeled survey observations.'),
  output_evidence = paste(
    'The report provides annual exploitation rate by numbers and annual recruitment (thousands',
    'of age-0 fish) and egg-based spawning output (millions of eggs) through FY 2017. It also',
    'provides selected terminal status uncertainty intervals. Numeric N-at-age and instantaneous',
    'F-at-age time series were not located; the reported fishery-mortality measure is exploitation.'),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-38-update/;',
    'https://sedarweb.org/documents/2019-update-sedar-38-update-assessment-report-south-atlantic-king-mackerel/;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10172;',
    'https://safmc.net/documents/sedar_a3_sow_tors_mar2026-pdf/',
    collapse = ' '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Screened as a distinct South Atlantic unit from the Gulf king mackerel candidate. The',
    'accepted 2020 update documents age-at-length data, fixed biological assumptions, and',
    'aggregate annual outputs. Eligibility remains unresolved because the numeric run-matched',
    'age-at-length and length-composition inputs needed to reconstruct catch-at-age were not',
    'recovered, and the report provides neither a full age-specific survey index nor',
    'N-at-age/F-at-age outputs.',
    'A February 2026 draft terms of reference plans a new assessment using data through FY',
    '2026-2027; it is not a completed production run.'),
  notes = paste(
    'NOAA:10171 is the separate Gulf of Mexico king mackerel management unit; the two units',
    'share a winter mixing zone but remain separate assessments. The 2014 SEDAR 38 base',
    'report link was unavailable from the SEDAR file endpoint during retrieval; the 2020 update',
    'contains the fixed M, maturity, fecundity, and growth summaries used for this screen.',
    'No canonical values were imported.')
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
cat('Screened NOAA South Atlantic king mackerel (NOAA:10172); input completeness remains unresolved.\n')
