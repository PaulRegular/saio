root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
candidate_id <- 'ICES:usk.27.5a14'
unit_id <- 'ices_tusk_5a14'
assessment_id <- paste0(unit_id, '_2026')
row <- match(candidate_id, register$candidate_id)
stopifnot(!is.na(row))
screened <- register[row, , drop = FALSE]
stopifnot(
  screened$official_stock_id == 'usk.27.5a14',
  screened$scientific_name == 'Brosme brosme',
  screened$inventory_assessment_year == 2026L,
  screened$candidate_unit_id == unit_id,
  screened$match_status == 'matched',
  screened$screening_status == 'screened',
  screened$eligibility == 'unresolved',
  screened$import_status == 'partial',
  screened$matched_stock_id == unit_id,
  grepl('SAM', screened$catch_age_evidence, fixed = TRUE),
  grepl('no corresponding catch weight-at-age data from Subarea 14', screened$catch_age_evidence, fixed = TRUE),
  grepl('age-disaggregated Icelandic spring SMB indices', screened$survey_age_evidence, fixed = TRUE),
  grepl('maturity-at-age is derived from autumn-survey', screened$maturity_evidence, fixed = TRUE),
  grepl('0.15 per year', screened$mortality_evidence, fixed = TRUE),
  grepl('Fbar ages 7-10', screened$output_evidence, fixed = TRUE),
  grepl('Eligibility remains unresolved', screened$decision_reason, fixed = TRUE),
  grepl('both 5.a and 14', screened$decision_reason, fixed = TRUE),
  any(stocks$stock_id == unit_id),
  any(assessments$assessment_id == assessment_id),
  all(assessments$inputs_status[assessments$assessment_id == assessment_id] == 'not_started'),
  all(assessments$outputs_status[assessments$assessment_id == assessment_id] == 'partial')
)

read_assessment_rows <- function(path, id) {
  rg <- Sys.which('rg')
  stopifnot(nzchar(rg))
  found <- suppressWarnings(system2(rg, c('--color', 'never', '--no-heading',
    '--no-line-number', '-F', id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(found, 'status')
  if (is.null(status)) status <- 0L
  stopifnot(status %in% c(0L, 1L))
  found <- found[startsWith(found, paste0('"', id, '",'))]
  if (!length(found)) return(data.frame())
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, found), collapse = '\n'),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
}

inputs <- read_assessment_rows(file.path(root, 'database', 'inputs.csv'), assessment_id)
outputs <- read_assessment_rows(file.path(root, 'database', 'outputs.csv'), assessment_id)
stopifnot(nrow(inputs) == 0L, nrow(outputs) == 191L)
historical <- outputs[is.na(outputs$scenario) & outputs$year <= 2025L, , drop = FALSE]
forecast <- outputs[!is.na(outputs$scenario) & outputs$scenario == 'forecast', , drop = FALSE]
stopifnot(
  identical(sort(unique(historical$year)), 1979:2025),
  identical(sort(unique(forecast$year)), 2026L),
  nrow(historical) == 188L, nrow(forecast) == 3L,
  setequal(unique(historical$measure), c('recruitment', 'total_biomass', 'SSB', 'Fbar')),
  setequal(unique(forecast$measure), c('recruitment', 'total_biomass', 'SSB')),
  all(historical$source_type == 'official_table'),
  all(forecast$source_type == 'official_table'),
  all(is.na(outputs$se)),
  all(is.finite(outputs$lwr)), all(is.finite(outputs$upr)),
  all(outputs$lwr <= outputs$value & outputs$value <= outputs$upr),
  historical$value[historical$year == 1979L & historical$measure == 'SSB'] == 16244,
  historical$value[historical$year == 2025L & historical$measure == 'Fbar'] == 0.107,
  forecast$value[forecast$measure == 'SSB'] == 13829,
  all(grepl('coverage level', outputs$notes, ignore.case = TRUE))
)

review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_tusk_5a14_2026.md'), warn = FALSE), collapse = ' ')
stopifnot(
  grepl('combined 5.a+14 unit', review, fixed = TRUE),
  grepl('2026 is a forecast', review, fixed = TRUE),
  grepl('no attached file', review, fixed = TRUE),
  grepl('191 aggregate output rows', review, fixed = TRUE),
  grepl('eligibility unresolved', review, fixed = TRUE),
  grepl('age-disaggregated curation', review, fixed = TRUE)
)

cache_options <- c(file.path(root, 'source_cache', 'discovery_ices_tusk_5a14_2026'),
  file.path(root, '..', '..', 'discovery_ices_tusk_5a14_2026'))
cache <- cache_options[dir.exists(cache_options)][1L]
manifest <- read.csv(file.path(root, 'provenance', assessment_id, 'sources.csv'),
  stringsAsFactors = FALSE)
files <- c('MFRI_tusk_2026_technical_report.html', 'MFRI_tusk_2026_advice.html',
  'MFRI_tusk_2023_technical_report.pdf', 'ICES_WKICEMP_2022_benchmark.pdf',
  'ICES_stock_graphs_2026_key_22530.html', 'ICES_source_data_2026_key_22530.html',
  'ICES_advice_2026_record_7219.html', 'ICES_stock_annex_2023_metadata.json')
stopifnot(nrow(manifest) == length(files), !anyDuplicated(manifest$file),
  all(files %in% manifest$file), all(file.exists(file.path(cache, files))),
  all(file.info(file.path(cache, files))$size == manifest$bytes[match(files, manifest$file)]),
  all(manifest$retrieved_on[match(files, manifest$file)] == '2026-10-30'),
  all(nchar(manifest$sha256[match(files, manifest$file)]) == 64L))

cat('ICES tusk partial output import, unresolved age-input eligibility, source values, and provenance checks passed.\n')
