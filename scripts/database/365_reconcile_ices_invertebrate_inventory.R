root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_ices_sid')
cache_path <- file.path(cache_dir, 'stock_list_2026.json')
expected_sha256 <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (!file.exists(cache_path) || sha256_file(cache_path) != expected_sha256) {
  stop('Cached 2026 ICES SID snapshot is missing or has changed.', call. = FALSE)
}
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
manifest_row <- match(basename(cache_path), manifest$file)
if (is.na(manifest_row) || manifest$sha256[manifest_row] != expected_sha256 ||
    manifest$url[manifest_row] != 'https://sid.ices.dk/services/year/2026') {
  stop('ICES SID provenance does not match the pinned source.', call. = FALSE)
}

json <- paste(readLines(cache_path, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
objects <- regmatches(json, gregexpr('(?s)\\{[^{}]*\\}', json, perl = TRUE))[[1L]]
field <- function(object, name) {
  pattern <- paste0('"', name, '"[[:space:]]*:[[:space:]]*"([^"]*)"')
  match <- regmatches(object, regexec(pattern, object, perl = TRUE))[[1L]]
  if (length(match) < 2L) NA_character_ else match[[2L]]
}
sid <- data.frame(
  stock_code = vapply(objects, field, character(1L), name = 'StockKeyLabel'),
  scientific_name = vapply(objects, field, character(1L), name = 'SpeciesScientificName'),
  stringsAsFactors = FALSE
)
sid <- sid[!is.na(sid$stock_code), , drop = FALSE]

candidates <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

species <- c('Nephrops norvegicus', 'Pandalus borealis')
rows <- which(candidates$organization == 'ICES' & candidates$scientific_name %in% species)
if (length(rows) != 32L || anyDuplicated(candidates$official_stock_id[rows])) {
  stop('The ICES invertebrate inventory set changed; review it before reconciliation.', call. = FALSE)
}
source_rows <- match(candidates$official_stock_id[rows], sid$stock_code)
if (anyNA(source_rows) || anyDuplicated(source_rows) ||
    !identical(candidates$scientific_name[rows], sid$scientific_name[source_rows])) {
  stop('ICES stock codes and taxa do not match the pinned SID snapshot.', call. = FALSE)
}
if (any(candidates$official_stock_id[rows] %in% stocks$authority_stock_id) ||
    any(candidates$official_stock_id[rows] %in% assessments$assessment_id) ||
    any(candidates$official_stock_id[rows] %in% inputs$assessment_id) ||
    any(candidates$official_stock_id[rows] %in% outputs$assessment_id)) {
  stop('An ICES invertebrate identity overlaps an existing canonical record.', call. = FALSE)
}
unit_ids <- paste0('ices_', gsub('(^_+|_+$)', '', gsub('[^a-z0-9]+', '_',
  tolower(candidates$official_stock_id[rows]))))
if (anyDuplicated(unit_ids) || any(unit_ids %in% candidates$candidate_unit_id[-rows])) {
  stop('Derived ICES candidate-unit identifiers are not unique.', call. = FALSE)
}
reviewed <- identical(candidates$match_status[rows], rep('new', length(rows))) &&
  identical(candidates$candidate_unit_id[rows], unit_ids) &&
  all(grepl('crosswalked against the pinned 2026 ICES SID', candidates$notes[rows],
    fixed = TRUE))
initial <- all(candidates$match_status[rows] == 'unreviewed') &&
  all(is.na(candidates$candidate_unit_id[rows]) | !nzchar(candidates$candidate_unit_id[rows]))
if (!initial && !reviewed) stop('ICES invertebrate rows have unexpected prior review state.', call. = FALSE)
if (any(candidates$screening_status[rows] != 'screened') ||
    any(candidates$eligibility[rows] != 'ineligible') ||
    any(candidates$import_status[rows] != 'not_started')) {
  stop('ICES invertebrate scope-screen status changed unexpectedly.', call. = FALSE)
}

if (!reviewed) {
  for (i in seq_along(rows)) {
    row <- rows[i]
    candidates$candidate_unit_id[row] <- unit_ids[i]
    candidates$match_status[row] <- 'new'
    candidates$review_date[row] <- '2026-10-30'
    candidates$notes[row] <- paste(candidates$notes[row],
      'Identity crosswalked against the pinned 2026 ICES SID by official stock code and scientific name; assessment inputs and outputs remain unaudited because this invertebrate is outside the initial marine-finfish scope.')
  }
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && !reviewed) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(candidates) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  tmp <- tempfile(fileext = '.csv')
  for (row in rows) {
    write.csv(candidates[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
    lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  }
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}

cat('Reconciled', length(rows), 'ICES invertebrate inventory identities; source-data eligibility remains unaudited.\n')
