path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:hom.27.4bc7d'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one ICES North Sea horse mackerel inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'ices_north_sea_horse_mackerel',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 WKBHMB benchmark reports catch-at-age in tonnes for ages 0-14 and',
    'years 2002-2022 (Table 4.2), with weight-at-age in kg (Table 4.3), allowing',
    'a documented number conversion for that prior benchmark. The latest 2026',
    'production-run catch-at-age inputs have not been recovered; the 2024 tables',
    'must not be substituted for the current run.'
  ),
  survey_age_evidence = paste(
    'The 2024 benchmark describes a combined FR-CGFS Q4 and NS-IBTS Q3 biomass/SSB',
    'index and a commercial CPUE series; the reviewed sources do not provide survey',
    'age compositions or an age-specific abundance index. Current 2026 run-matched',
    'index inputs have not been recovered.'
  ),
  weights_evidence = paste(
    'The 2024 WKBHMB benchmark reports catch weight-at-age in kg for ages 0-14 and',
    'years 2002-2022 (Table 4.3). The 2026 production-run weight inputs and any',
    'subsequent changes have not been verified.'
  ),
  maturity_evidence = paste(
    'The 2024 benchmark used the Western horse mackerel maturity-at-age ogive for',
    'ages 0-14 (Table 4.6), because a North Sea-specific ogive was unavailable.',
    'Use of this ogive in the 2026 production run is not yet confirmed.'
  ),
  mortality_evidence = paste(
    'The 2024 benchmark adopted the Western horse mackerel natural-mortality-at-age',
    'vector, ages 0-14 (Table 4.5; M declines from 1.07 to 0.19 per year). The 2026',
    'production-run mortality assumptions have not been verified.'
  ),
  timing_evidence = paste(
    'The 2024 benchmark used NS-IBTS quarter 3, FR-CGFS quarter 4, and commercial',
    'CPUE for 2017-2023. Exact fractional within-year observation timing is not',
    'specified in the reviewed sources, and current-run timing remains unverified.'
  ),
  output_evidence = paste(
    'ICES 2026 assessment key 25921 provides historical recruitment at age 1, SSB,',
    'and F for ages 2-8 for 2002-2025 with lower and upper uncertainty values, plus',
    'a 2026 forecast point without intervals. It does not provide numeric N-at-age',
    'or full F-at-age surfaces.'
  ),
  detailed_source_url = paste(
    'https://doi.org/10.17895/ices.pub.25002482.v2;',
    'https://asd.ices.dk/viewAdvice/7227;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25921;',
    'https://sid.ices.dk/Default.aspx'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The current ICES stock key hom.27.4bc7d is the North Sea unit in divisions',
    '4.b, 4.c and 7.d, distinct from the canonical southern horse mackerel unit in',
    'division 9.a. The 2024 benchmark used key hom.27.3a4bc7d; do not transfer its',
    'division 3.a data without confirming current stock allocation. ICES identifies',
    'the current production method as SAM and publishes',
    '2026 aggregate outputs. The 2024 benchmark documents a prior age-structured SAM',
    'input set, but run-matched inputs for the latest assessment were not recovered.',
    'Eligibility remains unresolved until current-run catch, biology and index inputs',
    'are verified; older benchmark values are not substituted.'
  ),
  notes = paste(
    'The 2024 benchmark source and 2026 advice/SAG output pages are cached under',
    'source_cache/discovery_ices_north_sea_horse_mackerel_2026/ with source URLs,',
    'retrieval dates and SHA-256 checksums. No canonical data were imported.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
legacy_review <- list(
  output_evidence = paste(
    'ICES 2026 assessment key 25921 provides annual recruitment at age 1, SSB,',
    'and F for ages 2-8, with lower and upper uncertainty values, through 2025.',
    'It does not provide numeric N-at-age or full F-at-age surfaces.'
  ),
  decision_reason = paste(
    'The current ICES stock key hom.27.4bc7d is the North Sea unit in divisions',
    '4.b, 4.c and 7.d, distinct from the canonical southern horse mackerel unit in',
    'division 9.a. ICES identifies the current production method as SAM and publishes',
    '2026 aggregate outputs. The 2024 benchmark documents a prior age-structured SAM',
    'input set, but run-matched inputs for the latest assessment were not recovered.',
    'Eligibility remains unresolved until current-run catch, biology and index inputs',
    'are verified; older benchmark values are not substituted.'
  )
)
matches_legacy <- all(vapply(setdiff(names(review), names(legacy_review)), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L))) && all(vapply(names(legacy_review), function(column) {
  identical(as.character(x[[column]][i]), as.character(legacy_review[[column]]))
}, logical(1L)))

if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (matches_legacy) {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  differs <- names(review)[!vapply(names(review), function(column) {
    identical(as.character(x[[column]][i]), as.character(review[[column]]))
  }, logical(1L))]
  stop('Candidate row has a conflicting prior review in: ',
    paste(differs, collapse = ', '), call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE)
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the distinct 2026 ICES North Sea horse mackerel unit; current-run input eligibility remains unresolved.\n')
