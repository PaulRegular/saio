read_table <- function(name) {
  read.csv(file.path("database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stock <- subset(read_table("stocks"), stock_id == "mpi_sbw_sbw6i")
assessment <- subset(read_table("assessments"),
  assessment_id == "mpi_sbw_sbw6i_2024")
assumptions <- subset(read_table("assumptions"),
  assessment_id == "mpi_sbw_sbw6i_2024")
inputs <- subset(read_table("inputs"), assessment_id == "mpi_sbw_sbw6i_2024")
outputs <- subset(read_table("outputs"), assessment_id == "mpi_sbw_sbw6i_2024")

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
index <- subset(inputs, type == "index" & measure == "total_biomass")
index_cv <- subset(inputs, type == "index" & measure == "biomass_index_cv")
expected_survey_years <- c(1993L, 1994L, 1995L, 1998L, 2000L, 2002L, 2004L,
  2006L, 2009L, 2011L, 2013L, 2016L, 2019L, 2022L)
index_key <- paste(index$survey, index$year, sep = "|")
index_cv_key <- paste(index_cv$survey, index_cv$year, sep = "|")

stopifnot(
  nrow(stock) == 1L,
  is.na(stock$charbonneau_id) || stock$charbonneau_id == "",
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "SBW 6I",
  stock$scientific_name == "Micromesistius australis",
  stock$area == "Campbell Island Rise",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2022L,
  assessment$estimate_terminal_year == 2022L,
  assessment$model_family == "Casal2",
  assessment$is_current,
  assessment$is_applied,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 21L,
  any(assumptions$setting == "natural_mortality" & assumptions$value == "0.20 per year, fixed in the Base run"),
  nrow(catch) == 52L,
  identical(sort(unique(as.integer(catch$year))), c(1971:1998, 2000:2022)),
  sum(as.integer(catch$year) == 1978L) == 2L,
  catch$value[catch$year == 1971L] == 7260,
  catch$value[catch$year == 2022L] == 22985,
  all(catch$unit == "tonnes"),
  grepl("2022-23", catch$observation_id[catch$year == 2022L], fixed = TRUE),
  any(grepl("1978-79", catch$observation_id[catch$year == 1978L], fixed = TRUE)),
  nrow(index) == 28L,
  identical(sort(unique(as.integer(index$year))), expected_survey_years),
  length(unique(index$survey)) == 2L,
  all(index$unit == "tonnes"),
  index$value[index$year == 2022L & grepl(" acoustic immature biomass$", index$survey)] == 5356,
  index$value[index$year == 2022L & grepl(" acoustic mature biomass$", index$survey)] == 91968,
  nrow(index_cv) == 28L,
  setequal(index_key, index_cv_key),
  all(index_cv$basis == "relative_scale"),
  all(index_cv$unit == "ratio"),
  index_cv$value[index_cv$year == 2022L & grepl(" acoustic immature biomass$", index_cv$survey)] == 0.22,
  index_cv$value[index_cv$year == 2022L & grepl(" acoustic mature biomass$", index_cv$survey)] == 0.20,
  !any(inputs$measure %in% c("numbers_at_age", "proportion_at_age", "weight_at_age", "maturity_at_age")),
  nrow(outputs) == 6L,
  outputs$value[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base_MPD"] == 308,
  outputs$value[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base_MCMC"] == 323,
  outputs$lwr[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base_MCMC"] == 292,
  outputs$upr[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base_MCMC"] == 369,
  outputs$value[outputs$measure == "SSB_ratio_to_B0" & outputs$scenario == "Base_MCMC"] == 63,
  outputs$unit[outputs$measure == "SSB_ratio_to_B0"] == "percent of B0",
  outputs$value[outputs$type == "catchability" & grepl(" immature biomass$", outputs$survey)] == 0.23,
  outputs$value[outputs$type == "catchability" & grepl(" mature biomass$", outputs$survey)] == 0.41,
  all(nzchar(inputs$source_reference)),
  all(nzchar(outputs$source_reference))
)

candidate <- subset(read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE), candidate_id == "MPI:SBW6I")
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_sbw_sbw6i",
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  candidate$eligibility == "unresolved"
)

cat("SBW 6I imported source records and reported values checks passed.\n")
