assessment_id <- "nefsc_haddock_gulf_of_maine_2026"
stock_id <- "ck_nefsc_garmiii_aeglefinus_5y"
database <- "database"
peer_review_url <- "https://www.fisheries.noaa.gov/s3/fileserve?filepath=2026-10/september-2026-management-track-peer-review-panel-report_20261007.pdf"
bundle_url <- "https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=2&review_type_id=6&filename=2026_HAD_GOM.zip"
sar_url <- bundle_url
source_reference <- paste(sar_url, "Gulf_of_Maine_Haddock_SAR_2026.pdf, Table 1, p. 7", sep = "; ")
output_reference <- paste(sar_url, "Gulf_of_Maine_Haddock_SAR_2026.pdf, Tables 2-4, pp. 7-8", sep = "; ")
review_reference <- peer_review_url

years <- 2015:2025
catch_t <- c(1512, 3406, 4894, 3710, 4542, 4810, 4618, 3353, 2734, 2288, 1741)
ssb_t <- c(52538, 73129, 71833, 89867, 69187, 42659, 19673, 22117, 14586, 16701, 11339)
f_full <- c(.046, .070, .095, .052, .072, .130, .280, .190, .274, .213, .223)
recruitment_000 <- c(9613, 10899, 11922, 7369, 4972, 6153, 23209, 22106, 2537, 1022, 1704)

if (!all(lengths(list(catch_t, ssb_t, f_full, recruitment_000)) == length(years))) {
  stop("The 2026 SAR table values do not match the year sequence.", call. = FALSE)
}

assessments_path <- file.path(database, "assessments.csv")
inputs_path <- file.path(database, "inputs.csv")
assumptions_path <- file.path(database, "assumptions.csv")
outputs_path <- file.path(database, "outputs.csv")

read_database_csv <- function(path) {
  read.csv(path, na.strings = "", stringsAsFactors = FALSE, check.names = FALSE)
}

new_paths <- c(assessments_path, inputs_path, assumptions_path, outputs_path)
for (path in new_paths) {
  existing <- read.csv(path, colClasses = "character", na.strings = "",
    check.names = FALSE)
  if (any(existing$assessment_id == assessment_id, na.rm = TRUE)) {
    stop(paste(assessment_id, "already has records in", basename(path),
      "and will not be duplicated."), call. = FALSE)
  }
}

append_new_rows <- function(path, new_rows) {
  write.table(new_rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", fileEncoding = "UTF-8")
}

stocks <- read_database_csv(file.path(database, "stocks.csv"))
if (!stock_id %in% stocks$stock_id) {
  stop("The Gulf of Maine haddock metadata record is missing.", call. = FALSE)
}

assessment <- data.frame(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2026L,
  terminal_year = 2025L,
  estimate_terminal_year = 2031L,
  assessment_type = "management_track_update",
  model_family = "WHAM",
  model_version = "2026 Management Track candidate model",
  is_current = FALSE,
  is_applied = TRUE,
  framework_year = 2022L,
  assessment_url = peer_review_url,
  framework_url = "",
  data_url = bundle_url,
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "The September 2026 peer-review panel found it technically sufficient for status evaluation and catch advice. Numerical recent total catch",
    "and aggregate model summaries are available, but numerical age compositions,",
    "survey series, biological surfaces, and fitted N/F-at-age outputs were not found."
  ),
  stringsAsFactors = FALSE
)

inputs <- data.frame(
  assessment_id = assessment_id,
  type = "catch",
  measure = "total_biomass",
  basis = "biomass",
  fleet = "Fishery",
  survey = "",
  sex = "",
  region = "Gulf of Maine",
  season = "",
  year = years,
  year_basis = "calendar_year",
  age = NA_integer_,
  value = catch_t,
  unit = "t",
  sampling_time = NA_real_,
  source_type = "official_table",
  source_reference = source_reference,
  transformation = "",
  notes = paste(
    "Reported total catch for the assessment. The source table sums recreational",
    "discards and landings, commercial discards and landings, and foreign landings.",
    "The accepted model represents commercial and recreational removals as one fleet."
  ),
  observation_id = "",
  length_bin = NA_real_,
  length_bin_lower = NA_real_,
  length_bin_upper = NA_real_,
  sample_size = NA_real_,
  age_error = "",
  partition = "",
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, notes = "") {
  data.frame(
    assessment_id = assessment_id,
    component = component,
    fleet = "",
    survey = "",
    sex = "",
    region = "",
    season = "",
    setting = setting,
    value = value,
    source_reference = review_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

assumptions <- do.call(rbind, list(
  assumption("assessment", "accepted_model", "WHAM 2026 Management Track candidate model",
    "Peer review found the model technically sufficient for status evaluation and catch advice."),
  assumption("population", "modeled_years", "1977-2025",
    "Survey series begin in 1977; the report gives the terminal fitted year as 2025."),
  assumption("population", "model_age_grid", "unknown",
    "The exact fitted age grid and plus group were not recovered from the published numerical tables."),
  assumption("catch", "fleet_structure", "One combined commercial and recreational fishery fleet",
    "The 2026 model uses a single fishery fleet; foreign landings are also included in total catch."),
  assumption("index", "active_streams", paste(
    "NEFSC spring BTS (1977-2025); NEFSC fall BTS (1977-2025);",
    "BLLS spring (2014-2025); BLLS fall (2014-2025)"
  ), "The fall 2025 BTS index was retained; the spring 2026 survey was not part of the assessment."),
  assumption("index", "age_composition_likelihood", "Dirichlet",
    "Applied to the five data streams: the fishery and four survey indices."),
  assumption("F", "selectivity_structure", "Age-specific selectivity for the fishery and four survey streams",
    "The fishery selectivity includes time blocks; exact boundaries and coefficients were not recovered."),
  assumption("M", "treatment", "Fixed, age-invariant M = 0.2",
    "Age-dependent M was explored but not retained in the accepted model."),
  assumption("N", "process", "2DAR1; recruitment decoupled from ages 2+",
    "The source describes correlated N-at-age effects with recruitment separated from ages 2+."),
  assumption("recruitment", "process", "AR1 deviations around a time-series mean",
    "The source describes an AR1 recruitment process."),
  assumption("biology", "maturity_at_age", "Mean maturity-at-age over the full time series",
    "The current assessment report describes a time-invariant maturity schedule."),
  assumption("mortality", "fully_selected_F_ages", "6-9",
    "The SAR defines F-full over ages 6-9."),
  assumption("assessment", "retrospective_adjustment", "None",
    "The peer review reported no substantial retrospective pattern and no adjustment was applied."),
  assumption("projection", "2026_catch_assumption", "1,944 t; supplied by the Groundfish PDT",
    "This is a projection assumption, not a fitted historical catch observation."),
  assumption("projection", "harvest_scenario", "Harvest at FMSY from 2027 through 2031",
    "The projection scenario uses a 2026 catch assumption and FMSY thereafter."),
  assumption("projection", "biological_inputs", "Five-year average weight-at-age and selectivity; average maturity",
    "These are the reported projection inputs."),
  assumption("outputs", "historical_uncertainty", "Numerical intervals not tabulated",
    "Figures show 90% intervals, but their values were not digitized; no historical SEs or intervals are entered.")
))

output_row <- function(type, measure, value, year = NA_integer_, unit,
    age = NA_integer_, age_group = "", lwr = NA_real_, upr = NA_real_,
    notes = "", reference = output_reference) {
  data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = "",
    survey = "",
    sex = "",
    region = "Gulf of Maine",
    season = "",
    year = year,
    age = age,
    age_group = age_group,
    value = value,
    se = NA_real_,
    lwr = lwr,
    upr = upr,
    unit = unit,
    source_type = "official_table",
    source_reference = reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

outputs <- do.call(rbind, list(
  do.call(rbind, lapply(seq_along(years), function(i) output_row(
    "biomass", "SSB", ssb_t[i], years[i], "t",
    notes = "Historical WHAM point estimate; no numerical interval is tabulated."
  ))),
  do.call(rbind, lapply(seq_along(years), function(i) output_row(
    "mortality", "Fbar", f_full[i], years[i], "1/year", age_group = "6-9",
    notes = "Reported fully selected F for ages 6-9; no numerical interval is tabulated."
  ))),
  do.call(rbind, lapply(seq_along(years), function(i) output_row(
    "recruitment", "recruitment", recruitment_000[i], years[i], "1000 fish", age = 1L,
    notes = "Reported age-1 recruitment; no numerical interval is tabulated."
  ))),
  output_row("mortality", "Fmsy", .35, unit = "1/year", lwr = .31, upr = .40,
    notes = "FMSY proxy based on F40%; reported 90% confidence interval."),
  output_row("biomass", "Bmsy", 7809, unit = "t", lwr = 4489, upr = 13583,
    notes = "SSBMSY proxy; reported 90% confidence interval."),
  output_row("catch", "msy", 1924, unit = "t/year", lwr = 1101, upr = 3360,
    notes = "MSY proxy; reported 90% confidence interval."),
  do.call(rbind, lapply(2026:2031, function(year) {
    values <- c(9335, 7293, 6229, 6208, 6535, 6799)
    lower <- c(4186, 2463, 1944, 1534, 1238, 1047)
    upper <- c(20816, 21593, 19962, 25117, 34494, 44158)
    i <- year - 2025L
    output_row("biomass", "SSB", values[i], year, "t", lwr = lower[i], upr = upper[i],
      notes = "Projection; reported 90% confidence interval.")
  })),
  do.call(rbind, lapply(2027:2031, function(year) {
    values <- c(2099, 1618, 1481, 1524, 1599)
    i <- year - 2026L
    output_row("catch", "predicted_catch", values[i], year, "t",
      notes = "Projected catch under the reported harvest scenario.")
  })),
  do.call(rbind, lapply(2026:2031, function(year) {
    values <- c(.268, rep(.352, 5))
    i <- year - 2025L
    output_row("mortality", "Fbar", values[i], year, "1/year", age_group = "6-9",
      notes = "Projected fully selected F for ages 6-9; no numerical interval is tabulated.")
  }))
))

append_new_rows(assessments_path, assessment)
append_new_rows(inputs_path, inputs)
append_new_rows(assumptions_path, assumptions)
append_new_rows(outputs_path, outputs)

cat("Imported partial official 2026 Gulf of Maine haddock catch, assumptions, summaries, and projections.\n")
cat("Age-structured inputs and outputs remain unavailable.")
