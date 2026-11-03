root <- "."
cache <- file.path(root, 'source_cache', 'noaa_north_atlantic_albacore_2023')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '13464', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10950' ||
    as.integer(assessment$assessment_year) != 2023L ||
    as.integer(assessment$last_data_year) != 2022L ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    !grepl('SS', as.character(assessment$assessment_model), fixed = TRUE))
  stop('NOAA Stock SMART metadata do not match the reviewed 2023 North Atlantic albacore record.',
    call. = FALSE)

files <- c('ICCAT_2023_NAtlantic_Albacore_Data_Preparatory_Meeting.pdf',
  'ICCAT_2023_Atlantic_Albacore_Stock_Assessment_Meeting.pdf',
  'ICCAT_2023_NAtlantic_Albacore_SS3_SCRS_2023_107.pdf',
  'ICCAT_2023_NAtlantic_Albacore_SS3_Diagnostics_SCRS_2023_145.pdf',
  'ICCAT_2025_SCRS_Report.pdf',
  'ICCAT_2026_Albacore_Assessment_Meeting_Agenda.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])) ||
    anyNA(manifest$revision[match(files, manifest$file)]) ||
    anyNA(manifest$source_url[match(files, manifest$file)]))
  stop('The North Atlantic albacore source cache is incomplete.', call. = FALSE)
pdf_headers <- vapply(file.path(cache, files), function(path) {
  con <- file(path, 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_headers))
  stop('A cached North Atlantic albacore source is not a PDF.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10950'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one North Atlantic albacore Stock SMART register row.', call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_north_atlantic_albacore',
  assessment_area = 'North Atlantic',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2023 Stock Synthesis assessment uses fleet catches, length compositions, and',
    'sparse spine-age samples. The reviewed material does not establish an annual',
    'catch-numbers-at-age input; a documented reconstruction may be possible but',
    'requires the detailed fleet-year size and age data.'),
  survey_age_evidence = paste('The model includes eight standardized fishery CPUE indices, not a survey index.',
    'Spine-age samples were available for 1990 and 2008-2012 and were assigned to',
    'baitboat in the model because their source fleet was uncertain. No annual',
    'age-specific abundance-index series was verified.'),
  weights_evidence = paste('The model fixes a length-weight relationship (a=1.339e-5, b=3.1066).',
    'A source weight-at-age surface was not identified; reconstruction would require',
    'the fitted growth and length-at-age distribution.'),
  maturity_evidence = paste('The assessment assumes 50% maturity at age 5 (90 cm) and 100% at age 6.'),
  mortality_evidence = paste('The 2023 reference case estimates age-specific M from a Lorenzen curve',
    'anchored at M=0.36 at age 6 under a 15-year maximum-age assumption.'),
  timing_evidence = paste('The model uses four within-year seasons and sets spawning at the beginning of',
    'month 6. CPUE observations are fleet-specific; row-level timing for a tinyAM',
    'index translation was not verified.'),
  output_evidence = paste('The 2023 assessment and later SCRS summaries report aggregate SSB, recruitment,',
    'and fishing-mortality status. Numeric annual N-at-age, F-at-age, and M-at-age',
    'tables were not found in the reviewed public sources.'),
  detailed_source_url = paste(
    'https://www.iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_NALB_DP_ENG.pdf;',
    'https://www.iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_ALB_SA_ENG.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV080_2023/n_3/CV080030279.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV080_2023/n_3/CV080030336.pdf;',
    'https://iccat.int/Documents/Meetings/Docs/2025/Reports/2025_SCRS_ENG.pdf;',
    'https://www.iccat.int/Documents/Meetings/Docs/2026/02859-26_ENG.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10950'),
  review_date = review_date,
  decision_reason = paste('NOAA Stock SMART lists a 2023 full-acceptance North Atlantic albacore assessment',
    '(record 13464) and reports data through 2022. The detailed 2023 ICCAT Stock',
    'Synthesis model paper describes a run through 2021, using catch, eight fishery',
    'CPUE indices, length compositions, and sparse spine-age samples. The difference',
    'in terminal year and the availability of source quantities needed to reconstruct',
    'age-specific observations remain unresolved. Keep this distinct from the North',
    'Pacific albacore unit; no canonical numerical records were added.'),
  notes = paste('The 2025 SCRS report continues to cite the 2023 North Atlantic assessment. The 2026',
    'Albacore meeting agenda covers a South Atlantic assessment and North Atlantic',
    'MSE update, not a new North Atlantic assessment. The Stock SMART last-data-year',
    'value (2022) does not match the detailed Stock Synthesis run endpoint (2021);',
    'resolve this before importing assessment-specific data.'),
  stringsAsFactors = FALSE)

current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) &&
    identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    candidates$import_status[i] == 'not_started' &&
    (is.na(candidates$candidate_unit_id[i]) ||
      !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine)
    stop('Unexpected existing review state for NOAA:10950.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA North Atlantic albacore ID 10950; eligibility remains unresolved pending source age-data recovery.\n')
