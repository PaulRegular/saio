root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_witch_northsea_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
report_file <- 'wgnssk_witch.pdf'
report_path <- file.path(cache, report_file)
report_url <- 'https://doi.org/10.17895/ices.pub.32676345.v2'
candidate_ids <- c('ICES:gug.27.3a47d', 'ICES:bll.27.3a47de', 'ICES:fle.27.420')
stock_ids <- c('gug.27.3a47d', 'bll.27.3a47de', 'fle.27.420')
scientific_names <- c('Eutrigla gurnardus', 'Scophthalmus rhombus', 'Platichthys flesus')
unit_ids <- c('ices_grey_gurnard_3a47d', 'ices_brill_3a47de', 'ices_flounder_420')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (!file.exists(report_path) || !file.exists(file.path(cache, 'wgnssk_witch.txt')))
  stop('Cache the 2026 WGNSSK report before screening these ICES units.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_row <- match(report_file, basename(sources$file))
if (is.na(source_row) || sources$url[source_row] !=
    'https://ndownloader.figshare.com/files/69947256' ||
    tolower(sources$sha256[source_row]) != sha256_file(report_path))
  stop('Cached report differs from its recorded source manifest.', call. = FALSE)

report_text <- tolower(paste(readLines(file.path(cache, 'wgnssk_witch.txt'), warn = FALSE),
  collapse = ' '))
report_normalized <- gsub('[^[:alnum:]]+', ' ', report_text)
section <- function(anchor, length = 6000L) {
  start <- regexpr(anchor, report_normalized, fixed = TRUE)[1L]
  if (start < 0L) return('')
  substr(report_normalized, start, start + length)
}
gurnard <- section('audit of gug 27 3a47d')
brill <- section('stock bll 27 3a47de')
flounder <- section('audit of fle 27 420')
if (!grepl('data limited dls category 3 method 2 3', gurnard, fixed = TRUE) ||
    !grepl('trends based assessment applying the rb rule', gurnard, fixed = TRUE) ||
    !grepl('spict assessment using commercial landings and three modelled exploitable biomass',
      brill, fixed = TRUE) ||
    !grepl('spict tuned with 3 survey index', flounder, fixed = TRUE))
  stop('The cached report does not support the reviewed current methods.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) ||
    !identical(as.character(candidates$official_stock_id[rows]), stock_ids) ||
    !identical(as.character(candidates$scientific_name[rows]), scientific_names) ||
    any(candidates$inventory_assessment_year[rows] != 2026L) ||
    any(stocks$authority_stock_id %in% stock_ids, na.rm = TRUE) ||
    any(stocks$scientific_name %in% scientific_names, na.rm = TRUE) ||
    any(assessments$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(inputs$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(outputs$assessment_id %in% unit_ids, na.rm = TRUE))
  stop('ICES stock identities conflict with the register or canonical database.',
    call. = FALSE)
initial_state <- all(candidates$match_status[rows] == 'unreviewed') &&
  all(candidates$screening_status[rows] == 'not_started') &&
  all(candidates$eligibility[rows] == 'unresolved') &&
  all(is.na(candidates$candidate_unit_id[rows]) | !nzchar(candidates$candidate_unit_id[rows]))
reviewed_state <- identical(as.character(candidates$match_status[rows]), rep('new', length(rows))) &&
  identical(as.character(candidates$screening_status[rows]), rep('screened', length(rows))) &&
  identical(as.character(candidates$eligibility[rows]), rep('ineligible', length(rows))) &&
  identical(as.character(candidates$candidate_unit_id[rows]), unit_ids)
if (!initial_state && !reviewed_state)
  stop('ICES units already have conflicting screening decisions.', call. = FALSE)

reviews <- list(
  list(
    catch_age_evidence = paste('The 2026 report describes a category-3 trends-based method',
      'with limited and incomplete catch data, not a catch-at-age population likelihood.'),
    survey_age_evidence = paste('IBTS Q1 and Q3 survey data support the stock index; the',
      'assessment does not use an age-specific survey abundance index.'),
    weights_evidence = paste('Length-weight relationships are used to calculate a mature',
      'biomass index; age-specific stock weights are not described as assessment inputs.'),
    maturity_evidence = paste('A length-based maturity ogive is used to calculate the',
      'mature biomass index; an age-structured maturity-at-age input is not described.'),
    mortality_evidence = 'The current category-3 index method does not report an age-structured mortality input.',
    timing_evidence = 'The report identifies Q1 and Q3 surveys but does not define timing for an age-structured abundance model.',
    output_evidence = paste('The 2026 advice uses the survey index and rb rule for catch advice;',
      'the report does not identify N-at-age or F-at-age population outputs.'),
    reason = paste('ICES unit gug.27.3a47d is a distinct current stock. The 2026 WGNSSK',
      'report describes a data-limited category-3 trends method using survey indices and',
      'limited catch, not an age-structured population assessment. Screen ineligible for',
      'the age-disaggregated set.'),
    note = paste('The 2026 WGNSSK audit describes IBTS Q1/Q3 indices, incomplete catch',
      'data, a length-weight and maturity-based mature-biomass indicator, and the rb advice',
      'rule. The current advice covers 2027-2028. No canonical numerical records were added.')
  ),
  list(
    catch_age_evidence = paste('The 2026 WGNSSK report describes a SPiCT assessment using',
      'commercial landings, not catch-at-age.'),
    survey_age_evidence = paste('The assessment uses three modelled exploitable-biomass',
      'indices; age-specific survey indices are not described.'),
    weights_evidence = 'The current SPiCT assessment summary does not describe stock weights-at-age.',
    maturity_evidence = 'The current SPiCT assessment summary does not describe maturity-at-age.',
    mortality_evidence = 'The current SPiCT assessment summary does not describe an age-structured M input.',
    timing_evidence = 'The report lists survey-index fleets but does not specify age-structured survey timing.',
    output_evidence = paste('The official report describes aggregate SPiCT biomass and fishing',
      'pressure results; it does not report N-at-age or F-at-age surfaces.'),
    reason = paste('ICES unit bll.27.3a47de is a distinct current stock. The 2026 WGNSSK',
      'report identifies SPiCT using landings and three modelled exploitable-biomass indices,',
      'not an age-structured population assessment. Screen ineligible for the age-disaggregated set.'),
    note = paste('The 2026 WGNSSK report says the current assessment is an update using SPiCT;',
      'discard information is used for advice but not included in the assessment model. No',
      'canonical numerical records were added.')
  ),
  list(
    catch_age_evidence = paste('The 2026 benchmark uses SPiCT and does not describe a',
      'catch-at-age population likelihood.'),
    survey_age_evidence = paste('SPiCT is tuned to DYFS, NS-IBTS Q1, and BTS Q3 survey indices;',
      'age-specific survey abundance inputs are not described.'),
    weights_evidence = 'The current SPiCT assessment summary does not describe stock weights-at-age.',
    maturity_evidence = 'The current SPiCT assessment summary does not describe maturity-at-age.',
    mortality_evidence = 'The current SPiCT assessment summary does not describe an age-structured M input.',
    timing_evidence = 'The report lists three survey indices but does not specify age-structured survey timing.',
    output_evidence = paste('The official 2026 benchmark reports aggregate SPiCT status and advice;',
      'it does not report N-at-age or F-at-age surfaces.'),
    reason = paste('ICES unit fle.27.420 is a distinct current stock with boundaries changed',
      'in the 2026 benchmark to exclude Kattegat. The accepted method is SPiCT with three',
      'survey indices, not an age-structured population assessment. Screen ineligible for',
      'the age-disaggregated set; keep fle.27.21-23 as a separate unit.'),
    note = paste('The 2026 WGNSSK report identifies a benchmark transition from the category-3',
      'chr rule to a category-2 SPiCT assessment and states Kattegat is no longer part of this',
      'unit. No canonical numerical records were added.')
  )
)

for (i in seq_along(rows)) {
  row <- rows[i]
  review <- reviews[[i]]
  candidates$candidate_unit_id[row] <- unit_ids[i]
  candidates$match_status[row] <- 'new'
  candidates$screening_status[row] <- 'screened'
  candidates$eligibility[row] <- 'ineligible'
  candidates$import_status[row] <- 'not_started'
  candidates$catch_age_evidence[row] <- review$catch_age_evidence
  candidates$survey_age_evidence[row] <- review$survey_age_evidence
  candidates$weights_evidence[row] <- review$weights_evidence
  candidates$maturity_evidence[row] <- review$maturity_evidence
  candidates$mortality_evidence[row] <- review$mortality_evidence
  candidates$timing_evidence[row] <- review$timing_evidence
  candidates$output_evidence[row] <- review$output_evidence
  candidates$detailed_source_url[row] <- report_url
  candidates$review_date[row] <- '2026-10-30'
  candidates$decision_reason[row] <- review$reason
  candidates$notes[row] <- review$note
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  for (row in rev(sort(rows))) {
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', candidates$candidate_id[row],
        '.', call. = FALSE)
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
  }
  writeBin(bytes, candidate_path)
}

cat('Screened three current WGNSSK units as ineligible for age-disaggregated assessment.\n')
