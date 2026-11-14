read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = classes)
}

read_assessment_rows <- function(path, id) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE, encoding = "bytes")
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE, encoding = "bytes")
    if (!length(lines)) break
    rows <- c(rows, lines[startsWith(lines, prefix)])
  }
  if (!length(rows)) return(NULL)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stock_id <- "noaa_gray_snapper_gulf"
assessment_id <- "noaa_gray_snapper_gulf_sedar75_2022"
stock <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "ocean"))
assessment <- read_columns("database/assessments.csv", c("assessment_id",
  "stock_id", "assessment_year", "terminal_year", "estimate_terminal_year",
  "assessment_type", "model_family", "model_version", "is_current",
  "is_applied", "inputs_status", "outputs_status", "assumptions_status"))
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_columns("database/assumptions.csv", c("assessment_id",
  "component", "setting", "value", "source_reference", "notes"))
candidates <- read_columns("discovery/candidates.csv", c("candidate_id",
  "matched_stock_id", "match_status", "eligibility", "import_status",
  "catch_age_evidence", "output_evidence", "notes"))
manifest <- read.csv("provenance/discovery_noaa_gray_snapper_2022/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- stock[stock$stock_id == stock_id, , drop = FALSE]
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10221", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10221",
  stock$scientific_name == "Lutjanus griseus",
  stock$area == "Gulf of Mexico",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2022",
  assessment$terminal_year == "2020",
  assessment$estimate_terminal_year == "2020",
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.19",
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assumptions_status == "partial",
  nrow(assumptions) == 10L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("Tables 14-19", candidate$catch_age_evidence, fixed = TRUE),
  grepl("Table 35", candidate$output_evidence, fixed = TRUE),
  nrow(manifest) >= 6L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(nzchar(manifest$url))
)

stopifnot(
  nrow(inputs) == 1697L,
  sum(inputs$measure == "landings_biomass") == 228L,
  sum(inputs$measure == "landings_numbers") == 228L,
  sum(inputs$measure == "discard_numbers") == 198L,
  sum(inputs$measure == "log_catch_sd") == 654L,
  sum(inputs$measure == "relative_abundance_index") == 180L,
  sum(inputs$measure == "log_index_sd") == 180L,
  sum(inputs$measure == "natural_mortality_at_age") == 29L,
  all(is.finite(as.numeric(inputs$value))),
  all(inputs$source_type == "official_table"),
  all(inputs$year_basis[!is.na(inputs$year)] == "calendar_year"),
  all(inputs$partition[inputs$measure %in% c("landings_biomass", "landings_numbers")] == "landings"),
  all(inputs$partition[inputs$measure == "discard_numbers"] == "discards"),
  setequal(unique(inputs$partition[inputs$measure == "log_catch_sd"]),
    c("landings", "discards")),
  all(inputs$unit[inputs$measure == "landings_biomass"] == "million pounds whole weight"),
  all(inputs$unit[inputs$measure == "landings_numbers"] == "thousand fish"),
  all(inputs$unit[inputs$measure == "discard_numbers"] == "fish"),
  all(inputs$basis[inputs$measure == "natural_mortality_at_age"] == "per_year"),
  setequal(inputs$age[inputs$measure == "natural_mortality_at_age"], as.character(0:28)),
  setequal(unique(inputs$year[inputs$measure == "landings_biomass"]), as.character(1945:2020)),
  setequal(unique(inputs$year[inputs$measure == "relative_abundance_index"]), as.character(1981:2020))
)

input_key_columns <- c("type", "measure", "basis", "fleet", "survey", "year",
  "age", "partition", "observation_id")
input_keys <- do.call(paste, c(lapply(inputs[input_key_columns], function(x)
  ifelse(is.na(x), "", as.character(x))), sep = "\r"))
stopifnot(!anyDuplicated(input_keys))

age0_index <- inputs[inputs$measure == "relative_abundance_index" &
  inputs$survey == "FWRI Age-0 FIM", , drop = FALSE]
age1_index <- inputs[inputs$measure == "relative_abundance_index" &
  inputs$survey == "FWRI Age-1 FIM", , drop = FALSE]
stopifnot(
  setequal(as.integer(age0_index$year), 1998:2020),
  setequal(as.integer(age1_index$year), 1996:2020),
  all(age0_index$age == "0"),
  all(age1_index$age == "1")
)

stopifnot(
  nrow(outputs) == 532L,
  setequal(unique(outputs$year), as.character(1945:2020)),
  all(is.finite(as.numeric(outputs$value))),
  all(outputs$source_type == "official_table"),
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  sum(outputs$measure == "total_biomass") == 76L,
  sum(outputs$measure == "biomass_by_age_group") == 76L,
  sum(outputs$measure == "SSB") == 76L,
  sum(outputs$measure == "total_numbers") == 76L,
  sum(outputs$measure == "recruitment") == 76L,
  sum(outputs$measure == "SSB_ratio_to_B0") == 76L,
  sum(outputs$measure == "exploitation_rate") == 76L,
  all(outputs$unit[outputs$measure == "total_biomass"] == "metric tons"),
  all(outputs$unit[outputs$measure == "total_numbers"] == "thousand fish"),
  all(outputs$unit[outputs$measure == "recruitment"] == "thousand fish"),
  all(outputs$age[outputs$measure == "recruitment"] == "0")
)

first_year <- outputs[outputs$year == "1945", , drop = FALSE]
last_year <- outputs[outputs$year == "2020", , drop = FALSE]
value_at <- function(rows, measure) as.numeric(rows$value[rows$measure == measure])
stopifnot(
  value_at(first_year, "total_biomass") == 56913,
  value_at(last_year, "SSB") == 10345,
  value_at(last_year, "exploitation_rate") == 0.088
)

review <- paste(readLines(
  "discovery/source_reviews/noaa_gray_snapper_2022.md", warn = FALSE),
  collapse = "\n")
stopifnot(
  grepl("Tables 14-19", review, fixed = TRUE),
  grepl("the report also says the Stock Synthesis inputs were in thousands of fish", review, fixed = TRUE),
  grepl("report presents the accepted compositions as figures", review, fixed = TRUE),
  grepl("Numeric fitted N-at-age and instantaneous F-at-age arrays were not located", review, fixed = TRUE),
  grepl("no output SEs or intervals are recorded", review, fixed = TRUE)
)

cat("NOAA Gulf gray snapper SEDAR 75 source rows, dimensions, units, and provenance passed.\n")
