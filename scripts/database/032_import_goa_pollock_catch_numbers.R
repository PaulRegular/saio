args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1]] else "."
root <- normalizePath(root, winslash = "/", mustWork = TRUE)
cache <- file.path(root, "source_cache/afsc_pollock_goa_2024")
database <- file.path(root, "database/inputs.csv")
pdf <- file.path(cache, "2024_GOA_pollock_SAFE_final.pdf")
report_url <- "https://files.npfmc.org/SAFE/2024/GOApollock.pdf"
source_reference <- paste0(report_url, "; Table 1.6, p. 37")

if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to extract the cached GOA pollock report.", call. = FALSE)
}
if (!file.exists(pdf)) stop("The cached final GOA pollock SAFE is missing.", call. = FALSE)
pages <- pdftools::pdf_text(pdf)
table_pages <- grep("Table 1\\.6\\. Catch at age", pages)
if (length(table_pages) != 1L) stop("Could not identify the unique Table 1.6 page.", call. = FALSE)
lines <- strsplit(pages[[table_pages]], "\\n")[[1]]
rows <- lapply(lines, function(line) {
  fields <- strsplit(gsub(",", "", trimws(line), fixed = TRUE), "[[:space:]]+")[[1]]
  if (length(fields) != 17L || !grepl("^(19|20)[0-9]{2}$", fields[[1]])) {
    return(NULL)
  }
  year <- as.integer(fields[[1]])
  if (!year %in% 1975:2023) {
    return(NULL)
  }
  values <- suppressWarnings(as.numeric(fields[-1]))
  if (anyNA(values) || any(!is.finite(values)) || any(values < 0)) {
    return(NULL)
  }
  data.frame(year = year, age = 1:15, value = values[1:15])
})
rows <- Filter(Negate(is.null), rows)
catch_numbers <- do.call(rbind, rows)
if (is.null(catch_numbers) || nrow(catch_numbers) != 49L * 15L ||
  !identical(sort(unique(catch_numbers$year)), 1975:2023) ||
  anyDuplicated(paste(catch_numbers$year, catch_numbers$age))) {
  stop("Table 1.6 did not yield exactly one catch value for every year-age cell.", call. = FALSE)
}
utils::write.csv(catch_numbers,
  file.path(cache, "report_catch_numbers_at_age.csv"),
  row.names = FALSE, na = ""
)

inputs <- utils::read.csv(database,
  stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)
new <- data.frame(
  assessment_id = "afsc_pollock_goa_2024", type = "catch", measure = "numbers_at_age",
  basis = "numbers", fleet = "Combined fishery", survey = "", sex = "", region = "",
  season = "", year = catch_numbers$year, year_basis = "calendar_year",
  age = catch_numbers$age, value = catch_numbers$value, unit = "million fish",
  sampling_time = "", source_type = "official_table", source_reference = source_reference,
  transformation = "", notes = paste0(
    "Published catch numbers at age, reported in million fish and rounded to 0.01 million. ",
    "The official model fits age-1-2 and age-10+ pooled compositions; this finer report table is retained separately and used for the."
  ), observation_id = "", length_bin = "", length_bin_lower = "",
  length_bin_upper = "", sample_size = "", age_error = "", partition = "",
  stringsAsFactors = FALSE, check.names = FALSE
)
new <- new[names(inputs)]
keep <- !(inputs$assessment_id == "afsc_pollock_goa_2024" &
  inputs$measure == "numbers_at_age" &
  inputs$source_reference == source_reference)
lines <- readLines(database, warn = FALSE, encoding = "UTF-8")
writeLines(lines[c(TRUE, keep)], database, useBytes = TRUE)
utils::write.table(new, database,
  sep = ",", row.names = FALSE, col.names = FALSE,
  append = TRUE, quote = TRUE, na = ""
)
cat("Imported ", nrow(new), " age-specific catch values from Table 1.6.\n", sep = "")
