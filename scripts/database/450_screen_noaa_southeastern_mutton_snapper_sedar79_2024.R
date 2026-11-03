root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_mutton_snapper_sedar79_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:11342'
unit_id <- 'noaa_southeastern_us_mutton_snapper'

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
  SEDAR79_DW03_size_age.pdf = '843b200db484723946866325018e92ccee13ec31c2c06764bba1153d1d4502ec',
  SEDAR79_DW12_reproduction.pdf = '7cd48111d84c977c23b809a493c1d5982ef440f6d8380a0d18e0e00143abc6e7',
  SEDAR79_DW22_age_growth_mortality.pdf = '6067337943b4d3a747b3d2917c5cbff61a8157120ba950dc207edba9d21d5fa2',
  SEDAR79_final_SAR.pdf = 'a7587c458500b203a7140d5bfdab8524d3017f2a8951d3442130db8b081ee357',
  SEDAR79_project_page.html = 'e8e4a923fc6cb75cb143bff00c965d5a8a65eb4346515b89af3bb2fc1d22628e',
  SEDAR79_SSC_review.pdf = 'b592fc1d9d6460e5f84d92bf15e98c4cb7e2006b1f618778c1f85127629b00e2'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The SEDAR 79 source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached SEDAR 79 source differs from its manifest: ', file, call. = FALSE)
}

project_page <- paste(readLines(file.path(cache, 'SEDAR79_project_page.html'),
  warn = FALSE), collapse = ' ')
if (!grepl('SEDAR 79', project_page, fixed = TRUE) ||
    !grepl('Mutton Snapper', project_page, fixed = TRUE))
  stop('The cached project page does not identify SEDAR 79 Mutton Snapper.', call. = FALSE)

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
    candidates$scientific_name[row] != 'Lutjanus analis' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(candidates$scientific_name[-row] == 'Lutjanus analis', na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == '11342', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('The Southeastern U.S. Mutton Snapper identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  assessment_area = 'Southeastern U.S. single stock spanning Gulf of Mexico and South Atlantic council jurisdictions; Caribbean excluded',
  catch_age_evidence = paste('The SEDAR 79 production model uses catch-weighted length compositions and conditional age-at-length (CAAL), not a direct marginal catch-at-age likelihood.',
    'The final SAR plots CAAL by fleet and year (Section III, Figures 9-12) and fishery-independent CAAL (Figure 17); the Data Workshop report documents annual age samples and sampling coverage.',
    'Annual catch numbers can be reconstructed approximately from the published catch/length inputs and CAAL matrices only after digitizing the figures; the complete numeric model-ready vectors were not found in the public files reviewed.'),
  survey_age_evidence = paste('The base model uses one fishery-dependent commercial longline CPUE index and six fishery-independent indices: three Reef Visual Census series, an age-0 young-of-year index, G-FISHER composite video, and SERFS video.',
    'The indices are aggregate annual series; the report does not provide a complete annual age-specific abundance-index matrix. The age-0 index is recruitment information, not a full age-specific survey surface.'),
  weights_evidence = 'SEDAR 79 SAR Section III Table 10 reports the fixed maximum-total-length-to-whole-weight relationship (a = 6.63e-06, b = 3.1601; kg and cm); growth is estimated in the assessment and supports age-specific weight calculations.',
  maturity_evidence = 'SEDAR 79 SAR Section III Table 10 specifies fixed logistic maturity-at-age with A50 = 3.48 years and a fixed female fraction of 0.5. The SEDAR 79-DW-12 reproduction report documents the underlying maturity analysis.',
  mortality_evidence = 'Natural mortality is fixed from M = 5.4 / tmax at a reference rate of 0.129 per year and scaled by age using the assessment growth relationship; the age-specific values are shown in Section III Table 11.',
  timing_evidence = paste('The assessment is annual, with spawning peaking in June and settlement assigned to January.',
    'The reviewed sources do not provide one common within-year timing fraction for all annual abundance indices; index-specific timing remains to be checked before translation.'),
  output_evidence = paste('SEDAR 79 SAR Section III Table 16 reports annual total biomass, female SSB, total abundance (thousands of fish), age-1 recruitment (thousands of fish), and depletion for 1981-2023.',
    'Table 15 reports annual fleet-specific apical F and combined age-3 F. Numeric annual N-at-age and F-at-age tables were not located; age-specific outputs would require the native report files or cautious figure extraction.'),
  detailed_source_url = paste('https://sedarweb.org/assessments/sedar-79/;',
    'https://sedarweb.org/documents/sedar-79-southeastern-us-mutton-snapper-final-stock-assessment-report/;',
    'https://sedarweb.org/documents/sedar-79-dw-03-size-and-age-information-for-mutton-snapper-lutjanus-analis-collected-in-association-with-fishery-dependent-monitoring-along-floridas-coast/;',
    'https://sedarweb.org/documents/sedar-79-dw-12-mutton-snapper-reproduction/;',
    'https://sedarweb.org/documents/sedar-79-dw-22-descriptions-of-age-growth-and-natural-mortality-of-mutton-snapper-lutjanus-analis-collected-from-fisheries-independent-and-dependent-sources-in-the-southeastern-united-states-fro/;',
    'https://sedarweb.org/documents/gulf-and-sa-ssc-review-of-sedar-79-southeastern-u-s-mutton-snapper/'),
  review_date = '2026-10-31',
  decision_reason = paste('SEDAR 79 is the latest completed detailed production assessment identified for the NOAA Southeastern U.S. unit (Stock SMART 11342), with data through 2023; the joint Gulf and South Atlantic SSCs concluded in March 2025 that the assessment was consistent with best scientific information.',
    'The report provides age-at-length observations, annual catches, biology, aggregate abundance indices, and comparable annual population outputs. The assessment does not fit direct catch-at-age observations, and reproducing age-specific inputs requires digitizing the published fleet/year CAAL and length-composition figures; this limitation is material but source-supported.'),
  notes = paste('The assessment treats Gulf of Mexico and South Atlantic council areas as one closed Southeastern U.S. population; the Caribbean is a separate management stock boundary.',
    'The full final report includes the 2023 terminal year, supporting life-history reports, annual summary outputs, and CAAL figures. A complete run-matched Stock Synthesis data/control archive or exact numeric CAAL matrices were not found during this screen.',
    'Cached documents are under source_cache/discovery_noaa_mutton_snapper_sedar79_2024, with retrieval dates and SHA-256 checksums in sources.csv. No canonical stock, assessment, input, or output records were added; import_status remains not_started.')
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
  stop('NOAA Southeastern U.S. Mutton Snapper candidate already has a conflicting review.',
    call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA Southeastern U.S. Mutton Snapper as eligible for source curation.\n')
