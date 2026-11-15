read_candidate_register <- function(root = ".") {
  utils::read.csv(file.path(root, "discovery", "candidates.csv"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

candidate_source_regions <- function(x,
    stocksmart_path = file.path("source_cache", "shared", "noaa_stocksmart",
      "stock_assessment_summary.rda")) {
  region <- rep(NA_character_, nrow(x))
  if (file.exists(stocksmart_path)) {
    cache <- new.env(parent = emptyenv())
    load(stocksmart_path, envir = cache)
    noaa <- cache$stock_assessment_summary
    noaa <- noaa[order(noaa$stock_id, -as.numeric(noaa$assessment_year),
      noaa$assessment_id, na.last = TRUE), ]
    noaa <- noaa[!duplicated(noaa$stock_id), ]
    is_noaa <- which(x$organization == 'NOAA')
    region[is_noaa] <- noaa$science_center[
      match(x$official_stock_id[is_noaa], as.character(noaa$stock_id))]
  }
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
  region
}

candidate_units <- function(x = read_candidate_register(), region = candidate_source_regions(x)) {
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

  stopifnot(!anyDuplicated(units$unit_key),
    sum(units$inventory_entries) == sum(linked),
    all(units$match_status %in% c('matched', 'new', 'ambiguous', 'unreviewed', 'mixed')),
    all(units$eligibility %in% c('eligible', 'ineligible', 'unresolved', 'mixed')),
    all(units$screening_status %in% c('screened', 'not_started', 'in_progress', 'mixed')))
  units
}

candidate_progress <- function(x = read_candidate_register(), region = candidate_source_regions(x)) {
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
  out
}
