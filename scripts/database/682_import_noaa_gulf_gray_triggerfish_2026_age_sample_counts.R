root <- "."
assessment_id <- "noaa_gulf_gray_triggerfish_sedar100_2026"
candidate_id <- "NOAA:10062"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(
  file.path(root, "provenance/discovery_noaa_gulf_gray_triggerfish_2026/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"
)

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}

verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  if (nrow(row) != 1L) stop("Source is not uniquely pinned: ", file, call. = FALSE)
  path <- file.path(root, "source_cache", row$cache_folder, row$cache_file)
  if (!file.exists(path) || as.character(file.info(path)$size) != row$bytes ||
      !identical(sha256_file(path), tolower(row$sha256))) {
    stop("Cached source differs from its provenance record: ", file, call. = FALSE)
  }
  text_path <- sub("\\.pdf$", ".txt", path, ignore.case = TRUE)
  if (!file.exists(text_path)) stop("Missing local text extract: ", text_path, call. = FALSE)
  readLines(text_path, warn = FALSE, encoding = "UTF-8")
}

dw04 <- verify_source("sedar-100-dw-04-recreational-length-age-compositions.pdf")
dw07 <- verify_source("sedar-100-dw-07-commercial-length-age-compositions.pdf")

table_section <- function(lines, title, next_title) {
  start <- which(grepl(title, lines, fixed = TRUE))
  if (length(start) != 1L) stop("Could not locate source table: ", title, call. = FALSE)
  end <- which(grepl(next_title, lines, fixed = TRUE))
  end <- end[end > start]
  if (length(end) != 1L) stop("Could not locate end of source table: ", title, call. = FALSE)
  lines[seq.int(start + 1L, end - 1L)]
}

parse_count_rows <- function(section, n_columns, years, label) {
  rows <- section[grepl("^[[:space:]]*20[0-9]{2}[[:space:]]+", section, perl = TRUE)]
  parsed <- lapply(rows, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.numeric(tokens))
    if (length(values) != n_columns || any(!is.finite(values)) ||
        any(values != floor(values))) {
      stop("Could not parse the published count row for ", label, ": ", line,
        call. = FALSE)
    }
    values
  })
  result <- do.call(rbind, parsed)
  if (nrow(result) != length(years) || !identical(as.integer(result[, 1L]), years)) {
    stop("Unexpected year coverage in ", label, call. = FALSE)
  }
  result
}

dw04_section <- table_section(
  dw04,
  "Table 3: Annual number of fish sampled for age by each data source.",
  "Table 4: Number of fish (nfish) and trips (ntrip) sampled for length and age"
)
dw04_codes <- c(
  "CRP", "MRFSS", "RECFIN", "SRHS", "PCLAB", "FIN-OBS",
  "FIN-BIOSTAT", "FWRI-OBS", "DISL/USA", "GRFS", "REPBIO", "TIP", "HB"
)
dw04_values <- parse_count_rows(dw04_section, length(dw04_codes) + 1L,
  2003:2024, "SEDAR 100-DW-04 Table 3")
if (sum(dw04_values[, -1L]) != 9289) {
  stop("SEDAR 100-DW-04 Table 3 annual cells must sum to 9,289.",
    call. = FALSE)
}

dw07_section <- table_section(
  dw07,
  "Table A.4. Number of fish and trips sampled for ages by year and gear",
  "Table A.5. Number of fish sampled for length by weighting strata"
)
dw07_lines <- dw07_section[grepl("^[[:space:]]*20[0-9]{2}[[:space:]]+", dw07_section, perl = TRUE)]
dw07_values <- lapply(dw07_lines, function(line) {
  values <- suppressWarnings(as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1L]]))
  if (!length(values) %in% c(3L, 5L) || any(!is.finite(values)) ||
      any(values != floor(values))) {
    stop("Could not parse SEDAR 100-DW-07 Table A.4 age sample counts: ", line,
      call. = FALSE)
  }
  values
})
dw07_years <- vapply(dw07_values, `[[`, numeric(1), 1L)
if (!identical(as.integer(dw07_years), 2003:2024) || anyDuplicated(dw07_years)) {
  stop("Unexpected year coverage in SEDAR 100-DW-07 Table A.4.", call. = FALSE)
}

rows <- list()
add_sample_count <- function(value, year, observation_id, source_reference,
                             notes, fleet) {
  rows[[length(rows) + 1L]] <<- pacific_database_row(
    "inputs", assessment_id = assessment_id, type = "biology",
    measure = "composition_sample_count", basis = "numbers", value = value,
    unit = "fish", year = year, year_basis = "calendar_year",
    fleet = fleet, observation_id = observation_id,
    source_type = "official_table", source_reference = source_reference,
    notes = notes
  )
}

for (j in seq_along(dw04_codes)) {
  for (i in seq_along(2003:2024)) {
    code <- dw04_codes[j]
    add_sample_count(
      dw04_values[i, j + 1L], 2002L + i,
      paste0("SEDAR100_DW04_Table3_", code),
      "SEDAR 100-DW-04, Table 3",
      paste("Annual number of fish sampled for age from source program", code,
        "as reported. These are sample counts, not age proportions, catch-at-age, or effective likelihood sample sizes."),
      "Recreational fishery"
    )
  }
}

for (i in seq_along(dw07_values)) {
  year <- as.integer(dw07_values[[i]][1L])
  add_sample_count(
    dw07_values[[i]][2L], year, "SEDAR100_DW07_TableA4_Handline_age_samples",
    "SEDAR 100-DW-07, Table A.4 (printed p. 27)",
    "Number of handline fish aged in the year. The source's trip count is not imported here. This is sampling metadata, not an age composition or effective likelihood sample size.",
    "Commercial handline"
  )
  if (length(dw07_values[[i]]) == 5L) {
    add_sample_count(
      dw07_values[[i]][4L], year, "SEDAR100_DW07_TableA4_Longline_age_samples",
      "SEDAR 100-DW-07, Table A.4 (printed p. 27)",
      "Number of longline fish aged in the year. The source's trip count is not imported here. This is sampling metadata, not an age composition or effective likelihood sample size.",
      "Commercial longline"
    )
  }
}

inputs <- do.call(rbind, rows)
rownames(inputs) <- NULL
dw07_counts <- inputs[inputs$source_reference ==
  "SEDAR 100-DW-07, Table A.4 (printed p. 27)", , drop = FALSE]
if (nrow(inputs) != 329L || any(!is.finite(inputs$value)) || any(inputs$value < 0) ||
    sum(inputs$value[inputs$source_reference == "SEDAR 100-DW-04, Table 3"]) != 9289 ||
    sum(dw07_counts$value[dw07_counts$fleet == "Commercial handline"]) != 5130 ||
    sum(dw07_counts$value[dw07_counts$fleet == "Commercial longline"]) != 900) {
  stop("Gray triggerfish age-sample counts failed row-count or total checks.", call. = FALSE)
}

if (!write_mode) {
  cat("Dry run:", nrow(inputs), "published age-sample counts; 9,289 recreational count cells and 6,030 commercial handline/longline age samples.\n")
  quit(save = "no", status = 0L)
}

database_path <- file.path(root, "database/inputs.csv")
connection <- file(database_path, open = "rt")
on.exit(close(connection), add = TRUE)
prefix <- paste0("\"", assessment_id, "\",\"biology\",\"composition_sample_count\"")
repeat {
  lines <- readLines(connection, n = 50000L, warn = FALSE)
  if (!length(lines)) break
  if (any(startsWith(lines, prefix))) {
    stop("Gray triggerfish age-sample counts already exist; refusing duplicate append.",
      call. = FALSE)
  }
}
close(connection)

write.table(inputs, database_path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", qmethod = "double")

candidate_path <- file.path(root, "discovery/candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
if (length(candidate_row) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
candidate_note <- paste(
  "SEDAR 100-DW-04 Table 3 and DW-07 Table A.4 age-sample counts are imported.",
  "These counts do not replace the source's plotted age compositions."
)
if (!grepl(candidate_note, candidates$notes[candidate_row], fixed = TRUE)) {
  candidates$notes[candidate_row] <- paste(candidates$notes[candidate_row], candidate_note)
  replace_candidate_register_row(candidate_path, candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id)
}

cat("Imported", nrow(inputs), "published Gulf gray triggerfish age-sample counts.\n")
