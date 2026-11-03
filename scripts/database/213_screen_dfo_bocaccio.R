# Record the DFO BC coastwide Bocaccio source screen in the candidate register.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('DFO:Pacific:Bocaccio Rockfish', x$candidate_id)
if (is.na(i)) stop('Expected DFO Bocaccio row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'unresolved')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Sebastes paucispinis'
x$assessment_area[i] <- 'British Columbia coastwide (PMFC 3CD+5ABCDE)'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2024 update uses trawl and other-fishery catches in tonnes, but only',
  'the combined trawl fishery has age-frequency observations. The 2019 report',
  'shows weighted catch age proportions in figures, not a numeric array; the',
  'other-fishery removals cannot be allocated at age without an unsupported',
  'assumption.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment uses six fishery-independent biomass-index series, four',
  'synoptic series with age-frequency observations and two historical series',
  'without age compositions. The numeric age-frequency inputs are shown in',
  'figures in the 2019 report. New 2021 QCS ages were excluded from the 2024',
  'update because the readings were inaccurate and imprecise.'
)
x$weights_evidence[i] <- paste(
  'The 2019 research document reports sex-specific growth and length-weight',
  'relationships from which model weight-at-age is derived (Appendix D,',
  'Tables D.2 and D.5). A run-specific numeric weight-at-age matrix or model',
  'input bundle was not located.'
)
x$maturity_evidence[i] <- paste(
  'Female maturity-at-age is tabulated in Appendix D, Table D.8 and used as',
  'a fixed input; the model expresses spawning biomass as mature females.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is fixed in three component runs at M = 0.07, 0.08, and',
  '0.09 per year; the 2024 update pools 1,000 MCMC samples from each run.'
)
x$timing_evidence[i] <- paste(
  'The annual Awatea model places catches, age-composition samples, and',
  'relative-abundance indices at mid-year (fraction 0.5), after half-year',
  'fishing and natural mortality.'
)
x$output_evidence[i] <- paste(
  'The 2024 Science Response reports B2024 = 23,789 tonnes (5th-95th',
  'percentiles 13,549-48,165) in Table 7, plus spawning-biomass and',
  'age-1 recruitment trajectories in figures. Numeric N-at-age and F-at-age',
  'output matrices were not located.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41260284.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'This is a distinct BC coastwide unit (PMFC 3CD+5ABCDE); the NOAA Southern',
  'Pacific Coast Bocaccio unit is a separate U.S. management stock. The latest',
  'advice is the 2024 update to the 2019 Awatea age-structured model, using',
  'catch and survey data through 2023. Eligibility remains unresolved because',
  'the numeric age compositions are not published as tables or a run bundle,',
  'and the model has no age composition for the non-trawl catch stream.'
)
x$notes[i] <- paste(
  'The 2019 model is two-sex, annual, and uses ages 1-50 with older fish',
  'accumulated at age 50. Five age-composition series were fitted: commercial',
  'trawl plus four synoptic surveys; the other fishery has no age-composition',
  'data. Age inputs are available only as report figures and sample-count',
  'tables. See source_reviews/dfo_bc_bocaccio.md and the local source-cache',
  'manifest; no stock-specific input files were found in PBSawatea.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
