source("R/read_database.R")
x <- read_assessment("afma_bight_redfish_gab_2022")

stopifnot(
  x$stocks$authority == "AFMA",
  x$stocks$scientific_name == "Centroberyx gerrardi",
  x$stocks$authority_stock_id == "SESSF Great Australian Bight Trawl Sector, Zone 80",
  x$stocks$ocean == "Southern Ocean",
  x$assessment$assessment_year == 2022L,
  x$assessment$terminal_year == 2022L,
  x$assessment$estimate_terminal_year == 2024L,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$model_family == "Stock Synthesis",
  x$assessment$model_version == "3.30.19.01",
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

i <- x$inputs
stopifnot(
  nrow(i) == 235L,
  sum(i$type == "catch" & i$measure == "landings_biomass") == 34L,
  sum(i$type == "index" & i$measure == "relative_biomass_index" & i$fleet == "Trawl", na.rm = TRUE) == 35L,
  sum(i$type == "index" & i$measure == "relative_biomass_index" & i$survey == "GAB Fishery Independent Survey", na.rm = TRUE) == 9L,
  sum(i$measure == "biomass_index_cv") == 9L,
  sum(i$measure == "ageing_error_sd") == 65L,
  sum(i$measure == "composition_sample_count" & grepl("^LENGTH_SAMPLE_", i$observation_id)) == 53L,
  sum(i$measure == "composition_sample_count" & grepl("^AGE_SAMPLE_", i$observation_id)) == 30L,
  !any(i$measure %in% c("numbers_at_age", "frequency_at_age", "conditional_proportion_at_age", "weight_at_age", "maturity_at_age"))
)

catch <- i[i$type == "catch" & i$measure == "landings_biomass", ]
cpue <- i[i$type == "index" & i$measure == "relative_biomass_index" & !is.na(i$fleet) & i$fleet == "Trawl", ]
fis <- i[!is.na(i$survey) & i$survey == "GAB Fishery Independent Survey" & i$measure == "relative_biomass_index", ]
fis_cv <- i[!is.na(i$survey) & i$survey == "GAB Fishery Independent Survey" & i$measure == "biomass_index_cv", ]
age_error <- i[i$measure == "ageing_error_sd", ]
age_samples <- i[i$measure == "composition_sample_count" & grepl("^AGE_SAMPLE_", i$observation_id), ]
length_samples <- i[i$measure == "composition_sample_count" & grepl("^LENGTH_SAMPLE_", i$observation_id), ]

stopifnot(
  setequal(catch$year, 1988:2021),
  catch$value[catch$year == 1988] == 94.65,
  catch$value[catch$year == 2004] == 951.95,
  catch$value[catch$year == 2021] == 262.49,
  all(catch$source_type == "official_table"),
  all(grepl("Total WA catch", catch$transformation, fixed = TRUE)),
  setequal(cpue$year, 1987:2021),
  cpue$value[cpue$year == 1987] == 2.58,
  cpue$value[cpue$year == 2021] == 0.68,
  fis$value[fis$year == 2004] == 20887,
  fis$value[fis$year == 2021] == 3447,
  fis_cv$value[fis_cv$year == 2021] == 0.2111,
  setequal(age_error$age, 0:64),
  age_error$value[age_error$age == 0] == 0.04133,
  age_error$value[age_error$age == 64] == 2.64503,
  age_samples$value[age_samples$year == 2021 & age_samples$fleet == "Trawl"] == 169,
  any(length_samples$value == 0)
)

wa_component <- c(9, 1, 8, 9, 35, 34, 17, 11, 6, 6, 8, 7, 8, 4, 8, 11,
  11, 9, 17, 20, 21, 15, 17, 13, 23, 30, 18, 28, 30, 21, 41, 39)
stopifnot(sum(wa_component) == 535)

o <- x$outputs
stopifnot(
  nrow(o) == 10L,
  o$value[o$measure == "unfished_spawning_biomass"] == 4535,
  o$value[o$measure == "SSB_ratio_to_B0"] == 0.67,
  o$year[o$measure == "SSB_ratio_to_B0"] == 2023L,
  o$value[o$measure == "natural_mortality_average_parameter"] == 0.1049,
  o$lwr[o$measure == "natural_mortality_average_parameter"] == 0.091,
  o$upr[o$measure == "natural_mortality_average_parameter"] == 0.107,
  o$value[o$measure == "catch_advice"] == 1056,
  o$year[o$measure == "catch_advice"] == 2023L,
  all(is.na(o$se))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- candidate[candidate$candidate_id == "AFMA:SESSF_GABTF_Bight_Redfish", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("catch numbers-at-age", candidate$catch_age_evidence, fixed = TRUE)
)

manifest <- read.csv("provenance/afma_bight_redfish_gab_2022/manifest.csv", stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 2L,
  setequal(basename(manifest$local_file), c(
    "stock-assessment-for-bight-redfish-tier-1-2022.pdf",
    "SESSF-Species-Summaries-2026.pdf"
  )),
  setequal(toupper(manifest$sha256), c(
    "39C0DB74FC36AD2BDF6839A77BE9597C1398D3FB8B99943ABABA8E65AAE3EBD5",
    "17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3"
  ))
)

cat("AFMA Bight Redfish 2022 source checks passed.\n")