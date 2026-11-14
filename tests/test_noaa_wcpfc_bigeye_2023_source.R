read_assessment_rows <- function(path, assessment_id) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', assessment_id, '",')
  rows <- character()
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE, encoding = "bytes")
    if (!length(lines)) break
    rows <- c(rows, lines[startsWith(lines, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = classes)
}

assessment_id <- "wcpfc_wcpo_bigeye_2023"
stock_id <- "wcpfc_wcpo_bigeye"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assessments <- read_columns("database/assessments.csv", c(
  "assessment_id", "stock_id", "assessment_year", "terminal_year",
  "estimate_terminal_year", "is_current", "is_applied", "model_family",
  "model_version", "assumptions_status", "inputs_status", "outputs_status"))
stocks <- read_columns("database/stocks.csv", c(
  "stock_id", "authority", "authority_stock_id", "scientific_name",
  "common_name", "area", "ocean"))
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidates <- read_columns("discovery/candidates.csv", c(
  "candidate_id", "matched_stock_id", "match_status", "eligibility", "import_status"))
inventory <- read_columns("discovery/inventory_units.csv", c(
  "unit_key", "matched_stock_id", "candidate_unit_id", "match_status", "import_status"))

assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:11684", , drop = FALSE]
unit <- inventory[!is.na(inventory$candidate_unit_id) &
  inventory$candidate_unit_id == stock_id, , drop = FALSE]
get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "WCPFC / SPC",
  stock$scientific_name == "Thunnus obesus",
  stock$ocean == "Western and Central Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == "2023",
  assessment$terminal_year == "2021",
  assessment$estimate_terminal_year == "2021",
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  assessment$model_family == "MULTIFAN-CL",
  assessment$model_version == "2023 diagnostic reference fit",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 14L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$match_status == "matched",
  unit$import_status == "partial",
  nrow(inputs) == 832587L,
  sum(inputs$measure == "catch_numbers") == 3100L,
  sum(inputs$measure == "catch_biomass") == 3235L,
  sum(inputs$measure == "effort") == 2811L,
  sum(inputs$measure == "relative_abundance_index") == 2520L,
  length(unique(get_input("relative_abundance_index")$survey)) == 9L,
  sum(inputs$measure == "observation_likelihood_weight") == 2520L,
  length(unique(get_input("frequency_at_length")$observation_id)) == 1013L,
  length(unique(get_input("frequency_at_weight")$observation_id)) == 3536L,
  all(is.na(get_input("frequency_at_length")$sample_size)),
  all(is.na(get_input("frequency_at_weight")$sample_size)),
  all(grepl("sample_size is left blank", get_input("frequency_at_weight")$notes,
    fixed = TRUE)),
  all(get_input("frequency_at_length")$length_bin %in% seq.int(10L, 198L, 2L)),
  all(get_input("frequency_at_weight")$weight_bin %in% 1:200),
  sum(inputs$measure == "conditional_frequency_at_age") == 864L,
  sum(as.numeric(get_input("conditional_frequency_at_age")$value)) == 1010,
  all(get_input("conditional_frequency_at_age")$age %in% 1:40),
  sum(inputs$measure == "tag_release_frequency_at_length") == 11210L,
  sum(inputs$measure == "tag_recapture_count") == 2892L,
  sum(as.numeric(get_input("tag_recapture_count")$value)) == 9798,
  !any(inputs$measure %in% c("catch_numbers_at_age", "numbers_at_age")),
  nrow(outputs) == 143450L,
  nrow(get_output("numbers_at_age")) == 100800L,
  nrow(get_output("fishing_mortality_at_age")) == 28000L,
  nrow(get_output("natural_mortality_at_age")) == 40L,
  nrow(get_output("predicted_index")) == 2520L,
  nrow(get_output("predicted_catch")) == 9030L,
  nrow(get_output("spawning_potential_biomass")) == 2590L,
  all(get_output("numbers_at_age")$age_group == "quarterly age class"),
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  all(is.finite(as.numeric(inputs$value))),
  all(is.finite(as.numeric(outputs$value))),
  file.exists("discovery/source_reviews/noaa_wcpfc_bigeye_2023.md")
)

cat("WCPFC 2023 WCPO bigeye source import checks passed.\n")
