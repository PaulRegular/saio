root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_gom_cobia_2020')
register_path <- file.path(root, 'discovery', 'candidates.csv')

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
  sedar28_update_gulf_cobia_2020.pdf = '22381a29b88513302726cc2988cb6044981e57bcfdc97571d6213f4defd3df95',
  sedar28_update_cobia_recreational_survey_wp02_2020.pdf = '2a6388c42bb8d621447c437323368e8d6f137e96c47d4484b4961d66860fd442',
  sedar28_update_cobia_length_compositions_wp04_2020.pdf = 'bcbff71d05b64d8966b6ce8597d84ef73a17228b0556fb26a251e41daa612988',
  sedar28_update_cobia_headboat_index_wp05_2020.pdf = 'd8ec954423d56abd0ccb0e03eaac1660952e5b4a87734ed06a885f1e9b893f79',
  sedar28_update_cobia_commercial_discards_wp06_2020.pdf = 'e74cc2acf2aa99e7233a053e29722cb64f110e82da190a259773f4f318eda313',
  sedar28_update_cobia_shrimp_bycatch_wp07_2020.pdf = '7b4270b1bbb728c0e1e4185aec7ecd655ec9c84f17b3bb33fe479b700cb6d689'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The Gulf cobia source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached Gulf cobia source differs from its manifest: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10390'
candidate_unit_id <- 'noaa_cobia_gulf_mexico_2020'
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || candidates$official_stock_id[row] != '10390' ||
    candidates$scientific_name[row] != 'Rachycentron canadum' ||
    candidates$stock_name[row] != 'Cobia - Gulf of Mexico' ||
    candidates$assessment_area[row] != 'Gulf of Mexico' ||
    candidates$inventory_assessment_year[row] != '2020')
  stop('The NOAA Gulf cobia inventory identity changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (candidate_unit_id %in% stocks$stock_id ||
    candidate_unit_id %in% assessments$assessment_id ||
    candidate_unit_id %in% inputs$assessment_id ||
    candidate_unit_id %in% outputs$assessment_id)
  stop('A canonical cobia record exists; recheck the current-unit crosswalk.', call. = FALSE)

report_url <- manifest$url[match('sedar28_update_gulf_cobia_2020.pdf', manifest$file)]
review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste0(
    'The 2020 official update fits recreational conditional age-at-length compositions, ',
    'ages 0-10 with age 10 as a plus group. The report records 1,266 age-length samples ',
    'in 1987-2002 and 2004-2018 (none in 2003). It does not fit direct catch-at-age. ',
    'Annual recreational length compositions and landings are published, so a documented ',
    'reconstruction is possible in principle; the numerical conditional age compositions ',
    'are plotted rather than tabulated, and no native SS3 input files were linked.'),
  survey_age_evidence = paste0(
    'The assessment uses aggregate fishery-dependent abundance indices: MRIP for 1981-2018 ',
    'and SRHS headboat for 1986-2019. Both use selectivity matching the aggregate ',
    'recreational fleet. Age-at-length observations come from recreational fishery samples; ',
    'there is no separate age-specific survey index. Any index-at-age reconstruction would ',
    'therefore be an approximation and must retain that distinction.'),
  weights_evidence = paste0(
    'The report provides the fixed sex-combined length-weight relationship and sex-specific ',
    'growth inputs. Weight-at-age can be derived from those official inputs; it is not a ',
    'directly observed annual age-specific weight surface.'),
  maturity_evidence = paste0(
    'Maturity is fixed by age: age 2 is 50% mature and ages 3+ are fully mature. The model ',
    'uses a 60% female sex ratio.'),
  mortality_evidence = paste0(
    'Natural mortality is fixed as an age-specific scaled Lorenzen vector, with fully ',
    'selected-age M = 0.38 per year; no M process is estimated.'),
  timing_evidence = paste0(
    'The model is annual and assumes fishing and spawning occur continuously and ',
    'homogeneously through the year; no within-year survey timing fraction is specified.'),
  output_evidence = paste0(
    'Table 15 reports annual model biomass, SSB, total abundance, age-0 recruitment and ',
    'depletion for 1927-2018. Recruitment uncertainty is also plotted. Numbers-at-age are ',
    'shown graphically; a numerical N-at-age table was not located. The report includes ',
    'fleet mortality/selectivity graphics, but no numerical F-at-age table was located.'),
  detailed_source_url = report_url,
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Eligible for source curation: the official update is age structured, includes ',
    'conditional age-at-length observations, annual catch and abundance inputs, fixed ',
    'age-specific biology, and reported population outputs. The age composition values ',
    'are available in figures rather than machine-readable tables, so import readiness ',
    'depends on recovering or transparently digitizing and validating those inputs.'),
  notes = paste0(
    'Latest detailed Gulf assessment located is the SEDAR 28 update dated June 2020, ',
    'with data through 2018; the 2024 NOAA management amendment continues to rely on ',
    'this assessment. Keep this Gulf unit separate from Southern Atlantic cobia. ',
    'The assessment report notes low confidence and data limitations, including poor fit ',
    'to age compositions and uncertain abundance-index interpretation.')
)

pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
already_reviewed <- all(vapply(names(review), function(column)
  identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
  logical(1L)))
if (!(pristine || already_reviewed))
  stop('The NOAA Gulf cobia candidate has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA Gulf of Mexico cobia as eligible for source curation, with age-input reconstruction caveats.\n')
