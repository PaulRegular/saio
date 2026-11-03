root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_ling_5b_2026')
candidate_id <- 'ICES:lin.27.5b'
stock_id <- 'ices_ling_faroe_5b'
assessment_id <- 'ices_ling_faroe_5b_2026'

sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
report <- readLines(file.path(cache, 'WGDEEP_2026_ling_5b_section.txt'), warn = FALSE)
candidates <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
source_lines <- c(
  'Table 3.2.7. Ling in 5.b. Catch numbers at age (*1000) used in the assessment.',
  'Table 3.2.8. Ling in 5.b. Weighted mean weights at age used in the assessment.',
  'Table 3.2.9. Ling in 5.b. Spring survey input to the tuning series in the assessment.',
  'Table 3.2.10. Ling in 5.b. Summer survey input to tuning series in the assessment.',
  'Table 3.2.11. Ling in 5.b. Estimated recruitment, spawning stock biomass (SSB), and average fishing mortality.',
  'Table 3.2.12. Ling in 5.b. Estimated fishing mortality at age.',
  'Table 3.2.13. Ling in 5.b. Estimated stock numbers at age.'
)

if (nrow(candidate) != 1L || candidate$official_stock_id != 'lin.27.5b' ||
    candidate$scientific_name != 'Molva molva' || candidate$assessment_area != 'Faroes' ||
    candidate$match_status != 'new' || candidate$screening_status != 'screened' ||
    candidate$eligibility != 'eligible' || candidate$import_status != 'partial' ||
    nrow(stock) != 1L || stock$authority_stock_id != 'lin.27.5b' ||
    nrow(assessment) != 1L || assessment$assessment_year != 2026L ||
    assessment$terminal_year != 2025L ||
    sum(inputs$assessment_id == assessment_id, na.rm = TRUE) != 1172L ||
    sum(outputs$assessment_id == assessment_id, na.rm = TRUE) != 720L ||
    nrow(sources) != 6L || anyDuplicated(sources$file) ||
    any(!file.exists(file.path(cache, sources$local_path))) ||
    !all(vapply(source_lines, function(line) any(grepl(line, report, fixed = TRUE)), logical(1L)))) {
  stop('The Faroes ling source screen and partial import do not match the reviewed evidence.',
    call. = FALSE)
}

cat('Faroes ling source identity, report tables, and partial-import status verified.\n')
