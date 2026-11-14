root <- "."
assessment_id <- "noaa_black_rockfish_washington_2023"
stock_id <- "noaa_black_rockfish_washington"

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
selected <- read.csv("discovery/selected_batch_31_2026.csv", stringsAsFactors = FALSE,
  check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:14409", , drop = FALSE]
inventory <- inventory[inventory$unit_key == "candidate:noaa_black_rockfish_washington_2023", , drop = FALSE]
selected <- selected[selected$candidate_unit_id == "noaa_black_rockfish_washington_2023", , drop = FALSE]

one_output <- function(measure, year = NA_integer_, age = NA_integer_, sex = NA_character_) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.na(year)) x <- x[x$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  if (!is.na(sex)) x <- x[x$sex == sex, , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one output row for ", measure, ".")
  x
}

spawning <- outputs[outputs$measure == "spawning_output", , drop = FALSE]
female_m <- outputs[outputs$measure == "natural_mortality_at_age" & outputs$sex == "female", , drop = FALSE]
male_m <- outputs[outputs$measure == "natural_mortality_at_age" & outputs$sex == "male", , drop = FALSE]
index <- inputs[inputs$type == "index" &
  inputs$measure %in% c("total_biomass", "recruitment_index"), , drop = FALSE]
index_times <- as.numeric(unique(index$sampling_time))
age_error_assumption <- assumptions[assumptions$setting == "age_error_codes", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  as.character(stock$authority_stock_id) == "14409",
  stock$scientific_name == "Sebastes melanops",
  stock$ocean == "Northeast Pacific",
  stock$area == "Washington",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2023L,
  assessment$terminal_year == 2022L,
  assessment$estimate_terminal_year == 2034L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 100434L,
  nrow(assumptions) == 33L,
  nrow(outputs) == 140600L,
  sum(inputs$type == "catch" & inputs$measure == "total_biomass") == 249L,
  min(inputs$year[inputs$type == "catch"]) == 1940L,
  max(inputs$year[inputs$type == "catch"]) == 2022L,
  sum(inputs$measure == "log_index_sd") == 86L,
  setequal(unique(index$measure), c("total_biomass", "recruitment_index")),
  nrow(index) == 86L,
  sum(index$measure == "total_biomass") == 79L,
  sum(index$measure == "recruitment_index") == 7L,
  length(index_times) == 3L,
  all(vapply(c(0, 5 / 12, 7 / 12), function(x) any(abs(index_times - x) < 1e-12), logical(1L))),
  sum(inputs$measure == "frequency_at_length") == 6328L,
  sum(inputs$measure == "frequency_at_age") == 93685L,
  any(!is.na(inputs$length_bin_lower[inputs$measure == "frequency_at_age"])),
  any(is.na(inputs$length_bin_lower[inputs$measure == "frequency_at_age"])),
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  !any(inputs$type == "index" & inputs$measure == "numbers_at_age"),
  nrow(female_m) == 3895L,
  nrow(male_m) == 3895L,
  all(abs(female_m$value - 0.17) < 1e-8),
  all(abs(male_m$value - 0.152) < 1e-8),
  nrow(spawning[!is.na(spawning$lwr) | !is.na(spawning$upr), , drop = FALSE]) == 11L,
  one_output("spawning_output", 2013L)$lwr == 187.93,
  one_output("spawning_output", 2013L)$upr == 290.48,
  one_output("spawning_output", 2023L)$value == 426.151,
  one_output("spawning_output", 2023L)$lwr == 251.53,
  one_output("spawning_output", 2023L)$upr == 600.77,
  one_output("total_numbers", 2023L)$source_type == "derived_source_output",
  all(is.na(outputs$se)),
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  selected$curation_status == "partial_source_import",
  any(assumptions$setting == "fixed_constant_M"),
  any(grepl("not estimated", assumptions$notes, fixed = TRUE)),
  nrow(age_error_assumption) == 1L,
  grepl("datafile.dat", age_error_assumption$source_reference, fixed = TRUE),
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference))
)

cat("NOAA Washington black rockfish 2023 source import checks passed.\n")
