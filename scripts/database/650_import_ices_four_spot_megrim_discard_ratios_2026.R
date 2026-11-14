root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_four_spot_megrim_8c9a_2026")
manifest_path <- file.path(root, "provenance", "ices_four_spot_megrim_8c9a_2026", "sources.csv")
register_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_33_2026.csv")
stock_id <- "ices_four_spot_megrim_8c9a"
assessment_id <- paste0(stock_id, "_2026")
candidate_id <- "ICES:ldb.27.8c9a"
report_url <- "https://doi.org/10.17895/ices.pub.32790321.v2"
write_requested <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")
dry_run <- !write_requested || identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- tolower(sub("[[:space:]].*$", "", result))
  } else {
    stop("A SHA-256 utility is required to verify the ICES source cache.", call. = FALSE)
  }
  if (length(hashes) != 1L || !grepl("^[[:xdigit:]]{64}$", hashes))
    stop("Could not calculate SHA-256 for ", basename(path), call. = FALSE)
  hashes
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
source_files <- c("WGBIE_2026_four_spot_megrim_8c9a.pdf",
  "WGBIE_2026_four_spot_megrim_8c9a.txt")
manifest <- manifest[match(source_files, manifest$file), , drop = FALSE]
source_paths <- file.path(cache, manifest$file)
if (anyNA(manifest$file) || any(!file.exists(source_paths)) ||
    any(file.info(source_paths)$size != manifest$bytes) ||
    !identical(tolower(manifest$sha256), unname(vapply(source_paths, sha256_file, character(1L)))))
  stop("The WGBIE 2026 report cache does not match its provenance manifest.", call. = FALSE)

report_lines <- readLines(file.path(cache, "WGBIE_2026_four_spot_megrim_8c9a.txt"),
  warn = FALSE, encoding = "UTF-8")
tokenize <- function(x) {
  tokens <- strsplit(trimws(x), "\\s+", perl = TRUE)[[1L]]
  if (identical(tokens, "")) character() else tokens
}
year_tokens <- function(x) {
  tokens <- tokenize(x)
  years <- sub("\\*$", "", tokens[grepl("^(19|20)[0-9]{2}\\*?$", tokens)])
  as.integer(years)
}
table_start <- grep("Table. 6.4.2a.", report_lines, fixed = TRUE)
table_end <- grep("Table. 6.4.2b.", report_lines, fixed = TRUE)
table_end <- table_end[table_end > table_start[1L]][1L]
if (length(table_start) != 1L || is.na(table_end))
  stop("Could not uniquely locate WGBIE Table 6.4.2a.", call. = FALSE)
table_lines <- report_lines[seq.int(table_start + 1L, table_end - 1L)]
expected_starts <- c(1994L, 2008L, 2017L)
header_rows <- grep("^\\s*Year\\s+(1994|2008|2017)\\b", table_lines, perl = TRUE)
if (length(header_rows) != length(expected_starts) ||
    !identical(vapply(header_rows, function(i) year_tokens(table_lines[i])[1L], integer(1L)),
      expected_starts))
  stop("Could not locate all three year blocks in WGBIE Table 6.4.2a.", call. = FALSE)

parse_ratio_row <- function(lines, label, expected_n) {
  pattern <- paste0("^\\s*", label, "(?:\\s+|$)")
  found <- which(grepl(pattern, lines, perl = TRUE))
  if (length(found) != 1L) stop("Could not uniquely locate the ", label, " row.", call. = FALSE)
  tokens <- tokenize(lines[found])
  label_tokens <- if (label %in% c("Weight Ratio", "Number Ratio")) 2L else 1L
  values <- suppressWarnings(as.numeric(gsub(",", "", tokens[-seq_len(label_tokens)], fixed = TRUE)))
  if (anyNA(values) || length(values) > expected_n)
    stop("Unexpected values in the Table 6.4.2a ", label, " row.", call. = FALSE)
  values
}

blocks <- list()
for (i in seq_along(header_rows)) {
  first <- header_rows[i]
  last <- if (i < length(header_rows)) header_rows[i + 1L] - 1L else length(table_lines)
  block <- table_lines[seq.int(first, last)]
  years <- year_tokens(block[1L])
  if (length(years) != 9L) stop("A Table 6.4.2a year block does not contain nine years.", call. = FALSE)
  weight_ratio <- parse_ratio_row(block, "Weight Ratio", length(years))
  cv_percent <- parse_ratio_row(block, "CV", length(years))
  number_ratio <- parse_ratio_row(block, "Number Ratio", length(years))
  if (length(weight_ratio) != length(years) || length(number_ratio) != length(years))
    stop("A Table 6.4.2a ratio row does not match its year header.", call. = FALSE)
  cv <- rep(NA_real_, length(years))
  cv[seq_along(cv_percent)] <- cv_percent
  blocks[[i]] <- data.frame(year = years, weight_ratio = weight_ratio,
    cv_percent = cv, number_ratio = number_ratio, stringsAsFactors = FALSE)
}
ratios <- do.call(rbind, blocks)
ratios <- ratios[order(ratios$year), , drop = FALSE]
expected_years <- c(1994L, 1997L, 1999L, 2000L, 2003:2018, 2019:2025)
if (nrow(ratios) != 27L || !identical(as.integer(ratios$year), expected_years) ||
    any(!is.finite(ratios$weight_ratio)) || any(!is.finite(ratios$number_ratio)) ||
    sum(is.finite(ratios$cv_percent)) != 19L ||
    !all(is.na(ratios$cv_percent[ratios$year >= 2018L])) ||
    ratios$weight_ratio[ratios$year == 1994L] != 0.30 ||
    ratios$number_ratio[ratios$year == 1994L] != 0.50 ||
    ratios$weight_ratio[ratios$year == 2025L] != 0.05 ||
    ratios$number_ratio[ratios$year == 2025L] != 0.10)
  stop("Table 6.4.2a year coverage, missing CVs, or checked values failed validation.", call. = FALSE)

input_columns <- names(read.csv(file.path(database, "inputs.csv"), nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
blank_rows <- function(n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_columns)),
    stringsAsFactors = FALSE, check.names = FALSE)
  names(out) <- input_columns
  out$assessment_id <- assessment_id
  out
}
number_text <- function(x) {
  out <- rep("", length(x))
  present <- !is.na(x)
  out[present] <- format(x[present], scientific = FALSE, trim = TRUE, digits = 15L)
  out
}
make_input <- function(measure, basis, value, unit, transformation, notes) {
  out <- blank_rows(length(value))
  out$type <- "catch"
  out$measure <- measure
  out$basis <- basis
  out$fleet <- "Spanish onboard sampling"
  out$region <- "ICES divisions 8.c and 9.a"
  out$season <- "annual"
  out$year <- ratios$year
  out$year_basis <- "calendar_year"
  out$value <- number_text(value)
  out$unit <- unit
  out$source_type <- "official_document"
  out$source_reference <- paste0(report_url, "; WGBIE 2026, Table 6.4.2a")
  out$transformation <- transformation
  out$notes <- notes
  out
}
source_note <- paste(
  "Spanish onboard-sampling discard-to-total-catch ratio reported in Table 6.4.2a.",
  "This is supporting discard-estimation data, not an additional catch observation or model fleet.",
  "The table notes all discard data were revised in WG2011 and marks 2011* as revised in WG2013."
)
cv_rows <- make_input("discard_fraction_cv", "relative_scale", ratios$cv_percent / 100,
    "ratio", "Source CV percentages divided by 100 to store the dimensionless CV as a ratio.",
    paste(source_note, "The CV row follows Weight Ratio in the source table; blank cells remain missing."))
inputs <- rbind(
  make_input("discard_fraction", "proportion_biomass", ratios$weight_ratio,
    "proportion", "", paste(source_note, "Basis is weight.")),
  cv_rows,
  make_input("discard_fraction", "proportion_numbers", ratios$number_ratio,
    "proportion", "", paste(source_note, "Basis is numbers; no CV is reported for this row."))
)
if (nrow(inputs) != 81L || sum(inputs$measure == "discard_fraction_cv") != 27L ||
    sum(!nzchar(inputs$value[inputs$measure == "discard_fraction_cv"])) != 8L)
  stop("Unexpected number of Table 6.4.2a input rows.", call. = FALSE)

read_assessment_rows <- function(path) {
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  prefix <- paste0('"', assessment_id, '",')
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character()
  else if (status != 0L) stop("Could not read existing assessment rows from ", path, call. = FALSE)
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(read.csv(text = header, nrows = 0L,
    stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"))
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}
normalize <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
key_columns <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
  "sex", "region", "season", "year", "year_basis", "age", "observation_id", "partition")
row_key <- function(x) do.call(paste, c(lapply(x[key_columns], normalize), sep = "\r"))
existing_inputs <- read_assessment_rows(file.path(database, "inputs.csv"))
new_keys <- row_key(inputs)
existing_keys <- row_key(existing_inputs)
if (anyDuplicated(new_keys) || anyDuplicated(existing_keys[existing_keys %in% new_keys]))
  stop("Duplicate Table 6.4.2a input keys were found.", call. = FALSE)
matched <- match(new_keys, existing_keys)
for (i in which(!is.na(matched))) {
  old <- existing_inputs[matched[i], names(inputs), drop = FALSE]
  if (!identical(normalize(unlist(old[1L, ], use.names = FALSE)),
      normalize(unlist(inputs[i, ], use.names = FALSE))))
    stop("An existing Table 6.4.2a record differs from the source for key ", new_keys[i], call. = FALSE)
}
missing_inputs <- inputs[is.na(matched), , drop = FALSE]

stocks <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (sum(stocks$stock_id == stock_id) != 1L ||
    sum(assessments$assessment_id == assessment_id & assessments$stock_id == stock_id) != 1L)
  stop("The current four-spot megrim stock and assessment must already exist.", call. = FALSE)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L || register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "ldb.27.8c9a" ||
    register$eligibility[candidate_row] != "eligible" ||
    !register$import_status[candidate_row] %in% c("partial", "imported") ||
    !register$matched_stock_id[candidate_row] %in% c(NA, "", stock_id))
  stop("The four-spot megrim candidate does not uniquely match the canonical stock.", call. = FALSE)
register$matched_stock_id[candidate_row] <- stock_id
register$match_status[candidate_row] <- "matched"
register$catch_age_evidence[candidate_row] <- paste(
  "WGBIE 2026 Table 6.4.2a provides Spanish onboard-sampling discard-to-total-catch ratios by weight and number for 27 years in 1994-2025, with weight-ratio CVs reported through 2017.",
  "Table 6.4.2b provides Spanish-trawler discard numbers-at-age; complete fleet catch-at-age remains unavailable."
)
register$review_date[candidate_row] <- "2026-11-14"
register$notes[candidate_row] <- paste(
  "Partial source import includes WGBIE 2026 Tables 6.4.2a and 6.4.2b, Table 6.4.5, the 2026 Stock Annex, and ICES SAG key 26018.",
  "The Table 6.4.2a CV was converted from percent to ratio; eight blank CV cells remain missing, not zero.",
  "The report's discard table age labels 0-7 differ from the Annex's 0-6+ model bins; see discovery/source_reviews/ices_four_spot_megrim_8c9a_2026.md."
)

inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (!inventory$matched_stock_id[inventory_row] %in% c(NA, "", stock_id) ||
    !inventory$match_status[inventory_row] %in% c("new", "matched"))
  stop("The four-spot megrim inventory crosswalk conflicts with the stock record.", call. = FALSE)
inventory$matched_stock_id[inventory_row] <- stock_id
inventory$match_status[inventory_row] <- "matched"
inventory$import_status[inventory_row] <- "partial"

selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L || selected$candidate_unit_id[selected_row] != stock_id)
  stop("The four-spot megrim selected-batch record is missing or inconsistent.", call. = FALSE)
selected$selection_basis[selected_row] <- paste(
  "Partial import includes Spanish discard-to-total-catch ratios by weight and number, age-specific discard numbers, aggregate catches, fixed biology, and official aggregate outputs with 90% intervals.",
  "Full fleet catch-at-age and survey age-index matrices remain unavailable."
)
selected$curation_status[selected_row] <- "partial_source_import"

append_rows <- function(path, data) {
  if (!nrow(data)) return(invisible(NULL))
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  if (!identical(names(data), columns)) stop("Column mismatch in ", path, call. = FALSE)
  if (file.info(path)$size > 0L) {
    con <- file(path, open = "rb")
    seek(con, where = -1L, origin = "end")
    last <- readBin(con, "raw", n = 1L)
    close(con)
    if (!identical(last, as.raw(10L))) cat("\n", file = path, append = TRUE)
  }
  write.table(data, file = path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", append = TRUE, qmethod = "double", eol = "\n")
}

if (dry_run) {
  cat("Validated WGBIE Table 6.4.2a: ", nrow(inputs), " source rows; ",
    nrow(missing_inputs), " rows to append; candidate and inventory crosswalks reconciled.\n",
    sep = "")
} else {
  append_rows(file.path(database, "inputs.csv"), missing_inputs)
  replace_candidate_register_row(register_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
  replace_csv_register_row(selected_path, selected_row,
    selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported ", nrow(missing_inputs),
    " WGBIE Table 6.4.2a rows and reconciled the four-spot megrim candidate crosswalk.\n",
    sep = "")
}
