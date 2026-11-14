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

assessment_id <- "noaa_goa_rougheye_blackspotted_2023"
stock_id <- "noaa_goa_rougheye_blackspotted"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read_columns("database/stocks.csv", c(
  "stock_id", "authority_stock_id", "scientific_name", "ocean"))
assessments <- read_columns("database/assessments.csv", c(
  "assessment_id", "stock_id", "assessment_year", "terminal_year",
  "estimate_terminal_year", "is_current", "inputs_status", "outputs_status",
  "assumptions_status"))
candidates <- read_columns("discovery/candidates.csv", c(
  "candidate_id", "matched_stock_id", "match_status", "screening_status",
  "eligibility", "import_status", "review_date", "detailed_source_url",
  "catch_age_evidence", "survey_age_evidence", "weights_evidence",
  "maturity_evidence", "mortality_evidence", "timing_evidence",
  "output_evidence"))
inventory <- read_columns("discovery/inventory_units.csv", c(
  "unit_key", "matched_stock_id", "match_status", "import_status",
  "candidate_ids"))
manifest <- read.csv("provenance/discovery_noaa_goa_rougheye_2023/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines(
  "discovery/source_reviews/noaa_goa_rougheye_blackspotted_2023.md",
  warn = FALSE), collapse = " ")

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:11443", , drop = FALSE]
unit <- inventory[!is.na(inventory$candidate_ids) &
  grepl("NOAA:11443", inventory$candidate_ids, fixed = TRUE), , drop = FALSE]
get_input <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
get_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]
fishery_age <- inputs[inputs$measure == "proportion_at_age" &
  inputs$type == "catch", , drop = FALSE]
survey_age <- inputs[inputs$measure == "proportion_at_age" &
  inputs$type == "index" &
  !is.na(inputs$survey) &
  inputs$survey == "GOA bottom-trawl survey", , drop = FALSE]
fishery_length <- inputs[inputs$measure == "proportion_at_length" &
  inputs$type == "catch" & !is.na(inputs$fleet) &
  inputs$fleet == "GOA fishery observer samples", , drop = FALSE]
trawl_length <- inputs[inputs$measure == "proportion_at_length" &
  inputs$type == "index" &
  !is.na(inputs$survey) &
  inputs$survey == "GOA bottom-trawl survey", , drop = FALSE]
longline_length <- inputs[inputs$measure == "proportion_at_length" &
  inputs$type == "index" &
  !is.na(inputs$survey) &
  inputs$survey == "GOA longline survey", , drop = FALSE]
index <- inputs[inputs$measure %in% c("relative_biomass_index",
  "relative_abundance_index"), , drop = FALSE]
indices_cv <- inputs[inputs$measure %in% c("biomass_index_cv",
  "abundance_index_cv"), , drop = FALSE]
n_age <- get_output("numbers_at_age")
total_n <- get_output("total_numbers")
posterior <- outputs[!is.na(outputs$scenario) &
  outputs$type == "population" &
  outputs$scenario == "Model 23.1b MCMC posterior mean", , drop = FALSE]
mle <- outputs[!is.na(outputs$scenario) &
  outputs$type == "population" &
  outputs$scenario == "Model 23.1b MLE", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "11443",
  grepl("Sebastes aleutianus", stock$scientific_name, fixed = TRUE),
  grepl("Sebastes melanostictus", stock$scientific_name, fixed = TRUE),
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == "2023",
  assessment$terminal_year == "2023",
  assessment$estimate_terminal_year == "2023",
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
  candidate$review_date == "2026-11-12",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$match_status == "matched",
  unit$import_status == "partial",
  nrow(inputs) == 2676L,
  nrow(outputs) == 488L,
  nrow(assumptions) == 13L,
  nrow(get_input("catch_biomass")) == 100L,
  setequal(unique(as.integer(get_input("catch_biomass")$year)), 1977:2022),
  sum(get_input("catch_biomass")$region == "Gulf of Alaska total") == 46L,
  sum(get_input("catch_biomass")$region == "Western GOA") == 18L,
  sum(get_input("catch_biomass")$region == "Central GOA") == 18L,
  sum(get_input("catch_biomass")$region == "Eastern GOA") == 18L,
  nrow(fishery_age) == 480L,
  setequal(unique(as.integer(fishery_age$year)), c(1990, 2004, 2006, 2008,
    2009, 2010, 2012, 2014, 2016, 2018, 2020, 2022)),
  setequal(unique(as.integer(fishery_age$age)), 3:42),
  sum(fishery_age$age == 42 & grepl("42\\+", fishery_age$notes)) == 12L,
  all(abs(tapply(fishery_age$value, fishery_age$year, sum) - 1) < 0.01),
  nrow(survey_age) == 640L,
  setequal(unique(as.integer(survey_age$year)), c(1984, 1987, 1990, 1993,
    1996, 1999, 2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021)),
  all(grepl("excluded from the author-preferred Model 23.1b",
    survey_age$notes[survey_age$year %in% c(1984, 1987)], fixed = TRUE)),
  nrow(fishery_length) == 252L,
  all(grepl("sum to roughly 0.5", fishery_length$notes, fixed = TRUE)),
  all(tapply(fishery_length$value, fishery_length$year, sum) > 0.45),
  all(tapply(fishery_length$value, fishery_length$year, sum) < 0.55),
  nrow(trawl_length) == 357L,
  all(grepl("not fit in the population model", trawl_length$notes, fixed = TRUE)),
  nrow(longline_length) == 651L,
  nrow(index) == 48L,
  nrow(indices_cv) == 48L,
  setequal(as.integer(index$year[index$measure == "relative_biomass_index"]),
    c(1984, 1987, 1990, 1993, 1996, 1999, 2003, 2005, 2007, 2009, 2011,
      2013, 2015, 2017, 2019, 2021, 2023)),
  setequal(as.integer(index$year[index$measure == "relative_abundance_index"]),
    1993:2023),
  nrow(get_input("weight_at_age")) == 50L,
  setequal(as.integer(get_input("weight_at_age")$age), 3:52),
  all(get_input("weight_at_age")$unit == "g per fish"),
  nrow(get_input("maturity_at_age")) == 50L,
  all(get_input("maturity_at_age")$value >= 0 &
    get_input("maturity_at_age")$value <= 1),
  all(get_input("maturity_at_age")$transformation ==
    "Source percent divided by 100."),
  nrow(n_age) == 50L,
  setequal(as.integer(n_age$age), 3:52),
  all(n_age$year == 2023),
  all(n_age$unit == "thousands of fish"),
  is.na(n_age$se),
  nrow(total_n) == 1L,
  abs(total_n$value - sum(n_age$value)) < 1e-8,
  nrow(mle) == 141L,
  nrow(posterior) == 141L,
  all(!is.na(posterior$lwr) & !is.na(posterior$upr)),
  setequal(unique(posterior$measure), c("SSB", "recruitment", "total_biomass")),
  setequal(unique(as.integer(posterior$year)), 1977:2023),
  nrow(get_output("q")) == 4L,
  all(get_output("q")$type == "catchability"),
  all(!is.na(get_output("q")$lwr) & !is.na(get_output("q")$upr)),
  get_output("natural_mortality_average_parameter")$value == 0.042,
  is.na(get_output("natural_mortality_average_parameter")$se),
  !any(outputs$measure == "fishing_mortality_at_age"),
  nrow(manifest) == 3L,
  setequal(manifest$file, c("goa_rougheye_2023_full.pdf",
    "goa_rougheye_2024_projection.pdf", "goa_rougheye_2025_catch_report.pdf")),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(grepl("2023", candidate$detailed_source_url, fixed = TRUE)),
  grepl("most recent full assessment remained 2023", review, fixed = TRUE),
  grepl("2026 full-assessment document", review, fixed = TRUE),
  grepl("roughly 0.5", review, fixed = TRUE),
  file.exists(file.path("source_cache/discovery_noaa_goa_rougheye_2023",
    "goa_rougheye_2023_full.pdf")),
  file.exists(file.path("source_cache/discovery_noaa_goa_rougheye_2023",
    "goa_rougheye_2025_catch_report.pdf"))
)

cat("NOAA GOA rougheye/blackspotted 2023 source coverage and provenance checks passed.\n")
