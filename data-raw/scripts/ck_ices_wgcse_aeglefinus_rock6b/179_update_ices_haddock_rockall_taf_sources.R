root <- "."
db <- file.path(root, "database")
assessment_id <- "ices_haddock_rockall_2026"
taf_commit <- "2b768d6e2563d38a172918390e8fe964596b1325"
taf_repository_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/tree/", taf_commit
)
taf_stock_weight_code_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/blob/", taf_commit,
  "/2026_had.27.6b_assessment/data_stockweights.R"
)
taf_data_code_url <- paste0(
  "https://github.com/ices-advice/2026_had.27.6b/blob/", taf_commit,
  "/2026_had.27.6b_assessment/data.R"
)
report <- "ICES WGCSE 2026, Haddock in Division 6.b, doi:10.17895/ices.pub.32625759"
input_path <- file.path(db, "inputs.csv")
inputs <- read.csv(input_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
catch_weight <- inputs[
  inputs$type == "catch_weight" & inputs$measure == "weight_at_age",
  , drop = FALSE
]
stock_weight <- inputs[
  inputs$type == "weight" & inputs$measure == "weight_at_age",
  , drop = FALSE
]

stopifnot(
  nrow(catch_weight) == 280L,
  identical(sort(unique(catch_weight$year)), 1991:2025),
  identical(sort(unique(catch_weight$age)), 1:8),
  all(catch_weight$source_type == "official_table")
)

if (nrow(stock_weight) == 0L) {
  stock_weight <- catch_weight
  stock_weight$type <- "weight"
  stock_weight$source_type <- "reconstructed_source_input"
  stock_weight$source_reference <- paste(
    report, "Table 8.11, p. 294;", taf_stock_weight_code_url
  )
  stock_weight$transformation <- paste(
    "The pinned official TAF script reads cw.dat and writes its values",
    "unchanged to sw.dat; Table 8.11 supplies the cw.dat values."
  )
  stock_weight$notes <- paste(
    "SAM stock-weight observations; age 8 is 8+.",
    "These observations are modelled by SAM and are not the fitted",
    "stock-weight surface."
  )
} else {
  stopifnot(nrow(stock_weight) == 280L)
}

catch_weight <- catch_weight[order(catch_weight$year, catch_weight$age), ]
stock_weight <- stock_weight[order(stock_weight$year, stock_weight$age), ]
stopifnot(
  identical(catch_weight$year, stock_weight$year),
  identical(catch_weight$age, stock_weight$age),
  identical(catch_weight$value, stock_weight$value),
  all(stock_weight$source_type == "reconstructed_source_input")
)

if (nrow(inputs[inputs$assessment_id == assessment_id &
                inputs$type == "weight" &
                inputs$measure == "weight_at_age", , drop = FALSE]) == 0L) {
  columns <- names(read.csv(input_path, nrows = 1L, check.names = FALSE))
  write.table(stock_weight[columns], input_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
}

update_row <- function(file, matches, changes) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  table <- read.csv(file, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"), colClasses = "character")
  row <- which(matches(table))
  stopifnot(length(row) == 1L, length(lines) == nrow(table) + 1L)
  for (column in names(changes)) table[row, column] <- changes[[column]]
  replacement <- capture.output(write.csv(table[row, , drop = FALSE],
    row.names = FALSE, na = ""))[[2L]]
  lines[row + 1L] <- replacement
  writeLines(lines, file, useBytes = TRUE)
}

update_row(file.path(db, "assessments.csv"), function(x) {
  x$assessment_id == assessment_id
}, list(
  repository_url = taf_repository_url,
  notes = paste(
    "Current detailed assessment. The 2025 SAM fit object was inspected only to verify overlapping input values and survey sample times; it is not represented as the 2026 fit.",
    "The pinned public TAF code mirror confirms that Table 8.11 catch weights are copied unchanged into the SAM stock-weight observation file. The mirror does not include the raw input data or fitted outputs.",
    "The report does not provide the complete fitted stock-weight surface or age-specific uncertainty for N and F, and does not state coverage for summary Low/High bounds."
  )
))

update_row(file.path(db, "assumptions.csv"), function(x) {
  x$assessment_id == assessment_id & x$setting == "observation_precision" &
    x$survey == "Modelled Q3"
}, list(
  value = paste(
    "Modelled Q3 CVs are used as relative observation weights; the TAF script replaces selected cohort-year CV cells with age-series maxima before converting them to weights."
  ),
  source_reference = paste(report, "Table 8.13;", taf_data_code_url),
  notes = paste(
    "Table 8.13 CVs remain as published. The code adjusts 2023 age 1, 2024 ages 1-2, and 2025 ages 2-3 to age-series maxima before weighting; exact unrounded adjusted values are absent from the public mirror."
  )
))

update_row(file.path(db, "assumptions.csv"), function(x) {
  x$assessment_id == assessment_id & x$setting == "stock_weight"
}, list(
  value = paste(
    "SAM models stock-weight observations copied unchanged from catch weights; the fitted surface uses a correlated biological process and is not published."
  ),
  source_reference = paste(report, "Table 8.11, p. 294;", taf_stock_weight_code_url),
  notes = paste(
    "The 280 stock-weight observations are reconstructed from Table 8.11 by the pinned TAF copy rule. No complete fitted surface was recovered."
  )
))

cat("Updated Rockall haddock stock-weight provenance and TAF assumptions.\n")
