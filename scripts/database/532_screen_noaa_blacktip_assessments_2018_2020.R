root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

source_urls <- c(
  paste0('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=11026; ',
    'https://sedarweb.org/assessments/sedar-65/; ',
    'https://sedarweb.org/documents/sedar-65-hms-atlantic-blacktip-shark-final-stock-assessment-report/'),
  paste0('https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=11027; ',
    'https://sedarweb.org/assessments/sedar-29-update-hms-gulf-of-mexico-blacktip-shark/; ',
    'https://sedarweb.org/documents/2018-update-sedar-29-hms-gulf-of-mexico-blacktip-shark/; ',
    'https://sedarweb.org/documents/addendum-to-2018-update-to-sedar-29-hms-gulf-of-mexico-blacktip-shark/'))

review <- data.frame(
  candidate_id = c('NOAA:11026', 'NOAA:11027'),
  candidate_unit_id = c('noaa_atlantic_blacktip_shark',
    'noaa_gulf_blacktip_shark'),
  match_status = rep('new', 2L),
  screening_status = rep('screened', 2L),
  eligibility = rep('ineligible', 2L),
  import_status = rep('not_started', 2L),
  catch_age_evidence = c(
    'SEDAR 65 fits total catch, including landings converted from weight where needed, and sex-specific length compositions in 5-cm fork-length bins. It does not report catch-at-age observations; the fitted composition likelihood is length based.',
    'The 2018 update fits total catch by fleet, not catch numbers-at-age. The report states that age-composition data were unavailable; length compositions informed selectivity outside the model and were not input directly.'),
  survey_age_evidence = c(
    'The accepted model uses aggregate CPUE abundance indices. Survey length compositions are available for some series, but no age-specific survey index or age-composition likelihood was identified.',
    'The update fits seven aggregate relative-abundance indices. No age-specific abundance index or age-composition observation likelihood was identified.'),
  weights_evidence = c(
    'The model fixes sex-specific weight-at-length relationships and sex-specific growth-at-age parameters. No observed weight-at-age input series was identified; age-specific weights are derived from the biological relationships.',
    'The report uses an age-specific weight schedule for catch calculations and reports age/growth and length-weight biology. These are biological model inputs, not observed age-specific catch or survey data.'),
  maturity_evidence = c(
    'Female maturity-at-age and annual pup production-at-age are fixed/derived life-history inputs; they do not constitute an observed age-composition series.',
    'The model uses an age-specific maternity ogive and fecundity-at-age assumptions as biological inputs. No age-specific observation likelihood is fitted.'),
  mortality_evidence = c(
    'Sex- and age-specific natural mortality is fixed in the base model from life-history invariant methods; it is not estimated from age-specific observations.',
    'Age-specific natural mortality is a life-history input derived from invariant methods; the assessment does not estimate an age-specific M process from age observations.'),
  timing_evidence = c(
    'The report includes annual catch and abundance-index series but does not specify a single within-year survey timing fraction for the aggregate indices.',
    'The model represents fleet catches by month and season length.'),
  output_evidence = c(
    'SEDAR 65 reports an age-structured Stock Synthesis assessment with recruitment, spawning-stock fecundity and population/fishing-mortality outputs. These fitted age surfaces do not replace the missing age-disaggregated observation inputs.',
    'The SSASPM reports numbers-at-age and recruitment, total abundance, spawning-stock fecundity, and apical fishing mortality. The report does not provide an age-disaggregated observation likelihood.'),
  detailed_source_url = source_urls,
  review_date = rep('2026-11-02', 2L),
  decision_reason = c(
    'Ineligible for age-disaggregated source curation: the latest fully accepted assessment uses total catch, aggregate CPUE and length-composition observations. Age-specific biological parameters and age-structured outputs do not establish an age-specific observation input.',
    'Ineligible for age-disaggregated source curation: the latest fully accepted update explicitly reports no age-composition observations; it uses total catch and aggregate relative-abundance indices, with length compositions used to build selectivity outside the fitted model.'),
  notes = c(
    'NOAA Stock SMART records SEDAR 65 as fully accepted (assessment year 2021; data through 2018). The detailed SEDAR report is dated 2020. This Atlantic stock remains distinct from the Gulf of Mexico unit and from the historical large-coastal-shark complex.',
    'NOAA Stock SMART records the 2018 SEDAR 29 full update as fully accepted (data through 2016). The September 2018 addendum documents reruns using calibrated MRIP estimates; this is the latest detailed run located for the Gulf unit.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (any(review$candidate_unit_id %in%
    register$candidate_unit_id[!register$candidate_id %in% review$candidate_id]))
  stop('A reviewed candidate unit is already assigned to another inventory row.',
    call. = FALSE)

blank <- function(x) is.na(x) || !nzchar(x)
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
  reviewed <- old$match_status == review$match_status[i] &&
    old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
    old$import_status == 'not_started' &&
    identical(unit, as.character(review$candidate_unit_id[i]))
  if (!initial && !reviewed)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  for (name in setdiff(names(review), 'candidate_id'))
    register[[name]][row_index] <- review[[name]][i]
  same <- all(vapply(names(register), function(name) {
    x <- register[[name]][row_index]
    y <- old[[name]]
    if (is.na(x)) is.na(y) else !is.na(y) &&
      identical(as.character(x), as.character(y))
  }, logical(1L)))
  if (!same && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened two NOAA blacktip shark stock units against the latest detailed assessments.\n')