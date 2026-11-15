path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:cod.27.46a7d20'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)
updates <- list(
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The 2026 assessment code reads Northwest and Southern/Viking catch-at-age files (cn_WS.dat and cn_NS.dat) from boot/data, but these numerical run inputs are absent from the public repository snapshot. The canonical database contains the preceding 2025 run catch-at-age, ages 1-7+, 1983-2024; it is not verified as the 2026 input.',
  survey_age_evidence = 'The 2026 data scripts identify manually downloaded DATRAS survey archives and codData210926.Rdata as the updated age-data source, but neither the source archive bundle nor the processed run-specific observations are committed. The 2025 canonical event contains seven fitted index streams, not verified as the 2026 values.',
  weights_evidence = 'The 2026 model setup reads catch and stock-weight files from boot/data, which are not present in the public repository snapshot. The preceding 2025 assessment has reported age-specific weights in the canonical database; the current 2026 values remain unverified.',
  maturity_evidence = 'The 2026 repository includes scripts to prepare and estimate maturity surfaces, but the required age data, generated mat_data.Rdata, and fitted maturity outputs are not included. The 2025 canonical maturity inputs are not confirmed as the current 2026 surface.',
  mortality_evidence = 'The 2026 assessment configuration and fitted model object are not included in the public repository snapshot, so the current M specification and values cannot be verified. The database records the preceding 2025 run separately.',
  timing_evidence = 'The 2026 numeric survey inputs and recalibrated configuration are absent; exact sampling fractions for the current run could not be verified. The 2025 event retains Q1=0.125, Q3+Q4=0.75, and recruitment-index timing=0, but these values are not assumed unchanged.',
  output_evidence = 'ICES SAG 2026 keys 26001-26003 provide official substock annual recruitment, SSB, total biomass, catch and F summaries with reported uncertainty where available; key 26010 provides combined landings and discards through 2025. These tables do not provide numeric N/F-at-age arrays; the 2026 endpoint has only the measures published for that year.',
  detailed_source_url = paste('https://doi.org/10.17895/ices.advice.30932018.v1', 'https://asd.ices.dk/viewAdvice/7246', 'https://sg.ices.dk/ViewSourceData.aspx?key=26001', 'https://sg.ices.dk/ViewSourceData.aspx?key=26002', 'https://sg.ices.dk/ViewSourceData.aspx?key=26003', 'https://sg.ices.dk/ViewSourceData.aspx?key=26010', 'https://github.com/ices-advice/2026_cod.27.46a7d20/tree/4b26121d33252734e3258912968de3cdbda065e4', sep = '; '),
  review_date = '2026-10-29',
  decision_reason = 'The latest official assessment is the 2026 assessment-year run used for advice released 2026-10-09. Its official SAG pages provide run-specific summary outputs and its pinned repository provides model/data-preparation code, but the run-specific numerical inputs, configuration and fitted object are absent. Eligibility remains unresolved until the latest-run inputs are recovered. The 2025 detailed event already in the database is retained separately and is not used to fill 2026 gaps.',
  notes = 'Matched to canonical stock ices_cod_north_sea. The 2026 run source snapshot is cached in the gitignored directory source_cache/discovery_ices_northern_shelf_cod_2026/ with retrieval dates, URLs and SHA-256 values in sources.csv. The 2025 detailed event is ices_cod_north_sea_2025; it is not treated as the current 2026 event.'
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
cat('Screened current ICES Northern Shelf cod sources; current-run eligibility remains unresolved.\n')
