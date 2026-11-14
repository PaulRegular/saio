read_matching_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stock_id <- "mpi_blue_cod_bco5"
assessment_id <- "mpi_blue_cod_bco5_2019"
stock <- read_matching_rows("database/stocks.csv", stock_id)
assessment <- read_matching_rows("database/assessments.csv", assessment_id)
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:BCO5")
selected <- read.csv("discovery/selected_batch_21_2026.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
selected <- subset(selected, candidate_id == "MPI:BCO5")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "BCO 5",
  stock$scientific_name == "Parapercis colias",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2019L,
  assessment$terminal_year == 2019L,
  assessment$is_current,
  assessment$is_applied,
  assessment$model_family == "Casal2",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 1738L,
  nrow(assumptions) == 28L,
  nrow(outputs) == 10L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "source_curated_partial"
)

catch <- inputs[inputs$measure == "catch_biomass", , drop = FALSE]
stopifnot(
  nrow(catch) == 1071L,
  all(catch$unit == "tonnes"),
  identical(sort(unique(as.integer(catch$year))), 1900:2018),
  length(unique(catch$fleet)) == 3L,
  length(unique(catch$region)) == 3L
)

cpue <- inputs[inputs$measure == "relative_abundance_index", , drop = FALSE]
cpue <- cpue[cpue$survey == "Standardized pot CPUE", , drop = FALSE]
survey <- inputs[inputs$survey == "Foveaux Strait random-stratified pot survey" &
  inputs$measure == "relative_abundance_index", , drop = FALSE]
survey_cv <- inputs[inputs$survey == "Foveaux Strait random-stratified pot survey" &
  inputs$measure == "abundance_index_cv", , drop = FALSE]
stopifnot(
  nrow(cpue) == 116L,
  identical(sort(unique(as.integer(cpue$year))), 1990:2018),
  length(unique(cpue$region)) == 4L,
  nrow(survey) == 3L,
  identical(as.numeric(survey$value), c(11.1, 17.6, 12.5)),
  identical(as.numeric(survey_cv$value), c(0.125, 0.135, 0.215))
)

age_composition <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
stopifnot(
  nrow(age_composition) == 208L,
  length(unique(age_composition$observation_id)) == 8L,
  min(as.numeric(age_composition$age)) == 3,
  max(as.numeric(age_composition$age)) == 15,
  all(is.na(age_composition$sample_size)),
  all(vapply(split(as.numeric(age_composition$value), age_composition$observation_id),
    function(x) abs(sum(x) - 1) <= 0.0002, logical(1L)))
)

length_composition <- inputs[inputs$measure == "proportion_at_length", , drop = FALSE]
recreational <- length_composition[length_composition$observation_id == "recreational_length_2010", , drop = FALSE]
stopifnot(
  nrow(length_composition) == 321L,
  length(unique(length_composition$observation_id)) == 8L,
  all(is.na(length_composition$sample_size)),
  !35 %in% as.numeric(recreational$length_bin),
  abs(sum(as.numeric(recreational$value)) - 0.927152) < 1e-6,
  all(grepl("sample_size is left blank because raw sampled fish counts are not published",
    length_composition$notes, fixed = TRUE))
)

likelihood_weights <- inputs[inputs$measure == "observation_likelihood_weight", , drop = FALSE]
stopifnot(nrow(likelihood_weights) == 16L,
  setequal(as.numeric(likelihood_weights$value), c(5, 20, 100)),
  all(is.na(likelihood_weights$age)),
  all(likelihood_weights$observation_id %in% inputs$observation_id[
    inputs$measure %in% c("proportion_at_age", "proportion_at_length")]))

depletion <- outputs[outputs$measure == "SSB_ratio_to_B0", , drop = FALSE]
derived_ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
stopifnot(
  nrow(depletion) == 5L,
  any(depletion$scenario == "MCMC base run" & depletion$value == 35.7 &
    depletion$lwr == 31 & depletion$upr == 41),
  any(depletion$scenario == "MPD base run" & depletion$value == 32.4 & depletion$region == "BCO 5"),
  nrow(derived_ssb) == 1L,
  derived_ssb$value == 6701,
  derived_ssb$source_type == "derived_source_output",
  is.na(derived_ssb$se),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "recruitment")),
  any(assumptions$component == "M" & assumptions$setting == "fixed_M" &
    assumptions$value == "Fixed at 0.17 per year")
)

review <- paste(readLines("source_reviews/mpi_blue_cod_bco5.md", warn = FALSE), collapse = " ")
stopifnot(
  grepl("1,738 numeric input rows", review, fixed = TRUE),
  grepl("omits the 35 cm bin", review, fixed = TRUE),
  grepl("not a direct catch-numbers-at-age series", review, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)

cat("BCO 5 2019 canonical source import checks passed.\n")
