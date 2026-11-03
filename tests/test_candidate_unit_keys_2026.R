root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

candidate_ids <- c(
  'NOAA:10002', 'NOAA:10004', 'NOAA:10005', 'NOAA:10011', 'NOAA:10015',
  'NOAA:10016', 'NOAA:10021', 'NOAA:10022', 'NOAA:10028', 'NOAA:10030',
  'NOAA:10035', 'NOAA:10046', 'NOAA:10054', 'NOAA:10393', 'NOAA:10415',
  'NOAA:10416', 'NOAA:10417', 'NOAA:10426', 'NOAA:10457', 'NOAA:10458',
  'NOAA:10460', 'NOAA:10461', 'NOAA:10462', 'NOAA:10466', 'NOAA:10562',
  'NOAA:10568', 'NOAA:11056', 'NOAA:14804', 'NOAA:14805', 'NOAA:15342',
  'NOAA:17280', 'NOAA:17281', 'NOAA:17282', 'NOAA:17357',
  'ICES:her.27.irls', 'ICES:mac.27.nea', 'ICES:whg.27.7b-ce-k',
  'ICES:pol.27.67', 'ICES:meg.27.8c9a', 'ICES:ple.27.7bc',
  'ICES:ple.27.7h-k', 'ICES:sol.27.7bc', 'ICES:cod.27.6b',
  'ICES:anf.27.3a46', 'ICES:sol.27.8c9a', 'ICES:her.27.nirs',
  'ICES:had.27.7a', 'ICES:wit.27.3a47d', 'ICES:bss.27.4bc7ad-h',
  'ICES:sol.27.8ab', 'ICES:sol.27.7a',
  'DFO:Maritimes:Acadian Redfish - Unit 3',
  'DFO:Maritimes:Atlantic Cod - NAFO 4X5Y',
  'DFO:Pacific:Bocaccio Rockfish',
  'DFO:Pacific:Pacific Herring - Central Coast',
  'DFO:Pacific:Pacific Herring - Haida Gwaii',
  'DFO:Pacific:Pacific Herring - Prince Rupert District',
  'DFO:Pacific:Pacific Herring - West Coast of Vancouver Island',
  'DFO:Pacific:Sablefish',
  'DFO:Gulf:White Hake - NAFO 4T',
  'DFO:Gulf:Yellowtail Flounder - NAFO 4T',
  'DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide')

rows <- register[match(candidate_ids, register$candidate_id), , drop = FALSE]
stopifnot(nrow(rows) == 62L, !anyNA(rows$candidate_id),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(!is.na(rows$candidate_unit_id) & nzchar(rows$candidate_unit_id)),
  !anyDuplicated(rows$candidate_unit_id),
  all(grepl('^(noaa_stocksmart_|ices_|dfo_sff_2024_)', rows$candidate_unit_id)))

unit_keys <- paste0('candidate:', rows$candidate_unit_id)
stopifnot(all(unit_keys %in% units$unit_key),
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(units$match_status == 'new' & units$eligibility == 'eligible') == 90L)

unit_count_columns <- c('eligible_new_units', 'ineligible_new_units',
  'unresolved_new_units', 'mixed_new_units', 'other_candidate_units')
stopifnot(all(unit_count_columns %in% names(progress)),
  all(progress$crosswalked_candidate_units == rowSums(progress[unit_count_columns])))

linked <- (!is.na(register$matched_stock_id) & nzchar(register$matched_stock_id)) |
  (!is.na(register$candidate_unit_id) & nzchar(register$candidate_unit_id))
unlinked <- register[!linked, , drop = FALSE]
stopifnot(nrow(unlinked) == 130L,
  all(unlinked$match_status %in% c('ambiguous', 'unreviewed')),
  sum(unlinked$match_status == 'unreviewed') == 100L,
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'inventory_new_unit_keys_2026.md')))
