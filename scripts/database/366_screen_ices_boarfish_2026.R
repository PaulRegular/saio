root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_ices_boarfish_2026')
source_manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
expected <- data.frame(
  file = c('wkb_horse_mackerel_boarfish_2024.pdf', 'wgwide_2025_executive_summary.pdf',
    'ices_source_data_2026.html'),
  sha256 = c('7260901717690407AA2A0CC8CE8ACE5771BC7734E8327BFEE1EA880988E5A29A',
    '613998E9E980FBC2BB459C910447B2CE772740D91E0E2383953893984E025A12',
    '5A041CB17455A20E3F167EC920339FCD447F64382292BE211C3540F521D01BB7'),
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
for (i in seq_len(nrow(expected))) {
  path <- file.path(cache_dir, expected$file[i])
  manifest_row <- match(expected$file[i], source_manifest$file)
  if (!file.exists(path) || is.na(manifest_row) ||
      toupper(source_manifest$sha256[manifest_row]) != expected$sha256[i] ||
      sha256_file(path) != expected$sha256[i]) {
    stop('A pinned boarfish source is missing or differs from its manifest: ',
      expected$file[i], call. = FALSE)
  }
}

sid_dir <- file.path(root, 'source_cache', 'discovery_ices_sid')
sid_path <- file.path(sid_dir, 'stock_list_2026.json')
sid_manifest <- read.csv(file.path(sid_dir, 'sources.csv'), stringsAsFactors = FALSE)
sid_row <- match(basename(sid_path), sid_manifest$file)
sid_sha <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'
if (!file.exists(sid_path) || is.na(sid_row) || toupper(sid_manifest$sha256[sid_row]) != sid_sha ||
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
sid_rows <- which(vapply(objects, field, character(1L), name = 'StockKeyLabel') == 'boc.27.6-8')
if (length(sid_rows) != 1L ||
    field(objects[sid_rows], 'SpeciesScientificName') != 'Capros aper' ||
    !grepl('subareas 6-8', field(objects[sid_rows], 'StockKeyDescription'), fixed = TRUE)) {
  stop('The official ICES stock code, species, or area changed in the SID snapshot.', call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_id <- 'ICES:boc.27.6-8'
unit_id <- 'ices_boarfish_6_8'
row <- which(candidates$candidate_id == candidate_id)
if (length(row) != 1L || candidates$official_stock_id[row] != 'boc.27.6-8' ||
    candidates$scientific_name[row] != 'Capros aper' || candidates$inventory_assessment_year[row] != 2026 ||
    any(stocks$authority_stock_id == 'boc.27.6-8', na.rm = TRUE)) {
  stop('Boarfish candidate identity or current assessment listing changed.', call. = FALSE)
}
if (any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    unit_id %in% assessments$assessment_id || unit_id %in% inputs$assessment_id ||
    unit_id %in% outputs$assessment_id) {
  stop('Boarfish candidate-unit key conflicts with an existing record.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 WKBHMB final SS3 model uses total annual catch and fishery length compositions; it does not use observed catch numbers-at-age. The 2026 update remains tied to the benchmarked length-based model.',
  survey_age_evidence = 'The model uses an acoustic total-stock-biomass index, a VAST groundfish biomass index, and survey length compositions. No age-specific survey abundance index is documented in the benchmark inputs.',
  weights_evidence = 'The assessment uses length-weight relationships and weight-at-length; it does not use weight-at-age as an input.',
  maturity_evidence = 'Maturity is represented by a time-invariant length ogive (L50 = 88 mm), not a maturity-at-age input.',
  mortality_evidence = 'Natural mortality is fixed at 0.174 and invariant across time and length in the benchmarked SS3 model.',
  timing_evidence = 'The benchmark places the acoustic index in month 6 and the groundfish index in month 11; the 2026 graph does not expose an age-specific index timing.',
  output_evidence = 'The 2026 ICES graph reports recruitment at age 0, SSB, and F for ages 4-14 with uncertainty. It does not report N-at-age or a full age-specific population surface.',
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.25002482',
    'https://doi.org/10.17895/ices.pub.30233824',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25915', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest 2026 ICES output follows the 2024 WKBHMB benchmark assessment, which WGWIDE 2025 describes as the current boarfish method. The fitted SS3 observations are total catch, aggregate acoustic and VAST biomass indices, and length compositions. Age-derived recruitment and F outputs do not establish age-disaggregated input data; the case is therefore ineligible for this age-input set.'),
  notes = paste('Identity is verified against the pinned 2026 ICES SID. The 2024 WKBHMB report describes a length-based SS3 model with a 30-age population structure, not observed catch-at-age or age-specific survey likelihoods. Assessment key 25915 supplies 2026 output series only. Source files and checksums are in the ignored local cache under source_cache/discovery_ices_boarfish_2026/. No canonical assessment or numerical records were added.')
)
initial <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
reviewed <- candidates$match_status[row] == 'new' &&
  candidates$candidate_unit_id[row] == unit_id &&
  candidates$screening_status[row] == 'screened' &&
  candidates$eligibility[row] == 'ineligible' &&
  grepl('does not use observed catch numbers-at-age', candidates$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) stop('Boarfish candidate has an unexpected prior review state.', call. = FALSE)
if (initial) {
  for (name in names(review)) candidates[[name]][row] <- review[[name]]
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(candidates) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  tmp <- tempfile(fileext = '.csv')
  write.csv(candidates[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}
cat('Screened ICES boarfish boc.27.6-8 against the 2024 benchmark and 2026 outputs; age-input eligibility is ineligible.\n')
