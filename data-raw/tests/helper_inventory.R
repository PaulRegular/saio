check_inventory_accounting <- function(register, progress, units) {
  metrics <- list(
    matched = c("match_status", "matched"), new = c("match_status", "new"),
    ambiguous = c("match_status", "ambiguous"),
    identity_unreviewed = c("match_status", "unreviewed"),
    eligible = c("eligibility", "eligible"), excluded = c("eligibility", "ineligible"),
    eligibility_unresolved = c("eligibility", "unresolved"),
    screening_not_started = c("screening_status", "not_started"),
    screening_in_progress = c("screening_status", "in_progress"),
    screening_complete = c("screening_status", "screened")
  )
  stopifnot(!anyDuplicated(register$candidate_id), !anyDuplicated(units$unit_key),
    sum(progress$inventory_rows) == nrow(register),
    all(progress$inventory_rows == progress$matched + progress$new +
      progress$ambiguous + progress$identity_unreviewed),
    all(progress$inventory_rows == progress$eligible + progress$excluded +
      progress$eligibility_unresolved),
    all(progress$inventory_rows == progress$screening_not_started +
      progress$screening_in_progress + progress$screening_complete))
  for (organization in unique(register$organization)) {
    rows <- register[register$organization == organization, , drop = FALSE]
    summary <- progress[progress$organization == organization, , drop = FALSE]
    stopifnot(sum(summary$inventory_rows) == nrow(rows),
      sum(summary$eligible_new) == sum(rows$match_status == "new" & rows$eligibility == "eligible"))
    for (metric in names(metrics)) {
      specification <- metrics[[metric]]
      stopifnot(sum(summary[[metric]]) == sum(rows[[specification[1L]]] == specification[2L]))
    }
  }
  linked <- (!is.na(register$matched_stock_id) & nzchar(register$matched_stock_id)) |
    (!is.na(register$candidate_unit_id) & nzchar(register$candidate_unit_id))
  ids <- strsplit(units$candidate_ids, " | ", fixed = TRUE)
  all_ids <- unlist(ids, use.names = FALSE)
  stopifnot(!anyDuplicated(all_ids), setequal(all_ids, register$candidate_id[linked]),
    identical(as.integer(lengths(ids)), as.integer(units$inventory_entries)))
  for (i in seq_len(nrow(units))) {
    rows <- register[match(ids[[i]], register$candidate_id), , drop = FALSE]
    for (field in c("match_status", "eligibility", "screening_status", "import_status")) {
      values <- unique(rows[[field]])
      expected <- if (length(values) == 1L) values else "mixed"
      stopifnot(identical(as.character(units[[field]][i]), as.character(expected)))
    }
  }
  invisible(TRUE)
}
