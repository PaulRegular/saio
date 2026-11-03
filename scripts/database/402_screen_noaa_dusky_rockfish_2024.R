root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_dusky_rockfish_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10559'
unit_id <- 'noaa_goa_dusky'
source_files <- c('GOA_dusky_rockfish_SAFE_2024.pdf', 'GOA_dusky_rockfish_harvest_projection_2026.pdf')
source_urls <- c(
  'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAdusky.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=12.+GOA+Dusky+Rockfish.pdf&p=ed574dbd-35fa-43dc-99f0-a80909caf4d5.pdf')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
source_paths <- file.path(cache, source_files)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, manifest$file)
if (anyNA(source_rows) || !identical(as.character(manifest$url[source_rows]), source_urls) ||
    !identical(as.character(manifest$retrieved_on[source_rows]), rep('2026-10-30', 2L)) ||
    !identical(as.numeric(file.info(source_paths)$size), as.numeric(c(6294172, 1764868))) ||
    !identical(as.numeric(manifest$bytes[source_rows]), as.numeric(file.info(source_paths)$size)) ||
    !identical(toupper(as.character(manifest$sha256[source_rows])),
      unname(vapply(source_paths, sha256_file, character(1L)))))
  stop('Cached dusky rockfish sources do not match their source manifest.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected exactly one NOAA 10559 inventory row.', call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (any(stocks$authority_stock_id == '10559', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Sebastes variabilis', na.rm = TRUE) ||
    any(grepl(unit_id, assessments$assessment_id, fixed = TRUE), na.rm = TRUE) ||
    any(grepl(unit_id, inputs$assessment_id, fixed = TRUE), na.rm = TRUE) ||
    any(grepl(unit_id, outputs$assessment_id, fixed = TRUE), na.rm = TRUE))
  stop('Screening must not create canonical dusky rockfish records.', call. = FALSE)

review <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = unit_id,
  organization = 'NOAA',
  official_stock_id = '10559',
  scientific_name = 'Sebastes variabilis',
  stock_name = 'Dusky rockfish - Gulf of Alaska',
  assessment_area = 'Gulf of Alaska',
  inventory_assessment_year = '2024',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10559',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 m22.5a full assessment fits total catch biomass in metric tonnes for 1977-2024 and fishery age compositions. The data summary lists fishery age-composition years 1998-2002, 2004-2006, 2008-2020 (biennial), and 2022; the report describes sampled fish aged 4-66. Annual catch-at-age numbers are not a native input, but source catch biomass, age proportions, and weight-at-age support a documented reconstruction. The report contains a discrepancy between the model data-year summary and the narrative sample years that needs checking during curation.',
  survey_age_evidence = 'The model uses GOA bottom-trawl VAST biomass estimates (tonnes, with standard errors and confidence intervals) for 1990-2023 and survey age compositions for 1990-2023. Survey age compositions are proportions for ages 4-29 plus a 30+ group, with input/effective sample sizes and haul counts. Biomass, age proportions, and weights-at-age permit documented age-specific index reconstruction; the report does not provide an age-specific biomass index directly.',
  weights_evidence = 'Mean weight-at-age is estimated outside the model from survey size-at-age data for combined sexes. The SAFE gives a weight growth equation in grams with W-infinity=1928 g, kappa=0.190, t0=0.607, and exponent b=3.0, supporting a documented age-specific weight reconstruction.',
  maturity_evidence = 'Female maturity-at-age is represented by a logistic curve estimated conditionally from combined observations cited to Lunsford (1997, personal communication) and Chilton (2010); the reported age at 50% maturity is 10.1. The fitted curve is shown in Figure 12-9, but the combined raw maturity observations are not tabulated in this SAFE and need source review before import.',
  mortality_evidence = 'Natural mortality is fixed at M=0.07 per year throughout the assessment; it is not estimated by age. The SAFE explains the historical basis and notes estimates from maximum observed ages.',
  timing_evidence = 'The assessment uses annual trawl-survey biomass and age-composition observations, but does not report a fractional within-year survey timing. Survey timing remains unresolved for any translation requiring a timing fraction.',
  output_evidence = 'The 2024 SAFE reports annual MLE female spawning biomass, total age-4+ biomass, fully selected F, and age-4 recruitment, plus MCMC means and 95% credible intervals for those time series. It does not provide numerical N-at-age or F-at-age surfaces. The September 2026 pre-dissemination peer-review harvest projection updates catch and projected biomass, but explicitly reruns no assessment model and is not formally disseminated by NMFS.',
  detailed_source_url = paste(source_urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'Eligible for source curation. The 2024 full m22.5a assessment provides total catch biomass, fishery and survey age compositions, survey biomass with uncertainty, a source-supported weight-at-age equation, a female maturity-at-age curve, fixed M, and comparable population outputs. The September 2026 report is a pre-dissemination peer-review harvest projection, not formally disseminated by NMFS, and confirms the next full assessment is scheduled for 2027. Curation must resolve the fishery age-sample year discrepancy, recover/cite the underlying maturity observations where possible, and record the unknown fractional survey timing.',
  notes = 'this is a new NOAA Gulf of Alaska assessment unit. Model year 2024 refers to the latest full assessment (recommended m22.5a), not the latest advice year: the pre-dissemination 2026 harvest projection carries the 2024 assessment forward without re-estimating parameters. The 2024 SAFE and 2026 projection PDF, retrieval date, sizes, URLs and SHA-256 checksums are cached in gitignored source_cache/discovery_noaa_dusky_rockfish_2024/. No canonical numerical data were imported.',
  stringsAsFactors = FALSE,
  check.names = FALSE
)
initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' & register$eligibility[row_index] == 'unresolved'
reviewed_state <- register$candidate_unit_id[row_index] == unit_id &
  register$match_status[row_index] == 'new' & register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'eligible' & as.character(register$inventory_assessment_year[row_index]) == '2024'
if (register$official_stock_id[row_index] != review$official_stock_id ||
    register$scientific_name[row_index] != review$scientific_name ||
    register$stock_name[row_index] != review$stock_name ||
    (!initial_state && !reviewed_state))
  stop('NOAA dusky rockfish identity or review state conflicts with the source screen.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row_index]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row_index] <- review[[name]]
    replace_candidate_register_row(register_path, row_index, register[row_index, , drop = FALSE], candidate_id)
  }
}
cat('Screened NOAA 10559 as eligible for source curation; latest full assessment is 2024 with a 2026 harvest projection.\n')
