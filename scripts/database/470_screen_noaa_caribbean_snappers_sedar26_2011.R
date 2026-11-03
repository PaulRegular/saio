root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_caribbean_snappers_sedar26_2011')
register_path <- file.path(root, 'discovery', 'candidates.csv')
unit_area <- 'U.S. Caribbean: Puerto Rico and U.S. Virgin Islands'

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
  NOAA_InPort_SEDAR_26.html = 'de7952d2a2f2566af570ebcc4d172dee7c939d3ec2a2545dd68d3718cadf6669',
  SEDAR_103_project.html = '1da8d1ef5e8a8d8a756ac6c97677022e71c4acfdcd993a5b3baff13a1639b84c',
  SEDAR_103_schedule.pdf = '96a9bd64d736411ea9c432d74fbace5c0c676732b2ee2077791a81728d363181',
  SEDAR_26_Haist_CIE_review.pdf = '316e1ce87944e8e7bdd78195929247c861878ed56d007d44574e71df91fc8f9b',
  SEDAR_26_project.html = 'f81023a6f871ce9c3490ecdf08ca53e023b85ee494e0c9c653825ed69ed2838f',
  SEDAR_26_queen_snapper_report.pdf = '0d7370a2f3eaa01ae11efb2f2766051b0c2fbf6e11718ec33100d8db664f2447',
  SEDAR_26_silk_snapper_report.pdf = 'a70580de6d41efcfd9c3c99098f465cc51c35562a79dc5e817809e4dd6eabbad')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The Caribbean snapper source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached Caribbean snapper source differs from its manifest: ', file,
      call. = FALSE)
}

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
project <- read_source('SEDAR_26_project.html')
inport <- read_source('NOAA_InPort_SEDAR_26.html')
sedar103 <- read_source('SEDAR_103_project.html')
if (!grepl('SEDAR 26', project, fixed = TRUE) ||
    !grepl('queen snapper', project, ignore.case = TRUE) ||
    !grepl('silk snapper', project, ignore.case = TRUE) ||
    !grepl('2011', inport, fixed = TRUE) ||
    !grepl('Completed', inport, fixed = TRUE) ||
    !grepl('November 2026 through March 2027', sedar103, fixed = TRUE))
  stop('Cached official sources do not support the assessment identity and successor status.',
    call. = FALSE)
for (file in c('SEDAR_26_queen_snapper_report.pdf',
    'SEDAR_26_silk_snapper_report.pdf', 'SEDAR_26_Haist_CIE_review.pdf',
    'SEDAR_103_schedule.pdf')) {
  if (!identical(rawToChar(readBin(file.path(cache, file), 'raw', n = 4L)), '%PDF'))
    stop('Cached source is not a PDF: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

cases <- list(
  list(candidate_id = 'NOAA:10241', candidate_unit_id = 'noaa_caribbean_silk_snapper',
    official_stock_id = '10241', scientific_name = 'Lutjanus vivanus',
    stock_name = 'Silk snapper - Caribbean', assessment_year = 2012),
  list(candidate_id = 'NOAA:10247', candidate_unit_id = 'noaa_caribbean_queen_snapper',
    official_stock_id = '10247', scientific_name = 'Etelis oculatus',
    stock_name = 'Queen snapper - Caribbean', assessment_year = 2011))

make_review <- function(case) {
  species <- sub(' - Caribbean$', '', case$stock_name)
  list(
    candidate_unit_id = case$candidate_unit_id,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    assessment_area = unit_area,
    catch_age_evidence = paste(species,
      'has Puerto Rico commercial and recreational catch/landings information, but SEDAR 26 reports that catch-at-age estimates were not developed. In the U.S. Virgin Islands, landings were reported at broader species-group level and could not be allocated reliably to this species.'),
    survey_age_evidence = paste('SEDAR 26 does not document an age-specific fishery-independent abundance index for',
      species, 'The quantitative abundance analyses are commercial CPUE indices; the report and review do not establish an age-index series.'),
    weights_evidence = paste('The data workshop reviewed growth and length/weight information, but no run-specific weight-at-age matrix was used in the quantitative assessment of',
      species, '.'),
    maturity_evidence = paste('Life-history literature was reviewed, but no age-structured population model or run-specific maturity-at-age input was fitted for',
      species, '.'),
    mortality_evidence = paste('The assessment explored data-limited length-frequency mortality methods. It did not estimate age-specific natural or fishing mortality surfaces for',
      species, '.'),
    timing_evidence = paste('The available quantitative index is commercial CPUE with annual landings and length samples; no age-indexed survey timing fraction is documented for',
      species, '.'),
    output_evidence = paste('SEDAR 26 reports CPUE and length-frequency analyses, not abundance-at-age, fishing mortality-at-age, or spawning biomass estimates for',
      species, '. The queen snapper summary explicitly states that accurate abundance or biomass estimates could not be developed.'),
    detailed_source_url = paste('https://sedarweb.org/assessments/sedar-26/;',
      'https://sedarweb.org/documents/sedar-26-caribbean-silk-snapper-final-stock-assessment-report/;',
      'https://sedarweb.org/documents/sedar-26-caribbean-queen-snapper-final-stock-assessment-report/;',
      'https://www.fisheries.noaa.gov/inport/item/35701;',
      'https://sedarweb.org/documents/cie-reviewer-report-haist/;',
      'https://sedarweb.org/assessments/sedar-103-us-caribbean-application-of-alternate-assessment-methods/;',
      'https://sedarweb.org/documents/sedar-103-us-caribbean-application-of-alternate-assessment-methods-project-schedule/'),
    review_date = '2026-10-31',
    decision_reason = paste('The latest completed detailed production assessment identified for this NOAA Caribbean unit is SEDAR 26 (2011, listed in NOAA InPort as effective 2011). It used data-limited commercial CPUE and length-frequency analyses rather than an age-structured model. The SEDAR 26 peer review found the data insufficient for standard stock-assessment models. SEDAR 103 is still in progress, with application webinars scheduled from November 2026 through March 2027 and review in 2027; it has not replaced SEDAR 26 with completed advice as of this review.'),
    notes = paste('NOAA Stock SMART identifies', case$official_stock_id, 'as the Caribbean',
      tolower(species), 'unit. SEDAR 26 reviewed Puerto Rico, St. Croix, and St. Thomas/St. John platforms; these are assessment subareas, not separate NOAA Stock SMART stock rows. This discovery screen adds no canonical stock, assessment, input, or output records.'))
}

reviews <- lapply(cases, make_review)
for (i in seq_along(cases)) {
  case <- cases[[i]]
  row <- match(case$candidate_id, candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == case$candidate_id, na.rm = TRUE) != 1L ||
      candidates$official_stock_id[row] != case$official_stock_id ||
      candidates$scientific_name[row] != case$scientific_name ||
      candidates$stock_name[row] != case$stock_name ||
      !candidates$assessment_area[row] %in% c('Caribbean', unit_area) ||
      any(candidates$candidate_unit_id[-row] == case$candidate_unit_id, na.rm = TRUE) ||
      any(as.character(stocks$authority_stock_id) == case$official_stock_id, na.rm = TRUE) ||
      any(stocks$stock_id == case$candidate_unit_id) ||
      any(assessments$stock_id == case$candidate_unit_id) ||
      any(inputs$assessment_id == case$candidate_unit_id) ||
      any(outputs$assessment_id == case$candidate_unit_id))
    stop('Caribbean snapper identity conflicts with the candidate register or canonical database: ',
      case$candidate_id, call. = FALSE)

  review <- reviews[[i]]
  current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(review)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], as.character(review[[column]])), logical(1L)))
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  if (!pristine && !already_reviewed)
    stop('Caribbean snapper candidate already has a conflicting review: ',
      case$candidate_id, call. = FALSE)

  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && !already_reviewed) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row,
      candidates[row, , drop = FALSE], case$candidate_id)
  }
}

cat('Screened the NOAA Caribbean silk- and queen-snapper units as ineligible for age-structured source curation.\n')
