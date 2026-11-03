path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

units <- list(
  'NOAA:10538' = 'noaa_goa_rougheye_blackspotted',
  'NOAA:11443' = 'noaa_goa_rougheye_blackspotted',
  'NOAA:10539' = 'noaa_uswc_rougheye_blackspotted',
  'NOAA:14516' = 'noaa_uswc_rougheye_blackspotted',
  'NOAA:11382' = 'noaa_bsai_rougheye_blackspotted',
  'NOAA:15394' = 'noaa_bsai_rougheye_blackspotted',
  'NOAA:15395' = 'noaa_bsai_rougheye_blackspotted'
)
ids <- names(units)
rows <- match(ids, x$candidate_id)
if (anyNA(rows)) stop('Expected NOAA rougheye/blackspotted inventory rows are missing.', call. = FALSE)

expected_initial <- c('NOAA:10538', 'NOAA:10539', 'NOAA:11382', 'NOAA:11443', 'NOAA:15394', 'NOAA:15395')
for (id in expected_initial) {
  i <- match(id, x$candidate_id)
  expected_eligibility <- if (id %in% c('NOAA:11382', 'NOAA:11443')) 'eligible' else 'ineligible'
  already_screened <- x$candidate_unit_id[i] == units[[id]] &&
    x$match_status[i] == 'new' && x$screening_status[i] == 'screened' &&
    x$eligibility[i] == expected_eligibility
  not_yet_screened <- is.na(x$candidate_unit_id[i]) &&
    x$match_status[i] == 'unreviewed' && x$screening_status[i] == 'not_started' &&
    x$eligibility[i] == 'unresolved'
  if (!already_screened && !not_yet_screened) {
    stop('Preserve the existing review state for ', id, '.', call. = FALSE)
  }
}

west_coast <- match('NOAA:14516', x$candidate_id)
if (!identical(x$match_status[west_coast], 'new') ||
    !identical(x$screening_status[west_coast], 'screened') ||
    !identical(x$eligibility[west_coast], 'eligible')) {
  stop('Preserve the existing NOAA:14516 source screen.', call. = FALSE)
}

set_values <- function(id, values) {
  i <- match(id, x$candidate_id)
  for (name in names(values)) x[[name]][i] <<- values[[name]]
}

goa_url <- paste(
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOArougheye.pdf;',
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10291'
)
bsai_url <- 'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIrougheye.pdf'
review_date <- '2026-10-31'
cache_note <- paste(
  'Official source PDFs and their URLs, retrieval date, sizes, and SHA-256',
  'checksums are in source_cache/discovery_noaa_rougheye_alaska_20261031/sources.csv.'
)

set_values('NOAA:10538', list(
  candidate_unit_id = units[['NOAA:10538']], match_status = 'new',
  screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
  detailed_source_url = goa_url, review_date = review_date,
  decision_reason = paste(
    'Historical 2007 Gulf of Alaska inventory row, superseded by the current',
    'Rougheye/Blackspotted complex represented by NOAA:11443. Link this old',
    'single-species label to the same regional candidate unit so it is not',
    'counted separately. The current 2023 full assessment, not this historical',
    'entry, is the age-structured source-curation candidate.'
  ),
  notes = paste(
    'Legacy inventory label Rougheye rockfish - Gulf of Alaska (S. aleutianus).',
    'The current GOA assessment treats rougheye and blackspotted as one complex.',
    'This row is retained as an inventory alias, not as a separate current case.'
  )
))

set_values('NOAA:11443', list(
  candidate_unit_id = units[['NOAA:11443']], scientific_name = 'Sebastes aleutianus; Sebastes melanostictus',
  assessment_area = 'Gulf of Alaska', match_status = 'new', screening_status = 'screened',
  eligibility = 'eligible', import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2023 recommended age-structured model uses aggregate fishery catches',
    'with fishery age-composition data. Catch-at-age is a documented',
    'reconstruction from catch totals and age compositions, rather than a',
    'direct annual catch-at-age likelihood input.'
  ),
  survey_age_evidence = paste(
    'The model uses a bottom-trawl survey biomass index and age compositions.',
    'The longline survey contributes an abundance index and length compositions,',
    'but no longline age data are available. Exact fractional-year survey timing',
    'remains to be verified from run-matched data before translation.'
  ),
  weights_evidence = paste(
    'The report gives weight-at-age for the recommended 2023 model; it is derived',
    'from survey length-at-age and a length-weight relationship.'
  ),
  maturity_evidence = paste(
    'The recommended model uses updated maturity-at-age estimated from published',
    'biological samples; age-specific values are reported with the population',
    'outputs.'
  ),
  mortality_evidence = paste(
    'Natural mortality is fixed at 0.042 per year in recommended Model 23.1b,',
    'based on the Cope-Hamel longevity estimator.'
  ),
  timing_evidence = paste(
    'The 2023 full assessment and 2024 projection use annual bottom-trawl and',
    'longline survey series. The exact within-year fractions are not stated in',
    'the reviewed reports and remain a translation follow-up.'
  ),
  output_evidence = paste(
    'The full assessment reports annual numbers-at-age, maturity-at-age,',
    'weight-at-age, selectivity-at-age, spawning biomass, recruitment, and',
    'uncertainty. The 2024 SAFE chapter is a projection based on the 2023 fit.'
  ),
  detailed_source_url = goa_url, review_date = review_date,
  decision_reason = paste(
    'NOAA Stock SMART ID 11443 is the current Gulf of Alaska complex of',
    'rougheye and blackspotted rockfish. The 2024 SAFE entry is a harvest',
    'projection based on the 2023 full age-structured assessment, which',
    'provides fishery and bottom-trawl age compositions, biological surfaces,',
    'and population outputs at age. Screen eligible for source curation;',
    'verify survey timing before translation. The 2026 full assessment was',
    'scheduled for later review and was not yet final on 2026-10-31.'
  ),
  notes = paste(
    'The 2023 recommended model is Model 23.1b. Age composition evidence is',
    'for the fishery and bottom-trawl survey; the longline survey has no age',
    'data. Exact fractional-year timing remains unverified.', cache_note
  )
))

set_values('NOAA:10539', list(
  candidate_unit_id = units[['NOAA:10539']], match_status = 'new',
  screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
  detailed_source_url = 'https://www.pcouncil.org/documents/2014/01/the-status-of-rougheye-rockfish-sebastes-aleutianus-and-blackspotted-rockfish-s-melanostictus-as-a-complex-along-the-u-s-west-coast-in-2013-published-january-6-2014.pdf',
  review_date = review_date,
  decision_reason = paste(
    'Historical 2010 Pacific Coast rougheye inventory row. The 2013 formal',
    'West Coast assessment pooled rougheye and blackspotted rockfish and',
    'defined the U.S. coastwide assessment area, which is represented by',
    'current NOAA:14516. Retain this row as a historical label in the same',
    'candidate unit, not as a separate current assessment case.'
  ),
  notes = paste(
    'The 2013 assessment reports the two species as a pooled complex and',
    'excludes Alaska and Canadian waters. The current 2025 assessment is the',
    'source-curation target; see noaa_rougheye_blackspotted_crosswalk.md.'
  )
))

set_values('NOAA:14516', list(candidate_unit_id = units[['NOAA:14516']]))

set_values('NOAA:11382', list(
  candidate_unit_id = units[['NOAA:11382']],
  scientific_name = 'Sebastes aleutianus; Sebastes melanostictus',
  assessment_area = 'Bering Sea / Aleutian Islands', match_status = 'new',
  screening_status = 'screened', eligibility = 'eligible', import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 update includes catch data through 2023 and fishery age',
    'compositions for the age-structured Aleutian Islands model component.',
    'Catch-at-age can be reconstructed from aggregate catches and the',
    'reported fishery age compositions.'
  ),
  survey_age_evidence = paste(
    'The Aleutian Islands model uses survey biomass and age-composition data.',
    'The 2024 update adds 2024 survey biomass and length composition and uses',
    'the 2022 AI survey age composition. The eastern Bering Sea component is',
    'not age-structured.'
  ),
  weights_evidence = paste(
    'The report gives a weight-at-age vector derived from survey growth and',
    'length-weight relationships for the AI model component.'
  ),
  maturity_evidence = paste(
    'The AI model estimates maturity-at-age using biological samples; the',
    'report provides age-specific maturity with the 2023/2024 population outputs.'
  ),
  mortality_evidence = paste(
    'Natural mortality is modeled with a lognormal prior centered at 0.045 per',
    'year; the report describes model estimates and alternative values.'
  ),
  timing_evidence = paste(
    'Annual fishery and AI survey series are identified in the SAFE chapter.',
    'The exact within-year fractions are not stated in the reviewed report and',
    'remain to be verified from the run-matched data before translation.'
  ),
  output_evidence = paste(
    'The SAFE report provides AI age-specific numbers, total biomass, spawning',
    'biomass, recruitment, and uncertainty. EBS is represented by Tier 5 survey',
    'biomass estimates rather than age-specific population outputs.'
  ),
  detailed_source_url = bsai_url, review_date = review_date,
  decision_reason = paste(
    'NOAA Stock SMART ID 11382 is the current BSAI rougheye/blackspotted',
    'complex. The latest reviewed 2024 SAFE update retains an age-structured',
    'model for the Aleutian Islands component and a non-age-structured Tier 5',
    'method for eastern Bering Sea. Screen eligible for source curation only',
    'with explicit AI-only age coverage; do not imply age-specific outputs for',
    'the complete BSAI complex. The 2026 update was scheduled for later review.'
  ),
  notes = paste(
    'The 2024 report says the last full assessment was in 2022. NOAA:15394 is',
    'the Eastern Bering Sea component and NOAA:15395 is a historical Aleutian',
    'Islands row; both are grouped under this BSAI candidate unit and not counted',
    'as separate stocks. Exact survey timing remains unverified.', cache_note
  )
))

set_values('NOAA:15394', list(
  candidate_unit_id = units[['NOAA:15394']],
  scientific_name = 'Sebastes aleutianus; Sebastes melanostictus',
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started', detailed_source_url = bsai_url,
  review_date = review_date,
  decision_reason = paste(
    'This NOAA inventory row names the Eastern Bering Sea portion of the',
    'BSAI complex. The official 2024 SAFE describes EBS as a non-age-structured',
    'Tier 5 component within the BSAI assessment. Link it to NOAA:11382 as a',
    'subarea record; do not count it as a separate current stock or an',
    'age-structured candidate.'
  ),
  notes = paste(
    'NOAA:15394 is the EBS subarea record for the BSAI management complex;',
    'the 2024 SAFE describes the whole BSAI complex as AI age-structured plus',
    'EBS Tier 5. Age-specific curation eligibility applies to the AI model',
    'component only.', cache_note
  )
))

set_values('NOAA:15395', list(
  candidate_unit_id = units[['NOAA:15395']],
  scientific_name = 'Sebastes aleutianus; Sebastes melanostictus',
  assessment_area = 'Aleutian Islands', match_status = 'new',
  screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  detailed_source_url = 'https://apps-afsc.fisheries.noaa.gov/REFM/Docs/2016/BSAIrougheye.pdf',
  review_date = review_date,
  decision_reason = paste(
    'This historical Aleutian Islands inventory row belongs to the BSAI',
    'rougheye/blackspotted assessment unit represented by current NOAA:11382.',
    'The 2016 full assessment describes age-structured assessments for the AI',
    'portion during 2008-2015. Retain NOAA:15395 as a historical component',
    'record, not a separate current assessment case.'
  ),
  notes = paste(
    'NOAA:15395 is the historical 2008 Aleutian Islands entry. The official',
    '2016 BSAI assessment documents the age-structured AI model history. The',
    'current 2024 SAFE retains an AI age-structured component and an EBS Tier 5',
    'component under the BSAI unit. Do not count this row separately.', cache_note
  )
))

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
starts <- grep('^"(NOAA|ICES|DFO):', lines, perl = TRUE)
if (length(starts) != nrow(x)) stop('Could not map CSV records to physical lines.', call. = FALSE)
spans <- data.frame(
  id = ids,
  start = starts[match(ids, x$candidate_id)],
  stringsAsFactors = FALSE
)
spans$end <- vapply(spans$start, function(record_start) {
  later <- starts[starts > record_start]
  if (length(later)) min(later) - 1L else length(lines)
}, integer(1))
tmp <- tempfile(fileext = '.csv')
for (j in order(spans$start, decreasing = TRUE)) {
  i <- match(spans$id[j], x$candidate_id)
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  if (length(updated) != 1L) stop('Updated CSV record unexpectedly contains line breaks.', call. = FALSE)
  lines <- c(lines[seq_len(spans$start[j] - 1L)], updated,
    if (spans$end[j] < length(lines)) lines[(spans$end[j] + 1L):length(lines)] else character())
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

source(file.path('scripts', 'database', '195_summarize_discovery.R'))
source(file.path('scripts', 'database', '196_summarize_inventory_units.R'))

cat('Reconciled NOAA rougheye/blackspotted historical and component rows into three regional assessment units.\n')
