root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_alaska_sablefish_2024_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
revision <- 'd080576086110b6dcfca2c37918bab3101fff44a'
source_files <- c(
  'alaska_sablefish_2024_final_safe.pdf',
  'alaska_sablefish_2024_input.dat',
  'alaska_sablefish_2024_control.ctl',
  'alaska_sablefish_2024_model.tpl',
  'alaska_sablefish_2024_output.rep',
  'alaska_sablefish_2024_output.rdat',
  'alaska_sablefish_table_3_3_data.xlsx',
  'alaska_sablefish_table_3_4_age_length_sample_sizes.xlsx',
  'alaska_sablefish_table_3_5_abundance_indices.xlsx',
  'alaska_sablefish_table_3c_1_biological_inputs.xlsx',
  'alaska_sablefish_table_3c_3_female_numbers_at_age.xlsx',
  'alaska_sablefish_table_3c_4_male_numbers_at_age.xlsx',
  'alaska_sablefish_table_3_8_recruitment_ssb_biomass.xlsx',
  'alaska_sablefish_2025_safe_catch_report.pdf')
source_urls <- c(
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/SAFE/Sablefish_SAFE_2024_final.pdf'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Data/tem_2024_na_wh.dat'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Model/Base%20%2823.5%29_final%20model/tem.ctl'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Model/Base%20%2823.5%29_final%20model/tem.tpl'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Model/Base%20%2823.5%29_final%20model/tem.rep'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Model/Base%20%2823.5%29_final%20model/tem.rdat'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203.3%20Data%20used%20in%20assessment.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203.4%20Length%20and%20age%20comps%20sample%20sizes.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203.5%20Abundance%20indices.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203C.1.%20Biological%20Inputs.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203C.3.%20NAA_female.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203C.4.%20NAA_male.xlsx'),
  paste0('https://raw.githubusercontent.com/dgoethel-noaa/2024-Sablefish-SAFE/', revision,
    '/Final%20Report/Tables/Table%203.8%20Recruitment%20SSB%20Bio%20and%20CIs.xlsx'),
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=3.+AK+Sablefish.pdf&p=69a6efa6-b56d-4bc7-80b1-f9670f6283da.pdf')
source_revisions <- c(rep(paste0('GitHub dgoethel-noaa/2024-Sablefish-SAFE commit ', revision), 13L),
  'Final 2025 NPFMC GOA SAFE catch-report chapter; identifies 2024 as latest full assessment')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 100L))
  stop('Cache the reviewed NOAA Alaska sablefish sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed source.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA Alaska sablefish source manifest check failed: ',
  paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'NOAA:10956'
row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected exactly one NOAA Stock SMART 10956 inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10956', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE))
  stop('Screening must not create canonical Alaska sablefish records.', call. = FALSE)

screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = 'noaa_alaska_sablefish',
  organization = 'NOAA',
  official_stock_id = '10956',
  scientific_name = 'Anoplopoma fimbria',
  stock_name = 'Sablefish - Eastern Bering Sea / Aleutian Islands / Gulf of Alaska',
  assessment_area = 'Eastern Bering Sea / Aleutian Islands / Gulf of Alaska',
  inventory_assessment_year = 2024L,
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10956',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('Final Model 23.5 fits sex-aggregated U.S. fixed-gear fishery age compositions for 1999-2023; sample sizes are about 991-1,236 ages annually. Compositions are weighted by catch numbers across FMP areas. Gear/year catches are supplied in tonnes; a tinyAM catch-at-age reconstruction must verify area weighting and keep the trawl fleet distinct, for which the assessment uses length rather than age compositions.'),
  survey_age_evidence = paste('The assessment fits NOAA domestic longline survey age compositions for 1996-2023 and Japanese-U.S. cooperative survey age compositions in selected years 1981-1993. NOAA longline RPNs span 1979-2023; the age compositions are weighted by area RPNs and can support an age-specific index reconstruction. Indices for unsurveyed areas are extrapolated; no survey index exists for 2024.'),
  weights_evidence = 'The final report provides sex-specific length-at-age and round weight-at-age for ages 2-31+ as fixed inputs (Table 3C.1).',
  maturity_evidence = 'The final report provides a fixed female maturity-at-age schedule for ages 2-31+ (Table 3C.1); model SSB is mature female biomass.',
  mortality_evidence = 'Natural mortality is estimated as one scalar with a prior; the 2024 Model 23.5 report gives MLE 0.114 and an MCMC mean near 0.11. Age- and sex-specific M should not be inferred.',
  timing_evidence = 'The assessment uses annual survey indices and compositions but does not provide a fractional within-year timing value. The timing needed for a tinyAM translation remains unresolved.',
  output_evidence = paste('The final report and model archive provide numeric female and male N-at-age for 1960-2024 (ages 2-31+), recruitment, age-2+ biomass, and female SSB. Table 3.8 includes 95% MCMC intervals for recruitment through 2023 and biomass/SSB through 2024. Reported F is fully selected; no published numeric F-at-age table was located.'),
  detailed_source_url = paste(c(
    'https://github.com/dgoethel-noaa/2024-Sablefish-SAFE/tree/d080576086110b6dcfca2c37918bab3101fff44a',
    source_urls[1], source_urls[2], source_urls[6], source_urls[10], source_urls[11], source_urls[12],
    source_urls[13], source_urls[14]), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('Stock SMART 10956 is the single federal Alaska sablefish assessment population, distinct from the NOAA Pacific Coast unit. The latest full production assessment located is the 2024 Model 23.5 update; the 2025 SAFE chapter confirms no 2025 assessment and rolls forward the 2024 model. Direct fishery/survey age compositions, age-specific biology, public final model input/output files, and annual age-specific abundance and aggregate population outputs support eligibility. Fleet-specific age coverage and survey timing are limitations to resolve during curation.'),
  notes = paste('Screened eligible; no canonical database values imported. See discovery/source_reviews/noaa_alaska_sablefish_2024.md. Authoritative report, final input/output files, and selected tables are cached locally with provenance.'),
  stringsAsFactors = FALSE,
  check.names = FALSE)

initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved'
current_state <- register$candidate_unit_id[row_index] == screened$candidate_unit_id &
  register$match_status[row_index] == 'new' &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'eligible'
expected_identity <- as.character(register$official_stock_id[row_index]) == screened$official_stock_id &
  register$scientific_name[row_index] == screened$scientific_name &
  register$stock_name[row_index] == screened$stock_name &
  as.character(register$inventory_assessment_year[row_index]) ==
    as.character(screened$inventory_assessment_year)
if (!expected_identity || (!initial_state && !current_state))
  stop('NOAA sablefish identity or review state conflicts with the source review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(screened), function(name)
    identical(as.character(register[[name]][row_index]), as.character(screened[[name]])), logical(1L)))
  if (needs_write)
    replace_candidate_register_row(register_path, row_index, screened, candidate_id)
}
cat('Screened NOAA:10956 Alaska sablefish as an eligible, distinct current age-structured assessment unit.\n')
