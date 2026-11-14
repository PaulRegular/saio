source("R/read_database.R")
source("tests/helper_inventory.R")

assessment_id <- "afma_himi_mackerel_icefish_2026"
x <- read_assessment(assessment_id)
inputs <- x$inputs
outputs <- x$outputs

cohort_density <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
weights <- inputs[inputs$type == "weight" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$type == "maturity" & inputs$measure == "maturity_at_age", ]
M <- inputs[inputs$type == "M" & inputs$measure == "natural_mortality_at_age", ]
catch <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", ]
survey_biomass <- outputs[outputs$type == "index" & outputs$measure == "total_biomass", ]
cohort_share <- outputs[outputs$measure == "biomass_by_age_group", ]
catch_advice <- outputs[outputs$measure == "catch_advice", ]
expected_density <- outputs[outputs$type == "index" & outputs$measure == "total_numbers", ]
expected_density_sum <- outputs[outputs$measure == "sum_expected_cohort_density", ]

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
progress <- read.csv("discovery/inventory_progress.csv", stringsAsFactors = FALSE)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE)
selected <- read.csv("discovery/selected_batch_07_2026.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
manifest <- read.csv("provenance/afma_himi_mackerel_icefish_2026_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
candidate <- candidates[candidates$candidate_id == "AFMA:HIMI_ICEFISH", , drop = FALSE]

check_inventory_accounting(candidates, progress, units)

stopifnot(
  nrow(x$stocks) == 1L,
  x$stocks$stock_id == "afma_himi_mackerel_icefish",
  x$stocks$authority_stock_id == "CCAMLR Division 58.5.2 (HIMI mackerel icefish)",
  x$stocks$ocean == "Southern Indian Ocean",
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2026L,
  x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(inputs) == 16L,
  all(as.numeric(cohort_density$age) == 1:4),
  identical(as.numeric(cohort_density$value), c(29, 185, 273, 612)),
  all(cohort_density$unit == "fish/km2"),
  all(cohort_density$year == 2026L),
  all(is.na(cohort_density$sampling_time)),
  grepl("SD = 1467", cohort_density$notes[cohort_density$age == 3], fixed = TRUE),
  identical(as.numeric(weights$value), c(0.022, 0.103, 0.218, 0.297)),
  all(as.numeric(maturity$age) == 1:3),
  all(as.numeric(maturity$value) == 1),
  all(as.numeric(M$age) == 1:3),
  all(as.numeric(M$value) == 0.4),
  nrow(catch) == 1L,
  catch$value == 419,
  catch$season == "Post-survey 2026",
  identical(as.numeric(survey_biomass$value), c(2808, 945, 1044, 4797)),
  identical(as.numeric(survey_biomass$se), c(799, 317, 247, 994)),
  identical(as.numeric(survey_biomass$lwr), c(1364, 422, 605, 2998)),
  identical(as.numeric(survey_biomass$upr), c(4381, 1629, 1517, 6845)),
  grepl("3254 t", survey_biomass$notes[survey_biomass$region == "Pooled survey area"], fixed = TRUE),
  identical(cohort_share$age_group, paste0(1:4, "+")),
  identical(as.numeric(cohort_share$value), c(0.25, 7.30, 22.78, 69.67)),
  identical(as.numeric(expected_density$value), 1098),
  nrow(expected_density_sum) == 1L,
  as.numeric(expected_density_sum$value) == 1099,
  identical(as.numeric(catch_advice$value), c(130, 112)),
  identical(catch_advice$season, c("2026/27", "2027/28")),
  x$assumptions$value[x$assumptions$setting == "initial_biomass"] == "987 t",
  nrow(candidate) == 1L,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  selected$curation_status == "source_curated_partial",
  nrow(manifest) == 1L,
  manifest$retrieved_on == "2026-11-06",
  manifest$sha256 == "17FF6A46D444A633C4BEE736694C56E524B59899A32AA7498EBA6414591DE955",
  file.exists(file.path("source_cache", manifest$local_file)),
  file.exists("discovery/source_reviews/afma_himi_mackerel_icefish_2026.md")
)

cached_file <- file.path("source_cache", manifest$local_file)
stopifnot(identical(
  toupper(unname(tools::sha256sum(cached_file))),
  toupper(manifest$sha256)
))

cat("AFMA HIMI mackerel icefish 2026 source checks passed.
")
