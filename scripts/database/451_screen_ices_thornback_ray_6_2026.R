root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_thornback_ray_6_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rjc.27.6'
unit_id <- 'ices_thornback_ray_6'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected <- c(
  ICES_advice_2026_rjc_27_6.pdf = 'dbbc5833c3a48cc912a485c0bb930973c838c52dfd93bfdff569f5715bb5d8d5',
  ICES_advice_record_7193.html = 'f1edf4a2e5512bec088afdf37b886d11f30a6c27f2320b8825224dbf870bdec3',
  ICES_standard_graphs_rjc_27_6_2026.html = 'af852f82c64b2c1a785bd24bc859c5364f4fab31db4391925634f4d76feab57a',
  ICES_SAG_rjc_27_6_2026.xml = 'c99ad96ee99c911a9a9c9cbb9e237e33edf712a4a7907f2d9320a3d11f6cd2dc'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The thornback ray source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached thornback ray source differs from its manifest: ', file, call. = FALSE)
}

advice <- paste(readLines(file.path(cache, 'ICES_advice_record_7193.html'), warn = FALSE),
  collapse = ' ')
source_data <- paste(readLines(file.path(cache,
  'ICES_standard_graphs_rjc_27_6_2026.html'), warn = FALSE), collapse = ' ')
stock_xml <- paste(readLines(file.path(cache, 'ICES_SAG_rjc_27_6_2026.xml'), warn = FALSE),
  collapse = ' ')
if (!all(vapply(c('rjc.27.6', '2026', 'Stock Category',
    'landings should be no more than 51 tonnes in each of the years 2027 and 2028',
    'cannot quantify the corresponding catches'),
    grepl, logical(1L), x = advice, fixed = TRUE)) ||
    !all(vapply(c('rjc.27.6', 'Assessment Year', '2026', 'B_index',
      'kilogram per square kilometer', 'Landings', 'tonnes'),
      grepl, logical(1L), x = source_data, fixed = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>rjc.27.6</StockCode>', '<StockCategory>3</StockCategory>',
      '<Fage></Fage>', '<RecruitmentAge></RecruitmentAge>',
      '<StockSizeDescription>B_index</StockSizeDescription>',
      '<ModelType>DLS</ModelType>', '<ModelName>rfb</ModelName>'),
      grepl, logical(1L), x = stock_xml, fixed = TRUE)))
  stop('The cached ICES sources do not support the documented thornback ray screen.',
    call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
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
    candidates$official_stock_id[row] != 'rjc.27.6' ||
    candidates$scientific_name[row] != 'Raja clavata' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'rjc.27.6', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('ICES thornback ray identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Subarea 6 (West of Scotland)',
  catch_age_evidence = paste('The 2026 advice and accompanying Standard Graphs records provide annual landings in tonnes, not catch-at-age or age-composition observations. The advice record identifies a Category 3 assessment and says corresponding catches cannot be quantified.'),
  survey_age_evidence = paste('Standard Graphs reports a single aggregate biomass index (B_index) in kg/km2; it does not report survey numbers-at-age or survey age compositions.'),
  weights_evidence = 'The reviewed 2026 assessment source set contains no weight-at-age inputs.',
  maturity_evidence = 'The reviewed 2026 assessment source set contains no maturity-at-age inputs.',
  mortality_evidence = paste('The 2026 Stock XML identifies a data-limited-stock rfb method, leaves Fage blank, and provides no age-specific natural-mortality assumptions or F-at-age series.'),
  timing_evidence = 'No within-year survey timing fraction or age-specific survey likelihood is reported in the 2026 advice and Standard Graphs source set.',
  output_evidence = paste('The official advice limits landings to 51 tonnes in each of 2027 and 2028. Standard Graphs reports an aggregate biomass index with 95% intervals and annual landings; the index is measured in kg/km2 and is explicitly labelled B_index. No SSB, recruitment time series, N-at-age, F-at-age, or M-at-age output is provided.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.advice.30932321; ',
    'https://asd.ices.dk/viewAdvice/7193; ',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25842; ',
    'https://sg.ices.dk/SAG_API/StockXmlDownload/25842'),
  review_date = '2026-10-31',
  decision_reason = paste('The latest public ICES records are for assessment year 2026, Category 3, using an aggregate biomass-index/advice method. Official source data provide landings and an aggregate B_index with uncertainty, but no age-disaggregated observations or age-specific population outputs. The current unit is ineligible for the age-disaggregated assessment set.'),
  notes = paste('This is a distinct ICES unit, rjc.27.6, covering thornback ray in Subarea 6 (West of Scotland); it is not a duplicate of the other Raja clavata advice units. The official 2026 advice limits landings to 51 tonnes in each of 2027 and 2028 and states that corresponding catches cannot be quantified. The advice PDF, advice record, Standard Graphs source-data page, and SAG XML are cached with provenance under source_cache/discovery_ices_thornback_ray_6_2026. No canonical stock, assessment, input or output records were added.' )
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
  stop('ICES thornback ray candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES thornback ray as ineligible for age-disaggregated source curation.\n')
