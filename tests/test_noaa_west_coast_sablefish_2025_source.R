source("R/read_database.R")
x <- read_assessment("noaa_sablefish_pacific_coast_2025")
i <- x$inputs
o <- x$outputs

catch <- i[i$type == "catch" & i$measure == "total_biomass", ]
catch_sd <- i[i$type == "catch" & i$measure == "log_catch_sd", ]
indices <- i[i$type == "index" & i$measure == "total_biomass", ]
index_sd <- i[i$type == "index" & i$measure == "log_index_sd", ]
recruit_index <- i[i$type == "covariate" & i$measure == "environmental_covariate", ]
age_comp <- i[i$measure == "frequency_at_age", ]
length_comp <- i[i$measure == "frequency_at_length", ]
mature_weight <- i[i$measure == "mature_weight_at_age", ]
N <- o[o$measure == "numbers_at_age", ]
F <- o[o$measure == "fishing_mortality_at_age", ]
M <- o[o$measure == "natural_mortality_at_age", ]
SSB <- o[o$measure == "SSB", ]
recruits <- o[o$measure == "recruitment", ]
total_N <- o[o$measure == "total_numbers", ]

stopifnot(
  x$stocks$ocean == "Northeast Pacific",
  x$stocks$authority_stock_id == "10466",
  x$assessment$assessment_year == 2025,
  x$assessment$terminal_year == 2024,
  x$assessment$inputs_status == "partial",
  x$assessment$outputs_status == "partial",
  nrow(catch) == 620L,
  nrow(catch_sd) == 620L,
  all(catch$unit == "metric tons"),
  all(catch_sd$value == 0.01),
  all(catch_sd$basis == "log_scale"),
  nrow(indices) == 35L,
  nrow(index_sd) == 35L,
  length(unique(indices$survey)) == 4L,
  all(indices$sampling_time[indices$season == "July"] == 0.5),
  all(indices$sampling_time[indices$season == "August"] == 7 / 12),
  nrow(recruit_index) == 5L,
  all(recruit_index$survey == "Recruitment index"),
  nrow(age_comp) >= 273L * 51L,
  all(age_comp$age %in% 0:50),
  all(age_comp$sample_size > 0),
  nrow(length_comp) >= 57L * 37L,
  all(length_comp$sample_size > 0),
  nrow(mature_weight) == 35L * 2L * 31L,
  all(mature_weight$age %in% 0:30),
  any(mature_weight$year == -1890 & mature_weight$year_basis == "model_year"),
  !any(i$measure == "proportion_mature_at_age"),
  nrow(N) == 147L * 2L * 71L,
  nrow(F) == 147L * 6L * 2L * 71L,
  nrow(M) == 147L * 2L * 71L,
  nrow(SSB) == 147L,
  nrow(recruits) == 147L,
  nrow(total_N) == 147L,
  setequal(unique(N$sex), c("female", "male")),
  setequal(unique(F$fleet), c("Trawl", "Hook-and-line", "Pot",
    "Trawl discard", "Hook-and-line discard", "Pot discard")),
  abs(SSB$value[SSB$year == 2024] - 61504.7) < 0.1,
  SSB$lwr[SSB$year == 2025] == 59331,
  SSB$upr[SSB$year == 2025] == 89486,
  recruits$lwr[recruits$year == 2024] == 7603,
  recruits$upr[recruits$year == 2024] == 166077,
  abs(total_N$value[total_N$year == 2024] -
    sum(N$value[N$year == 2024])) < 1e-8,
  all(abs(M$value - 0.087777) < 1e-6),
  all(is.na(N$se) & is.na(N$lwr) & is.na(N$upr)),
  all(is.na(F$se) & is.na(F$lwr) & is.na(F$upr)),
  all(is.na(M$se) & is.na(M$lwr) & is.na(M$upr))
)

candidate <- read.csv("discovery/candidates.csv",
  stringsAsFactors = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10466", ]
stopifnot(nrow(candidate) == 1L, candidate$matched_stock_id == x$stocks$stock_id,
  candidate$import_status == "partial")
cat("NOAA West Coast Sablefish source values, coverage, units, provenance, and output surfaces passed.\n")