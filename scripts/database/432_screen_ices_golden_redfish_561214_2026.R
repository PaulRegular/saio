root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_golden_redfish_561214_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:reg.27.561214'
unit_id <- 'ices_golden_redfish_561214'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

split_json_array <- function(value) {
  value <- substring(value, 2L, nchar(value) - 1L)
  if (!nzchar(value)) return(character())
  chars <- strsplit(value, '', fixed = TRUE)[[1L]]
  pieces <- character()
  start <- 1L
  depth <- 0L
  quoted <- FALSE
  escaped <- FALSE
  for (i in seq_along(chars)) {
    char <- chars[i]
    if (quoted) {
      if (escaped) escaped <- FALSE
      else if (char == '\\') escaped <- TRUE
      else if (char == '"') quoted <- FALSE
    } else if (char == '"') {
      quoted <- TRUE
    } else if (char %in% c('[', '{')) {
      depth <- depth + 1L
    } else if (char %in% c(']', '}')) {
      depth <- depth - 1L
    } else if (char == ',' && depth == 0L) {
      pieces <- c(pieces, paste(chars[start:(i - 1L)], collapse = ''))
      start <- i + 1L
    }
  }
  pieces <- c(pieces, paste(chars[start:length(chars)], collapse = ''))
  trimws(pieces)
}

extract_balanced_array <- function(value, start) {
  chars <- strsplit(substring(value, start), '', fixed = TRUE)[[1L]]
  depth <- 0L
  quoted <- FALSE
  escaped <- FALSE
  for (i in seq_along(chars)) {
    char <- chars[i]
    if (quoted) {
      if (escaped) escaped <- FALSE
      else if (char == '\\') escaped <- TRUE
      else if (char == '"') quoted <- FALSE
    } else if (char == '"') {
      quoted <- TRUE
    } else if (char == '[') {
      depth <- depth + 1L
    } else if (char == ']') {
      depth <- depth - 1L
      if (depth == 0L) return(paste(chars[seq_len(i)], collapse = ''))
    }
  }
  stop('Could not read an embedded table array.', call. = FALSE)
}

json_string_value <- function(value, key) {
  token <- paste0('"', key, '":"')
  position <- regexpr(token, value, fixed = TRUE)[1L]
  if (position < 1L) return('')
  start <- position + nchar(token)
  chars <- strsplit(substring(value, start), '', fixed = TRUE)[[1L]]
  out <- character()
  escaped <- FALSE
  for (char in chars) {
    if (escaped) {
      out <- c(out, switch(char, n = '\n', r = '\r', t = '\t', '"' = '"', '/' = '/', '\\' = '\\', char))
      escaped <- FALSE
    } else if (char == '\\') {
      escaped <- TRUE
    } else if (char == '"') {
      return(paste(out, collapse = ''))
    } else {
      out <- c(out, char)
    }
  }
  stop('Could not read an embedded table string.', call. = FALSE)
}

parse_mfri_table <- function(html, heading) {
  title <- paste0('<h3>', heading, '</h3>')
  start <- regexpr(title, html, fixed = TRUE)[1L]
  if (start < 1L) stop('Missing MFRI table section: ', heading, call. = FALSE)
  after <- substring(html, start + nchar(title))
  next_heading <- regexpr('<h3', after, fixed = TRUE)[1L]
  section <- if (next_heading > 0L) substring(after, 1L, next_heading - 1L) else after
  widget <- regexpr('<script type="application/json" data-for="[^"]+">.*?</script>',
    section, perl = TRUE)
  if (widget[1L] < 1L) stop('Missing MFRI table data: ', heading, call. = FALSE)
  script <- regmatches(section, widget)
  json <- sub('^<script[^>]*>', '', script, perl = TRUE)
  json <- sub('</script>$', '', json)
  data_pos <- regexpr('"data":\\[', json, perl = TRUE)
  if (data_pos[1L] < 1L) stop('Missing MFRI table columns: ', heading, call. = FALSE)
  array_start <- data_pos[1L] + attr(data_pos, 'match.length') - 1L
  data_array <- extract_balanced_array(json, array_start)
  columns <- lapply(split_json_array(data_array), function(column) {
    lapply(split_json_array(column), function(value) {
      value <- trimws(value)
      if (value %in% c('null', '""', '')) NA_character_
      else if (startsWith(value, '"') && endsWith(value, '"')) substring(value, 2L, nchar(value) - 1L)
      else value
    })
  })
  container <- json_string_value(json, 'container')
  cell_matches <- gregexpr('<th[^>]*>.*?</th>', container, perl = TRUE)
  cells <- regmatches(container, cell_matches)[[1L]]
  headers <- trimws(gsub('<[^>]+>', '', gsub('\\\\/', '/', cells)))
  if (length(headers) != length(columns))
    stop('MFRI table headers do not match data columns: ', heading, call. = FALSE)
  year_column <- match('Year', headers)
  age_columns <- which(grepl('^\\d+\\+?$', headers))
  if (is.na(year_column) || !length(age_columns))
    stop('MFRI table has no year or age columns: ', heading, call. = FALSE)
  years <- as.integer(unlist(columns[[year_column]], use.names = FALSE))
  values <- vapply(columns[age_columns], function(column)
    as.numeric(unlist(column, use.names = FALSE)), numeric(length(years)))
  if (is.null(dim(values))) values <- matrix(values, ncol = length(age_columns))
  valid <- rowSums(is.finite(values)) > 0L
  list(years = years, ages = headers[age_columns], values = values,
    valid_years = years[valid])
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
expected_files <- c('ICES_2026_advice.html', 'ICES_2026_charts.html',
  'ICES_2026_source_data.html', 'MFRI_2026_advice.html', 'MFRI_2026_tables.html',
  'MFRI_2026_technical_report.html', 'MFRI_2023_Golden_Redfish_report.pdf')
manifest_rows <- match(expected_files, manifest$file)
paths <- file.path(cache, manifest$file[manifest_rows])
if (nrow(manifest) != length(expected_files) || anyNA(manifest_rows) ||
    anyDuplicated(manifest$file) || any(manifest$retrieved_on[manifest_rows] != '2026-10-30') ||
    any(is.na(manifest$revision[manifest_rows]) | !nzchar(manifest$revision[manifest_rows])))
  stop('The cached golden-redfish source manifest is incomplete.', call. = FALSE)
if (any(!file.exists(paths)) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(tolower(manifest$sha256[manifest_rows]),
      unname(vapply(paths, sha256_file, character(1L)))))
  stop('Cached golden-redfish sources do not match their manifest.', call. = FALSE)

read_source <- function(name) paste(readLines(file.path(cache, name),
  warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
report_html <- read_source('MFRI_2026_technical_report.html')
report_text <- gsub('(?is)<script\\b.*?</script>', ' ', report_html, perl = TRUE)
report_text <- gsub('(?is)data:image/[^;]+;base64,[A-Za-z0-9+/=]+', ' ', report_text, perl = TRUE)
report_text <- gsub('(?is)<[^>]+>', ' ', report_text, perl = TRUE)
report_text <- gsub('[[:space:]]+', ' ', report_text)
tables_html <- read_source('MFRI_2026_tables.html')
source_data <- read_source('ICES_2026_source_data.html')
advice <- read_source('ICES_2026_advice.html')

if (!all(vapply(c('Golden redfish', 'SAM model', '1966', '25+', '1995',
    'Natural mortality', 'March', 'October'), grepl, logical(1L),
    x = report_text, ignore.case = TRUE)) ||
    !all(vapply(c('22441', '2026', 'Recruitment', 'SSB', 'Fishing Pressure',
      'thousands', 'tonnes'), grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
    !all(vapply(c('reg.27.561214', '2026', '22441', '5102'), grepl, logical(1L),
      x = advice, ignore.case = TRUE)))
  stop('The cached advice and reports do not match the reviewed 2026 assessment.', call. = FALSE)

parsed_tables <- list(
  catch = parse_mfri_table(tables_html, 'Catch at age'),
  catch_weight = parse_mfri_table(tables_html, 'Catch-weights'),
  stock_weight = parse_mfri_table(tables_html, 'Stock-weights'),
  maturity = parse_mfri_table(tables_html, 'Maturity at age'),
  spring_index = parse_mfri_table(tables_html, 'IS-SMB index'),
  autumn_index = parse_mfri_table(tables_html, 'IS-SMH index'),
  stock_numbers = parse_mfri_table(tables_html, 'Stock in numbers'),
  fishing_mortality = parse_mfri_table(tables_html, 'Fishing mortality'))
ages <- as.character(6:25)
if (!all(vapply(parsed_tables, function(x) identical(x$ages, ages), logical(1L))) ||
    !all(1995:2025 %in% parsed_tables$catch$valid_years) ||
    !all(1966:2025 %in% parsed_tables$stock_weight$valid_years) ||
    min(parsed_tables$maturity$valid_years) != 1986L ||
    max(parsed_tables$maturity$valid_years) != 2025L ||
    min(parsed_tables$spring_index$valid_years) != 1985L ||
    max(parsed_tables$spring_index$valid_years) != 2025L ||
    min(parsed_tables$autumn_index$valid_years) != 1996L ||
    max(parsed_tables$autumn_index$valid_years) != 2025L ||
    !all(1966:2026 %in% parsed_tables$stock_numbers$valid_years) ||
    !all(1966:2025 %in% parsed_tables$fishing_mortality$valid_years))
  stop('Published golden-redfish tables do not have the documented year-age coverage.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != 'reg.27.561214' ||
    register$scientific_name[row] != 'Sebastes norvegicus' ||
    as.character(register$inventory_assessment_year[row]) != '2026' ||
    any(tolower(stocks$authority_stock_id) == 'reg.27.561214', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$assessment_id, inputs$assessment_id,
      outputs$assessment_id), na.rm = TRUE))
  stop('Golden-redfish identity conflicts with the candidate register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id, matched_stock_id = '', match_status = 'new',
  screening_status = 'screened', eligibility = 'eligible', import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 MFRI production report says catch-at-age and total landings are available from 1966, but the age-based SAM model uses catch-at-age from 1995 onward. The published table reports numbers at ages 6-25+ in thousands for 1995-2025. Icelandic commercial length samples and ALKs supply the age allocation; estimated age catches are scaled to total landings across stock areas.'),
  survey_age_evidence = paste(
    'The production report describes autumn survey age data from 1996-2025; the MFRI table publishes age-disaggregated IS-SMH indices in numbers for ages 6-25+. The October survey was not conducted in 2011; the report says the missing autumn index was replaced by the 2010 and 2012 mean. The published 2011 age-table row should therefore be treated as imputed, not a direct survey observation. The model also uses a spring survey biomass index; the published IS-SMB age table is not treated as the model input because the report says spring observations enter as a single biomass series.'),
  weights_evidence = paste(
    'MFRI tables publish commercial catch weights-at-age and stock weights-at-age in grams for ages 6-25+ over 1966-2025. The report describes substitution between sources when a value is missing and two-year smoothing of stock weights.'),
  maturity_evidence = paste(
    'The source table publishes proportions mature at age for ages 6-25+ in 1986-2025. The report derives age maturity from a fixed length ogive and age-length keys, then smooths it over two years below age 15 and four years at ages 15+.'),
  mortality_evidence = paste(
    'Natural mortality is fixed at 0.05 for ages 6-24 and 0.1 for the 25+ group; it is not estimated in the current production model.'),
  timing_evidence = paste(
    'The production report identifies the Icelandic spring survey as March and the autumn survey as October. The model uses a spring aggregate biomass index and autumn length/age information. Exact within-year timing fractions and observation-likelihood weights are not reported in the reviewed sources.'),
  output_evidence = paste(
    'MFRI tables report stock numbers-at-age in thousands for ages 6-25+ from 1966-2026 and fishing mortality-at-age through 2025. The 2026 N row is a forecast/state beyond the 2025 observation horizon. ICES 2026 source data report age-6 recruitment in thousands, SSB in tonnes, and F for ages 9-19, with published intervals for aggregate outputs; age-specific uncertainty is not reported in the reviewed tables.'),
  detailed_source_url = paste(
    'https://asd.ices.dk/viewAdvice/5102;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22441;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22441;',
    'https://www.hafogvatn.is/static/extras/images/5_red_2026_1_techreport_en.html;',
    'https://www.hafogvatn.is/static/extras/images/5_red_2026_1_tables_en_v2.html;',
    'https://www.hafogvatn.is/static/extras/images/04-goldenredfish_tr1388153.pdf;',
    'https://doi.org/10.17895/ices.pub.22304638', sep = ' '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest 2026 production assessment for this current ICES unit is age-based SAM, with run-specific published catch-at-age, autumn survey age observations, stock and catch weights, maturity, fixed M, and official N-at-age/F-at-age and aggregate outputs. Source coverage is sufficient for eligibility, although native model files, exact observation weights and exact survey timing fractions were not recovered. No canonical source values have been imported yet.'),
  notes = paste(
    'Current ICES unit reg.27.561214 covers subareas 5, 6, 12, and 14 and is distinct from the existing Northeast Arctic golden-redfish unit reg.27.1-2. The 2026 assessment uses data through 2025; the MFRI tables also show a 2026 population forecast. The spring biomass series and autumn age data have different observation structures. The MFRI 2023 report and WKBNORTH 2023 benchmark provide framework context only; no historical values are substituted. Eligibility is a source-curation screen, not a claim that every likelihood detail is available.' )
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
normalize_text <- function(x) ifelse(is.na(x), '', as.character(x))
same_review <- all(vapply(names(review), function(column)
  identical(normalize_text(register[[column]][row]), normalize_text(review[[column]])),
  logical(1L)))
prior_review <- review
prior_review$survey_age_evidence <- sub(
  'The October survey was not conducted in 2011; the report says the missing autumn index was replaced by the 2010 and 2012 mean. The published 2011 age-table row should therefore be treated as imputed, not a direct survey observation.',
  'The October survey was not conducted in 2011.',
  prior_review$survey_age_evidence, fixed = TRUE)
same_prior_review <- all(vapply(names(prior_review), function(column)
  identical(normalize_text(register[[column]][row]), normalize_text(prior_review[[column]])),
  logical(1L)))
if (!initial && !same_review && !same_prior_review)
  stop('Golden-redfish candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) register[[column]][row] <- review[[column]]

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES golden redfish reg.27.561214 as eligible for source curation; no canonical values were added.\n')
screen_result <- list(candidate = register[row, , drop = FALSE], tables = parsed_tables,
  manifest = manifest[manifest_rows, , drop = FALSE])
