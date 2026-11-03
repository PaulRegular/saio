root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_screen_first_six_2026')
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

codes <- c('rhg.27.nea', 'aru.27.6b7-1012', 'mur.27.67a-ce-k89a',
  'rji.27.67', 'rju.27.7bj', 'rjm.27.67bj')
units <- c('ices_rhg_27_nea', 'ices_aru_27_6b7_1012',
  'ices_mur_27_67a_ce_k89a', 'ices_rji_27_67', 'ices_rju_27_7bj',
  'ices_rjm_27_67bj')
advice_ids <- c('3961', '3954', '7229', '3780', '3781', '7166')
graph_keys <- c('20946', '20919', '25910', '19099', '19179', '25849')
years <- c(2025L, 2025L, 2026L, 2024L, 2024L, 2026L)
categories <- c('6.3', '3.2', '5.2', '5.2', '6.3', '3')
methods <- c('no assessment', 'Survey trends-based assessment',
  'no assessment', 'no assessment', 'no assessment',
  'Trends from biomass index and length-based indicators')

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
stopifnot(nrow(manifest) == 12L, !anyDuplicated(manifest$file),
  all(manifest$retrieved_on == '2026-10-31'), all(file.exists(file.path(cache, manifest$file))))
sha256_file <- function(path) {
  result <- system2('certutil.exe', c('-hashfile',
    shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  stopifnot(length(hashes) == 1L)
  hashes
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$file[i])
  stopifnot(as.numeric(manifest$bytes[i]) == file.info(path)$size,
    identical(sha256_file(path), tolower(manifest$sha256[i])))
}

sid <- paste(readLines(file.path(root, 'source_cache', 'discovery_ices_sid',
  'stock_list_2026.json'), warn = FALSE), collapse = '')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')
sid_manifest <- read.csv(file.path(root, 'source_cache', 'discovery_ices_sid', 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(sid_manifest$retrieved_on[match('stock_list_2026.json', sid_manifest$file)] == '2026-10-28',
  tolower(sha256_file(sid_path)) == '913d6a3eeab9449ae3cd0dd15661a150d36ff79b6e6a9ba78d86d46ba1035f42')
advice_files <- c('ICES_Advice_3961_rhg_2025.html', 'ICES_Advice_3954_aru_2025.html',
  'ICES_Advice_7229_mur_2026.html', 'ICES_Advice_3780_rji_2024.html',
  'ICES_Advice_3781_rju_2024.html', 'ICES_Advice_7166_rjm_2026.html')
graph_files <- c('ICES_SAG_Source_20946_rhg_2025.html', 'ICES_SAG_Source_20919_aru_2025.html',
  'ICES_SAG_Source_25910_mur_2026.html', 'ICES_SAG_Source_19099_rji_2024.html',
  'ICES_SAG_Source_19179_rju_2024.html', 'ICES_SAG_Source_25849_rjm_2026.html')
for (i in seq_along(codes)) {
  code <- codes[i]
  candidate <- register[register$candidate_id == paste0('ICES:', code), , drop = FALSE]
  stopifnot(nrow(candidate) == 1L,
    candidate$candidate_unit_id == units[i], candidate$match_status == 'new',
    candidate$screening_status == 'screened', candidate$eligibility == 'ineligible',
    candidate$review_date == '2026-10-31',
    nzchar(candidate$catch_age_evidence), nzchar(candidate$survey_age_evidence),
    nzchar(candidate$weights_evidence), nzchar(candidate$maturity_evidence),
    nzchar(candidate$mortality_evidence), nzchar(candidate$timing_evidence),
    nzchar(candidate$output_evidence), grepl(paste0('viewAdvice/', advice_ids[i]),
      candidate$detailed_source_url, fixed = TRUE),
    grepl(paste0('key=', graph_keys[i]), candidate$detailed_source_url, fixed = TRUE),
    !code %in% stocks$authority_stock_id,
    grepl(paste0('"StockKeyLabel":"', code, '"'), sid, fixed = TRUE))

  advice_text <- paste(readLines(file.path(cache, advice_files[i]), warn = FALSE), collapse = ' ')
  graph_text <- paste(readLines(file.path(cache, graph_files[i]), warn = FALSE), collapse = ' ')
  stopifnot(grepl(code, advice_text, fixed = TRUE), grepl(as.character(years[i]), advice_text, fixed = TRUE),
    grepl(code, graph_text, fixed = TRUE), grepl(as.character(years[i]), graph_text, fixed = TRUE),
    grepl(graph_keys[i], graph_text, fixed = TRUE))
}

review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_initial_data_limited_group_2026.md'), warn = FALSE)
stopifnot(all(vapply(codes, grepl, logical(1L), x = paste(review, collapse = '\n'), fixed = TRUE)))
cat('ICES initial data-limited group screen: passed.\n')
