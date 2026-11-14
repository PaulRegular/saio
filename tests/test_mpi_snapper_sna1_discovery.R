read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

register <- read_table("discovery/candidates.csv")
row <- register[register$candidate_id == "MPI:SNA1", , drop = FALSE]
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
units <- read_table("discovery/inventory_units.csv")
unit_row <- units[units$unit_key == "stock:mpi_snapper_sna1", , drop = FALSE]
selection <- read_table("discovery/selected_batch_05_2026.csv")
manifest <- read_table("provenance/mpi_snapper_sna1_2023_sources.csv")
review_path <- "discovery/source_reviews/mpi_snapper_sna1_2023.md"
review <- paste(readLines(review_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == "mpi_snapper_sna1",
  row$organization == "Fisheries New Zealand",
  row$official_stock_id == "SNA 1",
  row$scientific_name == "Chrysophrys auratus",
  row$inventory_assessment_year == 2023L,
  row$match_status == "matched",
  row$screening_status == "screened",
  row$eligibility == "eligible",
  row$import_status == "partial",
  row$matched_stock_id == "mpi_snapper_sna1",
  "mpi_snapper_sna1" %in% stocks$stock_id,
  "mpi_snapper_sna1_2023" %in% assessments$assessment_id,
  nrow(selection) == 1L,
  selection$candidate_id == "MPI:SNA1",
  selection$candidate_unit_id == row$candidate_unit_id,
  selection$curation_status == "source_curated_partial",
  nrow(unit_row) == 1L,
  unit_row$matched_stock_id == "mpi_snapper_sna1",
  unit_row$inventory_entries == 1L,
  unit_row$import_status == "partial"
)

expected_files <- c(
  "FAR-2024-47-SNA1-assessment-2022-2023.pdf",
  "FAR-2022-24-SNA1-age-composition-2019-20.pdf",
  "FAR-2021-08-SNA1-trawl-surveys-2019-20.pdf",
  "FAR-2022-10-SNA1-trawl-surveys-2020-21.pdf",
  "FAR-2023-41-SNA1-bottom-trawl-CPUE.pdf",
  "Fisheries-Assessment-Plenary-2025-SNA1.pdf",
  "FAR-2024-69-SNA1-age-composition-2022-23.pdf"
)
stopifnot(nrow(manifest) == length(expected_files),
  setequal(basename(manifest$local_file), expected_files),
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(grepl("^https://", manifest$source_url)),
  all(manifest$retrieved_on == "2026-11-06"))

if (all(file.exists(file.path("source_cache", manifest$local_file)))) {
  actual <- toupper(unname(tools::sha256sum(
    file.path("source_cache", manifest$local_file))))
  stopifnot(identical(actual, manifest$sha256))
}

stopifnot(
  grepl("East Northland", review, fixed = TRUE),
  grepl("Hauraki Gulf", review, fixed = TRUE),
  grepl("Bay of Plenty", review, fixed = TRUE),
  grepl("age-specific research-survey abundance indices", review, fixed = TRUE),
  grepl("0.075 per year", review, fixed = TRUE),
  grepl("55,873 tonnes", review, fixed = TRUE),
  grepl("complete annual area-specific weight-at-age matrices", review, fixed = TRUE),
  grepl("are not tabulated", review, fixed = TRUE),
  grepl("FAR 2024/69", review, fixed = TRUE)
)

cat("SNA 1 discovery selection and source provenance passed.\n")
