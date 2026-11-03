root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_herring_north_sea_2026")
assessment_id <- "ices_herring_north_sea_2026"
report <- "https://doi.org/10.17895/ices.pub.31424315"
source_path <- file.path(cache, "North_Sea_herring_chapter.txt")
outputs_path <- file.path(database, "outputs.csv")
if (!file.exists(source_path)) stop("The cached official HAWG report text is missing.", call. = FALSE)

lines <- readLines(source_path, warn = FALSE, encoding = "UTF-8")
table_start <- grep("^Table 2\\.6\\.2\\.2 North Sea herring single fleet assessment\\. Catchabilities at age\\.$", lines)
if (length(table_start) != 1L) stop("Expected one official q table in the cached report.", call. = FALSE)
header <- table_start + 1L
if (trimws(lines[header]) != "fleet age value CV lbnd ubnd") {
  stop("The q table columns differ from the reviewed report table.", call. = FALSE)
}
fleet_names <- c("HERAS", "IBTS-Q1", "IBTS0", "IBTS-Q3", "LAI-ORSH", "LAI-BUN", "LAI-CNS", "LAI-SNS")
table_lines <- lines[seq.int(header + 2L, min(length(lines), header + 32L))]
table_lines <- table_lines[grepl("^(HERAS|IBTS-Q1|IBTS0|IBTS-Q3|LAI-ORSH|LAI-BUN|LAI-CNS|LAI-SNS)\\s", table_lines)]
source_rows <- lapply(table_lines, function(line) {
  fields <- strsplit(trimws(line), "\\s+")[[1L]]
  if (length(fields) != 6L || !fields[1L] %in% fleet_names) {
    stop("Could not parse a row from the official q table: ", line, call. = FALSE)
  }
  data.frame(
    survey = fields[1L], age = as.integer(fields[2L]),
    value = as.numeric(fields[3L]), cv = as.numeric(fields[4L]),
    lwr = as.numeric(fields[5L]), upr = as.numeric(fields[6L]),
    stringsAsFactors = FALSE
  )
})
source_rows <- do.call(rbind, source_rows)
expected_ages <- setNames(
  list(1:8, 1L, 0L, 0:5, 0L, 0L, 0L, 0L),
  c("HERAS", "IBTS-Q1", "IBTS0", "IBTS-Q3", "LAI-ORSH", "LAI-BUN", "LAI-CNS", "LAI-SNS")
)
expected_key <- unlist(lapply(names(expected_ages), function(survey) {
  paste(survey, expected_ages[[survey]], sep = "|")
}), use.names = FALSE)
actual_key <- paste(source_rows$survey, source_rows$age, sep = "|")
if (nrow(source_rows) != 20L || anyDuplicated(actual_key) ||
  !setequal(actual_key, expected_key) ||
  any(!is.finite(as.matrix(source_rows[c("value", "cv", "lwr", "upr")]))) ||
  any(source_rows$value <= 0 | source_rows$cv <= 0 | source_rows$lwr <= 0 |
    source_rows$upr <= source_rows$value | source_rows$lwr >= source_rows$value)) {
  stop("The official q table does not match the expected fleet-age coverage or valid estimates.", call. = FALSE)
}

output_schema <- names(utils::read.csv(
  outputs_path, nrows = 0L, colClasses = "character", check.names = FALSE
))
q_rows <- data.frame(
  assessment_id = assessment_id, type = "catchability", measure = "q",
  fleet = "", survey = source_rows$survey, sex = "", region = "", season = "",
  year = "", age = as.character(source_rows$age), age_group = "",
  value = sprintf("%.15g", source_rows$value),
  se = sprintf("%.15g", source_rows$value * source_rows$cv),
  lwr = sprintf("%.15g", source_rows$lwr),
  upr = sprintf("%.15g", source_rows$upr),
  unit = "native model q scale (physical index unit unresolved)",
  source_type = "official_table",
  source_reference = paste(report, "Table 2.6.2.2"),
  notes = paste0(
    "Reported CV=", sprintf("%.5g", source_rows$cv),
    "; natural-scale SE derived as q multiplied by CV. Lower and upper bounds are copied as printed; ",
    "the report table does not identify their confidence level or construction. Age rows are retained ",
    "as printed, including repeated values for source q-sharing groups."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)
q_rows <- q_rows[output_schema]

key_fields <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group"
)
row_key <- function(x) {
  values <- lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\r"))
}
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
existing_q <- outputs[
  outputs$assessment_id == assessment_id & outputs$type == "catchability" &
    outputs$measure == "q", , drop = FALSE
]
if (nrow(existing_q)) {
  if (nrow(existing_q) != nrow(q_rows) ||
    !setequal(row_key(existing_q), row_key(q_rows))) {
    stop("The database contains only part of the expected q output set.", call. = FALSE)
  }
  matched <- match(row_key(q_rows), row_key(existing_q))
  for (field in c("value", "se", "lwr", "upr")) {
    if (!isTRUE(all.equal(
      as.numeric(q_rows[[field]]), as.numeric(existing_q[[field]][matched]),
      tolerance = 1e-12
    ))) stop("Existing q output differs from the official report: ", field, call. = FALSE)
  }
  for (field in c("unit", "source_type", "source_reference", "notes")) {
    if (!identical(as.character(q_rows[[field]]), as.character(existing_q[[field]][matched]))) {
      stop("Existing q output metadata differs from the official report: ", field, call. = FALSE)
    }
  }
  q_rows <- q_rows[FALSE, , drop = FALSE]
}

if (identical(Sys.getenv("SAIO_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", nrow(q_rows), " official q output rows would be added.\n", sep = "")
  print(q_rows[c("survey", "age", "value", "se", "lwr", "upr")])
} else if (nrow(q_rows)) {
  utils::write.table(
    q_rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  cat("Imported 20 official q output rows; output completeness remains partial.\n")
} else {
  cat("The 20 official q output rows already match the report; no rows were added.\n")
}
