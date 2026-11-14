source("R/read_database.R")

database <- read_database()
record <- read_assessment("afma_sessf_eastern_school_whiting_2024", database)
outputs <- record$outputs

table43 <- subset(outputs, grepl("^Table 43:", scenario))
table44 <- subset(outputs, grepl("^Table 44:", scenario))
base_report <- subset(table43, scenario == "Table 43: Final combined base case")
base_minutes <- subset(outputs,
  measure == "unfished_spawning_biomass" & scenario == "2024 combined Tier 1 base case")
m05 <- subset(table43, scenario == "Table 43: Natural mortality M=0.5")
negative_delta <- subset(table43,
  measure == "change_in_negative_log_likelihood" & value < 0)
table44_2025 <- subset(table44, year == 2025L)
table44_2026 <- subset(table44, year == 2026L)

new_settings <- c(
  "assessment_length_weight_intercept_a",
  "assessment_length_weight_exponent_b",
  "female_length_at_50_percent_maturity",
  "female_maturity_slope"
)
new_assumptions <- subset(record$assumptions, setting %in% new_settings)

manifest <- read.csv("provenance/afma_school_whiting_2024/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
report <- subset(manifest, grepl("frdc_2019-030_final_report.pdf", local_file, fixed = TRUE))
report_path <- file.path("source_cache", report$local_file)
review <- paste(readLines("source_reviews/afma_school_whiting_sessf.md",
  warn = FALSE), collapse = " ")
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate,
  candidate_id == "AFMA:SESSF_Eastern_School_Whiting")

stopifnot(
  record$assessment$assessment_year == 2024L,
  all(record$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(record$inputs) == 0L,
  nrow(table43) == 95L,
  nrow(table44) == 10L,
  nrow(base_report) == 5L,
  subset(base_report, measure == "unfished_spawning_biomass")$value == 13208,
  subset(base_report, measure == "SSB")$value == 7110,
  subset(base_report, measure == "SSB_ratio_to_B0")$value == .54,
  nrow(negative_delta) > 0L,
  subset(base_minutes, value == 13207)$value == 13207,
  nrow(m05) == 5L,
  subset(m05, measure == "SSB")$value == 5631,
  subset(table44_2025, measure == "retained_catch")$value == 2489,
  subset(table44_2025, measure == "estimated_discards")$value == 597,
  subset(table44_2025, measure == "SSB_ratio_to_B0")$value == .538,
  subset(table44_2026, measure == "retained_catch")$value == 2374,
  subset(table44_2026, measure == "estimated_discards")$value == 587,
  subset(table44_2026, measure == "SSB_ratio_to_B0")$value == .509,
  subset(table44, measure == "long_term_yield")$value == 2830,
  nrow(new_assumptions) == 4L,
  setequal(new_assumptions$setting, new_settings),
  subset(new_assumptions, setting == "assessment_length_weight_intercept_a")$value == "1.32e-5",
  subset(new_assumptions, setting == "assessment_length_weight_exponent_b")$value == "2.93",
  subset(new_assumptions, setting == "female_length_at_50_percent_maturity")$value == "16 cm FL",
  subset(new_assumptions, setting == "female_maturity_slope")$value == "-2",
  all(is.na(c(base_report$se, base_report$lwr, base_report$upr))),
  nrow(report) == 1L,
  file.exists(report_path),
  toupper(unname(tools::sha256sum(report_path))) == report$sha256,
  nrow(candidate) == 1L,
  grepl("Table 43", candidate$output_evidence, fixed = TRUE),
  grepl("13,207 t", candidate$output_evidence, fixed = TRUE),
  grepl("March 2026", review, fixed = TRUE),
  grepl("not been digitized or inferred", review, fixed = TRUE),
  grepl("13,207 tonnes", review, fixed = TRUE),
  grepl("13,208 tonnes", review, fixed = TRUE)
)

cat("AFMA School Whiting detailed report source and outputs passed.\n")
