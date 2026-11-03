root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/438_screen_ices_plaice_89a_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

candidate_id <- 'ICES:ple.27.89a'
candidate <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_plaice_89a_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
advice <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
graph <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_plaice_89a_2025.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == 'ple.27.89a',
  candidate$scientific_name == 'Pleuronectes platessa',
  candidate$candidate_unit_id == 'ices_plaice_89a',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('commercial number-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('no commercial index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('no analytical assessment', candidate$decision_reason, fixed = TRUE),
  nrow(sources) == 3L,
  identical(basename(paths), sources$file),
  all(file.exists(paths)),
  identical(as.numeric(file.info(paths)$size), as.numeric(sources$bytes)),
  identical(toupper(sources$sha256), unname(vapply(paths, sha256_file, character(1L)))),
  identical(rawToChar(readBin(paths[1L], 'raw', n = 4L)), '%PDF'),
  grepl('27202791', advice, fixed = TRUE),
  grepl('99 tonnes', advice, fixed = TRUE),
  grepl('<span id="lblFAge"></span>', graph, fixed = TRUE),
  grepl('124 t', review, fixed = TRUE),
  grepl('99 t', review, fixed = TRUE),
  grepl('unresolved', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'ple.27.89a', na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% assessments$stock_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% inputs$assessment_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% outputs$assessment_id, na.rm = TRUE)
)

cat('ICES Bay of Biscay plaice 2025 source-screening checks passed.\n')
