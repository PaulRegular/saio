# Summarize source-list rows without treating unscreened rows as new stocks.
root <- "."
x <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'), envir = e)
noaa <- e$stock_assessment_summary
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
is_inidep <- x$organization == 'INIDEP'
region[is_inidep] <- 'Argentina; targeted assessment-report search, not a comprehensive inventory'
is_fisheries_nz <- x$organization == 'Fisheries New Zealand'
region[is_fisheries_nz] <- 'New Zealand'
other_region <- is.na(region) & !is.na(x$assessment_area) & nzchar(x$assessment_area)
region[other_region] <- x$assessment_area[other_region]
region[!is.na(region)] <- trimws(gsub('[[:space:]]+', ' ', region[!is.na(region)]))
region[is.na(region) | !nzchar(trimws(region))] <- 'Unspecified'
key <- data.frame(organization = x$organization, source_region = region, stringsAsFactors = FALSE)
metrics <- data.frame(inventory_rows = 1L, matched = as.integer(x$match_status == 'matched'),
  new = as.integer(x$match_status == 'new'), ambiguous = as.integer(x$match_status == 'ambiguous'),
  identity_unreviewed = as.integer(x$match_status == 'unreviewed'),
  eligible = as.integer(x$eligibility == 'eligible'), excluded = as.integer(x$eligibility == 'ineligible'),
  eligible_new = as.integer(x$match_status == 'new' & x$eligibility == 'eligible'),
  eligibility_unresolved = as.integer(x$eligibility == 'unresolved'),
  screening_not_started = as.integer(x$screening_status == 'not_started'),
  screening_in_progress = as.integer(x$screening_status == 'in_progress'),
  screening_complete = as.integer(x$screening_status == 'screened'))
out <- aggregate(metrics, by = key, FUN = sum)
out <- out[order(out$organization, out$source_region), ]
candidate_rows <- which(!is.na(x$candidate_unit_id) & nzchar(x$candidate_unit_id))
candidate_groups <- split(candidate_rows, x$candidate_unit_id[candidate_rows])
candidate_status <- do.call(rbind, lapply(names(candidate_groups), function(candidate_id) {
  rows <- candidate_groups[[candidate_id]]
  match_status <- unique(x$match_status[rows])
  eligibility <- unique(x$eligibility[rows])
  data.frame(
    candidate_unit_id = candidate_id,
    match_status = if (length(match_status) == 1L) match_status else 'mixed',
    eligibility = if (length(eligibility) == 1L) eligibility else 'mixed',
    stringsAsFactors = FALSE
  )
}))
out$matched_units <- 0L
out$crosswalked_candidate_units <- 0L
out$identity_unlinked_rows <- 0L
out$eligible_new_units <- 0L
out$ineligible_new_units <- 0L
out$unresolved_new_units <- 0L
out$mixed_new_units <- 0L
out$other_candidate_units <- 0L
for (i in seq_len(nrow(out))) {
  rows <- x$organization == out$organization[i] & region == out$source_region[i]
  matched_ids <- unique(x$matched_stock_id[rows & !is.na(x$matched_stock_id) & nzchar(x$matched_stock_id)])
  candidate_ids <- unique(x$candidate_unit_id[rows & !is.na(x$candidate_unit_id) & nzchar(x$candidate_unit_id)])
  candidate_state <- candidate_status[match(candidate_ids, candidate_status$candidate_unit_id), , drop = FALSE]
  linked <- (!is.na(x$matched_stock_id) & nzchar(x$matched_stock_id)) |
    (!is.na(x$candidate_unit_id) & nzchar(x$candidate_unit_id))
  out$matched_units[i] <- length(matched_ids)
  out$crosswalked_candidate_units[i] <- length(candidate_ids)
  out$identity_unlinked_rows[i] <- sum(rows & !linked)
  is_new <- candidate_state$match_status == 'new'
  out$eligible_new_units[i] <- sum(is_new & candidate_state$eligibility == 'eligible')
  out$ineligible_new_units[i] <- sum(is_new & candidate_state$eligibility == 'ineligible')
  out$unresolved_new_units[i] <- sum(is_new & candidate_state$eligibility == 'unresolved')
  out$mixed_new_units[i] <- sum(is_new & candidate_state$eligibility == 'mixed')
  out$other_candidate_units[i] <- sum(!is_new)
}
stopifnot(sum(out$inventory_rows) == nrow(x),
  all(out$inventory_rows == out$matched + out$new + out$ambiguous + out$identity_unreviewed),
  all(out$inventory_rows == out$eligible + out$excluded + out$eligibility_unresolved),
  all(out$inventory_rows == out$screening_not_started + out$screening_in_progress + out$screening_complete),
  all(out$crosswalked_candidate_units == out$eligible_new_units + out$ineligible_new_units +
    out$unresolved_new_units + out$mixed_new_units + out$other_candidate_units))
write.csv(out, file.path(root, 'discovery', 'inventory_progress.csv'), row.names = FALSE, na = '')
print(aggregate(out[3:ncol(out)], list(organization = out$organization), sum), row.names = FALSE)
