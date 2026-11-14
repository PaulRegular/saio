root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args
stock_id <- "mpi_snapper_sna8"
assessment_id <- "mpi_snapper_sna8_2024"
candidate_id <- "MPI:SNA8"
source_dir <- "source_cache/mpi_snapper_sna8_2024"
source_files <- file.path(source_dir, c(
  "FAR-2024-49-SNA8-assessment.pdf",
  "FAR-2024-50-SNA8-age-composition.pdf",
  "FAP-2025-SNA8-plenary.pdf"
))
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/25777/FAR-2024-49-Stock-assessment-of-snapper-in-SNA8-for-2024.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25778/FAR-2024-50-Length-and-age-composition-of-commercial-snapper-landings-in-SNA8-2022-23.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26113/snapper-sna-8-fisheries-assessment-plenary-may-2025-volume-3.pdf.ashx"
)
source_hashes <- c(
  "DA831791A82867CCA0B04833859A26CE63160E08D5F8D4039C0023D35022216D",
  "9E5313471B8FA1957BF679EEEA6EE85890F9BB26FEAA19495535A10B43C12580",
  "3D6A2FAAFA10287472DB78A77949584FBD0F936D24802F56E4428FF5CE27022B"
)
if (!all(file.exists(source_files))) {
  stop("Cache the three reviewed SNA 8 source PDFs before importing.", call. = FALSE)
}
actual_hashes <- toupper(unname(tools::sha256sum(source_files)))
if (!identical(actual_hashes, source_hashes)) {
  stop("A cached SNA 8 source differs from the reviewed file.", call. = FALSE)
}

catches <- read.table(text = "
year BT BPT JPLL Rec1 Rec2
1931 168 0 0 45 15
1932 191 0 0 47 16
1933 256 0 0 50 17
1934 228 0 0 52 17
1935 130 0 0 54 18
1936 124 0 0 56 19
1937 102 0 0 59 20
1938 107 0 0 61 20
1939 85 0 0 63 21
1940 91 0 0 65 22
1941 74 0 0 68 23
1942 68 0 0 70 23
1943 90 0 0 72 24
1944 83 0 0 75 25
1945 149 0 0 77 26
1946 293 0 0 79 26
1947 301 0 0 81 27
1948 258 0 0 84 28
1949 332 0 0 86 29
1950 382 0 0 88 29
1951 437 0 0 91 30
1952 433 0 0 93 31
1953 1349 0 0 95 32
1954 1312 0 0 97 32
1955 1442 0 0 100 33
1956 1396 0 0 102 34
1957 1766 0 0 104 35
1958 1354 0 0 106 35
1959 1337 0 0 109 36
1960 1442 0 0 111 37
1961 1414 0 0 113 38
1962 1622 0 0 116 39
1963 1747 0 0 118 39
1964 1531 0 0 120 40
1965 1418 0 2000 122 41
1966 2197 0 2000 125 42
1967 1772 0 2000 127 42
1968 1789 0 2000 129 43
1969 1613 0 2000 131 44
1970 1906 0 2000 134 45
1971 2222 0 2000 136 45
1972 1177 1177 2000 138 46
1973 1823 1823 2000 141 47
1974 2604 2604 2000 143 48
1975 2530 2530 749 145 48
1976 2557 3835 1127 147 49
1977 1419 3310 1104 150 50
1978 1042 4166 0 152 51
1979 831 3325 0 154 51
1980 794 3177 0 156 52
1981 757 3027 0 159 53
1982 633 2531 0 161 54
1983 435 1741 0 163 54
1984 414 1656 0 166 55
1985 371 1484 0 168 56
1986 439 1755 0 170 57
1987 295 688 0 172 57
1988 616 925 0 175 58
1989 840 840 0 177 59
1990 1010 696 0 179 60
1991 1091 734 0 179 60
1992 1101 504 0 179 60
1993 1382 315 0 179 60
1994 1163 534 0 179 60
1995 971 609 0 179 60
1996 1128 586 0 179 60
1997 1485 290 0 170 57
1998 1505 243 0 162 54
1999 1315 485 0 156 52
2000 1241 523 0 157 52
2001 1235 559 0 166 55
2002 1389 345 0 172 57
2003 1414 300 0 184 61
2004 1592 242 0 197 66
2005 1255 574 0 204 68
2006 1155 423 0 208 69
2007 1295 165 0 195 65
2008 1231 204 0 220 73
2009 1332 148 0 253 84
2010 1223 185 0 299 100
2011 1289 155 0 374 125
2012 1488 8 0 473 158
2013 1464 0 0 431 144
2014 1403 0 0 559 186
2015 1399 0 0 459 153
2016 1461 0 0 722 241
2017 1467 0 0 586 195
2018 1416 0 0 669 223
2019 1421 0 0 808 269
2020 1481 0 0 841 280
2021 1425 0 0 967 322
2022 1891 0 0 972 324
2023 1901 0 0 511 170
2024 1760 0 0 1070 357
", header = TRUE)
if (nrow(catches) != 94L || !identical(catches$year, 1931:2024)) {
  stop("Expected the complete Table A3 model catch history for 1931-2024.", call. = FALSE)
}

cpue <- read.table(text = "
fishing_year year index lwr upr
96/97 1997 0.771 0.669 0.877
97/98 1998 0.781 0.667 0.900
98/99 1999 0.870 0.768 0.978
99/00 2000 1.056 0.938 1.178
00/01 2001 0.769 0.676 0.872
01/02 2002 1.124 1.001 1.265
02/03 2003 1.125 1.001 1.258
03/04 2004 0.837 0.734 0.954
04/05 2005 1.079 0.950 1.229
05/06 2006 1.088 0.929 1.252
06/07 2007 0.924 0.798 1.052
07/08 2008 1.420 1.250 1.593
08/09 2009 1.466 1.303 1.642
09/10 2010 1.904 1.676 2.172
10/11 2011 2.699 2.328 3.076
11/12 2012 2.711 2.381 3.064
12/13 2013 2.934 2.579 3.318
13/14 2014 3.322 2.901 3.796
14/15 2015 3.872 3.321 4.502
15/16 2016 3.752 3.256 4.305
16/17 2017 3.167 2.740 3.647
17/18 2018 3.896 3.314 4.546
18/19 2019 4.450 3.789 5.177
19/20 2020 3.349 2.856 3.888
20/21 2021 3.532 2.936 4.161
21/22 2022 4.447 3.761 5.155
22/23 2023 5.004 4.114 5.936
", header = TRUE)
if (nrow(cpue) != 27L || !identical(cpue$year, 1997:2023)) {
  stop("Expected all 27 combined BT CPUE values from Table A2.", call. = FALSE)
}

survey <- read.table(text = "
survey_year model_year age2 age3 age4 age5
1989 1990 50.1 407.7 562.0 343.9
1991 1992 36.3 344.9 38.7 136.6
1994 1995 344.9 192.7 247.3 36.9
1996 1997 996.0 244.0 262.6 60.7
1999 2000 876.3 109.2 601.8 157.2
2018 2019 658.2 1141.9 731.6 683.2
2019 2020 902.0 727.6 2353.1 809.4
2020 2021 820.4 1188.6 1410.7 2404.4
2022 2023 754.0 1185.2 802.3 843.2
", header = TRUE)
if (nrow(survey) != 9L || !identical(survey$model_year,
  c(1990L, 1992L, 1995L, 1997L, 2000L, 2019L, 2020L, 2021L, 2023L))) {
  stop("Expected the nine survey-year rows in Table 5.", call. = FALSE)
}

age_comp <- read.table(text = "
age proportion cv n
1 0.0000 0.00 NA
2 0.0082 0.41 12
3 0.0867 0.20 74
4 0.1751 0.11 83
5 0.1675 0.12 64
6 0.1801 0.11 68
7 0.1372 0.13 61
8 0.0415 0.22 26
9 0.0666 0.17 42
10 0.0147 0.32 11
11 0.0167 0.25 16
12 0.0166 0.30 16
13 0.0245 0.21 29
14 0.0203 0.25 20
15 0.0060 0.38 8
16 0.0046 0.40 8
17 0.0097 0.25 16
18 0.0101 0.28 13
19 0.0028 0.46 4
20 0.0030 0.47 5
21 0.0013 0.51 6
22 0.0024 0.54 4
23 0.0007 0.67 2
24 0.0004 1.09 1
25 0.0009 0.62 6
26 0.0001 1.69 1
27 0.0004 1.47 2
28 0.0005 0.75 3
29 0.0000 0.00 NA
30 0.0014 0.69 6
", header = TRUE)
if (nrow(age_comp) != 30L || abs(sum(age_comp$proportion) - 1) > 0.001) {
  stop("Expected the 30 age classes in the 2022-23 north BT composition.", call. = FALSE)
}

weight_age <- read.table(text = "
age weight cv
2 0.39 0.03
3 0.48 0.03
4 0.66 0.03
5 0.82 0.03
6 0.95 0.02
7 1.08 0.02
8 1.26 0.04
9 1.30 0.03
10 1.51 0.07
11 1.65 0.04
12 1.53 0.07
13 1.75 0.04
14 1.67 0.06
15 1.91 0.06
16 2.20 0.11
17 2.40 0.04
18 2.23 0.05
19 2.49 0.08
20 2.28 0.16
21 3.56 0.12
22 2.66 0.11
23 3.19 0.20
24 4.43 0.68
25 3.94 0.11
26 3.76 0.96
27 5.21 0.83
28 3.38 0.17
30 5.34 0.17
", header = TRUE)
if (nrow(weight_age) != 28L || anyDuplicated(weight_age$age)) {
  stop("Expected the reported north BT weight-at-age cells from Appendix 8.", call. = FALSE)
}

stock_header <- names(read.csv("database/stocks.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assessment_header <- names(read.csv("database/assessments.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
assumption_header <- names(read.csv("database/assumptions.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
input_header <- names(read.csv("database/inputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))
output_header <- names(read.csv("database/outputs.csv", nrows = 0L,
  stringsAsFactors = FALSE, check.names = FALSE))

make_record <- function(header, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(header)),
    stringsAsFactors = FALSE)
  names(out) <- header
  out
}
make_inputs <- function(data, type, measure, basis, unit, source_reference,
  default_notes) {
  out <- make_record(input_header, nrow(data))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  out$notes <- default_notes
  for (name in intersect(names(data), names(out))) {
    value <- as.character(data[[name]])
    value[is.na(value)] <- ""
    out[[name]] <- value
  }
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- source_reference
  if (!"notes" %in% names(data)) out$notes <- default_notes
  out
}
make_assumption <- function(component, setting, value, source_reference, notes) {
  out <- make_record(assumption_header, 1L)
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

catch_long <- do.call(rbind, lapply(c("BT", "BPT", "JPLL", "Rec1", "Rec2"), function(fleet) {
  data.frame(
    fleet = unname(c(BT = "Single trawl (BT)", BPT = "Pair trawl (BPT)",
      JPLL = "Japanese longline (JPLL)", Rec1 = "Recreational outside harbours (Rec1)",
      Rec2 = "Recreational inside harbours (Rec2)")[fleet]),
    year = catches$year,
    year_basis = "model_year",
    value = catches[[fleet]],
    stringsAsFactors = FALSE
  )
}))
catch_inputs <- make_inputs(catch_long, "catch", "total_biomass", "biomass",
  "tonnes", "FAR 2024/49, Table A3, p. 77.",
  paste("Table A3 model catch history. Historical and recreational series include",
    "assumptions, apportionments, and reconstructed values described in the report;",
    "these values are not all direct landings observations."))

cpue$year_basis <- "model_year"
cpue$fleet <- "Single trawl CPUE (BT)"
cpue$season <- "January-April"
cpue$region <- "Core area north of Cape Egmont"
cpue$notes <- paste0(
  "Combined single-trawl CPUE index from fishing year ", cpue$fishing_year,
  "; reported 95% limits ", cpue$lwr, "-", cpue$upr,
  ". Table 7 reports 26 likelihood observations while Table A2 lists 27 rows;",
  " likelihood status of individual rows is not resolved here."
)
cpue_inputs <- make_inputs(cpue, "index", "relative_biomass_index",
  "relative_scale", "relative index", "FAR 2024/49, Appendix 2, Table A2, p. 76.",
  "")

survey_long <- do.call(rbind, lapply(2:5, function(age) {
  data.frame(
    survey = "Kaharoa WCNI trawl survey",
    region = "Core area north of Cape Egmont",
    year = survey$model_year,
    year_basis = "model_year",
    age = age,
    value = survey[[paste0("age", age)]],
    notes = paste0(
      "Survey calendar year ", survey$survey_year,
      "; observed age class ", age - 1L, "+. Source gives values in thousands;",
      " numerical CVs are not tabulated."
    ),
    stringsAsFactors = FALSE
  )
}))
survey_inputs <- make_inputs(survey_long, "index", "numbers_at_age",
  "numbers", "thousands of fish", "FAR 2024/49, Table 5, p. 33.",
  "")

age_comp$year <- 2023L
age_comp$year_basis <- "model_year"
age_comp$fleet <- "North bottom trawl"
age_comp$region <- "North of Cape Egmont"
age_comp$season <- "Spring-summer"
age_comp$age <- age_comp$age
age_comp$value <- age_comp$proportion
age_comp$sample_size <- age_comp$n
age_comp$notes <- ifelse(age_comp$age == 30,
  "The source group is >29 years and is stored at age 30, matching the assessment 30+ plus group.",
  "Source age-composition row; the source n field is retained as sample_size and is not the assessment ESS.")
age_prop_inputs <- make_inputs(age_comp, "catch", "proportion_at_age",
  "proportion", "proportion",
  "FAR 2024/50, Appendix 5, p. 48; FAR 2024/49, Table 3, p. 25.",
  "")
age_cv <- age_comp
age_cv$value <- age_cv$cv
age_cv$notes <- "Bootstrap coefficient of variation for the source proportion-at-age; not the assessment effective sample size."
age_cv_inputs <- make_inputs(age_cv, "catch", "relative_standard_error",
  "relative_scale", "ratio",
  "FAR 2024/50, Appendix 5, p. 48.",
  "")

weight_age$year <- 2023L
weight_age$year_basis <- "model_year"
weight_age$fleet <- "North bottom trawl sampled landings"
weight_age$region <- "North of Cape Egmont"
weight_age$season <- "Spring-summer"
weight_age$value <- weight_age$weight
weight_age$notes <- ifelse(weight_age$age == 30,
  "Source group is >29 years; empirical sampled-landings weight, not the assessment's fixed annual biological surface.",
  "Empirical north BT sampled-landings mean weight-at-age; not substituted for the assessment's fixed length-weight and growth relationships.")
weight_inputs <- make_inputs(weight_age, "weight", "weight_at_age",
  "kg_per_fish", "kg/fish",
  "FAR 2024/50, Appendix 8, p. 50.",
  "")
weight_cv <- weight_age
weight_cv$value <- weight_cv$cv
weight_cv$notes <- "Bootstrap CV of the empirical sampled-landings weight-at-age; not the assessment's model likelihood SD."
weight_cv_inputs <- make_inputs(weight_cv, "weight", "relative_standard_error",
  "relative_scale", "ratio",
  "FAR 2024/50, Appendix 8, p. 50.",
  "")

new_inputs <- rbind(catch_inputs, cpue_inputs, survey_inputs, age_prop_inputs,
  age_cv_inputs, weight_inputs, weight_cv_inputs)
if (nrow(new_inputs) != 94L * 5L + 27L + 9L * 4L + 30L * 2L + 28L * 2L) {
  stop("Unexpected SNA 8 input row count.", call. = FALSE)
}

stock_row <- make_record(stock_header, 1L)
stock_row[1, ] <- list(
  stock_id, "", "Fisheries New Zealand", "SNA 8", "Chrysophrys auratus",
  "Snapper", "SNA 8, west coast of New Zealand North Island",
  "West coast North Island", "Southwest Pacific",
  paste("SNA 8 is one current management stock. The 2024 Base Case includes catch",
    "from the whole QMA, while most observational data are from north of Cape Egmont.")
)
assessment_row <- make_record(assessment_header, 1L)
assessment_row[1, ] <- list(
  assessment_id, stock_id, "2024", "2024", "2024", "full_assessment",
  "Stock Synthesis", "3.30.22.00", "TRUE", "TRUE", "",
  source_urls[1L], "", source_urls[2L], "", "",
  "partial", "partial", "partial",
  paste("Latest detailed production assessment identified by the 2025 Plenary.",
    "The model data period extends through model year 2024 (2023/24 fishing year).",
    "Source records preserve the model catch history, one recent commercial age composition,",
    "age-specific survey abundance, selected biology observations, CPUE, and Table 10 outputs.",
    "Older fitted composition vectors, BPT CPUE observations, tagging indices, recreational",
    "length compositions, and annual numerical population surfaces remain unimported.")
)

assumptions <- list(
  make_assumption("mortality", "natural_mortality", "0.075 per year; fixed",
    "FAR 2024/49, Table 6, p. 39.",
    "Base Case natural mortality."),
  make_assumption("growth", "von_bertalanffy_growth",
    "Fixed; L1 13.1 cm; 1931-1979 k=0.146, Linf=54.5 cm; 1980-2005 k=0.112, Linf=69.6 cm; 2006-2024 k=0.150, Linf=54.4 cm",
    "FAR 2024/49, Table 6, p. 39.",
    "Three time-block growth parameterization."),
  make_assumption("growth", "cv_length_at_age", "0.08; fixed",
    "FAR 2024/49, Table 6, p. 39.",
    "Fixed coefficient of variation in length-at-age."),
  make_assumption("weight", "length_weight_relationship",
    "W = 4.467e-5 * length^2.793; fixed",
    "FAR 2024/49, Table 6, p. 39.",
    "Length in cm and weight in kg; do not substitute empirical 2022-23 sampled weights-at-age for this relationship."),
  make_assumption("maturity", "maturity_at_length",
    "Fixed logistic ogive; L50=35 cm, L5=26 cm, L95=44 cm",
    "FAR 2024/49, pp. 38-39 and Table 6, p. 39.",
    "Female maturity from WCNI survey gonad staging; an age-based vector is not tabulated."),
  make_assumption("recruitment", "stock_recruitment_relationship",
    "Beverton-Holt; steepness h=0.95 fixed",
    "FAR 2024/49, Table 6, p. 39.",
    "The 0.85 option is a sensitivity."),
  make_assumption("recruitment", "recruitment_sigma", "sigmaR=0.6; fixed",
    "FAR 2024/49, Table 6, p. 39.",
    "Applies to simple recruitment deviations."),
  make_assumption("recruitment", "recruitment_deviations",
    "Simple deviations estimated for initialization years 1950-1974 and main years 1975-2021; no averaging constraint",
    "FAR 2024/49, Table 6, p. 39 and Section 4.2, pp. 39-40.",
    "The report's parameter summary lists 47 main deviations, while its year labels are not entirely self-consistent; retain the reported periods pending source-file verification."),
  make_assumption("model", "age_structure",
    "30 age classes, sexes combined; age 30 is the 30+ plus group",
    "FAR 2024/49, Section 4.2, p. 39.",
    "Assessment initialized in 1975 under exploited conditions."),
  make_assumption("model", "annual_seasons",
    "Annual 1 October-30 September year; season 1 October-January; season 2 February-September",
    "FAR 2024/49, Section 4.2, p. 40.",
    "The annual time step is partitioned into two seasons."),
  make_assumption("timing", "spawning_and_recruitment_timing",
    "Spawning occurs instantaneously at start of year; recruitment is a function of spawning biomass at start of year",
    "FAR 2024/49, Section 4.2, p. 40.",
    "No fractional-year adjustment applied."),
  make_assumption("timing", "catch_timing",
    "Annual catches taken instantaneously halfway through season 1",
    "FAR 2024/49, Section 4.2, p. 42.",
    "Consistent with the main commercial catch period."),
  make_assumption("index", "CPUE_likelihood",
    "BT and BPT CPUE indices use lognormal errors; BT additional process error 0.1; BPT additional process error 0.2",
    "FAR 2024/49, Table 7, p. 42 and Section 4.2, p. 43.",
    "Table 7 reports CV ranges of 0.12-0.18 for BT and 0.12-0.30 for BPT."),
  make_assumption("index", "age_specific_survey_likelihood",
    "Native survey CVs; no additional process error",
    "FAR 2024/49, Table 7, p. 42 and Section 4.2, p. 43.",
    "Numerical age-specific CV values are not tabulated in the assessment report."),
  make_assumption("composition", "age_composition_likelihood",
    "Multinomial; relative ESS 6-35 for BT and 10-36 for BPT",
    "FAR 2024/49, Table 7, p. 42.",
    "Source sample CVs and raw sample-size fields are separate from the assessment ESS."),
  make_assumption("observation", "ageing_error",
    "No age-determination error included",
    "FAR 2024/49, Section 4.2, p. 41.",
    "All age compositions were assumed to have no age-determination error."),
  make_assumption("timing", "survey_timing",
    "Kaharoa WCNI surveys occur in November; fractional model-year timing not stated",
    "FAR 2024/49, pp. 31-33.",
    "The 2022 calendar-year survey is mapped to model year 2023.")
)
new_assumptions <- do.call(rbind, assumptions)

output_rows <- list()
add_output <- function(type, measure, value, unit, lwr = "", upr = "",
  year = 2024L, notes, scenario = "Base_Frec") {
  out <- make_record(output_header, 1L)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(year)
  out$scenario <- scenario
  out$value <- as.character(value)
  out$lwr <- as.character(lwr)
  out$upr <- as.character(upr)
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- "FAR 2024/49, Table 10, p. 65."
  out$notes <- notes
  output_rows[[length(output_rows) + 1L]] <<- out
}
add_output("biomass", "spawning_biomass", 49830, "tonnes",
  39807, 62665, notes = "2023-24 Base_Frec spawning biomass; value is the MCMC median and limits are the reported 95% interval.")
add_output("mortality", "fishing_mortality_ratio_to_target", 0.999, "ratio",
  0.814, 1.204, notes = "F2024/FSB40%; value is the MCMC median and limits are the reported 95% interval.")
add_output("mortality", "probability_fishing_mortality_below_target", 0.508, "probability",
  notes = "Source-reported probability that F2024 is below FSB40%.")
add_output("biomass", "yield_at_FSB40", 3667, "tonnes",
  3043, 4444, notes = "Yield at FSB40% based on the 2023-24 biomass; value and 95% MCMC interval.")
add_output("biomass", "vulnerable_biomass", 63989, "tonnes",
  notes = "MPD estimate of vulnerable biomass for Base_Frec; no interval is reported in Table 10.")
new_outputs <- do.call(rbind, output_rows)

for (table in c("assumptions", "inputs", "outputs")) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  classes <- rep("NULL", length(header))
  names(classes) <- header
  classes[["assessment_id"]] <- "character"
  existing <- read.csv(path, colClasses = classes, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(existing$assessment_id == assessment_id, na.rm = TRUE)) {
    stop(assessment_id, " already appears in ", path, ".", call. = FALSE)
  }
}
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id) {
  stop("The SNA 8 canonical record already exists; inspect before reimporting.", call. = FALSE)
}
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_index <- which(candidates$candidate_id == candidate_id)
if (length(candidate_index) != 1L ||
  !identical(candidates$import_status[candidate_index], "not_started")) {
  stop("Expected one not-started SNA 8 candidate row before importing.", call. = FALSE)
}

records <- list(
  stocks = stock_row,
  assessments = assessment_row,
  assumptions = new_assumptions,
  inputs = new_inputs,
  outputs = new_outputs
)
for (table in names(records)) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  if (!identical(names(records[[table]]), header)) {
    stop("Column mismatch for ", path, ".", call. = FALSE)
  }
}

cat("SNA 8 source import prepared: 1 stock, 1 assessment, ",
  nrow(new_assumptions), " assumptions, ", nrow(new_inputs), " inputs, ",
  nrow(new_outputs), " outputs.\n", sep = "")
cat("Inputs preserve 1931-2024 model catch history, combined BT CPUE, 2022-23 BT age proportions, age-specific survey numbers, and empirical sample weights.\n")
cat("Import remains partial: older fitted age compositions, BPT CPUE, tag indices, recreational length compositions, numerical survey CVs, and annual population outputs remain unresolved.\n")

if (!write_mode) {
  cat("Dry run only. Re-run with --write to append the source records.\n")
} else {
  append_rows <- function(path, rows) {
    header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
      check.names = FALSE))
    if (!identical(names(rows), header)) {
      stop("Column mismatch for ", path, ".", call. = FALSE)
    }
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
  candidates$catch_age_evidence[candidate_index] <- "FAR 2024/49 Table A3 model catch histories are imported by fleet for 1931-2024; observed north BT 2022-23 proportions-at-age and bootstrap CVs are imported separately. No catch numbers-at-age are reconstructed."
  candidates$survey_age_evidence[candidate_index] <- "FAR 2024/49 Table 5 values are imported for model ages 2-5 across nine survey years; numerical CVs are not tabulated. The report also has a fitted age-specific survey likelihood."
  candidates$weights_evidence[candidate_index] <- "Empirical north BT sampled-landings mean weight-at-age and CVs for 2022-23 are imported from FAR 2024/50 Appendix 8; they are distinct from the assessment's fixed length-weight and growth relationships."
  candidates$output_evidence[candidate_index] <- "FAR 2024/49 Table 10 Base_Frec outputs are imported for 2023-24 SSB and F/FSB40, plus probability, target yield, and vulnerable biomass. Annual population trajectories are figures, not full numerical tables."
  candidates$decision_reason[candidate_index] <- "Partial source import completed from the latest detailed assessment and companion age-composition report. Canonical data preserve model catch histories, CPUE, survey abundance, age proportions, empirical sampled weights, assumptions, and current summary outputs; several fitted likelihood series and annual population outputs remain unimported."
  candidates$notes[candidate_index] <- "SNA 8 is one stock unit; north/south and gear-specific rows are observation dimensions. Catch proportions remain distinct from catch numbers-at-age. The 2024 model uses the full QMA catch history while most observational data are from north of Cape Egmont."
  candidate_path <- "discovery/candidates.csv"
  candidate_lines <- readLines(candidate_path, warn = FALSE, encoding = "UTF-8")
  candidate_row <- capture.output(write.table(
    candidates[candidate_index, , drop = FALSE], file = "", sep = ",",
    row.names = FALSE, col.names = FALSE, na = "", quote = TRUE,
    qmethod = "double"
  ))
  candidate_line <- which(startsWith(candidate_lines, paste0('"', candidate_id, '",')))
  if (length(candidate_line) != 1L || length(candidate_row) != 1L) {
    stop("Could not safely update the SNA 8 candidate row.", call. = FALSE)
  }
  candidate_lines[candidate_line] <- candidate_row
  writeLines(candidate_lines, candidate_path, useBytes = TRUE)
  cat("SNA 8 source records appended; candidate import status is partial.\n")
}
