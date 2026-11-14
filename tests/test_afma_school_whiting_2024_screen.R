register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- register[
  register$candidate_id == "AFMA:SESSF_Eastern_School_Whiting", , drop = FALSE
]
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
stock <- stocks[stocks$stock_id == "afma_sessf_eastern_school_whiting", , drop = FALSE]
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
assessment <- assessments[
  assessments$assessment_id == "afma_sessf_eastern_school_whiting_2024", , drop = FALSE
]
outputs <- read.csv("database/outputs.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
outputs <- outputs[
  outputs$assessment_id == "afma_sessf_eastern_school_whiting_2024", , drop = FALSE
]
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
assumptions <- assumptions[
  assumptions$assessment_id == "afma_sessf_eastern_school_whiting_2024", , drop = FALSE
]
manifest <- read.csv(
  "provenance/afma_school_whiting_2024/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "afma_sessf_eastern_school_whiting",
  candidate$scientific_name == "Sillago flindersi",
  candidate$inventory_assessment_year == 2024L,
  candidate$match_status == "new",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("54%", candidate$output_evidence, fixed = TRUE),
  nrow(stock) == 1L,
  stock$ocean == "Southwest Pacific and Southern Ocean",
  nrow(assessment) == 1L,
  assessment$terminal_year == 2023L,
  assessment$estimate_terminal_year == 2025L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(outputs) == 4L,
  outputs$value[outputs$measure == "SSB_ratio_to_B0"] == 54,
  outputs$unit[outputs$measure == "SSB_ratio_to_B0"] == "percent",
  outputs$value[outputs$measure == "recommended_biological_catch" &
    !is.na(outputs$year) & outputs$year == 2025] == 3086,
  outputs$value[outputs$measure == "recommended_biological_catch" &
    !is.na(outputs$year) & outputs$year == 2026] == 2961,
  outputs$value[outputs$measure == "recommended_biological_catch" & is.na(outputs$year)] == 3024,
  nrow(assumptions[assumptions$component == "M" &
    assumptions$setting == "natural_mortality" & assumptions$value == "0.6 per year (pre-specified)", ]) == 1L,
  nrow(manifest) == 3L,
  all(nchar(manifest$sha256) == 64L),
  file.exists("source_reviews/afma_school_whiting_sessf.md")
)

cached <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cached))) {
  stopifnot(all(toupper(unname(tools::sha256sum(cached))) ==
    toupper(manifest$sha256)))
}

cat("AFMA eastern school whiting source checks passed.\n")
