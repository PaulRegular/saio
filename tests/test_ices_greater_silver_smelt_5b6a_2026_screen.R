root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/452_screen_ices_greater_silver_smelt_5b6a_2026.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN, old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:aru.27.5b6a', , drop = FALSE]
review <- screen$review
cache <- file.path(root, 'source_cache/discovery_ices_gss_5b6a_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'ices_greater_silver_smelt_5b6a', , drop = FALSE]
source_review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_greater_silver_smelt_5b6a_2026.md'),
  warn = FALSE), collapse = '\n')

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

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'aru.27.5b6a',
  candidate$scientific_name == 'Argentina silus',
  candidate$inventory_assessment_year == 2026L,
  candidate$candidate_unit_id == 'ices_greater_silver_smelt_5b6a',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  review$candidate_unit_id == 'ices_greater_silver_smelt_5b6a',
  review$match_status == 'new',
  review$screening_status == 'screened',
  review$eligibility == 'eligible',
  review$import_status == 'not_started',
  review$assessment_area == 'Divisions 5.b and 6.a (Faroes grounds and west of Scotland)',
  grepl('1995–2025', review$catch_age_evidence, fixed = TRUE),
  grepl('ages 5–21+', review$catch_age_evidence, fixed = TRUE),
  grepl('ages 10–21+ therefore require documented plot digitization',
    review$weights_evidence, fixed = TRUE),
  grepl('small age sample', review$weights_evidence, fixed = TRUE),
  grepl('1998–2025', review$survey_age_evidence, fixed = TRUE),
  grepl('2014–2025 except 2021', review$survey_age_evidence, fixed = TRUE),
  grepl('fixed maturity', review$maturity_evidence, fixed = TRUE),
  grepl('0.15', review$mortality_evidence, fixed = TRUE),
  grepl('exact timing fractions remain unresolved', review$timing_evidence, fixed = TRUE),
  grepl('95% intervals', review$output_evidence, fixed = TRUE),
  nrow(manifest) == length(expected),
  !anyDuplicated(manifest$file),
  setequal(manifest$file, names(expected)),
  all(manifest$retrieved_on == '2026-10-31'),
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  identical(tolower(manifest$sha256[match(names(expected), manifest$file)]),
    unname(expected)),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$match_status == 'new',
  unit$screening_status == 'screened',
  unit$eligibility == 'eligible',
  grepl('timing fractions', source_review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'aru.27.5b6a', na.rm = TRUE),
  !any(stocks$stock_id == 'ices_greater_silver_smelt_5b6a'),
  !any(assessments$stock_id == 'ices_greater_silver_smelt_5b6a'),
  !any(inputs$assessment_id == 'ices_greater_silver_smelt_5b6a'),
  !any(outputs$assessment_id == 'ices_greater_silver_smelt_5b6a')
)

cat('ICES 2026 greater silver smelt identity, source screen, provenance, and no-import checks passed.\n')
