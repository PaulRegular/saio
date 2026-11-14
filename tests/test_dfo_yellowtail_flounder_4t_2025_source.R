root <- "."
read_table <- function(name) {
  utils::read.csv(file.path(root, "database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, check.names = FALSE)
}

stock <- subset(read_table("stocks"), stock_id == "dfo_yellowtail_flounder_4t")
assessment <- subset(read_table("assessments"),
  assessment_id == "dfo_yellowtail_flounder_4t_2025")
assumptions <- subset(read_table("assumptions"),
  assessment_id == "dfo_yellowtail_flounder_4t_2025")
inputs <- subset(read_table("inputs"),
  assessment_id == "dfo_yellowtail_flounder_4t_2025")
outputs <- subset(read_table("outputs"),
  assessment_id == "dfo_yellowtail_flounder_4t_2025")
candidate <- subset(utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE),
  candidate_id == "DFO:Gulf:Yellowtail Flounder - NAFO 4T")
selected <- subset(utils::read.csv(file.path(root, "discovery",
  "selected_batch_01_2026.csv"), stringsAsFactors = FALSE, check.names = FALSE),
  candidate_unit_id == "dfo_sff_2024_gulf_yellowtail_flounder_nafo_4t")
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_gulf_yellowtail_flounder_2025.md")), collapse = "\n")
source_review <- paste(readLines(file.path(root, "source_reviews",
  "dfo_yellowtail_flounder_4t_2025.md")), collapse = " ")

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Myzopsetta ferruginea",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$terminal_year == 2025L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 10L,
  nrow(inputs) == 0L,
  nrow(outputs) == 4L,
  outputs$measure[outputs$type == "biomass"] == "biomass_age_5plus",
  outputs$value[outputs$type == "biomass"] == 8269,
  outputs$lwr[outputs$type == "biomass"] == 5666,
  outputs$upr[outputs$type == "biomass"] == 10872,
  outputs$unit[outputs$type == "biomass"] == "t",
  identical(sort(outputs$year[outputs$type == "mortality"]), 2023:2025),
  all(outputs$value[outputs$type == "mortality"] == 0),
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  candidate$matched_stock_id == "dfo_yellowtail_flounder_4t",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  grepl("stock_id = dfo_yellowtail_flounder_4t", source_review, fixed = TRUE),
  grepl("no numerical input rows", source_review, fixed = TRUE),
  grepl("redirected to a Government Publications archive notice", source_review, fixed = TRUE),
  grepl("not spawning-stock biomass", review, fixed = TRUE),
  grepl("currently redirects", review, fixed = TRUE)
)

cat("DFO NAFO 4T yellowtail flounder 2025 partial-source import checks passed.\n")
