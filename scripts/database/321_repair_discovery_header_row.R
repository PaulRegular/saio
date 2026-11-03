root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
header_rows <- which(vapply(seq_len(nrow(register)), function(i) {
  identical(as.character(unlist(register[i, , drop = FALSE], use.names = FALSE)), names(register))
}, logical(1L)))
if (length(header_rows) == 0L) {
  cat('Discovery register contains no duplicate header rows.\n')
} else {
  if (length(header_rows) != 1L) stop('Expected at most one duplicate header row.', call. = FALSE)
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- header_rows + 1L
  if (length(line_feeds) < physical_line) stop('Could not locate duplicate header row.', call. = FALSE)
  first <- if (physical_line == 1L) 1L else line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, after), path)
  cat('Removed one duplicate header row from the discovery register.\n')
}
register <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(register$candidate_id == 'candidate_id'),
  all(register$organization %in% c('NOAA', 'ICES', 'DFO')))
