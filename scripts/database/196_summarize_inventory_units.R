register_path <- file.path('discovery', 'candidates.csv')
root <- "."
x <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'), env)
noaa <- env$stock_assessment_summary
noaa <- noaa[order(noaa$stock_id, -as.numeric(noaa$assessment_year), noaa$assessment_id, na.last = TRUE), ]
noaa <- noaa[!duplicated(noaa$stock_id), ]

region <- rep(NA_character_, nrow(x))
is_noaa <- x$organization == 'NOAA'
region[is_noaa] <- noaa$science_center[match(x$official_stock_id[is_noaa], as.character(noaa$stock_id))]
is_dfo <- x$organization == 'DFO'
region[is_dfo] <- sub('^DFO:([^:]+):.*$', '\\1', x$candidate_id[is_dfo])
is_ices <- x$organization == 'ICES'
region[is_ices] <- x$assessment_area[is_ices]
is_nafo <- x$organization == 'NAFO'
region[is_nafo] <- x$assessment_area[is_nafo]
region[!is.na(region)] <- trimws(gsub('[[:space:]]+', ' ', region[!is.na(region)]))
region[is.na(region) | !nzchar(trimws(region))] <- 'Unspecified'

has_stock <- !is.na(x$matched_stock_id) & nzchar(x$matched_stock_id)
has_candidate <- !is.na(x$candidate_unit_id) & nzchar(x$candidate_unit_id)
unit_key <- ifelse(has_stock, paste0('stock:', x$matched_stock_id),
  ifelse(has_candidate, paste0('candidate:', x$candidate_unit_id), NA_character_))
linked <- !is.na(unit_key)

collapse <- function(value) {
  value <- sort(unique(value[!is.na(value) & nzchar(value)]))
  paste(value, collapse = ' | ')
}
single_status <- function(value) {
  value <- unique(value)
  if (length(value) == 1L) value else 'mixed'
}
summarize_unit <- function(indices) {
  row <- x[indices, , drop = FALSE]
  key <- unit_key[indices[1L]]
  data.frame(
    unit_key = key,
    matched_stock_id = if (startsWith(key, 'stock:')) substring(key, 7L) else '',
    candidate_unit_id = if (startsWith(key, 'candidate:')) substring(key, 11L) else '',
    match_status = single_status(row$match_status),
    eligibility = single_status(row$eligibility),
    screening_status = single_status(row$screening_status),
    import_status = single_status(row$import_status),
    organizations = collapse(row$organization),
    source_regions = collapse(region[indices]),
    candidate_ids = collapse(row$candidate_id),
    inventory_entries = nrow(row),
    stringsAsFactors = FALSE
  )
}

unit_indices <- split(which(linked), unit_key[linked])
units <- if (length(unit_indices)) do.call(rbind, lapply(unit_indices, summarize_unit)) else data.frame()
units <- units[order(units$unit_key), , drop = FALSE]
write.csv(units, file.path(root, 'discovery', 'inventory_units.csv'), row.names = FALSE, na = '')

stopifnot(!anyDuplicated(units$unit_key),
  sum(units$inventory_entries) == sum(linked),
  all(units$match_status %in% c('matched', 'new', 'ambiguous', 'unreviewed', 'mixed')),
  all(units$eligibility %in% c('eligible', 'ineligible', 'unresolved', 'mixed')),
  all(units$screening_status %in% c('screened', 'not_started', 'in_progress', 'mixed')))

cat(nrow(units), ' linked stock units represented by ', sum(units$inventory_entries),
  ' inventory rows; ', sum(!linked), ' rows still lack a crosswalk unit.\n', sep = '')
