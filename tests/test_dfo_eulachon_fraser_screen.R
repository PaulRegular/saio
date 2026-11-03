root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
id <- 'DFO:Pacific:Eulachon - Fraser River'
row <- register[register$candidate_id == id, , drop = FALSE]
review_path <- file.path(root, 'discovery', 'source_reviews', 'dfo_eulachon_fraser_2026.md')

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_eulachon_fraser_du',
  row$scientific_name == 'Thaleichthys pacificus',
  row$assessment_area == 'Fraser River Designatable Unit, British Columbia',
  is.na(row$inventory_assessment_year),
  row$match_status == 'new', is.na(row$matched_stock_id),
  row$screening_status == 'screened', row$eligibility == 'ineligible',
  row$import_status == 'not_started', row$review_date == '2026-10-30',
  !any(stocks$stock_id == row$candidate_unit_id),
  !any(assessments$stock_id == row$candidate_unit_id),
  grepl('not catch numbers-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('aggregate spawning', row$survey_age_evidence, fixed = TRUE),
  grepl('no validated ageing technique', row$maturity_evidence, fixed = TRUE),
  grepl('aggregate F quantities', row$output_evidence, fixed = TRUE),
  grepl('2012 RPA includes', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('2012 Canadian RPA includes an Appendix 3 Bayesian age-structured', review, fixed = TRUE),
  grepl('did not use catch numbers-at-age or an age-specific survey index likelihood', review, fixed = TRUE),
  grepl('ineligible for the current age-disaggregated assessment set', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input or output records were added.', review, fixed = TRUE)
)

cache <- file.path(root, 'source_cache', 'discovery_dfo_eulachon_fraser')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- file.path(cache, manifest$file)
stopifnot(nrow(manifest) == 4L, all(file.exists(files)),
  all(file.info(files)$size == manifest$bytes),
  identical(as.character(manifest$sha256), c('574406592EEAB2590117687B07F1727A1049CC796AD800ED52403D2D899AC314', 'A894C8E49A570ACDBC0E5E5219F7C2F47B547D674DFC7DA5D3E5AD014A99E4FE', 'CF7E444B7A33BEC382F3CC0192F7CEC742DBBEEF9121F6151C5B365778A4D624', 'A54B7D6E20012D0A5DAD43FD557D091DAE0CDC204BE6F432AE0320C40100961E')),
  all(manifest$retrieved_on == '2026-10-30'),
  all(vapply(files[grepl('\\.pdf$', files)], function(path) {
    identical(rawToChar(readBin(path, 'raw', n = 5L)), '%PDF-')
  }, logical(1L))),
  any(grepl('347894.pdf', manifest$source_url, fixed = TRUE)),
  any(grepl('364476.pdf', manifest$source_url, fixed = TRUE)),
  any(grepl('41275810.pdf', manifest$source_url, fixed = TRUE)),
  any(grepl('eulachon-eulakane-ifmp-pgip-sm-eng.html', manifest$source_url, fixed = TRUE)))

ifmp_summary <- paste(readLines(files[grepl('ifmp_2026_summary.html$', files)], warn = FALSE), collapse = ' ')
stopifnot(grepl('approach is no longer used', ifmp_summary, fixed = TRUE),
  grepl('Egg and Larval Survey', ifmp_summary, fixed = TRUE))
cat('DFO Fraser River Eulachon inventory-screening checks passed.\n')
