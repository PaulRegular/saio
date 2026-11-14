candidate_id <- "MPI:ORH3B"
candidate_unit_id <- "mpi_orh3b_chatham_rise"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
retrieved_on <- "2026-11-06"
source_dir <- "source_cache/mpi_orh3b_2025"
source_files <- file.path(source_dir, c(
  "FAR-2025-46-Stock-assessment-of-Chatham-Rise-orange-roughy-in-2025.pdf",
  "FAR-2025-18-Additional-analyses-for-orange-roughy-ORH3B.pdf",
  "FAR-2025-23-Acoustic-biomass-surveys-ORH3B-2022.pdf",
  "FSR-2026-02-Independent-International-Review-of-Orange-Roughy-Stock-Assessment-Modelling-2026.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/26145/FAR-2025-46-Stock-assessment-of-Chatham-Rise-orange-roughy-in-2025.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25870/FAR-2025-18-Additional-analyses-for-orange-roughy-ORH3B.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25881/FAR-2025-23-Acoustic-biomass-surveys-ORH3B-NWCR-and-ORH3B-ESCR-June-July-2022.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26256/FSR-2026-02-Independent-International-Review-of-Orange-Roughy-Stock-Assessment-Modelling-2026.pdf.ashx"
)
source_hashes <- c(
  "E0F81AF259FEDF4E3C35F84500CC32D83B76C499DCF21E90BE722AFA3E88D458",
  "3E9787D292FE99A3A4A0A071C1F32196E25798224E2AC9B3A58264FF4C2283BC",
  "B3E3DF10C138548D2164073BB2F613F1A1CAA0235050BD36435EB4519AB6BCC1",
  "B44BA102B9284DD6C18E2C7B5DAE60424C03BCB7EFF48A70D561AAC1C7240B0F"
)

if (!all(file.exists(source_files))) {
  stop("Cache the four reviewed orange roughy reports before registering ORH 3B.",
    call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached ORH 3B source differs from the reviewed version.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "Fisheries New Zealand",
  official_stock_id = "ORH 3B",
  scientific_name = "Hoplostethus atlanticus",
  stock_name = "Chatham Rise orange roughy",
  assessment_area = "ORH 3B, Chatham Rise components: East & South Chatham Rise and Northwest Chatham Rise",
  inventory_assessment_year = 2025L,
  inventory_url = "https://fs.fish.govt.nz/Page.aspx?dk=26145&pk=113",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2025/46 Appendices 3-4 provide annual catch biomass by modeled fishing",
    "area and sampled age-frequency proportions from target fishing in three",
    "spawning areas. The model fits biomass catches and age compositions separately;",
    "it does not publish catch numbers-at-age."
  ),
  survey_age_evidence = paste(
    "ESCR age-frequency samples cover the Old Spawning Plume (1984, 2003, 2012,",
    "2013, 2016, 2022, 2024), Rekohu (2012-2024), and Mt Muck/Crack (2013-2024),",
    "ages 18-100+. These are included only in the acoustic-plus-age-frequency",
    "alternatives. NWCR final runs use acoustic biomass only."
  ),
  weights_evidence = paste(
    "The CASAL2 appendices specify von Bertalanffy growth and a length-weight",
    "equation; a directly supplied weight-at-age table was not located."
  ),
  maturity_evidence = paste(
    "The model uses a logistic maturity/selectivity ogive with A50 28.51 and",
    "Ato95 4.56; a standalone numeric maturity-at-age table was not located."
  ),
  mortality_evidence = paste(
    "The ESCR final models fix M at 0.045 per year. NWCR final models estimate",
    "M with a normal prior centred at 0.045 and CV 0.333."
  ),
  timing_evidence = paste(
    "The model uses fishing years ending and a single annual step. Acoustic",
    "observations are placed at 0.75 of the model year."
  ),
  output_evidence = paste(
    "FAR 2025/46 Tables 7 and 10 report MCMC B0, 2025 SSB and status with",
    "95% credible intervals for the final ESCR and NWCR scenarios. Numerical",
    "annual N/F/M-at-age and SSB trajectories were not located."
  ),
  detailed_source_url = paste(source_urls, collapse = "; "),
  review_date = retrieved_on,
  decision_reason = paste(
    "The 2025 production assessment is the latest detailed assessment located;",
    "the 2026 orange roughy review is methodological and does not replace it.",
    "The source appendix provides model catch-biomass histories, selected sampled",
    "age-frequency inputs, acoustic biomass, biology and scalar outputs. The model",
    "fits totals and compositions separately rather than using catch numbers-at-age."
  ),
  notes = paste(
    "ORH 3B is the official management unit. This assessment covers the East &",
    "South and Northwest Chatham Rise components; retain them as regions rather",
    "than counting them as separate stock units. See",
    "source_reviews/mpi_orh3b_chatham_rise_2025.md."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

candidate_path <- "discovery/candidates.csv"
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (candidate_id %in% candidates$candidate_id ||
    candidate_unit_id %in% candidates$candidate_unit_id) {
  stop("ORH 3B or its candidate unit is already registered; reconcile before adding.",
    call. = FALSE)
}
candidate <- candidate[names(candidates)]

cat("Screened candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Decision:", candidate$eligibility, "; import status:", candidate$import_status, "\n")

if (write_mode) {
  write.table(candidate, candidate_path, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, quote = TRUE, qmethod = "double",
    na = "", eol = "\n")
  manifest <- data.frame(
    local_file = sub("^source_cache/", "", source_files),
    source_url = source_urls,
    retrieved_on = retrieved_on,
    sha256 = source_hashes,
    stringsAsFactors = FALSE
  )
  write.csv(manifest, "provenance/mpi_orh3b_2025_sources.csv",
    row.names = FALSE, na = "")
  cat("Added ORH 3B to the discovery register and wrote its source manifest.\n")
}
