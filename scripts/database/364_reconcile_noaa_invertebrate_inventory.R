root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache_file <- 'stock_assessment_summary.rda'
expected_url <- paste0('https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/',
  '664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_summary.rda')
expected_revision <- '664c4237e26520b260a090e1821a2cee5d1cdf07'
stock_ids <- c('10080', '10082', '10084', '10087', '10088', '10786', '10787',
  '10792', '10798', '10802', '10803', '10809', '10810', '10811', '10813',
  '10814', '10816', '10817', '10820', '10821', '10933', '10958', '11031',
  '11201', '11843', '12532', '12533', '12534', '14841', '14842')
candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- c(
  'noaa_brown_shrimp_south_atlantic', 'noaa_pink_shrimp_south_atlantic',
  'noaa_white_shrimp_south_atlantic', 'noaa_giant_octopus_bering',
  'noaa_giant_octopus_gulf_alaska', 'noaa_sea_scallop_nw_atlantic',
  'noaa_atlantic_surfclam_mid_atlantic', 'noaa_longfin_squid_georges_bank',
  'noaa_shortfin_squid_nw_atlantic', 'noaa_royal_red_shrimp_gulf',
  'noaa_brown_rock_shrimp_south_atlantic', 'noaa_red_king_crab_bristol_bay',
  'noaa_red_king_crab_norton_sound', 'noaa_red_king_crab_pribilof',
  'noaa_blue_king_crab_pribilof', 'noaa_blue_king_crab_st_matthew',
  'noaa_golden_king_crab_aleutian', 'noaa_golden_king_crab_pribilof',
  'noaa_snow_crab_bering', 'noaa_southern_tanner_crab_bering',
  'noaa_red_king_crab_western_aleutian', 'noaa_red_deepsea_crab_nw_atlantic',
  'noaa_caribbean_spiny_lobster_south_atlantic_gulf', 'noaa_weathervane_scallop_alaska',
  'noaa_spanner_crab_hawaii', 'noaa_caribbean_spiny_lobster_puerto_rico',
  'noaa_caribbean_spiny_lobster_st_thomas', 'noaa_caribbean_spiny_lobster_st_croix',
  'noaa_golden_king_crab_western_aleutian', 'noaa_golden_king_crab_eastern_aleutian')
scientific_names <- c(
  'Farfantepenaeus aztecus', 'Farfantepenaeus duorarum', 'Litopenaeus setiferus',
  'Enteroctopus dofleini', 'Enteroctopus dofleini', 'Placopecten magellanicus',
  'Spisula solidissima', 'Loligo pealeii', 'Illex illecebrosus', 'Pleoticus robustus',
  'Sicyonia brevirostris', 'Paralithodes camtschaticus', 'Paralithodes camtschaticus',
  'Paralithodes camtschaticus', 'Paralithodes platypus', 'Paralithodes platypus',
  'Lithodes aequispinus', 'Lithodes aequispinus', 'Chionoecetes opilio',
  'Chionoecetes bairdi', 'Paralithodes camtschaticus', 'Chaceon quinquedens',
  'Panulirus argus', 'Patinopecten caurinus', 'Ranina ranina', 'Panulirus argus',
  'Panulirus argus', 'Panulirus argus', 'Lithodes aequispinus', 'Lithodes aequispinus')
common_names <- c(
  'Brown shrimp', 'Pink shrimp', 'White shrimp', 'Giant octopus', 'Giant octopus',
  'Sea scallop', 'Atlantic surfclam', 'Longfin inshore squid', 'Northern shortfin squid',
  'Royal red shrimp', 'Brown rock shrimp', 'Red king crab', 'Red king crab',
  'Red king crab', 'Blue king crab', 'Blue king crab', 'Golden king crab',
  'Golden king crab', 'Snow crab', 'Southern Tanner crab', 'Red king crab',
  'Red deepsea crab', 'Caribbean spiny lobster', 'Weathervane scallop', 'Spanner crab',
  'Caribbean spiny lobster', 'Caribbean spiny lobster', 'Caribbean spiny lobster',
  'Golden king crab', 'Golden king crab')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

cache_path <- file.path(cache, cache_file)
if (!file.exists(cache_path)) stop('Missing cached NOAA Stock SMART metadata.', call. = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_row <- match(cache_file, manifest$file)
if (is.na(manifest_row) || manifest$url[manifest_row] != expected_url ||
    manifest$revision[manifest_row] != expected_revision ||
    tolower(manifest$sha256[manifest_row]) != sha256_file(cache_path))
  stop('Cached NOAA metadata differs from its recorded pinned source.', call. = FALSE)

source_env <- new.env(parent = emptyenv())
load(cache_path, envir = source_env)
metadata <- source_env$stock_assessment_summary
for (i in seq_along(stock_ids)) {
  source_rows <- metadata[as.character(metadata$stock_id) == stock_ids[i], , drop = FALSE]
  if (!nrow(source_rows) ||
      !all(source_rows$common_name == common_names[i]) ||
      !all(source_rows$scientific_name == scientific_names[i]))
    stop('Stock SMART identity is not internally consistent for ', candidate_ids[i], '.',
      call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) ||
    !identical(as.character(candidates$official_stock_id[rows]), stock_ids) ||
    !identical(as.character(candidates$scientific_name[rows]), scientific_names) ||
    any(candidates$screening_status[rows] != 'screened') ||
    any(candidates$eligibility[rows] != 'ineligible') ||
    any(candidates$import_status[rows] != 'not_started'))
  stop('NOAA invertebrate inventory rows differ from the reviewed scope-screen state.',
    call. = FALSE)
initial_state <- all(candidates$match_status[rows] == 'unreviewed') &&
  all(is.na(candidates$candidate_unit_id[rows]) | !nzchar(candidates$candidate_unit_id[rows]))
reviewed_state <- identical(as.character(candidates$match_status[rows]), rep('new', length(rows))) &&
  identical(as.character(candidates$candidate_unit_id[rows]), unit_ids) &&
  all(grepl('outside the initial marine-finfish scope', candidates$decision_reason[rows],
    fixed = TRUE))
if (!initial_state && !reviewed_state)
  stop('NOAA invertebrate identities conflict with previous candidate review.', call. = FALSE)
if (any(stocks$authority_stock_id %in% stock_ids, na.rm = TRUE) ||
    any(assessments$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(inputs$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(outputs$assessment_id %in% unit_ids, na.rm = TRUE))
  stop('NOAA invertebrate identities conflict with canonical numerical records.',
    call. = FALSE)

for (i in seq_along(rows)) {
  row <- rows[i]
  common_name <- candidates$stock_name[row]
  candidates$candidate_unit_id[row] <- unit_ids[i]
  candidates$match_status[row] <- 'new'
  candidates$decision_reason[row] <- paste('Stock SMART identifies a distinct', common_name,
    'management unit. This invertebrate is outside the initial marine-finfish scope,',
    'so it is screened ineligible without assessing model inputs.')
  candidates$notes[row] <- paste('Identity verified against the pinned NOAA-EDAB Stock SMART',
    'snapshot. Assessment and age-input completeness remain unreviewed because the taxon is',
    'outside the initial marine-finfish scope.')
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  for (row in rev(sort(rows))) {
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', candidates$candidate_id[row],
        '.', call. = FALSE)
    first <- line_feeds[physical_line - 1L] + 1L
    last <- line_feeds[physical_line]
    ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
      as.raw(c(13L, 10L)) else as.raw(10L)
    tmp <- tempfile(fileext = '.csv')
    write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
      col.names = FALSE, quote = TRUE, na = '')
    replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
    unlink(tmp)
    replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
    before <- bytes[seq_len(first - 1L)]
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    bytes <- c(before, charToRaw(replacement), ending, after)
  }
  writeBin(bytes, candidate_path)
}

cat('Reconciled 30 NOAA invertebrate identities; all remain outside the finfish scope.\n')
