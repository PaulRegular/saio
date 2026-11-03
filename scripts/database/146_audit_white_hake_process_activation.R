# Rebuild only this assessment's assumptions from the reviewed native input.
base <- "."
cache <- file.path(base, "source_cache", "ck_nefsc_garmiii_tenuis_gom_gb")
input <- file.path(cache, "RUN_005.DAT")
stopifnot(file.exists(input),
  digest::digest(readBin(input, "raw", n = file.info(input)$size),
    serialize = FALSE, algo = "sha256") ==
    "5f864a5fca6769aa8d94b01bcf1b14cf03cc03bf32121f3f56061aaf5cb9885f")
review <- new.env()
review$commandArgs <- function(trailingOnly = FALSE) "--dry-run"
sys.source(file.path(base, "scripts", "database", "140_import_nefsc_white_hake_2025.R"), review)
path <- file.path(base, "database", "assumptions.csv")
contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
selected <- which(startsWith(lines, '"nefsc_white_hake_2025",'))
stopifnot(length(selected) > 0L,
  identical(selected, seq.int(min(selected), max(selected))))
tmp <- tempfile(tmpdir = dirname(path))
write.table(review$new_assumptions, tmp, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
replacement <- paste0(replacement, if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
lines <- c(head(lines, min(selected) - 1L), replacement,
  tail(lines, length(lines) - max(selected)))
bytes <- charToRaw(paste0(paste(lines, collapse = "\n"),
  if (endsWith(contents, "\n")) "\n" else ""))
if (!identical(bytes, charToRaw(contents))) {
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not update White Hake assumptions.")
}
unlink(tmp)
cat("White Hake source activation audit updated; observations and official outputs unchanged.\n")
