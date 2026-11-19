test_that("a release downloads to a folder with spaces and can be reused", {
  fixture <- release_fixture()
  queries <- character()
  fetch <- function(url, destfile) {
    queries <<- c(queries, url)
    stopifnot(file.copy(file.path(fixture$assets, basename(url)), destfile))
  }

  destination <- file.path(fixture$work, "download with spaces")
  expected <- "https://github.com/PaulRegular/saio/releases/latest/download/manifest.csv"
  expect_message(
    received <- saio:::.saio_download("latest", destination, download = fetch),
    "Downloaded SAIO release"
  )
  expect_identical(received, normalizePath(destination, winslash = "/"))
  expect_identical(queries, c(expected, paste0(
    "https://github.com/PaulRegular/saio/releases/download/", fixture$tag, "/",
    fixture$manifest$asset
  )))
  expect_setequal(list.files(destination), c("manifest.csv", fixture$manifest$asset))

  queries <- character()
  expect_message(reused <- download_database(fixture$tag, destination), "Using SAIO release")
  expect_identical(reused, received)
  expect_message(
    latest <- saio:::.saio_download("latest", destination, download = fetch),
    "Using SAIO release"
  )
  expect_identical(latest, received)
  expect_identical(queries, expected)
})

test_that("the downloader validates release tags and destinations", {
  fixture <- release_fixture()
  fetch <- function(url, destfile) {
    stopifnot(file.copy(file.path(fixture$assets, basename(url)), destfile))
  }

  expect_error(download_database("../bad", fixture$work), "release tag")
  expect_error(download_database(fixture$tag, character()), "one folder path")
  expect_error(download_database("another-release", fixture$assets), "Choose a new folder")
  expect_error(download_database("latest", fixture$plain), "Choose a new folder")
  expect_error(
    saio:::.saio_download("wrong-tag", file.path(fixture$work, "wrong"), download = fetch),
    "instead of wrong-tag"
  )
})

test_that("checksum failures and interrupted downloads leave no partial release", {
  fixture <- release_fixture()
  fetch <- function(url, destfile) {
    stopifnot(file.copy(file.path(fixture$assets, basename(url)), destfile))
  }
  corrupt_fetch <- function(url, destfile) {
    fetch(url, destfile)
    if (basename(destfile) == "outputs.csv.gz") {
      bytes <- readBin(destfile, "raw", n = file.size(destfile))
      bytes[1L] <- as.raw(0L)
      writeBin(bytes, destfile)
    }
  }
  failed <- file.path(fixture$work, "failed")
  expect_error(saio:::.saio_download("latest", failed, download = corrupt_fetch),
    "Checksum mismatch")
  expect_false(file.exists(failed))
  expect_no_staging <- function() {
    expect_length(list.files(fixture$work, pattern = "^[.]saio-download-",
      all.files = TRUE), 0L)
  }
  expect_no_staging()

  interrupted_fetch <- function(url, destfile) {
    if (basename(destfile) == "inputs.csv.gz") stop("Connection interrupted")
    fetch(url, destfile)
  }
  interrupted <- file.path(fixture$work, "interrupted")
  expect_error(saio:::.saio_download("latest", interrupted, download = interrupted_fetch),
    "Connection interrupted")
  expect_false(file.exists(interrupted))
  expect_no_staging()
})
