assessment_id <- "ices_norway_pout_north_sea_2026_benchmark"
stock_id <- "ices_norway_pout_north_sea"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id, "native")
report_url <- "https://doi.org/10.17895/ices.pub.32019630"
report_pdf <- "https://ices-library.figshare.com/ndownloader/files/64519302"
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NP_Sep2025_bench_final_Mfor/run/sum.RData"
)
data_url <- sub("/run/sum\\.RData$", "/data/", model_url)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "sum.RData"), envir = model_env)
fit <- model_env$sesamsum
dat <- fit$data
ages <- as.integer(dat$ages)
times <- as.numeric(dat$times)
years <- seq.int(1984L, 2025L)
survey_names <- c(
  "IBTS Q1 (north of 57N)",
  "EGFS Q3",
  "SGFS Q3 (age-0 through 2012; ages 1-3+ thereafter)",
  "IBTS other countries Q3",
  "SGFS Q3 age 0 (2013 onward)"
)

if (!identical(ages, 0:3) || length(times) != 168L ||
  !isTRUE(all.equal(times, seq(1984, 2025.75, by = 0.25))) ||
  fit$opt$convergence != 0L ||
  !isTRUE(all.equal(as.numeric(dat$fbarrange), c(1, 2))) ||
  !identical(as.integer(dat$keyVarLogN), c(0L, 0L, 0L, 1L)) ||
  !identical(as.integer(dat$keyLogFsta), 0:3) ||
  !identical(as.integer(dat$keyVarLogF), c(0L, 0L, 1L, 1L)) ||
  !isTRUE(all.equal(as.numeric(dim(fit$pl$logN)), c(4, 168))) ||
  !isTRUE(all.equal(as.numeric(dim(fit$pl$logF)), c(4, 168)))) {
  stop("The cached fitted object does not match the reviewed final run.",
    call. = FALSE
  )
}

observations <- data.frame(
  year = floor(dat$t1 + 1e-8),
  quarter = as.integer(round((dat$t1 - floor(dat$t1 + 1e-8)) * 4) + 1),
  age = as.integer(dat$ageFrom),
  age_to = as.integer(dat$ageTo),
  fleet = as.integer(dat$fleet),
  value = as.numeric(dat$obs)
)
if (any(observations$age_to < observations$age) ||
  any(!is.finite(observations$value)) ||
  any(!observations$fleet %in% 1:6) ||
  sum(observations$age_to != observations$age) != 26L ||
  any(observations$age_to != observations$age &
    (observations$fleet != 5L | observations$age != 2L |
      observations$age_to != 3L)) ||
  !identical(as.integer(table(observations$fleet)), c(668L, 126L, 108L, 99L, 78L, 13L))) {
  stop("Unexpected observation rows in the cached fitted object.", call. = FALSE)
}

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", season = "",
                       sampling_time = NA_real_, source_reference,
                       transformation = "Copied the value from the official fitted model object.",
                       notes = "") {
  n <- length(value)
  yr <- rep_len(year, n)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = rep_len(basis, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey, n), sex = "", region = "",
    season = rep_len(season, n), year = yr,
    year_basis = ifelse(is.na(yr), "", "calendar_year"),
    age = rep_len(age, n), value = value, unit = rep_len(unit, n),
    sampling_time = rep_len(sampling_time, n), source_type = "native_model",
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = "", length_bin = NA_real_,
    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

obs_rows <- lapply(sort(unique(observations$fleet)), function(fleet_id) {
  z <- observations[observations$fleet == fleet_id, , drop = FALSE]
  season <- paste0("Q", z$quarter)
  if (fleet_id == 1L) {
    if (any(z$age != z$age_to)) {
      stop("Catch observations unexpectedly combine age groups.", call. = FALSE)
    }
    input_rows(
      "catch", "numbers_at_age", "numbers", z$year, z$age, z$value,
      "million fish",
      fleet = "Total catch", season = season,
      source_reference = paste0(model_url, "; fit$data$obs, t1, ageFrom, fleet"),
      transformation = "Copied raw quarterly catch-at-age observations from the processed final-run object.",
      notes = "Age 3 is the 3+ group; zero catches are retained. The fitted run contains catch through 2025 Q3."
    )
  } else {
    survey_id <- fleet_id - 1L
    direct <- z[z$age == z$age_to, , drop = FALSE]
    grouped <- z[z$age != z$age_to, , drop = FALSE]
    direct_rows <- input_rows(
      "index", "numbers_at_age", "index_scale",
      direct$year, direct$age, direct$value,
      "native survey-index units",
      survey = survey_names[[survey_id]],
      season = paste0("Q", direct$quarter),
      sampling_time = ifelse(direct$quarter == 1L, 0.125, 0.625),
      source_reference = paste0(model_url, "; fit$data$obs, t1, ageFrom, fleet"),
      transformation = "Copied raw survey-index observations from the processed final-run object.",
      notes = "Native index scale; age 3 is the 3+ group. Series/fleet mapping follows WKBWNG 2026 Section 2.5 and Table 2.5."
    )
    if (nrow(grouped)) {
      group_rows <- input_rows(
        "index", "index_by_age_group", "index_scale",
        grouped$year, grouped$age, grouped$value,
        "native survey-index units",
        survey = survey_names[[survey_id]],
        season = paste0("Q", grouped$quarter),
        sampling_time = ifelse(grouped$quarter == 1L, 0.125, 0.625),
        source_reference = paste0(model_url, "; fit$data$obs, ageFrom, ageTo, fleet"),
        transformation = "Copied the fitted observation grouped over its source age interval.",
        notes = "The source ageFrom=2 and ageTo=3 row is one 2-3+ index group; it is retained in the database and omitted from tinyAM conversion because tinyAM has no grouped-age index likelihood."
      )
      rbind(direct_rows, group_rows)
    } else {
      direct_rows
    }
  }
})

aux <- data.frame(
  year = floor(dat$auxt1 + 1e-8),
  quarter = as.integer(round((dat$auxt1 - floor(dat$auxt1 + 1e-8)) * 4) + 1),
  age = as.integer(dat$auxage),
  M = as.numeric(dat$auxM),
  PM = as.numeric(dat$auxPM),
  SW = as.numeric(dat$auxSW),
  CW = as.numeric(dat$auxCW),
  DW = as.numeric(dat$auxDW)
)
if (nrow(aux) != 668L || any(!is.finite(as.matrix(aux[c("M", "PM", "SW", "CW")]))) ||
  any(!is.finite(aux$DW)) || any(aux$M <= 0) ||
  any(aux$PM < 0 | aux$PM > 1) || any(aux$CW != aux$DW)) {
  stop("Unexpected auxiliary inputs in the cached fitted object.", call. = FALSE)
}

aux_rows <- function(type, measure, basis, value, unit, slot, notes) {
  input_rows(
    type, measure, basis, aux$year, aux$age, value, unit,
    season = paste0("Q", aux$quarter), source_reference =
      paste0(model_url, "; fit$data$", slot),
    transformation = "Converted native grams per fish to kilograms per fish where applicable.",
    notes = notes
  )
}

weight_profile <- unique(aux[c("quarter", "age", "SW")])
if (anyDuplicated(aux[c("quarter", "age", "year")]) ||
  nrow(weight_profile) != 16L ||
  anyDuplicated(weight_profile[c("quarter", "age")]) ||
  any(vapply(
    split(aux$SW, interaction(aux$quarter, aux$age, drop = TRUE)),
    function(x) length(unique(x)) != 1L, logical(1)
  ))) {
  stop("The stock weight-at-age input is not constant by quarter and age.",
    call. = FALSE
  )
}

inputs <- do.call(rbind, c(obs_rows, list(
  aux_rows(
    "M", "natural_mortality_at_age", "per_year", aux$M, "per year", "auxM",
    "Time-varying age- and quarter-specific M supplied to the fitted model; it is not estimated by SESAM."
  ),
  input_rows(
    "weight", "weight_at_age", "kg_per_fish",
    rep(NA_integer_, nrow(weight_profile)), weight_profile$age,
    weight_profile$SW / 1000, "kg per fish",
    season = paste0("Q", weight_profile$quarter),
    source_reference = paste0(model_url, "; fit$data$auxSW"),
    transformation = "Converted native grams per fish to kilograms per fish.",
    notes = "Stock weight is constant across years but differs by age and quarter; age 3 is the 3+ group."
  ),
  aux_rows(
    "catch_weight", "weight_at_age", "kg_per_fish", aux$CW / 1000,
    "kg per fish", "auxCW",
    "Catch weight-at-age varies by year and quarter. The source model's discard weights equal catch weights."
  ),
  aux_rows(
    "catch_weight", "discard_weight_at_age", "kg_per_fish", aux$DW / 1000,
    "kg per fish", "auxDW",
    "Source-model discard weights are retained separately and equal catch weights at every age, year, and quarter."
  ),
  input_rows(
    "maturity", "maturity_at_age", "proportion",
    rep(NA_integer_, length(ages)), ages,
    vapply(ages, function(age) unique(aux$PM[aux$age == age])[[1L]], numeric(1)),
    "proportion",
    source_reference = paste0(model_url, "; fit$data$auxPM"),
    transformation = "Copied the time-invariant maturity ogive from the official model object.",
    notes = "0% at age 0, 20% at age 1, and 100% at ages 2 and 3+."
  )
)))

output_rows <- function(type, measure, year, value, unit,
                        age = NA_integer_, age_group = "",
                        season = "", lwr = NA_real_, upr = NA_real_,
                        source_reference, notes = "") {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "",
    season = rep_len(season, n), year = rep_len(year, n),
    age = rep_len(age, n), age_group = rep_len(age_group, n),
    value = value, se = NA_real_, lwr = rep_len(lwr, n),
    upr = rep_len(upr, n), unit = rep_len(unit, n),
    source_type = "native_model", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

surface_output <- function(x, type, measure, unit, slot) {
  grid <- expand.grid(age = ages, index = seq_along(times))
  q <- as.integer(round((times[grid$index] - floor(times[grid$index])) * 4) + 1)
  output_rows(
    type, measure, floor(times[grid$index]),
    as.vector(x)[seq_len(nrow(grid))], unit,
    age = grid$age, age_group = ifelse(grid$age == max(ages), "3+", ""),
    season = paste0("Q", q),
    source_reference = paste0(model_url, "; fit$pl$", slot),
    notes = "Quarterly fitted state; age 3 is the 3+ group."
  )
}

output_time <- data.frame(
  year = floor(times),
  quarter = as.integer(round((times - floor(times)) * 4) + 1),
  season = paste0("Q", as.integer(round((times - floor(times)) * 4) + 1))
)
if (abs(fit$SSB[which(times == 2012.75)] - 30766.76) > 1) {
  stop("The cached fit does not match the benchmark's reported Blim check.",
    call. = FALSE
  )
}

outputs <- rbind(
  surface_output(
    exp(fit$pl$logN), "population", "numbers_at_age",
    "million fish", "logN"
  ),
  surface_output(
    exp(fit$pl$logF), "mortality", "fishing_mortality_at_age",
    "per year", "logF"
  ),
  output_rows(
    "biomass", "SSB", output_time$year, as.numeric(fit$SSB), "tonnes",
    season = output_time$season, lwr = as.numeric(fit$SSB.lo),
    upr = as.numeric(fit$SSB.hi),
    source_reference = paste0(model_url, "; SSB, SSB.lo, SSB.hi"),
    notes = "Quarterly spawning-stock biomass with native 95% limits."
  ),
  output_rows(
    "mortality", "Fbar", output_time$year, as.numeric(fit$FBAR), "per year",
    age_group = "1-2", season = output_time$season,
    lwr = as.numeric(fit$FBAR.lo), upr = as.numeric(fit$FBAR.hi),
    source_reference = paste0(model_url, "; FBAR, FBAR.lo, FBAR.hi"),
    notes = "Quarterly mean F at ages 1-2 with native 95% limits."
  ),
  output_rows(
    "recruitment", "recruitment", years, exp(fit$logrecr), "million fish",
    age = 0L, age_group = "age 0",
    lwr = exp(fit$logrecr.lo), upr = exp(fit$logrecr.hi),
    source_reference = paste0(model_url, "; logrecr, logrecr.lo, logrecr.hi"),
    notes = "Annual recruitment at age 0 with native 95% limits."
  )
)

assumption <- function(component, setting, value, source_reference,
                       notes = "", survey = "") {
  data.frame(
    assessment_id = assessment_id, component = component, fleet = "",
    survey = survey, sex = "", region = "", season = "", setting = setting,
    value = value, source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
report_ref <- paste0(report_url, "; WKBWNG 2026, Sections 2.3-2.6 and Tables 2.1-2.5")
model_ref <- paste0(model_url, "; fit$data and fit$pl")
assumptions <- do.call(rbind, list(
  assumption("model", "model_age_range", "ages 0-3+, recruitment at age 0", report_ref),
  assumption("model", "fitted_years", "1984-2025, quarterly state times", model_ref),
  assumption("model", "quarter_length", "0.25 year", model_ref),
  assumption(
    "recruitment", "recruitment_timing", "Q3", model_ref,
    "Recruitment enters the quarterly population process in the third quarter."
  ),
  assumption(
    "N", "process_variance_sharing", "ages 0-2 share; age 3+ separate", model_ref,
    "Copied from keyVarLogN."
  ),
  assumption("F", "process", "quarterly random walk in log F", report_ref),
  assumption(
    "F", "age_state_sharing", "separate F state for ages 0, 1, 2, and 3+", model_ref,
    "keyLogFsta is 0, 1, 2, 3."
  ),
  assumption(
    "F", "process_variance_sharing", "ages 0-1 share; ages 2-3+ share", model_ref,
    "Copied from keyVarLogF."
  ),
  assumption("F", "age_correlation", "AR(1) across ages", report_ref),
  assumption("F", "Fbar_ages", "1-2", model_ref),
  assumption(
    "F", "big_jump_rule", "multiply selected log-F increment SDs by 100", report_ref,
    "A time step is selected when the absolute change in log(catch + 1) exceeds 2.9."
  ),
  assumption(
    "M", "process", "externally supplied, time-varying M by age and quarter", report_ref,
    "M is not estimated by SESAM; the official M-0 input is based on North Sea SMS."
  ),
  assumption("M", "time_coverage", "1984-2022 SMS series; 2022 values carried through 2025", report_ref),
  assumption(
    "catch", "input_period", "1984-2025 Q1-Q3", model_ref,
    "The 2025 Q4 catch observation is not present."
  ),
  assumption("catch", "age_range", "ages 0-3+, with age 3 as the plus group", model_ref),
  assumption(
    "catch", "observation_variance_sharing", "age 0 separate; ages 1-2 share; age 3+ separate", model_ref,
    "Copied from keyVarObs."
  ),
  assumption("index", "q_sharing", paste(
    "IBTS Q1 ages 1/2/3+ separate; EGFS Q3 age 0, age 1, and ages 2-3+ shared;",
    "SGFS Q3 age 0, age 1, and ages 2-3+ shared; IBTS other countries Q3 ages 0, 1, and grouped 2-3+ separate;",
    "SGFS Q3 age 0 from 2013 separate."
  ), report_ref, "Fleets remain separate; the shared age keys are within EGFS and SGFS."),
  assumption("index", "observation_variance_sharing", paste(
    "IBTS Q1 ages 1/2/3+ separate; EGFS Q3 ages 0-3+ separate;",
    "SGFS Q3 age 0/1-2/3+ groups; IBTS other countries Q3 ages 0, 1, and grouped 2-3+ separate;",
    "later SGFS age 0 shares the earlier SGFS age-0 variance."
  ), model_ref, "Exact keyVarObs mapping is preserved in the cached object."),
  assumption(
    "index", "unresolved_coverage", "IBTS other countries Q3 ends in 2024 in the fitted object", report_ref,
    "WKBWNG Section 2.5 lists this index through 2025; the cached fit and obs.dat stop at 2024."
  ),
  assumption("biology", "maturity", "0, 0.2, 1, 1 at ages 0-3+", report_ref),
  assumption("biology", "stock_weight", "year-invariant; age- and quarter-specific", model_ref),
  assumption(
    "fit", "optimizer", "convergence 0; objective 1547.746", model_ref,
    "Optimizer message: relative convergence (4)."
  )
))
for (i in seq_along(survey_names)) {
  fleet_id <- i + 1L
  z <- observations[observations$fleet == fleet_id, , drop = FALSE]
  assumptions <- rbind(assumptions, assumption(
    "index", "sampling_time",
    if (unique(z$quarter) == 1L) "0.125" else "0.625",
    model_ref, "Midpoint of the survey quarter in the quarterly model.",
    survey = survey_names[[i]]
  ))
}

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "ICES",
  authority_stock_id = "nop.27.3a4",
  scientific_name = "Trisopterus esmarkii",
  common_name = "Norway pout",
  area = "Subarea 4 and Division 3.a",
  region = "North Sea, Skagerrak, and Kattegat",
  ocean = "Northeast Atlantic",
  notes = "ICES stock nop.27.3a4; North Sea and Skagerrak-Kattegat are assessed as one unit.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2025L, assessment_type = "benchmark",
  model_family = "SESAM",
  model_version = "WKBWNG 2026; NP_Sep2025_bench_final_Mfor",
  is_current = TRUE, is_applied = FALSE, framework_year = 2026L,
  assessment_url = report_url, framework_url = report_url,
  data_url = data_url, model_url = model_url, repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste(
    "Official February 2026 WKBWNG benchmark run, distinct from the 2025 production-advice assessment.",
    "WGNSSK 2026 states that no spring advice was issued for Norway pout, so this current detailed benchmark is not marked applied for advice.",
    "The fitted object and Table 2.5 settings match the official report; SSB at 2012.75 matches the reported Blim (30,766.76 t).",
    "The report lists IBTS other-countries Q3 through 2025, but the cached fit and obs.dat contain this fleet only through 2024."
  ),
  stringsAsFactors = FALSE
)

database <- file.path(base, "database")
read_db <- function(name) {
  read.csv(file.path(database, name),
    colClasses = "character",
    na.strings = "", check.names = FALSE
  )
}
append_rows <- function(path, rows, current, key) {
  if (!identical(names(current), names(rows))) {
    stop("Unexpected columns in ", basename(path), ".", call. = FALSE)
  }
  if (any(current[[key]] == assessment_id, na.rm = TRUE)) {
    stop("This assessment already occurs in ", basename(path), ".", call. = FALSE)
  }
  utils::write.table(rows, path,
    sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}

stocks <- read_db("stocks.csv")
if (!identical(names(stocks), names(stock)) || any(stocks$stock_id == stock_id)) {
  stop("Unexpected stock schema or this stock already exists.", call. = FALSE)
}
append_rows(
  file.path(database, "assessments.csv"), assessment,
  read_db("assessments.csv"), "assessment_id"
)
append_rows(
  file.path(database, "assumptions.csv"), assumptions,
  read_db("assumptions.csv"), "assessment_id"
)
append_rows(
  file.path(database, "inputs.csv"), inputs,
  read_db("inputs.csv"), "assessment_id"
)
append_rows(
  file.path(database, "outputs.csv"), outputs,
  read_db("outputs.csv"), "assessment_id"
)
utils::write.table(stock, file.path(database, "stocks.csv"),
  sep = ",",
  quote = TRUE, row.names = FALSE, col.names = FALSE,
  append = TRUE, na = ""
)
message(
  "Added ", nrow(inputs), " inputs, ", nrow(assumptions),
  " assumptions, and ", nrow(outputs), " outputs for ", assessment_id,
  "."
)
