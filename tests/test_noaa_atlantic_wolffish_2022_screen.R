root <- "."
source(file.path(root, 'scripts', 'database',
  '500_screen_noaa_atlantic_wolffish_2022.R'))

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:11562', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_atlantic_wolffish_us.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_noaa_atlantic_wolffish_2022')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_atlantic_wolffish_us',
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible', candidate$import_status == 'not_started',
  candidate$inventory_assessment_year == 2022,
  grepl('total catch and catch-size distributions', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-1 recruitment index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('SSB, fully selected F, age-1 recruitment', candidate$output_evidence, fixed = TRUE),
  grepl('Level 1 direct delivery', review, fixed = TRUE),
  grepl('not peer reviewed', review, fixed = TRUE),
  grepl('age-based abundance measures could not be developed', review, fixed = TRUE),
  grepl('ICES candidate `caa.27.5a`', review, fixed = TRUE),
  all(c('atlantic_wolffish_2022_assessment.pdf',
    'nefsc_fall_2022_management_track_panel_report.pdf') %in% manifest$file),
  any(manifest$status == 'access_denied' & grepl('2009', manifest$revision, fixed = TRUE)),
  !any(stocks$scientific_name == 'Anarhichas lupus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_atlantic_wolffish_2022', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_atlantic_wolffish_2022', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_atlantic_wolffish_2022', na.rm = TRUE),
  sum(noaa$inventory_rows) == 432L, sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L)

cat('NOAA Atlantic wolffish identity, source, eligibility and no-import checks passed.\n')
