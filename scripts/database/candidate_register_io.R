csv_record_bounds <- function(bytes) {
  if (!length(bytes)) stop('Candidate register is empty.', call. = FALSE)

  quote <- as.raw(34L)
  lf <- as.raw(10L)
  cr <- as.raw(13L)
  tab <- as.raw(9L)
  space <- as.raw(32L)
  starts <- integer()
  ends <- integer()
  start <- 1L
  in_quotes <- FALSE
  i <- 1L

  while (i <= length(bytes)) {
    if (bytes[i] == quote) {
      if (in_quotes && i < length(bytes) && bytes[i + 1L] == quote) {
        i <- i + 2L
      } else {
        in_quotes <- !in_quotes
        i <- i + 1L
      }
    } else if (bytes[i] == lf && !in_quotes) {
      end <- i - 1L
      while (end >= start && bytes[end] == cr) end <- end - 1L
      record <- if (end >= start) bytes[start:end] else raw(0L)
      if (length(record) && any(!(record %in% c(space, tab, cr)))) {
        starts <- c(starts, start)
        ends <- c(ends, end)
      }
      start <- i + 1L
      i <- i + 1L
    } else {
      i <- i + 1L
    }
  }

  if (in_quotes) stop('Candidate register has an unmatched quote.', call. = FALSE)
  if (start <= length(bytes)) {
    record <- bytes[start:length(bytes)]
    if (any(!(record %in% c(space, tab, cr)))) {
      starts <- c(starts, start)
      ends <- c(ends, length(bytes))
    }
  }
  list(start = starts, end = ends)
}

replace_candidate_register_row <- function(path, row_index, row, candidate_id) {
  if (nrow(row) != 1L) stop('Expected one candidate register row.', call. = FALSE)
  if (length(candidate_id) != 1L || is.na(candidate_id))
    stop('Expected one candidate identifier.', call. = FALSE)

  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (length(record_index) != 1L || is.na(record_index) ||
      record_index < 2L || record_index > length(bounds$start))
    stop('Candidate register row index is out of range.', call. = FALSE)

  old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
  if (!startsWith(old_record, paste0('"', candidate_id, '"')))
    stop('Candidate register row identity does not match ', candidate_id, '.', call. = FALSE)

  temporary <- tempfile(fileext = '.csv')
  on.exit(unlink(temporary), add = TRUE)
  write.table(row, temporary, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '', qmethod = 'double', eol = '\n')
  replacement <- readBin(temporary, 'raw', n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L))
    replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L))
    replacement <- replacement[-length(replacement)]

  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  has_carriage_return <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_carriage_return <- TRUE
    next_byte <- next_byte + 1L
  }
  line_ending <- raw(0L)
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    line_ending <- c(if (has_carriage_return) as.raw(13L) else raw(0L), as.raw(10L))
    last <- next_byte
    replacement <- c(replacement, line_ending)
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)

  updated <- tryCatch(read.csv(path, stringsAsFactors = FALSE,
    na.strings = c('', 'NA'), check.names = FALSE), error = function(e) NULL)
  valid <- !is.null(updated) && nrow(updated) == length(bounds$start) - 1L &&
    sum(updated$candidate_id == candidate_id, na.rm = TRUE) == 1L &&
    identical(as.character(updated$candidate_id[as.integer(row_index)]), candidate_id)
  if (!valid) {
    writeBin(original, path)
    stop('Updated candidate register failed its row-count or identity check.', call. = FALSE)
  }
  invisible(NULL)
}

remove_candidate_register_row <- function(path, row_index, candidate_id) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (length(record_index) != 1L || is.na(record_index) ||
      record_index < 2L || record_index > length(bounds$start))
    stop('Candidate register row index is out of range.', call. = FALSE)

  old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
  if (!startsWith(old_record, paste0('"', candidate_id, '"')))
    stop('Candidate register row identity does not match ', candidate_id, '.', call. = FALSE)

  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] %in% as.raw(c(13L, 10L))) {
    last <- next_byte
    next_byte <- next_byte + 1L
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, after), path)

  updated <- tryCatch(read.csv(path, stringsAsFactors = FALSE,
    na.strings = c('', 'NA'), check.names = FALSE), error = function(e) NULL)
  valid <- !is.null(updated) && nrow(updated) == length(bounds$start) - 2L &&
    !any(updated$candidate_id == candidate_id, na.rm = TRUE)
  if (!valid) {
    writeBin(original, path)
    stop('Updated candidate register failed its row-count or identity check.', call. = FALSE)
  }
  invisible(NULL)
}
