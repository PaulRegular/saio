root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

detailed_source_url <- paste(
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4130293x.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41087719.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40951686.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40946265.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41206903.pdf'
)
review_date <- '2026-10-29'

component_reviews <- list(
  'DFO:Maritimes:Atlantic Herring - Coastal Nova Scotia' = list(
    component = 'Coastal Nova Scotia spawning component (South Shore, Eastern Shore and Cape Breton)',
    catch_age_evidence = paste(
      'The 2019 data-input report documents fishery catch and biological samples,',
      'but the 2025 interim update does not provide a current numerical',
      'catch-at-age input series for an age-structured production fit.'
    ),
    survey_age_evidence = paste(
      'The component is assessed using acoustic biomass indicators and catch',
      'information; the 2025 update reports no fitted age-specific abundance index.'
    ),
    notes = paste(
      'Matched as a spawning component within the existing 4VWX management record.',
      'The 2025 update reports Coastal NS acoustic SSB indicators for Little Hope/',
      'Port Mouton and Halifax/Eastern Shore; these remain component indicators,',
      'not a fitted population-state surface.'
    )
  ),
  'DFO:Maritimes:Atlantic Herring - Offshore Scotian Shelf' = list(
    component = 'Offshore Scotian Shelf banks spawning component (The Patch and Western Hole)',
    catch_age_evidence = paste(
      'The 2019 data-input report documents historical fishery and age data, but',
      'the 2025 interim update does not provide a current numerical catch-at-age',
      'input series for an age-structured production fit.'
    ),
    survey_age_evidence = paste(
      'The 2025 update reports no new information for evaluating this component;',
      'systematic acoustic surveys have not been conducted since 1998.'
    ),
    notes = paste(
      'Matched as a spawning component within the existing 4VWX management record.',
      'Do not infer current age-specific abundance from the historical survey or',
      'age material.'
    )
  ),
  'DFO:Maritimes:Atlantic Herring - Southwest Nova Scotia / Bay of Fundy' = list(
    component = 'Southwest Nova Scotia/Bay of Fundy spawning component',
    catch_age_evidence = paste(
      'The public MSE conditioning inputs include commercial catch-at-age through',
      '2018 for this component; DFO says production reference OMs were conditioned',
      'through 2020. These are not a complete current fitted production input series.'
    ),
    survey_age_evidence = paste(
      'The MSE conditioning archive includes acoustic age information through 2018;',
      'the 2025 update reports acoustic SSB indicators but no fitted age-specific',
      'abundance output.'
    ),
    notes = paste(
      'Matched as the SWNS/BoF spawning component within the existing 4VWX',
      'management record. The 2022 MSE is a component-specific ensemble, not one',
      'official fitted population-state series.'
    )
  )
)

for (id in names(component_reviews)) {
  i <- match(id, x$candidate_id)
  if (is.na(i) || sum(x$candidate_id == id) != 1L) {
    stop(paste('Expected one DFO herring inventory row:', id), call. = FALSE)
  }
  component <- component_reviews[[id]]
  review <- list(
    candidate_unit_id = 'dfo_herring_4vwx_management_unit',
    organization = 'DFO',
    official_stock_id = paste('NAFO 4VWX component:', component$component),
    scientific_name = 'Clupea harengus',
    assessment_area = component$component,
    inventory_assessment_year = 2025L,
    matched_stock_id = 'ck_dfo_mar_harengus_4vwx',
    match_status = 'matched',
    screening_status = 'screened',
    eligibility = 'unresolved',
    import_status = 'imported',
    catch_age_evidence = component$catch_age_evidence,
    survey_age_evidence = component$survey_age_evidence,
    weights_evidence = paste(
      'Historical assessment input material documents biological sampling, but',
      'no current run-matched weight-at-age surface for an age-structured',
      'production fit was recovered.'
    ),
    maturity_evidence = paste(
      'Historical assessment input material documents biological sampling, but',
      'no current run-matched maturity-at-age surface for an age-structured',
      'production fit was recovered.'
    ),
    mortality_evidence = paste(
      'The current update reports no fitted age-specific F or M surface. The 2022',
      'SWNS/BoF MSE archive does not provide saved production reference OM states.'
    ),
    timing_evidence = paste(
      'The source identifies acoustic and fishery sampling but does not provide',
      'current fitted within-year timing fractions for a population model.'
    ),
    output_evidence = paste(
      'The 2025 update reports landings and component-level acoustic indices;',
      'no current fitted N/F/M-at-age or recruitment population-state series was found.'
    ),
    detailed_source_url = detailed_source_url,
    review_date = review_date,
    decision_reason = paste(
      'This named spawning component is represented within the existing DFO 4VWX',
      'canonical management-unit record and its imported 2025 component indicators.',
      'Current component assessment methods are indicator-based, with a separate',
      'SWNS/BoF MSE; current run-matched population age inputs and fitted',
      'age-specific outputs were not verified. Keep eligibility unresolved.'
    ),
    notes = paste(component$notes,
      'See discovery/source_reviews/dfo_4vwx_herring_component_crosswalk_2025.md',
      'and source_reviews/ck_dfo_mar_harengus_4vwx.md. Sources are already cached',
      'with checksums under source_cache/ck_dfo_mar_harengus_4vwx/.'
    )
  )
  if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
    stop(paste('Preserve existing DFO herring candidate state before screening:', id), call. = FALSE)
  }
  for (column in names(review)) x[[column]][i] <- review[[column]]
}

id <- 'DFO:Maritimes:Atlantic Herring - Southwest New Brunswick (migrant juveniles)'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L ||
    x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing DFO SWNB migrant-juvenile inventory state.', call. = FALSE)
}
juvenile_review <- list(
  official_stock_id = '4VWX5 Southwest New Brunswick migrant-juvenile fishery',
  scientific_name = 'Clupea harengus',
  stock_name = 'Atlantic Herring - Southwest New Brunswick migrant juveniles',
  assessment_area = 'Southwest New Brunswick weir/shutoff fishery near the Bay of Fundy',
  inventory_assessment_year = 2025L,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'imported',
  catch_age_evidence = paste(
    'The 2025 source reports landings for a migrant juvenile fishery. Ages 1-3',
    'are described as a mixed aggregation dominated by Subarea 5-origin fish;',
    'no separate assessed-stock catch-at-age vector was found.'
  ),
  survey_age_evidence = paste(
    'No separate fishery-independent abundance index or age-specific population',
    'index was found for this migrant-juvenile aggregation.'
  ),
  weights_evidence = paste(
    'No separate age-specific weight input for an assessed SWNB population was found.'
  ),
  maturity_evidence = paste(
    'No separate maturity-at-age input for an assessed SWNB population was found.'
  ),
  mortality_evidence = paste(
    'The fishery component has no separate fitted F or M population surface.'
  ),
  timing_evidence = paste(
    'The source describes a weir/shutoff fishery, not a population-model',
    'observation series with fitted timing.'
  ),
  output_evidence = paste(
    'The 2025 update reports 2024 landings; DFO says these are not indicative',
    'of abundance. No population or mortality outputs are reported.'
  ),
  detailed_source_url = detailed_source_url,
  review_date = review_date,
  decision_reason = paste(
    'This is a fishery aggregation, not a distinct assessed population unit.',
    'Juvenile fish are a mixture dominated by Subarea 5 spawning components',
    'and are excluded from the 4WX quota; mature age-4+ fish are considered',
    '4WX origin. Landings are not an abundance index. Do not create a new stock.'
  ),
  notes = paste(
    '2025 Science Response 2025/026 reports 2,328 t of 2024 landings and states',
    'the fishery is not indicative of abundance. See discovery/source_reviews/',
    'dfo_4vwx_herring_component_crosswalk_2025.md and source_reviews/',
    'ck_dfo_mar_harengus_4vwx.md. Source PDFs and checksums are cached under',
    'source_cache/ck_dfo_mar_harengus_4vwx/.'
  )
)
for (column in names(juvenile_review)) x[[column]][i] <- juvenile_review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Unexpected multiline rows in candidate register.', call. = FALSE)
for (id in c(names(component_reviews), 'DFO:Maritimes:Atlantic Herring - Southwest New Brunswick (migrant juveniles)')) {
  i <- match(id, x$candidate_id)
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Crosswalked three DFO 4VWX herring components and excluded the SWNB migrant-juvenile fishery as a distinct stock.\n')