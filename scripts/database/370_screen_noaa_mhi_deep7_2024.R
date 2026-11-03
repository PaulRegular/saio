root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_mhi_deep7_2024')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

expected <- data.frame(
  file = c('noaa_mhi_deep7_resource_page.html', 'noaa_mhi_deep7_2024_panel_review.pdf'),
  sha256 = c('530E4A4062E02A2B3118A9E04452BCEA897EF7102B90862136580D5946A32919',
    '433DD8AD16EC40D882994BF676C3E536885617DC2907BC1CAC5CFA10016BC748'),
  stringsAsFactors = FALSE
)
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected))) {
  path <- file.path(cache_dir, expected$file[i])
  source_row <- match(expected$file[i], manifest$file)
  if (!file.exists(path) || is.na(source_row) ||
      manifest$sha256[source_row] != expected$sha256[i] ||
      sha256_file(path) != expected$sha256[i]) {
    stop('A pinned Deep 7 source is missing or differs from its manifest: ',
      expected$file[i], call. = FALSE)
  }
}

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (sha256_file(stocksmart_path) !=
    'AD47F9EEB240C2E77B2B952809A12C4FA739E3F0D39BEAB283B413FDBAEF76A8') {
  stop('The pinned NOAA Stock SMART snapshot is missing or changed.', call. = FALSE)
}
stocksmart_env <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11827' &
  stocksmart$assessment_year == 2024, , drop = FALSE]
if (nrow(stocksmart) != 1L || stocksmart$assessment_id != 13362L ||
    stocksmart$last_data_year != 2023L || stocksmart$science_center != 'PIFSC' ||
    stocksmart$review_result != 'Full acceptance' || stocksmart$assessment_model != 'JABBA') {
  stop('The pinned NOAA Stock SMART snapshot no longer verifies the accepted 2024 Deep 7 run.',
    call. = FALSE)
}

resource_page <- paste(readLines(file.path(cache_dir, expected$file[1L]),
  warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('Benchmark Stock Assessment for the Main Hawaiian Islands Deep 7 Bottomfish Complex in 2024',
    resource_page, fixed = TRUE) || !grepl('NOAA-TM-NMFS-PIFSC-157', resource_page, fixed = TRUE)) {
  stop('The pinned NOAA resource page does not match the reviewed assessment.', call. = FALSE)
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

candidate_id <- 'NOAA:11827'
unit_id <- 'noaa_mhi_deep7_complex'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$stock_name[row] !=
    'Main Hawaiian Islands Deep 7 Bottomfish Multi-species Complex' ||
    register$inventory_assessment_year[row] != 2024L ||
    any(grepl('Deep 7', stocks$common_name, ignore.case = TRUE), na.rm = TRUE)) {
  stop('Deep 7 candidate identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    unit_id %in% assessments$assessment_id || unit_id %in% inputs$assessment_id ||
    unit_id %in% outputs$assessment_id) {
  stop('Deep 7 candidate-unit key conflicts with an existing record.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The accepted 2024 Deep 7 assessment is a Bayesian surplus-production model using aggregate total catch by species and aggregate abundance indices; it does not fit catch-at-age. Its supplementary Opakapaka Stock Synthesis model uses commercial and non-commercial catch, CPUE, BFISH relative-abundance indices, length compositions, and commercial weight compositions, but no observed catch-at-age or age-composition likelihood is documented in Figure 12.',
  survey_age_evidence = 'The main assessment uses annual standardized fishery CPUE (fishing years 1949-2023) and a fishery-independent BFISH relative biomass index based on surveys in 2016-2022 (early fall, corresponding to fishing years 2017-2023). Both indices are aggregate, not age-specific. The Opakapaka-only model also uses aggregate CPUE/BFISH indices.',
  weights_evidence = 'The supplementary Opakapaka model uses commercial-fishery weight-composition data; fixed life-history inputs are used for mortality, growth, longevity, fecundity, and reproduction. No weight-at-age likelihood is documented.',
  maturity_evidence = 'Age-related life-history information is fixed in the supplementary Opakapaka model. The report does not document observed maturity-at-age as an assessment likelihood input.',
  mortality_evidence = 'Natural mortality is treated as fixed life-history information in the supplementary Opakapaka model; the accepted Deep 7 JABBA model is aggregate and does not estimate M-at-age.',
  timing_evidence = 'The main model uses July-June fishing years. BFISH surveys occur in early fall of calendar years 2016-2022 and are assigned to the beginnings of fishing years 2017-2023. These are aggregate indices, so age-specific observation timing is not applicable.',
  output_evidence = 'The accepted JABBA model reports annual exploitable biomass, harvest rate, stock status, and reference points through 2023, with projections through 2029. The supplementary Opakapaka age-structured model reports biomass, harvest rate, and stock status; the report does not provide the age-disaggregated inputs required for an age-based tinyAM translation.',
  detailed_source_url = paste('https://repository.library.noaa.gov/view/noaa/56878/noaa_56878_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/56878',
    'https://www.fisheries.noaa.gov/s3/2024-07/Benchmark-Stock-Assessment-for-the-Main-Hawaiian-Islands-Deep-7-Bottomfish-Complex-in-2024-Chair-Report-508.pdf',
    'https://apps-st.fisheries.noaa.gov/stocksmart', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = 'The accepted assessment is an aggregate JABBA surplus-production model. Although the report also evaluates an Opakapaka-only age-structured Stock Synthesis model, its documented data inputs are catch, aggregate indices, length compositions, and weight compositions, not catch-at-age or observed age compositions. The assessment therefore does not meet the age-disaggregated input requirement.',
  notes = paste('NOAA Stock SMART PIFSC ID 11827 is the Main Hawaiian Islands Deep 7 multispecies management complex; the 2024 assessment is ID 13362 and uses data through 2023. The seven species are one assessment complex, not seven candidate units. The report discusses an Opakapaka-only model separately; this component is not conflated with the complex or NOAA:12442, the separate Opakapaka candidate row. The NOAA landing page and WPSAR chair review are cached in source_cache/discovery_noaa_mhi_deep7_2024/sources.csv. The primary report PDF is public at the cited NOAA repository URL, but a local download attempt returned HTTP 403 and was not retained. No canonical stock or numerical assessment records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('does not fit catch-at-age', register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) stop('Deep 7 candidate has an unexpected prior review state.',
  call. = FALSE)
update_review <- initial || any(vapply(names(review), function(name) {
  current <- register[[name]][row]
  expected <- review[[name]]
  if (is.na(current)) return(!is.na(expected))
  !identical(as.character(current), as.character(expected))
}, logical(1L)))
if (update_review) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && update_review) {
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
cat('Screened NOAA Stock SMART 11827 against the accepted 2024 Deep 7 assessment; age-input eligibility is ineligible.\n')
