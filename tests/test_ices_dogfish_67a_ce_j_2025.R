root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/437_screen_ices_dogfish_67a_ce_j_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:syc.27.67a-ce-j', , drop = FALSE]
cache <- file.path(root, 'source_cache/discovery_ices_dogfish_2025')
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
paths <- file.path(cache, sources$file)
graph <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_dogfish_67a_ce_j_2025.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  toupper(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE)))
}

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_lesser_spotted_dogfish_67a_ce_j',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('length-frequency data', candidate$catch_age_evidence, fixed = TRUE),
  grepl('relative biomass index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('<span id="lblKey">21039</span>', graph, fixed = TRUE),
  grepl('<span id="lblFAge"></span>', graph, fixed = TRUE),
  nrow(sources) == 2L,
  all(file.exists(paths)),
  all(file.info(paths)$size == sources$bytes),
  identical(toupper(sources$sha256), unname(vapply(paths, sha256_file, character(1L)))),
  identical(rawToChar(readBin(paths[1L], 'raw', n = 4L)), '%PDF'),
  grepl('category 3', review, fixed = TRUE),
  grepl('4781 t', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'syc.27.67a-ce-j', na.rm = TRUE)
)

cat('ICES Celtic Seas lesser spotted dogfish 2025 source-screening checks passed.\n')
