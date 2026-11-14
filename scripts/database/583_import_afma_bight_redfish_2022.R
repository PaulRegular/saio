assessment_id <- "afma_bight_redfish_gab_2022"
stock_id <- "afma_gab_bight_redfish"
candidate_id <- "AFMA:SESSF_GABTF_Bight_Redfish"
candidate_unit_id <- "afma_sessf_gab_bight_redfish"
report_url <- "https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-bight-redfish-tier-1-2022.pdf"
summary_url <- "https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf"
report_path <- "source_cache/australia_afma_bight_redfish_2022/stock-assessment-for-bight-redfish-tier-1-2022.pdf"
summary_path <- "source_cache/australia_afma_bight_redfish_2022/SESSF-Species-Summaries-2026.pdf"
source_paths <- c(report_path, summary_path)
source_urls <- c(report_url, summary_url)
source_hashes <- c(
  "39C0DB74FC36AD2BDF6839A77BE9597C1398D3FB8B99943ABABA8E65AAE3EBD5",
  "17427157044D117DB608886DAAC102F037CD414A1E297B51E7C2D2239A54ADB3"
)
retrieved_on <- "2026-11-06"
region <- "Great Australian Bight"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

if (!all(file.exists(source_paths))) stop("Cache the reviewed AFMA sources first.", call. = FALSE)
actual_hashes <- toupper(unname(tools::sha256sum(source_paths)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached Bight Redfish source differs from the reviewed version.", call. = FALSE)
}

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0, check.names = FALSE))
  missing <- setdiff(header, names(rows))
  if (length(missing)) stop("Import rows lack columns: ", paste(missing, collapse = ", "), call. = FALSE)
  write.table(rows[header], path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", append = TRUE, qmethod = "double", eol = "\n")
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
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
    candidate_id %in% candidates$candidate_id || candidate_unit_id %in% candidates$candidate_unit_id ||
    assessment_rows_exist("database/assumptions.csv", assessment_id) ||
    assessment_rows_exist("database/inputs.csv", assessment_id) ||
    assessment_rows_exist("database/outputs.csv", assessment_id)) {
  stop("The Bight Redfish 2022 record is already present; refusing to duplicate it.", call. = FALSE)
}

stock <- data.frame(
  stock_id = stock_id,
  charbonneau_id = "",
  authority = "AFMA",
  authority_stock_id = "SESSF Great Australian Bight Trawl Sector, Zone 80",
  scientific_name = "Centroberyx gerrardi",
  common_name = "Bight redfish",
  area = "Great Australian Bight Trawl Sector, Zone 80, Southern and Eastern Scalefish and Shark Fishery",
  region = "Great Australian Bight, Australia",
  ocean = "Southern Ocean",
  notes = paste(
    "AFMA identifies one Zone 80 assessment stock.",
    "The detailed report's preliminary base case excludes Western Australian catches;",
    "the 2026 AFMA summary says the current catch series was revised to include 535 tonnes",
    "from southern Western Australia."
  ),
  stringsAsFactors = FALSE
)

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2022L,
  terminal_year = 2022L,
  estimate_terminal_year = 2024L,
  assessment_type = "full_assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30.19.01",
  is_current = TRUE,
  is_applied = TRUE,
  framework_year = "",
  assessment_url = report_url,
  framework_url = "",
  data_url = report_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "AFMA's current species summary continues to identify the 2022 assessment and reports",
    "its results and later revisions to catch and growth inputs. The detailed 2022 report",
    "presents a preliminary base case. No native final model files were located."
  ),
  stringsAsFactors = FALSE
)

assumption_data <- data.frame(
  component = c(
    "population", "population", "population", "population", "fleet", "selectivity",
    "recruitment", "recruitment", "recruitment", "M", "index", "index", "observations",
    "biology", "catch"
  ),
  setting = c(
    "stock_structure", "model_structure", "model_years", "age_range", "fleets",
    "selectivity_structure", "stock_recruitment", "steepness", "recruitment_deviations",
    "natural_mortality", "standardized_cpue", "fishery_independent_survey",
    "composition_data", "growth_by_sex", "catch_series"
  ),
  value = c(
    "One assessment stock, Zone 80, Great Australian Bight.",
    "Annual, two-sex, age- and size-structured Stock Synthesis model; one area and one trawl fleet.",
    "Model years 1960/61–2021/22; fiscal years in observation tables are labelled by their first year.",
    "The age-observation plus group is age 64.",
    "The current summary describes one trawl fleet, with length-data sources separated in the composition model.",
    "Length-based logistic selectivity; selectivity can differ between the GAB-FIS and trawl data.",
    "Beverton-Holt stock-recruitment relationship; unfished recruitment estimated.",
    "Fixed at 0.75.",
    "Recruitment deviations estimated from 1960/61 through 2007/08.",
    "Estimated M is constant over age and time and shared between sexes. AFMA's current summary reports 0.1049 per year (95% profile range 0.091–0.107); the preliminary report's profile gives a different point estimate.",
    "Annual standardized trawl CPUE; the initial CV was 0.107 and was later retuned within Stock Synthesis. The final fitted SD is not tabulated.",
    "Nine relative-abundance estimates and CVs. Survey timing is generally February–April; the report's latest-survey prose says March 2021 while Table 3 labels its final index 2021/22.",
    "Length compositions and conditional age-at-length data are used. The report gives sample counts but not the numerical composition vectors or catch-at-age.",
    "The current summary reports separate male and female growth estimates; the preliminary report describes a shared growth curve. The current summary is retained as the latest source description.",
    "Use Table 2's Total WA catch series, consistent with the 2026 summary's note that the catch series was revised to include 535 tonnes from southern Western Australia. The report's preliminary base-case Total catch column excludes that component; no native final model file was located."
  ),
  source_reference = c(
    "AFMA 2026 SESSF Species Summaries, Bight Redfish entry; AFMA 2022 assessment, p. 5",
    "AFMA 2022 assessment, pp. 6–7; AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    "AFMA 2022 assessment, pp. 7, 12–14",
    "AFMA 2022 assessment, Table 1, p. 7",
    "AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    "AFMA 2022 assessment, p. 7; AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    "AFMA 2022 assessment, p. 7",
    "AFMA 2022 assessment, Table 1, p. 7",
    "AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    "AFMA 2026 SESSF Species Summaries, Bight Redfish entry; AFMA 2022 assessment, pp. 27–29",
    "AFMA 2022 assessment, pp. 7, 13–14",
    "AFMA 2022 assessment, p. 14 and Table 3",
    "AFMA 2022 assessment, pp. 12–17",
    "AFMA 2022 assessment, p. 7; AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    "AFMA 2022 assessment, Table 2, p. 14; AFMA 2026 SESSF Species Summaries, Bight Redfish entry"
  ),
  notes = c(
    "The assessment summary identifies Zone 80 as a single stock.",
    "The 2026 summary is used for current specifications where it differs from the preliminary report.",
    "Reported season labels are retained as first-year calendar labels in the input rows.",
    "Age error SD values are tabulated from ages 0 through 64.",
    "The report does not identify separate biological stocks for the observation fleets.",
    "Length and conditional age-at-length fleet structure is not equivalent to age-specific abundance observations.",
    "The numerical annual recruitment estimates are not published.",
    "Fixed assumption, not an estimate.",
    "No annual recruitment output series is tabulated.",
    "The report's preliminary base-case estimate is 0.1065; the later AFMA summary reports 0.1049 and gives the range 0.091–0.107.",
    "The report states the initial CV was tuned; 0.107 is not stored as the final likelihood error.",
    "Survey timing is left unspecified as a fraction of year. The text/table year-label discrepancy is preserved here.",
    "Sample counts are not age or length composition vectors and are not effective likelihood sample sizes.",
    "AFMA's 2026 summary says male and female growth parameters differ; no age-specific weight or maturity surfaces are tabulated.",
    "The selected current series is the table's Total WA catch column; the 2026 summary confirms the 535 tonne revision."
  ),
  stringsAsFactors = FALSE
)
assumptions <- data.frame(
  assessment_id = assessment_id,
  component = assumption_data$component,
  fleet = "",
  survey = "",
  sex = "",
  region = region,
  season = "",
  setting = assumption_data$setting,
  value = assumption_data$value,
  source_reference = assumption_data$source_reference,
  notes = assumption_data$notes,
  stringsAsFactors = FALSE
)

input_row <- function(type, measure, basis, value, unit, source_reference, notes,
                      fleet = "", survey = "", year = NA_integer_, year_basis = "",
                      age = NA_real_, sex = "", observation_id = "", age_error = "",
                      source_type = "official_table", transformation = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = "",
    year = year, year_basis = if (is.na(year)) "" else year_basis, age = age,
    value = value, unit = unit, sampling_time = NA_real_, source_type = source_type,
    source_reference = source_reference, transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = "", length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = age_error,
    partition = "", stringsAsFactors = FALSE
  )
}

input_rows <- list()
add_input <- function(...) input_rows[[length(input_rows) + 1L]] <<- input_row(...)

financial_years <- 1988:2021
total_wa_catch <- c(
  94.65, 171.83, 289.80, 274.61, 155.69, 141.47, 174.80, 184.92,
  333.17, 378.61, 445.78, 330.64, 395.87, 266.61, 432.67, 957.47,
  951.95, 806.39, 1025.14, 819.75, 685.17, 488.48, 323.60, 366.25,
  309.38, 249.84, 220.94, 214.26, 360.45, 322.23, 280.62, 227.88,
  223.81, 262.49
)
stopifnot(length(financial_years) == length(total_wa_catch))
for (i in seq_along(financial_years)) {
  yr <- financial_years[i]
  add_input(
    "catch", "landings_biomass", "biomass", total_wa_catch[i], "tonnes",
    "AFMA 2022 assessment, Table 2, p. 14; AFMA 2026 SESSF Species Summaries, Bight Redfish entry",
    paste(
      "Annual financial-year catch; year is the first year of the season.",
      "The selected Table 2 Total WA catch series includes the later-reported southern WA revision.",
      "AFMA's 2026 summary says the revised series includes 535 tonnes from southern WA.",
      "The report's preliminary base-case Total catch column excludes this component."
    ),
    fleet = "Trawl", year = yr, year_basis = "model_year",
    observation_id = paste0("TRAWL_CATCH_", yr),
    source_type = "official_table",
    transformation = "Use the source table's Total WA catch column, not its preliminary base-case Total catch column."
  )
}

cpue_years <- 1987:2021
trawl_cpue <- c(
  2.58, 2.48, 1.55, 1.43, 1.31, 0.96, 0.91, 0.62, 0.74, 0.91,
  0.96, 1.12, 0.99, 0.87, 0.68, 0.73, 1.02, 0.99, 0.94, 1.03,
  0.95, 1.02, 0.95, 0.77, 0.77, 0.69, 0.63, 0.68, 0.67, 0.93,
  0.96, 0.86, 0.68, 0.75, 0.68
)
stopifnot(length(cpue_years) == length(trawl_cpue))
for (i in seq_along(cpue_years)) {
  yr <- cpue_years[i]
  add_input(
    "index", "relative_biomass_index", "index_scale", trawl_cpue[i],
    "standardized CPUE (unit not stated)",
    "AFMA 2022 assessment, Table 2, p. 14",
    "Annual standardized trawl CPUE. The source does not state a measurement unit; the initial CV of 0.107 was retuned and is not treated as the final fitted likelihood error.",
    fleet = "Trawl", year = yr, year_basis = "model_year",
    observation_id = paste0("TRAWL_CPUE_", yr)
  )
}

fis_years <- c(2004L, 2005L, 2006L, 2007L, 2008L, 2009L, 2014L, 2017L, 2021L)
fis_values <- c(20887, 25380, 25713, 14591, 27610, 13189, 2573, 4053, 3447)
fis_cv <- c(0.13, 0.16, 0.16, 0.11, 0.18, 0.13, 0.28, 0.25, 0.2111)
survey_name <- "GAB Fishery Independent Survey"
stopifnot(length(fis_years) == length(fis_values), length(fis_years) == length(fis_cv))
for (i in seq_along(fis_years)) {
  yr <- fis_years[i]
  obs_id <- paste0("GAB_FIS_", yr)
  year_note <- if (yr == 2021L) {
    " The source table labels the last observation 2021/22, while its prose describes the most recent trip as March 2021; both source statements are retained."
  } else ""
  add_input(
    "index", "relative_biomass_index", "index_scale", fis_values[i],
    "tonnes (relative abundance index; not absolute biomass)",
    "AFMA 2022 assessment, Table 3, p. 14",
    paste0("Fishery Independent Survey relative-abundance estimate; financial-year label uses its first year.", year_note),
    survey = survey_name, year = yr, year_basis = "model_year", observation_id = obs_id
  )
  add_input(
    "index", "biomass_index_cv", "relative_scale", fis_cv[i], "ratio",
    "AFMA 2022 assessment, Table 3, p. 14",
    "Survey CV reported with the relative-abundance estimate; it is not an SE.",
    survey = survey_name, year = yr, year_basis = "model_year", observation_id = obs_id
  )
}

length_samples <- list(
  list(fleet = "Trawl", years = c(2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2018, 2019, 2020), values = c(2568, 2618, 1173, 1511, 3362, 2257, 404, 678, 1049, 2015, 221, 2008, 452, 1184, 1512, 1108, 936, 794, 442, 754)),
  list(fleet = "GAB-FIS", years = c(2004, 2005, 2006, 2007, 2008, 2010, 2014, 2017, 2020), values = c(1456, 1962, 1003, 2424, 1231, 1065, 1062, 807, 405)),
  list(fleet = "Industry", years = c(2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2020, 2021), values = c(644, 10051, 11093, 9396, 3999, 2313, 3450, 1511, 0, 264, 808)),
  list(fleet = "ISMP Port", years = c(1992, 1993, 1999, 2002, 2003, 2004, 2005, 2014, 2015, 2016, 2017, 2020, 2021), values = c(1, 2, 11, 100, 2706, 759, 541, 70, 62, 58, 11, 253, 454))
)
for (sample_data in length_samples) {
  stopifnot(length(sample_data$years) == length(sample_data$values))
  for (i in seq_along(sample_data$years)) {
    yr <- sample_data$years[i]
    add_input(
      "biology", "composition_sample_count", "numbers", sample_data$values[i], "fish",
      "AFMA 2022 assessment, Table 4, p. 15",
      "Reported 2022A length-sample count for this data source. This is not a length-composition vector or an effective likelihood sample size; zero means no usable observations in the reported source year.",
      fleet = sample_data$fleet, year = yr, year_basis = "model_year",
      observation_id = paste0("LENGTH_SAMPLE_", gsub("[^A-Za-z0-9]+", "_", sample_data$fleet), "_", yr)
    )
  }
}

age_samples <- list(
  list(fleet = "Trawl", years = c(1992, 1993, 1994, 1996, 1997, 1999, 2000, 2001, 2003, 2004, 2005, 2006, 2007, 2008, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021), values = c(90, 224, 47, 113, 927, 595, 330, 558, 600, 537, 410, 472, 353, 207, 34, 200, 488, 332, 507, 404, 593, 335, 496, 419, 455, 169)),
  list(fleet = "GAB-FIS", years = c(2005, 2008, 2010, 2014), values = c(101, 295, 223, 203))
)
for (sample_data in age_samples) {
  stopifnot(length(sample_data$years) == length(sample_data$values))
  for (i in seq_along(sample_data$years)) {
    yr <- sample_data$years[i]
    add_input(
      "biology", "composition_sample_count", "numbers", sample_data$values[i], "fish",
      "AFMA 2022 assessment, Table 5, p. 16",
      "Reported 2022A age-sample count for this source year. Raw counts are not age-composition vectors or effective likelihood sample sizes.",
      fleet = sample_data$fleet, year = yr, year_basis = "model_year",
      observation_id = paste0("AGE_SAMPLE_", gsub("[^A-Za-z0-9]+", "_", sample_data$fleet), "_", yr)
    )
  }
}

age_error_sd <- c(
  0.04133, 0.04133, 0.08266, 0.12399, 0.16531, 0.20664, 0.24797, 0.28930,
  0.33063, 0.37196, 0.41329, 0.45461, 0.49594, 0.53727, 0.57860, 0.61993,
  0.66126, 0.70259, 0.74391, 0.78524, 0.82657, 0.86790, 0.90923, 0.95056,
  0.99189, 1.03321, 1.07454, 1.11587, 1.15720, 1.19853, 1.23986, 1.28119,
  1.32251, 1.36384, 1.40517, 1.44650, 1.48783, 1.52916, 1.57049, 1.61181,
  1.65314, 1.69447, 1.73580, 1.77713, 1.81846, 1.85979, 1.90111, 1.94244,
  1.98377, 2.02510, 2.06643, 2.10776, 2.14909, 2.19041, 2.23174, 2.27307,
  2.31440, 2.35573, 2.39706, 2.43839, 2.47971, 2.52104, 2.56237, 2.60370,
  2.64503
)
stopifnot(length(age_error_sd) == 65L)
for (i in seq_along(age_error_sd)) {
  add_input(
    "biology", "ageing_error_sd", "age_error_sd", age_error_sd[i], "years",
    "AFMA 2022 assessment, Table 6, p. 17",
    "Standard deviation of normal age-reading error for the 2022 assessment; this is not a complete true-age-to-observed-age transition matrix.",
    age = i - 1L, observation_id = "AGE_ERROR_2022", age_error = "2022 assessment"
  )
}

inputs <- do.call(rbind, input_rows)
outputs <- rbind(
  data.frame(assessment_id = assessment_id, type = "biomass", measure = "unfished_spawning_biomass",
    fleet = "", survey = "", sex = "female", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 4535, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "tonnes", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "2022 assessment estimate of unfished female spawning biomass (B0). No uncertainty is reported.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biomass", measure = "SSB_ratio_to_B0",
    fleet = "", survey = "", sex = "female", region = region, season = "", year = 2023L,
    age = NA_real_, age_group = "", value = 0.67, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "proportion", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Projected female SSB for financial year 2023/24 as a proportion of B0; year is the first year of the financial year. No uncertainty is reported.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "natural_mortality_average_parameter",
    fleet = "", survey = "", sex = "", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 0.1049, se = NA_real_, lwr = 0.091, upr = 0.107,
    unit = "per year", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment assumptions and results",
    notes = "Current summary value for the 2022 assessment. Bounds are reported as a 95% profile confidence range; no standard error is given. The detailed preliminary report gives a different estimate of 0.1065.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "catch", measure = "catch_advice",
    fleet = "", survey = "", sex = "", region = region, season = "", year = 2023L,
    age = NA_real_, age_group = "", value = 1056, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "tonnes", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish advice",
    notes = "2023/24 recommended biological catch (RBC), not observed catch. The summary also gives a three-year average RBC of 994 tonnes and long-term yield of 595 tonnes per year.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "mean_length_parameter",
    fleet = "", survey = "", sex = "female", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 42.54, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "cm", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Female average estimated length as described in the summary; parameterization is not stated there.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "mean_length_parameter",
    fleet = "", survey = "", sex = "male", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 38.98, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "cm", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Male average estimated length as described in the summary; parameterization is not stated there.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "length_at_age_1_parameter",
    fleet = "", survey = "", sex = "female", region = region, season = "", year = NA_integer_,
    age = 1, age_group = "", value = 19.66, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "cm", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Estimated female length at age one as described in the summary.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "length_at_age_1_parameter",
    fleet = "", survey = "", sex = "male", region = region, season = "", year = NA_integer_,
    age = 1, age_group = "", value = 19.87, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "cm", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Estimated male length at age one as described in the summary.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "growth_rate_parameter",
    fleet = "", survey = "", sex = "female", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 0.07, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "per year", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Female growth-rate estimate as reported; the exact parameter name and uncertainty are not stated in the summary.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE),
  data.frame(assessment_id = assessment_id, type = "biology", measure = "growth_rate_parameter",
    fleet = "", survey = "", sex = "male", region = region, season = "", year = NA_integer_,
    age = NA_real_, age_group = "", value = 0.08, se = NA_real_, lwr = NA_real_, upr = NA_real_,
    unit = "per year", source_type = "official_document",
    source_reference = "AFMA 2026 SESSF Species Summaries, Bight Redfish assessment results",
    notes = "Male growth-rate estimate as reported; the exact parameter name and uncertainty are not stated in the summary.",
    scenario = "2022 assessment as summarized in 2026", stringsAsFactors = FALSE)
)

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "AFMA",
  official_stock_id = "SESSF Great Australian Bight Trawl Sector, Zone 80",
  scientific_name = "Centroberyx gerrardi",
  stock_name = "Bight redfish - Great Australian Bight",
  assessment_area = "Great Australian Bight Trawl Sector, Zone 80, Southern and Eastern Scalefish and Shark Fishery",
  inventory_assessment_year = 2022L,
  inventory_url = "https://www.afma.gov.au/species/bight-redfish",
  retrieved_on = retrieved_on,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "partial",
  catch_age_evidence = "The current detailed report tabulates aggregate catch only; catch numbers-at-age are not publicly available in the reviewed sources.",
  survey_age_evidence = "The report gives aggregate CPUE and GAB-FIS index values/CVs and raw age sample counts, but not age-specific indices or conditional age-at-length vectors.",
  weights_evidence = "Length/growth estimates are summarized, but no numerical age-specific weight surface is reported.",
  maturity_evidence = "No maturity-at-age schedule or numerical maturity surface was found.",
  mortality_evidence = "The current AFMA summary reports estimated M = 0.1049 per year, with a 95% profile range of 0.091–0.107; the detailed preliminary report differs.",
  timing_evidence = "The report describes FIS timing as generally February–April but does not provide a fractional survey timing; its latest-survey prose and table year label differ.",
  output_evidence = "The current summary reports B0, projected 2023/24 SSB/B0, an M range, growth summaries, and RBC advice; annual N/F/M/recruitment surfaces and uncertainty are not tabulated.",
  detailed_source_url = paste(report_url, summary_url, sep = "; "),
  review_date = retrieved_on,
  decision_reason = "Retain as a partial current-unit source record. Eligibility for an age-based translation is unresolved because catch-at-age and the numerical age/length composition vectors are unavailable.",
  notes = "The AFMA report is a preliminary base-case development document; the 2026 species summary supplies the current assessment description and output values. See source_reviews/afma_bight_redfish_gab_2022.md.",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
candidate <- candidate[names(candidates)]

cat("Bight Redfish source record:", nrow(inputs), "inputs,", nrow(assumptions),
    "assumptions,", nrow(outputs), "outputs.\n")
cat("Eligibility: unresolved; import status: partial.\n")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to update the database and candidate register.\n")
} else {
  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumptions)
  append_csv("database/inputs.csv", inputs)
  append_csv("database/outputs.csv", outputs)
  append_csv("discovery/candidates.csv", candidate)
  dir.create("provenance/afma_bight_redfish_gab_2022", recursive = TRUE, showWarnings = FALSE)
  manifest <- data.frame(
    local_file = sub("^source_cache/", "", source_paths),
    source_url = source_urls,
    retrieved_on = retrieved_on,
    sha256 = source_hashes,
    stringsAsFactors = FALSE
  )
  write.csv(manifest, "provenance/afma_bight_redfish_gab_2022/manifest.csv",
    row.names = FALSE, na = "")
  cat("Wrote the partial AFMA Bight Redfish source record and provenance manifest.\n")
}