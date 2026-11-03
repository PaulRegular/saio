root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen_review <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/492_screen_ices_seals_2026.R'),
  local = screen_review)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('ICES:seh.27.125a14', 'ICES:seh.27.1', 'ICES:sez.27.2514')
unit_ids <- c('ices_harp_seal_greenland_sea', 'ices_harp_seal_barents_white_sea',
  'ices_hooded_seal_greenland_sea')
screened <- candidates[match(ids, candidates$candidate_id), , drop = FALSE]
dfo_harp <- candidates[candidates$candidate_id ==
  'DFO:National Capital Region:Harp Seal - Northwest Atlantic', , drop = FALSE]

stopifnot(nrow(screened) == 3L,
  identical(screened$candidate_unit_id, unit_ids),
  all(screened$match_status == 'new'),
  all(screened$screening_status == 'screened'),
  all(screened$eligibility == 'ineligible'),
  all(screened$import_status == 'not_started'),
  identical(screened$assessment_area, c(
    'Greenland Sea stock (subareas 1, 2, and 14; Division 5.a)',
    'Barents and White Sea stock (Subarea 1)',
    'Greenland Sea stock (subareas 2, 5, and 14)')),
  grepl('age-based analytical SAM', screened$notes[2], fixed = TRUE),
  grepl('does not establish that age-structured data are absent',
    screened$decision_reason[2], fixed = TRUE),
  grepl('DFO Northwest Atlantic', screened$notes[1], fixed = TRUE),
  nrow(dfo_harp) == 1L,
  is.na(dfo_harp$candidate_unit_id) || !nzchar(dfo_harp$candidate_unit_id),
  !any(screened$official_stock_id %in% stocks$authority_stock_id),
  !any(unit_ids %in% assessments$stock_id),
  !any(unit_ids %in% inputs$assessment_id),
  !any(unit_ids %in% outputs$assessment_id),
  all(unit_ids %in% units$candidate_unit_id),
  all(units$inventory_entries[match(unit_ids, units$candidate_unit_id)] == 1L),
  file.exists(file.path(root, 'source_cache', 'discovery_ices_sid',
    c('stock_list_2026.json', 'sources.csv'))),
  file.exists(file.path(root, 'discovery/source_reviews/ices_seal_units_2026.md')))

cat('ICES seal identities, stock boundaries, out-of-scope decisions, and no-import checks passed.\n')
