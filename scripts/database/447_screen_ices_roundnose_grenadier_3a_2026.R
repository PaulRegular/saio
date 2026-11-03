root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_roundnose_grenadier_3a_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rng.27.3a'
unit_id <- 'ices_roundnose_grenadier_3a'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
expected <- c(
  ICES_2026_advice.html = 'ecc1c8eb6136f45fc4c474c2dba7ec1a2c3d3728f28565d9c62f3d62e41c4655',
  SAG_2026_charts.html = '3abe999fe9046372bae1fdefa2da1a6859429d996ba1ac1c45a60e9af723b1ba',
  SAG_2026_source_data.html = '0ba8907f6c2395c1943268eed9401ffaecb7e38d6ba14bcbb48b1e22eb04c6ae',
  SAG_2026_stock.xml = 'aff2eeb925a8412481f3bfa8d22c27dfb119cd6c755b04612f9e0c0e16194d86'
)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The roundnose-grenadier source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached roundnose-grenadier source differs from its manifest: ', file, call. = FALSE)
}

advice <- paste(readLines(file.path(cache, 'ICES_2026_advice.html'), warn = FALSE),
  collapse = ' ')
charts <- paste(readLines(file.path(cache, 'SAG_2026_charts.html'), warn = FALSE),
  collapse = ' ')
source_data <- paste(readLines(file.path(cache, 'SAG_2026_source_data.html'), warn = FALSE),
  collapse = ' ')
stock_xml <- paste(readLines(file.path(cache, 'SAG_2026_stock.xml'), warn = FALSE),
  collapse = ' ')
if (!all(vapply(c('rng.27.3a', 'Assessment Year', '2026', 'Stock Category', '3.2',
    'zero catch in each of the years 2027 and 2028'), grepl, logical(1L),
    x = advice, fixed = TRUE)) ||
    !all(vapply(c('id="lblStockCode" class="text">rng.27.3a</span>',
      'id="lblYear" class="text">2026</span>', 'id="lblKey" class="text">22371</span>',
      'B_index'), grepl, logical(1L), x = charts, fixed = TRUE)) ||
    !all(vapply(c('rng.27.3a', 'Assessment Year:', '2026', 'B_index',
      'Kilograms per hour', 'Age and Length', '<Fage></Fage>',
      '<RecruitmentAge></RecruitmentAge>'), grepl, logical(1L),
      x = paste(source_data, stock_xml), fixed = TRUE)) ||
    grepl('<Fage>[^<]+</Fage>', stock_xml) || grepl('<RecruitmentAge>[^<]+</RecruitmentAge>', stock_xml))
  stop('The cached ICES sources do not support the documented roundnose-grenadier screen.',
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
    candidates$official_stock_id[row] != 'rng.27.3a' ||
    candidates$scientific_name[row] != 'Coryphaenoides rupestris' ||
    !candidates$assessment_area[row] %in% c('Greater North Sea',
      'Division 3.a (Skagerrak and Kattegat)', 'Division 3.a (Skagerrak, Kattegat)') ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'rng.27.3a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('ICES roundnose-grenadier Division 3.a identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Division 3.a (Skagerrak, Kattegat)',
  catch_age_evidence = 'The 2026 ICES stock-graph source reports total landings and discards by year, not catch-at-age. No age composition is reported in the current public stock data.',
  survey_age_evidence = 'The current 2026 source reports one aggregate B_index with annual uncertainty in kg per hour; it is not an age-specific abundance index or age composition.',
  weights_evidence = 'No age-specific weights are reported in the current advice or stock-graph source data.',
  maturity_evidence = 'No maturity-at-age values are reported in the current advice or stock-graph source data.',
  mortality_evidence = 'The 2026 advice and stock-graph metadata provide no F-at-age or quantitative natural-mortality series; fishing-pressure metadata and Fage are blank.',
  timing_evidence = 'The current public sources do not report a fractional within-year timing for the aggregate survey B_index.',
  output_evidence = 'The 2026 ICES source reports B_index (kg/hour) and total landings/discards, not SSB, recruitment, N-at-age, F-at-age, or M-at-age. Although the generic source-data table labels its index columns Low SSB / SSB / High SSB, the stock metadata explicitly identifies the series as B_index.',
  detailed_source_url = paste('https://asd.ices.dk/viewAdvice/7200;',
    'https://doi.org/10.17895/ices.advice.30932369;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22371;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22371;',
    'https://sag.ices.dk/SAG_API/StockXmlDownload/22371'),
  review_date = '2026-10-31',
  decision_reason = 'The latest official advice located is assessment year 2026, category 3.2, with advice for zero catch in 2027-2028. The current SAG source reports an aggregate B_index and total landings/discards; its age/recruitment and F-age metadata are empty. The published current source set does not meet the age-disaggregated input and output screen.',
  notes = 'This is a distinct Division 3.a unit, not the Oceanic Northeast Atlantic roundnose grenadier unit rng.27.5a10b12ac14b. The source-graph metadata identifies the stock-size series as B_index; do not interpret its generic Low SSB / SSB / High SSB columns as spawning-stock biomass. Advice, chart, source-data HTML, and XML are cached with provenance under source_cache/discovery_ices_roundnose_grenadier_3a_2026. No canonical stock, assessment, input, or output records were added.'
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
  stop('ICES roundnose-grenadier Division 3.a candidate already has a conflicting review.',
    call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES roundnose grenadier in Division 3.a as ineligible for age-structured source curation.\n')
