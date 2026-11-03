root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_gray_snapper_2022')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'sedar75_final_assessment.pdf',
    'sedar75_wp07_fishery_length_age_compositions.pdf',
    'sedar75_wp05_life_history.pdf',
    'sedar75_wp01_inshore_index.pdf',
    'sedar75_wp03_seamap_index.pdf',
    'sedar75_gulf_ssc_review.pdf',
    'sedar75_executive_summary.pdf'
  ),
  url = c(
    'https://sedarweb.org/documents/sedar-75-gulf-of-mexico-gray-snapper-final-stock-assessment-report/',
    'https://sedarweb.org/documents/sedar-75-wp-07-gulf-of-mexico-gray-snapper-lutjanus-griseus-commercial-and-recreational-landings-length-and-age-compositions/',
    'https://sedarweb.org/documents/sedar-75-wp-05-life-history-data-for-sedar-75-gulf-of-mexico-gray-snapper/',
    'https://sedarweb.org/documents/sedar-75-wp-01-gray-snapper-abundance-indices-from-inshore-surveys-of-northeastern-gulf-of-mexico-estuaries-1996-2020/',
    'https://sedarweb.org/documents/sedar-75-wp-03-gray-snapper-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/',
    'https://sedarweb.org/documents/gulf-ssc-review-of-sedar-75-gulf-gray-snapper-pdf/',
    'https://sedarweb.org/documents/sedar-75-gulf-of-mexico-gray-snapper-executive-summary-report/'
  ),
  revision = c(
    'SEDAR 75 final operational Stock Synthesis assessment report, data through 2020',
    'SEDAR75-WP-07 commercial and recreational landings length and age compositions, July 2022',
    'SEDAR75-WP-05 life-history data for Gulf of Mexico Gray Snapper, July 2022',
    'SEDAR75-WP-01 FWRI estuarine age-0 and age-1 abundance indices, 1996-2020',
    'SEDAR75-WP-03 SEAMAP groundfish abundance indices',
    'Gulf Council SSC review of SEDAR 75, January 2023',
    'SEDAR 75 executive summary with stock status and assessment outcome'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed SEDAR 75 Gray Snapper sources before screening.', call. = FALSE)

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
  if (!identical(previous$file, manifest$file) || !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes)) ||
      !identical(tolower(previous$sha256), manifest$sha256))
    stop('Cached SEDAR 75 Gray Snapper manifest differs from the reviewed files.',
      call. = FALSE)
} else write.csv(manifest, manifest_path, row.names = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10221 & stocksmart$assessment_id == 12831,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2022L || run$last_data_year != 2020L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'SS' ||
    run$stock_name != 'Gray snapper - Gulf of Mexico')
  stop('NOAA Stock SMART metadata differs from the screened SEDAR 75 run.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10221'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_gray_snapper_gulf_mexico'
if (is.na(i) || candidates$scientific_name[i] != 'Lutjanus griseus' ||
    candidates$stock_name[i] != 'Gray snapper - Gulf of Mexico' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2022L ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Lutjanus griseus') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) || any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA Gray Snapper identity conflicts with candidate or canonical records.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The accepted SEDAR 75 Stock Synthesis assessment reports fleet landings and age',
    'compositions. Commercial vertical-line and longline and recreational private and',
    'charter/headboat age compositions contribute; recreational shore age compositions',
    'were removed from the accepted model. Age bins extend through 21+. Catch-at-age',
    'can be reconstructed from fleet totals and accepted compositions, retaining the',
    'model-specific weighting and the absence of shore age compositions.'),
  survey_age_evidence = paste(
    'SEDAR75-WP-01 provides separate FWRI indices for age 0 (1998-2020) and age 1',
    '(1996-2020), with annual means, SEs, CVs, and scaled means in fish per set.',
    'Other fishery-dependent and fishery-independent abundance indices are also',
    'documented in the assessment report.'),
  weights_evidence = paste(
    'The assessment report and life-history paper document growth, weight-length',
    'relationships, and biological inputs used to derive weights at age. Confirm the',
    'final model-ready matrices against the report tables during source curation.'),
  maturity_evidence = paste(
    'The accepted assessment uses an updated functional-maturity relationship, with',
    'maturity methods and age-related estimates documented in SEDAR75-WP-05 and the',
    'assessment report.'),
  mortality_evidence = paste(
    'The accepted report prints an age-specific natural-mortality vector, carried',
    'forward from SEDAR 51. M is fixed, with the base value for fully selected ages',
    'reported as 0.15 per year.'),
  timing_evidence = paste(
    'The assessment assumes continuous year-round fishing. The age-0 FWRI index is',
    'based on July-December sampling; the age-1 index is based on January-December',
    'sampling. Use of these annual indices needs a documented timing approximation;',
    'survey timing for other indices remains to be checked against their source papers.'),
  output_evidence = paste(
    'The assessment report gives numeric annual biomass, SSB, exploited abundance,',
    'age-0 recruitment, and stock-status outputs through 2020. No numeric fitted N-at-age',
    'or F-at-age table was located in the screened sources.'),
  detailed_source_url = paste(sources$url[c(1, 2, 3, 4, 5, 6, 7)], collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation as a new Gulf of Mexico unit. Stock SMART identifies',
    'the 2022 SEDAR 75 operational Stock Synthesis assessment through 2020 as fully',
    'accepted. The report and supporting papers provide accepted fleet age compositions,',
    'fleet landings, age-specific FWRI abundance indices, a fixed age-specific M vector,',
    'biological inputs, and numeric aggregate population outputs. The source quantities',
    'are recoverable from official tables and papers; survey timing and model-ready',
    'biological matrices require explicit validation during curation.'),
  notes = paste(
    'The model has population ages 0-28 and composition bins through 21+. Recreational',
    'shore age compositions were removed from the accepted fit. The age-0 index samples',
    'July-December and the age-1 index January-December, so any annual timing convention',
    'must be documented. No N-at-age/F-at-age numeric output table was located. This',
    'screen adds no canonical database values.')
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
cat('Screened NOAA Gulf of Mexico Gray Snapper (NOAA:10221) as eligible for source curation.\n')
