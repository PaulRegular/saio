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

stock_id <- "noaa_greater_amberjack_south_atlantic"
assessment_id <- "noaa_greater_amberjack_south_atlantic_sedar59_2020"
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
candidate <- candidates[candidates$candidate_id == "NOAA:10208", , drop = FALSE]
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- inventory[!is.na(inventory$candidate_unit_id) &
  inventory$candidate_unit_id == stock_id, , drop = FALSE]
manifest <- read.csv("provenance/discovery_noaa_greater_amberjack_south_atlantic_2020/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

stock <- stock[stock$stock_id == stock_id, , drop = FALSE]
assessment <- assessment[assessment$assessment_id == assessment_id, , drop = FALSE]
stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10208",
  stock$scientific_name == "Seriola dumerili",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2020,
  assessment$terminal_year == 2017,
  assessment$estimate_terminal_year == 2018,
  assessment$model_family == "Beaufort Assessment Model",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 14L,
  nrow(inputs) == 714L,
  nrow(outputs) == 1545L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  nrow(manifest) == 8L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(nzchar(manifest$url))
)

stopifnot(
  sum(inputs$measure == "landings_biomass") == 38L,
  sum(inputs$measure == "landings_numbers") == 38L,
  sum(inputs$measure == "discard_numbers") == 64L,
  sum(inputs$measure == "catch_cv") == 114L,
  sum(inputs$measure == "relative_abundance_index") == 70L,
  sum(inputs$measure == "abundance_index_cv") == 70L,
  sum(inputs$measure == "proportion_at_age") == 270L,
  sum(inputs$measure == "growth_length_at_age") == 10L,
  sum(inputs$measure == "weight_at_age") == 10L,
  sum(inputs$measure == "maturity_at_age") == 10L,
  sum(inputs$measure == "proportion_female_at_age") == 10L,
  sum(inputs$measure == "natural_mortality_at_age") == 10L,
  all(inputs$unit[inputs$measure == "landings_biomass"] == "1000 lb whole weight"),
  all(inputs$unit[inputs$measure == "relative_abundance_index"] == "relative index"),
  inputs$value[inputs$measure == "weight_at_age" & inputs$age == 10] == 12.55,
  inputs$value[inputs$measure == "maturity_at_age" & inputs$age == 10] == 1,
  inputs$value[inputs$measure == "natural_mortality_at_age" & inputs$age == 10] == 0.29,
  identical(sort(unique(as.integer(inputs$year[inputs$measure == "proportion_at_age"]))),
    c(1998:2004, 2007:2017)),
  max(abs(vapply(split(as.numeric(inputs$value[inputs$measure == "proportion_at_age"]),
    inputs$year[inputs$measure == "proportion_at_age"]), sum, numeric(1)) - 1)) < 0.002,
  inputs$value[inputs$measure == "relative_abundance_index" & inputs$survey == "Headboat" & inputs$year == 1980] == 0.86,
  inputs$value[inputs$measure == "relative_abundance_index" & inputs$survey == "SERFS video" & inputs$year == 2011] == 0.56
)

n_age <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
biomass_age <- outputs[outputs$measure == "biomass_at_age", , drop = FALSE]
f_age <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
total_biomass <- outputs[outputs$measure == "total_biomass", , drop = FALSE]
stopifnot(
  nrow(n_age) == 390L,
  nrow(biomass_age) == 390L,
  nrow(f_age) == 380L,
  all(n_age$age_group[n_age$age == 10] == "10+"),
  all(biomass_age$age_group[biomass_age$age == 10] == "10+"),
  all(f_age$age_group[f_age$age == 10] == "10+"),
  min(n_age$year) == 1980,
  max(n_age$year) == 2018,
  max(f_age$year) == 2017,
  n_age$value[n_age$year == 1980 & n_age$age == 1] == 1401.81,
  n_age$value[n_age$year == 1980 & n_age$age == 10] == 28.53,
  nrow(ssb) == 38L,
  max(ssb$year) == 2017,
  total_biomass$value[total_biomass$year == 2018] == 9605,
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr))
)
