read_source_table <- function(path) utils::read.csv(path,
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

candidate_id <- "INIDEP:MERLUCCIUS_HUBBSI_NORTH41"
candidate_unit_id <- "argentina_merluccius_hubbsi_north_41s"
candidate <- read_source_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selection <- read_source_table("discovery/selected_batch_13_2026.csv")
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
units <- read_source_table("discovery/inventory_units.csv")
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == candidate_unit_id, , drop = FALSE]
progress <- read_source_table("discovery/inventory_progress.csv")
progress <- progress[progress$organization == "INIDEP", , drop = FALSE]
manifest <- read_source_table(
  "provenance/inidep_merluccius_hubbsi_north_2025_sources.csv")
review <- paste(readLines(
  "source_reviews/argentina_merluccius_hubbsi_north_2025.md", warn = FALSE),
  collapse = "\n")
stocks <- read_source_table("database/stocks.csv")
assessments <- read_source_table("database/assessments.csv")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == candidate_unit_id,
  candidate$organization == "INIDEP",
  candidate$official_stock_id == "Efectivo norte de 41° S",
  candidate$scientific_name == "Merluccius hubbsi",
  candidate$assessment_area == "North of 41°S; ZCPAU and adjacent Argentine waters",
  candidate$inventory_assessment_year == 2025,
  candidate$match_status %in% c("new", "matched"),
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status %in% c("not_started", "partial"),
  grepl("Table 2", candidate$catch_age_evidence, fixed = TRUE),
  grepl("Table 5", candidate$survey_age_evidence, fixed = TRUE),
  grepl("CPUE timing is not stated", candidate$timing_evidence, fixed = TRUE),
  grepl("Table 11", candidate$output_evidence, fixed = TRUE),
  nrow(selection) == 1L,
  selection$curation_status %in% c("selected_for_source_curation", "partial_source_import"),
  nrow(unit) == 1L,
  unit$match_status %in% c("new", "matched"),
  unit$eligibility == "eligible",
  unit$inventory_entries == 1L,
  nrow(progress) == 1L,
  progress$inventory_rows == 2L,
  nrow(manifest) == 3L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(file.exists(manifest$local_file)),
  all(as.numeric(manifest$bytes) == file.info(manifest$local_file)$size),
  identical(toupper(unname(tools::sha256sum(manifest$local_file))), manifest$sha256),
  grepl("official Technical Report 43/2025", review, ignore.case = TRUE),
  grepl("does not provide annual numerical model-estimated", review,
    ignore.case = TRUE),
  grepl("managed by the Argentina-Uruguay CTMFM", review, fixed = TRUE),
  all(candidate$match_status %in% c("new", "matched")),
  (candidate$import_status == "not_started" &&
    !any(stocks$stock_id == candidate_unit_id) &&
    !any(assessments$assessment_id == paste0(candidate_unit_id, "_2025"))) ||
    (candidate$import_status == "partial" &&
      any(stocks$stock_id == candidate_unit_id) &&
      any(assessments$assessment_id == paste0(candidate_unit_id, "_2025"))),
  any(stocks$stock_id == "argentina_merluccius_hubbsi_south_41s")
)

cat("INIDEP northern hake source screening and provenance passed.\n")
