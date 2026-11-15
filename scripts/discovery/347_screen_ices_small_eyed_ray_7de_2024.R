root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_small_eyed_ray_7de_2024')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:rje.27.7de'
unit_id <- 'ices_small_eyed_ray_7de'
files <- c('ICES_Advice_3699.html', 'ICES_SAG_source_19097.html')
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/3699',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19097'
)
revisions <- c(
  'ICES 2024 advice record 3699, valid for 2025-2028',
  'ICES Stock Assessment Graphs source data, assessment year 2024, key 19097'
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
graph <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('rje.27.7de', '2024', 'Stock Category', '5',
    'landings should be no more than 32 tonnes', 'years 2025'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('rje.27.7de', '19097', '2024', 'Year</th><th scope="col">Landings'),
      grepl, logical(1L), x = graph, fixed = TRUE)) ||
    !grepl('2023</td><td[^>]*>48.61428</td>', graph, perl = TRUE))
  stop('Cached ICES advice or landings data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'rje.27.7de' ||
    candidates$scientific_name[row] != 'Raja microocellata' ||
    candidates$inventory_assessment_year[row] != 2024L ||
    any(stocks$authority_stock_id == 'rje.27.7de', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES small-eyed ray identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 ICES Category 5 advice uses landings only. The published source data',
    'table contains annual total landings in tonnes from 2009 through 2023; no',
    'catch-at-age or age-composition input is reported.'),
  survey_age_evidence = paste(
    'No survey abundance or age-specific survey index is reported for the current',
    'Category 5 advice.'),
  weights_evidence = paste(
    'No age-specific weight input is used or reported for the current advice.'),
  maturity_evidence = paste(
    'No maturity-at-age input is used or reported for the current advice.'),
  mortality_evidence = paste(
    'No age-specific fishing or natural-mortality estimate is used or reported.'),
  timing_evidence = paste(
    'A survey timing is not applicable because no survey index is used in the current',
    'Category 5 advice.'),
  output_evidence = paste(
    'The current advice is a landings limit of 32 tonnes per year for 2025-2028 and',
    'states that ICES cannot quantify corresponding catches. The graph reports',
    'landings only; no SSB, recruitment, N-at-age, F-at-age or M-at-age outputs are',
    'provided.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'This current English Channel small-eyed ray unit is distinct from the separate',
    'Bristol Channel/Celtic Sea North unit. Its latest advice is the 2024 ICES',
    'Category 5 method, based on landings data and without a quantitative population',
    'assessment. Sentinel-fishery monitoring in 7.e is data collection for possible',
    'future assessment development, not an input to this 2024 advice. The unit is',
    'ineligible for the age-disaggregated assessment set; no canonical data were added.'),
  notes = paste(
    'Advice record 3699 and Stock Assessment Graphs key 19097 are both for assessment',
    'year 2024. Advice is valid through 2028. The historical 2022 advice sheet also',
    'described the method as “no assessment” with landings-only inputs; those older',
    'values were not substituted for the current 2024 landings series or advice.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES small-eyed ray candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES English Channel small-eyed ray as landings-only Category 5 advice.\n')
