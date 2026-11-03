root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

candidate_id <- 'NOAA:12149'
unit_id <- 'noaa_cobia_atlantic_2020'
review_date <- '2026-11-02'
source_url <- paste(
  'https://sedarweb.org/documents/sedar-58-stock-assessment-report-atlantic-cobia-revised-september-14-2020/',
  'https://sedarweb.org/documents/sedar-58-cie-reviewer-report-casey/',
  sep = '; ')

if (anyDuplicated(register$candidate_id) ||
    any(register$candidate_unit_id[-match(candidate_id, register$candidate_id)] == unit_id,
      na.rm = TRUE))
  stop('NOAA Atlantic cobia candidate or unit identity is duplicated.', call. = FALSE)

row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index)) stop('NOAA:12149 is absent from the register.', call. = FALSE)
row <- register[row_index, , drop = FALSE]
row$candidate_unit_id <- unit_id
row$scientific_name <- 'Rachycentron canadum'
row$assessment_area <- 'Atlantic stock (Georgia and north)'
row$matched_stock_id <- ''
row$match_status <- 'new'
row$screening_status <- 'screened'
row$eligibility <- 'eligible'
row$import_status <- 'not_started'
row$catch_age_evidence <- paste(
  'The SEDAR 58 revised base run (co23) uses total catch by fleet plus annual general-recreational age compositions, which support a source-based catch-at-age reconstruction for that fleet.',
  'Commercial age compositions were excluded because the samples were not representative of the fleet.')
row$survey_age_evidence <- paste(
  'The only fitted abundance index is headboat CPUE for 1991-2015; it is aggregate, not an age-specific survey index.',
  'The annual general-recreational age compositions are fitted for 1986-2017 and can support documenting an age-structured observation approximation.')
row$weights_evidence <- paste(
  'The final BAM input includes age-specific weight-at-age and length/weight information for ages 1-15.',
  'The source report documents the corresponding growth and weight-length assumptions.')
row$maturity_evidence <- paste(
  'The final BAM input contains a female maturity-at-age vector for ages 1-15 and an assumed 50:50 sex ratio.')
row$mortality_evidence <- paste(
  'The final BAM input supplies age-dependent natural mortality for ages 1-15.',
  'This is a specified biological schedule, not an estimated M-at-age output.')
row$timing_evidence <- paste(
  'The BAM input documents spawning timing as a fraction of year.',
  'A distinct fractional timing for the headboat CPUE observation was not verified; this remains a translation detail to resolve from the index working paper.')
row$output_evidence <- paste(
  'The accepted revised base run reports population, fishing-mortality, biomass, recruitment, and reference-point results through 2017, with uncertainty and diagnostics in the assessment report.')
row$detailed_source_url <- source_url
row$review_date <- review_date
row$decision_reason <- paste(
  'Eligible for source curation: the current Atlantic stock assessment is SEDAR 58 (2020), whose revised base run co23 is identified as the definitive assessment.',
  'The age compositions and age-specific biological inputs are documented and official age-structured outputs are reported.',
  'The 2026 SEDAR 107 cobia benchmark had not been delivered at the review date; the Gulf cobia unit remains separate.')
row$notes <- paste(
  'The Stock SMART inventory row lists a 2020 assessment but calls its method a surplus-production model; the detailed SEDAR 58 source identifies BAM and is authoritative for this assessment.',
  'SEDAR 58 uses annual recreational age compositions for ages 1-12 over 1986-2017, headboat CPUE for 1991-2015, and excludes commercial age compositions.',
  'NOAA:10390 is the separate Gulf of Mexico cobia unit and is not merged with this Atlantic stock.')

current <- register[row_index, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
}, logical(1L)))
initial <- register$match_status[row_index] == 'unreviewed' &&
  register$screening_status[row_index] == 'not_started' &&
  register$eligibility[row_index] == 'unresolved' &&
  register$import_status[row_index] == 'not_started' &&
  (is.na(register$candidate_unit_id[row_index]) ||
    !nzchar(register$candidate_unit_id[row_index]))
reviewed <- register$candidate_unit_id[row_index] == unit_id &&
  register$match_status[row_index] == 'new' &&
  register$screening_status[row_index] == 'screened' &&
  register$eligibility[row_index] == 'eligible' &&
  register$import_status[row_index] == 'not_started'
if (!same && !initial && !reviewed)
  stop('Unexpected existing state for NOAA:12149.', call. = FALSE)
if (!same) {
  for (name in names(row)) register[[name]][row_index] <- row[[name]]
  replace_candidate_register_row(register_path, row_index,
    register[row_index, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:12149 as the eligible Atlantic cobia SEDAR 58 age-structured assessment.\n')
