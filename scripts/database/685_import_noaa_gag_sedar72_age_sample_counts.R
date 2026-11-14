root <- "."
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
candidate_id <- "NOAA:10348"
source_name <- "sedar72_wp17_compositions_2021.pdf"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest_path <- file.path(root, "provenance/noaa_gag_sedar72_2022/manifest.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")
source_row <- manifest[basename(manifest$file) == source_name, , drop = FALSE]
if (nrow(source_row) != 1L) stop("SEDAR 72 WP-17 source is not uniquely pinned.", call. = FALSE)

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hashes <- tolower(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE
    )))
  } else {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hashes <- tolower(sub("[[:space:]].*$", "", output[1L]))
  }
  if (length(hashes) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hashes
}

pdf_path <- file.path(root, source_row$file)
text_path <- file.path(root, "source_cache/noaa_gag_sedar72_2022/text",
  sub("\\.pdf$", ".txt", source_name, ignore.case = TRUE))
if (!file.exists(pdf_path) || as.character(file.info(pdf_path)$size) != source_row$bytes ||
    !identical(sha256_file(pdf_path), tolower(source_row$sha256))) {
  stop("Cached SEDAR 72 WP-17 PDF does not match its provenance record.", call. = FALSE)
}
if (!file.exists(text_path)) stop("Missing cached WP-17 text extraction: ", text_path,
  call. = FALSE)

lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
table_start <- which(grepl("Table 7: Annual number of age samples", lines, fixed = TRUE))
table_end <- which(grepl("^7[[:space:]]+Figures", lines, perl = TRUE))
table_end <- table_end[table_end > table_start]
if (length(table_start) != 1L || length(table_end) != 1L) {
  stop("Could not isolate SEDAR72-WP-17 Table 7.", call. = FALSE)
}
table_lines <- lines[seq.int(table_start + 1L, table_end - 1L)]
year_lines <- table_lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", table_lines,
  perl = TRUE)]
if (length(year_lines) != 29L) stop("Table 7 must contain 1991-2019.", call. = FALSE)

fleet_codes <- c("VL", "LL", "CB", "PR", "HB")
fleet_names <- c(
  VL = "Commercial vertical line",
  LL = "Commercial longline",
  CB = "Recreational charterboat",
  PR = "Recreational private",
  HB = "Recreational headboat"
)
parse_cell <- function(cell) {
  match <- regmatches(cell, regexec(
    "^([0-9]+|--)[[:space:]]*\\([[:space:]]*([0-9]+|--)[[:space:]]*\\)$",
    trimws(cell), perl = TRUE
  ))[[1L]]
  if (length(match) != 3L) stop("Could not parse Table 7 cell: ", cell, call. = FALSE)
  value <- function(x) if (x == "--") NA_real_ else as.numeric(x)
  c(fish = value(match[2L]), trips = value(match[3L]))
}
parsed <- lapply(year_lines, function(line) {
  year <- as.integer(sub("^[[:space:]]*([0-9]{4}).*$", "\\1", line, perl = TRUE))
  rest <- sub("^[[:space:]]*[0-9]{4}[[:space:]]+", "", line, perl = TRUE)
  spans <- regmatches(rest, gregexpr(
    "([0-9]+|--)[[:space:]]*\\([[:space:]]*([0-9]+|--)[[:space:]]*\\)",
    rest, perl = TRUE
  ))[[1L]]
  if (length(spans) != length(fleet_codes)) {
    stop("Table 7 year has an unexpected number of fleets: ", line, call. = FALSE)
  }
  values <- t(vapply(spans, parse_cell, numeric(2L)))
  data.frame(year = year, fleet_code = fleet_codes,
    fish = values[, "fish"], trips = values[, "trips"],
    stringsAsFactors = FALSE)
})
counts <- do.call(rbind, parsed)
rownames(counts) <- NULL
if (!identical(sort(unique(counts$year)), 1991:2019) || nrow(counts) != 145L ||
    sum(!is.na(counts$fish)) != 144L || sum(!is.na(counts$trips)) != 144L ||
    !all(counts$fish[!is.na(counts$fish)] == floor(counts$fish[!is.na(counts$fish)])) ||
    !all(counts$trips[!is.na(counts$trips)] == floor(counts$trips[!is.na(counts$trips)]))) {
  stop("SEDAR 72 Table 7 counts failed year, row, or integer checks.", call. = FALSE)
}

rows <- list()
for (i in seq_len(nrow(counts))) {
  x <- counts[i, , drop = FALSE]
  for (count_type in c("fish", "trips")) {
    value <- x[[count_type]]
    if (!is.finite(value)) next
    unit <- if (count_type == "fish") "fish" else "trips"
    rows[[length(rows) + 1L]] <- pacific_database_row(
      "inputs", assessment_id = assessment_id, type = "biology",
      measure = "composition_sample_count", basis = "numbers", value = value,
      unit = unit, year = x$year, year_basis = "calendar_year",
      fleet = fleet_names[[x$fleet_code]],
      observation_id = paste0("SEDAR72_WP17_",
        if (count_type == "trips") "Tab7_" else "Table7_",
        x$fleet_code, "_", count_type),
      source_type = "official_table",
      source_reference = "SEDAR72-WP-17, Table 7 (printed pp. 14-15)",
      notes = paste(
        "Annual number of fish aged or trips contributing to the final age-composition estimate.",
        "The source reports fish counts followed by trip counts in parentheses.",
        "These are sampling metadata, not age proportions or effective likelihood sample sizes.",
        "The source notes that ages represented by fewer than 10 fish were excluded."
      )
    )
  }
}
inputs <- do.call(rbind, rows)
rownames(inputs) <- NULL
if (nrow(inputs) != 288L || sum(inputs$unit == "fish") != 144L ||
    sum(inputs$unit == "trips") != 144L || any(!is.finite(inputs$value)) ||
    any(inputs$value < 0) || anyDuplicated(inputs[c("assessment_id", "measure",
      "basis", "year", "fleet", "observation_id")])) {
  stop("SEDAR 72 age-sample count rows failed key or value checks.", call. = FALSE)
}

input_path <- file.path(root, "database/inputs.csv")
prefix <- paste0("\"", assessment_id, "\",\"biology\",\"composition_sample_count\"")
connection <- file(input_path, open = "rt")
on.exit(close(connection), add = TRUE)
existing_lines <- character()
repeat {
  chunk <- readLines(connection, n = 50000L, warn = FALSE)
  if (!length(chunk)) break
  existing_lines <- c(existing_lines, chunk[startsWith(chunk, prefix)])
}
close(connection)
if (length(existing_lines)) {
  header <- readLines(input_path, n = 1L, warn = FALSE)
  existing <- read.csv(text = paste(c(header, existing_lines), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  row_signature <- function(data) {
    values <- lapply(data, function(x) {
      out <- as.character(x)
      out[is.na(x)] <- ""
      out
    })
    do.call(paste, c(values, sep = "\r"))
  }
  if (nrow(existing) != nrow(inputs) ||
      !setequal(row_signature(existing), row_signature(inputs))) {
    stop("Existing Gulf gag sample-count rows differ from the reviewed Table 7 import.",
      call. = FALSE)
  }
}
already_imported <- length(existing_lines) > 0L

cat("Verified SEDAR 72 WP-17 Table 7 age-sample counts.\n")
cat("Rows:", nrow(inputs), "(144 fish counts and 144 trip counts), 1991-2019.\n")
cat("The age-composition vectors themselves remain figure-only.\n")

if (write_mode) {
  if (!already_imported) {
    write.table(inputs, input_path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  }

  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L || candidates$eligibility[candidate_row] != "eligible") {
    stop("Expected one eligible Gulf gag source-curation candidate.", call. = FALSE)
  }
  addition <- paste(
    "SEDAR72-WP-17 Table 7 age-sample counts were imported by fleet and year for 1991-2019:",
    "144 fish-count rows and 144 trip-count rows. These are sampling metadata, not the",
    "figure-only age-composition vectors or effective likelihood sample sizes."
  )
  if (!grepl("SEDAR72-WP-17 Table 7 age-sample counts were imported", candidates$catch_age_evidence[candidate_row], fixed = TRUE)) {
    candidates$catch_age_evidence[candidate_row] <- paste(
      candidates$catch_age_evidence[candidate_row], addition)
    candidates$review_date[candidate_row] <- as.character(Sys.Date())
    replace_candidate_register_row(candidate_path, candidate_row,
      candidates[candidate_row, , drop = FALSE], candidate_id)
  }

  review_path <- file.path(root, "discovery/source_reviews/noaa_gag_sedar72_2022.md")
  review <- readLines(review_path, warn = FALSE, encoding = "UTF-8")
  marker <- "Remaining gaps: numeric age-composition arrays"
  at <- which(grepl(marker, review, fixed = TRUE))
  if (length(at) != 1L) stop("Could not locate the Gulf gag source-gap paragraph.", call. = FALSE)
  review[at] <- paste0(
    "SEDAR72-WP-17 Table 7 also provides age-sampling counts by fleet for 1991-2019; ",
    "144 fish counts and 144 trip counts are now imported as sampling metadata. ",
    "They do not supply the age-composition vectors or effective sample sizes. ",
    review[at]
  )
  writeLines(review, review_path, useBytes = TRUE)

  source(file.path(root, "scripts/database/002_validate_database.R"), local = TRUE)
  cat("Gulf gag age-sample count import written and database validation passed.\n")
} else {
  if (already_imported) cat("The exact Table 7 rows are already in the database.\n") else
    cat("Dry run only; pass --write to append the verified Table 7 rows.\n")
}
