# Screen current NOAA starry flounder entries and reconcile the legacy broad-area row.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:10025', 'NOAA:14804', 'NOAA:14805')
rows <- match(ids, x$candidate_id)
if (anyNA(rows)) stop('Expected NOAA starry flounder rows are missing.', call. = FALSE)
if (any(x$screening_status[rows] == 'screened')) {
  stopifnot(all(x$screening_status[rows] == 'screened'),
    x$match_status[rows[1L]] == 'ambiguous',
    all(x$match_status[rows[-1L]] == 'new'),
    all(x$eligibility[rows] == 'ineligible'))
} else if (any(x$screening_status[rows] != 'not_started') ||
           any(!x$match_status[rows] %in% c('unreviewed', 'ambiguous', 'new'))) {
  stop('Preserve the existing starry flounder reviews; candidate rows changed.', call. = FALSE)
}

legacy <- rows[1L]
x$match_status[legacy] <- 'ambiguous'
x$matched_stock_id[legacy] <- NA_character_
x$screening_status[legacy] <- 'screened'
x$eligibility[legacy] <- 'ineligible'
x$import_status[legacy] <- 'not_started'
x$catch_age_evidence[legacy] <- paste(
  'The NOAA Stock SMART 10025 row is the 2005 broad Pacific Coast assessment,',
  'not a current assessment unit. The current 2017 Northern and Southern',
  'entries use the DB-SRA report, which uses regional aggregate catch',
  'histories in metric tonnes rather than catch numbers-at-age.'
)
x$survey_age_evidence[legacy] <- paste(
  'The older 2005 assessment used relative trawl-logbook indices and a',
  'California age-1 abundance index, but no age- or length-composition data.',
  'Those are not inputs to the current 2017 DB-SRA, and this broad legacy',
  'entry is superseded by separate current Northern and Southern rows.'
)
x$weights_evidence[legacy] <- paste(
  'The current DB-SRA does not use age-specific weights. It uses life-history',
  'inputs and age at maturity; no current weight-at-age surface was found.'
)
x$maturity_evidence[legacy] <- paste(
  'The 2017 DB-SRA uses age at maturity of 3 years, not a maturity-at-age',
  'vector.'
)
x$mortality_evidence[legacy] <- paste(
  'The current DB-SRA uses a distribution for natural mortality as a',
  'life-history input; it does not estimate annual or age-specific M.'
)
x$timing_evidence[legacy] <- paste(
  'The current catch-based DB-SRA has no survey observation series requiring',
  'survey timing.'
)
x$output_evidence[legacy] <- paste(
  'The current DB-SRA reports MSY distributions and management harvest',
  'specifications, not annual N-at-age, F-at-age, or M-at-age. The 2027-28',
  'official specifications still cite the 2017 DB-SRA.'
)
x$detailed_source_url[legacy] <- 'https://www.pcouncil.org/documents/2017/11/agenda-item-f-6-attachment-3.pdf/'
x$review_date[legacy] <- '2026-10-29'
x$decision_reason[legacy] <- paste(
  'NOAA Stock SMART ID 10025 is the older 2005 broad Pacific Coast entry.',
  'The current 2017 assessment register has distinct Northern (14804) and',
  'Southern (14805) units. Treat the old row as an ambiguous historical',
  'identity linked to both current entries, not as a third current stock.',
  'The current DB-SRA inputs are not age-disaggregated.'
)
x$notes[legacy] <- paste(
  'The 2005 Stock Synthesis assessment modeled California and Oregon-Washington separately.',
  'The 2017 DB-SRA superseded those model projections',
  'for harvest specifications. Review current entries NOAA:14804 and',
  'NOAA:14805 together; see discovery/source_reviews/noaa_starry_flounder.md.'
)

for (j in rows[-1L]) {
  region <- if (x$official_stock_id[j] == '14804') 'Northern Pacific Coast (Oregon-Washington)' else 'Southern Pacific Coast (California)'
  x$match_status[j] <- 'new'
  x$matched_stock_id[j] <- NA_character_
  x$screening_status[j] <- 'screened'
  x$eligibility[j] <- 'ineligible'
  x$import_status[j] <- 'not_started'
  x$catch_age_evidence[j] <- paste(
    'The current 2017 DB-SRA for', region,
    'uses aggregate commercial and recreational catch/removals in metric tonnes,',
    'not catch numbers-at-age. The report documents reconstructed historical',
    'catch series and discard assumptions.'
  )
  x$survey_age_evidence[j] <- paste(
    'The current DB-SRA is based on catch history and life-history inputs; it',
    'does not use an age-specific abundance index or age compositions. The',
    'older 2005 assessment used no age- or length-composition data.'
  )
  x$weights_evidence[j] <- paste(
    'No age-specific weight input is used in the current DB-SRA; its',
    'life-history inputs are distributions for productivity and mortality.'
  )
  x$maturity_evidence[j] <- paste(
    'The current DB-SRA uses age at maturity of 3 years, not a',
    'maturity-at-age vector.'
  )
  x$mortality_evidence[j] <- paste(
    'Natural mortality is an input distribution derived from the prior',
    'assessment or DB-SRA conventions; it is not estimated at age.'
  )
  x$timing_evidence[j] <- paste(
    'No survey observation series is used by the current DB-SRA, so survey',
    'timing is not applicable to this assessment.'
  )
  x$output_evidence[j] <- paste(
    'The 2017 DB-SRA reports regional median MSY and uncertainty; the 2027-28',
    'specifications continue to use combined coastwide MSY/OFL 652 mt, ABC',
    '393 mt, and ACL 393 mt. No annual age-specific population or mortality',
    'outputs were found.'
  )
  x$detailed_source_url[j] <- 'https://www.pcouncil.org/documents/2017/11/agenda-item-f-6-attachment-3.pdf/'
  x$review_date[j] <- '2026-10-29'
  x$decision_reason[j] <- paste(
    'NOAA Stock SMART ID', x$official_stock_id[j], 'is the current', region,
    'assessment unit. The latest model used for 2027-28 harvest',
    'specifications remains the 2017 DB-SRA, which uses aggregate catch',
    'history and life-history distributions rather than age-disaggregated',
    'inputs or outputs. Ineligible for the age-structured candidate set.'
  )
  x$notes[j] <- paste(
    'NOAA Stock SMART metadata describe a', x$inventory_assessment_year[j], 'DB-SRA',
    'using data through 2016. The 2026',
    'harvest-specification analysis cites this assessment for 2027-28. See',
    'discovery/source_reviews/noaa_starry_flounder.md.'
  )
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[rows, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[rows + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
