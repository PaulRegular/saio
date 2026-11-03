root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_atlantic_wolffish_2022')
register_path <- file.path(root, 'discovery', 'candidates.csv')
today <- '2026-11-01'
candidate_id <- 'NOAA:11562'
unit_id <- 'noaa_atlantic_wolffish_us'

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
    value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify a cached source checksum.', call. = FALSE)
  hash
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
required_files <- c('atlantic_wolffish_2022_assessment.pdf',
  'nefsc_fall_2022_management_track_panel_report.pdf')
if (anyDuplicated(manifest$file[!is.na(manifest$file) & nzchar(manifest$file)]) ||
    !all(required_files %in% manifest$file[manifest$status == 'downloaded']))
  stop('The Atlantic wolffish source manifest is incomplete.', call. = FALSE)
for (file in required_files) {
  i <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[i] ||
      sha256_file(path) != manifest$sha256[i])
    stop('Cached wolffish source failed provenance validation: ', file, call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[as.character(stocksmart$stock_id) == '11562' &
  as.character(stocksmart$assessment_id) == '12525', , drop = FALSE]
if (nrow(assessment) != 1L || assessment$assessment_year != 2022L ||
    assessment$last_data_year != 2021L || assessment$science_center != 'NEFSC' ||
    assessment$stock_area != 'Gulf of Maine / Georges Bank' ||
    assessment$assessment_model != 'SCALE' || assessment$review_result != 'Full acceptance')
  stop('Stock SMART metadata no longer matches the reviewed Atlantic wolffish run.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) || sum(candidates$candidate_id == candidate_id) != 1L)
  stop('Expected one unique NOAA Atlantic wolffish candidate row.', call. = FALSE)
i <- match(candidate_id, candidates$candidate_id)
row <- data.frame(
  candidate_unit_id = unit_id,
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2022 SCALE update fits total catch and catch-size distributions; no catch numbers-at-age or source-supported reconstruction from age compositions was found. Catch is predominantly discards since 2010, with an 8% discard mortality assumption.',
  survey_age_evidence = 'The assessment uses one age-1 recruitment index plus NEFSC spring/fall and Massachusetts DMF spring adult survey indices. The report describes size and age data used to inform the SCALE model, but does not provide a full age-specific abundance-index matrix. The historical NOAA status review states age-based abundance measures could not be developed.',
  weights_evidence = '',
  maturity_evidence = 'The assessment update changed the maturity knife-edge to 52 cm from 50 cm; a recoverable maturity-at-age series is not provided in the current run report.',
  mortality_evidence = 'The current report does not document a natural-mortality-at-age surface or its exact treatment; no such age-specific input was found in the reviewed sources.',
  timing_evidence = 'The reviewed report describes annual survey indices but does not provide within-year observation timing fractions for an age-structured observation model.',
  output_evidence = 'Aggregate outputs include SSB, fully selected F, age-1 recruitment, catch and survey biomass indices through 2021. The report does not provide N-at-age or F-at-age surfaces; approximate 90% lognormal intervals are not shown because MCMC is not fully developed for SCALE.',
  detailed_source_url = paste(
    'https://d23h0vhsm26o6d.cloudfront.net/5_2022_CAT_UNIT_RPT_UPDATED.pdf;',
    'https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf;',
    'https://repository.library.noaa.gov/view/noaa/17699;',
    'https://www.fisheries.noaa.gov/species/atlantic-wolffish/management;',
    'https://repository.library.noaa.gov/view/noaa/73153/noaa_73153_DS1.pdf'),
  review_date = today,
  decision_reason = 'The latest NOAA Stock SMART run is the 2022 NEFSC SCALE update through 2021. SCALE uses catch-at-length and survey size/age information, not catch numbers-at-age or a full age-specific abundance series. The report does not support reconstructing those inputs from age compositions. Aggregate SSB, F and age-1 recruitment outputs are available, but the required age-disaggregated inputs are not; exclude this U.S. unit from the age-disaggregated candidate set.',
  notes = paste0('Stock SMART ID 11562 is one U.S. Atlantic wolffish management stock in the Gulf of Maine/Georges Bank area. It is distinct from ICES candidate ICES:caa.27.5a (Iceland grounds) and from Canadian Atlantic wolffish units. Stock SMART labels the run Full acceptance, while the Fall 2022 panel records Level 1 direct delivery and says the assessment was not peer reviewed. Its citation field still refers to the 2017 operational report. No canonical stock or numerical data were added.'),
  stringsAsFactors = FALSE)

current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(n) {
  x <- current[[n]]; y <- row[[n]]
  if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[i]) || !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine) stop('Unexpected existing NOAA wolffish review state.', call. = FALSE)
  for (n in names(row)) candidates[[n]][i] <- row[[n]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i, candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:11562 Atlantic wolffish as a new, ineligible U.S. SCALE unit.\n')
