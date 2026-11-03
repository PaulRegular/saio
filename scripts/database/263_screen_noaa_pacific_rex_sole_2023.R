root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)

id <- 'NOAA:10059'
source_review <- file.path(root, 'discovery', 'source_reviews',
  'noaa_pacific_rex_sole_2023.md')
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected NOAA Pacific Coast rex sole row is missing.', call. = FALSE)
if (any(stocks$scientific_name == 'Glyptocephalus zachirus')) {
  stop('A canonical rex sole stock is present; reconcile it before screening.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_pacific_rex_sole',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2023 production assessment includes catch biomass and fishery length compositions,',
    'with discards modeled separately from landings beginning in 2002. Its native data file',
    'has no fishery age-composition rows. Catch-at-age can be reconstructed from fishery',
    'length compositions and an age-length key informed by WCGBTS ages and fitted growth;',
    'this would be an approximation, not a native observed age series.'
  ),
  survey_age_evidence = paste(
    'Three aggregate survey-index fleets are included. WCGBTS fleet 5 has conditional',
    'age-at-length observations in 2007-2019 (620 aged fish, per the report), alongside',
    'survey length compositions. These are not a marginal age composition or age-specific',
    'index; an age-specific index could be reconstructed from the survey index, lengths and',
    'conditional age information and must be labeled as approximate.'
  ),
  weights_evidence = paste(
    'The report and native model archive provide weight-at-length and fitted growth inputs.',
    'Age-specific weights would be derived from the growth and weight-length relationships;',
    'preserve their source and transformation.'
  ),
  maturity_evidence = paste(
    'Maturity-at-length is based on Hosie and Horton (1977); the report says the logistic',
    'slope was assumed from Abookire (2006). Translate to age only with a documented',
    'growth-based conversion.'
  ),
  mortality_evidence = paste(
    'The control file specifies a one-parameter natural-mortality structure. Confirm the',
    'active parameter status, estimate and uncertainty in the selected base-run outputs.'
  ),
  timing_evidence = paste(
    'The model uses one annual 12-month season and three survey fleets. Verify the exact',
    'within-year timing encoded by the final native input before assigning a tinyAM survey',
    'fraction; do not infer it from the survey field season.'
  ),
  output_evidence = paste(
    'The native run archive includes Report.sso with numbers-at-age, catch-at-age,',
    'fishing-mortality-at-age, biomass-at-age and fitted age-composition output enabled.',
    'The report also gives spawning-output and recruitment summaries. Verify scales,',
    'coverage and uncertainty conventions before import.'
  ),
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2024/02/status-of-rex-sole-glyptocephalus-zachirus-along-the-u-s-west-coast-in-2023.pdf/;',
    'https://www.pcouncil.org/documents/2024/02/rex-sole-2023-model-files.zip/; NOAA Stock SMART entity 10059 (locked assessment ID 12970)'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2023 locked production assessment includes WCGBTS conditional age-at-length data,',
    'fishery and survey length compositions, aggregate survey indices, biological inputs',
    'and numeric age-specific model outputs. Age-specific catch and survey inputs are',
    'reconstructable only as documented approximations; retain native observations and',
    'do not describe reconstructed values as observed age series.'
  ),
  notes = paste(
    'Stock SMART entity 10059, assessment ID 12970 (locked), is a Pacific Coast unit',
    'distinct from GOA rex sole. The assessment data include 620 WCGBTS ages from',
    '2007-2019 (350 female, 231 male, 39 unsexed). Cross-organization identity review,',
    'final-run timing, active M parameter status, output scales and uncertainty remain to',
    'be verified before import. See the source review and ignored source_cache/',
    'discovery_noaa_pacific_rex_2023/sources.csv.'
  )
)

if (x$screening_status[i] == 'screened') {
  for (column in names(review)) {
    if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
      stop(paste('Previously screened Pacific rex sole field changed:', column), call. = FALSE)
    }
  }
  if (!file.exists(source_review)) stop('Pacific rex sole source review is missing.', call. = FALSE)
  cat('NOAA Pacific Coast rex sole already screened; no canonical data imported.\n')
  quit(save = 'no', status = 0L)
}

if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review state before screening Pacific rex sole.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Pacific Coast rex sole; no canonical data imported.\n')
