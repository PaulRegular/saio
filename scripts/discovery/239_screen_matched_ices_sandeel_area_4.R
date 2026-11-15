path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:san.sa.4'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_sandeel_area_4' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing ICES Area 4 sandeel identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The latest recovered detailed age-based run is the official 2025 SMS-effort model: ',
  'catch-at-age for 1993-2024, ages 0-4+ in two half-years, in million fish; age 0 is ',
  'excluded from the source likelihood.'
)
x$survey_age_evidence[i] <- paste0(
  'Dredge and Dredge2 series provide age-specific indices for ages 0-1; 2025-model ',
  'coverage is 1999-2003 and 2008-2024. Values remain on the source scale.'
)
x$weights_evidence[i] <- paste0(
  'Seasonal stock/catch weights cover ages 1-4+ in half-year 1 and ages 0-4+ in half-year 2, ',
  'in grams per fish.'
)
x$maturity_evidence[i] <- paste0(
  'Seasonal maturity proportions are supplied on the model age grid.'
)
x$mortality_evidence[i] <- paste0(
  'M is fixed using long-term multispecies averages and supplied as integrated half-year hazards.'
)
x$timing_evidence[i] <- paste0(
  'The source model represents Dredge observations over seasonal intervals; the exact ',
  'intervals are retained in the source review rather than reduced to point times.'
)
x$output_evidence[i] <- paste0(
  'The 2025 age-based run provides January N-at-age, July age-0 recruitment, seasonal/annual F, ',
  'SSB, biomass, predicted yield and Fbar ages 1-2. A separate 2026 category-5 advice update ',
  'reports aggregate catch and custom age-0/1 series only, with no age-structured model outputs.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.28389008.v5; ',
  'https://asd.ices.dk/viewAdvice/3832; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19335; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21271; ',
  'https://github.com/ices-advice/2025_san.sa.4/tree/5ccb6abb2595153a88c9c47ad628ad17f3ea3e06'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to current ICES Sandeel Area 4. The latest recovered detailed assessment is the ',
  '2025 age-based SMS-effort production run, which provides age-disaggregated inputs and ',
  'official population/mortality outputs. The later 2026 category-5 update is recorded ',
  'separately and is not treated as a new age-structured fit.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_sandeel_area_4.md. Keep the 2026 ',
  'summary event separate from the detailed 2025 age-based assessment; do not mix its ',
  'aggregate catches or custom index values into the 2025 inputs.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Sandeel Area 4 using its detailed 2025 assessment and separate 2026 summary.\n')
