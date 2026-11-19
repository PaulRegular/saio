.saio_user_data_dir <- function() {
  file.path(tools::R_user_dir("saio", "data"), "release")
}

.saio_release_tag <- function(tag) {
  is.character(tag) && length(tag) == 1L && !is.na(tag) &&
    grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", tag)
}

.saio_release_manifest <- function(database_dir) {
  path <- file.path(database_dir, "manifest.csv")
  if (!file.exists(path)) {
    stop("SAIO release manifest is missing: ", path, call. = FALSE)
  }
  manifest <- tryCatch(
    utils::read.csv(path, colClasses = "character", check.names = FALSE,
      na.strings = NULL, fill = FALSE),
    error = function(e) NULL
  )
  fields <- c("release", "schema_version", "table", "asset", "rows",
    "csv_bytes", "csv_sha256", "asset_bytes", "asset_sha256")
  valid <- !is.null(manifest) && identical(names(manifest), fields) &&
    nrow(manifest) == length(.saio_tables) && !anyNA(manifest) &&
    setequal(manifest$table, .saio_tables) &&
    all(manifest$schema_version == "1") &&
    .saio_release_tag(unique(manifest$release)) &&
    all(manifest$asset == paste0(manifest$table, ".csv.gz"))
  if (valid) {
    counts <- unlist(manifest[c("rows", "csv_bytes", "asset_bytes")],
      use.names = FALSE)
    hashes <- unlist(manifest[c("csv_sha256", "asset_sha256")], use.names = FALSE)
    valid <- all(grepl("^[0-9]+$", counts)) &&
      all(is.finite(as.numeric(counts))) &&
      all(grepl("^[[:xdigit:]]{64}$", hashes))
  }
  if (!valid) {
    stop("Invalid or unsupported SAIO release manifest: ", path, call. = FALSE)
  }
  for (name in c("rows", "csv_bytes", "asset_bytes")) {
    manifest[[name]] <- as.numeric(manifest[[name]])
  }
  manifest[match(.saio_tables, manifest$table), , drop = FALSE]
}

.saio_verify_asset <- function(path, bytes, digest) {
  info <- file.info(path)
  if (!isTRUE(!info$isdir && info$size == bytes)) {
    stop("Missing or invalid SAIO file: ", basename(path), call. = FALSE)
  }
  stream <- file(path, "rb")
  on.exit(close(stream))
  hash <- unclass(as.character(openssl::sha256(stream)))
  if (!identical(hash, tolower(digest))) {
    stop("Checksum mismatch for SAIO file: ", basename(path), call. = FALSE)
  }
  invisible(TRUE)
}

.saio_verify_download <- function(directory, manifest) {
  for (i in seq_len(nrow(manifest))) {
    .saio_verify_asset(file.path(directory, manifest$asset[i]),
      manifest$asset_bytes[i], manifest$asset_sha256[i])
  }
}

.saio_fetch_file <- function(url, destfile) {
  old <- options(timeout = max(300, getOption("timeout", 60)))
  on.exit(options(old), add = TRUE)
  status <- tryCatch(
    suppressWarnings(utils::download.file(url, destfile, method = "libcurl",
      mode = "wb", quiet = TRUE)),
    error = function(e) stop("Could not download ", basename(destfile),
      " from GitHub. ", conditionMessage(e), call. = FALSE)
  )
  if (!identical(as.integer(status), 0L)) {
    stop("Could not download ", basename(destfile), " from GitHub.", call. = FALSE)
  }
}

.saio_download <- function(release, database_dir, download = .saio_fetch_file) {
  if (!.saio_release_tag(release)) {
    stop("Supply \"latest\" or one SAIO release tag.", call. = FALSE)
  }
  if (!is.character(database_dir) || length(database_dir) != 1L ||
      is.na(database_dir) || !nzchar(database_dir)) {
    stop("Supply one folder path for database_dir.", call. = FALSE)
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Install the R package 'openssl' to verify SAIO release checksums.",
      call. = FALSE)
  }
  database_dir <- path.expand(database_dir)
  reuse <- function(manifest) {
    .saio_verify_download(database_dir, manifest)
    directory <- normalizePath(database_dir, winslash = "/", mustWork = TRUE)
    message("Using SAIO release ", manifest$release[1L], " in ", directory)
    directory
  }
  occupied <- function() {
    stop("The destination already exists: ", database_dir,
      ". Choose a new folder with database_dir.", call. = FALSE)
  }
  existing <- NULL
  if (file.exists(database_dir)) {
    existing <- tryCatch(.saio_release_manifest(database_dir),
      error = function(e) occupied())
    if (release != "latest") {
      if (!identical(existing$release[1L], release)) occupied()
      return(invisible(tryCatch(reuse(existing), error = function(e) occupied())))
    }
  }

  parent <- dirname(database_dir)
  if (!dir.exists(parent) && !dir.create(parent, recursive = TRUE)) {
    stop("Could not create the SAIO download folder: ", parent, call. = FALSE)
  }
  parent <- normalizePath(parent, winslash = "/", mustWork = TRUE)
  database_dir <- file.path(parent, basename(database_dir))
  staging <- tempfile(".saio-download-", tmpdir = parent)
  if (!dir.create(staging)) stop("Could not stage the SAIO download.", call. = FALSE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  base_url <- "https://github.com/PaulRegular/saio/releases"
  asset_url <- function(tag, asset) paste(base_url, "download", tag, asset, sep = "/")
  manifest_url <- if (release == "latest") {
    paste0(base_url, "/latest/download/manifest.csv")
  } else {
    asset_url(release, "manifest.csv")
  }
  download(manifest_url, file.path(staging, "manifest.csv"))
  manifest <- .saio_release_manifest(staging)
  tag <- manifest$release[1L]
  if (release != "latest" && !identical(tag, release)) {
    stop("The SAIO manifest identifies release ", tag, " instead of ", release,
      ".", call. = FALSE)
  }
  if (!is.null(existing)) {
    if (!identical(existing, manifest)) occupied()
    return(invisible(tryCatch(reuse(manifest), error = function(e) occupied())))
  }

  for (asset in manifest$asset) {
    download(asset_url(tag, asset), file.path(staging, asset))
  }
  .saio_verify_download(staging, manifest)
  if (file.exists(database_dir)) occupied()
  if (!file.rename(staging, database_dir)) {
    stop("Could not install the verified SAIO release in ", database_dir, ".",
      call. = FALSE)
  }
  message("Downloaded SAIO release ", tag, " to ", database_dir)
  invisible(database_dir)
}

#' Download a SAIO data release
#'
#' Download the five compressed stock assessment tables and their manifest
#' from a SAIO release on GitHub. The download checks the size and SHA-256
#' checksum of each table against the manifest. R can read the compressed
#' tables directly.
#'
#' @param release Use `"latest"` for the latest published data release,
#'   or supply a release tag to download a specific version.
#' @param database_dir Folder for the downloaded tables. The default is the
#'   `release` subfolder of R's user data directory for SAIO. Supply a path
#'   such as `"D:/SAIO/data"` to use another drive.
#'
#' @details
#' The function reuses an intact copy of the requested release. Choose a
#' new folder to keep another release or when the destination already
#' contains other data. Include the release tag when reporting an analysis.
#'
#' @returns The absolute path to the local data folder, invisibly. Pass this
#'   path as `database_dir` to the catalogue and read functions when using a
#'   custom folder.
#' @seealso [list_stocks()], [list_assessments()], [read_database()]
#' @rdname saio-download
#' @export
download_database <- function(release = "latest",
                              database_dir = .saio_user_data_dir()) {
  .saio_download(release, database_dir)
}
