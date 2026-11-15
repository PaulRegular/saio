root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_path <- file.path(root, 'source_cache', 'discovery_dfo_wcvi_chinook_2024')

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'DFO:Pacific:Chinook Salmon - West Coast of Vancouver Island'
candidate_unit_id <- 'dfo_chinook_wcvi_natural_origin'
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L) {
  stop('WCVI Chinook candidate is missing or duplicated.', call. = FALSE)
}
if (!identical(register$stock_name[row], 'Chinook Salmon - West Coast of Vancouver Island')) {
  stop('WCVI Chinook inventory identity has changed.', call. = FALSE)
}

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
if (any(stocks$scientific_name == 'Oncorhynchus tshawytscha', na.rm = TRUE)) {
  stop('A canonical Chinook stock exists; review identity before updating.', call. = FALSE)
}
if (any(grepl('wcvi_chinook|west_coast_vancouver_island_chinook',
    c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    ignore.case = TRUE), na.rm = TRUE)) {
  stop('Unexpected canonical WCVI Chinook assessment records were found.', call. = FALSE)
}

sources_path <- file.path(cache_path, 'sources.csv')
if (file.exists(sources_path)) {
  sources <- read.csv(sources_path, stringsAsFactors = FALSE)
  if (nrow(sources) != 4L || any(!file.exists(file.path(cache_path, sources$file)))) {
    stop('Cached WCVI Chinook source files are incomplete.', call. = FALSE)
  }
}

review <- list(
  candidate_unit_id = candidate_unit_id,
  scientific_name = 'Oncorhynchus tshawytscha',
  inventory_assessment_year = '2024',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 assessment uses catch and escapement totals with biological samples in terminal run reconstructions. The report does not establish a complete CU-specific fishery catch-at-age series for natural-origin Chinook.'),
  survey_age_evidence = paste(
    'Spawner abundance is compiled from river escapement and run-reconstruction programmes; no age-specific survey index for the natural-origin SMU was identified.'),
  weights_evidence = paste(
    'The report and supporting repository include adult biological samples and body-size data, but a complete age-, origin-, and year-aligned weight series for the assessment unit has not been verified.'),
  maturity_evidence = paste(
    'Age-at-maturity and age-specific maturation information are available primarily from the Robertson Creek Hatchery indicator; its representativeness for natural-origin populations is uncertain.'),
  mortality_evidence = paste(
    'The report presents age-specific cohort exploitation estimates for the Robertson Creek Hatchery indicator. Robust CU-specific exploitation histories for natural-origin Chinook are not available; annual natural mortality inputs were not identified.'),
  timing_evidence = paste(
    'The assessment combines annual catch and escapement programmes with monthly catch estimates in some terminal fisheries. A single within-year survey timing for an age-specific index is not established.'),
  output_evidence = paste(
    'The report provides aggregate abundance, spawner and recruitment information, and hatchery-indicator cohort exploitation estimates. It does not provide a conventional annual natural-origin N-at-age/F-at-age assessment surface.'),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-020-eng.pdf',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41293964.pdf',
    'https://github.com/SCA-stock-assess/WCVI-CN-ResDoc/tree/f6b643e5672374cb34bc7a99d6ff9151b69ce325',
    'https://github.com/SCA-stock-assess/WCVI_CN_TermRunRecon/tree/20053469c8c8416b5bb56cd7a858e4928f7fec16',
    sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The current unit is a natural-origin Chinook SMU with three CUs. The detailed report and supporting repositories document age samples and run reconstruction, but do not yet verify complete, aligned annual age-specific catch, abundance, and biological series for this unit.',
    'CU-specific catch/exploitation histories are explicitly limited; Robertson Creek hatchery cohort estimates are not equivalent to natural-origin SMU outputs. Keep eligibility unresolved pending age, origin, and year-coverage review.'),
  notes = paste(
    'New candidate unit identified from the DFO Pacific stock inventory; no canonical database records were added.',
    'The 2024 stock assessment was published as DFO Research Document 2026/020. The source-cache manifest records the locally retained response and selected support files.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- identical(as.character(register$match_status[row]), review$match_status) &&
  identical(as.character(register$screening_status[row]), review$screening_status) &&
  identical(as.character(register$eligibility[row]), review$eligibility) &&
  identical(ifelse(is.na(register$candidate_unit_id[row]), '', register$candidate_unit_id[row]),
    review$candidate_unit_id)
if (!initial && !reviewed) stop('WCVI Chinook has an unexpected prior review state.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  for (name in names(review)) register[[name]][row] <- review[[name]]
  tmp <- tempfile(fileext = '.csv')
  write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}

cat("Screened DFO's 2024 WCVI Chinook assessment; age-input eligibility remains unresolved pending alignment and coverage review.\n")
