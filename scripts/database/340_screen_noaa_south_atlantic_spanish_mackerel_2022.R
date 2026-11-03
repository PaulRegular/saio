root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_south_atlantic_spanish_mackerel_2022')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'sedar78_revised_july_2022_assessment.pdf',
    'sedar78_wp02_seamap_age0_indices.pdf',
    'sedar78_wp05_age_length_composition_weighting.pdf',
    'sedar78_wp08_age_data_1986_2020.pdf',
    'sedar78_wp12_florida_commercial_handline_index.pdf'
  ),
  url = c(
    'https://sedarweb.org/documents/sedar-78-stock-assessment-report-south-atlantic-spanish-mackerel-revised-july-2022/',
    'https://sedarweb.org/documents/sedar-78-wp02-spanish-mackerel-indices-of-abundance-in-u-s-south-atlantic-waters-based-on-the-seamap-sa-fishery-independent-coastal-trawl-survey/',
    'https://sedarweb.org/documents/sedar-78-wp05-general-recreational-and-commercial-age-and-length-composition-weighting-for-southeast-u-s-spanish-mackerel-scomberomorus-maculatus/',
    'https://sedarweb.org/documents/sedar-78-wp08-a-review-of-atlantic-spanish-mackerel-scomberomorus-maculatus-age-data-1986-2020-from-various-age-data-sources/',
    'https://sedarweb.org/documents/sedar-78-wp12-annual-indices-of-abundance-of-spanish-mackerel-from-florida-commercial-trip-tickets-1986-2020/'
  ),
  revision = c(
    'Final SEDAR 78 operational assessment report, revised July 2022; data through 2020',
    'SEDAR 78 working paper 02, SEAMAP-SA juvenile abundance indices; received October 29, 2021',
    'SEDAR 78 working paper 05, age/length composition weighting; October 2021',
    'SEDAR 78 working paper 08, age-data review 1986-2020; received October 29, 2021',
    'SEDAR 78 working paper 12, Florida handline trip-ticket index 1986-2020; received November 12, 2021'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
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
    stop('Cached SEDAR 78 sources differ from the reviewed files.', call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

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
    'The latest completed, fully accepted run located is the operational SEDAR 78 BAM',
    'assessment (Stock SMART 12822; 2023 assessment, data through 2020). The final report',
    'prints annual fishery landings/discards and observed age compositions for ages 0-10+',
    'in Tables 2 and 4-8. Commercial landings are 1000 lb whole weight; other catches are',
    '1000 fish. Handline and cast-net age compositions are pooled across years; gillnet,',
    'pound-net and recreational compositions are reported by year. These source quantities',
    'support a documented, approximate catch-at-age reconstruction, with pooled compositions',
    'and mixed catch units kept explicit.'),
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
    'The final report provides annual total abundance-at-age (1000 fish), biomass-at-age',
    '(1000 lb), recruitment (age-0 fish), SSB (mt), and instantaneous F-at-age (per year)',
    'through 2020. Table 1 also gives fixed M-at-age. Annual age-surface uncertainty was not',
    'located in the report; uncertainty is available for selected assessment quantities.'),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-78/;',
    'https://sedarweb.org/documents/sedar-78-stock-assessment-report-south-atlantic-spanish-mackerel-revised-july-2022/;',
    'https://sedarweb.org/documents/sedar-78-wp02-spanish-mackerel-indices-of-abundance-in-u-s-south-atlantic-waters-based-on-the-seamap-sa-fishery-independent-coastal-trawl-survey/;',
    'https://sedarweb.org/documents/sedar-78-wp05-general-recreational-and-commercial-age-and-length-composition-weighting-for-southeast-u-s-spanish-mackerel-scomberomorus-maculatus/;',
    'https://sedarweb.org/documents/sedar-78-wp08-a-review-of-atlantic-spanish-mackerel-scomberomorus-maculatus-age-data-1986-2020-from-various-age-data-sources/;',
    'https://sedarweb.org/documents/sedar-78-wp12-annual-indices-of-abundance-of-spanish-mackerel-from-florida-commercial-trip-tickets-1986-2020/;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10174;',
    'https://asmfc.org/species/spanish-mackerel/', collapse = ' '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation: the latest current-unit production assessment is the fully',
    'accepted 2022 SEDAR 78 operational BAM assessment through 2020, and its final report',
    'provides numerical catches, age compositions, age-specific biology, abundance indices,',
    'N-at-age, F-at-age, SSB and recruitment. The record is not yet imported. Age compositions',
    'are pooled for two fisheries, catch totals use different units, the exact single-year',
    'survey timing is unavailable, and the report has inconsistent June-versus-July SSB timing',
    'descriptions. These limitations must be carried into any later extraction.'),
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
