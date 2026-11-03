root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_red_grouper_sa_2017')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10332'
unit_id <- 'noaa_red_grouper_south_atlantic'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_hashes <- c(
  NOAA_Red_Grouper_Status.html = '1cd7255619d67ccce41d908acdfe982abe1e0055edd082c472ddfe2b95efd66b',
  SEDAR_53_Project.html = '7e7ae9808da22363e9d17876c148355f72683d1aceb24875ce72c0ef8997ce49',
  SEDAR_53_Red_Grouper_SAR_2017.pdf = 'ec3f0b6d97fbcfa4d38d5f9f6fa26417b380970a9c5c066248d15d084fe36c12',
  SEDAR_53_WP05_commercial_age_length_2016.pdf = 'e90353bf02d8a28bb3fe9f84b417622b1fff8bb9220b652a7ac18a22b20d6f19',
  SEDAR_53_WP08_recreational_age_length_2016.pdf = '0a9d35041e8745b4766bbf15d197f689c13e57918cbb1b78f668081637dee162',
  SEDAR_86_Project_Status.html = '66a3677ac7d2eae9e49665d648fd8ece19d79a0d56857bb3b5ac1697c1092c3b')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The South Atlantic red-grouper source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached red-grouper source differs from its manifest: ', file, call. = FALSE)
}

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' ')
noaa_status <- read_source('NOAA_Red_Grouper_Status.html')
sedar53 <- read_source('SEDAR_53_Project.html')
sedar86 <- read_source('SEDAR_86_Project_Status.html')
report <- file.path(cache, 'SEDAR_53_Red_Grouper_SAR_2017.pdf')
if (!grepl('South Atlantic stock is overfished (2017 stock assessment)', noaa_status,
    fixed = TRUE) || !grepl('not subject to overfishing based on 2024', noaa_status,
    fixed = TRUE) || !grepl('assessment took place over a series of webinars', sedar53,
    fixed = TRUE) || !grepl('will not be completed', sedar86, fixed = TRUE) ||
    !identical(rawToChar(readBin(report, 'raw', n = 4L)), '%PDF'))
  stop('The cached official sources do not support the reviewed run identity.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row <- match(candidate_id, candidates$candidate_id)
gulf <- match('NOAA:10331', candidates$candidate_id)
area <- paste('U.S. South Atlantic red grouper management unit under the South Atlantic Fishery',
  'Management Council; North Carolina through the Atlantic side of the Florida Keys.')
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    is.na(gulf) || candidates$scientific_name[row] != 'Epinephelus morio' ||
    candidates$stock_name[row] != 'Red grouper - Southern Atlantic Coast' ||
    !candidates$assessment_area[row] %in% c('Southern Atlantic Coast', area) ||
    candidates$candidate_unit_id[gulf] != 'noaa_red_grouper_gom' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == '10332', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) || any(assessments$stock_id == unit_id) ||
    any(inputs$assessment_id == unit_id) || any(outputs$assessment_id == unit_id))
  stop('South Atlantic red-grouper identity conflicts with the register or database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  assessment_area = area,
  catch_age_evidence = paste('The latest completed assessment used for South Atlantic stock status is SEDAR 53 (2017; data through 2015),',
    'a statistical catch-age BAM. It fits annual fleet landings/discards and age compositions for commercial lines, headboat,',
    'general recreational, and SERFS. SEDAR53-WP05 Table 3 publishes weighted commercial handline/longline age proportions',
    'for 1996-2015, ages 1-16 with 16+ pooled. Catch-at-age is not a complete direct input series; age-specific removals can be',
    'reconstructed only for fleet-years with matching catch totals and compositions. Preserve unsampled fleet-years as missing.'),
  survey_age_evidence = paste('The assessment fits an aggregate annual SERFS chevron-trap/video abundance index and SERFS age compositions.',
    'These support age-specific index reconstruction only over years with matching survey age compositions. Commercial handline',
    'and headboat abundance indices are aggregate, not age-indexed.'),
  weights_evidence = paste('Growth and weight-at-age are inputs summarized in SEDAR 53 Table 1. Total length follows a von Bertalanffy',
    'curve and whole weight is calculated as 8.418e-9 * TL^3.1; model ages are 1-16+.'),
  maturity_evidence = paste('Female maturity is a fixed logistic ogive from SEDAR 19 inputs (50% maturity at age 2.8; age-1 females',
    'immature); all males are considered mature. Sex ratio is a fixed logistic ogive. SSB is total mature biomass of both sexes at peak spawning.'),
  mortality_evidence = paste('Natural mortality is fixed over time and age-varying by the Lorenzen relationship, rescaled so cumulative',
    'survival through age 26 matches constant M=0.14. It is an assumed input, not an estimated M process.'),
  timing_evidence = paste('The model fits annual aggregate indices and seasonal fishery/survey source data. The report does not specify',
    'a single within-year fraction for all indices; source-specific seasonal timing must be retained or explicitly approximated during translation.'),
  output_evidence = paste('SEDAR 53 Table 6 reports start-of-year abundance at ages 1-16+ (1000 fish), including 1976-2015 and a',
    '2016 forecast. Table 8 reports annual apical F (yr^-1), total biomass and peak-spawning SSB (mt) through 2015. The assessment',
    'also reports recruitment and uncertainty analyses; age-specific uncertainty is not tabulated in the reviewed source.'),
  detailed_source_url = paste('https://www.fisheries.noaa.gov/species/red-grouper;',
    'https://sedarweb.org/assessments/sedar-53/;',
    'https://sedarweb.org/documents/sedar-53-stock-assessment-report-south-atlantic-red-grouper/;',
    'https://sedarweb.org/assessments/sedar-86/;',
    'https://sedarweb.org/documents/s53wp05-commercial-age-and-length-composition-weighting-for-u-s-red-grouper-epinephelus-morio/;',
    'https://sedarweb.org/documents/s53wp08-south-atlantic-u-s-red-grouper-epinephelus-morio-age-and-length-composition-from-the-recreational-fisheries/'),
  review_date = '2026-10-31',
  decision_reason = paste('NOAA’s current stock page identifies the 2017 assessment as the South Atlantic stock assessment used for status; the planned SEDAR 86 operational update was not completed.',
    'SEDAR 53 provides a catch-age model, observed age compositions, biological/mortality assumptions, and comparable age-specific abundance and aggregate SSB/F outputs.',
    'Source quantities support age-specific reconstruction for overlapping fleet-years, with explicit gaps for fleets or years without age compositions. Timing and age-specific uncertainty remain translation/extraction limitations.'),
  notes = paste('NOAA Stock SMART 10332 is the South Atlantic management unit and is distinct from Gulf of Mexico red grouper (10331).',
    'The latest completed detailed assessment is SEDAR 53 (2017; terminal data year 2015); SEDAR 86 was not completed.',
    'The SEDAR 53 final report and commercial/recreational age-composition papers are cached with provenance and SHA-256 checksums under',
    'source_cache/discovery_noaa_red_grouper_sa_2017. This is a discovery eligibility screen only: no canonical assessment, input or output data were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
already_reviewed <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!pristine && !already_reviewed)
  stop('NOAA South Atlantic red-grouper candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && !already_reviewed) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA South Atlantic red grouper (Stock SMART 10332) as eligible for source curation.\n')
