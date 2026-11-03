root <- "."
read_table <- function(name) {
  utils::read.csv(file.path(root, "database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, check.names = FALSE)
}

stock <- subset(read_table("stocks"),
  stock_id == "dfo_western_component_pollock_4xopqrs5")
assessments <- subset(read_table("assessments"),
  stock_id == "dfo_western_component_pollock_4xopqrs5")
assumptions <- subset(read_table("assumptions"),
  assessment_id %in% c("dfo_western_component_pollock_2022_j_m4b",
    "dfo_western_component_pollock_2025_hcr_update"))
inputs <- subset(read_table("inputs"),
  assessment_id %in% c("dfo_western_component_pollock_2022_j_m4b",
    "dfo_western_component_pollock_2025_hcr_update"))
outputs <- subset(read_table("outputs"),
  assessment_id %in% c("dfo_western_component_pollock_2022_j_m4b",
    "dfo_western_component_pollock_2025_hcr_update"))
candidate <- subset(utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE),
  candidate_id == "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)")
selected <- subset(utils::read.csv(file.path(root, "discovery",
  "selected_batch_01_2026.csv"), stringsAsFactors = FALSE, check.names = FALSE),
  candidate_unit_id == "dfo_western_component_pollock_4xopqrs5")
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_western_component_pollock_2022.md")), collapse = " ")

model_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Pollachius virens",
  stock$area == "NAFO 4Xopqrs plus Canadian portions of 5Yb and 5Zc",
  stock$ocean == "Northwest Atlantic",
  nrow(assessments) == 2L,
  assessments$terminal_year[assessments$assessment_id ==
    "dfo_western_component_pollock_2022_j_m4b"] == 2020L,
  assessments$model_version[assessments$assessment_id ==
    "dfo_western_component_pollock_2022_j_m4b"] == "J_M4B",
  assessments$is_current[assessments$assessment_id ==
    "dfo_western_component_pollock_2025_hcr_update"],
  nrow(assumptions) == 15L,
  nrow(inputs) == 0L,
  nrow(outputs) == 6L,
  model_output("ssb_age_4plus")$value == 21711,
  model_output("ssb_age_4plus")$unit == "t",
  model_output("f_age_6_9")$value == 0.124,
  model_output("mean_recruitment_age2_2016_2020")$value == 4700000,
  model_output("survey_ssb_3yr_geomean_q_adjusted")$value == 28368,
  model_output("hcr_catch_advice")$value == 2999,
  model_output("hcr_relative_harvest_rate")$value == 0.11,
  all(outputs$source_type == "official_document"),
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  candidate$review_date == "2026-11-02",
  candidate$matched_stock_id == "dfo_western_component_pollock_4xopqrs5",
  nrow(selected) == 1L,
  selected$inventory_assessment_year == 2025L,
  selected$curation_status == "partial_source_import",
  grepl("rather than a model refit", review, fixed = TRUE),
  grepl("not the same quantity as the model SSB", review, fixed = TRUE),
  grepl("archived-page notice", review, fixed = TRUE)
)

cat("DFO Western Component Pollock 2022/2025 partial-source import checks passed.\n")
