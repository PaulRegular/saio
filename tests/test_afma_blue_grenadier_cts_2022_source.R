source("R/read_database.R")
x <- read_assessment("afma_blue_grenadier_cts_2022")

stopifnot(
  x$stocks$stock_id == "afma_blue_grenadier_cts",
  x$stocks$authority == "AFMA",
  x$stocks$scientific_name == "Macruronus novaezelandiae",
  x$assessment$assessment_year == 2022,
  x$assessment$terminal_year == 2021,
  x$assessment$estimate_terminal_year == 2023,
  x$assessment$assessment_type == "full_assessment",
  x$assessment$model_family == "Stock Synthesis",
  x$assessment$model_version == "3.30.19.01",
  !x$assessment$is_current,
  x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x$assumptions) == 18L,
  nrow(x$inputs) == 30L,
  nrow(x$outputs) == 7L
)

index <- x$inputs[x$inputs$measure == "relative_biomass_index", ]
assessment_cv <- x$inputs[x$inputs$measure == "biomass_index_cv", ]
sampling_cv <- x$inputs[x$inputs$measure == "relative_standard_error", ]
expected_years <- c(2003:2010, 2020, 2021)
expected_biomass <- c(24690, 16295, 18852, 42882, 56330, 24450, 24787, 20622, 30328, 15101)
expected_assessment_cv <- c(0.30, 0.46, 0.30, 0.30, 0.52, 0.30, 1.00, 0.33, 0.30, 0.30)
expected_sampling_cv <- c(0.16, 0.46, 0.14, 0.14, 0.52, 0.22, 1.00, 0.33, 0.11, 0.20)

stopifnot(
  setequal(index$year, expected_years),
  identical(index$value[match(expected_years, index$year)], expected_biomass),
  identical(assessment_cv$value[match(expected_years, assessment_cv$year)], expected_assessment_cv),
  identical(sampling_cv$value[match(expected_years, sampling_cv$year)], expected_sampling_cv),
  all(index$basis == "index_scale"),
  all(index$unit == "tonnes (spawning-ground index)"),
  all(index$year_basis == "calendar_year"),
  all(grepl("turnover multiplier of 2", index$transformation, fixed = TRUE)),
  !2019 %in% index$year,
  !any(x$inputs$measure %in% c("landings_biomass", "discard_biomass", "numbers_at_age", "frequency_at_length", "conditional_proportion_at_age", "weight_at_age", "maturity_at_age"))
)

o <- x$outputs
stopifnot(
  o$value[o$measure == "unfished_spawning_biomass"] == 35680,
  o$value[o$measure == "SSB_ratio_to_B0"] == 1.24,
  o$year[o$measure == "SSB_ratio_to_B0"] == 2023,
  o$value[o$measure == "natural_mortality_average_parameter" & o$sex == "female"] == 0.239,
  o$value[o$measure == "natural_mortality_average_parameter" & o$sex == "male"] == 0.246,
  identical(o$value[o$measure == "catch_advice"], c(20168, 17182, 14590)),
  identical(o$year[o$measure == "catch_advice"], 2023:2025),
  all(is.na(o$se)),
  all(is.na(o$lwr)),
  all(is.na(o$upr))
)

assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE)
current <- assessments[assessments$stock_id == "afma_blue_grenadier_cts" & assessments$is_current, ]
stopifnot(
  nrow(current) == 1L,
  current$assessment_id == "afma_blue_grenadier_cts_2025",
  current$assessment_type == "update"
)

x2025 <- read_assessment("afma_blue_grenadier_cts_2025")
stopifnot(
  x2025$assessment$is_current,
  x2025$assessment$assessment_type == "update",
  nrow(x2025$inputs) == 0L,
  identical(x2025$outputs$value[match(c(2022, 2023, 2026), x2025$outputs$year)], c(107, 112, 99.5))
)

manifest <- read.csv("provenance/afma_blue_grenadier_cts_2022/manifest.csv", stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 4L,
  setequal(basename(manifest$local_file), c(
    "afma_blue_grenadier_2022_detailed_assessment.pdf",
    "afma_serag2_november_2022_minutes.pdf",
    "afma_sessf_species_summaries_2026.pdf",
    "AFMA-2019-0800-Blue-Grenadier-data-through-2020.pdf"
  )),
  setequal(toupper(manifest$sha256), c(
    "D5D2614F5C6C73BCD2AD971E4D44C13FE189FE6DED71379A59F24BA5F033557A",
    "35977AC3F54ECAF229C48F4542A85E7B3177D0C5D1539251F007AA3CC0A15F68",
    "17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3",
    "85AF4F446E885FBA074443050DB7DBDA77824239FB44F2BA713E9AE05AE5AF32"
  ))
)

cat("AFMA Blue Grenadier 2022 source checks passed.\n")
