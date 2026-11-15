# Screen NOAA's US West Coast arrowtooth flounder inventory row against the
# 2017 detailed assessment and the later catch-only projection advice.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10005', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Pacific Coast arrowtooth row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'unresolved')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Atheresthes stomias'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2017 report documents three fishery catch series (mink-food, fillet,',
  'discard) in tonnes and limited sex-specific age compositions from the',
  'fillet fishery. The age samples are sparse (1986-1991, 1998, 2003-2005,',
  '2013); they are not annual catch-at-age. The report describes reconstructed',
  'landings/discards and lists the native .dat file, but that file was not',
  'found among public downloads.'
)
x$survey_age_evidence[i] <- paste(
  'Four aggregate biomass survey indices are used. The NWFSC shelf-slope',
  'survey has sex-specific age-at-length data in 2003-2006 and 2013-2016,',
  'ages 1-28; the likelihood uses conditional age-at-length rather than a',
  'direct age-specific abundance index. The report lists model inputs, but',
  'the exact composition matrices were not publicly located.'
)
x$weights_evidence[i] <- paste(
  'The report documents an externally estimated length-weight relationship',
  'and estimated sex-specific growth. It does not provide direct numeric',
  'weight-at-age input vectors; those would require the fitted growth and',
  'length-weight parameters from the unavailable native files.'
)
x$maturity_evidence[i] <- paste(
  'Female maturity is a fixed length-based logistic ogive (slope 0.5,',
  'inflection 37.3 cm) carried forward from Rickey (1993). A numeric',
  'maturity-at-age series is not reported.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is fixed by sex at 0.216 per year for females and',
  '0.300 per year for males, the medians of documented lognormal priors.'
)
x$timing_evidence[i] <- paste(
  'The assessment report says survey calendar-date effects were not',
  'investigated. A within-year survey fraction is unresolved.'
)
x$output_evidence[i] <- paste(
  'The report provides annual spawning biomass and age-0 recruitment with',
  'standard deviations for 1916-2017, plus total biomass, age-3+ biomass,',
  'depletion and annual F rate. It names an annual sex-specific N-at-age CSV,',
  'but this output file was not located in public downloads.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2017/12/2017-assessment-update-for-the-us-west-coast-stock-of-arrowtooth-flounder.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'Identity is distinct from the Bering Sea/Aleutian Islands, Gulf of Alaska',
  'and British Columbia units. Eligibility remains unresolved: the assessment',
  'has age data, but annual numeric catch-at-age is not available and its',
  'age likelihood is composition/age-at-length based. The 2017 report lists',
  'native model inputs and an N-at-age output CSV, but those files could not',
  'be recovered from the public Council listing or direct file URLs. Exact',
  'inputs and age-specific outputs need verification before selection.'
)
x$notes[i] <- paste(
  'Stock SMART ID 10005 lists the scientific name Reinhardtius stomias; the',
  'official assessment identifies the stock as Atheresthes stomias. The 2017',
  'Stock Synthesis update is the latest detailed fitted assessment located.',
  'Subsequent advice uses catch-only projections based on that model: the',
  '2021 projection informs 2027-2028 specifications in the 2026 Council',
  'analysis. The projection updates catches, not the age-structured fit.',
  'See source_reviews/noaa_west_coast_arrowtooth.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
