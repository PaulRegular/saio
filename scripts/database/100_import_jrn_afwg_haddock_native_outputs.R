assessment_id <- "jrn_afwg_haddock_northeast_arctic_2026"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(
  base, "source_cache", "ck_ices_afwg_aeglefinus_nea_1_2", "assessment_2026"
)
model_url <- paste0(
  "https://www.stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NEAHaddock2026/run/model.RData"
)

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to extract native SAM outputs.", call. = FALSE)
}

model_env <- new.env(parent = baseenv())
load(file.path(cache, "run_model.RData"), envir = model_env)
fit <- model_env$fit
if (is.null(fit) || !identical(attr(fit, "RemoteSha"), "1cc464b80f6f") ||
  !identical(attr(fit, "Version"), "0.12.0") ||
  fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess)) {
  stop("The cached SAM fit is not the verified converged JRN-AFWG production run.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
fleet_names <- attr(fit$data, "fleetNames")
if (!identical(years, 1950:2026) || !identical(ages, 3:13) ||
  !identical(as.integer(fit$data$maxAgePerFleet), c(13L, 8L, 9L, 10L, 9L))) {
  stop("The cached SAM fit has unexpected dimensions or fleet age groups.", call. = FALSE)
}

read_table <- function(name) {
  path <- file.path(base, "database", paste0(name, ".csv"))
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  data <- utils::read.csv(
    text = lines, colClasses = "character", na.strings = "",
    check.names = FALSE, stringsAsFactors = FALSE
  )
  list(path = path, lines = lines, data = data)
}

inputs_file <- read_table("inputs")
outputs_file <- read_table("outputs")
assessments_file <- read_table("assessments")
inputs <- inputs_file$data
outputs <- outputs_file$data
assessments <- assessments_file$data
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L) {
  stop("Expected one JRN-AFWG haddock assessment record.", call. = FALSE)
}

state_log_se <- function(name) {
  state <- fit$pl[[name]]
  random_names <- names(fit$sdrep$par.random)
  random_index <- which(random_names == name)
  random_values <- unname(fit$sdrep$par.random[random_index])
  variance <- fit$sdrep$diag.cov.random[random_index]
  if (length(random_index) != length(state) ||
    max(abs(random_values - as.vector(state))) > 1e-10 ||
    length(variance) != length(state) || any(!is.finite(variance)) ||
    any(variance < 0)) {
    stop("Could not align the native ", name, " states with their covariance diagonals.", call. = FALSE)
  }
  matrix(sqrt(variance), nrow = nrow(state), ncol = ncol(state))
}

log_n <- t(fit$pl$logN)
se_log_n <- t(state_log_se("logN"))
f_state <- as.integer(fit$conf$keyLogFsta[1L, ]) + 1L
if (!identical(f_state, c(1:6, rep(6L, 5L)))) {
  stop("The final SAM F state map differs from the reviewed age sharing.", call. = FALSE)
}
log_f <- t(fit$pl$logF[f_state, , drop = FALSE])
se_log_f <- t(state_log_se("logF")[f_state, , drop = FALSE])

output_rows <- function(type, measure, year = NA_integer_, age = NA_integer_,
                        age_group = "", value, unit, se = NA_real_,
                        lwr = NA_real_, upr = NA_real_, fleet = "", survey = "",
                        source_reference, notes) {
  n <- length(value)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = rep_len(fleet, n), survey = rep_len(survey, n),
    sex = "combined", region = "Northeast Arctic", season = "",
    year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = value, se = rep_len(se, n),
    lwr = rep_len(lwr, n), upr = rep_len(upr, n), unit = rep_len(unit, n),
    source_type = "native_model", source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE, check.names = FALSE
  )
}

z <- stats::qnorm(0.975)
modified_rows <- integer()
uncertainty_note <- paste(
  "Conditional log-state SE from the native SAM random-effect covariance,",
  "converted to the natural scale by the delta method; 95% Wald limits are",
  "calculated on the log scale and condition on estimated fixed parameters."
)

update_state_surface <- function(measure, surface_years, log_value, log_se) {
  current <- which(
    outputs$assessment_id == assessment_id & outputs$measure == measure
  )
  grid <- expand.grid(year = surface_years, age = ages)
  output_key <- paste(
    suppressWarnings(as.integer(outputs$year[current])),
    suppressWarnings(as.integer(outputs$age[current]))
  )
  index <- match(paste(grid$year, grid$age), output_key)
  if (length(current) != nrow(grid) || anyNA(index) || anyDuplicated(index)) {
    stop("Stored ", measure, " output rows do not align uniquely with the native SAM surface.", call. = FALSE)
  }
  log_value <- as.vector(log_value[match(surface_years, years), , drop = FALSE])
  log_se <- as.vector(log_se[match(surface_years, years), , drop = FALSE])
  if (any(!is.finite(log_value)) || any(!is.finite(log_se)) || any(log_se < 0)) {
    stop("Native ", measure, " estimates or conditional SEs are invalid.", call. = FALSE)
  }

  output_index <- current[index]
  report_value <- suppressWarnings(as.numeric(outputs$value[output_index]))
  native_value <- exp(log_value)
  tolerance <- if (measure == "numbers_at_age") 0.51 else 0.00051
  if (any(!is.finite(report_value)) || max(abs(native_value - report_value)) > tolerance) {
    stop("The published ", measure, " rows do not match the cached final SAM run.", call. = FALSE)
  }
  modified_rows <<- union(modified_rows, output_index)
  outputs$se[output_index] <<- format(native_value * log_se, scientific = FALSE, trim = TRUE)
  outputs$lwr[output_index] <<- format(exp(log_value - z * log_se), scientific = FALSE, trim = TRUE)
  outputs$upr[output_index] <<- format(exp(log_value + z * log_se), scientific = FALSE, trim = TRUE)
  state_reference <- paste0(model_url, "; fit$sdrep$diag.cov.random")
  old_reference <- outputs$source_reference[output_index]
  outputs$source_reference[output_index] <<- ifelse(
    grepl(model_url, old_reference, fixed = TRUE), old_reference,
    paste(old_reference, state_reference)
  )
  old_notes <- outputs$notes[output_index]
  old_notes[is.na(old_notes)] <- ""
  old_notes <- gsub("No age-specific uncertainty is tabulated[.]", "", old_notes)
  outputs$notes[output_index] <<- ifelse(
    grepl(uncertainty_note, old_notes, fixed = TRUE), old_notes,
    trimws(paste(old_notes, uncertainty_note))
  )
}

update_state_surface("numbers_at_age", years, log_n, se_log_n)
update_state_surface("fishing_mortality_at_age", 1950:2025, log_f, se_log_f)

q_table <- stockassessment::qtable(fit)
q_log_se <- attr(q_table, "sd")
if (!identical(dim(q_table), dim(q_log_se)) ||
  !identical(dimnames(q_table), dimnames(q_log_se))) {
  stop("The native SAM q table and its log-scale SE table do not align.", call. = FALSE)
}
q_grid <- expand.grid(
  survey = rownames(q_table), age = as.integer(colnames(q_table)),
  KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
)
q_grid$log_q <- as.vector(q_table)
q_grid$log_se <- as.vector(q_log_se)
q_grid <- q_grid[is.finite(q_grid$log_q) & is.finite(q_grid$log_se), , drop = FALSE]
q_grid$fleet_id <- match(q_grid$survey, fleet_names)
q_grid$age_group <- ifelse(
  q_grid$age == fit$data$maxAgePerFleet[q_grid$fleet_id],
  paste0(q_grid$age, "+"), ""
)
q_value <- exp(q_grid$log_q)
q_outputs <- output_rows(
  "catchability", "q", age = q_grid$age, age_group = q_grid$age_group,
  value = q_value, unit = "native index-scale q coefficient",
  se = q_value * q_grid$log_se,
  lwr = exp(q_grid$log_q - z * q_grid$log_se),
  upr = exp(q_grid$log_q + z * q_grid$log_se), survey = q_grid$survey,
  source_reference = paste0(model_url, "; stockassessment::qtable(fit)"),
  notes = paste(
    "Exponentiated fitted SAM logFpar baseline q coefficient; its SE uses",
    "the delta method and its 95% Wald limits are on the log-q scale.",
    "The observation model also includes abundance-dependent logQpow terms,",
    "so this coefficient is not the effective q at every abundance. The",
    "physical index multiplier is not stated."
  )
)

qpow_key <- fit$conf$keyQpow
qpow_outputs <- do.call(rbind, lapply(seq_len(nrow(qpow_key)), function(fleet_id) {
  keys <- as.integer(qpow_key[fleet_id, ])
  parameter_ids <- unique(keys[keys >= 0L])
  if (!length(parameter_ids)) return(NULL)
  do.call(rbind, lapply(parameter_ids, function(parameter_id) {
    grouped_ages <- ages[keys == parameter_id]
    first_age <- min(grouped_ages)
    last_age <- max(grouped_ages)
    terminal_age <- fit$data$maxAgePerFleet[fleet_id]
    age_group <- if (length(grouped_ages) == 1L && last_age != terminal_age) {
      ""
    } else if (first_age == last_age) {
      paste0(first_age, "+")
    } else {
      paste0(first_age, "-", last_age,
        if (last_age == terminal_age) "+" else "")
    }
    output_rows(
      "catchability", "log_q_power",
      age = if (length(grouped_ages) == 1L && last_age != terminal_age) first_age else NA_integer_,
      age_group = age_group,
      value = fit$pl$logQpow[parameter_id + 1L],
      unit = "log scale", se = fit$plsd$logQpow[parameter_id + 1L],
      survey = fleet_names[fleet_id],
      source_reference = paste0(model_url, "; fit$pl$logQpow and fit$plsd$logQpow"),
      notes = paste(
        "Fitted SAM logQpow parameter on its reported scale; exp(value)",
        "multiplies the predicted log abundance in the survey observation",
        "equation. SE is on the logQpow parameter scale."
      )
    )
  }))
}))

aux <- as.data.frame(fit$data$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet_id", "age")
aux$year <- as.integer(aux$year)
aux$fleet_id <- as.integer(aux$fleet_id)
aux$age <- as.integer(aux$age)
if (length(fit$rep$predObs) != nrow(aux) ||
  length(fit$data$logobs) != nrow(aux)) {
  stop("Fitted observation predictions do not align with fit$data$aux.", call. = FALSE)
}
observed <- which(is.finite(fit$data$logobs))
if (length(observed) != 1626L || any(!is.finite(fit$rep$predObs[observed]))) {
  stop("The native SAM observation rows differ from the reviewed input coverage.", call. = FALSE)
}
aux$prediction <- exp(as.numeric(fit$rep$predObs))
aux$age_group <- ifelse(
  aux$age == fit$data$maxAgePerFleet[aux$fleet_id],
  paste0(aux$age, "+"), ""
)
catch_index <- observed[aux$fleet_id[observed] == 1L]
survey_index <- observed[aux$fleet_id[observed] > 1L]
new_catch_predictions <- output_rows(
  "catch", "predicted_catch", year = aux$year[catch_index],
  age = aux$age[catch_index], age_group = aux$age_group[catch_index],
  value = aux$prediction[catch_index], unit = "thousand fish",
  fleet = "Residual catch",
  source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
  notes = "Exponentiated fitted SAM log-catch predictions for observed residual-catch rows, aligned to native years and ages."
)
new_index_predictions <- output_rows(
  "index", "predicted_index", year = aux$year[survey_index],
  age = aux$age[survey_index], age_group = aux$age_group[survey_index],
  value = aux$prediction[survey_index], unit = "survey index (unit unresolved)",
  survey = fleet_names[aux$fleet_id[survey_index]],
  source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
  notes = "Exponentiated fitted SAM log-index predictions for observed rows, aligned to native survey, year and age group; the physical index multiplier is not stated."
)

new_rows <- rbind(q_outputs, qpow_outputs, new_catch_predictions, new_index_predictions)
row_key <- function(data) {
  columns <- c(
    "assessment_id", "type", "measure", "year", "age", "age_group",
    "fleet", "survey"
  )
  values <- lapply(data[columns], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\034"))
}
if (anyDuplicated(row_key(new_rows))) {
  stop("The native q, q-power or fitted prediction output keys are duplicated.", call. = FALSE)
}
new_rows <- new_rows[!row_key(new_rows) %in% row_key(outputs), , drop = FALSE]
if (nrow(q_outputs) != 28L || nrow(qpow_outputs) != 6L ||
  nrow(new_catch_predictions) != 836L || nrow(new_index_predictions) != 790L) {
  stop("The native output counts differ from the reviewed final SAM run.", call. = FALSE)
}

serialize_rows <- function(data) {
  if (!nrow(data)) return(character())
  vapply(seq_len(nrow(data)), function(i) {
    paste(capture.output(utils::write.table(
      data[i, , drop = FALSE], sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, na = ""
    )), collapse = "")
  }, character(1))
}

modified_lines <- serialize_rows(outputs[modified_rows, , drop = FALSE])
if (length(modified_lines) != length(modified_rows)) {
  stop("Could not preserve the existing state-output rows.", call. = FALSE)
}
for (i in seq_along(modified_rows)) {
  outputs_file$lines[[modified_rows[[i]] + 1L]] <- modified_lines[[i]]
}
outputs_file$lines <- c(outputs_file$lines, serialize_rows(new_rows))
writeLines(outputs_file$lines, outputs_file$path, useBytes = TRUE)

assessments$outputs_status[assessment_row] <- "complete"
assessments$notes[assessment_row] <- paste(
  "Native SAM output surfaces now include conditional age-specific N/F uncertainty, baseline q and logQpow estimates, and fitted catch/index predictions.",
  "Reported Low/High bounds retain their published values with coverage unspecified; the physical survey index multiplier remains unknown."
)
assessment_line <- serialize_rows(assessments[assessment_row, , drop = FALSE])
assessments_file$lines[[assessment_row + 1L]] <- assessment_line[[1L]]
writeLines(assessments_file$lines, assessments_file$path, useBytes = TRUE)

cat(
  "Updated ", length(modified_rows), " state uncertainty rows and added ",
  nrow(new_rows), " native q, q-power and fitted prediction rows.\n", sep = ""
)
