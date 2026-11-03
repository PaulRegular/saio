assessment_id <- "ices_norway_pout_north_sea_2026_benchmark"
root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", assessment_id, "native")
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NP_Sep2025_bench_final_Mfor/run/sum.RData"
)
model_path <- file.path(cache, "sum.RData")
if (!file.exists(model_path)) stop("The cached official SESAM fit is missing.", call. = FALSE)

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$sesamsum
survey_names <- c(
  "IBTS Q1 (north of 57N)",
  "EGFS Q3",
  "SGFS Q3 (age-0 through 2012; ages 1-3+ thereafter)",
  "IBTS other countries Q3",
  "SGFS Q3 age 0 (2013 onward)"
)
expected_keys <- matrix(NA_integer_, nrow = 6L, ncol = 4L)
expected_keys[2L, 2:4] <- 0:2
expected_keys[3L, ] <- c(3L, 4L, 5L, 5L)
expected_keys[4L, ] <- c(6L, 7L, 8L, 8L)
expected_keys[5L, 1:3] <- 9:11
expected_keys[6L, 1L] <- 12L
keys <- matrix(
  as.integer(fit$data$keyLogQ),
  nrow = nrow(fit$data$keyLogQ), ncol = ncol(fit$data$keyLogQ)
)
log_q <- as.numeric(fit$pl$logQ)
if (fit$opt$convergence != 0L ||
  !identical(keys, expected_keys) ||
  length(log_q) != 13L ||
  !identical(sort(unique(as.integer(keys[!is.na(keys)]))), 0:12) ||
  any(!is.finite(log_q))) {
  stop("The cached SESAM fit or q-sharing keys differ from the reviewed benchmark.",
    call. = FALSE
  )
}

output_schema <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0L,
  colClasses = "character", check.names = FALSE
))
q_rows <- do.call(rbind, lapply(seq_along(survey_names), function(i) {
  key_row <- keys[i + 1L, ]
  parameter_keys <- sort(unique(as.integer(key_row[!is.na(key_row)])))
  do.call(rbind, lapply(parameter_keys, function(key) {
    ages <- which(key_row == key) - 1L
    age_group <- if (length(ages) > 1L) {
      paste(range(ages), collapse = "-")
    } else if (ages == 3L) {
      "3+"
    } else {
      ""
    }
    data.frame(
      assessment_id = assessment_id, type = "catchability", measure = "q",
      fleet = "", survey = survey_names[[i]], sex = "", region = "",
      season = "", year = "", age = if (length(ages) == 1L) ages else "",
      age_group = age_group, value = exp(log_q[key + 1L]), se = NA_real_,
      lwr = NA_real_, upr = NA_real_, unit = "native index coefficient",
      source_type = "native_model",
      source_reference = paste0(
        model_url, "; fit$pl$logQ and fit$data$keyLogQ"
      ),
      notes = paste(
        "Natural-scale q is exp(logQ) using the native zero-based keyLogQ.",
        "Age 3 is the 3+ group; shared-age q keys are represented by age_group.",
        "The saved fit has no usable q uncertainty: plsd$logQ duplicates the",
        "point estimates, so standard errors and intervals are unavailable.",
        "Physical survey-index units are not specified."
      ),
      stringsAsFactors = FALSE, check.names = FALSE
    )
  }))
}))
q_rows <- q_rows[output_schema]
if (nrow(q_rows) != 13L ||
  anyDuplicated(q_rows[c("survey", "age", "age_group")])) {
  stop("The expected thirteen unique SESAM q estimates were not constructed.",
    call. = FALSE
  )
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
    stop("The database contains only part of the expected native q outputs.",
      call. = FALSE
    )
  }
  matched <- match(row_key(q_rows), row_key(existing_q))
  if (!isTRUE(all.equal(
    as.numeric(q_rows$value), as.numeric(existing_q$value[matched]),
    tolerance = 1e-12
  ))) stop("Existing q output differs from the cached SESAM fit.", call. = FALSE)
  for (field in c("se", "lwr", "upr")) {
    if (any(!is.na(existing_q[[field]][matched]))) {
      stop("Unexpected q uncertainty is recorded in ", field, ".", call. = FALSE)
    }
  }
  for (field in c("unit", "source_type", "source_reference", "notes")) {
    if (!identical(as.character(q_rows[[field]]),
      as.character(existing_q[[field]][matched]))) {
      stop("Existing q output differs from the source record: ", field,
        call. = FALSE
      )
    }
  }
  q_rows <- q_rows[FALSE, , drop = FALSE]
}

if (identical(Sys.getenv("SAIO_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", nrow(q_rows), " new SESAM q rows would be written.\n", sep = "")
  print(q_rows[c("survey", "age", "age_group", "value")])
} else if (nrow(q_rows)) {
  utils::write.table(
    q_rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  cat("Imported thirteen native q estimates; q uncertainty remains unavailable.\n")
} else {
  cat("The thirteen native q estimates already match the cached SESAM fit; no rows were added.\n")
}
