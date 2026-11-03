root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate_id <- 'ICES:ane.27.8'
unit_id <- 'ices_bay_biscay_anchovy_8'
row <- match(candidate_id, register$candidate_id)
stopifnot(!is.na(row))
screened <- register[row, , drop = FALSE]
stopifnot(
  screened$official_stock_id == 'ane.27.8',
  screened$scientific_name == 'Engraulis encrasicolus',
  screened$inventory_assessment_year == 2025,
  screened$candidate_unit_id == unit_id,
  screened$match_status == 'new',
  screened$screening_status == 'screened',
  screened$eligibility == 'eligible',
  screened$import_status == 'not_started',
  grepl('2025 Stock Synthesis run used for 2026 ICES advice', screened$decision_reason, fixed = TRUE),
  grepl('2025 fishery observations are provisional', screened$catch_age_evidence, fixed = TRUE),
  grepl('M0=2.17, M1=0.80, M2=1.20, and M3+=2.26', screened$mortality_evidence, fixed = TRUE),
  grepl('15 May', screened$timing_evidence, fixed = TRUE),
  grepl('N-at-age', screened$output_evidence, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'ane.27.8', na.rm = TRUE),
  all(!unit_id %in% stocks$stock_id),
  all(!unit_id %in% assessments$assessment_id),
  all(!unit_id %in% inputs$assessment_id),
  all(!unit_id %in% outputs$assessment_id)
)
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_bay_biscay_anchovy_2025.md'), warn = FALSE), collapse = ' ')
stopifnot(
  grepl('eligible for source curation', review, fixed = TRUE),
  grepl('BIOMAN spring DEPM survey', review, fixed = TRUE),
  grepl('age-0 settlement 1 July', review, fixed = TRUE),
  grepl('No canonical numerical records are added', review, fixed = TRUE)
)

cache <- file.path(root, 'source_cache', 'discovery_ices_bay_biscay_anchovy_2025')
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- c('WGHANSA_2025_Report.pdf', 'ICES_stock_annex_ane_27_8_2026.pdf',
    'WKBANSP_2024_v2.pdf', 'WGACEGG_2025_Report.pdf',
    'ICES_stock_graphs_2025_key_21265.html', 'ICES_source_data_2025_key_21265.html',
    'ICES_advice_2026_record_4005.html')
  urls <- c('https://ndownloader.figshare.com/files/62700859',
    'https://ndownloader.figshare.com/files/55501253',
    'https://ndownloader.figshare.com/files/52237436',
    'https://ndownloader.figshare.com/files/62338852',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=21265',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265',
    'https://asd.ices.dk/viewAdvice/4005')
  rows <- match(files, manifest$file)
  stopifnot(nrow(manifest) == length(files), !anyDuplicated(manifest$file), !anyNA(rows),
    identical(as.character(manifest$url[rows]), urls),
    all(manifest$retrieved_on[rows] == '2026-10-30'),
    all(file.exists(file.path(cache, files))),
    all(file.info(file.path(cache, files))$size == manifest$bytes[rows]))
}
cat('ICES Bay of Biscay anchovy identity, source screen, evidence, and no-import checks passed.\n')