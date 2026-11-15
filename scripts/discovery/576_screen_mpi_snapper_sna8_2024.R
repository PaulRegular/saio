root <- "."
retrieved_on <- "2026-11-05"
source_dir <- "source_cache/mpi_snapper_sna8_2024"
source_files <- file.path(source_dir, c(
  "FAR-2024-49-SNA8-assessment.pdf",
  "FAR-2024-50-SNA8-age-composition.pdf",
  "FAP-2025-SNA8-plenary.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/25777/FAR-2024-49-Stock-assessment-of-snapper-in-SNA8-for-2024.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25778/FAR-2024-50-Length-and-age-composition-of-commercial-snapper-landings-in-SNA8-2022-23.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26113/snapper-sna-8-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx"
)
expected_hash <- c(
  "DA831791A82867CCA0B04833859A26CE63160E08D5F8D4039C0023D35022216D",
  "9E5313471B8FA1957BF679EEEA6EE85890F9BB26FEAA19495535A10B43C12580",
  "3D6A2FAAFA10287472DB78A77949584FBD0F936D24802F56E4428FF5CE27022B"
)

if (!all(file.exists(source_files))) {
  stop("Cache the three reviewed Fisheries New Zealand PDFs before screening SNA 8.", call. = FALSE)
}
actual_hash <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) {
  stop("A cached SNA 8 source differs from the reviewed file.", call. = FALSE)
}

candidate <- data.frame(
  candidate_id = "MPI:SNA8",
  candidate_unit_id = "nz_snapper_sna8",
  organization = "Fisheries New Zealand",
  official_stock_id = "SNA 8",
  scientific_name = "Chrysophrys auratus",
  stock_name = "Snapper SNA 8",
  assessment_area = "SNA 8, west coast of New Zealand North Island",
  inventory_assessment_year = 2024L,
  inventory_url = source_urls[3L],
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "eligible",
  import_status = "not_started",
  catch_age_evidence = paste(
    "FAR 2024/49 Tables 3 and 4 summarize 27 single-trawl and 18 pair-trawl",
    "age-composition observations; Appendices A6 and A7 report observed",
    "proportions-at-age and CVs. The report also documents annual catch histories.",
    "These are composition observations, not catch numbers-at-age."
  ),
  survey_age_evidence = paste(
    "FAR 2024/49 Table 5 reports Kaharoa survey abundance estimates for",
    "age classes 1+ through 4+ (model ages 2-5) in thousands of fish.",
    "Associated age-specific series and uncertainty are also shown in Figures 23 and 36;"
  ),
  weights_evidence = paste(
    "The assessment fixes a length-weight relation and three time-block growth",
    "parameter sets (Table 6). FAR 2024/50 reports mean weight-at-age and CVs",
    "for selected 2022-23 sampled fisheries; the complete assessment biology",
    "surface is not published as an annual age-weight matrix."
  ),
  maturity_evidence = paste(
    "The 2024 assessment uses a fixed length-based logistic maturity ogive:",
    "L50 35 cm, L5 26 cm and L95 44 cm. The source does not tabulate an",
    "age-specific maturity vector."
  ),
  mortality_evidence = "Natural mortality is fixed at 0.075 per year in the Base Case.",
  timing_evidence = paste(
    "The model uses an annual 1 October-30 September year with October-January",
    "and February-September seasons; spawning occurs at the start of the year.",
    "Kaharoa surveys occur in November, but an exact fractional-year survey timing",
    "is not reported."
  ),
  output_evidence = paste(
    "FAR 2024/49 Table 10 reports Base_Frec current spawning biomass for 2023-24",
    "as 49,830 t (95% interval 39,807-62,665) and F2024/FSB40% as 0.999",
    "(95% interval 0.814-1.204). Annual SSB and F trajectories are plotted but",
    "not tabulated as complete numerical series."
  ),
  detailed_source_url = source_urls[1L],
  review_date = retrieved_on,
  decision_reason = paste(
    "The latest 2025 plenary lists 2024 as the most recent assessment year.",
    "The detailed 2024 production assessment provides age-composition inputs,",
    "age-specific survey abundance information, biological assumptions, and",
    "comparable current SSB and fishing-mortality outputs."
  ),
  notes = paste(
    "Treat SNA 8 as one stock unit. Gear-specific fisheries and north/south",
    "sampling areas are source dimensions within the assessment, not additional",
    "stock records. The assessment reports the scientific name Chrysophrys auratus."
  ),
  stringsAsFactors = FALSE
)

candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (candidate$candidate_id %in% candidates$candidate_id) {
  stop("MPI:SNA8 is already registered; review identity before updating.", call. = FALSE)
}
write.table(candidate, candidate_path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")

manifest <- data.frame(
  local_file = sub("^source_cache/", "", source_files),
  source_url = source_urls,
  retrieved_on = retrieved_on,
  sha256 = expected_hash,
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(root, "provenance", "mpi_snapper_sna8_2024_sources.csv"),
  row.names = FALSE, na = "")

cat("Registered SNA 8 snapper as a source-ready candidate.\n")