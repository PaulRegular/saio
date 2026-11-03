root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_small_eyed_ray_7fg_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rje.27.7fg'
unit_id <- 'ices_small_eyed_ray_7fg'

files <- c('advice_2026.html', 'charts_2026.html', 'source_data_2026.html')
urls <- c(
  'https://asd.ices.dk/viewAdvice/7191',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=25855',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25855')
revisions <- c(
  'ICES advice for 2027-2028; assessment year 2026; assessment key 25855',
  'ICES Standard Graphs, assessment year 2026, key 25855',
  'ICES Standard Graphs source data, assessment year 2026, key 25855')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the current ICES advice and Standard Graphs pages before screening ', candidate_id, '.',
    call. = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_rows <- match(files, basename(manifest$file))
if (anyNA(manifest_rows) ||
    !identical(as.character(manifest$url[manifest_rows]), urls) ||
    !identical(as.character(manifest$revision[manifest_rows]), revisions) ||
    !identical(toupper(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached ICES source files differ from their recorded manifest.', call. = FALSE)

advice <- paste(readLines(paths[1L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
charts <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('rje.27.7fg', advice, fixed = TRUE) ||
    !grepl('2026', advice, fixed = TRUE) ||
    !grepl('Stock Category</div>', advice, fixed = TRUE) ||
    !grepl('>3</div>', advice, fixed = TRUE) ||
    !grepl('value="124"', advice, fixed = TRUE) ||
    !grepl('cannot quantify the corresponding', advice, fixed = TRUE) ||
    !grepl('lblStockCode', charts, fixed = TRUE) ||
    !grepl('rje.27.7fg', charts, fixed = TRUE) ||
    !grepl('lblYear', charts, fixed = TRUE) ||
    !grepl('2026', charts, fixed = TRUE) ||
    !grepl('lblStockSizeDescription">B_index', source_data, fixed = TRUE) ||
    !grepl('Kilograms per hour', source_data, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">0', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE) ||
    !grepl('Low SSB</th><th scope="col">SSB</th><th scope="col">High SSB</th><th scope="col">Landings</th>',
      source_data, fixed = TRUE))
  stop('Cached ICES sources do not match the reviewed aggregate-data evidence.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row_index] != 'rje.27.7fg' ||
    register$scientific_name[row_index] != 'Raja microocellata' ||
    as.character(register$inventory_assessment_year[row_index]) != '2026' ||
    any(stocks$authority_stock_id == 'rje.27.7fg', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Small-eyed ray identity conflicts with the inventory or canonical database.', call. = FALSE)

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current Category 3 advice provides no age-specific catch or catch-composition',
    'series. The published stock graph reports annual landings in aggregate, not catch-at-age.'),
  survey_age_evidence = paste('ICES reports a single aggregate biomass index in kg/hour; the current source data',
    'do not report survey abundance or composition by age.'),
  weights_evidence = 'No weight-at-age inputs are reported for the current assessment.',
  maturity_evidence = 'No maturity-at-age inputs are reported for the current assessment.',
  mortality_evidence = 'The current advice does not report an age-structured mortality model or age-specific natural mortality.',
  timing_evidence = 'The aggregate index is annual; a fractional within-year survey timing is not reported.',
  output_evidence = paste('The 2026 source data show aggregate biomass-index/SSB values and landings; age and length',
    'recruitment are blank, and no numeric N-, F-, or M-at-age outputs are published.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest published advice is the 2026 Category 3 assessment. Its public inputs and',
    'outputs are aggregate landings, a survey biomass index, and length-based fishing-pressure information.',
    'The official source data contain no age-specific likelihood inputs or population outputs, so this stock',
    'is ineligible for the age-disaggregated assessment set.'),
  notes = paste('The official 2026 ICES advice and Standard Graphs pages, retrieval date, revisions, file sizes,',
    'and SHA-256 checksums are recorded under source_cache/discovery_ices_small_eyed_ray_7fg_2026/.',
    'This 7.f-7.g stock unit is distinct from the 7.d-7.e assessment. No canonical numerical records or',
    'tinyAM translation were added.'),
  stringsAsFactors = FALSE,
  check.names = FALSE)

initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved'
reviewed_state <- register$match_status[row_index] == 'new' &
  register$candidate_unit_id[row_index] == unit_id &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'ineligible'
if (!initial_state && !reviewed_state)
  stop('Small-eyed ray candidate already has a conflicting review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row_index]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row_index] <- review[[name]]
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], candidate_id)
  }
}
cat('Screened ICES small-eyed ray rje.27.7fg as ineligible for age-disaggregated inputs and outputs.\n')
