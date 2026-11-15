root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sprat_7de_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:spr.27.7de'
unit_id <- 'ices_sprat_english_channel'
files <- c(
  'ICES_Advice_4076.html',
  'ICES_SAG_source_21306.html',
  'ICES_SAG_charts_21306.html',
  'HAWG_2026.pdf',
  'WGIPS_2025.pdf'
)
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/4076',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21306',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=21306',
  'https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf',
  'https://literatur.thuenen.de/digbib_extern/dn070037.pdf'
)
revisions <- c(
  'ICES 2026 advice record 4076, advice for 1 July 2026 to 30 June 2027',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 21306',
  'ICES Stock Assessment Graphs, assessment year 2026, key 21306',
  'ICES HAWG 2026 full report, ICES Scientific Reports 8:16, DOI 10.17895/ices.pub.32790321.v1',
  'ICES WGIPS 2025 report, ICES Scientific Reports 7:54, DOI 10.17895/ices.pub.28890038'
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed ICES sources before screening ', id, '.', call. = FALSE)

sources <- data.frame(
  file = files, url = urls, retrieval_date = '2026-10-30', revision = revisions,
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  rows <- match(sources$file, previous$file)
  if (anyNA(rows) || !identical(previous$url[rows], sources$url) ||
      !identical(previous$revision[rows], sources$revision) ||
      !identical(tolower(previous$sha256[rows]), sources$sha256))
    stop('Cached ICES files differ from the reviewed source manifest.', call. = FALSE)
} else {
  write.csv(sources, manifest_path, row.names = FALSE, na = '')
}

advice <- paste(readLines(paths[1L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
charts <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
chart_flat <- gsub('[[:space:]]+', ' ', charts)
if (!all(vapply(c('spr.27.7de', '2026', 'Category', '3.3', '7 848 tonnes'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('spr.27.7de', 'Assessment Year', '2026', 'Biomass index',
      'tonnes', 'Age and Length'), grepl, logical(1L), x = source_data,
      ignore.case = TRUE)) ||
    !grepl('2025</td><td[^>]*>91577</td>', chart_flat, ignore.case = TRUE,
      perl = TRUE))
  stop('Cached ICES advice or stock-graph data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'spr.27.7de' ||
    candidates$scientific_name[row] != 'Sprattus sprattus' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'spr.27.7de', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES sprat identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest 2026 Category 3.3 advice uses catch/landings totals and a survey-biomass',
    'index. No catch-at-age or age-composition likelihood input is documented for the',
    'production advice run.'),
  survey_age_evidence = paste(
    'The annual October PELTIC survey supplies an aggregate biomass index. WGIPS 2025',
    'states that age and length composition are collected but are not yet used in the',
    'sprat assessment; the assessment does not use age-specific survey indices.'),
  weights_evidence = paste(
    'No age-specific weight input is used by the aggregate biomass-index harvest-rate',
    'assessment. Survey biomass is reported directly in tonnes.'),
  maturity_evidence = paste(
    'No maturity-at-age input is used by the Category 3 production advice method.'),
  mortality_evidence = paste(
    'No age-specific natural-mortality assumption or fitted M-at-age surface is part',
    'of the biomass-index assessment.'),
  timing_evidence = paste(
    'PELTIC is conducted annually in October and the preceding autumn survey informs',
    'the spring advice. Exact survey fraction is not specified in the reviewed sources.'),
  output_evidence = paste(
    'ICES reports the 2025 PELTIC biomass index as 91,577 tonnes and 2026 advice of no',
    'more than 7,848 tonnes catch. The 2026 graph metadata calls stock size a biomass',
    'index (tonnes); its table heading “SSB” should not be interpreted as spawning',
    'biomass. No N-at-age, recruitment-at-age, F-at-age, or M-at-age population',
    'outputs are reported.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The English Channel sprat unit is distinct from Baltic sprat in the canonical',
    'database. The latest completed 2026 ICES advice is a Category 3.3 data-limited',
    'assessment using aggregate PELTIC biomass and a constant harvest-rate rule, not',
    'an age-structured population model. Although the survey collects age and length',
    'composition, WGIPS states these are not used in the assessment. The case is',
    'ineligible for the age-disaggregated input/output set; no canonical numerical',
    'records were added.'),
  notes = paste(
    'Current assessment: ICES HAWG 2026, advice record 4076, stock-assessment graph',
    'key 21306; advice applies to 1 July 2026 through 30 June 2027 and uses survey',
    'biomass from 2025. HAWG reports biomass at 91,577 tonnes; graph metadata describes',
    'the quantity as a biomass index. Cached source files and SHA-256 checksums are in',
    'the ignored source cache. No earlier assessment was substituted.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES sprat candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', id, '.', call. = FALSE)
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
  bytes <- c(before, charToRaw(replacement), ending, after)
  writeBin(bytes, candidate_path)
}

cat('Screened ICES English Channel sprat as ineligible: the current assessment uses aggregate biomass, not age-structured inputs or outputs.\n')
