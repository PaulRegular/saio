root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_sharpchin_goa_2024')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'NOAA:10434'
unit_id <- 'noaa_goa_sharpchin_goa'
files <- c('GOA_Other_Rockfish_2023_final.pdf', 'GOA_Other_Rockfish_2024_final.pdf',
  'GOA_Other_Rockfish_2025_final.pdf', 'SSC_Draft_Report_Dec_2025.pdf')
paths <- file.path(cache, files)
urls <- c(
  'https://files.npfmc.org/SAFE/2023/GOAorock.pdf',
  'https://files.npfmc.org/SAFE/2024/GOAorock.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=16.+Other+Rockfish.pdf&p=005cba48-4f2b-4649-9661-0669bc41cb56.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=Draft+SSC+Report+Dec+2025.pdf&p=74322a78-4de1-451c-a10f-13b11286f8b9.pdf'
)
revisions <- c(
  'Official 2023 GOA SAFE chapter 16; full operational assessment; REMA Model 15.2; survey biomass through 2023',
  'Official 2024 GOA SAFE chapter 16; operational update and species reassignment; catch through 2024; Tier 4 estimates carried forward',
  'Official 2025 GOA SAFE chapter 16 catch report; no assessment conducted; 2024 assessment values rolled over; catch through 2025-11-08',
  'NPFMC SSC draft report, December 2025; confirms GOA Other Rockfish chapter retained the 2024 models after the shutdown prevented the planned review cycle'
)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
if (any(!file.exists(paths)) || any(file.info(paths)$size <= 100L))
  stop('Cache the reviewed NOAA sources before screening ', id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
rows <- match(files, sources$file)
if (anyNA(rows) || !identical(sources$url[rows], urls) ||
    !identical(sources$revision[rows], revisions) ||
    !identical(tolower(sources$sha256[rows]), unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[rows]), as.numeric(file.info(paths)$size)))
  stop('Cached NOAA files differ from the reviewed source manifest.', call. = FALSE)

summary_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), summary_env)
stocksmart <- summary_env$stock_assessment_summary
stocksmart <- stocksmart[stocksmart$stock_id == 10434, , drop = FALSE]
stocksmart <- stocksmart[order(-as.numeric(stocksmart$assessment_year)), , drop = FALSE]
latest <- stocksmart[1L, , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_year != 2023L ||
    latest$assessment_id != 13120L || latest$review_result != 'Full acceptance' ||
    latest$model_version != 'REMA - 15.2' ||
    !grepl('Index', latest$assessment_model, fixed = TRUE) || latest$last_data_year != 2023L)
  stop('Cached Stock SMART record does not confirm the screened production run.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id_row <- match(id, candidates$candidate_id)
if (is.na(id_row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[id_row] != '10434' ||
    candidates$scientific_name[id_row] != 'Sebastes zacentrus' ||
    candidates$inventory_assessment_year[id_row] != 2023L ||
    any(stocks$authority_stock_id == '10434', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-id_row] == unit_id, na.rm = TRUE))
  stop('NOAA sharpchin identity conflicts with the register or database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The accepted assessment is a tiered GOA Other Rockfish',
    'complex model and uses aggregate catch by year and area; no catch numbers-at-age',
    'or fitted catch-at-age series are used.'),
  survey_age_evidence = paste('The Tier 4 sharpchin component uses aggregate GOA',
    'bottom-trawl survey biomass in REMA Model 15.2, not age-specific survey indices.'),
  weights_evidence = paste('The assessment uses total catch and survey biomass; it',
    'does not use a weight-at-age surface.'),
  maturity_evidence = paste('Sharpchin age and maturity information is background',
    'for Tier assignment, not an age-specific population likelihood or SSB output.'),
  mortality_evidence = paste('M = 0.06 is fixed for Tier 4 harvest reference',
    'calculations; the REMA assessment does not estimate age-specific M.'),
  timing_evidence = paste('The fitted observations are annual aggregate survey',
    'biomass and total catch; no within-year age-specific observation timing applies.'),
  output_evidence = paste('The 2024 update carries forward the Tier 4 aggregate',
    'biomass estimate of 7,008 t and reference points. The 2025 catch report says',
    'no assessment was conducted and carries forward prior outputs; no N/F/M-at-age,',
    'recruitment, or SSB series are reported.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Stock SMART identifies the latest fully accepted',
    'stock-specific run as the 2023 index assessment, REMA Model 15.2. The 2024',
    'official update changed the complex membership and updated catch but did not',
    'rerun Tier 4 because no new GOA survey biomass was available. The 2025 SAFE',
    'chapter is catch-only and says no assessment was conducted. The current model',
    'remains aggregate survey-biomass REMA, with no age-specific input likelihoods;',
    'screen ineligible for the age-disaggregated set.'),
  notes = paste('Sharpchin is the Tier 4 species within the GOA Other Rockfish',
    'complex, not a standalone age-structured assessment. The 2023 REMA survey',
    'series covers 1990-2023. The 2024 update carries forward the 7,008 t Tier 4',
    'biomass estimate; the final 2025 chapter reports catch through 2025-11-08 and',
    'rolls forward assessment values because no assessment was conducted. Stock',
    'SMART ID 10435 is the separate Pacific Coast entry. No canonical data were',
    'added; cached source provenance and checksums are in sources.csv.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][id_row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[id_row] == 'unreviewed' &&
  candidates$screening_status[id_row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('NOAA sharpchin candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][id_row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- id_row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(candidates[id_row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

stopifnot(!any(inputs$assessment_id == unit_id), !any(outputs$assessment_id == unit_id),
  !any(assessments$assessment_id == unit_id))
cat('Screened NOAA Gulf of Alaska sharpchin rockfish as an aggregate-index assessment.\n')
