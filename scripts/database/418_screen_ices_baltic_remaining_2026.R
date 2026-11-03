root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_baltic_current_reports_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c('WGBFAS_2026.pdf', 'WGBAST_2025.pdf', 'WGBAST_2026.pdf'),
  url = c(
    'https://literatur.thuenen.de/digbib_extern/dn071152.pdf',
    'https://literatur.thuenen.de/digbib_extern/dn070649.pdf',
    'https://literatur.thuenen.de/digbib_extern/dn071135.pdf'),
  retrieved_on = '2026-10-30',
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  } else {
    result <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', result[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest_path <- file.path(cache, 'sources.csv')
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
source_rows <- match(sources$file, manifest$file)
source_paths <- file.path(cache, sources$file)
if (anyNA(source_rows) || any(!file.exists(source_paths)))
  stop('The local ICES Baltic report cache is incomplete.', call. = FALSE)
if (any(manifest$url[source_rows] != sources$url) ||
    any(manifest$retrieved_on[source_rows] != sources$retrieved_on) ||
    !identical(as.numeric(manifest$bytes[source_rows]), as.numeric(file.info(source_paths)$size)) ||
    !identical(tolower(manifest$sha256[source_rows]),
      unname(vapply(source_paths, sha256_file, character(1L)))))
  stop('The cached ICES Baltic reports do not match their source manifest.', call. = FALSE)
pdf_signatures <- vapply(source_paths, function(path)
  rawToChar(readBin(path, 'raw', n = 5L)), character(1L))
if (any(!startsWith(pdf_signatures, '%PDF-')))
  stop('A cached ICES report is not a PDF.', call. = FALSE)

screens <- data.frame(
  candidate_id = c('ICES:sal.27.22-31', 'ICES:sal.27.32', 'ICES:trs.27.22-32',
    'ICES:dab.27.22-32', 'ICES:bll.27.22-32'),
  unit_id = c('ices_salmon_main_basin_22_31', 'ices_salmon_gulf_finland_32',
    'ices_sea_trout_baltic_22_32', 'ices_dab_baltic_22_32', 'ices_brill_baltic_22_32'),
  source = c('WGBAST_2025', 'WGBAST_2025', 'WGBAST_2025', 'WGBFAS_2026', 'WGBFAS_2026'),
  scientific_name = c('Salmo salar', 'Salmo salar', 'Salmo trutta',
    'Limanda limanda', 'Scophthalmus rhombus'),
  stock_name = c(
    'Salmon (Salmo salar) in subdivisions 22-31 (Baltic Sea, excluding the Gulf of Finland)',
    'Salmon (Salmo salar) in Subdivision 32 (Gulf of Finland)',
    'Sea trout (Salmo trutta) in subdivisions 22-32 (Baltic Sea)',
    'Dab (Limanda limanda) in subdivisions 22-32 (Baltic Sea)',
    'Brill (Scophthalmus rhombus) in subdivisions 22-32 (Baltic Sea)'),
  stringsAsFactors = FALSE
)
screens$detailed_source_url <- ifelse(screens$source == 'WGBAST_2025',
  'https://doi.org/10.17895/ices.pub.29118545',
  'https://doi.org/10.17895/ices.pub.32455056')

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
rows <- match(screens$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(screens$candidate_id) || anyDuplicated(screens$unit_id))
  stop('Expected one register row and one candidate unit per Baltic stock.', call. = FALSE)
if (any(register$scientific_name[rows] != screens$scientific_name) ||
    any(register$stock_name[rows] != screens$stock_name) ||
    any(register$official_stock_id[rows] != sub('^ICES:', '', screens$candidate_id)))
  stop('ICES stock identity does not match the 2026 SID inventory.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) %in% tolower(sub('^ICES:', '', screens$candidate_id)),
    na.rm = TRUE))
  stop('An ICES stock code already appears in the canonical database.', call. = FALSE)
if (any(screens$unit_id %in% c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    na.rm = TRUE) || any(screens$unit_id %in% register$candidate_unit_id[-rows], na.rm = TRUE))
  stop('A candidate unit key conflicts with an existing record.', call. = FALSE)

assessment_text <- c(
  'The 2025 WGBAST report documents catch age samples, including age-read scales, but those samples are not shown as an annual catch-at-age likelihood series for this broad management unit. Whether the sampled data support a defensible annual reconstruction remains unresolved.',
  'The 2025 WGBAST report includes age-read catch samples, including samples from Subdivision 32, but does not show a complete annual catch-at-age likelihood series for the Gulf of Finland unit. Whether the sampled data support a defensible reconstruction remains unresolved.',
  'The reviewed WGBAST report describes catch and recruitment-status information, but no annual catch-at-age likelihood input for the Baltic sea-trout management unit was verified.',
  'The 2026 WGBFAS update reports aggregate landings and discards; no catch-at-age likelihood input was reported in the reviewed assessment chapter.',
  'The 2026 WGBFAS update reports aggregate landings and an abundance indicator; no catch-at-age likelihood input was reported in the reviewed assessment chapter.'
)
survey_text <- c(
  'The assessment uses river-run counts, parr and smolt monitoring, and stock-composition samples. These are not a marine age-specific abundance index for the broad subdivisions 22-31 unit.',
  'The assessment describes river and stock-composition monitoring, but no age-specific abundance index for the subdivision 32 population was verified.',
  'River recruitment-status monitoring and catch sampling are described, but no age-specific abundance index for the Baltic sea-trout unit was verified.',
  'The 2026 update uses aggregate stock indicators and a model-based exploitable biomass index; it does not report age-specific survey abundance.',
  'The BITS survey indicator is based on fish at least 20 cm per hour, not an age-specific abundance series.'
)
output_text <- c(
  'The latest detailed assessment reports river and life-history outputs (including smolt production, post-smolt survival, and stock status), not a complete N-at-age/F-at-age/M-at-age surface for subdivisions 22-31.',
  'The 2025 WGBAST report assesses wild-stock status by expert elicitation for AU 6; it does not report a population-at-age surface for subdivision 32.',
  'The latest report presents catch and recruitment-status summaries; no comparable N-at-age, F-at-age, or M-at-age population outputs were verified.',
  'The 2026 report describes SPiCT-based stock status and exploitable-biomass indicators; it does not report N-at-age, F-at-age, or M-at-age surfaces.',
  'The 2026 report provides an age-independent survey stock-size indicator; it does not report N-at-age, F-at-age, or M-at-age surfaces.'
)
eligibility <- c('unresolved', 'unresolved', 'ineligible', 'ineligible', 'ineligible')
reasons <- c(
  'Screened; age-input eligibility remains unresolved. The latest detailed WGBAST assessment reports biological age samples but uses a river life-history assessment and does not publish a conventional age-structured population surface for this broad unit. The representativeness and likelihood role of the age samples, and a comparable output definition, need source-level verification before this case can be classed eligible or excluded.',
  'Screened; age-input eligibility remains unresolved. The latest detailed WGBAST assessment reports age-read catch samples, but the Gulf of Finland stock is assessed by expert elicitation and no conventional population-at-age inputs or outputs are published. The samples do not by themselves establish that catch-at-age can be reconstructed for the assessment unit.',
  'Ineligible for the current age-disaggregated population-assessment comparison: the latest WGBAST report reviews catch and river recruitment-status information but does not provide a fitted age-structured population model, age-specific survey index, or comparable N/F/M-at-age outputs. This is not a claim that biological age samples do not exist.',
  'Ineligible for the current age-disaggregated population-assessment comparison: the 2026 update uses SPiCT and a model-based exploitable-biomass indicator, with no verified age-specific population inputs or N/F/M-at-age output. This does not establish that biological age samples do not exist.',
  'Ineligible for the current age-disaggregated population-assessment comparison: the 2026 update reports an age-independent BITS size indicator and trend-based stock assessment, with no verified catch-at-age input or N/F/M-at-age output. This does not establish that biological age samples do not exist.'
)

review_values <- lapply(seq_len(nrow(screens)), function(i) list(
  candidate_unit_id = screens$unit_id[i], match_status = 'new',
  screening_status = 'screened', eligibility = eligibility[i], import_status = 'not_started',
  catch_age_evidence = assessment_text[i], survey_age_evidence = survey_text[i],
  weights_evidence = 'The reviewed report does not provide a complete age-specific stock-weight series for this unit.',
  maturity_evidence = 'The reviewed report does not provide a complete maturity-at-age series for this unit.',
  mortality_evidence = 'The reports describe stock-specific survival, harvest, or aggregate fishing-pressure indicators; an age-specific F and M surface for the assessment unit was not verified.',
  timing_evidence = 'No age-specific abundance survey suitable for specifying a within-year observation timing was verified.',
  output_evidence = output_text[i], detailed_source_url = screens$detailed_source_url[i],
  review_date = '2026-10-30', decision_reason = reasons[i],
  notes = paste0('Identity and current assessment status were checked against the 2026 ICES SID inventory and the relevant latest detailed working-group report. In 2026, WGBAST conducted benchmark work and no new salmon or trout assessment; WGBFAS conducted 2026 updates for dab and brill. Cached reports, URLs, retrieval dates, sizes, and SHA-256 values are recorded in source_cache/discovery_ices_baltic_current_reports_2026/sources.csv. No canonical assessment, input, or output records were added.')
))

is_initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
is_reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == screens$unit_id &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == eligibility
if (any(!is_initial & !is_reviewed))
  stop('At least one candidate has a conflicting prior review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_along(rows)) {
    if (is_initial[i] || is_reviewed[i]) {
      for (field in names(review_values[[i]])) register[[field]][rows[i]] <- review_values[[i]][[field]]
      replace_candidate_register_row(register_path, rows[i], register[rows[i], , drop = FALSE],
        screens$candidate_id[i])
    }
  }
}

cat('Screened the remaining five 2026 ICES Baltic inventory entries against their detailed working-group reports.\n')
