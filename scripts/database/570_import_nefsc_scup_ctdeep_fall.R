# Supplement the 2015 S60_BASE_18 record with the CTDEEP fall source table.
# Run from the repository root. Omit --write for source verification only.
assessment_id <- "nefsc_scup_2015"
survey <- "CTDEEP fall trawl survey"
source_ref <- "NEFSC Reference Document 15-08, Table A43, p. 133"
pdf <- file.path("source_cache", assessment_id, "NEFSC_15-08_60th_SAW_Assessment_Report.pdf")
source_hash <- "bba43370850717552189fc7a44d314e51a76a76d930e51443e51f2da7924cc6f"
if (!file.exists(pdf)) stop("Cache the report identified in provenance/nefsc_scup_2015/manifest.csv.")
if (as.character(openssl::sha256(file(pdf))) != source_hash) stop("Unexpected source PDF checksum.")

page <- pdftools::pdf_text(pdf)[142L]
stopifnot(grepl("Table A43. CTDEEP fall trawl survey", page, fixed = TRUE))
lines <- trimws(strsplit(page, "\n")[[1L]])
year_lines <- grep("^(19|20)[0-9]{2} +", lines)
fields <- function(line) strsplit(line, "\\s+")[[1L]]
table <- do.call(rbind, lapply(year_lines, function(i) {
  values <- fields(lines[[i]])
  # The PDF splits the corrected 2013 row after an age-0 xxx.xx placeholder.
  if (values[1L] == "2013") {
    stopifnot(identical(values, c("2013", "xxx.xx")))
    values <- c("2013", fields(lines[[i + 1L]]))
    stopifnot(values[2L] == "17.74", values[13L] == "40.69")
  }
  if (values[1L] == "2010") {
    stopifnot(identical(values, c("2010", "n/a", "n/a")))
    return(NULL)
  }
  stopifnot(length(values) == 14L)
  as.numeric(values)
}))
counts <- table[, 2:12]
years <- as.integer(table[, 1L])
stopifnot(
  identical(years, setdiff(1984:2014, 2010L)),
  all(is.finite(counts) & counts >= 0),
  all(round(rowSums(counts), 2L) == table[, 13L])
)

input_path <- file.path("database", "inputs.csv")
assumption_path <- file.path("database", "assumptions.csv")
assessment_path <- file.path("database", "assessments.csv")
canonical_rows <- function(path, values) {
  header <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  size <- max(lengths(values))
  out <- as.data.frame(matrix(NA_character_, size, length(header)))
  names(out) <- header
  for (field in names(values)) out[[field]] <- as.character(values[[field]])
  out
}
ages <- rep(0:10, nrow(table))
common <- list(
  assessment_id = assessment_id, type = "index", basis = "numbers", survey = survey,
  region = "Long Island Sound", season = "fall", year_basis = "calendar_year",
  unit = "fish per tow", source_type = "official_table", source_reference = source_ref
)
at_age <- canonical_rows(input_path, c(common, list(
  measure = ifelse(ages == 10L, "index_by_age_group", "numbers_at_age"),
  year = rep(years, each = 11L), age = ages, value = as.vector(t(counts)),
  notes = ifelse(ages == 10L,
    "Age 10 denotes the published 10+ group. No survey in 2010.",
    "Stratified mean numbers at source age. Printed zeros retained. No survey in 2010.")
)))
totals <- canonical_rows(input_path, c(common, list(
  measure = "total_numbers", year = years, value = table[, 13L],
  notes = "Published total number per tow across source ages 0–10+. Same survey observations as the age rows."
)))
assumption <- canonical_rows(assumption_path, list(
  assessment_id = assessment_id, component = "index", survey = survey,
  region = "Long Island Sound", season = "fall", setting = "CTDEEP_fall_index",
  value = "September–October stratified random trawl survey, 1984–2014 except 2010. Table A43 reports mean numbers per tow at ages 0–10+ and aggregate numbers per tow.",
  source_reference = paste(source_ref, "and sections A6.6, A8.1.3, A8.3.1"),
  notes = paste(
    "The survey is listed in the final S60_BASE_18 diagnostics.",
    "The assessment used an aggregate index and age composition, with model ages 0–7+.",
    "Exact fitted composition vectors, CV adjustments and numerical timing are unresolved."
  )
))
append_rows <- function(path, data) {
  write.table(data, file = path, sep = ",", quote = TRUE, qmethod = "double",
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8")
}
has_survey <- function(path) {
  con <- file(path, open = "r", encoding = "UTF-8")
  on.exit(close(con))
  repeat {
    rows <- readLines(con, n = 20000L, warn = FALSE)
    if (!length(rows)) return(FALSE)
    scup <- startsWith(rows, paste0('"', assessment_id, '",'))
    if (any(grepl(paste0('"', survey, '"'), rows[scup], fixed = TRUE))) return(TRUE)
  }
}

if ("--write" %in% commandArgs(trailingOnly = TRUE)) {
  if (has_survey(input_path) || has_survey(assumption_path)) {
    stop("CTDEEP fall rows are already present. Review them before writing.")
  }
  assessments <- readLines(assessment_path, encoding = "UTF-8", warn = FALSE)
  row <- which(startsWith(assessments, paste0('"', assessment_id, '",')))
  old <- "active NEFSC fall age indices and N/F/SSB/recruitment tables"
  new <- "NEFSC fall age indices, CTDEEP fall age indices and annual totals, and N/F/SSB/recruitment tables"
  stopifnot(length(row) == 1L, grepl(old, assessments[row], fixed = TRUE))
  assessments[row] <- sub(old, new, assessments[row], fixed = TRUE)
  append_rows(input_path, rbind(at_age, totals))
  append_rows(assumption_path, assumption)
  con <- file(assessment_path, open = "wb")
  writeLines(enc2utf8(assessments), con, useBytes = TRUE)
  close(con)
}
cat("Table A43 verified:", nrow(at_age), "age observations and", nrow(totals), "annual totals.\n")
