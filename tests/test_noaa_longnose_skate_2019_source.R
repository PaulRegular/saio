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

root <- "."
assessment_id <- "noaa_pacific_coast_longnose_skate_2019"
stock_id <- "noaa_pacific_coast_longnose_skate"
inputs <- read_assessment_rows(file.path(root, "database/inputs.csv"), assessment_id)
outputs <- read_assessment_rows(file.path(root, "database/outputs.csv"), assessment_id)
assumptions <- read_assessment_rows(file.path(root, "database/assumptions.csv"), assessment_id)
stocks <- read_columns(file.path(root, "database/stocks.csv"), c("stock_id",
  "authority_stock_id", "scientific_name", "ocean"))
assessments <- read_columns(file.path(root, "database/assessments.csv"), c(
  "assessment_id", "stock_id", "assessment_year", "terminal_year",
  "estimate_terminal_year", "is_current", "inputs_status", "outputs_status",
  "assumptions_status"))
candidates <- read_columns(file.path(root, "discovery/candidates.csv"), c(
  "candidate_id", "matched_stock_id", "match_status", "screening_status",
  "eligibility", "import_status", "output_evidence"))
inventory <- read_columns(file.path(root, "discovery/inventory_units.csv"), c(
  "unit_key", "matched_stock_id", "match_status", "import_status", "candidate_ids"))
manifest <- read.csv(file.path(root,
  "provenance/discovery_noaa_longnose_skate_2019/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10731", , drop = FALSE]
unit <- inventory[inventory$unit_key == paste0("stock:", stock_id), , drop = FALSE]
get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10731",
  stock$scientific_name == "Beringraja rhina",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2019",
  assessment$terminal_year == "2018",
  assessment$estimate_terminal_year == "2019",
  assessment$is_current == "TRUE",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("F-at-age remains unavailable", candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$match_status == "matched",
  unit$import_status == "partial",
  grepl("NOAA:10731", unit$candidate_ids, fixed = TRUE),
  nrow(inputs) == 4824L,
  nrow(outputs) == 4024L,
  nrow(assumptions) == 13L,
  nrow(get_input("catch_biomass")) == 191L,
  nrow(get_input("relative_abundance_index")) == 52L,
  nrow(get_input("discard_fraction")) == 23L,
  nrow(get_input("discard_fraction_se")) == 23L,
  all(get_input("discard_fraction_se")$basis == "native_scale"),
  nrow(get_input("conditional_frequency_at_age")) == 2184L,
  nrow(get_input("frequency_at_length")) == 1980L,
  sum(grepl("negative fleet code", inputs$notes, fixed = TRUE)) == 33L,
  nrow(get_output("numbers_at_age")) == 3193L,
  setequal(unique(as.integer(get_output("numbers_at_age")$year)), 1916:2018),
  setequal(na.omit(unique(as.integer(get_output("numbers_at_age")$age))), 0:29),
  sum(get_output("numbers_at_age")$age_group == "30+", na.rm = TRUE) == 103L,
  nrow(get_output("SSB")) == 104L,
  nrow(get_output("recruitment")) == 104L,
  nrow(get_output("natural_mortality_average_parameter")) == 1L,
  as.numeric(get_output("natural_mortality_average_parameter")$value) == 0.22,
  nrow(get_output("natural_mortality_parameter_sd")) == 1L,
  as.numeric(get_output("natural_mortality_parameter_sd")$value) == 0.01,
  is.na(get_output("natural_mortality_parameter_sd")$se),
  all(is.na(get_output("numbers_at_age")$se)),
  nrow(manifest) == 5L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(file.exists(file.path("source_cache/discovery_noaa_longnose_skate_2019",
    manifest$file)))
)

cat("NOAA Pacific Coast Longnose Skate 2019 source import, units, coverage, provenance, uncertainty labels and partial-status checks passed.\n")
