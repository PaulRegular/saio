root <- "."
db <- file.path(root, "database")
assessment_id <- "nefsc_haddock_georges_bank_2026"
assessment <- read.csv(file.path(db, "assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
outputs <- read.csv(file.path(db, "outputs.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
a <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id & outputs$year %in% 2026:2031, , drop = FALSE]
ssb <- o[o$measure == "SSB", , drop = FALSE]
fbar <- o[o$measure == "Fbar", , drop = FALSE]
catch <- o[o$measure == "predicted_catch", , drop = FALSE]

stopifnot(
  nrow(a) == 1L, a$terminal_year == 2025L, a$estimate_terminal_year == 2031L,
  nrow(o) == 18L, nrow(ssb) == 6L, nrow(fbar) == 6L, nrow(catch) == 6L,
  identical(ssb$year, 2026:2031),
  identical(ssb$value, c(25281, 21828, 19804, 19818, 20956, 22157)),
  identical(ssb$lwr, c(9775, 6359, 5174, 4053, 3246, 2772)),
  identical(ssb$upr, c(65382, 74926, 75810, 96904, 135301, 177110)),
  identical(fbar$value, c(.247, rep(.27, 5))),
  all(fbar$age_group == "5–7"),
  fbar$lwr[1L] == .09, fbar$upr[1L] == .675,
  all(is.na(fbar$lwr[-1L])), all(is.na(fbar$upr[-1L])),
  identical(catch$value, c(5768, 5277, 4640, 4498, 4659, 4888)),
  all(o$source_type == "official_table"), all(is.na(o$se)),
  all(o$year > a$terminal_year)
)

cat("Georges Bank haddock projection records match the published 2026 Table 3.\n")
