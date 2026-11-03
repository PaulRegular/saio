root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Newfoundland and Labrador:Atlantic Herring - NAFO 2J3KLPs'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO Newfoundland herring inventory row.', call. = FALSE)
}

review <- list(
  official_stock_id = 'NAFO 2J3KLPs',
  scientific_name = 'Clupea harengus',
  assessment_area = paste(
    'NAFO 2J3KLPs management area; latest assessment covers five distinct',
    'biological complexes in NAFO 3KLPs'
  ),
  inventory_assessment_year = 2025L,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'Research Document 2025/079 describes annual commercial catch numbers-at-age',
    'derived from landings, mean weights and processor sample age proportions,',
    'with figures by complex and spawning type. These are fishery indicators, not',
    'inputs to the index-based population assessment; a complete numerical annual',
    'age-vector series is not tabulated.'
  ),
  survey_age_evidence = paste(
    'The standardized spring research-gillnet program provides mainly age-4+',
    'catch-rate indices and an age-4 recruitment index; acoustic surveys provide',
    'aggregate biomass indices, not age-specific abundance indices.'
  ),
  weights_evidence = paste(
    'Acoustic biomass calculations use survey-level mean weights derived from',
    'length and a length-weight relationship. Length-at-age is discussed, but no',
    'population-model weight-at-age surface is used.'
  ),
  maturity_evidence = paste(
    'Maturity and age-at-maturity are discussed, and maturity stage informs',
    'spawning-type designation; no population-model maturity-at-age surface is used.'
  ),
  mortality_evidence = paste(
    'The official assessment is index-based and reports no population-level',
    'fishing-mortality or natural-mortality surface.'
  ),
  timing_evidence = paste(
    'The research gillnet program is a spring survey conducted over a 45-day',
    'period between April 1 and July 31; acoustic surveys occur in fall or winter.',
    'No population-model likelihood or within-year model timing is specified.'
  ),
  output_evidence = paste(
    'Outputs are research-gillnet stock-status and recruitment indices, catch',
    'compositions, and episodic aggregate acoustic biomass indices; no fitted',
    'population-at-age or mortality outputs are reported.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41311899.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41299292.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/Library/359697.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The inventory label is a 2J3KLPs management area, while the latest full',
    'assessment covers five separate biological complexes in 3KLPs; this row',
    'cannot be matched one-to-one to a canonical stock. Although commercial',
    'catch numbers-at-age and age-based indices are reported, the current official',
    'method is index-based and does not estimate age-structured population or',
    'mortality outputs. The inventory row is ambiguous and ineligible for the',
    'age-structured population-assessment candidate set. No canonical records added.'
  ),
  notes = paste(
    'Research Document 2025/079, published December 2025, documents the full',
    'assessment reviewed in October 2022 using data to 2021; Science Response',
    '2025/023 updates indicators to 2024. Five 3KLPs complexes are WBNDB, BBTB,',
    'CBSS, SMBPB and FB; spring/fall spawning components occur within complexes.',
    'See discovery/source_reviews/dfo_nl_herring_3klps_2025.md. Source PDFs and',
    'checksums are cached locally under discovery_dfo_nl_herring_2025/.'
  )
)

if (x$screening_status[i] == 'screened') {
  if (x$match_status[i] != 'ambiguous' || x$eligibility[i] != 'ineligible' ||
      x$import_status[i] != 'not_started') {
    stop('Preserve the existing DFO herring identity and eligibility decisions.', call. = FALSE)
  }
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing DFO herring review state before screening.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Unexpected multiline rows in candidate register.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened DFO 2J3KLPs herring: ambiguous management boundary and index-based assessment.\n')