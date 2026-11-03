root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_ices_iceland_plaice_2026')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:ple.27.5a'
i <- which(candidates$candidate_id == id)
if (length(i) != 1L) stop('Expected one ICES inventory row: ', id, call. = FALSE)
if (any(stocks$authority_stock_id == 'ple.27.5a', na.rm = TRUE)) {
  stop('A canonical record already uses ple.27.5a; review the match before screening.',
    call. = FALSE)
}
review <- list(
  candidate_unit_id = 'ices_plaice_iceland_5a',
  official_stock_id = 'ple.27.5a',
  scientific_name = 'Pleuronectes platessa',
  stock_name = 'Plaice in Division 5.a (Iceland grounds)',
  assessment_area = 'Icelandic Waters',
  inventory_assessment_year = 2026L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 MFRI production report describes commercial catch-at-age from 1979 onward.',
    'Figure 11 displays catch numbers by age, but the full annual matrices are not',
    'provided as a numerical table or run file; chart digitization would be required.'
  ),
  survey_age_evidence = paste(
    'The SAM uses age-disaggregated Icelandic spring groundfish survey (IS-SMB) indices',
    'from 1985 onward, shown in Figure 19. The report does not provide the complete',
    'numerical age-by-year index matrix in a table or downloadable run bundle.'
  ),
  weights_evidence = paste(
    'Spring-survey stock weights-at-age are shown graphically. Ages 9+ are smoothed with',
    'a 3-year running average; pre-1985 values are held at the 1985 levels.'
  ),
  maturity_evidence = paste(
    'Female maturity-at-age is derived from annual maturity-at-length ogives and length',
    'distributions, then smoothed with a 3-year running average. Pre-1985 values use 1985.'
  ),
  mortality_evidence = paste(
    'Natural mortality is fixed at 0.15 per year for all ages; it is not estimated.'
  ),
  timing_evidence = paste(
    'The fitted age-specific index is the spring survey conducted in March. A one-eighth-year',
    'fraction is a reasonable timing approximation, but the exact model fraction was not found.'
  ),
  output_evidence = paste(
    'The 2026 MFRI report and ICES assessment key 22531 provide annual age-3 recruitment,',
    'SSB and F at ages 5-10 with uncertainty; catch totals are also reported. The published',
    '2026 assessment graphs do not expose the full fitted N-at-age or F-at-age arrays.'
  ),
  detailed_source_url = paste(
    'https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html;',
    'https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_advice_en.html;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22531;',
    'https://doi.org/10.17895/ices.pub.20132660.v1;',
    'https://doi.org/10.17895/ices.pub.19663971'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The current 2026 production assessment is a SAM catch-at-age model with reported',
    'commercial catch-at-age, an age-specific spring survey index, age-specific biological',
    'inputs and comparable official outputs. It is eligible for source curation, but source',
    'input matrices are primarily graphical and require documented digitization; no',
    'run-matched numerical input bundle or fitted SAM object was found.'
  ),
  notes = paste(
    'Distinct current Icelandic management unit, not the existing North Sea or Baltic plaice',
    'records. MFRI reports the 2026 assessment with data through 2025 and age 12 as the plus',
    'group; ICES Standard Graphs assessment key 22531 is pinned for output verification.',
    'The MFRI public assessment-data directory located during review only lists annual CSV',
    'folders through 2018. The 2022 stock annex and WKICEMP benchmark report document the',
    'model framework; the current report does not link a 2026 model repository or fitted object.',
    'See discovery/source_reviews/ices_plaice_iceland_2026.md.'
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
  'plaice_5a_techreport_2026.html',
  'plaice_5a_advice_2026.html',
  'ices_stock_graphs_22531_2026.html',
  'ices_source_data_22531_2026.html',
  'plaice_5a_stock_annex_2022.pdf',
  'wkicemp_2022_framework.pdf'
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
  if (requireNamespace('digest', quietly = TRUE)) {
    return(digest::digest(file = path, algo = 'sha256'))
  }
  output <- system2('certutil', c('-hashfile',
    normalizePath(path, winslash = '/', mustWork = TRUE), 'SHA256'), stdout = TRUE)
  hash <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output), value = TRUE)
  if (length(hash) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hash)
}
manifest <- data.frame(
  url = c(
    'https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_techreport_en.html',
    'https://www.hafogvatn.is/static/extras/images/23_ple_2026_1_advice_en.html',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22531',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22531',
    'https://ndownloader.figshare.com/files/36009905',
    'https://ndownloader.figshare.com/files/35127877'
  ),
  retrieved_on = '2026-10-29',
  revision = c(
    'MFRI 2026 assessment; data through 2025',
    'MFRI advice 2026/2027; published 2026-06-12',
    'ICES assessment key 22531; assessment year 2026',
    'ICES assessment key 22531; assessment year 2026',
    'ICES Stock Annex DOI 10.17895/ices.pub.20132660.v1',
    'ICES WKICEMP DOI 10.17895/ices.pub.19663971; 2022 report'
  ),
  bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)),
  status = 'cached',
  notes = c(
    'Detailed MFRI production assessment report; age inputs and biology are predominantly plotted.',
    'Official MFRI advice and assessment-method summary.',
    'Published annual assessment outputs; includes the 2026 projection row.',
    'Structured annual assessment output table; assessment key pins the run.',
    'Framework/configuration document cited by the production report.',
    'ICES benchmark workshop report for assessment settings and data review.'
  ),
  file = files,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(cache, 'sources.csv'), row.names = FALSE, na = '')
cat('Screened ICES plaice in Division 5.a as a new, eligible source-curation candidate.\n')
