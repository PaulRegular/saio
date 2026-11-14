source("R/read_database.R")
x <- read_assessment("noaa_northern_rockfish_bsai_2023")
i <- x$inputs
o <- x$outputs

stopifnot(
  x$stocks$authority == "NOAA",
  x$stocks$authority_stock_id == "10416",
  x$stocks$scientific_name == "Sebastes polyspinis",
  x$stocks$ocean == "Northeast Pacific",
  x$assessment$assessment_year == 2023L,
  x$assessment$terminal_year == 2023L,
  x$assessment$model_version == "Model 21 (2023)",
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

catch <- i[i$type == "catch" & i$measure == "catch_biomass", ]
survey <- i[i$type == "index" & i$measure == "total_biomass", ]
survey_cv <- i[i$type == "index" & i$measure == "biomass_index_cv", ]
fish_comp <- i[i$type == "catch" & i$measure == "proportion_at_age", ]
survey_comp <- i[i$type == "index" & i$measure == "proportion_at_age", ]
fish_samples <- i[i$measure == "composition_sample_count" & !is.na(i$fleet) & i$fleet == "BSAI fishery", ]
survey_samples <- i[i$measure == "composition_sample_count" & !is.na(i$survey) & i$survey == "Aleutian Islands bottom trawl survey", ]

stopifnot(
  nrow(catch) == 47L, setequal(catch$year, 1977:2023),
  catch$value[catch$year == 2023] == 9948,
  nrow(survey) == 13L, setequal(survey$year, c(1991L, 1994L, 1997L,
    2000L, 2002L, 2004L, 2006L, 2010L, 2012L, 2014L, 2016L, 2018L, 2022L)),
  nrow(survey_cv) == 13L, survey_cv$value[survey_cv$year == 2022] == 0.23,
  !any(i$year %in% c(1980L, 1983L, 1986L) & i$measure %in% c("total_biomass", "biomass_index_cv")),
  nrow(fish_comp) == 646L, nrow(survey_comp) == 494L,
  setequal(unique(fish_comp$age), 3:40),
  setequal(unique(survey_comp$age), 3:40),
  all(fish_comp$sample_size > 0), all(survey_comp$sample_size > 0),
  all(abs(tapply(fish_comp$value, fish_comp$observation_id, sum) - 1) <= 0.021),
  all(abs(tapply(survey_comp$value, survey_comp$observation_id, sum) - 1) <= 0.021),
  nrow(fish_samples) == 17L, nrow(survey_samples) == 13L,
  all(grepl("not renormalized", fish_comp$notes, fixed = TRUE)),
  grepl("40+ group", fish_comp$notes[fish_comp$age == 40], fixed = TRUE)
)

n <- o[o$measure == "numbers_at_age", ]
abundance <- o[o$measure == "total_numbers", ]
ssb <- o[o$measure == "SSB", ]
biomass <- o[o$measure == "total_biomass", ]
recruitment <- o[o$measure == "recruitment", ]
m <- o[o$measure == "natural_mortality_average_parameter", ]
log_f <- o[o$measure == "log_avg_fmort", ]
maturity <- o[o$measure == "maturity_at_age", ]

expected_abundance <- aggregate(value ~ year, n, sum)
actual_abundance <- abundance[match(expected_abundance$year, abundance$year), ]
stopifnot(
  nrow(n) == 47L * 38L,
  identical(sort(unique(n$age)), 3:40),
  all(n$age_group[n$age == 40] == "40+"),
  nrow(abundance) == 47L,
  max(abs(expected_abundance$value - actual_abundance$value)) < 1e-8,
  nrow(ssb) == 48L, ssb$value[ssb$year == 2024] == 128229,
  ssb$scenario[ssb$year == 2024] == "2024 projection",
  biomass$value[biomass$year == 2024] == 297189,
  max(recruitment$year, na.rm = TRUE) == 2020L,
  m$value == 0.0523, m$se == 0.0044,
  log_f$value == -4.8491, log_f$se == 0.0754,
  nrow(maturity) == 38L, all(is.na(maturity$year)),
  sum(o$measure == "fishing_mortality_at_age") == 0L
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10416", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "noaa_northern_rockfish_bsai",
  candidate$import_status == "partial",
  candidate$detailed_source_url == "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAInork.pdf"
)



