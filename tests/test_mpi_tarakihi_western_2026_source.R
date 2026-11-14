source("R/read_database.R")

database <- read_database()
western <- read_assessment("mpi_tarakihi_western_2026", database)
inputs <- western$inputs

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
composition <- subset(inputs, measure == "proportion_at_age")
maturity <- subset(inputs, type == "maturity" & measure == "maturity_at_age")
wcni_cpue <- subset(inputs, measure == "relative_abundance_index")
wcni_cpue_cv <- subset(inputs, measure == "abundance_index_cv" & fleet == "WCNI commercial trawl fishery")
tbgb_age1 <- subset(inputs, type == "index" & measure == "numbers_at_age" & age == 1)
tbgb_age1_cv <- subset(inputs, type == "index" & measure == "numbers_at_age_cv" & age == 1)
outputs <- western$outputs

stopifnot(
  western$stocks$stock_id == "mpi_tarakihi_western",
  western$stocks$authority_stock_id == "TAR 8 and western portions of TAR 1 and TAR 7",
  western$stocks$ocean == "Southwest Pacific",
  western$assessment$assessment_year == 2026L,
  western$assessment$terminal_year == 2025L,
  western$assessment$model_family == "Stock Synthesis",
  all(western$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 2511L,
  nrow(catch) == 376L,
  setequal(catch$year, 1932:2025),
  length(unique(catch$fleet)) == 4L,
  all(catch$unit == "tonnes"),
  nrow(subset(inputs, type == "catch" & measure == "numbers_at_age")) == 0L,
  nrow(subset(inputs, type == "weight" & measure == "weight_at_age")) == 0L,
  nrow(subset(inputs, type == "M" & measure == "natural_mortality_at_age")) == 0L,
  nrow(composition) == 1980L,
  length(unique(composition$observation_id)) == 33L,
  setequal(composition$age, 1:30),
  setequal(composition$sex, c("female", "male")),
  all(composition$value >= 0 & composition$value <= 1),
  all(composition$sample_size[!grepl("^WCSI survey_", composition$observation_id)] == 20),
  all(is.na(composition$sample_size[grepl("^WCSI survey_", composition$observation_id)])),
  composition$value[composition$observation_id == "WCSI commercial_2005" &
    composition$age == 3 & composition$sex == "female"] == 0.0027,
  abs(sum(composition$value[composition$observation_id == "WCSI commercial_2005"]) - 0.9919) < 1e-8,
  all(grepl("without normalization", composition$notes, fixed = TRUE)),
  nrow(maturity) == 10L,
  identical(maturity$value[order(maturity$age)], c(0, 0.03, 0.06, 0.14, 0.27, 0.47, 0.68, 0.84, 0.92, 1)),
  grepl("Age 10 represents 10+", maturity$notes[maturity$age == 10], fixed = TRUE),
  nrow(subset(inputs, type == "index" & measure == "total_biomass" & survey == "Kaharoa WCSI trawl survey")) == 17L,
  nrow(subset(inputs, type == "index" & measure == "total_biomass" & survey == "Kaharoa WCNI trawl survey")) == 7L,
  nrow(tbgb_age1) == 17L,
  nrow(tbgb_age1_cv) == 16L,
  tbgb_age1$value[tbgb_age1$year == 2023L] == 0,
  !any(tbgb_age1_cv$year == 2023L),
  nrow(wcni_cpue) == 32L,
  nrow(wcni_cpue_cv) == 32L,
  wcni_cpue$value[wcni_cpue$year == 1994L] == 0.307,
  abs(wcni_cpue_cv$value[wcni_cpue_cv$year == 1994L] -
    sqrt(exp(((log(0.428) - log(0.208)) / (2 * 1.96))^2) - 1)) < 1e-10,
  all(is.na(inputs$sampling_time[inputs$type == "index"])),
  nrow(outputs) == 10L,
  outputs$value[outputs$measure == "SSB"] == 4419,
  outputs$lwr[outputs$measure == "SSB"] == 3170,
  outputs$upr[outputs$measure == "SSB"] == 5986,
  outputs$value[outputs$measure == "unfished_spawning_biomass"] == 15284,
  outputs$value[outputs$measure == "F_ratio_to_FSB40"] == 1.599,
  outputs$value[outputs$measure == "yield_at_FSB40"] == 714,
  any(grepl("double-normal", western$assumptions$value, fixed = TRUE)),
  any(grepl("0.10 per year, fixed for both sexes", western$assumptions$value, fixed = TRUE))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:TAR:WESTERN")
sources <- read.csv("provenance/mpi_tarakihi_western_2026_sources.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_tarakihi_western",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(sources) == 1L,
  sources$sha256 == "9B7DCD75AF96DF146D1F12C838752D9904A331623C6609BED3B8B042BDD85698",
  file.exists(sources$local_file),
  toupper(unname(tools::sha256sum(sources$local_file))) == sources$sha256
)

cat("Western tarakihi source inputs, unchanged composition cells, outputs, assumptions, and provenance passed.\n")
