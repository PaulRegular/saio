root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/451_screen_ices_thornback_ray_6_2026.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv('TAM_SOURCE_DRY_RUN', old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'ICES:rjc.27.6', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_thornback_ray_6_2026')
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
  'discovery/source_reviews/ices_thornback_ray_6_2026.md'), warn = FALSE), collapse = '\n')

expected <- c(
  ICES_advice_2026_rjc_27_6.pdf = 'dbbc5833c3a48cc912a485c0bb930973c838c52dfd93bfdff569f5715bb5d8d5',
  ICES_advice_record_7193.html = 'f1edf4a2e5512bec088afdf37b886d11f30a6c27f2320b8825224dbf870bdec3',
  ICES_standard_graphs_rjc_27_6_2026.html = 'af852f82c64b2c1a785bd24bc859c5364f4fab31db4391925634f4d76feab57a',
  ICES_SAG_rjc_27_6_2026.xml = 'c99ad96ee99c911a9a9c9cbb9e237e33edf712a4a7907f2d9320a3d11f6cd2dc'
)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'ices_thornback_ray_6', , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'rjc.27.6',
  candidate$scientific_name == 'Raja clavata',
  candidate$candidate_unit_id == 'ices_thornback_ray_6',
  candidate$assessment_area == 'Subarea 6 (West of Scotland)',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  candidate$inventory_assessment_year == 2026L,
  grepl('Category 3', candidate$catch_age_evidence, fixed = TRUE),
  grepl('B_index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('51 tonnes', candidate$output_evidence, fixed = TRUE),
  grepl('cannot be quantified', candidate$catch_age_evidence, fixed = TRUE),
  nrow(manifest) == length(expected),
  !anyDuplicated(manifest$file),
  setequal(manifest$file, names(expected)),
  all(manifest$retrieved_on == '2026-10-31'),
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  tolower(manifest$sha256[match(names(expected), manifest$file)]) == unname(expected),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$screening_status == 'screened',
  unit$eligibility == 'ineligible',
  grepl('must not be relabelled as SSB', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'rjc.27.6', na.rm = TRUE),
  !any(stocks$stock_id == 'ices_thornback_ray_6'),
  !any(assessments$stock_id == 'ices_thornback_ray_6'),
  !any(inputs$assessment_id == 'ices_thornback_ray_6'),
  !any(outputs$assessment_id == 'ices_thornback_ray_6')
)

cat('ICES 2026 Subarea 6 thornback ray identity, source screen, provenance, and no-import checks passed.\n')
