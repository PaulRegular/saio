read_source_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

stock_id <- "npfc_chub_mackerel_nw_pacific"
assessment_id <- "npfc_chub_mackerel_nw_pacific_2025"
stocks <- read_source_table("database/stocks.csv")
stock <- subset(stocks, stocks$stock_id == "npfc_chub_mackerel_nw_pacific")
assessments <- read_source_table("database/assessments.csv")
assessment <- assessments[assessments[["assessment_id"]] == assessment_id, , drop = FALSE]
inputs <- subset(read_source_table("database/inputs.csv"),
  assessment_id == "npfc_chub_mackerel_nw_pacific_2025")
outputs <- subset(read_source_table("database/outputs.csv"),
  assessment_id == "npfc_chub_mackerel_nw_pacific_2025")
assumptions <- subset(read_source_table("database/assumptions.csv"),
  assessment_id == "npfc_chub_mackerel_nw_pacific_2025")
candidates <- read_source_table("discovery/candidates.csv")
candidate <- subset(candidates, candidates$candidate_id == "NPFC:CM_NWPO")
manifest <- read_source_table(
  "provenance/npfc_chub_mackerel_nw_pacific_2025_sources.csv")
review <- paste(readLines(
  "source_reviews/npfc_chub_mackerel_nw_pacific_2025.md", warn = FALSE),
  collapse = "\n")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NPFC",
  stock$scientific_name == "Scomber japonicus",
  stock$area == "NPFC Convention Area and Member EEZs",
  stock$ocean == "Northwest Pacific",
  is.na(stock$authority_stock_id) || stock$authority_stock_id == "",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2023,
  assessment$estimate_terminal_year == 2024,
  assessment$model_family == "SAM",
  assessment$model_version == "S02-Index24_1",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 7L,
  identical(as.integer(as.numeric(inputs$age)), 0:6),
  isTRUE(all.equal(as.numeric(inputs$value), c(0.80, 0.60, 0.51, 0.46, 0.43, 0.41, 0.40))),
  all(inputs$type == "M"),
  all(inputs$measure == "natural_mortality_at_age"),
  all(inputs$basis == "per_year"),
  all(inputs$unit == "per year"),
  all(is.na(inputs$year)),
  all(inputs$source_type == "official_table"),
  nrow(outputs) == 24L,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  all(outputs$source_type == "official_table"),
  all(c("SSB_reference_point_25th_percentile",
    "SSB_reference_point_50th_percentile",
    "SSB_reference_point_70th_percentile") %in% outputs$measure),
  all(c("SSB_ratio_to_25th_percentile_reference",
    "SSB_ratio_to_50th_percentile_reference",
    "SSB_ratio_to_70th_percentile_reference") %in% outputs$measure),
  nrow(assumptions) >= 20L,
  any(assumptions$setting == "within_year_timing" & assumptions$value == "unknown"),
  any(assumptions$setting == "Fcurrent_period" & assumptions$value == "unknown"),
  nrow(candidate) == 1L,
  candidate$match_status == "matched",
  candidate$matched_stock_id == stock_id,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(manifest) == 4L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("errors in FY2014-FY2017 catch-at-age", review, ignore.case = TRUE),
  grepl("FY2020-FY2023", review),
  grepl("FY2021-FY2023", review),
  grepl("eligibility remains unresolved", review, ignore.case = TRUE)
)

f_metrics <- c(
  current_spawning_potential_ratio = 16.2,
  `F0.1_ratio_to_Fcurrent` = 0.838,
  `F30SPR_ratio_to_Fcurrent` = 0.580,
  `F40SPR_ratio_to_Fcurrent` = 0.412,
  `F50SPR_ratio_to_Fcurrent` = 0.295,
  `F60SPR_ratio_to_Fcurrent` = 0.207,
  `F70SPR_ratio_to_Fcurrent` = 0.139
)
recent_f <- subset(outputs, scenario ==
  "S02-Index24_1; biological parameters FY2016-FY2023")
recent_values <- setNames(as.numeric(recent_f$value), recent_f$measure)
stopifnot(isTRUE(all.equal(recent_values[names(f_metrics)], f_metrics)))

full_f <- subset(outputs, scenario ==
  "S02-Index24_1; biological parameters FY1970-FY2023")
full_values <- setNames(as.numeric(full_f$value), full_f$measure)
full_expected <- c(
  current_spawning_potential_ratio = 27.8,
  `F0.1_ratio_to_Fcurrent` = 0.838,
  `F30SPR_ratio_to_Fcurrent` = 0.911,
  `F40SPR_ratio_to_Fcurrent` = 0.609,
  `F50SPR_ratio_to_Fcurrent` = 0.416,
  `F60SPR_ratio_to_Fcurrent` = 0.282,
  `F70SPR_ratio_to_Fcurrent` = 0.184
)
stopifnot(isTRUE(all.equal(full_values[names(full_expected)], full_expected)))

reference_values <- setNames(as.numeric(outputs$value), outputs$measure)
stopifnot(
  reference_values[["unfished_spawning_biomass"]] == 1399,
  reference_values[["SSB_reference_point_25th_percentile"]] == 107,
  reference_values[["SSB_reference_point_50th_percentile"]] == 289,
  reference_values[["SSB_reference_point_70th_percentile"]] == 585
)

status_rows <- subset(outputs, !is.na(year) & year == "2023")
status_values <- setNames(as.numeric(status_rows$value), status_rows$measure)
stopifnot(isTRUE(all.equal(status_values, c(
  SSB_ratio_to_25th_percentile_reference = 1.23,
  SSB_ratio_to_50th_percentile_reference = 0.46,
  SSB_ratio_to_70th_percentile_reference = 0.23
))))

cat("NPFC Northwest Pacific chub mackerel source validation passed.\n")
