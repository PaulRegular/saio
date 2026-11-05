root <- "."
register_path <- file.path(root, "discovery", "candidates.csv")
selection_path <- file.path(root, "discovery", "selected_batch_02_2026.csv")

candidate_id <- "MPI:LIN34"
candidate_unit_id <- "nz_ling_lin34"
assessment_url <- "https://fs.fish.govt.nz/Doc/26148/FAR-2025-48-Stock-assessment-of-Chatham-Rise-ling-2025.pdf.ashx"
input_url <- "https://fs.fish.govt.nz/Doc/26147/FAR-2025-47-Descriptive-analysis-LIN34-to-2023-24-and-inputs-for-2025-stock-assessment.pdf.ashx"
plenary_url <- "https://fs.fish.govt.nz/Doc/26063/ling-fisheries-assessment-plenary-may-2025-volume-2.pdf.ashx"

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "LIN 3&4",
  scientific_name = "Genypterus blacodes",
  stock_name = "Chatham Rise ling",
  assessment_area = "Chatham Rise (Fishstocks LIN 3 and LIN 4), New Zealand EEZ",
  inventory_assessment_year = 2025L,
  inventory_url = plenary_url,
  retrieved_on = "2026-11-05",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2025 model uses separate trawl, longline, and pot catch histories and sexed fishery age-composition data; pot age data were unavailable.",
    "FAR 2025/47 provides the detailed catch and age inputs. Preserve the native catch and composition records; any catch-numbers-at-age reconstruction must use documented proportions and age-specific weights."
  ),
  survey_age_evidence = paste(
    "The base model uses January Tangaroa survey biomass and sexed survey proportions-at-age for 1992–2014, 2016, 2018, 2020, 2022, and 2024.",
    "The model partition is two sexes and ages 3–25, with age 25 as the plus group."
  ),
  weights_evidence = paste(
    "Sex-specific growth and length-weight relationships are documented for LIN 3&4.",
    "Check the detailed input appendix for explicit weight-at-age values before importing; do not replace source parameters with a derived surface without documenting it."
  ),
  maturity_evidence = paste(
    "The detailed assessment documents the base maturity treatment and a separate sensitivity using an age-7 maturity ogive for both sexes.",
    "Keep the sensitivity distinct from the accepted base run."
  ),
  mortality_evidence = "Natural mortality is estimated as sex-specific and constant at age, parameterized by average M and the male–female difference.",
  timing_evidence = paste(
    "The assessment uses calendar years and a January–December cycle.",
    "The January summer survey is placed at 0.2 of the year; observation timing and mortality fractions are documented in the model cycle."
  ),
  output_evidence = paste(
    "The base-model table reports Bayesian medians and 95% credible intervals for B0, B2025, and B2025/B0.",
    "Biomass and exploitation trajectories are plotted, but annual numerical N-at-age and F-at-age surfaces are not tabulated."
  ),
  detailed_source_url = paste(assessment_url, input_url, sep = "; "),
  review_date = "2026-11-05",
  decision_reason = paste(
    "Eligible for source curation: the latest detailed 2025 Casal2 assessment and companion input report document fishery catches, sexed age compositions, a trawl survey biomass and age-composition series, biology, mortality, timing, and comparable Bayesian biomass outputs.",
    "Source records will remain in their reported forms; any age-specific catch reconstruction will be documented and will not be treated as a directly reported series."
  ),
  notes = paste(
    "LIN 3&4 is the Chatham Rise management unit and is distinct from other New Zealand ling units and ICES ling stocks.",
    "Longline and scampi CPUE were explored but were not used in the 2025 base model. The base run and the alternative age-7 maturity sensitivity must not be mixed."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (anyDuplicated(register$candidate_id)) stop("Candidate IDs are not unique.", call. = FALSE)
if (!identical(names(candidate), names(register))) stop("Candidate row does not match the register schema.", call. = FALSE)
existing <- which(register$candidate_id == candidate_id)
if (length(existing)) {
  if (length(existing) != 1L ||
    register$candidate_unit_id[existing] != candidate_unit_id ||
    register$official_stock_id[existing] != candidate$official_stock_id) {
    stop("Existing ling candidate does not match the reviewed stock unit.", call. = FALSE)
  }
} else {
  write.table(candidate, register_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
    append = TRUE, eol = "\n")
}

selection <- data.frame(
  priority = 2L,
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = candidate$organization,
  official_stock_id = candidate$official_stock_id,
  scientific_name = candidate$scientific_name,
  stock_name = candidate$stock_name,
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = candidate$inventory_assessment_year,
  detailed_source_url = paste(plenary_url, input_url, assessment_url, sep = "; "),
  review_date = candidate$review_date,
  selection_basis = paste(
    "The latest 2025 production run has a companion input report with fishery, age-composition, survey, biological, and timing details, plus tabulated Bayesian biomass outputs.",
    "Selected as a source-ready Southwest Pacific case after Hoki; assessment fitting was not used to make this selection."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

selected <- read.csv(selection_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (!identical(names(selection), names(selected))) stop("Selection row does not match the selected-batch schema.", call. = FALSE)
if (anyDuplicated(selected$candidate_id)) stop("Selected candidate IDs are not unique.", call. = FALSE)
existing <- which(selected$candidate_id == candidate_id)
if (length(existing)) {
  if (length(existing) != 1L || selected$official_stock_id[existing] != selection$official_stock_id) {
    stop("Existing selected ling row does not match the reviewed stock unit.", call. = FALSE)
  }
} else {
  selection$priority <- max(selected$priority, na.rm = TRUE) + 1L
  write.table(selection, selection_path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double",
    append = TRUE, eol = "\n")
}

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- read.csv(selection_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (sum(register$candidate_id == candidate_id) != 1L ||
  sum(selected$candidate_id == candidate_id) != 1L) {
  stop("Ling source-screen record was not written exactly once.", call. = FALSE)
}
cat("Screened and selected MPI LIN 3&4 for source curation.\n")
