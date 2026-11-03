root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/435_screen_ices_cod_faroe_bank_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:cod.27.5b2', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_cod_faroe_bank_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
source_data <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_cod_faroe_bank_2025.md'), warn = FALSE), collapse = '\n')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_cod_faroe_bank',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('landings as the catch input', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate Faroese summer', candidate$survey_age_evidence, fixed = TRUE),
  grepl('2025 category 3 assessment', candidate$decision_reason, fixed = TRUE),
  nrow(sources) == 2L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  identical(toupper(sources$sha256), unname(vapply(paths, sha256_file, character(1L)))),
  all(sources$retrieved_on == '2026-10-30'),
  identical(rawToChar(readBin(paths[1L], 'raw', n = 4L)), '%PDF'),
  grepl('cod.27.5b2', source_data, fixed = TRUE),
  grepl('<span id="lblYear">2025</span>', source_data, fixed = TRUE),
  grepl('<span id="lblKey">21243</span>', source_data, fixed = TRUE),
  grepl('<span id="lblStockSizeDescription">B_index</span>', source_data, fixed = TRUE),
  grepl('lblFAge"></span>', source_data, fixed = TRUE),
  grepl('<th scope="col">Low SSB</th>', source_data, fixed = TRUE),
  grepl('<th scope="col">High SSB</th>', source_data, fixed = TRUE),
  grepl('category 3', review, fixed = TRUE),
  grepl('does not establish that age samples', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'cod.27.5b2', na.rm = TRUE),
  !any(stocks$stock_id == candidate$candidate_unit_id),
  !any(assessments$stock_id == candidate$candidate_unit_id),
  !any(inputs$assessment_id == candidate$candidate_unit_id),
  !any(outputs$assessment_id == candidate$candidate_unit_id)
)

cat('ICES Faroe Bank cod source-screening checks passed.\n')
