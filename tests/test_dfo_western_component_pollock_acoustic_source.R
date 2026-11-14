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
    chunk <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, paste0('"', id, '",'))])
  }
  if (!length(selected)) return(utils::read.csv(text = header, check.names = FALSE))
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

stock_id <- "dfo_western_component_pollock_4xopqrs5"
assessment_key <- "dfo_western_component_pollock_2022_j_m4b"
survey_name <- "Western Component Pollock acoustic index"
assessment <- subset(read_table("assessments"), assessment_id == assessment_key)
inputs <- read_assessment_inputs(file.path(root, "database", "inputs.csv"), assessment_key)
age_index <- subset(inputs, type == "index" & measure == "biomass_at_age" & survey == survey_name)
total_index <- subset(inputs, type == "index" & measure == "total_biomass" & survey == survey_name)
source_file <- file.path("..", "..", "discovery_dfo_western_pollock_2022",
  "dfo_western_pollock_2026_029_table10_acoustic_biomass_at_age.csv")
if (!file.exists(source_file)) {
  source_file <- file.path(root, "source_cache", "discovery_dfo_western_pollock_2022",
    basename(source_file))
}
source_table <- utils::read.csv(source_file, check.names = FALSE,
  na.strings = c("", "NA"))
candidate <- subset(utils::read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE),
  candidate_id == "DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)")
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "dfo_western_component_pollock_2022.md")), collapse = " ")

stopifnot(
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$inputs_status == "partial",
  nrow(age_index) == 51L,
  nrow(total_index) == 6L,
  identical(sort(unique(age_index$year)), c(2012L, 2016L:2020L)),
  identical(sort(unique(age_index$age)), 2:12),
  all(age_index$basis == "index_scale", age_index$unit == "mt",
    age_index$season == "summer", age_index$sampling_time == 0.5,
    age_index$year_basis == "calendar_year", age_index$value > 0,
    grepl("Table 10, printed p. 47", age_index$source_reference, fixed = TRUE)),
  nrow(subset(age_index, year == 2012L)) == 7L,
  nrow(subset(age_index, year == 2016L)) == 8L,
  nrow(subset(age_index, year == 2017L)) == 9L,
  nrow(subset(age_index, year == 2018L)) == 8L,
  nrow(subset(age_index, year == 2019L)) == 10L,
  nrow(subset(age_index, year == 2020L)) == 9L,
  age_index$value[age_index$year == 2012L & age_index$age == 2L] == 3376,
  age_index$value[age_index$year == 2016L & age_index$age == 10L] == 77,
  age_index$value[age_index$year == 2017L & age_index$age == 11L] == 48,
  age_index$value[age_index$year == 2019L & age_index$age == 12L] == 64,
  age_index$value[age_index$year == 2020L & age_index$age == 10L] == 347,
  nrow(subset(age_index, year == 2013L | year == 2014L | year == 2015L)) == 0L,
  all(total_index$basis == "index_scale", total_index$measure == "total_biomass",
    is.na(total_index$age), total_index$unit == "mt", total_index$value > 0),
  isTRUE(all.equal(as.numeric(total_index$value[order(total_index$year)]), c(11578,36969,16431,16317,9341,38061))),
  grepl("LowCI=11511 mt and HighCI=11636 mt", total_index$notes[
    total_index$year == 2012L], fixed = TRUE),
  grepl("confidence level is not stated", total_index$notes, fixed = TRUE),
  identical(as.integer(source_table$year), c(2012L, 2016L:2020L)),
  source_table$total_mt[source_table$year == 2020L] == 38061,
  sum(age_index$value[age_index$year == 2020L]) == 38407,
  is.na(source_table$age_13),
  nrow(candidate) == 1L,
  candidate$import_status == "partial",
  grepl("51 non-missing age values", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Table 10", review, fixed = TRUE),
  grepl("six aggregate acoustic biomass-index rows", review, fixed = TRUE),
  grepl("confidence level is not stated", review, fixed = TRUE),
  grepl("sum to 38,407 mt in 2020", review, fixed = TRUE),
  grepl("Table 10 reports a 38,061 mt total", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Part I Table 9 reports 38,408 mt", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Both totals are retained as published", candidate$survey_age_evidence, fixed = TRUE)
)

cat("DFO Western Component Pollock acoustic-index checks passed.\n")
