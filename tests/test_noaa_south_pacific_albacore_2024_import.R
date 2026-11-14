root <- "."
assessment_id <- "wcpfc_south_pacific_albacore_2024"
stock_id <- "wcpfc_south_pacific_albacore"

read_assessment <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', id, '"')
  selected <- character()
  repeat {
    chunk <- readLines(connection, n = 50000L, warn = FALSE, encoding = "bytes")
    if (!length(chunk)) break
    selected <- c(selected, chunk[startsWith(chunk, prefix)])
  }
  utils::read.csv(text = paste(c(header, selected), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

stocks <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_assessment(file.path(root, "database/inputs.csv"), assessment_id)
outputs <- read_assessment(file.path(root, "database/outputs.csv"), assessment_id)
assumptions <- read.csv(file.path(root, "database/assumptions.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- read.csv(file.path(root, "discovery/candidates.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
candidate <- candidate[candidate$candidate_id == "NOAA:11688", , drop = FALSE]

length_comps <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
cpue <- inputs[inputs$measure == "relative_abundance_index", , drop = FALSE]
cpue_weights <- inputs[inputs$measure == "relative_precision_weight", , drop = FALSE]
caal <- inputs[inputs$measure == "conditional_frequency_at_age", , drop = FALSE]
reproductive_potential <- inputs[inputs$measure == "reproductive_potential_at_length", , drop = FALSE]
f_age <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
n_age <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
total_n <- outputs[outputs$measure == "total_numbers", , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
generic_cv <- assumptions[assumptions$setting == "generic_CV", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Thunnus alalunga",
  stock$ocean == "South Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2022L,
  assessment$model_family == "MULTIFAN-CL",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 89720L,
  sum(inputs$measure %in% c("catch_numbers", "catch_biomass")) == 3288L,
  sum(inputs$measure == "effort") == 2744L,
  sum(inputs$measure == "frequency_at_length") == 63500L,
  sum(inputs$measure == "relative_abundance_index") == 169L,
  sum(inputs$measure == "relative_precision_weight") == 169L,
  sum(inputs$measure == "conditional_frequency_at_age") == 19800L,
  sum(inputs$measure == "reproductive_potential_at_length") == 50L,
  all(is.na(length_comps$sample_size)),
  length(unique(length_comps$observation_id)) == 1270L,
  all(table(length_comps$observation_id) == 50L),
  all(length_comps$length_bin %in% seq.int(30L, 128L, by = 2L)),
  length(unique(cpue$survey)) == 3L,
  all(cpue$observation_id %in% cpue_weights$observation_id),
  length(unique(caal$observation_id)) == 33L,
  sum(caal$value) == 654L,
  all(caal$age %in% 1:12),
  nrow(reproductive_potential) == 50L,
  nrow(assumptions) == 15L,
  nrow(generic_cv) == 3L,
  all(as.numeric(generic_cv$value) == 0.20),
  nrow(outputs) == 6762L,
  nrow(n_age) == 1656L,
  identical(range(as.integer(n_age$year)), c(1954L, 2022L)),
  identical(range(as.integer(n_age$age)), c(1L, 12L)),
  length(unique(n_age$region)) == 2L,
  nrow(f_age) == 2484L,
  sum(f_age$region == "All model regions") == 828L,
  all(grepl("aggregation formula is not documented", f_age$notes[f_age$region == "All model regions"], fixed = TRUE)),
  nrow(total_n) == 207L,
  nrow(ssb) == 207L,
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial"
)

cat("WCPFC South Pacific albacore 2024 source import checks passed.\n")
