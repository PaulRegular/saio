path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  candidate_id = 'DFO:Arctic:Arctic Char - Cumberland Sound',
  official_stock_id = '',
  scientific_name = 'Salvelinus alpinus',
  inventory_assessment_year = '2017',
  catch_age_evidence = paste(
    'Commercial harvest histories through 2016 and approximate subsistence harvest are',
    'inputs to aggregate population methods. Fish were aged in biological sampling, but',
    'the report does not provide or fit catch numbers-at-age.'
  ),
  survey_age_evidence = paste(
    'Fishery-independent multi-mesh gillnet sampling covered 2010-2015. It produced five',
    'years of CPUE (fish per 24 hours), but DFO states the CPUE was not used in the',
    'quantitative model. No age-specific abundance index is reported.'
  ),
  weights_evidence = paste(
    'Round weights (g) were measured in biological samples and varied by year, sex and',
    'sampling gear. No numerical population weight-at-age input is reported.'
  ),
  maturity_evidence = paste(
    'Maturity stages were sampled, but the report describes maturity classification as',
    'subjective and does not provide a run-matched maturity-at-age vector.'
  ),
  mortality_evidence = paste(
    'The report gives sample-based total mortality Z and survival estimates, and scalar',
    'Catch-MSY m parameters. It does not separate age-specific fishing and natural',
    'mortality; natural mortality of young ages is unknown.'
  ),
  timing_evidence = paste(
    'The biological and effort sampling occurred in stock-specific seasons (March for',
    'Ijaruvung; February-March for Iqalujjuaq; August-September for Irvine). No fractional',
    'survey timing for a population model is reported.'
  ),
  output_evidence = paste(
    'The report gives aggregate abundance and biomass estimates with 5th and 95th',
    'percentiles, plus Catch-MSY summaries and 2016 reference-point status. It does not',
    'report annual N-at-age, F-at-age or recruitment trajectories.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/Library/40726174.pdf;',
    'https://www.dfo-mpo.gc.ca/about-notre-sujet/engagement/2022/docs/fish-stock-provisions-dispositions-stocks-poissons-eng.pdf;',
    'https://www.dfo-mpo.gc.ca/species-especes/profiles-profils/arctic-char-omble-chevalier-eng.html;',
    'https://www.dfo-mpo.gc.ca/about-notre-sujet/publications/work-plan-travail/2026-2027/wp-pt-eng.html;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41199595.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41204177.pdf'
  ),
  decision_reason = paste(
    'Ineligible for the age-disaggregated assessment set: the latest detailed assessment',
    'located uses aggregate harvest and data-limited Baranov, Catch-MSY and depletion-corrected',
    'average-catch methods. Biological age samples and scalar mortality estimates are not',
    'age-structured likelihood inputs or population-at-age outputs.'
  ),
  notes = paste(
    'The 2017 assessment, published as DFO Science Advisory Report 2018/021, covers three',
    'separate commercial waterbodies: Ijaruvung Lake (PG003), Iqalujjuaq Fiord (PG027) and',
    'Irvine Inlet (PG018). The 2022 proposed Fish Stock Provisions list these separately.',
    'The current DFO 2026-2027 work plan refers to monitoring-program risk screening for',
    'Iqalujjuaq and Irvine, not a replacement population assessment. Ikaluit Lake (Robert',
    'Peel Inlet), assessed separately in 2023, is not one of these three units. This inventory',
    'row cannot be assigned to one stock unit and remains ambiguous. No canonical data were added.'
  )
)

i <- match(review$candidate_id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == review$candidate_id) != 1L) {
  stop('Expected single DFO Cumberland Sound Arctic Char inventory row was not found.', call. = FALSE)
}
if (!x$screening_status[i] %in% c('not_started', 'screened') ||
    !x$match_status[i] %in% c('unreviewed', 'ambiguous') ||
    !x$eligibility[i] %in% c('unresolved', 'ineligible') ||
    !is.na(x$candidate_unit_id[i]) && nzchar(x$candidate_unit_id[i])) {
  stop('DFO Cumberland Sound Arctic Char row has an unexpected prior review state.', call. = FALSE)
}
stock_description <- paste(stocks$scientific_name, stocks$area, stocks$region, stocks$notes)
same_units <- grepl('Ijaruvung|Iqalujjuaq|Irvine Inlet', stock_description, ignore.case = TRUE)
if (any(stocks$scientific_name == review$scientific_name & same_units, na.rm = TRUE)) {
  stop('A canonical Cumberland Sound Arctic Char record now exists; reconcile it before rerunning.',
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
cat('Screened the DFO Cumberland Sound Arctic Char inventory row as an ambiguous multi-unit, age-structured-ineligible entry.\n')
