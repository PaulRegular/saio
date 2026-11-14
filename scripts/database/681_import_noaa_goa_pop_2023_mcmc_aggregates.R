root <- "."
assessment_id <- "noaa_goa_pop_2023"
scenario <- "MCMC posterior median; Table 9.8"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

manifest <- read.csv("provenance/noaa_goa_pop_20261029/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
report_name <- "GOA_Pacific_Ocean_Perch_2023_SAFE.pdf"
source_row <- manifest[manifest$local_file == report_name, , drop = FALSE]
cache_options <- c(
  file.path("source_cache", "noaa_goa_pop_20261029"),
  file.path("..", "..", "noaa_goa_pop_20261029")
)
cache <- cache_options[vapply(cache_options, function(path) {
  file.exists(file.path(path, report_name))
}, logical(1))][1L]
if (nrow(source_row) != 1L || is.na(cache)) {
  stop("The pinned GOA POP 2023 assessment report is unavailable.", call. = FALSE)
}

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hash <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hash) != 1L) stop("Could not hash the source PDF.", call. = FALSE)
  hash
}
report <- file.path(cache, report_name)
if (file.info(report)$size != as.numeric(source_row$bytes) ||
    !identical(sha256_file(report), tolower(source_row$sha256))) {
  stop("The cached report differs from its source manifest.", call. = FALSE)
}

pages <- pdftools::pdf_text(report)
table_page <- grep("Table 9.8. Estimated time series", pages, fixed = TRUE)
if (length(table_page) != 1L || table_page == length(pages)) {
  stop("Could not locate the Table 9.8 MCMC time series.", call. = FALSE)
}
lines <- unlist(strsplit(paste(pages[table_page:(table_page + 1L)],
  collapse = "\n"), "\n", fixed = TRUE), use.names = FALSE)
lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", lines)]
number <- "(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)"
entry_pattern <- paste0(number, "[[:space:]]*\\([[:space:]]*", number,
  "[[:space:]]*,[[:space:]]*", number, "[[:space:]]*\\)")
parse_entry <- function(text) {
  text <- gsub("(?<=\\d),(?=\\d{3}(\\D|$))", "", text, perl = TRUE)
  matches <- regmatches(text, gregexpr(entry_pattern, text, perl = TRUE))[[1L]]
  lapply(matches, function(match) {
    as.numeric(unlist(regmatches(match,
      gregexpr(number, match, perl = TRUE)), use.names = FALSE))
  })
}

annual <- lapply(lines, function(line) {
  year <- as.integer(sub("^\\s*([0-9]{4}).*$", "\\1", line))
  entries <- parse_entry(line)
  if (year < 2024L && length(entries) != 4L) {
    stop("Unexpected Table 9.8 row for ", year, ".", call. = FALSE)
  }
  if (year == 2024L && length(entries) != 2L) {
    stop("Unexpected 2024 Table 9.8 projection row.", call. = FALSE)
  }
  if (year < 2024L) {
    list(year = year, entries = entries)
  } else {
    list(year = year, entries = c(list(NULL, NULL), entries))
  }
})
years <- vapply(annual, `[[`, integer(1), "year")
if (!identical(years, 1961:2024)) {
  stop("Table 9.8 does not provide the expected 1961-2024 rows.", call. = FALSE)
}

metric_specs <- list(
  list(index = 1L, type = "mortality", measure = "apical_F",
    unit = "per year", scale = 1, age = NA_real_,
    notes = "Report labels this as fully selected F. MCMC median and 95% credible interval."),
  list(index = 2L, type = "recruitment", measure = "recruitment",
    unit = "million fish", scale = 1, age = 2,
    notes = "Age-2 recruitment. MCMC median and 95% credible interval."),
  list(index = 3L, type = "biomass", measure = "SSB",
    unit = "t", scale = 1000, age = NA_real_,
    notes = "Female spawning biomass; source kt converted to t. MCMC median and 95% credible interval."),
  list(index = 4L, type = "biomass", measure = "total_biomass",
    unit = "t", scale = 1000, age = NA_real_,
    notes = "Total age-2+ biomass; source kt converted to t. MCMC median and 95% credible interval.")
)
output_columns <- names(read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
rows <- list()
for (record in annual) {
  for (spec in metric_specs) {
    entry <- record$entries[[spec$index]]
    if (is.null(entry)) next
    rows[[length(rows) + 1L]] <- data.frame(
      assessment_id = assessment_id, type = spec$type, measure = spec$measure,
      fleet = "", survey = "", sex = "", region = "", season = "",
      year = record$year, age = spec$age, age_group = "",
      value = entry[1L] * spec$scale, se = NA_real_,
      lwr = entry[2L] * spec$scale, upr = entry[3L] * spec$scale,
      unit = spec$unit, source_type = "official_table",
      source_reference = paste0(
        "2023 GOA Pacific ocean perch SAFE, Table 9.8, pp. 31-32; ",
        source_row$url
      ),
      notes = spec$notes, scenario = scenario,
      stringsAsFactors = FALSE
    )
  }
}
outputs <- do.call(rbind, rows)
rownames(outputs) <- NULL
outputs <- outputs[output_columns]
expected_counts <- c(apical_F = 63L, recruitment = 63L, SSB = 64L,
  total_biomass = 64L)
if (nrow(outputs) != 254L || any(!is.finite(outputs$value)) ||
    any(!is.finite(outputs$lwr)) || any(!is.finite(outputs$upr)) ||
    !identical(as.integer(table(factor(outputs$measure,
      levels = names(expected_counts)))), unname(expected_counts))) {
  stop("MCMC output rows failed expected count or value checks.", call. = FALSE)
}

cat("Prepared GOA POP MCMC aggregate outputs: ", nrow(outputs),
  " rows (1961-2023 fitted series plus 2024 biomass projection).\n", sep = "")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the separate MCMC scenario.\n")
  quit(save = "no", status = 0L)
}

path <- file.path(root, "database", "outputs.csv")
header_line <- readLines(path, n = 1L, warn = FALSE)
header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
  check.names = FALSE))
if (!identical(header, names(outputs))) stop("Unexpected output schema.", call. = FALSE)
existing_lines <- system2("rg", c("--color", "never", "--no-heading",
  "--no-line-number", "-F", assessment_id, path), stdout = TRUE,
  stderr = FALSE)
status <- attr(existing_lines, "status")
if (is.null(status)) status <- 0L
if (status == 0L) {
  existing <- read.csv(text = paste(c(header_line, existing_lines), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  existing <- existing[!is.na(existing$scenario) &
    existing$scenario == scenario, , drop = FALSE]
  if (nrow(existing) == nrow(outputs)) {
    for (column in names(outputs)[vapply(outputs, is.character, logical(1))]) {
      existing[[column]][is.na(existing[[column]])] <- ""
      outputs[[column]][is.na(outputs[[column]])] <- ""
    }
    for (column in names(outputs)[vapply(outputs, is.numeric, logical(1))]) {
      if (is.logical(existing[[column]])) existing[[column]] <- as.numeric(existing[[column]])
    }
    comparison <- all.equal(existing, outputs, check.attributes = FALSE)
    if (isTRUE(comparison)) {
      cat("MCMC scenario is already present and matches the source; no rows appended.\n")
      quit(save = "no", status = 0L)
    }
  } else {
    comparison <- paste0("row count differs: ", nrow(existing), " vs ", nrow(outputs))
  }
  if (nrow(existing)) stop("A partial or conflicting MCMC scenario already exists: ",
    paste(comparison, collapse = "; "), call. = FALSE)
} else if (status != 1L) {
  stop("Could not inspect existing GOA POP output rows.", call. = FALSE)
}

size <- file.info(path)$size
con <- file(path, open = "rb")
seek(con, where = max(0, size - 2), origin = "start")
ending <- readBin(con, what = "raw", n = min(2, size))
close(con)
eol <- if (length(ending) == 2L && identical(ending, as.raw(c(13L, 10L)))) "\r\n" else "\n"
if (!length(ending) || tail(ending, 1L) != as.raw(10L)) {
  con <- file(path, open = "ab")
  writeBin(charToRaw(eol), con)
  close(con)
}
write.table(outputs, file = path, sep = ",", row.names = FALSE,
  col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
  eol = eol, append = TRUE)
cat("Appended the MCMC posterior median and interval scenario.\n")
