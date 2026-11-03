assessment_id <- "ices_cod_northeast_arctic_2026"
root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", assessment_id)
model_path <- file.path(cache, "baserun_model.RData")
if (!file.exists(model_path)) stop("The cached official SAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$fit
years <- as.integer(fit$data$years)
ages <- seq.int(
  min(as.integer(fit$data$minAgePerFleet)),
  max(as.integer(fit$data$maxAgePerFleet))
)
log_n <- fit$pl$logN
log_f <- fit$pl$logF
random_names <- names(fit$sdrep$par.random)
random_variance <- as.numeric(fit$sdrep$diag.cov.random)
n_index <- which(random_names == "logN")
f_index <- which(random_names == "logF")
if (fit$opt$convergence != 0L ||
  !identical(years, 1946:2026) || !identical(ages, 3:15) ||
  !identical(dim(log_n), c(13L, 81L)) ||
  !identical(dim(log_f), c(12L, 81L)) ||
  length(n_index) != length(log_n) || length(f_index) != length(log_f) ||
  length(random_variance) != length(fit$sdrep$par.random) ||
  any(!is.finite(random_variance)) || any(random_variance < 0) ||
  !isTRUE(all.equal(unname(fit$sdrep$par.random[n_index]), as.vector(log_n))) ||
  !isTRUE(all.equal(unname(fit$sdrep$par.random[f_index]), as.vector(log_f)))) {
  stop("The cached SAM state or random-effect covariance does not match the reviewed fit.",
    call. = FALSE
  )
}

z <- stats::qnorm(0.975)
n_log_se <- matrix(sqrt(random_variance[n_index]), nrow = 13L)
n_grid <- expand.grid(age = ages, year = years)
n_grid$log_estimate <- as.vector(log_n)
n_grid$se_log <- as.vector(n_log_se)

f_years <- years[years < max(years)]
f_log_se <- matrix(sqrt(random_variance[f_index]), nrow = 12L)
f_grid <- expand.grid(age = ages, year = f_years)
f_state_age <- pmin(f_grid$age - min(ages) + 1L, nrow(log_f))
f_state_year <- match(f_grid$year, years)
f_grid$log_estimate <- log_f[cbind(f_state_age, f_state_year)]
f_grid$se_log <- f_log_se[cbind(f_state_age, f_state_year)]

state_outputs <- function(x) {
  x$value <- exp(x$log_estimate)
  x$se <- x$value * x$se_log
  x$lwr <- exp(x$log_estimate - z * x$se_log)
  x$upr <- exp(x$log_estimate + z * x$se_log)
  x
}
n_grid <- state_outputs(n_grid)
f_grid <- state_outputs(f_grid)
uncertainty_note <- paste(
  "Conditional random-effect uncertainty from sqrt(diag.cov.random) on the",
  "log state; natural-scale SE uses the delta method and limits are 95%",
  "log-Wald intervals. Conditional on fitted fixed parameters; fixed-effect",
  "and covariance uncertainty are excluded, so these are not fully marginal."
)

outputs_path <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
if (!all(c("assessment_id", "type", "measure", "year", "age", "value",
  "se", "lwr", "upr", "notes") %in% names(outputs))) {
  stop("The canonical outputs schema is missing required state fields.", call. = FALSE)
}

update_state <- function(expected, type, measure, outputs) {
  expected$type <- type
  expected$measure <- measure
  selected <- which(outputs$assessment_id == assessment_id &
    outputs$type == type & outputs$measure == measure)
  current <- outputs[selected, , drop = FALSE]
  key <- function(x) paste(x$year, x$age, sep = "\r")
  if (nrow(current) != nrow(expected) || anyDuplicated(key(current))) {
    stop("Unexpected number of state output rows for ", measure, ".", call. = FALSE)
  }
  matched <- match(key(expected), key(current))
  if (anyNA(matched) || anyDuplicated(matched)) {
    stop("The state output years and ages do not match the native fit for ",
      measure, ".", call. = FALSE
    )
  }
  indices <- selected[matched]
  if (!isTRUE(all.equal(
    as.numeric(outputs$value[indices]), expected$value, tolerance = 1e-10
  ))) stop("Canonical state estimates do not match the cached fit for ", measure, ".", call. = FALSE)

  existing <- lapply(c("se", "lwr", "upr"), function(field) {
    as.numeric(outputs[[field]][indices])
  })
  names(existing) <- c("se", "lwr", "upr")
  expected_uncertainty <- expected[c("se", "lwr", "upr")]
  empty <- all(vapply(existing, function(x) all(is.na(x)), logical(1)))
  matched_existing <- all(vapply(names(existing), function(field) {
    isTRUE(all.equal(existing[[field]], expected_uncertainty[[field]], tolerance = 1e-12))
  }, logical(1)))
  if (!empty && !matched_existing) {
    stop("Existing state uncertainty is incomplete or differs from the fit for ",
      measure, ".", call. = FALSE
    )
  }

  note <- outputs$notes[indices]
  note[is.na(note)] <- ""
  note_missing <- !grepl(uncertainty_note, note, fixed = TRUE)
  changed_n <- if (empty) nrow(expected) else sum(note_missing)
  changed <- changed_n > 0L
  if (changed) {
    for (field in c("se", "lwr", "upr")) {
      outputs[[field]][indices] <- sprintf("%.15g", expected[[field]])
    }
    outputs$notes[indices[note_missing]] <- paste(
      outputs$notes[indices[note_missing]], uncertainty_note, sep = " "
    )
  }
  list(outputs = outputs, changed = changed_n)
}

n_result <- update_state(n_grid, "population", "numbers_at_age", outputs)
outputs <- n_result$outputs
f_result <- update_state(f_grid, "mortality", "fishing_mortality_at_age", outputs)
outputs <- f_result$outputs
updated_n <- n_result$changed
updated_f <- f_result$changed

assessments_path <- file.path(database, "assessments.csv")
assessments <- utils::read.csv(
  assessments_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
assessment_row <- which(assessments$assessment_id == assessment_id)
old_note <- "Numerical q and age-state uncertainty not yet exported."
new_note <- paste(
  "Native q uncertainty and conditional N/F state intervals are recorded.",
  "N/F intervals condition on fitted fixed parameters and are not fully marginal."
)
if (length(assessment_row) != 1L ||
  assessments$outputs_status[assessment_row] != "partial") {
  stop("The assessment record or its partial-output status differs from expectation.",
    call. = FALSE
  )
}
assessment_note <- assessments$notes[assessment_row]
if (grepl(old_note, assessment_note, fixed = TRUE)) {
  assessments$notes[assessment_row] <- sub(
    old_note, new_note, assessment_note, fixed = TRUE
  )
} else if (!grepl(new_note, assessment_note, fixed = TRUE)) {
  stop("The assessment note has changed; review it before importing uncertainty.",
    call. = FALSE
  )
}
old_configuration_note <- paste(
  "Survey native units, external cannibalism auxiliary data and detailed",
  "statistical-key/initial-state semantics require further review."
)
new_configuration_note <- paste(
  "Survey native units and external cannibalism mortality provenance remain",
  "incompletely characterized; native configuration and initial-state",
  "semantics have been checked."
)
assessment_note <- assessments$notes[assessment_row]
if (grepl(old_configuration_note, assessment_note, fixed = TRUE)) {
  assessments$notes[assessment_row] <- sub(
    old_configuration_note, new_configuration_note, assessment_note,
    fixed = TRUE
  )
} else if (!grepl(new_configuration_note, assessment_note, fixed = TRUE)) {
  stop("The assessment configuration note has changed; review before updating.",
    call. = FALSE
  )
}

if (identical(Sys.getenv("SAIO_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", updated_n, " N and ", updated_f,
    " F rows require conditional uncertainty updates.\n", sep = "")
} else {
  if (updated_n + updated_f > 0L) {
    utils::write.table(outputs, outputs_path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = TRUE, na = "")
  }
  utils::write.table(assessments, assessments_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = TRUE, na = "")
  cat("Imported conditional N/F state uncertainty; output status remains partial.\n")
}
