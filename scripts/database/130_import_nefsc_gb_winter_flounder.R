root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ck_nefsc_americanus_5z")
input_file <- file.path(cache, "2022_FLW_GB", "2022_WFL_GB_VPA.dat")

assessment_2022 <- "nefsc_winter_flounder_gb_2022_vpa"
assessment_2025 <- "nefsc_winter_flounder_gb_2025_wham"
stock_id <- "ck_nefsc_americanus_5z"
report_2022_url <- "https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf"
report_2025_url <- "https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10433"
bundle_2022_url <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=10&stock_id=1&review_type_id=2&filename=2022_FLW_GB.zip"
bundle_2025_url <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=10&stock_id=1&review_type_id=3&filename=2025_FLW_GB.zip"

if (!file.exists(input_file)) {
  stop("The cached 2022 VPA input file is missing: ", input_file, call. = FALSE)
}

read_table <- function(name) {
  read.csv(file.path(database, name),
    stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE
  )
}

stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
assumptions_existing <- read_table("assumptions.csv")
inputs_existing <- read_table("inputs.csv")
outputs_existing <- read_table("outputs.csv")
ids <- c(assessment_2022, assessment_2025)
for (table in list(assessments, assumptions_existing, inputs_existing, outputs_existing)) {
  if (any(table$assessment_id %in% ids, na.rm = TRUE)) {
    stop("Winter flounder assessment rows already exist; inspect before re-importing.", call. = FALSE)
  }
}
if (!stock_id %in% stocks$stock_id) stop("The Charbonneau-Keith stock record is missing.", call. = FALSE)

lines <- readLines(input_file, warn = FALSE)
param_line <- match("PARAM", lines) + 1L
param <- scan(text = lines[[param_line]], what = numeric(), quiet = TRUE)
if (length(param) < 6L) stop("Could not read VPA dimensions and first year.", call. = FALSE)
n_years <- as.integer(param[[1L]])
n_ages <- as.integer(param[[2L]])
n_index_streams <- as.integer(param[[3L]])
years <- seq.int(as.integer(param[[6L]]), length.out = n_years)
ages <- seq_len(n_ages)
if (n_years != 40L || n_ages != 7L || years[[1L]] != 1982L ||
  tail(years, 1L) != 2021L) {
  stop("The cached VPA file dimensions do not match the reviewed 1982-2021, ages 1-7 run.", call. = FALSE)
}

parse_numbers <- function(line) scan(text = line, what = numeric(), quiet = TRUE)
read_matrix <- function(label, columns = n_ages) {
  i <- match(label, lines)
  if (is.na(i)) stop("Missing VPA section: ", label, call. = FALSE)
  rows <- lapply(lines[seq.int(i + 1L, length.out = n_years)], parse_numbers)
  if (any(lengths(rows) != columns)) {
    stop("Unexpected row width in VPA section: ", label, call. = FALSE)
  }
  out <- do.call(rbind, rows)
  if (!all(dim(out) == c(n_years, columns)) || any(!is.finite(out))) {
    stop("Invalid values in VPA section: ", label, call. = FALSE)
  }
  out
}

catch_numbers <- read_matrix("CATCH AT AGE")
catch_weight <- read_matrix("WEIGHT AT AGE")
stock_weight <- read_matrix("BIOMASS")
ssb_weight <- read_matrix("SSB")
mortality <- read_matrix("M MATRIX")
maturity <- read_matrix("MATURITY")
if (!isTRUE(all.equal(stock_weight, ssb_weight, tolerance = 0))) {
  stop("The VPA BIOMASS and SSB weight surfaces differ; review before import.", call. = FALSE)
}
if (any(mortality != mortality[1L, 1L]) || mortality[1L, 1L] != 0.3) {
  stop("The VPA M matrix is not the reviewed constant 0.3 schedule.", call. = FALSE)
}
if (any(maturity < 0 | maturity > 1)) stop("Maturity values are outside [0, 1].", call. = FALSE)

index_section <- match("SURVEY INDEX", lines)
if (is.na(index_section)) stop("Missing VPA SURVEY INDEX section.", call. = FALSE)
index_stream <- strsplit(trimws(lines[[index_section + 1L]]), "[[:space:]]+")[[1L]]
index_age <- as.integer(strsplit(trimws(lines[[index_section + 2L]]), "[[:space:]]+")[[1L]])
index_time <- strsplit(trimws(lines[[index_section + 3L]]), "[[:space:]]+")[[1L]]
index_type <- strsplit(trimws(lines[[index_section + 4L]]), "[[:space:]]+")[[1L]]
index_rows <- lapply(
  lines[seq.int(index_section + 5L, length.out = n_years)],
  parse_numbers
)
index_values <- do.call(rbind, index_rows)
if (length(index_stream) != n_index_streams ||
  length(index_age) != n_index_streams ||
  length(index_time) != n_index_streams ||
  length(index_type) != n_index_streams ||
  any(lengths(index_rows) != n_index_streams) ||
  any(index_time != "1-JAN") || any(index_type != "NUMBER") ||
  any(!is.finite(index_values)) || any(index_values < 0)) {
  stop("The native survey index block has unexpected metadata or values.", call. = FALSE)
}

make_input <- function(assessment_id, type, measure, basis, fleet = "",
    survey = "", season = "", year, year_basis = "calendar_year", age,
    value, unit, sampling_time = NA_real_, source_type, source_reference,
    transformation = "", notes = "", observation_id = "") {
  n <- length(value)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep(type, n),
    measure = rep(measure, n), basis = rep(basis, n),
    fleet = rep(fleet, n), survey = rep(survey, n), sex = rep("", n),
    region = rep("Georges Bank", n), season = rep(season, n),
    year = rep_len(year, n), year_basis = rep_len(year_basis, n),
    age = rep_len(age, n), value = as.numeric(value), unit = rep(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = rep(source_type, n),
    source_reference = rep(source_reference, n),
    transformation = rep(transformation, n), notes = rep(notes, n),
    observation_id = rep(observation_id, n), length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE
  )
}

matrix_inputs <- function(aid, type, measure, basis, fleet, values, unit,
    reference, source_type = "native_model", transformation = "",
    notes = "") {
  grid <- expand.grid(year = years, age = ages)
  grid$value <- as.vector(t(values))
  make_input(
    aid, type, measure, basis, fleet = fleet, year = grid$year,
    age = grid$age, value = grid$value, unit = unit,
    source_type = source_type, source_reference = reference,
    transformation = transformation, notes = notes
  )
}

input_rows <- list(
  matrix_inputs(
    assessment_2022, "catch", "numbers_at_age", "numbers",
    "Combined VPA catch", catch_numbers, "thousand fish",
    "2022_WFL_GB_VPA.dat, CATCH AT AGE",
    notes = "Native VPA input values for ages 1-6 and the age-7 plus group, 1982-2021."
  ),
  matrix_inputs(
    assessment_2022, "catch_weight", "weight_at_age", "kg_per_fish",
    "Combined VPA catch", catch_weight, "kg per fish",
    "2022_WFL_GB_VPA.dat, WEIGHT AT AGE",
    transformation = "The native file omits a unit label; values are interpreted as kg per fish based on scale and reconciliation with the report's catch totals. Values are retained unchanged.",
    notes = "Catch weights are distinct from the population stock-weight surface."
  ),
  matrix_inputs(
    assessment_2022, "weight", "weight_at_age", "kg_per_fish",
    "", stock_weight, "kg per fish",
    "2022_WFL_GB_VPA.dat, BIOMASS",
    transformation = "The native file omits a unit label; values are interpreted as kg per fish. The BIOMASS and SSB sections are numerically identical, so the same surface is stored once.",
    notes = "Annual population weight-at-age surface. The age-7 row is the source plus group."
  ),
  matrix_inputs(
    assessment_2022, "maturity", "maturity_at_age", "proportion",
    "", maturity, "proportion mature",
    "2022_WFL_GB_VPA.dat, MATURITY",
    notes = "Annual maturity-at-age surface for ages 1-6 and age 7 plus."
  )
)

for (stream in seq_len(n_index_streams)) {
  code <- index_stream[[stream]]
  season <- if (grepl("Sp$", code)) "spring" else "fall"
  survey <- if (code == "US_Sp") {
    "NEFSC spring"
  } else if (code == "Can_Sp") {
    "DFO spring"
  } else {
    "NEFSC fall"
  }
  input_rows[[length(input_rows) + 1L]] <- make_input(
    assessment_2022, "index", "numbers_at_age", "index_scale",
    survey = survey, season = season, year = years,
    age = rep(index_age[[stream]], n_years),
    value = index_values[, stream],
    unit = "native survey index units",
    sampling_time = 0,
    source_type = "native_model",
    source_reference = paste0("2022_WFL_GB_VPA.dat, SURVEY INDEX, native stream ", code),
    notes = paste(
      "Native VPA input series; the file labels its timing 1-JAN and its basis NUMBER.",
      "Survey scale multiplier is not stated. Explicit zero cells are retained because",
      "the native file does not distinguish true zero values from missing values."
    ),
    observation_id = code
  )
}

input_rows[[length(input_rows) + 1L]] <- make_input(
  assessment_2022, "M", "natural_mortality_at_age", "per_year",
  year = rep(NA_real_, n_ages), year_basis = "", age = ages,
  value = mortality[1L, ], unit = "per year",
  source_type = "native_model",
  source_reference = "2022_WFL_GB_VPA.dat, M MATRIX",
  notes = "The source matrix is 0.3 for every age and year; stored once as a static age schedule."
)

years_2022_table <- 2012:2021
catch_2022_table <- c(2199, 1761, 1219, 940, 492, 400, 488, 329, 397, 283)
input_rows[[length(input_rows) + 1L]] <- make_input(
  assessment_2022, "catch", "total_biomass", "biomass",
  fleet = "Reported assessment catch", year = years_2022_table,
  age = NA_real_, value = catch_2022_table, unit = "metric tons",
  source_type = "official_table",
  source_reference = "2022 Management Track Assessment, Table 1, pp. 1-2",
  notes = "Published total catch for assessment."
)

years_2025_table <- 2015:2024
catch_2025 <- c(940, 492, 400, 488, 328, 374, 288, 249, 336, 756)
input_rows[[length(input_rows) + 1L]] <- make_input(
  assessment_2025, "catch", "total_biomass", "biomass",
  fleet = "Reported assessment catch", year = years_2025_table,
  age = NA_real_, value = catch_2025, unit = "metric tons",
  source_type = "official_table",
  source_reference = "2025 Management Track Assessment, Table 1, p. 1",
  notes = "Published catch for the 2025 WHAM run; aggregate only, with no age composition recovered. Kept separate from the 2022 VPA run."
)

make_assumption <- function(aid, component, setting, value, reference, notes = "") {
  data.frame(
    assessment_id = aid, component = component, fleet = "", survey = "",
    sex = "", region = "Georges Bank", season = "", setting = setting,
    value = value, source_reference = reference, notes = notes,
    stringsAsFactors = FALSE
  )
}

assumption_rows <- list(
  make_assumption(assessment_2022, "assessment", "model_run", "RunSpring22; VPA/ADAPT 3.1",
    "2022_WFL_GB_VPA.pdf, p. 1; 2022_WFL_GB_VPA.dat, MODEL ID",
    "Native file identifies model ID 2022MTassessmet; diagnostics identify RunSpring22."),
  make_assumption(assessment_2022, "population", "modeled_years", "1982-2021",
    "2022_WFL_GB_VPA.dat, PARAM; 2022 VPA diagnostics, p. 1"),
  make_assumption(assessment_2022, "population", "model_ages", "Ages 1-6 and 7+",
    "2022 VPA diagnostics, p. 1",
    "The native input dimension is seven ages; the report describes the terminal age as the plus group."),
  make_assumption(assessment_2022, "recruitment", "reported_age", "Age 1",
    "2022 Management Track Assessment, Table 1, p. 2"),
  make_assumption(assessment_2022, "M", "treatment", "Fixed at 0.3 per year for all ages and years",
    "2022_WFL_GB_VPA.dat, M MATRIX; 2022 Management Track Assessment, p. 3",
    "The report says M is based on longevity (maximum age 20); the exact estimation process is not reproduced."),
  make_assumption(assessment_2022, "F", "reported_full_F_ages", "4-6",
    "2022 Management Track Assessment, Table 1, p. 1"),
  make_assumption(assessment_2022, "F", "partial_recruitment_vector", "0.01 0.08 0.55 1 1 1",
    "2022_WFL_GB_VPA.dat, PARTIAL RECRUIT",
    "Raw VPA control vector preserved; mapping of the six values to all seven age groups is not resolved."),
  make_assumption(assessment_2022, "F", "F_plus", "1.00000*40",
    "2022_WFL_GB_VPA.dat, F-PLUS",
    "Native control expression preserved without further interpretation."),
  make_assumption(assessment_2022, "F", "F_ages", "4-6",
    "2022_WFL_GB_VPA.dat, AGES-F"),
  make_assumption(assessment_2022, "survey", "survey_streams",
    "NEFSC spring (US_Sp), DFO spring (Can_Sp), NEFSC fall (US_A0 through US_A6)",
    "2022_WFL_GB_VPA.dat, SURVEY INDEX",
    "The seven fall native codes are retained in observation_id; the report notes that terminal-year survey availability is incomplete."),
  make_assumption(assessment_2022, "survey", "survey_weight_factors", "1.0 for all 21 streams and all years",
    "2022_WFL_GB_VPA.dat, SURVEY FACTORS",
    "The source file contains only unit weights."),
  make_assumption(assessment_2022, "spawning", "MFSPAWN", "0.25 0.25",
    "2022_WFL_GB_VPA.dat, MFSPAWN",
    "Both native values are preserved; their precise meanings are not resolved from the released data file."),
  make_assumption(assessment_2022, "assessment", "retrospective_adjustment",
    "SSB rho=0.59; F rho=-0.36; 2021 stock-status estimates adjusted to SSB=4,503 mt and FFull=0.076",
    "2022 Management Track Assessment, pp. 1-2",
    "Table 1 outputs remain the unadjusted terminal estimates; adjusted values are not mixed into the annual trajectory."),
  make_assumption(assessment_2022, "recruitment", "reference_point", "Median age-1 recruitment = 8,759 thousand fish",
    "2022 Management Track Assessment, Table 2, p. 2"),
  make_assumption(assessment_2025, "recruitment", "reference_point", "Mean age-1 recruitment = 6,365 thousand fish",
    "2025 Management Track Assessment, Table 2, p. 1"),
  make_assumption(assessment_2022, "projection", "2022_assumed_catch", "278 metric tons",
    "2022 Management Track Assessment, Table 3, p. 2",
    "Projection assumption, not observed catch."),
  make_assumption(assessment_2022, "projection", "harvest_scenario", "Fishing at FMSY from 2023 through 2025",
    "2022 Management Track Assessment, Table 3, p. 2")
)

assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  assessment_2025, "assessment", "model_family", "WHAM",
  "2025 Management Track Assessment, pp. 1-2",
  "Peer review concluded that the 2025 assessment met the terms of reference and represented the best scientific information available for this stock."
)
assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  assessment_2025, "population", "modeled_years", "through 2024",
  "2025 Management Track Assessment, Table 1, p. 1",
  "Exact start year and age grid were not stated in the recovered summary tables."
)
assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  assessment_2025, "F", "reported_full_F_ages", "4-7",
  "2025 Management Track Assessment, Table 1, p. 1"
)
assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  assessment_2025, "M", "treatment", "Based on longevity (maximum age 20); constant over time; numerical setting not tabulated",
  "2025 Management Track Assessment, p. 3"
)
assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  assessment_2025, "projection", "2025_assumed_catch", "565 metric tons",
  "2025 Management Track Assessment, Table 3, p. 2",
  "Projection assumption supplied by the Groundfish Plan Development Team."
)

make_output <- function(aid, type, measure, value, year = NA_real_,
    age = NA_real_, age_group = "", unit, lwr = NA_real_, upr = NA_real_,
    notes, reference, source_type = "official_table") {
  n <- length(value)
  data.frame(
    assessment_id = rep(aid, n), type = rep(type, n), measure = rep(measure, n),
    fleet = "", survey = "", sex = "", region = "Georges Bank", season = "",
    year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = as.numeric(value),
    se = NA_real_, lwr = rep_len(lwr, n), upr = rep_len(upr, n),
    unit = rep(unit, n), source_type = rep(source_type, n),
    source_reference = rep(reference, n), notes = rep(notes, n),
    stringsAsFactors = FALSE
  )
}

output_rows <- list(
  make_output(assessment_2022, "biomass", "SSB",
    c(4289, 3477, 3229, 3162, 2736, 2385, 2515, 3326, 4079, 7159),
    years_2022_table, unit = "metric tons",
    notes = "Unadjusted historical estimate; no numerical interval is reported in Table 1.",
    reference = "2022 Management Track Assessment, Table 1, p. 2"),
  make_output(assessment_2022, "mortality", "Fbar",
    c(.5404, .5693, .4899, .2499, .2015, .1526, .2310, .1412, .0917, .0485),
    years_2022_table, age_group = "4-6", unit = "per year",
    notes = "Reported fully selected fishing mortality over ages 4-6; unadjusted annual trajectory.",
    reference = "2022 Management Track Assessment, Table 1, p. 2"),
  make_output(assessment_2022, "recruitment", "recruitment",
    c(3366, 2409, 2863, 1322, 3034, 3495, 5617, 4940, 10740, 8920),
    years_2022_table, age = 1, unit = "thousand fish",
    notes = "Age-1 recruitment; no numerical interval is reported in Table 1.",
    reference = "2022 Management Track Assessment, Table 1, p. 2"),
  make_output(assessment_2022, "mortality", "Fmsy", .452,
    unit = "per year", notes = "F40% proxy.",
    reference = "2022 Management Track Assessment, Table 2, p. 2"),
  make_output(assessment_2022, "biomass", "Bmsy", 7503,
    unit = "metric tons", lwr = 4790, upr = 10705,
    notes = "Reported reference point interval; the table does not state its confidence level.",
    reference = "2022 Management Track Assessment, Table 2, p. 2"),
  make_output(assessment_2022, "catch", "msy", 2757,
    unit = "metric tons per year", lwr = 1811, upr = 3918,
    notes = "Reported reference point interval; the table does not state its confidence level.",
    reference = "2022 Management Track Assessment, Table 2, p. 2"),
  make_output(assessment_2025, "biomass", "SSB",
    c(2702, 2280, 1995, 2057, 2196, 2668, 3216, 4009, 4654, 5477),
    years_2025_table, unit = "metric tons",
    notes = "2025 WHAM historical estimates; the report does not tabulate annual uncertainty intervals.",
    reference = "2025 Management Track Assessment, Table 1, p. 1"),
  make_output(assessment_2025, "mortality", "Fbar",
    c(.336, .245, .214, .279, .177, .156, .097, .072, .094, .177),
    years_2025_table, age_group = "4-7", unit = "per year",
    notes = "Reported fully selected fishing mortality over ages 4-7.",
    reference = "2025 Management Track Assessment, Table 1, p. 1"),
  make_output(assessment_2025, "recruitment", "recruitment",
    c(923, 1703, 2372, 3330, 4128, 3365, 4744, 8045, 7265, 5229),
    years_2025_table, age = 1, unit = "thousand fish",
    notes = "Age-1 recruitment from the 2025 WHAM run.",
    reference = "2025 Management Track Assessment, Table 1, p. 1"),
  make_output(assessment_2025, "mortality", "Fmsy", .431,
    unit = "per year", notes = "FMSY proxy.",
    reference = "2025 Management Track Assessment, Table 2, p. 1"),
  make_output(assessment_2025, "biomass", "Bmsy", 5182,
    unit = "metric tons", lwr = 4179, upr = 6426,
    notes = "Reported reference point interval; the table does not state its confidence level.",
    reference = "2025 Management Track Assessment, Table 2, p. 1"),
  make_output(assessment_2025, "catch", "msy", 1808,
    unit = "metric tons per year", lwr = 1455, upr = 2247,
    notes = "Reported reference point interval; the table does not state its confidence level.",
    reference = "2025 Management Track Assessment, Table 2, p. 1")
)

projection_years_2022 <- 2022:2025
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2022, "biomass", "SSB",
  c(5755, 6322, 4738, 5236), projection_years_2022,
  unit = "metric tons", lwr = c(4427, 4651, 3053, 3467),
  upr = c(7455, 8890, 5247, 7957),
  notes = "Projection estimates with reported 90% intervals; the first year uses the assumed 278 t catch.",
  reference = "2022 Management Track Assessment, Table 3, p. 2"
)
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2022, "mortality", "Fbar",
  c(.058, .452, .452, .452), projection_years_2022,
  age_group = "4-6", unit = "per year",
  notes = "Projected fully selected F over ages 4-6.",
  reference = "2022 Management Track Assessment, Table 3, p. 2"
)
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2022, "catch", "total_biomass",
  c(278, 2360, 1963, 1819), projection_years_2022,
  unit = "metric tons", notes = "Projection catch; 2022 catch was assumed as 278 t.",
  reference = "2022 Management Track Assessment, Table 3, p. 2"
)

projection_years_2025 <- 2025:2028
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2025, "biomass", "SSB",
  c(6164, 6388, 5701, 5343), projection_years_2025,
  unit = "metric tons", lwr = c(4127, 3853, 3082, 2576),
  upr = c(9205, 10593, 10548, 11084),
  notes = "WHAM projection estimates with the intervals reported in Table 3; confidence level is not stated in the table.",
  reference = "2025 Management Track Assessment, Table 3, p. 2"
)
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2025, "mortality", "Fbar",
  c(.102, .431, .431, .431), projection_years_2025,
  age_group = "4-7", unit = "per year",
  notes = "Projected fully selected F over ages 4-7.",
  reference = "2025 Management Track Assessment, Table 3, p. 2"
)
output_rows[[length(output_rows) + 1L]] <- make_output(
  assessment_2025, "catch", "total_biomass",
  c(565, 2278, 2002, 1864), projection_years_2025,
  unit = "metric tons", notes = "Projection catch; 2025 catch was assumed as 565 t.",
  reference = "2025 Management Track Assessment, Table 3, p. 2"
)

assessment_rows <- data.frame(
  assessment_id = c(assessment_2022, assessment_2025),
  stock_id = stock_id, assessment_year = c(2022L, 2025L),
  terminal_year = c(2021L, 2024L),
  estimate_terminal_year = c(2025L, 2028L),
  assessment_type = "management_track_update",
  model_family = c("VPA/ADAPT", "WHAM"),
  model_version = c("VPA 3.1 RunSpring22", "2025 Management Track WHAM"),
  is_current = c(TRUE, FALSE), is_applied = TRUE,
  framework_year = c(2020L, 2024L),
  assessment_url = c(report_2022_url, report_2025_url),
  framework_url = c("", ""),
  data_url = c(bundle_2022_url, bundle_2025_url),
  model_url = c(bundle_2022_url, ""),
  repository_url = c("", ""),
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = c(
    paste(
      "Latest official run with recoverable full input matrices is the 2022 VPA through 2021.",
      "The native data file is complete as released for catch, biology, M, and survey index matrices;",
      "underlying source gaps and control-file interpretation remain unresolved. Numerical N- and",
      "F-at-age outputs and age-specific uncertainty were not recovered, so outputs are partial."
    ),
    paste(
      "The 2025 Management Track assessment was accepted as the best scientific information available",
      "for this stock, but only summary tables were recovered. The 2025 WHAM run is recorded separately;",
      "its aggregate catch series and reported outputs are not combined with the 2022 VPA inputs."
    )
  ),
  stringsAsFactors = FALSE
)

new_inputs <- do.call(rbind, input_rows)
new_assumptions <- do.call(rbind, assumption_rows)
new_outputs <- do.call(rbind, output_rows)
if (anyDuplicated(new_inputs[c("assessment_id", "type", "measure", "fleet", "survey", "year", "age", "observation_id")])) {
  stop("Duplicate source input keys were generated.", call. = FALSE)
}
if (anyDuplicated(new_outputs[c("assessment_id", "type", "measure", "year", "age", "age_group")])) {
  stop("Duplicate source output keys were generated.", call. = FALSE)
}

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
stock$common_name <- "Winter flounder"
stock$authority_stock_id <- "GBWF"
stock$area <- "Georges Bank (NAFO 5Z)"
stock$region <- "Georges Bank"
stock$notes <- paste(
  stock$notes,
  "2022 and 2025 NOAA-NEFSC Georges Bank winter flounder assessment records added;",
  "Charbonneau-Keith identifier retained."
)
stocks[stocks$stock_id == stock_id, ] <- stock

write.csv(stocks, file.path(database, "stocks.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.table(assessment_rows, file.path(database, "assessments.csv"),
  sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = "", fileEncoding = "UTF-8"
)
write.table(new_assumptions, file.path(database, "assumptions.csv"),
  sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = "", fileEncoding = "UTF-8"
)
write.table(new_inputs, file.path(database, "inputs.csv"),
  sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = "", fileEncoding = "UTF-8"
)
write.table(new_outputs, file.path(database, "outputs.csv"),
  sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = "", fileEncoding = "UTF-8"
)
