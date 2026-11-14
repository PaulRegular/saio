root <- "."
candidate_id <- "ICES:ane.27.8"
stock_id <- "ices_bay_biscay_anchovy_8"
assessment_id <- "ices_bay_biscay_anchovy_2025"

register <- read.csv(file.path(root, "discovery/candidates.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
provenance <- read.csv(file.path(root, "provenance/ices_ane_27_8_sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)

candidate <- register[register$candidate_id %in% candidate_id, , drop = FALSE]
stock <- stocks[stocks$stock_id %in% stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id %in% assessment_id, , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery/source_reviews",
  "ices_bay_biscay_anchovy_2025.md"), warn = FALSE), collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == "ane.27.8",
  candidate$candidate_unit_id == stock_id,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(stock) == 1L,
  stock$authority_stock_id == "ane.27.8",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025L,
  assessment$model_version == "3.30.22.beta",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(provenance) == 5L,
  all(grepl("^[A-F0-9]{64}$", provenance$sha256)),
  grepl("2025 first-semester age input", review, fixed = TRUE),
  grepl("historical BIOMAN and PELGAS", review, ignore.case = TRUE),
  grepl("16 non-deviation Stock Synthesis parameter estimates", review, fixed = TRUE)
)

cat("ICES Bay of Biscay anchovy source record integration checks passed.\n")
