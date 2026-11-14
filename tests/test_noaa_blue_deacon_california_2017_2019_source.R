read_assessment_rows <- function(path, assessment_ids) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- unlist(lapply(assessment_ids, function(id) {
    x <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
      "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
    status <- attr(x, "status")
    if (is.null(status)) status <- 0L
    if (status == 1L) character() else if (status != 0L) stop("Could not read ", path) else
      x[startsWith(x, paste0("\"", id, "\","))]
  }), use.names = FALSE)
  if (!length(rows)) return(read.csv(text = header, nrows = 0L, check.names = FALSE,
    colClasses = "character"))
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

ids <- c("noaa_blue_deacon_california_2017", "noaa_blue_deacon_california_2019")
stock_id <- "noaa_blue_deacon_california"
inputs <- read_assessment_rows("database/inputs.csv", ids)
outputs <- read_assessment_rows("database/outputs.csv", ids)
assumptions <- read_assessment_rows("database/assumptions.csv", ids)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE, check.names = FALSE)
provenance <- read.csv(
  "provenance/discovery_noaa_blue_deacon_california_2017/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_blue_deacon_california_2017_2019.md",
  warn = FALSE), collapse = " ")

input_measure <- function(measure, assessment_id = ids[1L]) {
  inputs[inputs$assessment_id == assessment_id & inputs$measure == measure, , drop = FALSE]
}
output_measure <- function(measure, assessment_id = ids[1L]) {
  outputs[outputs$assessment_id == assessment_id & outputs$measure == measure, , drop = FALSE]
}
output_at <- function(measure, year, assessment_id = ids[1L]) {
  x <- output_measure(measure, assessment_id)
  x[x$year == as.character(year), , drop = FALSE]
}
numeric_value <- function(x) as.numeric(x$value)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment_2017 <- assessments[assessments$assessment_id == ids[1L], , drop = FALSE]
assessment_2019 <- assessments[assessments$assessment_id == ids[2L], , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:14821", , drop = FALSE]
unit <- inventory[inventory$unit_key == paste0("candidate:", stock_id), , drop = FALSE]
conditional_age <- input_measure("conditional_frequency_at_age")
age_comp <- input_measure("frequency_at_age")
length_comp <- input_measure("frequency_at_length")
update_catch <- input_measure("catch_biomass", ids[2L])

stopifnot(
  nrow(stock) == 1L, stock$ocean == "Northeast Pacific", stock$region == "California",
  stock$authority_stock_id == "14821",
  nrow(assessment_2017) == 1L, assessment_2017$assessment_year == "2017",
  assessment_2017$terminal_year == "2016", assessment_2017$estimate_terminal_year == "2017",
  assessment_2017$is_current == "FALSE", assessment_2017$inputs_status == "partial",
  assessment_2017$outputs_status == "partial",
  nrow(assessment_2019) == 1L, assessment_2019$assessment_year == "2019",
  assessment_2019$terminal_year == "2018", assessment_2019$estimate_terminal_year == "2019",
  assessment_2019$is_current == "TRUE", assessment_2019$assessment_type == "catch_only_update",
  nrow(inputs) == 15218L, nrow(assumptions) == 12L, nrow(outputs) == 920L,
  nrow(input_measure("catch_biomass")) == 641L,
  nrow(input_measure("catch_se")) == 641L,
  min(as.numeric(input_measure("catch_biomass")$year)) == 1900,
  max(as.numeric(input_measure("catch_biomass")$year)) == 2016,
  length(unique(input_measure("catch_biomass")$fleet)) == 8L,
  nrow(input_measure("relative_abundance_index")) == 69L,
  nrow(input_measure("log_index_sd")) == 70L,
  sum(grepl("disabled scenario-only SSB constraint", input_measure("log_index_sd")$notes,
    fixed = TRUE)) == 1L,
  length(unique(input_measure("relative_abundance_index")$survey)) == 5L,
  all(as.numeric(input_measure("relative_abundance_index")$sampling_time) == 0.5),
  all(as.numeric(input_measure("relative_abundance_index")$year) >= 1980),
  nrow(input_measure("spawning_output_index")) == 1L,
  input_measure("spawning_output_index")$basis == "native_scale",
  input_measure("spawning_output_index")$unit ==
    "native Stock Synthesis special index unit code 30",
  grepl("disabled in the base likelihood", input_measure("spawning_output_index")$notes,
    fixed = TRUE),
  nrow(length_comp) == 3806L,
  length(unique(length_comp$observation_id)) == 162L,
  sum(length_comp$sex == "combined") == 3322L,
  sum(length_comp$sex == "female") == 242L,
  sum(length_comp$sex == "male") == 242L,
  setequal(as.numeric(unique(length_comp$length_bin)), seq(10, 52, by = 2)),
  nrow(conditional_age) == 9072L,
  all(conditional_age$type == "biology"),
  length(unique(conditional_age$observation_id)) == 126L,
  nrow(age_comp) == 720L,
  length(unique(age_comp$observation_id)) == 10L,
  setequal(as.numeric(unique(conditional_age$age)), 0:35),
  all(as.numeric(conditional_age$sample_size) > 0),
  all(grepl("Negative fleet code", age_comp$notes, fixed = TRUE)),
  nrow(input_measure("age_error_mean_age")) == 72L,
  nrow(input_measure("ageing_error_sd")) == 72L,
  nrow(update_catch) == 54L,
  min(as.numeric(update_catch$year)) == 2010,
  max(as.numeric(update_catch$year)) == 2018,
  !any(as.numeric(update_catch$year) == 2019),
  nrow(output_measure("total_biomass")) == 118L,
  numeric_value(output_at("SSB", 2005)) == 383,
  as.numeric(output_at("SSB", 2005)$lwr) == 85,
  as.numeric(output_at("SSB", 2005)$upr) == 682,
  numeric_value(output_at("age0_recruitment", 2005)) == 2807,
  numeric_value(output_at("recruitment", 2005)) == 1623,
  numeric_value(output_at("SSB", 2017)) == 812,
  output_at("SSB", 2017)$scenario == "2017 estimate beyond native input terminal year 2016",
  numeric_value(output_measure("natural_mortality_parameter"))[1L] == 0.119,
  output_measure("natural_mortality_parameter")$type == "parameter",
  numeric_value(output_measure("log_male_natural_mortality_offset"))[1L] == 0.315,
  output_measure("log_male_natural_mortality_offset")$type == "parameter",
  nrow(output_measure("extra_log_index_sd")) == 5L,
  all(output_measure("extra_log_index_sd")$type == "parameter"),
  numeric_value(output_at("SSB", 2019, ids[2L])) == 903,
  as.numeric(output_at("SSB", 2019, ids[2L])$lwr) == 0,
  as.numeric(output_at("SSB", 2019, ids[2L])$upr) == 1867,
  numeric_value(output_at("recruitment", 2019, ids[2L])) == 3866,
  as.numeric(output_at("recruitment", 2019, ids[2L])$lwr) == 1285,
  as.numeric(output_at("recruitment", 2019, ids[2L])$upr) == 11631,
  numeric_value(output_at("spr_ratio_to_target", 2019, ids[2L])) == 0.789,
  candidate$matched_stock_id == stock_id, candidate$match_status == "matched",
  candidate$import_status == "partial", candidate$inventory_assessment_year == "2019",
  unit$matched_stock_id == stock_id, unit$import_status == "partial",
  nrow(provenance) == 8L, all(grepl("^[[:xdigit:]]{64}$", provenance$sha256)),
  all(as.numeric(provenance$bytes) > 0),
  grepl("Report.sso", review, fixed = TRUE),
  grepl("1,623 thousand fish", review, fixed = TRUE),
  grepl("management treatment unclear", review, fixed = TRUE)
)

cache <- "source_cache/discovery_noaa_blue_deacon_2017"
for (i in seq_len(nrow(provenance))) {
  path <- file.path(cache, provenance$local_file[i])
  stopifnot(file.exists(path), file.info(path)$size == as.numeric(provenance$bytes[i]),
    tolower(unname(tools::sha256sum(path))) == tolower(provenance$sha256[i]))
}

cat("California Blue/Deacon 2017 and 2019 source rows, dimensions, outputs, discrepancies and provenance passed.\n")
