root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_copper_california_2023')
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
  copper_ca_2023_preassessment_workshop.pdf = 'cbf946f472196070b54a5a15a4f8ad63a1469a40bd158928c6c1b017a152693b',
  copper_ca_2023_star_panel.pdf = 'b9b652c8a1ba5ab18711375c25aade9735ed45eef933e269c4e5967e997f742d',
  copper_ca_north_2023_assessment.pdf = '77d7355d39387321b4cb658cdb4c8278087ce7095bebae55964b37c6741dcc1b',
  copper_ca_north_2023_model_files.zip = '7e73cb89a067a1c2e47a037139951dbbe495bc19bbd9223f69eb4129b6a8507a',
  copper_ca_south_2023_assessment.pdf = 'ac9f8217c49c958df45c977f391768631ddcce7c8cac9bd2850fe5468a768662',
  copper_ca_south_2023_model_files.zip = '126dca017d25406195fdf7a7f08f5c05702ebbc653dbc1bd5bac33b576400644')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The California copper source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached California copper source differs from its manifest: ', file, call. = FALSE)
}

read_model_data <- function(area, data_file, control_file, starter_file, report_file,
                            expected_rows, expected_conditional, expected_marginal,
                            expected_years, expected_survey_months) {
  paths <- file.path(cache, 'extracted', area, if (area == 'north') 'nca' else 'sca')
  files <- file.path(paths, c(data_file, control_file, starter_file, report_file))
  if (!all(file.exists(files))) stop('The extracted ', area, ' model archive is incomplete.', call. = FALSE)
  data_lines <- readLines(files[1L], warn = FALSE)
  control_lines <- readLines(files[2L], warn = FALSE)
  starter_lines <- readLines(files[3L], warn = FALSE)
  report_lines <- readLines(files[4L], warn = FALSE)
  report_text <- paste(report_lines, collapse = ' ')
  read_scalar <- function(pattern, label) {
    row <- grep(pattern, data_lines)[1L]
    if (is.na(row)) stop('Missing ', area, ' ', label, '.', call. = FALSE)
    as.numeric(strsplit(trimws(data_lines[row]), '[[:space:]]+')[[1L]][1L])
  }

  n_age_bins <- read_scalar('^51[[:space:]]+#_N_age_bins', 'age-bin count')
  age_header <- grep('^51[[:space:]]+#_N_age_bins', data_lines)[1L]
  age_bins <- suppressWarnings(as.integer(strsplit(trimws(data_lines[age_header + 1L]),
    '[[:space:]]+')[[1L]]))
  n_fleets <- read_scalar('^[0-9]+[[:space:]]+#_Nfleets', 'fleet count')
  fleet_header <- grep('^#_fleet_type fishery_timing', data_lines)[1L]
  fleet_rows <- data_lines[(fleet_header + 1L):(fleet_header + n_fleets)]
  fleet_types <- vapply(strsplit(trimws(fleet_rows), '[[:space:]]+'),
    function(x) as.integer(x[1L]), integer(1L))
  fleet_months <- vapply(strsplit(trimws(fleet_rows), '[[:space:]]+'),
    function(x) as.integer(x[2L]), integer(1L))
  fleet_catch_units <- vapply(strsplit(trimws(fleet_rows), '[[:space:]]+'),
    function(x) as.integer(x[4L]), integer(1L))

  age_data_header <- grep('^#_yr[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr',
    data_lines)[1L]
  age_data_end <- which(grepl('^-9999[[:space:]]', data_lines) &
    seq_along(data_lines) > age_data_header)[1L]
  if (is.na(age_data_header) || is.na(age_data_end))
    stop('Missing ', area, ' age-composition block.', call. = FALSE)
  age_rows <- data_lines[(age_data_header + 1L):(age_data_end - 1L)]
  age_rows <- age_rows[grepl('^[[:space:]]*[0-9]{4}[[:space:]]', age_rows)]
  age_values <- lapply(age_rows, function(line)
    suppressWarnings(as.numeric(strsplit(trimws(line), '[[:space:]]+')[[1L]])))
  age_widths <- vapply(age_values, length, integer(1L))
  if (!length(age_values) || any(age_widths != 9L + 2L * n_age_bins))
    stop('Unexpected ', area, ' age-composition row structure.', call. = FALSE)
  age_data <- as.data.frame(do.call(rbind, lapply(age_values, `[`, seq_len(9L))))
  names(age_data) <- c('year', 'month', 'fleet', 'sex', 'part', 'age_error',
    'length_lower', 'length_upper', 'sample_size')
  conditional <- age_data$length_lower >= 0 & age_data$length_upper >= 0
  marginal <- age_data$length_lower < 0 & age_data$length_upper < 0

  if (read_scalar('^1916[[:space:]]+#_StartYr', 'start year') != 1916 ||
      read_scalar('^2022[[:space:]]+#_EndYr', 'terminal year') != 2022 ||
      read_scalar('^1[[:space:]]+#_Nseas', 'season count') != 1 ||
      read_scalar('^12[[:space:]]+#_months/season', 'months per season') != 12 ||
      read_scalar('^1[[:space:]]+#_spawn_month', 'spawning month') != 1 ||
      read_scalar('^2[[:space:]]+#_Ngenders', 'sex count') != 2 ||
      read_scalar('^50[[:space:]]+#_Nages', 'maximum model age') != 50 ||
      n_age_bins != 51 || !identical(age_bins, 0:50) ||
      length(fleet_types) != n_fleets || sum(fleet_types == 1L) != 4L ||
      any(fleet_catch_units[fleet_types == 1L] != 1L) ||
      sum(fleet_types == 3L) != n_fleets - 4L ||
      !identical(sort(unique(fleet_months[fleet_types == 3L])), expected_survey_months) ||
      nrow(age_data) != expected_rows || sum(conditional) != expected_conditional ||
      sum(marginal) != expected_marginal ||
      !identical(range(age_data$year), expected_years) ||
      !grepl('Age_Comp_Fit_Summary', report_text, fixed = TRUE) ||
      !grepl('CATCH_AT_AGE report:40', report_text, fixed = TRUE) ||
      !grepl('F_AT_AGE report:39', report_text, fixed = TRUE) ||
      !grepl('NUMBERS_AT_AGE', report_text, fixed = TRUE) ||
      !grepl('BIOMASS_AT_AGE', report_text, fixed = TRUE) ||
      !grepl('NatMort: 0', report_text, fixed = TRUE) ||
      !grepl('Maturity: 1', report_text, fixed = TRUE) ||
      !any(grepl('0.108', control_lines, fixed = TRUE)) ||
      !any(grepl(data_file, starter_lines, fixed = TRUE)) ||
      !any(grepl(control_file, starter_lines, fixed = TRUE)))
    stop('The cached ', area, ' California copper model does not match the reviewed source evidence.',
      call. = FALSE)
  list(age_rows = nrow(age_data), conditional = sum(conditional), marginal = sum(marginal),
    years = range(age_data$year), ages = age_bins, fleets = n_fleets,
    catch_units = unique(fleet_catch_units[fleet_types == 1L]))
}

north <- read_model_data('north', '2023_ca_n_copper.dat', '2023_ca_n_copper.ctl',
  'starter.ss', 'Report.sso', expected_rows = 489L, expected_conditional = 450L,
  expected_marginal = 39L, expected_years = c(1978, 2022), expected_survey_months = 7L)
south <- read_model_data('south', '2023_ca_s_copper.dat', '2023_ca_s_copper.ctl',
  'starter.ss', 'Report.sso', expected_rows = 771L, expected_conditional = 747L,
  expected_marginal = 24L, expected_years = c(1975, 2022),
  expected_survey_months = c(7L, 9L))

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

candidate_ids <- c('NOAA:15332', 'NOAA:15333')
candidate_unit_id <- 'noaa_copper_rockfish_california_2023'
candidate_rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(candidate_rows) || anyDuplicated(candidate_ids) ||
    any(candidates$official_stock_id[candidate_rows] != c('15332', '15333')) ||
    any(candidates$inventory_assessment_year[candidate_rows] != '2023') ||
    any(candidates$scientific_name[candidate_rows] != 'Sebastes caurinus') ||
    !identical(candidates$stock_name[candidate_rows], c(
      'Copper rockfish - Northern California', 'Copper rockfish - Southern California')))
  stop('The NOAA California copper inventory identities changed.', call. = FALSE)
if (any(stocks$stock_id == candidate_unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical California copper record now exists; recheck the stock crosswalk.', call. = FALSE)

shared_inputs <- paste0(
  'The 2023 California Stock Synthesis data file has four fishery catch fleets ',
  'with annual catch in biomass units, length compositions, and fitted age ',
  'composition records. These are not observed annual catch numbers-at-age. ',
  'A catch-at-age series for tinyAM would require a documented reconstruction ',
  'from model catches, length compositions, and age-at-length information.')
shared_surveys <- paste0(
  'The assessment uses aggregate survey indices and length data. The native ',
  'model also fits age-composition records, including conditional age-at-length ',
  'observations; the data do not contain a direct annual abundance-at-age index. ',
  'Any age-specific index for tinyAM would require a documented reconstruction ',
  'from the matching aggregate index, length composition, and age information.')
shared_weights <- paste0(
  'The model uses sex-specific growth and length-weight relationships; the ',
  'control files do not read an empirical weight-at-age file. Weight-at-age ',
  'surfaces are model-derived from the fitted biological relationships.')
shared_maturity <- paste0(
  'Maturity is represented by a length-logistic relationship in the fitted ',
  'Stock Synthesis models; maturity-at-age is derived from that relationship ',
  'and modeled growth rather than supplied as an observed annual age matrix.')
shared_mortality <- 'Natural mortality is fixed at 0.108 per year for female and male model groups; it is not an estimated M surface.'
shared_timing <- paste0(
  'The models have one 12-month season and January spawning. Survey timing is ',
  'specified in the native fleet configuration (month 7 in the northern model; ',
  'months 7 and 9 in the southern model). Do not convert these codes to a ',
  'fractional year without documenting the within-season convention.')
shared_outputs <- paste0(
  'The official model reports age-specific catch, numbers, fishing mortality, ',
  'and biomass surfaces for ages 0-50 through 2022, in addition to aggregate ',
  'spawning output and recruitment. North and south model outputs remain separate.')
source_urls <- paste(
  'https://www.pcouncil.org/documents/2024/03/status-of-copper-rockfish-along-the-u-s-california-coast-north-of-point-conception-in-2023.pdf/;',
  'https://www.pcouncil.org/documents/ca-copper-rockfish-north-2023-model-files-zip-file/;',
  'https://www.pcouncil.org/documents/2024/02/status-of-copper-rockfish-sebastes-caurinus-along-the-u-s-california-coast-south-of-point-conception-in-2023-november-2023.pdf/;',
  'https://www.pcouncil.org/documents/ca-copper-rockfish-south-2023-model-files-zip-file/;',
  'https://www.pcouncil.org/documents/2023/06/star-panel-1-report-for-copper-rockfish-in-ca-rex-sole-and-shortspine-thornyhead.pdf/;',
  'https://www.pcouncil.org/documents/report-of-the-pre-assessment-workshop-for-2023-groundfish-stock-assessments-of-copper-rockfish-canary-rockfish-and-black-rockfish/')

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = shared_inputs,
  survey_age_evidence = shared_surveys,
  weights_evidence = shared_weights,
  maturity_evidence = shared_maturity,
  mortality_evidence = shared_mortality,
  timing_evidence = shared_timing,
  output_evidence = shared_outputs,
  detailed_source_url = source_urls,
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Eligible for source curation as one California assessment family with two ',
    'sub-area models. The 2023 production archives directly include fitted age ',
    'compositions (conditional age-at-length and marginal-age records) and ',
    'age-specific official outputs. Catch-at-age and annual survey abundance-at-age ',
    'are not direct input series; any tinyAM age-specific observations require ',
    'documented reconstruction from the native catch/index totals, length ',
    'compositions, and age data. The source provides ages 0-50, fixed M, and ',
    'model-derived biological age surfaces.'),
  notes = paste0(
    'NOAA Stock SMART IDs 15332 and 15333 are linked to one California ',
    'assessment family; the north/south model areas remain distinct in source ',
    'data and outputs. Washington (15330) and Oregon (15331) are separate ',
    'assessment areas and are not included in this California family screen.'))

expected_by_id <- setNames(list(review, review), candidate_ids)
pristine <- vapply(candidate_rows, function(row)
  candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row])),
  logical(1L))
already_reviewed <- vapply(seq_along(candidate_ids), function(i) {
  row <- candidate_rows[i]
  all(vapply(names(review), function(column)
    identical(as.character(candidates[[column]][row]), as.character(review[[column]])), logical(1L)))
}, logical(1L))
required_current <- c('candidate_unit_id', 'match_status', 'screening_status', 'eligibility', 'import_status')
partial_review <- vapply(seq_along(candidate_ids), function(i) {
  row <- candidate_rows[i]
  all(vapply(required_current, function(column)
    identical(as.character(candidates[[column]][row]), as.character(review[[column]])), logical(1L))) &&
    all(vapply(setdiff(names(review), required_current), function(column) {
      value <- as.character(candidates[[column]][row])
      is.na(value) || !nzchar(value) || identical(value, as.character(review[[column]]))
    }, logical(1L)))
}, logical(1L))
if (any(!(pristine | already_reviewed | partial_review)))
  stop('At least one NOAA California copper candidate has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (i in seq_along(candidate_ids)) {
    row <- candidate_rows[i]
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_ids[i])
  }
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened the 2023 NOAA California copper rockfish assessment family for age-input eligibility.\n')
