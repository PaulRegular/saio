# Reconcile inventory labels with previously reviewed official assessment units.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = 'NA')
map <- data.frame(candidate = c('NOAA:10014', 'NOAA:10026', 'NOAA:10031', 'NOAA:10191', 'NOAA:11050', 'NOAA:12746'),
  stock = c('nefsc_witch_flounder_unit', 'afsc_alaska_plaice_bsai', 'afsc_yellowfin_sole_ebs',
    'nefsc_summer_flounder', 'afsc_northern_rock_sole_ebs', 'afsc_cod_ebs'),
  review = c('nefsc_witch_flounder_unit.md', 'afsc_alaska_plaice_bsai.md', 'afsc_yellowfin_sole_ebs.md',
    'ck_nefsc_garmiii_dentatus_ma.md', 'afsc_northern_rock_sole_ebs.md', 'afsc_cod_ebs.md'), stringsAsFactors = FALSE)
ci <- match(map$candidate, x$candidate_id)
si <- match(map$stock, stocks$stock_id)
if (anyNA(ci) || anyNA(si) || anyDuplicated(ci) ||
    any(tolower(x$scientific_name[ci]) != tolower(stocks$scientific_name[si])) ||
    any(!file.exists(file.path(root, 'source_reviews', map$review)))) stop('Identity or source-review mismatch.', call. = FALSE)
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
changed <- 0L
for (j in seq_along(ci)) {
  i <- ci[j]
  if (x$match_status[i] != 'unreviewed') next
  x$matched_stock_id[i] <- map$stock[j]
  x$match_status[i] <- 'matched'
  x$review_date[i] <- as.character(Sys.Date())
  x$decision_reason[i] <- paste0('Inventory unit matches the existing official stock; see source_reviews/', map$review[j], '. Current-run eligibility remains to be screened.')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  changed <- changed + 1L
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Reconciled', changed, 'NOAA stock identities.\n')
