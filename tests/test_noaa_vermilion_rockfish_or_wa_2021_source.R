root <- "."
read_assessment_rows <- function(path, ids) {
  con <- file(path, "rt")
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  prefixes <- paste0('"', ids, '",')
  rows <- character()
  repeat {
    block <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(block)) break
    keep <- vapply(block, function(line) any(startsWith(line, prefixes)), logical(1L))
    if (any(keep)) rows <- c(rows, block[keep])
  }
  if (!length(rows)) return(read.csv(text = header, stringsAsFactors = FALSE,
    check.names = FALSE, na.strings = c("", "NA")))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
ids <- c("noaa_vermilion_rockfish_or_wa_2021_oregon",
  "noaa_vermilion_rockfish_or_wa_2021_washington")
stock_id <- "noaa_vermilion_rockfish_or_wa"
stocks <- read_table("database/stocks.csv")
assessments <- read_table("database/assessments.csv")
inputs <- read_assessment_rows("database/inputs.csv", ids)
outputs <- read_assessment_rows("database/outputs.csv", ids)
assumptions_all <- read_table("database/assumptions.csv")
assumptions <- assumptions_all[assumptions_all$assessment_id %in% ids, , drop = FALSE]
candidates <- read_table("discovery/candidates.csv")
inventory <- read_table("discovery/inventory_units.csv")
selected <- read_table("discovery/selected_batch_35_2026.csv")
manifest <- read_table("provenance/noaa_vermilion_rockfish_or_wa_2021/sources.csv")
reviews <- paste(unlist(lapply(c(
  "discovery/source_reviews/noaa_vermilion_rockfish_or_wa_2021.md",
  "discovery/source_reviews/noaa_vermilion_rockfish_oregon_2021.md",
  "discovery/source_reviews/noaa_vermilion_rockfish_washington_2021.md"
), readLines, warn = FALSE)), collapse = " ")

one_output <- function(id, measure, year, age = NA_integer_, sex = NA_character_) {
  x <- outputs[outputs$assessment_id == id & outputs$measure == measure &
    outputs$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  if (!is.na(sex)) x <- x[x$sex == sex, , drop = FALSE]
  if (nrow(x) != 1L) stop("Expected one output for ", id, " ", measure, " ", year, ".")
  x
}
or_id <- ids[1L]
wa_id <- ids[2L]
candidate_rows <- candidates[candidates$candidate_id %in% c("NOAA:15338", "NOAA:15339"), , drop = FALSE]
inventory_row <- inventory[inventory$unit_key == paste0("candidate:", stock_id), , drop = FALSE]
selected_row <- selected[selected$candidate_unit_id == stock_id, , drop = FALSE]
or_inputs <- inputs[inputs$assessment_id == or_id, , drop = FALSE]
wa_inputs <- inputs[inputs$assessment_id == wa_id, , drop = FALSE]
or_outputs <- outputs[outputs$assessment_id == or_id, , drop = FALSE]
wa_outputs <- outputs[outputs$assessment_id == wa_id, , drop = FALSE]
or_spawn <- or_outputs[or_outputs$measure == "spawning_output", , drop = FALSE]
wa_spawn <- wa_outputs[wa_outputs$measure == "spawning_output", , drop = FALSE]
or_rec <- or_outputs[or_outputs$measure == "recruitment", , drop = FALSE]
wa_rec <- wa_outputs[wa_outputs$measure == "recruitment", , drop = FALSE]
or_m <- or_outputs[or_outputs$measure == "natural_mortality_at_age", , drop = FALSE]
wa_m <- wa_outputs[wa_outputs$measure == "natural_mortality_at_age", , drop = FALSE]
or_catch <- or_inputs[or_inputs$type == "catch" & or_inputs$measure %in%
  c("total_biomass", "total_numbers"), , drop = FALSE]
wa_catch <- wa_inputs[wa_inputs$type == "catch" & wa_inputs$measure %in%
  c("total_biomass", "total_numbers"), , drop = FALSE]
or_index <- or_inputs[or_inputs$type == "index" & or_inputs$measure == "total_numbers", , drop = FALSE]
or_index_sd <- or_inputs[or_inputs$type == "index" & or_inputs$measure == "log_index_sd", , drop = FALSE]
wa_index <- wa_inputs[wa_inputs$type == "index", , drop = FALSE]
or_age <- or_inputs[or_inputs$measure == "frequency_at_age", , drop = FALSE]
wa_age <- wa_inputs[wa_inputs$measure == "frequency_at_age", , drop = FALSE]
or_length <- or_inputs[or_inputs$measure == "frequency_at_length", , drop = FALSE]
wa_length <- wa_inputs[wa_inputs$measure == "frequency_at_length", , drop = FALSE]
derived_n <- outputs[outputs$measure == "total_numbers" &
  outputs$source_type == "derived_source_output", , drop = FALSE]

stopifnot(
  sum(stocks$stock_id == stock_id) == 1L,
  stocks$scientific_name[stocks$stock_id == stock_id] == "Sebastes miniatus",
  stocks$authority_stock_id[stocks$stock_id == stock_id] == "15338; 15339",
  stocks$ocean[stocks$stock_id == stock_id] == "Northeast Pacific",
  nrow(assessments[assessments$stock_id == stock_id, , drop = FALSE]) == 2L,
  setequal(assessments$assessment_id[assessments$stock_id == stock_id], ids),
  all(assessments$assessment_year[match(ids, assessments$assessment_id)] == 2021L),
  all(assessments$terminal_year[match(ids, assessments$assessment_id)] == 2020L),
  all(assessments$estimate_terminal_year[match(ids, assessments$assessment_id)] == 2022L),
  all(assessments$inputs_status[match(ids, assessments$assessment_id)] == "partial"),
  all(assessments$outputs_status[match(ids, assessments$assessment_id)] == "partial"),
  nrow(inputs) == 69016L,
  nrow(outputs) == 254494L,
  nrow(assumptions) == 21L,
  nrow(or_catch) == 258L,
  nrow(wa_catch) == 72L,
  min(as.numeric(or_catch$year)) == 1892L,
  max(as.numeric(or_catch$year)) == 2020L,
  min(as.numeric(wa_catch$year)) == 1949L,
  max(as.numeric(wa_catch$year)) == 2020L,
  all(or_catch$unit == "metric tonnes"),
  all(wa_catch$unit == "thousand fish"),
  nrow(or_index) == 20L,
  nrow(or_index_sd) == 20L,
  nrow(wa_index) == 0L,
  all(or_index$unit == "fish per angler-hour"),
  all(is.na(as.numeric(or_index$sampling_time))),
  nrow(or_length) == 2160L,
  nrow(or_age) == 43626L,
  nrow(wa_length) == 504L,
  nrow(wa_age) == 22356L,
  all(!is.na(as.numeric(or_age$age_error))),
  all(!is.na(as.numeric(wa_age$age_error))),
  all(!is.na(as.numeric(or_age$sample_size))),
  all(!is.na(as.numeric(wa_age$sample_size))),
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  !any(inputs$type == "index" & inputs$measure == "numbers_at_age"),
  nrow(or_spawn[!is.na(or_spawn$lwr) & !is.na(or_spawn$upr), , drop = FALSE]) == 11L,
  nrow(wa_spawn[is.na(wa_spawn$lwr) & !is.na(wa_spawn$upr), , drop = FALSE]) == 11L,
  all(or_spawn$unit == "million eggs"),
  all(wa_spawn$unit == "million eggs"),
  one_output(or_id, "spawning_output", 2021L)$value > 21.3,
  one_output(wa_id, "spawning_output", 2021L)$value > 1.5,
  nrow(or_rec[!is.na(or_rec$lwr) & !is.na(or_rec$upr), , drop = FALSE]) == 11L,
  nrow(wa_rec[!is.na(wa_rec$lwr) & !is.na(wa_rec$upr), , drop = FALSE]) == 11L,
  all(is.na(outputs$se)),
  !any(outputs$source_type == "native_model_forecast"),
  nrow(derived_n) == 205L,
  any(abs(as.numeric(or_m$value) - 0.0797241) < 1e-7),
  any(abs(as.numeric(or_m$value) - 0.0727871) < 1e-7),
  any(abs(as.numeric(wa_m$value) - 0.0842438) < 1e-7),
  any(abs(as.numeric(wa_m$value) - 0.0862956) < 1e-7),
  nrow(candidate_rows) == 2L,
  all(candidate_rows$matched_stock_id == stock_id),
  all(candidate_rows$match_status == "matched"),
  all(candidate_rows$import_status == "partial"),
  nrow(inventory_row) == 1L,
  inventory_row$matched_stock_id == stock_id,
  inventory_row$import_status == "partial",
  nrow(selected_row) == 1L,
  selected_row$curation_status == "partial_source_import",
  nrow(manifest) == 16L,
  grepl("Canonical inputs retain", reviews, fixed = TRUE),
  grepl("no estimates are pooled", reviews, fixed = TRUE)
)

cat("NOAA Vermilion rockfish OR/WA source import checks passed.\n")

