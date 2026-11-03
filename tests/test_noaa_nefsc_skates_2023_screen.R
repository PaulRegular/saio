root <- "."
source(file.path(root, 'scripts', 'database',
  '499_screen_noaa_nefsc_skates_2023.R'))

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('NOAA:11036', 'NOAA:11047', 'NOAA:11063', 'NOAA:11071',
  'NOAA:11076', 'NOAA:11080', 'NOAA:11269')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_northeast_skate_complex', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_nefsc_skate_complex_2023.md'), warn = FALSE), collapse = ' ')

source_cache <- file.path(root, 'source_cache', 'discovery_noaa_nefsc_skates_2023')
manifest <- read.csv(file.path(source_cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify a cached source checksum.', call. = FALSE)
  hash
}
for (i in seq_len(nrow(manifest))) {
  cached <- file.path(source_cache, manifest$file[i])
  stopifnot(file.exists(cached), file.info(cached)$size == manifest$bytes[i],
    sha256_file(cached) == manifest$sha256[i], manifest$retrieved_on[i] == '2026-11-01')
}

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(nrow(rows) == 7L, !anyDuplicated(rows$candidate_id),
  all(rows$candidate_unit_id == 'noaa_northeast_skate_complex'),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'), all(rows$import_status == 'not_started'),
  all(grepl('catch numbers-at-age', rows$catch_age_evidence, fixed = TRUE)),
  all(grepl('Index Method', rows$survey_age_evidence, fixed = TRUE)),
  all(grepl('annual F, recruitment and stock biomass', rows$output_evidence, fixed = TRUE)),
  all(grepl('sis/docServlet', rows$detailed_source_url, fixed = TRUE)),
  nrow(unit) == 1L, unit$inventory_entries == 7L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible',
  all(vapply(ids, function(id) grepl(id, unit$candidate_ids, fixed = TRUE), logical(1L))),
  grepl('one Northeast Skate Complex management unit', review, fixed = TRUE),
  grepl('Composition Input Data level 1', review, fixed = TRUE),
  grepl('could not be estimated', review, fixed = TRUE),
  !any(stocks$authority_stock_id %in% sub('^NOAA:', '', ids), na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_northeast_skate_complex_2023', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_northeast_skate_complex_2023', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_northeast_skate_complex_2023', na.rm = TRUE),
  sum(noaa$inventory_rows) == 432L, sum(noaa$screening_not_started) == 0L,
  sum(noaa$screening_complete) == 432L)

cat('NOAA Northeast Skate Complex screening, source provenance, unit crosswalk and no-import checks passed.\n')
