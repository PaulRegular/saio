root <- "."
source_paths <- c(list.files("database", pattern = "[.]csv$", full.names = TRUE),
  list.files("discovery", pattern = "[.]csv$", full.names = TRUE))
source_hashes <- tools::md5sum(source_paths)
import_env <- new.env(parent = globalenv())
import_env$commandArgs <- function(trailingOnly = FALSE) {
  if (trailingOnly) "--dry-run" else base::commandArgs(trailingOnly = FALSE)
}
source(file.path(root, "scripts", "database", "550_import_ices_celtic_sea_herring_2026.R"),
  local = import_env
)

x <- import_env$input_data
y <- import_env$outputs
a <- import_env$assumptions
stock_id <- "ices_her_27_irls"
assessment_id <- "ices_her_27_irls_2026"

stopifnot(
  nrow(import_env$stock) == 1L,
  import_env$stock$authority_stock_id == "her.27.irls",
  import_env$stock$scientific_name == "Clupea harengus",
  import_env$stock$ocean == "Northeast Atlantic",
  import_env$assessment$assessment_year == 2026L,
  import_env$assessment$terminal_year == 2025L,
  import_env$assessment$is_current,
  import_env$assessment$is_applied,
  all(c(import_env$assessment$assumptions_status,
    import_env$assessment$inputs_status, import_env$assessment$outputs_status) == "partial"),
  nrow(x) == 2163L,
  nrow(a) == 28L,
  nrow(y) == 340L
)

input <- function(type, measure, survey = NULL) {
  out <- x[x$type == type & x$measure == measure, , drop = FALSE]
  if (!is.null(survey)) out <- out[out$survey == survey, , drop = FALSE]
  out
}
output <- function(measure) y[y$measure == measure, , drop = FALSE]
cell <- function(data, year, age) {
  rows <- data$year == year
  if (is.na(age)) rows <- rows & is.na(data$age) else rows <- rows & data$age == age
  data$value[rows]
}

survey_name <- "Celtic Sea Pelagic Ecosystem Survey (CSHAS)"
catch <- input("catch", "numbers_at_age")
catch_total <- input("catch", "total_biomass")
catch_cv <- input("catch", "relative_standard_error")
catch_weight <- input("catch_weight", "catch_weight_at_age")
stock_weight <- input("weight", "weight_at_age")
maturity <- input("maturity", "maturity_at_age")
mortality <- input("M", "natural_mortality_at_age")
survey_total <- input("index", "total_numbers", survey_name)
survey_age <- input("index", "numbers_at_age", survey_name)
survey_cv <- input("index", "abundance_index_cv", survey_name)

stopifnot(
  nrow(catch) == 612L,
  identical(sort(unique(catch$year)), 1958:2025),
  identical(sort(unique(catch$age)), 1:9),
  all(catch$unit == "thousand fish"),
  cell(catch, 1958, 1) == 1642,
  cell(catch, 2025, 9) == 0,
  nrow(catch_total) == 68L,
  cell(catch_total, 1958, NA_integer_) == 22978,
  cell(catch_total, 2025, NA_integer_) == 987,
  nrow(catch_cv) == 68L,
  all(catch_cv$value == 0.2),
  nrow(catch_weight) == 611L,
  nrow(stock_weight) == 611L,
  !any(catch_weight$year == 2025 & catch_weight$age == 9),
  !any(stock_weight$year == 2025 & stock_weight$age == 9),
  cell(catch_weight, 1958, 1) == 0.096,
  cell(stock_weight, 2025, 8) == 0.151,
  nrow(maturity) == 9L,
  all(is.na(maturity$year)),
  identical(maturity$value[match(1:9, maturity$age)], c(0.5, rep(1, 8))),
  nrow(mortality) == 9L,
  all(is.na(mortality$year)),
  identical(mortality$value[match(1:9, mortality$age)],
    c(0.767, 0.385, 0.356, 0.339, 0.319, 0.314, 0.307, 0.307, 0.307)),
  all(x$year_basis[!is.na(x$year)] == "model_year")
)

stopifnot(
  nrow(survey_total) == 22L,
  identical(sort(unique(survey_total$year)), setdiff(2002:2025, c(2004, 2017))),
  cell(survey_total, 2002, NA_integer_) == 381900,
  cell(survey_total, 2019, NA_integer_) == 8873,
  cell(survey_total, 2024, NA_integer_) == 0,
  survey_total$sample_size[survey_total$year == 2002] == 15,
  survey_total$sample_size[survey_total$year == 2024] == 0,
  all(survey_total$sampling_time == 0.5),
  nrow(survey_age) == 131L,
  cell(survey_age, 2019, 2) == 98229,
  cell(survey_age, 2022, 4) == 39146,
  cell(survey_age, 2025, 7) == 931,
  !any(survey_age$year == 2006 & survey_age$age == 7),
  nrow(survey_cv) == 22L,
  survey_cv$value[survey_cv$year == 2024] == 0,
  all(survey_cv$value[survey_cv$year != 2024] == 0.5),
  all(grepl("2019 age-2 entry", survey_age$notes[survey_age$year == 2019], fixed = TRUE))
)

total_catch <- output("total_catch")
ssb <- output("SSB")
total_biomass <- output("total_biomass")
fbar <- output("Fbar")
recruitment <- output("recruitment")
stopifnot(
  nrow(total_catch) == 68L,
  nrow(ssb) == 68L,
  nrow(total_biomass) == 68L,
  nrow(fbar) == 68L,
  nrow(recruitment) == 68L,
  identical(sort(unique(ssb$year)), 1958:2025),
  total_catch$value[total_catch$year == 2025] == 687,
  ssb$value[ssb$year == 2025] == 16115,
  total_biomass$value[total_biomass$year == 2025] == 30971,
  fbar$value[fbar$year == 2025] == 0.0634,
  fbar$age_group[fbar$year == 2025] == "2-5 winter rings",
  recruitment$value[recruitment$year == 2025] == 390113,
  recruitment$unit[recruitment$year == 2025] == "thousand fish",
  all(is.na(y$se) & is.na(y$lwr) & is.na(y$upr)),
  all(grepl("point estimate only", y$notes, ignore.case = TRUE))
)

database <- file.path(root, "database")
stocks <- utils::read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- utils::read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- utils::read.csv(file.path(root, "discovery", "candidates.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- utils::read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_note <- candidates$notes[candidates$candidate_id == "ICES:her.27.irls"]
inventory <- utils::read.csv(file.path(root, "discovery", "inventory_units.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines(file.path(root, "discovery", "source_reviews", "ices_celtic_herring_2026.md"),
  warn = FALSE), collapse = "\n")
stopifnot(
  sum(stocks$stock_id == stock_id, na.rm = TRUE) == 1L,
  sum(assessments$assessment_id == assessment_id, na.rm = TRUE) == 1L,
  candidates$import_status[candidates$candidate_id == "ICES:her.27.irls"] == "partial",
  length(strsplit(candidate_note, "Imported report-table inputs and outputs.", fixed = TRUE)[[1L]]) == 2L,
  selected$curation_status[selected$candidate_id == "ICES:her.27.irls"] == "partial_source_import",
  inventory$import_status[import_env$candidate_inventory_row(inventory, "ICES:her.27.irls", stock_id)] == "partial",
  grepl("The 2019 acoustic input table prints age-2 abundance as 98,229", review, fixed = TRUE),
  grepl("Both values are imported in their separate source contexts without correction", review, fixed = TRUE)
)

cat("ICES 2026 Celtic Sea herring source import, coverage, units, source conflicts, and official-output checks passed.\n")
stopifnot(identical(source_hashes, tools::md5sum(source_paths)))
