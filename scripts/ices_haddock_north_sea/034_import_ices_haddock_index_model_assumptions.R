root <- normalizePath(".", winslash = "/", mustWork = TRUE)
assumption_file <- file.path(root, "database/assumptions.csv")
assessment_id <- "ices_haddock_north_sea_2026"
annex_url <- "https://ndownloader.figshare.com/files/59379713"

rows <- data.frame(
  assessment_id = assessment_id,
  component = "survey",
  fleet = "",
  survey = c("delta-GAMNS-WCQ1", "delta-GAMNS-WCQ3+Q4"),
  sex = "",
  region = "",
  season = "",
  setting = "index_model",
  value = paste(
    "Age-specific delta-GAM with a fixed spatial surface and independent",
    "year-specific spatial deviations; lognormal positive-catch component"
  ),
  source_reference = paste(
    annex_url,
    "https://ndownloader.figshare.com/files/55607879",
    sep = "; "
  ),
  notes = c(
    paste(
      "The post-review Q1 formula uses Duchon splines for depth and time of",
      "year and an offset log(HaulDur + 5); it combines Q1 survey data from",
      "the North Sea/Skagerrak and West Coast of Scotland."
    ),
    paste(
      "The post-review Q3+Q4 formula uses log depth, quarter-specific",
      "time-of-day effects and an offset log(HaulDur + 5); it combines Q3",
      "North Sea/Skagerrak and Q4 West Coast of Scotland survey data."
    )
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

existing <- read.csv(assumption_file, stringsAsFactors = FALSE, check.names = FALSE)
key_columns <- c("assessment_id", "component", "survey", "setting")
row_key <- function(x) {
  values <- lapply(x[key_columns], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\034"))
}
existing_rows <- existing[existing$assessment_id == assessment_id, , drop = FALSE]
existing_keys <- row_key(existing_rows)
append_rows <- rows[FALSE, , drop = FALSE]

for (i in seq_len(nrow(rows))) {
  match_row <- which(existing_keys == row_key(rows[i, , drop = FALSE]))
  if (length(match_row) > 1L) {
    stop("Survey index-model assumption key is not unique.")
  }
  if (!length(match_row)) {
    append_rows <- rbind(append_rows, rows[i, , drop = FALSE])
  } else {
    for (column in names(rows)) {
      existing_value <- as.character(existing_rows[match_row, column])
      expected_value <- as.character(rows[i, column])
      existing_value[is.na(existing_value)] <- ""
      expected_value[is.na(expected_value)] <- ""
      if (!identical(existing_value, expected_value)) {
        stop("Existing survey index-model assumption conflicts with the source review.")
      }
    }
  }
}

if (nrow(append_rows)) {
  write.table(
    append_rows,
    file = assumption_file,
    sep = ",",
    quote = TRUE,
    row.names = FALSE,
    col.names = FALSE,
    append = TRUE,
    na = ""
  )
}
cat("Added", nrow(append_rows), "survey index-model assumptions.\n")
