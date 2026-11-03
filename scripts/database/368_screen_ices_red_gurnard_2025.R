root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_ices_red_gurnard_2025')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

expected <- data.frame(
  file = c('ices_advice_2025_mirror.pdf', 'ices_advice_record_2023.html',
    'ices_sag_source_2023.html'),
  sha256 = c('74E4FE98F0BF1117D9D0921C9DF94F9CDDF7696AB37E6406DC81A4D2F4D092BF',
    'ED50D4968D16154712F31AD7F5C526F6330D5F44A863F98DE828085E027225D6',
    '7256084BAF788159B77B549BE3CD42060209223F4203A1177922A3BE8BD4FA3F'),
  stringsAsFactors = FALSE
)
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected))) {
  path <- file.path(cache_dir, expected$file[i])
  row <- match(expected$file[i], manifest$file)
  if (!file.exists(path) || is.na(row) || manifest$sha256[row] != expected$sha256[i] ||
      sha256_file(path) != expected$sha256[i]) {
    stop('A pinned red gurnard source is missing or differs from its manifest: ',
      expected$file[i], call. = FALSE)
  }
}

sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')
sid_manifest <- read.csv(file.path(root, 'source_cache', 'discovery_ices_sid', 'sources.csv'),
  stringsAsFactors = FALSE)
sid_row <- match(basename(sid_path), sid_manifest$file)
sid_sha <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'
if (!file.exists(sid_path) || is.na(sid_row) || sid_manifest$sha256[sid_row] != sid_sha ||
    sha256_file(sid_path) != sid_sha) {
  stop('The pinned 2026 ICES SID stock list is missing or changed.', call. = FALSE)
}
json <- paste(readLines(sid_path, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
objects <- regmatches(json, gregexpr('(?s)\\{[^{}]*\\}', json, perl = TRUE))[[1L]]
field <- function(object, name) {
  pattern <- paste0('"', name, '"[[:space:]]*:[[:space:]]*"([^"]*)"')
  match <- regmatches(object, regexec(pattern, object, perl = TRUE))[[1L]]
  if (length(match) < 2L) NA_character_ else match[[2L]]
}
sid_rows <- which(vapply(objects, field, character(1L), name = 'StockKeyLabel') == 'gur.27.3-8')
if (length(sid_rows) != 1L ||
    field(objects[sid_rows], 'SpeciesScientificName') != 'Chelidonichthys cuculus') {
  stop('The ICES red gurnard stock code or species changed in the SID snapshot.', call. = FALSE)
}

advice_record <- paste(readLines(file.path(cache_dir, 'ices_advice_record_2023.html'),
  warn = FALSE), collapse = ' ')
source_data <- paste(readLines(file.path(cache_dir, 'ices_sag_source_2023.html'),
  warn = FALSE), collapse = ' ')
if (!grepl('gur.27.3-8', advice_record, fixed = TRUE) ||
    !grepl('Stock Category', advice_record, fixed = TRUE) ||
    !grepl('3', advice_record, fixed = TRUE) ||
    !grepl('Assessment Year', advice_record, fixed = TRUE) ||
    !grepl('gur.27.3-8', source_data, fixed = TRUE) ||
    !grepl('B_index', source_data, fixed = TRUE) ||
    !grepl('Fish data', source_data, fixed = TRUE)) {
  stop('The cached ICES sources do not match the reviewed red gurnard evidence.', call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_id <- 'ICES:gur.27.3-8'
unit_id <- 'ices_red_gurnard_3_8'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$official_stock_id[row] != 'gur.27.3-8' ||
    register$scientific_name[row] != 'Chelidonichthys cuculus' ||
    register$inventory_assessment_year[row] != 2025 ||
    any(stocks$authority_stock_id == 'gur.27.3-8', na.rm = TRUE)) {
  stop('Red gurnard candidate identity or latest advice listing changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    unit_id %in% assessments$assessment_id || unit_id %in% inputs$assessment_id ||
    unit_id %in% outputs$assessment_id) {
  stop('Red gurnard candidate-unit key conflicts with an existing record.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The latest 2025 ICES advice describes a survey trends-based assessment and states that reliable catch data are not available. No catch-at-age or age-composition input was identified.',
  survey_age_evidence = 'The assessment uses aggregate biomass indices from groundfish surveys. The advice lists survey time series but does not identify age-specific abundance observations or age compositions used in the assessment.',
  weights_evidence = 'The current survey trends-based assessment does not report age-specific stock or catch weights.',
  maturity_evidence = 'The current survey trends-based assessment does not report maturity-at-age inputs.',
  mortality_evidence = 'The survey trends-based biomass-index assessment does not report an age-structured natural-mortality input.',
  timing_evidence = 'Multiple surveys contribute to an aggregate biomass index, but the advice does not provide fractional-year timing for an age-specific population model.',
  output_evidence = 'The 2025 advice reports a survey biomass index with uncertainty and landings, but no age-specific N, F, or M outputs. The index is not an age-structured SSB estimate.',
  detailed_source_url = paste('https://doi.org/10.17895/ices.advice.27202593',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=18521',
    'https://doi.org/10.17895/ices.pub.32625759', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest inventory advice cycle is 2025. Its official advice describes a Category 3 survey trends-based assessment, built around aggregate survey biomass indices, and states that reliable catch data are unavailable. The assessment does not provide the age-disaggregated observations and outputs required for the age-structured inventory.'),
  notes = paste('The 2025 advice is based on an assessment-index series; the linked Standard Graphs source key 18521 is labelled assessment year 2023 and contains aggregate biomass-index bounds and landings, not age-specific population surfaces. This single ICES stock spans subareas 3-8 and is treated as one candidate unit across multiple ecoregions. The official 2025 advice copy, advice record, and Standard Graphs source page are cached with URLs, retrieval dates, and SHA-256 hashes in source_cache/discovery_ices_red_gurnard_2025/sources.csv. No canonical stock or numerical records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('survey trends-based assessment', register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) stop('Red gurnard candidate has an unexpected prior review state.',
  call. = FALSE)
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  tmp <- tempfile(fileext = '.csv')
  write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}
cat('Screened ICES red gurnard gur.27.3-8 against the 2025 advice; age-input eligibility is ineligible.\n')
