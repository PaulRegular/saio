assessment_id <- "ices_cod_west_scotland_2022"
stock_id <- "ck_ices_wgcse_morhua_ns6a"
base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_wgcse_morhua_ns6a_2022")
run_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/cod.27.6a_2022"
framework_url <- "https://doi.org/10.17895/ices.pub.5548"

required <- c("run/model.RData", "run/data.RData", "data/cn.dat",
  "data/survey.dat", "data/cod6a_survey_variances.txt", "conf/model.cfg",
  "src/datascript.R", "ices_sag_17399.xml", "05_Section_3_Cod_6a_2022.pdf",
  "WKDEM_2020.pdf", "manifest.csv")
if (!all(file.exists(file.path(cache, required)))) {
  cli::cli_abort("Cache the reviewed West of Scotland cod sources before importing.")
}
manifest <- read.csv(file.path(cache, "manifest.csv"), stringsAsFactors = FALSE)
for (file in setdiff(required, "manifest.csv")) {
  path <- file.path(cache, file)
  row <- manifest[manifest$file == file, , drop = FALSE]
  checksum <- digest::digest(readBin(path, "raw", n = file.info(path)$size),
    algo = "sha256", serialize = FALSE)
  if (nrow(row) != 1L || row$sha256 != checksum) {
    cli::cli_abort("Source checksum mismatch for {.file {file}}.")
  }
}
read_db <- function(file) read.csv(file.path(database, file),
  colClasses = "character", na.strings = "", check.names = FALSE)
schemas <- lapply(c("stocks", "assessments", "assumptions", "inputs", "outputs"),
  function(name) names(read.csv(file.path(database, paste0(name, ".csv")), nrows = 0)))
names(schemas) <- c("stocks", "assessments", "assumptions", "inputs", "outputs")
rows <- function(table, n) {
  x <- as.data.frame(matrix("", n, length(schemas[[table]])), stringsAsFactors = FALSE)
  names(x) <- schemas[[table]]
  if ("assessment_id" %in% names(x)) x$assessment_id <- assessment_id
  x
}
number <- function(x) ifelse(is.finite(x),
  format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
model <- new.env(parent = baseenv())
load(file.path(cache, "run/model.RData"), model)
fit <- model$fit
raw <- new.env(parent = baseenv())
load(file.path(cache, "run/data.RData"), raw)
dat <- fit$data
years <- 1981:2021
ages <- 1:7
fleets <- attr(dat, "fleetNames")
aux <- as.data.frame(dat$aux)
names(aux) <- c("year", "fleet", "age")
cfg <- paste0(run_url, "/conf/model.cfg; fit$conf")
data_ref <- paste0(run_url, "/run/data.RData; dat")
model_ref <- paste0(run_url, "/run/model.RData; fit")

if (!inherits(fit, "sam") || !identical(as.integer(dat$years), years) ||
  !identical(fleets, c("Residual catch", "WCIBTS.Q1", "IRGFS.Q4", "WCIBTS.Q4", "SCO.Q1", "SCO.Q4")) ||
  !identical(as.integer(fit$conf$maxAgePlusGroup), c(1L, rep(0L, 5L))) ||
  !identical(as.integer(fit$conf$keyLogFsta[1, ]), c(0:2, rep(3L, 4L))) ||
  !identical(as.integer(fit$conf$keyVarLogN), c(0L, rep(1L, 6L))) ||
  !identical(as.integer(fit$conf$keyScaledYears), 1995:2006) ||
  !identical(as.integer(fit$conf$fbarRange), c(2L, 5L)) ||
  fit$conf$corFlag != 2 || fit$conf$stockRecruitmentModelCode != 0 ||
  fit$conf$fixVarToWeight != 0 || any(fit$conf$keyQpow != -1) ||
  any(as.character(fit$conf$obsCorStruct) != "ID") ||
  any(as.character(fit$conf$obsLikelihoodFlag) != "LN") ||
  !identical(attr(fit, "RemoteSha"), "ec2c2a0c6dde") ||
  fit$opt$convergence != 0 || !isTRUE(fit$sdrep$pdHess)) {
  cli::cli_abort("The cached fit is not the reviewed 2022 production run.")
}
for (name in c("years", "aux", "logobs", "weight", "stockMeanWeight",
  "catchMeanWeight", "natMor", "propMat")) {
  if (!isTRUE(all.equal(dat[[name]], raw$dat[[name]]))) {
    cli::cli_abort("Native input and fitted data disagree in {name}.")
  }
}
# Confirm the run against all published annual SSB, F and recruitment values.
xml <- xml2::read_xml(file.path(cache, "ices_sag_17399.xml"))
sag <- xml2::xml_find_all(xml, ".//Fish_Data")
sag_value <- function(name) as.numeric(xml2::xml_text(xml2::xml_find_first(sag, name)))
iy <- match(years, sag_value("Year"))
for (pair in list(c("logssb", "StockSize", "0.51"),
  c("logR", "Recruitment", "0.51"), c("logfbar", "FishingPressure", "0.00051"))) {
  estimate <- exp(fit$sdrep$value[names(fit$sdrep$value) == pair[1]])
  official <- sag_value(pair[2])[iy]
  if (length(estimate) != length(years) || anyNA(official) ||
    max(abs(estimate - official)) > as.numeric(pair[3])) {
    cli::cli_abort("The selected SAM run does not match published {pair[2]}.")
  }
}

input <- function(type, measure, basis, value, unit, year = NA, age = NA,
                  fleet = "", survey = "", time = NA, reference = data_ref,
                  transformation = "", notes = "") {
  n <- length(value)
  out <- rows("inputs", n)
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$value <- number(value); out$unit <- unit
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$fleet <- fleet; out$survey <- survey; out$sampling_time <- number(rep_len(time, n))
  out$source_type <- "native_model"; out$source_reference <- reference
  out$transformation <- transformation; out$notes <- notes
  out
}
catch <- stockassessment::read.ices(file.path(cache, "data/cn.dat"))
grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
stopifnot(identical(dim(catch), c(41L, 7L)),
  identical(as.integer(rownames(catch)), years), identical(as.integer(colnames(catch)), ages))
inputs <- input("catch", "numbers_at_age", "numbers", as.vector(catch),
  "thousand fish", grid$year, grid$age, fleet = fleets[1],
  reference = paste0(run_url, "/data/cn.dat; WGCSE 2022 Table 3.7"),
  notes = "Original residual catch, including landings and discards; age 7 is the plus group. Missing 2021 ages 1 and 2 remain missing; no fitted catch-scaling factors are applied.")

surveys <- stockassessment::read.ices(file.path(cache, "data/survey.dat"))
names(surveys) <- trimws(names(surveys))
for (i in seq_along(surveys)) {
  survey <- names(surveys)[i]
  x <- surveys[[i]]
  g <- expand.grid(year = as.integer(rownames(x)), age = as.integer(colnames(x)), KEEP.OUT.ATTRS = FALSE)
  unit <- if (survey == "IRGFS.Q4") "fish per minute" else "fish per hour"
  inputs <- rbind(inputs, input("index", "numbers_at_age", "numbers", as.vector(x),
    unit, g$year, g$age, survey = survey, time = dat$sampleTimes[i + 1L],
    reference = paste0(run_url, "/data/survey.dat; WGCSE 2022 Table 3.11"),
    transformation = "stockassessment::read.ices(): source numbers divided by the source effort column.",
    notes = if (survey == "IRGFS.Q4") "Irish survey numbers divided by minutes towed." else
      "Scottish source numbers standardised per ten hours and divided by effort=10; the model fits fish per hour."))
}
variances <- getFromNamespace("read.surveys", "stockassessment")(
  file.path(cache, "data/cod6a_survey_variances.txt"))
names(variances) <- trimws(names(variances))
for (survey in names(variances)) {
  x <- variances[[survey]]
  g <- expand.grid(year = as.integer(rownames(x)), age = as.integer(colnames(x)), KEEP.OUT.ATTRS = FALSE)
  expected_weight <- as.vector(surveys[[survey]]^2 / x)
  at <- match(paste(g$year, g$age, survey),
    paste(aux$year, aux$age, fleets[aux$fleet]))
  actual_weight <- dat$weight[at]
  finite <- is.finite(expected_weight)
  if (anyNA(at) || !identical(finite, is.finite(actual_weight)) ||
    !isTRUE(all.equal(expected_weight[finite], actual_weight[finite], tolerance = 1e-12))) {
    cli::cli_abort("Supplied variances do not reproduce the native {survey} precision weights.")
  }
  inputs <- rbind(inputs, input("index", "index_sd", "numbers", sqrt(as.vector(x)),
    "fish per hour", g$year, g$age, survey = survey,
    reference = paste0(run_url, "/data/cod6a_survey_variances.txt; src/datascript.R"),
    transformation = "Square root of supplied index variance, on the survey rate scale read by the native data script.",
    notes = "Used to construct relative precision as index squared / variance, not to fix the observation variance. Missing values remain missing."))
}
# Match each original observation to the fitted year-age-fleet map, including missing slots.
obs <- inputs[inputs$measure == "numbers_at_age", ]
key <- function(year, age, stream) paste(year, age, stream, sep = "\r")
at <- match(key(aux$year, aux$age, fleets[aux$fleet]),
  key(obs$year, obs$age, ifelse(obs$type == "catch", obs$fleet, obs$survey)))
values <- as.numeric(obs$value[at])
keep <- is.finite(dat$logobs)
if (anyNA(at) || !isTRUE(all.equal(values[keep], exp(dat$logobs[keep]), tolerance = 1e-12)) ||
  any(is.finite(values[!keep]) & values[!keep] > 0)) {
  cli::cli_abort("Imported observations do not match the native observation map.")
}
weighted <- which(is.finite(dat$weight))
inputs <- rbind(inputs, input(
  ifelse(aux$fleet[weighted] == 1, "catch", "index"), "relative_precision_weight",
  "relative_precision", dat$weight[weighted], "relative weight",
  aux$year[weighted], aux$age[weighted],
  fleet = ifelse(aux$fleet[weighted] == 1, fleets[1], ""),
  survey = ifelse(aux$fleet[weighted] == 1, "", fleets[aux$fleet[weighted]]),
  reference = paste0(run_url, "/src/datascript.R; dat$weight"),
  notes = "Native relative precision: 0.25 for catch from 2006; Scottish current-survey weights derive from index squared / supplied variance. NA native weights mean no relative adjustment; fixVarToWeight=0."))
surface <- function(slot, type, measure, basis, unit, notes) {
  x <- dat[[slot]]
  stopifnot(identical(dim(x), c(41L, 7L)), all(is.finite(x)))
  input(type, measure, basis, as.vector(x), unit, grid$year, grid$age,
    reference = paste0(data_ref, "$", slot), notes = notes)
}
inputs <- rbind(inputs,
  surface("stockMeanWeight", "weight", "weight_at_age", "kg_per_fish", "kg per fish", "Annual smoothed source stock weights; 2021 ages 1 and 2 use 2020 estimates as specified by WGCSE."),
  surface("catchMeanWeight", "catch_weight", "weight_at_age", "kg_per_fish", "kg per fish", "Annual source catch weights."),
  surface("landMeanWeight", "catch_weight", "landings_weight_at_age", "kg_per_fish", "kg per fish", "Source landings weights."),
  surface("disMeanWeight", "catch_weight", "discard_weight_at_age", "kg_per_fish", "kg per fish", "Source discard weights."),
  surface("natMor", "M", "natural_mortality_at_age", "per_year", "per year", "Fixed annual age-specific M derived from source smoothed weights using the Lorenzen relationship; not estimated by SAM."),
  surface("propMat", "maturity", "maturity_at_age", "proportion", "proportion", "Source maturity ogive repeated annually in the native inputs."),
  surface("landFrac", "catch", "landings_fraction_at_age", "proportion", "proportion", "Fraction of catch landed at age."),
  surface("propF", "biology", "fraction_F_before_spawning", "proportion", "proportion", "Source pre-spawning F fractions are zero."),
  surface("propM", "biology", "fraction_M_before_spawning", "proportion", "proportion", "Source pre-spawning M fractions are zero."))

assumption <- function(component, setting, value, notes = "", survey = "", reference = cfg) {
  out <- rows("assumptions", length(value))
  out$component <- component; out$setting <- setting; out$value <- value
  out$survey <- survey; out$source_reference <- reference; out$notes <- notes
  out
}
assumptions <- rbind(
  assumption("population", "years_and_ages", "1981-2021; ages 1-7+", "One combined-sex, combined-area population; no intermediate-year survey in 2022."),
  assumption("population", "recruitment_age", "1"),
  assumption("N", "recruitment_process", "Random walk", "stockRecruitmentModelCode=0; confirmed in WGCSE 2022 Section 3.4."),
  assumption("N", "process_variance_sharing", "Age 1 separate; ages 2-7 share one variance"),
  assumption("N", "initial_state", "Separate first-year latent N at every age; no first-year transition density",
    "The normal-fit N process begins with the second state column; the wide first-state prior in the source is used only for out-of-sample residual calculations.",
    reference = "https://github.com/fishfollower/SAM/blob/ec2c2a0c6dde/stockassessment/inst/include/n.hpp"),
  assumption("F", "age_state_sharing", "Ages 1, 2, 3 distinct; ages 4-7 share one F state"),
  assumption("F", "process", "Temporal random walk with AR(1) correlation across F age states", "corFlag=2; age 1 has separate process variance, older ages share one variance."),
  assumption("F", "Fbar_ages", "2-5", "Native arithmetic mean F."),
  assumption("M", "natural_mortality", "Fixed age-year Lorenzen M from smoothed stock weights", reference = data_ref),
  assumption("catch", "observation_model", "Independent lognormal catch-at-age", "Separate observation variances for age 1, ages 2-6, and age 7+. Missing/zero observations are not positive lognormal data."),
  assumption("catch", "relative_precision_weight", "0.25 from 2006 onwards; unweighted earlier", "Doubles fitted catch SD from 2006; source code obs.hpp uses SD / sqrt(weight) when fixVarToWeight=0.", reference = paste0(run_url, "/src/datascript.R")),
  assumption("catch", "catch_scaling", "One estimated catch-scaling parameter per year in 1995-2006, shared across ages", "predicted log catch = Baranov log catch - logScale; raw observations are not corrected using fitted parameters. Table 3.16 reports exp(logScale)."),
  assumption("index", "observation_model", "Independent lognormal survey indices", "One fitted observation variance per survey. Current Scottish series also use supplied relative-precision weights."),
  assumption("biology", "annual_inputs", "Stock/catch/landings/discard weights, M, maturity, landings fraction, spawning fractions", "All numerical native surfaces recovered; zero pre-spawning mortality fractions.", reference = data_ref),
  assumption("assessment", "stock_boundary", "Final standalone assessment before the 2023 Northern Shelf merger", "Do not count this historical assessment and the broader Northern Shelf stock as independent contemporary stocks.", reference = "https://doi.org/10.17895/ices.pub.22591423"))
for (i in 2:6) {
  key_text <- function(x) paste(paste0(ages[x >= 0], ":", x[x >= 0]), collapse = "; ")
  assumptions <- rbind(assumptions,
    assumption("index", "catchability_age_keys", key_text(fit$conf$keyLogFpar[i, ]),
      "Equal native keys mean shared log-q, distinct keys mean independent q; no power catchability.", fleets[i]),
    assumption("index", "survey_timing", number(dat$sampleTimes[i]),
      "Midpoint of the documented source survey window, as supplied to SAM.", fleets[i], data_ref))
}

output <- function(type, measure, value, unit, year = NA, age = NA,
                   se = NA, lwr = NA, upr = NA, fleet = "", survey = "",
                   group = "", reference = model_ref, notes = "", source_type = "native_model") {
  n <- length(value); out <- rows("outputs", n)
  out$type <- type; out$measure <- measure; out$value <- number(value); out$unit <- unit
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$age_group <- group; out$fleet <- fleet; out$survey <- survey
  out$se <- number(rep_len(se, n)); out$lwr <- number(rep_len(lwr, n)); out$upr <- number(rep_len(upr, n))
  out$source_type <- source_type; out$source_reference <- reference; out$notes <- notes
  out
}
z <- qnorm(0.975)
log_output <- function(type, measure, est, error, unit, ...) {
  output(type, measure, exp(est), unit, se = exp(est) * error,
    lwr = exp(est - z * error), upr = exp(est + z * error), ...)
}
uncertainty_note <- "Exponentiated native log estimate (median on the lognormal scale); approximate natural-scale delta-method SE and 95% log-scale Wald confidence limits."
state_sd <- function(name) {
  at <- which(names(fit$sdrep$par.random) == name)
  stopifnot(isTRUE(all.equal(unname(fit$sdrep$par.random[at]), as.vector(fit$pl[[name]]))),
    isTRUE(all.equal(sqrt(fit$sdrep$diag.cov.random[at]), as.vector(fit$plsd[[name]]))))
  fit$plsd[[name]]
}
N <- t(exp(fit$pl$logN))
fkey <- as.integer(fit$conf$keyLogFsta[1, ]) + 1L
F <- t(exp(fit$pl$logF[fkey, , drop = FALSE]))
outputs <- rbind(
  log_output("population", "numbers_at_age", as.vector(t(fit$pl$logN)),
    as.vector(t(state_sd("logN"))), "thousand fish", grid$year, grid$age,
    group = ifelse(grid$age == 7, "7+", ""), notes = uncertainty_note),
  log_output("mortality", "fishing_mortality_at_age", as.vector(t(fit$pl$logF[fkey, , drop = FALSE])),
    as.vector(t(state_sd("logF")[fkey, , drop = FALSE])), "per year", grid$year, grid$age,
    group = ifelse(grid$age == 7, "7+", ""), notes = uncertainty_note))
for (spec in list(c("logR", "recruitment", "recruitment", "thousand fish"),
  c("logssb", "biomass", "SSB", "tonnes"), c("logtsb", "biomass", "total_biomass", "tonnes"),
  c("logfbar", "mortality", "Fbar", "per year"), c("logCatch", "catch", "predicted_catch", "tonnes"))) {
  ix <- names(fit$sdrep$value) == spec[1]
  outputs <- rbind(outputs, log_output(spec[2], spec[3], fit$sdrep$value[ix],
    fit$sdrep$sd[ix], spec[4], year = years,
    age = if (spec[1] == "logR") 1 else NA,
    group = if (spec[1] == "logfbar") "2-5" else "",
    notes = paste(uncertainty_note, if (spec[1] == "logCatch")
      "Native total Baranov catch biomass before division by fitted catch-scaling factors." else "")))
}
for (i in 2:6) {
  active <- which(fit$conf$keyLogFpar[i, ] >= 0)
  key <- fit$conf$keyLogFpar[i, active] + 1L
  unit <- if (fleets[i] == "IRGFS.Q4") "fish per minute per thousand fish" else "fish per hour per thousand fish"
  outputs <- rbind(outputs, log_output("catchability", "q", fit$pl$logFpar[key],
    fit$plsd$logFpar[key], unit, age = ages[active], survey = fleets[i], notes = uncertainty_note))
}
ix <- which(names(fit$sdrep$par.fixed) == "logScale")
stopifnot(length(ix) == 12L, isTRUE(all.equal(unname(fit$sdrep$par.fixed[ix]), fit$pl$logScale)))
outputs <- rbind(outputs,
  log_output("catch", "catch_scaling_factor", fit$pl$logScale,
    sqrt(diag(fit$sdrep$cov.fixed)[ix]), "dimensionless", year = 1995:2006,
    fleet = fleets[1], notes = paste(uncertainty_note, "Baranov catch divided by this factor predicts recorded catch; not an input correction.")),
  output("population", "total_numbers", rowSums(N), "thousand fish", years,
    source_type = "derived_source_output", notes = "Sum of native N over ages 1-7+; uncertainty unavailable without the full joint covariance."))
pred <- exp(as.numeric(fit$rep$predObs))
for (i in 1:6) {
  at <- which(aux$fleet == i)
  unit <- if (i == 1) "thousand fish" else if (i == 3) "fish per minute" else "fish per hour"
  outputs <- rbind(outputs, output(if (i == 1) "catch" else "index",
    if (i == 1) "predicted_catch" else "predicted_index", pred[at], unit,
    aux$year[at], aux$age[at], fleet = if (i == 1) fleets[i] else "",
    survey = if (i > 1) fleets[i] else "", notes = if (i == 1)
      "Predicted recorded catch-at-age after dividing Baranov catch by the estimated annual scaling factor in 1995-2006. No prediction uncertainty supplied." else
      "Predicted survey rate on the native per-effort scale; no prediction uncertainty supplied."))
}
native <- function(name) exp(fit$sdrep$value[names(fit$sdrep$value) == name])
stopifnot(max(abs(rowSums(N * dat$stockMeanWeight * dat$propMat) - native("logssb"))) < 1e-6,
  max(abs(rowSums(N * dat$stockMeanWeight) - native("logtsb"))) < 1e-6,
  max(abs(rowMeans(F[, 2:5]) - native("logfbar"))) < 1e-8,
  max(abs(N[, 1] - native("logR"))) < 1e-8)

stocks <- read_db("stocks.csv")
at <- which(stocks$stock_id == stock_id)
stopifnot(length(at) == 1, stocks$charbonneau_id[at] == "ICES-WGCSE_morhua_NS6a")
stocks$authority_stock_id[at] <- "cod.27.6a"
stocks$common_name[at] <- "West of Scotland cod"
stocks$area[at] <- "ICES Division 6.a (West of Scotland)"
stocks$region[at] <- "West of Scotland"
stocks$ocean[at] <- "Northeast Atlantic"
stocks$notes[at] <- paste("Charbonneau-Keith ICES-WGCSE_morhua_NS6a; final standalone production assessment in 2022.",
  "Merged into Northern Shelf cod cod.27.46a7d20 in 2023; historical boundaries differ from the current combined assessment.")
assessment <- rows("assessments", 1)
assessment$stock_id <- stock_id; assessment$assessment_year <- "2022"
assessment$terminal_year <- assessment$estimate_terminal_year <- "2021"
assessment$assessment_type <- "annual"; assessment$model_family <- "SAM"
assessment$model_version <- paste("stockassessment", attr(fit, "Version"), "ec2c2a0c6dde")
assessment$is_current <- "TRUE"; assessment$is_applied <- "TRUE"; assessment$framework_year <- "2020"
assessment$assessment_url <- "https://doi.org/10.17895/ices.advice.19447889"
assessment$framework_url <- framework_url
assessment$data_url <- paste0(run_url, "/run/data.RData")
assessment$model_url <- paste0(run_url, "/run/model.RData")
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "complete"
assessment$notes <- paste("Final standalone 6.a assessment, not a new contemporary stock; 2023 Northern Shelf merger recorded in stock notes.",
  "Native 1981-2021 SSB, recruitment and F match the 2022 SAG advice series to reported rounding.",
  "All five survey series, annual biology, supplied precision weights and estimated 1995-2006 catch scaling retained.")

# Replace only this stock/assessment's lines; retain every other record byte-for-byte.
write_rows <- function(file, x, id = assessment_id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  stage <- tempfile(tmpdir = database)
  on.exit(unlink(stage), add = TRUE)
  write.table(x, stage, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(stage, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (length(selected) == nrow(x)) {
      lines[selected] <- paste0(replacement, ifelse(endsWith(lines[selected], "\r"), "\r", ""))
    } else {
      if (any(diff(selected) != 1L)) cli::cli_abort("Existing {file} rows are not contiguous; review before replacing.")
      lines <- append(lines[-selected], replacement, after = selected[1L] - 1L)
    }
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, stage)
  if (!file.copy(stage, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stocks[at, ], stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)
cat("Imported West of Scotland cod 2022:", nrow(inputs), "inputs,",
  nrow(assumptions), "assumptions,", nrow(outputs), "outputs.\n")
