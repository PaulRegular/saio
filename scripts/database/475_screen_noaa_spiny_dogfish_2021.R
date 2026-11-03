root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_spiny_dogfish_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_hashes <- c(
  pacific_spiny_dogfish_2021_assessment.pdf = '0996998a9a976af619f130f5161d2ab0ae6d0189d72a283b9ff150f89aa21e4c',
  pacific_spiny_dogfish_2021_model_files.zip = '0bd6c1d93e621a70b0ec5e23480eaa255d3a497da4fdccdf9a6dc8c05ccf7cbe',
  pacific_spiny_dogfish_2021_supplementary_tables.xlsx = '9479e1e2f5d5dd92388da98161061fa47046267e00ae7061abec46140f68652f',
  pacific_spiny_dogfish_2021_star_panel.pdf = '7f512a7f6fed6d47f065a829ce2731d22fb31d85afb861177c320e4b2d9f200b',
  noaa_pacific_spiny_dogfish_status_2026.html = '8eae78c1ffbba50d10eae46036b45ba9aba0879670e969646d02266a95737c13')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The spiny dogfish source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached spiny dogfish source differs from its manifest: ', file, call. = FALSE)
}

archive <- file.path(cache, 'extracted', 'Spiny_Dogfish_Model_For_DeVore')
data_file <- file.path(archive, 'Dogfish_data.ss')
control_file <- file.path(archive, 'Dogfish_control.ss')
starter_file <- file.path(archive, 'starter.ss')
report_file <- file.path(archive, 'Report.sso')
if (!all(file.exists(c(data_file, control_file, starter_file, report_file))))
  stop('The extracted spiny dogfish model archive is incomplete.', call. = FALSE)

data_lines <- readLines(data_file, warn = FALSE)
control_lines <- readLines(control_file, warn = FALSE)
starter_lines <- readLines(starter_file, warn = FALSE)
report_lines <- readLines(report_file, warn = FALSE)
report_text <- paste(report_lines, collapse = ' ')
read_scalar <- function(lines, pattern, label) {
  row <- grep(pattern, lines, ignore.case = TRUE)[1L]
  if (is.na(row)) stop('Missing ', label, '.', call. = FALSE)
  as.numeric(strsplit(trimws(lines[row]), '[[:space:]]+')[[1L]][1L])
}

age_bin_header <- grep('^#_agebin_vector', data_lines)[1L]
age_bin_line <- if (is.na(age_bin_header)) '' else
  sub('[[:space:]]+#_agebin_vector.*$', '', data_lines[age_bin_header + 1L])
age_bins <- suppressWarnings(as.integer(strsplit(trimws(age_bin_line),
  '[[:space:]]+')[[1L]]))
age_header <- grep('^#_Yr[[:space:]]+Seas[[:space:]]+FltSvy[[:space:]]+Gender[[:space:]]+Part[[:space:]]+Ageerr',
  data_lines)[1L]
age_end <- which(grepl('^-9999[[:space:]]', data_lines) & seq_along(data_lines) > age_header)[1L]
if (is.na(age_header) || is.na(age_end) || length(age_bins) != 72L ||
    !identical(age_bins, 0:71))
  stop('The pinned model does not contain the expected age-composition input.', call. = FALSE)
age_rows <- lapply(data_lines[(age_header + 1L):(age_end - 1L)], function(line) {
  line <- sub('[[:space:]]+#_.*$', '', line)
  values <- suppressWarnings(as.numeric(strsplit(trimws(line), '[[:space:]]+')[[1L]]))
  if (length(values) < 9L || anyNA(values[1:9])) return(NULL)
  values[1:9]
})
age_rows <- age_rows[!vapply(age_rows, is.null, logical(1L))]
age_data <- as.data.frame(do.call(rbind, age_rows))
names(age_data) <- c('year', 'season', 'fleet', 'sex', 'part', 'age_error',
  'length_lower', 'length_upper', 'sample_size')

fleet_header <- grep('^#_fleetinfo', data_lines)[1L]
fleet_rows <- data_lines[(fleet_header + 2L):(fleet_header + 14L)]
fleet_names <- sub('.*#_([0-9]+)[[:space:]]*$', '', fleet_rows)
fleet_types <- vapply(strsplit(trimws(fleet_rows), '[[:space:]]+'), function(x)
  as.integer(x[1L]), integer(1L))
status_page <- paste(readLines(file.path(cache, 'noaa_pacific_spiny_dogfish_status_2026.html'),
  warn = FALSE), collapse = ' ')
status_page <- gsub('&nbsp;|&#160;', ' ', status_page)

if (read_scalar(data_lines, '^1916[[:space:]]+#_styr', 'start year') != 1916 ||
    read_scalar(data_lines, '^2020[[:space:]]+#_endyr', 'terminal year') != 2020 ||
    read_scalar(data_lines, '^13[[:space:]]+#_Nfleets', 'fleet count') != 13 ||
    length(fleet_names) != 13L || sum(fleet_types == 1L) != 8L || sum(fleet_types == 3L) != 5L ||
    !identical(sort(unique(age_data$year)), 2010) ||
    !identical(sort(unique(age_data$fleet)), 11) ||
    !identical(sort(unique(age_data$sex)), as.numeric(1:2)) ||
    nrow(age_data) != 33L || sum(age_data$sample_size) != 515 ||
    min(age_data$length_lower) != 20 || max(age_data$length_upper) != 100 ||
    !grepl('2021 stock assessment', status_page, fixed = TRUE) ||
    !grepl('Age_Comp_Fit_Summary', report_text, fixed = TRUE) ||
    !grepl('CATCH_AT_AGE', report_text, fixed = TRUE) ||
    !grepl('F_AT_AGE', report_text, fixed = TRUE) ||
    !grepl('NUMBERS_AT_AGE', report_text, fixed = TRUE) ||
    !grepl('BIOMASS_AT_AGE', report_text, fixed = TRUE) ||
    !grepl('Biology_at_age_in_endyr', report_text, fixed = TRUE) ||
    !grepl('Maturity: 1', report_text, fixed = TRUE) ||
    !grepl('NatMort: 0', report_text, fixed = TRUE) ||
    !any(grepl('Dogfish_data.ss', starter_lines, fixed = TRUE)) ||
    !any(grepl('Dogfish_control.ss', starter_lines, fixed = TRUE)) ||
    !any(grepl('NatM_p_1_Fem_GP_1', control_lines, fixed = TRUE)) ||
    !any(grepl('0.065', control_lines, fixed = TRUE)))
  stop('The cached 2021 model does not match the reviewed source evidence.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

candidate_id <- 'NOAA:10702'
candidate_unit_id <- 'noaa_spiny_dogfish_pacific_coast_2021'
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$inventory_assessment_year[row] != '2021' ||
    candidates$official_stock_id[row] != '10702' ||
    candidates$stock_name[row] != 'Spiny dogfish - Pacific Coast')
  stop('The NOAA Pacific Coast spiny dogfish inventory identity changed.', call. = FALSE)
if (any(stocks$stock_id == candidate_unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical spiny dogfish record now exists; recheck the stock crosswalk.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = 'The accepted fit has fleet catch biomass and fleet length compositions, not observed catch-at-age. Its source quantities can support a documented, model-derived reconstruction by combining catches and length compositions with the WCGBTS age-at-length key; this must not be described as observed catch age. Fishery age samples were evaluated but excluded from the accepted fit because they were noisy and lacked smaller fish needed to estimate growth.',
  survey_age_evidence = 'The model has five aggregate abundance indices. The only fitted age data are 2010 WCGBTS conditional age-at-length observations (33 sex-by-length cells, 515 fish, ages 0-71). Together with annual survey length compositions they can support an approximate age-specific index reconstruction, but no annual age-specific index was directly observed.',
  weights_evidence = 'The model archive reports sex-specific weight-at-age derived from fitted growth and fixed weight-length relationships. Preserve its model-derived status and two-sex structure.',
  maturity_evidence = 'Maturity is specified as a length-logistic biological relationship; maturity-at-age is model-derived and should retain the sex-specific life-history definitions and source values.',
  mortality_evidence = 'Natural mortality is fixed at 0.065 per year for both sexes; the 2021 assessment does not estimate M.',
  timing_evidence = 'The model uses one 12-month season, a January spawning month, season-long fishery catches, and survey timing codes in the native fleet table. Convert these timing fields explicitly before creating tinyAM observations; no fractional-year value is assigned in this screen.',
  output_evidence = 'The official Report.sso includes age-specific catch, numbers, fishing mortality, biomass, and end-year biological surfaces. The 2021 report provides spawning-output summaries and uncertainty; outputs do not substitute for age-specific observed inputs.',
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2022/01/status-of-the-pacific-spiny-dogfish-shark-resource-off-the-continental-u-s-pacific-coast-in-2021-october-19-2021.pdf/;',
    'https://www.pcouncil.org/documents/spiny-dogfish-2021-model-files-zip-file/;',
    'https://www.pcouncil.org/documents/spiny-dogfish-assessment-supplementary-table-excel/;',
    'https://www.pcouncil.org/documents/spiny-dogfish-stock-assessment-review-star-panel-report/;',
    'https://www.fisheries.noaa.gov/species/pacific-spiny-dogfish'),
  review_date = '2026-10-31',
  decision_reason = 'Eligible for source curation with an explicit age-length-key reconstruction. The 2021 PFMC production assessment is the latest full assessment identified; its source model includes eight fishery catch series, annual length compositions, five aggregate abundance indices, a single 2010 WCGBTS conditional age-at-length sample, and age-specific official outputs. Age-specific catch and index observations are not direct inputs; any reconstruction must expose the assumptions and limitations of transferring that one survey-year age-length key.',
  notes = 'New U.S. Pacific Coast assessment unit, NOAA Stock SMART ID 10702; do not merge with the separate DFO inside or outside British Columbia units. Stock SMART lists the scientific name as Squalus acanthias, while current NOAA materials use Squalus suckleyi for Pacific spiny dogfish. Later 2023 catch-status information does not replace the 2021 full assessment run.')

expected <- c(list(candidate_id = candidate_id), review)
current <- lapply(names(expected), function(column) as.character(candidates[[column]][row]))
names(current) <- names(expected)
already_reviewed <- all(vapply(names(expected), function(column)
  identical(current[[column]], as.character(expected[[column]])), logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
required_current <- c('candidate_unit_id', 'match_status', 'screening_status',
  'eligibility', 'import_status')
partial_review <- all(vapply(required_current, function(column)
  identical(current[[column]], as.character(expected[[column]])), logical(1L))) &&
  all(vapply(setdiff(names(expected), required_current), function(column) {
    value <- current[[column]]
    is.na(value) || !nzchar(value) || identical(value, as.character(expected[[column]]))
  }, logical(1L)))
if (!pristine && !already_reviewed && !partial_review)
  stop('The NOAA spiny dogfish candidate already has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened the NOAA Pacific Coast spiny dogfish 2021 assessment for age-data eligibility.\n')
