read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

candidate_id <- "AFMA:SESSF_GUMMY_SHARK_2023"
candidate_unit_id <- "afma_gummy_shark_sessf"
candidate <- read_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selection <- read_table("discovery/selected_batch_14_2026.csv")
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
units <- read_table("discovery/inventory_units.csv")
unit <- units[units$unit_key == "stock:afma_gummy_shark_sessf", , drop = FALSE]
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
manifest <- read_table("provenance/afma_gummy_shark_2023_sources.csv")
review <- paste(readLines("discovery/source_reviews/afma_gummy_shark_2023.md",
  warn = FALSE, encoding = "UTF-8"), collapse = "\n")

stopifnot(
  nrow(candidate) == 1L,
  candidate$organization == "AFMA",
  candidate$official_stock_id == "SESSF Gummy Shark (Bass Strait, South Australia, Tasmania)",
  candidate$scientific_name == "Mustelus antarcticus",
  candidate$inventory_assessment_year == 2023L,
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  candidate$matched_stock_id == "afma_gummy_shark_sessf",
  candidate$match_status == "matched",
  nrow(selection) == 1L,
  selection$curation_status == "partial_source_import",
  nrow(unit) == 1L,
  unit$matched_stock_id == "afma_gummy_shark_sessf",
  unit$match_status == "matched",
  unit$import_status == "partial",
  nrow(manifest) == 1L,
  manifest$sha256 == "3AA1245146CEE94FB36C89F9E8FB1FC134D647360896E401E5762D9E7CD467DC",
  "afma_gummy_shark_sessf" %in% units$matched_stock_id,
  any(stocks$stock_id == "afma_gummy_shark_sessf" & stocks$scientific_name == "Mustelus antarcticus"),
  any(assessments$assessment_id == "afma_gummy_shark_sessf_2023"),
  grepl("1927-2022", review, fixed = TRUE),
  grepl("Bridge 17", review, fixed = TRUE),
  grepl("age-input eligibility remains unresolved", tolower(review), fixed = TRUE),
  grepl("2,016 imported catch rows", review, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)

report_file <- file.path("source_cache", manifest$local_file)
if (file.exists(report_file)) {
  stopifnot(identical(
    toupper(unname(tools::sha256sum(report_file))),
    toupper(manifest$sha256)
  ))
}
cat("AFMA Gummy Shark screening, run identity, source provenance, and unresolved age-input status passed.\n")

