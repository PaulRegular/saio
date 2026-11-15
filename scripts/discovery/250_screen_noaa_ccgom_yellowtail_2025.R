path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10035', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Cape Cod/Gulf of Maine yellowtail row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'unresolved')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Cape Cod/Gulf of Maine yellowtail review.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 WHAM assessment discusses commercial catch-at-age diagnostics,',
  'but the official support archive contains reports and figures rather than',
  'numeric annual catch-age inputs or composition arrays.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment uses six aggregate survey indices, disaggregated by vessel',
  'and season. Run-matched survey age compositions or age-specific index',
  'observations were not located in the official support archive.'
)
x$weights_evidence[i] <- paste(
  'The assessment uses time-varying age-specific weights, including a',
  'commercial fleet weight series. Numeric model input arrays are not in the',
  'public 2025 support bundle.'
)
x$maturity_evidence[i] <- paste(
  'The 2025 model uses a time-varying maturity schedule described as a',
  'three-year moving average; the run-matched numeric schedule was not located.'
)
x$mortality_evidence[i] <- paste(
  'The accepted WHAM model uses age-specific natural mortality; the support',
  'results show an age curve, but the numeric run-specific values were not found.'
)
x$timing_evidence[i] <- paste(
  'The assessment distinguishes spring and fall surveys and vessel-specific',
  'NEFSC series. Exact within-year sampling fractions were not verified.'
)
x$output_evidence[i] <- paste(
  'The 2025 report gives annual SSB (mt), fully selected F and age-1',
  'recruitment (thousands) for 2015-2024. A results PDF plots SSB-at-age,',
  'January 1 numbers-at-age and age-specific M, but does not provide their',
  'numeric annual arrays.'
)
x$detailed_source_url[i] <- paste(
  'https://www.fisheries.noaa.gov/s3//2025-11/September-2025-Management-Track-Peer-Review-Panel-Report_Final-508.pdf;',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php;',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=13&stock_id=3&review_type_id=2&filename=2025_YEL_CCGM.zip;',
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10438',
  sep = ' '
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 10035 is the Cape Cod/Gulf of Maine yellowtail',
  'flounder unit, distinct from the existing Georges Bank and Southern New',
  'England/Mid-Atlantic records; it remains a provisional new unit pending',
  'cross-inventory reconciliation. The final 2025 peer-review panel found',
  'the WHAM assessment represented best available science. Aggregate official',
  'outputs are reported, but run-matched numeric age inputs and age-specific',
  'output arrays were not recovered. Keep eligibility unresolved until the',
  'missing age-based inputs and outputs are verified.'
)
x$notes[i] <- paste(
  'Source review: discovery/source_reviews/noaa_yellowtail_ccgom_2025.md.',
  'The local, gitignored source cache contains the 2025 support ZIP, its',
  'assessment/results PDFs, and the final September 2025 panel report; its',
  'manifest records retrieval dates and SHA-256 checksums.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Cape Cod/Gulf of Maine yellowtail; source eligibility remains unresolved.\n')
