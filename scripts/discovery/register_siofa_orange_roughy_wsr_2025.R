candidate_path <- "discovery/candidates.csv"
candidate_id <- "SIOFA:ORY-2024-01:WSR"

if (!file.exists(candidate_path)) {
  stop("Run this script from the SAIO repository root.")
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
if (candidate_id %in% candidates$candidate_id) {
  stop("The SIOFA WSR candidate is already registered.")
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = "siofa_orange_roughy_wsr",
  organization = "SIOFA",
  official_stock_id = "WSR",
  scientific_name = "Hoplostethus atlanticus",
  stock_name = "Orange roughy",
  assessment_area = "Walter Shoal Ridge (WSR), SIOFA Statistical Area 2",
  inventory_assessment_year = "2025",
  inventory_url = "https://siofa.org/science/sc-works/ORY-2024-01",
  retrieved_on = "2026-11-06",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2025 WSR assessment fits total catch biomass and age-frequency data,",
    "not catch-at-age. The raw 2017 age data were unavailable; the 2019 and",
    "2020 scaled distributions are described but not fully tabulated."
  ),
  survey_age_evidence = paste(
    "Acoustic biomass indices are fitted by feature, but the public acoustic",
    "tables do not fully crosswalk to the feature names in the 2025 model."
  ),
  weights_evidence = paste(
    "Report 1 documents updated growth and length-weight analyses; the full",
    "run-matched numerical age-specific input arrays were not published."
  ),
  maturity_evidence = paste(
    "The WSR model estimates a logistic age-dependent maturity/selectivity",
    "curve shared between sexes; a numerical maturity-at-age input is not used."
  ),
  mortality_evidence = paste(
    "Combined-sex natural mortality is estimated with a normal prior; the R1.4",
    "prior mean is 0.045 per year with CV 0.1."
  ),
  timing_evidence = paste(
    "The assessment uses three annual time steps for recruitment, fishing, and",
    "ageing. Acoustic surveys occur in June-July; complete observation timing",
    "for all series is not reported."
  ),
  output_evidence = paste(
    "Report 2 Table 6 reports base-case R1.4 MCMC summaries for B0, 2023 SSB/B0,",
    "M, F40, BMSY, FMSY, catchability, and TACs; annual age-specific population",
    "output arrays are not numerically tabulated."
  ),
  detailed_source_url = "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-2-WSR-stock-assessment.pdf",
  review_date = "2026-11-06",
  decision_reason = paste(
    "A partial source record is supportable from run-specific scalar outputs.",
    "Eligibility for age-disaggregated input recovery remains unresolved because",
    "the assessment does not use catch-at-age and key numerical observation",
    "arrays are not fully recoverable from the public reports."
  ),
  notes = paste(
    "WSR is an assessment area, not a verified biological stock boundary.",
    "The 2025 project also models LWSR (which includes WSR) and SWIOR; these",
    "overlapping area models are not counted as additional stock units."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(identical(names(candidate), names(candidates)))
file_size <- file.info(candidate_path)$size
if (file_size > 0) {
  con <- file(candidate_path, open = "rb")
  seek(con, where = file_size - 1, origin = "start")
  last_byte <- readBin(con, what = "raw", n = 1L)
  close(con)
  if (!identical(last_byte, as.raw(10L))) {
    con <- file(candidate_path, open = "ab")
    writeBin(as.raw(c(13L, 10L)), con)
    close(con)
  }
}
write.table(candidate, candidate_path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double", na = "")

manifest <- data.frame(
  assessment_id = "siofa_orange_roughy_wsr_2025",
  cached_file = file.path("source_cache", "siofa_orange_roughy_2025", c(
    "Report-1-Biological-parameters-model-inputs.pdf",
    "Report-2-WSR-stock-assessment.pdf",
    "Report-3-LWSR-SWIOR-stock-assessment.pdf",
    "ORY-2023-02-Final-Report.pdf",
    "SC-11-28-SIOFA-ORY-2024-01-Final-Report.pdf",
    "WS2025-PAM3-03-Update-PAM-2024-03-progress.pdf"
  )),
  original_filename = c(
    "SIOFA-ORY-2024-01-Report-1-Biological-parameters-model-inputs.pdf",
    "SIOFA-ORY-2024-01-Report-2-WSR-stock-assessment.pdf",
    "SIOFA-ORY-2024-01-Report-3-LWSR-SWIOR-stock-assessment.pdf",
    "SC-10-41-SIOFA-ORY-2023-02-Final-Report.pdf",
    "SC-11-28-SIOFA-ORY-2024-01-Final-Report.pdf",
    "WS2025-PAM3-03-Update-PAM-2024-03-progress.pdf"
  ),
  source_url = c(
    "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-1-Biological-parameters-model-inputs.pdf",
    "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-2-WSR-stock-assessment.pdf",
    "https://siofa.org/sites/default/files/sc_works/SIOFA-ORY-2024-01-Report-3-LWSR-SWIOR-stock-assessment.pdf",
    "https://siofa.org/meeting-file/meeting-documents/10th_annual_meeting_of_the_siofa_scientific_committee_sc10/SC-10-41-SIOFA-ORY-2023-02-Final-Report.pdf",
    "https://siofa.org/system/files/meeting_documents/11th_annual_meeting_of_the_siofa_scientific_committee_sc11/SC-11-28-SIOFA-ORY-2024-01-Final-Report.pdf",
    "https://siofa.org/system/files/meeting_documents/third_scientific_committee_workshop_to_progress_the_siofa_precautionary_approach_and_management_projects_ws2025-pam3/WS2025-PAM3-03-Update-PAM-2024-03-progress.pdf"
  ),
  retrieval_date = "2026-11-06",
  verified_date = "2026-11-06",
  sha256 = c(
    "413EB49EF8D9C2B0E988A3A1514A7013A6204C2324B4284F4B5E8EBEBA9DB2B7",
    "C8E4694C6C97D0FB350715F8D2D17117EE0943B6D788A58F85A1352718B0E9D2",
    "A8F340B1964130DD71BD7BB7B9F1BA9C95359BAA0DAF48A6DB23863A9B3869CC",
    "211A786018D4EFAACE923ED6190A83484C979F25A0835A702794A90AC67AD796",
    "3EB447009F32930D9D186A3F7146EACAB8A4EDAAAC919F23A10A1A4B0AEC43AD",
    "3F08729C647EA60AC071A5871B5F39E37FF43B78A56885F03440A0FD1131E138"
  ),
  note = c(
    "Biological data characterization and model-input report.",
    "Detailed 2025 WSR assessment with data through 2023.",
    "Overlapping LWSR and separate SWIOR assessments; not pooled with WSR.",
    "Public survey-level acoustic biomass and CV estimates; feature crosswalk is incomplete.",
    "Final report for the ORY-2024-01 project, published after the 2025 assessment.",
    "Workshop report documents the interim catch limit based on mean 2015-2020 catch."
  ),
  stringsAsFactors = FALSE
)

if (any(!file.exists(manifest$cached_file))) {
  stop("A listed SIOFA source is missing from the local source cache.")
}
write.csv(manifest,
  "provenance/siofa_orange_roughy_2025_sources.csv",
  row.names = FALSE, na = "")
