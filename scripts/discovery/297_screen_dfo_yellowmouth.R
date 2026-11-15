path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  'DFO:Pacific:Yellowmouth Rockfish' = list(
    candidate_unit_id = 'dfo_yellowmouth_bc',
    official_stock_id = 'DFO Yellowmouth Rockfish - BC coastwide',
    scientific_name = 'Sebastes reedi',
    stock_name = 'Yellowmouth Rockfish - Coastwide',
    assessment_area = 'PMFC areas 3CD and 5ABCDE; excludes 4B',
    inventory_assessment_year = '2021',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2021 Stock Synthesis assessment uses annual commercial catch estimates',
      'from 1935-2021 and commercial age-frequency samples from 28 years (1979-2019).',
      'Bottom and midwater trawl data are combined as one fishery. Quarterly age',
      'compositions were catch-weighted and expanded using quarterly landings;',
      'catch-at-age therefore requires a documented reconstruction. Numeric input',
      'matrices were not found as separate public files in this screen.'
    ),
    survey_age_evidence = paste(
      'The model uses four aggregate trawl biomass-index series (QCS, WCVI, WCHG,',
      'and GIG) covering 1967-2020 and survey age compositions from 25 years across',
      'the four surveys. Survey age data are downweighted to 0.25; aggregate indices',
      'and age compositions could support a documented age-index reconstruction.'
    ),
    weights_evidence = paste(
      'Sex-specific growth and length-weight relationships were estimated from',
      'survey biological samples and fixed over time. The report gives growth and',
      'allometric parameters needed to derive weight-at-age for model ages 1-60.'
    ),
    maturity_evidence = paste(
      'The model uses a time-invariant female maturity ogive: zero at ages 1-4,',
      'a fitted monotonic curve at ages 5-16, and 1.0 from age 17 through the age-60',
      'accumulator. The source describes the biological samples and fitted form.'
    ),
    mortality_evidence = paste(
      'The composite base case pools five component runs with fixed scalar M values',
      'of 0.04, 0.045, 0.05, 0.055, and 0.06. An estimated-M sensitivity had poor',
      'MCMC diagnostics and is not the adopted central run. M is not age-specific.'
    ),
    timing_evidence = paste(
      'The assessment is annual. It defines spawning biomass at the start of the',
      'year and exploitation rate in mid-year. Exact fractional timing for each',
      'survey observation was not verified in the published report.'
    ),
    output_evidence = paste(
      'The official composite base case reports annual female spawning-biomass and',
      'age-0 recruitment trajectories with posterior intervals through 2022, plus',
      'tabulated terminal B2022 quantiles. Numeric N-at-age and instantaneous',
      'F-at-age arrays were not recovered; reported fishing pressure is exploitation.'
    ),
    detailed_source_url = paste(
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091449.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4103336x.pdf;',
      'https://csas-sccs.dfo-mpo.gc.ca/publications/96b903ca-fd67-4275-8236-84df0597b400;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127698x.pdf;',
      'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'DFO identifies the 2021 assessment as the latest detailed coastwide',
      'age-structured assessment found for this unit. The 2025/26 IFMP anticipated',
      'an update in 2024, but no later detailed Yellowmouth assessment was found',
      'in the current DFO Pacific plan or CSAS search. The 2021 report documents',
      'catch totals and age compositions, four survey indices and survey age data,',
      'biology, mortality scenarios, and official SSB/recruitment outputs. These',
      'support source curation with documented reconstruction; original numeric',
      'age matrices and exact survey timing remain source-recovery tasks.'
    ),
    notes = paste(
      'The assessment is coastwide across PMFC areas 3CD and 5ABCDE and excludes',
      '4B. It is a two-sex Stock Synthesis 3 assessment, ages 1-60, with one',
      'combined commercial trawl fishery and five fixed-M composite component runs.',
      'Age compositions are plotted in the report; no native run bundle was found',
      'in the public source search. Preserve the composite-base-case identity and',
      'distinguish its reported exploitation from instantaneous F-at-age.'
    )
  )
)

for (id in names(review)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop('Expected candidate row: ', id, call. = FALSE)
  if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
    stop('Unexpected canonical match for ', id, call. = FALSE)
  }
  for (column in names(review[[id]])) x[[column]][i] <- review[[id]][[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline rows; refusing unsafe update.', call. = FALSE)
}
for (id in names(review)) {
  i <- match(id, x$candidate_id)
  row <- x[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened the DFO Yellowmouth Rockfish coastwide assessment.\n')
