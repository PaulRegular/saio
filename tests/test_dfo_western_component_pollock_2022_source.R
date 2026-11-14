root <- "."
read_table <- function(name) {
  utils::read.csv(file.path(root, "database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, check.names = FALSE)
}
read_assessment_inputs <- function(path, id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  con <- file(path, open = "r")
  on.exit(close(con))
  readLines(con, n = 1L, warn = FALSE)
  selected <- character()
  repeat {
    chunk <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, paste0('"', id, '",'))])
  }
  if (!length(selected)) return(utils::read.csv(text = header, check.names = FALSE))
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

stock_key <- "dfo_western_component_pollock_4xopqrs5"
model_key <- "dfo_western_component_pollock_2022_j_m4b"
stock <- subset(read_table("stocks"), stock_id == stock_key)
assessments <- subset(read_table("assessments"), stock_id == stock_key)
assumptions <- subset(read_table("assumptions"),
  assessment_id %in% c(model_key, "dfo_western_component_pollock_2025_hcr_update"))
inputs <- read_assessment_inputs(file.path(root, "database", "inputs.csv"), model_key)
outputs <- subset(read_table("outputs"),
  assessment_id %in% c(model_key, "dfo_western_component_pollock_2025_hcr_update"))
candidate <- subset(utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE),
  candidate_id == "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)")
selected <- subset(utils::read.csv(file.path(root, "discovery",
  "selected_batch_01_2026.csv"), stringsAsFactors = FALSE, check.names = FALSE),
  candidate_unit_id == stock_key)
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_western_component_pollock_2022.md")), collapse = " ")

catch <- subset(inputs, type == "catch")
index <- subset(inputs, type == "index" & survey == "DFO summer RV survey")
model_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Pollachius virens",
  stock$area == "NAFO 4Xopqrs plus Canadian portions of 5Yb and 5Zc",
  stock$ocean == "Northwest Atlantic",
  nrow(assessments) == 2L,
  assessments$terminal_year[assessments$assessment_id == model_key] == 2020L,
  assessments$model_version[assessments$assessment_id == model_key] == "J_M4B",
  assessments$is_current[assessments$assessment_id == "dfo_western_component_pollock_2025_hcr_update"],
  nrow(assumptions) == 15L,
  nrow(catch) == 468L,
  nrow(index) == 444L,
  identical(sort(unique(catch$year)), 1982:2020),
  identical(sort(unique(index$year)), 1984:2020),
  identical(sort(unique(catch$age)), 2:13),
  identical(sort(unique(index$age)), 2:13),
  all(catch$measure == "numbers_at_age", catch$basis == "numbers",
    catch$unit == "thousand fish", catch$source_type == "official_table",
    catch$sampling_time == 0.5, grepl("Table 1, printed p. 34", catch$source_reference, fixed = TRUE)),
  all(index$measure == "numbers_at_age", index$basis == "index_scale",
    index$survey == "DFO summer RV survey", index$unit == "thousand fish",
    index$source_type == "official_table", index$sampling_time == 0.5,
    grepl("Table 5, printed p. 39", index$source_reference, fixed = TRUE)),
  all(catch$value >= 0),
  all(index$value >= 0),
  catch$value[catch$year == 1982 & catch$age == 2] == 95,
  catch$value[catch$year == 2020 & catch$age == 13] == 0,
  index$value[index$year == 1984 & index$age == 2] == 1891,
  index$value[index$year == 2020 & index$age == 2] == 1231,
  all(grepl("actual Eastern Georges Bank", index$notes[
    index$year %in% c(2016, 2017, 2019, 2020)], fixed = TRUE)),
  all(grepl("simulated EGB index", index$notes[
    !index$year %in% c(2016, 2017, 2019, 2020)], fixed = TRUE)),
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
  candidate$review_date == "2026-11-14",
  candidate$matched_stock_id == stock_key,
  nrow(selected) == 1L,
  selected$inventory_assessment_year == 2025L,
  selected$curation_status == "partial_source_import",
  grepl("468 commercial catch-at-age rows", review, fixed = TRUE),
  grepl("444 summer RV index-at-age rows", review, fixed = TRUE),
  grepl("archived-page HTML", review, fixed = TRUE),
  grepl("local source cache", review, fixed = TRUE)
)

cat("DFO Western Component Pollock source-import checks passed.\n")
