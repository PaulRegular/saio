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

assessment_id <- "noaa_gulf_red_snapper_2026"
stock_id <- "noaa_gulf_red_snapper"
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
cat("Read", nrow(inputs), "assessment input rows.\n")
assessments <- read_columns("database/assessments.csv", c("assessment_id",
  "stock_id", "assessment_year", "terminal_year", "estimate_terminal_year",
  "is_current", "is_applied", "model_family", "model_version",
  "inputs_status", "outputs_status", "assumptions_status"))
stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "ocean"))
assumptions <- read_columns("database/assumptions.csv", c("assessment_id",
  "component", "setting", "value", "source_reference", "notes"))
candidates <- read_columns("discovery/candidates.csv", c("candidate_id",
  "matched_stock_id", "match_status", "screening_status", "eligibility",
  "import_status", "survey_age_evidence", "output_evidence"))
selected <- read_columns("discovery/selected_batch_24_2026.csv", c("candidate_id",
  "curation_status", "detailed_source_url"))
manifest <- read.csv("provenance/discovery_noaa_gom_red_snapper_2026/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10230", , drop = FALSE]
selected_case <- selected[selected$candidate_id == "NOAA:10230", , drop = FALSE]
units <- read_columns("discovery/inventory_units.csv", c("unit_key", "matched_stock_id", "candidate_unit_id", "match_status", "import_status", "candidate_ids"))
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
get_output <- function(measure, type = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  if (!is.null(type)) x <- x[x$type == type, , drop = FALSE]
  x
}
get_input <- function(measure, survey, region, year) {
  inputs[inputs$measure == measure & inputs$survey == survey &
    inputs$region == region & inputs$year == as.character(year), , drop = FALSE]
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10230",
  stock$scientific_name == "Lutjanus campechanus",
  stock$area == "Gulf of Mexico",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2026",
  assessment$terminal_year == "2023",
  assessment$is_current == "TRUE",
  assessment$is_applied == "FALSE",
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.20",
  grepl("Tables 12-19", assessment$notes, fixed = TRUE),
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(assumptions) == 14L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  is.na(unit$candidate_unit_id) || unit$candidate_unit_id == "",
  unit$match_status == "matched",
  unit$import_status == "partial",
  grepl("NOAA:10230", unit$candidate_ids, fixed = TRUE),
  grepl("Tables 12-19", candidate$output_evidence, fixed = TRUE),
  grepl("Tables 5.8.1-5.8.3", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Tables 20-22", candidate$output_evidence, fixed = TRUE),
  nrow(selected_case) == 1L,
  selected_case$curation_status == "partial_source_import",
  grepl("dw-05", selected_case$detailed_source_url, fixed = TRUE),
  nrow(manifest) == 13L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(manifest$retrieved_on[manifest$file != "SEDAR98_DW13.pdf"] == "2026-11-09"),
  manifest$retrieved_on[manifest$file == "SEDAR98_DW13.pdf"] == "2026-11-11",
  nrow(inputs) == 7757L,
  sum(inputs$measure == "relative_abundance_index") == 647L,
  sum(inputs$measure == "abundance_index_cv") == 332L,
  sum(inputs$measure == "landings_biomass") == 642L,
  sum(inputs$measure == "discard_numbers") == 1403L,
  sum(inputs$measure == "discard_biomass") == 102L,
  sum(inputs$measure == "catch_se") == 336L,
  sum(inputs$measure == "landings_numbers") == 1439L,
  sum(inputs$measure == "catch_cv") == 819L,
  sum(inputs$measure == "natural_mortality_at_age") == 21L,
  sum(inputs$measure == "log_catch_sd") == 1578L,
  sum(inputs$measure == "log_index_sd") == 315L,
  sum(inputs$measure == "catch_numbers" & grepl("Table 99", inputs$source_reference, fixed = TRUE)) == 123L,
  sum(outputs$measure == "expected_relative_abundance_index") == 315L,
  sum(outputs$measure == "expected_landings_biomass") == 955L,
  sum(outputs$measure == "expected_landings_numbers") == 955L,
  sum(outputs$measure == "mean_landings_weight") == 955L,
  sum(outputs$measure == "expected_discard_numbers") == 623L,
  sum(outputs$measure == "expected_dead_discard_numbers") == 623L,
  sum(outputs$measure == "expected_discard_biomass") == 623L,
  sum(outputs$measure == "expected_dead_discard_biomass") == 623L,
  sum(outputs$measure == "mean_discard_weight") == 623L,
  length(unique(inputs$survey[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")])) == 16L,
  length(unique(paste(inputs$region[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")],
    inputs$survey[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")]))) == 34L,
  setequal(unique(inputs$region[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")]),
    c("West", "Central", "East")),
  all(is.finite(as.numeric(inputs$value))),
  all(inputs$year_basis[!is.na(inputs$year)] == "calendar_year"),
  all(inputs$source_type %in% c("official_table", "official_document", "reconstructed_source_input")),
  all(is.na(inputs$age[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")])),
  all(is.na(inputs$partition[inputs$measure %in% c("relative_abundance_index", "abundance_index_cv")])),
  nrow(outputs) == 9921L,
  setequal(unique(outputs$region[!is.na(outputs$region) & nzchar(outputs$region)]),
    c("West", "Central", "East")),
  setequal(unique(outputs$year), 1950:2023),
  nrow(get_output("total_biomass", "biomass")) == 222L,
  nrow(get_output("exploitable_biomass", "biomass")) == 222L,
  nrow(get_output("SSB", "biomass")) == 222L,
  nrow(get_output("numbers_at_age", "population")) == 222L,
  nrow(get_output("recruitment", "recruitment")) == 222L,
  nrow(get_output("SSB_ratio", "biomass")) == 222L,
  nrow(get_output("total_abundance", "population")) == 222L,
  nrow(get_output("exploitation_rate", "mortality")) == 2072L,
  all(get_output("exploitation_rate")$unit == "ratio"),
  all(get_output("exploitation_rate")$source_type == "official_table"),
  all(grepl("not instantaneous F", get_output("exploitation_rate")$notes, fixed = TRUE)),
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  all(is.na(get_output("numbers_at_age")$age)),
  all(get_output("numbers_at_age")$age_group == "1+"),
  abs(as.numeric(get_output("SSB")[get_output("SSB")$region == "West" &
    get_output("SSB")$year == 1950, "value"]) - 177309) < 1e-8,
  abs(as.numeric(get_output("SSB")[get_output("SSB")$region == "East" &
    get_output("SSB")$year == 2023, "value"]) - 6056) < 1e-8,
  abs(as.numeric(get_output("total_abundance")[get_output("total_abundance")$region == "Central" &
    get_output("total_abundance")$year == 1950, "value"]) - 47381) < 1e-8,
  all(grepl("denominator convention remains unresolved",
    get_output("SSB_ratio")$notes, fixed = TRUE)),
  all(grepl("rounded", get_output("total_abundance")$notes, fixed = TRUE))
)

model_landing <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 23" &
  inputs$measure == "landings_biomass" & inputs$year == "1950", , drop = FALSE]
model_landing_sd <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 23" &
  inputs$measure == "log_catch_sd" & inputs$year == "1950", , drop = FALSE]
model_discard <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 38" &
  inputs$measure == "discard_numbers" & inputs$year == "1996", , drop = FALSE]
model_discard_sd <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 38" &
  inputs$measure == "log_catch_sd" & inputs$year == "1996", , drop = FALSE]
model_index <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 59" &
  inputs$measure == "relative_abundance_index" & inputs$year == "1988", , drop = FALSE]
model_index_sd <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 59" &
  inputs$measure == "log_index_sd" & inputs$year == "1988", , drop = FALSE]
shrimp_bycatch <- inputs[inputs$source_reference == "SEDAR98_SAR.pdf, Table 99" &
  inputs$measure == "catch_numbers" & inputs$year == "1983" &
  inputs$region == "West", , drop = FALSE]
expected_landing <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 23" &
  outputs$measure == "expected_landings_biomass" & outputs$year == "1950", , drop = FALSE]
expected_landing_n <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 23" &
  outputs$measure == "expected_landings_numbers" & outputs$year == "1950", , drop = FALSE]
mean_landing_wt <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 23" &
  outputs$measure == "mean_landings_weight" & outputs$year == "1950", , drop = FALSE]
expected_discard <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 38" &
  outputs$measure == "expected_discard_numbers" & outputs$year == "1996", , drop = FALSE]
expected_dead_discard <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 38" &
  outputs$measure == "expected_dead_discard_numbers" & outputs$year == "1996", , drop = FALSE]
expected_discard_biomass <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 38" &
  outputs$measure == "expected_discard_biomass" & outputs$year == "1996", , drop = FALSE]
expected_index <- outputs[outputs$source_reference == "SEDAR98_SAR.pdf, Table 59" &
  outputs$measure == "expected_relative_abundance_index" & outputs$year == "1988", , drop = FALSE]
closed_discard_outputs <- outputs[outputs$measure == "expected_discard_numbers" &
  grepl("Table 44", outputs$source_reference, fixed = TRUE), , drop = FALSE]
stopifnot(
  nrow(model_landing) == 1L, as.numeric(model_landing$value) == 1.48,
  model_landing$partition == "landings",
  nrow(model_landing_sd) == 1L, as.numeric(model_landing_sd$value) == 0.05,
  nrow(model_discard) == 1L, as.numeric(model_discard$value) == 756,
  model_discard$partition == "discards",
  nrow(model_discard_sd) == 1L, as.numeric(model_discard_sd$value) == 0.665,
  nrow(model_index) == 1L, as.numeric(model_index$value) == 0.43,
  grepl("final model", model_index$survey, fixed = TRUE),
  nrow(model_index_sd) == 1L, as.numeric(model_index_sd$value) == 0.40,
  nrow(shrimp_bycatch) == 1L, as.numeric(shrimp_bycatch$value) == 11664.20,
  nrow(expected_landing) == 1L, as.numeric(expected_landing$value) == 1.48,
  nrow(expected_landing_n) == 1L, as.numeric(expected_landing_n$value) == 439,
  nrow(mean_landing_wt) == 1L, as.numeric(mean_landing_wt$value) == 3.4,
  nrow(expected_discard) == 1L, as.numeric(expected_discard$value) == 1738.510,
  nrow(expected_dead_discard) == 1L, as.numeric(expected_dead_discard$value) == 368.570,
  nrow(expected_discard_biomass) == 1L, as.numeric(expected_discard_biomass$value) == 1629.545,
  nrow(expected_index) == 1L, as.numeric(expected_index$value) == 0.31,
  nrow(closed_discard_outputs) > 0L,
  all(closed_discard_outputs$season == "closed_season")
)

index_values <- inputs[inputs$measure == "relative_abundance_index", , drop = FALSE]
index_cvs <- inputs[inputs$measure == "abundance_index_cv", , drop = FALSE]
index_keys <- c("survey", "region", "year")
matched_index <- merge(index_values[index_keys], index_cvs[index_keys],
  by = index_keys)
stopifnot(
  nrow(matched_index) == 332L,
  !anyDuplicated(matched_index),
  as.numeric(get_input("relative_abundance_index", "SEAMAP Fall Plankton",
    "West", 1986)$value) == 0.1747,
  as.numeric(get_input("abundance_index_cv", "SEAMAP Fall Plankton",
    "West", 1986)$value) == 0.5963,
  as.numeric(get_input("relative_abundance_index", "SEAMAP Groundfish Summer - Old",
    "West", 1984)$value) == 0.74713,
  as.numeric(get_input("abundance_index_cv", "SEAMAP Groundfish Summer - Old",
    "West", 1984)$value) == 0.28624,
  as.numeric(get_input("relative_abundance_index", "SEFSC Bottom Longline",
    "West", 2001)$value) == 0.28296,
  as.numeric(get_input("abundance_index_cv", "SEFSC Bottom Longline",
    "West", 2001)$value) == 0.26035,
  as.numeric(get_input("relative_abundance_index", "G-FISHER Reef Fish Video",
    "Central", 1993)$value) == 0.0964,
  as.numeric(get_input("abundance_index_cv", "G-FISHER Reef Fish Video",
    "Central", 1993)$value) == 0.6151,
  as.numeric(get_input("relative_abundance_index", "Observer Post-IFQ Commercial Vertical Line",
    "East", 2007)$value) == 0.325,
  as.numeric(get_input("abundance_index_cv", "Observer Post-IFQ Commercial Vertical Line",
    "East", 2007)$value) == 0.146
)

mature_m <- inputs[inputs$measure == "natural_mortality_at_age", , drop = FALSE]
mature_m <- mature_m[order(as.numeric(mature_m$age)), , drop = FALSE]
expected_m <- c(2.00, 1.20, 0.21, 0.17, 0.15, 0.14, 0.13, 0.12, 0.12,
  0.11, 0.11, 0.11, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10)
stopifnot(
  nrow(mature_m) == 21L,
  identical(as.integer(mature_m$age), 0:20),
  max(abs(as.numeric(mature_m$value) - expected_m)) < 1e-8,
  all(mature_m$unit == "per year"),
  grepl("Age 20 is the plus group", mature_m$notes[mature_m$age == 20], fixed = TRUE)
)

commercial_number <- inputs[inputs$measure == "discard_numbers" &
  inputs$fleet == "Handline Plus" & inputs$region == "East" &
  inputs$year == "1996" & inputs$season == "open", , drop = FALSE]
commercial_number_se <- inputs[inputs$measure == "catch_se" &
  inputs$observation_id == commercial_number$observation_id, , drop = FALSE]
stopifnot(
  nrow(commercial_number) == 1L,
  as.numeric(commercial_number$value) == 2634,
  nrow(commercial_number_se) == 1L,
  as.numeric(commercial_number_se$value) == 3174,
  commercial_number_se$unit == "fish standard error",
  commercial_number_se$basis == "native_scale"
)

recreational_discard <- inputs[inputs$measure == "discard_numbers" &
  inputs$fleet == "Charterboat" & inputs$region == "West" &
  inputs$year == "1981" & !is.na(inputs$partition) &
  inputs$partition == "federal_closed", , drop = FALSE]
recreational_discard_cv <- inputs[inputs$measure == "catch_cv" &
  inputs$fleet == "Charterboat" & inputs$region == "West" &
  inputs$year == "1981" & !is.na(inputs$partition) &
  inputs$partition == "federal_closed", , drop = FALSE]
stopifnot(
  nrow(recreational_discard) == 1L,
  as.numeric(recreational_discard$value) == 0,
  nrow(recreational_discard_cv) == 1L,
  as.numeric(recreational_discard_cv$value) == 0,
  grepl("Table 4.1", recreational_discard_cv$source_reference, fixed = TRUE)
)

partitioned_landing <- inputs[inputs$measure == "landings_numbers" &
  !is.na(inputs$partition) & nzchar(inputs$partition), , drop = FALSE]
annual_landing <- inputs[inputs$measure == "landings_numbers" &
  is.na(inputs$partition) & inputs$source_type == "reconstructed_source_input", , drop = FALSE]
landed_sum <- aggregate(as.numeric(value) ~ fleet + region + year,
  data = partitioned_landing, FUN = sum)
landing_match <- merge(annual_landing, landed_sum,
  by = c("fleet", "region", "year"))
stopifnot(
  nrow(annual_landing) == 273L,
  nrow(landing_match) == 273L,
  max(abs(as.numeric(landing_match$value) - landing_match$`as.numeric(value)`)) < 1e-8,
  all(grepl("Sum federal_open and federal_closed", annual_landing$transformation, fixed = TRUE))
)

n1 <- get_output("numbers_at_age", "population")
rec <- get_output("recruitment", "recruitment")
total_n <- get_output("total_abundance", "population")
joined <- merge(n1[, c("region", "year", "value")],
  rec[, c("region", "year", "value")], by = c("region", "year"),
  suffixes = c("_1plus", "_age0"))
joined <- merge(joined, total_n[, c("region", "year", "value")],
  by = c("region", "year"))
stopifnot(max(abs(as.numeric(joined$value) -
  as.numeric(joined$value_1plus) - as.numeric(joined$value_age0))) < 1e-8)

output_keys <- c("type", "measure", "fleet", "survey", "sex", "region", "season",
  "year", "age", "age_group", "scenario")
output_key <- do.call(paste, c(lapply(outputs[output_keys], function(x)
  ifelse(is.na(x), "", as.character(x))), sep = "\r"))
stopifnot(!anyDuplicated(output_key))

exploitation <- get_output("exploitation_rate", "mortality")
gulf_rate <- exploitation[is.na(exploitation$region) &
  exploitation$fleet == "All fleets", , drop = FALSE]
west_handline_rate <- exploitation[exploitation$region == "West" &
  exploitation$fleet == "Commercial Handline", , drop = FALSE]
west_charter_rate <- exploitation[exploitation$region == "West" &
  exploitation$fleet == "Recreational Charter", , drop = FALSE]
west_headboat_discard_rate <- exploitation[exploitation$region == "West" &
  exploitation$fleet == "Recreational Headboat Closed Season Discards", , drop = FALSE]
stopifnot(
  nrow(gulf_rate) == 74L,
  as.numeric(gulf_rate$value[gulf_rate$year == "1950"]) == 0.010,
  as.numeric(gulf_rate$value[gulf_rate$year == "1993"]) == 0.222,
  as.numeric(gulf_rate$value[gulf_rate$year == "2023"]) == 0.070,
  nrow(west_handline_rate) == 74L,
  as.numeric(west_handline_rate$value[west_handline_rate$year == "1950"]) == 0.004,
  as.numeric(west_charter_rate$value[west_charter_rate$year == "1950"]) == 0.002,
  as.numeric(west_headboat_discard_rate$value[
    west_headboat_discard_rate$year == "1950"]) == 0.001,
  all(is.na(exploitation$age)),
  all(exploitation$unit == "ratio")
)

review <- paste(readLines("discovery/source_reviews/noaa_gulf_red_snapper_2026.md",
  warn = FALSE), collapse = "\n")
stopifnot(
  grepl("tables do not provide standard errors or intervals", review, fixed = TRUE),
  grepl("does not mark it as applied for advice", review, fixed = TRUE),
  grepl("normalized to a mean of one", review, fixed = TRUE),
  grepl("DW-02 reports commercial landings by area and gear group", review, fixed = TRUE),
  grepl("546 recreational discard CV rows", review, fixed = TRUE),
  grepl("2,072 annual exploitation-rate outputs", review, fixed = TRUE),
  grepl("not instantaneous F", review, fixed = TRUE),
  grepl("full numerical likelihood arrays used by the final run", review, fixed = TRUE),
  grepl("denominator remains unresolved", review, fixed = TRUE)
)

gulf_candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
gulf_candidate <- gulf_candidate[gulf_candidate$candidate_id == "NOAA:10230", , drop = FALSE]
survey_evidence <- gulf_candidate$survey_age_evidence
stopifnot(nrow(gulf_candidate) == 1L,
  grepl("remain separate from 315 final-model indices", survey_evidence, fixed = TRUE),
  grepl("Tables 23-58", gulf_candidate$catch_age_evidence, fixed = TRUE),
  grepl("Tables 59-75", survey_evidence, fixed = TRUE),
  grepl("Tables 12-19", gulf_candidate$output_evidence, fixed = TRUE),
  grepl("Tables 20-22", gulf_candidate$output_evidence, fixed = TRUE),
  grepl("Table 99", gulf_candidate$output_evidence, fixed = TRUE))

cat("NOAA Gulf red snapper 2026 source inputs, outputs, status, units, derivation and provenance passed.\n")
