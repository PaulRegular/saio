file_sha256 <- function(path) {
  stream <- file(path, "rb")
  on.exit(close(stream))
  as.character(openssl::sha256(stream))
}

gzip_copy <- function(from, to) {
  stream <- gzfile(to, "wb")
  on.exit(close(stream))
  writeBin(readBin(from, "raw", n = file.size(from)), stream)
}

release_fixture <- function(chunked = FALSE) {
  work <- tempfile("saio package test ")
  assets <- file.path(work, "release fixtures")
  plain <- file.path(work, "plain tables")
  stopifnot(dir.create(assets, recursive = TRUE), dir.create(plain))

  stock_ids <- c("001", "002", "003")
  assessment_ids <- c("001_2025", "001_2024", "002_2025")
  input_ids <- c(rep(assessment_ids[3], if (chunked) 50000L else 1L),
    assessment_ids)
  fixtures <- list(
    stocks = data.frame(stock_id = stock_ids,
      common_name = c("Northern cod", "Sole", "Cod from Qu\u00e9bec"),
      scientific_name = c("Gadus morhua", "Solea solea", "Gadus morhua"),
      authority_stock_id = stock_ids),
    assessments = data.frame(assessment_id = assessment_ids,
      stock_id = stock_ids[c(1, 1, 2)], assessment_year = c("2025", "2024", "2025"),
      is_current = c(TRUE, FALSE, TRUE)),
    assumptions = data.frame(assessment_id = assessment_ids,
      value = c("0.2", "0.3", "age dependent"),
      notes = c("Original, checked.\nSource says \"fixed\".", "", NA)),
    inputs = data.frame(assessment_id = input_ids, year = "2025",
      age = 2.5, value = 3, sample_size = NA_real_),
    outputs = data.frame(assessment_id = assessment_ids, year = 2025L,
      value = c(15.1, 14, 50), lwr = c(9, NA, 30))
  )

  tag <- "saio-test-v1"
  manifest <- do.call(rbind, lapply(names(fixtures), function(table) {
    csv <- file.path(plain, paste0(table, ".csv"))
    if (table == "stocks") {
      # Write UTF-8 bytes directly, including in an ASCII check locale.
      lines <- c('"stock_id","common_name","scientific_name","authority_stock_id"',
        '"001","Northern cod","Gadus morhua","001"',
        '"002","Sole","Solea solea","002"',
        '"003","Cod from Qu\u00e9bec","Gadus morhua","003"')
      writeLines(enc2utf8(lines), csv, useBytes = TRUE)
    } else {
      utils::write.csv(fixtures[[table]], csv, row.names = FALSE)
    }
    asset <- paste0(table, ".csv.gz")
    path <- file.path(assets, asset)
    gzip_copy(csv, path)
    data.frame(release = tag, schema_version = "1", table, asset,
      rows = nrow(fixtures[[table]]), csv_bytes = file.size(csv),
      csv_sha256 = file_sha256(csv), asset_bytes = file.size(path),
      asset_sha256 = file_sha256(path))
  }))
  utils::write.csv(manifest, file.path(assets, "manifest.csv"), row.names = FALSE)

  list(work = work, assets = assets, plain = plain, data = fixtures,
    manifest = manifest, tag = tag)
}
