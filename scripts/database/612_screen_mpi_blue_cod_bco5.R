root <- "."
retrieved_on <- "2026-11-09"
source_dir <- file.path(root, "source_cache", "mpi_bco5")
source_files <- file.path(source_dir, c(
  "FAR-2020-14.pdf",
  "FAR-2024-03.pdf",
  "FAR-2024-55.pdf",
  "FAR-2024-56.pdf",
  "Plenary-2026-BCO5.pdf"
))
source_urls <- c(
  "https://www.mpi.govt.nz/dmsdocument/41406/direct",
  "https://www.mpi.govt.nz/dmsdocument/60796/direct",
  "https://www.mpi.govt.nz/dmsdocument/64962/direct",
  "https://www.mpi.govt.nz/dmsdocument/64965/direct",
  "https://www.mpi.govt.nz/dmsdocument/72170/direct"
)
record_urls <- c(
  "https://www.mpi.govt.nz/dmsdocument/41406-FAR-202014-Stock-assessment-of-blue-cod-Parapercis-colias-in-BCO-5-using-data-to-2019/sitemap",
  "https://www.mpi.govt.nz/dmsdocument/60796-FAR-202403-Relative-abundance-size-and-age-structure-and-stock-status-of-blue-cod-in-Foveaux-Strait-in-2023/sitemap",
  "https://www.mpi.govt.nz/dmsdocument/64962/sitemap",
  "https://www.mpi.govt.nz/dmsdocument/64965-FAR-202456-Stock-assessment-of-blue-cod-Parapercis-colias-in-BCO-5-using-data-to-2023/sitemap",
  "https://www.mpi.govt.nz/dmsdocument/72170-Fisheries-Assessment-Plenary-May-2026-Volume-1-BLUE-COD-BCO-5"
)
source_hashes <- c(
  "C817AFD295C7E01FA632C72CEFE90F862788D0EF290CB447327BE4AD14E3CE3D",
  "70AE5141A71906B30D581C9EB4A4F8F2311E20ECF97DB06B91F857290FE108A8",
  "9DF02AB3B7690AC336530541A1846D855834FD4A8FD17182E0449A9B02787B1D",
  "2C7BC56FCA4BABD7429C6848AEC2FE483209ADE795BFB9ADBB35F0EA268A1815",
  "7601087432B7ECFE1710989D26259AEF73DE41DC26FEE6F61FA1337F0F578A39"
)

if (!all(file.exists(source_files))) {
  stop("Cache the five reviewed Fisheries New Zealand reports before screening BCO 5.", call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached BCO 5 source differs from the reviewed file.", call. = FALSE)
}
candidate <- data.frame(
  candidate_id = "MPI:BCO5",
  candidate_unit_id = "mpi_blue_cod_bco5",
  organization = "Fisheries New Zealand",
  official_stock_id = "BCO 5",
  scientific_name = "Parapercis colias",
  stock_name = "Blue cod - BCO 5",
  assessment_area = "BCO 5; Statistical Areas 025, 027, and 030 in the 2019 assessment",
  inventory_assessment_year = 2019L,
  inventory_url = "https://www.mpi.govt.nz/fishing-aquaculture/fisheries-management/fish-stock-status/plenary-reports-for-individual-species",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2020/14 Appendix 1 reports reconstructed catches by fishery and area;",
    "Appendix 3 Tables 3.5-3.8 report commercial age-frequency compositions by",
    "area. These compositions are not direct catch numbers-at-age. The later",
    "2022-23 catch-age samples belong to the separate 2024 attempt."
  ),
  survey_age_evidence = paste(
    "FAR 2020/14 Appendix 2 reports pot-survey age samples for 2010, 2014, and",
    "2018; survey abundance indices are fitted for Statistical Area 025 only.",
    "The 2023 Foveaux survey is a later observation and is not part of the 2019 run."
  ),
  weights_evidence = paste(
    "The 2019 model derives weights from modeled length-at-age and a published",
    "length-weight relationship; a complete annual numerical weight-at-age surface",
    "is not tabulated in the reviewed sources."
  ),
  maturity_evidence = paste(
    "The 2019 report describes a shared logistic maturity ogive (A50 = 4.1,",
    "Ato95 = 2.47) informed by age and gonad samples; raw maturity observations",
    "are shown graphically, not as an annual maturity-at-age series."
  ),
  mortality_evidence = "The 2019 model fixes natural mortality at 0.17 per year.",
  timing_evidence = paste(
    "The 2019 model uses one annual time step and assumes year-round fisheries;",
    "spawning occurs after 93% of annual natural mortality. Exact within-year",
    "survey timing is not reported."
  ),
  output_evidence = paste(
    "FAR 2020/14 reports MPD B0 = 20,682 t and Bcurrent = 32.4% B0; its MCMC",
    "Bcurrent median is 35.7% B0 (95% credible interval 31-41%), rounded to 36%",
    "in the 2026 Plenary. Annual SSB and recruitment trajectories are plotted;",
    "numeric annual N-at-age and F-at-age series were not found."
  ),
  detailed_source_url = paste(record_urls[c(1L, 4L, 5L)], collapse = "; "),
  review_date = retrieved_on,
  decision_reason = paste(
    "Select the current BCO 5 unit for partial source curation: the 2019 age-based",
    "assessment remains the run used for advice and publishes age-frequency inputs",
    "and comparable aggregate biomass outputs. The 2024 assessment attempt was",
    "rejected and must remain separate. Numerical output coverage and some input",
    "surfaces are partial."
  ),
  notes = paste(
    "Candidate is the management unit, not three separate stocks. The 2019 models",
    "cover areas 025, 027, and 030; the rejected 2024 run groups 027+029.",
    "See source_reviews/mpi_blue_cod_bco5.md and selected_batch_21_2026.csv."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv(file.path(root, "database", "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review_path <- file.path(root, "source_reviews", "mpi_blue_cod_bco5.md")
review_text <- paste(readLines(review_path, warn = FALSE), collapse = " ")
required_review <- c("2019 age-based assessment", "2024 attempt", "35.7%", "not a complete direct catch-numbers-at-age series")
if (!all(vapply(required_review, grepl, logical(1L), x = review_text, fixed = TRUE))) {
  stop("The BCO 5 source review does not support the screening fields.", call. = FALSE)
}
if (candidate$candidate_id %in% candidates$candidate_id ||
    candidate$candidate_unit_id %in% candidates$candidate_unit_id) {
  stop("MPI:BCO5 or its candidate unit is already registered; reconcile before adding.", call. = FALSE)
}
if (any(stocks$authority_stock_id == "BCO 5", na.rm = TRUE)) {
  stop("BCO 5 already exists in the canonical stock table; reconcile before adding.", call. = FALSE)
}
if (!identical(names(candidate), names(candidates))) {
  stop("Candidate columns do not match discovery/candidates.csv.", call. = FALSE)
}

selection_path <- file.path(root, "discovery", "selected_batch_21_2026.csv")
if (file.exists(selection_path)) stop("Selected batch 21 already exists; review before rerunning.", call. = FALSE)
selection <- data.frame(
  priority = 1L,
  candidate_id = candidate$candidate_id,
  candidate_unit_id = candidate$candidate_unit_id,
  organization = candidate$organization,
  official_stock_id = candidate$official_stock_id,
  scientific_name = candidate$scientific_name,
  stock_name = candidate$stock_name,
  assessment_area = candidate$assessment_area,
  inventory_assessment_year = candidate$inventory_assessment_year,
  detailed_source_url = candidate$detailed_source_url,
  review_date = candidate$review_date,
  selection_basis = paste(
    "The 2019 age-based assessment remains the BCO 5 advice basis in the May 2026",
    "Plenary. It provides age-frequency input tables, model assumptions, and",
    "aggregate biomass outputs. The 2024 attempt was rejected and is kept separate."
  ),
  curation_status = "selected_for_source_curation",
  stringsAsFactors = FALSE
)
manifest <- data.frame(
  local_file = paste0("source_cache/mpi_bco5/", basename(source_files)),
  source_url = source_urls,
  record_url = record_urls,
  retrieved_on = retrieved_on,
  sha256 = source_hashes,
  bytes = file.info(source_files)$size,
  represented_assessment = c(
    "bco5_2019_assessment_used_for_advice",
    "bco5_2024_assessment_context",
    "bco5_2024_assessment_context",
    "bco5_2024_rejected_assessment_attempt",
    "bco5_2026_advice_status"
  ),
  status = "cached",
  notes = c(
    "Detailed age-based Casal2 assessment used for BCO 5 advice.",
    "Foveaux Strait 2023 potting survey; separate from the 2019 run.",
    "Commercial catch age samples for 2021-22 and 2022-23; separate from the 2019 run.",
    "Assessment using data to 2022-23; Area 025 result rejected by Plenary.",
    "May 2026 Plenary chapter; confirms advice status remains based on the 2019 run."
  ),
  stringsAsFactors = FALSE
)
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
cat("Blue cod BCO 5 source screen\n")
cat("  cached sources: ", length(source_files), "\n", sep = "")
cat("  selected unit: ", candidate$candidate_unit_id, "\n", sep = "")
cat("  assessment used for advice: 2019; separate 2024 rejected attempt\n")
if (!write_mode) {
  cat("Dry run only. Add --write to add the candidate and selected-batch rows.\n")
} else {
  write.table(candidate, candidate_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  write.csv(manifest, file.path(root, "provenance", "mpi_blue_cod_bco5_sources.csv"),
    row.names = FALSE, na = "")
  write.csv(selection, selection_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Registered BCO 5 as a screened candidate selected for source curation.\n")
}
