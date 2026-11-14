source_id <- "ccsbt_sbt_2026"
stock_id <- "ccsbt_sbt"
candidate_id <- "CCSBT:SBT"

if (!file.exists("database/stocks.csv")) {
  stop("Run this script from the SAIO repository root.")
}

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}

append_rows <- function(path, rows) {
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    final_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(final_byte, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(c(13L, 10L)), con)
      close(con)
    }
  }
  rows[] <- lapply(rows, as.character)
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

manifest <- read_table("provenance/ccsbt_sbt_2026_sources.csv")
local_files <- file.path("source_cache", manifest$local_file)
if (any(!file.exists(local_files))) {
  stop("The cached CCSBT source PDFs are required before importing this record.")
}
actual_hashes <- toupper(unname(tools::sha256sum(local_files)))
if (!identical(actual_hashes, toupper(manifest$sha256))) {
  stop("A cached CCSBT source PDF does not match its recorded SHA-256 checksum.")
}

stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
candidates <- read_table("discovery/candidates.csv")
stopifnot(!stock_id %in% stocks$stock_id,
  !source_id %in% assessments$assessment_id,
  !candidate_id %in% candidates$candidate_id)

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = NA_character_,
  authority = "CCSBT",
  authority_stock_id = "SBT",
  scientific_name = "Thunnus maccoyii",
  common_name = "Southern bluefin tuna",
  area = "Circumglobal Southern Hemisphere stock",
  region = "CCSBT global stock",
  ocean = "Southern Ocean",
  notes = paste(
    "One CCSBT-wide stock across the Southern Hemisphere.",
    "Southern Ocean is a broad database grouping and does not imply",
    "that the stock is confined to that ocean."
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = source_id,
  stock_id = stock_id,
  assessment_year = "2026",
  terminal_year = "2025",
  estimate_terminal_year = "2026",
  assessment_type = "full_assessment",
  model_family = "R-RTMB annual age-structured assessment",
  model_version = "CCSBT-ESC/2608/20; nine-cell reference-set MCMC",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = NA_character_,
  assessment_url = "https://www.ccsbt.org/system/files/2026-08/ESC31_20_AU-JP_sbt_stock_assessment_2026.pdf",
  framework_url = NA_character_,
  data_url = "https://www.ccsbt.org/system/files/2026-06/OMMP16_09_AU_DataPrep2026Assessment.pdf",
  model_url = NA_character_,
  repository_url = NA_character_,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The full assessment reports 2026 stock status using catch data through 2025.",
    "Run-matched numerical input arrays and annual age-specific output tables",
    "were not located in public sources. The 2026 assessment informs stock-status",
    "reporting; the 2027-2029 global TAC was calculated by the Cape Town",
    "Procedure in 2025 and is not an output of this assessment."
  ),
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(
    assessment_id = source_id,
    component = component,
    fleet = NA_character_,
    survey = NA_character_,
    sex = NA_character_,
    region = "CCSBT global stock",
    season = NA_character_,
    setting = setting,
    value = value,
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("population", "model_structure",
    "Annual age-structured population dynamics with two seasons.",
    "CCSBT ESC31/20 (2026), Section 3, PDF p. 5"),
  assumption("population", "catch_fleets",
    "Six catch fisheries: LL1-LL4, Indonesian and Australian surface; the CPUE likelihood uses a separate selectivity block.",
    "CCSBT ESC31/20 (2026), Section 2, PDF pp. 4-5"),
  assumption("observation", "composition_likelihoods",
    "Length compositions for the four longline fisheries; age compositions for the Indonesian and Australian surface fisheries; CPUE-weighted Japanese longline length compositions inform CPUE selectivity.",
    "CCSBT ESC31/20 (2026), Section 2, PDF pp. 4-5"),
  assumption("observation", "abundance_and_tag_data",
    "Japanese longline relative-abundance CPUE, aerial relative biomass for ages 2-4, conventional tag recaptures, age-2 gene tagging, POP and HSP close-kin data, and unaccounted-mortality estimates.",
    "CCSBT ESC31/20 (2026), Section 2, PDF pp. 5-6"),
  assumption("mortality", "natural_mortality",
    "Length-scaled M through age 25: M_a = M10 (L_a/L10)^(-1), with M10 estimated; M increases linearly from M25 to M30, with M30 estimated.",
    "CCSBT ESC31/20 (2026), Section 1, PDF p. 4",
    "The assessment uses mean length-at-age from the first year and season. The final report describes this formulation; no numeric run-matched length-at-age array was imported."),
  assumption("population", "reference_set",
    "Nine MCMC grid cells cross three steepness values and three CKMR reproductive-contribution parameter values; M10 and M30 are estimated within each cell.",
    "CCSBT ESC31/20 (2026), Section 1 and Section 3, PDF pp. 3 and 5-6"),
  assumption("assessment", "output_convention",
    "Table 1 values are posterior medians and 95% credible intervals across the reference set. Relative TRO and age-10+ biomass refer to 2026; MSY quantities use 2025, the latest fitted catch year.",
    "CCSBT ESC31/20 (2026), Table 1, PDF p. 12; Table 3 note, PDF p. 15"),
  assumption("source", "run_data_availability",
    "The reviewed public sources describe the observation streams but do not provide complete run-matched numeric arrays. The public sbt package examples use simulated data; assessment source objects are identified as private.",
    "CCSBT OMMP16/09 (2026); CCSBT OMMP14 Info 01 (2024); public sbt model data documentation",
    "No canonical input observations were imported.")
))

output <- function(type, measure, value, unit, year, lwr = NA_character_,
                   upr = NA_character_, scenario = "reference set",
                   source_reference, notes) {
  data.frame(
    assessment_id = source_id,
    type = type,
    measure = measure,
    fleet = NA_character_,
    survey = NA_character_,
    sex = NA_character_,
    region = "CCSBT global stock",
    season = NA_character_,
    year = as.character(year),
    age = NA_character_,
    age_group = NA_character_,
    value = as.character(value),
    se = NA_character_,
    lwr = as.character(lwr),
    upr = as.character(upr),
    unit = unit,
    source_type = "official_table",
    source_reference = source_reference,
    notes = notes,
    scenario = scenario,
    stringsAsFactors = FALSE
  )
)

table1 <- "CCSBT ESC31/20 (2026), Table 1, PDF p. 12"
table4 <- "CCSBT ESC31/20 (2026), Table 4, PDF p. 19"
outputs <- do.call(rbind, list(
  output("biomass", "relative_total_reproductive_output", 0.281, "ratio", 2026,
    0.209, 0.373, source_reference = table1,
    notes = "Posterior median and 95% credible interval; TRO2026/TRO0."),
  output("probability", "probability_relative_TRO_below_0.2", 0.011, "probability", 2026,
    source_reference = table1,
    notes = "Posterior probability; no interval reported."),
  output("biomass", "relative_biomass_age_10_plus", 0.231, "ratio", 2026,
    0.171, 0.313, source_reference = table1,
    notes = "Posterior median and 95% credible interval; age-10+ biomass depletion."),
  output("mortality", "F_ratio_to_FMSY", 0.553, "ratio", 2025,
    0.383, 0.811, source_reference = table1,
    notes = "Posterior median and 95% credible interval; latest fitted catch year."),
  output("biomass", "TRO_ratio_to_TRO_MSY", 0.985, "ratio", 2025,
    0.629, 1.587, source_reference = table1,
    notes = "Posterior median and 95% credible interval; latest fitted catch year."),
  output("catch", "MSY", 32529, "tonnes", 2025,
    26400, 39381, source_reference = table1,
    notes = "Posterior median and 95% credible interval."),
  output("probability", "probability_TRO2035_above_0.2_TRO0", 0.990, "probability", 2035,
    scenario = "reference-set projection; nominal allocations",
    source_reference = table4,
    notes = "Posterior probability; no interval reported."),
  output("probability", "probability_TRO2035_above_0.3_TRO0", 0.712, "probability", 2035,
    scenario = "reference-set projection; nominal allocations",
    source_reference = table4,
    notes = "Posterior probability; no interval reported."),
  output("biomass", "relative_total_reproductive_output", 0.339, "ratio", 2035,
    0.218, 0.542, scenario = "reference-set projection; nominal allocations",
    source_reference = table4,
    notes = "Posterior median and 95% credible interval; TRO2035/TRO0."),
  output("catch", "mean_catch_2026_2035", 25399, "tonnes", 2026,
    25349, 26249, scenario = "reference-set projection; nominal allocations",
    source_reference = table4,
    notes = "Mean annual TAC over 2026-2035; posterior median and 95% credible interval.")
))

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = stock_id,
  organization = "CCSBT",
  official_stock_id = "SBT",
  scientific_name = "Thunnus maccoyii",
  stock_name = "Southern bluefin tuna",
  assessment_area = "CCSBT-wide circumglobal stock, Southern Hemisphere",
  inventory_assessment_year = "2026",
  inventory_url = "https://www.ccsbt.org/en/content/latest-stock-assessment",
  retrieved_on = "2026-11-06",
  matched_stock_id = NA_character_,
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "partial",
  catch_age_evidence = "The 2026 assessment uses age compositions for Indonesian and Australian surface fisheries, but longline fleets use length compositions. Numerical age vectors are not present in reviewed public assessment files.",
  survey_age_evidence = "The assessment uses age-2-4 aerial relative biomass and age-2 gene-tagging abundance information, alongside aggregate CPUE; run-matched numeric arrays were not recovered.",
  weights_evidence = "The final report describes length-based natural mortality and age-specific selectivity but no numerical run-matched weight-at-age array was recovered.",
  maturity_evidence = "The 2026 preparation paper lists length-based maturity settings, but the final full assessment report does not confirm their retention; no maturity-at-age vector is publicly available.",
  mortality_evidence = "The 2026 assessment estimates M10 and M30 within its model grid and uses a length-scaled age curve with fixed exponent -1.",
  timing_evidence = "The population model has two annual seasons and assigns fisheries to seasons; no single within-year timing for survey observations was recovered.",
  output_evidence = "The official 2026 full assessment reports relative TRO, age-10+ biomass depletion, F/FMSY, TRO/TROMSY, MSY, and projection summaries; numerical annual N/F/M-at-age arrays were not found.",
  detailed_source_url = paste(
    "https://www.ccsbt.org/system/files/2026-08/ESC31_20_AU-JP_sbt_stock_assessment_2026.pdf;",
    "https://www.ccsbt.org/system/files/2026-06/OMMP16_09_AU_DataPrep2026Assessment.pdf"
  ),
  review_date = "2026-11-06",
  decision_reason = "A partial current-run record is supported by official scalar outputs and model-structure details. Age-input eligibility remains unresolved because the assessment confirms age-based likelihoods and indices but public run-matched numeric input arrays, biological vectors and annual age-specific output tables were not located. No older assessment was substituted.",
  notes = "One CCSBT-wide stock unit; national fleets, sexes, and grid cells are not counted as separate cases. See source_reviews/ccsbt_sbt_2026.md. The public sbt examples are simulated, while the assessment source objects are identified as private."
)

append_rows("database/stocks.csv", stock)
append_rows("database/assessments.csv", assessment)
append_rows("database/assumptions.csv", assumptions)
append_rows("database/outputs.csv", outputs)
append_rows("discovery/candidates.csv", candidate)

source("scripts/database/195_summarize_discovery.R", local = TRUE)
source("scripts/database/196_summarize_inventory_units.R", local = TRUE)

cat("Imported CCSBT 2026 SBT source review and partial stock-status outputs.\n")
cat("No numerical input arrays or annual age-specific output surfaces were available for import.\n")
