assessment_id <- "dfo_cod_4t4vn_2024"
cache <- "source_cache/dfo_cod_4t4vn"
database <- "database"
source_file <- "dfo_4tvn_cod_rebuilding_plan_2024.html"
source_url <- paste0(
  "https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/",
  "cod-morue/2024/cod-4TVn-morue-eng.html"
)
source_reference <- paste0(
  "DFO southern Gulf cod rebuilding plan, Figure 3 data table; Figure 3 cites ",
  "DFO Science Advisory Report 2024/026; ", source_url
)

if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("Install xml2 to parse the cached DFO assessment table.", call. = FALSE)
}

manifest <- read.csv(file.path(cache, "manifest.csv"),
  stringsAsFactors = FALSE, na.strings = "", check.names = FALSE
)
source_manifest <- manifest[manifest$source_file == source_file, , drop = FALSE]
if (nrow(source_manifest) != 1L || source_manifest$source_url != source_url) {
  stop("The cached DFO rebuilding-plan page must be recorded in the source manifest.",
    call. = FALSE
  )
}

page <- xml2::read_html(file.path(cache, source_file))
table <- xml2::xml_find_first(page, "//table[@id='tab2']")
if (inherits(table, "xml_missing")) {
  stop("The DFO Figure 3 data table was not found in the cached source.",
    call. = FALSE
  )
}

headers <- trimws(xml2::xml_text(xml2::xml_find_all(table, ".//thead/tr/th")))
expected_headers <- c(
  "Year", "F(1/yr)", "Confidence interval - low value",
  "Conficance interval - high value", "M ages 5-8 yrs  (1/yr",
  "Confidence interval - low value", "Conficance interval - high value",
  "M ages 9+ yrs (1/yr)", "Confidence interval - low value",
  "Conficance interval - high value"
)
if (!identical(headers, expected_headers)) {
  stop("The DFO mortality table headers changed; review the source before importing.",
    call. = FALSE
  )
}

source_rows <- lapply(xml2::xml_find_all(table, ".//tbody/tr"), function(row) {
  trimws(xml2::xml_text(xml2::xml_find_all(row, "./td")))
})
source_rows <- source_rows[vapply(source_rows, function(row) {
  length(row) == 10L && grepl("^[0-9]{4}$", row[[1L]])
}, logical(1))]
source_values <- as.data.frame(
  do.call(rbind, source_rows), stringsAsFactors = FALSE
)
names(source_values) <- paste0("column", seq_len(ncol(source_values)))
years <- as.integer(source_values$column1)
values <- as.data.frame(lapply(source_values[-1L], as.numeric))

if (!identical(years, 1950:2023) || nrow(values) != 74L ||
  any(!is.finite(as.matrix(values)))) {
  stop("The DFO mortality table does not contain a complete numeric 1950-2023 series.",
    call. = FALSE
  )
}

if (any(values$column2 < values$column3 | values$column2 > values$column4 |
    values$column3 > values$column4) ||
  any(values$column5 < values$column6 | values$column5 > values$column7 |
    values$column6 > values$column7) ||
  any(values$column8 < values$column9 | values$column8 > values$column10 |
    values$column9 > values$column10)) {
  stop("The DFO mortality estimates and confidence intervals are inconsistent.",
    call. = FALSE
  )
}

outputs_path <- file.path(database, "outputs.csv")
outputs <- read.csv(outputs_path,
  colClasses = "character", na.strings = "", check.names = FALSE,
  encoding = "UTF-8"
)
fields <- names(outputs)

make_rows <- function(measure, age_group, value, lwr, upr, notes) {
  rows <- as.data.frame(
    matrix("", nrow = length(years), ncol = length(fields)),
    stringsAsFactors = FALSE
  )
  names(rows) <- fields
  rows$assessment_id <- assessment_id
  rows$type <- "mortality"
  rows$measure <- measure
  rows$year <- as.character(years)
  rows$age_group <- age_group
  rows$value <- as.character(value)
  rows$lwr <- as.character(lwr)
  rows$upr <- as.character(upr)
  rows$unit <- "yr-1"
  rows$source_type <- "official_document"
  rows$source_reference <- source_reference
  rows$notes <- notes
  rows
}

new_outputs <- rbind(
  make_rows("fishing_mortality_summary", "",
    values$column2, values$column3, values$column4,
    paste(
      "Annual source-reported F estimate with a 95% confidence interval.",
      "The source labels this series F but does not specify its age range."
    )
  ),
  make_rows("Mbar", "5-8",
    values$column5, values$column6, values$column7,
    "Annual source-reported M for ages 5-8 with a 95% confidence interval."
  ),
  make_rows("Mbar", "9+",
    values$column8, values$column9, values$column10,
    "Annual source-reported M for ages 9+ with a 95% confidence interval."
  )
)

if (anyDuplicated(new_outputs[c("assessment_id", "measure", "year", "age_group")])) {
  stop("The extracted DFO mortality outputs contain duplicate keys.",
    call. = FALSE
  )
}

existing <- outputs[outputs$assessment_id == assessment_id &
  outputs$source_reference == source_reference, , drop = FALSE]
if (nrow(existing)) {
  key <- c("measure", "year", "age_group", "value", "lwr", "upr", "unit")
  normalize <- function(x) {
    x[] <- lapply(x, function(column) {
      column[is.na(column)] <- ""
      as.character(column)
    })
    rownames(x) <- NULL
    x
  }
  if (nrow(existing) == nrow(new_outputs) &&
    identical(normalize(existing[order(existing$measure, existing$year), key]),
      normalize(new_outputs[order(new_outputs$measure, new_outputs$year), key]))) {
    cat("The DFO 4T-4Vn mortality outputs already match the cached source.\n")
    quit(save = "no", status = 0L)
  }
  stop("Existing DFO mortality output rows do not match this extraction.",
    call. = FALSE
  )
}

info <- file.info(outputs_path)
connection <- file(outputs_path, open = "rb")
seek(connection, where = info$size - 1, origin = "start")
last_byte <- readBin(connection, what = "raw", n = 1L)
close(connection)
if (length(last_byte) && !identical(last_byte, as.raw(10L))) {
  cat("\n", file = outputs_path, append = TRUE)
}
write.table(new_outputs, file = outputs_path, sep = ",", row.names = FALSE,
  col.names = FALSE, quote = TRUE, append = TRUE, na = "",
  qmethod = "double", fileEncoding = "UTF-8"
)

cat("Imported 222 DFO 4T-4Vn annual mortality summary outputs for 1950-2023.\n")
