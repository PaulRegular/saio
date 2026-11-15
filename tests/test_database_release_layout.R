
local({
  source("R/read_database.R", local = TRUE)
  work <- tempfile("saio-release-check-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  assets <- file.path(work, "assets")
  database <- file.path(work, "database")
  dir.create(assets)
  dir.create(database)
  # The checkout already contains the tracked candidate register at restore time.
  candidates <- file.path(database, "candidates.csv")
  writeLines(c("candidate_id", "fixture"), candidates)
  candidate_hash <- tools::md5sum(candidates)

  sha256 <- function(path) {
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    unclass(as.character(openssl::sha256(con)))
  }
  tables <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
  rows <- lapply(tables, function(table) {
    asset <- paste0(table, ".csv.gz")
    csv <- file.path(work, paste0(table, ".csv"))
    writeLines(c("id", table), csv, useBytes = TRUE)
    bytes <- readBin(csv, "raw", n = file.size(csv))
    gz <- gzfile(file.path(assets, asset), "wb")
    writeBin(bytes, gz)
    close(gz)
    data.frame(release = "test", schema_version = "1", table, asset, rows = 1,
      csv_bytes = length(bytes), csv_sha256 = sha256(csv),
      asset_bytes = file.size(file.path(assets, asset)),
      asset_sha256 = sha256(file.path(assets, asset)))
  })
  write.csv(do.call(rbind, rows), file.path(assets, "manifest.csv"),
    row.names = FALSE)
  result <- system2(file.path(R.home("bin"), "Rscript"),
    c("scripts/003_restore_release.R", shQuote(assets), shQuote(database)),
    stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(result, "status"))) stop(paste(result, collapse = "\n"))
  stopifnot(
    identical(tools::md5sum(candidates), candidate_hash),
    setequal(list.files(database), c("candidates.csv", paste0(tables, ".csv"))),
    identical(names(read_database(database)), c(tables, "database_source", "commit"))
  )
  message("Release restore and reader use the five canonical tables.")
})
