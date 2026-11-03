root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_atlantic_menhaden_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'NOAA:11089'
unit_id <- 'noaa_atlantic_menhaden'

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_sources <- c(
  atlantic_menhaden_update_2025.pdf = '1F02AEC8FC22FF42F4288E10805517CBCB82BBBA247CE6FFB3EF867676505B1C',
  sedar_102_atlantic_menhaden_erp_2025.pdf = 'D64D7B4AB19725E1C4836629AEA97AFC5B17C7B403BBEBAEC68C9900408A48F3',
  sedar_69_menhaden_benchmark_2020.pdf = '80B75AF4E241C2AA4AB8B2B4C0E2D059488862AC8C192940C87E52D262E8449D'
)
for (file in names(expected_sources)) {
  path <- file.path(cache, file)
  source_row <- match(file, sources$file)
  if (is.na(source_row) || !file.exists(path) ||
      as.numeric(sources$bytes[source_row]) != file.info(path)$size ||
      toupper(sources$sha256[source_row]) != expected_sources[[file]] ||
      sha256_file(path) != expected_sources[[file]] ||
      !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
    stop('Cached menhaden source differs from its manifest: ', file, call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '11089' ||
    candidates$scientific_name[row] != 'Brevoortia tyrannus' ||
    candidates$inventory_assessment_year[row] != 2022L ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == '11089', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('NOAA Atlantic menhaden identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The official 2025 single-species BAM update reports catch-at-age proportions for ages 0-6+ in four north/south reduction and bait fleets (Tables A2-A5); landings by fishery and region are tabulated in 1,000 metric tons (Table A1). Bait age compositions begin in 1985, and the 2020 south bait composition is censored.',
  survey_age_evidence = 'The base run uses aggregate YOY and regional adult abundance indices plus survey length compositions, not observed survey numbers-at-age. The SEDAR 69 benchmark documents a sensitivity converting survey length compositions to age with fishery-dependent age-length keys; this is a documented approximation, not the base-run survey likelihood.',
  weights_evidence = 'The SEDAR 69 report tabulates time-varying population and fishery weight-at-age through 2017. The 2025 update extends the run to 2023 and updates fecundity using VIMS information, but exact updated weight and fecundity input arrays for 2018-2023 were not located.',
  maturity_evidence = 'The assessment uses time-varying maturity-at-age derived from a length-based maturity relationship and annual length-at-age. The SEDAR 69 report provides earlier numeric maturity inputs; exact updated 2018-2023 arrays for the 2025 run were not located.',
  mortality_evidence = 'The 2025 update specifies fixed age-varying M for ages 0, 1, 2, 3, 4, 5, and 6+: 1.39, 1.03, 0.82, 0.71, 0.64, 0.60, and 0.57 per year.',
  timing_evidence = 'The single-species model starts its fishing year on March 1; the 2025 report describes survey-specific seasons and timing in its index table. Exact within-year fractions for each index have not yet been transcribed.',
  output_evidence = 'The 2025 update reports recruitment, age-1+ biomass, full F, geometric-mean F ages 2-4, and fecundity through 2023 mainly as figures. Fecundity is not SSB. No numerical N-at-age or F-at-age output matrix or fitted model object was verified in the reviewed sources.',
  detailed_source_url = 'https://asmfc.org/wp-content/uploads/2025/11/2025AtlMenhadenSingleSpeciesAssmtUpdate_October2025.pdf',
  review_date = '2026-10-30',
  decision_reason = 'The current 2025 single-species update is age-structured and publishes catch-at-age proportions, landings, aggregate abundance indices, biological methods, and population summaries. Eligibility remains unresolved because updated age-specific biological arrays for 2018-2023, exact survey timing fractions, and numerical age-specific official outputs were not verified. Do not substitute the separate SEDAR 102 ERP model or older benchmark values for the current run.',
  notes = 'NOAA Stock SMART 11089 lists a 2022 assessment year, but the latest detailed production run located is the ASMFC 2025 single-species BAM update with terminal year 2023; the concurrently published SEDAR 102 ERP benchmark is a separate model. SEDAR 69 RD03 documents a 2020 sensitivity converting survey length compositions to age. No canonical assessment data were added. Three official source PDFs and provenance are cached in source_cache/discovery_noaa_atlantic_menhaden_2025/sources.csv.'
)

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('NOAA Atlantic menhaden candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], id)
}

cat('Screened NOAA Atlantic menhaden; source eligibility remains unresolved for the current run.\n')
