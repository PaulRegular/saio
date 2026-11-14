read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

candidate_id <- "MPI:GUR3"
candidate_unit_id <- "mpi_red_gurnard_gur3"
candidate <- read_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
batch <- read_table("discovery/selected_batch_17_2026.csv")
units <- read_table("discovery/inventory_units.csv")
unit <- units[units$unit_key == paste0("stock:", candidate_unit_id), , drop = FALSE]
manifest <- read_table("provenance/mpi_red_gurnard_gur3_2022_sources.csv")
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
review <- paste(readLines("discovery/source_reviews/mpi_red_gurnard_gur3_2022.md",
  warn = FALSE, encoding = "UTF-8"), collapse = "\n")

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == "GUR 3",
  candidate$scientific_name == "Chelidonichthys kumu",
  candidate$inventory_assessment_year == "2022",
  candidate$match_status == "matched",
  candidate$matched_stock_id == candidate_unit_id,
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(batch) == 1L,
  batch$candidate_id == candidate_id,
  batch$curation_status == "partial_source_import",
  nrow(unit) == 1L,
  unit$eligibility == "eligible",
  unit$screening_status == "screened",
  unit$match_status == "matched",
  unit$import_status == "partial",
  nrow(manifest) == 3L,
  sum(stocks$stock_id == candidate_unit_id) == 1L,
  sum(assessments$stock_id == candidate_unit_id) == 1L,
  grepl("no commercial fishery age or length compositions", review, ignore.case = TRUE),
  grepl("age-composition proportions", review, ignore.case = TRUE),
  grepl("CPUE index observations", review, ignore.case = TRUE),
  grepl("source importer records only values printed", review, ignore.case = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)

source_paths <- file.path("source_cache", manifest$local_file)
stopifnot(all(file.exists(source_paths)))
stopifnot(identical(
  toupper(unname(tools::sha256sum(source_paths))),
  toupper(manifest$sha256)
))
cat("GUR 3 unit screen, source evidence, selection, and provenance passed.\n")
