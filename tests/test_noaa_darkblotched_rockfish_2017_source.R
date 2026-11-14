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
  classes <- rep("NULL", length(fields)); names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = classes)
}

assessment_id <- "noaa_darkblotched_rockfish_2017"
stock_id <- "noaa_darkblotched_rockfish_pacific"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assessments <- read_columns("database/assessments.csv", c("assessment_id", "stock_id",
  "assessment_year", "terminal_year", "estimate_terminal_year", "is_current", "is_applied",
  "model_family", "model_version", "inputs_status", "outputs_status", "assumptions_status"))
stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id", "scientific_name",
  "common_name", "area", "region", "ocean"))
assumptions <- read_columns("database/assumptions.csv", c("assessment_id", "component", "setting", "value"))
candidates <- read_columns("discovery/candidates.csv", c("candidate_id", "candidate_unit_id",
  "matched_stock_id", "match_status", "eligibility", "import_status", "survey_age_evidence",
  "output_evidence"))
inventory <- read_columns("discovery/inventory_units.csv", c("unit_key", "candidate_unit_id",
  "matched_stock_id", "match_status", "import_status", "candidate_ids"))
selected <- read_columns("discovery/selected_batch_28_2026.csv", c("candidate_id", "candidate_unit_id", "curation_status"))
manifest <- read.csv("provenance/discovery_noaa_darkblotched_2017/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10562", , drop = FALSE]
unit <- inventory[inventory$candidate_ids == "NOAA:10562", , drop = FALSE]
selection <- selected[selected$candidate_id == "NOAA:10562", , drop = FALSE]
get_input <- function(measure, type = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}
get_output <- function(measure, type = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}

n <- get_output("numbers_at_age", "population")
b <- get_output("biomass_at_age", "biomass")
catch_age <- get_output("catch_numbers_at_age", "catch")
m <- get_output("natural_mortality_at_age", "mortality")
f <- get_output("fishing_mortality_at_age", "mortality")
spawn <- get_output("spawning_output", "biomass")
recruit <- get_output("recruitment", "recruitment")
ratio <- get_output("SSB_ratio", "biomass")
total_biomass <- get_output("total_biomass", "biomass")
summary_biomass <- get_output("summary_biomass", "biomass")
total_n <- get_output("total_abundance", "population")

stopifnot(
  nrow(stock) == 1L, stock$authority_stock_id == "10562",
  stock$scientific_name == "Sebastes crameri", stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$stock_id == stock_id,
  assessment$assessment_year == "2017", assessment$terminal_year == "2016",
  assessment$estimate_terminal_year == "2016", assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE", assessment$model_version == "3.30.01.12",
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial", nrow(assumptions) == 8L,
  nrow(candidate) == 1L, candidate$candidate_unit_id == "noaa_stocksmart_10562",
  candidate$matched_stock_id == stock_id, candidate$match_status == "matched",
  candidate$eligibility == "eligible", candidate$import_status == "partial",
  grepl("NWCBO", candidate$survey_age_evidence, fixed = TRUE),
  grepl("unavailable", candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L, unit$matched_stock_id == stock_id,
  unit$match_status == "matched", unit$import_status == "partial",
  nrow(selection) == 1L, selection$candidate_unit_id == "noaa_stocksmart_10562",
  selection$curation_status == "partial_source_import",
  nrow(manifest) == 3L, !anyDuplicated(manifest$cached_file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  nrow(inputs) == 42658L,
  sum(inputs$type == "catch" & inputs$measure == "total_biomass") == 306L,
  sum(inputs$type == "catch" & inputs$measure == "log_catch_sd") == 306L,
  all(get_input("total_biomass", "catch")$unit == "metric tons"),
  sum(inputs$type == "index" & inputs$measure == "total_biomass") == 31L,
  sum(inputs$type == "index" & inputs$measure == "log_index_sd") == 31L,
  all(get_input("total_biomass", "index")$basis == "biomass"),
  setequal(unique(inputs$survey[inputs$type == "index" & inputs$measure == "total_biomass"]),
    c("AKSHLF", "AKSLP", "NWSLP", "NWCBO")),
  all(inputs$sampling_time[inputs$type == "index" & inputs$measure == "total_biomass"] == 0.5),
  sum(inputs$measure == "frequency_at_age") == 36432L,
  sum(inputs$measure == "frequency_at_length") == 5460L,
  sum(inputs$measure == "ageing_error_sd") == 92L,
  all(inputs$basis[inputs$measure %in% c("frequency_at_age", "frequency_at_length")] == "native_frequency"),
  all(inputs$source_type == "native_model"),
  all(inputs$sample_size[inputs$measure %in% c("frequency_at_age", "frequency_at_length")] > 0),
  all(inputs$age[inputs$measure == "frequency_at_age"] %in% 0:35),
  setequal(unique(inputs$length_bin[inputs$measure == "frequency_at_length"]), seq(4, 62, 2)),
  any(grepl("negative codes identify evaluation-only rows", inputs$notes, fixed = TRUE)),
  !any(inputs$measure == "catch_numbers_at_age"),
  nrow(outputs) == 65892L,
  nrow(n) == 9384L, nrow(b) == 9384L, nrow(catch_age) == 28152L,
  nrow(m) == 9180L, nrow(f) == 9180L,
  setequal(unique(n$year), 1915:2016), setequal(unique(n$age), 0:45),
  setequal(unique(n$sex), c("female", "male")),
  setequal(unique(m$age), 0:44), setequal(unique(f$age), 0:44),
  sum(spawn$year == 2016L) == 1L,
  abs(spawn$value[spawn$year == 2016L] - 1355110000) < 1,
  abs(recruit$value[recruit$year == 2016L] - 2598.3) < 0.01,
  abs(total_biomass$value[total_biomass$year == 2016L] - 19431.1) < 0.1,
  abs(summary_biomass$value[summary_biomass$year == 2016L] - 19425.9) < 0.1,
  abs(ratio$value[ratio$year == 2016L] - 0.3823) < 0.001,
  abs(sum(n$value[n$year == 2016L & n$age == 0]) - 2598.3) < 0.01,
  abs(sum(b$value[b$year == 2016L]) - 19431.1) < 0.1,
  abs(sum(b$value[b$year == 2016L & b$age >= 1]) - 19425.9) < 0.1,
  abs(total_n$value[total_n$year == 2016L] -
    sum(n$value[n$year == 2016L])) < 1e-6,
  abs(f$value[f$year == 2016L & f$sex == "female" & f$age == 0] - 0.0033759) < 1e-6,
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  all(n$source_type == "native_model"),
  all(catch_age$source_type == "native_model"),
  all(f$source_type == "derived_source_output"),
  all(grepl("Z minus M", f$notes, fixed = TRUE))
)

cat("NOAA Darkblotched Rockfish 2017 source coverage, units, outputs, provenance, and partial-status checks passed.\n")
