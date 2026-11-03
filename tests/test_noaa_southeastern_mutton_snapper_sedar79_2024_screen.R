root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/450_screen_noaa_southeastern_mutton_snapper_sedar79_2024.R'),
  local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv('TAM_SOURCE_DRY_RUN', old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:11342', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_noaa_mutton_snapper_sedar79_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_southeastern_mutton_snapper_sedar79_2024.md'), warn = FALSE),
  collapse = '\n')

expected <- c(
  SEDAR79_DW03_size_age.pdf = '843b200db484723946866325018e92ccee13ec31c2c06764bba1153d1d4502ec',
  SEDAR79_DW12_reproduction.pdf = '7cd48111d84c977c23b809a493c1d5982ef440f6d8380a0d18e0e00143abc6e7',
  SEDAR79_DW22_age_growth_mortality.pdf = '6067337943b4d3a747b3d2917c5cbff61a8157120ba950dc207edba9d21d5fa2',
  SEDAR79_final_SAR.pdf = 'a7587c458500b203a7140d5bfdab8524d3017f2a8951d3442130db8b081ee357',
  SEDAR79_project_page.html = 'e8e4a923fc6cb75cb143bff00c965d5a8a65eb4346515b89af3bb2fc1d22628e',
  SEDAR79_SSC_review.pdf = 'b592fc1d9d6460e5f84d92bf15e98c4cb7e2006b1f618778c1f85127629b00e2'
)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_southeastern_us_mutton_snapper', , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == '11342',
  candidate$scientific_name == 'Lutjanus analis',
  candidate$candidate_unit_id == 'noaa_southeastern_us_mutton_snapper',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  candidate$inventory_assessment_year == 2024,
  grepl('single stock', candidate$assessment_area, fixed = TRUE),
  grepl('conditional age-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('digitizing the figures', candidate$catch_age_evidence, fixed = TRUE),
  grepl('six fishery-independent indices', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.129', candidate$mortality_evidence, fixed = TRUE),
  grepl('A50 = 3.48', candidate$maturity_evidence, fixed = TRUE),
  grepl('Table 16', candidate$output_evidence, fixed = TRUE),
  grepl('age-3 F', candidate$output_evidence, fixed = TRUE),
  grepl('March 2025', candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == length(expected),
  !anyDuplicated(manifest$file),
  setequal(manifest$file, names(expected)),
  all(manifest$retrieved_on == '2026-10-31'),
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(tolower(manifest$sha256[match(names(expected), manifest$file)]) == unname(expected)),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$screening_status == 'screened',
  unit$eligibility == 'eligible',
  grepl('age-at-length', review, fixed = TRUE),
  grepl('observation inputs are not', review, fixed = TRUE),
  grepl('marginal catch-at-age', review, fixed = TRUE),
  grepl('Table 16', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == '11342', na.rm = TRUE),
  !any(stocks$stock_id == 'noaa_southeastern_us_mutton_snapper'),
  !any(assessments$stock_id == 'noaa_southeastern_us_mutton_snapper'),
  !any(inputs$assessment_id == 'noaa_southeastern_us_mutton_snapper'),
  !any(outputs$assessment_id == 'noaa_southeastern_us_mutton_snapper')
)

cat('NOAA SEDAR 79 Mutton Snapper identity, source screen, provenance, and discovery-only checks passed.\n')
