root <- "."
database <- file.path(root, "database")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")

source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

selected <- read_csv(selected_path)
candidates <- read_csv(candidate_path)
inventory <- read_csv(inventory_path)
stocks <- read_csv(file.path(database, "stocks.csv"))
assessments <- read_csv(file.path(database, "assessments.csv"))

if (nrow(selected) != 20L || anyDuplicated(selected$candidate_unit_id))
  stop("The selected batch must contain 20 distinct candidate units.", call. = FALSE)

candidate_rows <- match(selected$candidate_unit_id, candidates$candidate_unit_id)
if (anyNA(candidate_rows))
  stop("A selected unit is missing from the candidate register.", call. = FALSE)

stock_ids <- candidates$matched_stock_id[candidate_rows]
for (i in seq_along(stock_ids)) {
  if (is.na(stock_ids[i]) || !nzchar(stock_ids[i])) {
    stock_ids[i] <- selected$candidate_unit_id[i]
  }
  stock <- stocks[stocks$stock_id == stock_ids[i], , drop = FALSE]
  if (nrow(stock) != 1L ||
      stock$scientific_name != candidates$scientific_name[candidate_rows[i]] ||
      !any(assessments$stock_id == stock_ids[i]))
    stop("Could not verify a unique canonical stock and assessment for ",
      selected$candidate_unit_id[i], call. = FALSE)
}
if (anyDuplicated(stock_ids))
  stop("Selected units resolve to duplicate canonical stocks.", call. = FALSE)

inventory_rows <- vapply(seq_along(stock_ids), function(i) {
  matches <- which(inventory$candidate_unit_id == selected$candidate_unit_id[i] |
    inventory$unit_key == paste0("candidate:", selected$candidate_unit_id[i]) |
    inventory$matched_stock_id == stock_ids[i] |
    inventory$unit_key == paste0("stock:", stock_ids[i]))
  if (length(matches) != 1L)
    stop("Could not identify one inventory row for ",
      selected$candidate_unit_id[i], call. = FALSE)
  matches
}, integer(1))

replace_inventory_row <- function(path, row_index, row, unit_key) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  if (record_index < 2L || record_index > length(bounds$start))
    stop("Inventory row index is out of range.", call. = FALSE)
  old_record <- rawToChar(bytes[bounds$start[record_index]:bounds$end[record_index]])
  if (!startsWith(old_record, paste0('"', unit_key, '"')))
    stop("Inventory row identity does not match ", unit_key, call. = FALSE)

  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
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
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement,
      if (has_carriage_return) as.raw(c(13L, 10L)) else as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  original <- bytes
  writeBin(c(before, replacement, after), path)
  updated <- tryCatch(read_csv(path), error = function(e) NULL)
  if (is.null(updated) || nrow(updated) != length(bounds$start) - 1L ||
      updated$unit_key[row_index] != unit_key ||
      updated$matched_stock_id[row_index] != row$matched_stock_id)
    {
      writeBin(original, path)
      stop("Updated inventory row failed its identity check.", call. = FALSE)
    }
}

for (i in seq_len(nrow(selected))) {
  candidate_index <- candidate_rows[i]
  inventory_index <- inventory_rows[i]
  if (is.na(candidates$matched_stock_id[candidate_index]) ||
      candidates$matched_stock_id[candidate_index] != stock_ids[i]) {
    row <- candidates[candidate_index, , drop = FALSE]
    row$matched_stock_id <- stock_ids[i]
    replace_candidate_register_row(candidate_path, candidate_index, row,
      candidates$candidate_id[candidate_index])
  }
  if (is.na(inventory$matched_stock_id[inventory_index]) ||
      inventory$matched_stock_id[inventory_index] != stock_ids[i] ||
      is.na(inventory$candidate_unit_id[inventory_index]) ||
      inventory$candidate_unit_id[inventory_index] != selected$candidate_unit_id[i]) {
    row <- inventory[inventory_index, , drop = FALSE]
    row$matched_stock_id <- stock_ids[i]
    row$candidate_unit_id <- selected$candidate_unit_id[i]
    replace_inventory_row(inventory_path, inventory_index, row,
      inventory$unit_key[inventory_index])
  }
}

cat("Reconciled ", length(stock_ids),
  " selected candidate units to distinct canonical stock records.\n", sep = "")
