base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_nefsc_garmiii_morhua_gb_2024")
assessment_id <- "nefsc_cod_georges_bank_2024"
stocksmart_url <- "https://apps-st.fisheries.noaa.gov/stocksmart/"
data_url <- paste0(
  "https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/",
  "664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_data.rda"
)
data_sha256 <- "141db3599cbf37af3e019bd53d2323d829a719b273e8ab0226b73f6ad18620b0"
data_file <- file.path(cache, "stock_assessment_data_664c4237.rda")

stopifnot(
  file.exists(data_file),
  digest::digest(
    readBin(data_file, "raw", n = file.info(data_file)$size),
    algo = "sha256", serialize = FALSE
  ) == data_sha256
)

source_env <- new.env(parent = emptyenv())
load(data_file, envir = source_env)
stopifnot(exists("stock_assessment_data", envir = source_env, inherits = FALSE))
stocksmart <- source_env$stock_assessment_data
stocksmart <- stocksmart[stocksmart$assessment_id == 13596, , drop = FALSE]

stopifnot(
  nrow(stocksmart) == 138L,
  all(stocksmart$stock_id == 10509),
  all(stocksmart$assessment_year == 2024),
  all(stocksmart$stock_name == "Atlantic cod - Georges Bank"),
  all(stocksmart$assessment_type == "Operational"),
  all(stocksmart$stock_area == "Georges Bank"),
  !anyDuplicated(stocksmart[c("metric", "year")])
)

series <- function(metric, description, units) {
  x <- stocksmart[stocksmart$metric == metric, , drop = FALSE]
  x <- x[order(x$year), , drop = FALSE]
  stopifnot(
    nrow(x) == 46L,
    identical(as.integer(x$year), 1978:2023),
    all(is.finite(x$value)),
    all(x$description == description),
    all(x$units == units)
  )
  x
}

ssb <- series("Abundance", "Spawning Stock Biomass", "Metric Tons")
f_full <- series("Fmort", "F for Fully-Selected Fish", "Fully-selected F")
recruitment <- series("Recruitment", "Number of Fish - Age 1", "Thousand Recruits")

outputs_path <- file.path(database, "outputs.csv")
current_outputs <- read.csv(
  outputs_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
  check.names = FALSE
)
table_outputs <- current_outputs[
  current_outputs$assessment_id == assessment_id &
    current_outputs$source_type == "official_table",
  , drop = FALSE
]

check_table_overlap <- function(x, measure, tolerance = 0) {
  reported <- table_outputs[
    table_outputs$measure == measure &
      table_outputs$year %in% 2014:2023,
    , drop = FALSE
  ]
  reported <- reported[order(reported$year), , drop = FALSE]
  extracted <- x$value[match(reported$year, x$year)]
  stopifnot(
    nrow(reported) == 10L,
    identical(as.integer(reported$year), 2014:2023),
    all(is.finite(extracted)),
    all(abs(reported$value - extracted) <= tolerance)
  )
}

check_table_overlap(ssb, "SSB")
check_table_overlap(recruitment, "recruitment")
check_table_overlap(
  f_full, "fishing_mortality_at_age",
  tolerance = 0.0005
)

reference <- paste(
  stocksmart_url,
  data_url,
  "Pinned data snapshot; assessment_id=13596",
  sep = "; "
)
row_notes <- paste(
  "NOAA Stock SMART 2024 operational assessment time series, stock_id=10509,",
  "assessment_id=13596. Compiled from the Stock SMART portal; values for",
  "2014-2023 checked against the assessment report Table 1. No uncertainty",
  "is provided. This is a reported time series, not a native fitted WHAM object."
)

blank_outputs <- function(n) {
  fields <- names(read.csv(outputs_path, nrows = 0, check.names = FALSE))
  x <- as.data.frame(
    matrix("", n, length(fields)),
    stringsAsFactors = FALSE
  )
  names(x) <- fields
  x$assessment_id <- assessment_id
  x
}

make_output <- function(x, type, measure, unit, age = NA_integer_,
                        age_group = "", notes = row_notes) {
  x <- x[x$year <= 2013, , drop = FALSE]
  out <- blank_outputs(nrow(x))
  out$type <- type
  out$measure <- measure
  out$year <- as.integer(x$year)
  out$value <- if (measure == "fishing_mortality_at_age") round(x$value, 3) else x$value
  out$age <- age
  if ("age_group" %in% names(out)) out$age_group <- age_group
  out$sex <- "combined"
  out$region <- "Georges Bank, 2023 revised stock definition"
  out$season <- "annual"
  out$unit <- unit
  out$source_type <- "official_machine_readable"
  out$source_reference <- reference
  out$notes <- notes
  out
}

f_notes <- paste(
  row_notes,
  "The assessment report defines fully selected F as applying to ages 9+;",
  "values are kept at the report's three-decimal precision."
)

history <- rbind(
  make_output(ssb, "biomass", "SSB", "tonnes"),
  make_output(
    recruitment, "recruitment", "recruitment", "thousand fish",
    age = 1L
  ),
  make_output(
    f_full, "mortality", "fishing_mortality_at_age", "year^-1",
    age = 9L, age_group = "9+", notes = f_notes
  )
)

append_history <- function(path, rows) {
  source_rows <- current_outputs[
    current_outputs$assessment_id == assessment_id &
      current_outputs$source_type == "official_machine_readable" &
      !is.na(current_outputs$source_reference) &
      grepl(data_url, current_outputs$source_reference, fixed = TRUE),
    , drop = FALSE
  ]

  if (nrow(source_rows)) {
    fields <- c("measure", "year", "value", "age", "unit")
    source_rows <- source_rows[
      order(source_rows$measure, source_rows$year), fields, drop = FALSE
    ]
    expected <- rows[
      order(rows$measure, rows$year), fields, drop = FALSE
    ]
    stopifnot(
      nrow(source_rows) == nrow(expected),
      isTRUE(all.equal(source_rows, expected, check.attributes = FALSE))
    )
    cat("Historical Stock SMART rows are already present and validated.\n")
    return(invisible(FALSE))
  }

  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  write.table(
    rows, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8"
  )
  text <- rawToChar(readBin(tmp, "raw", n = file.info(tmp)$size))
  text <- gsub("\r\n?", "\n", text)
  row_lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  row_lines <- row_lines[nzchar(row_lines)]
  stopifnot(length(row_lines) == nrow(rows))

  connection <- file(path, open = "ab")
  on.exit(close(connection), add = TRUE)
  writeBin(
    charToRaw(paste0(paste(row_lines, collapse = "\r\r\n"), "\r\r\n")),
    connection
  )
  invisible(TRUE)
}

if (identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")) {
  cat(
    "Validated", nrow(history), "historical Stock SMART output rows for",
    "1978-2013; 2014-2023 overlap matches the report.\n"
  )
} else if (isTRUE(append_history(outputs_path, history))) {
  cat("Added 1978-2013 Georges Bank cod output history.\n")
}