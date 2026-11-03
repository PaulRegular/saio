root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_shortraker_2023_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
source_files <- c(
  'bsai_shortraker_2024_assessment.pdf',
  'bsai_plan_team_report_2024.pdf',
  'bsai_shortraker_2025_safe_chapter.pdf',
  'goa_shortraker_2023_assessment.pdf',
  'ssc_report_2025_shortraker_status.pdf')
source_urls <- c(
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=BSAI+shortraker+rockfish+2024.pdf&p=35d1918f-7ab2-4b2b-b1f2-79ac64ee5208.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+BSAI+Plan+Team+Report.pdf&p=fec709bc-b313-48c2-a81e-b9cb68c2fcb3.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=15.+Shortraker.pdf&p=1d436d16-34dd-438a-8f52-cebcc73eafe6.pdf',
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023_prept/GOAshortraker.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2025_FINAL.pdf&p=0efca0d8-411d-4c4f-b2e8-1aa01c3fef62.pdf')
source_revisions <- c(
  'November 2024 BSAI operational update; Model 22_2024, updates 2022 REMA data; accepted by Plan Team',
  'BSAI Groundfish Plan Team November 2024 report; confirms Model 22_2024 recommendation',
  '2025 final SAFE chapter; 2025 was catch report, no updated assessment',
  'November 2023 operational assessment; Model 23.3 REMA using trawl biomass and longline RPW',
  'December 2025 final SSC report; GOA operational assessment last completed 2023; 2026 assessment considered')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 10000L))
  stop('Cache the reviewed NOAA shortraker sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA shortraker source manifest check failed: ',
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
candidate_ids <- c('NOAA:10553', 'NOAA:10554')
if (!identical(as.integer(table(factor(register$candidate_id, levels = candidate_ids))),
    c(1L, 1L)))
  stop('Expected one inventory row for each NOAA shortraker stock unit.', call. = FALSE)
if (any(stocks$authority_stock_id %in% c('10553', '10554'), na.rm = TRUE) ||
    any(stocks$scientific_name == 'Sebastes borealis', na.rm = TRUE) ||
    any(assessments$assessment_id %in% c('noaa_bsai_shortraker_2024',
      'noaa_goa_shortraker_2023'), na.rm = TRUE) ||
    any(inputs$assessment_id %in% c('noaa_bsai_shortraker_2024',
      'noaa_goa_shortraker_2023'), na.rm = TRUE) ||
    any(outputs$assessment_id %in% c('noaa_bsai_shortraker_2024',
      'noaa_goa_shortraker_2023'), na.rm = TRUE))
  stop('Screening must not create canonical shortraker assessment records.', call. = FALSE)

make_row <- function(candidate_id, unit_id, stock_id, stock_name, area, year,
                     source_url, catch_age, survey_age, weights, maturity, mortality,
                     timing, output, decision, notes) {
  data.frame(
    candidate_id = candidate_id,
    candidate_unit_id = unit_id,
    organization = 'NOAA',
    official_stock_id = stock_id,
    scientific_name = 'Sebastes borealis',
    stock_name = stock_name,
    assessment_area = area,
    inventory_assessment_year = year,
    inventory_url = paste0('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=',
      stock_id),
    retrieved_on = '2026-10-28',
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = catch_age,
    survey_age_evidence = survey_age,
    weights_evidence = weights,
    maturity_evidence = maturity,
    mortality_evidence = mortality,
    timing_evidence = timing,
    output_evidence = output,
    detailed_source_url = source_url,
    review_date = '2026-10-30',
    decision_reason = decision,
    notes = notes,
    stringsAsFactors = FALSE,
    check.names = FALSE)
}

bsai_urls <- paste(c(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10553',
  source_urls[1:3],
  'https://meetings.npfmc.org/Meeting/Details/8165'), collapse = '; ')
goa_urls <- paste(c(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10554',
  source_urls[4:5],
  'https://meetings.npfmc.org/Meeting/Details/8165'), collapse = '; ')

screened <- rbind(
  make_row(
    'NOAA:10553', 'noaa_bsai_shortraker', '10553',
    'Shortraker rockfish - Bering Sea / Aleutian Islands',
    'Bering Sea / Aleutian Islands', '2024', bsai_urls,
    'The 2024 Model 22_2024 update uses aggregate catches and survey inputs; the report lists fishery and survey length compositions, but no catch-at-age or age-composition likelihood.',
    'The REMA population model fits design-based survey biomass and its observation error, plus EBS-slope longline relative population weights. It does not fit an age-specific abundance index.',
    'No age-specific weight input is used by the selected Tier 5 biomass model.',
    'No age-indexed maturity input is used by the selected Tier 5 biomass model.',
    'Natural mortality is fixed at 0.03 per year; fishing reference rates are set from M rather than estimated as age-specific F.',
    'The selected model uses year-indexed biomass and relative-population-weight survey indices; a proportional within-year timing value is not reported.',
    'The report provides regional exploitable-biomass trajectories and uncertainty, plus aggregate OFL/ABC. It does not report annual N-at-age or F-at-age.',
    'NOAA 10553 is the distinct BSAI shortraker management unit. The latest detailed production model located is the 2024 Model 22_2024 operational update, accepted by the Plan Team; the 2025 SAFE chapter is a catch report and the 2026 full assessment is scheduled after this review date. The model is a Tier 5 survey-biomass random-effects model without age-disaggregated population inputs or outputs, so the unit is ineligible for the age-disaggregated set.',
    'Screened ineligible; no canonical database records added. Source PDFs and hashes are cached in gitignored source_cache/discovery_noaa_shortraker_2023_2025/. See discovery/source_reviews/noaa_shortraker_bsai_2024.md.'),
  make_row(
    'NOAA:10554', 'noaa_goa_shortraker', '10554',
    'Shortraker rockfish - Gulf of Alaska',
    'Gulf of Alaska', '2023', goa_urls,
    'The 2023 assessment uses aggregate catch. The report says commercial length samples are few and the few fishery age samples had not been aged; no catch-at-age input is reported.',
    'Model 23.3 fits regional bottom-trawl survey biomass for 1990-2023 and AFSC longline relative population weights for 1992-2023, with uncertainty. No age-specific survey index or age-composition likelihood is used.',
    'Length-weight and growth parameters are described as supporting biology, not as an age-specific likelihood input to the selected REMA model.',
    'Age/maturity studies are cited as life-history information, but maturity-at-age is not an input to the selected biomass model.',
    'Natural mortality is fixed at 0.03 per year under Tier 5; the model does not estimate annual age-specific M.',
    'The annual survey series are not documented as within-year timing fractions in the REMA model.',
    'The report provides aggregate exploitable-biomass trajectories with uncertainty and harvest limits. It does not report age-specific N, F, recruitment, or SSB surfaces.',
    'NOAA 10554 is the distinct GOA shortraker management unit. The latest operational assessment is the 2023 Model 23.3 REMA assessment; the final 2025 SSC report confirms no later operational assessment was completed and says a new assessment was considered for 2026. The selected Tier 5 model fits aggregate survey indices, not age-disaggregated inputs, so the unit is ineligible for the age-disaggregated set.',
    'Screened ineligible; no canonical database records added. Source PDFs and hashes are cached in gitignored source_cache/discovery_noaa_shortraker_2023_2025/. See discovery/source_reviews/noaa_shortraker_goa_2023.md.'))

row_index <- match(screened$candidate_id, register$candidate_id)
initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved'
current_state <- register$candidate_unit_id[row_index] == screened$candidate_unit_id &
  register$match_status[row_index] == 'new' &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'ineligible'
expected_identity <- as.character(register$official_stock_id[row_index]) ==
  screened$official_stock_id &
  register$scientific_name[row_index] == screened$scientific_name &
  register$stock_name[row_index] == screened$stock_name &
  as.character(register$inventory_assessment_year[row_index]) ==
  screened$inventory_assessment_year
if (any(!expected_identity) || any(!initial_state & !current_state))
  stop('NOAA shortraker identity or review state conflicts with the source review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_len(nrow(screened))) {
    needs_write <- initial_state[i] || !all(vapply(names(screened), function(name)
      identical(as.character(register[[name]][row_index[i]]),
        as.character(screened[[name]][i])), logical(1L)))
    if (needs_write)
      replace_candidate_register_row(register_path, row_index[i], screened[i, , drop = FALSE],
        screened$candidate_id[i])
  }
}
cat('Screened NOAA:10553 and NOAA:10554 as distinct new shortraker units; both are ineligible for age-disaggregated assessment data.\n')
