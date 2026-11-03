root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_south_atlantic_vermilion_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'sedar55_stock_assessment_report_2018.pdf',
    'sedar55_wp02_serfs_chevron_trap_index_2017.pdf',
    'sedar55_wp03_reproductive_life_history_2017_addendum.pdf',
    'sedar55_wp06_commercial_age_length_2017_addendum.pdf',
    'sedar55_wp07_serfs_trap_video_index_2017.pdf',
    'sedar55_wp09_recreational_age_length_2017.pdf',
    'safmc_ssc_october_2023_final_report.pdf',
    'safmc_vermilion_snapper_tor_draft_2026.pdf',
    'safmc_vermilion_snapper_tor_draft_august_2026.pdf',
    'safmc_september_2026_assessment_schedule.pdf'
  ),
  url = c(
    'https://sedarweb.org/documents/sedar-55-stock-assessment-report-south-atlantic-vermilion-snapper/',
    'https://sedarweb.org/documents/s55wp02-vemilion-snapper-fishery-independent-index-of-abundance-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2016/',
    'https://sedarweb.org/documents/s55wp03-update-of-vermilion-snapper-rhomboplites-aurobens-reproductive-life-history-from-the-marmap-serfs-program/',
    'https://sedarweb.org/documents/s55wp06-commercial-age-and-length-compositions-for-u-s-vermilion-snapper-rhomboplites-aurorubens/',
    'https://sedarweb.org/documents/s55wp07-integrated-data-from-chevron-traps-and-video-cameras-into-a-standardized-index-of-abundance-for-vermilion-snapper-rhomboplites-aurorubens/',
    'https://sedarweb.org/documents/s55wp09-south-atlantic-u-s-vermilion-snapper-rhomboplites-aurorubens-age-and-length-composition-from-the-recreational-fisheries/',
    'https://safmc.net/documents/fc1_a1e_ssc_oct2023_final_report-pdf/',
    'https://safmc.net/documents/10b_south_atlantic_vermilion_snapper_tors_apr2026_draft-pdf/',
    'https://safmc.net/documents/secad_a4c_south_atlantic_vermilion_snapper_tors_aug2026_draft_v3-pdf/',
    'https://safmc.net/documents/secad_a2_sedar_assessment_scheduling_grid-pdf/'
  ),
  revision = c(
    'Final SEDAR 55 assessment report, April 2018',
    'SEDAR55-WP02, 2017; SERFS chevron trap abundance index',
    'SEDAR55-WP03, 2017; final batch fecundity addendum January 16 2018',
    'SEDAR55-WP06, submitted November 2017; final composition addendum January 19 2018',
    'SEDAR55-WP07, 2017; combined trap/video abundance index sensitivity',
    'SEDAR55-WP09, December 2017; recreational age and length compositions',
    'SAFMC SSC final report, October 2023',
    'Draft terms of reference dated March 31 2026',
    'Draft terms of reference, August 2026 version 3',
    'SAFMC September 2026 meeting; July 2026 SEDAR scheduling grid'
  ),
  retrieved_utc = '2026-10-31',
  bytes = c(2388168, 2006475, 1955753, 1692399, 676788, 1436395,
    862838, 241407, 243275, 978767),
  sha256 = c(
    '41ac31776d56638c3d39b05737c36a3bffa0a749bf2b8040b821471105a13237',
    '80807720abc0eb0255ab6e587bb2c17c87d53235e84733106910969519b2ae9a',
    '234f779c813d24e38c36b5a31a8ebd60f47a92e88293d465bbd629c8a59b3393',
    'b01ac7b150ad01f4f4e7a3ede87145dd35a2c6f8f370ee6632366807bdbb4d4e',
    '74a0a59804a5b194d0fa13a1139b655f5d0fc4b91c135413f2b5d9148dfc5a7f',
    '21a679478c5da4628489b6bfcc85fd71d7e026c9e093535781db12d887ec8926',
    'af15bb7d330bfd3f64bde602563367d4e71f344926265023c1f1853f507e82f5',
    '5470c534fff3d1d102e1430b14cdad042517dee1f05e1c2e827bafe8dd7cba95',
    '340e216c50d6e913a3c1f1987beeafb4087c8b4807c5862509f9bdaa2cd53731',
    'f970639e080c47208e9840c26e94246e0d7c275a437d29e8c89c334c46587933'
  ),
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe',
      c('-hashfile', shQuote(path), 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
      output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

paths <- file.path(cache, sources$file)
if (any(!file.exists(paths)) || any(file.info(paths)$size != sources$bytes) ||
    !identical(unname(vapply(paths, sha256_file, character(1L))), sources$sha256))
  stop('Cached South Atlantic vermilion snapper sources differ from the reviewed manifest.',
    call. = FALSE)
pdf_headers <- vapply(paths, function(path)
  identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'), logical(1L))
if (!all(pdf_headers))
  stop('A cached South Atlantic vermilion snapper source is not a PDF.', call. = FALSE)

manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  old_manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(old_manifest$file, sources$file) ||
      !identical(old_manifest$url, sources$url) ||
      !identical(old_manifest$revision, sources$revision) ||
      !identical(old_manifest$retrieved_utc, sources$retrieved_utc) ||
      !identical(as.numeric(old_manifest$bytes), as.numeric(sources$bytes)) ||
      !identical(tolower(old_manifest$sha256), sources$sha256))
    stop('Cached South Atlantic vermilion snapper manifest conflicts with this screen.',
      call. = FALSE)
} else {
  write.csv(sources, manifest_path, row.names = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10257 & stocksmart$assessment_id == 8220,
  , drop = FALSE]
stock_history <- stocksmart[stocksmart$stock_id == 10257, , drop = FALSE]
if (nrow(run) != 1L || nrow(stock_history) != 4L ||
    max(as.integer(stock_history$assessment_year), na.rm = TRUE) != 2018L ||
    run$assessment_year != 2018L || run$last_data_year != 2016L ||
    run$assessment_model != 'Beaufort Statistical Catch-at-Age Model' ||
    run$review_result != 'Full acceptance' || run$assessment_type != 'Full Update' ||
    run$stock_name != 'Vermilion snapper - Southern Atlantic Coast')
  stop('NOAA Stock SMART metadata differs from the screened South Atlantic run.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'NOAA:10257'
unit_id <- 'noaa_vermilion_snapper_south_atlantic'
row <- match(candidate_id, candidates$candidate_id)
gulf_row <- match('NOAA:10256', candidates$candidate_id)
if (is.na(row) || is.na(gulf_row) ||
    sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '10257' ||
    candidates$scientific_name[row] != 'Rhomboplites aurorubens' ||
    candidates$assessment_area[row] != 'Southern Atlantic Coast' ||
    candidates$scientific_name[gulf_row] != candidates$scientific_name[row] ||
    candidates$assessment_area[gulf_row] != 'Gulf of Mexico' ||
    candidates$candidate_unit_id[gulf_row] == unit_id ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10257', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('NOAA South Atlantic vermilion snapper identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest accepted full assessment located is SEDAR 55 (2018), a Beaufort',
    'statistical catch-at-age update through 2016. It fits annual landings from five',
    'fleets and age compositions for commercial handline, headboat, general recreational,',
    'and SERFS chevron trap samples. Landings are in 1,000 lb whole weight for commercial',
    'fleets and 1,000 fish for recreational fleets. Composition ages are calendar ages 1-12+',
    'with age 12 as the plus group; sample years vary and years below the assessment sample',
    'threshold were excluded. Total landings and documented weighted age compositions support',
    'a source-based catch-at-age reconstruction, but the compositions are not themselves',
    'observed catch numbers-at-age.'),
  survey_age_evidence = paste(
    'The assessment includes age compositions from the fishery-independent SERFS chevron-trap',
    'survey for 1990-2016, at ages 1-12+. It fits aggregate abundance indices, including the',
    'combined SERFS trap/video series and the MARMAP Florida snapper-trap series (1983-1987);',
    'the MARMAP index had no age compositions. The model therefore has age composition plus',
    'aggregate index information, not an age-specific abundance index.'),
  weights_evidence = paste(
    'Growth parameters were estimated externally and treated as fixed inputs: von Bertalanffy',
    'L-infinity = 506 mm, K = 0.12/year, and t0 = -3.5 years. Whole weight at age is derived',
    'from total length in mm using WW = 2.1e-5 * TL^2.91; the report tabulates life-history',
    'characteristics at age.'),
  maturity_evidence = paste(
    'Female maturity is age-specific: 91% at age 1 and 99-100% at ages 2-12+. The assessment',
    'models spawning stock as egg production, including female proportion, batch fecundity,',
    'and age-specific spawning frequency; it is not conventional SSB biomass.'),
  mortality_evidence = paste(
    'Natural mortality is fixed and decreases with age following the Lorenzen relationship.',
    'The age-specific vector is scaled to match cumulative survival through age 19 under',
    'constant M = 0.22/year; an alternative Charnov form is a sensitivity only.'),
  timing_evidence = paste(
    'The model is annual and computes spawning stock at the midpoint of the year. Index',
    'predictions use population numbers at midyear (or weight at age for commercial handline).',
    'Specific survey-month timing was not established by the reviewed assessment sources.'),
  output_evidence = paste(
    'The report gives numerical base-run total abundance-at-age (Table 6; 1,000 fish; ages',
    '1-12+), biomass-at-age (Table 7; 1,000 lb whole weight), and F-at-age (Table 11; per year)',
    'over the historical assessment, alongside annual recruitment, total biomass, egg-production',
    'spawning stock, and status indicators. The MCB analysis reports uncertainty for selected',
    'aggregate/status outputs; age-specific uncertainty was not located in the tables.'),
  detailed_source_url = paste(sources$url, collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'Eligible for detailed source curation as a distinct South Atlantic management unit.',
    'SEDAR 55 is the latest accepted full assessment found (assessment year 2018; data through',
    '2016). The 2023 interim analysis was not accepted for catch advice because its index-based',
    'approach did not fit the index or inform the assessment population estimates. An updated',
    'assessment is planned outside SEDAR in 2027 and has not yet produced a completed run.'),
  notes = paste(
    'NOAA:10257 is the South Atlantic unit and must remain separate from NOAA:10256, the Gulf',
    'of Mexico unit of the same species. The 2026 draft terms of reference and September 2026',
    'assessment schedule identify a future update; they do not replace SEDAR 55 outputs. The',
    'age-composition and landings inputs are suitable for a documented catch-at-age reconstruction,',
    'with official fleet units and weighting preserved. Spawning stock is in eggs. No canonical',
    'data were imported and no tinyAM translation was attempted. The review files are cached in',
    'the gitignored source_cache directory with retrieval dates and SHA-256 checksums.')
)

current <- lapply(names(review), function(column)
  as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) ||
    !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('NOAA South Atlantic vermilion snapper candidate already has a conflicting review state.',
    call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:10257 South Atlantic vermilion snapper as eligible for source curation.\n')
