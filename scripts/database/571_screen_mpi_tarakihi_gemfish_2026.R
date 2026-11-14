root <- "."
retrieved_on <- "2026-11-05"

source_files <- c(
  eastern = file.path(root, "source_cache/mpi_tarakihi_eastern_2026/FAR-2026-44-eastern-tarakihi-2026.pdf"),
  western = file.path(root, "source_cache/mpi_tarakihi_western_2026/FAR-2026-23-western-tarakihi-2026.pdf"),
  southern_gemfish = file.path(root, "source_cache/mpi_gemfish_ski3_ski7_2025/FAR-2026-39-southern-gemfish-SKI3-SKI7.pdf")
)
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/26277/FAR-2026-44-Stock-assessment-of-eastern-tarakihi-for-2026.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26247/FAR-2026-23-Stock-assessment-of-western-tarakihi-for-2026.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26272/FAR-2026-39-2025-stock-assessment-gemfish-in-SKI3-and-SKI7.pdf.ashx"
)
expected_hash <- c(
  "20F9D9B6430AD975C095F4F652B4C4AD9AF84D991651D0BE13C4C5F5827051CF",
  "9B7DCD75AF96DF146D1F12C838752D9904A331623C6609BED3B8B042BDD85698",
  "449E200CB92A548C42F61B464CBD334E5E21F95378B5515B6262658CF7986580"
)

stopifnot(all(file.exists(source_files)))
actual_hash <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) {
  stop("A cached Fisheries New Zealand report differs from the reviewed source.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = c("MPI:TAR:EASTERN", "MPI:TAR:WESTERN", "MPI:SKI3+SKI7"),
  candidate_unit_id = c("nz_tarakihi_eastern", "nz_tarakihi_western", "nz_gemfish_ski3_ski7"),
  organization = "Fisheries New Zealand",
  official_stock_id = c(
    "Eastern biological stock: TAR 3, TAR 2, eastern TAR 1 and TAR 7",
    "Western biological stock: TAR 8, western TAR 1 and TAR 7",
    "SKI 3 and SKI 7 biological stock complex"
  ),
  scientific_name = c("Nemadactylus macropterus", "Nemadactylus macropterus", "Rexea solandri"),
  stock_name = c("Eastern tarakihi", "Western tarakihi", "Southern gemfish"),
  assessment_area = c(
    "Eastern biological stock spanning TAR 3, TAR 2, and eastern portions of TAR 1 and TAR 7",
    "Western biological stock spanning TAR 8 and western portions of TAR 1 and TAR 7",
    "SKI 3 and SKI 7 biological stock complex"
  ),
  inventory_assessment_year = c(2026L, 2026L, 2025L),
  inventory_url = c(
    "https://fs.fish.govt.nz/Page.aspx?dk=26277&pk=113",
    "https://fs.fish.govt.nz/Page.aspx?dk=26247&pk=113",
    "https://fs.fish.govt.nz/Page.aspx?dk=26272&pk=113"
  ),
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = c("eligible", "eligible", "unresolved"),
  import_status = "not_started",
  catch_age_evidence = c(
    "FAR 2026/44 Appendix 7 Table A30 reports catch biomass by eight fisheries for 1932-2025. Tables A31-A37 report fishery and survey age-composition proportions; these are not catch numbers-at-age and must remain separate from catch biomass.",
    "FAR 2026/23 Appendix 4 Table A16 reports catch biomass by fishery for 1932-2025. Tables A17-A22 report commercial and survey age-composition proportions; these are not catch numbers-at-age.",
    "The assessment report lists observer age-composition data but gives sample counts, not fitted vectors. Three companion reports publish calculated numbers-at-age and CVs for 2020-21, 2021-22, and 2022-23; the assessment describes fitted observer age data for 2021-22 through 2023-24, so the mapping remains unresolved."
  ),
  survey_age_evidence = c(
    "The report provides survey biomass indices, age-2 abundance indices, and survey age compositions with source uncertainty; exact input tables and index series are to be imported from the report.",
    "The report provides WCSI and WCNI survey biomass indices, a TBGB age-1 abundance index, and survey age compositions with source uncertainty. TAR 8 CPUE was excluded from the final model because its trend conflicted with other abundance data.",
    "Table 9 reports 29 survey biomass indices and CVs. The report lists survey age compositions for four SKI 3 Tangaroa surveys in 1993-1996 but does not provide their numerical vectors."
  ),
  weights_evidence = c(
    "The report gives sex-specific growth and length-weight model parameters; a direct annual weight-at-age matrix was not identified.",
    "The report gives growth and length-weight model parameters; a direct annual weight-at-age matrix was not identified.",
    "The report gives sex-specific growth and length-weight parameter values, but no direct weight-at-age matrix; Table 14 identifies growth parameters as estimated but final estimates are not tabulated."
  ),
  maturity_evidence = c(
    "The report documents the base-case maturity schedule; numerical age-specific values and sex treatment are to be checked during import.",
    "The report documents the base-case maturity schedule; numerical age-specific values and sex treatment are to be checked during import.",
    "Table 13 states (0.1, 0.4, 0.8, 1.0) for ages 1-5 and both sexes, but gives four values for five ages; no age-specific vector is inferred."
  ),
  mortality_evidence = c(
    "Base assessment fixes natural mortality at 0.10 per year for both sexes.",
    "Base assessment fixes natural mortality at 0.10 per year for both sexes.",
    "The base model fixes natural mortality M at 0.25 per year for both sexes; sensitivities at 0.20 and 0.30 are reported."
  ),
  timing_evidence = c(
    "Annual model year is October-September with October-March and April-September periods and spawning at the start of period 2. No single fractional-year timing for each index was identified.",
    "Annual model year is October-September with October-March and April-September periods and spawning at the start of period 2. No single fractional-year timing for each index was identified.",
    "Fishing years are October-September, labelled by their ending calendar year, with one annual model step. Survey trip months/ranges are shown, but no within-year model fraction is specified."
  ),
  output_evidence = c(
    "Tables 17-19 report MCMC medians and intervals for unfished and terminal spawning biomass, biomass ratios, F reference values and projections. Annual numeric N-at-age, F-at-age, M-at-age and recruitment arrays were not located in the report.",
    "Tables 15-16 report MCMC medians and intervals for unfished and terminal spawning biomass, biomass ratios and F reference values. Annual numeric N-at-age, F-at-age, M-at-age and recruitment arrays were not located in the report.",
    "Table 17 reports MPD values for B0, 2025 SSB/B0, the U40%B0 proportional-removal reference, U2025, and U2025/U40%B0 across the base and sensitivities. MCMC did not achieve acceptable convergence; no uncertainty intervals or annual N/F/recruitment arrays are tabulated."
  ),
  detailed_source_url = source_urls,
  review_date = retrieved_on,
  decision_reason = c(
    "Eligible for source curation: the latest detailed 2026 report covers the current eastern biological unit and reports catch biomass, abundance indices, age compositions, biological assumptions and comparable assessment outputs.",
    "Eligible for source curation: the latest detailed 2026 report covers the current western biological unit and reports catch biomass, abundance indices, age compositions, biological assumptions and comparable assessment outputs.",
    "The latest detailed assessment is published for the current SKI 3+7 unit, and the selected survey-abundance growth model reports numeric catch, survey-index, and status tables. Keep eligibility unresolved because the age-composition year mapping, direct age weights, and maturity vector remain unverified. MCMC failure is an uncertainty limitation, not a reason by itself to exclude the source record."
  ),
  notes = c(
    "One eastern biological stock with three model regions and movement; do not create separate stocks for TAR 1, TAR 2, and TAR 3 regions.",
    "One western biological stock distinct from eastern tarakihi; do not create separate stock records for TAR 8, western TAR 1, and western TAR 7.",
    "The report says the survey-abundance growth model was accepted after CPUE alternatives were rejected. It reports recent observer age data years that differ from the fishing years in cited catch-age reports; mapping remains unresolved. MCMC uncertainty is unavailable."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
if (any(candidate$candidate_id %in% candidates$candidate_id) || anyDuplicated(candidate$candidate_id)) {
  stop("A screened candidate ID already exists; review identity before appending.", call. = FALSE)
}
write.table(candidate, candidate_path, sep = ",", quote = TRUE, row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", qmethod = "double")

manifest <- data.frame(
  local_file = sub("^\\./?", "", source_files),
  source_url = source_urls,
  retrieved_on = retrieved_on,
  sha256 = expected_hash,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(root, "provenance", "mpi_tarakihi_gemfish_2026_sources.csv"), row.names = FALSE, na = "")

sys.source(file.path(root, "scripts/database/195_summarize_discovery.R"), envir = new.env(parent = globalenv()))
sys.source(file.path(root, "scripts/database/196_summarize_inventory_units.R"), envir = new.env(parent = globalenv()))

cat("Screened two tarakihi biological stocks and recorded southern gemfish source gaps.\n")
