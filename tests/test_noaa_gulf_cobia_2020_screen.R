read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L)
    stop("Could not read assessment rows from ", path)
  rows <- rows[startsWith(rows, paste0('"', assessment_id, '",'))]
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

candidate_id <- "NOAA:10390"
stock_id <- "noaa_cobia_gulf_mexico_2020"
assessment_id <- paste0(stock_id, "_sedar28_update")
register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
imported <- nrow(inputs) > 0L || nrow(outputs) > 0L ||
  any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id)

review <- paste(readLines("discovery/source_reviews/noaa_gulf_cobia_2020.md",
  warn = FALSE), collapse = " ")
stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_id == candidate_id,
  candidate$candidate_unit_id == stock_id,
  candidate$scientific_name == "Rachycentron canadum",
  candidate$inventory_assessment_year == "2020",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  grepl("conditional age-at-length", candidate$catch_age_evidence, fixed = TRUE) ||
    grepl("age-at-length", candidate$catch_age_evidence, fixed = TRUE),
  grepl("age-specific (survey|abundance) index",
    candidate$survey_age_evidence, ignore.case = TRUE),
  grepl("0.38", candidate$mortality_evidence, fixed = TRUE),
  grepl("Tables 13", candidate$output_evidence, fixed = TRUE),
  grepl("age-input reconstruction caveat", review, fixed = TRUE) ||
    grepl("composition cells", review, fixed = TRUE),
  grepl("figures", review, fixed = TRUE),
  sum(stocks$stock_id == stock_id, na.rm = TRUE) == as.integer(imported),
  sum(assessments$assessment_id == assessment_id, na.rm = TRUE) == as.integer(imported),
  sum(units$candidate_unit_id == stock_id, na.rm = TRUE) == 1L
)
if (imported) stopifnot(
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(inputs) == 1190L,
  nrow(outputs) == 844L,
  nrow(units[!is.na(units$matched_stock_id) & units$matched_stock_id == stock_id,
    , drop = FALSE]) == 1L
) else stopifnot(
  candidate$match_status == "new",
  candidate$import_status == "not_started",
  nrow(inputs) == 0L,
  nrow(outputs) == 0L
)
cat("NOAA Gulf cobia source identity, screening, and import state passed.\n")
