root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_ling_5a_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:lin.27.5a'
unit_id <- 'ices_ling_5a'

files <- c('MFRI_ling_2026_technical_report.html',
  'ICES_stock_graphs_2026_key_22475.html', 'ICES_source_data_2026_key_22475.html',
  'ICES_ling_5a_Stock_Annex_2023.pdf', 'ICES_ling_5a_Stock_Annex_2023_metadata.json')
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_techreport_en.html',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22475',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22475',
  'https://ndownloader.figshare.com/files/41399199',
  'https://api.figshare.com/v2/articles/23599644'
)
revisions <- c(
  'MFRI Ling 2026 technical report, published 2026-06-12',
  'ICES Standard Graphs, assessment year 2026, stock lin.27.5a, key 22475',
  'ICES source data, assessment year 2026, stock lin.27.5a, key 22475',
  'ICES Stock Annex DOI 10.17895/ices.pub.23599644.v1; PDF filename identifies version 2022',
  'Figshare API metadata for ICES Stock Annex DOI 10.17895/ices.pub.23599644.v1'
)
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 100L))
  stop('Cache the reviewed ICES and MFRI sources before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(sources$url[source_rows], urls) ||
    !identical(sources$revision[source_rows], revisions) ||
    !identical(tolower(sources$sha256[source_rows]),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached source files differ from the reviewed source manifest.', call. = FALSE)

report_text <- paste(readLines(file.path(cache,
  'MFRI_ling_2026_technical_report.txt'), warn = FALSE), collapse = ' ')
annex_text <- paste(readLines(file.path(cache,
  'ICES_ling_5a_Stock_Annex_2023.txt'), warn = FALSE), collapse = ' ')
graphs <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
if (!grepl('Figure 8: Ling. Catch at age from the commercial fishery', report_text,
      fixed = TRUE) ||
    !grepl('catch in numbers', report_text, fixed = TRUE) ||
    !grepl('Figure 15: Ling. Age disaggregated indices', report_text, fixed = TRUE) ||
    !grepl('gillnet survey', report_text, fixed = TRUE) ||
    !grepl('Figure 16: Ling. Stock weights from the spring survey', report_text,
      fixed = TRUE) ||
    !grepl('Figure 17: Ling. Maturity at age in the survey', report_text, fixed = TRUE) ||
    !grepl('M=0.15', annex_text, fixed = TRUE) ||
    !grepl('id="lblYear" class="text">2026', graphs, fixed = TRUE) ||
    !grepl('lin.27.5a', graphs, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">2', source_data, fixed = TRUE) ||
    !grepl('lblFAge">8-11', source_data, fixed = TRUE) ||
    !grepl('thousands', source_data, fixed = TRUE) ||
    !grepl('tonnes', source_data, fixed = TRUE))
  stop('Cached public sources do not match the reviewed stock and input/output evidence.',
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
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id) != 1L ||
    candidates$official_stock_id[row] != 'lin.27.5a' ||
    candidates$scientific_name[row] != 'Molva molva' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'lin.27.5a', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Ling identity conflicts with the register or canonical database.', call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('Figure 8 reports commercial catch numbers-at-age by cohort.',
    'The 2023 Stock Annex describes ages 2-12+ and notes that catch age reading stopped',
    'in 1998 and resumed in 2013. Values are figure-based; digitization must preserve',
    'missing years and validate age/year coverage.'),
  survey_age_evidence = paste('Figure 15 reports age-disaggregated spring and autumn',
    'groundfish-survey indices and the April gillnet survey. The surveys began in 1985',
    'for spring and 1996 for autumn and gillnet; numerical inputs are figure-based.'),
  weights_evidence = paste('Figure 10 reports catch weight-at-age and Figure 16 reports',
    'stock weight-at-age from the spring survey. Stock weights are also used for SSB.'),
  maturity_evidence = paste('Figure 17 reports maturity-at-age from the spring survey.',
    'The report states that maturity before 1985 is held at 1985 levels.'),
  mortality_evidence = paste('The ICES 2023 Stock Annex states that natural mortality is',
    'fixed at M = 0.15 because no direct information is available.'),
  timing_evidence = paste('The spring groundfish survey is conducted in March, the autumn',
    'survey in October, and the gillnet survey in early April. Month-based fractional-year',
    'timing would be an approximation.'),
  output_evidence = paste('ICES 2026 Standard Graphs/source data report recruitment at age 2',
    '(thousands), SSB and total biomass (tonnes), and F for ages 8-11 with 2.5% and 97.5%',
    'limits. They do not provide N-at-age or F-at-age surfaces.'),
  detailed_source_url = paste(c(
    'https://www.hafogvatn.is/static/extras/images/6_lin_2026_1_techreport_en.html',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22475',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22475',
    'https://doi.org/10.17895/ices.pub.23599644.v1'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('ICES unit lin.27.5a is not represented in the canonical stocks table.',
    'The latest 2026 assessment is age-based SAM and provides catch numbers-at-age, three',
    'age-specific survey series, catch and stock weights, maturity, and fixed M = 0.15.',
    'Official outputs include recruitment, SSB, and F with uncertainty. Input matrices are',
    'mainly figure-based and catch age readings have a historical gap, so source curation',
    'requires digitization and coverage checks. Eligible for source curation.'),
  notes = paste('The MFRI 2026 technical report describes the current SAM assessment and',
    'includes figures through the 2026 advice cycle. The 2023 Stock Annex gives the model',
    'settings and fixed M assumption; its published PDF filename identifies version 2022.',
    'The report recommends 7,657 tonnes for the 2026/2027 fishing year. Source files, URLs,',
    'pinned revisions, retrieval dates, and SHA-256 values are recorded in',
    'source_cache/discovery_ices_ling_5a_2026/sources.csv. No canonical numerical records',
    'were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('Ling candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', candidate_id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

cat('Screened ICES ling as an eligible figure-based source-curation candidate.\n')
