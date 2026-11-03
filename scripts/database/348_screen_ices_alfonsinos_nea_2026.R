root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_alfonsinos_nea_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:alf.27.nea'
unit_id <- 'ices_alfonsinos_nea'
files <- c(
  'ICES_Advice_6154.html',
  'ICES_StockGraphs_22402.html',
  'ICES_SourceData_22402.html',
  'ICES_StockAssessment_22402.xml'
)
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/6154',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22402',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22402',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22402'
)
revisions <- c(
  'ICES 2026 advice record 6154, valid for 2027-2028',
  'ICES Stock Assessment Graphs, assessment year 2026, key 22402',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 22402',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 22402'
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
graphs <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
xml <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('alf.27.nea', '2026', 'Stock Category', '3.2', '194 tonnes'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('alf.27.nea', '2026', 'Kilograms per day', 'Landings',
      'Fishing Pressure Proxy'), grepl, logical(1L), x = graphs, ignore.case = TRUE)) ||
    !all(vapply(c('alf.27.nea', 'Assessment Year', '2026', 'B_index',
      'Length-based Fishing Pressure Proxy', 'Kilograms per day', 'Landings'),
      grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
    !all(vapply(c('<StockCategory>3.2</StockCategory>', '<ModelType>DLS</ModelType>',
      '<StockSizeDescription>B_index</StockSizeDescription>',
      '<FishingPressureDescription>Length-based Fishing</FishingPressureDescription>',
      '<RecruitmentAge></RecruitmentAge>', '<Fage></Fage>'),
      grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'alf.27.nea' ||
    candidates$scientific_name[row] != 'Beryx' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'alf.27.nea', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES alfonsinos identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 Category 3.2 advice reports annual landings in tonnes for 1990-2025,',
    'not catch-at-age or age-composition likelihood inputs.'),
  survey_age_evidence = paste(
    'The current public graph reports a biomass index in kg/day for 2003-2016 and',
    '2019-2025 and a length-based fishing-pressure proxy. No age-specific abundance',
    'index or survey age-composition likelihood is reported.'),
  weights_evidence = paste(
    'No age-specific weight input is used or reported for the length-based indicator',
    'advice.'),
  maturity_evidence = paste(
    'No maturity-at-age input is used or reported for the current Category 3.2 method.'),
  mortality_evidence = paste(
    'The reported fishing-pressure quantity is a length-based proxy, not an estimated',
    'F-at-age or M-at-age surface. No age-specific natural-mortality assumption is',
    'reported.'),
  timing_evidence = paste(
    'The reported kg/day biomass index is not identified as a survey series; no survey',
    'timing is reported for this assessment.'),
  output_evidence = paste(
    'The 2026 graph reports a commercial biomass index in kg/day, annual landings in',
    'tonnes and a length-based fishing-pressure proxy. Its source data describe stock',
    'size as B_index; the table heading “SSB” does not establish spawning biomass.',
    'No recruitment, N-at-age, F-at-age or M-at-age population outputs are reported.',
    'Advice limits landings to 194 tonnes in each of 2027 and 2028 and says ICES cannot',
    'quantify the corresponding catches.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest current-unit advice is the 2026 ICES Category 3.2 assessment. The',
    'public stock graph identifies the model as DLS and reports a kg/day biomass',
    'index, annual landings and a length-based fishing-pressure proxy; its XML has no',
    'recruitment age or F-at-age field. These aggregate/length-based series do not',
    'establish age-disaggregated population inputs or outputs. The unit is therefore',
    'ineligible for the age-structured assessment set; no canonical data were added.'),
  notes = paste(
    'Advice record 6154 and Stock Assessment Graphs key 22402 both refer to the 2026',
    'assessment. Advice covers 2027-2028; the graph reports landings through 2025.',
    'The printed “SSB” column is mapped to StockSize in XML, whose declared measure',
    'is B_index in kg/day, so it is not treated as SSB. Cached files and SHA-256 checks',
    'are in the ignored source cache.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES alfonsinos candidate already has a conflicting review.', call. = FALSE)
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
  replacement <- sub('\r?\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  bytes <- c(before, charToRaw(replacement), ending, after)
  writeBin(bytes, candidate_path)
}

cat('Screened ICES alfonsinos as length-based Category 3.2 advice.\n')
