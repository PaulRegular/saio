root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
result <- source(file.path(root, 'scripts', 'database',
  '432_screen_ices_golden_redfish_561214_2026.R'), local = screen)$value
if (is.na(old_dry_run)) {
  Sys.unsetenv('TAM_SOURCE_DRY_RUN')
} else {
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)
}

candidate <- result$candidate
catch <- result$tables$catch
catch_weight <- result$tables$catch_weight
stock_weight <- result$tables$stock_weight
maturity <- result$tables$maturity
spring_index <- result$tables$spring_index
autumn_index <- result$tables$autumn_index
stock_numbers <- result$tables$stock_numbers
fishing_mortality <- result$tables$fishing_mortality
manifest <- result$manifest
cache <- file.path(root, 'source_cache', 'discovery_ices_golden_redfish_561214_2026')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_id == 'ICES:reg.27.561214',
  candidate$official_stock_id == 'reg.27.561214',
  candidate$scientific_name == 'Sebastes norvegicus',
  candidate$candidate_unit_id == 'ices_golden_redfish_561214',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  grepl('1995 onward', candidate$catch_age_evidence, fixed = TRUE),
  grepl('fixed at 0.05', candidate$mortality_evidence, fixed = TRUE),
  grepl('March', candidate$timing_evidence, fixed = TRUE),
  grepl('2010 and 2012 mean', candidate$survey_age_evidence, fixed = TRUE),
  grepl('numbers-at-age', candidate$output_evidence, fixed = TRUE),
  identical(catch$ages, as.character(6:25)),
  all(1995:2025 %in% catch$valid_years),
  catch$values[match(2025L, catch$years), 1L] == 0.207,
  all(1966:2025 %in% catch_weight$valid_years),
  all(1966:2025 %in% stock_weight$valid_years),
  min(maturity$valid_years) == 1986L,
  max(maturity$valid_years) == 2025L,
  min(spring_index$valid_years) == 1985L,
  max(spring_index$valid_years) == 2025L,
  spring_index$values[match(2025L, spring_index$years), 1L] == 8.393,
  min(autumn_index$valid_years) == 1996L,
  max(autumn_index$valid_years) == 2025L,
  autumn_index$values[match(2025L, autumn_index$years), 1L] == 12,
  all(1966:2026 %in% stock_numbers$valid_years),
  stock_numbers$values[match(2025L, stock_numbers$years), 1L] == 125683,
  all(1966:2025 %in% fishing_mortality$valid_years),
  nrow(manifest) == 7L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nchar(manifest$sha256) == 64L),
  any(stocks$stock_id == 'ck_ices_afwg_norvegicus_deep1_2' &
    stocks$authority_stock_id == 'reg.27.1-2' &
    stocks$scientific_name == 'Sebastes norvegicus'),
  !any(tolower(stocks$authority_stock_id) == 'reg.27.561214', na.rm = TRUE),
  !any(assessments$assessment_id == 'ices_golden_redfish_561214'),
  !any(inputs$assessment_id == 'ices_golden_redfish_561214'),
  !any(outputs$assessment_id == 'ices_golden_redfish_561214')
)

cat('ICES 2026 golden-redfish identity, age coverage, biological inputs, outputs, provenance, and discovery-only status passed.\n')
