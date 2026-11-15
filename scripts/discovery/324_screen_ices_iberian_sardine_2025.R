root <- "."
cache <- file.path(root, 'source_cache', 'ices_iberian_sardine_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
source_review_path <- file.path(root, 'discovery', 'source_reviews', 'ices_iberian_sardine_2025.md')
manifest_path <- file.path(cache, 'manifest.csv')
candidate_id <- 'ICES:pil.27.8c9a'
candidate_unit_id <- 'ices_iberian_sardine_8c9a'
required_files <- c('wghansa_2025_report.pdf', 'sardine_stock_annex_2026.pdf',
  'ices_sardine_advice_2025.pdf', 'ices_sardine_standard_graphs_data.html')
source_urls <- c('https://ndownloader.figshare.com/files/62700859',
  'https://ndownloader.figshare.com/files/62698540',
  'https://ndownloader.figshare.com/files/60316211',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21259')
source_revisions <- c('10.17895/ices.pub.29335520.v3',
  '10.17895/ices.pub.31305346.v1', '10.17895/ices.advice.27692337.v1',
  'Assessment key 21259; accessed 2026-10-30')
source_paths <- file.path(cache, required_files)
if (!all(file.exists(source_paths)) || any(file.info(source_paths)$size <= 0)) {
  stop('Cache the ICES report, stock annex, advice, and Standard Graphs data before screening.', call. = FALSE)
}
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
manifest <- data.frame(file = source_paths, url = source_urls, revision = source_revisions,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(required_files)), bytes = file.info(source_paths)$size,
  sha256 = vapply(source_paths, hash_file, character(1L)), stringsAsFactors = FALSE)
if (file.exists(manifest_path)) {
  existing <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(existing$file, manifest$file) || !identical(existing$url, manifest$url) ||
      !identical(existing$revision, manifest$revision) ||
      !identical(existing$sha256, manifest$sha256)) {
    stop('Cached source manifest does not match the reviewed files.', call. = FALSE)
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
i <- which(candidates$candidate_id == candidate_id)
if (length(i) != 1L || candidates$official_stock_id[i] != 'pil.27.8c9a' ||
    !grepl('Sardina pilchardus', candidates$scientific_name[i], fixed = TRUE) ||
    candidates$inventory_assessment_year[i] != 2025) {
  stop('Expected one current ICES Iberian sardine inventory row.', call. = FALSE)
}
if (any(stocks$authority_stock_id == 'pil.27.8c9a', na.rm = TRUE) ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE)) {
  stop('Iberian sardine conflicts with an existing canonical or candidate identity.', call. = FALSE)
}
if (any(assessments$assessment_id == 'ices_iberian_sardine_2025') ||
    any(inputs$assessment_id == 'ices_iberian_sardine_2025') ||
    any(outputs$assessment_id == 'ices_iberian_sardine_2025')) {
  stop('This screen must not add canonical assessment data.', call. = FALSE)
}
review <- list(
  candidate_unit_id = candidate_unit_id, match_status = 'new',
  screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
  catch_age_evidence = paste('The 2026 Stock Annex reports catch numbers-at-age for 1978 onward, ages 0-6+',
    'from raised Spanish and Portuguese national figures. Cadiz catch compositions before 1998 are',
    'reconstructed using South Portugal age composition. The annual numeric input matrix was not',
    'recovered because the assessment TAF repository is not publicly accessible. The annex does not specify the numeric scale.'),
  survey_age_evidence = paste('The model uses spring acoustic abundance indices and age compositions for ages 1-6+',
    'across areas 8c and 9a from 1997 onward, plus an autumn age-0 abundance index for subdivision',
    '9.a.c.n. from 1997 onward. A triennial aggregate DEPM SSB index is also used. Numeric annual',
    'age-specific index and composition matrices were not recovered.'),
  weights_evidence = paste('Catch weights-at-age are supplied for ages 0-6+; 1978-1990 uses assumed means',
    'from 1991-1995. Spawning-stock weights-at-age use DEPM, with 1978-1998 assumed from the',
    '1999 and 2002 surveys and interpolation between survey years. The annual numeric series was',
    'not recovered.'),
  maturity_evidence = paste('Maturity-at-age is derived from DEPM surveys, interpolated between surveys;',
    '1978-1998 uses the mean from 1999-2014 and years after the last survey use the latest estimate.',
    'The annual numeric ogive was not recovered.'),
  mortality_evidence = 'The 2026 Stock Annex gives fixed annual M-at-age values based on the Gislason formulation: ages 0-6+ = 0.98, 0.61, 0.47, 0.40, 0.36, 0.35, and 0.32 year-1.',
  timing_evidence = paste('The assessment is annual, single-season, and estimates start-of-year biomass.',
    'The report does not give fractional-year sampling times for spring or autumn acoustic indices.'),
  output_evidence = paste('ICES Standard Graphs key 21259 provides annual age-0 recruitment, B1+ biomass',
    '(the stock annex identifies SSB as B1+), and F averaged over ages 2-5 for 1978-2025, with',
    '95% intervals. Historical N-at-age, F-at-age, and M-at-age outputs are not provided.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.29335520.v3',
    'https://doi.org/10.17895/ices.pub.31305346.v1',
    'https://doi.org/10.17895/ices.advice.27692337.v1',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21259', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest current-unit production assessment is the 2025 Stock Synthesis run.',
    'The 2026 Stock Annex verifies age-specific catch, acoustic index, age composition, weight,',
    'maturity, and fixed M input structures, while Standard Graphs provides annual recruitment,',
    'B1+, and Fbar outputs. The published sources do not provide the numeric annual input matrices,',
    'and the cited TAF repository returned 404 from the public GitHub API. Eligibility remains',
    'unresolved pending run-matched inputs and exact survey timing.'),
  notes = paste('This current Iberian sardine unit is distinct from the canonical Bay of Biscay unit',
    'pil.27.8abd; no exact-area canonical record was found. The 2026 advice uses the 2025 assessment.',
    'The cited 2025 TAF repository was not publicly accessible during review.')
)
for (column in names(review)) candidates[[column]][i] <- review[[column]]
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
source_review <- c(
  '# ICES Iberian sardine (pil.27.8c9a)', '',
  'Reviewed 2026-10-30. The current ICES stock list identifies the latest assessment year as 2025. The corresponding ICES advice uses that Stock Synthesis assessment for the 2026 catch recommendation.', '',
  'The March 2026 Stock Annex documents a single-area, single-season, combined-sex age-based Stock Synthesis model. It specifies catch numbers-at-age for 1978 onward, ages 0-6+, derived from raised Spanish and Portuguese figures. Cadiz catch compositions before 1998 are reconstructed using the South Portugal age composition. Commercial age compositions enter the likelihood. Annual numeric catch-at-age and composition input matrices are not in the recovered public sources. The annex does not specify the numeric scale for catch-at-age.', '',
  'The model uses a spring acoustic abundance index and age compositions for ages 1-6+ across divisions 8.c and 9.a from 1997 onward, an autumn age-0 recruitment index from subdivision 9.a.c.n. from 1997 onward, and a triennial aggregate SSB index from DEPM surveys. The Stock Annex describes the acoustic survey series, but it does not give the model input arrays or numeric fractional-year survey timing.', '',
  'Catch weights-at-age cover ages 0-6+; values for 1978-1990 are assumed from the 1991-1995 mean. Spawning-stock weights-at-age are interpolated between DEPM surveys, with the 1978-1998 values assumed from the 1999 and 2002 surveys. Maturity-at-age is also derived from DEPM, interpolated between survey years, held to the 1999-2014 mean in 1978-1998, and set to the latest estimate after the final survey. Fixed M-at-age is 0.98, 0.61, 0.47, 0.40, 0.36, 0.35, and 0.32 year-1 for ages 0, 1, 2, 3, 4, 5, and 6+.', '',
  'The 2025 Standard Graphs output reports annual age-0 recruitment, B1+ biomass (the stock annex defines SSB as B1+), and F averaged over ages 2-5 through 2025, with 95% intervals. Historical annual N-at-age, F-at-age, and M-at-age outputs were not recovered. The public GitHub API returned 404 for the TAF repository named in the Stock Annex. Because the exact model input matrices and survey timing remain unavailable, eligibility is unresolved rather than confirmed.', '',
  'This unit is distinct from the already curated Bay of Biscay sardine stock pil.27.8abd. No canonical current-area record was found.', '',
  'Sources:', '',
  '- [ICES WGHANSA 2025 report](https://doi.org/10.17895/ices.pub.29335520.v3).',
  '- [ICES Stock Annex, March 2026](https://doi.org/10.17895/ices.pub.31305346.v1), especially Sections 2-3 and pp. 13-28.',
  '- [ICES Advice 2025](https://doi.org/10.17895/ices.advice.27692337.v1), assessment year 2025.',
  '- [ICES Standard Graphs data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21259), stock assessment key 21259.',
  '- [TAF assessment repository cited by the Stock Annex](https://github.com/ices-taf/2025_pil.27.8c9a_assessment); public GitHub metadata returned 404 during this review.', '',
  'The report, Stock Annex, advice PDF, and Standard Graphs source page are cached in the gitignored source_cache/ices_iberian_sardine_2025/; the local manifest records URLs, pinned source revisions, retrieval time, file sizes, and SHA-256 checksums.'
)
writeLines(source_review, source_review_path, useBytes = TRUE)
replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
cat('Screened ICES Iberian sardine as unresolved pending recovery of its run-matched input matrices and timing.\n')