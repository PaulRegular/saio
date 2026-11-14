source("R/read_database.R")

database <- read_database()
gemfish <- read_assessment("mpi_gemfish_ski1_ski2_2023", database)

stopifnot(
  gemfish$stocks$stock_id == "mpi_gemfish_northern_ski1_ski2",
  gemfish$stocks$authority_stock_id == "SKI 1 + SKI 2",
  gemfish$stocks$ocean == "Southwest Pacific",
  gemfish$assessment$assessment_year == 2023L,
  gemfish$assessment$terminal_year == 2023L,
  gemfish$assessment$model_family == "Stock Synthesis",
  all(gemfish$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

catch <- subset(gemfish$inputs, type == "catch" & measure == "total_biomass")
index <- subset(gemfish$inputs, measure == "relative_abundance_index")
index_se <- subset(gemfish$inputs, measure == "index_sd")
composition <- subset(gemfish$inputs, measure == "proportion_at_age")

stopifnot(
  nrow(catch) == 592L,
  setequal(catch$year, 1950:2023),
  length(unique(catch$region)) == 2L,
  length(unique(catch$fleet)) == 2L,
  length(unique(catch$season)) == 2L,
  all(catch$unit == "tonnes"),
  nrow(index) == 33L,
  nrow(index_se) == 33L,
  setequal(index$year, 1990:2022),
  index$value[index$year == 1990L] == 2.320,
  index_se$value[index_se$year == 1990L] == 0.147,
  all(index$unit == "relative index units"),
  all(index_se$unit == "relative index units"),
  all(is.na(index$sampling_time)),
  nrow(composition) == 840L,
  length(unique(composition$observation_id)) == 28L,
  setequal(composition$age, 1:15),
  setequal(composition$sex, c("female", "male")),
  all(is.na(composition$sample_size)),
  sum(composition$value[composition$year == 2005L & composition$fleet ==
    "SKI 2 non-target trawl fishery" & composition$sex == "male"]) == 0.2532
)

composition_sums <- aggregate(value ~ observation_id, composition, sum)
stopifnot(nrow(composition_sums) == 28L, max(abs(composition_sums$value - 1)) <= 0.002)

catch_key <- c("region", "fleet", "season")
catch_2022 <- subset(catch, year == 2022L)
catch_2023 <- subset(catch, year == 2023L)
catch_2022 <- catch_2022[do.call(order, catch_2022[catch_key]), ]
catch_2023 <- catch_2023[do.call(order, catch_2023[catch_key]), ]
stopifnot(identical(catch_2023$value, catch_2022$value))

outputs <- gemfish$outputs
stopifnot(
  nrow(outputs) == 7L,
  outputs$value[outputs$measure == "SSB"] == 9401,
  outputs$lwr[outputs$measure == "SSB"] == 6312,
  outputs$upr[outputs$measure == "SSB"] == 14825,
  outputs$value[outputs$measure == "unfished_spawning_biomass"] == 9041,
  outputs$value[outputs$measure == "F_ratio_to_FSB40"] == 0.17
)

assumptions <- gemfish$assumptions
stopifnot(
  any(grepl("0.25 per year for both sexes", assumptions$value, fixed = TRUE)),
  any(grepl("A50=7.2 years", assumptions$value, fixed = TRUE)),
  any(grepl("individual observation values", assumptions$value, fixed = TRUE))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:SKI1+SKI2")
sources <- read.csv("provenance/mpi_gemfish_ski1_ski2_2023_sources.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_gemfish_northern_ski1_ski2",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(sources) == 3L,
  all(grepl("^[[:xdigit:]]{64}$", sources$sha256)),
  all(grepl("^https://fs\\.fish\\.govt\\.nz/", sources$source_url))
)

cat("Northern gemfish source inputs, output summaries, assumptions, and provenance passed.\n")
