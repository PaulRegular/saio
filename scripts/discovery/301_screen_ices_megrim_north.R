path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'ICES:meg.27.7b-k8abd'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected ICES megrim inventory row was not found.', call. = FALSE)
if (any(grepl('meg.27.7b-k8abd', read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE)$authority_stock_id, fixed = TRUE))) {
  stop('Unexpected canonical match for ICES megrim.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'ices_megrim_north_7b_k8abd',
  stock_name = 'Megrim (Lepidorhombus whiffiagonis) - divisions 7.b-k, 8.a-b, and 8.d',
  assessment_area = 'ICES divisions 7.b-k, 8.a-b, and 8.d (west and southwest of Ireland, Bay of Biscay)',
  inventory_assessment_year = '2025',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'WGBIE 2025 reports landed, discarded, and total catch numbers-at-age through 2024,',
    'with annual catches tabulated for 1984-2024. The run-matched numeric catch-age',
    'matrix is not in the public report; age distributions and caught/landed/discarded',
    'age surfaces are figures, so exact numerical inputs remain unavailable.'
  ),
  survey_age_evidence = paste(
    'The assessment uses numeric age-specific indices: combined French-Irish Q4 IBTS',
    'G9527_G7212, ages 1-10 for 2003-2024 (2017 missing), and Spanish Porcupine Bank',
    'G5768, ages 1-10 for 2001-2024. Both series are tabulated in WGBIE 2025.'
  ),
  weights_evidence = paste(
    'WGBIE reports numbers- and weights-at-age through 2024 from four countries and',
    'Spanish age distributions converted from length data. The report does not reproduce',
    'the complete numeric run-matched weight-at-age arrays.'
  ),
  maturity_evidence = paste(
    'The assessment uses a female-only maturity ogive based on histological methods;',
    'the cited 2021 maturity study and northern stock annex are follow-up sources, but',
    'the public annex is dated 2018 despite the report describing 2022/2024 updates; the',
    'complete numeric vector and current annex version need verification.'
  ),
  mortality_evidence = 'Natural mortality is fixed at M = 0.2 for all ages and years.',
  timing_evidence = paste(
    'G5768 is described as occurring at the end of Q3 and start of Q4; the combined',
    'G9527_G7212 survey is Q4. Exact fractional-year timings are not stated.'
  ),
  output_evidence = paste(
    'The official assessment reports annual age-1 recruitment, SSB, catch, and mean F',
    'ages 3-6 for 1984-2024. Recruitment and SSB have 5th/95th percentiles; SAG provides',
    'low/high recruitment, SSB, and F. Numeric N-at-age and F-at-age matrices were not found.'
  ),
  detailed_source_url = paste(
    'https://doi.org/10.17895/ices.pub.29390639;',
    'https://ndownloader.figshare.com/files/58805062;',
    'https://ndownloader.figshare.com/files/58806451;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21222;',
    'https://asd.ices.dk/viewAdvice/3866;',
    'https://doi.org/10.17895/ices.pub.23261078'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2025 WGBIE category 1 a4a assessment has data through 2024 and is linked to',
    'official 2026 advice. WD12 says the initial base run was not accepted and then',
    'documents proposed corrections; exact linkage of the corrected run to advice key',
    '21222 needs native-file confirmation. Numeric catch-age matrices are absent from',
    'the report and shown only as figures. Keep eligibility unresolved; no values imported.'
  ),
  notes = paste(
    'Provisional new unit, distinct from southern megrim meg.27.8c9a. Candidate source',
    'cache is ignored by git. Source report identifies complete catch numbers/weights',
    'at age as submitted to InterCatch, but accessible numeric catch-age arrays were not found.'
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
cat('Screened ICES megrim meg.27.7b-k8abd.\n')
