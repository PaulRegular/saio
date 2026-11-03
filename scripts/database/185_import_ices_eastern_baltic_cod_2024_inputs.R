base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_wgbfas_morhua_bs_25_32", "assessment_2024")
assessment_id <- "ices_cod_eastern_baltic_2024"
report_url <- "https://doi.org/10.17895/ices.pub.25764978"
report_file <- file.path(cache, "WGBFAS_2024.pdf")
expected_sha256 <- "AE2E5188E7AF13A8A5DB913771E83D23164F22BCD9C5B431101FA94F780C7478"
dry_run <- identical(tolower(Sys.getenv("SAIO_IMPORT_DRY_RUN")), "true")

if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install digest and pdftools to import the cached report tables.", call. = FALSE)
}
if (!file.exists(report_file)) stop("Missing cached WGBFAS 2024 report.", call. = FALSE)

actual_sha256 <- digest::digest(
  readBin(report_file, "raw", n = file.info(report_file)$size),
  serialize = FALSE,
  algo = "sha256"
)
if (!identical(toupper(actual_sha256), expected_sha256)) {
  stop("Cached WGBFAS 2024 report checksum does not match the reviewed source.", call. = FALSE)
}

page_lines <- lapply(pdftools::pdf_text(report_file), function(x) {
  trimws(strsplit(x, "\n", fixed = TRUE)[[1L]])
})
table_page <- function(number) {
  heading <- paste0("^Table[[:space:]]+", gsub("\\.", "\\\\.", number), "[.]")
  found <- which(vapply(page_lines, function(x) any(grepl(heading, x)), logical(1)))
  if (length(found) != 1L) stop("Could not uniquely locate Table ", number, ".", call. = FALSE)
  found
}

year_token <- function(x) grepl("^(19|20)[0-9]{2}$", x)
numeric_token <- function(x) grepl("^[0-9]+([.][0-9]+)?[*]{0,2}$", x)
parse_summary <- function() {
  first_page <- table_page("2.1.11")
  rows <- list()
  active <- FALSE
  for (page in seq.int(first_page, length(page_lines))) {
    for (line in page_lines[[page]]) {
      if (!active && grepl("^Table[[:space:]]+2[.]1[.]11[.]", line)) {
        active <- TRUE
        next
      }
      if (active && grepl("^Table[[:space:]]+2[.]1[.]12[.]", line)) {
        return(do.call(rbind, rows))
      }
      if (!active) next
      cells <- strsplit(line, "[[:space:]]+")[[1L]]
      if (!length(cells) || !year_token(cells[[1L]])) next
      year <- as.integer(cells[[1L]])
      values <- cells[-1L]
      if (!length(values) || !all(vapply(values, numeric_token, logical(1)))) next
      values <- as.numeric(gsub("[*]", "", values))
      row <- data.frame(
        year = year,
        relative_recruitment = NA_real_,
        relative_SSB = NA_real_,
        landings = NA_real_,
        discards = NA_real_,
        relative_Fbar = NA_real_
      )
      if (year %in% 1946:1965 && length(values) == 4L) {
        row$relative_recruitment <- values[[1L]]
        row$relative_SSB <- values[[2L]]
        row$landings <- values[[3L]]
        row$relative_Fbar <- values[[4L]]
      } else if (year %in% 1966:2023 && length(values) == 5L) {
        row$relative_recruitment <- values[[1L]]
        row$relative_SSB <- values[[2L]]
        row$landings <- values[[3L]]
        row$discards <- values[[4L]]
        row$relative_Fbar <- values[[5L]]
      } else if (year == 2024L && length(values) == 1L) {
        row$relative_recruitment <- values[[1L]]
      } else {
        next
      }
      rows[[length(rows) + 1L]] <- row
    }
  }
  stop("Could not find the end of Table 2.1.11.", call. = FALSE)
}

summary <- parse_summary()
summary <- summary[order(summary$year), , drop = FALSE]
if (!identical(summary$year, 1946:2024) ||
  sum(!is.na(summary$landings)) != 78L ||
  sum(!is.na(summary$discards)) != 58L ||
  !identical(summary$year[!is.na(summary$discards)], 1966:2023) ||
  summary$landings[summary$year == 2023L] != 1008 ||
  summary$discards[summary$year == 2023L] != 57) {
  stop("Unexpected annual catch coverage or values in Table 2.1.11.", call. = FALSE)
}

input_file <- file.path(database, "inputs.csv")
input_header <- names(utils::read.csv(input_file, nrows = 0L, check.names = FALSE))
blank <- function(header, n) {
  out <- as.data.frame(lapply(header, function(x) rep("", n)), stringsAsFactors = FALSE)
  names(out) <- header
  out
}
number_string <- function(x) format(x, digits = 15, scientific = FALSE, trim = TRUE)
input_rows <- function(measure, year, value, source_type, source_reference, notes, transformation = "") {
  out <- blank(input_header, length(value))
  out$assessment_id <- assessment_id
  out$type <- "catch"
  out$measure <- measure
  out$basis <- "biomass"
  out$sex <- "combined"
  out$region <- "Eastern Baltic cod, ICES SDs 24-32"
  out$season <- "annual"
  out$year <- number_string(year)
  out$year_basis <- "calendar_year"
  out$value <- number_string(value)
  out$unit <- "tonnes"
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}

landings <- summary[!is.na(summary$landings), , drop = FALSE]
discards <- summary[!is.na(summary$discards), , drop = FALSE]
input_rows <- rbind(
  input_rows(
    "landings_biomass", landings$year, landings$landings,
    "official_table", paste("ICES WGBFAS 2024, Table 2.1.11", report_url),
    paste(
      "Annual aggregate landings in tonnes, transcribed as printed.",
      "The table marks the Landings heading with an asterisk and gives the footnote 'average of 2018-2022'; its exact applicability to the annual values is unclear.",
      "These are not the fleet- and quarter-specific catch inputs used by Stock Synthesis."
    )
  ),
  input_rows(
    "discard_biomass", discards$year, discards$discards,
    "official_table", paste("ICES WGBFAS 2024, Table 2.1.11", report_url),
    paste(
      "Annual aggregate discards in tonnes, transcribed as printed.",
      "No values are reported before 1966; blank years are not treated as zero.",
      "These are not the fleet- and quarter-specific catch inputs used by Stock Synthesis."
    )
  ),
  input_rows(
    "total_biomass", 2024L, 1065,
    "official_document", paste("ICES WGBFAS 2024, section 2.1.4.1", report_url),
    "The assessment report states that 2024 total catch was set to 1065 tonnes, equal to 2023 total catch. No landings/discards or fleet/quarter split is reported for this assumed value.",
    "Copied the stated model catch assumption; not split into components."
  )
)
input_rows <- input_rows[order(input_rows$measure, as.integer(input_rows$year)), , drop = FALSE]

assessment_file <- file.path(database, "assessments.csv")
assessments <- utils::read.csv(assessment_file, stringsAsFactors = FALSE, check.names = FALSE, skipNul = TRUE)
assessment_index <- which(assessments$assessment_id == assessment_id)
if (length(assessment_index) != 1L) stop("Expected one Eastern Baltic cod 2024 assessment row.", call. = FALSE)
if (assessments$inputs_status[assessment_index] != "not_started") {
  stop("The assessment input status has changed; review before importing.", call. = FALSE)
}
assessments$inputs_status[assessment_index] <- "partial"
assessments$notes[assessment_index] <- sub(
  "",
  "Some aggregate catches are recovered, but full model inputs remain unavailable.",
  assessments$notes[assessment_index],
  fixed = TRUE
)
assessments$notes[assessment_index] <- paste(
  assessments$notes[assessment_index],
  "Aggregate annual landings/discards and the stated 2024 total-catch assumption are recovered, but the complete fleet/quarter catch series and other model inputs remain unavailable."
)

assumption_file <- file.path(database, "assumptions.csv")
assumptions <- utils::read.csv(assumption_file, stringsAsFactors = FALSE, check.names = FALSE, skipNul = TRUE)
recovery_index <- which(
  assumptions$assessment_id == assessment_id &
    assumptions$component == "assessment" & assumptions$setting == "input_data_recovery"
)
if (length(recovery_index) != 1L) stop("Expected one input-data recovery assumption.", call. = FALSE)
assumptions$value[recovery_index] <- paste(
  "Aggregate annual landings/discards from Table 2.1.11 and the assumed 2024 total catch were recovered;",
  "complete fleet/quarter catch data, compositions, survey observations, and full biological input surfaces remain unavailable"
)
assumptions$notes[recovery_index] <- paste(
  "The published aggregate catch rows do not replace the fleet- and quarter-specific input structure.",
  "No input observations are fabricated or reconstructed from fitted quantities."
)
if (any(assumptions$assessment_id == assessment_id & assumptions$setting == "catch_input_structure")) {
  stop("The catch-input structure assumption already exists; review before importing.", call. = FALSE)
}
new_assumption <- as.data.frame(lapply(assumptions, function(x) ""), stringsAsFactors = FALSE)
new_assumption$assessment_id <- assessment_id
new_assumption$component <- "catch"
new_assumption$setting <- "catch_input_structure"
new_assumption$value <- "Total catch biomass is divided between active and passive fleets from 1987 onwards, and catches for both fleets are divided by quarter"
new_assumption$source_reference <- paste("ICES WGBFAS 2024, section 2.1.4.1", report_url)
new_assumption$notes <- "The report describes these dimensions but does not publish the full annual fleet-by-quarter inputs. Table 2.1.11 contains aggregate landings/discards only."
assumptions <- rbind(assumptions, new_assumption)

existing <- file(input_file, open = "rt")
invisible(readLines(existing, n = 1L, warn = FALSE))
found_input <- FALSE
repeat {
  lines <- readLines(existing, n = 50000L, warn = FALSE)
  if (!length(lines)) break
  if (any(startsWith(lines, paste0('"', assessment_id, '"')))) {
    found_input <- TRUE
    break
  }
}
close(existing)
if (found_input) stop("Inputs already exist for this assessment; refusing to duplicate them.", call. = FALSE)

cat(
  "Verified WGBFAS 2024 aggregate catch extraction:", nrow(landings), "landings rows;",
  nrow(discards), "discards rows; one stated 2024 total-catch assumption.\n"
)
if (dry_run) {
  cat("Dry run: no database files changed.\n")
} else {
  write.table(input_rows, input_file, sep = ",", append = TRUE, row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "\r\n", fileEncoding = "UTF-8")
  data.table::fwrite(assessments, assessment_file, quote = TRUE, na = "", eol = "\r\n")
  data.table::fwrite(assumptions, assumption_file, quote = TRUE, na = "", eol = "\r\n")
  cat("Imported aggregate Eastern Baltic cod 2024 catch inputs and marked input coverage partial.\n")
}
