root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_ling_1_2_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:lin.27.1-2'
unit_id <- 'ices_ling_ne_arctic_1_2'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected <- c(
  WGDEEP_2025_v3.pdf = '1714e5481706dce214091ff8298ed12c36a733e115d52f374143ddcc7ee9c382',
  ICES_Advice_lin_27_1_2_2025.pdf = '9abdc9a07f5e978e5e7bc68e454c3962b5d9b1b97618661f4c240e1cb6f21b15',
  ICES_advice_lin_27_1_2_2025_metadata.json = '27936ed91cffdf123c536c570b6d151f7329c677c0b35f5b97b1388642a8279c',
  ICES_standard_graphs_source_20918.html = '327f3f567aa80d9f4602147ea23271863cda3003543dc9d05c19177b1b03a983',
  ICES_SAG_20918.xml = 'b337840052ec976f5ff88769d20c1ecc9a9955cccf723a6b14d3adb4f56f8163'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The Northeast Arctic ling source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- normalizePath(file.path(cache, manifest$local_path[source_row]),
    winslash = '/', mustWork = FALSE)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached Northeast Arctic ling source differs from its manifest: ', file,
      call. = FALSE)
}

read_source <- function(file) {
  row <- match(file, manifest$file)
  paste(readLines(file.path(cache, manifest$local_path[row]), warn = FALSE),
    collapse = ' ')
}
is_pdf <- function(file) {
  path <- file.path(cache, manifest$local_path[match(file, manifest$file)])
  identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF')
}

advice_metadata <- read_source('ICES_advice_lin_27_1_2_2025_metadata.json')
source_data <- read_source('ICES_standard_graphs_source_20918.html')
stock_xml <- read_source('ICES_SAG_20918.xml')
source_checks <- c(
  wgdeep_pdf = is_pdf('WGDEEP_2025_v3.pdf'),
  advice_pdf = is_pdf('ICES_Advice_lin_27_1_2_2025.pdf'),
  advice = all(vapply(c('lin.27.1-2', '10.17895/ices.advice.27202677.v1',
    '2025-06-12', '2026; 2027'), grepl, logical(1L), x = advice_metadata,
    fixed = TRUE)),
  standard_graphs = all(vapply(c('lin.27.1-2', 'Assessment Year:',
    'Kilograms per 1000 hooks'), grepl, logical(1L),
    x = source_data, fixed = TRUE)),
  sag_xml = all(vapply(c('<AssessmentYear>2025</AssessmentYear>',
    '<StockCode>lin.27.1-2</StockCode>', '<StockCategory>3.21</StockCategory>',
    '<ModelType>None</ModelType>', '<ModelName>Other</ModelName>',
    '<StockSizeDescription>B_index</StockSizeDescription>',
    '<ConfidenceIntervalDefinition>95%</ConfidenceIntervalDefinition>',
    '<RecruitmentAge></RecruitmentAge>', '<Fage></Fage>',
    '<Flength></Flength>', '<SettingValue>Length-based Fishing Pressure Proxy</SettingValue>',
    '<SettingValue>CPUE (Kg /1000 hooks)</SettingValue>'),
    grepl, logical(1L), x = stock_xml, fixed = TRUE)),
  no_age_output = !grepl('<Age_Data>', stock_xml, fixed = TRUE)
)
if (!all(source_checks)) {
  print(source_checks)
  stop('The cached sources do not support the documented Northeast Arctic ling screen.',
    call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'lin.27.1-2' ||
    candidates$scientific_name[row] != 'Molva molva' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    candidates$assessment_area[row] != 'Arctic Ocean, Barents Sea, Norwegian Sea' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'lin.27.1-2', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The Northeast Arctic ling identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The reviewed 2025 ICES advice, Standard Graphs source, and SAG export provide aggregate landings in tonnes for 1988–2024. They do not provide an age-specific catch input. No catch-at-age series for this assessment run was verified in these sources.'),
  survey_age_evidence = paste('The current assessment output provides one aggregate biomass-index series identified as longline CPUE (kg per 1,000 hooks), with 95% intervals for 2000–2024. It is not age-disaggregated; no survey index-at-age series was verified in the reviewed sources.'),
  weights_evidence = 'No weights-at-age for the 2025 assessment were identified in the reviewed official assessment products.',
  maturity_evidence = 'No maturity-at-age input for the 2025 assessment was identified in the reviewed official assessment products.',
  mortality_evidence = paste('The 2025 SAG record identifies a length-based fishing-pressure proxy, not age-specific fishing mortality, and does not report an estimated M surface. No age-based mortality input was verified.'),
  timing_evidence = 'The published abundance index is aggregate longline CPUE; no separate age-specific survey series or model timing fraction was reported in the reviewed sources.',
  output_evidence = paste('The 2025 SAG export provides a B_index series for 2000–2024 with 95% intervals, landings for 1988–2024, and a length-based fishing-pressure proxy (ratio) for 2002–2024. Stock size is measured in kg per 1,000 hooks. Recruitment, SSB, and N-at-age/F-at-age/M-at-age surfaces are not reported in this assessment output.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.advice.27202677; ',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=20918; ',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=20918; ',
    'https://sag.ices.dk/SAG_API/StockXmlDownload/20918; ',
    'https://doi.org/10.17895/ices.pub.29086478.v3'),
  review_date = '2026-10-31',
  decision_reason = paste('This is a distinct new Northeast Arctic stock unit. The latest public advice is the 2025 ICES advice for 2026–2027; its linked 2025 SAG assessment is Category 3.21 with ModelType None and ModelName Other. The official output is aggregate longline CPUE, landings, and a length-based fishing-pressure proxy, without age-specific assessment outputs. It is ineligible for the age-disaggregated assessment set, while remaining in the discovery register. This decision describes the reviewed assessment products; it does not claim that age samples are absent from all national source systems.'),
  notes = paste('The ICES advice was posted 2025-06-12. The 2025 SAG source describes stock size as B_index and the unit as kilograms per 1,000 hooks; do not interpret this series as SSB. The current outputs do not provide a comparable age-structured population trajectory for tinyAM. No canonical stock, assessment, input, or output records were added. Source files, revisions, retrieval dates, sizes, and SHA-256 hashes are in the gitignored local cache at source_cache/discovery_ices_ling_1_2_2025.')
)

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('The Northeast Arctic ling candidate already has a conflicting review.',
    call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES Northeast Arctic ling as a new, ineligible candidate for age-disaggregated assessment.\n')
