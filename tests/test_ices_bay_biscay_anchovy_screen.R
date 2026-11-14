root <- "."
register <- read.csv(file.path(root, "discovery", "candidates.csv"), stringsAsFactors = FALSE)
selected <- read.csv(file.path(root, "discovery", "selected_batch_19_2026.csv"), stringsAsFactors = FALSE)
provenance <- read.csv(file.path(root, "provenance", "ices_ane_27_8_sources.csv"), stringsAsFactors = FALSE)

candidate <- register[register$candidate_id == "ICES:ane.27.8", , drop = FALSE]
batch <- selected[selected$candidate_id == "ICES:ane.27.8", , drop = FALSE]
source_review <- paste(readLines(file.path(root, "discovery", "source_reviews", "ices_bay_biscay_anchovy_2025.md")), collapse = "\n")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "ices_bay_biscay_anchovy_8",
  candidate$official_stock_id == "ane.27.8",
  candidate$assessment_area == "ICES Subarea 8 (Bay of Biscay)",
  candidate$eligibility == "eligible",
  candidate$screening_status == "screened",
  grepl("aggregate PELGAS/BIOMAN SSB and CV", candidate$survey_age_evidence, fixed = TRUE),
  grepl("JUVENA N0/CV", candidate$survey_age_evidence, fixed = TRUE),
  grepl("table does not state a unit", candidate$survey_age_evidence, fixed = TRUE),
  grepl("million fish", candidate$survey_age_evidence, fixed = TRUE),
  grepl("29335520.v3", candidate$detailed_source_url, fixed = TRUE),
  !grepl("52237436", candidate$detailed_source_url, fixed = TRUE),
  nrow(batch) == 1L,
  batch$inventory_assessment_year == 2025L,
  batch$curation_status %in% c("selected_for_source_curation", "partial_source_import"),
  nrow(provenance) == 5L,
  all(grepl("^[A-F0-9]{64}$", provenance$sha256)),
  grepl("source_cache/ices_ane_27_8", source_review, fixed = TRUE),
  grepl("provenance/ices_ane_27_8_sources.csv", source_review, fixed = TRUE),
  grepl("145,608 t", source_review, fixed = TRUE),
  grepl("157,247 t", source_review, fixed = TRUE),
  grepl("Table 2.5.1.1 directly reports", source_review, fixed = TRUE),
  grepl("Table 2.5.2.1 is the model-configuration table", source_review, fixed = TRUE),
  grepl("no numerical observations", source_review, fixed = TRUE),
  grepl("2025 first-semester age input", source_review, fixed = TRUE),
  grepl("386,953,330.0", source_review, fixed = TRUE),
  grepl("4,951, 3,430, and 266 million", source_review, fixed = TRUE),
  grepl("conversion from the reported millions", source_review, fixed = TRUE),
  grepl("Historical BIOMAN and PELGAS age series are shown graphically", source_review, fixed = TRUE)
)

cat("ICES Bay of Biscay anchovy discovery checks passed.\n")
