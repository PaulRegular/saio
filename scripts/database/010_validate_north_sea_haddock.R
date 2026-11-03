root <- "database"
read <- function(name) {
  x <- read.csv(file.path(root, paste0(name, ".csv")), stringsAsFactors = FALSE)
  x <- x[x$assessment_id == "ices_haddock_north_sea_2026", ]
  x$value <- suppressWarnings(as.numeric(as.character(x$value)))
  x
}
inputs <- read("inputs")
outputs <- read("outputs")
stopifnot(nrow(inputs) == 6906, nrow(outputs) == 2373)
obs <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
sd <- inputs[inputs$measure == "log_index_sd", ]
key <- function(x) paste(x$survey, x$year, x$age)
stopifnot(nrow(obs) == 667, setequal(key(obs), key(sd)), all(sd$value > 0))
stopifnot(all(obs$sampling_time[obs$survey == "delta-GAMNS-WCQ1"] == .125))
stopifnot(all(obs$sampling_time[obs$survey == "delta-GAMNS-WCQ3+Q4"] == .75))
stopifnot(setequal(obs$age[obs$survey == "delta-GAMNS-WCQ1"], 1:8))
stopifnot(setequal(obs$age[obs$survey == "delta-GAMNS-WCQ3+Q4"], 0:8))
catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
stopifnot(nrow(catch) == 486, max(catch$year) == 2025)
f <- outputs[outputs$measure == "fishing_mortality_at_age", ]
fbar <- outputs[outputs$measure == "Fbar", ]
mean_f <- aggregate(value ~ year, f[f$age %in% 2:4, ], mean)
joined <- merge(fbar, mean_f, by = "year")
stopifnot(nrow(joined) == 54, all(abs(joined$value.x - joined$value.y) < 1e-12))
n <- outputs[outputs$measure == "numbers_at_age" & outputs$type == "population", ]
r <- outputs[outputs$measure == "recruitment", ]
joined <- merge(n[n$age == 0, ], r, by = "year")
stopifnot(nrow(joined) == 55, all(abs(joined$value.x - joined$value.y) < 1e-7))
ssb <- outputs[outputs$measure == "SSB" & outputs$year == 2026, ]
stopifnot(abs(ssb$value - 699809.6) < .1)
stopifnot(abs(ssb$value - 667758) > 30000)
interval <- outputs[!is.na(outputs$lwr), ]
stopifnot(all(interval$lwr <= interval$value), all(interval$value <= interval$upr))
cat("Haddock survey weights, SD pairing, age surfaces and forecast separation passed.\n")

for (measure in c("fraction_F_before_spawning", "fraction_M_before_spawning")) {
  x <- inputs[inputs$measure == measure, ]
  stopifnot(
    nrow(x) == 495, all(x$value == 0),
    setequal(x$year, 1972:2026), setequal(x$age, 0:8)
  )
  native <- read.csv(file.path(
    "source_cache/ices_haddock_north_sea_2026",
    if (measure == "fraction_F_before_spawning") "native_propF.csv" else "native_propM.csv"
  ))
  joined <- merge(x, native, by = c("year", "age"))
  stopifnot(nrow(joined) == 495, all(joined$value.x == joined$value.y))
}
cat("Both native spawning-fraction matrices verified.\n")

q <- outputs[outputs$type == "catchability", ]
stopifnot(
  nrow(q) == 20, all(is.na(q$year)), all(q$se > 0),
  all(q$lwr < q$value), all(q$upr > q$value)
)
power <- q[q$measure == "q_power", ]
stopifnot(
  nrow(power) == 3,
  setequal(paste(power$survey, power$age), c("delta-GAMNS-WCQ1 1", "delta-GAMNS-WCQ3+Q4 0", "delta-GAMNS-WCQ3+Q4 1"))
)
native_q <- read.csv("source_cache/ices_haddock_north_sea_2026/native_catchability.csv")
joined <- merge(q, native_q, by = c("measure", "survey", "age"))
stopifnot(
  nrow(joined) == 20, all(abs(joined$value.x - exp(joined$log_estimate)) < 1e-10),
  all(abs(joined$se.x - joined$value.x * joined$log_se) < 1e-10)
)
cat("Catchability power mapping and uncertainty scales verified.\n")

model_env <- new.env()
load("source_cache/ices_haddock_north_sea_2026/run_model.RData", model_env)
stopifnot(
  model_env$fit$conf$initState == 0,
  length(model_env$fit$pl$initN) == 0, length(model_env$fit$pl$initF) == 0,
  all(c("logN", "logF") %in% names(model_env$fit$sdrep$par.random))
)
cat("Native initial-state configuration verified.\n")

fit <- model_env$fit
years <- as.integer(fit$data$years)
ages <- seq.int(min(fit$data$minAgePerFleet), max(fit$data$maxAgePerFleet))
n_state <- length(fit$pl$logN)
state_se_log <- sqrt(fit$sdrep$diag.cov.random)
state_interval <- function(log_state, se_log, state_years) {
  grid <- expand.grid(age = ages, year = state_years)
  estimate <- as.vector(log_state[, seq_along(state_years), drop = FALSE])
  se_log <- se_log[seq_along(estimate)]
  data.frame(
    year = grid$year,
    age = grid$age,
    value = exp(estimate),
    se = exp(estimate) * se_log,
    lwr = exp(estimate - qnorm(0.975) * se_log),
    upr = exp(estimate + qnorm(0.975) * se_log)
  )
}
check_state_interval <- function(measure, type, expected) {
  actual <- outputs[outputs$measure == measure & outputs$type == type, ]
  joined <- merge(expected, actual, by = c("year", "age"), suffixes = c("_expected", "_actual"))
  stopifnot(
    nrow(joined) == nrow(expected),
    !anyNA(joined$se_actual),
    max(abs(joined$value_expected - joined$value_actual) /
      pmax(1, joined$value_expected)) < 1e-10,
    max(abs(joined$se_expected - joined$se_actual) /
      pmax(1, joined$se_expected)) < 1e-10,
    max(abs(joined$lwr_expected - joined$lwr_actual) /
      pmax(1, joined$lwr_expected)) < 1e-10,
    max(abs(joined$upr_expected - joined$upr_actual) /
      pmax(1, joined$upr_expected)) < 1e-10,
    all(grepl("conditional on fitted fixed parameters", actual$notes, fixed = TRUE))
  )
}
check_state_interval(
  "numbers_at_age",
  "population",
  state_interval(fit$pl$logN, state_se_log[n_state + seq_len(n_state)], years)
)
check_state_interval(
  "fishing_mortality_at_age",
  "mortality",
  state_interval(fit$pl$logF, state_se_log[seq_len(n_state)], years[years <= max(years) - 1L])
)
cat("Conditional N/F state uncertainty and 95% intervals verified.\n")

precision <- inputs[inputs$type == "index" &
  inputs$measure == "relative_precision_weight", ]
stopifnot(
  nrow(precision) == 667L,
  setequal(key(precision), key(obs)),
  !anyDuplicated(key(precision)),
  all(precision$value > 0),
  all(precision$sampling_time[precision$survey == "delta-GAMNS-WCQ1"] == .125),
  all(precision$sampling_time[precision$survey == "delta-GAMNS-WCQ3+Q4"] == .75)
)

cv_rows <- function(filename, survey) {
  path <- file.path(
    "source_cache/ices_haddock_north_sea_2026",
    filename
  )
  header <- scan(path, skip = 2, n = 5, quiet = TRUE)
  years <- seq.int(as.integer(header[1]), as.integer(header[2]))
  ages <- seq.int(as.integer(header[3]), as.integer(header[4]))
  cv <- as.matrix(read.table(path, skip = 5, header = FALSE))
  stopifnot(nrow(cv) == length(years), ncol(cv) >= length(ages))
  cv <- cv[, seq_along(ages), drop = FALSE]
  grid <- expand.grid(year = years, age = ages)
  data.frame(
    survey = survey,
    year = grid$year,
    age = grid$age,
    expected = 1 / log1p(as.vector(cv)^2)
  )
}
cv <- rbind(
  cv_rows("data_survey-haddock-Q1-1-8plus_CV.dat", "delta-GAMNS-WCQ1"),
  cv_rows("data_survey-haddock-Q3Q4-0-8plus_CV.dat", "delta-GAMNS-WCQ3+Q4")
)
weight_check <- merge(
  precision[, c("survey", "year", "age", "value")],
  cv,
  by = c("survey", "year", "age"),
  all = TRUE
)
stopifnot(
  nrow(weight_check) == 667L,
  !anyNA(weight_check$value),
  !anyNA(weight_check$expected),
  max(abs(weight_check$value - weight_check$expected)) < 1e-10
)
precision_values <- precision[, c("survey", "year", "age", "value")]
names(precision_values)[4] <- "weight"
sd_values <- sd[, c("survey", "year", "age", "value")]
names(sd_values)[4] <- "relative_sd"
paired <- merge(precision_values, sd_values,
  by = c("survey", "year", "age"), all = TRUE
)
stopifnot(
  nrow(paired) == 667L,
  !anyNA(paired$relative_sd),
  max(abs(paired$relative_sd - 1 / sqrt(paired$weight))) < 1e-12
)
cat("Native precision weights and relative log-SD factors verified.\n")
