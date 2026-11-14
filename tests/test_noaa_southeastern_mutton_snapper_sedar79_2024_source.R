assessment_id <- "noaa_southeastern_us_mutton_snapper_sedar79_2024"
stock_id <- "noaa_southeastern_us_mutton_snapper"

read_assessment_rows <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    block <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(block)) break
    selected <- startsWith(block, prefix)
    if (any(selected)) rows <- c(rows, block[selected])
  }
  if (!length(rows)) return(read.csv(text = header, stringsAsFactors = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions_all <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- assumptions_all[assumptions_all$assessment_id == assessment_id, , drop = FALSE]
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:11342", , drop = FALSE]
inventory <- inventory[inventory$candidate_ids == "NOAA:11342", , drop = FALSE]

one_input <- function(measure, year, survey = NA_character_, fleet = NA_character_, age = NA_integer_) {
  x <- inputs[inputs$measure == measure & inputs$year == year, , drop = FALSE]
  if (!is.na(survey)) x <- x[x$survey == survey, , drop = FALSE]
  if (!is.na(fleet)) x <- x[x$fleet == fleet, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one input row for ", measure, " / ", year, ".")
  x
}
one_output <- function(measure, year = NA_integer_, age = NA_integer_, fleet = NA_character_) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.na(year)) x <- x[x$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  if (!is.na(fleet)) x <- x[x$fleet == fleet, , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one output row for ", measure, ".")
  x
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "11342",
  stock$scientific_name == "Lutjanus analis",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2023L,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 794L,
  nrow(assumptions) == 11L,
  nrow(outputs) == 590L,
  sum(inputs$type == "catch" & inputs$measure == "landings_biomass") == 86L,
  sum(inputs$type == "catch" & inputs$measure == "log_catch_sd") == 86L +
    sum(inputs$fleet %in% c("Recreational East", "Recreational West") &
      inputs$measure == "log_catch_sd"),
  sum(inputs$type == "catch" & inputs$measure == "discard_numbers" &
    inputs$fleet == "Commercial Other") == 31L,
  sum(inputs$type == "index" & inputs$measure == "relative_abundance_index") == 86L,
  sum(inputs$type == "index" & inputs$measure == "recruitment_index") == 24L,
  length(unique(inputs$survey[inputs$type == "index" &
    inputs$measure %in% c("relative_abundance_index", "recruitment_index")])) == 7L,
  !any(inputs$measure %in% c("numbers_at_age", "frequency_at_age",
    "conditional_frequency_at_age", "conditional_proportion_at_age")),
  one_input("landings_biomass", 1981L, fleet = "Commercial Longline")$value == 28.107,
  one_input("discard_numbers", 2023L, fleet = "Commercial Other")$value == 5.505,
  one_input("relative_abundance_index", 1996L,
    survey = "GOM Combined Stereo Video")$value == 2.959,
  one_input("abundance_index_cv", 1996L,
    survey = "GOM Combined Stereo Video")$value == 0.652,
  one_input("recruitment_index", 1999L,
    survey = "Indian River YOY", age = 0L)$value == 0.363,
  sum(outputs$measure == "apical_F") == 172L,
  sum(outputs$measure == "fishing_mortality_at_age") == 43L,
  all(outputs$age[outputs$measure == "fishing_mortality_at_age"] == 3L),
  one_output("total_biomass", 2023L)$value == 15132,
  one_output("SSB", 2023L)$value == 5898,
  one_output("total_numbers", 2023L)$value == 12611,
  one_output("recruitment", 2023L, age = 1L)$value == 3138,
  one_output("SSB_ratio_to_SSB0", 2023L)$value == 0.33,
  one_output("apical_F", 2023L, fleet = "Commercial Longline")$value == 0,
  one_output("fishing_mortality_at_age", 2023L, age = 3L)$value == 0.07,
  sum(outputs$measure == "natural_mortality_at_age") == 40L,
  all(is.na(outputs$year[outputs$measure == "natural_mortality_at_age"])),
  one_output("natural_mortality_at_age", age = 1L)$value == 0.300,
  one_output("natural_mortality_at_age", age = 40L)$value == 0.118,
  one_output("growth_length_at_age", age = 1L)$value == 27.65,
  one_output("maturity_at_age", age = 4L)$value == 0.780,
  one_output("weight_at_age", age = 1L)$source_type == "derived_source_output",
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  any(grepl("conditional age-at-length", assumptions$value, fixed = TRUE)),
  any(grepl("not recovered", assumptions$notes, fixed = TRUE)),
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference))
)

cat("NOAA Southeastern U.S. Mutton Snapper SEDAR 79 source import checks passed.\n")
