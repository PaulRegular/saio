root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

assessment_url <- 'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2022/BSAIshark.pdf'
update_url <- paste0(
  'https://meetings.npfmc.org/CommentReview/DownloadFile?',
  'fileName=C1+BSAI+Groundfish+SAFE+Introduction.pdf&',
  'p=e6feed39-97d1-4f25-aa97-492b733d3c7e.pdf')
current_chapters_url <- 'https://meetings.npfmc.org/Meeting/Details/7163'
noaa_shark_page <- 'https://www.fisheries.noaa.gov/alaska/ecosystems/shark-research-alaska'
source_urls <- paste(assessment_url, update_url, current_chapters_url,
  noaa_shark_page, sep = '; ')

review <- data.frame(
  candidate_id = c('NOAA:10696', 'NOAA:11403', 'NOAA:10700', 'NOAA:11450'),
  candidate_unit_id = c('noaa_pacific_sleeper_shark_bsai',
    'noaa_bsai_shark_complex', 'noaa_spiny_dogfish_goa',
    'noaa_goa_shark_complex'),
  match_status = rep('new', 4L),
  screening_status = rep('screened', 4L),
  eligibility = rep('ineligible', 4L),
  import_status = rep('not_started', 4L),
  catch_age_evidence = c(
    'The latest detailed SAFE source located is the 2022 assessment. Pacific sleeper shark is assessed using a catch-only Tier 6 model; the report states that age data are unavailable. No catch numbers-at-age or age-composition likelihood was found.',
    'The BSAI shark complex is managed in aggregate under Tier 6 using catch history for harvest specifications. Its species-specific catch summaries do not provide a catch-at-age input for the multi-species complex.',
    'The GOA spiny dogfish component uses the random-effects biomass model (Model 15.3A) and survey biomass with catchability and mortality assumptions. The report presents length distributions and life-history ages, but no catch-at-age or age-composition likelihood.',
    'The GOA shark complex combines a Tier 5 spiny-dogfish biomass model with Tier 6 catch-based components for other sharks. No single age-structured catch input represents this mixed-species unit.'),
  survey_age_evidence = c(
    'Trawl and longline survey catches and relative-population-number series are reported as auxiliary information. The SAFE states survey information is not used to generate harvest specifications for the BSAI shark complex; no age-specific survey index is fitted.',
    'The report includes survey catch and relative abundance summaries for constituent species, but these are not age-specific observations in an age-structured model.',
    'The accepted biomass assessment uses aggregate survey biomass observations; survey length data are descriptive and do not form an age-specific abundance index.',
    'The assessment reports aggregate survey biomass for the spiny-dogfish component and auxiliary survey information for other species; no age-specific abundance likelihood is fitted for the complex.'),
  weights_evidence = c(
    'No run-specific weight-at-age input was identified. The report describes life history as poorly known.',
    'There is no single species-specific weight-at-age surface for this multi-species complex.',
    'The report includes length-weight and life-history information, but the random-effects biomass assessment does not fit weight-at-age observations.',
    'No single species-specific weight-at-age input applies to the mixed-species complex.'),
  maturity_evidence = c(
    'The report describes sleeper-shark life history as unknown; maturity-at-age is unavailable.',
    'The aggregate complex has no single maturity-at-age input.',
    'Age-at-maturity is included in the life-history review, but it is not an age-composition or maturity likelihood in the accepted biomass model.',
    'The complex combines species with different life histories; no single maturity-at-age input is used.'),
  mortality_evidence = c(
    'The catch-only Tier 6 component does not estimate an age-specific M surface; sleeper-shark mortality and age-at-maturity are unknown.',
    'The Tier 6 catch-history method does not estimate age-specific natural mortality.',
    'The random-effects biomass model uses a fixed mortality rate for harvest specifications, not an estimated age-specific M surface.',
    'The complex combines Tier 5 and Tier 6 components; it has no common age-specific M process.'),
  timing_evidence = rep(
    'Catch and survey information is annual or summarized over survey periods. The reviewed sources do not specify one fractional survey timing for a tinyAM age-structured model.',
    4L),
  output_evidence = c(
    'Official outputs are catch-based harvest specifications and complex/component status summaries, not annual age-specific abundance, fishing mortality, recruitment, or spawning biomass trajectories.',
    'The report provides aggregate complex ABC/OFL and catch specifications, but no age-specific population outputs.',
    'The accepted model reports aggregate exploitable biomass and harvest specifications; it does not report age-specific N or F surfaces.',
    'Official outputs are aggregate harvest specifications for the complex and its Tier 5/6 components, not age-specific population trajectories.'),
  detailed_source_url = rep(source_urls, 4L),
  review_date = rep('2026-11-02', 4L),
  decision_reason = c(
    'Ineligible for the age-disaggregated input screen. The latest detailed assessment located (2022) uses a catch-only Tier 6 method for this species component, and the report states that age data are unavailable. The 2024 SAFE carries forward the previous assessment for 2025-2026 specifications; no 2026 shark chapter was posted in the reviewed 2026 SAFE chapter list.',
    'Ineligible: this is a multi-species complex assessed from aggregate catch history under Tier 6, without age-disaggregated observations or age-specific population outputs. The 2022 SAFE is the latest detailed assessment located; later specifications carry forward its model results.',
    'Ineligible for age-input screening: the current GOA spiny-dogfish Tier 5 method is a random-effects survey-biomass model, not an age-structured assessment. Biological age information and survey length distributions do not provide fitted catch-at-age or age-specific index data.',
    'Ineligible: the GOA shark complex combines a random-effects biomass assessment for spiny dogfish with catch-based Tier 6 components for other sharks. It has no unified age-specific input or output surface.'),
  notes = c(
    'The NOAA inventory labels this species as a stock row, but the 2022 assessment treats BSAI sharks within the broader managed complex; Pacific sleeper shark receives a species-specific catch-only component model. No canonical stock record exists. The 2024 SAFE uses prior assessment specifications for 2025-2026; the 2026 chapter list reviewed on 2026-11-02 contains no shark chapter.',
    'Stock SMART inventory year is older than the detailed 2022 SAFE. The report defines the BSAI shark complex as a multi-species Tier 6 management unit and reports species components separately; do not count those components as separate additional stocks.',
    'The GOA spiny-dogfish component is a species-specific Tier 5 assessment within the GOA shark complex. Its annual/random-effects biomass and fixed natural-mortality calculations are not an age-structured population model.',
    'The GOA complex is not equivalent to the BSAI complex: GOA spiny dogfish is Tier 5, while the other shark components are Tier 6. The 2022 assessment is the latest detailed run located, with later catch/specification updates rather than age-structured model outputs.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (any(review$candidate_unit_id %in%
    register$candidate_unit_id[!register$candidate_id %in% review$candidate_id]))
  stop('A reviewed candidate unit is already assigned to another inventory row.',
    call. = FALSE)

blank <- function(x) is.na(x) || !nzchar(x)
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
  reviewed <- old$match_status == review$match_status[i] &&
    old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
    old$import_status == 'not_started' &&
    identical(unit, as.character(review$candidate_unit_id[i]))
  if (!initial && !reviewed)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  if (initial || reviewed) {
    for (name in setdiff(names(review), 'candidate_id'))
      register[[name]][row_index] <- review[[name]][i]
    if (id == 'NOAA:11403')
      register$assessment_area[row_index] <- 'Bering Sea / Aleutian Islands'
    if (id == 'NOAA:11450')
      register$assessment_area[row_index] <- 'Gulf of Alaska'
    same <- all(vapply(names(register), function(name) {
      x <- register[[name]][row_index]
      y <- old[[name]]
      if (is.na(x)) is.na(y) else !is.na(y) &&
        identical(as.character(x), as.character(y))
    }, logical(1L)))
    if (!same && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
      replace_candidate_register_row(register_path, row_index,
        register[row_index, , drop = FALSE], id)
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened four NOAA Alaska shark records against the 2022 assessment and subsequent SAFE updates.\n')
