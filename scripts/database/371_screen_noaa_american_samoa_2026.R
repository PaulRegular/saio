root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_american_samoa_2026')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

expected_sources <- data.frame(
  file = c('american_samoa_2023_assessment.pdf', 'american_samoa_2026_wpsar_review.pdf'),
  sha256 = c('632D0AA67C8FB99931EBCAEE981137BEA0DD66A76194AF11D232BF9DB80868DD',
    'D539CC84F200BC22FB281A93E7EB11EED38F92C403F4F8D40BC5D9EE03AA2516'),
  stringsAsFactors = FALSE
)
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected_sources))) {
  source_row <- match(expected_sources$file[i], manifest$file)
  path <- file.path(cache_dir, expected_sources$file[i])
  if (!file.exists(path) || is.na(source_row) ||
      manifest$sha256[source_row] != expected_sources$sha256[i] ||
      sha256_file(path) != expected_sources$sha256[i]) {
    stop('A pinned American Samoa source is missing or differs from its manifest: ',
      expected_sources$file[i], call. = FALSE)
  }
}

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (sha256_file(stocksmart_path) !=
    'AD47F9EEB240C2E77B2B952809A12C4FA739E3F0D39BEAB283B413FDBAEF76A8') {
  stop('The pinned NOAA Stock SMART snapshot is missing or changed.', call. = FALSE)
}
stocksmart_env <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
expected_stocksmart <- data.frame(
  stock_id = c(11695L, 11695L, 11997L, 11998L, 11999L, 12003L, 12005L, 12007L,
    12011L, 12013L, 12215L),
  assessment_year = c(2015L, 2019L, rep(2023L, 9L)),
  last_data_year = c(2013L, 2017L, rep(2021L, 9L)),
  assessment_model = c('PIFSC Bayesian surplus production model with MSY prior\n',
    'JABBA', rep('SS', 9L)),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(expected_stocksmart))) {
  row <- stocksmart[stocksmart$stock_id == expected_stocksmart$stock_id[i] &
    stocksmart$assessment_year == expected_stocksmart$assessment_year[i], , drop = FALSE]
  if (nrow(row) != 1L || row$last_data_year != expected_stocksmart$last_data_year[i] ||
      row$assessment_model != expected_stocksmart$assessment_model[i] ||
      row$science_center != 'PIFSC' || row$review_result != 'Full acceptance') {
    stop('The pinned NOAA Stock SMART snapshot does not match the reviewed Samoa entry: ',
      expected_stocksmart$stock_id[i], call. = FALSE)
  }
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

current_process <- paste(
  'The official 2026 Stock Synthesis update fits this species using aggregate catch',
  '(historical 1967-1985 and creel-survey catch 1986-2025), an aggregate standardized',
  'boat-based creel CPUE index (2016-2025), and length compositions from creel surveys',
  'and biosampling. The report documents no catch-at-age or age-composition likelihood;',
  'age structures are reconstructed internally from growth and length data.'
)
prior_process <- paste(
  'The 2023 Stock Synthesis species assessment used aggregate catch, an aggregate',
  'boat-based creel CPUE index, and length compositions. The report documents no',
  'catch-at-age or age-composition likelihood; age structures are reconstructed',
  'internally from growth and length data.'
)
current_survey <- paste(
  'The standardized abundance index is aggregate boat-based creel CPUE for bottomfishing',
  'gear, 2016-2025; it is not age-specific. The update does not document an age-specific',
  'survey series.'
)
prior_survey <- paste(
  'The standardized abundance index is aggregate boat-based creel CPUE for bottomfishing',
  'gear, 2016-2021; it is not age-specific. The 2023 report does not document an',
  'age-specific survey series.'
)
weights <- paste(
  'The assessment uses a fixed weight-at-length relationship to convert catch and',
  'length observations. No observed weight-at-age series or age-specific weight input',
  'is documented.'
)
maturity <- paste(
  'Maturity and fecundity are fixed life-history relationships by length and weight;',
  'female mature biomass defines SSB. No maturity-at-age input series is documented.'
)
mortality <- paste(
  'Natural mortality is fixed, constant with age, and derived from longevity using the',
  'Hamel-Cope relationship. No estimated age-specific M series is documented.'
)
timing <- paste(
  'Catch and standardized CPUE are annual. The report describes spawning and recruitment',
  'in the first month of the year, but does not provide a fractional-year timing for an',
  'age-specific observation; the only index is aggregate CPUE.'
)
current_output <- paste(
  'Species reports provide annual SSB, age-0 recruitment, and instantaneous annual F',
  'through 2025 with CVs. They do not provide numeric N-at-age or F-at-age time series.'
)
prior_output <- paste(
  'The 2023 species report provides annual SSB, age-0 recruitment, and instantaneous',
  'annual F through 2021 with CVs, but no numeric N-at-age or F-at-age time series.',
  'Those results are not substituted for a current-unit assessment.'
)

species <- data.frame(
  candidate_id = c('NOAA:11997', 'NOAA:11998', 'NOAA:12003', 'NOAA:12005',
    'NOAA:11999', 'NOAA:12007', 'NOAA:12011', 'NOAA:12013', 'NOAA:12215'),
  candidate_unit_id = c('noaa_american_samoa_etco', 'noaa_american_samoa_apru',
    'noaa_american_samoa_prfl', 'noaa_american_samoa_przo',
    'noaa_american_samoa_apvi', 'noaa_american_samoa_calu',
    'noaa_american_samoa_valo', 'noaa_american_samoa_leru',
    'noaa_american_samoa_luka'),
  scientific_name = c('Etelis coruscans', 'Aphareus rutilans',
    'Pristipomoides flavipinnis', 'Pristipomoides zonatus', 'Aprion virescens',
    'Caranx lugubris', 'Variola louti', 'Lethrinus rubrioperculatus', 'Lutjanus kasmira'),
  current_2026 = c(TRUE, TRUE, TRUE, TRUE, rep(FALSE, 5L)),
  stringsAsFactors = FALSE
)

review_rows <- lapply(seq_len(nrow(species)), function(i) {
  current <- species$current_2026[i]
  list(
    candidate_unit_id = species$candidate_unit_id[i],
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = if (current) current_process else prior_process,
    survey_age_evidence = if (current) current_survey else prior_survey,
    weights_evidence = weights,
    maturity_evidence = maturity,
    mortality_evidence = mortality,
    timing_evidence = timing,
    output_evidence = if (current) current_output else prior_output,
    detailed_source_url = paste(
      'https://repository.library.noaa.gov/view/noaa/74402/noaa_74402_DS1.pdf',
      'https://www.wpcouncil.org/wp-content/uploads/2026/04/09.E.21-WPSAR-for-AS-Bottomfish-stock-assessment-2026-update-Summary-Report-and-Individual-Reports.pdf',
      'https://repository.library.noaa.gov/view/noaa/50907/noaa_50907_DS1.pdf',
      'https://apps-st.fisheries.noaa.gov/stocksmart', sep = '; '),
    review_date = '2026-10-30',
    decision_reason = if (current) paste(
      'The latest official update is the WPSAR-reviewed 2026 Stock Synthesis model using',
      'data through 2025. It estimates age-structured population states but fits catch,',
      'aggregate CPUE, and length compositions, not observed age-specific population',
      'inputs. No age-specific survey index or numeric age-specific output series is',
      'documented, so this is ineligible for the age-disaggregated input set.') else paste(
      'The 2026 update narrowed the assessed BMUS list and did not refit this species.',
      'Its 2023 assessment is not a current-unit substitute. The prior model also used',
      'aggregate catch and CPUE plus length compositions rather than observed age-specific',
      'population inputs; the entry is ineligible for the current age-disaggregated set.'),
    notes = if (current) paste(
      'Stock SMART lists the 2023 assessment through 2021 with Full acceptance status;',
      'the newer official 2026 update uses data through 2025 and was reviewed by WPSAR',
      'on 2026-05-18/19. It models this species separately. The 2026 WPSAR review found',
      'the update suitable for management and as best scientific information available.',
      'No canonical records were added.') else paste(
      'The 2023 Stock Synthesis assessment is the latest detailed species result',
      'in the pinned Stock SMART snapshot, but this species is outside the revised six-',
      'species BMUS list used by the 2026 update. Treat as a legacy assessment entry, not',
      'a current assessment candidate. No canonical records were added.')
  )
})
names(review_rows) <- species$candidate_id

legacy_id <- 'NOAA:11695'
legacy_row <- which(register$candidate_id == legacy_id)
if (length(legacy_row) != 1L) stop('Expected one American Samoa complex row.', call. = FALSE)
legacy_review <- list(
  candidate_unit_id = NA_character_,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest Stock SMART entry is a 2019 aggregate JABBA surplus-production model',
    'using total catch and aggregate CPUE; it does not fit catch-at-age. The 2023',
    'benchmark replaced the complex with species-specific Stock Synthesis assessments,',
    'and the 2026 update further revised the assessed species list.'),
  survey_age_evidence = paste(
    'The 2019 assessment used aggregate CPUE; no age-specific survey index is documented.',
    'Later assessments use aggregate boat-based creel CPUE, also not age-specific.'),
  weights_evidence = 'No weight-at-age input was used in the aggregate 2019 assessment.',
  maturity_evidence = 'No maturity-at-age input was used in the aggregate 2019 assessment.',
  mortality_evidence = paste(
    'The aggregate 2019 JABBA assessment did not estimate age-specific M. Later species',
    'models use fixed life-history mortality assumptions.'),
  timing_evidence = 'The aggregate 2019 catch and CPUE series are annual; age-specific timing is not applicable.',
  output_evidence = paste(
    'The 2019 complex report provides aggregate biomass and harvest-rate outputs, not',
    'age-specific quantities. It is superseded by species-specific assessments.'),
  detailed_source_url = paste(
    'https://repository.library.noaa.gov/view/noaa/21164/noaa_21164_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/50907/noaa_50907_DS1.pdf',
    'https://repository.library.noaa.gov/view/noaa/74402/noaa_74402_DS1.pdf',
    'https://apps-st.fisheries.noaa.gov/stocksmart', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The 2019 aggregate complex was replaced by species-specific models in 2023 and a',
    'revised species list in 2026. This one-to-many boundary change cannot be linked to',
    'a single current candidate unit. The old aggregate model is not eligible for the',
    'current age-disaggregated set.'),
  notes = paste(
    'NOAA Stock SMART ID 11695 is the former American Samoa multispecies complex; its',
    'latest row is the 2019 JABBA model through 2017 with Full acceptance status.',
    'The 2023 shift to species-specific assessments split this historical complex across',
    'species units. Its current one-to-many crosswalk is unresolved, so candidate_unit_id',
    'remains blank. No canonical records were added.')
)
review_rows[[legacy_id]] <- legacy_review

candidate_ids <- c(legacy_id, species$candidate_id)
rows <- match(candidate_ids, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows)) stop('American Samoa candidate IDs are missing or duplicated.',
  call. = FALSE)
if (any(!is.na(register$matched_stock_id[rows]) & nzchar(register$matched_stock_id[rows]))) {
  stop('An American Samoa candidate has a canonical stock match requiring review.', call. = FALSE)
}
for (i in seq_along(rows)) {
  current_units <- register$candidate_unit_id[-rows[i]]
  proposed_unit <- review_rows[[candidate_ids[i]]]$candidate_unit_id
  if (!is.na(proposed_unit) && nzchar(proposed_unit) &&
      any(current_units == proposed_unit, na.rm = TRUE)) {
    stop('Candidate unit key already belongs to another inventory row: ', proposed_unit,
      call. = FALSE)
  }
}

database_stock_names <- paste(stocks$common_name, stocks$scientific_name, stocks$area, collapse = ' ')
if (grepl('American Samoa', database_stock_names, ignore.case = TRUE) ||
    any(grepl('American Samoa', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE) ||
    any(grepl('American Samoa', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE) ||
    any(grepl('American Samoa', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE)) {
  stop('Unexpected American Samoa canonical records found; review matching before updating.',
    call. = FALSE)
}

initial <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
}, logical(1L))
reviewed <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  review <- review_rows[[candidate_ids[i]]]
  identical(as.character(register$match_status[row]), review$match_status) &&
    identical(as.character(register$screening_status[row]), review$screening_status) &&
    identical(as.character(register$eligibility[row]), review$eligibility) &&
    identical(ifelse(is.na(register$candidate_unit_id[row]), '', register$candidate_unit_id[row]),
      ifelse(is.na(review$candidate_unit_id), '', review$candidate_unit_id))
}, logical(1L))
if (any(!initial & !reviewed)) stop('An American Samoa candidate has an unexpected prior review state.',
  call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && any(initial)) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  for (i in which(initial)) {
    row <- rows[i]
    for (name in names(review_rows[[candidate_ids[i]]])) {
      register[[name]][row] <- review_rows[[candidate_ids[i]]][[name]]
    }
    tmp <- tempfile(fileext = '.csv')
    write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
    lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
    unlink(tmp)
  }
  writeLines(lines, register_path, useBytes = TRUE)
}

cat('Screened the former American Samoa complex and nine species entries against the 2026 update; age-specific input eligibility is ineligible.\n')
