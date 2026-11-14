root <- "."
read_table <- function(name, assessment_id = NULL) {
  path <- file.path(root, 'database', paste0(name, '.csv'))
  header <- readLines(path, n = 1L, warn = FALSE)
  if (is.null(assessment_id)) {
    return(read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
      check.names = FALSE))
  }
  rows <- system2('rg', c('--color', 'never', '--no-heading',
    '--no-line-number', '-F', assessment_id, path), stdout = TRUE,
    stderr = FALSE)
  status <- attr(rows, 'status')
  if (is.null(status)) status <- 0L
  stopifnot(status == 0L)
  read.csv(text = paste(c(header, rows), collapse = '\n'),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
}

stocks <- read_table('stocks')
assessments <- read_table('assessments')
assumptions <- read_table('assumptions', 'noaa_goa_pop_2023')
inputs <- read_table('inputs', 'noaa_goa_pop_2023')
outputs <- read_table('outputs', 'noaa_goa_pop_2023')
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
selected <- read.csv(file.path(root, 'discovery', 'selected_batch_01_2026.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

assessment_id <- 'noaa_goa_pop_2023'
stock_id <- 'afsc_goa_pacific_ocean_perch'
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumption <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
input <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
output <- outputs
near <- function(x, y, tolerance = 1e-6) {
  isTRUE(all.equal(as.numeric(x), as.numeric(y), tolerance = tolerance))
}

catch <- input[input$type == 'catch' & input$measure == 'total_biomass', , drop = FALSE]
survey <- input[input$type == 'index' &
  input$measure %in% c('total_biomass', 'index_sd'), , drop = FALSE]
fish_age <- input[input$type == 'catch' &
  input$measure == 'proportion_at_age', , drop = FALSE]
survey_age <- input[input$type == 'index' &
  input$measure == 'proportion_at_age', , drop = FALSE]
n_at_age <- output[output$measure == 'numbers_at_age', , drop = FALSE]
point_output <- output[is.na(output$scenario), , drop = FALSE]
ssb <- point_output[point_output$measure == 'SSB', , drop = FALSE]
m_at_age <- output[output$measure == 'natural_mortality_at_age', , drop = FALSE]
mcmc <- output[!is.na(output$scenario) &
  output$scenario == 'MCMC posterior median; Table 9.8', , drop = FALSE]

candidate_row <- candidate[candidate$candidate_id == 'NOAA:11056', , drop = FALSE]
selected_row <- selected[selected$candidate_id == 'NOAA:11056', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_pacific_ocean_perch.md'), warn = FALSE), collapse = ' ')

stopifnot(
  nrow(stock) == 1L,
  stock$authority == 'NOAA-AFSC',
  stock$authority_stock_id == 'Stock SMART 11056',
  stock$ocean == 'Northeast Pacific',
  nrow(assessment) == 1L,
  assessment$assessment_year == 2023,
  assessment$terminal_year == 2023,
  assessment$estimate_terminal_year == 2025,
  assessment$assumptions_status == 'complete',
  assessment$inputs_status == 'complete',
  assessment$outputs_status == 'partial',
  nrow(assumption) == 140L,
  nrow(input) == 2107L,
  nrow(output) == 7646L,
  nrow(catch) == 63L,
  near(catch$value[catch$year == 1961], 16000),
  near(catch$value[catch$year == 2023], 30380.690922833, 1e-8),
  all(catch$unit == 't'),
  nrow(survey) == 32L,
  near(survey$value[survey$measure == 'total_biomass' & survey$year == 1990], 157295),
  near(survey$value[survey$measure == 'index_sd' & survey$year == 1990], 47129),
  nrow(fish_age) == 17L * 24L,
  nrow(survey_age) == 14L * 24L,
  near(fish_age$value[fish_age$year == 1990 & fish_age$age == 25], 0.10230792),
  near(survey_age$value[survey_age$year == 1990 & survey_age$age == 25], 0.070479987),
  fish_age$sample_size[fish_age$year == 1990][1] == 578,
  survey_age$sample_size[survey_age$year == 1990][1] == 1754,
  nrow(n_at_age) == 63L * 28L,
  near(n_at_age$value[n_at_age$year == 1961 & n_at_age$age == 2], 107.319),
  near(n_at_age$value[n_at_age$year == 1961 & n_at_age$age == 29], 160.439),
  near(ssb$value[ssb$year == 2023], 234352),
  near(m_at_age$value[1], 0.074344943, 1e-8),
  near(output$value[output$measure == 'q'], 1.736106),
  nrow(mcmc) == 254L,
  sum(mcmc$measure == 'apical_F') == 63L,
  sum(mcmc$measure == 'recruitment') == 63L,
  sum(mcmc$measure == 'SSB') == 64L,
  sum(mcmc$measure == 'total_biomass') == 64L,
  all(is.na(point_output$se) & is.na(point_output$lwr) & is.na(point_output$upr)),
  all(is.na(mcmc$se) & is.finite(mcmc$lwr) & is.finite(mcmc$upr)),
  near(mcmc$value[mcmc$measure == 'SSB' & mcmc$year == 2023], 240000),
  near(mcmc$lwr[mcmc$measure == 'SSB' & mcmc$year == 2023], 157000),
  near(mcmc$upr[mcmc$measure == 'SSB' & mcmc$year == 2023], 365000),
  near(mcmc$value[mcmc$measure == 'recruitment' & mcmc$year == 2023], 83),
  near(mcmc$lwr[mcmc$measure == 'recruitment' & mcmc$year == 2023], 17),
  near(mcmc$upr[mcmc$measure == 'recruitment' & mcmc$year == 2023], 370),
  near(mcmc$value[mcmc$measure == 'apical_F' & mcmc$year == 2023], 0.072),
  near(mcmc$lwr[mcmc$measure == 'apical_F' & mcmc$year == 2023], 0.044),
  near(mcmc$upr[mcmc$measure == 'apical_F' & mcmc$year == 2023], 0.12),
  nrow(candidate_row) == 1L,
  candidate_row$matched_stock_id == stock_id,
  candidate_row$match_status == 'matched',
  candidate_row$import_status == 'partial',
  nrow(selected_row) == 1L,
  selected_row$curation_status == 'partial_source_import',
  grepl('1990 survey age composition', review, fixed = TRUE),
  grepl('without survival to spawning', review, fixed = TRUE),
  grepl('survey timing', review, fixed = TRUE)
)

cat('NOAA GOA Pacific ocean perch 2023 source import checks passed.\n')
