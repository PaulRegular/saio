path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:whg.27.3a'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one ICES Division 3.a whiting inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'ices_whiting_3a',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The reviewed 2026 official assessment is a Category 3 biomass-index',
    'assessment; its advice and source-data pages do not report catch-at-age',
    'as a fitted input. The source inventory does not establish whether raw age',
    'samples exist outside the reviewed assessment materials.'
  ),
  survey_age_evidence = paste(
    'The 2026 Stock Assessment Graphs source identifies stock size as B_index',
    'and reports an aggregate biomass-index series in tonnes. The reviewed',
    'official assessment materials do not document an age-specific survey',
    'likelihood or index.'
  ),
  weights_evidence = 'Age-specific stock weights are not documented for the current Category 3 assessment.',
  maturity_evidence = 'Age-specific maturity is not documented for the current Category 3 assessment.',
  mortality_evidence = 'An age-specific natural-mortality input is not documented for the current Category 3 assessment.',
  timing_evidence = 'The reviewed source-data page does not provide a fractional survey timing for an age-structured model.',
  output_evidence = paste(
    'The 2026 official source data report aggregate B_index values in tonnes',
    'from 1975-2025, with low/high bounds from 1983 onward, plus landings and',
    'discards. Relative F is shown for 2022-2025. The age and length output',
    'section has no age-specific population surfaces.'
  ),
  detailed_source_url = paste(
    'https://asd.ices.dk/viewAdvice/7159;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22563;',
    'https://sid.ices.dk/Default.aspx'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The ICES Division 3.a whiting unit is geographically distinct from the',
    'North Sea, Irish Sea and West of Scotland whiting records in the canonical',
    'database. Its latest official advice is for 2026 and assigns stock Category',
    '3. The corresponding SAG source identifies an aggregate B_index, not an',
    'age-structured assessment or age-specific outputs. It is therefore excluded',
    'from the age-structured candidate pool; this is not evidence that no raw age',
    'observations exist elsewhere.'
  ),
  notes = paste(
    'The 2026 ICES advice and SAG source pages are cached under',
    'source_cache/discovery_ices_whiting_3a_2026/ with retrieval dates and',
    'SHA-256 checksums. No canonical numerical data were imported.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  stop('Candidate row has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE)
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened distinct ICES whiting Division 3.a; current official assessment is an aggregate Category 3 index method.\n')
