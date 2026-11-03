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
candidate <- register[register$candidate_id == 'ICES:sbr.27.9', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_blackspot_seabream_9_2026.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_ices_blackspot_seabream_9_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- c('ICES_advice_2026_record_7185.html', 'ICES_stock_graphs_2026_key_23734.html',
  'ICES_source_data_2026_key_23734.html', 'ICES_WKBSS3_2025_report.pdf',
  'ICES_sbr_27_9_2026_working_documents.pdf', 'ICES_WKBSS3_figshare_metadata.json')

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'sbr.27.9',
  candidate$scientific_name == 'Pagellus bogaraveo',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$candidate_unit_id == 'ices_blackspot_seabream_9',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('explicitly states that no age data are available', candidate$catch_age_evidence, fixed = TRUE),
  grepl('no age-specific survey index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('EmpiricalWAA=0', candidate$weights_evidence, fixed = TRUE),
  grepl('borrowed its maturity ogive', candidate$maturity_evidence, fixed = TRUE),
  grepl('M=0.275 scaled to age 4', candidate$mortality_evidence, fixed = TRUE),
  grepl('aggregate recruitment, SSB, and F time series', candidate$output_evidence, fixed = TRUE),
  grepl('earlier run', candidate$decision_reason, fixed = TRUE),
  grepl('does not assert that unreviewed age samples do not exist', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == length(files),
  !anyDuplicated(manifest$file),
  all(files %in% manifest$file),
  all(file.exists(file.path(cache, files))),
  all(file.info(file.path(cache, files))$size == manifest$bytes[match(files, manifest$file)]),
  all(nchar(manifest$sha256[match(files, manifest$file)]) == 64L),
  !any(tolower(stocks$authority_stock_id) == 'sbr.27.9', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_blackspot_seabream_9', na.rm = TRUE),
  !any(inputs$assessment_id == 'ices_blackspot_seabream_9', na.rm = TRUE),
  !any(outputs$assessment_id == 'ices_blackspot_seabream_9', na.rm = TRUE),
  grepl('no age data were available for the Portuguese and northern Spanish coasts', review, fixed = TRUE),
  grepl('landings only for 2003–2025', review, fixed = TRUE),
  grepl('No tinyAM translation was attempted.', review, fixed = TRUE)
)

cat('ICES blackspot seabream identity, latest-versus-benchmark evidence, provenance, and no-import checks passed.\n')
