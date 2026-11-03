root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_cabezon_2019')
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
  cabezon_2019_assessment.pdf = 'd2f6d74d80341b3c839b116738c270cd89177954e51818ad3a5a82d56047b395',
  cabezon_2019_supplementary_tables.xlsx = '76584e191962684431e45bbe024b2c5a9c001b8838fec0d57402e4b3aa488efc',
  cabezon_2019_ors_model.zip = 'f31193de1ab1922a9692c5eaa803873fa89acd569d06bfbb3b5fcf9308007150',
  cabezon_2019_scs_model.zip = 'd70bb127403986a280f34c0e0df69f1964e19f2e09c780d044b467c2e2543808',
  cabezon_2019_ncs_model.zip = '5b5e49393c5f064d52874612b319f6ca7862183315024ada15747e2f67ef5c4f',
  cabezon_2019_star_panel.pdf = '1399a90f09765f9a7e27ac94de34c2254f37e65e6309c3d0adc181cb0833e555')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The cabezon source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached cabezon source differs from its manifest: ', file, call. = FALSE)
}

one_file <- function(directory, pattern) {
  files <- list.files(directory, pattern = pattern, recursive = TRUE, full.names = TRUE)
  if (length(files) != 1L) stop('Expected one ', pattern, ' under ', directory, call. = FALSE)
  files
}

age_bins <- function(path) {
  lines <- readLines(path, warn = FALSE)
  row <- grep('#_N_age_bins', lines, fixed = TRUE)[1L]
  if (is.na(row)) stop('Missing age-bin count in ', path, call. = FALSE)
  as.integer(strsplit(trimws(lines[row]), '[[:space:]]+')[[1L]][1L])
}

areas <- list(
  ncs = list(age_bins = 20L, terminal_year = 2018L),
  scs = list(age_bins = 0L, terminal_year = 2018L),
  ors = list(age_bins = 21L, terminal_year = 2018L))
archive <- file.path(cache, 'extracted')
for (area in names(areas)) {
  directory <- file.path(archive, area)
  data_file <- one_file(directory, if (area == 'ncs') '^data_ncs_4fleets[.]ss$' else
    if (area == 'scs') '^data_scs_4fleets[.]ss$' else '^ORcab_data[.]ss$')
  report_file <- one_file(directory, '^Report[.]sso$')
  data <- readLines(data_file, warn = FALSE)
  report <- readLines(report_file, warn = FALSE)
  report_text <- paste(report, collapse = ' ')
  if (age_bins(data_file) != areas[[area]]$age_bins ||
      !any(grepl('CATCH_AT_AGE', report_text, fixed = TRUE)) ||
      !any(grepl('F_AT_AGE', report_text, fixed = TRUE)) ||
      !any(grepl('NUMBERS_AT_AGE', report_text, fixed = TRUE)) ||
      !any(grepl('Maturity:', report, fixed = TRUE)) ||
      !any(grepl('NatMort:', report, fixed = TRUE)))
    stop('The pinned 2019 ', toupper(area), ' model files fail expected input/output checks.',
      call. = FALSE)
  if (!any(grepl('^2018[[:space:]]+#_EndYr', data, ignore.case = TRUE)))
    stop('The pinned 2019 ', toupper(area), ' input does not end in 2018.', call. = FALSE)
}

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

source_urls <- paste(
  'https://www.pcouncil.org/documents/2019/10/assessing-cabezon-scorpaenichthys-marmoratus-stocks-in-waters-off-of-california-and-oregon-with-catch-limit-estimation-for-washington-state-10-18-2019.pdf',
  'https://www.pcouncil.org/documents/2019/10/cabezon-supplementary-tables-october-2019.xlsx',
  'https://www.pcouncil.org/documents/2019/10/cabezon-star-panel-report-may-6-10-2019.pdf',
  'https://www.pcouncil.org/documents/cabezon-ors-model-files-zip-file/',
  'https://www.pcouncil.org/documents/cabezon-scs-model-files-zip-file/',
  'https://www.pcouncil.org/documents/cabezon-ncs-model-files-zip-file/')
review_date <- '2026-10-31'

decisions <- list(
  `NOAA:10299` = list(
    candidate_unit_id = NA_character_, match_status = 'ambiguous',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2009 California assessment row predates the 2019 split into northern and southern California models. The current 2019 fits do not include observed fishery catch-at-age; the NCS research age samples do not represent catch age.',
    survey_age_evidence = 'The historical row is not a current assessment unit. The current NCS and SCS fits use aggregate CPUE indices; the old row is not a separate age-specific survey series.',
    weights_evidence = 'Current 2019 biological evidence is held in the distinct NCS and SCS units; do not assign a single California weight-at-age surface to this historical aggregate row.',
    maturity_evidence = 'Current 2019 biological evidence is held in the distinct NCS and SCS units; do not assign a single California maturity-at-age surface to this historical aggregate row.',
    mortality_evidence = 'Current 2019 mortality assumptions are stock-specific for the NCS and SCS units; the historical 2009 row is not treated as an independent current unit.',
    timing_evidence = 'The 2019 assessment changed California catch and length-composition timing to month 6. This historical row is not used as a current assessment input.',
    output_evidence = 'The 2009 output series is superseded by separate 2019 NCS and SCS outputs. Do not combine those surfaces into a fabricated California aggregate.',
    detailed_source_url = source_urls,
    decision_reason = 'The 2009 California inventory row is an ambiguous one-to-many historical alias to current NOAA:15050 (NCS) and NOAA:15051 (SCS), not a third current unit. The 2019 current-unit fits are reviewed separately.',
    notes = 'Historical NOAA Stock SMART California row 10299 (assessment year 2009) was superseded by separate 2019 northern and southern California substock assessments. Preserve as an ambiguous alias and do not count as a new current case.'),
  `NOAA:12193` = list(
    candidate_unit_id = 'noaa_cabezon_oregon_2019', match_status = 'new',
    screening_status = 'screened', eligibility = 'eligible', import_status = 'not_started',
    catch_age_evidence = 'The 2019 ORS fit uses fleet catches and conditional age-at-length data from recreational ocean-boat samples in 2005-2018 (2,328 fish) and sparse commercial dead-fishery samples from 2003 and 2007-2018 (364 fish). These source samples can support a documented, partial fleet/year catch-age reconstruction; they are not a complete observed catch-at-age series.',
    survey_age_evidence = 'The ORS assessment has aggregate logbook, onboard observer, ORBS and MRFSS abundance indices. Age compositions from the recreational ocean-boat fleet overlap the recreational indices and can support a labelled age-specific reconstruction; the assessment does not provide a directly observed age-specific index.',
    weights_evidence = 'The report describes an Oregon length-weight relationship estimated from ORBS biological records and PacFIN, aggregated across sexes; native model files and Report.sso contain derived age surfaces. Preserve this distinction when curating.',
    maturity_evidence = 'Maturity and fecundity are represented through Oregon-specific size-based biological inputs and the fitted model; retain original sex and age definitions when extracting.',
    mortality_evidence = 'The 2019 ORS fit uses stock-specific natural-mortality treatment and priors documented in the report and native control; verify exact values from those files before importing.',
    timing_evidence = 'Oregon fleet timing is encoded in the native Stock Synthesis data and control files. Convert those settings explicitly before assigning a fractional-year timing.',
    output_evidence = 'The 2019 ORS Report.sso contains annual numbers-at-age, F-at-age, catch-at-age, and spawning output through 2018.',
    detailed_source_url = source_urls,
    decision_reason = 'The current 2019 Oregon substock (ORS) has observed fishery age-at-length samples, fleet catches, overlapping aggregate recreational indices, biological inputs, and official age-specific outputs. Eligible for source curation with partial age reconstruction and explicit coverage limitations.',
    notes = 'Current Oregon substock component of the 2019 PFMC cabezon assessment family. Do not count regional model components as separate species-level cases.'),
  `NOAA:14803` = list(
    candidate_unit_id = 'noaa_cabezon_washington_2019', match_status = 'new',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2019 Washington assessment is a data-poor Simple Stock Synthesis analysis based on total catch and length compositions, not a catch-at-age likelihood.',
    survey_age_evidence = 'No age-specific abundance index is used in the Washington SSS assessment.',
    weights_evidence = 'Washington life-history inputs support the SSS model; no fitted age-specific stock-weight surface comparable to the full SS models is reported.',
    maturity_evidence = 'The Washington substock is assessed with a length-based spawner-potential-ratio method; no fitted maturity-at-age series is reported.',
    mortality_evidence = 'Age and life-history information is used to inform growth and mortality assumptions for the data-poor SSS model, not to estimate an age-structured annual mortality surface.',
    timing_evidence = 'The Washington depletion model does not use a within-year age-specific survey index.',
    output_evidence = 'The 2019 report provides Washington depletion and catch-limit results, not comparable annual N-at-age or F-at-age outputs.',
    detailed_source_url = source_urls,
    decision_reason = 'The current Washington unit is a category-3 data-poor SSS analysis, not a full age-structured fit. It is ineligible for the age-disaggregated source set.',
    notes = 'Current Washington substock component of the 2019 assessment family; its SSS method is distinct from the NCS, SCS and ORS full Stock Synthesis models.'),
  `NOAA:15050` = list(
    candidate_unit_id = 'noaa_cabezon_northern_california_2019', match_status = 'new',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2019 NCS fit uses catch and length compositions, but the report explicitly states that catch-age compositions representing fishery data are unavailable. The 1996-2002 research age samples support growth estimation and do not represent catch age.',
    survey_age_evidence = 'The NCS fit includes aggregate CPFV and CCFRP abundance indices; CCFRP is fishery-independent but supplies length composition rather than age composition. Research age-at-length samples are not an age-specific index.',
    weights_evidence = 'The NCS model estimates sex-specific growth and uses stock-specific length-weight biological data; the native model report includes the derived age surfaces.',
    maturity_evidence = 'The 2019 report and native files document stock-specific maturity and fecundity inputs; preserve their biological units and sex treatment.',
    mortality_evidence = 'Natural mortality is estimated with stock-specific priors in the 2019 NCS fit; do not replace it with a fixed common value.',
    timing_evidence = 'The 2019 NCS catches and length compositions are assigned to month 6. CPUE and CCFRP survey timing must be checked in the native fleet inputs before translation.',
    output_evidence = 'The 2019 NCS Report.sso contains annual numbers-at-age, F-at-age, catch-at-age, and spawning output through 2018.',
    detailed_source_url = source_urls,
    decision_reason = 'The current NCS fit is age-structured and reports age-specific outputs, but the only age samples are research data used for growth, not fishery catch age; no age-specific survey index is available. It is ineligible for this age-input set.',
    notes = 'Current Northern California substock (NCS), separate from Southern California, Oregon, and Washington components of the 2019 PFMC assessment family.'),
  `NOAA:15051` = list(
    candidate_unit_id = 'noaa_cabezon_southern_california_2019', match_status = 'new',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2019 SCS model has no conditional age-at-length observations in its fitted likelihood and no observed fishery catch-at-age series.',
    survey_age_evidence = 'The SCS model uses an aggregate CPFV abundance index and has no age-specific survey index or fitted age-composition series.',
    weights_evidence = 'The SCS fit fixes growth to the NCS estimates and uses California stock-specific length-weight biological data; retain the source distinction from age-specific model outputs.',
    maturity_evidence = 'The 2019 report and model files document Southern California maturity and fecundity treatment; preserve the stock-specific biological definition.',
    mortality_evidence = 'Natural mortality is estimated with stock-specific priors in the 2019 SCS fit.',
    timing_evidence = 'The 2019 SCS catches and length compositions are assigned to month 6. CPUE timing requires explicit review of native inputs before translation.',
    output_evidence = 'The 2019 SCS Report.sso contains annual numbers-at-age, F-at-age, catch-at-age, and spawning output through 2018.',
    detailed_source_url = source_urls,
    decision_reason = 'The current SCS fit is age-structured and reports age-specific outputs, but its likelihood contains no age compositions and no catch-age or age-specific abundance inputs. It is ineligible for this age-input set.',
    notes = 'Current Southern California substock (SCS), separate from Northern California, Oregon, and Washington components of the 2019 PFMC assessment family.'))

for (candidate_id in names(decisions)) {
  row <- match(candidate_id, candidates$candidate_id)
  decision <- decisions[[candidate_id]]
  if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L)
    stop('Expected one candidate row for ', candidate_id, call. = FALSE)
  expected <- c(list(candidate_id = candidate_id), decision, list(review_date = review_date))
  if (candidate_id == 'NOAA:10299') {
    if (candidates$scientific_name[row] != 'Scorpaenichthys marmoratus' ||
        candidates$inventory_assessment_year[row] != '2009')
      stop('The historical California row identity or year changed.', call. = FALSE)
  } else if (candidates$scientific_name[row] != 'Scorpaenichthys marmoratus' ||
      candidates$inventory_assessment_year[row] != '2019') {
    stop('The 2019 cabezon candidate identity or year changed: ', candidate_id,
      call. = FALSE)
  }
  if (any(stocks$scientific_name == 'Scorpaenichthys marmoratus', na.rm = TRUE) ||
      any(assessments$stock_id == decision$candidate_unit_id, na.rm = TRUE) ||
      any(inputs$assessment_id == decision$candidate_unit_id, na.rm = TRUE) ||
      any(outputs$assessment_id == decision$candidate_unit_id, na.rm = TRUE))
    stop('A canonical cabezon record exists; review the crosswalk before screening.',
      call. = FALSE)
}

required_status <- c('candidate_unit_id', 'match_status', 'screening_status',
  'eligibility', 'import_status')
for (candidate_id in names(decisions)) {
  row <- match(candidate_id, candidates$candidate_id)
  decision <- decisions[[candidate_id]]
  expected <- c(list(candidate_unit_id = decision$candidate_unit_id),
    decision[setdiff(names(decision), 'candidate_unit_id')], list(review_date = review_date))
  current <- lapply(names(expected), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(expected)
  already_reviewed <- all(vapply(names(expected), function(column)
    identical(current[[column]], as.character(expected[[column]])), logical(1L)))
  pristine <- candidates$screening_status[row] == 'not_started' &&
    candidates$match_status[row] == 'unreviewed' &&
    candidates$eligibility[row] == 'unresolved' && candidates$import_status[row] == 'not_started'
  partial <- all(vapply(required_status, function(column)
    identical(current[[column]], as.character(expected[[column]])), logical(1L))) &&
    all(vapply(setdiff(names(expected), required_status), function(column) {
      value <- current[[column]]
      is.na(value) || !nzchar(value) || identical(value, as.character(expected[[column]]))
    }, logical(1L)))
  if (!pristine && !already_reviewed && !partial)
    stop('Candidate has a conflicting prior screening: ', candidate_id, call. = FALSE)
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (candidate_id in names(decisions)) {
    row <- match(candidate_id, candidates$candidate_id)
    for (column in names(decisions[[candidate_id]]))
      candidates[[column]][row] <- decisions[[candidate_id]][[column]]
    candidates$review_date[row] <- review_date
  }
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (candidate_id in names(decisions)) {
    row <- match(candidate_id, candidates$candidate_id)
    replace_candidate_register_row(register_path, row,
      candidates[row, , drop = FALSE], candidate_id)
  }
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened current and historical NOAA cabezon inventory rows against the 2019 PFMC substock assessment family.\n')
