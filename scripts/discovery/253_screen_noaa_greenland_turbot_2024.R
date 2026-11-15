path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10054'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)

updates <- list(
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The official 2024 Model 16.4c uses aggregate catch and fishery length compositions; a run-matched fishery catch-at-age series or sufficient source data for its reconstruction was not recovered.',
  survey_age_evidence = 'The model uses shelf and slope biomass indices plus length compositions. Shelf survey age-composition records are available for some years but are explicitly excluded from the likelihood; numeric run-matched age-composition records were not recovered.',
  weights_evidence = 'Growth and length-at-age are estimated from survey data; a numeric run-matched weight-at-age surface was not recovered.',
  maturity_evidence = 'Female maturity is a fixed logistic ogive at length, with 50% maturity at 60 cm; the reviewed source does not supply a run-matched age-specific maturity input.',
  mortality_evidence = 'Natural mortality is fixed at 0.112 per year.',
  timing_evidence = 'The assessment is annual.',
  output_evidence = 'The SAFE reports age-0 recruitment and numbers-at-age, total age-1+ biomass, female spawning biomass and aggregate fishing mortality. The model outputs do not replace missing age-disaggregated observations.',
  detailed_source_url = paste('https://files.npfmc.org/SAFE/2024/BSAIturbot.pdf', 'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2025_FINAL.pdf&p=7e59a76c-3801-48fe-8bd8-7f1a1501a142.pdf', 'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=PRESENTATION+Gturbot_September2026.pdf&p=4900ef4a-db30-4b5a-8502-88aaff678b07.pdf', sep = '; '),
  review_date = '2026-10-29',
  decision_reason = 'The current official 2024 Model 16.4c assessment is age structured, but it fits aggregate catch and length compositions, not catch-at-age. Survey age-composition records are excluded from the likelihood and their numeric run-matched values were not recovered. Eligibility for an age-disaggregated remains unresolved pending those source inputs. September 2026 alternatives are preliminary and not treated as a replacement production assessment.',
  notes = 'Provisional new unit: BSAI Greenland turbot, NOAA Stock SMART 10054; distinct from the Gulf of Alaska Greenland turbot complex. 2024 Model 16.4c is the latest official run located; 2025-26 model alternatives remain under review. Sources cached under source_cache/discovery_noaa_greenland_turbot_2024/.'
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
cat('Screened NOAA BSAI Greenland turbot; age-input readiness remains unresolved.\n')
