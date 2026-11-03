assessment_id <- "dfo_northern_mackerel_2025"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", assessment_id)
model_revision <- "435d10bcb6ee64e0d94c77f6854e0d37f53e4b8b"
ccam_revision <- "1bcb06473343c13ebeebecdb54acd905220aeb61"
model_url <- paste0(
  "https://github.com/iml-assess/mackerel_assessment/blob/",
  model_revision, "/Rdata/2025/fit.Rdata"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "model_repository", "Rdata", "2025", "fit.Rdata"),
  envir = model_env
)
fit <- model_env$fit
if (is.null(fit) || !identical(attr(fit, "RemoteSha"), "1d1cc18416b2") ||
  !identical(attr(fit, "Version"), "0.1.1") ||
  fit$opt$convergence != 0L || !isTRUE(fit$sdrep$pdHess)) {
  stop("The cached fit is not the verified DFO 2025 CCAM run.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
key_sel <- fit$conf$keySel
if (!identical(years, 1969:2025) || !identical(ages, 1:10) ||
  !identical(dim(key_sel), c(length(years), length(ages))) ||
  !identical(as.integer(sort(unique(as.vector(key_sel)))), 0:4) ||
  length(fit$pl$logFy) != length(years) ||
  length(fit$plsd$logFy) != length(years) ||
  length(fit$pl$logitSel) != 4L) {
  stop("The cached fit has unexpected years, ages, or F parameter mapping.", call. = FALSE)
}

random_names <- names(fit$sdrep$par.random)
log_f_index <- which(random_names == "logFy")
if (length(log_f_index) != length(years) ||
  max(abs(unname(fit$sdrep$par.random[log_f_index]) - fit$pl$logFy)) > 1e-10 ||
  max(abs(sqrt(fit$sdrep$diag.cov.random[log_f_index]) - fit$plsd$logFy)) > 1e-10) {
  stop("The saved logFy states and conditional covariance do not align.", call. = FALSE)
}

selectivity <- matrix(1, nrow = length(years), ncol = length(ages))
for (j in seq_along(ages)) {
  keys <- as.integer(key_sel[, j])
  estimated <- keys != max(key_sel)
  selectivity[estimated, j] <- stats::plogis(fit$pl$logitSel[keys[estimated] + 1L])
}
log_f <- outer(fit$pl$logFy, rep(1, length(ages))) + log(selectivity)
fitted_f <- exp(log_f)
log_f_se <- matrix(fit$plsd$logFy, nrow = length(years), ncol = length(ages))
f_se <- fitted_f * log_f_se
f_lwr <- exp(log_f - 2 * log_f_se)
f_upr <- exp(log_f + 2 * log_f_se)
if (any(!is.finite(fitted_f)) || any(!is.finite(f_se)) ||
  any(!is.finite(f_lwr)) || any(!is.finite(f_upr)) ||
  any(f_se <= 0) || any(f_lwr >= fitted_f) || any(fitted_f >= f_upr)) {
  stop("The native F estimates or conditional intervals are invalid.", call. = FALSE)
}

f_export <- utils::read.csv(
  file.path(cache, "model_repository", "csv", "2025", "f.csv"),
  stringsAsFactors = FALSE, check.names = FALSE
)
if (!identical(as.integer(f_export[[1L]]), years) ||
  !all(as.character(ages) %in% names(f_export)) ||
  max(abs(round(fitted_f, 2) - as.matrix(f_export[as.character(ages)]))) > 1e-12) {
  stop("Native F does not reproduce the published table after its 0.01 rounding.", call. = FALSE)
}

output_path <- file.path(base, "database", "outputs.csv")
output_lines <- readLines(output_path, warn = FALSE, encoding = "UTF-8")
outputs <- utils::read.csv(
  text = output_lines, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
if (!"age_group" %in% names(outputs)) outputs$age_group <- ""
f_rows <- which(
  outputs$assessment_id == assessment_id &
    outputs$measure == "fishing_mortality_at_age"
)
grid <- expand.grid(age = ages, year = years, KEEP.OUT.ATTRS = FALSE)
output_key <- paste(
  suppressWarnings(as.integer(outputs$year[f_rows])),
  suppressWarnings(as.integer(outputs$age[f_rows]))
)
grid_key <- paste(grid$year, grid$age)
grid_row <- match(output_key, grid_key)
if (length(f_rows) != length(years) * length(ages) ||
  anyNA(grid_row) || anyDuplicated(grid_row) ||
  length(output_lines) != nrow(outputs) + 1L) {
  stop("Stored F output rows do not align uniquely with the native age-year grid.", call. = FALSE)
}

f_value <- as.vector(t(fitted_f))[grid_row]
f_standard_error <- as.vector(t(f_se))[grid_row]
f_lower <- as.vector(t(f_lwr))[grid_row]
f_upper <- as.vector(t(f_upr))[grid_row]
reported_f <- suppressWarnings(as.numeric(outputs$value[f_rows]))
if (any(!is.finite(reported_f)) ||
  (max(abs(reported_f - round(f_value, 2))) > 1e-10 &&
    max(abs(reported_f - f_value)) > 1e-10)) {
  stop("Existing F values differ from the official rounded export.", call. = FALSE)
}

format_number <- function(x) format(x, scientific = FALSE, digits = 17, trim = TRUE)
conditional_note <- paste(
  "Exact F-at-age is reconstructed from the pinned fit's annual logFy and",
  "CCAM selectivity mapping; it reproduces the public f.csv table after",
  "rounding to 0.01. SE is the natural-scale delta-method transformation",
  "of the conditional logFy state SD. Bounds are exp(log F +/- 2 SD(logFy)),",
  "asymptotic and conditional on fitted fixed parameters. They exclude",
  "selectivity-parameter uncertainty and covariance with logFy; they are not",
  "full marginal confidence intervals."
)
outputs$value[f_rows] <- format_number(f_value)
outputs$se[f_rows] <- format_number(f_standard_error)
outputs$lwr[f_rows] <- format_number(f_lower)
outputs$upr[f_rows] <- format_number(f_upper)
outputs$source_reference[f_rows] <- paste0(
  model_url,
  "; CCAM_repository/inst/include/derived.hpp::FFun;",
  " CCAM_repository/R/tables.R::faytable.ccam; fit$plsd$logFy"
)
outputs$notes[f_rows] <- conditional_note

serialize_row <- function(row) {
  paste(capture.output(utils::write.table(
    row, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = ""
  )), collapse = "")
}
for (i in seq_along(f_rows)) {
  output_lines[[f_rows[[i]] + 1L]] <- serialize_row(outputs[f_rows[[i]], , drop = FALSE])
}
writeLines(output_lines, output_path, useBytes = TRUE)

assessments_path <- file.path(base, "database", "assessments.csv")
assessment_lines <- readLines(assessments_path, warn = FALSE, encoding = "UTF-8")
assessments <- utils::read.csv(
  text = assessment_lines, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
assessment_row <- which(assessments$assessment_id == assessment_id)
if (length(assessment_row) != 1L ||
  assessments$outputs_status[assessment_row] != "partial") {
  stop("Expected one partial-output DFO mackerel assessment record.", call. = FALSE)
}
fit_note <- paste(
  "Conditional annual logFy uncertainty is now recorded for F-at-age.",
  "Full marginal F uncertainty remains unavailable because fixed selectivity uncertainty and its covariance with logFy are not available in the cached fit summary.",
  "The fit object records CCAM RemoteSha 1d1cc18416b2; the cached source snapshot is 1bcb06473343c13ebeebecdb54acd905220aeb61."
)
assessments$model_version[assessment_row] <- paste0(
  "2025 run; mackerel_assessment ", model_revision,
  "; fit CCAM RemoteSha 1d1cc18416b2; available CCAM source snapshot ",
  ccam_revision
)
old_note <- assessments$notes[assessment_row]
if (is.na(old_note)) old_note <- ""
assessments$notes[assessment_row] <- if (grepl(fit_note, old_note, fixed = TRUE)) {
  old_note
} else {
  trimws(paste(old_note, fit_note))
}
assessment_lines[[assessment_row + 1L]] <- serialize_row(
  assessments[assessment_row, , drop = FALSE]
)
writeLines(assessment_lines, assessments_path, useBytes = TRUE)

cat("Added conditional F uncertainty for ", length(f_rows),
  " native age-year estimates; outputs remain partial.\n", sep = "")
