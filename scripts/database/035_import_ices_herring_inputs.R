root <- normalizePath(".", winslash = "/", mustWork = TRUE)
cache <- file.path(root, "source_cache/ices_herring_north_sea_2026")
database <- file.path(root, "database")
assessment_id <- "ices_herring_north_sea_2026"
report <- "https://doi.org/10.17895/ices.pub.31424315"
inputs_path <- file.path(database, "inputs.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs <- read.csv(inputs_path, colClasses = "character", na.strings = "", encoding = "UTF-8", check.names = FALSE)
assumptions <- read.csv(assumptions_path, colClasses = "character", na.strings = "", encoding = "UTF-8", check.names = FALSE)
raw <- read.csv(file.path(cache, "report_tables_raw.csv"), stringsAsFactors = FALSE)
m <- raw[raw$table == "2.6.1.3", , drop = FALSE]
if (nrow(m) != 711L || !identical(sort(unique(m$year)), 1947:2025) ||
  !identical(sort(unique(as.integer(m$native_column))), 0:8)) {
  stop("The published M table did not have the expected year/age coverage.")
}

new_m <- as.data.frame(matrix(NA_character_, nrow = nrow(m), ncol = ncol(inputs)),
  stringsAsFactors = FALSE
)
names(new_m) <- names(inputs)
new_m$assessment_id <- assessment_id
new_m$type <- "M"
new_m$measure <- "natural_mortality_at_age"
new_m$basis <- "per_year"
new_m$year <- as.character(m$year)
new_m$year_basis <- "calendar_year"
new_m$age <- as.character(as.integer(m$native_column))
new_m$value <- as.character(m$value)
new_m$unit <- "per year"
new_m$source_type <- "official_table"
new_m$source_reference <- paste(report, "Table 2.6.1.3")
new_m$notes <- paste(
  "Published natural-mortality input matrix used by the official model; age 8 is the plus group.",
  "The pinned model script adds 0.02 to the constructed M surface before fitting.",
  "Values are copied as published without recalculation. The report describes three-year outer-year averaging, while the pinned construction script specifies five years. No 2026 M row is published."
)
key <- function(x) paste(x$assessment_id, x$type, x$measure, x$year, x$age, sep = "|")
existing <- inputs[inputs$assessment_id == assessment_id & inputs$type == "M" &
  inputs$measure == "natural_mortality_at_age", , drop = FALSE]
new_m <- new_m[!key(new_m) %in% key(existing), , drop = FALSE]

sampling_time <- c(HERAS = "0.5", `IBTS-Q1` = "0.125", IBTS0 = "0.125", `IBTS-Q3` = "0.625")
season <- c(HERAS = "June-July", `IBTS-Q1` = "Q1", IBTS0 = "Q1", `IBTS-Q3` = "Q3")
timed <- inputs$assessment_id == assessment_id & inputs$type == "index" &
  inputs$survey %in% names(sampling_time)
timing_note <- "Approximate seasonal midpoint; the official fleet.txt timing was unavailable."
needs_update <- timed & (inputs$sampling_time != sampling_time[inputs$survey] |
  inputs$season != season[inputs$survey] | is.na(inputs$notes) |
  !grepl(timing_note, inputs$notes, fixed = TRUE))
inputs$sampling_time[timed] <- unname(sampling_time[inputs$survey[timed]])
inputs$season[timed] <- unname(season[inputs$survey[timed]])
inputs$notes[timed & (is.na(inputs$notes) | !grepl(timing_note, inputs$notes, fixed = TRUE))] <-
  timing_note
if (nrow(new_m)) inputs <- rbind(inputs, new_m)

if (nrow(new_m) || any(needs_update)) {
  csv_field <- function(value) {
    if (is.na(value)) {
      return("")
    }
    value <- enc2utf8(value)
    if (grepl('[,"\r\n]', value) || grepl("^[[:space:]]|[[:space:]]$", value)) {
      paste0('"', gsub('"', '""', value, fixed = TRUE), '"')
    } else {
      value
    }
  }
  rows <- c(
    paste(vapply(names(inputs), csv_field, character(1)), collapse = ","),
    vapply(seq_len(nrow(inputs)), function(i) {
      paste(vapply(seq_len(ncol(inputs)), function(j) csv_field(inputs[[j]][i]), character(1)), collapse = ",")
    }, character(1))
  )
  con <- file(inputs_path, open = "wb")
  writeLines(enc2utf8(rows), con, sep = "\r\n", useBytes = TRUE)
  close(con)
}

check <- read.csv(inputs_path, colClasses = "character", na.strings = "", encoding = "UTF-8", check.names = FALSE)
check_m <- check[check$assessment_id == assessment_id & check$type == "M" &
  check$measure == "natural_mortality_at_age", , drop = FALSE]
check_timed <- check[check$assessment_id == assessment_id & check$type == "index" &
  check$survey %in% names(sampling_time), , drop = FALSE]
if (nrow(check_m) != 711L || anyDuplicated(key(check_m)) || nrow(check_timed) != 534L ||
  any(check_timed$sampling_time != sampling_time[check_timed$survey]) ||
  any(check_timed$season != season[check_timed$survey])) {
  stop("Herring M or survey-timing rows did not validate after import.")
}
cat("Herring M rows present:", nrow(check_m), "(new:", nrow(new_m), "); approximate survey timings recorded for", nrow(check_timed), "rows.\n")

m_assumption <- assumptions$assessment_id == assessment_id &
  assumptions$component == "M" & assumptions$setting == "structure"
if (sum(m_assumption) != 1L) stop("Expected one Herring M structure assumption.")
assumptions$notes[m_assumption] <- paste(
  "The canonical database contains the published SMS-2023 age-year surface for 1947-2025.",
  "The official model adds 0.02 to this surface; the 2026 M input is unavailable."
)
write.csv(assumptions, assumptions_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
