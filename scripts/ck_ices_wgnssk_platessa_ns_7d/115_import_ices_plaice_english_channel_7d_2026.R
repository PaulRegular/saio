assessment_id <- "ices_plaice_english_channel_7d_2026"
stock_id <- "ck_ices_wgnssk_platessa_ns_7d"
root <- "."
cache <- file.path(root, "source_cache", "ices_plaice_7d_2026")
database <- file.path(root, "database")
model_base <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.7d_2026"
model_ref <- paste0(model_base, "/run/data.RData")
config_ref <- paste0(model_base, "/conf/model.cfg")
advice_url <- "https://doi.org/10.17895/ices.advice.30932276"
framework_url <- "https://doi.org/10.17895/ices.pub.28715180"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22484"
sag_xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22484"
sam_commit <- "1cc464b80f6f2a4a38b35cce276f13e521761da3"

required_files <- file.path(cache, c(
  "run/data.RData", "conf/model.cfg", "conf/locked.ver",
  "data/cn.dat", "data/cw.dat", "data/dw.dat", "data/lw.dat",
  "data/mo.dat", "data/nm.dat", "data/pf.dat", "data/pm.dat",
  "data/lf.dat", "data/sw.dat", "data/survey.dat",
  "ices_sag_2026_key_22484.xml"
))
if (any(!file.exists(required_files))) {
  stop("Cache the official ICES SAM inputs and SAG XML before importing.", call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
assumptions_path <- file.path(database, "assumptions.csv")
inputs_path <- file.path(database, "inputs.csv")
outputs_path <- file.path(database, "outputs.csv")

read_table <- function(path) {
  utils::read.csv(path, colClasses = "character", na.strings = "",
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

append_rows <- function(path, rows, id_column = "assessment_id", id_value = assessment_id) {
  existing <- read_table(path)
  if (!identical(names(existing), names(rows))) {
    stop("Unexpected columns in ", basename(path), call. = FALSE)
  }
  if (any(existing[[id_column]] == id_value, na.rm = TRUE)) {
    stop("Rows already exist for ", id_value, " in ", basename(path), call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = ""
  )
}

load(file.path(cache, "run/data.RData"))
if (!exists("dat") || !is.matrix(dat$aux) || !all(c("year", "fleet", "age") %in% colnames(dat$aux))) {
  stop("The cached SAM data object is missing its observation index.", call. = FALSE)
}
years <- as.integer(dat$years)
ages <- seq.int(dat$minAgePerFleet[[1L]], dat$maxAgePerFleet[[1L]])
config_text <- paste(readLines(file.path(cache, "conf/model.cfg"), warn = FALSE),
  collapse = "\n"
)
if (!identical(years, 1980:2025) || !identical(ages, 1:7) ||
  !grepl("(?s)\\$maxAgePlusGroup.*?\\n\\s*1\\s+0\\s+0", config_text, perl = TRUE)) {
  stop("Unexpected years, ages, or plus-group flags in the native SAM data.", call. = FALSE)
}

input_header <- names(read_table(inputs_path))
output_header <- names(read_table(outputs_path))
assumption_header <- names(read_table(assumptions_path))

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = NA_character_, survey = NA_character_,
                       sampling_time = NA_real_, source_reference,
                       transformation = "Copied from the official SAM input object.",
                       notes = "", year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
                       source_type = "native_model") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(input_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- input_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- basis
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$year <- as.character(rep_len(year, n))
  out$year_basis <- as.character(rep_len(year_basis, n))
  out$age <- as.character(rep_len(age, n))
  out$value <- as.character(value)
  out$unit <- unit
  out$sampling_time <- as.character(rep_len(sampling_time, n))
  out$source_type <- source_type
  out$source_reference <- source_reference
  out$transformation <- transformation
  out$notes <- notes
  out
}

surface_rows <- function(surface, type, measure, basis, unit, source_file,
                         annual = TRUE, notes = "") {
  surface <- as.matrix(surface)
  if (ncol(surface) != length(ages)) stop("Unexpected age dimension in ", source_file)
  if (annual) {
    if (nrow(surface) != length(years)) stop("Unexpected year dimension in ", source_file)
    grid <- expand.grid(year = years, age = ages)
    input_rows(type, measure, basis, grid$year, grid$age, as.vector(surface), unit,
      source_reference = paste0(model_base, "/data/", source_file), notes = notes
    )
  } else {
    if (nrow(surface) != length(years) ||
      max(abs(sweep(surface, 2L, surface[1L, ], `-`)), na.rm = TRUE) > 1e-12) {
      stop("Expected a time-invariant source surface in ", source_file)
    }
    input_rows(type, measure, basis, NA_integer_, ages, surface[1L, ], unit,
      source_reference = paste0(model_base, "/data/", source_file),
      notes = paste(notes, "The source SAM object repeats this age surface by year; stored once."),
      year_basis = NA_character_
    )
  }
}

observation <- data.frame(
  year = dat$aux[, "year"], fleet = dat$aux[, "fleet"], age = dat$aux[, "age"],
  value = exp(dat$logobs)
)
catch <- observation[observation$fleet == 1L, , drop = FALSE]
uk_bts <- observation[observation$fleet == 2L & is.finite(observation$value), , drop = FALSE]
fr_gfs <- observation[observation$fleet == 3L & is.finite(observation$value), , drop = FALSE]
if (nrow(catch) != 322L || nrow(uk_bts) != 216L || nrow(fr_gfs) != 215L) {
  stop("Unexpected observation counts in the SAM data object.", call. = FALSE)
}

inputs <- rbind(
  input_rows("catch", "numbers_at_age", "numbers", catch$year, catch$age,
    catch$value, "thousand fish", fleet = "Residual catch",
    source_reference = paste0(model_base, "/data/cn.dat; ", model_ref),
    transformation = "Exponentiated the natural-log residual catch values in the native SAM data object.",
    notes = "The cn.dat heading is mislabeled as landings weight. The SAM data object identifies this as fleet 1 residual catch; catch numbers multiplied by catch weights reproduce ICES total catches to rounding."
  ),
  input_rows("index", "numbers_at_age", "index_scale", uk_bts$year, uk_bts$age,
    uk_bts$value, "survey index (unit unresolved)", survey = "UK BTS",
    sampling_time = dat$sampleTimes[[2L]],
    source_reference = paste0(model_base, "/data/survey.dat; ", model_ref),
    transformation = "Exponentiated natural-log UK BTS observations in the native SAM data object.",
    notes = "Age-specific index scale multiplier is not stated. The six missing age-year cells in 2022 are preserved as absent values."
  ),
  input_rows("index", "numbers_at_age", "index_scale", fr_gfs$year, fr_gfs$age,
    fr_gfs$value, "survey index (unit unresolved)", survey = "FR GFS",
    sampling_time = dat$sampleTimes[[3L]],
    source_reference = paste0(model_base, "/data/survey.dat; ", model_ref),
    transformation = "Exponentiated natural-log FR GFS observations in the native SAM data object.",
    notes = "Age-specific index scale multiplier is not stated. The missing age-5 value in 1998 is preserved as absent."
  ),
  surface_rows(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish", "kg per fish", "sw.dat",
    notes = "Annual stock weight-at-age; the benchmark describes these as Q2 landings weights."),
  surface_rows(dat$catchMeanWeight[, , 1L], "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "cw.dat"),
  surface_rows(dat$landMeanWeight[, , 1L], "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "lw.dat"),
  surface_rows(dat$disMeanWeight[, , 1L], "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "dw.dat"),
  surface_rows(dat$propMat, "maturity", "maturity_at_age", "proportion", "proportion", "mo.dat",
    annual = FALSE, notes = "Histology-based maturity ogive adopted at WKBNSCS 2025."),
  surface_rows(dat$natMor, "M", "natural_mortality_at_age", "per_year", "per year", "nm.dat",
    annual = FALSE, notes = "Fixed age-specific M; the native config sets mortalityModel=0."),
  surface_rows(dat$landFrac[, , 1L], "catch", "landings_fraction_at_age", "proportion", "proportion", "lf.dat",
    annual = FALSE, notes = "Native SAM field is 1 at every age; this is not interpreted as the observed landings-to-catch ratio."),
  surface_rows(dat$propF[, , 1L], "biology", "fraction_F_before_spawning", "proportion", "proportion", "pf.dat",
    annual = FALSE, notes = "No fishing mortality is applied before spawning."),
  surface_rows(dat$propM, "biology", "fraction_M_before_spawning", "proportion", "proportion", "pm.dat",
    annual = FALSE, notes = "No natural mortality is applied before spawning.")
)

xml <- paste(readLines(file.path(cache, "ices_sag_2026_key_22484.xml"),
  warn = FALSE, encoding = "UTF-8"), collapse = "\n"
)
blocks <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
if (!length(blocks)) stop("No Fish_Data records in ICES SAG XML.")
field <- function(node, tag) {
  match <- regmatches(node, regexec(paste0("(?s)<", tag, ">(.*?)</", tag, ">"), node, perl = TRUE))[[1L]]
  if (length(match) < 2L || !nzchar(match[[2L]])) return(NA_real_)
  suppressWarnings(as.numeric(match[[2L]]))
}
tags <- c(
  "Year", "Recruitment", "Low_Recruitment", "High_Recruitment",
  "StockSize", "Low_StockSize", "High_StockSize",
  "FishingPressure", "Low_FishingPressure", "High_FishingPressure",
  "Catches", "Landings", "Discards"
)
sag <- as.data.frame(do.call(rbind, lapply(blocks, function(node) {
  as.list(vapply(tags, function(tag) field(node, tag), numeric(1)))
})))
names(sag) <- c("year", "recruitment", "recruitment_lwr", "recruitment_upr",
  "SSB", "SSB_lwr", "SSB_upr", "Fbar", "Fbar_lwr", "Fbar_upr",
  "catches", "landings", "discards")
sag[] <- lapply(sag, function(x) suppressWarnings(as.numeric(as.character(x))))
sag$year <- as.integer(sag$year)
sag$catch <- sag$catches
missing_catches <- is.na(sag$catch)
sag$catch[missing_catches] <- with(sag, landings + discards)[missing_catches]
historical <- sag[sag$year %in% years, , drop = FALSE]
if (!identical(sort(historical$year), years) || anyNA(historical$SSB) ||
  anyNA(historical$recruitment) || anyNA(historical$Fbar)) {
  stop("Unexpected historical year or output coverage in ICES SAG XML.")
}
catch_weight <- dat$catchMeanWeight[, , 1L]
catch_tonnes <- tapply(catch$value * catch_weight[cbind(
  match(catch$year, years), catch$age
)], catch$year, sum)
catch_diff <- abs(catch_tonnes[as.character(historical$year)] - historical$catch) /
  pmax(1, historical$catch)
if (anyNA(historical$catch) || max(catch_diff, na.rm = TRUE) > 0.01) {
  stop("Native catch numbers and weights do not reproduce SAG catches (landings plus discards) within 1%.")
}

output_rows <- function(type, measure, year, age = NA_integer_, age_group = NA_character_,
                        value, lwr = NA_real_, upr = NA_real_, unit,
                        source_reference = sag_url, notes = "") {
  n <- length(value)
  out <- as.data.frame(matrix(NA_character_, nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_header
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- as.character(year)
  out$age <- as.character(rep_len(age, n))
  out$age_group <- as.character(rep_len(age_group, n))
  out$value <- as.character(value)
  out$lwr <- as.character(rep_len(lwr, n))
  out$upr <- as.character(rep_len(upr, n))
  out$unit <- unit
  out$source_type <- "official_machine_readable"
  out$source_reference <- source_reference
  out$notes <- notes
  out[!is.na(value), , drop = FALSE]
}

output_note <- "ICES SAG annual output; published 2.5th and 97.5th percentiles retained as the 95% interval."
forecast_note <- paste(output_note, "2026 is the advice forecast; fitted historical terminal year is 2025.")
outputs <- rbind(
  output_rows("recruitment", "recruitment", sag$year, age = 1L,
    value = sag$recruitment, lwr = sag$recruitment_lwr, upr = sag$recruitment_upr,
    unit = "thousand fish", notes = ifelse(sag$year > max(years), forecast_note, output_note)),
  output_rows("biomass", "SSB", sag$year,
    value = sag$SSB, lwr = sag$SSB_lwr, upr = sag$SSB_upr,
    unit = "tonnes", notes = ifelse(sag$year > max(years), forecast_note, output_note)),
  output_rows("mortality", "Fbar", sag$year, age_group = "3-6",
    value = sag$Fbar, lwr = sag$Fbar_lwr, upr = sag$Fbar_upr,
    unit = "per year", notes = paste(output_note, "ICES SAG defines Fbar as ages 3-6."))
)

assumption_rows <- function(component, setting, value, source_reference = config_ref,
                            notes = "", survey = NA_character_, fleet = NA_character_) {
  out <- as.data.frame(matrix(NA_character_, nrow = 1L, ncol = length(assumption_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- assumption_header
  out$assessment_id <- assessment_id
  out$component <- component
  out$fleet <- fleet
  out$survey <- survey
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}

assumptions <- do.call(rbind, list(
  assumption_rows("assessment", "assessment_type", "ICES 2026 advice assessment"),
  assumption_rows("assessment", "stock_code", "ple.27.7d", sag_url),
  assumption_rows("assessment", "assessment_year", "2026", sag_url),
  assumption_rows("assessment", "sam_package", "stockassessment 0.12.0", paste0("https://github.com/fishfollower/SAM/tree/", sam_commit, "/stockassessment"), paste("Configuration locks RemoteSha", sam_commit, "but no fitted model object was recovered.")),
  assumption_rows("population", "model_years", "1980-2025", model_ref),
  assumption_rows("population", "model_ages", "1-7", config_ref, "Age 7 is the plus group."),
  assumption_rows("population", "recruitment_age", "1", config_ref),
  assumption_rows("population", "stock_recruitment_model", "Random walk", config_ref, "stockRecruitmentModelCode=0."),
  assumption_rows("population", "N_process_variance_sharing", "Age 1 separate; ages 2-7 shared", config_ref, "keyVarLogN=0,1,1,1,1,1,1."),
  assumption_rows("F", "process", "Random walk through time; AR(1) correlation among age increments", config_ref, "corFlag=2; ages 1-5 have distinct states and ages 6-7 share a state."),
  assumption_rows("F", "process_variance_sharing", "One shared F process variance", config_ref, "keyVarF uses one variance group across fitted ages."),
  assumption_rows("F", "Fbar_ages", "3-6", sag_url, "ICES SAG metadata specifies ages 3-6. The archived model.cfg uses fbarRange=3 7 and the local pinned-package refit reports Fbar(3-7); the native configuration and published reporting definition differ."),
  assumption_rows("M", "natural_mortality", "Fixed age-specific M", paste0(model_base, "/data/nm.dat"), "mortalityModel=0; see natural_mortality_at_age inputs."),
  assumption_rows("catch", "observation_model", "Lognormal", config_ref, "One observation variance group is shared across catch ages."),
  assumption_rows("catch", "fleet", "Single aggregate residual catch stream", paste0(model_base, "/data/cn.dat"), "Recreational catches are not included; the benchmark describes Q1 mature-plaice catch allocation among 7d, 4, and 7e."),
  assumption_rows("index", "observation_model", "Lognormal age-specific indices", config_ref, "Observation correlation is ID within each survey."),
  assumption_rows("index", "observation_variance_sharing", "One shared variance per survey across ages", config_ref, "keyVarObs has one variance group for each survey fleet.", survey = "UK BTS"),
  assumption_rows("index", "observation_variance_sharing", "One shared variance per survey across ages", config_ref, "keyVarObs has one variance group for each survey fleet.", survey = "FR GFS"),
  assumption_rows("index", "catchability_age_sharing", "Separate q at ages 1-4; ages 5-6 share q", config_ref, "keyLogFpar has five q groups per survey; keyQpow disables density-dependent q.", survey = "UK BTS"),
  assumption_rows("index", "catchability_age_sharing", "Separate q at ages 1-4; ages 5-6 share q", config_ref, "keyLogFpar has five q groups per survey; keyQpow disables density-dependent q.", survey = "FR GFS"),
  assumption_rows("index", "sampling_time", as.character(dat$sampleTimes[[2L]]), paste0(model_ref, "; fit$data$sampleTimes"), "Fraction of model year; midpoint of Q3.", survey = "UK BTS"),
  assumption_rows("index", "sampling_time", as.character(dat$sampleTimes[[3L]]), paste0(model_ref, "; fit$data$sampleTimes"), "Fraction of model year; midpoint of Q4.", survey = "FR GFS"),
  assumption_rows("biology", "maturity_ogive", paste(dat$propMat[1L, ], collapse = ", "), paste0(framework_url, "; Table 1.3; ", model_base, "/data/mo.dat"), "Constant histology-based ogive adopted at WKBNSCS 2025."),
  assumption_rows("biology", "stock_weight_definition", "Q2 landings weight at age", paste0(framework_url, "; section 1.4.1.2; ", model_base, "/data/sw.dat"), "Annual surface retained as supplied."),
  assumption_rows("biology", "spawning_timing", "Start of year; propF=0 and propM=0", paste0(model_base, "/data/pf.dat; ", model_base, "/data/pm.dat"), "No mortality is applied before spawning."),
  assumption_rows("outputs", "published_metrics", "Recruitment age 1; SSB; Fbar ages 3-6", sag_url, "No N-at-age or F-at-age surface is published in the SAG source data."),
  assumption_rows("outputs", "unavailable_metrics", "N-at-age; F-at-age; total abundance", model_ref, "The public fitted model.RData was not available. The local refit of the locked package did not reproduce SAG aggregate outputs, so its state estimates are not imported as official outputs.")
))

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2026L,
  terminal_year = 2025L, estimate_terminal_year = 2026L,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = paste0("stockassessment 0.12.0 (", sam_commit, ")"),
  is_current = TRUE, is_applied = TRUE, framework_year = 2025L,
  assessment_url = advice_url, framework_url = framework_url,
  data_url = sag_url, model_url = model_base,
  repository_url = paste0("https://github.com/fishfollower/SAM/tree/", sam_commit, "/stockassessment"),
  assumptions_status = "complete", inputs_status = "complete", outputs_status = "partial",
  notes = "Official 2026 ICES advice assessment fitted through 2025 with 2026 forecast outputs. Inputs/configuration are recovered from the public SAM archive. SAG supplies aggregate recruitment, SSB and Fbar, but no age-specific N/F or fitted object; local reproduction did not match the SAG estimates, so no reconstructed states are recorded as official.",
  stringsAsFactors = FALSE, check.names = FALSE
)

stocks <- read_table(stocks_path)
stock_row <- which(stocks$stock_id == stock_id)
if (length(stock_row) != 1L) stop("Expected one existing Charbonneau-Keith stock row.")
stocks$authority_stock_id[stock_row] <- "ple.27.7d"
stocks$common_name[stock_row] <- "Eastern English Channel plaice"
stocks$area[stock_row] <- "ICES Division 7.d"
stocks$region[stock_row] <- "Eastern English Channel"
stocks$notes[stock_row] <- paste(
  "Matched to the 2026 official ICES assessment for stock ple.27.7d.",
  "Charbonneau-Keith Master identifier retained as a catalogue crosswalk; it did not establish assessment status.",
  "Previous catalogue area label retained in source review."
)
utils::write.csv(stocks, stocks_path, row.names = FALSE, na = "")

append_rows(assessments_path, assessment)
append_rows(assumptions_path, assumptions)
append_rows(inputs_path, inputs)
append_rows(outputs_path, outputs)

cat("Imported", assessment_id, "with", nrow(inputs), "input rows,",
  nrow(assumptions), "assumptions, and", nrow(outputs), "official output rows.\n")
