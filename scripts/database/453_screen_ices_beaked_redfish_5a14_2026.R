root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_beaked_redfish_5a14_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:reb.27.5a14'
unit_id <- 'ices_beaked_redfish_icelandic_slope'

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
  ICES_advice_record_7218.html = '719ba2c32febf83184caca5e523a42bf284603ece90ce4fe69ffdd8d3c3e6d7f',
  ICES_SAG_reb_27_5a14_2026.xml = 'e14fa9dd76adaee2ec7047ad1677e618e357dc02d411dfcef4a779ffa4b220b1',
  ICES_standard_graphs_reb_27_5a14_2026.html = 'd48bdececa896cdcf77a6d55aa9afecac8987a41dba528a890bf6678fd203957',
  MFRI_2026_beaked_redfish_techreport.html = 'fc3928c22bcfb1600e8e674f9b5f38f9e415e6d64e7e626824c8925ab936fb1e'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The beaked-redfish source manifest is incomplete.', call. = FALSE)

for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached beaked-redfish source differs from its manifest: ', file,
      call. = FALSE)
}

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
report <- read_source('MFRI_2026_beaked_redfish_techreport.txt')
advice <- read_source('ICES_advice_record_7218.html')
source_data <- read_source('ICES_standard_graphs_reb_27_5a14_2026.html')
stock_xml <- read_source('ICES_SAG_reb_27_5a14_2026.xml')

report_evidence <- c(
  'age- and length-based assessment model (Gadget)',
  'Length-disaggregated survey indices from the autumn survey',
  'Length distributions from the Icelandic commercial bottom trawl fleet',
  'Landings by 6-month periods from Iceland',
  'Age–length distributions from the autumn survey',
  'Comparison of commercial sample age-length distribution',
  'Natural mortality',
  '0.05 for all ages',
  'Length–weight relationship parameters',
  'A logistic, length-based maturity ogive',
  'Annual outputs from the final model are shown in Figure',
  'recruitment',
  'limited age data are available'
)
source_checks <- c(
  report = all(vapply(report_evidence, grepl, logical(1L), x = report, fixed = TRUE)),
  advice = all(vapply(c('reb.27.5a14', 'Assessment Year', '2026',
    'Stock Category', 'zero catch'), grepl, logical(1L), x = advice, fixed = TRUE)),
  standard_graphs = all(vapply(c('reb.27.5a14', 'Assessment Year', '2026',
    'Stock size description', 'SSB'), grepl, logical(1L), x = source_data, fixed = TRUE)),
  sag_xml = all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
    '<StockCode>reb.27.5a14</StockCode>', '<StockCategory>1</StockCategory>'),
    grepl, logical(1L), x = stock_xml, fixed = TRUE))
)
if (!all(source_checks)) {
  print(source_checks)
  print(report_evidence[!vapply(report_evidence, grepl, logical(1L),
    x = report, fixed = TRUE)])
  stop('The cached sources do not support the documented beaked-redfish screen.',
    call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'reb.27.5a14' ||
    candidates$scientific_name[row] != 'Sebastes mentella' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'reb.27.5a14', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The beaked-redfish identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  assessment_area = 'Icelandic slope; ICES Subarea 14 and Division 5.a (East of Greenland and Iceland grounds)',
  catch_age_evidence = paste('The 2026 Gadget assessment uses six-month landings, commercial length distributions, and commercial age-length composition, but no catch numbers-at-age table was identified. The report shows commercial age-length fit plots rather than complete numerical annual age-length inputs and expansion information. A defensible catch-at-age reconstruction is therefore not yet verified.'),
  survey_age_evidence = paste('The autumn survey input is a length-disaggregated abundance index; the assessment also uses autumn-survey age-length compositions. The report shows selected age-composition fits but no complete numeric annual age-specific index or age-length input matrix. The length index cannot be relabelled as an age-specific abundance index.'),
  weights_evidence = paste('The model fixes a length-weight relationship based on autumn-survey biological data. A complete numeric weight-at-age series is not reported; recovering one would require the numeric growth and age-length inputs.'),
  maturity_evidence = paste('Maturity is represented by an estimated length-based ogive from autumn-survey data. A numeric age-specific maturity schedule was not identified in the reviewed current sources.'),
  mortality_evidence = 'Natural mortality is fixed at 0.05 for all ages.',
  timing_evidence = paste('The model uses two six-month time steps and an autumn survey. The exact survey timing fraction used by the model was not identified in the reviewed public sources.'),
  output_evidence = paste('The 2026 MFRI report presents SSB, age-3 recruitment, and fishing-mortality trends with 95% intervals, and forecast tables; ICES publishes annual assessment-graph data. A complete numeric N-at-age or F-at-age output series was not identified.'),
  detailed_source_url = paste('https://www.hafogvatn.is/static/extras/images/61_drf_2026_1_techreport_en.html; ',
    'https://asd.ices.dk/viewAdvice/7218; ',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22659; ',
    'https://sg.ices.dk/SAG_API/StockXmlDownload/22659; ',
    'https://data.hafro.is/assmt/readme.html'),
  review_date = '2026-10-31',
  decision_reason = paste('The 2026 Icelandic slope unit is a distinct active Category 1 Gadget assessment. Its official report confirms age-length observations, but the reviewed current public materials do not provide the numerical annual age-length observations and supporting expansion data needed to verify catch-at-age or age-specific abundance inputs. Weight-at-age and exact survey timing are also unresolved. Keep eligibility unresolved as a source gap; do not call it ineligible based only on the Gadget model label.'),
  notes = paste('This ICES unit is distinct from the existing Sebastes mentella record for Subareas 1 and 2 (reb.27.1-2). Current source review covered the 2026 MFRI technical report, ICES advice record 7218, Standard Graphs and SAG records for assessment key 22659, and the Hafro assessment-data catalogue. The 2026 report includes model-fit figures and annual output trends but not a complete numeric model-ready age input set. Cached source files and checksums are under source_cache/discovery_ices_beaked_redfish_5a14_2026. No canonical records were added.')
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
  stop('The ICES beaked-redfish candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE],
    candidate_id)
}

cat('Screened ICES Icelandic slope beaked redfish as a new unit with age-input eligibility unresolved.\n')
