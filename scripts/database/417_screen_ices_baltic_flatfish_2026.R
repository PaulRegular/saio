root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_baltic_flatfish_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

screens <- data.frame(
  candidate_id = c('ICES:tur.27.22-32', 'ICES:bwp.27.2729-32', 'ICES:bzq.27.2425',
    'ICES:bzq.27.2628', 'ICES:fle.27.21-23'),
  unit_id = c('ices_turbot_baltic_22_32', 'ices_baltic_flounder_2729_32',
    'ices_flounder_baltic_2425', 'ices_flounder_baltic_2628', 'ices_flounder_baltic_21_23'),
  scientific_name = c('Psetta maxima (historic name), Scophthalmus maximus',
    'Platichthys solemdali', 'Platichthys', 'Platichthys', 'Platichthys flesus'),
  stock_name = c(
    'Turbot (Scophthalmus maximus) in subdivisions 22-32 (Baltic Sea)',
    'Baltic flounder (Platichthys solemdali) in subdivisions 27 and 29-32 (northern central and northern Baltic Sea)',
    'Flounder (Platichthys spp) in subdivisions 24 and 25 (west of Bornholm and southwestern central Baltic)',
    'Flounder (Platichthys spp) in subdivisions 26 and 28 (east of Gotland and Gulf of Gdansk)',
    'Flounder (Platichthys flesus) in subdivisions 21-23 (Kattegat, Belt Seas, and the Sound)'),
  source_key = c('22682', '22348', '22345', '22421', '25796'),
  category = c('3.2', '3', '3.2', '2.11', '2.11'),
  file = c('tur_27_22_32_2026.html', 'bwp_27_2729_32_2026.html',
    'bzq_27_2425_2026.html', 'bzq_27_2628_2026.html', 'fle_27_21_23_2026.html'),
  stock_size = c('B_index', 'B_index', 'SSB', 'B/Bmsy', 'B/Bmsy'),
  stock_size_units = c('Kilograms per hour', 'Numbers per trap (fisheries)', 'tonnes', '', ''),
  fishing_pressure = c('Lfm/Lmean', 'Lfm/Lmean', 'F', 'F/Fmsy', 'F/Fmsy'),
  stringsAsFactors = FALSE
)
screens$source_url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=',
  screens$source_key)

sha256_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  } else {
    result <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', result[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_files <- c('stock_list_2026.html', screens$file)
manifest_urls <- c('https://standardgraphs.ices.dk/stockList.aspx', screens$source_url)
manifest_rows <- match(manifest_files, manifest$file)
manifest_paths <- file.path(cache, manifest_files)
if (anyNA(manifest_rows) || any(!file.exists(manifest_paths)))
  stop('The local ICES source cache is incomplete.', call. = FALSE)
if (any(as.character(manifest$url[manifest_rows]) != manifest_urls) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(manifest_paths)$size)) ||
    !identical(tolower(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(manifest_paths, sha256_file, character(1L)))))
  stop('The cached ICES sources do not match their manifest.', call. = FALSE)

stock_list <- paste(readLines(manifest_paths[1L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_text <- lapply(manifest_paths[-1L], function(path)
  paste(readLines(path, warn = FALSE, encoding = 'UTF-8'), collapse = ' '))
for (i in seq_len(nrow(screens))) {
  stock_row_pattern <- paste0('href="ViewCharts.aspx\\?key=', screens$source_key[i],
    '">', gsub('\\.', '\\\\.', sub('^ICES:', '', screens$candidate_id[i])),
    '\\s*</a>\\s*</td><td[^>]*>', screens$category[i], '</td>')
  stock_row_verified <- grepl(stock_row_pattern, stock_list, perl = TRUE)
  expected <- c(paste0('lblStockCode">', sub('^ICES:', '', screens$candidate_id[i]), '</span>'),
    'lblYear">2026</span>', paste0('lblKey">', screens$source_key[i], '</span>'),
    'lblFAge"></span>', 'lblFLength"></span>',
    paste0('lblStockSizeDescription">', screens$stock_size[i], '</span>'),
    paste0('lblFishingPressureDescription">', screens$fishing_pressure[i], '</span>'))
  if (!stock_row_verified ||
      !all(vapply(expected, grepl, logical(1L), x = source_text[[i]], fixed = TRUE)))
    stop('Cached ICES stock list or source data does not verify ', screens$candidate_id[i],
      '.', call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
rows <- match(screens$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(screens$candidate_id) || anyDuplicated(screens$unit_id))
  stop('Expected one register row and one candidate unit per screened ICES stock.', call. = FALSE)
if (any(register$scientific_name[rows] != screens$scientific_name) ||
    any(register$stock_name[rows] != screens$stock_name) ||
    any(register$official_stock_id[rows] != sub('^ICES:', '', screens$candidate_id)))
  stop('ICES stock identity does not match the published 2026 Standard Graphs list.',
    call. = FALSE)
if (any(tolower(stocks$authority_stock_id) %in% tolower(sub('^ICES:', '', screens$candidate_id)),
    na.rm = TRUE))
  stop('An ICES stock code already appears in the canonical database.', call. = FALSE)
if (any(screens$unit_id %in% c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    na.rm = TRUE) || any(screens$unit_id %in% register$candidate_unit_id[-rows], na.rm = TRUE))
  stop('A candidate unit key conflicts with an existing record.', call. = FALSE)

survey_evidence <- c(
  'The current page reports a stock-size indicator in kilograms per hour; it does not report an age-specific survey-abundance series.',
  'The current page reports a stock-size indicator in numbers per trap from fisheries and a length-based pressure proxy; neither is an age-specific abundance index.',
  'The current page reports aggregate SSB, catches/landings, and discards; it does not report an age-specific survey index.',
  'The current page reports biomass and fishing-pressure ratios, not age-specific survey abundance.',
  'The current page reports biomass and fishing-pressure ratios, not age-specific survey abundance.'
)
output_evidence <- paste0('The 2026 source reports ', screens$stock_size,
  ifelse(nzchar(screens$stock_size_units), paste0(' (', screens$stock_size_units, ')'), ''),
  ' and ', screens$fishing_pressure,
  '; it does not publish N-at-age, F-at-age, or M-at-age surfaces.')
decision_reason <- paste0('Ineligible for the current age-disaggregated comparison: the 2026 category ',
  screens$category,
  ' advice-linked page reports aggregate stock-size and fishing-pressure indicators but no verifiable age-specific inputs or N/F/M-at-age output. Detailed assessment input files were not recovered in this screen. This does not establish that biological age samples do not exist.')

review_values <- lapply(seq_len(nrow(screens)), function(i) list(
  candidate_unit_id = screens$unit_id[i], match_status = 'new', screening_status = 'screened',
  eligibility = 'ineligible', import_status = 'not_started',
  catch_age_evidence = 'The current page provides aggregate annual catches or landings, not catch numbers-at-age or catch-at-age compositions.',
  survey_age_evidence = survey_evidence[i],
  weights_evidence = 'No age-specific weight-at-age series is reported in the current advice-linked page.',
  maturity_evidence = 'No maturity-at-age surface is reported in the current advice-linked page.',
  mortality_evidence = paste0('The published fishing-pressure measure is ', screens$fishing_pressure[i],
    '; no F-at-age or M-at-age series is reported.'),
  timing_evidence = 'The current page contains no age-specific survey observation for which fractional within-year timing could be specified.',
  output_evidence = output_evidence[i], detailed_source_url = screens$source_url[i],
  review_date = '2026-10-30', decision_reason = decision_reason[i],
  notes = 'Identity, category, year, and stock key were checked against the 2026 ICES Standard Graphs list and stock-specific source data. Cached URLs, retrieval date, revisions, sizes, and SHA-256 checksums are in source_cache/discovery_ices_baltic_flatfish_2026/sources.csv. No canonical records were added.'
))

is_initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
is_reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == screens$unit_id &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (any(!is_initial & !is_reviewed))
  stop('At least one candidate has a conflicting prior review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_along(rows)) {
    if (is_initial[i] || is_reviewed[i]) {
      for (field in names(review_values[[i]])) register[[field]][rows[i]] <- review_values[[i]][[field]]
      replace_candidate_register_row(register_path, rows[i], register[rows[i], , drop = FALSE],
        screens$candidate_id[i])
    }
  }
}

cat('Screened five current 2026 ICES Baltic flatfish stock records as ineligible for age-disaggregated comparison.\n')
