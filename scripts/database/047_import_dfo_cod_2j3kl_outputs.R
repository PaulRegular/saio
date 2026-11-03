root <- "."
cache <- file.path(root, "source_cache", "dfo_cod_2j3kl_2025")
pdf <- file.path(cache, "Fs70-5-2026-026-eng.pdf")
text_file <- sub("\\.pdf$", ".txt", pdf)

# Read the cached text extraction, or extract it from the authoritative PDF.
if (!file.exists(text_file)) {
  writeLines(pdftools::pdf_text(pdf), text_file)
}
text <- readLines(text_file, warn = FALSE, encoding = "UTF-8")
tables <- data.frame(
  number = 19:24,
  type = c("population", "biomass", "biomass", rep("mortality", 3)),
  measure = c(
    "numbers_at_age", "biomass_at_age", "mature_biomass_at_age",
    "total_mortality_at_age", "natural_mortality_at_age",
    "fishing_mortality_at_age"
  ),
  unit = c("million fish", "kt", "kt", rep("yr-1", 3)),
  first_page = c(50, 52, 54, 56, 58, 60)
)
path <- file.path(root, "database", "outputs.csv")
original <- readLines(path, warn = FALSE, encoding = "UTF-8")
outputs <- read.csv(
  text = original, colClasses = "character", na.strings = "",
  check.names = FALSE
)
new <- lapply(seq_len(nrow(tables)), function(i) {
  tab <- tables[i, ]
  start <- grep(paste0("^Table ", tab$number, "\\."), text)
  end <- grep(paste0("^Table ", tab$number + 1L, "\\."), text)
  stopifnot(length(start) == 1L, length(end) == 1L)
  lines <- text[seq.int(start + 1L, end - 1L)]
  lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines)]
  values <- lapply(lines, function(line) {
    as.numeric(gsub(",", "", strsplit(trimws(line), "\\s+")[[1L]]))
  })
  expected_years <- if (tab$number <= 21L) 1954:2025 else 1954:2024
  stopifnot(
    length(values) == length(expected_years),
    all(lengths(values) == 16L)
  )
  values <- do.call(rbind, values)
  stopifnot(
    identical(as.integer(values[, 1]), expected_years),
    all(is.finite(values)), all(values[, -1] >= 0)
  )
  rows <- outputs[rep(NA_integer_, length(expected_years) * 15L), ]
  rows$assessment_id <- "dfo_cod_2j3kl_2025"
  rows$type <- tab$type
  rows$measure <- tab$measure
  rows$year <- rep(expected_years, each = 15L)
  rows$age <- rep(0:14, length(expected_years))
  rows$value <- as.vector(t(values[, -1]))
  rows$unit <- tab$unit
  rows$source_type <- "official_table"
  rows$source_reference <- paste0(
    "DFO Research Document 2026/026, Table ",
    tab$number, ", pp. ", tab$first_page, "-",
    tab$first_page + 1L
  )
  rows$notes <- "Reported rounded age-specific estimate; age-specific uncertainty is not tabulated."
  rows
})
new <- do.call(rbind, new)
stopifnot(nrow(new) == 6435L)
replace <- outputs$assessment_id == "dfo_cod_2j3kl_2025" &
  outputs$measure %in% tables$measure
writeLines(original[c(TRUE, !replace)], path, useBytes = TRUE)
write.table(new, path,
  sep = ",", quote = TRUE, row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8"
)

cat("Imported Northern cod Tables 19-24: 6,435 reported age-specific values.\n")
