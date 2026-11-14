read_source_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_SUR41"
candidate_unit_id <- "argentina_merluccius_hubbsi_south_41s"
candidate <- read_source_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selection <- read_source_table("discovery/selected_batch_12_2026.csv")
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
unit <- read_source_table("discovery/inventory_units.csv")
unit <- unit[!is.na(unit$candidate_unit_id) &
  unit$candidate_unit_id == candidate_unit_id, , drop = FALSE]
progress <- read_source_table("discovery/inventory_progress.csv")
progress <- progress[progress$organization == "INIDEP", , drop = FALSE]
manifest <- read_source_table(
  "provenance/inidep_merluccius_hubbsi_south_2025_sources.csv")
review <- paste(readLines(
  "source_reviews/argentina_merluccius_hubbsi_south_2025.md", warn = FALSE),
  collapse = "\n")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == candidate_unit_id,
  candidate$organization == "INIDEP",
  candidate$official_stock_id == "Efectivo sur de 41° S",
  candidate$scientific_name == "Merluccius hubbsi",
  candidate$inventory_assessment_year == "2025",
  candidate$match_status == "new",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status %in% c("not_started", "partial", "imported"),
  grepl("Table 9", candidate$catch_age_evidence, fixed = TRUE),
  grepl("Table 8", candidate$survey_age_evidence, fixed = TRUE),
  grepl("precise within-year sampling fraction is not stated", candidate$timing_evidence, fixed = TRUE),
  grepl("not a comprehensive national inventory", candidate$notes, fixed = TRUE),
  nrow(selection) == 1L,
  selection$candidate_unit_id == candidate_unit_id,
  selection$curation_status %in% c("selected_for_source_curation", "partial_source_import"),
  nrow(unit) == 1L,
  unit$organizations == "INIDEP",
  unit$inventory_entries == 1L,
  nrow(progress) == 1L,
  progress$inventory_rows == 1L,
  grepl("not a comprehensive inventory", progress$source_region, fixed = TRUE),
  nrow(manifest) == 2L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("Table 11 reports coefficients of variation", review, fixed = TRUE),
  grepl("Tables 9 and 12 were checked against rendered report pages", review,
    fixed = TRUE),
  grepl("transcribed as 1,470,380 thousand fish", review, fixed = TRUE),
  grepl("direct INIDEP-hosted copy of the 2025", review, fixed = TRUE)
)

cat("INIDEP southern hake candidate screening and source provenance passed.\n")
