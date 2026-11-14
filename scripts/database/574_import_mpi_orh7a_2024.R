root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args

stock_id <- "mpi_orh7a_challenger"
assessment_id <- "mpi_orh7a_2024"
candidate_id <- "MPI:ORH7A"
source_dir <- "source_cache/mpi_orange_roughy_orh7a_2024"
source_files <- file.path(source_dir, c(
  "FAR-2024-58-ORH7A-assessment-2024.pdf",
  "FAR-2024-26-ORH7A-acoustic-survey-2023.pdf",
  "Fisheries-Assessment-Plenary-2026-Volume-2.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/25788/FAR-2024-58-Assessment-of-the-Challenger-Plateau-orange-roughy-stock-for-2024.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25743/FAR-2024-26-Estimation-of-the-abundance-of-orange%20roughy-on-the-southwest-Challenger%20Plateau.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26242/Fisheries-Assessment-Plenary-May-2026-Volume-2.pdf.ashx"
)
source_hashes <- c(
  "585A13B5BA9C5D98E06C5A39F7F5AEFFE8420960DE34BE0ECEB6D95432A19BA7",
  "005D62B9E551BBB01811E9CE1B3AF609C190391BD0DA6B52BB63066C98012C39",
  "FF026E1C2C1CCB69FEF35F1ACEE60BFC4766D8DDCDA98C1DC02FA5C97681E128"
)
if (!all(file.exists(source_files))) stop("Cache the three reviewed Fisheries New Zealand PDFs before importing.", call. = FALSE)
actual_hashes <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) stop("A cached source differs from the reviewed file.", call. = FALSE)

catches <- read.table(text = "
year catch_t
1981 43
1982 5523
1983 15391
1984 12386
1985 6652
1986 10179
1987 14940
1988 15836
1989 12801
1990 5171
1991 1561
1992 2102
1993 2296
1994 1819
1995 1718
1996 1752
1997 1374
1998 1577
1999 1311
2000 660
2001 0
2002 0
2003 5
2004 0
2005 166
2006 229
2007 0
2008 0
2009 252
2010 361
2011 505
2012 536
2013 815
2014 574
2015 1674
2016 1646
2017 1704
2018 1869
2019 1670
2020 1990
2021 2178
2022 2301
2023 1860
2024 1860
", header = TRUE)
if (!identical(catches$year, 1981:2024) || nrow(catches) != 44L) stop("CASAL catch series must cover model years 1981-2024.", call. = FALSE)

index_data <- read.table(text = "
survey|year|biomass_t|cv|source_table|cv_note
Thomas Harrison trawl survey|2006|13987|0.34|Table 5, printed p. 12|Model CV includes 20% process error.
Thomas Harrison trawl survey|2009|34864|0.31|Table 5, printed p. 12|Model CV includes 20% process error.
Thomas Harrison trawl survey|2011|18425|0.33|Table 5, printed p. 12|Model CV includes 20% process error.
Thomas Harrison trawl survey|2012|22451|0.27|Table 5, printed p. 12|Model CV includes 20% process error.
Thomas Harrison trawl survey|2013|18993|0.55|Table 5, printed p. 12|Model CV includes 20% process error.
Thomas Harrison trawl survey|2018|48038|0.55|Table 5, printed p. 12|Model CV includes 20% process error.
Challenger Plateau aggregate acoustic survey|2009|22697|0.26|Table 6, printed p. 13|All2 base-case aggregate index; no acoustic process error.
Challenger Plateau aggregate acoustic survey|2013|20107|0.15|Table 6, printed p. 13|All2 base-case aggregate index; no acoustic process error.
", header = TRUE, sep = "|", stringsAsFactors = FALSE)
if (nrow(index_data) != 8L) stop("Expected eight All2 biomass-index inputs.", call. = FALSE)

composition_data <- list(
  list(year = 1987L, survey = "Amaltal Explorer trawl survey", observation_id = "ORH7A_AFreq_1987", sample_size = 10,
    values = scan(text = paste(
      "0 0 0 0 0 0 0 0 0 0",
      "0.00656168 0.003937008 0.01706037 0.01312336 0.01312336 0.01049869 0.03674541 0.01574803 0.0144357 0.01181102",
      "0.0183727 0.02230971 0.01049869 0.02493438 0.0183727 0.02230971 0.0183727 0.03018373 0.03149606 0.01968504",
      "0.04724409 0.01968504 0.02493438 0.02493438 0.04199475 0.01574803 0.03805774 0.02493438 0.009186352 0.02362205",
      "0.02624672 0.01968504 0.01312336 0.01706037 0.01574803 0.02099738 0.02887139 0.00656168 0.01181102 0.01312336",
      "0.002624672 0.01312336 0.01968504 0.007874016 0.009186352 0.002624672 0.001312336 0.01049869 0.00656168 0.00656168",
      "0.009186352 0 0.01181102 0 0.005249344 0.009186352 0.005249344 0 0.00656168 0.01049869",
      "0 0.001312336 0.00656168 0.003937008 0.002624672 0 0.005249344 0 0 0.003937008",
      "0.007874016 0.001312336 0 0.00656168 0 0.01968504",
      sep = " "
    ), what = numeric(), quiet = TRUE)),
  list(year = 2006L, survey = "Thomas Harrison trawl survey", observation_id = "ORH7A_AFreq_2006", sample_size = 10,
    values = scan(text = paste(
      "0 0 0.0008532423 0.002559727 0.001706485 0.001706485 0.004266212 0.005119454 0.005119454 0.01706485",
      "0.03754266 0.0665529 0.04522184 0.06484642 0.05887372 0.02645051 0.04095563 0.04692833 0.008532423 0.03242321",
      "0.08532423 0.02986348 0.03924915 0.0162116 0.0443686 0.03156997 0.03583618 0.01535836 0.01279863 0.05119454",
      "0.02389078 0.01194539 0.01706485 0.006825939 0.004266212 0.003412969 0.006825939 0.01962457 0.004266212 0.001706485",
      "0.01279863 0.01279863 0.001706485 0.005972696 0.002559727 0.005119454 0 0 0.002559727 0.003412969",
      "0 0 0 0 0 0 0.006825939 0 0 0.001706485",
      "0.01109215 0 0 0 0 0.001706485 0 0 0 0.001706485",
      "0 0 0 0 0 0 0.0008532423 0 0 0",
      "0 0 0 0 0 0",
      sep = " "
    ), what = numeric(), quiet = TRUE)),
  list(year = 2009L, survey = "Thomas Harrison trawl survey", observation_id = "ORH7A_AFreq_2009", sample_size = 10,
    values = scan(text = paste(
      "0 0 0.001703578 0 0.001703578 0.003407155 0.0306644 0.02896082 0.01873935 0.02725724",
      "0.02725724 0.04770017 0.03236797 0.02214651 0.07325383 0.03577513 0.07495741 0.03407155 0.04770017 0.04599659",
      "0.03918228 0.04940375 0.02896082 0.03918228 0.04088586 0.02385009 0.03407155 0.02896082 0.02725724 0.005110733",
      "0.0306644 0.005110733 0 0.005110733 0.00681431 0.005110733 0.001703578 0.008517888 0 0.005110733",
      "0.003407155 0.008517888 0.008517888 0.003407155 0 0 0.003407155 0 0 0.003407155",
      "0.00681431 0.001703578 0.005110733 0 0 0 0 0 0 0",
      "0.005110733 0 0 0 0 0 0 0.001703578 0 0",
      "0 0 0 0 0.01022147 0 0 0 0 0",
      "0 0 0 0 0 0",
      sep = " "
    ), what = numeric(), quiet = TRUE)),
  list(year = 2018L, survey = "Thomas Harrison trawl survey", observation_id = "ORH7A_AFreq_2018", sample_size = 10,
    values = scan(text = paste(
      "0 0 0 0 0.005060266 0 0.006761356 0.01002867 0.01268612 0.0146093",
      "0.01844751 0.02278862 0.01672607 0.01019668 0.01251519 0.008008393 0.01998815 0.02982031 0.04219187 0.01733302",
      "0.03176847 0.02335195 0.03298992 0.04931774 0.02693554 0.03646654 0.02449202 0.03340329 0.03163068 0.05372512",
      "0.04284767 0.03743045 0.02181655 0.0348701 0.04319939 0.02246943 0.0179859 0.02329616 0.01198962 0.0125024",
      "0.02281883 0.008449655 0.009778681 0.009010675 0.009834479 0.004297498 0.002530133 0.004963169 0.004455632 0.002292933",
      "0.008403726 0.003914957 0.001997012 0.006246265 0.002372 0.003083599 0.006552056 0 0 7.906665e-05",
      "0.00312429 0.003552761 0.001265066 0.004448078 0.002570824 0.004264361 0 0.003795199 0.0008569413 0.0001581333",
      "0 0 0 0 0 0 0.0003953333 0 0 0",
      "0 0.0005534666 0 0 0 0.004284706",
      sep = " "
    ), what = numeric(), quiet = TRUE)),
  list(year = 2014L, survey = "Volcano age-frequency sample", observation_id = "ORH7A_AFreqVol_2014", sample_size = 10,
    values = scan(text = paste(
      "0 0 0 0 0 0.003 0 0.008 0.006 0.002",
      "0.007 0.007 0.006 0.01 0.011 0.019 0.027 0.038 0.016 0.037",
      "0.033 0.036 0.042 0.058 0.034 0.037 0.046 0.042 0.042 0.032",
      "0.03 0.034 0.037 0.03 0.013 0.022 0.026 0.025 0.022 0.029",
      "0.015 0.012 0.008 0.009 0 0.012 0.004 0.007 0.004 0.009",
      "0.012 0 0.005 0.003 0.004 0 0 0.003 0.009 0.003",
      "0 0 0.003 0 0.006 0 0 0 0 0",
      "0 0 0 0 0 0 0.003 0 0 0",
      "0 0 0 0 0 0",
      sep = " "
    ), what = numeric(), quiet = TRUE)),
  list(year = 2018L, survey = "Volcano age-frequency sample", observation_id = "ORH7A_AFreqVol_2018", sample_size = 5,
    values = scan(text = paste(
      "0 0 0 0 0 0 0 0 0 0",
      "0 0 0 0.00708502 0.008097166 0 0.01315789 0.01518219 0.01518219 0.001012146",
      "0.01315789 0.003036437 0.03340081 0.02732794 0.008097166 0.009109312 0.02125506 0.01923077 0.05161943 0.02327935",
      "0.0354251 0.00708502 0.04048583 0.02631579 0.02935223 0.03441296 0.03846154 0.01923077 0.02226721 0.03340081",
      "0.03036437 0.02024291 0.02327935 0.0111336 0.02732794 0.03137652 0.01315789 0.02631579 0.02024291 0.0111336",
      "0.01619433 0.02834008 0 0.02530364 0 0.008097166 0.008097166 0.01315789 0.01720648 0.02024291",
      "0.005060729 0.02125506 0 0 0 0.005060729 0.00708502 0 0 0",
      "0 0.0111336 0.01315789 0 0 0 0 0 0 0.002024291",
      "0.009109312 0 0 0 0 0.01923077",
      sep = " "
    ), what = numeric(), quiet = TRUE))
)

if (length(composition_data) != 6L || any(vapply(composition_data, function(x) length(x$values) != 86L, logical(1)))) {
  stop("Expected six age-frequency samples across ages 15-100.", call. = FALSE)
}

add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
    year_basis = "", age = NA_real_, fleet = "", survey = "", sex = "",
    region = "", season = "", sampling_time = NA_real_,
    source_type = "official_document", source_reference, transformation = "",
    notes = "", observation_id = "", sample_size = NA_real_,
    age_error = NA_real_, partition = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = as.integer(year), year_basis = year_basis, age = as.numeric(age),
    value = as.numeric(value), unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes, observation_id = observation_id,
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = as.numeric(sample_size), age_error = as.numeric(age_error),
    partition = partition, stringsAsFactors = FALSE
  )
}
input_rows <- list()
for (i in seq_len(nrow(catches))) {
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "catch", "total_biomass", "biomass", catches$catch_t[i], "tonnes",
    year = catches$year[i], year_basis = "model_year",
    fleet = "EEZ and Westpac Bank fishery",
    region = "Southwest Challenger Plateau and Westpac Bank",
    source_reference = "Fisheries New Zealand FAR 2024/58, Table 4, printed p. 11; CASAL Appendix A, printed p. 28",
    notes = "Catch biomass including source-estimated over-runs. CASAL model year 1981 represents fishing year 1980-81; model year 2024 represents 2023-24. The terminal value is assumed equal to 2022-23.",
    observation_id = paste0("catch-", catches$year[i])
  )
}
for (i in seq_len(nrow(index_data))) {
  ref <- paste("Fisheries New Zealand FAR 2024/58,", index_data$source_table[i],
    "and CASAL Appendix A, printed pp. 31-32")
  timing <- "CASAL step 2, proportion_mortality=0.5: share of step mortality before the observation, not a calendar-year fraction."
  obs_id <- paste0("index-", gsub("[^A-Za-z0-9]+", "-", tolower(index_data$survey[i])), "-", index_data$year[i])
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "total_biomass", "biomass", index_data$biomass_t[i], "tonnes",
    year = index_data$year[i], year_basis = "calendar_year",
    survey = index_data$survey[i],
    region = "Southwest Challenger Plateau and Westpac Bank",
    source_reference = ref, notes = paste(index_data$cv_note[i], timing),
    observation_id = obs_id
  )
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "biomass_index_cv", "relative_scale", index_data$cv[i], "ratio",
    year = index_data$year[i], year_basis = "calendar_year",
    survey = index_data$survey[i],
    region = "Southwest Challenger Plateau and Westpac Bank",
    source_reference = ref, notes = index_data$cv_note[i],
    observation_id = obs_id
  )
}
for (x in composition_data) {
  for (k in seq_along(x$values)) {
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "index", "proportion_at_age", "proportion_numbers", x$values[k],
      "proportion", year = x$year, year_basis = "calendar_year", age = 14 + k,
      survey = x$survey,
      region = if (grepl("Volcano", x$survey)) "Westpac Bank" else "Challenger Plateau",
      source_reference = "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed pp. 29-30",
      notes = "CASAL survey age-frequency input; ages 15-100 with age 100 as the plus group. Source declares sum_to_one=True; printed values are retained without renormalization. sample_size is the effective likelihood sample size, not raw otolith count.",
      observation_id = x$observation_id, sample_size = x$sample_size
    )
  }
}
new_inputs <- do.call(rbind, input_rows)
if (nrow(new_inputs) != 576L) stop("Unexpected number of source input rows.", call. = FALSE)

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = "", sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE
  )
}
add_assumption("model", "model_structure", "CASAL age-structured, single-sex model; one area; ages 1-100 with age 100 plus group; mature/immature partition; annual cycle with two time steps.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed pp. 28-29")
add_assumption("model", "model_period", "Initial year 1911; current year 2024; final projection year 2174.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 28")
add_assumption("recruitment", "stock_recruitment", "Beverton-Holt; steepness 0.75; recruitment year-class strengths fixed at 1 (deterministic recruitment).", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 28", "The report states recruitment is deterministic in the 2024 base case.")
add_assumption("biology", "growth", "Von Bertalanffy length-at-age: Linf=34.2, t0=-0.5; CV parameters 0.10 and 0.05.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 29", "Parameters are preserved in the CASAL form; units are not stated in the appendix.")
add_assumption("biology", "length_weight_relationship", "Weight = 9.21e-8 * length^2.71.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 29", "The source gives the parametric relationship rather than a weight-at-age table; units are not stated in the appendix.")
add_assumption("biology", "maturity_and_selectivity", "A logistic maturity ogive is estimated and used as the selectivity ogive.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 29; discussion pp. 20-21", "The report describes A50 as close to 34 years; age-specific surfaces are not tabulated.")
add_assumption("mortality", "natural_mortality", "One age-invariant M parameter is estimated with a lognormal prior (mu=0.078, CV=1.2); initial M=0.045 per year.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 29; discussion p. 14", "The report cautions that estimated M includes undefined factors and is a general productivity descriptor, not a direct estimate of natural mortality.")
add_assumption("assessment", "unfished_biomass_prior", "B0 estimated with a uniform prior from 30,000 to 200,000 tonnes.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 29")
add_assumption("catch", "catch_overrun_adjustments", "Catch over-runs included: 30% in 1980-81 to 1987-88; 25% in 1988-89; 20% in 1989-90; 15% in 1990-91; 10% in 1991-92 to 1992-93; 5% from 1993-94 onwards.", "Fisheries New Zealand FAR 2024/58, Table 4 notes, printed p. 11")
add_assumption("catch", "terminal_catch_assumption", "Catch for 2023-24 was assumed equal to 2022-23 (1,860 tonnes).", "Fisheries New Zealand FAR 2024/58, Table 4, printed p. 11")
add_assumption("index", "trawl_q_prior", "Thomas Harrison trawl survey q uses an uninformed uniform-log prior with bounds 0.10-2.00.", "Fisheries New Zealand FAR 2024/58, Table 5, printed p. 12; CASAL Appendix A, printed p. 31")
add_assumption("index", "trawl_index_error", "Thomas Harrison trawl biomass-index CVs include an additional 20% process error.", "Fisheries New Zealand FAR 2024/58, Table 5, printed p. 12")
add_assumption("index", "acoustic_base_case", "All2 sums accepted Volcano, West and East acoustic biomass estimates into one index; only 2009 and 2013 are included in the base-case likelihood.", "Fisheries New Zealand FAR 2024/58, Table 6 and model-run description, printed p. 13; CASAL Appendix A, printed p. 31")
add_assumption("index", "acoustic_q_prior", "The All2 aggregate acoustic index q has a lognormal prior with mu=0.8 and CV=0.30.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed p. 31")
add_assumption("index", "observation_timing", "Biomass and age-frequency observations occur in time step 2 with proportion_mortality=0.5.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed pp. 29-32", "In CASAL this is the proportion of step mortality before observations; it does not define a fraction of the calendar year.")
add_assumption("composition", "age_frequency_likelihood", "Age frequencies use a multinomial likelihood; effective sample size is 10 except Volcano 2018, which uses 5.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed pp. 29-30; discussion p. 14", "No commercial age frequencies were available. The 2023 survey otolith sample was not aged because it was considered unrepresentative. No statistical reweighting was attempted.")
add_assumption("composition", "ageing_error", "Normal ageing error with standard deviation 0.1 years; applied to the survey age-frequency samples.", "Fisheries New Zealand FAR 2024/58, CASAL Appendix A, printed pp. 29-30")
add_assumption("assessment", "base_and_sensitivity_runs", "All2 is the base case. All6 adds less certain or incomplete acoustic survey years; 3Series fits separate Volcano, East and West acoustic series.", "Fisheries New Zealand FAR 2024/58, model-run description, printed pp. 13-14; Fisheries Assessment Plenary May 2026, Vol. 2, printed pp. 1007-1008")
add_assumption("assessment", "assessment_acceptance", "The 2024 assessment was accepted by the Fisheries New Zealand Deepwater Working Group and Plenary and used for scientific advice.", "Fisheries New Zealand FAR 2024/58, Executive Summary, printed p. 1")
new_assumptions <- do.call(rbind, assumption_rows)

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "ORH 7A", scientific_name = "Hoplostethus atlanticus",
  common_name = "Orange roughy",
  area = "Southwest Challenger Plateau and Westpac Bank (ORH 7A)",
  region = "Southwest Challenger Plateau", ocean = "Southwest Pacific",
  notes = "Single official ORH 7A stock covering the southwest Challenger Plateau and Westpac Bank; the latter is outside the New Zealand EEZ.",
  stringsAsFactors = FALSE
)
assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2024L, estimate_terminal_year = 2024L,
  assessment_type = "full_assessment", model_family = "CASAL", model_version = "",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://fs.fish.govt.nz/Page.aspx?dk=25788&pk=113",
  framework_url = "", data_url = "", model_url = "", repository_url = "",
  assumptions_status = "complete", inputs_status = "complete", outputs_status = "partial",
  notes = "Latest detailed official assessment located for ORH 7A; the 2026 Fisheries Assessment Plenary still identifies 2024 as the most recent assessment. The All2 run is the base case. The full All2 likelihood data arrays are published in Appendix A; age-specific population-output surfaces are not tabulated.",
  stringsAsFactors = FALSE
)

run_results <- data.frame(
  scenario = c("All2 (base)", "All6", "3Series"),
  M = c(0.033, 0.024, 0.031), M_lwr = c(0.020, 0.016, 0.020), M_upr = c(0.054, 0.037, 0.045),
  B0 = c(99.4, 98.5, 97.5), B0_lwr = c(87.6, 91.3, 89.3), B0_upr = c(117.2, 110.3, 110.5),
  SSB_ratio = c(35, 16, 29), SSB_ratio_lwr = c(16, 8, 18), SSB_ratio_upr = c(57, 35, 44),
  p_gt_50 = c(0.09, 0.00, 0.09), p_gt_30 = c(0.66, 0.06, 0.44),
  p_lt_20 = c(0.07, 0.71, 0.05), p_lt_10 = c(0.00, 0.12, 0.00),
  stringsAsFactors = FALSE
)
output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
    year = NA_integer_, lwr = NA_real_, upr = NA_real_, scenario = "") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "Southwest Challenger Plateau and Westpac Bank",
    season = "", year = as.integer(year), age = NA_real_, age_group = "",
    value = as.numeric(value), se = NA_real_, lwr = as.numeric(lwr),
    upr = as.numeric(upr), unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE
  )
}
output_ref <- "Fisheries Assessment Plenary, May 2026, Vol. 2, ORH 7A Table 6, printed p. 1008"
interval_note <- "MCMC median and reported 95% credible interval; the source reports limits in parentheses. No standard error is reported."
for (r in seq_len(nrow(run_results))) {
  z <- run_results[r, ]
  add_output("mortality", "natural_mortality_average_parameter", z$M, "per year",
    output_ref, paste(interval_note, "The report states this estimated M is a general productivity descriptor and is not directly comparable to natural mortality."),
    lwr = z$M_lwr, upr = z$M_upr, scenario = z$scenario)
  add_output("biomass", "unfished_spawning_biomass", z$B0, "thousand tonnes",
    output_ref, paste(interval_note, "The source reports B0 in thousands of tonnes."),
    lwr = z$B0_lwr, upr = z$B0_upr, scenario = z$scenario)
  add_output("biomass", "SSB_ratio_to_B0", z$SSB_ratio, "percent",
    output_ref, paste(interval_note, "The source reports B2024 as a percentage of B0; the source scale is retained."),
    year = 2024L, lwr = z$SSB_ratio_lwr, upr = z$SSB_ratio_upr, scenario = z$scenario)
  probabilities <- c(
    probability_above_50_percent_B0 = z$p_gt_50,
    probability_above_30_percent_B0 = z$p_gt_30,
    probability_below_20_percent_B0 = z$p_lt_20,
    probability_below_10_percent_B0 = z$p_lt_10
  )
  for (measure in names(probabilities)) add_output(
    "biomass", measure, probabilities[[measure]], "probability", output_ref,
    "Posterior probability for B2024 relative to the named B0 reference point; reported on the 0-1 scale.",
    year = 2024L, scenario = z$scenario)
}
new_outputs <- do.call(rbind, output_rows)
output_header <- names(read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
new_outputs <- new_outputs[output_header]
if (nrow(new_outputs) != 21L) stop("Unexpected number of source output rows.", call. = FALSE)

candidate_row <- data.frame(
  candidate_id = candidate_id, candidate_unit_id = "mpi_orh7a",
  organization = "Fisheries New Zealand", official_stock_id = "ORH 7A",
  scientific_name = "Hoplostethus atlanticus",
  stock_name = "Orange roughy - Challenger Plateau",
  assessment_area = "Southwest Challenger Plateau and Westpac Bank",
  inventory_assessment_year = 2024L,
  inventory_url = "https://fs.fish.govt.nz/Page.aspx?dk=26242&pk=113",
  retrieved_on = "2026-11-05", matched_stock_id = "", match_status = "new",
  screening_status = "screened", eligibility = "ineligible", import_status = "partial",
  catch_age_evidence = "The 2024 CASAL base case uses annual catch biomass, not catch-at-age; the report states there are no commercial age frequencies.",
  survey_age_evidence = "Six survey age-frequency likelihood samples are available, alongside aggregate trawl and acoustic biomass indices. No age-specific abundance index is fitted.",
  weights_evidence = "The CASAL appendix provides a von Bertalanffy length-at-age function and length-weight relationship, but no weight-at-age vector.",
  maturity_evidence = "The CASAL appendix uses an estimated logistic maturity/selectivity ogive; no numeric maturity-at-age vector is tabulated.",
  mortality_evidence = "Age-invariant M is estimated with a lognormal prior; the report cautions that estimated M is a general productivity descriptor.",
  timing_evidence = "CASAL observations occur in time step 2 with proportion_mortality=0.5; this is not a calendar-year sampling fraction.",
  output_evidence = "The 2026 Plenary reports M, B0, B2024/B0, and status probabilities for the 2024 All2 base case and sensitivities.",
  detailed_source_url = "https://fs.fish.govt.nz/Doc/25788/FAR-2024-58-Assessment-of-the-Challenger-Plateau-orange-roughy-stock-for-2024.pdf.ashx",
  review_date = "2026-11-05",
  decision_reason = "The official run inputs and summary outputs are imported. The assessment uses annual catch biomass and survey age compositions but reports no catch-at-age series or an age-specific abundance-index likelihood.",
  notes = "The All2 base-case observations are captured; All6 and 3Series output summaries are retained as source-reported sensitivities. Survey age-frequency samples are compositions and are not converted into age-specific abundance.",
  stringsAsFactors = FALSE
)
manifest <- data.frame(
  local_file = paste0(source_dir, "/", basename(source_files)),
  source_url = source_urls, retrieved_on = "2026-11-05", sha256 = source_hashes,
  stringsAsFactors = FALSE
)

validate_database_id <- function(path, id) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  classes <- rep("NULL", length(header))
  names(classes) <- header
  classes[["assessment_id"]] <- "character"
  existing <- read.csv(path, colClasses = classes, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(existing$assessment_id == id, na.rm = TRUE)) stop(id, " already appears in ", path, ".", call. = FALSE)
}
for (table in c("assumptions", "inputs", "outputs")) validate_database_id(file.path("database", paste0(table, ".csv")), assessment_id)

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id || candidate_id %in% candidates$candidate_id) {
  stop("The ORH 7A record already exists; inspect the current state before reimporting.", call. = FALSE)
}

cat("ORH 7A source import prepared: 1 stock, 1 assessment, ", nrow(new_assumptions),
  " assumptions, ", nrow(new_inputs), " inputs, ", nrow(new_outputs),
  " outputs, and 3 cached sources.\n", sep = "")
cat("Catch: 1981-2024 model years; All2 biomass indices: six trawl and two acoustic observations.\n")
cat("Age compositions: six survey samples, ages 15-100 plus group; no catch-at-age rows.\n")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the records and source manifest.\n")
} else {
  append_rows <- function(path, rows) {
    header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
    if (!identical(names(rows), header)) stop("Column mismatch for ", path, ".", call. = FALSE)
    write.table(rows, file = path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", quote = TRUE, qmethod = "double")
  }
  append_rows("database/stocks.csv", stock_row)
  append_rows("database/assessments.csv", assessment_row)
  append_rows("database/assumptions.csv", new_assumptions)
  append_rows("database/inputs.csv", new_inputs)
  append_rows("database/outputs.csv", new_outputs)
  append_rows("discovery/candidates.csv", candidate_row)
  utils::write.csv(manifest, "provenance/mpi_orh7a_2024_sources.csv",
    row.names = FALSE, na = "")
  cat("ORH 7A source records and source manifest appended.\n")
}
