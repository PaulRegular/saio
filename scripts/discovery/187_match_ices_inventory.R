# Match reviewed ICES stock codes to existing stock units; this does not screen data.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
candidates <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = 'NA')
code <- tolower(trimws(stocks$authority_stock_id))
ices <- which(candidates$organization == 'ICES' & !is.na(candidates$official_stock_id))
matched <- 0L
changed <- integer()
for (i in ices) {
  key <- tolower(trimws(candidates$official_stock_id[i]))
  hit <- which(!is.na(code) & code == key)
  if (length(hit) != 1L) next
  a <- tolower(trimws(candidates$scientific_name[i]))
  b <- tolower(trimws(stocks$scientific_name[hit]))
  same_species <- !is.na(a) && !is.na(b) && (a == b || (a == 'ammodytes' && b == 'ammodytes spp.'))
  if (!same_species) next
  if (!is.na(candidates$match_status[i]) && candidates$match_status[i] != 'unreviewed') next
  candidates$matched_stock_id[i] <- stocks$stock_id[hit]
  candidates$match_status[i] <- 'matched'
  candidates$decision_reason[i] <- paste('Existing unit: matching official ICES stock code and species;',
    'area, latest-run and source-data screening remain to be checked.')
  candidates$review_date[i] <- '2026-10-28'
  matched <- matched + 1L
  changed <- c(changed, i)
}
if (matched == 0L) { cat('No new matches.\n'); quit(save = 'no', status = 0L) }
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (i in changed) {
  write.csv(candidates[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Recorded', matched, 'existing ICES stock matches.\n')