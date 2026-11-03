root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/455_screen_ices_ling_1_2_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'ICES:lin.27.1-2', , drop = FALSE]
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/ices_ling_1_2_2025.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'ices_ling_ne_arctic_1_2',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('kg per 1,000 hooks', candidate$survey_age_evidence, fixed = TRUE),
  grepl('Category 3.21', candidate$decision_reason, fixed = TRUE),
  grepl('not interpret this series as SSB', candidate$notes, fixed = TRUE),
  grepl('2000–2024', review, fixed = TRUE),
  grepl('do not establish whether age samples', review, fixed = TRUE),
  !any(tolower(stocks$authority_stock_id) == 'lin.27.1-2', na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% assessments$stock_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% inputs$assessment_id, na.rm = TRUE),
  !any(candidate$candidate_unit_id %in% outputs$assessment_id, na.rm = TRUE)
)

cat('ICES Northeast Arctic ling 2025 source-screening checks passed.\n')
