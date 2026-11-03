root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
db_dir <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ices_turbot_north_sea_preflight", "tur4_m9", "run")
assessment_id <- "ices_turbot_north_sea_2025_benchmark"

user_library <- Sys.glob(file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", "*"))
.libPaths(c(user_library, .libPaths()))
if (!requireNamespace("TMB", quietly = TRUE)) stop("Install TMB to read the cached SAM fit.", call. = FALSE)

model_file <- file.path(cache, "model.RData")
if (!file.exists(model_file)) stop("The cached tur4.m9 model object is required.", call. = FALSE)
fit_env <- new.env(parent = globalenv())
load(model_file, envir = fit_env)
if (!exists("fit", fit_env, inherits = FALSE)) stop("The cached model object does not contain fit.", call. = FALSE)
fit <- fit_env$fit

outputs_file <- file.path(db_dir, "outputs.csv")
output_table <- read.csv(outputs_file, skipNul = TRUE, stringsAsFactors = FALSE,
  check.names = FALSE)
existing <- output_table[0, , drop = FALSE]
if (!"assessment_id" %in% names(existing) || !"measure" %in% names(existing)) {
  stop("Unexpected output table schema.", call. = FALSE)
}
if (any(output_table$assessment_id == assessment_id & output_table$measure == "weight_at_age")) {
  stop("The fitted stock-weight output is already present.", call. = FALSE)
}

years <- as.integer(fit$data$years)
ages <- seq_len(fit$conf$maxAge)
log_weight <- fit$pl$logSW[seq_along(years), , drop = FALSE]
log_weight_se <- fit$plsd$logSW[seq_along(years), , drop = FALSE]
if (!identical(dim(log_weight), c(length(years), length(ages))) ||
  !identical(dim(log_weight_se), dim(log_weight)) ||
  any(!is.finite(log_weight)) || any(!is.finite(log_weight_se))) {
  stop("The cached SAM weight surface does not match the fitted year-age grid.", call. = FALSE)
}

grid <- expand.grid(age = ages, year = years)
value <- as.vector(t(exp(log_weight)))
se <- as.vector(t(log_weight_se))
rows <- data.frame(
  assessment_id = assessment_id,
  type = "biology",
  measure = "weight_at_age",
  fleet = NA_character_, survey = NA_character_, sex = NA_character_,
  region = NA_character_, season = NA_character_,
  year = grid$year, age = grid$age, age_group = NA_character_,
  value = value, se = se, lwr = NA_real_, upr = NA_real_,
  unit = "kg per fish", source_type = "derived_source_output",
  source_reference = "tur4.m9/run/model.RData (fit$pl$logSW and fit$plsd$logSW)",
  notes = paste(
    "Fitted latent SAM stock weight; estimate is exp(logSW).",
    "SE is for logSW and remains on the log scale.",
    "These are fitted biological outputs, distinct from the noisy stock-weight inputs."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)
rows <- rows[, names(existing), drop = FALSE]
write.table(rows, outputs_file, sep = ",", append = TRUE, row.names = FALSE,
  col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "\r\n",
  fileEncoding = "UTF-8")
cat("Added", nrow(rows), "fitted stock-weight outputs for", assessment_id, ".\n")
