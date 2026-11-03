root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_lingcod_2021')
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
  northern_lingcod_2021.pdf = 'cc3550c45dc7a6494f2cd8b14f4a317a9fd42799e106a574e5860256efc7987b',
  southern_lingcod_2021.pdf = '56953db2490455891326c0bfc3174eeb47567873fed7808885e68b40abe93f25',
  lingcod_2021_model_files.zip = '797e442e9c0754bb0cae4f53eb8d259fd4dc661b0aaa68a5775cf022fc9fb901',
  lingcod_2021_star_panel_report.pdf = 'a5fc19b9a12a86b7535962e863ff41f2181cf38a824f91a48d3e5b4ed2397f08',
  noaa_lingcod_status_2026.html = 'b960a5e9f9d666540b8dd05604c9b5d180ebce94493cb6056b7be857a6012767',
  repository_README.md = '0556f38e347aa2516f08f6552ce28fe354d088c32a7be10c1107a2e786a1107c')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The lingcod source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached lingcod source differs from its manifest: ', file, call. = FALSE)
}

status_page <- paste(readLines(file.path(cache, 'noaa_lingcod_status_2026.html'),
  warn = FALSE), collapse = ' ')
repository <- paste(readLines(file.path(cache, 'repository_README.md'),
  warn = FALSE), collapse = ' ')
if (!grepl('two stocks', status_page, ignore.case = TRUE) ||
    !grepl('2021&nbsp;stock assessment', status_page, fixed = TRUE) ||
    !grepl('2027 stock assessment', repository, fixed = TRUE) ||
    !grepl('2021 lingcod assessments', repository, fixed = TRUE))
  stop('Current NOAA status or pinned model repository does not support the source review.',
    call. = FALSE)

report_fleets <- function(path) {
  lines <- readLines(path, warn = FALSE)
  start <- match('Age_Comp_Fit_Summary', lines)
  if (is.na(start)) stop('Missing Age_Comp_Fit_Summary in ', path, call. = FALSE)
  end <- grep('^ OVERALL_COMPS', lines[(start + 1L):length(lines)])[1] + start
  rows <- lines[(start + 2L):(end - 1L)]
  rows <- rows[grepl('^[0-9]+[[:space:]]+[0-9]+[[:space:]]', rows)]
  sort(unique(as.integer(vapply(strsplit(trimws(rows), '[[:space:]]+'),
    `[`, '', 2L))))
}

age_composition_data <- function(path) {
  lines <- readLines(path, warn = FALSE)
  start <- grep('^#_Yr[[:space:]]+Seas[[:space:]]+FltSvy[[:space:]]+Gender[[:space:]]+Part[[:space:]]+Ageerr',
    lines)[1]
  if (is.na(start)) stop('Missing age-composition data section in ', path, call. = FALSE)
  end <- which(grepl('^-9999[[:space:]]', lines) & seq_along(lines) > start)[1]
  fields <- strsplit(trimws(lines[(start + 1L):(end - 1L)]), '[[:space:]]+')
  rows <- lapply(fields, function(value) {
    if (length(value) < 9L) return(NULL)
    suppressWarnings(as.numeric(value[1:9]))
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  values <- do.call(rbind, rows)
  data.frame(year = values[, 1L], fleet = values[, 3L])
}

age_years <- function(data, fleets) {
  lapply(fleets, function(fleet) sort(unique(data$year[data$fleet == fleet]))) |>
    setNames(as.character(fleets))
}

archive <- file.path(cache, 'extracted')
areas <- list(
  north = list(
    candidate_id = 'NOAA:12194',
    candidate_unit_id = 'noaa_lingcod_north_pacific_coast_2021',
    official_stock_id = '12194',
    stock_name = 'Lingcod - Northern Pacific Coast',
    fleets = c(1L, 2L, 3L, 4L, 6L, 7L, 9L),
    years = list(
      `1` = 1978:2020, `2` = setdiff(1980:2020, c(1981, 1983:1985)),
      `3` = setdiff(1979:2020, 1984), `4` = setdiff(1999:2019, 2009:2011),
      `6` = c(1992, 1995, 1998, 2001, 2004), `7` = setdiff(2003:2019, 2017),
      `9` = 2016),
    eligibility = 'eligible'),
  south = list(
    candidate_id = 'NOAA:12195',
    candidate_unit_id = 'noaa_lingcod_south_pacific_coast_2021',
    official_stock_id = '12195',
    stock_name = 'Lingcod - Southern Pacific Coast',
    fleets = 7L,
    years = list(`7` = 2003:2019),
    eligibility = 'ineligible'))

for (area in names(areas)) {
  input <- file.path(archive, area, 'ling_data.ss')
  control <- file.path(archive, area, 'ling_control.ss')
  report <- file.path(archive, area, 'Report.sso')
  wtatage <- file.path(archive, area, 'wtatage.ss_new')
  if (!all(file.exists(c(input, control, report, wtatage))))
    stop('Missing pinned 2021 model source for ', area, '.', call. = FALSE)
  input_lines <- readLines(input, warn = FALSE)
  control_lines <- readLines(control, warn = FALSE)
  report_lines <- readLines(report, warn = FALSE)
  report_text <- paste(report_lines, collapse = ' ')
  agebin_header <- grep('^#_agebin_vector', input_lines)[1]
  agebin_values <- suppressWarnings(as.integer(strsplit(
    trimws(input_lines[agebin_header + 1L]), '[[:space:]]+')[[1L]][1:21]))
  if (!any(grepl('^2020[[:space:]]+#_endyr', input_lines)) ||
      !any(grepl('^#V3\\.30', input_lines)) ||
      !identical(agebin_values, 0:20) ||
      !any(grepl('Maturity:', report_lines, fixed = TRUE)) ||
      !any(grepl('NatMort:', report_lines, fixed = TRUE)) ||
      !grepl('CATCH_AT_AGE', report_text, fixed = TRUE) ||
      !grepl('NUMBERS_AT_AGE', report_text, fixed = TRUE) ||
      !grepl('F_AT_AGE', report_text, fixed = TRUE) ||
      !any(grepl('NatM_p_', control_lines, fixed = TRUE)))
    stop('The pinned 2021 model files do not contain expected assessment inputs and outputs: ',
      area, call. = FALSE)

  age_data <- age_composition_data(input)
  observed_fleets <- report_fleets(report)
  if (!identical(observed_fleets, areas[[area]]$fleets))
    stop('Active age-composition fleets differ from the reviewed 2021 fit: ', area,
      call. = FALSE)
  observed_years <- age_years(age_data, observed_fleets)
  expected_years <- areas[[area]]$years[as.character(observed_fleets)]
  same_years <- all(vapply(names(expected_years), function(fleet)
    identical(as.integer(observed_years[[fleet]]),
      as.integer(expected_years[[fleet]])), logical(1L)))
  if (!same_years)
    stop('Active age-composition year coverage differs from the reviewed 2021 fit: ',
      area, call. = FALSE)
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

reviews <- list(
  north = list(
    match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste('The 2021 Stock Synthesis input has fleet-level catch biomass and active conditional age-at-length data for commercial trawl, fixed gear, Washington and Oregon recreational fleets. Those source quantities support a documented catch-at-age reconstruction for sampled fleet-years; exact catch units and conversion must be retained during import.'),
    survey_age_evidence = paste('The fitted model includes aggregate survey indices and active conditional age-at-length data for Triennial (1992, 1995, 1998, 2001, 2004) and WCGBTS (2003-2016, 2018-2019), alongside other age-composition fleets. The 2021 run uses data through 2020.'),
    weights_evidence = paste('The pinned assessment archive and Report.sso provide sex-specific weight-at-age, growth, and maturity calculations. Preserve their model-generated nature, sex structure, and age ranges.'),
    maturity_evidence = paste('The age-logistic maturity parameters are fixed from the biological analysis described in the assessment report. The resulting maturity-at-age calculations are sex-specific; preserve the fixed values and age range.'),
    mortality_evidence = paste('The 2021 control and report specify estimated sex-specific natural-mortality parameters. The reported model uses age-structured fishing mortality and provides F-at-age output.'),
    timing_evidence = paste('Survey timing is encoded in the Stock Synthesis fleet inputs and annual-season setup. Convert the source timing convention explicitly before creating tinyAM observations; no unverified fractional-year value is assigned here.'),
    output_evidence = paste('The official model archive includes catch-at-age, numbers-at-age, and F-at-age tables in Report.sso, with spawning output, recruitment and other assessment summaries. The report and model archive support source-level comparison.'),
    decision_reason = paste('Screened eligible for source curation. NOAA and PFMC identify the 2021 assessment as the latest assessment used for management; the pinned model data end in 2020. Its active fishery age-composition likelihood and catch biomass permit a documented age-specific catch reconstruction, and official age-specific N/F outputs are available. The north unit is distinct from the Canadian DFO outside-waters unit.'),
    notes = paste('New U.S. northern Pacific Coast stock unit, Stock SMART ID 12194. The model boundary is 40 degrees 10 minutes N; the northern assessment stops at the U.S.-Canada border. Do not pool it with southern U.S. lingcod or Canadian outside-waters lingcod. The 2027 assessment work is ongoing and does not replace the 2021 production run used for management.')),
  south = list(
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste('The fitted model has fleet catch biomass, but the 2021 assessment review says sparse fishery age data were excluded. Negative-fleet fishery age rows in ling_data.ss are expected-only observations and do not enter the accepted likelihood. The retained source quantities therefore do not support reconstructing the catch-at-age input used by the official fit.'),
    survey_age_evidence = paste('The active age-composition likelihood is the WCGBTS conditional age-at-length series in 2003-2019. Aggregate survey indices are available, but age-resolved information is limited to this survey.'),
    weights_evidence = paste('The pinned assessment archive and Report.sso provide sex-specific weight-at-age, growth, and maturity calculations. Preserve their model-generated nature, sex structure, and age ranges.'),
    maturity_evidence = paste('The age-logistic maturity parameters are fixed from the biological analysis described in the assessment report. The resulting maturity-at-age calculations are sex-specific; preserve the fixed values and age range.'),
    mortality_evidence = paste('The 2021 control and report specify estimated sex-specific natural-mortality parameters. The reported model uses age-structured fishing mortality and provides F-at-age output.'),
    timing_evidence = paste('Survey timing is encoded in the Stock Synthesis fleet inputs and annual-season setup. Convert the source timing convention explicitly before creating tinyAM observations; no unverified fractional-year value is assigned here.'),
    output_evidence = paste('The official model archive includes catch-at-age, numbers-at-age, and F-at-age tables in Report.sso, with spawning output, recruitment and other assessment summaries. Outputs alone do not replace the age-specific catch likelihood inputs.'),
    decision_reason = paste('Screened ineligible for the age-disaggregated input set. The 2021 assessment STAR review reports sparse fishery ages and states that all age data other than WCGBTS were removed from the southern fit because their fits conflicted and affected population scale. The remaining WCGBTS age series informs survey age structure but cannot replace an age-specific catch input. The model file retains negative-fleet rows for expected values only; these do not contribute to the fitted likelihood.'),
    notes = paste('New U.S. southern Pacific Coast stock unit, Stock SMART ID 12195, separate from NOAA northern lingcod and the Canadian DFO outside-waters unit. The model boundary is 40 degrees 10 minutes N.')))

for (area in names(areas)) {
  spec <- areas[[area]]
  row <- match(spec$candidate_id, candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == spec$candidate_id, na.rm = TRUE) != 1L ||
      candidates$official_stock_id[row] != spec$official_stock_id ||
      candidates$scientific_name[row] != 'Ophiodon elongatus' ||
      candidates$stock_name[row] != spec$stock_name ||
      candidates$inventory_assessment_year[row] != '2021' ||
      any(candidates$candidate_unit_id[-row] == spec$candidate_unit_id, na.rm = TRUE) ||
      any(as.character(stocks$authority_stock_id) == spec$official_stock_id, na.rm = TRUE) ||
      any(stocks$stock_id == spec$candidate_unit_id, na.rm = TRUE) ||
      any(assessments$stock_id == spec$candidate_unit_id, na.rm = TRUE) ||
      any(inputs$assessment_id == spec$candidate_unit_id, na.rm = TRUE) ||
      any(outputs$assessment_id == spec$candidate_unit_id, na.rm = TRUE))
    stop('Lingcod identity conflicts with the discovery register or canonical database: ',
      spec$candidate_id, call. = FALSE)
  if (any(stocks$scientific_name == 'Ophiodon elongatus', na.rm = TRUE))
    stop('A canonical lingcod stock requires an explicit crosswalk review before this screen.',
      call. = FALSE)

  review <- c(list(candidate_unit_id = spec$candidate_unit_id), reviews[[area]],
    list(detailed_source_url = paste(
      'https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-northern-u-s-west-coast-in-2021-december-2021.pdf/;',
      'https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-southern-u-s-west-coast-in-2021-december-2021.pdf/;',
      'https://www.pcouncil.org/documents/2021/10/lingcod-stock-assessment-review-star-panel-report.pdf/;',
      'https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/;',
      'https://www.fisheries.noaa.gov/species/lingcod'),
      review_date = '2026-10-31'))
  current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(review)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], as.character(review[[column]])), logical(1L)))
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  required_current <- c('candidate_unit_id', 'match_status', 'screening_status',
    'eligibility', 'import_status')
  partial_review <- all(vapply(required_current, function(column)
    identical(current[[column]], as.character(review[[column]])), logical(1L))) &&
    all(vapply(setdiff(names(review), required_current), function(column) {
      value <- current[[column]]
      is.na(value) || !nzchar(value) ||
        identical(value, as.character(review[[column]]))
    }, logical(1L)))
  if (!pristine && !already_reviewed && !partial_review)
    stop('Lingcod candidate already has a conflicting review: ', spec$candidate_id,
      call. = FALSE)
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (area in names(areas)) {
    spec <- areas[[area]]
    row <- match(spec$candidate_id, candidates$candidate_id)
    review <- c(list(candidate_unit_id = spec$candidate_unit_id), reviews[[area]],
      list(detailed_source_url = paste(
        'https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-northern-u-s-west-coast-in-2021-december-2021.pdf/;',
        'https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-southern-u-s-west-coast-in-2021-december-2021.pdf/;',
        'https://www.pcouncil.org/documents/2021/10/lingcod-stock-assessment-review-star-panel-report.pdf/;',
        'https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/;',
        'https://www.fisheries.noaa.gov/species/lingcod'),
        review_date = '2026-10-31'))
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
  }
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (area in names(areas)) {
    spec <- areas[[area]]
    row <- match(spec$candidate_id, candidates$candidate_id)
    replace_candidate_register_row(register_path, row,
      candidates[row, , drop = FALSE], spec$candidate_id)
  }
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened both U.S. Pacific Coast lingcod candidates against the pinned 2021 assessments.\n')
