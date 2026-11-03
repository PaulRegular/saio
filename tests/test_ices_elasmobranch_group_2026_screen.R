root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_elasmobranch_group_2026')
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

codes <- c('sho.27.67', 'gfb.27.nea', 'raj.27.89a', 'rjb.27.89a', 'rjn.27.8c', 'syc.27.8abd')
units <- c('ices_sho_27_67', 'ices_gfb_27_nea', 'ices_raj_27_89a',
  'ices_rjb_27_89a', 'ices_rjn_27_8c', 'ices_syc_27_8abd')
keys <- c('18348', '23774', '19096', '13860', '19116', '21069')
graph_years <- c(2023L, 2026L, 2024L, 2020L, 2024L, 2025L)
files <- c('ICES_SAG_Source_18348_sho.html', 'ICES_SAG_Source_23774_gfb.html',
  'ICES_SAG_Source_19096_raj.html', 'ICES_SAG_Source_13860_rjb.html',
  'ICES_SAG_Source_19116_rjn.html', 'ICES_SAG_Source_21069_syc.html')

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
stopifnot(nrow(manifest) == 6L, !anyDuplicated(manifest$file),
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

sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')
sid_text <- paste(readLines(sid_path, warn = FALSE), collapse = '')
sid_manifest <- read.csv(file.path(root, 'source_cache', 'discovery_ices_sid', 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
sid_row <- match('stock_list_2026.json', sid_manifest$file)
stopifnot(sid_manifest$retrieved_on[sid_row] == '2026-10-28',
  tolower(sha256_file(sid_path)) == '913d6a3eeab9449ae3cd0dd15661a150d36ff79b6e6a9ba78d86d46ba1035f42')

for (i in seq_along(codes)) {
  candidate <- register[register$candidate_id == paste0('ICES:', codes[i]), , drop = FALSE]
  graph <- paste(readLines(file.path(cache, files[i]), warn = FALSE), collapse = ' ')
  stopifnot(nrow(candidate) == 1L, candidate$candidate_unit_id == units[i],
    candidate$match_status == 'new', candidate$screening_status == 'screened',
    candidate$eligibility == 'ineligible', candidate$review_date == '2026-10-31',
    nzchar(candidate$catch_age_evidence), nzchar(candidate$survey_age_evidence),
    nzchar(candidate$weights_evidence), nzchar(candidate$maturity_evidence),
    nzchar(candidate$mortality_evidence), nzchar(candidate$timing_evidence),
    nzchar(candidate$output_evidence), grepl(paste0('key=', keys[i]),
      candidate$detailed_source_url, fixed = TRUE),
    !tolower(codes[i]) %in% tolower(stocks$authority_stock_id),
    grepl(paste0('"StockKeyLabel":"', codes[i], '"'), sid_text, fixed = TRUE),
    grepl(codes[i], graph, fixed = TRUE),
    grepl(paste0('id="lblYear">', graph_years[i]), graph, fixed = TRUE))
}

review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_elasmobranch_group_2026.md'), warn = FALSE), collapse = '\n')
stopifnot(all(vapply(codes, grepl, logical(1L), x = review, fixed = TRUE)),
  grepl('2020 source data', review, fixed = TRUE), grepl('2024 source data', review, fixed = TRUE))
cat('ICES elasmobranch group source, identity, and no-age-series checks passed.\n')
