candidate_path <- "discovery/candidates.csv"
manifest_path <- "provenance/mpi_trevally_tre7_2026_sources.csv"

candidate_id <- "MPI:TRE7"
candidate_unit_id <- "mpi_trevally_tre7"

if (!file.exists(candidate_path)) {
  stop("Run this script from the SAIO repository root.")
}

candidates <- read.csv(
  candidate_path, stringsAsFactors = FALSE, colClasses = "character",
  check.names = FALSE
)

if (candidate_id %in% candidates[["candidate_id"]] ||
    candidate_unit_id %in% candidates[["candidate_unit_id"]]) {
  stop("The TRE 7 candidate is already registered.")
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "TRE 7",
  scientific_name = "Pseudocaranx dentex",
  stock_name = "Trevally",
  assessment_area = "TRE 7; west coast North Island and north and west South Island",
  inventory_assessment_year = "2026",
  inventory_url = "https://fs.fish.govt.nz/Page.aspx?dk=26266&pk=113",
  retrieved_on = "2026-11-05",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2026/34 Table A13 reports annual commercial catch histories for 1975-2025;",
    "Tables 3 and 6 identify fitted age-composition years. FAR 2025/38 provides",
    "recent age data for 2022-23 and 2023-24; older likelihood vectors require",
    "the cited historical sampling reports."
  ),
  survey_age_evidence = paste(
    "FAR 2026/34 Table 4 reports Kaharoa biomass and one-year-old abundance",
    "indices with CVs; the fitted age compositions are from commercial fisheries."
  ),
  weights_evidence = paste(
    "FAR 2026/34 Table 5 reports combined-sex growth and length-weight parameters;",
    "FAR 2025/38 reports recent empirical mean weight-at-age. Earlier annual age",
    "weight vectors remain to be verified."
  ),
  maturity_evidence = "FAR 2026/34 Table 5 specifies maturity by age: ages 1-3 = 0, age 4 = 0.5, ages 5+ = 1.",
  mortality_evidence = "Natural mortality is fixed at 0.10 per year in the base model.",
  timing_evidence = paste(
    "Kaharoa surveys occur in October-November and Table 4 maps survey calendar",
    "years to model years; the numerical within-year observation timing is not stated."
  ),
  output_evidence = paste(
    "FAR 2026/34 Tables 7-8 report MCMC medians and 95% intervals for spawning",
    "biomass and F-reference metrics. Annual numerical N/F-at-age arrays are not tabulated."
  ),
  detailed_source_url = "https://fs.fish.govt.nz/Doc/26266/FAR-2026-34-Stock-assessment-of-trevally-in-TRE7-for-2026.pdf.ashx",
  review_date = "2026-11-05",
  decision_reason = paste(
    "Eligible for source curation: the latest detailed report provides run-specific",
    "catch, CPUE, trawl-survey, age-composition, biological and summary output data.",
    "The published base model covers only the northern sub-stock; the TwoRegion",
    "full-TRE 7 run is a separate sensitivity."
  ),
  notes = paste(
    "The base Stock Synthesis assessment covers the northern NMB and KMNTB areas,",
    "while the TwoRegion sensitivity includes the full TRE 7 area. Recent age",
    "composition vectors are in FAR 2025/38; earlier vectors and full annual",
    "population output arrays remain to be recovered."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(identical(names(candidate), names(candidates)))
write.table(
  candidate, candidate_path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double",
  na = ""
)

manifest <- data.frame(
  local_file = c(
    "source_cache/mpi_trevally_tre7_2026/FAR-2026-34-TRE7-assessment.pdf",
    "source_cache/mpi_trevally_tre7_2026/FAR-2025-38-TRE7-age-compositions.pdf"
  ),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/26266/FAR-2026-34-Stock-assessment-of-trevally-in-TRE7-for-2026.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26130/FAR-2025-38-Length-and-age-composition-TRE7-2022-23-and-2023-24.pdf.ashx"
  ),
  retrieved_on = "2026-11-05",
  sha256 = c(
    "DF854B9C6AB2E0E20581E4F164EBC58BF8C9E438ACB4772C3D5943BB1340CD8B",
    "2A0515A5E762F9DACC41347C6ABD799FA3894D5F44E5BC1480BC3E216968BA57"
  ),
  stringsAsFactors = FALSE
)

if (any(!file.exists(manifest$local_file))) {
  stop("A TRE 7 source listed in the manifest is missing from the local cache.")
}

write.csv(manifest, manifest_path, row.names = FALSE, na = "")
