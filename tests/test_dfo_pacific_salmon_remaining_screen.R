root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)

get_row <- function(id_pattern) {
  rows <- grep(id_pattern, register$candidate_id)
  stopifnot(length(rows) == 1L)
  register[rows, , drop = FALSE]
}

north_coast_coho <- get_row('^DFO:Pacific:Coho Salmon - North Coast$')
fraser_pink <- get_row('^DFO:Pacific:Pink Salmon .* Fraser$')
skeena_nass_pink <- get_row('^DFO:Pacific:Pink Salmon - Skeena-Nass$')
nass_sockeye <- get_row('^DFO:Pacific:Sockeye Salmon - Nass$')
skeena_sockeye <- get_row('^DFO:Pacific:Sockeye Salmon - Skeena$')
stikine_sockeye <- get_row('^DFO:Pacific:Sockeye Salmon - Stikine$')
barkley_sockeye <- get_row('^DFO:Pacific:WCVI Barkley Sockeye Salmon$')

stopifnot(
  north_coast_coho$match_status == 'ambiguous',
  north_coast_coho$screening_status == 'screened',
  north_coast_coho$eligibility == 'unresolved',
  is.na(north_coast_coho$candidate_unit_id),
  grepl('Central Coast, Haida Gwaii, Nass and Skeena', north_coast_coho$catch_age_evidence, fixed = TRUE),
  fraser_pink$candidate_unit_id == 'dfo_fraser_pink_odd_smu',
  fraser_pink$scientific_name == 'Oncorhynchus gorbuscha',
  fraser_pink$inventory_assessment_year == 2023L,
  fraser_pink$match_status == 'new', fraser_pink$screening_status == 'screened',
  fraser_pink$eligibility == 'ineligible',
  grepl('single-age-class', fraser_pink$decision_reason, fixed = TRUE),
  grepl('catch, escapement, total run size and exploitation-rate', fraser_pink$output_evidence, fixed = TRUE),
  skeena_nass_pink$match_status == 'ambiguous',
  skeena_nass_pink$screening_status == 'screened',
  skeena_nass_pink$eligibility == 'unresolved',
  is.na(skeena_nass_pink$candidate_unit_id),
  grepl('Pink Skeena and Pink Nass', skeena_nass_pink$decision_reason, fixed = TRUE),
  nass_sockeye$candidate_unit_id == 'dfo_nass_sockeye_smu',
  nass_sockeye$match_status == 'new', nass_sockeye$screening_status == 'screened',
  nass_sockeye$eligibility == 'ineligible',
  grepl('Age composition', nass_sockeye$survey_age_evidence, fixed = TRUE),
  grepl('back-calculate recruitment', nass_sockeye$decision_reason, fixed = TRUE),
  skeena_sockeye$candidate_unit_id == 'dfo_skeena_sockeye_smu',
  skeena_sockeye$match_status == 'new', skeena_sockeye$screening_status == 'screened',
  skeena_sockeye$eligibility == 'ineligible',
  stikine_sockeye$candidate_unit_id == 'dfo_stikine_sockeye_smu',
  stikine_sockeye$match_status == 'new', stikine_sockeye$screening_status == 'screened',
  stikine_sockeye$eligibility == 'ineligible',
  grepl('genetic mark-recapture', stikine_sockeye$decision_reason, fixed = TRUE),
  barkley_sockeye$candidate_unit_id == 'dfo_wcvi_barkley_sockeye_smu',
  barkley_sockeye$inventory_assessment_year == 2024L,
  barkley_sockeye$match_status == 'new', barkley_sockeye$screening_status == 'screened',
  barkley_sockeye$eligibility == 'ineligible',
  grepl('2026/022', barkley_sockeye$output_evidence, fixed = TRUE),
  all(register$import_status[c(grep('^DFO:Pacific:Coho Salmon - North Coast$', register$candidate_id),
    grep('^DFO:Pacific:Pink Salmon .* Fraser$', register$candidate_id),
    grep('^DFO:Pacific:Pink Salmon - Skeena-Nass$', register$candidate_id),
    grep('^DFO:Pacific:Sockeye Salmon - Nass$', register$candidate_id),
    grep('^DFO:Pacific:Sockeye Salmon - Skeena$', register$candidate_id),
    grep('^DFO:Pacific:Sockeye Salmon - Stikine$', register$candidate_id),
    grep('^DFO:Pacific:WCVI Barkley Sockeye Salmon$', register$candidate_id))] == 'not_started')
)

new_units <- c('dfo_fraser_pink_odd_smu', 'dfo_nass_sockeye_smu',
  'dfo_skeena_sockeye_smu', 'dfo_stikine_sockeye_smu',
  'dfo_wcvi_barkley_sockeye_smu')
stopifnot(
  all(!new_units %in% stocks$stock_id),
  all(!new_units %in% assessments$assessment_id),
  all(!new_units %in% inputs$assessment_id),
  all(!new_units %in% outputs$assessment_id)
)

cache <- file.path(root, 'source_cache', 'discovery_dfo_pacific_salmon_2026')
manifest_path <- file.path(cache, 'sources.csv')
review_path <- file.path(root, 'discovery', 'source_reviews', 'dfo_pacific_salmon_remaining_2026.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  stopifnot(
    nrow(manifest) == 4L,
    all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(manifest$retrieved_on == '2026-10-30'),
    identical(as.character(manifest$sha256), c(
      'C6B351A57E3B58D54B3C7265FC207C624A06A9330C63FDF5FF5237FE26666A6E',
      '82ED1B245083528699D5827BDE0EB161C179AA176149E516C2093D112ABDEB7F',
      '186FE076E90DAC19693F8E1F95073BFCDFC30CE79AA582C0CB166D03BAC290A1',
      'E1D777BF5A2421ECBBCE14FD582487AA63E90A6C64DA251648A6DAAFD6ACDA11'
    ))
  )
}
stopifnot(
  grepl('Fraser Pink Odd', review, fixed = TRUE),
  grepl('Barkley sockeye', review, fixed = TRUE),
  grepl('No canonical database stock, assessment, input or output records were created.', review, fixed = TRUE),
  grepl('2026/022', review, fixed = TRUE)
)
cat('DFO remaining Pacific salmon identity, eligibility and source checks passed.\n')
