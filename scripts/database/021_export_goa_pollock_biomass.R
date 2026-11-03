# Official-run biomass from final GOA pollock Table 1.23
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
cache <- file.path(root, "source_cache/afsc_pollock_goa_2024")
text_path <- file.path(cache, "report_table_1_23.txt")
if (file.exists(text_path)) {
  text <- paste(readLines(text_path, encoding = "UTF-8"), collapse = "\n")
} else {
  if (!requireNamespace("pdftools", quietly = TRUE)) stop("Install pdftools to extract the cached report.")
  text <- pdftools::pdf_text(file.path(cache, "2024_GOA_pollock_SAFE_final.pdf"))[52]
}
stopifnot(grepl("Table 1.23", text, fixed = TRUE), grepl("2024 assessment", text, fixed = TRUE))
lines <- strsplit(text, "\n")[[1]]
cells <- strsplit(trimws(gsub(",", "", lines, fixed = TRUE)), "[[:space:]]+")
cells <- Filter(function(x) {
  length(x) > 2 && grepl("^[0-9]{4}$", x[1]) &&
    grepl("^[0-9]+$", x[2]) && as.integer(x[1]) %in% 1977:2024
}, cells)
stopifnot(all(lengths(cells) == ifelse(vapply(cells, function(x) x[1] == "2024", logical(1)), 7, 11)))
rows <- do.call(rbind, lapply(cells, function(x) {
  data.frame(
    year = as.integer(x[1]), value = as.numeric(x[2]), ssb = as.numeric(x[3]), recruitment = as.numeric(x[5])
  )
}))
stopifnot(identical(rows$year, 1977:2024), tail(rows$value, 1) == 1005)
write.csv(rows, file.path(cache, "report_age3plus_biomass.csv"), row.names = FALSE)
message("Staged 48 official 2024 biomass values; prior-assessment columns excluded.")
