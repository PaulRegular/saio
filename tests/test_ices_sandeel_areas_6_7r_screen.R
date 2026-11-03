Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source('scripts/database/343_screen_ices_sandeel_areas_6_7r_2023.R')

register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

cases <- data.frame(
  candidate_id = c('ICES:san.sa.6', 'ICES:san.sa.7r'),
  candidate_unit_id = c('ices_sandeel_area_6', 'ices_sandeel_area_7r'),
  assessment_key = c(17719L, 17717L),
  advice_key = c(3112L, 3113L),
  category = c('5.2', '5.3'),
  catch = c('42', '0'),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(cases))) {
  case <- cases[i, ]
  candidate <- register[register$candidate_id == case$candidate_id, , drop = FALSE]
  area <- if (case$candidate_id == 'ICES:san.sa.6') '6' else '7r'
  cache <- file.path('source_cache',
    paste0('discovery_ices_sandeel_area_', area, '_2023'))
  sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
  paths <- file.path(cache, sources$file)
  advice <- paste(readLines(paths[grep('ICES_Advice', sources$file)], warn = FALSE),
    collapse = '\n')
  sag <- paste(readLines(paths[grep('SAG_', sources$file)], warn = FALSE), collapse = '\n')
  sag_flat <- gsub('[[:space:]]+', ' ', sag)

  stopifnot(
    nrow(candidate) == 1L,
    candidate$candidate_unit_id == case$candidate_unit_id,
    candidate$match_status == 'new',
    candidate$screening_status == 'screened',
    candidate$eligibility == 'ineligible',
    candidate$import_status == 'not_started',
    grepl(paste('Category', case$category), candidate$catch_age_evidence, fixed = TRUE),
    all(file.exists(paths)),
    all(file.info(paths)$size > 0),
    all(tolower(sources$sha256) == tolower(vapply(paths, sha256_file, character(1L)))),
    grepl(sub('^ICES:', '', case$candidate_id), advice, fixed = TRUE),
    grepl(as.character(case$assessment_key), advice, fixed = TRUE),
    grepl(as.character(case$advice_key), basename(paths[1L]), fixed = TRUE),
    grepl(sub('^ICES:', '', case$candidate_id), sag, fixed = TRUE),
    grepl('Catches', sag, fixed = TRUE),
    grepl(paste0('>2022</td><td[^>]*>', case$catch, '</td>'), sag_flat,
      ignore.case = TRUE, perl = TRUE),
    !any(stocks$authority_stock_id == sub('^ICES:', '', case$candidate_id), na.rm = TRUE),
    !any(assessments$assessment_id == case$candidate_unit_id),
    !any(inputs$assessment_id == case$candidate_unit_id),
    !any(outputs$assessment_id == case$candidate_unit_id),
    file.exists(file.path('discovery', 'source_reviews',
      paste0(if (case$candidate_id == 'ICES:san.sa.6') 'ices_sandeel_area_6_2023' else
        'ices_sandeel_area_7r_2023', '.md')))
  )
}

cat('ICES sandeel Areas 6 and 7r screening checks passed.\n')
