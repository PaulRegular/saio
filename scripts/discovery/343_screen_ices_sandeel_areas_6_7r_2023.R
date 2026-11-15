root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
shared_report <- file.path(root, 'source_cache', 'ices_sandeel_area_1r_2026', 'HAWG_2026.pdf')

cases <- data.frame(
  candidate_id = c('ICES:san.sa.6', 'ICES:san.sa.7r'),
  candidate_unit_id = c('ices_sandeel_area_6', 'ices_sandeel_area_7r'),
  stock_name = c(
    'Sandeel (Ammodytes spp.) in subdivisions 20-22, Sandeel Area 6 (Kattegat)',
    'Sandeel (Ammodytes spp.) in Division 4.a, Sandeel Area 7r (northern North Sea, Shetland)'),
  advice_key = c(3112L, 3113L),
  assessment_key = c(17719L, 17717L),
  category = c('5.2', '5.3'),
  catch_2022 = c('42', '0'),
  advice_summary = c(
    'catches should be no more than 140 tonnes in each of the years 2023 and 2024',
    'there should be zero catches in each of the years 2023 and 2024'),
  stringsAsFactors = FALSE
)

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

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(file.exists(shared_report),
  identical(readBin(shared_report, 'raw', n = 4L), charToRaw('%PDF')))

reports <- list()
for (i in seq_len(nrow(cases))) {
  case <- cases[i, ]
  area <- if (case$candidate_id == 'ICES:san.sa.6') '6' else '7r'
  cache <- file.path(root, 'source_cache', paste0('discovery_ices_sandeel_area_', area, '_2023'))
  advice_file <- paste0('ICES_Advice_', case$advice_key, '.html')
  sag_file <- paste0('SAG_', case$assessment_key, '.html')
  paths <- c(
    file.path(cache, advice_file),
    file.path(cache, sag_file),
    shared_report
  )
  if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
    stop('Cache the reviewed ICES sources before screening ', case$candidate_id, '.', call. = FALSE)

  sources <- data.frame(
    file = c(advice_file, sag_file, '../ices_sandeel_area_1r_2026/HAWG_2026.pdf'),
    url = c(
      paste0('https://asd.ices.dk/viewAdvice/', case$advice_key),
      paste0('https://sg.ices.dk/ViewSourceData.aspx?key=', case$assessment_key),
      'https://doi.org/10.17895/ices.pub.31424315'),
    retrieval_date = c('2026-10-30', '2026-10-30', ''),
    verified_date = c('2026-10-30', '2026-10-30', '2026-10-24'),
    revision = c(
      paste('ICES advice record', case$advice_key, 'assessment year 2023'),
      paste('ICES Stock Assessment Graphs key', case$assessment_key,
        'assessment year 2023'),
      'ICES HAWG 2026 report, shared cached file; original retrieval date not recorded'),
    sha256 = unname(vapply(paths, sha256_file, character(1L))),
    stringsAsFactors = FALSE
  )
  manifest_path <- file.path(cache, 'sources.csv')
  if (file.exists(manifest_path)) {
    previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
    rows <- match(previous$file, sources$file)
    if (anyNA(rows) || !identical(previous$url, sources$url[rows]) ||
        !identical(previous$revision, sources$revision[rows]) ||
        !identical(tolower(previous$sha256), sources$sha256[rows]))
      stop('Cached source files differ from the reviewed files for ', case$candidate_id, '.',
        call. = FALSE)
  }
  write.csv(sources, manifest_path, row.names = FALSE, na = '')

  advice <- paste(readLines(paths[1L], warn = FALSE), collapse = '\n')
  sag <- paste(readLines(paths[2L], warn = FALSE), collapse = '\n')
  sag_flat <- gsub('[[:space:]]+', ' ', sag)
  stock_code <- sub('^ICES:', '', case$candidate_id)
  if (!all(vapply(c(stock_code, '2023', case$category, case$advice_summary),
      grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
      !all(vapply(c(stock_code, as.character(case$assessment_key), '2023',
          'Catches', '2022'), grepl, logical(1L), x = sag, ignore.case = TRUE)) ||
      !grepl(paste0('>2022</td><td[^>]*>', case$catch_2022, '</td>'), sag_flat,
        ignore.case = TRUE, perl = TRUE))
    stop('Cached ICES advice or graph data do not match the reviewed assessment for ',
      case$candidate_id, '.', call. = FALSE)

  row <- match(case$candidate_id, candidates$candidate_id)
  unit_id <- case$candidate_unit_id
  if (is.na(row) || sum(candidates$candidate_id == case$candidate_id) != 1L ||
      candidates$official_stock_id[row] != sub('^ICES:', '', case$candidate_id) ||
      candidates$scientific_name[row] != 'Ammodytes' ||
      candidates$inventory_assessment_year[row] != 2025L ||
      (!is.na(candidates$candidate_unit_id[row]) &&
        candidates$candidate_unit_id[row] != unit_id) ||
      any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
      any(stocks$authority_stock_id == sub('^ICES:', '', case$candidate_id), na.rm = TRUE) ||
      any(stocks$stock_id == unit_id))
    stop('ICES sandeel identity conflicts with the candidate register or canonical database: ',
      case$candidate_id, '.', call. = FALSE)

  advice_detail <- if (case$candidate_id == 'ICES:san.sa.6')
    'The 2023 advice permits catches up to 140 tonnes in each of 2023 and 2024.' else
    'The 2023 advice recommends zero catches in 2023 and 2024.'
  reports[[i]] <- list(
    row = row,
    candidate_unit_id = unit_id,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2026 HAWG report lists the area-specific Category', case$category,
      'analysis as last updated in 2019. It describes the 2023-2024 advice method as ICES',
      'Category 5, which uses catch data only; no catch-at-age or age-composition series is',
      'reported. The 2023 stock-graph record contains a 2022 catch entry only, in tonnes.'),
    survey_age_evidence = paste(
      'No survey index or age-specific survey information is reported for this Category 5',
      'advice method; no survey likelihood is documented.'),
    weights_evidence = paste(
      'No weight-at-age input for the production advice was located; the catch-only method',
      'does not report age-specific biological inputs.'),
    maturity_evidence = paste(
      'No maturity-at-age input for the production advice was located; the catch-only method',
      'does not report age-specific biological inputs.'),
    mortality_evidence = paste(
      'No age-specific natural-mortality input or fitted M surface is reported for the',
      'Category 5 catch-only advice method.'),
    timing_evidence = paste(
      'No survey timing is applicable to the catch-only advice record because no survey',
      'likelihood is reported.'),
    output_evidence = paste(
      advice_detail,
      'The 2023 stock-graph record provides 2022 catch only; no comparable SSB, recruitment,',
      'N-at-age or F-at-age population outputs were located.'),
    detailed_source_url = paste(
      'https://doi.org/10.17895/ices.pub.31424315;',
      paste0('https://asd.ices.dk/viewAdvice/', case$advice_key), ';',
      paste0('https://sg.ices.dk/ViewSourceData.aspx?key=', case$assessment_key)),
    review_date = '2026-10-30',
    decision_reason = paste(
      'Screened ineligible for the age-disaggregated assessment set. The latest ICES advice',
      'record located is from 2023, with advice for 2023-2024. The 2026 HAWG report lists',
      'the area-specific Category', case$category,
      'analysis as last updated in 2019 and describes the method as catch-only. No',
      'age-specific inputs or comparable population outputs were located. No canonical',
      'assessment or numerical data were added.'),
    notes = paste(
      case$stock_name,
      'The 2023 stock-graph catch entry is', case$catch_2022,
      'tonnes for 2022. The HAWG 2026 PDF was reused from the shared ICES sandeel source',
      'cache; its original retrieval date was not recorded and it was verified on 2026-10-24.',
      'The advice and stock-graph pages were retrieved on 2026-10-30.')
  )
}

for (i in seq_along(reports)) {
  for (column in names(reports[[i]])) {
    if (column != 'row') candidates[[column]][reports[[i]]$row] <- reports[[i]][[column]]
  }
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  for (i in rev(seq_along(reports))) {
    row <- reports[[i]]$row
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', cases$candidate_id[i], '.', call. = FALSE)
    first <- line_feeds[physical_line - 1L] + 1L
    last <- line_feeds[physical_line]
    ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
      as.raw(c(13L, 10L)) else as.raw(10L)
    tmp <- tempfile(fileext = '.csv')
    write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
      col.names = FALSE, quote = TRUE, na = '')
    replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
    unlink(tmp)
    replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
    before <- bytes[seq_len(first - 1L)]
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    bytes <- c(before, charToRaw(replacement), ending, after)
    line_feeds <- which(bytes == as.raw(10L))
  }
  writeBin(bytes, candidate_path)
}

cat('Screened ICES sandeel Areas 6 and 7r as catch-only Category 5 advice; both are ineligible for age-disaggregated assessment coverage.\n')
