root <- "."
id <- 'NOAA:12442'
unit_id <- 'noaa_opakapaka_mhi'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == id, , drop = FALSE]
unit <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- unit[!is.na(unit$candidate_unit_id) & unit$candidate_unit_id == unit_id, , drop = FALSE]
review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_opakapaka_mhi_2024.md'), warn = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(nrow(candidate) == 1L, candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible', candidate$import_status == 'not_started',
  nrow(unit) == 1L, unit$inventory_entries == 1L, unit$eligibility == 'ineligible',
  candidate$official_stock_id == '12442', candidate$scientific_name == 'Pristipomoides filamentosus',
  grepl('noaa_17252_DS1.pdf', candidate$detailed_source_url, fixed = TRUE),
  grepl('noaa_30604_DS1.pdf', candidate$detailed_source_url, fixed = TRUE),
  any(grepl('age-specific observed inputs', review, fixed = TRUE)),
  any(grepl('noaa_17252_DS1.pdf', review, fixed = TRUE)),
  any(grepl('noaa_30604_DS1.pdf', review, fixed = TRUE)),
  any(grepl('no canonical', review, ignore.case = TRUE)),
  !any(grepl('Pristipomoides filamentosus', stocks$scientific_name, fixed = TRUE), na.rm = TRUE))
cat('NOAA 12442 opakapaka identity, age-input screen and no-import checks passed.\n')
