root <- "."
cache <- file.path(root, 'source_cache', 'noaa_windowpane_2023')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
review_path <- file.path(root, 'discovery', 'source_reviews', 'noaa_windowpane_2023.md')
manifest_path <- file.path(cache, 'manifest.csv')

candidate_ids <- c('NOAA:10192', 'NOAA:10193')
candidate_units <- c('noaa_windowpane_north_gom_gb', 'noaa_windowpane_south_sne_ma')
expected_areas <- c('Gulf of Maine / Georges Bank',
  'Southern New England / Mid-Atlantic')
source_files <- c('northern_windowpane_2023_management_track.pdf',
  'southern_windowpane_2023_management_track.pdf')
source_urls <- c(
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9039',
  'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9040')
source_revisions <- c('2023 Management Track Assessment; compiled 2023-10-17',
  '2023 Management Track Assessment; compiled 2023-09-21')
source_paths <- file.path(cache, source_files)

if (!all(file.exists(source_paths)) || any(file.info(source_paths)$size <= 0)) {
  stop('Cache both NOAA 2023 Windowpane assessment reports before screening.', call. = FALSE)
}
pdf_headers <- vapply(source_paths, function(path) {
  identical(readBin(path, 'raw', n = 4L), charToRaw('%PDF'))
}, logical(1L))
if (!all(pdf_headers)) stop('A cached NOAA source is not a PDF.', call. = FALSE)

hash_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- data.frame(file = source_paths, url = source_urls,
  revision = source_revisions,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(source_paths)),
  bytes = file.info(source_paths)$size,
  sha256 = vapply(source_paths, hash_file, character(1L)), stringsAsFactors = FALSE)
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) || !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(previous$sha256, manifest$sha256)) {
    stop('Cached source manifest does not match the reviewed source files.', call. = FALSE)
  }
} else {
  write.csv(manifest, manifest_path, row.names = FALSE, na = '')
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

indices <- match(candidate_ids, candidates$candidate_id)
if (anyNA(indices) || anyDuplicated(indices) ||
    any(candidates$scientific_name[indices] != 'Scophthalmus aquosus') ||
    any(candidates$assessment_area[indices] != expected_areas) ||
    any(candidates$inventory_assessment_year[indices] != 2023L)) {
  stop('Expected the two current NOAA Windowpane inventory rows.', call. = FALSE)
}
if (any(stocks$authority_stock_id %in% c('10192', '10193'), na.rm = TRUE) ||
    any(stocks$stock_id %in% candidate_units) ||
    any(candidates$candidate_unit_id[-indices] %in% candidate_units, na.rm = TRUE)) {
  stop('Windowpane stock identity conflicts with an existing canonical/candidate unit.',
    call. = FALSE)
}
if (any(assessments$stock_id %in% candidate_units) ||
    any(inputs$assessment_id %in% candidate_units) ||
    any(outputs$assessment_id %in% candidate_units)) {
  stop('This inventory screen must not add canonical assessment data.', call. = FALSE)
}

common <- list(
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2023 assessments use annual total catch in weight; no catch-at-age or age-composition likelihood was identified.',
  survey_age_evidence = 'The assessments use aggregate NEFSC bottom-trawl survey biomass indices. Survey age samples or length compositions are not age-specific abundance observations in these models.',
  weights_evidence = 'No weights-at-age are used by the current aggregate assessment methods.',
  maturity_evidence = 'No maturity-at-age is used by the current aggregate assessment methods.',
  mortality_evidence = 'The current empirical/AIM methods do not estimate or require age-specific natural mortality.',
  timing_evidence = 'The source reports annual survey series but no within-year fractional timing; there is no age-structured tinyAM observation series to map.',
  output_evidence = 'The northern assessment reports swept-area biomass (metric tons) and catch/biomass exploitation rate (percent). The southern assessment reports a three-year mean survey biomass index (kg/tow) and relative F (kt per kg/tow). Neither reports population-at-age or age-specific mortality.',
  detailed_source_url = paste(source_urls, collapse = '; '), review_date = '2026-10-30',
  notes = paste('Separate Gulf of Maine/Georges Bank and Southern New England/Mid-Atlantic stock units.',
    'Biological ageing work and survey length compositions do not establish age-disaggregated assessment likelihood inputs.')
)
specific <- list(
  list(candidate_unit_id = candidate_units[1], decision_reason = paste(
    'The latest assessment update is the 2023 Management Track Assessment using data through 2022.',
    'The 2019 AIM model was discontinued after poor fit; the current empirical method estimates swept-area biomass and catch/biomass exploitation rates from aggregate catch and survey data.',
    'It provides no age-based likelihood or population-at-age outputs, so this current unit is ineligible for the age-disaggregated assessment inventory.')),
  list(candidate_unit_id = candidate_units[2], decision_reason = paste(
    'The latest assessment update is the 2023 Management Track Assessment using data through 2022.',
    'The assessment retains the aggregate AIM model, using catch and the NEFSC fall survey biomass index; the published outputs are biomass-index and relative-F summaries.',
    'It provides no age-based likelihood or population-at-age outputs, so this current unit is ineligible for the age-disaggregated assessment inventory.'))
)

for (j in seq_along(indices)) {
  i <- indices[j]
  for (column in names(common)) candidates[[column]][i] <- common[[column]]
  for (column in names(specific[[j]])) candidates[[column]][i] <- specific[[j]][[column]]
}

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path, call. = FALSE)
  first <- if (physical_line == 1L) 1L else line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}

for (i in indices) replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])

source_review <- c(
  '# NOAA Windowpane flounder, northern and southern units (2023)', '',
  'Reviewed 2026-10-30. NOAA Stock SMART rows 10192 and 10193 describe separate Gulf of Maine/Georges Bank and Southern New England/Mid-Atlantic units. No matching canonical tinyAM stock record was found; they are crosswalked as two distinct provisional units.', '',
  'The latest detailed updates located are the 2023 Management Track Assessment reports, both using data through 2022. The northern report says the prior AIM model had been discontinued after poor fit in the 2019 operational assessment and uses an empirical method based on paired-gear survey catch efficiencies. It combines total catch with aggregate fall NEFSC bottom-trawl survey indices to estimate swept-area biomass and catch/biomass exploitation rate. The southern report retains the AIM model with aggregate catch and fall NEFSC survey biomass; it reports a three-year moving-average biomass index and relative F defined from catch divided by survey index.', '',
  'Neither current assessment uses catch-at-age, age compositions, age-specific survey abundance, weights-at-age, maturity-at-age, or age-specific natural mortality. Age-reading and biological sampling do not amount to age-disaggregated likelihood inputs. Their reported biomass, exploitation, and relative-F outputs are aggregate empirical indicators, not population-at-age or instantaneous F-at-age surfaces. The assessment sources therefore do not support an age-structured tinyAM source record for either current unit.', '',
  'The northern report describes its paper as a draft working paper for peer review. The September 2023 Management Track peer-review report includes the northern unit; its public download returned HTTP 403 during this retrieval, so the cached northern assessment report remains the primary detailed source. The southern report is also labelled a draft working paper for peer review; the September 2023 peer-review compilation lists windowpane as Level 2 for the northern and Level 1 for the southern stock, so the southern update is not described here as a formal peer-reviewed assessment.', '',
  'Sources:', '',
  '- [NOAA NEFSC 2023 Management Track Assessment, northern windowpane](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9039), compiled 2023-10-17; data through 2022.',
  '- [NOAA NEFSC 2023 Management Track Assessment, southern windowpane](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9040), compiled 2023-09-21; data through 2022.',
  '- [NOAA NEFSC Fall 2023 Management Track Assessments Report](https://doi.org/10.25923/1p81-jn30), including the September peer-review panel report and review-level listing.',
  '- [NOAA 2023 September Management Track Peer Review Panel Report](https://www.fisheries.noaa.gov/s3/2023-10/2023-September-Management-Track-Peer-Review-Panel-Report-good.pdf); direct public download returned HTTP 403 during retrieval.',
  '- [NOAA NEFSC Reference Document 22-06](https://repository.library.noaa.gov/view/noaa/39402), 2019 operational review context for the northern AIM model.', '',
  'Both per-stock assessment PDFs are cached in `source_cache/noaa_windowpane_2023/`; the local manifest records source URLs, assessment revision, retrieval time, bytes, and SHA-256 checksums. The peer-review PDF was not cached because the public download endpoint returned HTTP 403.'
)
writeLines(source_review, review_path, useBytes = TRUE)
cat('Screened both current NOAA Windowpane units as ineligible for age-disaggregated assessment inputs.\n')
