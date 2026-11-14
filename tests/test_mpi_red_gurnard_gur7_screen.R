read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

candidate_id <- "MPI:GUR7"
candidate_unit_id <- "mpi_red_gurnard_gur7"
all_candidates <- read_table("discovery/candidates.csv")
candidate <- all_candidates
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selection <- read_table("discovery/selected_batch_18_2026.csv")
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
units <- read_table("discovery/inventory_units.csv")
unit <- units[units$unit_key == paste0("stock:", candidate_unit_id), , drop = FALSE]
progress <- read_table("discovery/inventory_progress.csv")
nz_progress <- progress[progress$organization == "Fisheries New Zealand" &
  progress$source_region == "New Zealand", , drop = FALSE]
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
stock <- stocks[stocks$stock_id == candidate_unit_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == paste0(candidate_unit_id, "_2022"), , drop = FALSE]
manifest <- read_table("provenance/mpi_red_gurnard_gur7_2022_sources.csv")
review <- paste(readLines("discovery/source_reviews/mpi_red_gurnard_gur7_2022.md",
  warn = FALSE, encoding = "UTF-8"), collapse = "\n")

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == "GUR 7",
  candidate$scientific_name == "Chelidonichthys kumu",
  candidate$inventory_assessment_year == "2022",
  candidate$match_status == "matched",
  candidate$matched_stock_id == candidate_unit_id,
  candidate$screening_status == "screened",
  candidate$eligibility == "ineligible",
  candidate$import_status == "partial",
  grepl("Table A2 tabulates the complete", candidate$survey_age_evidence, fixed = TRUE),
  nrow(selection) == 1L,
  selection$candidate_unit_id == candidate_unit_id,
  grepl("Selected for partial current-unit source recovery", selection$selection_basis, fixed = TRUE),
  selection$curation_status == "partial_source_import",
  nrow(unit) == 1L,
  unit$eligibility == "ineligible",
  unit$screening_status == "screened",
  unit$import_status == "partial",
  unit$matched_stock_id == candidate_unit_id,
  nrow(nz_progress) == 1L,
  nz_progress$inventory_rows == sum(all_candidates$organization == "Fisheries New Zealand"),
  nrow(manifest) == 2L,
  nrow(stock) == 1L,
  stock$authority_stock_id == "GUR 7",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$is_current == "TRUE",
  assessment$assessment_year == "2022",
  assessment$terminal_year == "2021",
  assessment$model_version == "3.30.17",
  grepl("no commercial age or length compositions", review, ignore.case = TRUE),
  grepl("does tabulate the numeric survey age-composition vectors", review, fixed = TRUE),
  grepl("partial source import", review, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)

source_paths <- file.path("source_cache", manifest$local_file)
if (all(file.exists(source_paths))) {
  stopifnot(identical(
    toupper(unname(tools::sha256sum(source_paths))),
    toupper(manifest$sha256)
  ))
}
cat("GUR 7 unit, assessment-year, partial import, provenance, and source-screen checks passed.\n")
