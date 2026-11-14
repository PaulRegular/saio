# Restore a release into the local database directory or an empty test directory.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% 1:2) {
  stop("Usage: Rscript scripts/database/003_restore_release.R <assets-dir> [database-dir]",
    call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("Install the R package 'openssl' to verify release checksums.", call. = FALSE)
}

restore_release <- function(assets, destination) {
  sha256 <- function(path) {
    stream <- file(path, "rb")
    on.exit(close(stream))
    unclass(as.character(openssl::sha256(stream)))
  }
  manifest <- read.csv(file.path(assets, "manifest.csv"), colClasses = "character",
    na.strings = NULL)
  expected <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
  fields <- c("release", "schema_version", "table", "asset", "rows", "csv_bytes",
    "csv_sha256", "asset_bytes", "asset_sha256")
  if (!identical(names(manifest), fields) || !setequal(manifest$table, expected) ||
    anyDuplicated(manifest$table) || !all(manifest$schema_version == "1") ||
    length(unique(manifest$release)) != 1L || !nzchar(manifest$release[1L]) ||
    !all(manifest$asset == paste0(manifest$table, ".csv.gz"))) {
    stop("Invalid or unsupported SAIO release manifest.", call. = FALSE)
  }
  if (any(!grepl("^[0-9]+$", unlist(manifest[c("rows", "csv_bytes", "asset_bytes")])))) {
    stop("Invalid size or row count in the SAIO release manifest.", call. = FALSE)
  }
  files <- paste0(manifest$table, ".csv")
  targets <- file.path(destination, files)
  if (any(file.exists(targets))) {
    stop("Choose an empty destination or move the existing SAIO tables before restoring.",
      call. = FALSE)
  }
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  staging <- tempfile(".saio-release-", tmpdir = destination)
  if (!dir.create(staging)) stop("Unable to stage restored SAIO tables.", call. = FALSE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)

  restore_table <- function(asset, csv) {
    input <- gzfile(asset, "rb")
    on.exit(close(input))
    output <- file(csv, "wb")
    on.exit(close(output), add = TRUE)
    repeat {
      bytes <- readBin(input, "raw", n = 1024L * 1024L)
      if (!length(bytes)) break
      writeBin(bytes, output)
    }
  }
  staged <- file.path(staging, files)
  for (i in seq_len(nrow(manifest))) {
    asset <- file.path(assets, manifest$asset[i])
    if (!isTRUE(file.size(asset) == as.numeric(manifest$asset_bytes[i])) ||
      !identical(sha256(asset), manifest$asset_sha256[i])) {
      stop("Missing or invalid release asset: ", manifest$asset[i], call. = FALSE)
    }
    restore_table(asset, staged[i])
    if (!isTRUE(file.size(staged[i]) == as.numeric(manifest$csv_bytes[i])) ||
      !identical(sha256(staged[i]), manifest$csv_sha256[i])) {
      stop("Restored table does not match the manifest: ", files[i], call. = FALSE)
    }
    cat("Verified", files[i], "\n")
  }
  if (any(file.exists(targets))) {
    stop("SAIO tables appeared in the destination during restoration.", call. = FALSE)
  }
  installed <- file.rename(staged, targets)
  if (!all(installed)) {
    unlink(targets[installed])
    stop("Could not install the verified SAIO table set.", call. = FALSE)
  }
  cat("Restored", manifest$release[1L], "to", normalizePath(destination), "\n")
}

restore_release(args[1L], if (length(args) == 2L) args[2L] else "database")
