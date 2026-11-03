assessment_id <- "ices_whiting_north_sea_2026"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id)
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NSwhiting_2026n/run/model.RData"
)

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to extract native SAM outputs.", call. = FALSE)
}

model_env <- new.env(parent = baseenv())
load(file.path(cache, "NSwhiting_2026n_model.RData"), envir = model_env)
fit <- model_env$fit
if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess)) {
  stop("The cached official SAM fit did not pass its optimizer and Hessian checks.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- as.integer(colnames(fit$data$stockMeanWeight))
fleet_names <- attr(fit$data, "fleetNames")
aux <- as.data.frame(fit$data$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
aux$year <- as.integer(aux$year)
aux$fleet <- as.integer(aux$fleet)
aux$age <- as.integer(aux$age)

random_names <- names(fit$sdrep$par.random)
random_values <- unname(fit$sdrep$par.random)
random_variances <- fit$sdrep$diag.cov.random
modified_output_rows <- integer()
random_state_se <- function(name) {
  state <- fit$pl[[name]]
  index <- which(random_names == name)
  if (length(index) != length(state) ||
    max(abs(random_values[index] - as.vector(state))) > 1e-10) {
    stop("Could not align the native ", name, " states with their covariance diagonals.", call. = FALSE)
  }
  matrix(
    sqrt(random_variances[index]), nrow = nrow(state), ncol = ncol(state),
    dimnames = dimnames(state)
  )
}

output_rows <- function(type, measure, year = NA_integer_, age = NA_integer_,
                        value, unit, se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        fleet = "", survey = "", age_group = "",
                        source_reference, notes) {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep_len(fleet, n), survey = rep_len(survey, n),
    sex = "", region = "", season = "", year = rep_len(year, n),
    age = rep_len(age, n), age_group = rep_len(age_group, n),
    value = value, se = rep_len(se, n), lwr = rep_len(lwr, n),
    upr = rep_len(upr, n), unit = rep_len(unit, n),
    source_type = "native_model", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

z <- stats::qnorm(0.975)
update_surface <- function(measure, log_state, log_se, year_age) {
  if (year_age) {
    log_state <- t(log_state)
    log_se <- t(log_se)
  }
  surface_years <- years
  log_state <- log_state[seq_along(surface_years), , drop = FALSE]
  log_se <- log_se[seq_along(surface_years), , drop = FALSE]
  grid <- expand.grid(year = surface_years, age = ages, KEEP.OUT.ATTRS = FALSE)
  log_value <- as.vector(log_state)
  log_error <- as.vector(log_se)
  current <- which(outputs$assessment_id == assessment_id & outputs$measure == measure)
  index <- match(paste(grid$year, grid$age), paste(
    as.integer(outputs$year[current]), as.integer(outputs$age[current])
  ))
  if (length(current) != nrow(grid) || anyNA(index) || anyDuplicated(index)) {
    stop("The stored ", measure, " surface does not align uniquely to the native fit.", call. = FALSE)
  }
  output_index <- current[index]
  modified_output_rows <<- union(modified_output_rows, output_index)
  outputs$se[output_index] <<- format(exp(log_value) * log_error, scientific = FALSE, trim = TRUE)
  outputs$lwr[output_index] <<- format(exp(log_value - z * log_error), scientific = FALSE, trim = TRUE)
  outputs$upr[output_index] <<- format(exp(log_value + z * log_error), scientific = FALSE, trim = TRUE)
  uncertainty_note <- paste(
    "Conditional log-state SE converted to the natural scale by the delta method; 95% Wald limits are calculated on the log scale."
  )
  old_notes <- outputs$notes[output_index]
  outputs$notes[output_index] <<- ifelse(
    grepl(uncertainty_note, old_notes, fixed = TRUE), old_notes,
    paste(old_notes, uncertainty_note)
  )
}

database <- file.path(base, "database")
outputs_path <- file.path(database, "outputs.csv")
output_lines <- readLines(outputs_path, warn = FALSE, encoding = "UTF-8")
outputs <- utils::read.csv(
  text = output_lines, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
if (!all(c("se", "lwr", "upr", "notes") %in% names(outputs))) {
  stop("Unexpected output database schema.", call. = FALSE)
}

update_surface("numbers_at_age", fit$pl$logN, random_state_se("logN"), TRUE)
update_surface("fishing_mortality_at_age", fit$pl$logF, random_state_se("logF"), TRUE)
update_surface(
  "natural_mortality_at_age", fit$pl$logNM[seq_along(years), , drop = FALSE],
  random_state_se("logNM")[seq_along(years), , drop = FALSE], FALSE
)

q_table <- stockassessment::qtable(fit)
q_log_se <- attr(q_table, "sd")
if (!identical(dim(q_table), dim(q_log_se)) ||
  !identical(dimnames(q_table), dimnames(q_log_se))) {
  stop("The SAM q table and its log-scale SE table do not align.", call. = FALSE)
}
q_grid <- expand.grid(
  survey = rownames(q_table), age = as.integer(colnames(q_table)),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
)
q_grid$log_q <- as.vector(q_table)
q_grid$log_se <- as.vector(q_log_se)
q_grid <- q_grid[is.finite(q_grid$log_q) & is.finite(q_grid$log_se), , drop = FALSE]
q_value <- exp(q_grid$log_q)
new_q <- output_rows(
  "catchability", "q", value = q_value,
  age = q_grid$age, survey = q_grid$survey,
  unit = "native survey-index units per thousand fish",
  se = q_value * q_grid$log_se,
  lwr = exp(q_grid$log_q - z * q_grid$log_se),
  upr = exp(q_grid$log_q + z * q_grid$log_se),
  source_reference = paste0(model_url, "; stockassessment::qtable(fit), attr(sd)"),
  notes = "Exponentiated fitted log-q; SE is delta-method natural-scale and limits are 95% Wald intervals on the log scale."
)

if (length(fit$rep$predObs) != nrow(aux)) {
  stop("Native fitted observation values do not align with fit$data$aux.", call. = FALSE)
}
aux$prediction <- exp(as.numeric(fit$rep$predObs))
catch_index <- which(aux$fleet == 1L)
index_rows <- which(aux$fleet %in% 2:3)
new_predictions <- rbind(
  output_rows(
    "catch", "predicted_catch", year = aux$year[catch_index],
    age = aux$age[catch_index], value = aux$prediction[catch_index],
    fleet = fleet_names[[1L]], unit = "thousand fish",
    source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-catch predictions aligned to the native year, fleet, and age rows."
  ),
  output_rows(
    "index", "predicted_index", year = aux$year[index_rows],
    age = aux$age[index_rows], value = aux$prediction[index_rows],
    survey = fleet_names[aux$fleet[index_rows]],
    unit = "native survey-index units",
    source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
    notes = "Exponentiated fitted SAM log-index predictions aligned to the native year, survey, and age rows."
  )
)

native_summary <- function(fun, type, measure, unit, age = NA_integer_,
                           age_group = "", notes) {
  table <- fun(fit)
  row <- table["2026", , drop = FALSE]
  if (nrow(row) != 1L || any(!is.finite(row))) {
    stop("Could not recover the 2026 native ", measure, " estimate and interval.", call. = FALSE)
  }
  output_rows(
    type, measure, year = 2026L, age = age, age_group = age_group,
    value = row[1L, "Estimate"], lwr = row[1L, "Low"], upr = row[1L, "High"],
    unit = unit, source_reference = paste0(model_url, "; stockassessment::", deparse(substitute(fun)), "(fit)"),
    notes = notes
  )
}
new_summaries <- rbind(
  native_summary(
    stockassessment::rectable, "recruitment", "recruitment", "thousand fish",
    age = 0L, age_group = "age 0",
    notes = "Native 2026 intermediate-year recruitment estimate and 95% confidence limits; not included in the report summary table."
  ),
  native_summary(
    stockassessment::fbartable, "mortality", "Fbar", "per year",
    age_group = "2-5",
    notes = "Native 2026 intermediate-year Fbar over ages 2-5 and 95% confidence limits; not included in the report summary table."
  ),
  native_summary(
    stockassessment::tsbtable, "biomass", "total_biomass", "tonnes",
    notes = "Native 2026 intermediate-year total stock biomass and 95% confidence limits; not included in the report summary table."
  )
)

new_rows <- rbind(new_q, new_predictions, new_summaries)
row_key <- function(x) {
  columns <- c("assessment_id", "type", "measure", "year", "age", "age_group", "fleet", "survey")
  values <- lapply(x[columns], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\034"))
}
new_rows <- new_rows[!row_key(new_rows) %in% row_key(outputs), , drop = FALSE]

serialize_rows <- function(x) {
  if (!nrow(x)) return(character())
  vapply(seq_len(nrow(x)), function(i) paste(capture.output(utils::write.table(
    x[i, , drop = FALSE], sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, na = ""
  )), collapse = ""), character(1))
}
replacement <- serialize_rows(outputs[modified_output_rows, , drop = FALSE])
if (length(replacement) != length(modified_output_rows)) {
  stop("Could not preserve the database output rows while updating uncertainty.", call. = FALSE)
}
for (i in seq_along(modified_output_rows)) {
  output_lines[[modified_output_rows[[i]] + 1L]] <- replacement[[i]]
}
output_lines <- c(output_lines, serialize_rows(new_rows))
writeLines(output_lines, outputs_path, useBytes = TRUE)

assessments_path <- file.path(database, "assessments.csv")
assessment_lines <- readLines(assessments_path, warn = FALSE, encoding = "UTF-8")
assessments <- utils::read.csv(
  text = assessment_lines, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L) stop("Expected one whiting assessment record.", call. = FALSE)
assessments$outputs_status[assessment_row] <- "complete"
assessments$notes[assessment_row] <- paste(
  "Official state surfaces now include conditional uncertainty, and native q, fitted catch/index predictions, and 2026 intermediate-year recruitment, Fbar, and total biomass are recorded.",
  "The April NSwhiting_2026n run matches published summary estimates for 1978-2025 and the official 2026 SSB value. A later June update exists but does not match the published 2026 summary series and is not treated as official. The native fit and documented input matrices are cached locally outside Git."
)
assessment_lines[[assessment_row + 1L]] <- serialize_rows(assessments[assessment_row, , drop = FALSE])
writeLines(assessment_lines, assessments_path, useBytes = TRUE)

cat(
  "Updated 1,323 state uncertainty rows and added ", nrow(new_rows),
  " native q, prediction, and 2026 summary rows.\n", sep = ""
)
