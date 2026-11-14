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
assessment_id <- "noaa_bsai_rougheye_blackspotted_2024"
stock_id <- "noaa_bsai_rougheye_blackspotted"
inputs <- read_assessment_rows(file.path(root, "database/inputs.csv"), assessment_id)
outputs <- read_assessment_rows(file.path(root, "database/outputs.csv"), assessment_id)
assumptions <- read_assessment_rows(file.path(root, "database/assumptions.csv"), assessment_id)
stocks <- read_columns(file.path(root, "database/stocks.csv"), c(
  "stock_id", "authority_stock_id", "scientific_name", "ocean"))
assessments <- read_columns(file.path(root, "database/assessments.csv"), c(
  "assessment_id", "stock_id", "assessment_year", "terminal_year",
  "estimate_terminal_year", "is_current", "inputs_status", "outputs_status",
  "assumptions_status"))
candidates <- read_columns(file.path(root, "discovery/candidates.csv"), c(
  "candidate_id", "matched_stock_id", "match_status", "screening_status",
  "eligibility", "import_status", "catch_age_evidence", "survey_age_evidence",
  "weights_evidence", "maturity_evidence", "mortality_evidence",
  "timing_evidence", "output_evidence"))
inventory <- read_columns(file.path(root, "discovery/inventory_units.csv"), c(
  "unit_key", "matched_stock_id", "match_status", "import_status", "candidate_ids"))
manifest <- read.csv(file.path(root,
  "provenance/discovery_noaa_bsai_rougheye_2024/sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines(file.path(root,
  "discovery/source_reviews/noaa_bsai_blackspotted_rougheye_2024.md"),
  warn = FALSE), collapse = " ")

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:11382", , drop = FALSE]
unit <- inventory[inventory$unit_key == paste0("stock:", stock_id), , drop = FALSE]
get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]
n_age <- get_output("numbers_at_age")
total_n <- get_output("total_numbers")
ai_index <- get_input("relative_biomass_index")
ai_index <- ai_index[ai_index$region == "Aleutian Islands total", , drop = FALSE]
ebi_index <- get_input("relative_biomass_index")
ebi_index <- ebi_index[ebi_index$region == "Eastern Bering Sea slope", , drop = FALSE]
length_comp <- get_input("proportion_at_length")
length_comp <- length_comp[length_comp$observation_id == "table14_18_2024", , drop = FALSE]
age_comp <- get_input("proportion_at_age")
maturity <- get_output("maturity_at_age")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "11382",
  grepl("Sebastes aleutianus", stock$scientific_name, fixed = TRUE),
  grepl("Sebastes melanostictus", stock$scientific_name, fixed = TRUE),
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == "2024",
  assessment$terminal_year == "2024",
  assessment$estimate_terminal_year == "2025",
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
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$match_status == "matched",
  unit$import_status == "partial",
  grepl("NOAA:11382", unit$candidate_ids, fixed = TRUE),
  nrow(inputs) == 2083L,
  nrow(outputs) == 2299L,
  nrow(assumptions) == 15L,
  nrow(get_input("catch_biomass")) == 302L,
  nrow(get_input("proportion_at_age")) == 1118L,
  nrow(get_input("proportion_at_length")) == 468L,
  nrow(get_input("relative_biomass_index")) == 76L,
  nrow(get_input("biomass_index_cv")) == 76L,
  nrow(get_input("weight_at_age")) == 43L,
  nrow(n_age) == 2064L,
  setequal(unique(as.integer(n_age$year)), 1977:2024),
  setequal(unique(as.integer(n_age$age)), 3:45),
  sum(n_age$age_group == "45+", na.rm = TRUE) == 48L,
  all(n_age$unit == "millions of fish"),
  all(n_age$type == "population"),
  all(total_n$type == "population"),
  all(is.na(n_age$se)),
  nrow(total_n) == 48L,
  all(vapply(1977:2024, function(y) {
    abs(sum(n_age$value[n_age$year == y]) -
      total_n$value[total_n$year == y]) < 1e-8
  }, logical(1))),
  nrow(ai_index) == 14L,
  setequal(as.integer(ai_index$year), c(1991, 1994, 1997, 2000, 2002,
    2004, 2006, 2010, 2012, 2014, 2016, 2018, 2022, 2024)),
  nrow(ebi_index) == 6L,
  all(grepl("separate Tier 5", ebi_index$notes, fixed = TRUE)),
  sum(grepl("likelihood inclusion is unresolved", ai_index$notes, fixed = TRUE)) == 1L,
  nrow(length_comp) == 39L,
  all(is.na(length_comp$sample_size)),
  all(grepl("sample_size is left blank", length_comp$notes, fixed = TRUE)),
  abs(sum(length_comp$value) - 1) < 0.01,
  sum(age_comp$age == 45, na.rm = TRUE) == 26L,
  all(get_input("weight_at_age")$unit == "g per fish"),
  setequal(as.integer(get_input("weight_at_age")$age), 3:45),
  nrow(maturity) == 43L,
  all(maturity$measure == "maturity_at_age"),
  all(is.na(maturity$se)),
  get_output("natural_mortality_average_parameter")$value == 0.05,
  is.na(get_output("natural_mortality_average_parameter")$se),
  get_output("q")$type == "catchability",
  get_output("q")$value == 1.04,
  get_output("q")$se == 0.05,
  nrow(get_output("mat_beta1")) == 1L,
  nrow(get_output("mat_beta2")) == 1L,
  all(is.na(get_output("mat_beta1")$lwr)),
  all(is.na(get_output("mat_beta2")$upr)),
  nrow(get_output("SSB")) == 49L,
  nrow(get_output("total_biomass")) == 49L,
  nrow(get_output("recruitment")) == 42L,
  setequal(unique(as.integer(get_output("SSB")$year)), 1977:2025),
  identical(sort(unique(as.integer(get_output("recruitment")$year))), 1977:2018),
  all(!is.na(get_output("SSB")$se[get_output("SSB")$year <= 2024])),
  is.na(get_output("SSB")$se[get_output("SSB")$year == 2025]),
  !any(inputs$measure %in% c("catch_numbers_at_age", "catch_at_age")),
  !any(outputs$measure %in% c("fishing_mortality_at_age", "catch_numbers_at_age")),
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference)),
  nrow(manifest) == 1L,
  manifest$file == "BSAIrougheye_2024.pdf",
  grepl("^[[:xdigit:]]{64}$", manifest$sha256),
  file.exists(file.path("source_cache/discovery_noaa_bsai_rougheye_2024",
    "BSAIrougheye_2024.pdf")),
  identical(sort(as.integer(get_output("recruitment")$year[is.na(get_output("recruitment")$se)])), c(2001L, 2014L, 2015L)),
  grepl("1977-2018 only", review, fixed = TRUE),
  grepl("not renormalized", review, fixed = TRUE),
  grepl("fishery weight-at-age", review, fixed = TRUE)
)

cat("NOAA BSAI blackspotted/rougheye 2024 source coverage and provenance checks passed.\n")
