read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "bytes")
  matches <- system2("rg", c("--color", "never", "--no-heading", "--no-line-number",
    "-F", assessment_id, path), stdout = TRUE, stderr = FALSE)
  status <- attr(matches, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) matches <- character() else if (status != 0L)
    stop("Could not read records for ", assessment_id, ".")
  matches <- matches[startsWith(matches, paste0('"', assessment_id, '",'))]
  read.csv(text = paste(c(header, matches), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}

root <- "."
stock_id <- "noaa_gulf_golden_tilefish"
assessment_id <- "noaa_gulf_golden_tilefish_2011"
stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessment <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == "NOAA:10383", , drop = FALSE]
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
selected <- read.csv("discovery/selected_batch_38_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- selected[selected$candidate_id == "NOAA:10383", , drop = FALSE]
manifest <- read.csv("provenance/discovery_noaa_gulf_tilefish_sedar22_2011/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_golden_tilefish_gulf_sedar22_2011.md",
  warn = FALSE), collapse = " ")

stock_row <- stock[stock$stock_id == stock_id, , drop = FALSE]
assessment_row <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
landings <- inputs[inputs$measure == "landings_biomass", , drop = FALSE]
discard <- inputs[inputs$measure == "discard_numbers", , drop = FALSE]
indices <- inputs[inputs$measure == "relative_abundance_index", , drop = FALSE]
index_sd <- inputs[inputs$measure == "log_index_sd", , drop = FALSE]
age_error <- inputs[inputs$measure == "ageing_error_sd", , drop = FALSE]
length_cells <- inputs[inputs$measure == "frequency_at_length", , drop = FALSE]
age_cells <- inputs[inputs$measure == "conditional_frequency_at_age", , drop = FALSE]
sample_counts <- inputs[inputs$measure == "composition_sample_count", , drop = FALSE]
length_counts <- sample_counts[grepl("^tilefish_length_", sample_counts$observation_id), , drop = FALSE]
age_counts <- sample_counts[grepl("^tilefish_age_", sample_counts$observation_id), , drop = FALSE]
length_cells <- length_cells[order(length_cells$observation_id, as.numeric(length_cells$length_bin)), ]
age_cells <- age_cells[order(age_cells$observation_id, as.numeric(age_cells$age)), ]
composition_check <- function(cells, totals, expected_cells, expected_samples, cap) {
  groups <- split(cells, cells$observation_id)
  total_by_id <- setNames(as.numeric(totals$value), totals$observation_id)
  all(vapply(groups, function(x) {
    id <- x$observation_id[1L]
    nrow(x) == expected_cells && sum(as.numeric(x$value)) == total_by_id[[id]] &&
      length(unique(as.numeric(x$sample_size))) == 1L &&
      as.numeric(x$sample_size[1L]) == min(total_by_id[[id]], cap)
  }, logical(1L))) && length(groups) == expected_samples
}

total_biomass <- outputs[outputs$measure == "total_biomass", , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]
exploitation <- outputs[outputs$measure == "exploitation_rate", , drop = FALSE]
get_output <- function(x, measure, year, region) {
  x[!is.na(x$year) & x$measure == measure & x$year == as.character(year) &
      x$region == region, , drop = FALSE]
}

stopifnot(
  nrow(stock_row) == 1L,
  stock_row$authority == "NOAA Fisheries",
  stock_row$authority_stock_id == "10383",
  stock_row$scientific_name == "Lopholatilus chamaeleonticeps",
  stock_row$common_name == "Gulf of Mexico golden tilefish",
  stock_row$area == "Gulf of Mexico",
  stock_row$ocean == "Northwest Atlantic",
  nrow(assessment_row) == 1L,
  assessment_row$assessment_year == 2011,
  assessment_row$terminal_year == 2009,
  assessment_row$model_family == "Stock Synthesis",
  assessment_row$model_version == "3.10g",
  assessment_row$is_current,
  assessment_row$is_applied,
  assessment_row$inputs_status == "partial",
  assessment_row$outputs_status == "partial",
  assessment_row$assumptions_status == "partial",
  nrow(assumptions) == 16L,
  nrow(inputs) == 36719L,
  nrow(outputs) == 322L,
  nrow(landings) == 222L,
  nrow(discard) == 2L,
  all(is.na(discard$year)),
  setequal(as.numeric(discard$value), c(981, 3509)),
  nrow(indices) == 52L,
  nrow(index_sd) == 52L,
  nrow(age_error) == 31L,
  setequal(as.numeric(age_error$age), seq(0.5, 30.5, 1)),
  as.numeric(age_error$value[age_error$age == 0.5]) == 0.01,
  as.numeric(age_error$value[age_error$age == 30.5]) == 3.67,
  nrow(length_cells) == 7200L,
  nrow(length_counts) == 150L,
  composition_check(length_cells, length_counts, 48L, 150L, 200L),
  sum(as.numeric(length_counts$value) > 200) == 21L,
  nrow(age_cells) == 28043L,
  nrow(age_counts) == 967L,
  composition_check(age_cells, age_counts, 29L, 967L, 100L),
  setequal(as.numeric(age_cells$age), 2:30),
  all(age_cells$length_bin_upper == as.numeric(age_cells$length_bin_lower) + 2),
  grepl("age 30 is the plus group", paste(age_cells$notes, collapse = " "), ignore.case = TRUE),
  nrow(total_biomass) == 92L,
  nrow(ssb) == 92L,
  nrow(recruitment) == 92L,
  nrow(exploitation) == 46L,
  all(is.na(outputs$se)) && all(is.na(outputs$lwr)) && all(is.na(outputs$upr)),
  as.numeric(get_output(total_biomass, "total_biomass", 1965, "East")$value) == 3914820,
  as.numeric(get_output(ssb, "SSB", 1965, "East")$value) == 38.4,
  as.numeric(get_output(recruitment, "recruitment", 1965, "East")$value) == 85,
  as.numeric(exploitation$value[!is.na(exploitation$year) & exploitation$year == "1965"]) == 9.2e-4,
  all(exploitation$unit == "ratio"),
  all(grepl("not an age-specific instantaneous", exploitation$notes, fixed = TRUE)),
  nrow(outputs[!is.na(outputs$scenario) & outputs$scenario == "Virgin", , drop = FALSE]) == 7L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial",
  nrow(selected) == 1L,
  selected$curation_status == "partial_source_import",
  nrow(manifest) == 8L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  grepl("Appendix A raw counts", review, fixed = TRUE),
  grepl("Table 3.7 supplies", review, fixed = TRUE),
  grepl("status determinations only", review, ignore.case = TRUE),
  grepl("1970", review, fixed = TRUE),
  !any(landings$year == "1970")
)

cat("NOAA Gulf golden tilefish SEDAR 22 source inputs, native composition records, output definitions, coverage and provenance passed.\n")
