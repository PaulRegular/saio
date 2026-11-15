path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10187'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected NOAA butterfish inventory row was not found.', call. = FALSE)
if (any(grepl('10187', read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE)$authority_stock_id, fixed = TRUE))) {
  stop('Unexpected canonical match for NOAA butterfish.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_butterfish_gom_cape_hatteras',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The accepted 2024 Management Track support tables report total-catch proportions by',
    'weight at ages 0, 1, 2, 3, and 4+ for 1989-2023. With total catch and mean catch',
    'weight at age, numbers-at-age can be reconstructed from source quantities.'
  ),
  survey_age_evidence = paste(
    'SASI Tables 6-7 report NEFSC spring/fall mean numbers per tow at ages 0-4+ for',
    '1989-2023; Tables 9-10 give NEAMAP spring/fall age indices from 2008/2007-2023.',
    'The carried-forward model excludes NEFSC spring Albatross; exact 2024 run inputs',
    'are not in the support archive.'
  ),
  weights_evidence = paste(
    'SASI Table 3 reports total-catch mean weights at ages 0, 1, 2, 3, and 4+ in kg',
    'for 1989-2023, with stated interpolations for age 4+ in 1996-1997 and age 0 in 2017.'
  ),
  maturity_evidence = paste(
    'The carried-forward base report Table 3.2 provides annual age-0 to 4+ maturity',
    'ogives for 1989-2019. The 2024 update does not table 2020-2023 values; current-run',
    'terminal maturity inputs need follow-up.'
  ),
  mortality_evidence = 'The 2024 report states that the assessment carries forward M = 1.278 from the 2020 model.',
  timing_evidence = paste(
    'The assessment uses spring and fall survey series. The base model uses spawning',
    'fraction 0.5 and specifies month 10 for NEAMAP fall; exact 2024 run-matched timing',
    'for the remaining survey series is not published in the support archive.'
  ),
  output_evidence = paste(
    'SASI Table 11 reports annual SSB (mt), fully selected F at age 3, and age-0',
    'recruitment (millions), with CVs, for 1989-2023. Numeric fitted N-at-age and',
    'F-at-age arrays were not found in the 2024 support archive.'
  ),
  detailed_source_url = paste(
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=16&stock_id=6&review_type_id=2&filename=2024_BUT_UNIT.zip;',
    'https://www.fisheries.noaa.gov/s3/2024-07/2024-June-Management-Track-Peer-Review-Panel-Report-508-7-18-24.pdf;',
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=16&stock_id=6&review_type_id=5&info_type_id=5&map_type_id=&filename=Butterfish_2021_Assessment_Report.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2024 Level 2 Management Track is the latest production run located; the peer',
    'review panel endorsed it as best scientific information available. Numerical',
    'catch composition, age-specific survey series, age weights, fixed M, maturity',
    'base ogives, and annual SSB/F/recruitment outputs support source curation. The',
    '2024-run maturity extension and exact complete survey timing remain unresolved.'
  ),
  notes = paste(
    'Provisional new NOAA unit, not present in canonical stocks or other reviewed',
    'candidate rows. Do not import the reconstructed catch numbers until the source',
    'proportions, total catch, weight units, and run linkage are independently checked.'
  )
)

for (column in names(review)) x[[column]][i] <- review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA butterfish stock 10187.\n')
