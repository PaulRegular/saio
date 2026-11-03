base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_hawg_dubius_ns/2026_san.sa.4")
assessment_id <- "ices_sandeel_area_4_2026_summary"
xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/21271"
source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21271"
xml_path <- file.path(cache, "SAG_21271.xml")
html_path <- file.path(cache, "SAG_21271_source_data.html")

if (!file.exists(xml_path) || !file.exists(html_path)) {
  stop("Cache the official SAG 21271 XML and source-data page before importing.",
    call. = FALSE)
}

xml <- paste(readLines(xml_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
html <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
tag_value <- function(text, tag) {
  match <- regmatches(text, regexec(paste0("<", tag, ">(.*?)</", tag, ">"),
    text, perl = TRUE))[[1L]]
  if (length(match) < 2L || !nzchar(match[2L])) NA_character_ else match[2L]
}
records <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>",
  xml, perl = TRUE))[[1L]]
field <- function(tag) unname(vapply(records, tag_value, character(1), tag = tag))
table_rows <- function(id) {
  table <- regmatches(html, regexec(paste0(
    "(?s)<table[^>]*id=\"", id, "\".*?</table>"
  ), html, perl = TRUE))[[1L]]
  if (!length(table) || is.na(table[1L]) || !nzchar(table[1L])) {
    stop("SAG table not found: ", id, call. = FALSE)
  }
  rows <- regmatches(table[1L], gregexpr("(?s)<tr\\b.*?</tr>",
    table[1L], perl = TRUE))[[1L]]
  lapply(rows, function(row) {
    cells <- regmatches(row, gregexpr("(?s)<t[dh]\\b.*?</t[dh]>", row,
      perl = TRUE))[[1L]]
    trimws(gsub("&nbsp;|&#160;", "", gsub("(?s)<[^>]+>", "", cells,
      perl = TRUE)))
  })
}
catch_table <- table_rows("gvFishData")
custom_table <- table_rows("gvAllFishData")
catch_cells <- do.call(rbind, catch_table[-1L])
custom_cells <- do.call(rbind, custom_table[-1L])
source <- data.frame(
  year = as.integer(unname(catch_cells[, 1L])),
  catches = unname(catch_cells[, 2L]),
  custom_year = as.integer(unname(custom_cells[, 1L])),
  dredge_age_0 = unname(custom_cells[, 2L]),
  dredge_age_1 = unname(custom_cells[, 3L]),
  stringsAsFactors = FALSE
)
catch_value <- suppressWarnings(as.numeric(source$catches))
index_0 <- suppressWarnings(as.numeric(source$dredge_age_0))
index_1 <- suppressWarnings(as.numeric(source$dredge_age_1))

stopifnot(
  identical(catch_table[[1L]], c("Year", "Catches")),
  identical(custom_table[[1L]], c("Year", "Custom1", "Custom2")),
  tag_value(xml, "AssessmentYear") == "2026",
  tag_value(xml, "StockCategory") == "5",
  tag_value(xml, "NameSystemProducedFile") ==
    "SAG - from a previous assessment (21271)",
  tag_value(xml, "CustomSeriesName1") == "Dredge survey Age 0",
  tag_value(xml, "CustomSeriesName2") == "Dredge survey Age 1",
  is.na(tag_value(xml, "CustomSeriesUnits1")),
  is.na(tag_value(xml, "CustomSeriesUnits2")),
  identical(source$year, 1993:2025),
  identical(source$custom_year, source$year),
  all(is.finite(catch_value) & catch_value >= 0),
  identical(which(is.finite(index_0)), which(source$year %in% 2008:2025)),
  identical(which(is.finite(index_1)), which(source$year %in% 2008:2025)),
  all(is.na(suppressWarnings(as.numeric(field("Recruitment"))))),
  all(is.na(suppressWarnings(as.numeric(field("StockSize"))))),
  all(is.na(suppressWarnings(as.numeric(field("FishingPressure")))))
)

blank <- function(file, n) {
  fields <- names(read.csv(file.path(database, file), nrows = 0,
    check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  x$assessment_id <- assessment_id
  x
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       survey = "", notes = "") {
  x <- blank("inputs.csv", length(year))
  x$type <- type
  x$measure <- measure
  x$basis <- basis
  x$survey <- survey
  x$sex <- "combined"
  x$region <- "Sandeel Area 4"
  x$year <- as.character(year)
  x$year_basis <- "calendar_year"
  x$age <- ifelse(is.na(age), "", as.character(age))
  x$value <- as.character(value)
  x$unit <- unit
  x$source_type <- "official_table"
  x$source_reference <- paste("ICES SAG assessment key 21271", source_url,
    xml_url, sep = "; ")
  x$notes <- notes
  x
}

catch_rows <- input_rows(
  "catch", "total_biomass", "biomass", source$year, NA_integer_,
  source$catches, "tonnes",
  notes = paste(
    "SAG Catches field for the separate 2026 category-5 summary.",
    "Annual total catch is retained as reported, not converted to catch-at-age",
    "or treated as a fitted age-composition likelihood."
  )
)
index_rows <- do.call(rbind, lapply(0:1, function(age) {
  value <- source[[paste0("dredge_age_", age)]]
  keep <- !is.na(value) & nzchar(value)
  input_rows(
    "index", "numbers_at_age", "index_scale", source$year[keep], age,
    value[keep], "number (index scale; multiplier not stated)",
    survey = "Dredge survey",
    notes = paste(
      "SAG custom series Dredge survey Age", age,
      "is retained on its published scale. The SAG export does not state",
      "its unit, multiplier, sampling time, or likelihood role; it is kept",
      "separate from the 2025 Dredge and Dredge2 series."
    )
  )
}))
inputs_add <- rbind(catch_rows, index_rows)
stopifnot(nrow(catch_rows) == 33L, nrow(index_rows) == 36L)

write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0("\"", id, "\",")))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0,
    check.names = FALSE))))
  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (!identical(selected, seq.int(min(selected), max(selected)))) {
      stop("Existing rows for the assessment are not contiguous in ", file,
        call. = FALSE)
    }
    replacement <- paste0(replacement,
      if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
    lines <- c(head(lines, min(selected) - 1L), replacement,
      tail(lines, length(lines) - max(selected)))
  } else {
    lines <- c(lines, replacement)
  }
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"),
    if (endsWith(contents, "\n")) "\n" else ""))
  writeBin(bytes, path)
}
write_rows("inputs.csv", inputs_add, assessment_id)

update_row <- function(file, matches, changes) {
  path <- file.path(database, file)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  table <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = "character")
  row <- which(matches(table))
  stopifnot(length(row) == 1L, length(lines) == nrow(table) + 1L)
  for (column in names(changes)) table[row, column] <- changes[[column]]
  lines[row + 1L] <- capture.output(write.csv(
    table[row, , drop = FALSE], row.names = FALSE, na = ""
  ))[[2L]]
  writeLines(lines, path, useBytes = TRUE)
}

update_row("assessments.csv", function(x) {
  x$assessment_id == assessment_id
}, list(
  data_url = source_url,
  inputs_status = "partial",
  outputs_status = "not_applicable",
  notes = paste(
    "Separate 2026 category-5 summary update. Official SAG data provide",
    "annual total catches and custom age-0/1 dredge series through 2025.",
    "The source reports no age-structured N, F, recruitment, or SSB outputs;",
    "custom-series units and likelihood role are not stated. The 2025",
    "age-based assessment remains a separate event."
  )
))
update_row("assumptions.csv", function(x) {
  x$assessment_id == assessment_id & x$setting == "separate_advice_vintage"
}, list(
  value = paste(
    "2026 category-5 advice summary is separate from the 2025 age-based assessment"
  ),
  source_reference = paste("ICES SAG assessment key 21271", source_url,
    xml_url, sep = "; "),
  notes = paste(
    "The SAG export identifies a previous assessment and contains no model",
    "name or age-structured population outputs. Its annual catch series and",
    "age-0/1 custom dredge data are recorded only under this 2026 event.",
    "Custom-series units and scaling are absent; do not mix them with the",
    "2025 age-based inputs."
  )
))

cat("Updated Area 4 2026 summary: 33 annual catch rows, 36 custom index rows, no model outputs.\n")
