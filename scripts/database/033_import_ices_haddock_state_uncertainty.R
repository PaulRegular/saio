assessment_id <- "ices_haddock_north_sea_2026"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
cache <- file.path(root, "source_cache", assessment_id)
output_file <- file.path(root, "database/outputs.csv")
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NShaddock_WGNSSK2026_Run1/run/model.RData"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "run_model.RData"), envir = model_env)
fit <- model_env$fit
years <- as.integer(fit$data$years)
ages <- seq.int(min(fit$data$minAgePerFleet), max(fit$data$maxAgePerFleet))
log_F <- as.matrix(fit$pl$logF)
log_N <- as.matrix(fit$pl$logN)
n_state <- length(log_N)
n_age_year <- length(ages) * length(years)
random_names <- names(fit$sdrep$par.random)
state_variance <- fit$sdrep$diag.cov.random

stopifnot(
  isTRUE(fit$sdrep$pdHess),
  identical(dim(log_F), c(length(ages), length(years))),
  identical(dim(log_N), c(length(ages), length(years))),
  length(fit$sdrep$par.random) == 2L * n_age_year,
  length(state_variance) == 2L * n_age_year,
  all(random_names[seq_len(n_age_year)] == "logF"),
  all(random_names[n_age_year + seq_len(n_age_year)] == "logN"),
  max(abs(as.vector(log_F) - fit$sdrep$par.random[seq_len(n_age_year)])) < 1e-12,
  max(abs(as.vector(log_N) - fit$sdrep$par.random[n_age_year + seq_len(n_age_year)])) < 1e-12,
  all(is.finite(state_variance)),
  all(state_variance >= 0)
)

state_rows <- function(log_state, variance, state_years, measure, type) {
  n_year <- length(state_years)
  state <- as.vector(log_state[, seq_len(n_year), drop = FALSE])
  state_se <- sqrt(variance[seq_along(state)])
  grid <- expand.grid(age = ages, year = state_years)
  estimate <- exp(state)
  data.frame(
    type = type,
    measure = measure,
    year = grid$year,
    age = grid$age,
    value = estimate,
    se = estimate * state_se,
    lwr = exp(state - qnorm(0.975) * state_se),
    upr = exp(state + qnorm(0.975) * state_se),
    stringsAsFactors = FALSE
  )
}

n_rows <- state_rows(
  log_N,
  state_variance[n_age_year + seq_len(n_age_year)],
  years,
  "numbers_at_age",
  "population"
)
f_years <- years[years <= max(years) - 1L]
f_rows <- state_rows(
  log_F,
  state_variance[seq_len(n_age_year)],
  f_years,
  "fishing_mortality_at_age",
  "mortality"
)
state_rows_to_update <- rbind(n_rows, f_rows)
state_rows_to_update$assessment_id <- assessment_id
state_rows_to_update$fleet <- ifelse(
  state_rows_to_update$measure == "fishing_mortality_at_age",
  "Residual catch",
  ""
)
state_rows_to_update$survey <- ""
state_rows_to_update$notes <- paste(
  "Estimate is exp(log-state mode). Conditional random-effect covariance diagonal",
  "is conditional on fitted fixed parameters; SE is delta-method on natural scale,",
  "and bounds are 95% log-Wald intervals."
)

outputs <- read.csv(
  output_file,
  stringsAsFactors = FALSE,
  na.strings = "",
  check.names = FALSE
)
output_lines <- readLines(output_file, warn = FALSE, encoding = "UTF-8")
stopifnot(length(output_lines) == nrow(outputs) + 1L)

key_columns <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group"
)
key <- function(x) {
  parts <- lapply(key_columns, function(column) {
    values <- if (column %in% names(x)) as.character(x[[column]]) else ""
    values[is.na(values)] <- ""
    values
  })
  do.call(paste, c(parts, sep = "\034"))
}
existing_key <- key(outputs)
expected_key <- key(state_rows_to_update)
stopifnot(
  !anyDuplicated(existing_key),
  !anyDuplicated(expected_key),
  length(expected_key) == 981L
)
row_index <- match(expected_key, existing_key)
stopifnot(!anyNA(row_index))
existing <- outputs[row_index, , drop = FALSE]
stopifnot(
  max(abs(existing$value - state_rows_to_update$value) / pmax(1, existing$value)) < 1e-10,
  all(existing$unit[existing$measure == "numbers_at_age"] == "thousand fish"),
  all(existing$unit[existing$measure == "fishing_mortality_at_age"] == "per year")
)

for (i in seq_along(row_index)) {
  row <- row_index[i]
  values <- state_rows_to_update[i, ]
  for (column in c("se", "lwr", "upr")) {
    current <- outputs[[column]][row]
    expected <- values[[column]]
    if (!is.na(current) && abs(current - expected) > 1e-10 * max(1, abs(expected))) {
      stop("Existing state uncertainty conflicts with the cached SAM covariance.")
    }
    outputs[[column]][row] <- expected
  }
  current_note <- outputs$notes[row]
  if (is.na(current_note) || !grepl("Conditional random-effect covariance diagonal", current_note, fixed = TRUE)) {
    outputs$notes[row] <- if (is.na(current_note) || !nzchar(current_note)) {
      values$notes
    } else {
      paste(current_note, values$notes)
    }
  }
  csv_row <- capture.output(write.table(
    outputs[row, , drop = FALSE],
    sep = ",",
    quote = TRUE,
    row.names = FALSE,
    col.names = FALSE,
    na = ""
  ))
  output_lines[row + 1L] <- paste(csv_row, collapse = "")
}

writeLines(output_lines, output_file, useBytes = TRUE)
cat("Updated conditional state uncertainty for", length(row_index), "N and F estimates.\n")
