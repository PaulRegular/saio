root <- "."
db <- file.path(root, "database")
cache <- file.path(root, "source_cache", "nefsc_american_plaice_5yz")
model_dir <- file.path(cache, "2022", "research_track")
assessment_id <- "nefsc_american_plaice_5yz_2022_run29f4"
summary_2024_id <- "nefsc_american_plaice_5yz_2024_mt"
summary_2026_id <- "nefsc_american_plaice_5yz_2026_mt_provisional"
stock_id <- "ck_nefsc_platessoides_5yz"
report_2024 <- "https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9879"
report_2026 <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=2&stock_id=4&review_type_id=6&filename=2026_PLA_GMGB.zip"
report_2022 <- "https://www.fisheries.noaa.gov/event/american-plaice-2022-research-track-assessment-peer-review-meeting"
data_2022 <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=2&stock_id=4&review_type_id=5&filename=2022_PLA_GMGB_1.zip"
model_repository <- "https://github.com/ahart1/PlaiceWG2021/tree/be1dbc66ebef7fa2fe2614fee0fe9646051b97c3"

abort <- function(...) stop(paste0(...), call. = FALSE)
input_file <- file.path(model_dir, "WHAM_Run29F4_input.rds")
model_file <- file.path(model_dir, "WHAM_Run29F4_model.rds")
if (!file.exists(input_file) || !file.exists(model_file)) {
  abort("Cached Run29F4 WHAM input and model objects are required in ", model_dir)
}
i <- readRDS(input_file)
m <- readRDS(model_file)
d <- i$data
years <- as.integer(i$years)
ages <- seq_len(dim(d$waa)[3L])
if (!identical(years, 1980:2019) || !identical(ages, 1:11) ||
    !identical(dim(d$agg_indices), c(40L, 4L)) ||
    !identical(dim(d$index_paa), c(4L, 40L, 11L))) {
  abort("Run29F4 year, age, or index dimensions changed; review before import.")
}
catch_sums <- rowSums(d$catch_paa[1L, , ])
index_sums <- t(apply(d$index_paa, c(1L, 2L), sum))
if (!all(abs(catch_sums - 1) < 1e-8) ||
    !all(abs(index_sums[d$use_index_paa == 1L] - 1) < 1e-8)) {
  abort("A native catch or survey age-composition row does not sum to one.")
}
if (!all(d$mature == matrix(d$mature[1L, ], nrow = length(years),
                             ncol = length(ages), byrow = TRUE))) {
  abort("The maturity schedule is not constant as expected for Run29F4.")
}
if (length(i$par$M_a) != length(ages) ||
    any(abs(exp(i$par$M_a) - 0.3) > 1e-10)) {
  abort("The fixed M input changed; review the source before importing.")
}

series <- data.frame(
  index = 1:4,
  survey = c("NEFSC spring Albatross", "NEFSC spring Bigelow",
             "NEFSC fall Albatross", "NEFSC fall Bigelow"),
  season = c("spring", "spring", "fall", "fall"),
  stringsAsFactors = FALSE
)
source_ref <- function(object) paste0("WHAM_Run29F4_", object)

make_input <- function(id, type, measure, basis, value, unit,
                       year = NA_integer_, age = NA_integer_, fleet = NA_character_,
                       survey = NA_character_, season = NA_character_,
                       sample_size = NA_real_, sampling_time = NA_real_,
                       source_type = "native_model", source_reference,
                       transformation = "Reshaped from the native Run29F4 WHAM object without changing values.",
                       notes = "") {
  n <- length(value)
  rep_n <- function(x) {
    if (length(x) == n) return(x)
    if (length(x) != 1L) abort("Input fields do not align to the values being imported.")
    rep(x, n)
  }
  year <- rep_n(year)
  age <- rep_n(age)
  data.frame(
    assessment_id = rep(id, n), type = rep_n(type), measure = rep_n(measure),
    basis = rep_n(basis), fleet = rep_n(fleet), survey = rep_n(survey),
    sex = rep(NA_character_, n), region = rep(NA_character_, n),
    season = rep_n(season), year = year,
    year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = age, value = as.numeric(value), unit = rep_n(unit),
    sampling_time = as.numeric(rep_n(sampling_time)),
    source_type = rep_n(source_type), source_reference = rep_n(source_reference),
    transformation = rep_n(transformation), notes = rep_n(notes),
    observation_id = rep(NA_character_, n), length_bin = rep(NA_real_, n),
    length_bin_lower = rep(NA_real_, n), length_bin_upper = rep(NA_real_, n),
    sample_size = as.numeric(rep_n(sample_size)), age_error = rep(NA_real_, n),
    partition = rep(NA_character_, n), stringsAsFactors = FALSE
  )
}

make_surface_input <- function(type, measure, basis, values, unit, reference,
                               survey = NA_character_, season = NA_character_,
                               fleet = NA_character_, notes = "") {
  grid <- expand.grid(age = ages, year = years)
  make_input(
    assessment_id, type, measure, basis, as.vector(t(values)), unit,
    year = grid$year, age = grid$age, fleet = fleet, survey = survey,
    season = season, source_reference = source_ref(reference), notes = notes
  )
}

inputs_2022 <- list(
  make_input(assessment_id, "catch", "total_numbers", "numbers", d$agg_catch[, 1L],
    "thousand fish", year = years, fleet = "Commercial fishery",
    source_reference = source_ref("data$agg_catch"),
    notes = "Annual total catch number input used with catch proportions-at-age."),
  make_input(assessment_id, "catch", "index_sd", "log_scale", d$agg_catch_sigma[, 1L],
    "log SD", year = years, fleet = "Commercial fishery",
    source_reference = source_ref("data$agg_catch_sigma"),
    notes = "Native aggregate-catch log-scale standard deviation; the model uses a catch scale parameter."),
  make_input(assessment_id, "catch", "proportion_at_age", "proportion_numbers",
    as.vector(t(d$catch_paa[1L, , ])), "proportion",
    year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
    fleet = "Commercial fishery",
    sample_size = rep(d$catch_Neff[, 1L], each = length(ages)),
    source_reference = source_ref("data$catch_paa"),
    notes = "Native number proportions; sample_size is the source effective sample size."),
  make_surface_input("catch_weight", "weight_at_age", "kg_per_fish", d$waa[1L, , ],
    "kg/fish", "data$waa[1,,]", fleet = "Commercial fishery",
    notes = "Catch weight-at-age surface from native weight pointer 1."),
  make_surface_input("weight", "weight_at_age", "kg_per_fish", d$waa[2L, , ],
    "kg/fish", "data$waa[2,,]",
    notes = "Beginning-of-year stock weight surface; pointer used for January 1 and SSB calculations."),
  make_input(assessment_id, "maturity", "maturity_at_age", "proportion",
    d$mature[1L, ], "proportion", age = ages,
    source_reference = source_ref("data$mature"),
    notes = "The native model repeats this constant maturity schedule in each year."),
  make_input(assessment_id, "M", "natural_mortality_at_age", "per_year",
    exp(i$par$M_a), "per year", age = ages,
    source_reference = source_ref("par$M_a and data$M_est"),
    notes = "Natural mortality fixed at 0.3 per year for all ages and years.")
)

for (j in seq_len(nrow(series))) {
  survey <- series$survey[j]
  season <- series$season[j]
  pointer <- d$waa_pointer_indices[j]
  inputs_2022[[length(inputs_2022) + 1L]] <- make_surface_input(
    "weight", "weight_at_age", "kg_per_fish", d$waa[pointer, , ], "kg/fish",
    paste0("data$waa[", pointer, ",,] via data$waa_pointer_indices[", j, "]"),
    survey = survey, season = season,
    notes = paste("Native survey weight pointer", pointer,
                  "for this index; repeated annually as stored in the model object.")
  )
  active <- which(d$use_indices[, j] == 1L)
  if (!length(active)) abort("A modeled survey has no aggregate-index observations.")
  inputs_2022[[length(inputs_2022) + 1L]] <- make_input(
    assessment_id, "index", "total_biomass", "biomass",
    d$agg_indices[active, j], "kg/tow", year = years[active],
    survey = survey, season = season,
    sampling_time = d$fracyr_indices[active, j],
    source_reference = source_ref("data$agg_indices"),
    notes = "Native aggregate biomass index. Bigelow observations are not calibrated to Albatross units in this candidate run."
  )
  inputs_2022[[length(inputs_2022) + 1L]] <- make_input(
    assessment_id, "index", "log_index_sd", "log_scale",
    d$agg_index_sigma[active, j], "log SD", year = years[active],
    survey = survey, season = season,
    source_reference = source_ref("data$agg_index_sigma"),
    notes = "Native year- and index-specific log-scale observation SD input."
  )
  composition_years <- which(d$use_index_paa[, j] == 1L)
  for (t in composition_years) {
    inputs_2022[[length(inputs_2022) + 1L]] <- make_input(
      assessment_id, "index", "proportion_at_age", "proportion_numbers",
      d$index_paa[j, t, ], "proportion", year = years[t], age = ages,
      survey = survey, season = season,
      sample_size = d$index_Neff[t, j],
      sampling_time = d$fracyr_indices[t, j],
      source_reference = source_ref("data$index_paa"),
      notes = "Native number composition; sample_size is the source effective sample size."
    )
  }
}
inputs_2022 <- do.call(rbind, inputs_2022)

assumption <- function(id, component, setting, value, reference, notes = "",
                       survey = NA_character_, season = NA_character_) {
  data.frame(
    assessment_id = id, component = component, fleet = NA_character_,
    survey = survey, sex = NA_character_, region = NA_character_, season = season,
    setting = setting, value = as.character(value), source_reference = reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
assumptions_2022 <- do.call(rbind, list(
  assumption(assessment_id, "assessment", "run", "2022 Research Track candidate Run29F4",
    source_ref("WHAM_Run29F4_input.rds and model.rds"),
    "One of three candidate runs (29F2, 29F4, 29F5); exact adoption as the production advice model is not established."),
  assumption(assessment_id, "model", "model_version", m$wham_version,
    source_ref("model$wham_version")),
  assumption(assessment_id, "population", "year_range", "1980-2019",
    source_ref("input$years")),
  assumption(assessment_id, "population", "age_range", "Ages 1-10 and 11+",
    source_ref("input$ages.lab")),
  assumption(assessment_id, "N", "process",
    "Random effects on all N-at-age states; age-1 and ages-2+ use separate process SDs; age/time correlations fixed at zero.",
    source_ref("data$NAA_sigma_pointers and input$map$trans_NAA_rho"),
    "The native model therefore uses independent state errors across years and ages, with two SD groups."),
  assumption(assessment_id, "recruitment", "stock_recruit",
    "No stock-recruit relationship; recruitment varies around an estimated mean.",
    "WP18 Hart et al., Section 4.12"),
  assumption(assessment_id, "F", "selectivity",
    "One fishery; logistic fleet selectivity with a time-varying selectivity random effect.",
    "WP18 Hart et al., Section 4.12; native model object"),
  assumption(assessment_id, "index", "selectivity",
    "Four age-specific index selectivity patterns; one age per index fixed at full selectivity; no index selectivity random effects in Run29F4.",
    "WP18 Hart et al., Section 4.12.1"),
  assumption(assessment_id, "M", "process", "Fixed at 0.3 per year across ages and time.",
    "WP18 Hart et al., Section 4.12; native input par$M_a"),
  assumption(assessment_id, "catch", "likelihood",
    "Aggregate catch lognormal; number composition modeled with logistic-normal likelihood and effective sample size 100.",
    "Native data arrays; WP18 Hart et al., Sections 4.12 and 4.10"),
  assumption(assessment_id, "index", "likelihood",
    "Aggregate biomass indices in kg/tow and number compositions for four seasonal/vessel series; logistic-normal age-composition likelihood with effective sample size 50.",
    "WP18 Hart et al., Section 4.12; native data arrays"),
  assumption(assessment_id, "biology", "maturity",
    "Constant age-specific maturity schedule repeated over 1980-2019.",
    source_ref("data$mature")),
  assumption(assessment_id, "biology", "spawning_time", "0.25 of year",
    source_ref("data$fracyr_SSB")),
  assumption(assessment_id, "index", "index_series_order",
    "1 spring Albatross; 2 spring Bigelow; 3 fall Albatross; 4 fall Bigelow.",
    "WP18 Hart et al., Section 4.12; age compositions matched to WP20 Alade survey tables 6-7"),
  assumption(assessment_id, "index", "timing_mapping",
    "Native fracyr_indices columns are 0.25, 0.75, 0.25, 0.75 for series 1-4.",
    source_ref("data$fracyr_indices"),
    "The middle two timing values conflict with the season identities in the age-composition arrays (series 2 is spring, series 3 is fall). The source timing values are retained verbatim in inputs; the mismatch is unresolved.")
))

output_frame <- function(id, type, measure, value, unit, year = NA_integer_,
                         age = NA_integer_, age_group = NA_character_, se = NA_real_,
                         source_type = "native_model", source_reference,
                         notes = "") {
  n <- length(value)
  rep_n <- function(x) {
    if (length(x) == n) return(x)
    if (length(x) != 1L) abort("Output fields do not align to the values being imported.")
    rep(x, n)
  }
  data.frame(
    assessment_id = rep(id, n), type = rep_n(type), measure = rep_n(measure),
    fleet = rep(NA_character_, n), survey = rep(NA_character_, n),
    sex = rep(NA_character_, n), region = rep(NA_character_, n),
    season = rep(NA_character_, n), year = rep_n(year), age = rep_n(age),
    age_group = rep_n(age_group), value = as.numeric(value), se = as.numeric(rep_n(se)),
    lwr = rep(NA_real_, n), upr = rep(NA_real_, n), unit = rep_n(unit),
    source_type = rep_n(source_type), source_reference = rep_n(source_reference),
    notes = rep_n(notes), stringsAsFactors = FALSE
  )
}

sd_matrix <- function(name, nrow, ncol) {
  index <- which(names(m$sdrep$value) == name)
  if (length(index) != nrow * ncol) abort("Unexpected uncertainty dimensions for ", name)
  matrix(m$sdrep$sd[index], nrow = nrow, ncol = ncol)
}

N <- m$rep$NAA
F <- m$rep$FAA[, 1L, ]
N_se <- N * sd_matrix("log_NAA_rep", length(years), length(ages))
F_se <- F * sd_matrix("log_FAA", length(years), length(ages))
SSB <- as.numeric(m$rep$SSB)
SSB_log_se <- m$sdrep$sd[names(m$sdrep$value) == "log_SSB"]
Fbar <- as.numeric(m$rep$Fbar)
Fbar_log_se <- m$sdrep$sd[names(m$sdrep$value) == "log_Fbar"]
if (length(SSB) != length(years) || length(SSB_log_se) != length(years) ||
    length(Fbar) != length(years) || length(Fbar_log_se) != length(years)) {
  abort("Unexpected output dimensions in the cached Run29F4 model object.")
}
output_grid <- expand.grid(age = ages, year = years)
outputs_2022 <- list(
  output_frame(assessment_id, "population", "numbers_at_age", as.vector(t(N)),
    "thousand fish", year = output_grid$year, age = output_grid$age,
    se = as.vector(t(N_se)), source_reference = source_ref("model$rep$NAA and model$sdrep$log_NAA_rep"),
    notes = "SE uses the delta method: N times the SD of log N."),
  output_frame(assessment_id, "mortality", "fishing_mortality_at_age", as.vector(t(F)),
    "per year", year = output_grid$year, age = output_grid$age,
    se = as.vector(t(F_se)), source_reference = source_ref("model$rep$FAA and model$sdrep$log_FAA"),
    notes = "SE uses the delta method: F times the SD of log F."),
  output_frame(assessment_id, "biomass", "SSB", SSB, "metric tonnes", year = years,
    se = SSB * SSB_log_se, source_reference = source_ref("model$rep$SSB and model$sdrep$log_SSB"),
    notes = "SE uses the delta method: SSB times the SD of log SSB."),
  output_frame(assessment_id, "recruitment", "recruitment", N[, 1L], "thousand fish",
    year = years, age = 1L, se = N_se[, 1L],
    source_type = "derived_source_output",
    source_reference = source_ref("model$rep$NAA[,1]"),
    notes = "Age-1 abundance in the same year; SE is copied from the matching N-at-age estimate."),
  output_frame(assessment_id, "population", "total_numbers", rowSums(N), "thousand fish",
    year = years, source_type = "derived_source_output",
    source_reference = source_ref("model$rep$NAA"),
    notes = "Derived by summing all source age groups. No uncertainty is reported because cross-age covariance is not exported."),
  output_frame(assessment_id, "mortality", "Fbar", Fbar, "per year", year = years,
    age_group = "6-9", se = Fbar * Fbar_log_se,
    source_reference = source_ref("model$rep$Fbar and model$sdrep$log_Fbar"),
    notes = "Native fully selected Fbar over ages 6-9; SE uses the delta method.")
)
outputs_2022 <- do.call(rbind, outputs_2022)

summary_outputs <- function(id, years, ssb, fbar, recruitment, reference) {
  note <- "Transcribed from the official summary table; no numerical uncertainty is reported in the table."
  rbind(
    output_frame(id, "biomass", "SSB", ssb, "metric tonnes", year = years,
      source_type = "official_table", source_reference = reference, notes = note),
    output_frame(id, "mortality", "Fbar", fbar, "per year", year = years,
      age_group = "6-9", source_type = "official_table", source_reference = reference, notes = note),
    output_frame(id, "recruitment", "recruitment", recruitment, "thousand fish",
      year = years, age = 1L, source_type = "official_table",
      source_reference = reference, notes = note)
  )
}
outputs_2024 <- summary_outputs(
  summary_2024_id, 2014:2023,
  c(32766, 37035, 45530, 48698, 45743, 30378, 23682, 19644, 21206, 25248),
  c(0.042, 0.041, 0.030, 0.029, 0.027, 0.037, 0.031, 0.041, 0.041, 0.057),
  c(109468, 28942, 59527, 15283, 69501, 40833, 56544, 65743, 61410, 46657),
  "2024 Management Track report, Table 1"
)

summary_catch_inputs <- function(id, years, landings, discards, total_catch, reference) {
  note <- paste(
    "Aggregate values reported in the assessment data table; these do not recover",
    "the age-specific catch inputs or catch likelihood."
  )
  rbind(
    make_input(id, "catch", "landings_biomass", "biomass", landings,
      "metric tonnes", year = years, fleet = "Commercial fishery",
      source_type = "official_table", source_reference = reference,
      transformation = "Transcribed from the reported table; no unit conversion.",
      notes = paste(note, "Commercial landings are a component of total catch.")),
    make_input(id, "catch", "discard_biomass", "biomass", discards,
      "metric tonnes", year = years, fleet = "Commercial fishery",
      source_type = "official_table", source_reference = reference,
      transformation = "Transcribed from the reported table; no unit conversion.",
      notes = paste(note, "Commercial discards are a component of total catch.")),
    make_input(id, "catch", "total_biomass", "biomass", total_catch,
      "metric tonnes", year = years, fleet = "Commercial fishery",
      source_type = "official_table", source_reference = reference,
      transformation = "Transcribed from the reported table; no unit conversion.",
      notes = paste(note,
        "The table's rounded total can differ by 1 tonne from the displayed component sum and is not an independent observation."))
  )
}

inputs_2024 <- summary_catch_inputs(
  summary_2024_id, 2014:2023,
  c(1239, 1231, 1009, 1134, 1087, 970, 597, 631, 699, 1168),
  c(92, 86, 108, 102, 109, 78, 74, 71, 58, 77),
  c(1331, 1317, 1117, 1235, 1196, 1048, 671, 702, 757, 1244),
  "2024 Management Track report, Table 1"
)

outputs_2026 <- summary_outputs(
  summary_2026_id, 2015:2025,
  c(33204, 40571, 43962, 39307, 24660, 19003, 13930, 15653, 21966, 21473, 17169),
  c(0.046, 0.034, 0.033, 0.034, 0.045, 0.038, 0.060, 0.047, 0.054, 0.072, 0.096),
  c(22165, 47319, 11948, 48920, 31538, 40894, 45050, 37294, 20696, 8103, 32473),
  "2026 Management Track assessment report, Tables 1-2 (provisional report)"
)

assumptions_2024 <- do.call(rbind, list(
  assumption(summary_2024_id, "model", "model_family", "WHAM",
    "2024 Management Track report, Table 1 and text"),
  assumption(summary_2024_id, "population", "terminal_year", "2023",
    "2024 Management Track report, Table 1"),
  assumption(summary_2024_id, "catch", "age_composition_years",
    "Catch age-composition data excluded for 2018-2023 due a landings-at-length processing bias.",
    "2024 Management Track report, Special Comments"),
  assumption(summary_2024_id, "outputs", "age_specific_results",
    "N-at-age, F-at-age, and M-at-age numerical outputs were not recovered from the available report/archive.",
    "2024 Management Track report and cached SASI archive")
))
assumptions_2026 <- do.call(rbind, list(
  assumption(summary_2026_id, "model", "model_family", "WHAM 2.1.0.9007",
    "2026 provisional Management Track report, pp. 4-6"),
  assumption(summary_2026_id, "population", "terminal_year", "2025",
    "2026 provisional Management Track report, Tables 1-2"),
  assumption(summary_2026_id, "catch", "age_composition_years",
    "Age-composition data incorporated from 2018-2025.",
    "2026 provisional Management Track report, p. 4"),
  assumption(summary_2026_id, "M", "process", "Not resolved from the provisional summary report.",
    "2026 provisional Management Track report", "No numeric age-specific M or native model object was found."),
  assumption(summary_2026_id, "assessment", "publication_status",
    "Provisional, pre-review/pre-decisional report; not a formal publication.",
    "2026 provisional Management Track report, disclaimer",
    "The September 2026 review panel report is cached separately; no final production input/output archive was found.")
))

assessments <- data.frame(
  assessment_id = c(assessment_id, summary_2024_id, summary_2026_id),
  stock_id = stock_id,
  assessment_year = c(2022L, 2024L, 2026L),
  terminal_year = c(2019L, 2023L, 2025L),
  estimate_terminal_year = c(2019L, 2023L, 2025L),
  assessment_type = c("research_track_candidate", "management_track_update", "provisional_management_track_update"),
  model_family = c("WHAM", "WHAM", "WHAM"),
  model_version = c(paste("WHAM", m$wham_version, "Run29F4 candidate"),
                    "2024 Management Track update", "2026 Management Track MT3; peer reviewed, report pre-decisional"),
  is_current = c(FALSE, FALSE, TRUE),
  is_applied = c(FALSE, TRUE, FALSE),
  framework_year = c(2022L, 2022L, 2022L),
  assessment_url = c(report_2022, report_2024,
                     "https://www.fisheries.noaa.gov/event/peer-review-2026-september-management-track-assessments"),
  framework_url = c(data_2022,
                    "https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf",
                    "https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf"),
  data_url = c(data_2022, "", report_2026),
  model_url = c(model_repository, "", ""),
  repository_url = c(model_repository, "", ""),
  assumptions_status = c("partial", "partial", "partial"),
  inputs_status = c("complete", "partial", "partial"),
  outputs_status = c("complete", "partial", "partial"),
  notes = c(
    "Full native WHAM Run29F4 inputs and fitted outputs are cached. Run29F4 was one of three 2022 research-track candidates; the exact candidate adopted for management advice is not established. The report's 2022 research-track model informed subsequent Management Track assessments.",
    "Official 2024 Management Track aggregate catch data and summary outputs are recorded, but its age-specific model inputs and fitted surfaces were not recovered. Values are not mixed with the 2022 candidate run.",
    "The 2026 MT3 assessment passed September 2026 peer review. Available report remains pre-decisional and no native inputs or age surfaces were found. Advice adoption has not been verified; is_applied remains FALSE."
  ), stringsAsFactors = FALSE
)

replace_rows <- function(name, ids, rows) {
  path <- file.path(db, name)
  schema <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  missing <- setdiff(schema, names(rows))
  if (length(missing)) abort(name, " rows missing columns: ", paste(missing, collapse = ", "))
  rows <- rows[, schema, drop = FALSE]
  if (name %in% c("stocks.csv", "assessments.csv")) {
    old <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = "")
    id_column <- if (name == "stocks.csv") "stock_id" else "assessment_id"
    old <- old[!old[[id_column]] %in% ids, , drop = FALSE]
    result <- rbind(old, rows)
    write.csv(result, path, row.names = FALSE, na = "")
    return(invisible(nrow(rows)))
  }
  temp_rows <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_rows), add = TRUE)
  write.csv(rows, temp_rows, row.names = FALSE, na = "")
  appended <- readLines(temp_rows, warn = FALSE, encoding = "bytes")[-1L]
  write_bytes <- function(lines, connection) {
    if (length(lines)) writeBin(charToRaw(paste0(paste(lines, collapse = "\r\n"), "\r\n")), connection)
  }
  input <- file(path, open = "rb")
  on.exit(try(close(input), silent = TRUE), add = TRUE)
  temp_path <- tempfile(tmpdir = dirname(path))
  output <- file(temp_path, open = "wb")
  on.exit({ try(close(output), silent = TRUE); unlink(temp_path) }, add = TRUE)
  header <- readLines(input, n = 1L, warn = FALSE, encoding = "bytes")
  write_bytes(header, output)
  repeat {
    chunk <- readLines(input, n = 10000L, warn = FALSE, encoding = "bytes")
    if (!length(chunk)) break
    first_field <- sub('^"?([^",]*).*$','\\1', chunk)
    write_bytes(chunk[!first_field %in% ids], output)
  }
  write_bytes(appended, output)
  close(output); close(input)
  if (!file.copy(temp_path, path, overwrite = TRUE)) abort("Could not replace ", path)
  invisible(nrow(rows))
}

stocks <- read.csv(file.path(db, "stocks.csv"), stringsAsFactors = FALSE,
                   check.names = FALSE, na.strings = "")
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
if (nrow(stock) != 1L) abort("Expected one existing Charbonneau-Keith American plaice stock row.")
stock$common_name <- "American plaice"
stock$notes <- paste(
  "Gulf of Maine/Georges Bank American plaice, NEFSC area 5YZ.",
  "The most recent full native assessment candidate with recoverable inputs and fitted outputs is 2022 WHAM Run29F4; 2024 official summary outputs and a separate provisional 2026 Management Track summary are recorded without mixing runs.",
  "Charbonneau-Keith Master.csv identifier NEFSC_platessoides_5YZ retained."
)

replace_rows("stocks.csv", stock_id, stock)
replace_rows("assessments.csv", assessments$assessment_id, assessments)
replace_rows("assumptions.csv", c(assessment_id, summary_2024_id, summary_2026_id),
             rbind(assumptions_2022, assumptions_2024, assumptions_2026))
replace_rows("inputs.csv", c(assessment_id, summary_2024_id),
             rbind(inputs_2022, inputs_2024))
replace_rows("outputs.csv", c(assessment_id, summary_2024_id, summary_2026_id),
             rbind(outputs_2022, outputs_2024, outputs_2026))

cat("Imported Run29F4", nrow(inputs_2022), "input rows and", nrow(outputs_2022),
    "fitted outputs; added 2024 aggregate catch inputs and 2024/provisional 2026 summary outputs.\n")


# Add the 2026 peer-review evidence and independently verified recent catch.
source("scripts/database/175_update_nefsc_plaice_2026.R")
