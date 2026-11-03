root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_red_grouper_gom_2025')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10331'
i <- which(candidates$candidate_id == id)
if (length(i) != 1L) stop('Expected one NOAA inventory row: ', id, call. = FALSE)
if (any(stocks$authority_stock_id == '10331', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-i] == 'noaa_red_grouper_gom', na.rm = TRUE)) {
  stop('Another canonical or candidate row already uses the Gulf red grouper unit.',
    call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_red_grouper_gom',
  official_stock_id = '10331',
  scientific_name = 'Epinephelus morio',
  stock_name = 'Red grouper - Gulf of Mexico',
  assessment_area = 'Gulf of Mexico',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 88 uses commercial and recreational landings, discards, and weighted',
    'landings age compositions. Commercial handline ages cover 1991-2022, longline',
    '1993-2022, trap 1991-2006 (pooled as a super-period), and recreational 1991-2022.',
    'Composition bins are annual ages with 20+ as the plus group; the composition',
    'figures and working papers require digitization for annual proportions.'
  ),
  survey_age_evidence = paste(
    'The assessment fits aggregate abundance indices and length compositions for the',
    'Combined Video Survey (1993-2022), SEAMAP Summer Groundfish Survey (2009-2022),',
    'and NMFS Bottom Longline Survey (2001-2022). It does not list age compositions or',
    'age-specific indices for these surveys. Do not derive survey-age observations from',
    'fitted selectivity or population states.'
  ),
  weights_evidence = paste(
    'The model uses a fixed weight-length relationship and an estimated age-growth',
    'curve; it does not report an independently observed annual stock-weight-at-age',
    'input series. A weight-at-age surface would be derived from model biology, not a',
    'direct source observation.'
  ),
  maturity_evidence = paste(
    'Maturity and female-to-male transition schedules are carried forward from the',
    'SEDAR 42 benchmark; the model fixes fecundity-at-age as relative egg production.',
    'This differs from a conventional mature-biomass SSB definition.'
  ),
  mortality_evidence = paste(
    'M is a time-invariant, age-dependent Lorenzen schedule. The point estimate is',
    'Mtarget = 5.4/29 = 0.186 using maximum age 29, with length-at-age determining',
    'the age pattern. Sensitivities use maximum ages 24 and 34.'
  ),
  timing_evidence = paste(
    'Seasonal timing is documented. The NMFS BLL uses August samples in the eastern',
    'GOM and September in the central and western GOM, with early October 2022 stations',
    'retained; the fitted SEAMAP index uses summer data. The video index pools surveys',
    'with differing sampling months. These windows do not define one fractional timing',
    'for each pooled model index.'
  ),
  output_evidence = paste(
    'Table 15 reports annual recruitment, total and exploitable biomass, exploitable',
    'abundance and SSB from 1986-2022. SSB is relative egg production, not biomass.',
    'Tables 13-14 report exploitation rates. Age-specific N and F are shown in figures,',
    'but numerical full surfaces and annual output uncertainty were not located.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-88-gulf-of-mexico-red-grouper/;',
    'https://sedarweb.org/documents/sedar-88-gulf-of-mexico-red-grouper-final-stock-assessment-report-updated-december-2025/;',
    'https://sedarweb.org/documents/sedar-88-wp-03-commercial-landings-of-gulf-of-mexico-red-grouper-epinephelus-morio-from-1986-2022/;',
    'https://sedarweb.org/documents/sedar-88-wp-06-gulf-of-mexico-red-grouper-epinephelus-morio-length-and-age-compositions-from-the-recreational-fishery/;',
    'https://sedarweb.org/documents/sedar-88-wp-09-gulf-of-mexico-red-grouper-epinephelus-morio-commercial-landings-length-and-age-compositions/;',
    'https://sedarweb.org/documents/sedar-88-wp-10-standardized-catch-per-unit-effort-for-gulf-of-mexico-red-grouper-from-the-southeast-region-headboat-survey/;',
    'https://sedarweb.org/documents/sedar-88-wp-11-a-review-of-the-gulf-of-mexico-red-grouper-epinephelus-morio-age-length-data-1978-2022/;',
    'https://sedarweb.org/documents/sedar-88-wp-12-an-index-of-relative-abundance-for-red-grouper-captured-during-the-nmfs-bottom-longline-survey-in-the-northern-gulf-of-mexico/;',
    'https://sedarweb.org/documents/sedar-88-wp-13-red-grouper-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/;',
    'https://sedarweb.org/documents/sedar-88-wp-16-combined-indices-of-abundance-for-red-grouper-epinephelus-morio-in-the-eastern-gulf-of-mexico-using-data-from-three-historic-video-surveys-and-unified-g-fisher-program/'
  ),
  review_date = '2026-10-30',
  decision_reason = paste(
    'SEDAR 88 is the latest full, accepted production assessment (completed in 2025,',
    'data through 2022). It provides age-composition inputs, aggregate abundance',
    'indices, biology and annual population outputs. The 2026 StockSMART monitoring',
    'row is marked Remand and is not a replacement production run. tinyAM eligibility',
    'remains unresolved because no fitted survey-age observations or single fractional',
    'timing for the pooled indices were found, and SSB is reported as egg production',
    'rather than biomass.'
  ),
  notes = paste(
    'The December 10, 2025 report revision corrects Tables 5, 7, 8 and 19; use this',
    'revision rather than the February 2025 release. StockSMART assessment 13943',
    'records full acceptance for SEDAR 88; assessment 14350 is a 2026 stock monitoring',
    'update with review result Remand and the same terminal data year. NOAA Stock',
    'SMART 10332 is the distinct South Atlantic red grouper unit. See',
    'discovery/source_reviews/noaa_red_grouper_gom_2025.md.'
  )
)

already_applied <- all(vapply(names(review), function(column) {
  identical(as.character(candidates[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (!already_applied) {
  if (!candidates$screening_status[i] %in% c('not_started', 'screened') ||
      !candidates$match_status[i] %in% c('unreviewed', 'new')) {
    stop('Inventory row has a conflicting prior review: ', id, call. = FALSE)
  }
  for (column in names(review)) candidates[[column]][i] <- review[[column]]
  lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(candidates) + 1L) {
    stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
  }
  row <- candidates[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  writeLines(lines, candidate_path, useBytes = TRUE)
}

files <- c(
  'sedar_88_red_grouper_final_updated_2025.pdf',
  'sedar_88_wp03_commercial_landings.pdf',
  'sedar_88_wp06_recreational_compositions.pdf',
  'sedar_88_wp09_commercial_compositions.pdf',
  'sedar_88_wp10_headboat_cpue.pdf',
  'sedar_88_wp11_age_length_data.pdf',
  'sedar_88_wp12_bottom_longline_index.pdf',
  'sedar_88_wp13_seamap_indices.pdf',
  'sedar_88_wp16_combined_video_index.pdf'
)
paths <- file.path(cache, files)
if (!all(file.exists(paths)) || any(file.info(paths)$size == 0)) {
  stop('Expected cached source files are missing or empty.', call. = FALSE)
}
pdf_ok <- vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_ok)) stop('A cached source does not have a PDF signature.', call. = FALSE)
sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE)) {
    return(digest::digest(file = path, algo = 'sha256'))
  }
  output <- system2('certutil', c('-hashfile',
    normalizePath(path, winslash = '/', mustWork = TRUE), 'SHA256'), stdout = TRUE)
  hash <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output), value = TRUE)
  if (length(hash) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hash)
}
urls <- c(
  'https://sedarweb.org/documents/sedar-88-gulf-of-mexico-red-grouper-final-stock-assessment-report-updated-december-2025/',
  'https://sedarweb.org/documents/sedar-88-wp-03-commercial-landings-of-gulf-of-mexico-red-grouper-epinephelus-morio-from-1986-2022/',
  'https://sedarweb.org/documents/sedar-88-wp-06-gulf-of-mexico-red-grouper-epinephelus-morio-length-and-age-compositions-from-the-recreational-fishery/',
  'https://sedarweb.org/documents/sedar-88-wp-09-gulf-of-mexico-red-grouper-epinephelus-morio-commercial-landings-length-and-age-compositions/',
  'https://sedarweb.org/documents/sedar-88-wp-10-standardized-catch-per-unit-effort-for-gulf-of-mexico-red-grouper-from-the-southeast-region-headboat-survey/',
  'https://sedarweb.org/documents/sedar-88-wp-11-a-review-of-the-gulf-of-mexico-red-grouper-epinephelus-morio-age-length-data-1978-2022/',
  'https://sedarweb.org/documents/sedar-88-wp-12-an-index-of-relative-abundance-for-red-grouper-captured-during-the-nmfs-bottom-longline-survey-in-the-northern-gulf-of-mexico/',
  'https://sedarweb.org/documents/sedar-88-wp-13-red-grouper-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/',
  'https://sedarweb.org/documents/sedar-88-wp-16-combined-indices-of-abundance-for-red-grouper-epinephelus-morio-in-the-eastern-gulf-of-mexico-using-data-from-three-historic-video-surveys-and-unified-g-fisher-program/'
)
revisions <- c(
  'SEDAR 88 operational assessment; December 10, 2025 corrected revision; terminal data year 2022',
  'SEDAR 88 WP-03; commercial landings 1986-2022',
  'SEDAR 88 WP-06; recreational length and age compositions',
  'SEDAR 88 WP-09; commercial landings length and age compositions',
  'SEDAR 88 WP-10; Southeast Region Headboat Survey index',
  'SEDAR 88 WP-11; age-length data 1978-2022 and ageing error',
  'SEDAR 88 WP-12; NMFS Bottom Longline index',
  'SEDAR 88 WP-13; SEAMAP Groundfish abundance indices',
  'SEDAR 88 WP-16; combined video index and G-FISHER'
)
manifest <- data.frame(
  url = urls,
  retrieved_on = '2026-10-29',
  revision = revisions,
  bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)),
  status = 'cached',
  notes = c(
    'Use corrected December 2025 release; report history identifies errors in Tables 5, 7, 8 and 19.',
    'Commercial landings and fleet-level source data.',
    'Recreational length and age composition data; age series are plotted.',
    'Commercial length and age composition data; weighted age series are plotted.',
    'Fishery-dependent aggregate abundance index.',
    'Age observations and ageing-error analysis; not a fitted model object.',
    'Fishery-independent aggregate abundance index.',
    'Fishery-independent aggregate abundance indices.',
    'Fishery-independent aggregate combined video index.'
  ),
  file = files,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(cache, 'sources.csv'), row.names = FALSE, na = '')
cat('Screened NOAA Gulf of Mexico red grouper against SEDAR 88 and its supporting data papers.\n')
