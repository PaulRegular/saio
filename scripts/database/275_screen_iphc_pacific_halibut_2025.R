path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:11082', 'DFO:Pacific:Pacific Halibut')
i <- match(ids, x$candidate_id)
if (anyNA(i) || anyDuplicated(x$candidate_id[i])) {
  stop('Expected NOAA and DFO inventory rows for Pacific halibut.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'iphc_pacific_halibut',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'IPHC-2026-TSD-031 provides directed-fishery age-frequency specimen counts by',
    'regulatory area, year (1993-2025), and sex; the 2026-06 table revision is later',
    'than the assessment vintage and 2025 is preliminary. The assessment overview',
    'states port otoliths are sampled in proportion to landings within area/year.',
    'Combining source proportions with TSD-007 landings supports a documented',
    'catch-at-age reconstruction, with age-specific weight conversion and run-vintage',
    'checks required; model input arrays are available only by IPHC permission.'
  ),
  survey_age_evidence = paste(
    'Public IPHC FISS individual records cover 1998-2025 and include age, sex,',
    'maturity, length, station, and year; 365,576 of 2,273,521 records have a resolved',
    'age. Modelled FISS NPUE is available by regulatory area for 1993-2025, in numbers',
    'per standardized 100-hook skate with CV and 95% intervals. Splitting that index',
    'by observed age composition is possible for sampled area-years; unsampled areas',
    'are not extrapolated. Ageing groups and the post-assessment 2025 data vintage',
    'must be checked before treating reconstructed series as run-matched inputs.'
  ),
  weights_evidence = paste(
    'The 2025 assessment overview describes sex-, area-, age-, and year-specific',
    'FISS and fishery weight-at-age, with population values smoothed across years.',
    'The public FISS file provides fork length and age, and IPHC publishes a',
    'length-weight relationship. These support a documented reconstruction, but the',
    'exact four-model input matrices are not in the public assessment bundle.'
  ),
  maturity_evidence = paste(
    'The 2025 assessment updated the female maturity ogive using histology from',
    '2022-2024; the data overview reports a curve truncated below age 7. The public',
    'FISS records include maturity observations. The report provides the ogive',
    'graphically, so exact run-matched values need recovery or documented',
    'digitization before import.'
  ),
  mortality_evidence = paste(
    'The 2025 ensemble includes four model structures: female natural mortality is',
    'estimated in three models and fixed at 0.15/year in the coastwide short model;',
    'male natural mortality is estimated in all four. Preserve model-specific M',
    'treatment rather than treating the ensemble as one fixed-M specification.'
  ),
  timing_evidence = paste(
    'The FISS is an annual summer survey conducted across late May-September; the',
    'assessment is annual. Sources establish a seasonal window but not one common',
    'within-year sampling fraction.',
    'approximation, ideally using area/year survey dates.'
  ),
  output_evidence = paste(
    'The official 2025 assessment reports annual female spawning biomass with',
    'approximate 95% credible intervals, plus recruitment, age-8+ biomass, and',
    'fishing-intensity estimates. IPHC-2026-TSD-029 provides annual spawning-biomass',
    'series for each of the four assessment models (1888-2026) in tonnes or millions',
    'of pounds. Public numeric historical N-at-age and F-at-age arrays were not found.'
  ),
  detailed_source_url = paste(
    'https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf;',
    'https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf;',
    'https://www.iphc.int/data/time-series-datasets/;',
    'https://www.iphc.int/data/fiss-pacific-halibut-data/;',
    'https://www.iphc.int/data/directed-commercial-pacific-halibut-length-and-age-statistics/;',
    'https://www.iphc.int/data/fishery-landings-by-iphc-regulatory-area/'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 11082 and the DFO Pacific halibut inventory entry refer to',
    'the same IPHC Convention Area resource spanning Canada and the United States;',
    '',
    'provisional new unit. The current official assessment is IPHC-2026-SA-01, a',
    'four-model 2025 assessment. Public commercial age frequencies, area-specific',
    'landings, FISS age samples, an area-specific FISS abundance index, biology, and',
    'annual SSB outputs support source-based age-input reconstruction, so the unit is',
    'eligible for source curation with explicit approximations. This is not an exact',
    'replication of the Stock Synthesis likelihood: run input files require permission,',
    'the public commercial-age table was revised after the run, and numeric historical',
    'N-at-age and F-at-age outputs were not located.'
  ),
  notes = paste(
    'NOAA inventory year 2024 and the DFO 2024 survey row are source metadata, not',
    'the latest assessment year. Use the IPHC 2025 assessment through its 31 October',
    '2025 data cutoff; do not substitute post-run updates without checking them against',
    'the pinned run. The latest assessment and public source files are cached under',
    'source_cache/discovery_iphc_pacific_halibut/ with retrieval dates, table/document',
    'identifiers, and SHA-256 hashes.'
  )
)

for (j in seq_along(i)) {
  if (x$screening_status[i[j]] == 'not_started' &&
      x$match_status[i[j]] == 'unreviewed') {
    for (column in names(review)) x[[column]][i[j]] <- review[[column]]
  } else if (!all(vapply(names(review), function(column) {
    identical(as.character(x[[column]][i[j]]), as.character(review[[column]]))
  }, logical(1L)))) {
    stop(paste('Candidate row has a conflicting prior review:', ids[j]), call. = FALSE)
  }
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
for (j in seq_along(i)) {
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i[j], , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i[j] + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Crosswalked NOAA and DFO Pacific halibut entries to one eligible IPHC stock unit.\n')
