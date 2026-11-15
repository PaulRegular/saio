# Reconcile DFO inventory entries with assessed units and their components.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = 'NA')
map <- data.frame(candidate = c('DFO:Maritimes:Atlantic Cod - NAFO 5Zjm', 'DFO:Pacific:Canary Rockfish',
  'DFO:Pacific:Pacific Hake - Offshore', 'DFO:Pacific:Pacific Ocean Perch - PMFC 3CD-WCVI',
  'DFO:Pacific:Pacific Ocean Perch - PMFC 5ABC-QCS', 'DFO:Pacific:Pacific Ocean Perch - PMFC 5DE-HS/DE/WHG'),
  stock = c('ck_nefsc_trac_cert_morhua_gb', 'dfo_canary_bc', 'joint_hake_coastal',
    'dfo_pop_bc', 'dfo_pop_bc', 'dfo_pop_bc'),
  review = c('ck_nefsc_trac_cert_morhua_gb.md', 'dfo_canary_bc.md', 'joint_hake_coastal.md',
    'dfo_pop_bc.md', 'dfo_pop_bc.md', 'dfo_pop_bc.md'), stringsAsFactors = FALSE)
ci <- match(map$candidate, x$candidate_id)
si <- match(map$stock, stocks$stock_id)
if (anyNA(ci) || anyNA(si) || anyDuplicated(ci) ||
    any(!file.exists(file.path(root, 'source_reviews', map$review)))) stop('Identity or source-review mismatch.', call. = FALSE)
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
changed <- 0L
for (j in seq_along(ci)) {
  i <- ci[j]
  if (x$match_status[i] != 'unreviewed') next
  if (!is.na(x$scientific_name[i]) && nzchar(x$scientific_name[i]) &&
      tolower(x$scientific_name[i]) != tolower(stocks$scientific_name[si[j]])) stop('Species mismatch.', call. = FALSE)
  x$scientific_name[i] <- stocks$scientific_name[si[j]]
  x$matched_stock_id[i] <- map$stock[j]
  x$match_status[i] <- 'matched'
  x$review_date[i] <- as.character(Sys.Date())
  relation <- if (map$stock[j] == 'dfo_pop_bc') 'Three survey entries are areas of one coastwide assessment, not three additional cases. ' else ''
  x$decision_reason[i] <- paste0(relation, 'See source_reviews/', map$review[j], '; current-run eligibility remains to be screened.')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  changed <- changed + 1L
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Reconciled', changed, 'DFO inventory entries.\n')
