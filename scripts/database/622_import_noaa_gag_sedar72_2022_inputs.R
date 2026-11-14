root <- "."
cache_name <- "noaa_gag_sedar72_2022"
cache_candidates <- c(
  file.path(root, "source_cache", cache_name),
  file.path(root, "..", "..", cache_name)
)
cache_dir <- cache_candidates[dir.exists(cache_candidates)][1L]
manifest_path <- file.path("provenance", cache_name, "manifest.csv")
assessment_id <- "noaa_gag_gulf_sedar72_srfs_2022"
candidate_id <- "NOAA:10348"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

if (is.na(cache_dir) || !length(cache_dir)) {
  stop("Could not find the gitignored SEDAR 72 source cache.", call. = FALSE)
}
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    output <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      output, value = TRUE)))
  } else {
    output <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hashes <- sub("[[:space:]].*$", "", output[1L])
  }
  if (length(hashes) != 1L) stop("Could not calculate source SHA-256.", call. = FALSE)
  hashes
}

source_names <- c(
  "sedar72_srfs_amendment_2022.pdf",
  "sedar72_final_report_2021.pdf",
  "sedar72_wp17_compositions_2021.pdf",
  "sedar72_executive_summary_2022.pdf",
  "sedar72_ssc_review_2022.pdf"
)
verify_source <- function(name) {
  row <- manifest[basename(manifest$file) == name, , drop = FALSE]
  path <- file.path(cache_dir, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached SEDAR 72 source does not match its provenance record: ", name,
      call. = FALSE)
  }
  path
}
paths <- setNames(vapply(source_names, verify_source, character(1L)), source_names)
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached SEDAR 72 input tables.", call. = FALSE)
}
pages <- pdftools::pdf_text(paths[["sedar72_srfs_amendment_2022.pdf"]])

table_markers <- c(
  "Table 1. Gulf of Mexico Gag Grouper recreational landings in numbers",
  "Table 2. Gulf of Mexico Gag Grouper recreational discards in numbers",
  "Table 3. Log-scale standard error (SE) inputs associated with landings",
  "Table 4. Log-scale standard error (SE) inputs associated with each"
)
table_starts <- vapply(table_markers, function(marker) {
  hits <- which(vapply(pages, function(page) grepl(marker, page, fixed = TRUE),
    logical(1L)))
  if (length(hits) != 1L) stop("Could not uniquely locate ", marker, call. = FALSE)
  hits
}, integer(1L))

parse_table <- function(index, years, columns) {
  first_page <- table_starts[index]
  next_page <- if (index < length(table_starts)) table_starts[index + 1L] - 1L else first_page + 1L
  lines <- trimws(unlist(strsplit(paste(pages[first_page:next_page], collapse = "\n"), "\n")))
  lines <- lines[grepl("^(19|20)[0-9]{2}[[:space:]]+", lines)]
  parsed <- lapply(lines, function(line) {
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    fields <- gsub("[,*]", "", fields)
    values <- suppressWarnings(as.numeric(fields))
    if (anyNA(values)) stop("Could not parse a row in SEDAR 72 Table ", index, ".")
    values
  })
  if (length(parsed) != length(years)) {
    stop("SEDAR 72 Table ", index, " has unexpected year coverage.", call. = FALSE)
  }
  actual_years <- vapply(parsed, `[[`, numeric(1L), 1L)
  if (!identical(as.integer(actual_years), years)) {
    stop("SEDAR 72 Table ", index, " does not contain the expected year series.", call. = FALSE)
  }
  values <- lapply(parsed, `[` , -1L)
  if (index %in% 1:2) {
    if (any(lengths(values) < 3L)) stop("Catch totals are incomplete in Table ", index, ".")
    data.frame(year = years,
      charter = vapply(values, `[[`, numeric(1L), 1L),
      headboat = vapply(values, `[[`, numeric(1L), 2L),
      private_shore = vapply(values, function(x) x[length(x)], numeric(1L)))
  } else {
    if (any(lengths(values) != columns)) {
      stop("Unexpected column count in SEDAR 72 Table ", index, ".", call. = FALSE)
    }
    data.frame(year = years, do.call(rbind, values))
  }
}

landings <- parse_table(1L, 1963:2019, 3L)
discards <- parse_table(2L, 1981:2019, 3L)
landings_sd <- parse_table(3L, 1981:2019, 3L)
discard_sd <- parse_table(4L, 1981:2019, 3L)
names(landings_sd) <- c("year", "headboat", "charter", "private_shore")
names(discard_sd) <- c("year", "charter", "headboat", "private_shore")

fleet_names <- c(
  charter = "Recreational charter",
  headboat = "Recreational headboat",
  private_shore = "Recreational private + shore"
)
source_reference <- function(table) {
  paste0("SEDAR72_SRFS_Amendment_2022.pdf, Table ", table)
}
add_series <- function(table, measure, basis, partition, source_table, notes,
                       unit, years, fleet, values) {
  n <- length(values)
  out <- pacific_database_row("inputs", n = n)
  out$assessment_id <- assessment_id
  out$type <- "catch"
  out$measure <- measure
  out$basis <- basis
  out$fleet <- fleet_names[[fleet]]
  out$year <- as.integer(years)
  out$year_basis <- "calendar_year"
  out$value <- as.numeric(values)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference(source_table)
  out$partition <- partition
  out$notes <- notes
  out
}

input_rows <- list()
for (fleet in names(fleet_names)) {
  input_rows[[length(input_rows) + 1L]] <- add_series(
    landings, "landings_numbers", "numbers", "landings", 1L,
    paste("Annual recreational landings in numbers. Private + Shore Total is the model fleet input;",
      "the Private SRFS and Non-SRFS columns are source decompositions, not separate fleet observations.",
      "The corrected 1983 Private SRFS subcomponent is shown with an asterisk; the reported total is retained."),
    "fish", landings$year, fleet, landings[[fleet]])
  input_rows[[length(input_rows) + 1L]] <- add_series(
    discards, "discard_numbers", "numbers", "discards", 2L,
    "Annual recreational discards before applying the assessment discard-mortality rate.",
    "fish", discards$year, fleet, discards[[fleet]])
}
for (fleet in names(fleet_names)) {
  input_rows[[length(input_rows) + 1L]] <- add_series(
    landings_sd, "log_catch_sd", "log_scale", "landings", 3L,
    "Source-reported standard error on log landings, retained as printed.",
    "log-scale standard error", landings_sd$year, fleet, landings_sd[[fleet]])
  input_rows[[length(input_rows) + 1L]] <- add_series(
    discard_sd, "log_catch_sd", "log_scale", "discards", 4L,
    "Source-reported standard error on log discards, retained as printed; discard numbers are before discard mortality.",
    "log-scale standard error", discard_sd$year, fleet, discard_sd[[fleet]])
}
inputs <- do.call(rbind, input_rows)
key <- paste(inputs$measure, inputs$year, inputs$fleet, inputs$partition, sep = "|")
if (nrow(inputs) != 522L || any(!is.finite(inputs$value)) || any(inputs$value < 0) ||
    anyDuplicated(key) || any(landings$year != 1963:2019) ||
    any(discards$year != 1981:2019) || any(landings_sd$year != 1981:2019) ||
    any(discard_sd$year != 1981:2019)) {
  stop("SEDAR 72 recreational catch inputs failed coverage or value checks.", call. = FALSE)
}

assessment_path <- file.path("database", "assessments.csv")
assessments <- read.csv(assessment_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment_row <- which(assessments$assessment_id == assessment_id)
candidate_path <- file.path("discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
inventory_path <- file.path("discovery", "inventory_units.csv")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
inventory_row <- candidate_inventory_row(inventory, candidate_id, "noaa_gag_gulf")

existing_inputs <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading", "-F",
  assessment_id, file.path("database", "inputs.csv")), stdout = TRUE, stderr = FALSE))
rg_status <- attr(existing_inputs, "status")
if (is.null(rg_status)) rg_status <- 0L
if (length(assessment_row) != 1L || length(candidate_row) != 1L ||
    rg_status != 1L || length(existing_inputs) ||
    assessments$inputs_status[assessment_row] != "not_started" ||
    candidates$match_status[candidate_row] != "matched" ||
    candidates$import_status[candidate_row] != "partial") {
  stop("Gulf gag identity, status, or input rows conflict with this import.", call. = FALSE)
}

if (write_mode) {
  write.table(inputs, file.path("database", "inputs.csv"), sep = ",",
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  assessments$inputs_status[assessment_row] <- "partial"
  assessments$notes[assessment_row] <- paste(assessments$notes[assessment_row],
    "SEDAR 72 SRFS amendment Tables 1-4 recreational landings/discards and log-scale catch errors are imported; commercial, index, age-composition, and numeric biology inputs remain incomplete.")
  replace_csv_register_row(assessment_path, assessment_row,
    assessments[assessment_row, , drop = FALSE], "assessment_id", assessment_id)
  candidates$catch_age_evidence[candidate_row] <- paste(
    candidates$catch_age_evidence[candidate_row],
    "Tables 1-4 now provide recreational fleet landings/discard numbers and log-scale errors; these are aggregate catch inputs, while numeric age-composition arrays remain unavailable and are shown only in source figures.")
  candidates$review_date[candidate_row] <- as.character(Sys.Date())
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key", inventory$unit_key[inventory_row])
} else {
  message("Dry run: ", nrow(inputs), " Gulf gag recreational catch and log-scale error rows from SEDAR 72 Tables 1-4. Use --write to import.")
}
