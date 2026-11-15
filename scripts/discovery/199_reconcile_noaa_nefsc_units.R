root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

review <- data.frame(
  candidate_id = c('NOAA:10164','NOAA:10508','NOAA:10509','NOAA:10519'),
  matched_stock_id = c('nefsc_atlantic_mackerel','ck_nefsc_saw_morhua_gom',
    'nefsc_cod_georges_bank','ck_nefsc_garmiii_aeglefinus_5y'),
  eligibility = c('eligible','ineligible','unresolved','unresolved'),
  source_review = c('nefsc_atlantic_mackerel.md','nefsc_gom_cod_2021.md',
    'ck_nefsc_garmiii_morhua_gb.md','nefsc_haddock_gulf_of_maine.md'),
  detailed_source_url = c(
    'https://doi.org/10.25923/swk4-1e81',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2021&species_id=4&stock_id=2&review_type_id=3&filename=2021_COD_GM.zip',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=4&stock_id=1&review_type_id=3&info_type_id=-1&filename=2024_COD_GB_Report.pdf',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=2&review_type_id=6&filename=2026_HAD_GOM.zip'),
  stringsAsFactors = FALSE
)
cached_sources <- c('nefsc_atlantic_mackerel_2018','ck_nefsc_saw_morhua_gom_2021',
  'ck_nefsc_garmiii_morhua_gb_2024','nefsc_haddock_gulf_of_maine_2026')

review$catch_age_evidence <- c(
  'The detailed 2018 SAW-64 Run 118 contains combined U.S.-Canadian catch numbers-at-age 1-10+ for 1968-2016; the 2025 update has aggregate catch only.',
  'Official 2021 M02 inputs contain catch-at-age for ages 1-9+ over 1982-2019; this applies to the legacy combined GOM unit only.',
  'The 2024 MT run 4 record contains combined catch totals for 2014-2023; numerical catch-at-age and age-composition arrays were not recovered.',
  'The 2026 management-track report provides aggregate catch through 2025; numerical catch-at-age and composition matrices were not recovered.'
)
review$survey_age_evidence <- c(
  'SAW-64 Tables A38-A39 contain spring trawl abundance-at-age for ages 1-10; the egg/ichthyoplankton index is aggregate only.',
  'The 2021 M02 source contains NEFSC spring and fall calibrated abundance-at-age; the MADMF spring age series was not recovered.',
  'The 2024 assessment identifies age-structured surveys, but no run-matched numerical survey index/composition arrays were recovered.',
  'The 2026 report describes four abundance indices and their age-composition likelihoods, but numerical observation arrays are unavailable.'
)
review$weights_evidence <- c(
  'SAW-64 Tables A33-A34 provide catch/SSB and January 1 weight-at-age; they are kept distinct.',
  'The 2021 source contains catch weights and January 1/stock weights by age.',
  'The 2024 public record does not contain numerical weight-at-age surfaces.',
  'The 2026 report describes age-specific weights, but the fitted numerical surface is unavailable.'
)
review$maturity_evidence <- c(
  'SAW-64 Table A4 provides annual Canadian maturity-at-age ogives for the northern spawning contingent.',
  'The 2021 M02 supplement provides a female age-based maturity curve; values are rounded digitizations and explicitly approximate.',
  'The numerical maturity-at-age surface for the 2024 run was not recovered.',
  'The 2026 assessment uses time-averaged maturity-at-age; the numerical vector was not recovered.'
)
review$mortality_evidence <- c(
  'M = 0.2 per year is fixed in the detailed 2018 assessment.',
  'M02 fixes M = 0.2 per year for ages 1-9+.',
  'The 2024 run fixes M = 0.29 per year for ages 1-9+.',
  'The 2026 model fixes age-invariant M = 0.2 per year.'
)
review$timing_evidence <- c(
  'The 2018 translation review uses the mean spring survey day, 95.7/365; this is documented as a timing approximation.',
  'The 2021 source distinguishes NEFSC spring and fall survey series; exact fractional sampling dates are not reported in the source review.',
  'The 2024 report does not provide recoverable numerical timing for the missing survey arrays.',
  'The 2026 report describes spring/fall survey series; exact annual timing and observation arrays were not recovered.'
)
review$output_evidence <- c(
  'Official SAW-64 Tables A42-A45 provide SSB, N-at-age, F-at-age, Fbar, recruitment and biomass; 2025 aggregate outputs are separately recorded.',
  'The 2021 report provides SSB, age-1 recruitment and fully selected F for 2012-2019; no numerical N-at-age or F-at-age surface was recovered.',
  'The official 2024 report provides aggregate catch, SSB, Fbar and recruitment; N-at-age and F-at-age arrays remain unavailable.',
  'The 2026 SAR provides aggregate SSB, F and recruitment; full N-at-age/F-at-age and numerical historical uncertainty are unavailable.'
)
review$decision_reason <- c(
  'NOAA 10164 refers to the Atlantic mackerel assessment represented by nefsc_atlantic_mackerel. The detailed 2018 source explicitly includes combined U.S.-Canadian catch-at-age; the newer 2025 update is retained separately as summary-only. See source_reviews/nefsc_atlantic_mackerel.md.',
  'NOAA 10508 matches the legacy combined Gulf of Maine cod record. The 2021 M02 assessment has age-specific inputs, but the 2023 research track replaced that unit with successor stock units; under the current-unit scope, this legacy record is not an eligible new case. See source_reviews/nefsc_gom_cod_2021.md.',
  'NOAA Stock SMART identifies 10509 / assessment 13596 as the 2024 operational Georges Bank cod series. Its revised 2023 boundary excludes areas 521 and 526 and matches nefsc_cod_georges_bank, not the historical wider catalogue unit. Age-specific arrays for the current run remain unavailable. See source_reviews/ck_nefsc_garmiii_morhua_gb.md.',
  'NOAA 10519 is Gulf of Maine haddock and matches the existing 5Y stock record. The current 2026 assessment has only partial numerical records; its age-specific input arrays and fitted N/F surfaces were not recovered. See source_reviews/nefsc_haddock_gulf_of_maine.md.'
)
review$notes <- paste0('Identity and source review: source_reviews/', review$source_review,
  '. Keep assessment units and years separate; do not transfer older-unit values to successor units.')

row_index <- match(review$candidate_id, x$candidate_id)
if (anyNA(row_index) || anyDuplicated(review$candidate_id)) stop('Candidate IDs are missing or duplicated.', call. = FALSE)
if (any(x$match_status[row_index] != 'unreviewed' | x$screening_status[row_index] != 'not_started')) {
  stop('A candidate was already reviewed; inspect the register before rerunning.', call. = FALSE)
}
if (any(!file.exists(file.path(root, 'source_reviews', review$source_review)))) stop('A required source review is missing.', call. = FALSE)
if (any(!dir.exists(file.path(root, 'source_cache', cached_sources)))) stop('A required source cache is missing.', call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
if (any(!review$matched_stock_id %in% stocks$stock_id)) stop('A matched canonical stock is missing.', call. = FALSE)
x$matched_stock_id[row_index] <- review$matched_stock_id
x$match_status[row_index] <- 'matched'
x$screening_status[row_index] <- 'screened'
x$eligibility[row_index] <- review$eligibility
x$import_status[row_index] <- 'imported'
x$review_date[row_index] <- as.character(Sys.Date())
for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence','maturity_evidence',
                'mortality_evidence','timing_evidence','output_evidence','detailed_source_url',
                'decision_reason','notes')) x[[field]][row_index] <- review[[field]]

eligible <- row_index[review$eligibility == 'eligible']
for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence','maturity_evidence',
                'mortality_evidence','timing_evidence','output_evidence','detailed_source_url')) {
  if (any(is.na(x[[field]][eligible]) | !nzchar(x[[field]][eligible]))) stop('Eligible rows need complete evidence.', call. = FALSE)
}
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (i in row_index) {
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Reconciled and screened', length(row_index), 'NOAA Northeast science-centre entries.\n')
