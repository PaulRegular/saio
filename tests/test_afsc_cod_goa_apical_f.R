source("R/read_database.R")

goa <- read_assessment("afsc_cod_goa_2026")
outputs <- goa$outputs
apical_f <- outputs[outputs$measure == "apical_F", , drop = FALSE]

stopifnot(
  nrow(apical_f) == 49L,
  identical(sort(apical_f$year), 1977:2025),
  all(apical_f$type == "mortality"),
  all(apical_f$unit == "per year"),
  all(apical_f$source_type == "official_table"),
  all(is.finite(apical_f$value)),
  all(is.finite(apical_f$se) & apical_f$se > 0),
  all(is.na(apical_f$age)),
  all(grepl("Table 2.9", apical_f$source_reference, fixed = TRUE)),
  all(grepl("Sum Apical F", apical_f$notes, fixed = TRUE)),
  apical_f$value[apical_f$year == 1977] == 0.012,
  apical_f$se[apical_f$year == 1977] == 0.003,
  apical_f$value[apical_f$year == 2025] == 0.399,
  apical_f$se[apical_f$year == 2025] == 0.043
)

cat("GOA Pacific cod Table 2.9 apical-F outputs passed.\n")