path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:ple.27.7d'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wgnssk_platessa_ns_7d' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing ICES Division 7.d plaice identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The 2026 SAM production run uses residual catch numbers-at-age for 1980-2025, ',
  'ages 1-7, in thousand fish; exponentiated values times native catch weights reproduce ',
  'reported annual catch totals within rounding.'
)
x$survey_age_evidence[i] <- paste0(
  'Age-specific UK BTS indices cover ages 1-6 for 1989-2025 and FR GFS indices cover ',
  'ages 1-6 for 1990-2025; observations remain on native relative scales.'
)
x$weights_evidence[i] <- paste0(
  'Stock, catch, landings and discard weights cover 1980-2025, ages 1-7, in kg per fish; ',
  'stock weights use Q2 catch weights.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is a static histology-based ogive for ages 1-7, following the 2025 benchmark.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed by age for ages 1-7; the model does not estimate M.'
)
x$timing_evidence[i] <- paste0(
  'Native SAM observation times are 0.625 for the Q3 UK BTS and 0.875 for the Q4 FR GFS.'
)
x$output_evidence[i] <- paste0(
  'ICES SAG reports official age-1 recruitment, SSB and Fbar for 1980-2025 with 95% ',
  'intervals, plus 2026 recruitment/SSB forecasts. The report does not provide N-at-age, ',
  'F-at-age or total abundance outputs.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32676345; ',
  'https://doi.org/10.17895/ices.advice.30932276; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22484; ',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22484; ',
  'https://doi.org/10.17895/ices.pub.28715180; ',
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.7d_2026'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Division 7.d plaice unit and 2026 SAM assessment. Age-specific ',
  'catch, survey, biology and timing inputs plus official aggregate outputs support an ',
  'age-structured translation screen. The native fitted-object endpoint was unavailable; ',
  'a local refit did not reproduce SAG summaries and is not treated as an official output. ',
  'N/F-at-age outputs and age-specific uncertainty are unavailable.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_plaice_english_channel_7d_2026.md. ',
  'The 2026 record is distinct from the historical 2025 tinyAM translation; native SS3 ',
  'outputs are not recovered.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Division 7.d plaice against the 2026 SAM assessment.\n')
