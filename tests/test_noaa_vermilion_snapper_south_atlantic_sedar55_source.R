stock_id <- "noaa_vermilion_snapper_south_atlantic"
assessment_id <- paste0(stock_id, "_sedar55_2018")
candidate_id <- "NOAA:10257"

read_assessment_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  prefix <- paste0('"', id, '",')
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(data.frame())
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  read.csv(text = paste(rows, collapse = "\n"), header = FALSE,
    col.names = header, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- read.csv(
  "provenance/discovery_noaa_south_atlantic_vermilion_snapper_2018/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
age_comps <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
length_comps <- inputs[inputs$measure == "proportion_at_length", , drop = FALSE]
age_error <- inputs[inputs$measure == "age_error_probability", , drop = FALSE]
row_sums <- tapply(as.numeric(age_error$value), age_error$age, sum)
output_key <- paste(outputs$type, outputs$measure, outputs$year, outputs$age, sep = "|")
value_at <- function(rows, measure, year, age = NA_character_) {
  keep <- rows$measure == measure & rows$year == as.character(year)
  if (!is.na(age)) keep <- keep & rows$age == as.character(age)
  as.numeric(rows$value[keep])
}

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10257",
  stock$scientific_name == "Rhomboplites aurorubens",
  stock$area == "South Atlantic U.S. EEZ",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2018,
  assessment$terminal_year == 2016,
  assessment$estimate_terminal_year == 2017,
  assessment$model_family == "Beaufort Assessment Model (BAM)",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 13L,
  nrow(inputs) == 4724L,
  nrow(outputs) == 2938L,
  nrow(age_comps) == 936L,
  nrow(length_comps) == 2852L,
  all(age_comps$age %in% as.character(1:12)),
  all(age_comps$unit == "proportion"),
  all(length_comps$unit == "proportion"),
  all(age_comps$age[age_comps$age == "12"] == "12"),
  all(grepl("sample_size is left blank", length_comps$notes[is.na(length_comps$sample_size)], fixed = TRUE)),
  nrow(age_error) == 144L,
  setequal(unique(age_error$age), as.character(1:12)),
  setequal(unique(age_error$age_error), as.character(1:12)),
  max(abs(row_sums - 1)) <= 1e-6,
  all(table(output_key) == 1L),
  nrow(outputs[outputs$measure == "numbers_at_age", ]) == 864L,
  nrow(outputs[outputs$measure == "biomass_at_age", ]) == 864L,
  nrow(outputs[outputs$measure == "fishing_mortality_at_age", ]) == 852L,
  nrow(outputs[outputs$measure == "natural_mortality_at_age", ]) == 0L,
  value_at(outputs, "numbers_at_age", 1946, 1) == 6601771,
  abs(value_at(outputs, "biomass_at_age", 1946, 1) - 995.5515) < 1e-8,
  value_at(outputs, "SSB", 2017) == 1.333492,
  all(is.na(outputs$se)),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 9L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(!is.na(inputs$source_reference) & nzchar(inputs$source_reference)),
  all(!is.na(outputs$source_reference) & nzchar(outputs$source_reference))
)

cat("NOAA South Atlantic vermilion snapper SEDAR 55 inputs, outputs, units, and provenance passed.\n")
