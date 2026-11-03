root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_plaice_baltic_21_32_2026")
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "ple.27.21.32_WGBFAS_2026_SA/run/model.RData"
)
assessment_id <- "ices_plaice_baltic_21_32_2026"
model_path <- file.path(cache, "run__model.RData")
if (!file.exists(model_path)) stop("The cached official SAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$fit
survey_names <- unname(attr(fit$data, "fleetNames")[2:3])
expected_surveys <- c("Q1IBTS+BITS1-7+", "Q4IBTS+BITS1-7+")
expected_keys <- rbind(
  c(0L, 1L, 2L, 2L, 2L, 3L, 4L),
  c(5L, 6L, 7L, 8L, 8L, 8L, 8L)
)
keys <- rbind(
  as.integer(fit$conf$keyLogFpar[2L, ]),
  as.integer(fit$conf$keyLogFpar[3L, ])
)
if (fit$opt$convergence != 0L ||
  !identical(as.integer(fit$data$years), 2002:2025) ||
  !identical(survey_names, expected_surveys) ||
  !identical(dim(keys), c(2L, 7L)) ||
  !identical(keys, expected_keys) ||
  length(fit$pl$logFpar) != 9L ||
  length(fit$plsd$logFpar) != 9L) {
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
new_output <- function(survey, age, age_group, key) {
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
      "age 7 is the terminal 7+ group."
    ),
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

q_rows <- do.call(rbind, lapply(seq_len(2L), function(i) {
  survey_keys <- keys[i, ]
  parameter_keys <- sort(unique(survey_keys))
  do.call(rbind, lapply(parameter_keys, function(key) {
    ages <- which(survey_keys == key)
    age_group <- if (identical(ages, 7L)) {
      "7+"
    } else if (length(ages) > 1L) {
      paste(range(ages), collapse = "-")
    } else {
      ""
    }
    age <- if (nzchar(age_group)) NA_integer_ else ages
    new_output(survey_names[i], age, age_group, key)
  }))
}))
q_rows <- q_rows[output_schema]

if (nrow(q_rows) != 9L || anyDuplicated(q_rows[c("survey", "age", "age_group")])) {
  stop("The expected nine unique native q estimates were not constructed.", call. = FALSE)
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
  cat("Imported nine native q outputs; outputs_status remains partial because other source-output differences are unresolved.\n")
} else {
  cat("The nine native q outputs already match the cached SAM fit; no rows were added.\n")
}
