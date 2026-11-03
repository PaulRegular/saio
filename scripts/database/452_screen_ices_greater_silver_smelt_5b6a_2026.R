root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_gss_5b6a_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:aru.27.5b6a'
unit_id <- 'ices_greater_silver_smelt_5b6a'
taf_revision <- 'ices-advice/2026_aru.27.5b6a at commit 7b7436c9e90c66c18411b7bf53bdf3ff096e5b33'

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
  WGDEEP_2026_v1.pdf = '4dece836b45b56c03a34d2ddf7ee1dd88eda7cdf2ba8d6717f86949888da89cd',
  ICES_advice_record_7183.html = '474d69a9472d4168900956c606659cd3e3a326897baa377ed1cf6bb2389db5b3',
  ICES_standard_graphs_aru_27_5b6a_2026.html = '9f70683f6c0f513173fc18ae6e6d2dedc7e0dc4707ba89abc10c079224204ad9',
  ICES_SAG_aru_27_5b6a_2026.xml = '38a81d7344a801cc40f4308a333fd2122ef27a5992f1e1cea93e167f343f584b',
  ICES_SID_year_2026.json = 'c5d9816e40f393ed3664dcb92710b75a47e0dd4961eb29fe3524570ae2cd5efc',
  README.md = '65dd860cd815af18b5d010e2f346fa11e8c8e2ed94efd71dc54d3825a3d0c5e0',
  data.R = 'd4331f53f39ac1e4882c41cec9bc8ebce3e64e87caa5763d4e65c1ee676bc7f0',
  model.R = 'fe5246ad4866a1ad08f2c9b6c204931e9b31528241c959fe9675fc7af34cd606',
  output.R = '99c580eaae68749c2896f597e0126375c0ed0733146ff5d8d2065ee7cbf43aab',
  output_diagnostics.r = '4be19ac5368798c5b31c6330adacd139ee04f7730880d2c688873e4e4e9bf071',
  forecast.R = 'ccd26afcef9415747c3251f3f060232585d387b5281ef51546f3a88a387a7761',
  SAG.r = '485ce782b970352636d48d9c30dbfe77cfdf12261eef003ac6509b1e8d396506',
  boot__DATA.bib = '53fd5965c1fea16295a2cde46099fcdcf89125fbb61329f2b650814fd32e0539',
  boot__SOFTWARE.bib = 'e02764d06cd14ee68ca1f9a87c28c053fdd380bdd3caf32db9417c131dcb7c4e',
  TAF_repository_tree.json = '5cd54ae2a4435b6f9554658c07ee2a1aea93f6f4e38c4c6ee8157e7bbe81d061',
  'WGDEEP_2026_gss_pages_330-370.txt' = '2e3dd0d5973dcc9a6077c84a56662b0983bb7583a180ba3817ac7ddcc772c5bb'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The greater silver smelt source manifest is incomplete.', call. = FALSE)

for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached greater silver smelt source differs from its manifest: ', file,
      call. = FALSE)
}

taf_files <- c('README.md', 'data.R', 'model.R', 'output.R', 'output_diagnostics.r',
  'forecast.R', 'SAG.r', 'boot__DATA.bib', 'boot__SOFTWARE.bib',
  'TAF_repository_tree.json')
taf_rows <- match(taf_files, manifest$file)
if (anyNA(taf_rows) || any(manifest$revision[taf_rows] != taf_revision))
  stop('The TAF sources are not pinned to the reviewed repository revision.', call. = FALSE)

read_source <- function(file) gsub('[[:space:]]+', ' ',
  paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' '))
report <- read_source('WGDEEP_2026_gss_pages_330-370.txt')
advice <- read_source('ICES_advice_record_7183.html')
source_data <- read_source('ICES_standard_graphs_aru_27_5b6a_2026.html')
stock_xml <- read_source('ICES_SAG_aru_27_5b6a_2026.xml')
taf_data <- read_source('data.R')
taf_model <- read_source('model.R')
taf_output <- read_source('output.R')
taf_tree <- read_source('TAF_repository_tree.json')

report_evidence <- c(
  'Table 6.3.5. Greater silver smelt in 5.b and 6.a. Catch numbers at age (*1000) used in the assessment.',
  'Table 6.3.6. Greater silver smelt in 5.b and 6.a. Mean weight at age used in the assessment.',
  'Figure 6.3.8. Greater silver smelt 5.b and 6a. Mean weight -at-age of greater silver smelt in the commercial catch within 5.b and 6.a.',
  'Table 6.3.7. Greater silver smelt 5.b and 6a. Maturity proportion by age used in the assessment',
  'Table 6.3.8. Greater silver smelt in 5.b and 6.a. Faroese summer survey input',
  'Table 6.3.9. Greater silver smelt in 5.b and 6.a. Faroese Deepwater survey input',
  'Table 6.3.10. Greater silver smelt in 5.b and 6.a. Standardised biomass index',
  'Table 6.3.14. Greater silver smelt in 5.b and 6.a. Estimated fishing mortality at age.',
  'Table 6.4.13. Greater silver smelt in 5.b and 6.a. Assessment summary.',
  'Catch at age data from 1995 to 2004 is derived from Faroese sampling raised to international catches.',
  'natural mortality is set to 0.15 for all ages and years',
  'Faroese deep-water trawl survey has been conducted in September'
)
taf_evidence <- c(
  'ARG@catch.n[] <- t(catage)',
  'ARG@stock.wt[] <- t(wstock)',
  'ARG@mat[] <- t(maturity)',
  'ARG@m[] <- t(natmort)',
  'range(ARG.tun[[i]])[c(\"startf\",\"endf\")] <- attr(surveys[[i]],\"time\")',
  'ARG.ctrl@cor.obs.Flag[2:3]',
  'write.taf(flr2taf(ARG.sam@stock.n), \"output/natage.csv\")',
  'write.taf(flr2taf(ARG.sam@harvest), \"output/fatage.csv\")'
)
source_checks <- c(
  report = all(vapply(report_evidence, grepl, logical(1L), x = report, fixed = TRUE)),
  taf = all(vapply(taf_evidence, grepl, logical(1L),
    x = paste(taf_data, taf_model, taf_output), fixed = TRUE)),
  standard_graphs = all(vapply(c('aru.27.5b6a', 'Assessment Year', '2026', '23736'),
    grepl, logical(1L), x = source_data, fixed = TRUE)),
  sag_xml = all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
    '<StockCode>aru.27.5b6a</StockCode>', '<StockCategory>1</StockCategory>',
    '<Fage>6-14</Fage>', '<RecruitmentAge>5</RecruitmentAge>',
    '<ModelType>A</ModelType>', '<ModelName>SAM</ModelName>',
    '<StockSizeDescription>SSB</StockSizeDescription>'),
    grepl, logical(1L), x = stock_xml, fixed = TRUE)),
  advice = grepl('22 865 tonnes', advice, fixed = TRUE),
  repository_revision = grepl('7b7436c9e90c66c18411b7bf53bdf3ff096e5b33',
    taf_tree, fixed = TRUE)
)
if (!all(source_checks)) {
  print(source_checks)
  print(report_evidence[!vapply(report_evidence, grepl, logical(1L),
    x = report, fixed = TRUE)])
  stop('The cached ICES sources do not support the documented greater silver smelt screen.',
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
    candidates$official_stock_id[row] != 'aru.27.5b6a' ||
    candidates$scientific_name[row] != 'Argentina silus' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'aru.27.5b6a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('Greater silver smelt identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  assessment_area = 'Divisions 5.b and 6.a (Faroes grounds and west of Scotland)',
  catch_age_evidence = paste('The 2026 WGDEEP report Table 6.3.5 gives observed catch numbers-at-age in thousands for ages 5–21+ from 1995–2025. Catch-at-age for 1995–2004 is Faroese sampling raised to international catches; later years use InterCatch, with age data contributed by Faroes and the Netherlands. The report also notes ages 2–4 exist in InterCatch but are not used in this assessment.'),
  survey_age_evidence = paste('The assessment uses the Faroese summer survey age-index series for ages 5–12 (Table 6.3.8; 1998–2025 in the published table) and the Faroese deepwater survey for ages 5–14 (Table 6.3.9; 2014–2025 except 2021). Their published tables identify annual age-specific tuning inputs. Additional Scottish deepwater slope and combined Faroese–EU CPUE inputs are aggregate biomass indices, not age-specific indices.'),
  weights_evidence = paste('Table 6.3.6 reports annual catch weights-at-age for ages 5–9 through 2025. Figure 6.3.8 plots the annual weight-at-age series across the assessed ages 5–21+, in kg; values for ages 10–21+ therefore require documented plot digitization. The report says stock weights are assumed equal to catch weights. The report cautions that weights for fish older than 15 in 2019 may be unreliable because of a small age sample.'),
  maturity_evidence = paste('Table 6.3.7 reports the fixed maturity-at-age proportions for ages 5–21+ (0.13 at age 5, rising to 1.0 at age 13 and older). The report says this schedule is fixed for the assessment period.'),
  mortality_evidence = paste('Natural mortality is fixed at 0.15 for all ages and years; the public TAF preprocessing script reads the natural-mortality input.'),
  timing_evidence = paste('The report identifies the Faroese deepwater survey as a September survey and describes the Faroese groundfish series as a summer survey. The 2026 TAF code uses survey-specific startf/endf attributes, but the public report tables and pinned TAF repository do not expose the underlying survey.dat file or exact annual fractions. The seasonal descriptions support source curation, but exact timing fractions remain unresolved for a faithful.'),
  output_evidence = paste('The official 2026 report provides annual recruitment, SSB and F summaries with 95% intervals (Table 6.4.13; the report also references this table under a differing 6.3.13 number) and estimated F-at-age (Table 6.3.14). The pinned TAF output code writes N-at-age and F-at-age, but the public repository snapshot contains no fitted RData or generated output tables; annual N-at-age values are therefore not independently recoverable from that repository.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.32051352.v1; ',
    'https://asd.ices.dk/viewAdvice/7183; ',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23736; ',
    'https://sg.ices.dk/SAG_API/StockXmlDownload/23736; ',
    'https://github.com/ices-advice/2026_aru.27.5b6a/tree/7b7436c9e90c66c18411b7bf53bdf3ff096e5b33'),
  review_date = '2026-10-31',
  decision_reason = paste('The current ICES unit aru.27.5b6a is a distinct new unit with a 2026 Category 1 SAM assessment. The official report provides catch numbers-at-age, two age-specific survey tuning series, age-specific catch weights for ages 5–9 and a plot of weights for the remaining assessed ages, fixed maturity and M, and comparable SSB, recruitment and F outputs with uncertainty. It is eligible for source curation, with figure digitization needed for weights at ages 10–21+ and a small-sample caveat for older-fish weights. Exact annual survey timing fractions and the fitted model/data files remain unresolved and must be addressed before translation; no canonical numerical records are added by this screen.'),
  notes = paste('This is the greater silver smelt unit for ICES divisions 5.b and 6.a (Faroes grounds and west of Scotland), distinct from aru.27.5a14, aru.27.123a4 and aru.27.6b7-1012. The 2026 report states catch-at-age starts in 1995, ages 5–21+; catch weights are tabulated for ages 5–9 and plotted for the full assessed range, stock weights are assumed equal to catch weights, and M=0.15 is fixed. The age-specific summer and deepwater survey tables are published in the report, while exact time fractions and raw survey data are absent from the public TAF snapshot. All sources are cached with revision/date/checksum provenance under source_cache/discovery_ices_gss_5b6a_2026. No canonical stock, assessment, input, or output records were added.')
)

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
previous_weights_evidence <- paste('Table 6.3.6 reports annual catch weights-at-age for ages 5–9 through 2025; the assessment report states that stock weights are assumed equal to catch weights. The public TAF data script maps the stock-weight input to the model object.')
same_previous_screen <- candidates$candidate_unit_id[row] == unit_id &&
  candidates$match_status[row] == 'new' &&
  candidates$screening_status[row] == 'screened' &&
  candidates$eligibility[row] == 'eligible' &&
  identical(as.character(candidates$weights_evidence[row]), previous_weights_evidence)
if (!is_unreviewed && !same_review && !same_previous_screen)
  stop('Greater silver smelt candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') &&
    (is_unreviewed || same_previous_screen || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE],
    candidate_id)
}

cat('Screened ICES greater silver smelt in divisions 5.b and 6.a as eligible for source curation.\n')
