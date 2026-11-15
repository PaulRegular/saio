root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)

ids <- c('NOAA:10058', 'NOAA:15410', 'NOAA:15411')
source_review <- file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_rex_sole_2026.md')
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected NOAA rex sole inventory rows are missing.', call. = FALSE)
if (any(stocks$scientific_name == 'Glyptocephalus zachirus')) {
  stop('A canonical rex sole stock is present; reconcile it before screening.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_goa_rex_sole',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The final 2026 assessment reports fishery catch biomass in tonnes from 1982 through August 2026',
    '(Table 7 says August 29; page 9 says August 22 for the terminal catch cutoff),',
    'and sex-specific fishery age compositions in 1992, 1995, 1999, 2003, 2005, 2007,',
    '2009, 2010, 2012 and 2014-2024. The compositions are sampled proportions, not',
    'catch numbers-at-age; reconstruction requires catch biomass and weight-at-age.'
  ),
  survey_age_evidence = paste(
    'The RACE bottom-trawl survey provides separate eastern and western-central biomass',
    'indices for 1984-1999 (triennial) and 2001-2025 (biennial), with conditional',
    'age-at-length data in 1984, 1987, 1993, 1999 and biennially from 2001-2025.',
    'Marginal age compositions are not in the objective function; an age-specific',
    'survey index would be a documented reconstruction, not the native likelihood.',
    'Table 7 ends in 2025 while page 11 labels 112,824 t as a 2026 survey estimate; verify the year.'
  ),
  weights_evidence = paste(
    'Sex- and area-specific growth is estimated. Fixed weight-length relationships are',
    'female alpha 1.35e-6, beta 3.44963 and male alpha 2.18e-6, beta 3.30571; weight',
    'at age depends on the growth curves. Confirm the exact final-run weight scale before import.'
  ),
  maturity_evidence = paste(
    'Female maturity uses a logistic size-at-maturity relationship: 50% at 351.7 mm,',
    'with slope 0.0392 per mm, converted to age using survey-based mean length-at-age.'
  ),
  mortality_evidence = paste(
    'Natural mortality is fixed at 0.17 per year for females and males; M is not estimated.'
  ),
  timing_evidence = paste(
    'The assessment is annual. The available proposed-run file has one 12-month season and assigns',
    'survey biomass observations to month 7, but it ends in 2024 and is not the final 2026',
    'run. The SSC notes survey timing was misspecified in the SS3-to-SPoRC bridge; verify',
    'the final-run timing before translation and do not infer a year fraction yet.'
  ),
  output_evidence = paste(
    'Appendix F reports Model 25.1 numbers-at-age for 1982-2026 by two areas and sex,',
    'ages 0-20. It gives no uncertainty intervals and does not state the number scale in',
    'the heading. The report also gives spawning-biomass and recruitment results; a numeric',
    'F-at-age surface was not located. M is fixed at 0.17, not an estimated output.'
  ),
  detailed_source_url = paste(
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=6.+GOA+Rex+Sole.pdf&p=44a13dd4-61ed-4ab1-9eb8-69094d5e517b.pdf;',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C3+GOA+Groundfish+Plan+Team+Report.pdf&p=1e1317f4-91d2-49f2-91ca-ae9865e7e7bc.pdf;',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+October+2026+FINAL.pdf&p=72476d9c-c900-4f64-8e25-bb9dc7842c26.pdf;',
    'https://github.com/noaa-afsc/goa_rex/tree/453e1166e1bf83b9062fe228b93f2225b1cbe1aa'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The official 2026 full assessment is a two-area assessment for the current Gulf of Alaska',
    'unit. The Plan Team recommended Model 25.1 for harvest specifications and the SSC supported',
    'the recommendation. The assessment documents age compositions, conditional survey',
    'age-at-length, biological inputs, survey indices and comparable population outputs.',
    'The source quantities support curation, with transformations and run-matched input details',
    'to verify before import.'
  ),
  notes = paste(
    'NOAA IDs 10058, 15410 and 15411 are grouped as one unit: 10058 is the legacy Gulf-wide',
    'entry; 15410 and 15411 are eastern and western-central area entries. NOAA ID 10059',
    'Pacific Coast rex sole is a separate unit. The public AFSC repository at revision',
    '453e1166e1bf83b9062fe228b93f2225b1cbe1aa contains proposed runs ending in 2024, not',
    'run-matched final 2026 files. The final-report-linked Appendix E attachment is marked',
    'draft; confirm its correspondence to the final model before importing values. See the',
    'source review and ignored source_cache/discovery_noaa_goa_rex_2026/sources.csv.'
  )
)

if (all(x$screening_status[i] == 'screened')) {
  for (column in names(review)) {
    if (!all(as.character(x[[column]][i]) == as.character(review[[column]]))) {
      stop(paste('Previously screened NOAA rex sole field changed:', column), call. = FALSE)
    }
  }
  if (!file.exists(source_review)) stop('NOAA rex sole source review is missing.', call. = FALSE)
  cat('NOAA Gulf of Alaska rex sole already screened; no canonical data imported.\n')
  quit(save = 'no', status = 0L)
}

if (any(x$match_status[i] != 'unreviewed') || any(x$screening_status[i] != 'not_started')) {
  stop('Preserve the existing review state before screening NOAA rex sole.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
for (j in seq_along(i)) {
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i[j], , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i[j] + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Gulf of Alaska rex sole; no canonical data imported.\n')
