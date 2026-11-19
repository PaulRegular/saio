library(saio)

local({
  work <- tempfile("saio package test ")
  stopifnot(dir.create(work))
  on.exit(unlink(work, recursive = TRUE))
  assets <- file.path(work, "release fixtures")
  plain <- file.path(work, "plain tables")
  stopifnot(dir.create(assets), dir.create(plain))

  stock_ids <- c("001", "002", "003")
  assessment_ids <- c("001_2025", "001_2024", "002_2025")
  fixtures <- list(
    stocks = data.frame(stock_id = stock_ids,
      common_name = c("Northern cod", "Sole", "Cod from Qu\u00e9bec"),
      scientific_name = c("Gadus morhua", "Solea solea", "Gadus morhua"),
      authority_stock_id = c("001", "002", "003")),
    assessments = data.frame(assessment_id = assessment_ids,
      stock_id = stock_ids[c(1, 1, 2)], assessment_year = c("2025", "2024", "2025"),
      is_current = c(TRUE, FALSE, TRUE)),
    assumptions = data.frame(assessment_id = assessment_ids,
      value = c("0.2", "0.3", "age dependent"),
      notes = c("Original, checked.\nSource says \"fixed\".", "", NA)),
    inputs = data.frame(assessment_id = c(rep(assessment_ids[3], 50000),
      assessment_ids[c(1, 2)]), year = "2025", age = 2.5, value = 3,
      sample_size = NA_real_),
    outputs = data.frame(assessment_id = assessment_ids, year = 2025L,
      value = c(15.1, 14, 50), lwr = c(9, NA, 30))
  )
  tag <- "saio-test-v1"
  manifest <- do.call(rbind, lapply(names(fixtures), function(table) {
    csv <- file.path(plain, paste0(table, ".csv"))
    if (table == "stocks") {
      # Write the UTF-8 fixture explicitly, including under an ASCII check locale.
      lines <- c('"stock_id","common_name","scientific_name","authority_stock_id"',
        '"001","Northern cod","Gadus morhua","001"',
        '"002","Sole","Solea solea","002"',
        '"003","Cod from Qu\u00e9bec","Gadus morhua","003"')
      writeLines(enc2utf8(lines), csv, useBytes = TRUE)
    } else {
      utils::write.csv(fixtures[[table]], csv, row.names = FALSE)
    }
    bytes <- readBin(csv, "raw", n = file.size(csv))
    asset <- paste0(table, ".csv.gz")
    path <- file.path(assets, asset)
    gz <- gzfile(path, "wb")
    writeBin(bytes, gz)
    close(gz)
    hash <- function(path) {
      con <- file(path, "rb")
      on.exit(close(con))
      as.character(openssl::sha256(con))
    }
    data.frame(release = tag, schema_version = "1", table, asset,
      rows = nrow(fixtures[[table]]), csv_bytes = length(bytes), csv_sha256 = hash(csv),
      asset_bytes = file.size(path), asset_sha256 = hash(path))
  }))
  utils::write.csv(manifest, file.path(assets, "manifest.csv"), row.names = FALSE)

  expect_error <- function(expr, message) {
    error <- tryCatch({ force(expr); NULL }, error = identity)
    stopifnot(inherits(error, "error"),
      grepl(message, conditionMessage(error), fixed = TRUE))
  }
  queries <- character()
  fetch <- function(url, destfile) {
    queries <<- c(queries, url)
    stopifnot(file.copy(file.path(assets, basename(url)), destfile))
    invisible(NULL)
  }

  destination <- file.path(work, "download with spaces")
  received <- saio:::.saio_download("latest", destination, download = fetch)
  github <- "https://github.com/PaulRegular/saio/releases/"
  stopifnot(
    identical(received, normalizePath(destination, winslash = "/")),
    identical(queries, c(paste0(github, "latest/download/manifest.csv"),
      paste0(github, "download/", tag, "/", manifest$asset))),
    setequal(list.files(destination), c("manifest.csv", manifest$asset))
  )
  queries <- character()
  stopifnot(identical(saio:::.saio_download(tag, destination, download = fetch), received),
    !length(queries))
  stopifnot(identical(saio:::.saio_download("latest", destination, download = fetch), received),
    identical(queries, paste0(github, "latest/download/manifest.csv")))
  expect_error(saio:::.saio_download("another-release", destination, download = fetch), "Choose a new folder")
  expect_error(saio:::.saio_download("wrong-tag", file.path(work, "wrong"), download = fetch),
    "instead of wrong-tag")
  expect_error(saio:::.saio_download("../bad", file.path(work, "bad"), download = fetch),
    "release tag")

  corrupt_fetch <- function(url, destfile) {
    fetch(url, destfile)
    if (basename(url) == "outputs.csv.gz") {
      bytes <- readBin(destfile, "raw", n = file.size(destfile))
      bytes[1L] <- as.raw(0L)
      writeBin(bytes, destfile)
    }
  }
  failed <- file.path(work, "failed")
  expect_error(saio:::.saio_download("latest", failed, download = corrupt_fetch), "Checksum mismatch")
  stopifnot(!file.exists(failed), !length(list.files(work, pattern = "^[.]saio-download-",
    all.files = TRUE)))
  expect_error(saio:::.saio_download("latest", plain, download = fetch), "Choose a new folder")
  interrupted_fetch <- function(url, destfile) {
    if (basename(url) == "inputs.csv.gz") stop("Connection interrupted")
    fetch(url, destfile)
  }
  interrupted <- file.path(work, "interrupted")
  expect_error(saio:::.saio_download("latest", interrupted,
    download = interrupted_fetch), "Connection interrupted")
  stopifnot(!file.exists(interrupted), !length(list.files(work,
    pattern = "^[.]saio-download-", all.files = TRUE)))

  tmp_before <- list.files(tempdir(), all.files = TRUE)
  full <- read_database(received)
  stock <- read_database(received, stock_id = "001")
  selected <- read_database(received, assessment_id = "001_2025")
  catalogue_only <- read_database(received, stock_id = "003")
  stopifnot(
    identical(list_stocks(database_dir = received)$stock_id, stock_ids),
    identical(list_stocks("COD", received)$stock_id, stock_ids[c(1, 3)]),
    identical(list_stocks("qu\u00e9bec", received)$stock_id, "003"),
    identical(list_assessments("001", received)$assessment_id, assessment_ids[1:2]),
    identical(stock$assessments$assessment_id, assessment_ids[1:2]),
    identical(selected$assessments$assessment_id, "001_2025"),
    identical(selected$stocks$stock_id, "001"),
    identical(selected$inputs$age, 2.5),
    identical(selected$inputs$year, 2025L),
    identical(selected$assumptions$value, "0.2"),
    identical(selected$assumptions$notes, fixtures$assumptions$notes[1L]),
    identical(selected$database_release, tag),
    identical(selected$database_source, "release"),
    is.na(selected$commit),
    identical(names(read_database(received, stock_id = "001", tables = "outputs")),
      c("outputs", "database_source", "commit", "database_release")),
    nrow(catalogue_only$assessments) == 0L,
    nrow(catalogue_only$inputs) == 0L,
    identical(catalogue_only$inputs$age, numeric())
  )
  for (table in c("assumptions", "inputs", "outputs")) {
    rows <- full[[table]][full[[table]]$assessment_id %in% assessment_ids[1:2], , drop = FALSE]
    rownames(rows) <- NULL
    stopifnot(identical(stock[[table]], rows),
      identical(saio:::.saio_read_table(file.path(plain, paste0(table, ".csv")),
        table, assessment_ids[1:2], "assessment_id"), rows))
  }
  stopifnot(identical(list.files(tempdir(), all.files = TRUE), tmp_before),
    setequal(list.files(destination), c("manifest.csv", manifest$asset)))

  expect_error(read_database(received, stock_id = "004"), "list_stocks()")
  expect_error(read_database(received, assessment_id = "004_2025"), "list_assessments()")
  expect_error(read_database(received, stock_id = "001", assessment_id = "001_2025"),
    "either stock_id or assessment_id")
  expect_error(read_database(received, tables = "unknown"), "Choose from these SAIO tables")

  # Browsing and table requests only need their relevant files.
  inputs <- file.path(received, "inputs.csv.gz")
  stopifnot(file.rename(inputs, paste0(inputs, ".saved")))
  stopifnot(nrow(list_stocks(database_dir = received)) == 3L,
    nrow(list_assessments(database_dir = received)) == 3L,
    nrow(read_database(received, assessment_id = "001_2025", tables = "outputs")$outputs) == 1L)
  expect_error(read_database(received, assessment_id = "001_2025"), "inputs.csv.gz")
})
