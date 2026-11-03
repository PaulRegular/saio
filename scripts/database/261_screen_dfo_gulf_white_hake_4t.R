root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Gulf:White Hake - NAFO 4T'
source_review <- file.path(root, 'source_reviews',
  'dfo_white_hake_4t_2022.md')

if (any(grepl('White Hake', stocks$common_name, ignore.case = TRUE) &
    grepl('4T', stocks$area, fixed = TRUE), na.rm = TRUE)) {
  stop('A possible DFO 4T white hake canonical stock already exists; reconcile before screening.',
    call. = FALSE)
}

i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Gulf white hake inventory row is missing.', call. = FALSE)

review <- list(
  scientific_name = 'Urophycis tenuis',
  inventory_assessment_year = 2022,
  assessment_area = 'NAFO Division 4T, southern Gulf of St. Lawrence',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The official age-structured assessment uses total annual fishery catch',
    'and fishery age compositions. Research Document 2025/008 Appendix Table A4',
    'reports commercial catch-at-age in thousands for 1978-2022, with bins',
    '0-2, ages 3-12 and 13+. The model grid is ages 2-10+, so age-bin mapping',
    'must be resolved and documented before import.'
  ),
  survey_age_evidence = paste(
    'The model likelihood uses age-aggregated RV and Mobile Sentinel biomass',
    'indices for ages 2-7 plus survey proportions-at-age. Appendix Table A5',
    'also reports September RV stratified catch rates by age (fish/tow) for',
    'ages 2-14 and 1978-2022, which supports a documented age-indexed',
    'translation while preserving the native aggregate likelihood inputs.'
  ),
  weights_evidence = paste(
    'Age-specific weights from the fishery, RV and Mobile Sentinel surveys',
    'are identified as model inputs. Appendix Table A6 supplies RV mean',
    'weight-at-age in kg for 1978-2022; fishery and Mobile Sentinel numeric',
    'vectors still need recovery or verification before import.'
  ),
  maturity_evidence = paste(
    'The assessment assumes knife-edge maturity: ages 2-3 are immature and',
    'age 4 and older are fully mature.'
  ),
  mortality_evidence = paste(
    'The official model estimates independent natural-mortality time series',
    'for ages 2-3, 4-5 and 6+, with log-scale random-walk deviations.'
  ),
  timing_evidence = paste(
    'The RV survey is conducted in September and the Mobile Sentinel survey',
    'in August. The reports do not specify exact within-month fractions of',
    ''
  ),
  output_evidence = paste(
    'The Science Advisory Report gives 2022 SSB as 6.1 kt and reports annual',
    'SSB, age-2 recruitment, age-6+ fishing mortality and age-group M',
    'trajectories. The detailed report describes MCMC-based intervals, but',
    'numeric annual uncertainty and N/F-at-age arrays were not recovered.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-6/Fs70-6-2024-055-eng.pdf;',
    'https://open-science.canada.ca/server/api/core/bitstreams/28963929-7d4b-47c6-a56d-c0d705be4621/content'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The official 2024 assessment is an age-structured model for the current',
    'DFO management unit, NAFO Division 4T, with source catch, survey age',
    'information, biological inputs, mortality assumptions and comparable',
    'population outputs. This is a distinct Canadian unit, not the existing',
    'NOAA Gulf of Maine/Georges Bank white hake stock. The directly reported',
    'age bins and non-RV weight vectors require further extraction before import.'
  ),
  notes = paste(
    'Assessment terminal year: 2022. The model covers 1978-2022 and ages 2-10+.',
    'Treat the age-specific RV catch-rate table as a reconstruction source, not',
    'as the assessment’s native likelihood (aggregate biomass plus age',
    'composition). Preserve native units and likelihood structure in the',
    'canonical database; translation remains unattempted.'
  )
)

if (x$screening_status[i] == 'screened') {
  for (column in names(review)) {
    if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
      stop(paste('Previously screened DFO white hake field changed:', column), call. = FALSE)
    }
  }
  if (!file.exists(source_review)) stop('DFO white hake source review is missing.', call. = FALSE)
  cat('DFO 4T white hake already screened; no canonical data imported.\n')
  quit(save = 'no', status = 0L)
}

if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review state before screening DFO 4T white hake.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened DFO NAFO 4T white hake; no canonical data imported.\n')
