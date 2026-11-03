root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_seabass_8c9a_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:bss.27.8c9a'
unit_id <- 'ices_seabass_8c9a'

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
  ICES_2025_advice.html = '3cf3266056c5fa4a81d4dab1043459e5b144598faed7e7cc2397d515d84315f7',
  SAG_2025_charts.html = '846143461c427402019a4492de48f56b37f4a085ae8ed9f81cf1b9c203acddef',
  SAG_2025_source_data.html = '514e9a7d60963871b9238c8395f501c6f698cfb8ec42dac6e40db1dd32f0b81d',
  SAG_2025_stock.xml = '5d0299fd4a42b498e17202f09b915ce2607a3b9ee884aa7cc180748b97d1ef45'
)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The seabass source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached seabass source differs from its manifest: ', file, call. = FALSE)
}

advice <- paste(readLines(file.path(cache, 'ICES_2025_advice.html'), warn = FALSE),
  collapse = ' ')
charts <- paste(readLines(file.path(cache, 'SAG_2025_charts.html'), warn = FALSE),
  collapse = ' ')
source_data <- paste(readLines(file.path(cache, 'SAG_2025_source_data.html'), warn = FALSE),
  collapse = ' ')
stock_xml <- paste(readLines(file.path(cache, 'SAG_2025_stock.xml'), warn = FALSE),
  collapse = ' ')
if (!all(vapply(c('bss.27.8c9a', 'Assessment Year', '2025',
    'Stock Category', '>5<',
    'commercial catches in each of the years 2026, 2027 and 2028 should be no more than 306 tonnes'),
    grepl, logical(1L), x = advice, fixed = TRUE)) ||
    !all(vapply(c('bss.27.8c9a', 'Assessment Year', '2025', '19602'),
      grepl, logical(1L), x = charts, fixed = TRUE)) ||
    !all(vapply(c('bss.27.8c9a', '2025', '19602', 'Landings', 'tonnes', '1978', '2024'),
      grepl, logical(1L), x = source_data, fixed = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2025</AssessmentYear>',
      '<StockCode>bss.27.8c9a</StockCode>', '<StockCategory>5</StockCategory>',
      '<ModelType>None</ModelType>', '<Fage></Fage>', '<RecruitmentAge></RecruitmentAge>'),
      grepl, logical(1L), x = stock_xml, fixed = TRUE)) ||
    grepl('<StockSize>[^<]+</StockSize>', stock_xml) ||
    grepl('<Recruitment>[^<]+</Recruitment>', stock_xml) ||
    grepl('<FishingPressure>[^<]+</FishingPressure>', stock_xml))
  stop('The cached ICES sources do not support the documented seabass screen.', call. = FALSE)

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
neighbor <- match('ICES:bss.27.8ab', candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    is.na(neighbor) || candidates$official_stock_id[row] != 'bss.27.8c9a' ||
    candidates$scientific_name[row] != 'Dicentrarchus labrax' ||
    candidates$candidate_unit_id[neighbor] != 'ices_seabass_8ab' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'bss.27.8c9a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('ICES seabass 8.c/9.a identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Divisions 8.c and 9.a (southern Bay of Biscay and Atlantic Iberian waters)',
  catch_age_evidence = 'The 2025 ICES source-data table and XML report annual landings in tonnes for 1978-2024 only. No catch-at-age or age-composition series is provided; the advice database classifies the unit as Category 5.',
  survey_age_evidence = 'The current category-5 advice and published source-data/XML contain no survey index or age-specific survey observations.',
  weights_evidence = 'The 2025 source set provides no age-specific stock or catch weights.',
  maturity_evidence = 'The 2025 source set provides no maturity-at-age series.',
  mortality_evidence = 'The 2025 source XML has no age-specific F series; no quantitative age-specific natural-mortality assumptions are reported for this landings-only advice.',
  timing_evidence = 'No age-specific survey observation is used or reported in the current category-5 source set, so survey timing is not available.',
  output_evidence = 'The 2025 advice gives a commercial-catch limit of 306 tonnes for each of 2026-2028. The SAG XML contains a 1978-2024 landings series but empty recruitment, stock-size, and fishing-pressure fields; no numeric SSB, recruitment, N-at-age, F-at-age, or M-at-age output was recovered.',
  detailed_source_url = paste('https://asd.ices.dk/viewAdvice/3920;',
    'https://doi.org/10.17895/ices.advice.27202533;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=19602;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19602;',
    'https://sag.ices.dk/SAG_API/StockXmlDownload/19602'),
  review_date = '2026-10-31',
  decision_reason = 'The latest ICES advice located is assessment year 2025, Category 5. Official advice limits commercial catches to 306 tonnes in each of 2026-2028; the published source table/XML contains annual landings only and no numeric age-structured population outputs. The latest public source set does not meet the age-disaggregated input and output screen.',
  notes = 'This is a distinct official ICES unit, bss.27.8c9a (southern Bay of Biscay and Atlantic Iberian waters), separate from the northern/central Bay of Biscay unit bss.27.8ab. The two units share a broad ecoregion but have different official boundaries and advice. ICES category 5 is landings-only. The XML generic metadata labels stock size as SSB but its annual stock-size values are empty; do not infer an SSB series. Advice, charts, source-data HTML and XML are cached with provenance under source_cache/discovery_ices_seabass_8c9a_2025. No canonical stock, assessment, input or output records were added.'
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
  stop('ICES seabass 8.c/9.a candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES seabass in divisions 8.c and 9.a as ineligible for age-disaggregated source curation.\n')
