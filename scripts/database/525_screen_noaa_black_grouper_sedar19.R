root <- "."
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_black_grouper_sedar19')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
expected <- c('SEDAR19_Black_Grouper_Final_Assessment_Report.pdf',
  'SAFMC_Black_Grouper_Management_Procedure_Report_2026.pdf',
  'SEDAR19_DW09_Black_Grouper_Age_Growth_Maturity.pdf')
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      file.info(path)$size != as.numeric(manifest$bytes[i]))
    stop('A pinned black grouper source is missing or differs from its manifest: ', file, call. = FALSE)
}

e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'), e)
s <- e$stock_assessment_summary
s <- s[as.character(s$stock_id) == '14148', , drop = FALSE]
if (nrow(s) != 1L || s$assessment_id != 5223L || s$assessment_year != 2010L ||
    s$last_data_year != 2008L || s$science_center != 'SEFSC' ||
    !grepl('Age Structured Assessment Program Model', s$assessment_model, fixed = TRUE) ||
    s$model_version != 'Version 2.0.19' || s$review_result != 'Full acceptance')
  stop('Stock SMART no longer identifies NOAA:14148 as reviewed.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:14148'
unit_id <- 'noaa_black_grouper_south_atlantic_gulf'
row <- which(register$candidate_id == id)
if (length(row) != 1L ||
    any(grepl('Mycteroperca bonaci', stocks$scientific_name, fixed = TRUE), na.rm = TRUE) ||
    any(grepl('Black grouper', stocks$common_name, ignore.case = TRUE), na.rm = TRUE))
  stop('Black grouper identity conflicts with the register or canonical database.', call. = FALSE)
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Black grouper candidate-unit key conflicts with another candidate.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  scientific_name = 'Mycteroperca bonaci',
  assessment_area = 'South Atlantic and Gulf of Mexico',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('SEDAR 19 used an ASAP2 statistical catch-at-age model with age compositions. The final report says commercial catch-at-age is handled within the model but does not provide the complete numerical fleet-by-year inputs or age-composition likelihood data. Longline age samples are absent for 1986-1991.'),
  survey_age_evidence = paste('The final report summary mentions five indices including an FWC visual-survey age-1 index, but its post-review base-run note excludes the RVC and FWC visual indices; the 2026 overview describes eight indices. The final accepted index set is unresolved pending final-run files or tables.'),
  weights_evidence = paste('The final assessment report documents age-specific weight inputs and corrects the longline discard weight-at-age in Table A2.1.2.'),
  maturity_evidence = paste('The final assessment report provides age-specific female and male maturity summaries and documents the maturity and sex-transition biology used for this protogynous species.'),
  mortality_evidence = paste('The final assessment report provides age-specific natural-mortality life-history values and documents alternative mortality estimates.'),
  timing_evidence = paste('The assessment is annual; a within-year timing fraction for the final accepted abundance-index set was not verified.'),
  output_evidence = paste('The final report provides beginning-of-year population numbers-at-age and stock biomass-at-age for 1986-2008, ages 1-20+ (Table A3.3.4.9), plus fishing mortality at age and aggregate spawning-biomass and recruitment results.'),
  detailed_source_url = paste('https://sedarweb.org/documents/sedar-19-final-stock-assessment-report-south-atlantic-and-gulf-of-mexico-black-grouper/',
    'https://sedarweb.org/documents/s19dw09-age-growth-and-maturity-of-black-grouper-mycteroperca-bonaci-crabtree-and-bullock-1998-revisited/',
    'https://safmc.net/documents/5b_design-of-alternative-mps-for-black-grouper-final-report-pdf/',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=14148', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Screened; age-disaggregated eligibility remains unresolved. SEDAR 19 is the latest completed formal assessment (2010; data through 2008; Stock SMART assessment 5223, Full acceptance). Although the assessment uses an age-structured ASAP2 model and reports age-specific outputs, the numerical catch-at-age/composition inputs and exact final accepted index set have not been verified from public source files. The 2017 Stock Synthesis effort was suspended and is not a replacement production assessment.'),
  notes = paste('NOAA Stock SMART ID 14148 represents one South Atlantic and Gulf of Mexico black grouper unit (Mycteroperca bonaci), not separate Gulf and Atlantic stocks. No matching canonical stock was found. The 2010 SEDAR 19 assessment is the latest completed formal assessment; the 2026 SAFMC review says the 2017 assessment attempt was suspended because catch records were uncertain and notes that data were revised in 2017. Sources are cached under source_cache/discovery_noaa_black_grouper_sedar19 with retrieval dates, URLs, revisions, file sizes and SHA-256 hashes. No canonical records were added.')
)
blank <- function(x) is.na(x) || !nzchar(x)
initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  blank(register$candidate_unit_id[row])
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved' &&
  register$scientific_name[row] == 'Mycteroperca bonaci'
if (!initial && !reviewed)
  stop('Black grouper candidate has an unexpected prior review state.', call. = FALSE)
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], id)
  }
}
cat('Screened NOAA 14148 South Atlantic and Gulf of Mexico black grouper; eligibility remains unresolved.\n')
