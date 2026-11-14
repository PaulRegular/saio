assessment_id <- "qld_saddletail_snapper_east_coast_2026"
stock_id <- "qld_saddletail_snapper_east_coast"
report <- "https://era.dpi.qld.gov.au/id/eprint/15593/1/2026%20East%20Coast%20Saddletail%20Snapper%20stock%20assessment.pdf"
record <- "https://era.dpi.qld.gov.au/id/eprint/15593/"
source_reference <- "Fox and Sumpter (2026), Stock assessment of Queensland east coast saddletail snapper"

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  rows <- rows[header]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
              quote = TRUE, na = "", append = TRUE, qmethod = "double")
}

assessment_rows_exist <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)

if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
    "QDAF:QLD_EC_SADDLETAIL_2026" %in% candidates$candidate_id ||
    assessment_rows_exist("database/assumptions.csv", assessment_id) ||
    assessment_rows_exist("database/outputs.csv", assessment_id)) {
  stop("The saddletail snapper source record is already present; refusing to duplicate it.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "Queensland DPI",
  authority_stock_id = "",
  scientific_name = "Lutjanus malabaricus",
  common_name = "Saddletail snapper",
  area = "Queensland east coast, Cape York to south of Brisbane",
  region = "Queensland, Australia",
  ocean = "Southwest Pacific",
  notes = "The 2026 report treats the Queensland east coast as one biological stock; it distinguishes the Gulf of Carpentaria and Western Australian stocks.",
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026,
  terminal_year = 2025,
  estimate_terminal_year = 2026,
  assessment_type = "assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.23.2",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = "",
  assessment_url = report,
  framework_url = "",
  data_url = record,
  model_url = "",
  repository_url = record,
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "Financial-year data through 2025 (July 2024-June 2025); the terminal biomass estimate is for the beginning of 2026. The public record contains the report PDF but no native model input files or composition arrays.",
  stringsAsFactors = FALSE
)

assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c("M", "M", "recruitment", "recruitment", "recruitment", "population", "population", "fishery", "observation_model", "observation_model", "index", "biology", "biology", "biology", "biology", "catch"),
  fleet = "",
  survey = "",
  sex = "combined",
  region = "Queensland east coast",
  season = "",
  setting = c("fixed_M_scenario_0.11", "fixed_M_scenario_0.14", "Beverton-Holt_steepness_0.65", "Beverton-Holt_steepness_0.75", "Beverton-Holt_steepness_0.85", "unfished_state", "sex_structure", "model_fleets", "age_data_likelihood", "length_data_weighting", "catch_rate_standard_error", "weight_length_relationship", "maturity_at_length", "fecundity", "growth", "depredation"),
  value = c("0.11 yr^-1", "0.14 yr^-1", "0.65", "0.75", "0.85", "Unfished in 1961", "Two sexes; 50% female at birth; no sex change", "Commercial; recreational and Traditional Owners combined; charter", "Conditional age-at-length; age-only compositions were not fit", "Two methods: catch-removal weighting and population-representative weighting", "0.2", "W_kg = exp(-10.5 + 2.83 * log(FL_cm))", "1 / (1 + exp((57.3 - FL_cm) / 3.72))", "Stock Synthesis fecundity option 1; a = 1, b = 0; eggs equivalent to spawning biomass", "Von Bertalanffy by sex; growth parameters estimated", "1% through 2009; then linear increase to 29% commercial and 58% other fleets by 2025"),
  source_reference = c(rep(paste(source_reference, "Table 2.3"), 5),
                       paste(source_reference, "Section 2.8.3"), paste(source_reference, "Section 2.8.3"), paste(source_reference, "Section 2.8.2"),
                       paste(source_reference, "Section 2.6"),
                       paste(source_reference, "Section 2.6.2"),
                       paste(source_reference, "Section 2.4"),
                       paste(source_reference, "Section 2.5.3; McPherson et al. (1992)"),
                       paste(source_reference, "Section 2.5.2; Hillcoat (2022)"),
                       paste(source_reference, "Section 2.5.2; Methot et al. (2024)"),
                       paste(source_reference, "Section 2.8.3"),
                       paste(source_reference, "Section 2.8.3")),
  notes = c("Each value was fixed within a model scenario; both values were included in the 12-scenario ensemble.",
            "Each value was fixed within a model scenario; both values were included in the 12-scenario ensemble.",
            "Steepness values were crossed with M and the two length-weighting methods.",
            "Steepness values were crossed with M and the two length-weighting methods.",
            "Steepness values were crossed with M and the two length-weighting methods.",
            "The unfished starting state is an assessment assumption.",
            "The model is annual and age structured.",
            "Charter selectivity mirrors recreational and Traditional Owners selectivity.",
            "The report states that age-only compositions were for visualization and were not used in fitting.",
            "Both weighting methods contributed equally to the final ensemble.",
            "The broad standard error down-weighted catch-rate indices because of hyperstability concerns.",
            "Fork length is measured in centimetres; the model uses fork length.",
            "L50 is 57.3 cm.",
            "The model therefore equates eggs with spawning biomass.",
            "A single growth curve per sex was used across the Queensland east coast.",
            "Other fleets means recreational, Traditional Owners, and charter."),
  stringsAsFactors = FALSE
)

outputs <- data.frame(
  assessment_id = assessment_id,
  type = c("biomass", "mortality"),
  measure = c("spawning_biomass_ratio", "fishing_pressure_ratio"),
  fleet = "",
  survey = "",
  sex = "combined",
  region = "Queensland east coast",
  season = "",
  year = c(2026, 2025),
  age = "",
  age_group = "",
  value = c(28, 3.85),
  se = "",
  lwr = c(19, 2.48),
  upr = c(42, 5.84),
  unit = c("percent of unfished spawning biomass", "ratio to F60"),
  source_type = "official_table",
  source_reference = c(paste(source_reference, "Table 3.2"), paste(source_reference, "Table 3.2")),
  notes = c("Median across the equally weighted 12-scenario MCMC ensemble; 95% credible interval. This is a ratio, not absolute biomass in tonnes.",
            "Median across the 12-scenario MCMC ensemble, inclusive of depredation; 95% credible interval."),
  scenario = "12-scenario MCMC ensemble",
  stringsAsFactors = FALSE
)

candidate <- data.frame(
  candidate_id = "QDAF:QLD_EC_SADDLETAIL_2026",
  candidate_unit_id = "australia_qld_east_coast_saddletail_snapper",
  organization = "Queensland DPI",
  official_stock_id = "Queensland east coast",
  scientific_name = "Lutjanus malabaricus",
  stock_name = "Saddletail snapper - Queensland east coast",
  assessment_area = "Queensland east coast",
  inventory_assessment_year = 2026,
  inventory_url = record,
  retrieved_on = "2026-11-05",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "partial",
  catch_age_evidence = "The model uses annual catches and conditional age-at-length, not catch-at-age. The report describes catch reconstruction but the public eRA record does not include the native catch or composition arrays.",
  survey_age_evidence = "Standardised commercial and recreational catch-rate indices are used; no age-specific abundance survey index is reported.",
  weights_evidence = "The assessment uses a fork-length weight relationship from McPherson et al. (1992); no numerical weight-at-age array is provided in the public report.",
  maturity_evidence = "The report gives a length-based maturity curve with L50 = 57.3 cm and slope 3.72.",
  mortality_evidence = "Natural mortality is fixed at 0.11 or 0.14 per year across scenarios.",
  timing_evidence = "Assessment years are financial years (July-June); within-year survey timing is not reported as a model input.",
  output_evidence = "The report gives terminal spawning-biomass ratio and fishing-pressure ratio with 95% credible intervals, but no machine-readable age-specific output surfaces.",
  detailed_source_url = report,
  review_date = "2026-11-05",
  decision_reason = "Current, detailed official assessment is verified and partial outputs/assumptions are imported. Age-data eligibility remains unresolved because the public record does not supply the numerical catch, length, conditional age-at-length, or catch-rate input arrays or native SS3 files.",
  notes = "The 2026 report models Queensland east coast saddletail snapper as a single biological stock. The official source review documents the partial import and source gaps.",
  stringsAsFactors = FALSE
)

append_csv("database/stocks.csv", stock)
append_csv("database/assessments.csv", assessment)
append_csv("database/assumptions.csv", assumptions)
append_csv("database/outputs.csv", outputs)
append_csv("discovery/candidates.csv", candidate)

cat("Imported a partial 2026 Queensland east coast saddletail snapper source record.\n")
