root <- "."
db <- file.path(root, "database")
assessment_id <- "dfo_yellowmouth_2021"
stock_id <- "dfo_yellowmouth_bc"
assessment_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091449.pdf"
advice_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4103336x.pdf"

source(file.path(root, "scripts", "database", "pacific_tables.R"))

if (stock_id %in% utils::read.csv(file.path(db, "stocks.csv"))$stock_id) {
  cli::cli_abort("The Yellowmouth Rockfish stock already exists.")
}
if (assessment_id %in% utils::read.csv(file.path(db, "assessments.csv"))$assessment_id) {
  cli::cli_abort("The Yellowmouth Rockfish assessment already exists.")
}

stocks <- pacific_database_row(
  "stocks",
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "DFO",
  authority_stock_id = "DFO Yellowmouth Rockfish - BC coastwide",
  scientific_name = "Sebastes reedi",
  common_name = "Yellowmouth Rockfish - Coastwide",
  area = "PMFC areas 3CD and 5ABCDE; excludes 4B",
  region = "British Columbia",
  ocean = "Northeast Pacific",
  notes = paste(
    "Current DFO coastwide unit includes PMFC areas 3CD and 5ABCDE and excludes 4B.",
    "No Charbonneau–Keith match was identified."
  )
)

assessments <- pacific_database_row(
  "assessments",
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2021L,
  terminal_year = 2021L,
  estimate_terminal_year = 2022L,
  assessment_type = "full_assessment",
  model_family = "Stock Synthesis 3",
  model_version = "3.30.17.01; composite base case",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = NA_integer_,
  assessment_url = assessment_url,
  framework_url = "",
  data_url = "",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Latest detailed production assessment located for the current coastwide unit.",
    "It is a two-sex annual Stock Synthesis model with ages 1-60 and five fixed-M runs pooled for the composite base case.",
    "Reported age-composition inputs and annual population trajectories are figures rather than numeric tables;",
    "numeric N-at-age and instantaneous F-at-age output series and a run-matched native model bundle were not recovered."
  )
)

input_rows <- function(type, measure, basis, value, unit, source_reference,
                       year = NA_integer_, age = NA_integer_, fleet = "",
                       survey = "", sex = "", region = "BC coast",
                       season = "", sampling_time = NA_real_,
                       source_type = "official_table", transformation = "",
                       notes = "") {
  n <- length(value)
  if (length(year) == 1L) year <- rep(year, n)
  if (length(age) == 1L) age <- rep(age, n)
  if (length(sampling_time) == 1L) sampling_time <- rep(sampling_time, n)
  if (length(region) == 1L) region <- rep(region, n)
  pacific_database_row(
    "inputs",
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    basis = basis,
    fleet = fleet,
    survey = survey,
    sex = sex,
    region = region,
    season = season,
    year = year,
    year_basis = ifelse(is.na(year), "", "calendar_year"),
    age = age,
    value = value,
    unit = unit,
    sampling_time = sampling_time,
    source_type = source_type,
    source_reference = source_reference,
    transformation = transformation,
    notes = notes
  )
}

assumption_rows <- function(component, setting, value, source_reference,
                            sex = "", notes = "") {
  n <- length(value)
  pacific_database_row(
    "assumptions",
    assessment_id = assessment_id,
    component = component,
    fleet = "",
    survey = "",
    sex = rep_len(sex, n),
    region = "BC coast",
    season = "",
    setting = setting,
    value = as.character(value),
    source_reference = source_reference,
    notes = notes
  )
}

output_rows <- function(type, measure, quantiles, unit, source_reference,
                        year = NA_integer_, notes = "") {
  pacific_database_row(
    "outputs",
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = "",
    survey = "",
    sex = if (measure %in% c("unfished_spawning_biomass", "spawning_biomass")) "female" else "",
    region = "BC coast",
    season = "",
    year = year,
    age = NA_integer_,
    age_group = "",
    value = quantiles[3],
    se = NA_real_,
    lwr = quantiles[1],
    upr = quantiles[5],
    unit = unit,
    source_type = "official_table",
    source_reference = source_reference,
    notes = notes
  )
}

catch_values <- c(
  2.68, 3.11, 2.85, 3.73, 3.97, 7.02, 4.20, 45.1, 151, 63.2, 704, 355,
  173, 288, 353, 646, 598, 512, 220, 319, 362, 270, 254, 307, 403, 321,
  371, 556, 429, 395, 1858, 3592, 2093, 2011, 2248, 1295, 1069, 1683,
  2256, 3000, 1578, 1282, 1137, 1535, 1165, 1143, 1028, 707, 805, 1095,
  1356, 1825, 2438, 2773, 2527, 2995, 2689, 3859, 2785, 2408, 2556,
  1484, 2104, 1870, 1760, 2099, 1862, 2030, 1924, 1914, 1978, 1818, 1375,
  1230, 1612, 1196, 1238, 1206, 1368, 1379, 1223, 1162, 1404, 1216, 1521,
  1057, 1057
)
stopifnot(length(catch_values) == length(1935:2021))
catch_notes <- rep(
  paste(
    "Coastwide reconstructed total catch including landings and releases.",
    "Table values are rounded; the model-native catch vector was not recovered."
  ),
  length(catch_values)
)
catch_notes[length(catch_notes)] <- paste(
  "The table reports 298 t to the end of June 2021; the assessment explicitly used",
  "the 2020 catch value of 1,057 t as the 2021 model input."
)
catch_inputs <- input_rows(
  type = "catch",
  measure = "total_biomass",
  basis = "biomass",
  value = catch_values,
  unit = "t",
  source_reference = paste0(assessment_url, " Table A.4, p. 48"),
  year = 1935:2021,
  fleet = "Trawl+",
  region = "PMFC 3CD+5ABCDE",
  sampling_time = 0.5,
  source_type = c(rep("official_table", 86L), "reconstructed_source_input"),
  transformation = c(rep("", 86L),
    "Use the 2020 value for 2021, as explicitly specified in Table A.4."),
  notes = catch_notes
)

survey_data <- data.frame(
  survey = c(
    rep("Goose Island Gully historical trawl survey", 8),
    rep("Queen Charlotte Sound synoptic trawl survey", 10),
    rep("West Coast Vancouver Island synoptic trawl survey", 8),
    rep("West Coast Haida Gwaii synoptic trawl survey", 8)
  ),
  year = c(
    1967, 1969, 1971, 1973, 1976, 1977, 1984, 1994,
    2003, 2004, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019,
    2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018,
    2006, 2007, 2008, 2010, 2012, 2016, 2018, 2020
  ),
  estimate = c(
    397.8, 359.9, 765.8, 371.7, 157.1, 27.2, 686.6, 2623.7,
    1407.2, 3812.8, 1632.6, 1388.2, 2604.8, 2651.5, 1432.8, 989.9, 6318.2, 5400.8,
    30.5, 108.5, 38.8, 342.9, 125.2, 188.3, 27.7, 29.0,
    133.9, 344.9, 232.4, 41.1, 1039.0, 1454.7, 666.0, 932.7
  ),
  bootstrap_mean = c(
    394.4, 359.9, 760.5, 370.8, 155.5, 27.2, 703.7, 2583.0,
    1391.9, 3759.4, 1638.5, 1407.5, 2640.4, 2607.8, 1415.8, 978.2, 6330.6, 5411.3,
    29.9, 106.4, 39.4, 341.2, 125.7, 190.7, 27.6, 29.9,
    134.6, 350.5, 235.4, 42.1, 1036.5, 1446.9, 652.0, 914.3
  ),
  lower = c(
    64.4, 50.2, 78.4, 87.3, 35.0, 4.4, 136.1, 544.2,
    598.0, 950.1, 636.6, 653.6, 883.4, 1015.9, 673.6, 333.7, 2312.7, 728.2,
    0.0, 42.3, 4.5, 97.7, 13.2, 10.3, 5.5, 3.6,
    48.2, 101.7, 58.4, 11.8, 433.2, 233.5, 165.8, 263.1
  ),
  upper = c(
    862.4, 813.1, 2249.2, 833.3, 362.6, 68.9, 1757.3, 6719.9,
    2692.6, 8314.0, 3468.2, 2409.1, 5163.7, 5032.5, 2506.6, 1920.8, 13689.6, 14942.6,
    88.0, 209.2, 109.3, 689.7, 383.1, 504.9, 74.5, 81.3,
    296.8, 710.6, 609.0, 78.4, 1953.5, 4092.1, 1565.8, 2085.0
  ),
  bootstrap_cv = c(
    .497, .543, .805, .510, .516, .615, .575, .575,
    .366, .483, .425, .320, .417, .389, .321, .406, .447, .700,
    .725, .380, .690, .433, .732, .665, .617, .707,
    .443, .444, .540, .415, .363, .727, .549, .483
  ),
  analytic_cv = c(
    .504, .546, .839, .507, .520, .625, .606, .574,
    .372, .473, .425, .309, .427, .406, .333, .401, .455, .713,
    .739, .371, .700, .432, .741, .644, .620, .726,
    .428, .457, .544, .420, .351, .753, .539, .487
  ),
  table = c(rep("Table B.4", 8), rep("Table B.7", 10),
            rep("Table B.10", 8), rep("Table B.13", 8)),
  stringsAsFactors = FALSE
)
stopifnot(nrow(survey_data) == 34L)

survey_table_notes <- sprintf(
  "Eq. B.4 biomass estimate; bootstrap mean %.1f t; 95%% bootstrap interval [%.1f, %.1f] t; bootstrap CV %.3f; analytic CV %.3f. The report does not identify which CV series was passed to the assessment run.",
  survey_data$bootstrap_mean, survey_data$lower, survey_data$upper,
  survey_data$bootstrap_cv, survey_data$analytic_cv
)
survey_inputs <- input_rows(
  type = "index",
  measure = "total_biomass",
  basis = "biomass",
  value = survey_data$estimate,
  unit = "t",
  source_reference = paste0(assessment_url, " ", survey_data$table),
  year = survey_data$year,
  survey = survey_data$survey,
  sampling_time = 0.5,
  notes = survey_table_notes
)
survey_cv_inputs <- input_rows(
  type = "index",
  measure = "biomass_index_cv",
  basis = "relative_scale",
  value = survey_data$bootstrap_cv,
  unit = "ratio",
  source_reference = paste0(assessment_url, " ", survey_data$table),
  year = survey_data$year,
  survey = survey_data$survey,
  notes = paste(
    "Bootstrap CV based on 1,000 resamples. The source table also reports an analytic CV,",
    "preserved in the matched biomass-index row notes; the exact CV series used in the run is not identified."
  )
)

cpue <- data.frame(
  year = 1996:2020,
  value = c(
    1.553, 1.798, 2.662, 2.332, 1.581, 1.291, 1.081, 0.817, 1.076, 1.040,
    1.208, 1.167, 1.287, 1.096, 0.708, 0.561, 0.516, 0.494, 0.466, 0.438,
    0.646, 1.124, 0.803, 1.072, 1.113
  ),
  lower = c(
    1.299, 1.645, 2.446, 2.046, 1.456, 1.198, 1.004, 0.763, 0.979, 0.950,
    1.096, 1.074, 1.111, 0.992, 0.650, 0.501, 0.456, 0.420, 0.373, 0.388,
    0.572, 0.994, 0.694, 0.931, 0.926
  ),
  upper = c(
    1.820, 2.080, 2.938, 2.531, 1.696, 1.410, 1.180, 0.890, 1.193, 1.148,
    1.338, 1.288, 1.428, 1.209, 0.778, 0.623, 0.577, 0.581, 0.533, 0.531,
    0.713, 1.259, 0.891, 1.279, 1.269
  ),
  se = c(
    .0903, .0547, .0487, .0513, .0470, .0418, .0417, .0407, .0463, .0478,
    .0508, .0502, .0635, .0517, .0510, .0599, .0603, .0784, .0850, .0751,
    .0601, .0590, .0677, .0793, .0785
  )
)
stopifnot(nrow(cpue) == 25L)

cpue_notes <- sprintf(
  "Combined delta-lognormal bottom-trawl CPUE index from Table C.9; geometric mean scaled to 1.0; bootstrap 95%% interval [%.3f, %.3f]; bootstrap SE %.4f on the relative-index scale. The report says these SEs were used as initial CVs in the stock assessment.",
  cpue$lower, cpue$upper, cpue$se
)
cpue_inputs <- input_rows(
  type = "index",
  measure = "relative_abundance_index",
  basis = "index_scale",
  value = cpue$value,
  unit = "relative index (geometric mean = 1)",
  source_reference = paste0(assessment_url, " Table C.9"),
  year = cpue$year,
  fleet = "Trawl+",
  survey = "Commercial bottom-trawl CPUE",
  sampling_time = 0.5,
  notes = cpue_notes
)
cpue_sd_inputs <- input_rows(
  type = "index",
  measure = "index_sd",
  basis = "index_scale",
  value = cpue$se,
  unit = "relative index units",
  source_reference = paste0(assessment_url, " Table C.9"),
  year = cpue$year,
  fleet = "Trawl+",
  survey = "Commercial bottom-trawl CPUE",
  notes = paste(
    "Source-reported bootstrap standard error (100 replicates), on the relative-index scale.",
    "It is kept as an SE; the report states it was used as an initial CV."
  )
)

maturity_age <- 1:60
maturity_values <- c(
  rep(0, 4),
  .0549, .0880, .1352, .1994, .2819, .3822, .4970, .6198,
  .7414, .8505, .9357, .9873,
  rep(1, 44)
)
stopifnot(length(maturity_values) == 60L)
maturity_source <- ifelse(maturity_age >= 21, "official_document", "official_table")
maturity_inputs <- input_rows(
  type = "maturity",
  measure = "maturity_at_age",
  basis = "proportion",
  value = maturity_values,
  unit = "proportion mature",
  source_reference = paste0(assessment_url, " Table D.6 and Appendix D.1.3"),
  age = maturity_age,
  sex = "female",
  source_type = maturity_source,
  notes = paste(
    "Time-invariant female maturity ogive used in the population model.",
    "Ages 1-4 are zero; ages 5-16 use the Table D.6 Mod column; all ages 17+ were explicitly forced to 1."
  )
)

assumptions <- rbind(
  assumption_rows("population", "model_age_range", "1-60; age 60 is the accumulator",
    paste0(assessment_url, " Appendix E.2, E.4.1")),
  assumption_rows("population", "model_year_range", "1935-2021; population states through start of 2022",
    paste0(assessment_url, " Appendix E.2, E.4.1-E.4.2")),
  assumption_rows("catch", "fishery_structure", "One combined fishery: Trawl+",
    paste0(assessment_url, " Appendix E.2, E.4.3"),
    notes = "Combines trawl, halibut longline, sablefish trap/longline, dogfish/lingcod/salmon troll, and hook-and-line rockfish catches."),
  assumption_rows("catch", "catch_timing", 0.5,
    paste0(assessment_url, " Appendix E.2, assumption 2"),
    notes = "Annual catch is treated as known without error and occurs midyear."),
  assumption_rows("index", "abundance_index_timing", 0.5,
    paste0(assessment_url, " Appendix E.2, assumption 13"),
    notes = "Indices are compared with vulnerable biomass at midyear after half the catch and half natural mortality."),
  assumption_rows("index", "age_composition_timing", 0.5,
    paste0(assessment_url, " Appendix E.2, assumption 14"),
    notes = "Age-composition samples represent midyear after half the catch and half natural mortality."),
  assumption_rows("index", "survey_age_composition_weight", 0.25,
    paste0(advice_url, " assessment summary; detailed report model description"),
    notes = "Survey age compositions were downweighted to 0.25 because they did not consistently track cohorts."),
  assumption_rows("recruitment", "stock_recruitment_model", "Beverton-Holt; steepness h=0.7",
    paste0(assessment_url, " Appendix E.2, assumptions 3 and 8")),
  assumption_rows("recruitment", "recruitment_process_sd", 0.9,
    paste0(assessment_url, " Appendix E.2, assumption 9"),
    notes = "Fixed lognormal recruitment standard deviation."),
  assumption_rows("recruitment", "female_recruitment_fraction", 0.5,
    paste0(assessment_url, " Appendix E.2, assumption 8")),
  assumption_rows("M", paste0("fixed_M_", c("R77", "R71", "R75", "R72", "R76")),
    c(.04, .045, .05, .055, .06),
    paste0(assessment_url, " Appendix F.2.3 and Table F.4"),
    sex = "both",
    notes = paste("Age- and time-invariant fixed M for component run",
      c("R77", "R71", "R75", "R72", "R76"),
      "; the composite posterior pools the five runs. These are not estimated M values.")),
  assumption_rows("assessment", "composite_MCMC_sample_count", 10000,
    paste0(assessment_url, " Appendix F.2.3 and Table F.4"),
    notes = "Five component runs contributed 2,000 retained samples each."),
  assumption_rows("age_composition", "commercial_observation_years",
    "1979-1980, 1990-1996, 1998-2003, 2005, 2007, 2009-2019",
    paste0(assessment_url, " Table E.1"),
    notes = "Model years with commercial proportion-at-age data; numeric vectors are not tabulated."),
  assumption_rows("age_composition", "QCS_observation_years",
    "2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019",
    paste0(assessment_url, " Table E.1"),
    notes = "Survey proportion-at-age years; numeric vectors are not tabulated."),
  assumption_rows("age_composition", "WCVI_observation_years",
    "1996, 2006, 2010, 2012",
    paste0(assessment_url, " Table E.1"),
    notes = "Survey proportion-at-age years; numeric vectors are not tabulated."),
  assumption_rows("age_composition", "WCHG_observation_years",
    "1997, 2006-2008, 2010, 2012, 2014, 2016, 2018",
    paste0(assessment_url, " Table E.1"),
    notes = "Survey proportion-at-age years; numeric vectors are not tabulated."),
  assumption_rows("age_composition", "GIG_observation_years",
    "1979, 1994-1995",
    paste0(assessment_url, " Table E.1"),
    notes = "Survey proportion-at-age years; numeric vectors are not tabulated."),
  assumption_rows("biology", "length_weight_log_a", c(-11.757, -11.950),
    paste0(assessment_url, " Table D.2"),
    sex = c("female", "male"),
    notes = "Coastwide survey-data parameter estimates used for model weights-at-age; source table reports SEs 0.016 and 0.014 respectively."),
  assumption_rows("biology", "length_weight_exponent_b", c(3.183, 3.241),
    paste0(assessment_url, " Table D.2"),
    sex = c("female", "male"),
    notes = "Coastwide survey-data parameter estimates used for model weights-at-age; source table reports SEs 0.004 for both sexes."),
  assumption_rows("biology", "growth_Linf_cm", c(48.2, 46.7),
    paste0(assessment_url, " Table D.4"),
    sex = c("female", "male"),
    notes = "Von Bertalanffy estimates from research and survey data, fixed in the population model."),
  assumption_rows("biology", "growth_rate_per_year", c(.1157, .1288),
    paste0(assessment_url, " Table D.4"),
    sex = c("female", "male"),
    notes = "Von Bertalanffy estimates from research and survey data, fixed in the population model."),
  assumption_rows("biology", "growth_t0_years", c(-2.46, -2.00),
    paste0(assessment_url, " Table D.4"),
    sex = c("female", "male"),
    notes = "Von Bertalanffy estimates from research and survey data, fixed in the population model."),
  assumption_rows("biology", "weight_at_age_surface",
    "Fixed over time and derived from sex-specific length-weight and age-length model parameters",
    paste0(assessment_url, " Appendix E.4.6"),
    notes = "The report does not tabulate the final numeric weight-at-age surface; the model age-class convention must be respected in any later derivation."),
  assumption_rows("index", "survey_precision_series",
    "Bootstrap CV and analytic CV both reported",
    paste0(assessment_url, " Tables B.4, B.7, B.10, B.13"),
    notes = "The import preserves the bootstrap CV; the report does not identify which CV version was passed to the production run.")
)

output_table <- paste0(assessment_url, " Table F.4, p. 216")
output_note <- function(x) {
  sprintf(
    "Composite-base MCMC quantiles 5/25/50/75/95%% = %s; value is the median; lwr/upr are 5th/95th percentiles (a central 90%% posterior interval, not a 95%% interval).",
    paste(format(x, trim = TRUE, scientific = FALSE), collapse = "/")
  )
}
outputs <- rbind(
  output_rows("biomass", "unfished_spawning_biomass",
    c(20898, 23707, 26386, 30528, 41314), "t", output_table,
    notes = output_note(c(20898, 23707, 26386, 30528, 41314))),
  output_rows("biomass", "spawning_biomass",
    c(10070, 13848, 18001, 24978, 42533), "t", output_table,
    year = 2022L,
    notes = paste("B2022 is at the start of 2022 (equivalent to end of 2021).",
      output_note(c(10070, 13848, 18001, 24978, 42533)))),
  output_rows("biomass", "spawning_biomass_to_B0",
    c(.4446, .5708, .6922, .8417, 1.080), "ratio", output_table,
    year = 2022L, notes = output_note(c(.4446, .5708, .6922, .8417, 1.080))),
  output_rows("mortality", "exploitation_rate",
    c(.01012, .01697, .02357, .03048, .04154), "ratio", output_table,
    year = 2021L, notes = paste("u2021, midyear exploitation rate.",
      output_note(c(.01012, .01697, .02357, .03048, .04154)))),
  output_rows("mortality", "maximum_exploitation_rate",
    c(.02686, .03845, .04837, .05730, .06531), "ratio", output_table,
    notes = paste("Maximum over 1935-2022 in each posterior sample.",
      output_note(c(.02686, .03845, .04837, .05730, .06531)))),
  output_rows("catch", "msy",
    c(695.7, 845.4, 1039, 1327, 1919), "t", output_table,
    notes = output_note(c(695.7, 845.4, 1039, 1327, 1919))),
  output_rows("biomass", "Bmsy",
    c(6063, 6894, 7656, 8810, 11938), "t", output_table,
    notes = output_note(c(6063, 6894, 7656, 8810, 11938))),
  output_rows("biomass", "biomass_reference_point_0.4_BMSY",
    c(2425, 2758, 3063, 3524, 4775), "t", output_table,
    notes = output_note(c(2425, 2758, 3063, 3524, 4775))),
  output_rows("biomass", "biomass_reference_point_0.8_BMSY",
    c(4850, 5515, 6125, 7048, 9550), "t", output_table,
    notes = output_note(c(4850, 5515, 6125, 7048, 9550))),
  output_rows("biomass", "spawning_biomass_to_Bmsy",
    c(1.535, 1.969, 2.394, 2.905, 3.727), "ratio", output_table,
    year = 2022L, notes = output_note(c(1.535, 1.969, 2.394, 2.905, 3.727))),
  output_rows("biomass", "Bmsy_to_B0",
    c(.2702, .2847, .2917, .2971, .3036), "ratio", output_table,
    notes = output_note(c(.2702, .2847, .2917, .2971, .3036))),
  output_rows("mortality", "exploitation_rate_at_msy",
    c(.04063, .04356, .04636, .04893, .05117), "ratio", output_table,
    notes = output_note(c(.04063, .04356, .04636, .04893, .05117))),
  output_rows("mortality", "exploitation_rate_to_msy",
    c(.2019, .3471, .5082, .7066, 1.001), "ratio", output_table,
    year = 2021L, notes = output_note(c(.2019, .3471, .5082, .7066, 1.001)))
)

inputs <- do.call(rbind, c(
  list(catch_inputs, survey_inputs, survey_cv_inputs, cpue_inputs,
       cpue_sd_inputs, maturity_inputs)
))
append_pacific_case(
  stocks = stocks,
  assessments = assessments,
  assumptions = assumptions,
  inputs = inputs,
  outputs = outputs
)

cat(
  "Imported DFO Yellowmouth Rockfish 2021: ",
  nrow(inputs), " source-input rows, ",
  nrow(assumptions), " assumption/biological-parameter rows, ",
  nrow(outputs), " reported output rows.\n",
  sep = ""
)
