assessment_id <- "ices_plaice_irish_sea_7a_2026"
stock_id <- "ck_ices_wgcse_platessa_is27_7a"
root <- "."
cache <- file.path(root, "source_cache", assessment_id)
database <- file.path(root, "database")
model_base <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Ple.7a_26"
model_url <- paste0(model_base, "/run/model.RData")
data_url <- paste0(model_base, "/run/data.RData")
config_url <- paste0(model_base, "/conf/model.cfg")
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22655"
sag_xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22655"
report_url <- "https://doi.org/10.17895/ices.pub.32625759"
framework_url <- "https://doi.org/10.17895/ices.pub.8713"
taf_commit <- "20246f16b79a4f4618faed4d8140aa4176a9819c"
taf_url <- paste0(
  "https://github.com/ices-advice/2026_ple.27.7a/tree/",
  taf_commit
)

required_files <- file.path(cache, c(
  "run_data.RData", "run_model.RData", "conf_model.cfg",
  "data_cn.dat", "data_cw.dat", "data_dw.dat", "data_lf.dat",
  "data_lw.dat", "data_mo.dat", "data_nm.dat", "data_pf.dat",
  "data_pm.dat", "data_survey.dat", "data_Survey_DARDS.dat",
  "data_sw.dat", "ices_sag_2026_stock.xml", "taf_data.R",
  "taf_parameters.R", "taf_model.R", "taf_output.R"
))
if (any(!file.exists(required_files))) {
  stop("Cache the pinned ICES assessment sources before importing.", call. = FALSE)
}

read_table <- function(path) {
  utils::read.csv(path, colClasses = "character", na.strings = "",
    check.names = FALSE, stringsAsFactors = FALSE
  )
}
append_rows <- function(path, rows, id_column = "assessment_id") {
  existing <- read_table(path)
  if (!identical(names(existing), names(rows))) {
    stop("Unexpected columns in ", basename(path), call. = FALSE)
  }
  if (any(existing[[id_column]] == assessment_id, na.rm = TRUE)) {
    stop("Rows already exist for ", assessment_id, " in ", basename(path), call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}

load_object <- function(file, object_name) {
  e <- new.env(parent = globalenv())
  suppressWarnings(load(file.path(cache, file), envir = e))
  object <- e[[object_name]]
  if (is.null(object)) stop(file, " does not contain ", object_name, ".", call. = FALSE)
  object
}

source_data <- load_object("run_data.RData", "dat")
fit <- load_object("run_model.RData", "fit")
model_data <- fit$obj$env$data
years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
if (!identical(years, 1981:2025) || !identical(ages, 1:8) ||
  !identical(as.integer(source_data$years), years) ||
  !isTRUE(all.equal(model_data$aux, fit$data$aux)) ||
  !isTRUE(all.equal(model_data$years, fit$data$years)) ||
  !isTRUE(all.equal(model_data$logobs, fit$data$logobs)) ||
  !identical(as.integer(model_data$fleetTypes), c(0L, 2L, 3L, 3L)) ||
  !isTRUE(all.equal(as.numeric(model_data$sampleTimes), c(0, 0.8, 0, 0)))) {
  stop("The cached SAM fit and data do not match the expected 2026 run.", call. = FALSE)
}
if (fit$opt$convergence != 0L || !is.finite(fit$opt$objective) ||
  !identical(as.integer(fit$conf$fbarRange), c(3L, 6L)) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, 0L, 0L, 0L)) ||
  !identical(as.integer(fit$conf$keyLogFsta[1L, ]), c(0:6, 6L)) ||
  !identical(as.integer(fit$conf$keyBiomassTreat), c(-1L, -1L, 0L, 0L))) {
  stop("The model fit or SAM configuration differs from the 2026 assessment.", call. = FALSE)
}

obs <- data.frame(
  year = model_data$aux[, "year"],
  fleet = model_data$aux[, "fleet"],
  age = model_data$aux[, "age"],
  value = exp(model_data$logobs)
)
catch <- obs[obs$fleet == 1L, , drop = FALSE]
uk_bts <- obs[obs$fleet == 2L & is.finite(obs$value), , drop = FALSE]
nigfs_q1 <- obs[obs$fleet == 3L & is.finite(obs$value), , drop = FALSE]
nigfs_q4 <- obs[obs$fleet == 4L & is.finite(obs$value), , drop = FALSE]
if (nrow(catch) != 360L || sum(is.finite(catch$value)) != 358L || nrow(uk_bts) != 224L ||
  nrow(nigfs_q1) != 34L || nrow(nigfs_q4) != 33L ||
  any(!catch$age %in% ages) || any(!uk_bts$age %in% 1:7) ||
  any(nigfs_q1$age != -1L) || any(nigfs_q4$age != -1L)) {
  stop("Unexpected fleet, year, age, or missing-observation coverage in the fitted SAM data.")
}

raw_catch <- exp(source_data$logobs)
catch_idx <- source_data$aux[, "fleet"] == 1L & is.finite(raw_catch)
raw_land_fraction <- source_data$landFrac[cbind(
  match(source_data$aux[catch_idx, "year"], years),
  match(source_data$aux[catch_idx, "age"], ages),
  1L
)]
discard_survival <- 0.4
dead_catch <- raw_catch[catch_idx] * (
  raw_land_fraction + (1 - raw_land_fraction) * (1 - discard_survival)
)
if (!isTRUE(all.equal(
  as.numeric(dead_catch),
  as.numeric(exp(model_data$logobs[catch_idx])),
  tolerance = 1e-10
))) {
  stop("The fitted catch does not reproduce the TAF discard-survival transformation.")
}
adjusted_land_fraction <- raw_land_fraction / (
  raw_land_fraction + (1 - raw_land_fraction) * (1 - discard_survival)
)
fit_land_fraction <- model_data$landFrac[cbind(
  match(source_data$aux[catch_idx, "year"], years),
  match(source_data$aux[catch_idx, "age"], ages),
  1L
)]
if (!isTRUE(all.equal(adjusted_land_fraction, fit_land_fraction, tolerance = 1e-10))) {
  stop("The fitted landings fractions do not match the TAF survival adjustment.")
}

input_header <- names(read_table(file.path(database, "inputs.csv")))
input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", region = "", season = "",
                       sampling_time = NA_real_, source_reference,
                       source_type = "native_model", transformation = "",
                       notes = "", year_basis = NULL) {
  n <- max(length(year), length(age), length(value), length(fleet),
    length(survey), length(region), length(season), length(sampling_time),
    length(source_reference), length(source_type), length(transformation),
    length(notes), length(year_basis))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(input_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- input_header
  put <- function(field, x) {
    x <- rep_len(x, n)
    out[[field]] <<- ifelse(is.na(x), "", as.character(x))
  }
  put("assessment_id", assessment_id)
  put("type", type)
  put("measure", measure)
  put("basis", basis)
  put("fleet", fleet)
  put("survey", survey)
  put("region", region)
  put("season", season)
  put("year", year)
  if (is.null(year_basis)) {
    year_basis <- if (all(is.na(year))) "" else "calendar_year"
  }
  put("year_basis", year_basis)
  put("age", age)
  put("value", ifelse(is.finite(value),
    format(value, digits = 15, scientific = FALSE, trim = TRUE), ""))
  put("unit", unit)
  put("sampling_time", ifelse(is.na(sampling_time), "", as.character(sampling_time)))
  put("source_type", source_type)
  put("source_reference", source_reference)
  put("transformation", transformation)
  put("notes", notes)
  out
}

surface_rows <- function(surface, type, measure, basis, unit, source_file,
                         annual = TRUE, transformation = "", notes = "") {
  surface <- as.matrix(surface)
  if (ncol(surface) != length(ages)) stop("Unexpected age dimension in ", source_file)
  source_reference <- paste0(model_url, "; ", source_file)
  if (annual) {
    if (nrow(surface) != length(years)) stop("Unexpected year dimension in ", source_file)
    grid <- expand.grid(year = years, age = ages)
    value <- as.vector(surface)
    keep <- is.finite(value)
    input_rows(type, measure, basis, grid$year[keep], grid$age[keep],
      value[keep], unit, source_reference = source_reference,
      transformation = transformation, notes = notes
    )
  } else {
    if (nrow(surface) != length(years) ||
      any(!is.finite(surface)) ||
      max(abs(sweep(surface, 2L, surface[1L, ], function(x, y) x - y))) > 1e-12) {
      stop("Expected a finite, time-invariant surface in ", source_file)
    }
    input_rows(type, measure, basis, rep(NA_integer_, length(ages)), ages,
      surface[1L, ], unit, source_reference = source_reference,
      transformation = transformation, notes = notes, year_basis = ""
    )
  }
}

model_ref <- paste0(model_url, "; fit$obj$env$data")
inputs <- rbind(
  input_rows("catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish", fleet = "Commercial dead catch",
    source_reference = paste0(model_ref, "; ", model_base, "/data/cn.dat"),
    transformation = "Exponentiated the fitted SAM log observations. The pinned TAF data script applies 40% discard survival, so fitted catch is landings plus 60% of discards.",
    notes = "The source run data are pre-adjustment values; the effective fitted observations are retained here. Two source catch cells are absent in the fit."
  ),
  input_rows("index", "numbers_at_age", "index_scale", uk_bts$year, uk_bts$age,
    uk_bts$value, "survey index (unit unresolved)", survey = "UK BTS-Q3",
    region = "Irish Sea", season = "Q3", sampling_time = model_data$sampleTimes[[2L]],
    source_reference = paste0(model_ref, "; ", model_base, "/data/survey.dat; WGCSE 2026 Table 13.4"),
    transformation = "Exponentiated the fitted SAM log observations; retained the native index scale.",
    notes = "The source report provides an age-specific biomass index but does not state a model index multiplier."
  ),
  input_rows("index", "total_biomass", "biomass", nigfs_q1$year,
    rep(NA_integer_, nrow(nigfs_q1)), nigfs_q1$value, "kg per 3 miles",
    survey = "NIGFS-WIBTS-Q1", region = "Combined Irish Sea strata 1-7",
    season = "Q1", sampling_time = model_data$sampleTimes[[3L]],
    source_reference = paste0(model_ref, "; ", model_base, "/data/Survey_DARDS.dat; WGCSE 2026 Table 13.3a"),
    transformation = "Exponentiated the fitted SAM log observations; no unit conversion applied.",
    notes = "The SAM data label is DARDS. The fitted configuration treats this as an SSB index; sampling time in the model data is 0."
  ),
  input_rows("index", "total_biomass", "biomass", nigfs_q4$year,
    rep(NA_integer_, nrow(nigfs_q4)), nigfs_q4$value, "kg per 3 miles",
    survey = "NIGFS-WIBTS-Q4", region = "Combined Irish Sea strata 1-7",
    season = "Q4", sampling_time = model_data$sampleTimes[[4L]],
    source_reference = paste0(model_ref, "; ", model_base, "/data/Survey_DARDS.dat; WGCSE 2026 Table 13.3b"),
    transformation = "Exponentiated the fitted SAM log observations; no unit conversion applied.",
    notes = "The SAM data label is DARDA. The fitted configuration treats this as an SSB index; 2024 is absent and the model timing value is 0."
  ),
  surface_rows(model_data$stockMeanWeight, "weight", "weight_at_age",
    "kg_per_fish", "kg per fish", "fit$obj$env$data$stockMeanWeight",
    notes = "Effective stock weights used by the fitted SAM model. The TAF data script replaces the pre-adjustment stock-weight surface with catch weights after applying discard survival."
  ),
  surface_rows(model_data$catchMeanWeight[, , 1L], "catch_weight",
    "weight_at_age", "kg_per_fish", "kg per fish", "fit$obj$env$data$catchMeanWeight",
    notes = "Catch weights after the TAF discard-survival adjustment."
  ),
  surface_rows(model_data$landMeanWeight[, , 1L], "catch_weight",
    "landings_weight_at_age", "kg_per_fish", "kg per fish", "fit$obj$env$data$landMeanWeight"),
  surface_rows(model_data$disMeanWeight[, , 1L], "catch_weight",
    "discard_weight_at_age", "kg_per_fish", "kg per fish", "fit$obj$env$data$disMeanWeight"),
  surface_rows(model_data$landFrac[, , 1L], "catch",
    "landings_fraction_at_age", "proportion", "proportion",
    "fit$obj$env$data$landFrac",
    transformation = "Recomputed by the TAF data script as landings divided by landings plus the dead fraction of discards.",
    notes = "This is the effective post-survival landings fraction in the fitted model."
  ),
  surface_rows(model_data$propMat, "maturity", "maturity_at_age",
    "proportion", "proportion", "fit$obj$env$data$propMat", annual = FALSE,
    notes = "Fixed age-specific maturity ogive.")
)

mortality <- surface_rows(model_data$natMor, "M", "natural_mortality_at_age",
  "per_year", "per year", "fit$obj$env$data$natMor", annual = FALSE,
  notes = "Fixed age-specific natural mortality; constant over years.")
biology <- rbind(
  surface_rows(model_data$propF[, , 1L], "biology",
    "fraction_F_before_spawning", "proportion", "proportion",
    "fit$obj$env$data$propF", annual = FALSE,
    notes = "No fishing mortality is applied before spawning."),
  surface_rows(model_data$propM, "biology",
    "fraction_M_before_spawning", "proportion", "proportion",
    "fit$obj$env$data$propM", annual = FALSE,
    notes = "No natural mortality is applied before spawning.")
)
inputs <- rbind(inputs, mortality, biology)

xml <- paste(readLines(file.path(cache, "ices_sag_2026_stock.xml"),
  warn = FALSE, encoding = "UTF-8"), collapse = "\n"
)
blocks <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
if (!length(blocks)) stop("No Fish_Data records in the ICES SAG XML.")
read_field <- function(node, tag) {
  match <- regmatches(node, regexec(
    paste0("(?s)<", tag, ">(.*?)</", tag, ">"), node, perl = TRUE
  ))[[1L]]
  if (length(match) < 2L || !nzchar(match[[2L]])) return(NA_real_)
  suppressWarnings(as.numeric(match[[2L]]))
}
sag_tags <- c(
  "Year", "Recruitment", "Low_Recruitment", "High_Recruitment",
  "StockSize", "Low_StockSize", "High_StockSize",
  "FishingPressure", "Low_FishingPressure", "High_FishingPressure"
)
sag <- as.data.frame(do.call(rbind, lapply(blocks, function(node) {
  as.list(vapply(sag_tags, function(tag) read_field(node, tag), numeric(1)))
})))
names(sag) <- c(
  "year", "recruitment", "recruitment_lwr", "recruitment_upr",
  "SSB", "SSB_lwr", "SSB_upr", "Fbar", "Fbar_lwr", "Fbar_upr"
)
sag[] <- lapply(sag, function(x) suppressWarnings(as.numeric(as.character(x))))
sag$year <- as.integer(sag$year)
historical_sag <- sag[sag$year %in% years, , drop = FALSE]
if (!identical(sort(historical_sag$year), years)) {
  stop("The SAG XML does not cover every fitted year.")
}

summary_series <- function(name) {
  idx <- which(names(fit$sdrep$value) == name)
  if (length(idx) != length(years)) stop("Unexpected fitted summary length for ", name)
  log_estimate <- as.numeric(fit$sdrep$value[idx])
  log_sd <- as.numeric(fit$sdrep$sd[idx])
  data.frame(
    estimate = exp(log_estimate),
    se = exp(log_estimate) * log_sd,
    lwr = exp(log_estimate - 2 * log_sd),
    upr = exp(log_estimate + 2 * log_sd)
  )
}
summary_outputs <- list(
  recruitment = summary_series("logR"),
  SSB = summary_series("logssb"),
  Fbar = summary_series("logfbar"),
  TSB = summary_series("logtsb"),
  dead_catch = summary_series("logCatch")
)
for (measure in names(summary_outputs)) {
  sag_measure <- if (measure == "recruitment") "recruitment" else measure
  if (!sag_measure %in% names(historical_sag)) next
  if (anyNA(historical_sag[[sag_measure]]) ||
    max(abs(summary_outputs[[measure]]$estimate - historical_sag[[sag_measure]]) /
      pmax(1, historical_sag[[sag_measure]])) > 0.01) {
    stop("The fitted ", measure, " series does not match ICES SAG within 1%.")
  }
}

N <- exp(t(fit$pl$logN))
F_state <- cbind(NA_real_, exp(t(fit$pl$logF)))
F_key <- as.integer(fit$conf$keyLogFsta[1L, ])
F <- F_state[, F_key + 2L, drop = FALSE]
F[is.na(F)] <- 0
if (!identical(dim(N), c(length(years), length(ages))) ||
  !identical(dim(F), c(length(years), length(ages))) ||
  max(abs(F[, 7L] - F[, 8L])) > 1e-12) {
  stop("The fitted N/F surfaces do not match the SAM age structure.")
}

output_header <- names(read_table(file.path(database, "outputs.csv")))
output_rows <- function(type, measure, year, age = NA_integer_,
                        age_group = "", value, se = NA_real_, lwr = NA_real_,
                        upr = NA_real_, unit, source_type,
                        source_reference, notes = "") {
  keep <- is.finite(value)
  n <- sum(keep)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_header
  put <- function(field, x) {
    x <- rep_len(x, length(value))[keep]
    out[[field]] <<- ifelse(is.na(x), "", as.character(x))
  }
  put("assessment_id", assessment_id)
  put("type", type)
  put("measure", measure)
  put("year", year)
  put("age", age)
  put("age_group", age_group)
  put("value", format(value[keep], digits = 15, scientific = FALSE, trim = TRUE))
  put("se", format(se[keep], digits = 15, scientific = FALSE, trim = TRUE))
  put("lwr", format(lwr[keep], digits = 15, scientific = FALSE, trim = TRUE))
  put("upr", format(upr[keep], digits = 15, scientific = FALSE, trim = TRUE))
  put("unit", unit)
  put("source_type", source_type)
  put("source_reference", source_reference)
  put("notes", notes)
  out
}

output_ref <- paste0(model_ref, "; WGCSE 2026 Tables 13.11-13.13")
outputs <- rbind(
  output_rows("population", "numbers_at_age",
    rep(years, each = length(ages)), rep(ages, times = length(years)),
    value = as.vector(t(N)), unit = "thousand fish", source_type = "native_model",
    source_reference = paste0(model_ref, "; WGCSE 2026 Table 13.11"),
    notes = "Unrounded official fitted estimates. Age 8 is the 8+ group; age-specific uncertainty is not reported in the source table."
  ),
  output_rows("population", "total_abundance", years,
    value = rowSums(N), unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(model_ref, "; WGCSE 2026 Table 13.11"),
    notes = "Sum of official fitted N-at-age across ages 1-8+. No uncertainty interval is available for the total."
  ),
  output_rows("mortality", "fishing_mortality_at_age",
    rep(years, each = length(ages)), rep(ages, times = length(years)),
    value = as.vector(t(F)), unit = "per year", source_type = "native_model",
    source_reference = paste0(model_ref, "; WGCSE 2026 Table 13.12"),
    notes = "Unrounded official fitted estimates. Age 8 shares its F state with age 7; age-specific uncertainty is not reported in the source table."
  ),
  output_rows("recruitment", "recruitment", years, age = 1L,
    value = summary_outputs$recruitment$estimate,
    se = summary_outputs$recruitment$se,
    lwr = summary_outputs$recruitment$lwr,
    upr = summary_outputs$recruitment$upr, unit = "thousand fish",
    source_type = "native_model", source_reference = output_ref,
    notes = "Fitted SAM estimates; approximate 95% limits are exp(log estimate +/- 2 log-scale standard errors), matching the TAF report-table method."
  ),
  output_rows("biomass", "SSB", years,
    value = summary_outputs$SSB$estimate, se = summary_outputs$SSB$se,
    lwr = summary_outputs$SSB$lwr,
    upr = summary_outputs$SSB$upr, unit = "tonnes",
    source_type = "native_model", source_reference = output_ref,
    notes = "Fitted SAM estimates; approximate 95% limits are exp(log estimate +/- 2 log-scale standard errors), matching the TAF report-table method."
  ),
  output_rows("mortality", "Fbar", years, age_group = "3-6",
    value = summary_outputs$Fbar$estimate, se = summary_outputs$Fbar$se,
    lwr = summary_outputs$Fbar$lwr,
    upr = summary_outputs$Fbar$upr, unit = "per year",
    source_type = "native_model", source_reference = output_ref,
    notes = "Arithmetic mean F for ages 3-6, as specified in the fitted configuration and ICES report. Approximate 95% limits use +/- 2 log-scale standard errors."
  ),
  output_rows("biomass", "total_biomass", years,
    value = summary_outputs$TSB$estimate, se = summary_outputs$TSB$se,
    lwr = summary_outputs$TSB$lwr,
    upr = summary_outputs$TSB$upr, unit = "tonnes",
    source_type = "native_model", source_reference = output_ref,
    notes = "Total stock biomass from the fitted SAM summary; approximate 95% limits use +/- 2 log-scale standard errors."
  ),
  output_rows("catch", "dead_catch", years,
    value = summary_outputs$dead_catch$estimate,
    se = summary_outputs$dead_catch$se,
    lwr = summary_outputs$dead_catch$lwr,
    upr = summary_outputs$dead_catch$upr, unit = "tonnes",
    source_type = "native_model", source_reference = output_ref,
    notes = "Catch is landings plus 60% of discards. Approximate 95% limits use +/- 2 log-scale standard errors."
  )
)
forecast <- sag[sag$year == 2026L, , drop = FALSE]
if (nrow(forecast) == 1L) {
  outputs <- rbind(outputs,
    output_rows("recruitment", "recruitment", 2026L, age = 1L,
      value = forecast$recruitment, lwr = forecast$recruitment_lwr,
      upr = forecast$recruitment_upr, unit = "thousand fish",
      source_type = "official_machine_readable", source_reference = sag_xml_url,
      notes = "2026 forecast from ICES SAG; this is not an additional fitted year."),
    output_rows("biomass", "SSB", 2026L,
      value = forecast$SSB, lwr = forecast$SSB_lwr, upr = forecast$SSB_upr,
      unit = "tonnes", source_type = "official_machine_readable",
      source_reference = sag_xml_url,
      notes = "2026 forecast from ICES SAG; this is not an additional fitted year.")
  )
}

assumption_header <- names(read_table(file.path(database, "assumptions.csv")))
assumption_rows <- function(component, setting, value, source_reference,
                            notes = "", survey = "", fleet = "", season = "") {
  n <- max(length(component), length(setting), length(value),
    length(source_reference), length(notes), length(survey), length(fleet),
    length(season))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(assumption_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- rep_len(source_reference, n)
  out$notes <- rep_len(notes, n)
  out$survey <- rep_len(survey, n)
  out$fleet <- rep_len(fleet, n)
  out$season <- rep_len(season, n)
  out
}
assumptions <- do.call(rbind, list(
  assumption_rows("assessment", "stock_code", "ple.27.7a", sag_url),
  assumption_rows("assessment", "assessment_year", "2026", sag_url),
  assumption_rows("assessment", "official_run", "Ple.7a_26", model_url,
    paste("The official fitted SAM object has optimizer convergence code", fit$opt$convergence, "and objective", format(fit$opt$objective, digits = 8), ".")),
  assumption_rows("assessment", "taf_repository_revision", taf_commit, taf_url),
  assumption_rows("assessment", "stockassessment_version", "unknown", file.path(cache, "conf_locked.ver"),
    "The public lock file contains no package revision; the official fitted object is used directly."),
  assumption_rows("population", "model_years", "1981-2025", model_url),
  assumption_rows("population", "model_ages", "1-8+", config_url,
    "Age 8 is the plus group."),
  assumption_rows("population", "recruitment_age", "1", config_url),
  assumption_rows("N", "process", "Random walk", config_url,
    "stockRecruitmentModelCode=0."),
  assumption_rows("N", "process_variance_sharing", "Age 1 separate; ages 2-8 share one variance", config_url),
  assumption_rows("F", "process", "Temporal random walk with AR(1) correlation across age states", config_url,
    "corFlag=2; one F process variance is shared."),
  assumption_rows("F", "age_state_sharing", "Ages 1-7 separate; age 8 shares the age-7 F state", config_url),
  assumption_rows("F", "Fbar_ages", "3-6", config_url,
    "The fitted configuration and ICES report both specify ages 3-6."),
  assumption_rows("M", "natural_mortality", "Fixed age-specific M, constant over years", model_url,
    "The fitted model input surface is retained in inputs.csv."),
  assumption_rows("catch", "discard_survival", "0.4", taf_url,
    "The fitted catch is landings plus 60% of discards."),
  assumption_rows("catch", "observation_model", "Lognormal", config_url,
    "One observation variance group is shared across catch ages."),
  assumption_rows("catch", "observation_weighting", "No supplied observation weights", model_url,
    "The fitted data object has no finite observation weights; fixVarToWeight=0."),
  assumption_rows("index", "observation_model", "Lognormal, independent observation errors", config_url,
    "obsCorStruct=ID for each fleet."),
  assumption_rows("index", "q_age_sharing", "UK BTS-Q3 has separate q values at ages 1-7", config_url,
    "The fitted config disables density-dependent q.", survey = "UK BTS-Q3"),
  assumption_rows("index", "observation_variance_sharing", "One shared variance across ages", config_url,
    survey = "UK BTS-Q3"),
  assumption_rows("index", "sampling_time", "0.8", model_url,
    "The fitted SAM model value is retained; the survey is the UK beam-trawl Q3 index.",
    survey = "UK BTS-Q3", season = "Q3"),
  assumption_rows("index", "index_treatment", "SSB biomass index", config_url,
    "keyBiomassTreat=0; aggregate values are kept at the native kg per 3 miles scale.",
    survey = c("NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4")),
  assumption_rows("index", "sampling_time", "0", model_url,
    "The fitted SAM data object sets sampleTimes=0 for these aggregate SSB indices.",
    survey = c("NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4"),
    season = c("Q1", "Q4")),
  assumption_rows("index", "observation_variance_sharing", "One variance per aggregate survey", config_url,
    survey = c("NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4"),
    season = c("Q1", "Q4")),
  assumption_rows("biology", "maturity", "Fixed age-specific maturity ogive", model_url),
  assumption_rows("biology", "stock_weight", "Effective stock weight equals discard-adjusted catch weight", taf_url,
    "The TAF data script replaces the original stock weight input after the discard-survival adjustment."),
  assumption_rows("biology", "spawning_time", "propF=0 and propM=0", model_url,
    "No fishing or natural mortality is applied before spawning."),
  assumption_rows("outputs", "fitted_population_and_F", "N-at-age and F-at-age, years 1981-2025, ages 1-8+", model_url,
    "The native fitted object is available; total abundance is derived by summing N-at-age."),
  assumption_rows("outputs", "aggregate_metrics", "Recruitment, SSB, Fbar ages 3-6, TSB, and dead catch", report_url,
    "Fitted series and approximate uncertainty are available in the native model object; 2026 recruitment and SSB forecasts are retained from SAG.")
))

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L,
  estimate_terminal_year = 2026L, assessment_type = "annual_assessment",
  model_family = "SAM", model_version = "SAM; package version not pinned",
  is_current = TRUE, is_applied = TRUE, framework_year = 2017L,
  assessment_url = report_url, framework_url = framework_url,
  data_url = sag_url, model_url = model_base, repository_url = taf_url,
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "complete",
  notes = paste(
    "Official 2026 ICES assessment fitted through 2025.",
    "The native fitted SAM object is recovered from the public archive.",
    "Its embedded input data are the post-discard-survival values used by the fit;",
    "the separate run/data.RData object is pre-adjustment and is retained to verify the TAF transformation.",
    "Age-specific N/F and aggregate fitted outputs are extracted from the official fit;",
    "2026 recruitment and SSB are forecasts from SAG."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")
stocks <- read_table(stocks_path)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L ||
  any(read_table(assessments_path)$stock_id == stock_id)) {
  stop("Expected one unpopulated Charbonneau-Keith stock row.", call. = FALSE)
}
stocks$authority_stock_id[stock_row] <- "ple.27.7a"
stocks$common_name[stock_row] <- "Irish Sea plaice"
stocks$area[stock_row] <- "ICES Division 7.a"
stocks$region[stock_row] <- "Irish Sea"
stocks$notes[stock_row] <- paste(
  "Matched to the official ICES 2026 assessment for stock ple.27.7a.",
  "Charbonneau-Keith Master identifier is retained as a catalogue crosswalk, not evidence of assessment coverage."
)
utils::write.csv(stocks, stocks_path, row.names = FALSE, na = "")
append_rows(assessments_path, assessment)
append_rows(assumptions_path, assumptions)
append_rows(inputs_path, inputs)
append_rows(outputs_path, outputs)

cat("Imported", assessment_id, "with", nrow(inputs), "input rows and",
  nrow(outputs), "output rows.\n")
