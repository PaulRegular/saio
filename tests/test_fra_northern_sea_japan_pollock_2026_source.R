source("tests/helper_nonenglish_exclusion.R")
check_nonenglish_exclusion(
  "fra_wpollock_northern_sea_japan",
  "fra_northern_sea_japan_pollock_2026",
  "FRA:FRA-SA2026-SC01-01",
  "Japanese",
  "source_reviews/fra_wpollock_northern_sea_japan.md"
)
cat("FRA Northern Sea of Japan pollock is excluded under the English-report scope.\n")