assessment_id <- "mpi_ling_lin7wc_2026"
stock_id <- "mpi_ling_lin7wc"
candidate_id <- "MPI:LIN7WC"
source_cache <- "source_cache/mpi_ling_lin7wc_2026"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

source_files <- data.frame(
  local_file = c(
    file.path(source_cache, "FAR-2026-26.pdf"),
    file.path(source_cache, "FAR-2026-25.pdf"),
    file.path(source_cache, "FAR-2026-06.pdf"),
    file.path(source_cache, "FAR-2025-41.pdf")
  ),
  source_url = c(
    "https://fs.fish.govt.nz/Doc/26250/FAR-2026-26-The-2026-stock-assessment-LIN7WC.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26249/FAR-2026-25-Descriptive-analysis-LIN7WC-to-2025-and-inputs-for-2026-stock-assessment.pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26199/FAR-2026-06-Catch-at-age-estimates-for-hake-and-ling-from-commercial-fisheries-in-2023-24-and-trawl-surveys-in-2024%20(1).pdf.ashx",
    "https://fs.fish.govt.nz/Doc/26135/FAR-2025-41-Trawl-survey-for-middle-depth-fish-species-WCSI-2024-TAN2407.pdf.ashx"
  ),
  retrieved_on = "2026-11-06",
  sha256 = c(
    "871202A3970B6554F36D1DC4BD7184A1A8A5F05BECEA21DC16CFE7F97F0CA445",
    "261A653258FAA3221A442766F2998219F00AC29B733EBDE144F35CA1519DDC5A",
    "7250D4DF0A5259B8454D18B620A7D411FADE4CDE68CC9C57B0B620034C1C0FA2",
    "3043F7E6E8C8F3395E8683ED0312C2D8AC93097858D8577B747764C86D8999C9"
  ),
  stringsAsFactors = FALSE
)
if (any(!file.exists(source_files$local_file))) {
  stop("All four reviewed source PDFs must be cached before import.")
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files$local_file)))
if (!identical(actual_hashes, source_files$sha256)) {
  stop("A cached source PDF differs from the reviewed version.")
}
source_files$local_file <- gsub("\\\\", "/", source_files$local_file)

catch_text <- "
year trawl longline potting
1972 0 0 0
1973 85 20 0
1974 144 40 0
1975 401 800 0
1976 565 2100 0
1977 715 4300 0
1978 300 323 0
1979 539 360 0
1980 540 305 0
1981 492 300 0
1982 675 400 0
1983 1040 710 0
1984 924 595 0
1985 1156 302 0
1986 1082 362 0
1987 1105 370 0
1988 1428 291 0
1989 1959 370 0
1990 2695 259 0
1991 2046 456 0
1992 1777 931 0
1993 1591 739 0
1994 1442 969 0
1995 1385 868 0
1996 1877 861 0
1997 2068 1350 0
1998 2045 1073 0
1999 2191 900 0
2000 2386 935 0
2001 2382 999 1
2002 2475 762 0
2003 2094 926 0
2004 2092 764 0
2005 1595 845 0
2006 1773 781 0
2007 1323 1161 0
2008 1150 1021 0
2009 1216 992 0
2010 1386 1199 0
2011 1606 1143 0
2012 1697 1285 0
2013 1959 1089 0
2014 1914 1444 0
2015 2092 1349 2
2016 2159 1471 15
2017 2451 1470 0
2018 2440 1225 15
2019 1834 1400 8
2020 1687 1752 0
2021 1406 1847 210
2022 1482 1590 213
2023 1488 1184 739
2024 1244 1215 765
2025 903 872 581
"
catches <- read.table(text = catch_text, header = TRUE)

cpue_text <- "
year ll_raw ll_adjusted ll_cv trawl_raw trawl_adjusted trawl_cv
1990 855 1060 0.07 NA NA NA
1991 1030 1264 0.06 NA NA NA
1992 1169 1421 0.05 NA NA NA
1993 899 1083 0.05 NA NA NA
1994 867 1033 0.05 NA NA NA
1995 929 1096 0.05 NA NA NA
1996 579 677 0.05 NA NA NA
1997 696 805 0.05 1544 1783 0.14
1998 782 896 0.04 1244 1422 0.14
1999 832 943 0.05 1536 1739 0.14
2000 851 955 0.04 1218 1365 0.14
2001 1024 1138 0.04 1189 1319 0.14
2002 948 1043 0.05 1039 1141 0.14
2003 1057 1152 0.04 830 903 0.14
2004 1095 1182 0.05 935 1007 0.14
2005 765 817 0.04 882 940 0.14
2006 735 777 0.04 938 991 0.14
2007 1068 1118 0.04 962 1005 0.14
2008 1010 1047 0.05 904 936 0.14
2009 1005 1032 0.04 1208 1238 0.14
2010 1216 1236 0.04 992 1006 0.14
2011 1071 1078 0.04 1082 1087 0.14
2012 1113 1109 0.04 961 956 0.14
2013 1187 1171 0.04 1144 1127 0.14
2014 1216 1188 0.04 1058 1031 0.14
2015 1043 1009 0.04 1118 1079 0.14
2016 1044 1000 0.04 1129 1079 0.14
2017 1143 1083 0.04 1143 1081 0.14
2018 1092 1025 0.04 947 887 0.14
2019 1149 1068 0.04 945 877 0.14
2020 1094 1006 0.04 975 895 0.14
2021 915 833 0.04 868 789 0.14
2022 777 701 0.04 808 727 0.14
2023 767 685 0.05 943 841 0.14
2024 617 545 0.05 784 692 0.14
2025 493 432 0.06 637 557 0.14
"
cpue <- read.table(text = cpue_text, header = TRUE, na.strings = "NA")
survey_biomass <- data.frame(
  year = c(2000, 2012, 2013, 2016, 2018, 2021, 2024),
  value = c(1860.9, 2168.8, 2000.4, 1635.4, 1682.4, 1230.7, 611.7),
  cv_percent = c(17.3, 14.8, 18.4, 12.7, 18.3, 17.7, 16.0)
)

commercial_age_text <- "
age male male_cv female female_cv
3 5 2.7 NA NA
4 186 0.9 230 1.6
5 1282 1.2 488 1.2
6 620 0.7 1211 0.8
7 493 0.6 2943 0.5
8 4138 0.3 2036 0.6
9 5349 0.3 3989 0.5
10 6827 0.2 3190 0.3
11 6743 0.2 3575 0.3
12 5610 0.3 6193 0.3
13 4737 0.3 6794 0.3
14 3188 0.3 3226 0.4
15 1741 0.4 2663 0.4
16 2030 0.3 3822 0.4
17 345 0.9 2802 0.4
18 1107 0.6 1464 0.6
19 292 0.8 679 0.7
20 516 0.6 718 0.9
21 NA NA 1354 0.6
22 187 0.9 695 0.7
23 195 0.9 61 1.4
24 186 0.9 182 1.3
25 NA NA NA NA
26 NA NA 4 2.4
"
commercial_age <- read.table(text = commercial_age_text, header = TRUE,
  na.strings = "NA")

survey_age_text <- "
age male male_cv female female_cv
2 NA NA NA NA
3 1601 1.2 1748 1.6
4 2061 1.1 587 2.2
5 748 1.1 1077 1.7
6 2468 0.7 4957 1.2
7 1801 0.7 1888 0.7
8 5525 0.5 3198 0.5
9 6783 0.4 3122 0.9
10 7565 0.4 2592 0.5
11 6353 0.3 5205 0.3
12 4909 0.4 5931 0.3
13 5915 0.3 6080 0.3
14 4247 0.3 3918 0.4
15 2380 0.4 3336 0.4
16 3366 0.5 3151 0.4
17 743 0.8 1573 0.6
18 2283 0.5 1242 0.6
19 642 0.9 547 0.8
20 1530 0.7 661 0.8
21 NA NA 621 0.8
22 365 1.2 1675 0.6
23 309 1.0 1314 1.0
24 674 0.9 882 1.5
25 NA NA NA NA
26 NA NA 145 1.6
"
survey_age <- read.table(text = survey_age_text, header = TRUE,
  na.strings = "NA")

maturity <- data.frame(
  age = 3:12,
  male = c(0, 0.015, 0.095, 0.39, 0.77, 0.94, 1, 1, 1, 1),
  female = c(0, 0.004, 0.017, 0.06, 0.18, 0.39, 0.65, 0.85, 0.94, 1)
)

input_row <- function(type, measure, basis, value, unit, year = "",
                      year_basis = "", age = "", fleet = "", survey = "",
                      sex = "", season = "", sampling_time = "",
                      observation_id = "", sample_size = "",
                      source_reference, transformation = "", notes = "",
                      region = "LIN 7WC") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex,
    region = region, season = season, year = as.character(year),
    year_basis = year_basis, age = as.character(age), value = as.character(value),
    unit = unit, sampling_time = as.character(sampling_time),
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = observation_id, stringsAsFactors = FALSE
  )
}
input_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- input_row(...)
}

catch_reference <- "FAR 2026/25, Appendix E, Table E.1, p. 82"
for (fleet in c("Bottom trawl", "Bottom longline", "Potting")) {
  column <- switch(fleet, "Bottom trawl" = "trawl",
    "Bottom longline" = "longline", "Potting" = "potting")
  for (i in seq_len(nrow(catches))) {
    add_input(
      type = "catch", measure = "landings_biomass", basis = "biomass",
      value = catches[[column]][i], unit = "tonnes",
      year = catches$year[i], year_basis = "model_year", fleet = fleet,
      season = "annual", source_reference = catch_reference,
      notes = paste(
        "Annual scaled catch biomass used by the 2026 assessment.",
        "Trawl includes all catches other than bottom longline or potting."
      )
    )
  }
}

cpue_reference <- "FAR 2026/25, Appendix D, Table D.8, p. 64"
cpue_series <- list(
  list(name = "Bottom longline CPUE", value = "ll_adjusted", cv = "ll_cv"),
  list(name = "Bottom trawl CPUE", value = "trawl_adjusted", cv = "trawl_cv")
)
for (series in cpue_series) {
  for (i in seq_len(nrow(cpue))) {
    value <- cpue[[series$value]][i]
    cv <- cpue[[series$cv]][i]
    if (is.na(value)) next
    id <- paste(gsub("[^A-Za-z0-9]+", "_", series$name), cpue$year[i], sep = "_")
    add_input(
      type = "index", measure = "relative_abundance_index",
      basis = "index_scale", value = value,
      unit = "CPUE index units (not stated)", survey = series$name,
      year = cpue$year[i], year_basis = "model_year", season = "annual",
      sampling_time = 0.5, observation_id = id,
      source_reference = cpue_reference,
      notes = paste(
        "Adjusted CPUE series used by the 2026 assessment, including the",
        "1% annual learning-rate adjustment. Source does not state physical units."
      )
    )
    add_input(
      type = "index", measure = "abundance_index_cv",
      basis = "relative_scale", value = cv, unit = "ratio",
      survey = series$name, year = cpue$year[i], year_basis = "model_year",
      season = "annual", sampling_time = 0.5, observation_id = id,
      source_reference = cpue_reference,
      notes = "Source-reported CV for the adjusted CPUE observation."
    )
  }
}

survey_name <- "Tangaroa trawl survey, core strata (300-650 m)"
survey_reference <- "FAR 2025/41, Table 16, p. 27"
for (i in seq_len(nrow(survey_biomass))) {
  id <- paste0("TAN_core_", survey_biomass$year[i])
  add_input(
    type = "index", measure = "relative_biomass_index", basis = "biomass",
    value = survey_biomass$value[i], unit = "tonnes", survey = survey_name,
    year = survey_biomass$year[i], year_basis = "model_year",
    season = "annual", sampling_time = 0.5, observation_id = id,
    source_reference = survey_reference,
    notes = paste(
      "Tangaroa core-strata biomass index. The 2000 estimate was recalculated",
      "using 2012-13 stratum areas. The assessment lists the same survey years."
    )
  )
  add_input(
    type = "index", measure = "biomass_index_cv", basis = "relative_scale",
    value = survey_biomass$cv_percent[i] / 100, unit = "ratio",
    survey = survey_name, year = survey_biomass$year[i],
    year_basis = "model_year", season = "annual", sampling_time = 0.5,
    observation_id = id, source_reference = survey_reference,
    transformation = "Source CV percent divided by 100 and stored as a ratio.",
    notes = "Source Table 16 reports CV in parentheses as percent."
  )
}

add_age_rows <- function(table, type, fleet = "", survey = "",
                         table_reference, unit, basis, period) {
  for (sex in c("male", "female")) {
    value_column <- sex
    cv_column <- paste0(sex, "_cv")
    for (i in seq_len(nrow(table))) {
      value <- table[[value_column]][i]
      if (is.na(value)) next
      id <- paste(
        if (type == "catch") "LIN7WC_trawl_age" else "TAN2407_age",
        sex, "2024", sep = "_"
      )
      common <- list(
        year = 2024, year_basis = "model_year", age = table$age[i],
        fleet = fleet, survey = survey, sex = sex, season = "annual",
        sampling_time = 0.5, observation_id = id,
        source_reference = table_reference,
        notes = paste(
          "Reported calculated numbers-at-age for", period,
          "in 2024. A dash in the table is defined as no data and is omitted;",
          "it is not converted to zero. This is not the complete historical",
          "age-composition series used by the assessment."
        )
      )
      do.call(add_input, c(list(
        type = type, measure = "numbers_at_age", basis = basis,
        value = value, unit = unit
      ), common))
      cv_common <- common
      cv_common$notes <- paste(
        "Source-reported CV proportion for the numbers-at-age estimate.",
        "A dash is no data, not zero."
      )
      do.call(add_input, c(list(
        type = type, measure = "numbers_at_age_cv", basis = "relative_scale",
        value = table[[cv_column]][i], unit = "ratio"
      ), cv_common))
    }
  }
}
add_age_rows(
  commercial_age, type = "catch", fleet = "Bottom trawl",
  table_reference = "FAR 2026/06, Table 15, p. 21",
  unit = "numbers-at-age (unit not stated)", basis = "numbers",
  period = "the August-September commercial trawl fishery"
)
add_age_rows(
  survey_age, type = "index", survey = "Tangaroa trawl survey (TAN2407)",
  table_reference = "FAR 2026/06, Table 23, p. 25",
  unit = "number (index scale; multiplier not stated)", basis = "index_scale",
  period = "the July-August survey"
)

maturity_reference <- "FAR 2026/26, Table 4, p. 4"
for (sex in c("male", "female")) {
  for (i in seq_len(nrow(maturity))) {
    add_input(
      type = "maturity", measure = "maturity_at_age", basis = "proportion",
      value = maturity[[sex]][i], unit = "proportion", age = maturity$age[i],
      sex = sex, source_reference = maturity_reference,
      notes = paste(
        "Fixed maturity-at-age reported for ages 3-12. Other ages in the",
        "model age grid are not tabulated."
      )
    )
  }
}
inputs <- do.call(rbind, input_rows)
stopifnot(
  identical(catches$year, 1972:2025),
  sum(!is.na(cpue$ll_adjusted)) == 36L,
  sum(!is.na(cpue$trawl_adjusted)) == 29L,
  identical(survey_biomass$year, c(2000, 2012, 2013, 2016, 2018, 2021, 2024)),
  sum(!is.na(commercial_age$male)) + sum(!is.na(commercial_age$female)) +
    sum(!is.na(survey_age$male)) + sum(!is.na(survey_age$female)) == 87L,
  nrow(inputs) == 500L
)

assumption_row <- function(component, setting, value, source_reference,
                           notes = "", fleet = "", survey = "", sex = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = "LIN 7WC", season = "",
    setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
assumptions <- rbind(
  assumption_row("population", "model_structure",
    "Two-sex age-based statistical catch-at-age model; ages 1-28.",
    "FAR 2026/26, pp. 2-3"),
  assumption_row("population", "plus_group",
    "Age 28 is the plus group.", "FAR 2026/26, p. 2"),
  assumption_row("population", "annual_cycle",
    "One January-December time step; ageing occurs at the end of December.",
    "FAR 2026/26, Table 1, p. 3"),
  assumption_row("population", "spawning_timing",
    "Spawning occurs during the annual step before fishing and natural mortality.",
    "FAR 2026/26, Table 1, p. 3"),
  assumption_row("recruitment", "stock_recruitment_relationship",
    "Beverton-Holt.", "FAR 2026/26, p. 2"),
  assumption_row("recruitment", "steepness_h", "0.84",
    "FAR 2026/26, Table 3, p. 4"),
  assumption_row("recruitment", "recruitment_variability_sigma_R", "0.6",
    "FAR 2026/26, Table 3, p. 4"),
  assumption_row("recruitment", "year_class_strength",
    "Lognormal recruitment multipliers estimated using the simplex method; multipliers average one. Final assessment estimates year classes through 2020.",
    "FAR 2026/26, pp. 4-5"),
  assumption_row("M", "natural_mortality",
    "Fixed M=0.18 y-1, constant at age and equal for both sexes.",
    "FAR 2026/26, p. 4"),
  assumption_row("M", "natural_mortality_sensitivities",
    "M=0.16 and M=0.20 y-1.", "FAR 2026/26, pp. 4, 8"),
  assumption_row("observations", "index_likelihood",
    "Lognormal for Tangaroa biomass and both CPUE series.",
    "FAR 2026/26, p. 3"),
  assumption_row("observations", "age_composition_likelihood",
    "Multinomial for all age-composition observations.",
    "FAR 2026/26, p. 3"),
  assumption_row("observations", "composition_effective_sample_size",
    "Estimated using the TA1.8 method of Francis (2011).",
    "FAR 2026/26, p. 3"),
  assumption_row("observations", "index_observation_error",
    "Reported CVs represent sampling error only; process error was added and estimated at MPD.",
    "FAR 2026/26, p. 3"),
  assumption_row("observations", "estimated_index_process_error", "0.02",
    "FAR 2026/26, p. 6", notes = "MPD estimate for the Tangaroa survey biomass index.",
    survey = "Tangaroa trawl survey"),
  assumption_row("observations", "estimated_index_process_error", "0.12",
    "FAR 2026/26, p. 6", notes = "MPD estimate for bottom-longline CPUE.",
    survey = "Bottom longline CPUE"),
  assumption_row("observations", "estimated_index_process_error", "0.09",
    "FAR 2026/26, p. 6", notes = "MPD estimate for bottom-trawl CPUE.",
    survey = "Bottom trawl CPUE"),
  assumption_row("catchability", "q_estimation",
    "Free q parameters estimated for the Tangaroa survey and each CPUE series.",
    "FAR 2026/26, pp. 4, 5"),
  assumption_row("catchability", "q_prior",
    "Final survey q prior is uniform; CPUE q prior distributions are reported in Table 5.",
    "FAR 2026/26, pp. 5-6",
    notes = "The table and narrative describe q prior parameterization differently; the source record retains the report descriptions without attempting to reconcile them."),
  assumption_row("selectivity", "fishery_and_survey_selectivity",
    "Logistic selectivity; selectivity is constant through time for each fishery and the survey.",
    "FAR 2026/26, p. 4"),
  assumption_row("selectivity", "potting_selectivity",
    "Potting shares bottom-longline selectivity because age data are unavailable for potting.",
    "FAR 2026/26, p. 3"),
  assumption_row("CPUE", "learning_rate",
    "CPUE series include a 1% annual learning-rate adjustment.",
    "FAR 2026/26, p. 3; FAR 2026/25, Table D.8, p. 64"),
  assumption_row("observation_timing", "observation_fraction_of_Z", "0.5",
    "FAR 2026/26, Table 1, p. 3",
    notes = "Table 1 assigns 0.5 of total mortality to the observation time for all age and index observations."),
  assumption_row("growth", "von_bertalanffy_t0_y", "-0.1",
    "FAR 2026/26, Table 3, p. 4", sex = "combined"),
  assumption_row("growth", "von_bertalanffy_k_y-1", "0.13",
    "FAR 2026/26, Table 3, p. 4", sex = "male"),
  assumption_row("growth", "von_bertalanffy_k_y-1", "0.11",
    "FAR 2026/26, Table 3, p. 4", sex = "female"),
  assumption_row("growth", "von_bertalanffy_Linf_cm", "126.1",
    "FAR 2026/26, Table 3, p. 4", sex = "male"),
  assumption_row("growth", "von_bertalanffy_Linf_cm", "148.9",
    "FAR 2026/26, Table 3, p. 4", sex = "female"),
  assumption_row("growth", "length_at_age_CV", "0.09",
    "FAR 2026/26, Table 3, p. 4", sex = "male"),
  assumption_row("growth", "length_at_age_CV", "0.09",
    "FAR 2026/26, Table 3, p. 4", sex = "female"),
  assumption_row("growth", "length_weight_a", "1.31e-6",
    "FAR 2026/26, Table 3, p. 4", sex = "male",
    notes = "The source table labels the units g.cm-1."),
  assumption_row("growth", "length_weight_a", "0.98e-6",
    "FAR 2026/26, Table 3, p. 4", sex = "female",
    notes = "The source table labels the units g.cm-1."),
  assumption_row("growth", "length_weight_b", "3.292",
    "FAR 2026/26, Table 3, p. 4", sex = "male"),
  assumption_row("growth", "length_weight_b", "3.362",
    "FAR 2026/26, Table 3, p. 4", sex = "female"),
  assumption_row("maturity", "maturity_source",
    "Fixed age-specific values in Table 4, ages 3-12; source is Horn (2005).",
    "FAR 2026/26, Table 4, p. 4"),
  assumption_row("biology", "ageing_error_CV", "0.05",
    "FAR 2026/26, Table 3, p. 4"),
  assumption_row("biology", "male_at_birth", "0.5",
    "FAR 2026/26, Table 3, p. 4"),
  assumption_row("biology", "proportion_mature_spawning", "1.0",
    "FAR 2026/26, Table 3, p. 4"),
  assumption_row("biology", "maximum_exploitation_rate", "0.6",
    "FAR 2026/26, Table 3, p. 4")
)

output_row <- function(type, measure, value, unit, scenario,
                       year = "", lwr = "", upr = "",
                       source_reference, notes) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "combined", region = "LIN 7WC",
    season = "", year = as.character(year), age = "", age_group = "",
    scenario = scenario, value = as.character(value), se = "",
    lwr = as.character(lwr), upr = as.character(upr), unit = unit,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
mpd_scenario <- "Base case; MPD"
posterior_scenario <- "Base case; MCMC posterior median"
outputs <- rbind(
  output_row("biomass", "unfished_spawning_biomass", 54241, "tonnes",
    mpd_scenario, source_reference = "FAR 2026/26, Table 7, p. 6",
    notes = "MPD base-case estimate."),
  output_row("biomass", "spawning_biomass", 24341, "tonnes",
    mpd_scenario, year = 2023,
    source_reference = "FAR 2026/26, Table 7, p. 6",
    notes = "2023 MPD base-case estimate."),
  output_row("biomass", "SSB_ratio_to_B0", 0.449, "ratio",
    mpd_scenario, year = 2023,
    source_reference = "FAR 2026/26, Table 7, p. 6",
    notes = "2023 spawning biomass as a proportion of B0."),
  output_row("biomass", "spawning_biomass", 18621, "tonnes",
    mpd_scenario, year = 2026,
    source_reference = "FAR 2026/26, Table 7, p. 6",
    notes = "2026 MPD base-case estimate; the report does not provide this as an MCMC median."),
  output_row("biomass", "SSB_ratio_to_B0", 0.343, "ratio",
    mpd_scenario, year = 2026,
    source_reference = "FAR 2026/26, Table 7, p. 6",
    notes = "2026 spawning biomass as a proportion of B0; MPD estimate."),
  output_row("biomass", "unfished_spawning_biomass", 54144, "tonnes",
    posterior_scenario, lwr = 50096, upr = 59413,
    source_reference = "FAR 2026/26, Table 8, p. 8",
    notes = "Posterior median and 95% credible interval."),
  output_row("biomass", "SSB_ratio_to_B0", 0.340, "ratio",
    posterior_scenario, year = 2026, lwr = 0.289, upr = 0.401,
    source_reference = "FAR 2026/26, Table 8, p. 8",
    notes = "2026 status as a proportion of B0; report percentages divided by 100. Posterior median and 95% credible interval."),
  output_row("probability", "probability_above_0.4_B0", 0.027,
    "probability", posterior_scenario, year = 2026,
    source_reference = "FAR 2026/26, Table 8, p. 8",
    notes = "Posterior probability that 2026 spawning biomass exceeds 40% of B0."),
  output_row("probability", "probability_below_0.2_B0", 0,
    "probability", posterior_scenario, year = 2026,
    source_reference = "FAR 2026/26, Table 8, p. 8",
    notes = "Posterior probability that 2026 spawning biomass is below 20% of B0.")
)
stopifnot(nrow(assumptions) == 39L, nrow(outputs) == 9L)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "LIN 7WC", scientific_name = "Genypterus blacodes",
  common_name = "West Coast South Island ling",
  area = "West Coast South Island biological stock, including Statistical Area 032",
  region = "LIN 7WC", ocean = "Southwest Pacific",
  notes = paste(
    "Biological stock unit in the 2026 assessment. Distinct from Chatham Rise",
    "LIN 3&4; potting is a separate fishery within this stock."
  ),
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2025, estimate_terminal_year = 2026,
  assessment_type = "full_assessment", model_family = "Casal2",
  model_version = "v24.02", is_current = TRUE, is_applied = TRUE,
  framework_year = "",
  assessment_url = source_files$source_url[1],
  framework_url = "",
  data_url = paste(source_files$source_url[2:4], collapse = "; "),
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Latest detailed production assessment located for the current LIN 7WC",
    "unit. Source tables provide partial numerical catch, CPUE, survey, age,",
    "biology and summary-output records. Historical fitted age-composition",
    "vectors, complete age-specific weights and numerical annual population",
    "surfaces were not located. No public native fitted object or model-file",
    "repository was located in the reviewed official sources."
  ),
  stringsAsFactors = FALSE
)

database_path <- function(name) file.path("database", name)
columns_for <- function(path) {
  names(read.csv(path, nrows = 0, stringsAsFactors = FALSE,
    check.names = FALSE))
}
rows_as_table <- function(rows, path) {
  columns <- columns_for(path)
  if (!is.data.frame(rows)) rows <- do.call(rbind, rows)
  for (name in setdiff(columns, names(rows))) rows[[name]] <- ""
  rows <- rows[columns]
  rows[] <- lapply(rows, as.character)
  rows
}
csv_has_record <- function(path, id) {
  con <- file(path, open = "r")
  on.exit(close(con))
  readLines(con, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '"')
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
append_table <- function(rows, filename) {
  path <- database_path(filename)
  rows <- rows_as_table(rows, path)
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")
    seek(con, where = size - 1, origin = "start")
    last <- readBin(con, "raw", n = 1L)
    close(con)
    if (!identical(last, as.raw(10L))) {
      con <- file(path, open = "ab")
      writeBin(as.raw(10L), con)
      close(con)
    }
  }
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "", eol = "\n")
}

cat(
  "Prepared ", nrow(inputs), " input rows (",
  sum(inputs$measure == "landings_biomass"), " catch biomass, ",
  sum(inputs$measure == "relative_abundance_index"), " CPUE values, ",
  sum(inputs$measure == "relative_biomass_index"), " survey biomass values, ",
  sum(inputs$measure == "numbers_at_age"), " reported age-number values, ",
  sum(inputs$measure == "maturity_at_age"), " maturity values), ",
  nrow(assumptions), " assumptions, and ", nrow(outputs),
  " output rows.\n", sep = ""
)

if (write_mode) {
  if (csv_has_record(database_path("stocks.csv"), stock_id)) {
    stop("LIN 7WC stock already exists; refusing duplicate import.")
  }
  for (name in c("assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
    if (csv_has_record(database_path(name), assessment_id)) {
      stop("LIN 7WC assessment records already exist; refusing duplicate import.")
    }
  }

  candidates <- read.csv("discovery/candidates.csv",
    stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE
  )
  candidate_index <- match(candidate_id, candidates$candidate_id)
  if (is.na(candidate_index) ||
      candidates$import_status[candidate_index] != "not_started") {
    stop("LIN 7WC candidate is missing or already imported.")
  }

  append_table(stock, "stocks.csv")
  append_table(assessment, "assessments.csv")
  append_table(assumptions, "assumptions.csv")
  append_table(inputs, "inputs.csv")
  append_table(outputs, "outputs.csv")

  source("scripts/database/candidate_register_io.R")
  candidates$matched_stock_id[candidate_index] <- stock_id
  candidates$match_status[candidate_index] <- "matched"
  candidates$import_status[candidate_index] <- "partial"
  replace_candidate_register_row(
    "discovery/candidates.csv", candidate_index,
    candidates[candidate_index, , drop = FALSE], candidate_id
  )

  manifest_path <- file.path("provenance", "mpi_ling_lin7wc_2026_sources.csv")
  write.csv(source_files, manifest_path, row.names = FALSE, na = "")
  cat("Added LIN 7WC source records and updated the candidate register.\n")
}
