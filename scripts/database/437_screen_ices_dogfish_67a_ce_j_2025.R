root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_dogfish_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:syc.27.67a-ce-j'
unit_id <- 'ices_lesser_spotted_dogfish_67a_ce_j'
files <- c('wgef_2025.pdf', 'ICES_SAG_source_data_2025_syc_27_67a_ce_j.html')
urls <- c(
  'https://literatur.thuenen.de/digbib_extern/dn070539.pdf',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21039')
revisions <- c(
  paste('ICES. 2025. Working Group on Elasmobranch Fishes (WGEF), ICES Scientific Reports 7(92),',
    '934 pp.; DOI 10.17895/ices.pub.30137623. Stock section 15.9.5 (printed pp. 291-294), section 21 (printed pp. 596-647), section 22 (printed pp. 648-669), section 23 (printed pp. 670-674), section 25.6.1 (printed pp. 697-698), section 25.9.2 (printed pp. 705-709), section 25.9.3 (printed pp. 710-713), and section 25.9.5 (printed pp. 716-722).'),
  'ICES Standard Graphs source data, assessment year 2025, stock assessment key 21039; B_index and Fproxy fields; age-specific F field blank.')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)))
  stop('Cache the reviewed 2025 WGEF report and ICES source-data page before screening ',
    candidate_id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, sources$file)
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    any(sources$retrieved_on[source_rows] != '2026-10-30') ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(toupper(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(rawToChar(readBin(paths[1L], 'raw', n = 4L)), '%PDF'))
  stop('Cached WGEF sources differ from their provenance manifest.', call. = FALSE)

source_data <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('syc.27.67a-ce-j', source_data, fixed = TRUE) ||
    !grepl('<span id="lblYear">2025</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblKey">21039</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblStockSizeDescription">B_index</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblStockSizeUnits">kilogram per square kilometer</span>', source_data, fixed = TRUE) ||
    !grepl('<span id="lblFishingPressureDescription">Fproxy</span>', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE))
  stop('Cached ICES source data do not match the reviewed 2025 aggregate-index record.',
    call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row] != 'syc.27.67a-ce-j' ||
    register$scientific_name[row] != 'Scyliorhinus canicula' ||
    any(tolower(stocks$authority_stock_id) == 'syc.27.67a-ce-j', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('Celtic Seas dogfish identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2025 WGEF report lists landings and commercial length-frequency data',
    'for landings and discards; it does not describe catch numbers-at-age or an age-composition likelihood.'),
  survey_age_evidence = paste('Four trawl-survey indices are normalized and combined into one annual relative',
    'biomass index (2005-2024); the production assessment does not use age-specific survey observations.'),
  weights_evidence = paste('The 2025 length-based rule uses Lc 42 cm, Lmean 55.4 cm, Linf 87.4 cm and k = 0.118;',
    'the reviewed assessment does not report age-specific weights.'),
  maturity_evidence = 'The reviewed assessment does not report maturity-at-age inputs.',
  mortality_evidence = paste('Fishing pressure is represented by the length-based LF=M proxy; no age-specific',
    'natural-mortality process is reported.'),
  timing_evidence = paste('The combined index uses EVHOE-WIBTS-Q4, IE-IGFS-WIBTS-Q4, SP-PORC-WIBTS-Q3,',
    'and UK(E&W)-BTS-Q3; it is an aggregate seasonal survey index, not an age-structured observation.'),
  output_evidence = paste('ICES reports B_index in kg/km2 and Fproxy as a ratio, plus the RFB calculation and',
    '2026-2027 landings advice. The report and Standard Graphs page do not provide N-at-age, F-at-age, M-at-age, SSB, or recruitment estimates.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.30137623;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21039'),
  review_date = '2026-10-30',
  decision_reason = paste('The latest assessment located is the 2025 ICES category 3 assessment using the rfb rule.',
    'Its production inputs are landings, catch length-frequency distributions and aggregate survey biomass indices; it reports length-based fishing-pressure metrics and stock-level advice, not age-disaggregated population inputs or outputs. The unit is therefore ineligible for the age-disaggregated set. This does not establish that age samples are absent from biological monitoring.'),
  notes = paste('ICES Standard Graphs assessment key 21039 identifies the stock-size measure as B_index in',
    'kg/km2 and pressure as Fproxy; the age-specific F field is blank. The 2025 WGEF report gives a 5194 t RFB calculation and 4781 t advice for 2026-2027. This is a distinct new ICES assessment unit with no exact canonical stock match. The report PDF and source-data page are cached under source_cache/discovery_ices_dogfish_2025/ with retrieval dates and checksums in sources.csv. No canonical data or tinyAM translation were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('Celtic Seas dogfish candidate already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES lesser spotted dogfish in Celtic Seas as ineligible for age-disaggregated inputs and outputs.\n')
