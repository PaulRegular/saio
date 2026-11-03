root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database_dir <- file.path(root, "database")
read_table <- function(name) read.csv(
  file.path(database_dir, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)

stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
inputs <- read_table("inputs.csv")
outputs <- read_table("outputs.csv")
stock_id <- "ck_ices_wgbfas_solea_ns_iiia_22_24"
assessment_id <- "ices_sole_20_24_2025"
summary_id <- "ices_sole_20_24_2026_summary"
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
detailed <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
summary <- assessments[assessments$assessment_id == summary_id, , drop = FALSE]
source_inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
source_outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
fit_env <- new.env(parent = baseenv())
load(file.path(root, "source_cache",
  assessment_id, "run", "model.RData"), envir = fit_env)
fit <- fit_env$fit
summary_outputs <- outputs[outputs$assessment_id == summary_id & outputs$measure %in% c("recruitment", "SSB", "Fbar"), , drop = FALSE]
predicted_catch <- source_outputs[source_outputs$measure == "predicted_catch", , drop = FALSE]
predicted_index <- source_outputs[source_outputs$measure == "predicted_index", , drop = FALSE]
q_outputs <- source_outputs[
  source_outputs$type == "catchability" & source_outputs$measure == "q", , drop = FALSE
]
q_survey_names <- c("Q4Solesurvey1-9+", "Gillnet", "Trawl")
expected_q_keys <- rbind(
  c(0L, 1L, 2L, 3L, 3L, 3L, 3L, 3L, 3L),
  c(-1L, 4L, 5L, 6L, 7L, 7L, 7L, 7L, -1L),
  c(-1L, 8L, 9L, 10L, 11L, 11L, -1L, -1L, -1L)
)
q_group_ages <- function(i) {
  group <- q_outputs$age_group[i]
  if (!is.na(group) && grepl("^[0-9]+-[0-9]+$", group)) {
    bounds <- as.integer(strsplit(group, "-", fixed = TRUE)[[1L]])
    return(seq.int(bounds[1L], bounds[2L]))
  }
  as.integer(q_outputs$age[i])
}
stock_file <- file.path(database_dir, "stocks.csv")
stock_connection <- file(stock_file, "rb")
stock_bytes <- readBin(stock_connection, "raw", n = file.info(stock_file)[["size"]])
close(stock_connection)

observations <- source_inputs[source_inputs$measure == "numbers_at_age", , drop = FALSE]
catch <- observations[observations$type == "catch", , drop = FALSE]
indices <- observations[observations$type == "index", , drop = FALSE]
q4 <- indices[indices$survey == "Q4Solesurvey1-9+", , drop = FALSE]
gillnet <- indices[indices$survey == "Gillnet", , drop = FALSE]
trawl <- indices[indices$survey == "Trawl", , drop = FALSE]

cv <- source_inputs[source_inputs$measure == "relative_standard_error", , drop = FALSE]
precision <- source_inputs[source_inputs$measure == "relative_precision_weight", , drop = FALSE]
precision_index <- match(paste(precision$year, precision$age), paste(cv$year, cv$age))
cv_value <- as.numeric(cv$value[precision_index])
weight_value <- as.numeric(precision$value)

n_at_age <- source_outputs[
  source_outputs$type == "population" & source_outputs$measure == "numbers_at_age",
  , drop = FALSE
]
total_numbers <- source_outputs[
  source_outputs$measure == "total_numbers", , drop = FALSE
]
expected_total <- stats::aggregate(as.numeric(n_at_age$value),
  list(year = n_at_age$year), sum
)
total_index <- match(expected_total$year, total_numbers$year)

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "sol.27.20-24",
  stock$common_name == "Common sole",
  stock$ocean == "Northeast Atlantic",
  !any(stock_bytes == as.raw(0L)),
  nrow(detailed) == 1L,
  !detailed$is_current,
  detailed$assessment_year == 2025,
  detailed$terminal_year == 2024,
  detailed$inputs_status == "complete",
  detailed$outputs_status == "complete",
  nrow(summary) == 1L,
  summary$is_current,
  summary$model_family == "SAM",
  summary$inputs_status == "partial",
  summary$outputs_status == "partial",
  summary$assessment_type == "annual_assessment",
  summary$assessment_year == 2026,
  summary$assessment_url == "https://doi.org/10.17895/ices.pub.32455056.v3",
  any(inputs$assessment_id == summary_id),
  nrow(catch) == 328L,
  all(catch$year %in% 1984:2024),
  setequal(unique(catch$age), 2:9),
  all(catch$fleet == "Residual catch"),
  all(catch$unit == "thousand fish"),
  nrow(q4) == 189L,
  sum(is.na(q4$value)) == 18L,
  sum(is.finite(q4$value)) == 171L,
  setequal(unique(q4$age), 1:9),
  setequal(unique(q4$year), 2004:2024),
  all(q4$sampling_time == 0.8754645),
  nrow(gillnet) == 98L,
  setequal(unique(gillnet$age), 2:8),
  setequal(unique(gillnet$year), 1994:2007),
  all(gillnet$sampling_time == 0.56),
  nrow(trawl) == 110L,
  setequal(unique(trawl$age), 2:6),
  setequal(unique(trawl$year), 1987:2008),
  all(trawl$sampling_time == 0.875),
  length(precision_index) == 171L,
  !anyNA(precision_index),
  max(abs(weight_value - 1 / (cv_value / mean(as.numeric(cv$value)))^2)) < 1e-8,
  all(source_inputs$value[source_inputs$measure == "natural_mortality_at_age"] == 0.1),
  identical(as.numeric(source_inputs$value[source_inputs$measure == "maturity_at_age"]), c(0, 0, rep(1, 7))),
  nrow(n_at_age[as.integer(n_at_age$year) %in% 1984:2024, ]) == 369L,
  nrow(source_outputs[source_outputs$measure == "fishing_mortality_at_age" & as.integer(source_outputs$year) %in% 1984:2024, ]) == 328L,
  nrow(predicted_catch) == 328L,
  all(predicted_catch$fleet == "Residual catch"),
  nrow(predicted_index) == 397L,
  setequal(unique(predicted_index$survey), c("Q4Solesurvey1-9+", "Gillnet", "Trawl")),
  sum(predicted_index$survey == "Q4Solesurvey1-9+") == 189L,
  !any(source_outputs$measure == "natural_mortality_at_age"),
  all(!is.na(total_index)),
  max(abs(as.numeric(total_numbers$value[total_index]) - expected_total$x)) < 1e-7,
  nrow(summary_outputs) == 128L,
  source_outputs$value[source_outputs$measure == "recruitment" & source_outputs$year == 2024] == 1231,
  source_outputs$value[source_outputs$measure == "SSB" & source_outputs$year == 2024] == 1408,
  summary_outputs$value[summary_outputs$measure == "recruitment" & summary_outputs$year == 2024] == 1408,
  summary_outputs$value[summary_outputs$measure == "SSB" & summary_outputs$year == 2024] == 1469,
  summary_outputs$value[summary_outputs$measure == "SSB" & summary_outputs$year == 2026] == 1491
)

stopifnot(
  nrow(q_outputs) == 12L,
  identical(
    unname(expected_q_keys),
    do.call(rbind, lapply(2:4, function(i) {
      as.integer(fit$conf$keyLogFpar[i, ])
    }))
  ),
  all(q_outputs$source_type == "native_model"),
  all(is.na(q_outputs$year)),
  all(q_outputs$unit == "native survey index units per thousand fish (physical index unit unresolved)"),
  setequal(
    paste(q_outputs$survey[!is.na(q_outputs$age_group)],
      q_outputs$age_group[!is.na(q_outputs$age_group)], sep = ":"),
    c("Q4Solesurvey1-9+:4-9", "Gillnet:5-8", "Trawl:5-6")
  )
)
expected_q_ages <- list(
  "Q4Solesurvey1-9+" = 1:9,
  Gillnet = 2:8,
  Trawl = 2:6
)
for (survey in names(expected_q_ages)) {
  survey_rows <- which(q_outputs$survey == survey)
  covered_ages <- sort(unlist(lapply(survey_rows, q_group_ages)))
  stopifnot(identical(as.integer(covered_ages), expected_q_ages[[survey]]))
}
for (i in seq_len(nrow(q_outputs))) {
  survey_row <- match(q_outputs$survey[i], q_survey_names) + 1L
  mapped_ages <- q_group_ages(i)
  parameter_key <- unique(as.integer(fit$conf$keyLogFpar[survey_row, mapped_ages]))
  stopifnot(length(parameter_key) == 1L, parameter_key >= 0L)
  parameter <- parameter_key + 1L
  log_estimate <- fit$pl$logFpar[parameter]
  log_se <- fit$plsd$logFpar[parameter]
  estimate <- exp(log_estimate)
  stopifnot(
    abs(as.numeric(q_outputs$value[i]) - estimate) < 1e-12,
    abs(as.numeric(q_outputs$se[i]) - estimate * log_se) < 1e-12,
    abs(as.numeric(q_outputs$lwr[i]) - exp(log_estimate - qnorm(0.975) * log_se)) < 1e-12,
    abs(as.numeric(q_outputs$upr[i]) - exp(log_estimate + qnorm(0.975) * log_se)) < 1e-12
  )
}

cat("ICES sole 20–24 source records passed.\n")
