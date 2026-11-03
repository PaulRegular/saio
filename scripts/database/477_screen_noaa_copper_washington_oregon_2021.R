root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_copper_washington_oregon_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_hashes <- c(
  copper_washington_2021_assessment.pdf = '91b58c7549c5691711bc3804aacf7547e014ed7b8184e94a4eed60733adaaf50',
  copper_oregon_2021_assessment.pdf = 'a832b4cd8451ec801734ac1b669608b7c1af95bf024dabc4e08132e123371fcb')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The Washington/Oregon copper source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached copper assessment differs from its manifest: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_ids <- c('NOAA:15330', 'NOAA:15331')
candidate_unit_ids <- c('noaa_copper_rockfish_washington_2021',
  'noaa_copper_rockfish_oregon_2021')
rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(candidate_ids) ||
    any(candidates$official_stock_id[rows] != c('15330', '15331')) ||
    any(candidates$inventory_assessment_year[rows] != '2021') ||
    any(candidates$scientific_name[rows] != 'Sebastes caurinus') ||
    !identical(candidates$stock_name[rows],
      c('Copper rockfish - Washington', 'Copper rockfish - Oregon')))
  stop('The NOAA Washington/Oregon copper inventory identities changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(candidate_unit_ids %in% stocks$stock_id) ||
    any(assessments$assessment_id %in% candidate_unit_ids) ||
    any(inputs$assessment_id %in% candidate_unit_ids) ||
    any(outputs$assessment_id %in% candidate_unit_ids))
  stop('A canonical copper record exists; recheck the current-unit crosswalk.', call. = FALSE)

make_review <- function(region, unit_id, url, survey_evidence) {
  list(
    candidate_unit_id = unit_id,
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste0(
      'The 2021 Stock Synthesis catch-and-length assessment has no annual catch-at-age ' ,
      'or fitted age-composition likelihood. Catch is entered as aggregate removals; ',
      'the age samples described in the report support biological growth inputs, not ',
      'an annual catch-age series.'),
    survey_age_evidence = survey_evidence,
    weights_evidence = paste0(
      'The assessment derives age-specific weight from sex-specific growth and ',
      'length-weight relationships; the report includes age-specific biological ',
      'tables but not an observed annual weight-at-age surface.'),
    maturity_evidence = paste0(
      'Maturity is specified from a maturity-at-length relationship and converted ',
      'to age-specific biology; it is not a year-by-age observation series.'),
    mortality_evidence = paste0(
      'Natural mortality is fixed at 0.108 per year for both sexes in the base ',
      'assessment; it is not an estimated age-specific M series.'),
    timing_evidence = paste0(
      'No abundance survey is included in the base model, so there is no survey ',
      'timing to translate.'),
    output_evidence = paste0(
      'The assessment report provides official stock-status and spawning-output ',
      'results. This screen does not establish a published official age-specific ',
      'population-output table.'),
    detailed_source_url = url,
    review_date = '2026-10-31',
    decision_reason = paste0(
      'Ineligible for the age-disaggregated comparison set. The latest detailed ',
      'assessment is a catch-and-length Stock Synthesis model, not an age-data ',
      'likelihood model. Biological age samples inform growth but do not provide ',
      'annual catch-at-age or survey abundance-at-age observations. ', region,
      ' is retained as its own assessment unit.'),
    notes = paste0(
      'This is the separate 2021 ', region,
      ' copper rockfish assessment area, not one of the north/south California ',
      'sub-area models in the 2023 assessment.'))
}

washington <- make_review('Washington', candidate_unit_ids[1L], manifest$url[match(
  'copper_washington_2021_assessment.pdf', manifest$file)], paste0(
    'The report states that no fishery-independent data source was available ',
    'for the assessment; no abundance index was fitted.'))
oregon <- make_review('Oregon', candidate_unit_ids[2L], manifest$url[match(
  'copper_oregon_2021_assessment.pdf', manifest$file)], paste0(
    'No fishery-independent index was fitted in the base assessment. The ODFW ',
    'Marine Reserve hook-and-line survey was examined but not used because the ',
    'copper data were limited; the CPFV index appears only in a sensitivity, ',
    'not the base model.'))
reviews <- setNames(list(washington, oregon), candidate_ids)

pristine <- vapply(rows, function(row)
  candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row])),
  logical(1L))
already_reviewed <- vapply(seq_along(candidate_ids), function(i) {
  row <- rows[i]
  all(vapply(names(reviews[[i]]), function(column)
    identical(as.character(candidates[[column]][row]), as.character(reviews[[i]][[column]])),
    logical(1L)))
}, logical(1L))
if (any(!(pristine | already_reviewed)))
  stop('At least one NOAA Washington/Oregon copper candidate has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (i in seq_along(candidate_ids)) {
    row <- rows[i]
    for (column in names(reviews[[i]])) candidates[[column]][row] <- reviews[[i]][[column]]
    replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_ids[i])
  }
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened the 2021 NOAA Washington and Oregon copper rockfish assessments as catch-and-length cases without age-disaggregated observation likelihoods.\n')
