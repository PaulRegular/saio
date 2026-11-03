root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

common <- list(
  official_stock_id = NA_character_,
  scientific_name = 'Salmo salar',
  inventory_assessment_year = 2025L,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  weights_evidence = paste(
    'Reports describe adult size and other biological characteristics, but no consistent,',
    'run-matched age-specific population weights were verified for an age-structured model.'
  ),
  maturity_evidence = paste(
    'River-specific egg deposition is calculated using adult abundance and biological',
    'characteristics; no run-matched maturity-at-age series was verified.'
  ),
  mortality_evidence = paste(
    'River-specific removals and catch-and-release mortality are considered, but no',
    'age-specific natural-mortality process or F-at-age population surface was identified.'
  ),
  timing_evidence = paste(
    'The assessment uses river counts, angling/fishery observations and juvenile surveys;',
    'no within-year timing for an age-structured marine survey likelihood is specified.'
  ),
  review_date = '2026-10-29'
)

reviews <- list(
  'DFO:Gulf:Atlantic Salmon - Gulf' = c(common, list(
    candidate_unit_id = NA_character_,
    assessment_area = paste(
      'DFO Gulf Region, SFAs 15–18; multiple river populations assessed separately,',
      'including Restigouche, Miramichi branches, PEI rivers and Margaree.'
    ),
    catch_age_evidence = paste(
      'The latest update describes fishery catch/effort and adult return estimates by small',
      'and large size groups. No catch-numbers-at-age input or source-supported',
      'reconstruction for a single river unit was verified.'
    ),
    survey_age_evidence = paste(
      'Juvenile electrofishing indices include age-class information in parts of SFA 16,',
      'but adult returns are not reported as an age-specific abundance index. Other SFAs',
      'use adult counts, redd counts, and fishery-dependent indices.'
    ),
    output_evidence = paste(
      'The update reports river-level adult returns, spawners, egg deposition, and juvenile',
      'indices. It does not provide N-at-age, F-at-age, or M-at-age population outputs.'
    ),
    detailed_source_url = paste(
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41293927.pdf; ',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41199650.pdf'
    ),
    decision_reason = paste(
      'This DFO Gulf inventory row groups distinct river populations and assessment',
      'methods; it is not one stock unit. The latest update describes index-based',
      'river assessments and does not establish catch-at-age or age-specific population',
      'outputs for an age-structured candidate. This screens out the composite row only;',
      'it does not exclude future river-specific source reviews.'
    ),
    notes = paste(
      'The June 2025 Science Response updates indicators through 2024 and states that the',
      'last full assessment was for 2019 returns. It describes five river-level programs,',
      'including empirical-index methods for PEI and multiple index-based methods elsewhere.',
      'Source review: discovery/source_reviews/dfo_atlantic_salmon_gulf_2025.md. Official',
      'PDFs are cached locally with provenance in the ignored source cache.'
    )
  )),
  'DFO:Newfoundland and Labrador:Atlantic Salmon - NL' = c(common, list(
    candidate_unit_id = NA_character_,
    assessment_area = paste(
      'DFO Newfoundland and Labrador Region, SFAs 1–14B; river-level populations,',
      'with current monitoring of a subset of rivers.'
    ),
    catch_age_evidence = paste(
      'The latest update reports recreational removals and Labrador harvest by fishery',
      'and size group, not catch numbers-at-age. No run-matched catch-age reconstruction',
      'for a single river population was verified.'
    ),
    survey_age_evidence = paste(
      'Adult and smolt counts are reported by monitored river; biological age and size',
      'information is collected at some facilities, but no age-specific abundance',
      'likelihood or index was identified in the current assessment.'
    ),
    output_evidence = paste(
      'The latest status update reports river-level total returns, smolt abundance,',
      'marine survival and egg-deposition status. It does not report N-at-age, F-at-age,',
      'or M-at-age population outputs.'
    ),
    detailed_source_url = paste(
      'https://publications.gc.ca/site/eng/9.962539/publication.html; ',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294713.pdf; ',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4123506x.pdf'
    ),
    decision_reason = paste(
      'This regional inventory row combines river-level salmon populations rather than',
      'one stock unit. DFO identifies the current approach as index-based and reports',
      'river counts and egg-deposition indicators, not catch-at-age or age-specific',
      'population surfaces. This screens out the composite row only; separate river',
      'units would need their own identity and source review.'
    ),
    notes = paste(
      'The latest public update is for 2025 and was published as Science Response 2026/021;',
      'it says the last full assessment covered 2023 returns (Science Advisory Report',
      '2025/025), with a full assessment anticipated in late 2026. The 2025 update',
      'lists age information among biological data, but its assessment is river-level',
      'and index-based. Research Document 2024/075 covers the earlier 2022 assessment.',
      'The 2026/021 PDF download redirected to the archived-information page during local',
      'caching; the official page and PDF text were reviewed. Source review:',
      'discovery/source_reviews/dfo_atlantic_salmon_nl_2026.md.'
    )
  ))
)

for (id in names(reviews)) {
  i <- which(candidates$candidate_id == id)
  if (length(i) != 1L) stop('Expected one inventory row: ', id, call. = FALSE)
  review <- reviews[[id]]
  already_applied <- all(vapply(names(review), function(column) {
    identical(as.character(candidates[[column]][i]), as.character(review[[column]]))
  }, logical(1L)))
  if (!already_applied) {
    if (candidates$screening_status[i] != 'not_started' ||
        candidates$match_status[i] != 'unreviewed') {
      stop('Inventory row has a conflicting prior review: ', id, call. = FALSE)
    }
    for (column in names(review)) candidates[[column]][i] <- review[[column]]
  }
}

for (id in names(reviews)) {
  i <- match(id, candidates$candidate_id)
  if (!is.na(candidates$candidate_unit_id[i]) || !is.na(candidates$official_stock_id[i])) {
    stop('Composite regional row must not be assigned a stock identifier: ', id, call. = FALSE)
  }
}

lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
for (id in names(reviews)) {
  i <- match(id, candidates$candidate_id)
  row <- candidates[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, candidate_path, useBytes = TRUE)
cat('Screened the two composite DFO Atlantic salmon inventory rows; no river population was treated as a single stock.\n')
