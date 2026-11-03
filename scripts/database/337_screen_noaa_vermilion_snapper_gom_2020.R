root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_vermilion_snapper_gom_2020')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'sedar67_final_assessment.pdf',
    'sedar67_ssc_review.pdf',
    'sedar67_executive_summary.pdf',
    'gulf_ssc_september_2023_minutes.pdf',
    'gulf_ssc_september_2023_summary.pdf',
    'gulf_sedar_schedule_february_2025.pdf'
  ),
  url = c(
    'https://sedarweb.org/documents/sedar-67-gulf-of-mexico-vermilion-snapper-final-stock-assessment-report/',
    'https://sedarweb.org/documents/report-of-the-gulf-of-mexico-ssc-review-of-the-sedar-67-vermilion-snapper-assessment/',
    'https://sedarweb.org/documents/sedar-67-gulf-of-mexico-vermillion-snapper-executive-summary-report/',
    'https://gulf-council-media.s3.amazonaws.com/uploads/2025/05/GMFMC-SSC-September-2023.pdf',
    'https://gulf-council-media.s3.amazonaws.com/uploads/2025/02/Gulf-Standing-RF-Socio-Eco-SSC-Summary-Sept-2023-10082023.pdf',
    'https://gulf-council-media.s3.amazonaws.com/uploads/2025/04/I-4a-STC_Feb2025_Summary_v4_with_graphics.pdf'
  ),
  revision = c(
    'SEDAR 67 final Stock Synthesis report, updated July 2020; model through 2017',
    'Gulf Council SSC review of SEDAR 67, June 1, 2020',
    'SEDAR 67 Gulf vermilion snapper executive summary, 2020',
    'Gulf Council SSC meeting minutes, September 27-28, 2023',
    'Gulf Council SSC meeting summary, September 2023',
    'SEDAR Steering Committee summary report, February 2025; Gulf Council recommended an update in 2027'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the listed SEDAR 67 and Gulf Council sources before screening.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', shQuote(path), 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
manifest <- transform(sources, bytes = file.info(paths)$size,
  sha256 = unname(vapply(paths, sha256_file, character(1L))))
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  previous_rows <- match(previous$file, manifest$file)
  if (anyNA(previous_rows) ||
      !identical(previous$url, manifest$url[previous_rows]) ||
      !identical(previous$revision, manifest$revision[previous_rows]) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes[previous_rows])) ||
      !identical(tolower(previous$sha256), manifest$sha256[previous_rows]))
    stop('Cached SEDAR 67 or Gulf Council manifest differs from the reviewed files.',
      call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10256 & stocksmart$assessment_id == 10102,
  , drop = FALSE]
monitoring <- stocksmart[stocksmart$stock_id == 10256 & stocksmart$assessment_id == 13023,
  , drop = FALSE]
if (nrow(run) != 1L || run$assessment_year != 2020L || run$last_data_year != 2017L ||
    run$review_result != 'Full acceptance' || run$assessment_model != 'SS' ||
    run$stock_name != 'Vermilion snapper - Gulf of Mexico' ||
    nrow(monitoring) != 1L || monitoring$assessment_year != 2023L ||
    monitoring$last_data_year != 2023L ||
    monitoring$assessment_type != 'Stock Monitoring Update' ||
    monitoring$review_result != 'Accept previous approach, remand new attempt')
  stop('NOAA Stock SMART metadata differs from the screened Gulf Vermilion Snapper runs.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10256'
i <- match(id, candidates$candidate_id)
candidate_unit_id <- 'noaa_vermilion_snapper_gulf_mexico'
south_atlantic <- match('NOAA:10257', candidates$candidate_id)
if (is.na(i) || is.na(south_atlantic) ||
    candidates$scientific_name[i] != 'Rhomboplites aurorubens' ||
    candidates$stock_name[i] != 'Vermilion snapper - Gulf of Mexico' ||
    candidates$assessment_area[i] != 'Gulf of Mexico' ||
    as.integer(candidates$inventory_assessment_year[i]) != 2023L ||
    candidates$scientific_name[south_atlantic] != candidates$scientific_name[i] ||
    candidates$assessment_area[south_atlantic] != 'Southern Atlantic Coast' ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE) ||
    any(stocks$scientific_name == 'Rhomboplites aurorubens') ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$assessment_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) ||
    any(outputs$assessment_id == candidate_unit_id))
  stop('NOAA Gulf Vermilion Snapper identity conflicts with candidate or canonical records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest full accepted age-structured run located is SEDAR 67 (Stock SMART run',
    '10102), an operational Stock Synthesis model with data through 2017. Its Appendix A',
    'prints the final SS3 input files. Commercial east and west handline catch is in metric',
    'tons; recreational catch is in thousands of fish. The model fits commercial east and',
    'west and aggregated Gulf-wide recreational age compositions, with modeled ages 0-14',
    '(age 14 is a plus group; fishery recruitment and fishing begin at age 1). Age-specific',
    'catch can be reconstructed from catch totals and these compositions.'),
  survey_age_evidence = paste(
    'The 2020 model uses aggregate fishery-dependent and fishery-independent indices,',
    'including headboat CPUE, SEAMAP larval, combined video, and SEAMAP summer groundfish',
    'series. Survey likelihoods are not age-specific abundance indices; survey compositions',
    'are length-based. The 2023 Gulf interim analysis uses an updated G-FISHER video index',
    'to review catch advice and is not a replacement age-structured assessment.'),
  weights_evidence = paste(
    'Growth and length-weight relationships are fixed from SEDAR 45 and retained in SEDAR 67.',
    'Age-specific weights can be derived from the run-specific growth and length-weight inputs;',
    'the model-ready values should be checked against the printed Appendix A and Table 2.'),
  maturity_evidence = paste(
    'The report gives the fixed maturity relationship and spawning biology. The model defines',
    'spawning output as egg production, using female proportion, maturity, batch fecundity,',
    'and spawning frequency, rather than conventional biomass SSB.'),
  mortality_evidence = paste(
    'Natural mortality is a fixed age-specific Lorenzen vector, scaled to average M = 0.25.',
    'Age-0 mortality is adjusted for the assumed midyear birth date.'),
  timing_evidence = paste(
    'The assessment is annual, single-season, and assumes fishing and spawning occur',
    'continuously through the year. Exact within-year timing for each survey index is not',
    'established by the reviewed report and should not be inferred from annual frequency.'),
  output_evidence = paste(
    'Table 18 reports annual total biomass (metric tons), spawning output (eggs), total',
    'abundance (thousands of fish), and recruitment (thousands of fish) through 2017.',
    'Tables 16-17 report fleet fishing mortality and harvest rate, not F-at-age. N-at-age',
    'appears only as a figure; no numeric N-at-age or F-at-age series or population-output',
    'uncertainty table was located.'),
  detailed_source_url = paste(sources$url, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation as a distinct Gulf of Mexico unit. The latest Stock SMART',
    'row is a 2023 Stock Monitoring Update whose review outcome is “Accept previous approach,',
    'remand new attempt”; the 2023 Gulf SSC interim analysis used G-FISHER to consider catch',
    'advice and its motion to accept the analysis and recommend updated catch advice failed.',
    'Neither establishes a new accepted age-structured assessment. The latest full accepted',
    'age-structured run located is the 2020 SEDAR 67 Stock Synthesis assessment through 2017,',
    'with final model input files and numerical aggregate outputs in its report. It is eligible',
    'for detailed source curation, with age-specific survey indices and numeric N/F-at-age',
    'outputs absent from the reviewed public sources. A February 2025 committee summary records',
    'the Gulf Council recommendation for an update in 2027; this is a future recommendation,',
    'not a completed assessment.'),
  notes = paste(
    'Do not combine the 2023 interim index update with the 2020 SEDAR 67 likelihood or outputs.',
    'The same species has a separate NOAA:10257 Southern Atlantic Coast management unit; the',
    'Gulf and South Atlantic entries remain separate. SEDAR 67 outputs are point estimates',
    'without population-series uncertainty in Table 18; the report provides no numeric',
    'N-at-age/F-at-age arrays. The August 2025 committee summary places its vermilion snapper',
    'assessment scheduled outside SEDAR under the South Atlantic section, so it was not used',
    'as evidence about this Gulf unit. No canonical database values were imported.')
)
for (column in names(review)) candidates[[column]][i] <- review[[column]]

bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
line_feeds <- which(bytes == as.raw(10L))
physical_line <- i + 1L
if (length(line_feeds) < physical_line) stop('Candidate CSV row is out of range.', call. = FALSE)
first <- line_feeds[physical_line - 1L] + 1L
last <- line_feeds[physical_line]
ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
tmp <- tempfile(fileext = '.csv')
write.table(candidates[i, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
  col.names = FALSE, quote = TRUE, na = '')
replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
unlink(tmp)
replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
before <- bytes[seq_len(first - 1L)]
after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
cat('Screened NOAA Gulf of Mexico Vermilion Snapper (NOAA:10256) as eligible for source curation.\n')
