root <- "."
cache <- file.path(root, 'source_cache', 'noaa_scamp_sedar68oa')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
review_path <- file.path(root, 'discovery', 'source_reviews',
  'noaa_scamp_sedar68oa_2022.md')
manifest_path <- file.path(cache, 'manifest.csv')

files <- c(
  'sedar_68oa_gulf_report.pdf',
  'sedar_68oa_gulf_wp05_age_length_compositions.pdf',
  'sedar_68oa_gulf_scamp_ageing_error_wp04.pdf',
  'sedar_68oa_gulf_april_2025_projections.pdf',
  'noaa_q4_2025_stock_status_appendix.pdf',
  'sedar_68oa_south_atlantic_report.pdf',
  'sedar_68oa_south_atlantic_wp05.pdf',
  'sedar_68oa_south_atlantic_july_2023_ssc_output.pdf')
urls <- c(
  'https://sedarweb.org/documents/sedar-68oa-gulf-of-mexico-scamp-operational-assessment-final-stock-assessment-report/',
  'https://sedarweb.org/documents/sedar-68oa-wp-05-gulf-of-mexico-scamp-mycteroperca-phenax-and-yellowmouth-grouper-mycteroperca-interstitialis-commercial-and-recreational-length-and-age-compositions/',
  'https://sedarweb.org/documents/sedar-68oa-wp-04-age-and-ageing-error-of-scamp-from-the-northern-gulf-of-mexico/',
  'https://gulf-council-media.s3.amazonaws.com/uploads/2025/04/06d.-SEDAR68-OA-Gulf-Scamp-Projection-Report_April2025.pdf',
  'https://www.fisheries.noaa.gov/s3/2026-03/Appendix-E.pdf',
  'https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-operational-assessment-final-stock-assessment-report/',
  'https://sedarweb.org/documents/sedar68oa-wp05south-atlantic-u-s-scamp-mycteroperca-phenax-age-and-length-composition-from-the-recreational-fisheries/',
  'https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-july-2023-ssc-meeting-output/')
revisions <- c(
  'SEDAR 68OA Gulf of Mexico Scamp Grouper final stock assessment report, August 2022',
  'SEDAR68OA-WP-05 Gulf scamp and yellowmouth grouper commercial and recreational length and age compositions, June 2022',
  'SEDAR68OA-WP-04 age and ageing error of Scamp from the northern Gulf of Mexico, updated July 2022',
  'SEDAR 68OA Gulf Scamp additional projections report, April 2025; projections from the 2022 assessment',
  'NOAA FY2025 Q4 stock status Appendix E, published 2026',
  'SEDAR 68OA South Atlantic Scamp final stock assessment report, December 2022',
  'SEDAR68OA-WP-05 South Atlantic recreational scamp age and length compositions, 2022',
  'SEDAR 68OA South Atlantic Scamp SSC meeting output, July 2023')
paths <- file.path(cache, files)

if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the eight cited SEDAR and NOAA sources before screening.', call. = FALSE)
}
if (!all(vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L)))) {
  stop('A cached Scamp source is not a PDF.', call. = FALSE)
}

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

manifest <- data.frame(file = paths, url = urls, revision = revisions,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(paths)), bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)), stringsAsFactors = FALSE)
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) || !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(previous$sha256, manifest$sha256)) {
    stop('Cached Scamp source manifest does not match the reviewed files.', call. = FALSE)
  }
} else {
  write.csv(manifest, manifest_path, row.names = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

ids <- c('NOAA:10324', 'NOAA:10326')
indices <- match(ids, candidates$candidate_id)
if (anyNA(indices) || anyDuplicated(indices) ||
    any(candidates$scientific_name[indices] != 'Mycteroperca phenax') ||
    !identical(as.character(candidates$assessment_area[indices]),
      c('Gulf of Mexico', 'Southern Atlantic Coast'))) {
  stop('Expected distinct Gulf and South Atlantic Scamp Stock SMART rows.', call. = FALSE)
}
candidate_units <- c('noaa_scamp_yellowmouth_gulf_complex',
  'noaa_scamp_yellowmouth_south_atlantic_complex')
if (any(stocks$scientific_name %in% c('Mycteroperca phenax', 'Mycteroperca interstitialis')) ||
    any(candidates$candidate_unit_id[-indices] %in% candidate_units, na.rm = TRUE)) {
  stop('A Scamp candidate conflicts with an existing canonical or candidate stock unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id %in% candidate_units) ||
    any(inputs$assessment_id %in% candidate_units) ||
    any(outputs$assessment_id %in% candidate_units)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}

reviews <- list(
  list(candidate_unit_id = candidate_units[1], match_status = 'new',
    screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2022 Gulf operational assessment includes nominal annual age compositions for',
      'commercial vertical-line and longline, recreational charter/private, and headboat',
      'fleets. The cited 2022 working paper documents the proportions and age sampling, but',
      'publishes composition curves as figures rather than numeric annual age vectors. Table 4',
      'provides annual fish/trip sample counts; exact model age bins and observed vectors still',
      'need native-file or other source recovery.'),
    survey_age_evidence = paste(
      'The fitted indices are aggregate CPUE/video series, not age-stratified abundance',
      'indices. Age compositions are fishery-dependent fleet observations, not survey age',
      'indices.'),
    weights_evidence = paste(
      'The report specifies a fixed gutted-weight-to-fork-length relationship and a',
      'size-modified von Bertalanffy growth curve. These support derivation of weight-at-age,',
      'but the exact run-matched age-weight surface has not been recovered.'),
    maturity_evidence = paste(
      'The assessment uses an age-based logistic maturity relationship (slope -1.335; age',
      'at 50% maturity about 3.407 years) and sex-transition biology for this protogynous',
      'species. The fitted model is sex-structured.'),
    mortality_evidence = paste(
      'The report specifies an age-specific Lorenzen-scaled natural-mortality vector;',
      'the numerical run-matched vector remains to be extracted.'),
    timing_evidence = paste(
      'The assessment is annual and reports population states at the start of the year.',
      'Fractional observation timing for individual fleets and indices was not recovered.'),
    output_evidence = paste(
      'The final report contains annual sex-specific expected numbers-at-age for female',
      'and male fish (Tables 15A/16A and companion biomass tables), plus annual recruitment,',
      'biomass, and SSB. A run-matched full F-at-age table was not verified in this screen.'),
    detailed_source_url = paste(urls[1:5], collapse = '; '), review_date = '2026-10-30',
    decision_reason = paste(
      'The 2022 SEDAR 68OA is the latest full production assessment located. The 2025',
      'projection report updates advice projections from the earlier fitted assessment,',
      'rather than providing a new population-model fit. Official sources document age',
      'composition inputs and age-specific population outputs, but their numerical age',
      'composition arrays and several run-matched biological inputs remain unavailable.',
      'Eligibility is unresolved pending recovery of the exact age vectors/native files.'),
    notes = paste(
      'NOAA Stock SMART 10324 is the Gulf management unit. SEDAR 68OA assesses Scamp and',
      'Yellowmouth Grouper jointly because of species-identification concerns; do not treat',
      'the complex as Scamp-only. Stock SMART lists 2025 metadata, but NOAA FY2025 Q4 status',
      'and the 2025 projection report point to the 2022 full assessment. Source PDFs are in',
      'the ignored source_cache/noaa_scamp_sedar68oa/ with URL and checksum provenance.')),
  list(candidate_unit_id = candidate_units[2], match_status = 'new',
    screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2022 South Atlantic operational assessment fits age compositions from commercial,',
      'recreational, and SERFS sources. Age bins are pooled in the oldest ages (15+), with',
      'fleet coverage varying by year. Annual proportions are presented in figures and',
      'numeric sample summaries, not as a complete tabulated observation matrix.'),
    survey_age_evidence = paste(
      'The model includes SERFS age compositions plus aggregate abundance indices; the age',
      'compositions are not a continuous age-specific abundance-index series. The 2022',
      'report gives annual coverage and sampling methods; exact numeric age vectors remain',
      'to be recovered.'),
    weights_evidence = paste(
      'The assessment reports age-specific abundance and uses age/length biology, but the',
      'run-matched numerical weight-at-age input was not recovered from the reviewed PDFs.'),
    maturity_evidence = paste(
      'Age-specific maturity and sex-transition biology are described for the complex;',
      'the exact run-matched arrays still require extraction.'),
    mortality_evidence = paste(
      'The report documents an age-specific natural-mortality assumption for the fitted',
      'model; an exact numerical vector was not recovered in this screen.'),
    timing_evidence = paste(
      'The model is annual, with the terminal modeled year 2021. Fractional timing for',
      'each survey and fleet observation was not recovered.'),
    output_evidence = paste(
      'The final report includes annual total abundance-at-age (Table 6, thousands of fish)',
      'and instantaneous fishing mortality-at-age (Table 12, yr-1), together with SSB and',
      'recruitment outputs. The July 2023 SSC output confirms the model was used for advice.'),
    detailed_source_url = paste(urls[6:8], collapse = '; '), review_date = '2026-10-30',
    decision_reason = paste(
      'The SEDAR 68OA South Atlantic fit is the latest detailed production assessment',
      'located, with population outputs through 2021 and subsequent SSC advice in 2023.',
      'Its age-composition inputs are documented but not published as complete numerical',
      'arrays in the reviewed reports. Eligibility remains unresolved pending numeric',
      'composition and run-matched biological input recovery.'),
    notes = paste(
      'NOAA Stock SMART 10326 is distinct from the Gulf unit. The SEDAR model jointly',
      'assesses Scamp and Yellowmouth Grouper because the species can be difficult to',
      'distinguish; preserve this complex identity. The assessment terminal year is 2021;',
      '2023 is the SSC review/output year. Sources are cached under',
      'source_cache/noaa_scamp_sedar68oa/ with URL and checksum provenance.'))
)

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path,
    call. = FALSE)
  first <- if (physical_line == 1L) 1L else line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}

for (j in seq_along(indices)) {
  i <- indices[j]
  review <- reviews[[j]]
  if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
      !candidates$screening_status[i] %in% c('not_started', 'screened')) {
    stop('Scamp inventory row has a conflicting review: ', ids[j], call. = FALSE)
  }
  for (column in names(review)) candidates[[column]][i] <- review[[column]]
  replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
}

source_review <- c(
  '# NOAA Scamp inventory units: SEDAR 68OA', '',
  'Reviewed 2026-10-30. NOAA Stock SMART rows 10324 (Gulf of Mexico) and 10326 (South Atlantic) represent separate regional management units. SEDAR 68 operational assessments model Scamp (*Mycteroperca phenax*) jointly with Yellowmouth Grouper (*M. interstitialis*) because species identification in catches is uncertain.', '',
  '## Gulf of Mexico unit', '',
  'The latest full fit located is the SEDAR 68OA Gulf operational assessment, published August 2022 and fitted through 2020. NOAA’s FY2025 Q4 stock-status appendix identifies the last assessment year as 2022. The April 2025 SEDAR projection report updates advice projections using the existing model, rather than reporting a new fitted assessment.', '',
  'The Stock Synthesis model fits annual nominal age compositions for commercial vertical-line and longline, recreational charter/private, and headboat fleets. The 2022 working paper documents age sampling, age-composition construction and annual sample counts (1977–2020); annual age proportions are presented as figures rather than numeric vectors. The report also includes aggregate abundance indices, age-specific natural mortality, and age/length life-history inputs. Survey indices are aggregate, not age-stratified. Numeric sex-specific expected numbers-at-age are reported in thousands of fish (Tables 15A/16A and companion biomass tables), with recruitment, biomass and SSB outputs. The exact observed age vectors and run-matched numerical biological arrays remain to be recovered; a full F-at-age output was not verified in this pass.', '',
  'The Gulf unit remains eligibility-unresolved. Official assessment evidence confirms age-composition likelihoods and age-specific population outputs, but does not expose the complete numeric composition matrices as tables or machine-readable files in the reviewed sources.', '',
  '## South Atlantic unit', '',
  'The latest detailed fit located is the SEDAR 68OA South Atlantic operational assessment, published December 2022 and fitted through 2021. The South Atlantic SSC reviewed it in January 2023, with July 2023 advice output; the model remains the most recent full assessment identified in the current source review.', '',
  'The assessment fits commercial, recreational and SERFS age compositions, with oldest ages pooled at 15+ and coverage varying across fleets and years. Numeric age proportions are shown in figures, while the working paper provides sample descriptions and counts. The final report provides annual total abundance-at-age in thousands of fish (Table 6) and instantaneous fishing mortality-at-age in yr-1 (Table 12), as well as SSB and recruitment. The reviewed PDFs do not provide a complete numeric input matrix or the run-matched weight, maturity and mortality arrays needed for direct reconstruction.', '',
  'The South Atlantic unit also remains eligibility-unresolved pending recovery of numerical age-composition inputs and exact biological arrays. The Gulf and South Atlantic units must not be merged: they have separate regional assessment histories and management units, even though their fitted models include both species.', '',
  '## Sources and local cache', '',
  '- [SEDAR 68 assessment page](https://sedarweb.org/assessments/sedar-68/) lists the separate Gulf and South Atlantic operational assessment tracks and working papers.',
  '- [Gulf operational assessment report](https://sedarweb.org/documents/sedar-68oa-gulf-of-mexico-scamp-operational-assessment-final-stock-assessment-report/).',
  '- [Gulf age-composition working paper, SEDAR68OA-WP-05](https://sedarweb.org/documents/sedar-68oa-wp-05-gulf-of-mexico-scamp-mycteroperca-phenax-and-yellowmouth-grouper-mycteroperca-interstitialis-commercial-and-recreational-length-and-age-compositions/).',
  '- [Gulf ageing-error working paper, SEDAR68OA-WP-04](https://sedarweb.org/documents/sedar-68oa-wp-04-age-and-ageing-error-of-scamp-from-the-northern-gulf-of-mexico/).',
  '- [Gulf additional projections, April 2025](https://gulf-council-media.s3.amazonaws.com/uploads/2025/04/06d.-SEDAR68-OA-Gulf-Scamp-Projection-Report_April2025.pdf).',
  '- [NOAA FY2025 Q4 stock-status Appendix E](https://www.fisheries.noaa.gov/s3/2026-03/Appendix-E.pdf).',
  '- [South Atlantic operational assessment report](https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-operational-assessment-final-stock-assessment-report/).',
  '- [South Atlantic age-composition working paper, SEDAR68OA-WP-05](https://sedarweb.org/documents/sedar68oa-wp05south-atlantic-u-s-scamp-mycteroperca-phenax-age-and-length-composition-from-the-recreational-fisheries/).',
  '- [South Atlantic SSC meeting output, July 2023](https://sedarweb.org/documents/sedar-68oa-south-atlantic-scamp-july-2023-ssc-meeting-output/).', '',
  'All eight PDFs are cached locally under the ignored `source_cache/noaa_scamp_sedar68oa/` directory. Its `manifest.csv` records source URLs, document revisions, retrieval time, byte size and SHA-256 checksums. These are discovery records only; no canonical stock, assessment, input or output data were added.')
writeLines(source_review, review_path, useBytes = TRUE)
cat('Screened NOAA Stock SMART Scamp rows against the Gulf and South Atlantic SEDAR 68OA sources.\n')
