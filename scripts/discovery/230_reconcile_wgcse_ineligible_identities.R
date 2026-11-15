path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

distinct_units <- c(
  'ICES:ple.27.7h-k', 'ICES:had.27.7a', 'ICES:cod.27.6b',
  'ICES:ple.27.7bc', 'ICES:sol.27.7bc'
)
unresolved_species <- c('ICES:lez.27.4a6a', 'ICES:lez.27.6b')
ids <- c(distinct_units, unresolved_species)
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected WGCSE candidates were not found.', call. = FALSE)
if (any(x$organization[i] != 'ICES') ||
    any(x$screening_status[i] != 'screened') ||
    any(x$eligibility[i] != 'ineligible') ||
    any(!is.na(x$matched_stock_id[i]))) {
  stop('Preserve the existing screening decision and absence of a canonical match.', call. = FALSE)
}

new_i <- match(distinct_units, x$candidate_id)
if (any(!x$match_status[new_i] %in% c('unreviewed', 'new'))) {
  stop('Unexpected identity status for a distinct current ICES unit.', call. = FALSE)
}
x$match_status[new_i] <- 'new'
x$notes[new_i] <- paste0(
  'Identity reviewed against the canonical database: the official ICES stock code and area ',
  'identify a distinct current unit; no canonical match was found. Provisional new identity ',
  'pending cross-organization reconciliation. Current-method screening remains ineligible.'
)
new_prefix <- paste0(
  'Provisional distinct current stock unit based on its unique ICES code and assessment area; ',
  'cross-organization reconciliation remains. '
)
needs_new_prefix <- !startsWith(x$decision_reason[new_i], new_prefix)
if (any(needs_new_prefix)) {
  j <- new_i[needs_new_prefix]
  x$decision_reason[j] <- paste0(new_prefix, x$decision_reason[j])
}

ambiguous_i <- match(unresolved_species, x$candidate_id)
if (any(!x$match_status[ambiguous_i] %in% c('unreviewed', 'ambiguous'))) {
  stop('Unexpected identity status for genus-only ICES entries.', call. = FALSE)
}
x$match_status[ambiguous_i] <- 'ambiguous'
x$notes[ambiguous_i] <- paste0(
  'Identity remains ambiguous because the ICES inventory reports only Lepidorhombus spp.; ',
  'the exact species and canonical stock match cannot be verified from this source. ',
  'Current-method screening remains ineligible.'
)
ambiguous_prefix <- paste0(
  'Identity is unresolved at species level: the inventory reports Lepidorhombus spp. only. ',
  'Do not create a canonical stock record without species-level evidence. '
)
needs_ambiguous_prefix <- !startsWith(x$decision_reason[ambiguous_i], ambiguous_prefix)
if (any(needs_ambiguous_prefix)) {
  j <- ambiguous_i[needs_ambiguous_prefix]
  x$decision_reason[j] <- paste0(ambiguous_prefix, x$decision_reason[j])
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Reconciled five distinct WGCSE stock codes and retained two genus-only megrim identities as ambiguous.\n')
