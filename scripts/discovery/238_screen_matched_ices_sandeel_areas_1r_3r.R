path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
updates <- list(
  list(
    id = 'ICES:san.sa.1r', stock = 'ices_sandeel_area_1r',
    review = 'ices_sandeel_area_1r.md',
    catch = 'The 2026 SMS-effort model uses catch numbers-at-age for 1983-2025, ages 0-4+ in two half-years, in million fish; the source likelihood excludes age 0.',
    survey = 'Age-specific Dredge indices cover ages 0-1 in 2004-2025; RTM indices cover ages 1-3 in 2016-2020, 2023 and 2025. Values remain on native scales.',
    weights = 'Seasonal stock and catch weights cover ages 1-4+ in half-year 1 and ages 0-4+ in half-year 2, in grams per fish.',
    maturity = 'Proportion mature is supplied on the same seasonal age grid as weights.',
    mortality = 'Natural mortality is supplied as integrated half-year hazards from multispecies modelling; it is not estimated by the assessment.',
    timing = 'Dredge likelihood averages abundance over 0.875-1 of the year; RTM is observed at the beginning of half-year 1. Neither is represented by a single common point time.',
    output = 'Official outputs include January N-at-age for ages 1-4+, July age-0 recruitment, annual/seasonal F, SSB, total biomass and arithmetic Fbar ages 1-2. SAG limits are available for SSB, recruitment and Fbar; N/F uncertainty is unavailable.',
    sources = 'https://doi.org/10.17895/ices.pub.31424315; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21280; https://github.com/ices-advice/2026_san.sa.1r/tree/8a556698db2c9c23321980c8fec368c80562b89f',
    reason = 'Matched to the current ICES Area 1r unit and official 2026 HAWG SMS-effort production assessment. Catch-at-age, two age-specific surveys, seasonal biology and fixed M, and official population/mortality outputs are recovered. Within-season survey intervals and unavailable age-specific uncertainty remain explicit.'
  ),
  list(
    id = 'ICES:san.sa.2r', stock = 'ices_sandeel_area_2r',
    review = 'ices_sandeel_area_2r.md',
    catch = 'The 2026 SMS-effort model uses catch numbers-at-age for 1983-2025, ages 0-4+ in two half-years, in million fish; the source likelihood excludes age 0.',
    survey = 'The Dredge index covers ages 0-1 in 2004-2025 on its native scaled-number index; an absolute multiplier is not reported. No commercial tuning series is active.',
    weights = 'Seasonal stock and catch weights cover ages 1-4+ in half-year 1 and ages 0-4+ in half-year 2, in grams per fish.',
    maturity = 'Proportion mature is supplied on the same seasonal age grid as weights.',
    mortality = 'M is fixed by age and season using long-term multispecies averages; source values are integrated half-year hazards.',
    timing = 'Dredge predictions average abundance over 0.875-1 of the year; the assessment does not reduce this observation interval to a point time.',
    output = 'Official outputs include January N-at-age for ages 1-4+, July age-0 recruitment, annual/seasonal F, SSB, total biomass, predicted yield and arithmetic Fbar ages 1-2. SAG limits are available for SSB, recruitment and Fbar; N/F uncertainty is unavailable.',
    sources = 'https://doi.org/10.17895/ices.pub.31424315; https://asd.ices.dk/viewAdvice/4046; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21281; https://github.com/ices-advice/2026_san.sa.2r/tree/7a77f3b7a2e2fc2cb6609bbe234f8de9b97dac3f',
    reason = 'Matched to the current ICES Area 2r unit and official 2026 HAWG SMS-effort production assessment. Catch-at-age, age-specific Dredge index, seasonal biology and fixed M, and official population/mortality outputs are recovered. Native index scaling and interval timing remain documented.'
  ),
  list(
    id = 'ICES:san.sa.3r', stock = 'ices_sandeel_area_3r',
    review = 'ices_sandeel_area_3r.md',
    catch = 'The 2026 SMS-effort model uses catch numbers-at-age for 1987-2025, ages 0-4+ in two half-years, in million fish; age-0 catch is excluded from the likelihood and 2025 source zeros are retained.',
    survey = 'Age-specific indices include Dredge ages 0-1 in 2006-2025 and acoustic ages 1-4+ in 2009-2025; both remain on native scaled-number indices.',
    weights = 'Seasonal stock and catch weights cover ages 1-4+ in half-year 1 and ages 0-4+ in half-year 2, in grams per fish.',
    maturity = 'Proportion mature is supplied on the seasonal age grid.',
    mortality = 'M is supplied and varies by year, age and half-year from multispecies modelling; it is not estimated by the assessment.',
    timing = 'Dredge predictions average abundance over annual times 0.875-1; the acoustic index averages over 0.25-0.35. These source intervals are not point samples.',
    output = 'Official outputs include January N-at-age for ages 1-4+, July age-0 recruitment, annual/seasonal F, January biomass/SSB, predicted yield and arithmetic Fbar ages 1-2. SAG limits are available for SSB, recruitment and Fbar; N/F uncertainty is unavailable.',
    sources = 'https://doi.org/10.17895/ices.pub.31424315; https://asd.ices.dk/viewAdvice/4047; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21282; https://github.com/ices-advice/2026_san.sa.3r/tree/93847fb928ebf02f995c503e67f52bc2dd1398cc',
    reason = 'Matched to the current ICES Area 3r unit and official 2026 HAWG SMS-effort production assessment. Seasonal catch-at-age, two age-specific survey series, biological inputs and fixed M, and official population/mortality outputs are recovered. Source observation intervals and absent age-specific uncertainty remain explicit.'
  )
)

for (u in updates) {
  i <- which(x$candidate_id == u$id)
  if (length(i) != 1L || x$matched_stock_id[i] != u$stock ||
      x$match_status[i] != 'matched' ||
      !x$screening_status[i] %in% c('not_started', 'screened')) {
    stop('Preserve the existing matched sandeel identity for ', u$id, '.', call. = FALSE)
  }
  x$screening_status[i] <- 'screened'
  x$eligibility[i] <- 'eligible'
  x$import_status[i] <- 'imported'
  x$catch_age_evidence[i] <- u$catch
  x$survey_age_evidence[i] <- u$survey
  x$weights_evidence[i] <- u$weights
  x$maturity_evidence[i] <- u$maturity
  x$mortality_evidence[i] <- u$mortality
  x$timing_evidence[i] <- u$timing
  x$output_evidence[i] <- u$output
  x$detailed_source_url[i] <- u$sources
  x$review_date[i] <- '2026-10-29'
  x$decision_reason[i] <- u$reason
  x$notes[i] <- paste0('See source_reviews/', u$review,
    '; official taxon is Ammodytes spp. and the regional record has no invented Charbonneau identifier.')
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (u in updates) {
  i <- match(u$id, x$candidate_id)
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Sandeel Areas 1r, 2r and 3r against their current HAWG assessments.\n')
