root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_ices_iceland_wolffish_2026')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:caa.27.5a'
i <- which(candidates$candidate_id == id)
if (length(i) != 1L) stop('Expected one ICES inventory row: ', id, call. = FALSE)
if (any(stocks$authority_stock_id == 'caa.27.5a', na.rm = TRUE)) {
  stop('A canonical record already uses caa.27.5a; review the match before screening.',
    call. = FALSE)
}

review <- list(
  candidate_unit_id = 'ices_atlantic_wolffish_iceland_5a',
  official_stock_id = 'caa.27.5a',
  scientific_name = 'Anarhichas lupus',
  stock_name = 'Atlantic wolffish in Division 5.a (Iceland grounds)',
  assessment_area = 'Icelandic Waters',
  inventory_assessment_year = 2026L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 production report describes catch-at-age from 1979 onward, except that',
    'age-disaggregated catches are unavailable for 1981-1997 and total landings are',
    'used in those years. The 2022 Stock Annex gives an earlier range (catch-at-age',
    'in 1979 and 1996 onward; landings in 1980-1995); resolve this version difference',
    'against run-specific source files before importing numeric inputs.'
  ),
  survey_age_evidence = paste(
    'The 2026 assessment uses age-disaggregated Icelandic spring groundfish survey',
    '(IS-SMB) indices from 1985 and autumn groundfish survey (IS-SMH) indices from',
    '2000, ages 4-16+. The spring survey is conducted in March; autumn survey samples',
    'are mostly from October. The 2022 Stock Annex says autumn age composition uses',
    'spring-survey age data, which should be checked against the current run.'
  ),
  weights_evidence = paste(
    'The 2026 report shows annual stock weights-at-age from spring-survey data; the',
    '2022 Stock Annex describes catch weights derived from catch weight-length data',
    'and stock weights from the spring survey, both divided by abundance. Stock',
    'weights were smoothed with a 3-year moving average in the annex. Current annual',
    'numeric weight matrices were not located outside figures.'
  ),
  maturity_evidence = paste(
    'The 2026 report presents annual proportion-mature-at-age. The 2022 Stock Annex',
    'describes proportions derived from a length-based maturity ogive fit to autumn',
    'survey and commercial data, with an annual effect fixed over years and 3-year',
    'moving-average smoothing. Spawning stock is based on mature females; current',
    'numeric matrices were not located outside figures.'
  ),
  mortality_evidence = paste(
    'Natural mortality is assumed fixed at 0.15 per year for all ages; it is not',
    'estimated in the production assessment.'
  ),
  timing_evidence = paste(
    'The fitted indices are the March spring survey (about 0.17 of a calendar year)',
    'and the autumn survey, sampled mostly in October (about 0.83). These are calendar',
    'timing approximations; an exact model fraction was not located.'
  ),
  output_evidence = paste(
    'The ICES 2026 assessment key 22633 reports annual age-4 recruitment (thousands),',
    'SSB (tonnes), and total F for ages 10-15, with 95% intervals. The last fitted',
    'year is 2025; the 2026-2028 values in the MFRI report are projections. Full',
    'fitted N-at-age and F-at-age arrays were not found in the reviewed output tables.'
  ),
  detailed_source_url = paste(
    'https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_techreport_en.html;',
    'https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_advice_en.html;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22633;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22633;',
    'https://doi.org/10.17895/ices.pub.22819988;',
    'https://doi.org/10.17895/ices.pub.19663971'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest 2026 production assessment is a SAM catch-at-age model with catch',
    'numbers at age, two age-disaggregated survey series, age-specific biology, fixed',
    'M and comparable SSB, recruitment and F outputs. It qualifies for source curation.',
    'Most current input matrices are plotted rather than tabulated, and the catch-age',
    'year coverage differs between the 2026 report and the 2022 Stock Annex; resolve',
    'those gaps before importing values.'
  ),
  notes = paste(
    'Distinct Icelandic management unit; NOAA Stock SMART 11562 is a different',
    'Gulf of Maine/Georges Bank unit of the same species. The current MFRI production',
    'assessment is key 22633, assessment year 2026, with fitted data through 2025.',
    'No run-matched 2026 numeric input bundle, current ICES TAF repository or fitted',
    'SAM object was located in the reviewed sources. A stockassessment package is not',
    'installed in this R execution environment, so fitfromweb retrieval could not be',
    'tested; this is not evidence that no object exists. The 2022 Stock Annex and',
    'WKICEMP framework report are cached or cross-referenced in the local ignored',
    'source cache. See discovery/source_reviews/ices_atlantic_wolffish_iceland_2026.md.'
  )
)
already_applied <- all(vapply(names(review), function(column) {
  identical(as.character(candidates[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (!already_applied) {
  if (candidates$screening_status[i] != 'not_started' ||
      candidates$match_status[i] != 'unreviewed') {
    stop('Inventory row has a conflicting prior review: ', id, call. = FALSE)
  }
  for (column in names(review)) candidates[[column]][i] <- review[[column]]
  lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(candidates) + 1L) {
    stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
  }
  row <- candidates[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  writeLines(lines, candidate_path, useBytes = TRUE)
}

files <- c(
  'wolffish_5a_techreport_2026.html',
  'wolffish_5a_advice_2026.html',
  'ices_stock_graphs_22633_2026.html',
  'ices_source_data_22633_2026.html',
  'wolffish_5a_stock_annex_2022.pdf',
  '../discovery_ices_iceland_plaice_2026/wkicemp_2022_framework.pdf'
)
paths <- file.path(cache, files)
if (!all(file.exists(paths)) || any(file.info(paths)$size == 0)) {
  stop('Expected cached source files are missing or empty.', call. = FALSE)
}
pdf_files <- grepl('\\.pdf$', files)
pdf_ok <- vapply(paths[pdf_files], function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_ok)) stop('A cached source does not have a PDF signature.', call. = FALSE)
sha256_file <- function(path) {
  output <- system2('certutil', c('-hashfile',
    normalizePath(path, winslash = '/', mustWork = TRUE), 'SHA256'), stdout = TRUE)
  hash <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output), value = TRUE)
  if (length(hash) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hash)
}
manifest <- data.frame(
  url = c(
    'https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_techreport_en.html',
    'https://www.hafogvatn.is/static/extras/images/09_caa_2026_1_advice_en.html',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22633',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22633',
    'https://ndownloader.figshare.com/files/40570238',
    'https://doi.org/10.17895/ices.pub.19663971'
  ),
  retrieved_on = '2026-10-29',
  revision = c(
    'MFRI 2026 production assessment; data through 2025',
    'MFRI advice 2026/2027; published 2026-06-12',
    'ICES assessment key 22633; assessment year 2026',
    'ICES assessment key 22633; assessment year 2026',
    'ICES Stock Annex DOI 10.17895/ices.pub.22819988.v1',
    'ICES WKICEMP DOI 10.17895/ices.pub.19663971; 2022 report'
  ),
  bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)),
  status = c(rep('cached', 5L), 'cached_reference'),
  notes = c(
    'Detailed current production report; age-based input matrices and biology are primarily plotted.',
    'Official MFRI advice and assessment-method summary.',
    'Published outputs; key 22633 pins the production assessment and includes projections.',
    'Structured annual output series; key 22633 pins the production assessment.',
    'Current stock-specific framework and input construction.',
    'Shared locally cached benchmark report; reused from the Icelandic plaice source cache to avoid a duplicate 35 MB file.'
  ),
  file = files,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(cache, 'sources.csv'), row.names = FALSE, na = '')
cat('Screened ICES Atlantic wolffish in Division 5.a as a new, eligible source-curation candidate.\n')
