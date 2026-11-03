root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database',
  '453_screen_ices_beaked_redfish_5a14_2026.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN, old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:reb.27.5a14', , drop = FALSE]
review <- screen$review
cache <- file.path(root, 'source_cache/discovery_ices_beaked_redfish_5a14_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'ices_beaked_redfish_icelandic_slope', , drop = FALSE]
source_review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_beaked_redfish_icelandic_slope_2026.md'),
  warn = FALSE), collapse = '\n')

expected <- c(
  ICES_advice_record_7218.html = '719ba2c32febf83184caca5e523a42bf284603ece90ce4fe69ffdd8d3c3e6d7f',
  ICES_SAG_reb_27_5a14_2026.xml = 'e14fa9dd76adaee2ec7047ad1677e618e357dc02d411dfcef4a779ffa4b220b1',
  ICES_standard_graphs_reb_27_5a14_2026.html = 'd48bdececa896cdcf77a6d55aa9afecac8987a41dba528a890bf6678fd203957',
  MFRI_2026_beaked_redfish_techreport.html = 'fc3928c22bcfb1600e8e674f9b5f38f9e415e6d64e7e626824c8925ab936fb1e'
)

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'reb.27.5a14',
  candidate$scientific_name == 'Sebastes mentella',
  candidate$inventory_assessment_year == 2026L,
  candidate$candidate_unit_id == 'ices_beaked_redfish_icelandic_slope',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('no catch numbers-at-age table', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-length compositions', candidate$survey_age_evidence, fixed = TRUE),
  grepl('not reported', candidate$weights_evidence, fixed = TRUE),
  grepl('0.05', candidate$mortality_evidence, fixed = TRUE),
  grepl('exact survey timing fraction', candidate$timing_evidence, fixed = TRUE),
  grepl('95% intervals', candidate$output_evidence, fixed = TRUE),
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
  unit$eligibility == 'unresolved',
  grepl('Eligibility remains **unresolved**', source_review, fixed = TRUE),
  grepl('complete numeric input set', source_review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'reb.27.5a14', na.rm = TRUE),
  any(tolower(stocks$authority_stock_id) == 'reb.27.1-2', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_beaked_redfish_icelandic_slope'),
  !any(inputs$assessment_id == 'ices_beaked_redfish_icelandic_slope'),
  !any(outputs$assessment_id == 'ices_beaked_redfish_icelandic_slope')
)

cat('ICES 2026 Icelandic slope beaked-redfish identity, input gap, provenance, and no-import checks passed.\n')
