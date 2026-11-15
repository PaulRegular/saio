path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  candidate_id = 'DFO:Arctic:Arctic Char - Cambridge Bay',
  official_stock_id = '',
  scientific_name = 'Salvelinus alpinus',
  inventory_assessment_year = '2021',
  catch_age_evidence = paste(
    'Annual harvest is reported by river in tonnes. Fish plant and survey samples include',
    'otolith ages, but the reviewed assessment does not use catch numbers-at-age.'
  ),
  survey_age_evidence = paste(
    'The Halokvik and Jayko reports describe short abundance-index series, including',
    'historical weir counts and 2010-2015 multi-mesh gillnet surveys. Age data from these',
    'surveys describe sampled fish; no age-specific abundance index is reported.'
  ),
  weights_evidence = paste(
    'Individual round weights are recorded in grams and weight-at-age growth is modelled',
    'for the sampled Halokvik and Jayko fish. These are biological samples and growth',
    'results, not a run-matched population weight-at-age input to DB-SRA.'
  ),
  maturity_evidence = paste(
    'The DB-SRA uses age-at-maturity; the Halokvik and Jayko report gives estimated ages',
    'at 50% maturity, not annual maturity-at-age input vectors.'
  ),
  mortality_evidence = paste(
    'Age-dependent M is calculated from empirical life-history, length-growth and',
    'weight-growth relationships. It is not estimated as part of an age-structured',
    'population model.'
  ),
  timing_evidence = paste(
    'Commercial fishing occurs in seasonal river runs, including downstream fishing in',
    'July and upstream fishing from mid-August to early September. The annual DB-SRA',
    'does not use a fractional survey timing.'
  ),
  output_evidence = paste(
    'The detailed Halokvik and Jayko report provides river-specific biomass trajectories',
    'and reference-point results from DB-SRA, plus growth and empirical M summaries.',
    'It does not provide fitted population N-at-age, F-at-age or annual recruitment.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40961308.pdf;',
    'https://publications.gc.ca/collections/collection_2021/mpo-dfo/fs70-5/Fs70-5-2019-062-eng.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/Library/350263.pdf;',
    'https://publications.gc.ca/collections/collection_2020/mpo-dfo/fs70-7/Fs70-7-2020-049-eng.pdf;',
    'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/arctic-char-omble-chev/arctic-char-omble-chev-eng.html'
  ),
  decision_reason = paste(
    'Ineligible for the age-disaggregated assessment set: the latest detailed models',
    'reviewed are DB-SRA/data-limited analyses based on aggregate harvest and biomass',
    'information; biological age samples and empirical age-dependent M do not constitute',
    'catch-at-age or age-specific population outputs.'
  ),
  notes = paste(
    'The 2021 IFMP treats the five current commercial river waterbodies as separate',
    'management units. The 2021 detailed assessment covers Halokvik and Jayko only; the',
    'Cambridge Bay survey row cannot be treated as one fitted stock or crosswalked to one',
    'candidate unit. Keep this aggregate row ambiguous until river-specific inventory',
    'entries and current assessment boundaries are reconciled. No canonical data were added.'
  )
)

i <- match(review$candidate_id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == review$candidate_id) != 1L) {
  stop('Expected single DFO Cambridge Bay Arctic Char inventory row was not found.', call. = FALSE)
}
if (!x$screening_status[i] %in% c('not_started', 'screened') ||
    !x$match_status[i] %in% c('unreviewed', 'ambiguous') ||
    !x$eligibility[i] %in% c('unresolved', 'ineligible') ||
    !is.na(x$candidate_unit_id[i]) && nzchar(x$candidate_unit_id[i])) {
  stop('DFO Cambridge Bay Arctic Char row has an unexpected prior review state.', call. = FALSE)
}
canonical_area <- paste(stocks$area, stocks$region, stocks$notes)
same_area <- grepl('Cambridge Bay|Halokvik|Jayko|Lauchlan|Ekalluk|Paliryuak',
  canonical_area, ignore.case = TRUE)
if (any(stocks$scientific_name == review$scientific_name & same_area, na.rm = TRUE)) {
  stop('A canonical Cambridge Bay Arctic Char record now exists; reconcile it before rerunning.',
    call. = FALSE)
}

review$match_status <- 'ambiguous'
review$screening_status <- 'screened'
review$eligibility <- 'ineligible'
review$import_status <- 'not_started'
review$review_date <- '2026-10-29'
for (column in names(review)) x[[column]][i] <- review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the DFO Cambridge Bay Arctic Char inventory entry; its five river management units remain unresolved as a single candidate.\n')
