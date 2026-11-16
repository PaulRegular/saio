source("tests/helper_nonenglish_exclusion.R")
check_nonenglish_exclusion(
  "argentina_merluccius_hubbsi_north_41s",
  "argentina_merluccius_hubbsi_north_41s_2025",
  "INIDEP:MERLUCCIUS_HUBBSI_NORTH41",
  "Spanish",
  "source_reviews/argentina_merluccius_hubbsi_north_41s.md"
)
cat("INIDEP northern hake is excluded under the English-report scope.\n")