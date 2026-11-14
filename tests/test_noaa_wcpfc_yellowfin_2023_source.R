root <- "."
assessment_id <- "wcpfc_wcpo_yellowfin_2023"
stock_id <- "wcpfc_wcpo_yellowfin"
candidate_id <- "NOAA:11694"

read_assessment_rows <- function(path, id, expected_rows) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  prefix <- paste0('"', id, '",')
  size <- file.info(path)$size
  span <- min(size, 128 * 1024^2)
  repeat {
    offset <- max(0, size - span)
    seek(con, where = offset, origin = "start")
    if (offset > 0) readLines(con, n = 1L, warn = FALSE)
    lines <- readLines(con, warn = FALSE)
    rows <- lines[startsWith(lines, prefix)]
    if (length(rows) >= expected_rows || span >= size) break
    span <- min(size, span * 2)
  }
  if (!length(rows)) return(NULL)
  if (length(rows) != expected_rows) stop("Unexpected number of assessment rows in ", path)
  header <- readLines(path, n = 1L, warn = FALSE)
  temporary_csv <- tempfile(fileext = ".csv", tmpdir = "tmp")
  writeLines(c(header, rows), temporary_csv, useBytes = TRUE)
  on.exit(unlink(temporary_csv), add = TRUE)
  read.csv(temporary_csv, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

manifest <- read.csv("provenance/discovery_noaa_wcpo_yellowfin_2023/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(manifest) == 37L, !anyDuplicated(manifest$file))
stopifnot(any(grepl("54274c0edac84e65fdbd8ef5996038e6a8714641",
  manifest$url, fixed = TRUE)))
stopifnot(any(grepl("6b28f0bf4975895beae4df861124b30286ff6fa0",
  manifest$url, fixed = TRUE)))

assessment <- read_assessment_rows("database/assessments.csv", assessment_id, 1L)
stopifnot(nrow(assessment) == 1L, assessment$stock_id == stock_id,
  assessment$assessment_year == 2023L, assessment$terminal_year == 2021L,
  assessment$is_current == "FALSE", assessment$is_applied == "TRUE",
  assessment$inputs_status == "partial", assessment$outputs_status == "partial")
current_diagnostic <- read_assessment_rows("database/assessments.csv",
  "wcpfc_wcpo_yellowfin_2026", 1L)
stopifnot(nrow(current_diagnostic) == 1L,
  current_diagnostic$is_current == "TRUE",
  current_diagnostic$is_applied == "FALSE")

inputs <- read_assessment_rows("database/inputs.csv", assessment_id, 788074L)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id, 141298L)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id, 12L)
stopifnot(nrow(inputs) == 788074L, nrow(outputs) == 141298L,
  nrow(assumptions) == 12L)
stopifnot(sum(inputs$measure %in% c("catch_numbers", "catch_biomass")) == 6588L,
  sum(inputs$measure == "effort") == 1709L,
  sum(inputs$measure == "relative_abundance_index") == 1400L,
  sum(inputs$measure == "frequency_at_length") == 135090L,
  sum(inputs$measure == "frequency_at_weight") == 622800L,
  sum(inputs$measure == "conditional_frequency_at_age") == 1249L,
  sum(inputs$measure == "tag_release_frequency_at_length") == 13300L,
  sum(inputs$measure == "tag_recapture_count") == 5938L)
stopifnot(!any(inputs$measure %in% c("catch_at_age", "numbers_at_age")),
  all(inputs$unit[inputs$measure == "frequency_at_weight"] ==
    "native MFCL weight frequency"),
  all(grepl("sample_size is left blank", inputs$notes[
    inputs$measure %in% c("frequency_at_length", "frequency_at_weight")],
    fixed = TRUE)))
caal <- inputs[inputs$measure == "conditional_frequency_at_age", ]
stopifnot(all(caal$type == "biology"), all(caal$basis == "native_frequency"),
  all(caal$length_bin_upper - caal$length_bin_lower == 2),
  all(caal$sample_size > 0), !anyNA(caal$observation_id))

outputs_diag <- outputs[outputs$scenario == "Diagnostic2023 reference fit", ]
stopifnot(sum(outputs_diag$measure == "numbers_at_age") == 56000L,
  sum(outputs_diag$measure == "fishing_mortality_at_age") == 16800L,
  sum(outputs_diag$measure == "mature_biomass_at_age") == 56000L,
  sum(outputs_diag$measure == "predicted_index") == 1400L,
  sum(outputs_diag$measure == "predicted_catch") == 9030L,
  all(is.na(outputs_diag$se)), all(is.na(outputs_diag$lwr)),
  all(is.na(outputs_diag$upr)))
grid_sb <- outputs[outputs$scenario == "54-model grid median", ]
source_grid_sb <- read.csv(
  "source_cache/discovery_noaa_wcpo_yellowfin_2023/notes/median_sb_time_series.csv",
  check.names = FALSE)
stopifnot(nrow(grid_sb) == 70L,
  identical(as.integer(grid_sb$year), as.integer(source_grid_sb$Year)),
  isTRUE(all.equal(grid_sb$value, source_grid_sb$SB, tolerance = 1e-12)))
grid_stats <- outputs[grepl("^54-model grid plus estimation uncertainty:",
  outputs$scenario), ]
stopifnot(nrow(grid_stats) == 18L, all(is.na(grid_stats$se)),
  all(is.na(grid_stats$lwr)), all(is.na(grid_stats$upr)),
  all(grepl("not confidence limits", grid_stats$notes, fixed = TRUE)))

annual_sb <- outputs[outputs$measure == "spawning_potential_biomass" &
  is.na(outputs$region) & is.na(outputs$season) &
  outputs$scenario == "Diagnostic2023 reference fit", ]
source_summary <- read.csv(
  "source_cache/discovery_noaa_wcpo_yellowfin_2023/TAF/output/summary.csv")
stopifnot(nrow(annual_sb) == 70L,
  isTRUE(all.equal(annual_sb$value, source_summary$sb, tolerance = 1e-12)))

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
candidate <- candidate[candidate$candidate_id == candidate_id, ]
stopifnot(nrow(candidate) == 1L, candidate$import_status == "partial",
  candidate$matched_stock_id == stock_id)

cat("2023 WCPO yellowfin source, status, coverage, units and output summaries passed.\n")
