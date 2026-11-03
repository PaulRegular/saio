# Screen NOAA Dover sole against the 2021 full assessment and its native model files.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10022', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Dover sole row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Microstomus pacificus'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2021 Stock Synthesis data file contains retained catches for two',
  'fisheries and year/sex/fleet age-composition observations, ages 1-60.',
  'Age compositions are available rather than complete observed catch-at-age;',
  'catch-at-age can be reconstructed from totals, compositions and weights.',
  'The assessment reports limited new fishery age readings after 2010.'
)
x$survey_age_evidence[i] <- paste(
  'Four aggregate survey-index series are included. The native data file',
  'includes conditional age-at-length records for the NWFSC Slope and',
  'WCGBTS surveys and derived marginal WCGBTS ghost compositions. The latter',
  'are not independent likelihood observations. An age-specific index would',
  'require a documented conversion from the aggregate index and age data.'
)
x$weights_evidence[i] <- paste(
  'The two-sex model uses size-based growth and weight-length relationships,',
  'not a fixed observed weight-at-age input. Derived age-specific weights are',
  'available in the official fitted model output.'
)
x$maturity_evidence[i] <- paste(
  'The official model uses a length-based female maturity relationship and',
  'length/weight-based fecundity; derived age-specific biology is reported.'
)
x$mortality_evidence[i] <- paste(
  'Female natural mortality is fixed at 0.108 per year; male M is estimated',
  'as an offset from female M. The fitted model reports the resulting values.'
)
x$timing_evidence[i] <- paste(
  'The native input specifies survey timing months: AFSC Slope 10, Triennial',
  '7, NWFSC Slope 9 and WCGBTS 8. These settings are available for review.'
)
x$output_evidence[i] <- paste(
  'The official Report.sso includes numbers-at-age, catch-at-age, F-at-age',
  'and biomass-at-age, as well as aggregate biomass and recruitment outputs.',
  'Age-specific fitted outputs are not observed catch-age inputs.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2021/10/status-of-dover-sole-microstomus-pacificus-along-the-u-s-west-coast-in-2021.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'No matching canonical US West Coast Dover sole stock was found. The',
  'public 2021 full assessment bundle provides native age-composition and',
  'survey age information, aggregate catch/index inputs, biological model',
  'files, and official age-specific population and mortality outputs.',
  'Mark eligible for source import and a documented age-structured',
  'approximation; this does not imply a like-for-like SS translation.'
)
x$notes[i] <- paste(
  'NOAA Stock SMART ID 10022; one coastwide US stock unit, distinct from',
  'Canadian Dover sole. The 2021 assessment uses data through 2020. The',
  '2021 model-file ZIP includes native inputs and fitted outputs; recent',
  'management projections reviewed remain based on the 2021 full assessment.',
  'See discovery/source_reviews/noaa_pacific_coast_dover_sole.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)