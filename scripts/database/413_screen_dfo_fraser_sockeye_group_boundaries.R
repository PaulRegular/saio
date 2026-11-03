root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

candidate_ids <- c(
  'DFO:Pacific:Sockeye Salmon - Fraser (Early Summer)',
  'DFO:Pacific:Sockeye Salmon - Fraser (Summer)',
  'DFO:Pacific:Sockeye Salmon - Fraser (Late)'
)
rows <- match(candidate_ids, x$candidate_id)
if (anyNA(rows)) stop('Expected Fraser Sockeye management-group rows are missing.', call. = FALSE)

source_urls <- paste(
  'https://www.psc.org/publications/data/fraser-sockeye-stock-recruit-dataset/;',
  'https://www.psc.org/download/130/frp-data/19739/stock-recruit-data-documentation.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294622.pdf;',
  'https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf'
)
review <- 'See discovery/source_reviews/dfo_fraser_sockeye_other_groups.md.'

for (i in rows) {
  if (x$screening_status[i] == 'not_started') {
    group <- sub('^DFO:Pacific:Sockeye Salmon - Fraser \\((.*)\\)$', '\\1', x$candidate_id[i])
    x$scientific_name[i] <- 'Oncorhynchus nerka'
    x$assessment_area[i] <- paste(
      'Fraser River', group, 'sockeye management/run-timing group, multiple Conservation Units'
    )
    x$inventory_assessment_year[i] <- NA_integer_
    x$match_status[i] <- 'ambiguous'
    x$screening_status[i] <- 'screened'
    x$eligibility[i] <- 'unresolved'
    x$import_status[i] <- 'not_started'
    x$catch_age_evidence[i] <- paste(
      'PSC reports age-specific recruitment for individual production groups,',
      'but the DFO management-group row does not resolve to one production unit',
      'or provide a matching catch-at-age input series.'
    )
    x$survey_age_evidence[i] <- paste(
      'PSC age-specific recruitment values are run-size/stock-recruit outputs,',
      'not an independent age-specific abundance-index likelihood for this',
      'multi-unit management-group row.'
    )
    x$weights_evidence[i] <- paste(
      'No single age-specific weight input can be assigned to the broad',
      'management group without resolving its constituent stock units.'
    )
    x$maturity_evidence[i] <- paste(
      'No single maturity-at-age input can be assigned to the broad management',
      'group without resolving its constituent stock units.'
    )
    x$mortality_evidence[i] <- paste(
      'The reviewed sources describe stock-specific run-size adjustments, not',
      'one annual F-at-age or M-at-age process for this broad group.'
    )
    x$timing_evidence[i] <- paste(
      'No within-year timing fraction for an age-specific survey likelihood',
      'is established for the broad management-group inventory row.'
    )
    x$output_evidence[i] <- paste(
      'The PSC detailed dataset reports age-specific recruits at individual',
      'production-stock level. It does not contain one aggregate production',
      'row matching this multi-unit management group.'
    )
    x$detailed_source_url[i] <- source_urls
    x$review_date[i] <- '2026-10-30'
    x$decision_reason[i] <- paste(
      'The DFO inventory label is a management/run-timing group spanning',
      'multiple production groups and Conservation Units. The public PSC',
      'age-specific data are at the constituent production-group level and',
      'cannot be assigned or aggregated to this row without an explicit',
      'current assessment unit mapping. Keep identity ambiguous and eligibility',
      'unresolved; do not create or count a new stock unit.'
    )
    x$notes[i] <- paste(
      'No canonical records or candidate unit were added. The underlying',
      'production groups may have usable sources and should be reviewed only',
      'after matching them to exact current units. ', review
    )
  } else if (x$screening_status[i] == 'screened') {
    stopifnot(
      is.na(x$candidate_unit_id[i]),
      x$match_status[i] == 'ambiguous',
      x$eligibility[i] == 'unresolved'
    )
  } else {
    stop('Preserve the existing Fraser Sockeye review state.', call. = FALSE)
  }
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in rows) replace_candidate_register_row(path, i, x[i, , drop = FALSE], x$candidate_id[i])
