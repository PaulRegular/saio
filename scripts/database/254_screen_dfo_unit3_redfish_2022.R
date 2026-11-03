path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Maritimes:Acadian Redfish - Unit 3'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)

updates <- list(
  scientific_name = 'Sebastes spp.',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The latest status update reports landings and catch-at-size summaries, not catch-at-age.',
  survey_age_evidence = 'The DFO summer RV survey provides total and mature biomass indices and abundance-at-length; no age-specific abundance index is used.',
  weights_evidence = 'Mature biomass uses a combined-sex length-weight relationship from 1992-2019; no weights-at-age are used.',
  maturity_evidence = 'Mature biomass is defined using fish above 22 cm fork length; the update does not use maturity-at-age.',
  mortality_evidence = 'No natural-mortality process is fitted. Relative F is reported as landings divided by a smoothed mature biomass index.',
  timing_evidence = 'The DFO summer RV survey is conducted in July and August; no within-year model timing is specified.',
  output_evidence = 'The status update reports landings, total and mature survey biomass, abundance-at-length and relative F; it does not provide age-specific N, F, M, recruitment or SSB outputs.',
  detailed_source_url = paste('https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41119423.pdf', 'https://waves-vagues.dfo-mpo.gc.ca/Library/40597829.pdf', 'https://www.dfo-mpo.gc.ca/reports-rapports/regs/sff-cpd/survey-sondage/index-en.html', 'https://www.dfo-mpo.gc.ca/about-notre-sujet/publications/work-plan-travail/2026-2027/wp-pt-eng.html', sep = '; '),
  review_date = '2026-10-29',
  decision_reason = 'The latest public status update is an index-based report for 2022, not an age-structured production assessment. It uses catch-at-size, aggregate survey biomass and abundance-at-length, and a length-based mature biomass proxy. Age-disaggregated tinyAM inputs and age-specific model outputs were not found. The report also states that Acadian and Deepwater redfish are not separated in commercial or survey catches.',
  notes = 'Provisional new current DFO management unit: Redfish Unit 3, including NAFO Division 4X and DFO statistical areas 4Wdehkl. The DFO 2024 Sustainability Survey labels it Acadian Redfish Unit 3, while the 2022 status update reports that Acadian and Deepwater redfish are not separated in survey or commercial catches. Sources are cached under source_cache/discovery_dfo_unit3_redfish_2022/.'
)

for (column in names(updates)) x[[column]][i] <- updates[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
cat('Screened DFO Unit 3 redfish; current age-disaggregated eligibility is ineligible.\n')
