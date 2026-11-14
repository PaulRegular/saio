assessment_id <- "afma_sessf_silver_warehou_2021"

read_table <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

read_assessment_rows <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 25000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

source("tests/helper_inventory.R")
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
candidates <- read_table("discovery/candidates.csv")
selected <- read_table("discovery/selected_batch_08_2026.csv")
progress <- read_table("discovery/inventory_progress.csv")
units <- read_table("discovery/inventory_units.csv")
manifest <- read_table("provenance/afma_sessf_silver_warehou_2021_sources.csv")

stock <- stocks[stocks$stock_id == "afma_sessf_silver_warehou", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "AFMA:SESSF_SILVER_WAREHOU", , drop = FALSE]
selection <- selected[selected$candidate_id == candidate$candidate_id, , drop = FALSE]
check_inventory_accounting(candidates, progress, units)

catch <- inputs[inputs$measure == "catch_biomass", , drop = FALSE]
discard <- inputs[inputs$measure == "discard_fraction", , drop = FALSE]
age_counts <- inputs[inputs$measure == "composition_sample_count", , drop = FALSE]
age_error <- inputs[inputs$measure == "ageing_error_sd", , drop = FALSE]
parameters <- outputs[outputs$type == "parameter", , drop = FALSE]
projection <- outputs[grepl("Low recruitment;", outputs$scenario, fixed = TRUE), , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "AFMA",
  stock$authority_stock_id == "Silver Warehou (SESSF)",
  stock$scientific_name == "Seriolella punctata",
  stock$ocean == "Southwest Pacific and Southern Ocean",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2020L,
  assessment$estimate_terminal_year == 2040L,
  assessment$model_version == "3.30.17.00",
  assessment$is_current,
  assessment$is_applied,
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 221L,
  nrow(catch) == 82L,
  setequal(as.integer(catch$year), 1980:2020),
  catch$value[catch$fleet == "East trawl" & catch$year == 1980] == 29.5,
  catch$value[catch$fleet == "West trawl" & catch$year == 2020] == 190.7,
  nrow(discard) == 58L,
  discard$value[discard$fleet == "East trawl" & discard$year == 2020] == 0.79,
  discard$sample_size[discard$fleet == "West trawl" & discard$year == 2020] == 416,
  nrow(age_counts) == 57L,
  age_counts$value[age_counts$fleet == "East trawl" & age_counts$year == 2010] == 687,
  nrow(age_error) == 24L,
  setequal(as.integer(age_error$age), 0:23),
  age_error$value[age_error$age == 23] == 2.012440,
  !any(inputs$measure %in% c("numbers_at_age", "relative_abundance_index", "proportion_at_age")),
  nrow(assumptions) == 22L,
  nrow(parameters) == 10L,
  setequal(parameters$measure, c(
    "L_at_amin", "L_at_amax", "VonBert_K", "CV_young", "Q_EastTrawl",
    "Q_WestTrawl", "Size_inflection_Etrawl", "Size_95_width_Etrawl",
    "Size_inflection_Wtrawl", "Size_95_width_Wtrawl"
  )),
  parameters$value[parameters$measure == "Q_WestTrawl"] == -0.02,
  all(is.na(parameters$year)),
  nrow(projection) == 285L,
  projection$value[projection$measure == "SSB_ratio_to_B0" &
    projection$scenario == "Low recruitment; 350 t constant catch" & projection$year == 2040] == 0.35,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2022] == 5374,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  selection$curation_status == "source_curated_partial",
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == "2026-11-06"),
  identical(toupper(unname(tools::sha256sum(file.path("source_cache", manifest$local_file)))),
    toupper(manifest$sha256))
)

cat("AFMA SESSF silver warehou 2021 source checks passed.\n")
