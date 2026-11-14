stock_id <- "noaa_south_atlantic_red_porgy"
assessment_id <- "noaa_south_atlantic_red_porgy_sedar60_2020"
candidate_id <- "NOAA:10100"

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
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv("provenance/noaa_south_atlantic_red_porgy_sedar60_2020/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_south_atlantic_red_porgy_2020.md",
  warn = FALSE), collapse = "\n")

input_value <- function(measure, year = NA_integer_, age = NA_integer_,
                        fleet = NA_character_, survey = NA_character_,
                        sex = NA_character_, partition = NA_character_) {
  keep <- inputs$measure == measure
  if (!is.na(year)) keep <- keep & inputs$year == as.character(year)
  if (!is.na(age)) keep <- keep & inputs$age == as.character(age)
  if (!is.na(fleet)) keep <- keep & !is.na(inputs$fleet) & inputs$fleet == fleet
  if (!is.na(survey)) keep <- keep & !is.na(inputs$survey) & inputs$survey == survey
  if (!is.na(sex)) keep <- keep & !is.na(inputs$sex) & inputs$sex == sex
  if (!is.na(partition)) keep <- keep & !is.na(inputs$partition) & inputs$partition == partition
  as.numeric(inputs$value[keep])
}
output_value <- function(measure, year = NA_integer_, age = NA_integer_,
                         fleet = NA_character_, scenario = NA_character_) {
  keep <- outputs$measure == measure
  if (!is.na(year)) keep <- keep & outputs$year == as.character(year)
  if (!is.na(age)) keep <- keep & outputs$age == as.character(age)
  if (!is.na(fleet)) keep <- keep & !is.na(outputs$fleet) & outputs$fleet == fleet
  if (!is.na(scenario)) keep <- keep & !is.na(outputs$scenario) & outputs$scenario == scenario
  as.numeric(outputs$value[keep])
}
output_key <- paste(outputs$type, outputs$measure, outputs$fleet, outputs$survey,
  outputs$year, outputs$age, outputs$age_group, outputs$scenario, sep = "|")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA Fisheries",
  stock$authority_stock_id == "10100",
  stock$scientific_name == "Pagrus pagrus",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2020,
  assessment$terminal_year == 2017,
  assessment$estimate_terminal_year == 2017,
  assessment$model_family == "Beaufort Assessment Model",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 11L,
  nrow(inputs) == 806L,
  nrow(outputs) == 5554L,
  all(inputs$source_type == "official_table"),
  all(outputs$source_type == "official_table"),
  anyDuplicated(output_key) == 0L,
  input_value("landings_biomass", 1972, fleet = "Commercial handline",
    partition = "landings") == 32.17,
  input_value("catch_cv", 1972, fleet = "Commercial handline",
    partition = "landings") == 0.05,
  input_value("relative_abundance_index", 1973,
    survey = "Recreational headboat index") == 1.990,
  input_value("abundance_index_cv", 1973,
    survey = "Recreational headboat index") == 0.177,
  any(input_value("composition_sample_count", 1997,
    fleet = "Commercial handline") == 309),
  input_value("natural_mortality_at_age", age = 14) == 0.21,
  input_value("weight_at_age", age = 14) == 1.05,
  input_value("maturity_at_age", age = 1, sex = "female") == 0.30,
  !any(inputs$measure == "proportion_at_age"),
  output_value("numbers_at_age", 1972, age = 1) == 3331.19,
  output_value("total_numbers", 2017) == 1764.35,
  output_value("SSB", 2017) == 780,
  output_value("fishing_mortality_at_age", 2017, age = 14) == 0.281,
  output_value("Fmsy", scenario = "base-run reference quantity estimate") == 0.18,
  output_value("F20_percent", scenario = "base-run reference quantity estimate") == 3.115,
  output_value("estimated_discards", scenario = "MSY dead-discard numbers estimate") == 104,
  outputs$se[outputs$measure == "Fmsy" &
    outputs$scenario == "base-run reference quantity estimate"] == 0.027,
  all(is.na(outputs$se[outputs$measure == "numbers_at_age"])),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 1L,
  manifest$bytes == "2544289",
  grepl("Tables 16–29", review, fixed = TRUE),
  grepl("composition proportions", review, fixed = TRUE),
  grepl("Table 11's year-specific CVs", review, fixed = TRUE)
)

cat("NOAA South Atlantic red porgy SEDAR 60 source inputs, outputs, units, and provenance passed.\n")
