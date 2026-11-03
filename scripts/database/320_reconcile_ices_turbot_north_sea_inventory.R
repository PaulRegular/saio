root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
candidates <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))

candidate_id <- 'ICES:tur.27.4'
stock_id <- 'ck_ices_wgnssk_maximus_ns_4'
benchmark_id <- 'ices_turbot_north_sea_2025_benchmark'
summary_id <- 'ices_turbot_north_sea_2026_summary'
i <- which(candidates$candidate_id == candidate_id)
s <- which(stocks$stock_id == stock_id)
if (length(i) != 1L || length(s) != 1L) stop('Expected one inventory row and canonical stock.', call. = FALSE)
if (candidates$official_stock_id[i] != 'tur.27.4' ||
    !grepl('Scophthalmus maximus', candidates$scientific_name[i], fixed = TRUE) ||
    !grepl('Subarea 4', candidates$stock_name[i], fixed = TRUE)) {
  stop('ICES stock-code, species, or assessment-area evidence changed.', call. = FALSE)
}
if (any(stocks$authority_stock_id[-s] == 'tur.27.4', na.rm = TRUE)) {
  stop('The official stock code has been assigned to another canonical stock.', call. = FALSE)
}
if (!grepl(stocks$scientific_name[s], candidates$scientific_name[i], fixed = TRUE) ||
    stocks$region[s] != 'Northeast Atlantic') {
  stop('Canonical species or basin does not support this identity match.', call. = FALSE)
}
replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  lf <- which(bytes == as.raw(10L))
  line_number <- row_index + 1L
  if (length(lf) < line_number) stop('CSV row index is out of range: ', path, call. = FALSE)
  first <- if (line_number == 1L) 1L else lf[line_number - 1L] + 1L
  last <- lf[line_number]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) {
    as.raw(c(13L, 10L))
  } else {
    as.raw(10L)
  }
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- rawToChar(replacement)
  replacement <- sub('\\r?\\n$', '', replacement, perl = TRUE)
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}
if (!all(c(benchmark_id, summary_id) %in% assessments$assessment_id) ||
    sum(inputs$assessment_id == benchmark_id) == 0L ||
    sum(outputs$assessment_id == benchmark_id) == 0L ||
    sum(outputs$assessment_id == summary_id) == 0L) {
  stop('Expected detailed benchmark and later advice summary are not represented.', call. = FALSE)
}

stocks$authority_stock_id[s] <- 'tur.27.4'
stocks$notes[s] <- paste(
  'Originally added as Charbonneau-Keith metadata; matched to official ICES stock',
  'tur.27.4 using species and North Sea area. Detailed 2025 WKBNSCS M9 inputs and',
  'outputs and separate 2026 advice summaries are recorded; see',
  'source_reviews/ices_turbot_north_sea.md.'
)

review <- list(
  matched_stock_id = stock_id,
  match_status = 'matched',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'imported',
  catch_age_evidence = 'The canonical 2025 WKBNSCS M9 record contains catch numbers-at-age in thousands of fish for 1981-2023, ages 1-8 (8+); see ices_turbot_north_sea.md.',
  survey_age_evidence = 'Age-specific BTS+COAST index values (1991-2023, ages 1-7) and BSAS index values (2019-2023, ages 1-8) are retained in the 2025 M9 canonical record.',
  weights_evidence = 'Observed stock weights by year and age are retained; the assessment also uses fleet catch weights. The source notes distinguish native observations from the fitted weight surface.',
  maturity_evidence = 'The fixed female maturity-at-age vector for ages 1-8 is retained in the canonical inputs.',
  mortality_evidence = 'The M9 model uses the fixed age-varying Lorenzen M vector retained in the canonical inputs; M is not estimated.',
  timing_evidence = 'Both age-specific surveys use sampling_time = 0.705 in the detailed 2025 M9 configuration.',
  output_evidence = 'The 2025 M9 record contains official N-at-age, F-at-age, recruitment, SSB and Fbar outputs. The separate 2026 advice summary contains aggregate outputs through 2025; it is not merged with the M9 run.',
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.28715180', 'https://asd.ices.dk/viewAdvice/5097', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('Matched by official ICES code tur.27.4, scientific name and North Sea area to the existing canonical stock. The latest 2026 advice summary and the detailed 2025 M9 benchmark are already recorded separately; the latter contains a complete age-structured input/output set. This inventory row is a crosswalk, not a new stock or assessment import.'),
  notes = paste('The 2026 ICES Advice View is assessment year 2026 and is summary-only in the canonical database. The 2025 WKBNSCS benchmark M9 is a distinct detailed run and was not the model used for 2025 advice. See source_reviews/ices_turbot_north_sea.md and the ignored local cache under source_cache/ices_turbot_north_sea_preflight/.')
)
if (!is.na(candidates$matched_stock_id[i]) && candidates$matched_stock_id[i] != stock_id) {
  stop('Inventory row is already linked to a different stock.', call. = FALSE)
}
for (column in names(review)) candidates[[column]][i] <- review[[column]]
stock_path <- file.path(root, 'database', 'stocks.csv')
replace_csv_row(stock_path, s, stocks[s, , drop = FALSE])
replace_csv_row(path, i, candidates[i, , drop = FALSE])
cat('Reconciled ICES tur.27.4 to', stock_id, 'using the official code, species, area, and existing source records.\n')
