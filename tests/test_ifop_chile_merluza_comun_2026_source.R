root <- "."
assessment_id <- "ifop_merluza_comun_2026"
stock_id <- "ifop_merluza_comun_up"
candidate_id <- "IFOP:merluza_comun_UP"

read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  selected <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, prefix)])
  }
  utils::read.csv(
    text = paste0(paste(c(header, selected), collapse = "\n"), "\n"),
    stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA")
  )
}

stocks <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
all_assumptions <- read.csv(file.path(root, "database/assumptions.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
assumptions <- all_assumptions[
  all_assumptions$assessment_id == assessment_id, , drop = FALSE
]
inputs <- read_assessment_rows(file.path(root, "database/inputs.csv"), assessment_id)
outputs <- read_assessment_rows(file.path(root, "database/outputs.csv"), assessment_id)
candidate <- read.csv(file.path(root, "discovery/candidates.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selection <- read.csv(file.path(root, "discovery/selected_batch_20_2026.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv(file.path(root, "provenance/ifop_merluza_comun_2026_sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
catch <- inputs[inputs$measure == "catch_biomass", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "IFOP",
  stock$scientific_name == "Merluccius gayi",
  stock$ocean == "Southeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2024L,
  assessment$estimate_terminal_year == 2025L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 14L,
  nrow(catch) == 7L,
  identical(as.integer(catch$year), 2019:2025),
  identical(as.numeric(catch$value), c(47719, 49187, 47362, 41200, 40127, 38359, 34920)),
  all(catch$unit == "t"),
  all(catch$source_type[catch$year < 2025] == "reconstructed_source_input"),
  grepl("projection catch assumption", catch$notes[catch$year == 2025], fixed = TRUE),
  nrow(outputs) == 162L,
  identical(sort(unique(as.integer(outputs$year))), 1999:2025),
  identical(as.integer(table(outputs$measure)), rep(27L, 6L)),
  sum(outputs$measure == "fishing_mortality_summary") == 27L,
  outputs$value[outputs$measure == "total_biomass" & outputs$year == 1999] == 1117,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2025] == 152,
  outputs$value[outputs$measure == "recruitment" & outputs$year == 2025] == 457,
  outputs$value[outputs$measure == "fishing_mortality_summary" & outputs$year == 2025] == 0.15,
  outputs$value[outputs$measure == "exploitation_rate" & outputs$year == 2025] == 0.12,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  !any(outputs$measure %in% c("numbers_at_age", "F_at_age", "M_at_age"))
)

stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(selection) == 1L,
  selection$curation_status == "partial_source_import",
  any(grepl("Access database extracted", manifest$notes, fixed = TRUE)),
  any(grepl("preliminary observations", manifest$notes, fixed = TRUE))
)

review <- paste(readLines(file.path(root, "discovery/source_reviews",
  "ifop_chile_merluza_comun_2026.md"), warn = FALSE), collapse = " ")
stopifnot(
  grepl("Table 17 reports estimated abundance by age and sex", review, fixed = TRUE),
  grepl("619 age-read fish", review, fixed = TRUE),
  grepl("not a ready-to-use fitted age-composition matrix", review, fixed = TRUE),
  grepl("not a translation-ready assessment", review, fixed = TRUE),
  grepl("blank age-13 cell", review, fixed = TRUE)
)

cat("IFOP Chilean common-hake source import checks passed.\n")
