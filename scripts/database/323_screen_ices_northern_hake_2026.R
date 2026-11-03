root <- "."
cache <- file.path(root, 'source_cache', 'ices_northern_hake_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
source_review_path <- file.path(root, 'discovery', 'source_reviews',
  'ices_northern_hake_2026.md')
manifest_path <- file.path(cache, 'manifest.csv')
candidate_id <- 'ICES:hke.27.3a46-8abd'
candidate_unit_id <- 'ices_northern_hake'
required_files <- c('wgbie_2026_hake_north_section09.pdf',
  'ices_advice_2026_hake_north.pdf', 'ices_sag_2026_source_data.html')
source_urls <- c(
  'https://ndownloader.figshare.com/files/66353060',
  'https://ndownloader.figshare.com/files/66071894',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22627'
)
if (!all(file.exists(file.path(cache, required_files))) ||
    any(file.info(file.path(cache, required_files))$size <= 0)) {
  stop('Cache the reviewed 2026 ICES report section, advice PDF, and graph data before screening.',
    call. = FALSE)
}

hash_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
      value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- data.frame(
  file = file.path(cache, required_files),
  url = source_urls,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC',
    format = '%Y-%m-%dT%H:%M:%SZ'), length(required_files)),
  sha256 = vapply(file.path(cache, required_files), hash_file, character(1L)),
  stringsAsFactors = FALSE
)
if (file.exists(manifest_path)) {
  existing <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(existing$file, manifest$file) ||
      !identical(existing$url, manifest$url) ||
      !identical(existing$sha256, manifest$sha256)) {
    stop('Cached source manifest does not match the reviewed files.', call. = FALSE)
  }
} else {
  write.csv(manifest, manifest_path, row.names = FALSE, na = '')
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- which(candidates$candidate_id == candidate_id)
if (length(i) != 1L || candidates$official_stock_id[i] != 'hke.27.3a46-8abd' ||
    !grepl('Merluccius merluccius', candidates$scientific_name[i], fixed = TRUE) ||
    !grepl('Northern stock', candidates$stock_name[i], fixed = TRUE)) {
  stop('Expected one current ICES northern hake inventory row.', call. = FALSE)
}
if (any(stocks$authority_stock_id == 'hke.27.3a46-8abd', na.rm = TRUE) ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE)) {
  stop('Northern hake conflicts with an existing canonical or candidate identity.',
    call. = FALSE)
}
if (any(assessments$assessment_id == 'ices_northern_hake_2026') ||
    any(inputs$assessment_id == 'ices_northern_hake_2026') ||
    any(outputs$assessment_id == 'ices_northern_hake_2026')) {
  stop('This source-screening step must not add canonical assessment data.',
    call. = FALSE)
}

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current 2026 Stock Synthesis assessment uses fleet catches, landings',
    'and discards plus length-frequency distributions. No catch-at-age series is reported.',
    'Figure 9.7 also notes mean-length-at-age observations; these do not provide annual catch',
    'numbers-at-age or catch age compositions.'),
  survey_age_evidence = paste('The model uses aggregate survey abundance indices and survey length',
    'compositions. No age-specific abundance index or survey age-composition series is reported.',
    'The North Sea IBTS index is discussed but is not used in this assessment.'),
  weights_evidence = 'The model uses growth and length-weight relationships; age-specific input weight series are not reported in the 2026 assessment sources.',
  maturity_evidence = 'The 2026 assessment uses constant maturity, but the numerical ogive is not reported in the recovered summary sources.',
  mortality_evidence = 'The sex-separated Stock Synthesis model uses sex-dependent, age-dependent natural mortality; values are not reported in the recovered summary sources.',
  timing_evidence = paste('The model is seasonal and uses survey indices and length observations from multiple quarters.',
    'A single annual sampling-time fraction is not specified in the recovered summary sources.'),
  output_evidence = paste('The 2026 ICES source data report annual age-0 recruitment, total biomass, female SSB,',
    'catches, landings, discards, and aggregate F for ages 1-7, with intervals for recruitment, SSB,',
    'and F with 90% intervals. The assessment report shows numbers-at-age in a short-term forecast figure, not a',
    'historical annual N-at-age series; no historical F-at-age, M-at-age, or full age-specific',
    'population output series was recovered.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.32790321.v1',
    'https://doi.org/10.17895/ices.advice.30932108.v1',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22627', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest current-unit production assessment is the 2026 WGBIE update.',
    'It uses a sex-separated, age-structured population model internally, but its fitted observations',
    'are fleet catches, aggregate abundance indices, and length-frequency data rather than',
    'catch-at-age or age-specific survey observations. The public source data give aggregate annual',
    'outputs; the report only shows a short-term numbers-at-age forecast. It is ineligible for the',
    'age-disaggregated input/output set. The 2026 report cites a TAF assessment repository that was',
    'not publicly accessible during this review.'),
  notes = paste('This current northern hake advice unit has no matching canonical stock record; the',
    'separate ICES southern hake unit and the NOAA-DFO Pacific hake unit are not matches. The 2026',
    'WGBIE report and advice are cached under source_cache/ices_northern_hake_2026/. The assessment',
    'repository cited in report footnote 3 returned no public GitHub repository metadata.')
)
for (column in names(review)) candidates[[column]][i] <- review[[column]]

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path,
    call. = FALSE)
  first <- if (physical_line == 1L) 1L else line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) {
    as.raw(c(13L, 10L))
  } else {
    as.raw(10L)
  }
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}

source_review <- c(
  '# ICES northern hake (`hke.27.3a46-8abd`)',
  '',
  'Reviewed 2026-10-30. ICES continues to assess the northern hake unit across subareas 4, 6, and 7 and divisions 3.a, 8.a, 8.b, and 8.d. The latest production assessment is the 2026 WGBIE update; ICES issued advice for 2027 catches of no more than 46,824 tonnes.',
  '',
  'The 2026 assessment uses a sex-separated Stock Synthesis population model with sex-dependent growth and natural mortality. Its observations are commercial catches, aggregate survey abundance indices, and length-frequency data for landings, discards, and surveys. Figure 9.7 also identifies mean-length-at-age observations, but the assessment does not report catch-at-age or annual age-composition inputs. The survey indices are aggregate; the North Sea IBTS biomass/abundance survey is discussed but explicitly not used in the fit.',
  '',
  'ICES Standard Graphs reports annual age-0 recruitment, total biomass, female spawning-stock biomass, landings, catches, discards, and F averaged over ages 1-7, with 90% intervals for recruitment, SSB, and F. The report contains a numbers-at-age figure for the short-term forecast, not a historical annual N-at-age series. No historical F-at-age, M-at-age, or age-specific abundance series was recovered from the public outputs. Age-specific weights and numerical maturity/M inputs are not available in the recovered 2026 summary sources.',
  '',
  'The case is screened ineligible for the age-disaggregated set because the current assessment lacks catch-at-age and age-specific survey observations, and a historical annual age-specific population output series was not recovered. The assessment report cites an ICES TAF repository, but its GitHub API endpoint returned 404 during this review, so its input and output files could not be checked. The detailed assessment and aggregate comparison outputs remain useful for a future non-age-structured comparison.',
  '',
  'Sources:',
  '',
  '- [ICES WGBIE 2026 report](https://doi.org/10.17895/ices.pub.32790321.v1), Section 9, pp. 416-464; especially Sections 9.2-9.3 and Figures 9.7 and 9.19.',
  '- [ICES 2026 Advice View](https://asd.ices.dk/viewAdvice/5110), stock assessment key 22627; advice for 2027 catches.',
  '- [ICES Standard Graphs source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22627), stock key 22627.',
  '- The report cites [the 2026 TAF assessment repository](https://github.com/ices-taf/2026_hke.27.3a46-8abd_assessment) in footnote 3; public GitHub metadata was unavailable during this review.',
  '',
  'The assessment section, advice PDF, and Standard Graphs source page are cached in the gitignored `source_cache/ices_northern_hake_2026/`; `manifest.csv` records download URLs, retrieval time, and SHA-256 checksums.'
)
writeLines(source_review, source_review_path, useBytes = TRUE)
replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
cat('Screened ICES northern hake as a current length-data assessment, ineligible for the age-disaggregated set.\n')
