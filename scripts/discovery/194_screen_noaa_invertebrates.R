# Screen explicitly identified non-finfish in the NOAA inventory snapshot.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
species <- c('Farfantepenaeus aztecus', 'Farfantepenaeus duorarum',
  'Litopenaeus setiferus', 'Enteroctopus dofleini', 'Placopecten magellanicus',
  'Spisula solidissima', 'Loligo pealeii', 'Illex illecebrosus',
  'Pleoticus robustus', 'Sicyonia brevirostris', 'Paralithodes camtschaticus',
  'Paralithodes platypus', 'Lithodes aequispinus', 'Chionoecetes opilio',
  'Chionoecetes bairdi', 'Chaceon quinquedens', 'Panulirus argus',
  'Patinopecten caurinus', 'Ranina ranina')
complexes <- c('NOAA:10977', 'NOAA:11449')
i <- which(x$organization == 'NOAA' & x$screening_status == 'not_started' &
  (x$scientific_name %in% species | (x$candidate_id %in% complexes &
    grepl('Squid Complex', x$stock_name, fixed = TRUE))))
if (!length(i)) { cat('No new NOAA invertebrate exclusions.\n'); quit(save = 'no', status = 0L) }
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  x$screening_status[j] <- 'screened'
  x$eligibility[j] <- 'ineligible'
  x$review_date[j] <- as.character(Sys.Date())
  x$decision_reason[j] <- 'NOAA inventory identifies an invertebrate; outside the initial marine-finfish discovery scope.'
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Excluded', length(i), 'NOAA invertebrate inventory entries.\n')
