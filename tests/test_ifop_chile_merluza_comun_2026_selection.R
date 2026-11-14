root <- "."
candidate_id <- "IFOP:merluza_comun_UP"
stock_id <- "ifop_merluza_comun_up"

candidates <- read.csv(file.path(root, "discovery/candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selection <- read.csv(file.path(root, "discovery/selected_batch_20_2026.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
sources <- read.csv(file.path(root, "provenance/ifop_merluza_comun_2026_sources.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
stopifnot(
  nrow(candidates) == 971L,
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == stock_id,
  candidate$organization == "IFOP",
  is.na(candidate$official_stock_id) || !nzchar(candidate$official_stock_id),
  candidate$scientific_name == "Merluccius gayi",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(stock) == 1L
)

selection_row <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
stopifnot(
  nrow(selection_row) == 1L,
  selection_row$inventory_assessment_year == 2026L,
  selection_row$curation_status == "partial_source_import",
  nrow(sources) == 8L,
  all(grepl("^[A-F0-9]{64}$", sources$sha256)),
  all(file.exists(file.path(root, sources$file))),
  identical(toupper(unname(tools::sha256sum(file.path(root, sources$file)))), sources$sha256),
  any(grepl("revision minute", sources$notes, fixed = TRUE)),
  any(grepl("quota decree", sources$notes, fixed = TRUE)),
  any(grepl("Access database extracted", sources$notes, fixed = TRUE))
)

review <- paste(readLines(file.path(root, "discovery/source_reviews",
  "ifop_chile_merluza_comun_2026.md"), warn = FALSE), collapse = " ")
stopifnot(
  grepl("2027 status assessment as in progress", review, fixed = TRUE),
  grepl("not observed catch", review, fixed = TRUE),
  grepl("preliminary 2025 fitted observations", review, fixed = TRUE),
  grepl("age-13 cell", review, fixed = TRUE)
)

structure <- paste(readLines(file.path(root, "DATABASE_STRUCTURE.md"), warn = FALSE), collapse = " ")
validator <- paste(readLines(file.path(root, "scripts/database/002_validate_database.R"), warn = FALSE), collapse = " ")
stopifnot(
  grepl("Southeast Pacific", structure, fixed = TRUE),
  grepl("Southeast Pacific", validator, fixed = TRUE)
)

cat("IFOP Chilean common-hake selection and provenance checks passed.\n")
