root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
inputs_only <- "--inputs-only" %in% args

source_files <- c(
  "source_cache/mpi_hake_hak1_2024/FAR-2026-01-HAK1-inputs.pdf",
  "source_cache/mpi_hake_hak1_2024/FAR-2026-02-HAK1-2024-assessment.pdf",
  "source_cache/mpi_hake_hak1_2024/FAR-2026-06-hake-ling-catch-at-age.pdf",
  "source_cache/mpi_hake_hak1_2024/HAK-2025-Plenary-volume-1.pdf",
  "source_cache/mpi_hake_hak7_2024/FAR-2025-03-HAK7-2024-assessment.pdf",
  "source_cache/mpi_hake_hak7_2024/FAR-2026-06-hake-ling-catch-at-age.pdf",
  "source_cache/mpi_hake_hak7_2024/HAK-2025-Plenary-volume-1.pdf"
)
expected_hash <- c(
  "55FD165C2E1FF65C52237B8133D286AF20350015A4F73D7305D83BBEF21D49B5",
  "32B9797E13F175A0111F71FE0287D326CDC8959EC79284988946D49B93EE09D0",
  "7250D4DF0A5259B8454D18B620A7D411FADE4CDE68CC9C57B0B620034C1C0FA2",
  "3DD152053F51B7D58FC521F1B2EEA78F279F5B42515DD08F7C9E31233B886086",
  "C398ACB90353FE723E4055648551EE1AEE58783D9B331391FDB29FC456075DCF",
  "7250D4DF0A5259B8454D18B620A7D411FADE4CDE68CC9C57B0B620034C1C0FA2",
  "3DD152053F51B7D58FC521F1B2EEA78F279F5B42515DD08F7C9E31233B886086"
)
if (!all(file.exists(source_files))) stop("Cache the pinned HAK1 and HAK7 reports before importing.", call. = FALSE)
actual_hash <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) stop("A cached hake source does not match its reviewed checksum.", call. = FALSE)

source_urls <- c(
  "https://fs.fish.govt.nz/Doc/26190/FAR-2026-01-Descriptive-analysis-and-stock-assessment-model-inputs-HAK1-to-2023-24.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26191/FAR-2026-02-Stock-assessment-of-HAK1-for-2023-24.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26199/FAR-2026-06-Catch-at-age-estimates-for-hake-and-ling-from-commercial-fisheries-in-2023-24-and-trawl-surveys-in-2024%20%281%29.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26044/hake-hak-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25857/FAR-2025-03-Stock-assessment-of-HAK7-for-the-2023-24-fishing-year.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26199/FAR-2026-06-Catch-at-age-estimates-for-hake-and-ling-from-commercial-fisheries-in-2023-24-and-trawl-surveys-in-2024%20%281%29.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26044/hake-hak-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx"
)
manifest_rows <- function(index) data.frame(
  local_file = sub("^source_cache/", "", source_files[index]),
  source_url = source_urls[index], retrieved_on = "2026-11-05",
  sha256 = expected_hash[index], stringsAsFactors = FALSE
)

assessment_ids <- c(
  "mpi_hake_hak1_subantarctic_2024", "mpi_hake_hak1_age_update_2024",
  "mpi_hake_hak7_wcsi_2024", "mpi_hake_hak7_age_update_2024"
)
stock_ids <- c("mpi_hake_hak1_subantarctic", "mpi_hake_hak7_wcsi")
input_rows <- list()
assumption_rows <- list()
output_rows <- list()

add_input <- function(assessment_id, type, measure, basis, value, unit,
                      year = NA_integer_, year_basis = "", age = NA_integer_,
                      fleet = "", survey = "", sex = "",
                      region = "", season = "", sampling_time = NA_real_,
                      source_reference, notes = "", observation_id = "",
                      source_type = "official_table") {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id, type, measure, basis, fleet, survey, sex, region, season,
    year = as.integer(year), year_basis, age = as.numeric(age),
    value = as.numeric(value), unit, sampling_time, source_type, source_reference,
    transformation = "", notes, observation_id, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
    age_error = NA_real_, partition = NA_character_, stringsAsFactors = FALSE
  )
}

add_age_number <- function(assessment_id, data_id, type, year, year_basis,
                           age, value, cv, sex, fleet = "", survey = "",
                           season = "", source_reference, notes, region) {
  if (is.na(value)) return(invisible(NULL))
  add_input(assessment_id, type, "numbers_at_age", "numbers", value, "fish",
    year = year, year_basis = year_basis, age = age, fleet = fleet, survey = survey,
    sex = sex, region = region, season = season, source_reference = source_reference,
    notes = notes, observation_id = data_id)
  if (!is.na(cv)) add_input(assessment_id, type, "numbers_at_age_cv", "relative_scale", cv,
    "ratio", year = year, year_basis = year_basis, age = age, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    source_reference = source_reference,
    notes = "Source-reported coefficient of variation for the matching numbers-at-age estimate; not an absolute-scale standard error.",
    observation_id = data_id)
}

add_assumption <- function(assessment_id, component, setting, value,
                           source_reference, notes = "", fleet = "", survey = "",
                           sex = "", region = "", season = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id, component, fleet, survey, sex, region, season, setting,
    value = as.character(value), source_reference, notes, stringsAsFactors = FALSE
  )
}

add_output <- function(assessment_id, type, measure, value, unit,
                       year = NA_integer_, survey = "", sex = "", lwr = NA_real_,
                       upr = NA_real_, source_reference, notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id, type, measure, fleet = "", survey, sex, region = "", season = "",
    year = as.integer(year), age = NA_real_, age_group = "", value = as.numeric(value),
    se = NA_real_, lwr = as.numeric(lwr), upr = as.numeric(upr), unit,
    source_type = "official_table", source_reference, notes, scenario = "",
    stringsAsFactors = FALSE
  )
}

years_hak1 <- 1975:2025
summer_hak1 <- c(113.6,266.1,352.2,721.5,344.7,331.4,257.6,169.5,424.2,683.7,497.1,774.6,675.1,1036.9,1171.3,554.7,2154.6,2653.4,3807.8,1569.7,1913.5,2717.6,1868.5,2838.1,2639.6,2879.7,2684.1,2320.1,2661.7,3205.0,2550.9,2511.2,1689.9,2313.6,2423.1,1882.2,1292.6,1855.2,1842.7,1794.3,1565.8,1459.2,912.7,1140.7,640.2,881.1,1281.5,1519.6,933.5,750.6,1073.2)
winter_hak1 <- c(6.4,14.9,19.8,40.5,19.3,18.6,14.4,9.5,23.8,38.3,27.9,43.4,37.9,58.1,65.7,163.8,163.8,152.7,110.7,50.1,68.6,71.8,50.4,105.5,231.6,219.9,132.3,123.7,118.1,22.9,39.7,27.0,16.5,16.4,22.2,44.6,26.0,46.6,35.5,45.9,42.5,10.8,31.3,9.3,6.8,15.9,14.5,4.4,15.5,2.4,10.6)
stopifnot(length(summer_hak1) == length(years_hak1), length(winter_hak1) == length(years_hak1))
for (i in seq_along(years_hak1)) for (j in 1:2) {
  fleet <- if (j == 1L) "Summer fishery (Sep-Mar)" else "Winter fishery (Apr-Aug)"
  value <- if (j == 1L) summer_hak1[i] else winter_hak1[i]
  note <- if (years_hak1[i] == 2025L) "Assumed catch; based on the mean reported for the previous five years." else
    "Scaled catch in the September-August model year; September catches in 1990-1994 were reassigned to the following fishing year."
  add_input("mpi_hake_hak1_subantarctic_2024", "catch", "total_biomass", "biomass", value, "tonnes",
    year = years_hak1[i], year_basis = "model_year", fleet = fleet, region = "Sub-Antarctic",
    season = if (j == 1L) "summer" else "winter",
    source_reference = "Fisheries New Zealand FAR 2026/02, Table 1",
    notes = note)
}

survey_hak1 <- data.frame(
  year = c(1992,1993,1994,2001:2010,2012,2013,2015,2019,2021,2023,2025),
  biomass = c(5686,1944,2567,2657,2170,1777,1672,1694,1459,1530,2470,2162,1442,1855,2428,1477,1675,1572,1285,1521),
  cv = c(.43,.12,.12,.16,.20,.16,.23,.21,.17,.15,.15,.17,.20,.23,.23,.25,.25,.20,.18,.16)
)
survey_hak1_fall <- data.frame(year = c(1992,1993,1996,1998), biomass = c(5028,3221,2026,2554), cv = c(.15,.14,.12,.18))
add_hak1_index <- function(z, season, survey) for (i in seq_len(nrow(z))) {
  add_input("mpi_hake_hak1_subantarctic_2024", "index", "total_biomass", "biomass", z$biomass[i], "tonnes",
    year = z$year[i], year_basis = "model_year", survey = survey, region = "Sub-Antarctic", season = season,
    source_reference = "Fisheries New Zealand FAR 2026/02, Table 5",
    notes = "Tangaroa relative biomass index. CV represents sampling error; the assessment adds process error. Survey month windows are reported, but no numerical within-year sampling fraction is specified.")
  add_input("mpi_hake_hak1_subantarctic_2024", "index", "biomass_index_cv", "relative_scale", z$cv[i], "ratio",
    year = z$year[i], year_basis = "model_year", survey = survey, region = "Sub-Antarctic", season = season,
    source_reference = "Fisheries New Zealand FAR 2026/02, Table 5",
    notes = "Source-reported sampling CV for the corresponding survey biomass observation.")
}
add_hak1_index(survey_hak1, "Nov-Dec", "Tangaroa Sub-Antarctic summer survey")
add_hak1_index(survey_hak1_fall, "Apr-May", "Tangaroa Sub-Antarctic autumn survey")

maturity_hak1 <- data.frame(
  age = rep(1:14, 2), sex = rep(c("M", "F"), each = 14),
  value = c(0,.001,.009,.098,.410,.694,.821,.885,.969,.990,.999,1,1,1,
    0,.002,.009,.048,.192,.481,.740,.875,.936,.966,.983,.992,.997,1)
)
for (i in seq_len(nrow(maturity_hak1))) add_input("mpi_hake_hak1_subantarctic_2024", "maturity", "maturity_at_age", "proportion",
  maturity_hak1$value[i], "proportion", age = maturity_hak1$age[i], sex = maturity_hak1$sex[i],
  region = "Sub-Antarctic", source_reference = "Fisheries New Zealand FAR 2026/02, Table 3",
  notes = "Time-invariant estimated rate of maturity, not a maturation rate.")

years_hak7 <- 1990:2024
catch_hak7 <- c(4903,6147,3026,7121,2958,8839,8662,6111,7404,8159,6895,8357,7519,7432,7943,7314,6905,7668,2617,5953,2346,3574,4459,5434,3641,6219,2863,4701,3085,1562,2063,1367,1324,1695,1695)
stopifnot(length(catch_hak7) == length(years_hak7))
for (i in seq_along(years_hak7)) add_input("mpi_hake_hak7_wcsi_2024", "catch", "total_biomass", "biomass", catch_hak7[i], "tonnes",
  year = years_hak7[i], year_basis = "model_year", fleet = "Total HAK 7 fishery", region = "West Coast South Island",
  source_reference = if (years_hak7[i] <= 2023) "Fisheries New Zealand FAR 2025/03, Table 1" else "Fisheries New Zealand FAR 2025/03, p. 5",
  notes = if (years_hak7[i] == 2024L) "Assumed 2023-24 catch, set equal to the reported 2022-23 catch of 1,695 t." else
    "Scaled catch in the October-September model year; this published table begins in 1990 although the model begins earlier.")

survey_hak7 <- data.frame(year = c(2000,2012,2013,2016,2018,2021), biomass = c(803.0,582.8,330.9,221.5,229.2,506.6), cv = c(.13,.13,.17,.24,.33,.34))
for (i in seq_len(nrow(survey_hak7))) {
  add_input("mpi_hake_hak7_wcsi_2024", "index", "total_biomass", "biomass", survey_hak7$biomass[i], "tonnes",
    year = survey_hak7$year[i], year_basis = "model_year", survey = "Tangaroa HAK 7 core strata", region = "West Coast South Island",
    season = "winter", source_reference = "Fisheries New Zealand FAR 2025/03, Table 4",
    notes = "The assessment uses core strata only. The 2016 survey may have underestimated biomass; the source reports a highly skewed sex ratio and low catch rate.")
  add_input("mpi_hake_hak7_wcsi_2024", "index", "biomass_index_cv", "relative_scale", survey_hak7$cv[i], "ratio",
    year = survey_hak7$year[i], year_basis = "model_year", survey = "Tangaroa HAK 7 core strata", region = "West Coast South Island",
    season = "winter", source_reference = "Fisheries New Zealand FAR 2025/03, Table 4",
    notes = "Source-reported sampling CV for the matching Tangaroa core-strata index; additional process error is treated separately in the assessment.")
}
maturity_hak7 <- data.frame(
  age = rep(1:10, 2), sex = rep(c("M", "F"), each = 10),
  value = c(0,.01,.05,.27,.73,.95,.99,1,1,1, 0,.02,.07,.25,.57,.84,.96,.99,1,1)
)
for (i in seq_len(nrow(maturity_hak7))) add_input("mpi_hake_hak7_wcsi_2024", "maturity", "maturity_at_age", "proportion",
  maturity_hak7$value[i], "proportion", age = maturity_hak7$age[i],
  sex = maturity_hak7$sex[i], region = "West Coast South Island",
  source_reference = "Fisheries New Zealand FAR 2025/03, Table 3",
  notes = if (maturity_hak7$age[i] == 10) "Age 10 is the 10+ group." else "Time-invariant maturity proportion.")

add_assumptions_hak1 <- function() {
  id <- "mpi_hake_hak1_subantarctic_2024"
  add_assumption(id, "assessment", "selected_base_model", "R5.0, 2025 base case; Casal2",
    "Fisheries New Zealand FAR 2026/02, sections 3.1-3.2")
  add_assumption(id, "population", "biological_stock_definition", "Sub-Antarctic HAK 1 biological stock, including Puysegur Bank",
    "Fisheries New Zealand FAR 2026/02, Figure 1 and Table 5",
    "Distinct from Chatham Rise hake within the HAK 1 administrative fishstock.")
  add_assumption(id, "timing", "model_year", "September-August; years labelled by ending year",
    "Fisheries New Zealand FAR 2026/02, Table 1")
  add_assumption(id, "population", "assessment_age_range", "Ages 2-25+, with age 25+ as the plus group",
    "Fisheries New Zealand FAR 2026/02, section 2.1.3")
  add_assumption(id, "catch", "catch_observations", "Scaled summer and winter catch totals; September catches in 1990-1994 assigned to the following model year",
    "Fisheries New Zealand FAR 2026/02, Table 1 and section 2.1.1")
  add_assumption(id, "composition", "age_composition_likelihood", "Sexed multinomial compositions; commercial fishery observations are split into summer and winter fisheries",
    "Fisheries New Zealand FAR 2026/02, section 2.1.3",
    "The report describes sample-size adjustment, but does not provide the full numerical age-composition vectors in tables.")
  add_assumption(id, "composition", "included_composition_years", "Commercial 1999-2024; survey years listed in FAR 2026/02 Table 4",
    "Fisheries New Zealand FAR 2026/02, Table 4")
  add_assumption(id, "index", "survey_biomass_likelihood", "Lognormal with sampling CV and separately estimated process error",
    "Fisheries New Zealand FAR 2026/02, section 2.1.3")
  add_assumption(id, "index", "survey_months", "Nov-Dec and Apr-May; September survey series excluded",
    "Fisheries New Zealand FAR 2026/02, Table 4 and section 2.1.3",
    "Exact within-year sampling fractions are not reported; sampling_time is left blank.")
  add_assumption(id, "mortality", "natural_mortality", "M = 0.19 yr-1 for both sexes; fixed in R5.0",
    "Fisheries New Zealand FAR 2026/02, Table 2",
    "The value is estimated only in sensitivity models.", sex = "M/F")
  add_assumption(id, "growth", "von_bertalanffy_parameters", "Male Linf=89.0 cm, k=0.29 yr-1, t0=-0.36 yr, CV=0.07; female Linf=113.9 cm, k=0.17 yr-1, t0=-1.07 yr, CV=0.09",
    "Fisheries New Zealand FAR 2026/02, Table 2",
    "Parameters are retained as reported; no weight-at-age surface is derived.")
  add_assumption(id, "growth", "length_weight_parameters", "Male a=2.35e-06, b=3.257; female a=2.46e-06, b=3.246",
    "Fisheries New Zealand FAR 2026/01, Table 3",
    "Length-weight relationship is weight=a*length^b; source units and parameter convention are retained.")
  add_assumption(id, "recruitment", "stock_recruitment", "Beverton-Holt; steepness h=0.8; recruitment variability sigma_R=1.1",
    "Fisheries New Zealand FAR 2026/02, Table 2")
  add_assumption(id, "biology", "ageing_error_cv", "0.08",
    "Fisheries New Zealand FAR 2026/02, Table 2")
  add_assumption(id, "biology", "sex_ratio_at_recruitment", "0.5 male",
    "Fisheries New Zealand FAR 2026/02, Table 2")
  add_assumption(id, "biology", "proportion_mature_that_spawn", "1.0",
    "Fisheries New Zealand FAR 2026/02, Table 2")
}
add_assumptions_hak1()

add_assumptions_hak7 <- function() {
  id <- "mpi_hake_hak7_wcsi_2024"
  add_assumption(id, "assessment", "selected_base_model", "R2.4, 2024 base case; Casal2",
    "Fisheries New Zealand FAR 2025/03, sections 2-3")
  add_assumption(id, "population", "biological_stock_definition", "West Coast South Island HAK 7 biological stock",
    "Fisheries New Zealand FAR 2025/03, Figure 1")
  add_assumption(id, "timing", "model_year", "October-September; years labelled by ending year",
    "Fisheries New Zealand FAR 2025/03, section 2.1.1")
  add_assumption(id, "population", "assessment_age_range", "Age 5 and older; younger fish excluded from the base case",
    "Fisheries New Zealand FAR 2025/03, section 2.1.3")
  add_assumption(id, "catch", "catch_observations", "Scaled HAK 7 catch history; 2023-24 catch assumed equal to 2022-23 catch",
    "Fisheries New Zealand FAR 2025/03, Table 1 and p. 5",
    "The published catch table starts in 1990; model history begins earlier.")
  add_assumption(id, "composition", "fishery_age_compositions", "Sexed compositions from deep, north shallow, and south shallow fisheries through 2022",
    "Fisheries New Zealand FAR 2025/03, section 2.1.3 and Table 5",
    "Numerical composition proportions are plotted, not tabulated. Base case R2.4 uses multinomial likelihoods and effective sample sizes.")
  add_assumption(id, "composition", "survey_age_compositions", "Sexed Tangaroa core-strata compositions through 2021",
    "Fisheries New Zealand FAR 2025/03, section 2.1.3 and Table 5",
    "Composition data are not age-specific abundance indices.")
  add_assumption(id, "index", "survey_index_series", "Tangaroa core strata only; Kaharoa inshore series excluded",
    "Fisheries New Zealand FAR 2025/03, Table 4 and section 2.1.3")
  add_assumption(id, "index", "survey_biomass_likelihood", "Lognormal with sampling CV and additional process error",
    "Fisheries New Zealand FAR 2025/03, section 2.1.3")
  add_assumption(id, "index", "survey_months", "Tangaroa HAK 7 surveys occur in July-August",
    "Fisheries New Zealand FAR 2025/03, Figure 4 and Fisheries New Zealand FAR 2026/06, Table 8",
    "No numerical within-year sampling fraction is reported; sampling_time is left blank.")
  add_assumption(id, "mortality", "natural_mortality", "M = 0.19 yr-1 for both sexes; fixed in the R2.4 base case",
    "Fisheries New Zealand FAR 2025/03, Table 2",
    "Alternative estimated-M structures are sensitivities, not the selected base case.", sex = "M/F")
  add_assumption(id, "growth", "von_bertalanffy_parameters", "Male k=0.329 yr-1, t0=-0.43 yr, Linf=83.1 cm, CV=0.07; female k=0.192 yr-1, t0=-0.98 yr, Linf=107.0 cm, CV=0.10",
    "Fisheries New Zealand FAR 2025/03, Table 2; cross-checked against Fisheries Assessment Plenary 2025, volume 1",
    "The FAR 2025/03 Table 2 labels t0 and Linf inconsistently; the Fisheries Assessment Plenary confirms the parameter mapping. No weight-at-age surface is derived.")
  add_assumption(id, "growth", "length_weight_parameters", "Male a=3.34e-06, b=3.175; female a=3.48e-06, b=3.177",
    "Fisheries New Zealand FAR 2025/03, Table 2",
    "Length-weight relationship is weight=a*length^b; values are retained as reported.")
  add_assumption(id, "recruitment", "stock_recruitment", "Beverton-Holt; steepness h=0.84; recruitment variability sigma_R=1.1",
    "Fisheries New Zealand FAR 2025/03, Table 2")
  add_assumption(id, "biology", "ageing_error_cv", "0.08",
    "Fisheries New Zealand FAR 2025/03, Table 2")
  add_assumption(id, "biology", "sex_ratio_at_recruitment", "0.5 male",
    "Fisheries New Zealand FAR 2025/03, Table 2")
  add_assumption(id, "biology", "proportion_mature_that_spawn", "1.0",
    "Fisheries New Zealand FAR 2025/03, Table 2")
  add_assumption(id, "biology", "maximum_exploitation_rate", "0.7",
    "Fisheries New Zealand FAR 2025/03, Table 2",
    "Constraint used to avoid implausible model estimates.")
}
add_assumptions_hak7()

add_output("mpi_hake_hak1_subantarctic_2024", "biomass", "unfished_spawning_biomass", 72577, "tonnes",
  lwr = 60157, upr = 93766, source_reference = "Fisheries New Zealand FAR 2026/02, Table 11 (printed p. 29)",
  notes = "R5.0 MCMC median and 95% credible interval.")
add_output("mpi_hake_hak1_subantarctic_2024", "biomass", "SSB", 47023, "tonnes", year = 2025,
  lwr = 33165, upr = 70417, source_reference = "Fisheries New Zealand FAR 2026/02, Table 11 (printed p. 29)",
  notes = "R5.0 MCMC median for B2025 and 95% credible interval.")
add_output("mpi_hake_hak1_subantarctic_2024", "biomass", "SSB_ratio_to_B0", 64.8, "percent", year = 2025,
  lwr = 52.3, upr = 79.0, source_reference = "Fisheries New Zealand FAR 2026/02, Table 11 (printed p. 29)",
  notes = "R5.0 MCMC median for B2025/B0 and 95% credible interval; values are percentages.")
add_output("mpi_hake_hak1_subantarctic_2024", "catchability", "q", .035, "dimensionless",
  survey = "Tangaroa Sub-Antarctic summer survey", lwr = .025, upr = .045,
  source_reference = "Fisheries New Zealand FAR 2026/02, Table 12 (printed p. 29)", notes = "R5.0 MCMC median and 95% credible interval for the Nov-Dec survey series.")
add_output("mpi_hake_hak1_subantarctic_2024", "catchability", "q", .056, "dimensionless",
  survey = "Tangaroa Sub-Antarctic autumn survey", lwr = .038, upr = .085,
  source_reference = "Fisheries New Zealand FAR 2026/02, Table 12 (printed p. 29)", notes = "R5.0 MCMC median and 95% credible interval for the Apr-May survey series.")

add_output("mpi_hake_hak7_wcsi_2024", "biomass", "unfished_spawning_biomass", 75480, "tonnes",
  lwr = 70830, upr = 81830, source_reference = "Fisheries New Zealand FAR 2025/03, Table 12 (printed p. 31)",
  notes = "R2.4 base-case MCMC median and 95% credible interval.")
add_output("mpi_hake_hak7_wcsi_2024", "biomass", "SSB", 35580, "tonnes", year = 2024,
  lwr = 24640, upr = 54660, source_reference = "Fisheries New Zealand FAR 2025/03, Table 12 (printed p. 31)",
  notes = "R2.4 base-case MCMC median for B2024 and 95% credible interval.")
add_output("mpi_hake_hak7_wcsi_2024", "biomass", "SSB_ratio_to_B0", 47.2, "percent", year = 2024,
  lwr = 34.5, upr = 67.5, source_reference = "Fisheries New Zealand FAR 2025/03, Table 12 (printed p. 31)",
  notes = "R2.4 base-case MCMC median for B2024/B0 and 95% credible interval; values are percentages.")
add_output("mpi_hake_hak7_wcsi_2024", "catchability", "q", .035, "dimensionless",
  survey = "Tangaroa HAK 7 core strata", lwr = .025, upr = .050,
  source_reference = "Fisheries New Zealand FAR 2025/03, Table 13 (printed p. 32)",
  notes = "R2.4 base-case MCMC median and 95% credible interval.")

fishery_hak1 <- data.frame(age = 3:26,
  male = c(808,NA,2010,17924,30813,35978,16538,11809,6995,3697,4941,NA,3910,NA,2227,2809,896,1755,1917,2272,1047,896,563,NA),
  male_cv = c(.9,NA,.6,.2,.2,.2,.2,.3,.3,.5,.5,NA,.5,NA,.6,.6,1,.7,.8,.6,1,1.1,1.1,NA),
  female = c(NA,1855,NA,874,7848,11544,14559,5148,8182,6225,3513,2486,1305,2662,2619,912,NA,1350,1275,763,NA,NA,NA,NA),
  female_cv = c(NA,.5,NA,1.1,.3,.3,.2,.4,.4,.4,.5,.4,.7,.5,.7,.9,NA,1,.8,.8,NA,NA,NA,NA))
for (i in seq_len(nrow(fishery_hak1))) for (sex in c("M", "F")) add_age_number(
  "mpi_hake_hak1_age_update_2024", "HAK1-commercial-2023-24", "catch", 2024, "model_year",
  fishery_hak1$age[i], if (sex == "M") fishery_hak1$male[i] else fishery_hak1$female[i],
  if (sex == "M") fishery_hak1$male_cv[i] else fishery_hak1$female_cv[i], sex,
  fleet = "Commercial trawl fishery", season = "2023-24 fishing year",
  source_reference = "Fisheries New Zealand FAR 2026/06, Table 3",
  notes = "Reported scaled numbers-at-age estimate from the 2023-24 fishery. The assessment uses sex-specific age-composition likelihoods; this table does not provide the full fitted likelihood vectors.",
  region = "Sub-Antarctic")

survey_age_hak1 <- data.frame(age = 1:28,
  male = c(NA,557,34845,48690,13285,4938,1328,564,NA,NA,2522,NA,NA,NA,NA,NA,NA,NA,NA,NA,294,1000,NA,NA,NA,NA,NA,NA),
  male_cv = c(NA,1.5,.4,.3,.4,.5,1.7,1.5,NA,NA,.9,NA,NA,NA,NA,NA,NA,NA,NA,NA,1.3,1.5,NA,NA,NA,NA,NA,NA),
  female = c(NA,564,29846,36885,24356,5879,12200,39554,10388,14654,8367,4724,5694,10647,7040,4439,1000,NA,17360,402,5155,4439,NA,NA,NA,NA,10126,NA),
  female_cv = c(NA,2.3,.5,.4,.4,.8,.6,.4,.8,.6,.8,1,1,.6,.8,1.1,1.6,NA,.7,2,1,1.1,NA,NA,NA,NA,1.3,NA))
for (i in seq_len(nrow(survey_age_hak1))) for (sex in c("M", "F")) add_age_number(
  "mpi_hake_hak1_age_update_2024", "HAK1-TAN2413", "index", 2025, "model_year",
  survey_age_hak1$age[i], if (sex == "M") survey_age_hak1$male[i] else survey_age_hak1$female[i],
  if (sex == "M") survey_age_hak1$male_cv[i] else survey_age_hak1$female_cv[i], sex,
  survey = "Tangaroa Sub-Antarctic summer survey", season = "Nov-Dec 2024",
  source_reference = "Fisheries New Zealand FAR 2026/06, Table 7",
  notes = "Reported estimated numbers-at-age from TAN2413. The 2024 survey is represented by model year 2025 in FAR 2026/02. Dashes are retained as missing source cells, not zeroes.",
  region = "Sub-Antarctic")

fishery_hak7 <- data.frame(age = 1:22,
  male = c(11511,8638,2857,24681,79114,43233,12135,905,2195,3077,764,4360,2430,1778,791,188,726,1897,NA,NA,867,NA),
  male_cv = c(.5,.5,.7,.2,.1,.2,.3,1.2,.8,.6,1.1,.6,.8,.9,1.1,1.6,1.1,.9,NA,NA,1.1,NA),
  female = c(9301,7280,2478,574,29796,72139,71196,27419,15021,12407,5685,6600,8028,7592,3646,2675,5563,2653,3143,550,NA,1340),
  female_cv = c(.7,.7,.5,1,.2,.1,.1,.2,.3,.3,.4,.4,.3,.4,.6,.6,.4,.5,.5,1.2,NA,1))
for (i in seq_len(nrow(fishery_hak7))) for (sex in c("M", "F")) add_age_number(
  "mpi_hake_hak7_age_update_2024", "HAK7-commercial-2023-24", "catch", 2024, "model_year",
  fishery_hak7$age[i], if (sex == "M") fishery_hak7$male[i] else fishery_hak7$female[i],
  if (sex == "M") fishery_hak7$male_cv[i] else fishery_hak7$female_cv[i], sex,
  fleet = "Commercial trawl fishery", season = "May-Sep 2024",
  source_reference = "Fisheries New Zealand FAR 2026/06, Table 5",
  notes = "Reported scaled numbers-at-age estimate for 2023-24. The 2024 assessment's fitted commercial age-composition series ends in 2022; this later table is kept as a separate data update.",
  region = "West Coast South Island")

survey_core_hak7 <- data.frame(age = 1:21,
  male = c(1658,NA,NA,1562,4993,1631,717,394,177,388,355,648,823,265,197,NA,175,NA,NA,66,NA),
  male_cv = c(.9,NA,NA,.8,.5,.6,.9,.9,1.4,1.4,1,.9,.9,1.3,1.6,NA,1.3,NA,NA,2.2,NA),
  female = c(311,724,NA,NA,3016,4345,3542,2024,940,529,625,79,321,698,185,982,1026,66,627,NA,NA),
  female_cv = c(1.4,1.4,NA,NA,.7,.5,.4,.6,.5,.9,.7,1,1.2,.8,1.1,.9,.9,1.9,1.2,NA,NA))
survey_all_hak7 <- data.frame(age = 1:24,
  male = c(1658,1609,1574,6581,31054,15390,8607,4073,2814,3103,3519,4934,6417,2846,3412,1457,1199,915,NA,524,547,NA,NA,NA),
  male_cv = c(.8,.8,1,.4,.4,.5,.6,.6,.7,.7,.6,.6,.6,.7,.7,1.2,.9,1,NA,1.1,1.7,NA,NA,NA),
  female = c(765,1500,1470,1114,11461,26079,19800,15219,8073,4313,5765,1527,2440,3639,2460,1929,3129,502,974,NA,NA,NA,NA,736),
  female_cv = c(1.1,.8,.8,.8,.4,.4,.4,.4,.6,.5,.5,.7,.6,.6,.6,.6,.5,1.2,.9,NA,NA,NA,NA,1))
for (z in list(list(data = survey_core_hak7, strata = "core"), list(data = survey_all_hak7, strata = "all"))) {
  tab <- z$data
  for (i in seq_len(nrow(tab))) for (sex in c("M", "F")) add_age_number(
    "mpi_hake_hak7_age_update_2024", paste0("HAK7-TAN2407-", z$strata), "index", 2024, "model_year",
    tab$age[i], if (sex == "M") tab$male[i] else tab$female[i],
    if (sex == "M") tab$male_cv[i] else tab$female_cv[i], sex,
    survey = paste("Tangaroa HAK 7", z$strata, "strata"), season = "Jul-Aug 2024",
    source_reference = "Fisheries New Zealand FAR 2026/06, Table 9",
    notes = paste("Reported estimated numbers-at-age from TAN2407", z$strata,
      "strata. This survey post-dates the HAK 7 2024 assessment's fitted age-composition data; retained separately from the assessment inputs. Dashes are missing source cells, not zeroes."),
    region = "West Coast South Island")
}

inputs <- do.call(rbind, input_rows)
assumptions <- do.call(rbind, assumption_rows)
outputs <- do.call(rbind, output_rows)
stopifnot(nrow(inputs[inputs$assessment_id == "mpi_hake_hak1_subantarctic_2024" & inputs$type == "catch", ]) == 102L,
  nrow(inputs[inputs$assessment_id == "mpi_hake_hak1_subantarctic_2024" & inputs$measure == "total_biomass", ]) == 126L,
  nrow(inputs[inputs$assessment_id == "mpi_hake_hak7_wcsi_2024" & inputs$type == "catch", ]) == 35L,
  nrow(inputs[inputs$assessment_id == "mpi_hake_hak7_wcsi_2024" & inputs$measure == "total_biomass", ]) == 41L,
  nrow(inputs[inputs$assessment_id == "mpi_hake_hak1_subantarctic_2024" & inputs$measure == "maturity_at_age", ]) == 28L,
  nrow(inputs[inputs$assessment_id == "mpi_hake_hak7_wcsi_2024" & inputs$measure == "maturity_at_age", ]) == 20L,
  nrow(outputs[outputs$assessment_id == "mpi_hake_hak1_subantarctic_2024", ]) == 5L,
  nrow(outputs[outputs$assessment_id == "mpi_hake_hak7_wcsi_2024", ]) == 4L)

stocks <- data.frame(
  stock_id = stock_ids, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = c("HAK 1", "HAK 7"), scientific_name = "Merluccius australis",
  common_name = c("Sub-Antarctic hake", "West Coast South Island hake"),
  area = c("Sub-Antarctic biological stock, including Puysegur Bank", "West Coast South Island biological stock"),
  region = "New Zealand waters", ocean = "Southwest Pacific",
  notes = c("HAK 1 is an administrative fishstock containing more than one biological stock; this record is the Sub-Antarctic unit.",
    "HAK 7 is the distinct West Coast South Island biological stock."), stringsAsFactors = FALSE
)
assessment_rows_out <- data.frame(
  assessment_id = assessment_ids,
  stock_id = c(stock_ids[1], stock_ids[1], stock_ids[2], stock_ids[2]),
  assessment_year = c(2025L, 2026L, 2024L, 2026L),
  terminal_year = c(2025L, 2024L, 2024L, 2024L), estimate_terminal_year = NA_integer_,
  assessment_type = c("full_assessment", "data_update", "full_assessment", "data_update"),
  model_family = c("Casal2", "Data update; no assessment model", "Casal2", "Data update; no assessment model"),
  model_version = c("R5.0, 2025 base case", "FAR 2026/06 catch-at-age estimates", "R2.4 base case", "FAR 2026/06 catch-at-age estimates"),
  is_current = c(TRUE, FALSE, TRUE, FALSE), is_applied = c(TRUE, FALSE, TRUE, FALSE),
  framework_year = NA_integer_,
  assessment_url = c(source_urls[2], source_urls[3], source_urls[5], source_urls[6]),
  framework_url = "", data_url = c(source_urls[1], source_urls[3], source_urls[6], source_urls[6]),
  model_url = "", repository_url = "",
  assumptions_status = c("partial", "not_applicable", "partial", "not_applicable"),
  inputs_status = c("partial", "complete", "partial", "complete"),
  outputs_status = c("partial", "not_applicable", "partial", "not_applicable"),
  notes = c(
    "Latest detailed HAK 1 Sub-Antarctic production assessment located; report published as FAR 2026/02 for the 2023-24 assessment cycle. Model-year terminal state is labelled 2025. The numerical historical age-composition likelihood vectors and a direct weight-at-age matrix are not tabulated.",
    "Supplementary official age-data tables for the 2023-24 commercial fishery and 2024 TAN2413 survey. These scaled numbers-at-age and their CVs are recorded separately from the fitted assessment and do not replace the assessment's composition likelihood vectors.",
    "Latest detailed HAK 7 production assessment located, for the 2023-24 fishing year. Catch and survey biomass index tables, maturity, assumptions and summary biomass outputs are recorded. Numerical age-composition likelihood vectors and direct weight-at-age values are not tabulated.",
    "Supplementary official 2023-24 commercial and 2024 TAN2407 core/all survey numbers-at-age. These data post-date the age-composition series fitted in the 2024 assessment and are not attached to that assessment's likelihood inputs."),
  stringsAsFactors = FALSE
)

read_csv <- function(file) read.csv(file.path(root, file), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stream_has_id <- function(path, id) {
  con <- file(path, open = "r"); on.exit(close(con))
  prefix <- paste0('"', id, '"')
  repeat { chunk <- readLines(con, n = 20000L, warn = FALSE); if (!length(chunk)) return(FALSE)
    if (any(startsWith(chunk, prefix))) return(TRUE) }
}
append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
  row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
replace_register_row <- function(path, field, id, values) {
  z <- read_csv(path); hit <- which(z[[field]] == id)
  if (length(hit) != 1L) stop("Expected exactly one register row for ", id, ".", call. = FALSE)
  for (name in names(values)) z[[name]][hit] <- values[[name]]
  write.csv(z, path, row.names = FALSE, na = "")
}

if (write_mode || inputs_only) {
  if (write_mode) {
  for (file in c("stocks.csv", "assessments.csv", "inputs.csv", "assumptions.csv", "outputs.csv")) {
    ids <- if (file == "stocks.csv") stock_ids else assessment_ids
    if (any(vapply(ids, function(id) stream_has_id(file.path(root, "database", file), id), logical(1)))) {
      stop("A HAK1/HAK7 stock or assessment ID already exists in ", file, "; review before importing.", call. = FALSE)
    }
  }
    for (i in seq_len(nrow(stocks))) append_csv(stocks[i, ], file.path(root, "database", "stocks.csv"))
    append_csv(assessment_rows_out, file.path(root, "database", "assessments.csv"))
  }
  append_csv(inputs, file.path(root, "database", "inputs.csv"))
  if (write_mode) {
    append_csv(assumptions, file.path(root, "database", "assumptions.csv"))
    append_csv(outputs, file.path(root, "database", "outputs.csv"))
    write.csv(manifest_rows(1:4), file.path(root, "provenance", "mpi_hake_hak1_2024_sources.csv"), row.names = FALSE, na = "")
    write.csv(manifest_rows(5:7), file.path(root, "provenance", "mpi_hake_hak7_2024_sources.csv"), row.names = FALSE, na = "")
    for (i in seq_along(stock_ids)) {
    candidate_id <- if (i == 1L) "MPI:HAK1:SubAntarctic" else "MPI:HAK7:WCSI"
    replace_register_row(file.path(root, "discovery", "candidates.csv"), "candidate_id", candidate_id, list(
      matched_stock_id = stock_ids[i], import_status = "partial",
      inventory_assessment_year = if (i == 1L) 2025L else 2024L,
      catch_age_evidence = if (i == 1L) "Imported scaled summer/winter catch totals for 1975-2025 and separate official 2023-24 sex-specific numbers-at-age estimates. The assessment's exact historical age-composition likelihood vectors are not tabulated." else
        "Imported scaled HAK 7 catch totals for 1990-2024 and separate official 2023-24 sex-specific catch numbers-at-age. The assessment's fitted fishery age compositions extend through 2022 and are not numerically tabulated.",
      survey_age_evidence = if (i == 1L) "Imported Tangaroa Nov-Dec and Apr-May biomass indices with source CVs; retained the 2024 TAN2413 sex-specific numbers-at-age separately as model year 2025. Historical age compositions are only plotted." else
        "Imported Tangaroa core-strata biomass indices with CVs for 2000-2021. Separate 2024 TAN2407 core/all sex-specific numbers-at-age are recorded as a post-fit data update, not as assessment likelihood inputs.",
      weights_evidence = if (i == 1L) "FAR 2026/01 reports sex-specific length-weight and growth parameters. No direct weight-at-age surface was found; no derived weight surface was added." else
        "Sex-specific growth and length-weight parameters are preserved as assumptions. No direct weight-at-age surface was found; no derived weight surface was added.",
      maturity_evidence = if (i == 1L) "Imported the FAR 2026/02 Table 3 male and female maturity proportions at ages 1-14." else
        "Imported FAR 2025/03 Table 3 male and female maturity proportions at ages 1-10+, preserving the plus group.",
      mortality_evidence = "The selected base model fixes sex-specific natural mortality at 0.19 yr-1; estimated-M alternatives are sensitivities only.",
      timing_evidence = if (i == 1L) "Model year is September-August; survey timing is Nov-Dec or Apr-May. The reports do not provide a numerical within-year sampling fraction." else
        "Model year is October-September; Tangaroa surveys are in July-August. The reports do not provide a numerical within-year sampling fraction.",
      output_evidence = if (i == 1L) "Imported base-case MCMC medians and 95% credible intervals for B0, B2025, B2025/B0 and catchability for both survey series." else
        "Imported base-case MCMC medians and 95% credible intervals for B0, B2024, B2024/B0 and Tangaroa survey catchability. Annual N-at-age, F-at-age and recruitment values are shown as figures, not numerical tables."
    ))
      replace_register_row(file.path(root, "discovery", "selected_batch_03_2026.csv"), "candidate_id", candidate_id,
        list(inventory_assessment_year = if (i == 1L) 2025L else 2024L,
          curation_status = "partial_source_import"))
    }
  }
}

cat("New Zealand hake source import ", if (write_mode) "written" else "validated (dry run)",
  ": ", nrow(inputs), " input rows, ", nrow(assumptions), " assumptions, ", nrow(outputs),
  " outputs across two production assessments and two supplemental data updates.\n", sep = "")
