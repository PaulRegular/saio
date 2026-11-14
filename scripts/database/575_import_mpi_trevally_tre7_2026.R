root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args

stock_id <- "mpi_trevally_tre7"
assessment_id <- "mpi_trevally_tre7_2026"
candidate_id <- "MPI:TRE7"
source_dir <- "source_cache/mpi_trevally_tre7_2026"
source_files <- file.path(source_dir, c(
  "FAR-2026-34-TRE7-assessment.pdf",
  "FAR-2025-38-TRE7-age-compositions.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/26266/FAR-2026-34-Stock-assessment-of-trevally-in-TRE7-for-2026.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26130/FAR-2025-38-Length-and-age-composition-TRE7-2022-23-and-2023-24.pdf.ashx"
)
source_hashes <- c(
  "DF854B9C6AB2E0E20581E4F164EBC58BF8C9E438ACB4772C3D5943BB1340CD8B",
  "2A0515A5E762F9DACC41347C6ABD799FA3894D5F44E5BC1480BC3E216968BA57"
)
if (!all(file.exists(source_files))) {
  stop("Cache the reviewed Fisheries New Zealand assessment and age-composition PDFs before importing.", call. = FALSE)
}
actual_hashes <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached source differs from the reviewed file.", call. = FALSE)
}

catches <- read.table(text = "
year NMB_BT KMNTB_BT NMB_KMNTB_BPT STB_BT_BPT
1975 0 0 1464 551
1976 0 0 1728 665
1977 0 0 2048 564
1978 0 0 2144 711
1979 12 39 2542 597
1980 130 422 1930 573
1981 202 660 2012 673
1982 73 237 2291 457
1983 64 165 1828 542
1984 56 146 1418 427
1985 66 171 1514 461
1986 82 213 1299 420
1987 197 778 441 373
1988 211 831 470 398
1989 198 782 443 375
1990 114 667 452 468
1991 17 680 499 941
1992 77 788 260 309
1993 364 1073 193 238
1994 440 1049 515 294
1995 561 1045 210 365
1996 345 767 512 416
1997 549 858 56 399
1998 355 1204 33 531
1999 259 1210 268 433
2000 298 954 338 687
2001 140 896 445 425
2002 77 962 279 510
2003 221 1162 442 246
2004 204 1162 467 345
2005 268 916 551 229
2006 118 1200 362 296
2007 189 1271 110 186
2008 160 1213 327 114
2009 324 1223 306 185
2010 473 951 322 240
2011 311 959 360 311
2012 413 1297 0 204
2013 209 1443 0 208
2014 483 887 0 256
2015 551 1211 0 79
2016 639 1060 0 270
2017 601 796 0 348
2018 641 964 0 180
2019 350 912 0 178
2020 278 1028 0 300
2021 386 663 0 109
2022 414 960 0 102
2023 312 620 0 211
2024 211 435 0 234
2025 302 682 0 342
", header = TRUE)
if (nrow(catches) != 51L || !identical(catches$year, 1975:2025)) {
  stop("Expected Table A13 catch histories for model years 1975-2025.", call. = FALSE)
}

cpue <- read.table(text = "
year index lci uci
1994 0.5740 0.4437 0.7403
1995 0.9290 0.7135 1.1703
1996 0.3049 0.2050 0.4288
1997 0.5588 0.4416 0.7134
1998 0.5051 0.3993 0.6276
1999 0.7626 0.6030 0.9476
2000 1.1835 0.9312 1.4726
2001 1.1575 0.9253 1.4447
2002 1.1131 0.8756 1.4091
2003 1.2691 0.9978 1.5504
2004 1.0501 0.8346 1.2888
2005 0.9799 0.7733 1.2091
2006 1.4448 1.1299 1.8073
2007 1.0048 0.8141 1.2334
2008 1.1351 0.9019 1.4095
2009 1.3491 1.0671 1.6864
2010 0.9382 0.7409 1.1880
2011 1.6221 1.2804 2.0151
2012 1.5609 1.2330 1.9570
2013 1.4164 1.1308 1.7725
2014 0.9152 0.7194 1.1567
2015 0.9722 0.7593 1.2253
2016 0.7619 0.6027 0.9505
2017 0.8508 0.6641 1.0690
2018 0.8365 0.6556 1.0676
2019 0.9854 0.7596 1.2455
2020 0.9951 0.7868 1.2478
2021 0.7300 0.5657 0.9336
2022 1.0094 0.7967 1.2606
2023 1.5851 1.2198 2.0005
2024 1.5188 1.1604 1.9763
2025 1.0489 0.8038 1.3257
", header = TRUE)
if (nrow(cpue) != 32L || !identical(cpue$year, 1994:2025)) {
  stop("Expected the 32 KMNTB CPUE model-year observations in Table A8.", call. = FALSE)
}

survey <- read.table(text = "
survey_year model_year northern northern_cv one_year one_year_cv southern southern_cv
1991 1992 1026 0.25 3.1 2.39 508 0.50
1994 1995 508 0.49 37.8 0.76 NA NA
1996 1997 315 0.35 96.2 0.59 NA NA
1999 2000 626 0.54 88.8 9.26 NA NA
2018 2019 587 0.19 62.1 1.83 2304 0.66
2019 2020 555 0.35 10.1 1.91 121 0.48
2020 2021 1173 0.30 72.1 0.71 464 0.48
2022 2023 682 0.49 1.9 3.49 2031 0.65
", header = TRUE)
if (nrow(survey) != 8L || !identical(survey$model_year, c(1992L, 1995L, 1997L, 2000L, 2019L, 2020L, 2021L, 2023L))) {
  stop("Unexpected Kaharoa survey years or model-year mapping.", call. = FALSE)
}

composition <- list(
  list(year = 2023L, region = "NMB", sample_size = 385,
    p = c(0, .1264, .2309, .1593, .0708, .0731, .0684, .0375, .0447, .0502, .0022, .0265, .0127, .0088, .0082, .0087, .0240, .0082, 0, .0394),
    cv = c(0, .44, .26, .22, .25, .27, .30, .38, .33, .44, 1.40, .39, .59, .86, .73, 1.03, .47, .88, 0, .35)),
  list(year = 2023L, region = "KMH", sample_size = 586,
    p = c(0, .0344, .1087, .0419, .1294, .1202, .1470, .0732, .0697, .0462, .0319, .0277, .0102, .0133, .0302, .0218, .0305, .0149, .0099, .0388),
    cv = c(0, .71, .31, .32, .22, .18, .19, .21, .26, .30, .29, .42, .57, .57, .39, .38, .35, .49, .58, .33)),
  list(year = 2023L, region = "NTB", sample_size = 118,
    p = c(0, .0288, .1241, .0966, .2146, .1407, .1464, .0620, .0393, .0400, 0, .0112, 0, .0058, .0397, .0169, .0112, .0112, 0, .0115),
    cv = c(0, 1.01, .28, .44, .19, .32, .29, .41, .59, .67, 0, 1.10, 0, 1.45, .47, .72, 1.10, 1.15, 0, 1.12)),
  list(year = 2023L, region = "STB", sample_size = 394,
    p = c(0, 0, .0152, .0541, .4812, .0409, .0629, .0175, .0396, .0218, .0054, .0143, .0307, .0180, .0366, .0120, .0248, .0006, .0082, .1162),
    cv = c(0, 0, .76, .39, .33, .52, .41, .64, .74, .47, .85, .59, .51, .79, .51, .71, .49, 1.60, .81, .37)),
  list(year = 2024L, region = "NMB", sample_size = 395,
    p = c(.0012, .0370, .0869, .2713, .2042, .0825, .0877, .0757, .0283, .0443, .0140, .0070, .0133, .0030, .0059, .0026, .0082, .0084, .0034, .0150),
    cv = c(1.42, .45, .30, .14, .16, .30, .20, .24, .36, .42, .52, .98, .57, 1.03, .97, 1.44, .74, .76, 1.35, .49)),
  list(year = 2024L, region = "KMH", sample_size = 588,
    p = c(.0047, .0679, .0840, .1182, .0756, .1078, .0924, .0605, .0669, .0775, .0272, .0168, .0180, .0088, .0153, .0301, .0175, .0140, .0178, .0787),
    cv = c(1.24, .53, .49, .35, .39, .24, .23, .23, .23, .43, .53, .53, .48, .66, .41, .40, .44, .47, .61, .26)),
  list(year = 2024L, region = "NTB", sample_size = 394,
    p = c(0, .0116, .0551, .1345, .0940, .1198, .1437, .1289, .0730, .0540, .0477, .0144, .0144, .0027, .0077, .0253, .0183, .0186, .0028, .0335),
    cv = c(0, .78, .38, .35, .34, .23, .18, .38, .28, .32, .32, .51, .62, 1.42, .91, .68, .55, .50, 1.05, .35)),
  list(year = 2024L, region = "STB", sample_size = 385,
    p = c(0, .0200, .0182, .0279, .0828, .3560, .0393, .0537, .0237, .0126, .0175, 0, .0125, .0044, .0108, .0323, .0142, .0340, .0114, .2286),
    cv = c(0, 1.05, .78, .54, .30, .35, .38, .40, .53, .60, .53, 0, .74, 1.13, .58, .49, .52, .46, .53, .22))
)
if (length(composition) != 8L ||
    any(vapply(composition, function(x) length(x$p) != 20L || length(x$cv) != 20L, logical(1))) ||
    any(vapply(composition, function(x) abs(sum(x$p) - 1) > 0.002, logical(1)))) {
  stop("Recent age-composition vectors are incomplete or do not sum to one.", call. = FALSE)
}

add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
    year_basis = "", age = NA_real_, age_group = "", fleet = "", survey = "",
    sex = "", region = "", season = "", sampling_time = NA_real_,
    source_type = "official_table", source_reference = "", transformation = "",
    notes = "", observation_id = "", sample_size = NA_real_,
    age_error = NA_real_, partition = "") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    year = as.integer(year), year_basis = year_basis, age = as.numeric(age),
    age_group = age_group, value = as.numeric(value), unit = unit,
    sampling_time = as.numeric(sampling_time), source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = as.numeric(sample_size), age_error = as.numeric(age_error),
    partition = partition, stringsAsFactors = FALSE
  )
}
input_rows <- list()
for (i in seq_len(nrow(catches))) {
  for (fleet_column in names(catches)[-1]) {
    area <- switch(
      fleet_column,
      NMB_BT = "NMB",
      KMNTB_BT = "KMNTB",
      NMB_KMNTB_BPT = "NMB and KMNTB",
      STB_BT_BPT = "STB"
    )
    fleet <- switch(
      fleet_column,
      NMB_BT = "NMB bottom trawl",
      KMNTB_BT = "KMNTB bottom trawl",
      NMB_KMNTB_BPT = "NMB and KMNTB bottom pair trawl",
      STB_BT_BPT = "STB bottom trawl and bottom pair trawl"
    )
    scope <- if (fleet_column == "STB_BT_BPT") {
      "Included in the TwoRegion sensitivity only; excluded from the Base northern model."
    } else {
      "Included in the Base northern assessment."
    }
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "catch", "total_biomass", "biomass", catches[[fleet_column]][i], "tonnes",
      year = catches$year[i], year_basis = "model_year", fleet = fleet,
      region = area, source_reference = "Fisheries New Zealand FAR 2026/34, Table A13, p. 75",
      notes = paste("Annual catch history including unreported catches.", scope),
      observation_id = paste0("tre7-catch-", fleet_column, "-", catches$year[i])
    )
  }
}

for (i in seq_len(nrow(cpue))) {
  ci_note <- sprintf("Table A8 reports the Combined index 95%% limits LCI %.4f and UCI %.4f. Fishing year %d-%02d maps to model year %d. The assessment adds 10%% process error; its annual fitted CV vector is not published.",
    cpue$lci[i], cpue$uci[i], cpue$year[i] - 1L, cpue$year[i] %% 100L, cpue$year[i])
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "relative_biomass_index", "index_scale", cpue$index[i],
    "relative CPUE index", year = cpue$year[i], year_basis = "model_year",
    fleet = "KMNTB bottom trawl", region = "KMNTB",
    source_reference = "Fisheries New Zealand FAR 2026/34, Table A8, Appendix 2",
    notes = ci_note,
    observation_id = paste0("tre7-kmntb-cpue-", cpue$year[i])
  )
}

for (i in seq_len(nrow(survey))) {
  year <- survey$model_year[i]
  northern_id <- paste0("tre7-kaharoa-north-", year)
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "total_biomass", "biomass", survey$northern[i], "tonnes",
    year = year, year_basis = "model_year",
    survey = "Kaharoa WCNI trawl survey", region = "Northern NMB/KMNTB core",
    source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
    notes = paste0("Survey calendar year ", survey$survey_year[i],
      " maps to this model year. Base-model northern biomass index."),
    observation_id = northern_id
  )
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "biomass_index_cv", "relative_scale", survey$northern_cv[i], "ratio",
    year = year, year_basis = "model_year",
    survey = "Kaharoa WCNI trawl survey", region = "Northern NMB/KMNTB core",
    source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
    notes = "Source-reported CV for the northern biomass index.",
    observation_id = northern_id
  )
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "numbers_at_age", "numbers", survey$one_year[i], "thousand fish",
    year = year, year_basis = "model_year", age = 1,
    survey = "Kaharoa WCNI trawl survey", region = "Northern NMB/KMNTB core",
    source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
    notes = paste0("Index of one-year-old fish; survey calendar year ",
      survey$survey_year[i], " maps to this model year."),
    observation_id = paste0("tre7-kaharoa-one-year-", year)
  )
  input_rows[[length(input_rows) + 1L]] <- add_input(
    "index", "numbers_at_age_cv", "relative_scale", survey$one_year_cv[i], "ratio",
    year = year, year_basis = "model_year", age = 1,
    survey = "Kaharoa WCNI trawl survey", region = "Northern NMB/KMNTB core",
    source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
    notes = if (survey$one_year_cv[i] == 9.26) {
      "Source-reported CV. Table 4 gives 9.26, while Table 6 summarizes the fitted-series CV range as 0.59-3.49; both source values are preserved without adjustment."
    } else {
      "Source-reported CV for the one-year-old abundance index."
    },
    observation_id = paste0("tre7-kaharoa-one-year-", year)
  )
  if (is.finite(survey$southern[i])) {
    southern_id <- paste0("tre7-kaharoa-south-", year)
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "index", "total_biomass", "biomass", survey$southern[i], "tonnes",
      year = year, year_basis = "model_year",
      survey = "Kaharoa WCNI trawl survey", region = "Southern TRE 7 (STB)",
      source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
      notes = "Southern biomass index used in the TwoRegion sensitivity, not the Base northern model.",
      observation_id = southern_id
    )
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "index", "biomass_index_cv", "relative_scale", survey$southern_cv[i], "ratio",
      year = year, year_basis = "model_year",
      survey = "Kaharoa WCNI trawl survey", region = "Southern TRE 7 (STB)",
      source_reference = "Fisheries New Zealand FAR 2026/34, Table 4, p. 28",
      notes = "Source-reported CV for the southern index used in the TwoRegion sensitivity.",
      observation_id = southern_id
    )
  }
}

for (x in composition) {
  observation_id <- paste0("tre7-age-", x$year, "-", x$region)
  table_ref <- if (x$year == 2023L) {
    "Fisheries New Zealand FAR 2025/38, Table A6.1, pp. 54-55"
  } else {
    "Fisheries New Zealand FAR 2025/38, Table A7.1, pp. 55-56"
  }
  region_name <- switch(
    x$region,
    NMB = "Ninety Mile Beach (NMB)",
    KMH = "Kaipara-Manukau (KMH)",
    NTB = "North Taranaki Bight (NTB)",
    STB = "South Taranaki Bight (STB)"
  )
  sample_note <- paste(
    "Source-reported commercial proportion at age; age 20 is the source >19 plus group.",
    "sample_size is the number aged in the sampling report, not the assessment effective sample size.",
    "FAR 2026/34 does not publish the KMH+NTB combined likelihood vector; these source-area values are kept separate.",
    if (x$region == "STB") "STB composition relates to the TwoRegion sensitivity and is excluded from the Base model." else
      "Northern subarea composition is relevant to the Base assessment."
  )
  for (age in 1:20) {
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "catch", "proportion_at_age", "proportion_numbers", x$p[age], "proportion",
      year = x$year, year_basis = "model_year", age = age,
      fleet = if (x$year == 2023L) "Commercial bottom trawl" else
        "Commercial bottom trawl and precision bottom trawl",
      region = region_name, source_reference = table_ref, notes = sample_note,
      observation_id = observation_id, sample_size = x$sample_size
    )
    input_rows[[length(input_rows) + 1L]] <- add_input(
      "catch", "relative_standard_error", "relative_scale", x$cv[age], "ratio",
      year = x$year, year_basis = "model_year", age = age,
      fleet = if (x$year == 2023L) "Commercial bottom trawl" else
        "Commercial bottom trawl and precision bottom trawl",
      region = region_name, source_reference = table_ref,
      notes = "Source-reported coefficient of variation for the age proportion; retained on its reported relative scale.",
      observation_id = observation_id
    )
  }
}
new_inputs <- do.call(rbind, input_rows)
input_header <- names(read.csv("database/inputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
new_inputs <- new_inputs[input_header]
if (nrow(new_inputs) != 598L) {
  stop("Unexpected number of recovered TRE 7 input rows.", call. = FALSE)
}

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "",
    fleet = "", survey = "", region = "", season = "", sex = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = fleet,
    survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE
  )
}
add_assumption("model", "model_structure",
  "Stock Synthesis 3.30.23.1; model years 1975-2025; sexes combined; ages 1-39 plus age 40+; exploited equilibrium initial population; initial F estimated without a prior.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, pp. 29-30")
add_assumption("model", "base_model_area",
  "Northern TRE 7 sub-stock: NMB and KMNTB; STB catch is excluded. The TwoRegion run is a separate whole-TRE 7 sensitivity and was not selected as the base result.",
  "Fisheries New Zealand FAR 2026/34, Sections 5.1-5.2, pp. 29-31; Table 7, p. 45")
add_assumption("mortality", "natural_mortality",
  "Fixed, age-invariant M = 0.10 per year.",
  "Fisheries New Zealand FAR 2026/34, Table 5, p. 30",
  "The report derives this setting as log(100)/45, assuming a maximum age of 45 years.")
add_assumption("biology", "growth",
  "Combined-sex von Bertalanffy growth: L1 = 13.64 cm, Linf = 44.99 cm, k = 0.225.",
  "Fisheries New Zealand FAR 2026/34, Table 5, p. 30")
add_assumption("biology", "length_weight_relationship",
  "Length-weight parameters a = 3.471e-05 and b = 2.826.",
  "Fisheries New Zealand FAR 2026/34, Table 5, p. 30",
  "The table reports coefficients but does not state the units in the row; no unit conversion is inferred.")
add_assumption("biology", "maturity_at_age",
  "Ages 1-3 = 0; age 4 = 0.5; ages 5+ = 1.0.",
  "Fisheries New Zealand FAR 2026/34, Table 5, p. 30")
add_assumption("recruitment", "stock_recruitment",
  "Beverton-Holt; steepness fixed at 0.80; recruitment log-SD fixed at 0.60.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, p. 30; Table 5, p. 30")
add_assumption("recruitment", "recruitment_deviations",
  "Main recruitment deviations estimated for 1975-2023; early deviations for 1960-1974 estimated to configure the initial 1975 age structure.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, p. 30")
add_assumption("model", "initial_population",
  "Initial age structure is an exploited equilibrium; initial fishing mortality is estimated with no prior.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, p. 30",
  "The report describes the initial F estimate as uncertain; its numeric posterior is not tabulated.")
add_assumption("fishery", "selectivity",
  "KMNTB bottom trawl selectivity is logistic; NMB trawl is double-normal; BPT shares KMNTB BT selectivity.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, p. 30")
add_assumption("index", "cpue_index",
  "KMNTB bottom trawl CPUE is the primary abundance index and is linked to vulnerable biomass.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2, p. 30")
add_assumption("index", "cpue_process_error",
  "10% process error is added to each KMNTB CPUE observation; Table 6 reports fitted CVs of 0.21-0.31.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2 and Table 6, pp. 30-31",
  "Table A8 reports annual 95% confidence limits, but the final annual fitted CV vector is not tabulated; no annual CVs were derived.")
add_assumption("index", "kaharoa_core_area",
  "Northern trawl survey core approximates KMNTB and NMB inside the 100 m depth contour, excluding the Maui dolphin trawl exclusion area.",
  "Fisheries New Zealand FAR 2026/34, Section 4.1, p. 28")
add_assumption("index", "survey_timing",
  "Kaharoa surveys occur in October-November; the numerical within-year observation fraction is not stated.",
  "Fisheries New Zealand FAR 2026/34, Section 4.1, p. 28",
  "sampling_time is left blank.")
add_assumption("composition", "age_composition_weighting",
  "Age compositions use Francis method TA1.8; final ESS ranges are BPT 26, KMNTB 5.9-27.8, and NMB 8.1-43.2.",
  "Fisheries New Zealand FAR 2026/34, Section 5.2 and Table 6, pp. 30-31",
  "Annual ESS values and the exact KMH+NTB combined input vectors are not published.")
add_assumption("composition", "survey_length_composition",
  "Kaharoa length compositions have final ESS 1.",
  "Fisheries New Zealand FAR 2026/34, Table 6, p. 31",
  "The annual length-composition vectors are not imported.")
add_assumption("data", "age_composition_coverage",
  "Fitted samples include BPT 1975, 1976, 1978, 1979, 1998, 1999, 2001; KMNTB 1998-2001, 2006-2008, 2010, 2013, 2023, 2024; NMB 1998-2001, 2007-2008, 2010, 2013, 2023, 2024.",
  "Fisheries New Zealand FAR 2026/34, Table 6, p. 31",
  "Older detailed vectors are not included in this import. Recent source-area vectors from FAR 2025/38 are preserved separately and not combined into an unpublished KMNTB likelihood vector.")
new_assumptions <- do.call(rbind, assumption_rows)

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "TRE 7", scientific_name = "Pseudocaranx dentex",
  common_name = "Trevally",
  area = "TRE 7; west coast of the North Island and north and west coasts of the South Island",
  region = "West coast of New Zealand",
  ocean = "Southwest Pacific",
  notes = "The official TRE 7 stock unit includes the full management area. The 2026 base assessment estimates only the northern NMB and KMNTB sub-stock; STB is included only in a separate TwoRegion sensitivity.",
  stringsAsFactors = FALSE
)
assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2025L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.23.1", is_current = TRUE, is_applied = TRUE,
  framework_year = NA_integer_,
  assessment_url = "https://fs.fish.govt.nz/Page.aspx?dk=26266&pk=113",
  framework_url = "", data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed official assessment located. The Base model is the northern NMB/KMNTB sub-stock, not the full TRE 7 stock unit. The import preserves Table A13 catch biomass, KMNTB CPUE, Kaharoa indices, source-area 2022-23 and 2023-24 proportions-at-age, core model assumptions, and terminal summary outputs. Historical age-composition vectors, exact annual ESS values, survey length compositions, native SS3 files, and annual numerical population surfaces are not included.",
  stringsAsFactors = FALSE
)

output_rows <- list()
add_output <- function(type, measure, value, unit, source_reference, notes,
    year = NA_integer_, lwr = NA_real_, upr = NA_real_, scenario = "Base") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "Northern NMB/KMNTB base model",
    season = "", year = as.integer(year), age = NA_real_, age_group = "",
    value = as.numeric(value), se = NA_real_, lwr = as.numeric(lwr),
    upr = as.numeric(upr), unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE
  )
}
table7_ref <- "Fisheries New Zealand FAR 2026/34, Table 7, p. 45"
table8_ref <- "Fisheries New Zealand FAR 2026/34, Table 8, p. 46"
table9_ref <- "Fisheries New Zealand FAR 2026/34, Table 9, p. 47"
interval_note <- "MCMC median and source-reported 95% interval; no standard error is reported."
add_output("biomass", "unfished_spawning_biomass", 58862, "tonnes",
  table7_ref, paste(interval_note, "Female spawning biomass SB0 for the northern base model."),
  lwr = 45728, upr = 80440)
add_output("biomass", "spawning_biomass", 34648, "tonnes",
  table7_ref, paste(interval_note, "Female spawning biomass SB2025 for the northern base model."),
  year = 2025L, lwr = 23425, upr = 58260)
add_output("biomass", "target_spawning_biomass", 23545, "tonnes",
  table7_ref, paste(interval_note, "SB40, the 40% SB0 target biomass."),
  lwr = 18291, upr = 32176)
add_output("biomass", "SSB_ratio_to_B0", 0.594, "ratio",
  table7_ref, paste(interval_note, "SB2025/SB0 for the northern base model."),
  year = 2025L, lwr = 0.432, upr = 0.820)
add_output("biomass", "SSB_ratio_to_SB40", 1.485, "ratio",
  table7_ref, paste(interval_note, "SB2025/SB40 for the northern base model."),
  year = 2025L, lwr = 1.080, upr = 2.049)
add_output("mortality", "target_fishing_mortality", 0.072, "per year",
  table8_ref, "MCMC median target fishing mortality FSB40; a 95% interval is not reported.")
add_output("mortality", "fishing_mortality_ratio_to_target", 0.368, "ratio",
  table8_ref, paste(interval_note, "F2025/FSB40 for the northern base model."),
  year = 2025L, lwr = 0.226, upr = 0.536)
add_output("mortality", "probability_fishing_mortality_below_target", 1, "probability",
  table8_ref, "Source-reported probability that F2025 is below FSB40.",
  year = 2025L)
add_output("biomass", "SSB2030_ratio_to_B0", 0.568, "ratio",
  table9_ref, paste(interval_note, "Five-year forecast at current TACC; SB2030/SB0."),
  year = 2030L, lwr = 0.398, upr = 0.816)
add_output("biomass", "probability_SSB2030_above_10_percent_B0", 1, "probability",
  table9_ref, "Source-reported forecast probability that SB2030 exceeds 10% SB0.",
  year = 2030L)
add_output("biomass", "probability_SSB2030_above_20_percent_B0", 1, "probability",
  table9_ref, "Source-reported forecast probability that SB2030 exceeds 20% SB0.",
  year = 2030L)
add_output("biomass", "probability_SSB2030_above_40_percent_B0", 0.97, "probability",
  table9_ref, "Source-reported forecast probability that SB2030 exceeds 40% SB0.",
  year = 2030L)
new_outputs <- do.call(rbind, output_rows)
output_header <- names(read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
new_outputs <- new_outputs[output_header]
if (nrow(new_assumptions) != 17L || nrow(new_outputs) != 12L) {
  stop("Unexpected assumption or output row count.", call. = FALSE)
}

for (table in c("assumptions", "inputs", "outputs")) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE, check.names = FALSE))
  classes <- rep("NULL", length(header))
  names(classes) <- header
  classes[["assessment_id"]] <- "character"
  existing <- read.csv(path, colClasses = classes, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(existing$assessment_id == assessment_id, na.rm = TRUE)) {
    stop(assessment_id, " already appears in ", path, ".", call. = FALSE)
  }
}
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("The TRE 7 canonical record already exists; inspect the current state before reimporting.", call. = FALSE)
}
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidate_index <- which(candidates$candidate_id == candidate_id)
if (length(candidate_index) != 1L || candidates$import_status[candidate_index] != "not_started") {
  stop("Expected one not-started TRE 7 candidate row before importing.", call. = FALSE)
}

manifest <- data.frame(
  local_file = paste0(source_dir, "/", basename(source_files)),
  source_url = source_urls, retrieved_on = "2026-11-05", sha256 = source_hashes,
  stringsAsFactors = FALSE
)

cat("TRE 7 source import prepared: 1 stock, 1 assessment, ",
  nrow(new_assumptions), " assumptions, ", nrow(new_inputs), " inputs, ",
  nrow(new_outputs), " outputs, and 2 cached sources.\n", sep = "")
cat("Inputs preserve 1975-2025 catch biomass, 1994-2025 KMNTB CPUE, Kaharoa indices, and 2023-2024 source-area age proportions.\n")
cat("The import is partial: older fitted composition vectors, annual population surfaces, and exact model likelihood weights remain unavailable in the recovered files.\n")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the source records.\n")
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
  candidates$matched_stock_id[candidate_index] <- stock_id
  candidates$match_status[candidate_index] <- "matched"
  candidates$import_status[candidate_index] <- "partial"
  candidates$catch_age_evidence[candidate_index] <- "FAR 2026/34 Table A13 provides total catch biomass, not catch-at-age counts. Proportion-at-age source data for 2022-23 and 2023-24 are imported from FAR 2025/38 by source subarea; older fitted vectors and the exact KMNTB combined vector remain unextracted."
  candidates$survey_age_evidence[candidate_index] <- "Kaharoa biomass and one-year-old abundance indices with CVs are imported from FAR 2026/34 Table 4. Table 6 identifies the fitted age-composition years and ESS ranges; most fitted age vectors and the exact annual ESS values are not imported."
  candidates$weights_evidence[candidate_index] <- "FAR 2026/34 reports combined-sex growth and length-weight parameters. The recent FAR 2025/38 empirical mean weights-at-age are not confirmed as fitted stock-weight inputs and are not substituted for the assessment biological relationships."
  candidates$output_evidence[candidate_index] <- "Tables 7-9 of FAR 2026/34 provide MCMC median and 95% intervals for SB0, SB2025, SB40, status ratios, F reference metrics, and 2030 forecast status. Annual SSB and recruitment are figures only; numerical N/F-at-age surfaces are not tabulated."
  candidates$decision_reason[candidate_index] <- "Partial source import completed from the latest detailed production assessment and recent age-composition report. Numerical source coverage is strong for catches, CPUE, Kaharoa indices, biology, and summary outputs, but older fitted compositions, exact KMNTB aggregation, annual ESS, survey length compositions, and annual numerical population surfaces remain unresolved."
  candidates$notes[candidate_index] <- "The official TRE 7 stock covers the full management area, but the 2026 Base model covers northern NMB/KMNTB only; STB inputs are identified as TwoRegion sensitivity data. Source-area recent compositions are preserved separately; no composition aggregation, catch-at-age reconstruction, or age-specific population output was invented."
  candidate_path <- "discovery/candidates.csv"
  candidate_lines <- readLines(candidate_path, warn = FALSE, encoding = "UTF-8")
  candidate_row <- capture.output(write.table(
    candidates[candidate_index, , drop = FALSE], file = "", sep = ",",
    row.names = FALSE, col.names = FALSE, na = "", quote = TRUE,
    qmethod = "double"
  ))
  candidate_line <- which(startsWith(candidate_lines, paste0('"', candidate_id, '",')))
  if (length(candidate_line) != 1L || length(candidate_row) != 1L) {
    stop("Could not safely update the single TRE 7 candidate row.", call. = FALSE)
  }
  candidate_lines[candidate_line] <- candidate_row
  writeLines(candidate_lines, candidate_path, useBytes = TRUE)
  utils::write.csv(manifest, "provenance/mpi_trevally_tre7_2026_sources.csv",
    row.names = FALSE, na = "")
  cat("TRE 7 source records and source manifest appended; candidate import status is partial.\n")
}

