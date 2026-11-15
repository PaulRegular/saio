source("scripts/database/source_manifest_io.R", local = TRUE)

fields <- c("file", "url", "revision", "retrieved_on", "sha256", "bytes", "notes")
legacy <- data.frame(
  local_file = c("native.csv", "report.pdf"),
  source_url = c("https://example.test/native.csv", "https://example.test/report.pdf"),
  retrieved_utc = c("2026-11-10T13:01:00Z", ""),
  md5 = c("old-checksum", ""),
  verified_date = c("", "2026-11-11"),
  note = c("Pinned data", "")
)
manifest <- standardize_source_manifest(legacy)
stopifnot(
  identical(names(manifest)[seq_along(fields)], fields),
  identical(manifest[names(legacy)], legacy),
  identical(manifest$file, legacy$local_file),
  identical(manifest$retrieved_on, legacy$retrieved_utc),
  identical(manifest$notes, legacy$note),
  all(manifest$sha256 == ""),
  all(manifest$bytes == ""),
  identical(standardize_source_manifest(manifest), manifest)
)

local({
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path))
  write_source_manifest(legacy, path, row.names = FALSE, na = "")
  saved <- read.csv(path, colClasses = "character", check.names = FALSE)
  stopifnot(identical(saved, manifest))
})

files <- list.files("provenance", full.names = TRUE, recursive = TRUE, pattern = "\\.csv$")
files <- files[!grepl("/transcriptions/", files, fixed = TRUE)]
stopifnot(
  length(files) > 0L,
  all(basename(files) == "sources.csv"),
  all(vapply(files, function(file) {
    header <- read.csv(file, nrows = 0L, check.names = FALSE)
    identical(names(header)[seq_along(fields)], fields)
  }, logical(1L)))
)
cat(length(files), "tracked source manifests use the standard fields.\n")
