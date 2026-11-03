root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_sole_20_24_2025")
assessment_id <- "ices_sole_20_24_2025"
source_dir <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "Sole20_24_2025_new_indicesCV_conf"
)
model_url <- paste0(source_dir, "/run/model.RData")
model_path <- file.path(cache, "run", "model.RData")
if (!file.exists(model_path)) stop("The cached official SAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$fit
survey_names <- unname(attr(fit$data, "fleetNames")[2:4])
expected_surveys <- c("Q4Solesurvey1-9+", "Gillnet", "Trawl")
expected_keys <- rbind(
  c(0L, 1L, 2L, 3L, 3L, 3L, 3L, 3L, 3L),
  c(-1L, 4L, 5L, 6L, 7L, 7L, 7L, 7L, -1L),
  c(-1L, 8L, 9L, 10L, 11L, 11L, -1L, -1L, -1L)
)
keys <- do.call(rbind, lapply(2:4, function(i) {
  as.integer(fit$conf$keyLogFpar[i, ])
}))
if (fit$opt$convergence != 0L ||
  !identical(as.integer(fit$data$years), 1984:2024) ||
  !identical(survey_names, expected_surveys) ||
  !identical(dim(keys), c(3L, 9L)) ||
  !identical(keys, expected_keys) ||
  length(fit$pl$logFpar) != 12L ||
  length(fit$plsd$logFpar) != 12L) {
  stop("The cached fit or configured q age blocks differ from the reviewed SAM run.", call. = FALSE)
}
log_q <- as.numeric(fit$pl$logFpar)
log_q_se <- as.numeric(fit$plsd$logFpar)
if (any(!is.finite(log_q)) || any(!is.finite(log_q_se)) || any(log_q_se < 0)) {
  stop("The SAM q estimates and standard errors must be finite.", call. = FALSE)
}

output_schema <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0L,
  colClasses = "character", check.names = FALSE
))
q_output <- function(survey, age, age_group, key) {
  parameter <- key + 1L
  estimate <- exp(log_q[parameter])
  se_log <- log_q_se[parameter]
  data.frame(
    assessment_id = assessment_id, type = "catchability", measure = "q",
    fleet = "", survey = survey, sex = "", region = "", season = "",
    year = "", age = ifelse(is.na(age), "", as.character(age)),
    age_group = age_group, value = estimate, se = estimate * se_log,
    lwr = exp(log_q[parameter] - stats::qnorm(0.975) * se_log),
    upr = exp(log_q[parameter] + stats::qnorm(0.975) * se_log),
    unit = "native survey index units per thousand fish (physical index unit unresolved)",
    source_type = "native_model",
    source_reference = paste0(
      model_url,
      "; fit$conf$keyLogFpar, fit$pl$logFpar, and fit$plsd$logFpar"
    ),
    notes = paste(
      "Natural-scale q is exp(logFpar); its SE is converted from the native",
      "log-q SE by the delta method. Limits are a normal-approximation 95%",
      "interval on log-q. Age groups follow the configured SAM sharing keys;",
      "age 9 is the terminal 9+ group."
    ),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

q_rows <- do.call(rbind, lapply(seq_along(survey_names), function(i) {
  survey_keys <- keys[i, ]
  parameter_keys <- sort(unique(survey_keys[survey_keys >= 0L]))
  do.call(rbind, lapply(parameter_keys, function(key) {
    ages <- which(survey_keys == key)
    age_group <- if (length(ages) > 1L) paste(range(ages), collapse = "-") else ""
    age <- if (nzchar(age_group)) NA_integer_ else ages
    q_output(survey_names[i], age, age_group, key)
  }))
}))
q_rows <- q_rows[output_schema]

if (nrow(q_rows) != 12L ||
  anyDuplicated(q_rows[c("survey", "age", "age_group")])) {
  stop("The expected twelve unique native q estimates were not constructed.", call. = FALSE)
}

key_fields <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group"
)
row_key <- function(x) {
  values <- lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\r"))
}
outputs_path <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
existing_q <- outputs[
  outputs$assessment_id == assessment_id & outputs$type == "catchability" &
    outputs$measure == "q", , drop = FALSE
]
if (nrow(existing_q)) {
  if (nrow(existing_q) != nrow(q_rows) ||
    !setequal(row_key(existing_q), row_key(q_rows))) {
    stop("The database contains only part of the expected native q output set.", call. = FALSE)
  }
  matched <- match(row_key(q_rows), row_key(existing_q))
  for (field in c("value", "se", "lwr", "upr")) {
    if (!isTRUE(all.equal(
      as.numeric(q_rows[[field]]), as.numeric(existing_q[[field]][matched]),
      tolerance = 1e-12
    ))) stop("Existing q output differs from the cached SAM fit: ", field, call. = FALSE)
  }
  for (field in c("unit", "source_type", "source_reference", "notes")) {
    if (!identical(as.character(q_rows[[field]]), as.character(existing_q[[field]][matched]))) {
      stop("Existing q output differs from the source record: ", field, call. = FALSE)
    }
  }
  q_rows <- q_rows[FALSE, , drop = FALSE]
}

if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", nrow(q_rows), " new native q rows would be written.\n", sep = "")
  print(q_rows[c("survey", "age", "age_group", "value", "se", "lwr", "upr")])
} else if (nrow(q_rows)) {
  utils::write.table(
    q_rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  cat("Imported twelve native q outputs; outputs_status remains partial because forecast outputs remain incomplete.\n")
} else {
  cat("The twelve native q outputs already match the cached SAM fit; no rows were added.\n")
}
