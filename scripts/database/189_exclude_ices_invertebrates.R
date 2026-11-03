# Screen named ICES invertebrates outside the initial marine-finfish scope.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$organization == 'ICES' & x$screening_status == 'not_started' &
  tolower(trimws(x$scientific_name)) %in% c('nephrops norvegicus', 'pandalus borealis'))
if (!length(i)) { cat('No new invertebrate exclusions.\n'); quit(save = 'no', status = 0L) }
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  x$screening_status[j] <- 'screened'
  x$eligibility[j] <- 'ineligible'
  x$review_date[j] <- as.character(Sys.Date())
  x$decision_reason[j] <- 'ICES SID identifies a crustacean species; outside the initial marine-finfish discovery scope.'
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Excluded', length(i), 'ICES invertebrate entries.\n')