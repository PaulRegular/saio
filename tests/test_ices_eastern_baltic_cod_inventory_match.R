root <- "."
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root,
  'scripts/database/355_reconcile_ices_eastern_baltic_cod_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidates <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stock <- stocks[stocks$stock_id == 'ck_ices_wgbfas_morhua_bs_25_32', , drop = FALSE]
candidate <- candidates[candidates$candidate_id == 'ICES:cod.27.24-32', , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == 'cod.27.24-32',
  stock$common_name == 'Eastern Baltic cod',
  stock$area == 'Subdivisions 24-32 (eastern Baltic)',
  sum(stocks$authority_stock_id == 'cod.27.24-32', na.rm = TRUE) == 1L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock$stock_id,
  candidate$match_status == 'matched',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'imported',
  !any(candidates$candidate_unit_id == 'ices_cod_eastern_baltic_24_32', na.rm = TRUE),
  all(c('ices_cod_eastern_baltic_2024', 'ices_cod_eastern_baltic_2026') %in%
    assessments$assessment_id),
  grepl('current ICES unit cod.27.24-32', stock$notes, fixed = TRUE),
  grepl('historical Charbonneau-Keith BS 25-32', candidate$notes, fixed = TRUE)
)

cat('ICES eastern Baltic cod inventory identity and boundary checks passed.\n')
