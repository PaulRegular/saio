source("tests/helper_nonenglish_exclusion.R")
check_nonenglish_exclusion(
  "argentina_merluccius_hubbsi_south_41s",
  "argentina_merluccius_hubbsi_south_41s_2025",
  "INIDEP:MERLUCCIUS_HUBBSI_SUR41",
  "Spanish",
  "source_reviews/argentina_merluccius_hubbsi_south_41s.md"
)
cat("INIDEP southern hake is excluded under the English-report scope.\n")