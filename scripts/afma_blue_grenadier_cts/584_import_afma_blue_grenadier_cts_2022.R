assessment_id <- "afma_blue_grenadier_cts_2022"
stock_id <- "afma_blue_grenadier_cts"
report_url <- "https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-blue-grenadier-2022.pdf"

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  rows <- rows[header]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", append = TRUE, qmethod = "double")
}

assessment_rows_exist <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)

if (!stock_id %in% stocks$stock_id) {
  stop("The Blue Grenadier CTS stock must exist before importing its 2022 assessment.", call. = FALSE)
}
if (assessment_id %in% assessments$assessment_id ||
    assessment_rows_exist("database/assumptions.csv", assessment_id) ||
    assessment_rows_exist("database/inputs.csv", assessment_id) ||
    assessment_rows_exist("database/outputs.csv", assessment_id)) {
  stop("The Blue Grenadier 2022 source record is already present; refusing to duplicate it.", call. = FALSE)
}

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2022,
  terminal_year = 2021,
  estimate_terminal_year = 2023,
  assessment_type = "full_assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.19.01",
  is_current = FALSE,
  is_applied = TRUE,
  framework_year = 2021,
  assessment_url = report_url,
  framework_url = "",
  data_url = "",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = "The published technical paper presents a preliminary 2022 base case. SERAG's November 2022 minutes report advice from the updated Tier 1 assessment, and AFMA's 2026 species summary identifies 2022 as the last full Tier 1 assessment and 2025 as an update. This historical applied run is separate from the current 2025 update. Only numeric acoustic observations and selected reported outputs could be recovered; no final native model files were found.",
  stringsAsFactors = FALSE
)

assumptions <- data.frame(
  assessment_id = assessment_id,
  component = c(
    "population", "population", "population", "population", "recruitment",
    "mortality", "growth", "fleet", "selectivity", "index", "index",
    "observation_model", "observation_model", "biology", "biology", "biology",
    "timing", "input_data"
  ),
  fleet = "",
  survey = "",
  sex = "",
  region = "",
  season = "",
  setting = c(
    "model_structure", "base_case_label", "initial_population", "plus_group",
    "stock_recruitment", "natural_mortality", "growth", "fleet_structure",
    "selectivity", "acoustic_index_base_case", "acoustic_observation_error",
    "cpue_observation_error", "composition_sample_size", "weight_length_parameters",
    "female_maturity_at_length", "fraction_mature_spawning", "annual_data_period",
    "unpublished_numeric_inputs"
  ),
  value = c(
    "Single age- and size-structured stock with males and females modeled separately in Stock Synthesis.",
    "Tuned2022_v2.",
    "The population is assumed to be at unfished equilibrium at the start of 1960.",
    "Age 20 is the plus group; age observations extend through age 20.",
    "Stochastic Beverton-Holt stock-recruitment relationship; steepness is fixed at 0.75; recruitment deviations are estimated for 1974-2018.",
    "Male and female M are estimated separately and are constant across age and time.",
    "Von Bertalanffy growth is sex-specific, with cohort-specific growth deviations estimated for year classes 1978-2018.",
    "The spawning fishery operates in Zone 40 off western Tasmania during June-August; the non-spawning fishery operates in other months and zones.",
    "Length-specific and time-invariant; logistic for the spawning fleet and dome-shaped for the non-spawning fleet.",
    "Base case includes acoustic biomass observations from 2003-2010 and 2020-2021. The 2019 observation was a sensitivity and was excluded from the base case.",
    "The tabulated spawning-ground biomass observations are doubled for a turnover rate of 2. Assessment CVs below 0.30 are raised to 0.30; an extra variance component is estimated. Acoustic selectivity mirrors the maturity ogive.",
    "CPUE CV was initially 0.248 from a loess fit and was then re-tuned to model-estimated standard errors.",
    "Length-composition and conditional age-at-length data are fitted. Retained and discarded onboard length sample sizes are capped at 200 with a minimum of 100; port sample size uses trips capped at 100.",
    "Female length-weight parameters: a=0.01502, b=2.728; male parameters: a=0.0168, b=2.680.",
    "Female maturity is represented by a logistic length ogive with L50=63.7 cm and slope parameter -0.261.",
    "A fraction 0.84 of the mature population is assumed to spawn each year.",
    "Annual input data are formulated by calendar year; no fractional within-year observation times were reported.",
    "Numerical catch, CPUE, discard, length-composition, conditional age-at-length, egg-survey and age-reading-error arrays were not found in the reviewed production-run sources. Numerical weight-at-age and maturity-at-age schedules are also unavailable."
  ),
  source_reference = c(
    "Tuck and Bessell-Browne 2022, sections 1.1 and 5.1",
    "Tuck and Bessell-Browne 2022, section 5.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, sections 1.1 and 5.3",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 5.6, Table 2; SERAG November 2022 minutes, Attachment G",
    "Tuck and Bessell-Browne 2022, sections 1.1 and 5.6",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, section 1.1",
    "Tuck and Bessell-Browne 2022, Table 1",
    "Tuck and Bessell-Browne 2022, Table 1",
    "Tuck and Bessell-Browne 2022, Table 1",
    "Tuck and Bessell-Browne 2022, section 2",
    "Tuck and Bessell-Browne 2022; sources listed in source review"
  ),
  notes = c(
    "The assessment concerns the single Commonwealth Trawl Sector stock and distinguishes spawning and non-spawning sub-fisheries.",
    "The technical paper labels this a preliminary base case; SERAG later used the 2022 Tier 1 assessment for advice.",
    "",
    "",
    "",
    "Point estimates are stored separately as reported outputs.",
    "The numeric cohort growth surface is not published.",
    "",
    "",
    "Table 2 also lists 2019 as a sensitivity, not part of the tuned base case.",
    "The source table reports raw biomass and both sampling CV and assessment CV. The input rows retain raw values and document the turnover multiplier rather than silently doubling them.",
    "The numeric CPUE series and final tuned error values are not published in the reviewed sources.",
    "These settings describe composition weighting; sample counts and composition vectors are not published numerically.",
    "Coefficients are reported for the length-weight equations; numeric weight-at-age schedules are not given.",
    "The model's numerical maturity-at-age surface is unavailable.",
    "",
    "The report states the annual calendar-year basis but does not give within-year timing fractions for the acoustic observations.",
    "Older 2021 values are not substituted for the 2022 run, and 2022 values are not copied into the current 2025 record."
  ),
  stringsAsFactors = FALSE
)

years <- c(2003:2010, 2020, 2021)
acoustic_biomass <- c(24690, 16295, 18852, 42882, 56330, 24450, 24787, 20622, 30328, 15101)
assessment_cv <- c(0.30, 0.46, 0.30, 0.30, 0.52, 0.30, 1.00, 0.33, 0.30, 0.30)
sampling_cv <- c(0.16, 0.46, 0.14, 0.14, 0.52, 0.22, 1.00, 0.33, 0.11, 0.20)
survey_name <- "Blue Grenadier spawning-ground acoustic survey"
region_name <- "Western Tasmania spawning ground"
source_table <- "Tuck and Bessell-Browne 2022, section 5.6, Table 2"

input_rows <- function(measure, values, basis, unit, transformation = "", notes = "") {
  data.frame(
    assessment_id = assessment_id,
    type = "index",
    measure = measure,
    basis = basis,
    fleet = "",
    survey = survey_name,
    sex = "",
    region = region_name,
    season = "",
    year = years,
    year_basis = "calendar_year",
    age = "",
    value = values,
    unit = unit,
    sampling_time = "",
    source_type = "official_table",
    source_reference = source_table,
    transformation = transformation,
    notes = notes,
    observation_id = paste0("acoustic_", years),
    length_bin = "",
    length_bin_lower = "",
    length_bin_upper = "",
    sample_size = "",
    age_error = "",
    partition = "",
    stringsAsFactors = FALSE
  )
}

inputs <- rbind(
  input_rows(
    "relative_biomass_index", acoustic_biomass, "index_scale",
    "tonnes (spawning-ground index)",
    "Values retained on the source table scale; the assessment applies a spawning-ground turnover multiplier of 2.",
    "Base-case acoustic observation. This is a spawning-ground index, not absolute whole-stock biomass."
  ),
  input_rows(
    "biomass_index_cv", assessment_cv, "relative_scale", "ratio",
    notes = "Assessment CV reported for the base-case acoustic observation; an additional variance component is estimated."
  ),
  input_rows(
    "relative_standard_error", sampling_cv, "relative_scale", "ratio",
    notes = "Survey sampling CV reported separately from the assessment CV."
  )
)

outputs <- data.frame(
  assessment_id = assessment_id,
  type = c("biomass", "biomass", "mortality", "mortality", "catch", "catch", "catch"),
  measure = c(
    "unfished_spawning_biomass", "SSB_ratio_to_B0",
    "natural_mortality_average_parameter", "natural_mortality_average_parameter",
    "catch_advice", "catch_advice", "catch_advice"
  ),
  fleet = "",
  survey = "",
  sex = c("female", "female", "female", "male", "", "", ""),
  region = "",
  season = "",
  year = c(NA_real_, 2023, NA_real_, NA_real_, 2023, 2024, 2025),
  age = "",
  age_group = "",
  value = c(35680, 1.24, 0.239, 0.246, 20168, 17182, 14590),
  se = "",
  lwr = "",
  upr = "",
  unit = c("tonnes", "ratio", "per year", "per year", rep("tonnes including discards", 3)),
  source_type = c(rep("official_document", 4), rep("official_table", 3)),
  source_reference = c(
    "Tuck and Bessell-Browne 2022, sections 5.3-5.4",
    "Tuck and Bessell-Browne 2022, section 5.4",
    "Tuck and Bessell-Browne 2022, section 5.3",
    "Tuck and Bessell-Browne 2022, section 5.3",
    rep("SERAG November 2022 minutes, Attachment G", 3)
  ),
  notes = c(
    "Estimated unfished female spawning biomass B0.",
    "2023 projected spawning biomass as a fraction of B0; the report gives 124 percent and assumes 2021 catches in 2022.",
    "Estimated age- and time-invariant female natural mortality parameter.",
    "Estimated age- and time-invariant male natural mortality parameter.",
    "SERAG-recommended annual RBC values from the 2022 assessment; reported totals include discards.",
    "SERAG-recommended annual RBC values from the 2022 assessment; reported totals include discards.",
    "SERAG-recommended annual RBC values from the 2022 assessment; reported totals include discards."
  ),
  scenario = "2022 Tier 1 assessment",
  stringsAsFactors = FALSE
)

append_csv("database/assessments.csv", assessment)
append_csv("database/assumptions.csv", assumptions)
append_csv("database/inputs.csv", inputs)
append_csv("database/outputs.csv", outputs)

cat("Imported the separate applied 2022 Blue Grenadier CTS assessment record.\n")
