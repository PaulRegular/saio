path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

reviews <- list(
  list(
    candidate_id = 'DFO:Pacific:Quillback Rockfish - Inside waters',
    candidate_unit_id = 'dfo_quillback_inside',
    scientific_name = 'Sebastes maliger',
    assessment_area = 'British Columbia Inside waters, Groundfish Management Area 4B',
    catch_age_evidence = paste(
      'The 2021 management-procedure analysis conditions an RCM using commercial and',
      'recreational catches and composition data. The report documents commercial age',
      'samples in 1984-1994, 1996, and 2000-2001, with no commercial age samples after',
      '2001. This does not establish a complete numeric annual catch-at-age series.'
    ),
    survey_age_evidence = paste(
      'Age-composition likelihoods use biological samples from the inside hard-bottom',
      'longline (HBLL) survey and Jig Area 12 survey; aggregate abundance indices are',
      'developed separately for those surveys. The reported composition sample sizes are',
      'capped at 100 (HBLL) and 50 (Jig). Numeric age-specific index series were not found.'
    ),
    weights_evidence = paste(
      'The model uses commercial mean weight, and age/growth biology is described from',
      'survey samples. A run-matched, machine-readable weight-at-age vector was not verified.'
    ),
    maturity_evidence = paste(
      'Female maturity is specified as an age-based function estimated from survey',
      'biological samples. The precise run-matched numeric vector was not recovered as a',
      'machine-readable input.'
    ),
    mortality_evidence = paste(
      'Natural mortality is not estimated as a single fitted time series. Reference',
      'operating models use alternative mean M values of 0.055, 0.067, and 0.088 per year.'
    ),
    timing_evidence = paste(
      'The HBLL and Jig Area 12 indices and age samples are described, but a model-scale',
      'fractional timing for each observation series was not verified.'
    ),
    output_evidence = paste(
      'The report presents modeled spawning biomass, depletion, fishing-mortality/reference',
      'ratios, recruitment and fits to age compositions across operating-model replicates.',
      'Run-matched numerical annual N-at-age and F-at-age arrays were not located.'
    ),
    detailed_source_url = paste(
      'https://open-science.canada.ca/server/api/core/bitstreams/6c15c3af-e055-48b2-873f-e9f0fc8289e4/content;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41204323.pdf'
    ),
    decision_reason = paste(
      'The latest detailed official assessment located is the 2021 Inside Quillback',
      'management-procedure analysis (research document published 2024). It uses age',
      'compositions, but the reviewed public sources do not establish a complete annual',
      'catch-at-age series, exportable age-specific survey indices, exact survey timing, or',
      'run-matched numeric age-specific outputs. Eligibility for the age-input set remains',
      'unresolved pending source-data review.'
    ),
    notes = paste(
      'Distinct DFO Inside unit in Area 4B; not coalesced with the separate Outside unit or',
      'NOAA California stock. Model terminal year is 2021. No canonical database values were added.'
    )
  ),
  list(
    candidate_id = 'DFO:Pacific:Quillback Rockfish - Outside waters',
    candidate_unit_id = 'dfo_quillback_outside',
    scientific_name = 'Sebastes maliger',
    assessment_area = 'British Columbia Outside waters, outside Groundfish Management Area 4B',
    catch_age_evidence = paste(
      'The 2021 management-procedure analysis conditions Stock Synthesis 3 operating',
      'models on historical catches and age compositions from fisheries and surveys.',
      'Commercial catch histories include reconstructed removals, but a complete numeric',
      'annual catch-at-age matrix was not verified in the reviewed public files.'
    ),
    survey_age_evidence = paste(
      'The fitted model uses age compositions from fishery and survey sources plus',
      'aggregate indices from the outside HBLL and IPHC longline surveys and the Hecate',
      'Strait trawl survey. These compositions are not themselves absolute age-specific',
      'abundance indices; run-matched numeric composition matrices were not located.'
    ),
    weights_evidence = paste(
      'Commercial fishery mean weight is an input. Age-specific growth, weight and other',
      'biological specifications are described in the report, but a complete run-matched',
      'weight-at-age surface was not recovered as a machine-readable input.'
    ),
    maturity_evidence = paste(
      'The age-structured model specifies female maturity by age from biological samples.',
      'The exact run-matched numeric maturity vector was not recovered as a machine-readable input.'
    ),
    mortality_evidence = paste(
      'Natural mortality is fixed within operating-model scenarios, with reference values',
      'of 0.046 and 0.056 per year; the model does not estimate an annual M-at-age surface.'
    ),
    timing_evidence = paste(
      'HBLL, IPHC and Hecate Strait survey sources are identified, but fractional',
      'within-year timing for the fitted index observations was not verified.'
    ),
    output_evidence = paste(
      'The report provides annual historical spawning-biomass and F/reference-point',
      'trajectories and terminal-year posterior summaries across operating models.',
      'Run-matched numerical annual N-at-age and F-at-age arrays were not located.'
    ),
    detailed_source_url = paste(
      'https://open-science.canada.ca/server/api/core/bitstreams/d02461e4-0a5d-4004-b684-b37be53a86cb/content;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41209862.pdf'
    ),
    decision_reason = paste(
      'The latest detailed official assessment located is the 2021 Outside Quillback',
      'management-procedure analysis (research document published 2025). Its age-structured',
      'SS3 operating models use fishery and survey age compositions, but complete numeric',
      'age inputs, fractional survey timing, and run-matched annual age-specific outputs were',
      'not verified. Eligibility for the age-input set remains unresolved pending source-data review.'
    ),
    notes = paste(
      'Distinct DFO Outside unit covering BC waters outside Groundfish Management Area 4B;',
      'the model separates North (5BCDE) and South (5A3CD) areas. Model terminal year is 2021.',
      'No canonical database values were added.'
    )
  )
)

for (review in reviews) {
  i <- match(review$candidate_id, x$candidate_id)
  if (is.na(i)) stop('Expected DFO Quillback inventory row was not found.', call. = FALSE)
  if (!x$screening_status[i] %in% c('not_started', 'screened') ||
      !x$match_status[i] %in% c('unreviewed', 'new')) {
    stop('DFO Quillback inventory row has an unexpected prior review state.', call. = FALSE)
  }
  if (any(stocks$scientific_name == review$scientific_name &
      grepl('quillback', tolower(stocks$common_name)))) {
    stop('A canonical Quillback record now exists; reconcile it before rerunning.', call. = FALSE)
  }
  review$match_status <- 'new'
  review$screening_status <- 'screened'
  review$eligibility <- 'unresolved'
  review$import_status <- 'not_started'
  review$inventory_assessment_year <- '2021'
  review$review_date <- '2026-10-29'
  for (column in names(review)) x[[column]][i] <- review[[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
for (review in reviews) {
  i <- match(review$candidate_id, x$candidate_id)
  row <- x[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened the DFO Inside and Outside Quillback 2021 assessments; both remain eligibility-unresolved.\n')
