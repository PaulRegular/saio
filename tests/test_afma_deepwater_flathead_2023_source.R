source("R/read_database.R")
x <- read_assessment("afma_deepwater_flathead_gab_2023")

stopifnot(
  x$stocks$authority == "AFMA",
  x$stocks$scientific_name == "Neoplatycephalus conatus",
  x$stocks$area == "Great Australian Bight Trawl Sector, Southern and Eastern Scalefish and Shark Fishery",
  x$stocks$ocean == "Southern Ocean",
  x$assessment$assessment_year == 2023L,
  x$assessment$terminal_year == 2023L,
  x$assessment$estimate_terminal_year == 2024L,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$model_family == "Stock Synthesis",
  x$assessment$model_version == "3.30.21.00",
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial")
)

i <- x$inputs
stopifnot(
  nrow(i) == 200L,
  sum(i$type == "catch" & i$measure == "landings_biomass") == 48L,
  sum(i$type == "index" & i$measure == "relative_biomass_index" & i$fleet == "Trawl", na.rm = TRUE) == 35L,
  sum(i$type == "index" & i$measure == "relative_biomass_index" & i$survey == "GAB Fishery Independent Survey (GABFIS)", na.rm = TRUE) == 9L,
  sum(i$measure == "biomass_index_cv") == 9L,
  sum(i$measure == "ageing_error_sd") == 60L,
  sum(i$measure == "composition_sample_count") == 39L,
  !any(i$measure %in% c("numbers_at_age", "frequency_at_age", "conditional_proportion_at_age")),
  !any(i$measure %in% c("weight_at_age", "spawning_weight_at_age", "maturity_at_age"))
)

fisheries_catch <- i[i$type == "catch" & i$measure == "landings_biomass", ]
trawl_catch <- fisheries_catch[fisheries_catch$fleet == "Trawl", ]
ds_catch <- fisheries_catch[fisheries_catch$fleet == "Danish seine", ]
fis <- i[!is.na(i$survey) & i$survey == "GAB Fishery Independent Survey (GABFIS)" &
  i$measure == "relative_biomass_index", ]
fis_cv <- i[i$measure == "biomass_index_cv", ]
reader1 <- i[i$measure == "ageing_error_sd" & !is.na(i$age_error) & i$age_error == "Reader 1", ]
reader2 <- i[i$measure == "ageing_error_sd" & !is.na(i$age_error) & i$age_error == "Reader 2", ]
stopifnot(
  nrow(trawl_catch) == 35L,
  min(trawl_catch$year) == 1988L,
  max(trawl_catch$year) == 2022L,
  trawl_catch$value[trawl_catch$year == 1988] == 312,
  trawl_catch$value[trawl_catch$year == 2022] == 565,
  nrow(ds_catch) == 13L,
  ds_catch$value[ds_catch$year == 2010] == 5,
  ds_catch$value[ds_catch$year == 2022] == 111,
  nrow(fis) == 9L,
  fis$value[fis$year == 2004] == 12152,
  fis$value[fis$year == 2020] == 5225,
  setequal(fis$observation_id, fis_cv$observation_id),
  fis_cv$value[fis_cv$year == 2020] == 0.08,
  all(reader1$age == 0:29),
  all(reader2$age == 0:29),
  reader1$value[reader1$age == 0] == 0.229109,
  reader2$value[reader2$age == 29] == 0.724528,
  all(i$year_basis[!is.na(i$year)] == "model_year")
)

o <- x$outputs
stopifnot(
  nrow(o) == 8L,
  o$value[o$measure == "unfished_spawning_biomass"] == 9918,
  o$value[o$measure == "spawning_biomass"] == 4413,
  o$value[o$measure == "SSB_ratio_to_B0"] == 0.44,
  o$value[o$measure == "natural_mortality_average_parameter"] == 0.24,
  identical(o$value[o$measure == "catch_advice"], c(1220, 1211, 1204, 1200)),
  identical(o$year[o$measure == "catch_advice"], 2024:2027),
  all(is.na(o$se)),
  all(is.na(o$lwr)),
  all(is.na(o$upr))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- candidate[candidate$candidate_id == "AFMA:SESSF_GABTF_Deepwater_Flathead", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("age-at-length", candidate$catch_age_evidence, fixed = TRUE)
)

manifest <- read.csv("provenance/afma_deepwater_flathead_gab_2023/manifest.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 2L,
  setequal(basename(manifest$local_file), c(
    "stock-assessment-for-deepwater-flathead-2023.pdf",
    "SESSF-Species-Summaries-2026.pdf"
  )),
  all(nchar(manifest$sha256) == 64L)
)

cat("AFMA Deepwater Flathead 2023 source checks passed.\n")