source("R/read_database.R")

database <- read_database()
eastern <- read_assessment("mpi_tarakihi_eastern_2026", database)
inputs <- eastern$inputs
catch <- subset(inputs, type == "catch" & measure == "total_biomass")
composition <- subset(inputs, measure == "proportion_at_age")
maturity <- subset(inputs, type == "maturity" & measure == "maturity_at_age")
biomass_index <- subset(inputs, type == "index" & measure == "total_biomass")
age2_index <- subset(inputs, type == "index" & measure == "numbers_at_age")
cpue <- subset(inputs, measure == "relative_abundance_index")
cpue_cv <- subset(inputs, measure == "abundance_index_cv")

stopifnot(
  eastern$stocks$stock_id == "mpi_tarakihi_eastern",
  eastern$stocks$authority_stock_id == "TAR 3, TAR 2, and eastern portions of TAR 1 and TAR 7",
  eastern$stocks$ocean == "Southwest Pacific",
  eastern$assessment$assessment_year == 2026L,
  eastern$assessment$terminal_year == 2025L,
  eastern$assessment$model_family == "Stock Synthesis",
  all(eastern$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 2364L,
  nrow(catch) == 752L,
  setequal(catch$year, 1932:2025),
  length(unique(catch$fleet)) == 8L,
  all(catch$unit == "tonnes"),
  catch$value[catch$year == 2025L & catch$fleet == "ECSI commercial trawl fishery"] == 585,
  catch$value[catch$year == 2025L & catch$fleet == "TAR 2 recreational fishery"] == 44,
  nrow(subset(inputs, type == "catch" & measure == "numbers_at_age")) == 0L,
  nrow(subset(inputs, type == "weight" & measure == "weight_at_age")) == 0L,
  nrow(composition) == 1410L,
  length(unique(composition$observation_id)) == 47L,
  setequal(composition$age, 1:30),
  all(composition$sex == "both"),
  all(composition$value >= 0 & composition$value <= 1),
  composition$value[composition$observation_id == "ECSI winter survey_2007" & composition$age == 2L] == 0.1765,
  composition$value[composition$observation_id == "ENLD fishery_2014" & composition$age == 4L] == 0.0080,
  composition$sample_size[composition$observation_id == "ENLD fishery_2014"] == 15,
  abs(sum(composition$value[composition$observation_id == "BPLE fishery_2008"]) - 1.9999) < 1e-8,
  all(grepl("were not normalized", composition$notes, fixed = TRUE)),
  nrow(maturity) == 6L,
  identical(maturity$value[order(maturity$age)], c(0, 0, 0, 0.25, 0.5, 1)),
  grepl("Age 6 represents ages 6+", maturity$notes[maturity$age == 6L], fixed = TRUE),
  nrow(biomass_index) == 20L,
  sum(grepl("winter", biomass_index$survey)) == 15L,
  sum(grepl("summer", biomass_index$survey)) == 5L,
  biomass_index$value[biomass_index$year == 2024L & grepl("winter", biomass_index$survey)] == 617,
  biomass_index$value[biomass_index$year == 2001L & grepl("summer", biomass_index$survey)] == 1510,
  nrow(age2_index) == 10L,
  age2_index$value[age2_index$year == 2024L] == 33,
  age2_index$unit[age2_index$year == 2024L] == "survey index units (scale not specified)",
  nrow(cpue) == 136L,
  nrow(cpue_cv) == 0L,
  length(unique(cpue$fleet)) == 5L,
  !any(grepl("ECSI", cpue$fleet)),
  cpue$value[cpue$year == 1994L & cpue$fleet == "ENLD commercial trawl fishery"] == 0.855,
  grepl("0.524 to 1.223", cpue$notes[cpue$year == 1994L & cpue$fleet == "ENLD commercial trawl fishery"], fixed = TRUE),
  any(grepl("ENLD 0.30; BPLE 0.27-0.34", eastern$assumptions$value, fixed = TRUE)),
  all(is.na(inputs$sampling_time[inputs$type == "index"]))
)

outputs <- eastern$outputs
stopifnot(
  nrow(outputs) == 22L,
  outputs$value[outputs$measure == "SSB"] == 5403,
  outputs$lwr[outputs$measure == "SSB"] == 4398,
  outputs$upr[outputs$measure == "SSB"] == 6466,
  outputs$value[outputs$measure == "unfished_spawning_biomass"] == 69831,
  outputs$value[outputs$measure == "F_reference_at_SB40"] == 0.065,
  is.na(outputs$year[outputs$measure == "F_reference_at_SB40"]),
  outputs$value[outputs$measure == "F_ratio_to_FSB40"] == 2.62,
  outputs$value[outputs$measure == "yield_at_FSB40"] == 881,
  is.na(outputs$year[outputs$measure == "yield_at_FSB40"]),
  outputs$value[outputs$measure == "SSB_ratio_to_B0" & !is.na(outputs$scenario) & outputs$scenario == "FSB40%"] == 0.123,
  outputs$lwr[outputs$measure == "SSB_ratio_to_B0" & !is.na(outputs$scenario) & outputs$scenario == "TACC"] == 0.036,
  all(grepl("95%", outputs$notes)),
  any(grepl("Age-dependent movement", eastern$assumptions$value, fixed = TRUE)),
  any(grepl("1980-2023", eastern$assumptions$value, fixed = TRUE)),
  any(grepl("fixed for both sexes", eastern$assumptions$value, fixed = TRUE))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:TAR:EASTERN")
sources <- read.csv("provenance/mpi_tarakihi_eastern_2026_sources.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_tarakihi_eastern",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(sources) == 1L,
  sources$sha256 == "20F9D9B6430AD975C095F4F652B4C4AD9AF84D991651D0BE13C4C5F5827051CF",
  file.exists(sources$local_file),
  toupper(unname(tools::sha256sum(sources$local_file))) == sources$sha256
)

cat("Eastern tarakihi source inputs, composition cells, official outputs, assumptions, and provenance passed.\n")
