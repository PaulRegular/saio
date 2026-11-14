source("R/read_database.R")
x <- read_assessment("afma_blue_grenadier_cts_2025")

stopifnot(
  x$stocks$scientific_name == "Macruronus novaezelandiae",
  x$stocks$authority == "AFMA",
  x$stocks$authority_stock_id == "Commonwealth Trawl Sector (CTS)",
  x$stocks$ocean == "Southwest Pacific and Southern Ocean",
  x$assessment$assessment_year == 2025,
  x$assessment$assessment_type == "update",
  x$assessment$terminal_year == 2024,
  x$assessment$estimate_terminal_year == 2026,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$model_family == "unknown",
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x$inputs) == 0L
)

stopifnot(
  nrow(x$outputs) == 18L,
  sum(x$outputs$measure == "spawning_biomass_ratio") == 3L
)
ratio <- x$outputs[x$outputs$measure == "spawning_biomass_ratio", ]
stopifnot(
  setequal(ratio$year, c(2022, 2023, 2026)),
  identical(ratio$value[match(c(2022, 2023, 2026), ratio$year)], c(107, 112, 99.5)),
  ratio$source_type[ratio$year == 2026] == "official_document",
  grepl("rounds this to 100%", ratio$notes[ratio$year == 2026], fixed = TRUE)
)

b0 <- x$outputs[x$outputs$measure == "unfished_spawning_biomass", ]
m <- x$outputs[x$outputs$measure == "natural_mortality_average_parameter", ]
rbc <- x$outputs[x$outputs$measure == "recommended_biological_catch", ]
annual_rbc <- rbc[!is.na(as.numeric(rbc$year)), ]
discards <- x$outputs[x$outputs$measure == "estimated_discards", ]
annual_discards <- discards[!is.na(as.numeric(discards$year)), ]
discount <- x$outputs[x$outputs$measure == "tier_2_discount_factor", ]
provisional_tac <- x$outputs[x$outputs$measure == "provisional_TAC", ]
long_term <- x$outputs[x$outputs$measure %in%
  c("long_term_recommended_biological_catch", "long_term_estimated_discards"), ]
stopifnot(
  nrow(b0) == 1L, b0$value == 42626, b0$unit == "tonnes",
  nrow(m) == 2L, all(m$type == "parameter"),
  m$value[m$sex == "female"] == 0.238, m$value[m$sex == "male"] == 0.248,
  all(m$unit == "per year"),
  all(as.numeric(annual_rbc$year[order(as.numeric(annual_rbc$year))]) == 2026:2028),
  identical(as.numeric(annual_rbc$value[order(as.numeric(annual_rbc$year))]),
    c(17744, 15459, 13727)),
  rbc$value[is.na(as.numeric(rbc$year))] == 15643,
  identical(as.numeric(annual_discards$value[order(as.numeric(annual_discards$year))]),
    c(218, 209, 205)),
  discards$value[is.na(as.numeric(discards$year))] == 211,
  discount$value == 782,
  provisional_tac$value == 14650,
  setequal(long_term$measure,
    c("long_term_recommended_biological_catch", "long_term_estimated_discards")),
  long_term$value[long_term$measure == "long_term_recommended_biological_catch"] == 8300,
  grepl("Approximate", long_term$notes[long_term$measure ==
    "long_term_recommended_biological_catch"], fixed = TRUE),
  all(is.na(x$outputs$se)), all(is.na(x$outputs$lwr)), all(is.na(x$outputs$upr))
)

assumptions <- x$assumptions
acoustic <- assumptions[assumptions$setting == "acoustic_base_case_years", ]
coverage <- assumptions[assumptions$setting == "data_year_coverage", ]
stopifnot(
  nrow(assumptions) == 10L,
  nrow(acoustic) == 1L,
  grepl("2003-2010", acoustic$value, fixed = TRUE),
  grepl("2020-2021 and 2023-2024", acoustic$value, fixed = TRUE),
  nrow(coverage) == 1L,
  grepl("through 2024", coverage$value, fixed = TRUE),
  assumptions$value[assumptions$setting == "steepness"] == "0.75 (fixed)",
  assumptions$value[assumptions$setting == "estimated_recruitment_years"] == "1974-2019",
  assumptions$value[assumptions$setting == "length_at_50_percent_maturity"] == "63.7 cm",
  grepl("Estimated separately by sex", assumptions$value[
    assumptions$setting == "natural_mortality"], fixed = TRUE),
  !anyDuplicated(assumptions$setting),
  assumptions$value[assumptions$setting == "survey_timing"] == "unknown"
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- candidate[candidate$candidate_id == "AFMA:SESSF_CTS_Blue_Grenadier", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$organization == "AFMA",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("numerical catch and age inputs were not found", candidate$catch_age_evidence, fixed = TRUE),
  grepl("0.238", candidate$mortality_evidence, fixed = TRUE),
  grepl("RBC", candidate$output_evidence, fixed = TRUE)
)

manifest <- read.csv("provenance/afma_blue_grenadier_cts_2025_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(
  nrow(manifest) == 5L,
  all(grepl("^https://www\\.afma\\.gov\\.au/", manifest$source_url)),
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  any(grepl("2026 SESSF Species Summaries", manifest$represented_source, fixed = TRUE))
)

cat("AFMA Blue Grenadier 2025 source checks passed.\n")
