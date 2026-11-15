root <- "."
retrieved_on <- "2026-11-06"
source_dir <- "source_cache/mpi_sbw_sbw6i_2023"
source_files <- file.path(source_dir, c(
  "FAR-2024-37-SBW-6I-assessment.pdf",
  "FAR-2023-63-SBW-input-data-review.pdf",
  "FAR-2023-37-SBW-6I-acoustic-survey.pdf",
  "FAP-2025-SBW-plenary.pdf",
  "FAR-2025-44-SBW-6I-6B-catch-at-age.pdf",
  "FAR-2026-38-SBW-6I-6B-catch-at-age.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/25762/FAR-2024-37-Southern-blue-whiting-stock-assessment-Campbell-Island-Rise-to-2022-23.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25586/FAR-2023-63-Southern-Blue-Whiting-Fisheries-Characterisation-Up-To-2022-4422.pdf.ashx",
  "https://webstatic.niwa.co.nz/library/FAR2023-37.pdf",
  "https://fs.fish.govt.nz/Doc/26114/southern-blue-whiting-sbw-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26189/FAR-2025-44-Catch-at-age-southern-blue-whiting-2024-25-fishing-year.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26271/FAR-2026-38-Catch-at-age-in-SBW%206I-and-SBW6B-2025-26.pdf.ashx"
)
source_hashes <- c(
  "F746EE559E8D6403B7CB7DDB2292B4A977EF778E1C900ABE54338C1FEF588396",
  "4AA109FC8ECA83B9DC60294704A0E2E531278538D62ABC68789342D203CC3D77",
  "897A8F624AB001990DAB831D546343031C90A79913394EA9B397CE88CBC6B8E5",
  "41959A0C34B235C97BFD5DC70EF2AD2E4489761C8D1929F4AD1402C96E461CAA",
  "D3765074B8789F197274FCB077573D9A9C0301DB39B3F81C78D913180D5462DC",
  "294AA93630CAAFB2CFE71D445A06AD7832C1B9C8A8BAAFF74FA22A7484688C53"
)

if (!all(file.exists(source_files))) {
  stop("Cache the six reviewed Fisheries New Zealand and NIWA PDFs before screening SBW 6I.",
    call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached SBW 6I source differs from the reviewed file.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = "MPI:SBW6I",
  candidate_unit_id = "nz_southern_blue_whiting_sbw6i",
  organization = "Fisheries New Zealand",
  official_stock_id = "SBW 6I",
  scientific_name = "Micromesistius australis",
  stock_name = "Southern blue whiting, Campbell Island Rise",
  assessment_area = "Campbell Island Rise",
  inventory_assessment_year = 2024L,
  inventory_url = source_urls[4L],
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2024/37 reports sex-specific commercial proportions-at-age for 1979-2022,",
    "excluding 1987, ages 1-15+, as figures. Numeric vectors and bootstrap CVs are",
    "not tabulated in the reviewed reports. Table 2 supplies catch biomass, not",
    "catch numbers-at-age."
  ),
  survey_age_evidence = paste(
    "The production assessment uses immature and mature wide-area acoustic biomass",
    "indices in 14 survey years from 1993-2022. These are aggregate biomass indices,",
    "not age-specific abundance indices; the juvenile category was excluded."
  ),
  weights_evidence = paste(
    "The assessment uses empirical sex-specific length-at-age matrices and a fixed",
    "sex-specific length-weight relationship. The complete annual matrix is not",
    "tabulated in the reviewed public sources."
  ),
  maturity_evidence = paste(
    "The model estimates sex-specific logistic maturation parameters A50 and Ato95;",
    "no numerical annual age-specific maturity surface is published for the Base run."
  ),
  mortality_evidence = "Base case natural mortality is fixed at 0.20 per year; 0.15, 0.25, and estimated-M runs are sensitivities.",
  timing_evidence = paste(
    "The annual model has Nov-Aug and Sep-Oct time steps, with 90% and 10% of M",
    "respectively. Acoustic observations are treated as relative mid-season biomass;",
    "an exact fractional-year survey time is not reported."
  ),
  output_evidence = paste(
    "FAR 2024/37 Tables 8-10 report Base-run MPD and MCMC B0, 2022 SSB as a",
    "percentage of B0, and acoustic catchability with intervals. Annual SSB and",
    "exploitation/YCS trajectories are plotted; numerical age-specific N/F/M outputs",
    "were not found."
  ),
  detailed_source_url = source_urls[1L],
  review_date = retrieved_on,
  decision_reason = paste(
    "The 2025 Plenary identifies the 2024 publication as the latest full assessment",
    "and lists 2026 as the next assessment. Run-specific catch and acoustic index",
    "tables and summary outputs are recoverable, so the current unit will be retained",
    "as a partial record. Translation eligibility remains unresolved until numeric",
    "age-composition and complete biological inputs are available. FAR 2025/44 and",
    "FAR 2026/38 are later age-data reports, not updates to this assessment run."
  ),
  notes = paste(
    "SBW 6I (Campbell Island Rise) is one of four separately assessed southern blue",
    "whiting units. FAR 2026/38 reports 2025 age and length data but is not mixed into",
    "the 2022-23 production assessment. See source_reviews/mpi_sbw_sbw6i_2024.md."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (candidate$candidate_id %in% candidates$candidate_id ||
    candidate$candidate_unit_id %in% candidates$candidate_unit_id) {
  stop("MPI:SBW6I or its candidate unit is already registered; reconcile before adding.",
    call. = FALSE)
}
if (!identical(names(candidate), names(candidates))) {
  stop("Candidate columns do not match discovery/candidates.csv.", call. = FALSE)
}
write.table(candidate, candidate_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")

manifest <- data.frame(
  local_file = sub("^source_cache/", "", source_files),
  source_url = source_urls,
  retrieved_on = retrieved_on,
  sha256 = source_hashes,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(root, "provenance", "mpi_sbw_sbw6i_2024_sources.csv"),
  row.names = FALSE, na = "")

cat("Registered Campbell Island Rise southern blue whiting as a screened candidate.\n")
cat("Age-structured translation eligibility remains unresolved because numeric age compositions and complete biological surfaces are not publicly tabulated in the reviewed files.\n")
