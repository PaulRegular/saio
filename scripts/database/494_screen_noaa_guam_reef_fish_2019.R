root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_guam_reef_fish_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

expected <- data.frame(
  id = c('15110', '15113', '15114', '15130', '15131', '15132', '15133', '15134',
    '15135', '15136', '15137', '15138'),
  species = c('Monotaxis grandoculis', 'Lutjanus fulvus', 'Caranx melampygus',
    'Naso unicornis', 'Lutjanus gibbus', 'Carangoides orthogrammus',
    'Lethrinus olivaceus', 'Hipposcarus longiceps', 'Scarus rubroviolaceus',
    'Lethrinus xanthochilus', 'Chlorurus microrhinos', 'Scarus altipinnis'),
  stringsAsFactors = FALSE)
expected$candidate_id <- paste0('NOAA:', expected$id)
expected$candidate_unit_id <- paste0('noaa_guam_reef_', expected$id)
later_report_species <- c('15113', '15114', '15133')

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify NOAA source checksum.', call. = FALSE)
  hash
}

expected_sources <- data.frame(
  file = c('noaa_20062_wpcouncil_copy.pdf', 'noaa_2019_guam_12_species.html',
    'noaa_2023_guam_7_species.html'),
  url = c(
    'https://www.wpcouncil.org/wp-content/uploads/2019/06/06.C1-Nadon-2019-Guam-reef-fish-assessments.pdf',
    'https://www.fisheries.noaa.gov/resource/document/stock-assessment-guam-coral-reef-fish-2019-0',
    'https://www.fisheries.noaa.gov/resource/document/evaluation-status-and-management-option-7-species-reef-fish-guam'),
  official_source_url = c(
    'https://repository.library.noaa.gov/view/noaa/20062/noaa_20062_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/20062',
    'https://repository.library.noaa.gov/view/noaa/56263/noaa_56263_DS1.pdf'),
  official_sha512 = c(
    '7d4541130f3220ef4b58c079f4f89375f76f83fd7d4ad95fca8b94f118f87d543390e69e12ff633a383d4e614140f762ed12b2d74c5ac1a2bab20ba5988e3e27',
    '7d4541130f3220ef4b58c079f4f89375f76f83fd7d4ad95fca8b94f118f87d543390e69e12ff633a383d4e614140f762ed12b2d74c5ac1a2bab20ba5988e3e27',
    '56c0885a297ebd13d5700587eb8eeb84e143063c515a75cd1795681d51de328c2f541943e9deda4fb8465b6a346f0b0f73867af98e84cf54e732169295d90ab7'),
  cache_status = c('mirror_downloaded', 'page_downloaded', 'page_downloaded_pdf_blocked'),
  bytes = c(6520054L, 135404L, 134522L),
  sha256 = c(
    'c69e900fe0cf27ac091b92b9567080d8a5848549dfc1afff1829de17908ddbfb',
    '2552901195950a431a2ee133b28e98a8b5fd2e43a68482495f97db211cefcd4d',
    '60c0fb1888bdd1c74afc43ffdfff69761a460931ad326e9f5451ed1af4dec526'),
  stringsAsFactors = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (!all(expected_sources$file %in% manifest$file))
  stop('The cached Guam source manifest is incomplete.', call. = FALSE)
for (i in seq_len(nrow(expected_sources))) {
  row <- match(expected_sources$file[i], manifest$file)
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      manifest$url[row] != expected_sources$url[i] ||
      manifest$official_source_url[row] != expected_sources$official_source_url[i] ||
      manifest$official_sha512[row] != expected_sources$official_sha512[i] ||
      manifest$cache_status[row] != expected_sources$cache_status[i] ||
      manifest$retrieved_on[row] != '2026-11-01' ||
      manifest$bytes[row] != expected_sources$bytes[i] ||
      tolower(manifest$sha256[row]) != expected_sources$sha256[i] ||
      sha256_file(path) != expected_sources$sha256[i])
    stop('Cached Guam source failed provenance validation: ', expected_sources$file[i],
      call. = FALSE)
}

page_2019 <- paste(readLines(file.path(cache, 'noaa_2019_guam_12_species.html'),
  warn = FALSE), collapse = ' ')
page_2023 <- paste(readLines(file.path(cache, 'noaa_2023_guam_7_species.html'),
  warn = FALSE), collapse = ' ')
if (!grepl('Stock Assessment of Guam Coral Reef Fish, 2019', page_2019, fixed = TRUE) ||
    !grepl('12 reef-associated fish stocks', page_2019, fixed = TRUE) ||
    !grepl('Caranx melampygus', page_2023, fixed = TRUE) ||
    !grepl('Lethrinus olivaceus', page_2023, fixed = TRUE) ||
    !grepl('Lutjanus fulvus', page_2023, fixed = TRUE) ||
    !grepl('growth-type-group length-based spawning potential ratio model',
      page_2023, fixed = TRUE))
  stop('NOAA Guam report metadata does not match the reviewed species and methods.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
if (any(expected$id %in% trimws(stocks$authority_stock_id), na.rm = TRUE))
  stop('A Guam reef-fish Stock SMART ID already appears in stocks.csv.', call. = FALSE)
same_species_area <- stocks$scientific_name %in% expected$species &
  grepl('Guam', paste(stocks$stock_name, stocks$area, stocks$region), ignore.case = TRUE)
if (any(same_species_area, na.rm = TRUE))
  stop('A canonical Guam stock may match one of these reef-fish units; review the crosswalk.',
    call. = FALSE)
existing_unit_ids <- candidates$candidate_unit_id[
  !candidates$candidate_id %in% expected$candidate_id]
existing_unit_ids <- existing_unit_ids[!is.na(existing_unit_ids) & nzchar(existing_unit_ids)]
if (any(expected$candidate_unit_id %in% existing_unit_ids) ||
    anyDuplicated(expected$candidate_unit_id))
  stop('A Guam reef-fish candidate-unit identifier is duplicated.', call. = FALSE)

dry_run <- identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')
if (!dry_run) source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in seq_len(nrow(expected))) {
  row <- match(expected$candidate_id[i], candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == expected$candidate_id[i]) != 1L ||
      candidates$organization[row] != 'NOAA' ||
      candidates$official_stock_id[row] != expected$id[i] ||
      candidates$scientific_name[row] != expected$species[i] ||
      as.integer(candidates$inventory_assessment_year[row]) != 2019L)
    stop('Candidate identity or inventory year changed: ', expected$candidate_id[i],
      call. = FALSE)

  newer_analysis <- expected$id[i] %in% later_report_species
  url <- if (newer_analysis)
    'https://www.fisheries.noaa.gov/resource/document/evaluation-status-and-management-option-7-species-reef-fish-guam' else
    'https://www.fisheries.noaa.gov/resource/document/stock-assessment-guam-coral-reef-fish-2019-0'
  later_note <- if (newer_analysis)
    ' A 2023 PIFSC report also analyzed this species for Guam JCR-FMP management scenarios using GTG-LBSPR; it does not report age-structured inputs or outputs.' else
    ''
  review <- list(
    candidate_unit_id = expected$candidate_unit_id[i],
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('The 2019 assessment uses total catch estimates and fishery-dependent size compositions, not catch numbers-at-age.'),
    survey_age_evidence = paste0('Fishery-independent diver surveys provide aggregate abundance/biomass and size data; the reviewed reports do not use an age-specific survey index.'),
    weights_evidence = 'Life-history and length-weight information support the length-based per-recruit analysis; no age-specific weight-at-age surface is used or reported.',
    maturity_evidence = 'Maturity information is represented in the length-based life-history inputs, not as a maturity-at-age vector for an age-structured assessment.',
    mortality_evidence = 'The GTG-LBSPR analysis is length-based and reports current fishing mortality and SPR metrics; it does not specify an age-structured M-at-age process.',
    timing_evidence = 'No age-specific abundance index is used, so fractional-year survey timing for an age-structured index is not reported.',
    output_evidence = 'The 2019 report provides fishing mortality, F30, SPR, and selected aggregate biomass/catch-limit distributions; it does not report recruitment or N-, F-, or M-at-age. The 2023 report for three overlapping species remains length-based.',
    detailed_source_url = url,
    review_date = '2026-11-01',
    decision_reason = paste0('The latest reviewed Guam report(s) use the growth-type-group length-based spawning-potential-ratio method, with size compositions, aggregate abundance/biomass, total catch, and life-history inputs. They do not verify age-disaggregated catch or survey likelihood inputs or age-specific population outputs. Ineligible for the age-disaggregated assessment set; this does not establish that age samples are absent from other research.'),
    notes = paste0('NOAA Stock SMART ID ', expected$id[i], ' identifies a single-species Guam Island reef-fish assessment unit, distinct from Guam bottomfish management-unit species and from nearby offshore banks. The 2019 PIFSC assessment covers 2013–2017 data. See discovery/source_reviews/noaa_guam_reef_fish_2019.md. No canonical stock, assessment, input, or output record was added.', later_note))

  current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(review)
  desired <- lapply(review, as.character)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], desired[[column]]), logical(1L)))
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  if (!pristine && !already_reviewed)
    stop('Candidate has an unexpected existing identity or review state: ',
      expected$candidate_id[i], call. = FALSE)
  if (!already_reviewed) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    if (!dry_run) {
      replace_candidate_register_row(register_path, row,
        candidates[row, , drop = FALSE], expected$candidate_id[i])
      candidates <- read.csv(register_path, stringsAsFactors = FALSE,
        na.strings = c('', 'NA'), check.names = FALSE)
    }
  }
}

if (!dry_run) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened 12 NOAA Guam reef-fish units as ineligible for age-disaggregated source curation.\n')
