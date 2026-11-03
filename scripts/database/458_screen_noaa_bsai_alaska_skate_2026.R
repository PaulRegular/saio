root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_bsai_alaska_skate_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10736'
unit_id <- 'noaa_bsai_alaska_skate'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path,
    call. = FALSE)
  tolower(hashes)
}

source_files <- c('NOAA_2023/BSAIskate_2023_SAFE.pdf',
  'NOAA_2023/F_2026_Groundfish_Stock_Assessment_SSC_Review.pdf',
  'NOAA_2023/data_aksk14_2_2023.ss',
  'NOAA_2023/M14_2NAA_summary.csv',
  'NOAA_2023/M14_2biomass_summary.csv',
  'NOAA_2023/M14_2exploitation_summary.csv',
  'NOAA_2023/M14_2recruit_summary.csv',
  'NOAA_2023/M14_2lengthcomps_summary.csv',
  'NOAA_2024/BSAIintro_2024_SAFE.pdf')
expected_sha256 <- c('01eeb03c2b6a197d876f046f5010fae0e90179bc9dd8bbb574582e93546e24ad',
  'ec766eb0a54a55ebe867a496ad6108611153affd0ad1fc5ae8dd6287c0a14ffa',
  '67e65debeb29465448d686a51888cb3f48c224cf649bfdd0799ee6129887eb94',
  'd083ec793ee9ae36fb6f9360974d2ccbdc3b1d3c13d235de75cac55b015e44dd',
  '23bd8d8f72418f01c074b9fb138f071de9efb1c78876bf672a891c2e2bc405e6',
  'de8ed5911c541fee1ec9c60fe79cac266c63d51a47ef5ee5d7cf5c65c3b6c541',
  '5044fd11289fb78286bb8b8d988ce40893c1400bec64b3bb1ce3580e9675b2e7',
  '579b0e9c476bb18deddfbce28d0aa989632a92d3731a1d2ec3514b5f0679af76',
  'b62ad5dc0701d7974008c7373a39374866896ce0ffc46963c0b37e8aee120448')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
source_rows <- match(source_files, sources$file)
source_paths <- file.path(cache, source_files)
if (anyNA(source_rows) || any(!file.exists(source_paths)) ||
    !identical(unname(tolower(as.character(sources$sha256[source_rows]))), expected_sha256) ||
    any(as.numeric(sources$bytes[source_rows]) != file.info(source_paths)$size) ||
    !identical(unname(tolower(vapply(source_paths, sha256_file, character(1L)))), expected_sha256))
  stop('Cached NOAA Alaska skate sources differ from the reviewed manifest.', call. = FALSE)

data_path <- file.path(cache, 'NOAA_2023', 'data_aksk14_2_2023.ss')
data_lines <- readLines(data_path, warn = FALSE)
agecomp_header <- grep('^#_yr month fleet sex part ageerr Lbin_lo Lbin_hi Nsamp datavector',
  trimws(data_lines))
meansize_header <- grep('^#_yr month fleet sex part ageerr ignore datavector',
  trimws(data_lines))
if (length(agecomp_header) != 1L || length(meansize_header) != 1L ||
    !any(grepl('^2023[[:space:]]+#_EndYr$', trimws(data_lines))) ||
    !any(grepl('^1[[:space:]]+#_Ngenders:', trimws(data_lines))) ||
    !any(grepl('^1[[:space:]]+#_Nareas$', trimws(data_lines))) ||
    !any(grepl('^1[[:space:]]+#_Use_MeanSize-at-Age_obs', trimws(data_lines))))
  stop('The cached Stock Synthesis data file differs from the reviewed run.', call. = FALSE)

section_rows <- function(lines, header) {
  following <- trimws(lines[seq.int(header + 1L, length(lines))])
  following <- following[nzchar(following) & !startsWith(following, '#')]
  end <- which(grepl('^-9999([[:space:]]|$)', following))[1L]
  if (is.na(end)) stop('A Stock Synthesis data section lacks its terminator.', call. = FALSE)
  following[seq_len(end)]
}
agecomp_rows <- section_rows(data_lines, agecomp_header)
meansize_rows <- section_rows(data_lines, meansize_header)
meansize_years <- as.integer(sub('^([0-9]{4}).*$', '\\1', meansize_rows[-length(meansize_rows)]))
if (length(agecomp_rows) != 1L || !grepl('^-9999([[:space:]]|$)', agecomp_rows) ||
    !identical(meansize_years, c(2003L, 2007L, 2008L, 2009L, 2015L)))
  stop('The cached run does not have the reviewed age-observation structure.', call. = FALSE)

naa <- read.csv(file.path(cache, 'NOAA_2023', 'M14_2NAA_summary.csv'),
  check.names = FALSE)
expected_ages <- as.character(0:25)
if (!identical(names(naa), c('Yr', expected_ages)) ||
    !identical(as.integer(naa$Yr), 1948:2028) || anyNA(naa))
  stop('The cached 2023 N-at-age output differs from its reviewed coverage.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '10736' ||
    candidates$scientific_name[row] != 'Bathyraja parmifera' ||
    !grepl('Bering Sea / Aleutian Islands', candidates$assessment_area[row], fixed = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '10736', na.rm = TRUE) ||
    any(tolower(stocks$scientific_name) == 'bathyraja parmifera', na.rm = TRUE))
  stop('NOAA Alaska skate identity conflicts with the candidate register or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2023 operational Model 14.2d uses aggregate reconstructed catch by longline and trawl,',
    'including gear-specific catch-accounting estimates. Its Stock Synthesis file has no fishery age-composition',
    'records; catch units are biomass, not numbers-at-age.'),
  survey_age_evidence = paste('The assessment fits an EBS shelf survey biomass index and survey length compositions.',
    'Paired survey length-at-age observations occur only in 2003, 2007-2009, and 2015 and inform the growth curve;',
    'they are not age compositions or an age-specific abundance index. The report states there are no fishery ages',
    'and no new survey age data since the prior full assessment.'),
  weights_evidence = paste('The model uses a combined-sex length-weight relationship (weight in kg, total length in cm):',
    'W = 9.0e-6 * TL^2.9617. No observed weight-at-age input is reported; an age surface would require derivation',
    'from this relationship and fitted growth.'),
  maturity_evidence = paste('Maturity is modeled as a length-based ogive (L50 = 93.28 cm total length; slope = -0.548).',
    'No observed maturity-at-age input is reported; an age surface would require derivation using fitted growth.'),
  mortality_evidence = 'Natural mortality is fixed at M = 0.13 per year for Alaska skate; the Other Skates Tier 5 unit is separate and uses M = 0.10.',
  timing_evidence = paste('The one-season Stock Synthesis input uses survey observations in month 7 and spawning month 1.',
    'This is a calendar-month specification; no separate fractional-year survey timing input was reported.'),
  output_evidence = paste('The 2023 Model 14.2d output archive reports N-at-age for ages 0-25 and years 1948-2028',
    '(unit not stated in the CSV), biomass in metric tonnes, age-0 recruitment in thousands of fish with CV, and',
    'aggregate exploitation (catch / total biomass). The report also provides age-structured population output,',
    'but these fitted quantities do not replace missing age-disaggregated observations. No comparable F-at-age or',
    'M-at-age summary table was located.'),
  detailed_source_url = paste(c('https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAIskate.pdf',
    'https://github.com/afsc-assessments/AFSC_BSAI_SKATE_Assessment/tree/main/2023/Tier3',
    'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIintro.pdf',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=2025_BSAIskates_SeptPT.pdf&p=018bc1f8-77d9-4e80-b825-2213af5f0d08.pdf',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=2025_BSAIskate_SEPTPT.pdf&p=07108b82-7dd2-412f-86ba-9a0cf5ba68d3.pdf',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Stock+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf'),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The latest completed operational assessment located is the 2023 Model 14.2d, used for 2024 harvest',
    'specifications. It has aggregate catch and survey-biomass observations with length compositions, but no fishery',
    'age compositions or age-specific abundance observations. The sparse survey length-at-age samples inform growth',
    'only. Therefore it is ineligible for the age-disaggregated source set despite age-structured fitted outputs.'),
  notes = paste('This candidate is the Tier 3 BSAI Alaska skate component; the BSAI Other Skates Tier 5 complex is a',
    'separate assessment unit. The NOAA Stock SMART Gulf of Alaska Skate Complex (NOAA:11005) is also separate and',
    'was not matched to this unit. The 2024 SAFE is a harvest projection, while the 2025 alternatives were proposals',
    'rather than an accepted production assessment. NPFMC scheduled the 2026 BSAI skates final assessment for December',
    '2026, after this review date. The cached 2023 SS3 data file is under the Model 14.2d update path and has _EndYr=2023,',
    'but its header comment still says data through 2020; run identity is supported by the official report and output',
    'files, and this stale comment is retained as a provenance caveat. No canonical records were added and no tinyAM',
    'translation was attempted.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('NOAA Alaska skate candidate already has a conflicting review state.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:10736 BSAI Alaska skate; ineligible for the age-disaggregated source set.\n')
