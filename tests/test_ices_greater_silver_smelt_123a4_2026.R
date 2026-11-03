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

candidate_id <- 'ICES:aru.27.123a4'
unit_id <- 'ices_greater_silver_smelt_123a4'
row <- match(candidate_id, register$candidate_id)
stopifnot(!is.na(row))
screened <- register[row, , drop = FALSE]
stopifnot(
  screened$official_stock_id == 'aru.27.123a4',
  screened$scientific_name == 'Argentina silus',
  screened$inventory_assessment_year == 2026,
  screened$candidate_unit_id == unit_id,
  screened$match_status == 'new',
  screened$screening_status == 'screened',
  screened$eligibility == 'ineligible',
  screened$import_status == 'not_started',
  grepl('SPiCT surplus-production', screened$decision_reason, fixed = TRUE),
  grepl('Do not substitute older trend-based advice', screened$decision_reason, fixed = TRUE),
  grepl('biennial acoustic survey biomass index', screened$survey_age_evidence, fixed = TRUE),
  grepl('B/Bmsy and F/Fmsy', screened$output_evidence, fixed = TRUE),
  !any(stocks$authority_stock_id == 'aru.27.123a4', na.rm = TRUE),
  all(!unit_id %in% stocks$stock_id),
  all(!unit_id %in% assessments$assessment_id),
  all(!unit_id %in% inputs$assessment_id),
  all(!unit_id %in% outputs$assessment_id)
)

cache <- file.path(root, 'source_cache',
  'discovery_ices_greater_silver_smelt_123a4_2026')
manifest_path <- file.path(cache, 'sources.csv')
review_path <- file.path(root, 'discovery', 'source_reviews',
  'ices_greater_silver_smelt_123a4_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('SPiCT', review, fixed = TRUE),
  grepl('biennial acoustic biomass index', review, fixed = TRUE),
  grepl('unit field is inconsistent with the ratio label', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input, or output records were added.', review, fixed = TRUE)
)

if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- c(
    'ICES_stock_graphs_2026_key_22376.html',
    'ICES_source_data_2026_key_22376.html',
    'ICES_advice_2026_record_6155.html',
    'ICES_request_2024_SPiCT_benchmark.pdf',
    'Scotland_North_Sea_GSS_FMP_2026_assessment.html')
  urls <- c(
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22376',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22376',
    'https://asd.ices.dk/viewAdvice/6155',
    'https://www.ices.dk/advice/Advice-activities/2024_%20attachements/Norway_request_greater_silver_smelt.pdf',
    'https://www.gov.scot/publications/north-sea-greater-silver-smelt-fisheries-management-plan/pages/10/')
  hashes <- c(
    '3c75d023021b468c63a76d63e4b1eb71ee1581bf7bc6c17f04924456f237d129',
    'd7f4d898cdd98ed0b102092090f4e47a50fd3ad5de1d1012d033615ce7d7c2c1',
    '1496cd9b6b9916adcead95a3a05bb8c3b128b5235488257a74eb1aa92bb6c22d',
    '9c1798674a5c7b6ec1c64895b8e96147d72edd3f6dff0cf67315fc869a72f2fc',
    '384490c7196427d26a2e82da6a754893bcab9cd51cd0115d1515fc97ce68c3f5')
  manifest_rows <- match(files, manifest$file)
  cached <- file.path(cache, files)
  stopifnot(
    nrow(manifest) == 5L,
    !anyDuplicated(manifest$file),
    !anyNA(manifest_rows),
    identical(as.character(manifest$url[manifest_rows]), urls),
    identical(as.character(manifest$sha256[manifest_rows]), hashes),
    all(file.exists(cached)),
    all(file.info(cached)$size == manifest$bytes[manifest_rows]),
    all(manifest$retrieved_on[manifest_rows] == '2026-10-30')
  )
}

cat('ICES Greater silver smelt identity, current assessment, source provenance, and no-import checks passed.\n')
