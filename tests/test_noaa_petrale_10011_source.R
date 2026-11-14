root <- "database"
stock_id <- "noaa_petrale_sole_pacific_coast"
assessment_id <- "noaa_petrale_sole_pacific_coast_2023"
projection_id <- "noaa_petrale_sole_pacific_coast_2025_projection"

read_table <- function(name) read.csv(file.path(root, name),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
assumptions <- read_table("assumptions.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")

stock <- stocks[stocks$stock_id == stock_id, ]
events <- assessments[assessments$stock_id == stock_id, ]
stopifnot(nrow(stock) == 1L, stock$authority == "NOAA-NWFSC",
  stock$authority_stock_id == "10011", stock$scientific_name == "Eopsetta jordani",
  stock$ocean == "Northeast Pacific", nrow(events) == 2L,
  setequal(events$assessment_id, c(assessment_id, projection_id)))

benchmark <- events[events$assessment_id == assessment_id, ]
projection <- events[events$assessment_id == projection_id, ]
stopifnot(benchmark$assessment_year == 2023L,
  benchmark$terminal_year == 2022L, benchmark$estimate_terminal_year == 2034L,
  !benchmark$is_current, benchmark$is_applied,
  projection$assessment_year == 2025L, projection$terminal_year == 2024L,
  projection$estimate_terminal_year == 2036L,
  projection$is_current, projection$is_applied,
  all(c(benchmark$inputs_status, benchmark$outputs_status,
    benchmark$assumptions_status, projection$inputs_status,
    projection$outputs_status, projection$assumptions_status) == "partial"))

i <- inputs[inputs$assessment_id == assessment_id, ]
ip <- inputs[inputs$assessment_id == projection_id, ]
stopifnot(nrow(i) == 25334L, nrow(ip) == 8L,
  sum(i$measure == "catch_biomass") == 274L,
  sum(i$measure == "catch_se") == 274L,
  sum(i$measure == "relative_biomass_index") == 28L,
  sum(i$measure == "log_index_sd") == 28L,
  sum(i$measure == "discard_fraction") == 43L,
  sum(i$measure == "discard_fraction_cv") == 43L,
  sum(i$measure == "mean_body_weight") == 40L,
  sum(i$measure == "mean_body_weight_cv") == 40L,
  sum(i$measure == "frequency_at_length") > 0L,
  sum(i$measure == "frequency_at_age") > 0L,
  length(unique(i$observation_id[i$measure == "frequency_at_length"])) == 177L,
  length(unique(i$observation_id[i$measure == "frequency_at_age"])) == 809L,
  all(i$value[i$measure == "catch_biomass"] >= 0),
  all(i$unit[i$measure == "catch_biomass"] == "metric tonnes"),
  all(i$basis[i$measure == "discard_fraction"] == "proportion"),
  all(i$year[i$measure == "relative_biomass_index"] %in% 1980:2022),
  all(i$survey[i$measure == "relative_biomass_index"] %in% c("Triennial", "WCGBTS")),
  all(i$sampling_time[i$measure == "relative_biomass_index"] == 0.5),
  all(i$value[i$measure == "relative_biomass_index"] > 0),
  all(i$basis[i$measure == "log_index_sd"] == "log_scale"),
  all(i$age[i$measure == "frequency_at_age"] %in% 1:17),
  all(i$length_bin[i$measure == "frequency_at_length"] %in% seq(12, 62, 2)),
  any(i$value[i$measure %in% c("frequency_at_age", "frequency_at_length")] > 1),
  any(grepl("Original signed fleet code", i$notes)),
  any(grepl("Original signed year", i$notes)),
  any(grepl("sex code 3", i$notes)),
  any(i$sex == "combined", na.rm = TRUE),
  !any(i$measure %in% c("numbers_at_age", "weight_at_age",
    "maturity_at_age", "natural_mortality_at_age")),
  all(ip$measure == "catch_biomass"),
  setequal(ip$value[ip$observation_id == "Table 2: 92% of 2026 ACL" & ip$year == 2026],
    2290))

o <- outputs[outputs$assessment_id == assessment_id, ]
op <- outputs[outputs$assessment_id == projection_id, ]
stopifnot(nrow(o) == 105192L, nrow(op) == 140L,
  sum(o$type == "population" & o$measure == "numbers_at_age") == 13038L,
  sum(o$type == "catch" & o$measure == "numbers_at_age") == 26076L,
  sum(o$measure == "biomass_at_age") == 13038L,
  sum(o$measure == "natural_mortality_at_age") == 13038L,
  sum(o$measure == "fishing_mortality_at_age") == 26076L,
  sum(o$measure == "weight_at_age") == 13038L,
  sum(o$measure == "proportion_mature_at_age") == 82L,
  all(o$year[o$measure == "proportion_mature_at_age"] == 2034),
  sum(o$measure == "total_numbers") == 159L,
  all(o$year[o$measure == "numbers_at_age"] %in% 1876:2034),
  all(o$age[o$measure == "numbers_at_age"] %in% 0:40),
  all(is.na(o$se[o$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "weight_at_age", "proportion_mature_at_age")])),
  all(is.na(o$lwr[o$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "weight_at_age", "proportion_mature_at_age")])),
  all(o$lwr[o$measure == "spawning_output" & o$year %in% 2013:2023] > 0),
  all(o$upr[o$measure == "spawning_output" & o$year %in% 2013:2023] >
    o$lwr[o$measure == "spawning_output" & o$year %in% 2013:2023]),
  all(o$lwr[o$measure == "recruitment" & o$year %in% 2013:2023] > 0),
  nrow(o[o$measure == "spawning_output" & !is.na(o$lwr), ]) == 11L,
  nrow(o[o$measure == "recruitment" & !is.na(o$lwr), ]) == 11L)

n <- o[o$type == "population" & o$measure == "numbers_at_age", ]
total <- aggregate(value ~ year, n, sum)
stored_total <- o[o$measure == "total_numbers", c("year", "value")]
total <- total[order(total$year), ]
stored_total <- stored_total[order(stored_total$year), ]
stopifnot(identical(total$year, stored_total$year),
  isTRUE(all.equal(total$value, stored_total$value, tolerance = 1e-10)))

p <- op[op$scenario == "Table 2: 92% of 2026 ACL", ]
p1 <- op[op$scenario == "Table 1: GMT 2026 removals", ]
p_spawn <- p[p$measure == "spawning_output", ]
p_fraction <- p[p$measure == "fraction_unfished_spawning_output", ]
p_acl <- p[p$measure == "ACL", ]
p_removals <- ip[ip$observation_id == "Table 2: 92% of 2026 ACL", ]
stopifnot(nrow(p_spawn) == 14L, all(p_spawn$year == 2023:2036),
  identical(p_spawn$value, c(7.69, 6.98, 6.29, 6.09, 5.95, 5.88, 5.93,
    6.02, 6.11, 6.19, 6.24, 6.28, 6.31, 6.33)),
  nrow(p_fraction) == 14L, nrow(p_acl) == 11L,
  p_acl$value[p_acl$year == 2026] == 2489,
  p_acl$value[p_acl$year == 2036] == 2484,
  p_removals$value[p_removals$year == 2026] == 2290,
  all(is.na(op$se)), all(is.na(op$lwr)), all(is.na(op$upr)),
  nrow(p1[p1$measure == "spawning_output", ]) == 14L)

a <- assumptions[assumptions$assessment_id %in%
  c(assessment_id, projection_id), ]
stopifnot(nrow(a) == 9L,
  any(a$setting == "natural_mortality"),
  any(a$setting == "survey_indices_and_timing"),
  any(a$setting == "projection_basis"))

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10011", ]
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- inventory[inventory$unit_key == "candidate:noaa_stocksmart_10011", ]
selected <- read.csv("discovery/selected_batch_05_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected <- selected[selected$candidate_unit_id == "noaa_stocksmart_10011", ]
stopifnot(nrow(candidate) == 1L, candidate$import_status == "partial",
  candidate$matched_stock_id == stock_id, nrow(inventory) == 1L,
  inventory$import_status == "partial", nrow(selected) == 1L,
  selected$curation_status == "partial_source_import")

manifest <- read.csv("provenance/noaa_petrale_10011_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(manifest) == 7L)
for (j in seq_len(nrow(manifest))) {
  path <- file.path("source_cache", manifest$local_file[j])
  stopifnot(file.exists(path),
    file.info(path)$size == manifest$bytes[j],
    toupper(unname(tools::sha256sum(path))) == manifest$sha256[j])
}
cat("NOAA Pacific Coast Petrale Sole source, database, output, projection, and provenance checks passed.\n")
