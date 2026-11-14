.libPaths(c("source_cache/r-library", .libPaths()))

root <- "."
cache <- file.path(root, "source_cache", "discovery_ices_ling_5a_2026")
assessment_id <- "ices_ling_5a_2026"
source_manifest <- read.csv(
  file.path(root, "provenance", "discovery_ices_ling_5a_2026", "supplementary_sources.csv"),
  stringsAsFactors = FALSE
)
importer <- file.path(root, "scripts", "database", "661_import_ices_ling_5a_supplementary_tables.R")
old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
import_env <- new.env(parent = globalenv())
sys.source(importer, envir = import_env)
if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

inputs <- import_env$inputs
outputs <- import_env$outputs
input_measure <- function(measure, type = NULL) {
  keep <- inputs$measure == measure
  if (!is.null(type)) keep <- keep & inputs$type == type
  inputs[keep, , drop = FALSE]
}
output_measure <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]
input_value <- function(type, measure, year, age, survey = "") {
  rows <- inputs[inputs$type == type & inputs$measure == measure &
    inputs$year == year & inputs$age == age & inputs$survey == survey, , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  rows$value
}
output_value <- function(measure, year, age) {
  rows <- outputs[outputs$measure == measure & outputs$year == year &
    outputs$age == age, , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  rows$value
}

stopifnot(
  nrow(source_manifest) == 1L,
  source_manifest$file == "MFRI_ling_2026_supplementary_tables.html",
  source_manifest$retrieved_on == "2026-11-14",
  source_manifest$sha256 == "084aef47d10cb0c6a44e3fea6a568fe3ed5e4cc210eef209061ce040dd4f46a5",
  file.exists(file.path(cache, source_manifest$file)),
  file.info(file.path(cache, source_manifest$file))$size == as.numeric(source_manifest$bytes),
  nrow(inputs) == 3008L,
  nrow(outputs) == 1045L,
  nrow(input_measure("numbers_at_age", "catch")) == 470L,
  nrow(input_measure("catch_weight_at_age")) == 517L,
  nrow(input_measure("weight_at_age")) == 517L,
  nrow(input_measure("maturity_at_age")) == 517L,
  nrow(input_measure("numbers_at_age", "index")) == 987L,
  nrow(output_measure("numbers_at_age")) == 528L,
  nrow(output_measure("fishing_mortality_at_age")) == 517L,
  identical(sort(unique(input_measure("numbers_at_age", "catch")$age)), 3:12),
  identical(sort(unique(output_measure("numbers_at_age")$year)), 1979:2026),
  identical(sort(unique(output_measure("fishing_mortality_at_age")$year)), 1979:2025),
  sum(input_measure("numbers_at_age", "index")$survey == "IS-SMB groundfish survey") == 451L,
  sum(input_measure("numbers_at_age", "index")$survey == "IS-SMH groundfish survey") == 280L,
  sum(input_measure("numbers_at_age", "index")$survey == "IS-SMN gillnet survey") == 256L,
  all(is.na(input_measure("numbers_at_age", "index")$sampling_time)),
  all(input_measure("numbers_at_age", "index")$unit == "reported index units"),
  all(input_measure("numbers_at_age", "index")$basis == "index_scale"),
  all(input_measure("maturity_at_age")$value >= 0 & input_measure("maturity_at_age")$value <= 1),
  input_value("catch", "numbers_at_age", 1979L, 3L) == 0,
  input_value("catch", "numbers_at_age", 1979L, 4L) == 1.246,
  input_value("catch_weight", "catch_weight_at_age", 1979L, 2L) == 135,
  input_value("weight", "weight_at_age", 1979L, 2L) == 135,
  input_value("maturity", "maturity_at_age", 1979L, 2L) == 0,
  input_value("index", "numbers_at_age", 1985L, 2L, "IS-SMB groundfish survey") == 0.005,
  output_value("numbers_at_age", 1979L, 2L) == 2692,
  output_value("fishing_mortality_at_age", 1979L, 2L) == 0,
  sum(outputs$scenario == "2026 advice projection") == 11L,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  import_env$candidate_updated$matched_stock_id == "ices_ling_5a",
  import_env$assessment_updated$outputs_status == "complete",
  import_env$assessment_updated$inputs_status == "partial",
  import_env$inventory_updated$import_status == "partial"
)

review <- paste(readLines(
  file.path(root, "discovery", "source_reviews", "ices_ling_5a_2026.md"), warn = FALSE
), collapse = "\n")
stopifnot(
  grepl("3–12+", review, fixed = TRUE),
  grepl("six blank cells", review, fixed = TRUE),
  grepl("eight blank cells", review, fixed = TRUE),
  grepl("Table 14", review, fixed = TRUE),
  grepl("SSB-weights table is empty", review, fixed = TRUE),
  grepl("sampling fractions", review, fixed = TRUE)
)

cat("Icelandic ling supplementary-table checks passed.\n")
