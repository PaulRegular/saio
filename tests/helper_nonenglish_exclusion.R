check_nonenglish_exclusion <- function(stock_id, assessment_id, candidate_id, language, review_path) {
  stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = c("", "NA"))
  assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = c("", "NA"))
  candidates <- read.csv("database/candidates.csv", stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = c("", "NA"))
  candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
  review <- paste(readLines(review_path, warn = FALSE), collapse = "\n")
  stopifnot(
    !any(stocks$stock_id == stock_id),
    !any(assessments$assessment_id == assessment_id),
    nrow(candidate) == 1L,
    is.na(candidate$matched_stock_id) || !nzchar(candidate$matched_stock_id),
    candidate$match_status == "new",
    candidate$import_status == "not_started",
    grepl(language, candidate$decision_reason, fixed = TRUE),
    grepl(language, review, fixed = TRUE),
    grepl("not included in the canonical SAIO tables", review, fixed = TRUE)
  )
}