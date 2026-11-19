# Source retrieval is separate from the routine database-to-model workflow.
cache_pacific_source <- function(stock_id, url, name, revision = "") {
  directory <- file.path("source_cache", stock_id)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(directory, name)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  manifest_file <- file.path(directory, "manifest.csv")
  manifest <- if (file.exists(manifest_file)) {
    read.csv(manifest_file, stringsAsFactors = FALSE)
  } else {
    data.frame(file = character(), url = character(), retrieved = character(),
               md5 = character(), revision = character(), status = character())
  }
  existing <- manifest$file == name & manifest$url == url
  valid_format <- function(path) {
    if (!file.exists(path)) return(FALSE)
    signature <- readBin(path, "raw", n = 5L)
    extension <- tolower(tools::file_ext(path))
    if (extension == "pdf") return(identical(signature, charToRaw("%PDF-")))
    if (extension == "zip") return(length(signature) >= 2L &&
                                    identical(signature[1:2], charToRaw("PK")))
    TRUE
  }
  if (any(existing) && file.exists(path) && valid_format(path) &&
      manifest$status[which(existing)[1L]] == "downloaded" &&
      identical(unname(tools::md5sum(path)), manifest$md5[which(existing)[1L]])) {
    return(path)
  }
  status <- tryCatch({
    utils::download.file(url, path, mode = "wb", quiet = TRUE)
    "downloaded"
  }, error = function(e) conditionMessage(e))
  if (status == "downloaded" && !valid_format(path)) {
    status <- "invalid file format (possibly an HTML error page)"
  }
  checksum <- if (status == "downloaded") unname(tools::md5sum(path)) else ""
  manifest <- rbind(manifest[!existing, ], data.frame(
    file = name, url = url, retrieved = format(Sys.Date(), "%Y-%m-%d"),
    md5 = checksum, revision = revision, status = status
  ))
  utils::write.csv(manifest, manifest_file, row.names = FALSE, na = "")
  if (status != "downloaded") cli::cli_abort("Could not cache {url}: {status}")
  path
}
