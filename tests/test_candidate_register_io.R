source('scripts/database/candidate_register_io.R')

path <- tempfile(fileext = '.csv')
writeLines(c(
  '"candidate_id","notes"',
  '"NOAA:1","first line',
  'second line ""quoted"""',
  '',
  '"NOAA:2","old"',
  '"NOAA:3","unchanged"'
), path, useBytes = TRUE)

register <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(register) == 3L,
  identical(register$candidate_id, c('NOAA:1', 'NOAA:2', 'NOAA:3')))

updated_row <- register[2L, , drop = FALSE]
updated_row$notes <- 'updated'
replace_candidate_register_row(path, 2L, updated_row, 'NOAA:2')

updated <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(updated) == 3L,
  identical(updated$candidate_id, c('NOAA:1', 'NOAA:2', 'NOAA:3')),
  identical(updated$notes, c('first line\nsecond line "quoted"', 'updated', 'unchanged')))

updated_row <- updated[2L, , drop = FALSE]
updated_row$notes <- 'updated twice'
replace_candidate_register_row(path, 2L, updated_row, 'NOAA:2')
updated_twice <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
serialized <- rawToChar(readBin(path, 'raw', n = file.info(path)$size))
stopifnot(nrow(updated_twice) == 3L,
  identical(updated_twice$notes[2L], 'updated twice'),
  !grepl('\r\r\n', serialized, fixed = TRUE))

before_mismatch <- readBin(path, 'raw', n = file.info(path)$size)
mismatch_error <- tryCatch({
  replace_candidate_register_row(path, 1L, updated_row, 'NOAA:2')
  FALSE
}, error = function(e) TRUE)
after_mismatch <- readBin(path, 'raw', n = file.info(path)$size)
stopifnot(mismatch_error, identical(before_mismatch, after_mismatch))

remove_candidate_register_row(path, 2L, 'NOAA:2')
after_remove <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(after_remove) == 2L,
  identical(after_remove$candidate_id, c('NOAA:1', 'NOAA:3')),
  identical(after_remove$notes, c('first line\nsecond line "quoted"', 'unchanged')))

remove_candidate_register_row(path, 2L, 'NOAA:3')
after_remove_last <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(after_remove_last) == 1L,
  identical(after_remove_last$candidate_id, 'NOAA:1'),
  identical(after_remove_last$notes, 'first line\nsecond line "quoted"'))

unlink(path)
cat('Candidate register updates preserve quoted newlines, skip blank CSV lines, and remove exact records safely.\n')
