read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L) stop("Could not read ", path)
  rows <- rows[startsWith(rows, paste0("\"", assessment_id, "\","))]
  if (!length(rows)) return(read.csv(text = header, nrows = 0L, check.names = FALSE,
    colClasses = "character"))
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

assessment_id <- "noaa_blue_deacon_oregon_2017"
stock_id <- "noaa_blue_deacon_oregon"
candidate_id <- "NOAA:14822"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE, check.names = FALSE)
provenance <- read.csv("provenance/discovery_noaa_blue_deacon_2017/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_blue_deacon_oregon_2017.md"), collapse = " ")

input_measure <- function(measure) inputs[inputs$measure == measure, , drop = FALSE]
output_measure <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]
numeric_value <- function(x) as.numeric(x$value)
output_at <- function(measure, year) {
  x <- output_measure(measure)
  x[x$year == as.character(year), , drop = FALSE]
}

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
unit <- inventory[inventory$unit_key == paste0("candidate:", stock_id), , drop = FALSE]
length_comp <- input_measure("frequency_at_length")
age_comp <- input_measure("frequency_at_age")
conditional_age <- input_measure("conditional_frequency_at_age")
negative_age <- age_comp[grepl("_fleet-", age_comp$observation_id), , drop = FALSE]
recruitment_2006 <- output_at("recruitment", 2006)
recruitment_2007 <- output_at("recruitment", 2007)

stopifnot(
  nrow(stock) == 1L, stock$ocean == "Northeast Pacific",
  stock$region == "Oregon", stock$authority_stock_id == "14822",
  nrow(assessment) == 1L, assessment$assessment_year == 2017,
  assessment$terminal_year == 2016, assessment$estimate_terminal_year == 2017,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(inputs) == 19180L, nrow(assumptions) == 26L, nrow(outputs) == 100L,
  nrow(input_measure("catch_biomass")) == 625L,
  nrow(input_measure("catch_se")) == 625L,
  sum(as.numeric(input_measure("catch_se")$value) == 0) == 146L,
  !nrow(input_measure("log_catch_sd")),
  all(grepl("not supplied observation SDs", input_measure("catch_se")$notes, fixed = TRUE)),
  min(as.numeric(input_measure("catch_biomass")$year)) == 1892,
  max(as.numeric(input_measure("catch_biomass")$year)) == 2016,
  length(unique(input_measure("catch_biomass")$fleet)) == 5L,
  nrow(input_measure("relative_abundance_index")) == 60L,
  nrow(input_measure("log_index_sd")) == 60L,
  length(unique(input_measure("relative_abundance_index")$survey)) == 4L,
  all(as.numeric(input_measure("relative_abundance_index")$sampling_time) == 0.5),
  all(input_measure("relative_abundance_index")$season == "month 7"),
  nrow(length_comp) == 2618L, length(unique(length_comp$observation_id)) == 101L,
  setequal(as.numeric(unique(length_comp$length_bin)), seq(10, 52, by = 2)),
  all(as.numeric(length_comp$value) >= 0),
  nrow(age_comp) == 1692L, length(unique(age_comp$observation_id)) == 47L,
  nrow(conditional_age) == 13356L,
  length(unique(conditional_age$observation_id)) == 371L,
  setequal(as.numeric(unique(conditional_age$age)), 0:35),
  all(as.numeric(conditional_age$sample_size) > 0),
  length(unique(negative_age$observation_id)) == 47L,
  all(grepl("Negative fleet code", negative_age$notes, fixed = TRUE)),
  all(grepl("B17.dat", inputs$source_reference, fixed = TRUE)),
  nrow(input_measure("age_error_mean_age")) == 72L,
  nrow(input_measure("ageing_error_sd")) == 72L,
  sum(assumptions$setting == "natural_mortality") == 1L,
  grepl("0.1588", assumptions$value[assumptions$setting == "natural_mortality"], fixed = TRUE),
  grepl("0.159 exponential offset", assumptions$value[assumptions$setting == "natural_mortality"], fixed = TRUE),
  length(unique(outputs$measure[!is.na(outputs$age) & outputs$measure != "recruitment"])) == 0L,
  nrow(output_measure("total_biomass")) == 13L,
  numeric_value(output_at("total_biomass", 2005)) == 1898,
  numeric_value(output_at("SSB", 2005)) == 386,
  output_at("SSB", 2005)$unit == "million eggs",
  numeric_value(recruitment_2006) == 369,
  as.numeric(recruitment_2006$lwr) == 172, as.numeric(recruitment_2006$upr) == 792,
  numeric_value(recruitment_2007) == 959,
  as.numeric(recruitment_2007$lwr) == 483, as.numeric(recruitment_2007$upr) == 1903,
  all(outputs$scenario[outputs$year == "2017"] == "2017 forecast"),
  all(is.na(outputs$se)),
  candidate$matched_stock_id == stock_id, candidate$match_status == "matched",
  candidate$import_status == "partial", candidate$inventory_assessment_year == "2017",
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial",
  nrow(provenance) == 4L, all(grepl("^[[:xdigit:]]{64}$", provenance$sha256)),
  all(as.numeric(provenance$bytes) > 0),
  grepl("not annual catch-at-age", review, fixed = TRUE),
  grepl("does not contain Report.sso", review, fixed = TRUE),
  grepl("age-invariant natural mortality", review, fixed = TRUE)
)

cat("Oregon Blue/Deacon source rows, units, coverage, outputs and provenance passed.\n")
