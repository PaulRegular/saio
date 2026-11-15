standardize_source_manifest <- function(manifest) {
  aliases <- list(
    file = c("file", "local_file", "cached_file", "cache_file", "local_path", "relative_path", "path", "file_name", "source_file"),
    url = c("url", "source_url", "official_source_url"),
    revision = c("revision", "source_revision", "repository_revision", "pinned_revision", "version"),
    retrieved_on = c("retrieved_on", "retrieved_utc", "retrieved_at", "retrieval_date", "retrieved_date", "retrieved"),
    sha256 = c("sha256"),
    bytes = c("bytes", "size_bytes"),
    notes = c("notes", "note", "description", "represented_source", "purpose")
  )
  fields <- lapply(aliases, function(columns) {
    value <- rep("", nrow(manifest))
    for (column in intersect(columns, names(manifest))) {
      recorded <- as.character(manifest[[column]])
      use <- !nzchar(trimws(value)) & !is.na(recorded) & nzchar(trimws(recorded))
      value[use] <- recorded[use]
    }
    value
  })
  cbind(as.data.frame(fields, stringsAsFactors = FALSE),
    manifest[setdiff(names(manifest), names(fields))])
}

write_source_manifest <- function(manifest, file, ...) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(standardize_source_manifest(manifest), file, ...)
}
