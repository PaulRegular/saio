root <- "."
cache <- file.path(root, 'source_cache', 'noaa_south_atlantic_spanish_mackerel_2022')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
source_manifest_path <- file.path(root, 'provenance',
  'noaa_south_atlantic_spanish_mackerel_2022_sources.csv')
sources <- read.csv(source_manifest_path, stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed SEDAR 78 sources before screening.', call. = FALSE)
if (any(vapply(paths, function(path) {
  con <- file(path, open = 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', n = 4L), charToRaw('%PDF'))
}, logical(1L)) == FALSE))
  stop('A cached SEDAR 78 source is not a PDF.', call. = FALSE)
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
if (any(as.numeric(sources$size_bytes) != file.info(paths)$size) ||
    any(tolower(sources$sha256) != unname(vapply(paths, sha256_file, character(1L)))))
  stop('Cached SEDAR 78 sources differ from the tracked provenance manifest.', call. = FALSE)
stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10174 & stocksmart$assessment_id == 12822,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2023L || run$last_data_year != 2020L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'BAM' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'Spanish mackerel - Southern Atlantic Coast')
  stop('NOAA Stock SMART metadata differs from the screened SEDAR 78 run.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10174'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_south_atlantic_spanish_mackerel'
gulf <- match('NOAA:10173', candidates$candidate_id)
if (is.na(i) || is.na(gulf) ||
    candidates$scientific_name[i] != 'Scomberomorus maculatus' ||
    candidates$stock_name[i] != 'Spanish mackerel - Southern Atlantic Coast' ||
    candidates$assessment_area[i] != 'Southern Atlantic Coast' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2023L ||
    candidates$scientific_name[gulf] != candidates$scientific_name[i] ||
    candidates$assessment_area[gulf] != 'Gulf of Mexico' ||
    candidates$candidate_unit_id[gulf] == candidate_unit_id ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Scomberomorus maculatus') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) ||
    any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA South Atlantic Spanish mackerel identity conflicts with candidate or canonical records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'Table 2 gives aggregate catches/removals by fleet, while Tables 4-8 provide observed age',
    'compositions for ages 0-10+. The model fits those native quantities separately; age-specific',
    'landings and discard series in Tables 16-21 are estimated outputs, not catch-at-age inputs.',
    'Commercial landings are 1000 lb whole weight; other catches are 1000 fish. Handline and',
    'cast-net compositions are pooled across years; gillnet, pound-net and recreational',
    'compositions are reported by year.'),
  survey_age_evidence = paste(
    'The assessment uses aggregate commercial handline, MRIP recreational, and SEAMAP-SA',
    'coastal-trawl age-0 abundance indices. The model report gives numerical annual indices',
    'and CVs: handline and MRIP 1986-2020, SEAMAP age-0 1989-2019. WP02 documents spring,',
    'summer and fall sampling and age-0/age-1 index methods; these are not full age-specific',
    'abundance surfaces.'),
  weights_evidence = paste(
    'SEDAR 78 Table 1 reports numeric length-at-age and whole-weight-at-age for the total',
    'population, females, and fishery-dependent population for ages 0-10, in inches and lb.',
    'These are age-specific model inputs, not annual weights.'),
  maturity_evidence = paste(
    'SEDAR 78 Table 1 reports fixed female maturity-at-age for ages 0-10; sex ratio is fixed',
    'at 50:50. Female maturity and population biology are distinguishable from fishery-',
    'dependent growth.'),
  mortality_evidence = paste(
    'Natural mortality is fixed over time and decreases with age. Table 1 reports M for ages',
    '0-10 as 0.68, 0.46, 0.40, 0.37, 0.36, 0.35, 0.34, 0.34, 0.34, 0.34, and 0.34 per',
    'year. It is a Lorenzen schedule scaled to match survival from age 2 through the oldest',
    'age under constant M=0.35.'),
  timing_evidence = paste(
    'The report predicts indices from midyear abundance (the handline index uses midyear',
    'biomass). SEAMAP trawls span spring, summer and fall, so a single survey timing fraction',
    'is not documented. The methods section says peak spawning is June 1, while Table 11',
    'describes SSB at the end of July; reconcile this internal timing discrepancy before',
    'importing or translating SSB.'),
  output_evidence = paste(
    'Tables 9-15 report annual N-at-age, biomass-at-age, aggregate B and SSB, fleet F summaries,',
    'F-at-age and total mortality-at-age. Tables 16-17 report model-estimated total landings-at-age',
    'in numbers and weight; Tables 18-19 provide annual fleet landings and discard totals; Tables',
    '20-21 report dead discards-at-age. The fitted period is 1986-2020, with 2021 interim values',
    'also printed for N-at-age and biomass-at-age. Age-surface uncertainty is not tabulated; the',
    'report provides uncertainty for selected aggregate quantities.'),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-78/;',
    'https://sedarweb.org/documents/sedar-78-stock-assessment-report-south-atlantic-spanish-mackerel-revised-july-2022/;',
    'https://sedarweb.org/documents/sedar-78-wp01-sa-coastal-trawl-survey-data-and-sampling-collection-methods/;',
    'https://sedarweb.org/documents/sedar-78-wp02-spanish-mackerel-indices-of-abundance-in-u-s-south-atlantic-waters-based-on-the-seamap-sa-fishery-independent-coastal-trawl-survey/;',
    'https://sedarweb.org/documents/sedar-78-wp03-general-recreational-survey-data-for-spanish-mackerel-in-the-south-atlantic/;',
    'https://sedarweb.org/documents/sedar-78-wp04-sedar-78-spanish-mackerel-bycatch-estimates-from-us-atlantic-coast-shrimp-trawls/;',
    'https://sedarweb.org/documents/sedar-78-wp05-general-recreational-and-commercial-age-and-length-composition-weighting-for-southeast-u-s-spanish-mackerel-scomberomorus-maculatus/;',
    'https://sedarweb.org/documents/sedar-78-wp08-a-review-of-atlantic-spanish-mackerel-scomberomorus-maculatus-age-data-1986-2020-from-various-age-data-sources/;',
    'https://sedarweb.org/documents/sedar-78-wp09-fishery-dependent-cpue-index-for-spanish-mackerel-derived-from-mrip-data/;',
    'https://sedarweb.org/documents/sedar-78-wp11-discards-of-spanish-mackerel-calculated-for-commercial-fishing-vessels-with-federal-fishing-permits-in-the-us-south-atlantic/;',
    'https://sedarweb.org/documents/sedar-78-wp12-annual-indices-of-abundance-of-spanish-mackerel-from-florida-commercial-trip-tickets-1986-2020/;',
    'https://sedarweb.org/documents/sedar-78-south-atlantic-spanish-mackerel-july-2023-ssc-meeting/;',
    'https://sedarweb.org/assessments/sedar-110-south-atlantic-spanish-mackerel/;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10174;',
    'https://asmfc.org/species/spanish-mackerel/', collapse = ' '),
  review_date = '2026-11-08',
  decision_reason = paste(
    'Eligible for source curation: SEDAR 78 is the latest detailed production assessment for',
    'the current unit, with 2022 model results through 2020. Stock SMART records a Full',
    'acceptance review result; the July 2023 SSC supported stock-status and catch-level advice,',
    'but not projections. The report provides the native catches, compositions, indices and',
    'biology, plus population, mortality and catch outputs. Handline and cast-net compositions',
    'are pooled; catch units differ by fleet; one survey timing fraction is unavailable; and',
    'the report has conflicting June/July SSB timing descriptions.'),
  notes = paste(
    'Distinct South Atlantic management unit from NOAA:10173 Gulf Spanish mackerel. The 2027',
    'assessment is scheduled, not completed. No canonical database values were added.')
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
cat('Screened NOAA South Atlantic Spanish mackerel (NOAA:10174); eligible for source curation.\n')
