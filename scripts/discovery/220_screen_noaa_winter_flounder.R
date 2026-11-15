# Screen the current NOAA Gulf of Maine and SNE/MA winter flounder units.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:10028', 'NOAA:10030')
rows <- match(ids, x$candidate_id)
if (anyNA(rows)) stop('Expected NOAA winter flounder rows are missing.', call. = FALSE)
if (any(x$screening_status[rows] == 'screened')) {
  stopifnot(all(x$screening_status[rows] == 'screened'),
    all(x$match_status[rows] == 'new'),
    x$eligibility[rows[1L]] == 'ineligible',
    x$eligibility[rows[2L]] == 'unresolved')
} else if (any(x$screening_status[rows] != 'not_started') ||
           any(x$match_status[rows] != 'unreviewed')) {
  stop('Preserve the existing winter flounder reviews; candidate rows changed.', call. = FALSE)
}

gom <- rows[1L]
x$match_status[gom] <- 'new'
x$matched_stock_id[gom] <- NA_character_
x$screening_status[gom] <- 'screened'
x$eligibility[gom] <- 'ineligible'
x$import_status[gom] <- 'not_started'
x$catch_age_evidence[gom] <- paste(
  'The 2025 assessment updates commercial and recreational catch totals in',
  'metric tonnes through 2024. It is an area-swept 30+ cm biomass assessment,',
  'not a catch-at-age model; no catch numbers-at-age are used.'
)
x$survey_age_evidence[gom] <- paste(
  'The assessment uses fall area-swept biomass estimates from NEFSC, MDMF,',
  'and MENH surveys, with updated q = 0.79. These are 30+ cm aggregate',
  'biomass observations, not age-specific abundance indices or age samples.'
)
x$weights_evidence[gom] <- paste(
  'The area-swept biomass model does not use weight-at-age inputs.'
)
x$maturity_evidence[gom] <- paste(
  'The area-swept biomass model does not use maturity-at-age inputs.'
)
x$mortality_evidence[gom] <- paste(
  'The 2025 report describes 30+ cm exploitation rate, not age-specific',
  'natural mortality; M-at-age inputs are not part of this area-swept model.'
)
x$timing_evidence[gom] <- paste(
  'The biomass indices are from fall surveys. The report does not provide',
  'a model sampling fraction within the year.'
)
x$output_evidence[gom] <- paste(
  'The report provides 30+ cm biomass and exploitation-rate time series;',
  '2024 biomass is 4,537 mt and exploitation rate is 0.044. It does not',
  'report N-at-age, F-at-age, or M-at-age.'
)
x$detailed_source_url[gom] <- 'https://asmfc.org/wp-content/uploads/2026/01/GOM_WFlounderMgmtTrackAssmtReport_Sept2025.pdf'
x$review_date[gom] <- '2026-10-29'
x$decision_reason[gom] <- paste(
  'NOAA Stock SMART ID 10028 is the current Gulf of Maine unit. Its latest',
  '2025 management-track assessment updates the 2022 area-swept biomass',
  'method, rather than an age-structured assessment. It has no age-based',
  'inputs or age-specific outputs and is ineligible for the age-structured',
  'candidate set.'
)
x$notes[gom] <- paste(
  'Stock SMART assessment ID 14073 is an Operational assessment using the',
  'area-swept biomass method with data through 2024. The 2025 report was',
  'compiled in August 2025 and posted by ASMFC in January 2026; see',
  'discovery/source_reviews/noaa_winter_flounder_gom_sne.md.'
)

sne <- rows[2L]
x$match_status[sne] <- 'new'
x$matched_stock_id[sne] <- NA_character_
x$screening_status[sne] <- 'screened'
x$eligibility[sne] <- 'unresolved'
x$import_status[sne] <- 'not_started'
x$catch_age_evidence[sne] <- paste(
  'The 2025 ASAP update uses commercial and recreational catch data through',
  '2024. Its report tabulates fleet landings/discards and aggregate catch for',
  'assessment in metric tonnes for 2015-2024, but does not publish the',
  'age-specific catch arrays or age-composition sample counts.'
)
x$survey_age_evidence[sne] <- paste(
  'The 2025 report updates research-survey abundance indices and shows',
  'biomass-index series, but provides no age-composition arrays or',
  'age-specific abundance index values. Current-run source arrays were not',
  'recovered.'
)
x$weights_evidence[sne] <- paste(
  'The report states that projections use mean weights-at-age averaged over',
  'the most recent five years; the numerical current-run arrays were not',
  'included in the recovered report.'
)
x$maturity_evidence[sne] <- paste(
  'The report states that projections use maturity-at-age averaged over the',
  'most recent five years; the numerical current-run arrays were not included.'
)
x$mortality_evidence[sne] <- paste(
  'The report identifies natural mortality as an important uncertainty and',
  'states the 2011 benchmark increased M from 0.2 to 0.3. The 2025 update',
  'says data structure, settings, and assumptions were unchanged; the native',
  '2025 M vector or input file was not recovered.'
)
x$timing_evidence[sne] <- paste(
  'The report identifies spring/fall NEFSC and state survey series, but does',
  'not provide the current model timing table or survey-year fractions.'
)
x$output_evidence[sne] <- paste(
  'The report gives aggregate SSB, fully selected F and recruitment through',
  '2024; 2024 estimates are 2,787 mt, 0.048, and 6,211 thousand fish.',
  'Approximate 90% lognormal intervals are plotted. It does not provide',
  'annual N-at-age, F-at-age, or M-at-age outputs.'
)
x$detailed_source_url[sne] <- 'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10436'
x$review_date[sne] <- '2026-10-29'
x$decision_reason[sne] <- paste(
  'NOAA Stock SMART ID 10030 is the distinct SNE/MA winter flounder stock',
  'and the latest assessment is the 2025 ASAP management-track update with',
  'data through 2024. The report confirms an age-structured model and',
  'age-specific projection biology, but does not provide the current run’s',
  'catch-age and survey-age inputs, numeric biological arrays, or timing',
  'table. Keep age-input eligibility unresolved pending recovery of the',
  'native 2025 model data.'
)
x$notes[sne] <- paste(
  'Stock SMART assessment ID 14072 is an Operational ASAP assessment.',
  'The public report is marked a draft working paper for peer review only,',
  'but the 2025 results were presented to the ASMFC Management Board for',
  '2026-2028 management decisions. The 2025 report states that data',
  'structure, model settings, and assumptions were unchanged. See',
  'discovery/source_reviews/noaa_winter_flounder_gom_sne.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[rows, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[rows + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
