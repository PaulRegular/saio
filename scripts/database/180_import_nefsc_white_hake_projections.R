base <- "."
.local_library <- file.path(base, "source_cache", "Rlibrary")
if (dir.exists(.local_library)) .libPaths(c(.local_library, .libPaths()))
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_nefsc_garmiii_tenuis_gom_gb")
assessment_id <- "nefsc_white_hake_2025"
report_file <- file.path(cache, "2025_HKW_UNIT_RPT.pdf")
stocksmart_file <- file.path(cache, "stock_assessment_data_664c4237.rda")
report_url <- paste0(
  "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&",
  "species_id=8&stock_id=6&review_type_id=3&info_type_id=-1&map_type_id=&",
  "filename=2025_HKW_UNIT_RPT.pdf"
)
stocksmart_url <- paste0(
  "https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/",
  "664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_data.rda"
)
stocksmart_sha256 <- "141db3599cbf37af3e019bd53d2323d829a719b273e8ab0226b73f6ad18620b0"
outputs_path <- file.path(database, "outputs.csv")
assumptions_path <- file.path(database, "assumptions.csv")
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

if (!all(file.exists(c(report_file, stocksmart_file)))) {
  stop("The cached White Hake report and Stock SMART snapshot are required.", call. = FALSE)
}
actual_sha256 <- digest::digest(
  readBin(stocksmart_file, "raw", n = file.info(stocksmart_file)$size),
  algo = "sha256", serialize = FALSE
)
if (!identical(actual_sha256, stocksmart_sha256)) {
  stop("The pinned Stock SMART snapshot checksum does not match.", call. = FALSE)
}

pages <- pdftools::pdf_text(report_file)
lines <- trimws(unlist(strsplit(paste(pages, collapse = "\n"), "\n")))
pattern <- paste0(
  "^(2025|2026|2027|2028)[[:space:]]+([0-9,]+)[[:space:]]+",
  "([0-9,]+)[[:space:]]+\\(([0-9,]+)[[:space:]]*-[[:space:]]*",
  "([0-9,]+)\\)[[:space:]]+([0-9.]+)$"
)
matches <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
matches <- matches[lengths(matches) == 7L]
projection <- do.call(rbind, lapply(matches, function(x) {
  as.numeric(gsub(",", "", x[-1L], fixed = TRUE))
}))
colnames(projection) <- c("year", "catch", "SSB", "SSB_lwr", "SSB_upr", "Fbar")
expected_projection <- rbind(
  c(2025, 1802, 13385, 10960, 15861, 0.144),
  c(2026, 1943, 12140,  9884, 14394, 0.176),
  c(2027, 1677, 10839,  9070, 12610, 0.176),
  c(2028, 1502, 10219,  8801, 11652, 0.176)
)
if (!identical(unname(projection), unname(expected_projection))) {
  stop("White Hake Table 3 values or years differ from the verified projection table.", call. = FALSE)
}

source_env <- new.env(parent = globalenv())
load(stocksmart_file, envir = source_env)
if (!exists("stock_assessment_data", envir = source_env, inherits = FALSE)) {
  stop("The pinned snapshot lacks stock_assessment_data.", call. = FALSE)
}
stocksmart <- source_env$stock_assessment_data
stocksmart <- stocksmart[stocksmart$assessment_id == 14071, , drop = FALSE]
if (nrow(stocksmart) != 249L ||
  !all(stocksmart$stock_id == 10518) ||
  !all(stocksmart$assessment_year == 2025) ||
  !all(stocksmart$assessment_type == "Operational") ||
  !all(stocksmart$stock_name == "White hake - Gulf of Maine / Georges Bank")) {
  stop("Stock SMART assessment identity does not match the White Hake production run.", call. = FALSE)
}
smart_value <- function(metric, year) {
  x <- stocksmart[stocksmart$metric == metric & stocksmart$year == year, , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one Stock SMART value for ", metric, " ", year, ".", call. = FALSE)
  x$value
}
if (smart_value("Abundance", 2025) != projection[1L, "SSB"]) {
  stop("The 2025 Table 3 SSB value does not match Stock SMART.", call. = FALSE)
}

outputs <- read.csv(
  outputs_path, stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)
assumptions <- read.csv(
  assumptions_path, stringsAsFactors = FALSE, check.names = FALSE,
  na.strings = c("", "NA")
)
assessment <- read.csv(
  file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA")
)
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
if (nrow(assessment) != 1L || assessment$terminal_year != 2024L ||
  assessment$outputs_status != "partial") {
  stop("The White Hake fitted terminal year or output status changed unexpectedly.", call. = FALSE)
}

check_historical <- function(metric, measure, tolerance = 0) {
  source <- stocksmart[stocksmart$metric == metric & stocksmart$year <= 2024, , drop = FALSE]
  source <- source[order(source$year), , drop = FALSE]
  stored <- outputs[
    outputs$assessment_id == assessment_id & outputs$measure == measure &
      outputs$year <= 2024 & outputs$source_type == "official_table",
    , drop = FALSE
  ]
  stored <- stored[order(stored$year), , drop = FALSE]
  if (nrow(source) != 62L || nrow(stored) != 62L ||
    !identical(as.integer(source$year), 1963:2024) ||
    !identical(as.integer(stored$year), 1963:2024) ||
    any(abs(source$value - stored$value) > tolerance)) {
    stop("Historical White Hake ", measure, " values do not match the report.", call. = FALSE)
  }
}
check_historical("Abundance", "SSB")
check_historical("Recruitment", "recruitment")
check_historical("Fmort", "Fbar", tolerance = 0.0005)

output_fields <- names(outputs)
output_row <- function(type, measure, year, value, unit, notes,
                       fleet = "", age_group = "", lwr = NA_real_,
                       upr = NA_real_) {
  row <- as.data.frame(
    matrix("", nrow = 1L, ncol = length(output_fields)),
    stringsAsFactors = FALSE
  )
  names(row) <- output_fields
  row$assessment_id <- assessment_id
  row$type <- type
  row$measure <- measure
  row$fleet <- fleet
  row$year <- as.character(year)
  row$age_group <- age_group
  row$value <- as.character(value)
  row$unit <- unit
  row$source_type <- "official_table"
  row$source_reference <- paste(report_url, "Table 3 (PDF page 3)", sep = "; ")
  row$notes <- notes
  if (is.finite(lwr)) row$lwr <- as.character(lwr)
  if (is.finite(upr)) row$upr <- as.character(upr)
  row
}

scenario <- paste(
  "Table 3 management projection; historical fitted terminal year remains 2024.",
  "The report does not identify whether point estimates are means or medians."
)
projection_rows <- do.call(rbind, lapply(seq_len(nrow(projection)), function(i) {
  x <- projection[i, ]
  catch_note <- if (x[["year"]] == 2025) {
    paste(scenario, "2025 catch (1,802 t) was estimated by the NEFMC Groundfish Plan Development Team and is a projection input.")
  } else {
    paste(scenario, "Projected total fishery catch under the FMSY-proxy harvest scenario for 2026-2028.")
  }
  f_note <- if (x[["year"]] == 2025) {
    paste(scenario, "Table 3 reports fully selected F = 0.144 for 2025.")
  } else {
    paste(scenario, "Fully selected F is 0.176 under the FMSY-proxy scenario for 2026-2028; no interval is reported.")
  }
  rbind(
    output_row("catch", "predicted_catch", x[["year"]], x[["catch"]],
      "metric tons", catch_note, fleet = "Total fishery catch"),
    output_row("biomass", "SSB", x[["year"]], x[["SSB"]],
      "metric tons", paste(scenario, "Table 3 reports 5th and 95th percentile bounds."),
      lwr = x[["SSB_lwr"]], upr = x[["SSB_upr"]]),
    output_row("mortality", "Fbar", x[["year"]], x[["Fbar"]],
      "yr-1", f_note, age_group = "6-9+")
  )
}))

assumption_fields <- names(assumptions)
assumption_row <- function(setting, value, notes) {
  row <- as.data.frame(
    matrix("", nrow = 1L, ncol = length(assumption_fields)),
    stringsAsFactors = FALSE
  )
  names(row) <- assumption_fields
  row$assessment_id <- assessment_id
  row$component <- "projection"
  row$setting <- setting
  row$value <- value
  row$source_reference <- paste(report_url, "Table 3 (PDF page 3)", sep = "; ")
  row$notes <- notes
  row
}
projection_assumptions <- rbind(
  assumption_row(
    "harvest_scenario",
    "FMSY proxy; fully selected F = 0.176 yr-1 in 2026-2028",
    "Management projection scenario; this is not an additional fitted historical mortality state."
  ),
  assumption_row(
    "catch_2025",
    "1,802 metric tons; NEFMC Groundfish Plan Development Team estimate",
    "Used as the 2025 projection input in Table 3; not a model-estimated catch output."
  )
)

append_database_rows <- function(path, rows) {
  temporary <- tempfile(tmpdir = database)
  on.exit(unlink(temporary), add = TRUE)
  write.table(
    rows, file = temporary, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8"
  )
  text <- rawToChar(readBin(temporary, "raw", n = file.info(temporary)$size))
  text <- gsub("\r\n?", "\n", text)
  row_lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  row_lines <- row_lines[nzchar(row_lines)]
  if (length(row_lines) != nrow(rows)) {
    stop("Could not serialize all rows for ", basename(path), ".", call. = FALSE)
  }
  connection <- file(path, open = "ab")
  on.exit(close(connection), add = TRUE)
  writeBin(
    charToRaw(paste0(paste(row_lines, collapse = "\r\r\n"), "\r\r\n")),
    connection
  )
}

existing_outputs <- outputs[
  outputs$assessment_id == assessment_id &
    outputs$year %in% 2025:2028 &
    outputs$measure %in% c("predicted_catch", "SSB", "Fbar"),
  , drop = FALSE
]
if (nrow(existing_outputs)) {
  key <- function(x) paste(x$measure, x$year, sep = "\034")
  expected_key <- key(projection_rows)
  existing_index <- match(expected_key, key(existing_outputs))
  same <- nrow(existing_outputs) == nrow(projection_rows) && !anyNA(existing_index)
  if (same) {
    actual <- existing_outputs[existing_index, , drop = FALSE]
    same <- all(vapply(c("value", "lwr", "upr", "unit", "source_type", "source_reference", "notes"),
      function(field) {
        a <- actual[[field]]
        b <- projection_rows[[field]]
        a[is.na(a)] <- ""
        b[is.na(b)] <- ""
        identical(as.character(a), as.character(b))
      }, logical(1)))
  }
  if (!same) stop("Existing White Hake projection rows differ from Table 3.", call. = FALSE)
}

existing_assumptions <- assumptions[
  assumptions$assessment_id == assessment_id &
    assumptions$component == "projection" &
    assumptions$setting %in% projection_assumptions$setting,
  , drop = FALSE
]
if (nrow(existing_assumptions)) {
  key <- function(x) x$setting
  existing_index <- match(key(projection_assumptions), key(existing_assumptions))
  same <- nrow(existing_assumptions) == nrow(projection_assumptions) && !anyNA(existing_index)
  if (same) {
    actual <- existing_assumptions[existing_index, , drop = FALSE]
    same <- all(vapply(c("value", "source_reference", "notes"),
      function(field) {
        a <- actual[[field]]
        b <- projection_assumptions[[field]]
        a[is.na(a)] <- ""
        b[is.na(b)] <- ""
        identical(as.character(a), as.character(b))
      }, logical(1)))
  }
  if (!same) stop("Existing White Hake projection assumptions differ from Table 3.", call. = FALSE)
}

if (dry_run) {
  cat("Validated 12 White Hake projection rows and 2 scenario assumptions; no database files changed.\n")
} else {
  if (!nrow(existing_outputs)) {
    append_database_rows(outputs_path, projection_rows)
    cat("Imported 12 White Hake Table 3 projection rows for 2025-2028.\n")
  } else {
    cat("White Hake projection rows are already current.\n")
  }
  if (!nrow(existing_assumptions)) {
    append_database_rows(assumptions_path, projection_assumptions)
    cat("Imported 2 White Hake Table 3 scenario assumptions.\n")
  } else {
    cat("White Hake projection assumptions are already current.\n")
  }
}