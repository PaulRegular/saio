root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_haddock_7b_k_2026")
assessment_id <- "ices_haddock_celtic_sea_7b_k_2026"
survey <- "FRA_IRL_IBTS"
years <- 1993:2025
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "HAD7bk_2026/run/model.RData"
)

model_path <- file.path(cache, "run", "model.RData")
if (!file.exists(model_path)) stop("The cached official SAM model is missing.", call. = FALSE)

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$fit
assessments_path <- file.path(database, "assessments.csv")
assessments <- utils::read.csv(
  assessments_path, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
assessment_index <- which(assessments$assessment_id == assessment_id)
if (length(assessment_index) != 1L) {
  stop("Expected exactly one imported Celtic Sea haddock assessment.", call. = FALSE)
}
if (assessments$assumptions_status[assessment_index] != "complete" ||
  assessments$inputs_status[assessment_index] != "complete" ||
  !assessments$outputs_status[assessment_index] %in% c("partial", "complete")) {
  stop("The source record is not in the reviewed state expected for this output supplement.", call. = FALSE)
}

fleet_names <- attr(fit$data, "fleetNames")
if (fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess) ||
  !identical(as.integer(fit$data$years), years) ||
  !identical(as.character(fleet_names), c("Residual catch", survey)) ||
  !isTRUE(all.equal(as.numeric(fit$data$sampleTimes), c(0, 0.875))) ||
  !identical(as.integer(fit$data$maxAgePerFleet), c(8L, 7L)) ||
  nrow(fit$data$aux) != 448L ||
  length(fit$data$logobs) != 448L ||
  length(fit$rep$predObs) != 448L ||
  sum(is.na(fit$data$logobs)) != 3L ||
  any(!is.finite(fit$rep$predObs))) {
  stop("The fitted SAM rows or prediction vectors differ from the reviewed native run.", call. = FALSE)
}

aux <- as.data.frame(fit$data$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet_id", "age")
aux$year <- as.integer(aux$year)
aux$fleet_id <- as.integer(aux$fleet_id)
aux$age <- as.integer(aux$age)
if (!all(aux$fleet_id %in% seq_along(fleet_names))) {
  stop("The native prediction rows contain an unknown fleet ID.", call. = FALSE)
}
predicted <- exp(as.numeric(fit$rep$predObs))
if (any(!is.finite(predicted))) {
  stop("Exponentiated native SAM predictions are not finite.", call. = FALSE)
}

q_fleets <- which(as.integer(fit$data$fleetTypes) != 0L)
q_key <- fit$conf$keyLogFpar[q_fleets, , drop = FALSE]
q_ages <- as.integer(fit$conf$minAge:fit$conf$maxAge)
if (length(q_fleets) != 1L ||
  !identical(as.character(fleet_names[q_fleets]), survey) ||
  !identical(as.integer(q_key[1L, ]), c(0:7, -1L)) ||
  !identical(length(fit$pl$logFpar), 8L) ||
  !identical(length(fit$plsd$logFpar), 8L)) {
  stop("The configured age-specific q map differs from the reviewed SAM run.", call. = FALSE)
}
q_keep <- q_key[1L, ] >= 0L
q_parameter <- as.integer(q_key[1L, q_keep]) + 1L
log_q <- as.numeric(fit$pl$logFpar[q_parameter])
log_q_se <- as.numeric(fit$plsd$logFpar[q_parameter])
if (length(log_q) != 8L || any(!is.finite(log_q)) ||
  any(!is.finite(log_q_se)) || any(log_q_se < 0)) {
  stop("Could not recover finite q estimates and log-scale standard errors.", call. = FALSE)
}

z <- stats::qnorm(0.975)
output_rows <- function(type, measure, value, year = NA_integer_, age = NA_integer_,
                        age_group = "", fleet = "", survey_name = "",
                        unit, se = NA_real_, lwr = NA_real_, upr = NA_real_,
                        source_reference, notes) {
  n <- length(value)
  data.frame(
    assessment_id = rep(assessment_id, n), type = rep(type, n),
    measure = rep(measure, n), fleet = rep_len(fleet, n),
    survey = rep_len(survey_name, n), sex = rep("combined", n),
    region = rep("ICES 7.b–k", n), season = rep(NA_character_, n),
    year = rep_len(year, n), age = rep_len(age, n),
    age_group = rep_len(age_group, n), value = as.numeric(value),
    se = rep_len(se, n), lwr = rep_len(lwr, n), upr = rep_len(upr, n),
    unit = rep(unit, n), source_type = rep("native_model", n),
    source_reference = rep(source_reference, n), notes = rep(notes, n),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

q_value <- exp(log_q)
new_q <- output_rows(
  "catchability", "q", value = q_value,
  age = q_ages[q_keep], survey_name = survey,
  unit = "native survey-index units per thousand fish",
  se = q_value * log_q_se,
  lwr = exp(log_q - z * log_q_se),
  upr = exp(log_q + z * log_q_se),
  source_reference = paste0(
    model_url, "; fit$conf$keyLogFpar, fit$pl$logFpar, and fit$plsd$logFpar"
  ),
  notes = paste(
    "Exponentiated fitted SAM log-q by survey age. The fitted SE is converted",
    "to the natural q scale by the delta method; limits are 95% Wald intervals",
    "calculated on the log-q scale."
  )
)

catch_rows <- which(aux$fleet_id == 1L)
index_rows <- which(aux$fleet_id == 2L)
prediction_note <- paste(
  "Exponentiated fitted SAM log-observation prediction aligned to",
  "fit$data$aux. Includes all rows in the native fitted observation array;",
  "rows with missing log observations have fitted predictions, while age-0",
  "catch rows omitted from that array have no prediction here."
)
catch_age_group <- ifelse(aux$age[catch_rows] == 8L, "8+", "")
new_catch <- output_rows(
  "catch", "predicted_catch", value = predicted[catch_rows],
  year = aux$year[catch_rows], age = aux$age[catch_rows],
  age_group = catch_age_group, fleet = fleet_names[[1L]],
  unit = "thousand fish",
  source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
  notes = prediction_note
)
new_index <- output_rows(
  "index", "predicted_index", value = predicted[index_rows],
  year = aux$year[index_rows], age = aux$age[index_rows],
  survey_name = fleet_names[[2L]],
  unit = "survey index (unit unresolved)",
  source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
  notes = prediction_note
)
new_rows <- rbind(new_q, new_catch, new_index)

outputs_path <- file.path(database, "outputs.csv")
output_lines <- readLines(outputs_path, warn = FALSE, encoding = "UTF-8")
header <- output_lines[[1L]]
event_lines <- output_lines[startsWith(
  output_lines, paste0("\"", assessment_id, "\"")
)]
existing <- utils::read.csv(
  text = c(header, event_lines), colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
columns <- names(utils::read.csv(
  outputs_path, nrows = 0L, check.names = FALSE, stringsAsFactors = FALSE
))
if (!setequal(names(new_rows), columns)) {
  stop("The output rows do not match the canonical database schema.", call. = FALSE)
}
new_rows <- new_rows[columns]

row_key <- function(x) {
  fields <- c(
    "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
    "season", "year", "age", "age_group"
  )
  values <- lapply(x[fields], function(value) {
    value <- as.character(value)
    Encoding(value) <- "UTF-8"
    value[is.na(value) | !nzchar(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\034"))
}
if (anyDuplicated(row_key(existing))) {
  stop("The imported assessment already contains duplicate output keys.", call. = FALSE)
}
if (nrow(new_q) != 8L || nrow(new_catch) != 264L || nrow(new_index) != 184L ||
  anyDuplicated(row_key(new_rows))) {
  stop("The native q or prediction output coverage differs from the reviewed run.", call. = FALSE)
}
new_rows <- new_rows[!row_key(new_rows) %in% row_key(existing), , drop = FALSE]
if (nrow(new_rows) != 456L && nrow(new_rows) != 0L) {
  stop("Only part of the expected output supplement is present.", call. = FALSE)
}

updated_assessments <- assessments
updated_assessments$outputs_status[assessment_index] <- "complete"
completion_note <- paste(
  "Native fitted catch and index predictions (all 448 rows in fit$data$aux)",
  "and age-specific q estimates for ages 0–7 are now imported. Three rows",
  "have missing observations but are retained because SAM reports fitted",
  "predictions for those rows; the prediction table excludes age-0 catch rows",
  "omitted from the fitted observation array."
)
old_note <- updated_assessments$notes[assessment_index]
if (!grepl(completion_note, old_note, fixed = TRUE)) {
  updated_assessments$notes[assessment_index] <- paste(old_note, completion_note)
}

if (identical(Sys.getenv("SAIO_DATABASE_DRY_RUN"), "true")) {
  cat(
    "Dry run passed: ", nrow(new_q), " q rows, ", nrow(new_catch),
    " catch predictions, ", nrow(new_index),
    " index predictions; ", nrow(new_rows),
    " new rows would be written and outputs_status would be complete.\n",
    sep = ""
  )
} else {
  if (nrow(new_rows)) {
    utils::write.table(
      new_rows, outputs_path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
    )
  }
  utils::write.csv(
    updated_assessments, assessments_path, row.names = FALSE, na = ""
  )
  cat(
    "Imported ", nrow(new_q), " q rows, ", nrow(new_catch),
    " catch predictions, and ", nrow(new_index),
    " index predictions; outputs_status is complete.\n",
    sep = ""
  )
}
