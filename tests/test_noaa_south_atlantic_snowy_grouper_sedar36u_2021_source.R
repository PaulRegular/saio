read_assessment_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  prefix <- paste0('"', id, '",')
  rows <- rows[!is.na(rows) & nzchar(rows) & startsWith(rows, prefix)]
  if (!length(rows)) return(data.frame())
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  read.csv(text = paste(rows, collapse = "\n"), header = FALSE,
    col.names = header, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

assessment_id <- "noaa_snowy_grouper_south_atlantic_sedar36u_2021"
stock_id <- "noaa_snowy_grouper_south_atlantic"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
manifest <- read.csv("provenance/noaa_snowy_grouper_sedar36u_2021/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_snowy_grouper_sedar36u_2021.md",
  warn = FALSE), collapse = " ")

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10339", , drop = FALSE]
inventory_row <- inventory[grepl("NOAA:10339", inventory$candidate_ids, fixed = TRUE), , drop = FALSE]
weight_age1 <- inputs[inputs$measure == "weight_at_age" & inputs$age == 1L, , drop = FALSE]
m_age25 <- inputs[inputs$measure == "natural_mortality_at_age" & inputs$age == 25L, , drop = FALSE]
catch_ch_1974 <- inputs[inputs$measure == "catch_biomass" &
  inputs$fleet == "Commercial handline" & inputs$year == 1974L, , drop = FALSE]
catch_cl_1974 <- inputs[inputs$measure == "catch_biomass" &
  inputs$fleet == "Commercial longline" & inputs$year == 1974L, , drop = FALSE]
headboat_1978 <- inputs[inputs$measure == "relative_abundance_index" &
  inputs$survey == "Headboat index" & inputs$year == 1978L, , drop = FALSE]
headboat_cv_1978 <- inputs[inputs$measure == "abundance_index_cv" &
  inputs$survey == "Headboat index" & inputs$year == 1978L, , drop = FALSE]
chevron_age_n_1996 <- inputs[inputs$measure == "composition_sample_count" &
  inputs$observation_id == "SEDAR36U_Table34_age_chevron_trap" &
  inputs$year == 1996L, , drop = FALSE]
nage_1974_age1 <- outputs[outputs$measure == "numbers_at_age" &
  outputs$year == 1974L & outputs$age == 1L, , drop = FALSE]
total_n_1974 <- outputs[outputs$measure == "total_numbers" & outputs$year == 1974L, , drop = FALSE]
recruitment_1974 <- outputs[outputs$measure == "recruitment" & outputs$year == 1974L, , drop = FALSE]
nage_2019_age1 <- outputs[outputs$measure == "numbers_at_age" &
  outputs$year == 2019L & outputs$age == 1L, , drop = FALSE]
ssb_1974 <- outputs[outputs$measure == "SSB" & outputs$year == 1974L, , drop = FALSE]
ssb_2019 <- outputs[outputs$measure == "SSB" & outputs$year == 2019L, , drop = FALSE]
f_2018_age25 <- outputs[outputs$measure == "fishing_mortality_at_age" &
  outputs$year == 2018L & outputs$age == 25L, , drop = FALSE]
bmsy <- outputs[outputs$measure == "Bmsy", , drop = FALSE]
mcb_bmsy <- bmsy[bmsy$scenario == "Monte Carlo/Bootstrap median", , drop = FALSE]
selectivity_age25 <- outputs[outputs$measure == "fleet_selectivity_at_age" &
  !is.na(outputs$survey) & outputs$survey == "MARMAP chevron trap" &
  outputs$age == 25L, , drop = FALSE]
yield85 <- outputs[outputs$measure == "yield_at_85_percent_Fmsy" &
  outputs$scenario == "Monte Carlo/Bootstrap median", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10339",
  stock$scientific_name == "Epinephelus niveatus",
  stock$area == "South Atlantic Coast",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2018L,
  assessment$estimate_terminal_year == 2019L,
  assessment$model_family == "Beaufort Assessment Model",
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(assumptions) == 11L,
  nrow(inputs) == 687L,
  nrow(outputs) == 6877L,
  nrow(weight_age1) == 1L,
  weight_age1$value == 0.76,
  weight_age1$unit == "kg/fish whole weight",
  nrow(m_age25) == 1L,
  m_age25$value == 0.071,
  nrow(catch_ch_1974) == 1L,
  catch_ch_1974$value == 187.166,
  catch_ch_1974$unit == "1,000 lb whole weight",
  nrow(catch_cl_1974) == 0L,
  nrow(headboat_1978) == 1L,
  headboat_1978$value == 1.58,
  nrow(headboat_cv_1978) == 1L,
  headboat_cv_1978$value == 0.25,
  nrow(chevron_age_n_1996) == 1L,
  chevron_age_n_1996$value == 58,
  nrow(nage_1974_age1) == 1L,
  nage_1974_age1$value == 209.84,
  total_n_1974$value == 705.83,
  recruitment_1974$value == nage_1974_age1$value,
  nage_2019_age1$value == 195.93,
  nage_2019_age1$scenario == "2019 assessment projection",
  nrow(ssb_1974) == 1L,
  ssb_1974$value == 883,
  ssb_1974$unit == "metric tons",
  nrow(ssb_2019) == 0L,
  nrow(f_2018_age25) == 1L,
  f_2018_age25$value == 0.119,
  f_2018_age25$age_group == "25+",
  nrow(bmsy[bmsy$scenario == "base-run estimate", , drop = FALSE]) == 1L,
  bmsy$value[bmsy$scenario == "base-run estimate"] == 3237.6,
  mcb_bmsy$value == 3400.9,
  mcb_bmsy$se == 6682.9,
  nrow(selectivity_age25) == 1L,
  selectivity_age25$year == 2018L,
  selectivity_age25$age_group == "25+",
  yield85$value == 529.0,
  yield85$se == 708.5,
  is.na(yield85$year),
  nrow(inputs[inputs$measure %in% c("proportion_at_age", "frequency_at_age",
    "landings_numbers_at_age", "landings_weight_at_age"), , drop = FALSE]) == 0L,
  all(is.na(outputs$se[is.na(outputs$scenario) |
    outputs$scenario != "Monte Carlo/Bootstrap median"])),
  all(outputs$scenario[!is.na(outputs$year) & outputs$year == 2019L] ==
    "2019 assessment projection"),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(inventory_row) == 1L,
  inventory_row$matched_stock_id == stock_id,
  inventory_row$import_status == "partial",
  nrow(manifest) == 3L,
  !anyDuplicated(manifest$file),
  all(grepl("^source_cache/noaa_snowy_grouper_sedar36u_2021/", manifest$file)),
  all(grepl("^2026-11-10T", manifest$retrieved_utc)),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(file.exists(manifest$file)),
  all(tolower(unname(tools::sha256sum(manifest$file))) == tolower(manifest$sha256)),
  grepl("no values were digitized or reconstructed", review, ignore.case = TRUE),
  grepl("Tables 6–16", review, fixed = TRUE)
)

cat("NOAA South Atlantic snowy grouper SEDAR 36 Update source values, dimensions, partial status, uncertainty and provenance passed.\n")
