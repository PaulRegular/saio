root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_gulf_king_mackerel_2020')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'sedar38_update_report.pdf',
    'sedar38_base_report.pdf',
    'sedar38_update_executive_summary.pdf',
    'sedar99_schedule_october_2026.pdf'
  ),
  url = c(
    'https://sedarweb.org/documents/2019-update-sedar-38-update-assessment-report-gulf-of-mexico-king-mackerel/',
    'https://sedarweb.org/documents/sedar-38-final-stock-assessment-report-gulf-of-mexico-king-mackerel/',
    'https://sedarweb.org/documents/sedar-38-gulf-of-mexico-king-mackerel-executive-summary-update-report/',
    'https://sedarweb.org/documents/sedar-99-gulf-of-mexico-king-mackerel-project-schedule/'
  ),
  revision = c(
    'SEDAR 38 Update, September 2020; model through FY 2017-2018',
    'SEDAR 38 final assessment report, September 2014; base model and life-history methods',
    'Gulf Council SSC accepted SEDAR 38 Update; September 2020',
    'SEDAR 99 schedule updated October 2026; final report due September 2027'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed SEDAR 38 and SEDAR 99 sources before screening.', call. = FALSE)

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
    stop('Cached SEDAR 38 or SEDAR 99 manifest differs from the reviewed files.',
      call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10171 & stocksmart$assessment_id == 10686,
  , drop = FALSE]
monitoring <- stocksmart[stocksmart$stock_id == 10171 & stocksmart$assessment_id == 13022,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2020L || run$last_data_year != 2017L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'SS' ||
    run$stock_name != 'King mackerel - Gulf of Mexico' ||
    nrow(monitoring) != 1L || monitoring$assessment_year != 2023L ||
    monitoring$last_data_year != 2023L ||
    monitoring$assessment_type != 'Stock Monitoring Update' ||
    monitoring$review_result != 'Accept previous approach, remand new attempt')
  stop('NOAA Stock SMART metadata differs from the screened Gulf king mackerel runs.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10171'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_gulf_king_mackerel'
south_atlantic <- match('NOAA:10172', candidates$candidate_id)
if (is.na(i) || is.na(south_atlantic) ||
    candidates$scientific_name[i] != 'Scomberomorus cavalla' ||
    candidates$stock_name[i] != 'King mackerel - Gulf of Mexico' ||
    candidates$assessment_area[i] != 'Gulf of Mexico' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2023L ||
    candidates$scientific_name[south_atlantic] != candidates$scientific_name[i] ||
    candidates$assessment_area[south_atlantic] != 'Southern Atlantic Coast' ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Scomberomorus cavalla') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) ||
    any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA Gulf king mackerel identity conflicts with candidate or canonical records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest completed accepted age-structured run located is Stock SMART assessment',
    '10686, the operational SEDAR 38 Update through FY 2017-2018. It reports retained',
    'removals for commercial handline/gillnet in metric tons and recreational headboat and',
    'charter/private fisheries in fish numbers, plus dead discards for four fleets and shrimp',
    'bycatch. The model used conditional age-at-length observations; the report lists age-data',
    'coverage for handline (1991-2017) and charter/private (1986-2017), but does not provide',
    'the numeric run-matched composition arrays needed to verify catch-at-age reconstruction.'),
  survey_age_evidence = paste(
    'The accepted run used aggregate commercial handline and headboat CPUE plus',
    'fishery-independent SEAMAP groundfish-trawl and larval/plankton indices. These are',
    'aggregate, not age-specific abundance indices. The model included conditional',
    'age-at-length and fleet length compositions; SEAMAP trawl selectivity was fixed to ages 0-1',
    'and shrimp bycatch to age 0.'),
  weights_evidence = paste(
    'Sex-specific von Bertalanffy growth was estimated in the model. Length-weight and',
    'age-specific biological inputs are described in the SEDAR 38 base assessment, but the',
    'reviewed update report does not provide a verified run-matched weight-at-age series.'),
  maturity_evidence = paste(
    'Maturity-at-age, fecundity and natural mortality were fixed inputs carried forward from',
    'SEDAR 38. The model reports spawning output as millions of hydrated eggs; conventional',
    'biomass SSB is not the assessment definition.'),
  mortality_evidence = paste(
    'Natural mortality was fixed at an age-specific Lorenzen vector derived externally from',
    'mean length-at-age; M = 0.174 is used in the stock-status reference-point definition.'),
  timing_evidence = paste(
    'The model uses fishing years from July 1 through June 30. The reviewed sources do not',
    'establish fractional within-year timing for each aggregate survey index.'),
  output_evidence = paste(
    'Table 5.1 reports annual age-0 recruitment (thousands of fish), spawning output',
    '(billions of eggs), exploitation-rate F, and retained landings through FY 2017-2018.',
    'Annual numeric N-at-age and F-at-age arrays were not located. Current terminal status',
    'ratios have uncertainty intervals, but the annual population series are point estimates.'),
  detailed_source_url = paste(sources$url, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Screened as a distinct Gulf of Mexico candidate with a detailed accepted age-structured',
    'run and reported aggregate outputs. Eligibility remains unresolved because the final',
    'update report describes conditional age-at-length inputs but does not publish numeric',
    'run-matched arrays needed to validate an age-specific catch reconstruction, and exact',
    'run-matched weight-at-age inputs were not recovered. SEDAR 99 is in progress and its',
    'October 2026 schedule lists the final assessment report for September 2027.'),
  notes = paste(
    'Do not use preliminary SEDAR 99 data papers as if they were accepted outputs from the',
    '2020 SEDAR 38 Update. NOAA:10172 is the separate South Atlantic king mackerel unit.',
    'No canonical database values were imported.')
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
cat('Screened NOAA Gulf king mackerel (NOAA:10171); input completeness remains unresolved.\n')
