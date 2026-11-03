root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cases <- list(
  list(
    id = 'ICES:mon.27.78abd', unit = 'ices_white_anglerfish_78abd',
    year = 2026L, advice = '7176', key = '23756', fage = '3-15',
    stock_size = 'Combined-sex SSB',
    catch = paste('WGBIE 2026 section 3.2 reports landings and discards and catch',
      'numbers-at-length. About 50% of landings had associated length data; no',
      'catch-at-age or age-composition likelihood input is reported.'),
    survey = paste('The model uses the combined FR_IE_IBTS survey index, Irish IAMS',
      'and Spanish SpGFS-WIBTS-Q4 index, with survey length compositions. No',
      'age-specific abundance index or age-composition input is reported.'),
    weights = paste('Growth, length-weight and maturity inputs are fixed for females;',
      'male growth parameters are partly estimated. The run-specific assumptions',
      'are described in the Stock Annex; no weight-at-age series was recovered.'),
    maturity = paste('Maturity is fixed and documented in the Stock Annex; no',
      'age-specific maturity input series was recovered from the report.'),
    mortality = paste('Natural mortality is fixed, not estimated, and specified in',
      'the Stock Annex. No estimated M-at-age output is reported.'),
    timing = paste('The FR_IE_IBTS and Spanish SpGFS-WIBTS-Q4 indices are quarter-4',
      'surveys. IAMS occurs early in the year but is entered on 31 December of the',
      'previous year for the in-year assessment.'),
    output = paste('Stock Assessment Graphs reports age-0 recruitment (thousands),',
      'combined-sex SSB (tonnes) and F ages 3-15. It does not provide N-at-age,',
      'F-at-age or M-at-age surfaces.'),
    decision = paste('The latest 2026 Category 1 production assessment is a',
      'length-based age-structured Stock Synthesis 3 model. Its documented catch',
      'and survey composition observations are at length, and the public graph',
      'reports only aggregate biomass/recruitment and age-group F outputs. The',
      'unit is ineligible for the age-disaggregated candidate set; no canonical',
      'assessment or data rows were added.'),
    notes = paste('WGBIE 2026 section 3.2 uses data through 2025 and identifies',
      'fixed M, maturity, female growth and length-weight assumptions. The detailed',
      'WGBIE report is shared with the black-bellied anglerfish screen and cached',
      'under discovery_ices_black_bellied_anglerfish_78abd_2026.'),
    report = 'section 3.2'
  ),
  list(
    id = 'ICES:mon.27.8c9a', unit = 'ices_white_anglerfish_8c9a',
    year = 2026L, advice = '7177', key = '22608', fage = '2-15',
    stock_size = 'SSB',
    catch = paste('WGBIE 2026 section 4.2 reports quarterly landings by four fleets',
      'and length compositions at length. The 2026 production report explicitly',
      'states that no age information is available; catch-at-age is not used.'),
    survey = paste('The model uses an aggregate Spanish SpGFS-WIBTS-Q4 abundance',
      'index and two aggregate commercial CPUE indices, plus length compositions.',
      'Survey length compositions are not age-specific abundance inputs.'),
    weights = paste('Weight-at-length and sex-specific growth are used; the report',
      'does not provide an observed weight-at-age input. Female maturity is a',
      'length-based logistic curve.'),
    maturity = paste('The production model uses a length-based female maturity ogive',
      '(L50 58.11 cm, slope 0.388); no maturity-at-age observations are reported.'),
    mortality = paste('Natural mortality is fixed by sex and age: females 0.94 at',
      'age 0, 0.53 at age 1, 0.37 at age 2, 0.29 at age 3+; males use 0.30 at age',
      '3+. M is not estimated.'),
    timing = paste('The population model uses quarterly data. The abundance survey',
      'is the fourth-quarter Spanish SpGFS-WIBTS-Q4 series; commercial CPUE spans',
      '2009-2025 and 1996-2011. No age-specific survey timing applies.'),
    output = paste('Stock Assessment Graphs reports age-0 recruitment (thousands),',
      'SSB (the report defines it as female-only, tonnes) and F ages 2-15. No',
      'N-at-age or F-at-age annual surface is published.'),
    decision = paste('The latest 2026 Category 1 production assessment is an',
      'age-structured Stock Synthesis model fitted without age data: WGBIE explicitly',
      'states no age information is available and documents catch, CPUE/survey and',
      'composition observations at aggregate or length scales. Its public outputs',
      'are age-0 recruitment, female-only SSB and age-group F, not age-specific',
      'population surfaces. It is ineligible for the age-disaggregated set; no',
      'canonical assessment or data rows were added.'),
    notes = paste('The WGBIE 2026 report describes an update through 2025. The 2026',
      'Stock Assessment Graphs key is 22608. The detailed WGBIE report is shared',
      'with the black-bellied anglerfish screen and cached under',
      'discovery_ices_black_bellied_anglerfish_78abd_2026.'),
    report = 'section 4.2'
  )
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

for (case in cases) {
  suffix <- if (endsWith(case$id, '78abd')) '78abd' else '8c9a'
  cache <- file.path(root, 'source_cache',
    paste0('discovery_ices_white_anglerfish_', suffix, '_2026'))
  files <- c(paste0('ICES_Advice_', case$advice, '.html'),
    paste0('ICES_StockGraphs_', case$key, '.html'),
    paste0('ICES_SourceData_', case$key, '.html'),
    paste0('ICES_StockAssessment_', case$key, '.xml'))
  paths <- file.path(cache, files)
  urls <- c(paste0('https://asd.ices.dk/viewAdvice/', case$advice),
    paste0('https://standardgraphs.ices.dk/ViewCharts.aspx?key=', case$key),
    paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=', case$key),
    paste0('https://sag.ices.dk/SAG_API/StockXmlDownload/', case$key))
  revisions <- c(
    paste('ICES 2026 advice record', case$advice, 'for', sub('ICES:', '', case$id)),
    paste('ICES Stock Assessment Graphs, assessment year 2026, key', case$key),
    paste('ICES Stock Assessment Graphs source data, assessment year 2026, key', case$key),
    paste('ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key', case$key)
  )
  if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
    stop('Cache the reviewed ICES sources before screening ', case$id, '.', call. = FALSE)
  sources <- data.frame(
    file = files, url = urls, retrieval_date = '2026-10-30', revision = revisions,
    bytes = unname(file.info(paths)$size),
    sha256 = unname(vapply(paths, sha256_file, character(1L))),
    retrieved_utc = '2026-10-30', stringsAsFactors = FALSE
  )
  manifest_path <- file.path(cache, 'sources.csv')
  if (file.exists(manifest_path)) {
    previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
    rows <- match(sources$file, previous$file)
    if (anyNA(rows) || !identical(previous$url[rows], sources$url) ||
        !identical(previous$revision[rows], sources$revision) ||
        !identical(tolower(previous$sha256[rows]), sources$sha256))
      stop('Cached ICES files differ from the reviewed source manifest for ', case$id, '.',
        call. = FALSE)
  } else {
    write.csv(sources, manifest_path, row.names = FALSE, na = '')
  }

  advice <- paste(readLines(paths[1L], warn = FALSE), collapse = ' ')
  source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
  xml <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
  advice_terms <- if (case$id == 'ICES:mon.27.78abd')
    c(sub('ICES:', '', case$id), '2026', 'Stock Category', '36980 tonnes') else
    c(sub('ICES:', '', case$id), '2026', 'Stock Category', '2 841 tonnes',
      '4 619 tonnes')
  if (!all(vapply(advice_terms, grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
      !all(vapply(c(sub('ICES:', '', case$id), 'Assessment Year', 'Age and Length',
        'Unit recruitment'),
        grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
      !all(vapply(c('<ModelType>AL</ModelType>', '<ModelName>SS3</ModelName>',
        paste0('<StockSizeDescription>', case$stock_size, '</StockSizeDescription>'),
        '<RecruitmentAge>0</RecruitmentAge>', paste0('<Fage>', case$fage, '</Fage>')),
        grepl, logical(1L), x = xml, fixed = TRUE)))
    stop('Cached ICES advice or graph data do not match the reviewed assessment for ',
      case$id, '.', call. = FALSE)

  row <- match(case$id, candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == case$id) != 1L ||
      candidates$official_stock_id[row] != sub('ICES:', '', case$id) ||
      candidates$scientific_name[row] != 'Lophius piscatorius' ||
      candidates$inventory_assessment_year[row] != case$year ||
      any(stocks$authority_stock_id == sub('ICES:', '', case$id), na.rm = TRUE) ||
      any(stocks$stock_id == case$unit) ||
      any(candidates$candidate_unit_id[-row] == case$unit, na.rm = TRUE))
    stop('ICES white anglerfish identity conflicts with the candidate register or canonical database.',
      call. = FALSE)

  review <- list(
    candidate_unit_id = case$unit, match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = case$catch, survey_age_evidence = case$survey,
    weights_evidence = case$weights, maturity_evidence = case$maturity,
    mortality_evidence = case$mortality, timing_evidence = case$timing,
    output_evidence = case$output, detailed_source_url = paste(urls, collapse = '; '),
    review_date = '2026-10-30', decision_reason = case$decision, notes = case$notes
  )
  current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(review)
  same_review <- all(vapply(names(review), function(column) {
    identical(current[[column]], as.character(review[[column]]))
  }, logical(1L)))
  is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started'
  if (!is_unreviewed && !same_review)
    stop('ICES white anglerfish candidate already has a conflicting review: ', case$id,
      '.', call. = FALSE)
  for (column in names(review)) candidates[[column]][row] <- review[[column]]

  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
    line_feeds <- which(bytes == as.raw(10L))
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', case$id, '.', call. = FALSE)
    first <- line_feeds[physical_line - 1L] + 1L
    last <- line_feeds[physical_line]
    ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
      as.raw(c(13L, 10L)) else as.raw(10L)
    tmp <- tempfile(fileext = '.csv')
    write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
      col.names = FALSE, quote = TRUE, na = '')
    replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
    unlink(tmp)
    replacement <- sub('\r?\n$', '', rawToChar(replacement), perl = TRUE)
    before <- bytes[seq_len(first - 1L)]
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
  }
}

cat('Screened both 2026 ICES white anglerfish units as length-based assessments.\n')
