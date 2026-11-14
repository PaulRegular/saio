source("R/read_database.R")
x <- read_assessment("mpi_orh7a_2024")
i <- x$inputs
o <- x$outputs
catch <- subset(i, type == "catch" & measure == "total_biomass")
index <- subset(i, type == "index" & measure == "total_biomass")
cv <- subset(i, type == "index" & measure == "biomass_index_cv")
age <- subset(i, type == "index" & measure == "proportion_at_age")

stopifnot(
  x$stocks$stock_id == "mpi_orh7a_challenger",
  x$stocks$authority == "Fisheries New Zealand",
  x$stocks$authority_stock_id == "ORH 7A",
  x$stocks$scientific_name == "Hoplostethus atlanticus",
  x$stocks$ocean == "Southwest Pacific",
  x$assessment$assessment_year == 2024L,
  x$assessment$terminal_year == 2024L,
  x$assessment$model_family == "CASAL",
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$assumptions_status == "complete",
  x$assessment$inputs_status == "complete",
  x$assessment$outputs_status == "partial",
  nrow(i) == 576L,
  nrow(catch) == 44L,
  identical(sort(catch$year), 1981:2024),
  catch$value[catch$year == 1981L] == 43,
  catch$value[catch$year == 2024L] == 1860,
  all(catch$unit == "tonnes"),
  all(catch$year_basis == "model_year"),
  nrow(index) == 8L,
  sum(grepl("Thomas Harrison", index$survey)) == 6L,
  setequal(index$year[grepl("acoustic", index$survey)], c(2009L, 2013L)),
  !any(index$year == 2023L),
  nrow(cv) == 8L,
  all(vapply(seq_len(nrow(index)), function(k) {
    sum(cv$survey == index$survey[k] & cv$year == index$year[k]) == 1L
  }, logical(1))),
  nrow(age) == 516L,
  length(unique(age$observation_id)) == 6L,
  setequal(age$age, 15:100),
  all(age$value >= 0 & age$value <= 1),
  all(age$sample_size[age$year != 2018L | grepl("Thomas Harrison", age$survey)] == 10),
  unique(age$sample_size[age$year == 2018L & grepl("Volcano", age$survey)]) == 5,
  all(vapply(split(age$value, age$observation_id), function(z) {
    length(z) == 86L && abs(sum(z) - 1) < 0.005
  }, logical(1))),
  nrow(subset(i, type == "catch" & measure %in% c("numbers_at_age", "proportion_at_age"))) == 0L,
  nrow(o) == 21L,
  setequal(o$scenario, c("All2 (base)", "All6", "3Series")),
  all(is.na(o$se)),
  all(grepl("95% credible interval", o$notes, fixed = TRUE)[
    o$measure %in% c("natural_mortality_average_parameter",
      "unfished_spawning_biomass", "SSB_ratio_to_B0")
  ]),
  nrow(subset(o, measure == "natural_mortality_average_parameter")) == 3L,
  nrow(subset(o, measure == "unfished_spawning_biomass")) == 3L,
  nrow(subset(o, measure == "SSB_ratio_to_B0")) == 3L,
  setequal(unique(o$measure[grepl("^probability_", o$measure)]), c(
    "probability_above_50_percent_B0", "probability_above_30_percent_B0",
    "probability_below_20_percent_B0", "probability_below_10_percent_B0"
  )),
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age"))
)

all2_ssb <- subset(o, measure == "SSB_ratio_to_B0" & scenario == "All2 (base)")
stopifnot(
  all2_ssb$year == 2024L,
  all2_ssb$value == 35,
  all2_ssb$lwr == 16,
  all2_ssb$upr == 57,
  subset(o, measure == "natural_mortality_average_parameter" &
    scenario == "All2 (base)")$value == 0.033
)

assumptions <- x$assumptions
stopifnot(
  any(assumptions$setting == "observation_timing" &
    grepl("does not define a fraction of the calendar year", assumptions$notes, fixed = TRUE)),
  any(assumptions$setting == "acoustic_base_case" &
    grepl("2009 and 2013", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "age_frequency_likelihood" &
    grepl("No commercial age frequencies", assumptions$notes, fixed = TRUE))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:ORH7A")
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_orh7a_challenger",
  candidate$eligibility == "ineligible",
  candidate$import_status == "partial",
  grepl("no catch-at-age", candidate$decision_reason, fixed = TRUE)
)

manifest <- read.csv("provenance/mpi_orh7a_2024_sources.csv", stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 3L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(manifest$retrieved_on == "2026-11-05"),
  all(grepl("mpi_orange_roughy_orh7a_2024", manifest$local_file, fixed = TRUE))
)

cat("ORH 7A 2024 source checks passed.\n")
