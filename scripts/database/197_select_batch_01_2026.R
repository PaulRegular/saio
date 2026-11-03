root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

selection <- data.frame(
  priority = seq_len(20L),
  candidate_id = c(
    'DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO',
    'DFO:Gulf:White Hake - NAFO 4T',
    'DFO:Gulf:Yellowtail Flounder - NAFO 4T',
    'DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)',
    'DFO:Pacific:Yellowmouth Rockfish',
    'DFO:Gulf:Winter Flounder - NAFO 4T',
    'ICES:caa.27.5a',
    'ICES:cod.21.1.isc',
    'ICES:cod.21.1.osc',
    'ICES:reg.27.561214',
    'ICES:aru.27.5b6a',
    'ICES:her.27.irls',
    'ICES:bss.27.8ab',
    'ICES:whg.27.7b-ce-k',
    'NOAA:10455',
    'NOAA:10466',
    'NOAA:10568',
    'NOAA:10426',
    'NOAA:10415',
    'NOAA:14407'
  ),
  stringsAsFactors = FALSE
)
selection <- merge(selection, register, by = 'candidate_id', all.x = TRUE,
  sort = FALSE)
selection <- selection[order(selection$priority), ]
unit_status <- units$eligibility[match(selection$candidate_unit_id, units$candidate_unit_id)]
stopifnot(nrow(selection) == 20L, !anyNA(selection$candidate_unit_id),
  !anyDuplicated(selection$candidate_unit_id),
  all(selection$match_status == 'new'), all(selection$eligibility == 'eligible'),
  all(unit_status == 'eligible'), all(selection$screening_status == 'screened'),
  !any(selection$candidate_id %in% register$candidate_id[!is.na(register$matched_stock_id)]))

selection$selection_basis <- paste(
  'Ranked from the screened inventory for source evidence covering age-disaggregated',
  'inputs, biology, mortality assumptions, timing, and official outputs. Verify the',
  'latest advice run and exact source coverage before import.'
)
selection$curation_status <- 'selected_pending_source_validation'
selection <- selection[, c('priority', 'candidate_unit_id', 'candidate_id',
  'organization', 'official_stock_id', 'scientific_name', 'stock_name',
  'assessment_area', 'inventory_assessment_year', 'detailed_source_url',
  'review_date', 'selection_basis', 'curation_status')]
write.csv(selection, file.path(root, 'discovery', 'selected_batch_01_2026.csv'),
  row.names = FALSE, na = '')
cat('Selected 20 distinct eligible units: ',
  paste(names(table(selection$organization)), table(selection$organization),
    sep = '=', collapse = ', '), '\n', sep = '')
