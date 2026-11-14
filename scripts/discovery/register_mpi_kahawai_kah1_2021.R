candidate_path <- "discovery/candidates.csv"
selected_path <- "discovery/selected_batch_04_2026.csv"
manifest_path <- "provenance/mpi_kahawai_kah1_2021_sources.csv"
source_pdf <- "source_cache/mpi_kahawai_kah1_2021/FAR2022-54.pdf"

candidate <- data.frame(
  candidate_id = "MPI:KAH1",
  candidate_unit_id = "nz_kahawai_kah1",
  organization = "Fisheries New Zealand",
  official_stock_id = "KAH 1",
  scientific_name = "Arripis trutta",
  stock_name = "Kahawai",
  assessment_area = "KAH 1, off the northeast North Island",
  inventory_assessment_year = "2021",
  inventory_url = "https://www.mpi.govt.nz/dmsdocument/71944/direct",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2022/54 Appendix 4 contains annual model catch biomass for nine fleets",
    "and age-composition proportions with effective sample sizes for seven fleets.",
    "The age compositions are sample observations, not catch numbers-at-age."
  ),
  survey_age_evidence = paste(
    "The assessment uses three regional recreational CPUE indices and one aerial",
    "SPUE index, all aggregate rather than age-specific abundance indices."
  ),
  weights_evidence = paste(
    "Appendix 4 specifies von Bertalanffy size-at-age and a length-weight",
    "relationship; the model calculates weights internally rather than supplying",
    "a tabulated weight-at-age vector."
  ),
  maturity_evidence = "Appendix 4 specifies knife-edge maturity at age 4.",
  mortality_evidence = "Natural mortality is fixed at 0.22 per year in the base assessment; 0.20 and 0.24 are sensitivity runs.",
  timing_evidence = "The four relative-abundance series use proportion_mortality = 0.5 in the annual model cycle.",
  output_evidence = paste(
    "FAR 2022/54 Table 9 reports base and natural-mortality sensitivity medians",
    "and 95% credible intervals for unfished and 2020 spawning biomass and status",
    "ratios. Annual numerical N-at-age, F-at-age, M-at-age and recruitment outputs",
    "are not tabulated."
  ),
  detailed_source_url = "https://www.mpi.govt.nz/dmsdocument/54118/direct",
  review_date = "2026-11-06",
  decision_reason = paste(
    "Eligible for source curation: the latest detailed production assessment",
    "publishes its CASAL input appendix with age-composition observations, catch",
    "histories, aggregate abundance indices, biological equations and summary",
    "outputs. Fisheries New Zealand's 2026-27 research plan states that the last",
    "assessment was conducted in 2021 and a new assessment is planned for 2029."
  ),
  notes = paste(
    "One current stock unit; no Charbonneau-Keith match identified. The age",
    "composition likelihoods are not catch numbers-at-age and there is no",
    "age-specific survey index. The 2025 Plenary gives a later status summary;",
    "the canonical run-level record will preserve values from the detailed 2021",
    "assessment and document that distinction."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

candidates <- read.csv(
  candidate_path, stringsAsFactors = FALSE, colClasses = "character",
  check.names = FALSE
)
if (candidate$candidate_id %in% candidates$candidate_id ||
    candidate$candidate_unit_id %in% candidates$candidate_unit_id) {
  stop("KAH 1 is already registered.")
}
if (!identical(names(candidate), names(candidates))) {
  stop("KAH 1 candidate fields do not match the register schema.")
}
write.table(
  candidate, candidate_path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = ""
)

selected <- data.frame(
  priority = 1L,
  candidate_id = "MPI:KAH1",
  candidate_unit_id = "nz_kahawai_kah1",
  organization = "Fisheries New Zealand",
  official_stock_id = "KAH 1",
  scientific_name = "Arripis trutta",
  stock_name = "Kahawai",
  assessment_area = "KAH 1, off the northeast North Island",
  inventory_assessment_year = "2021",
  detailed_source_url = "https://www.mpi.govt.nz/dmsdocument/54118/direct",
  review_date = "2026-11-06",
  selection_basis = paste(
    "A source-ready New Zealand case for the next global expansion wave: the",
    "latest detailed assessment includes CASAL input files and summary outputs.",
    "Age-composition samples are proportions with effective sample sizes; the",
    "assessment does not publish catch numbers-at-age or age-specific survey indices."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (!file.exists(selected_path)) {
  write.csv(selected, selected_path, row.names = FALSE, na = "")
} else {
  stop("The KAH 1 selection file already exists.")
}

if (!file.exists(source_pdf)) {
  stop("Download the official FAR 2022/54 PDF to the ignored source cache first.")
}
actual_hash <- toupper(unname(tools::sha256sum(source_pdf)))
if (!identical(actual_hash, "D3A6DC8BB710AC13CD520BB7D188A15850302C9EB334DA3AC59C0F575EE02DEA")) {
  stop("The cached KAH 1 report differs from the reviewed source.")
}
manifest <- data.frame(
  local_file = source_pdf,
  source_url = "https://webstatic.niwa.co.nz/library/FAR2022-54.pdf",
  retrieved_on = "2026-11-06",
  sha256 = "D3A6DC8BB710AC13CD520BB7D188A15850302C9EB334DA3AC59C0F575EE02DEA",
  stringsAsFactors = FALSE
)
write.csv(manifest, manifest_path, row.names = FALSE, na = "")
cat("Registered Fisheries New Zealand KAH 1 for source curation.\n")
