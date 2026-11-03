assessment_id <- "ices_plaice_irish_sea_7a_2026"
root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", assessment_id)
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "Ple.7a_26/run/model.RData"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "run_model.RData"), envir = model_env)
fit <- model_env$fit
if (is.null(fit) || fit$opt$convergence != 0L) {
  stop("The cached official SAM fit is missing or did not converge.", call. = FALSE)
}

fleet_names <- c(
  "Residual catch", "UK BTS-Q3", "NIGFS-WIBTS-Q1", "NIGFS-WIBTS-Q4"
)
years <- as.integer(fit$data$years)
ages <- seq.int(fit$conf$minAge, fit$conf$maxAge)
keys <- as.matrix(fit$conf$keyLogFpar)
log_q <- as.numeric(fit$pl$logFpar)
log_q_se <- as.numeric(fit$plsd$logFpar)
fixed_log_q <- fit$sdrep$par.fixed[names(fit$sdrep$par.fixed) == "logFpar"]
fixed_log_q_se <- sqrt(diag(fit$sdrep$cov.fixed))[
  names(fit$sdrep$par.fixed) == "logFpar"
]
aux <- as.data.frame(fit$data$aux)
prediction <- exp(as.numeric(fit$rep$predObs))

expected_keys <- matrix(-1L, nrow = 4L, ncol = 8L)
expected_keys[2L, 1:7] <- 0:6
expected_keys[3L, 1L] <- 7L
expected_keys[4L, 1L] <- 8L
if (!identical(dim(keys), c(4L, 8L)) ||
  !identical(unname(as.integer(keys)), unname(as.integer(expected_keys))) ||
  !identical(years, 1981:2025) || !identical(ages, 1:8) ||
  length(log_q) != 9L || length(log_q_se) != 9L ||
  !isTRUE(all.equal(log_q, as.numeric(fixed_log_q), tolerance = 1e-12)) ||
  !isTRUE(all.equal(log_q_se, as.numeric(fixed_log_q_se), tolerance = 1e-10)) ||
  !identical(names(aux), c("year", "fleet", "age")) ||
  !identical(as.integer(table(factor(aux$fleet, levels = 1:4))),
    c(360L, 231L, 34L, 34L)) ||
  length(prediction) != nrow(aux) || any(!is.finite(prediction))) {
  stop("The archived fit differs from the reviewed q keys or prediction rows.",
    call. = FALSE
  )
}

output_header <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0L,
  colClasses = "character", check.names = FALSE
))
output_rows <- function(type, measure, year, age = NA_integer_,
                        age_group = "", value, se = NA_real_, lwr = NA_real_,
                        upr = NA_real_, unit, source_type = "native_model",
                        source_reference, notes, fleet = "", survey = "") {
  keep <- is.finite(value)
  out <- as.data.frame(matrix("", nrow = sum(keep), ncol = length(output_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_header
  put <- function(field, x) {
    x <- rep_len(x, length(value))[keep]
    x[is.na(x)] <- ""
    out[[field]] <<- as.character(x)
  }
  put("assessment_id", assessment_id)
  put("type", type)
  put("measure", measure)
  put("fleet", fleet)
  put("survey", survey)
  put("year", year)
  put("age", age)
  put("age_group", age_group)
  for (field in c("value", "se", "lwr", "upr")) {
    x <- get(field)
    put(field, ifelse(is.finite(x),
      format(x, digits = 15, scientific = FALSE, trim = TRUE), ""))
  }
  put("unit", unit)
  put("source_type", source_type)
  put("source_reference", source_reference)
  put("notes", notes)
  out
}

z <- stats::qnorm(0.975)
q_rows <- list()
for (model_fleet in 2:4) {
  fleet_keys <- as.integer(keys[model_fleet, ])
  for (key in sort(unique(fleet_keys[fleet_keys >= 0L]))) {
    q_ages <- ages[fleet_keys == key]
    aggregate_ssb_index <- fit$conf$keyBiomassTreat[model_fleet] == 0L
    q_age <- if (aggregate_ssb_index) NA_integer_ else q_ages
    q_age_group <- if (aggregate_ssb_index || length(q_ages) == 1L) {
      ""
    } else {
      paste(range(q_ages), collapse = "-")
    }
    q_value <- exp(log_q[key + 1L])
    q_log_se <- log_q_se[key + 1L]
    q_rows[[length(q_rows) + 1L]] <- output_rows(
      "catchability", "q", year = NA_integer_, age = q_age,
      age_group = q_age_group, value = q_value,
      se = q_value * q_log_se,
      lwr = exp(log_q[key + 1L] - z * q_log_se),
      upr = exp(log_q[key + 1L] + z * q_log_se),
      unit = if (aggregate_ssb_index) {
        "native survey-index units per tonne SSB"
      } else {
        "native survey-index units per thousand fish"
      },
      source_reference = paste0(
        model_url, "; fit$pl$logFpar, fit$plsd$logFpar, and fit$conf$keyLogFpar"
      ),
      notes = paste(
        "Exponentiated fitted SAM log-q parameter.",
        "SE is delta-method natural-scale; limits are 95% Wald intervals on the log scale.",
        if (aggregate_ssb_index) {
          "This q scales the aggregate SSB index; no fish age applies."
        } else {
          "UK BTS q is age-specific for ages 1-7."
        },
        "The source does not state the physical UK BTS index scale."
      ),
      survey = fleet_names[[model_fleet]]
    )
  }
}
q_rows <- do.call(rbind, q_rows)

prediction_rows <- list()
for (model_fleet in 1:4) {
  rows <- which(as.integer(aux$fleet) == model_fleet)
  is_catch <- model_fleet == 1L
  prediction_rows[[length(prediction_rows) + 1L]] <- output_rows(
    if (is_catch) "catch" else "index",
    if (is_catch) "predicted_catch" else "predicted_index",
    year = as.integer(aux$year[rows]),
    age = if (is_catch || model_fleet == 2L) as.integer(aux$age[rows]) else NA_integer_,
    value = prediction[rows],
    unit = if (is_catch) {
      "thousand fish"
    } else if (model_fleet == 2L) {
      "native survey-index units"
    } else {
      "kg per 3 miles"
    },
    source_reference = paste0(
      model_url, "; fit$rep$predObs aligned to fit$data$aux"
    ),
    notes = paste(
      "Exponentiated fitted SAM log-observation predictions in native row order.",
      "Predictions are retained for rows whose observed value was missing."
    ),
    fleet = if (is_catch) fleet_names[[model_fleet]] else "",
    survey = if (is_catch) "" else fleet_names[[model_fleet]]
  )
}
prediction_rows <- do.call(rbind, prediction_rows)
new_rows <- rbind(q_rows, prediction_rows)
new_rows <- new_rows[output_header]

key_fields <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group"
)
row_key <- function(x) {
  fields <- lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(fields, sep = "\r"))
}
if (anyDuplicated(row_key(new_rows)) || nrow(q_rows) != 9L ||
  nrow(prediction_rows) != 659L) {
  stop("Unexpected number or duplication of q/prediction output rows.", call. = FALSE)
}

outputs_path <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
existing <- outputs[outputs$assessment_id == assessment_id &
  outputs$type %in% c("catchability", "catch", "index") &
  outputs$measure %in% c("q", "predicted_catch", "predicted_index"), , drop = FALSE]
if (nrow(existing)) {
  if (!setequal(row_key(existing), row_key(new_rows))) {
    stop("The database contains only part of the expected q/prediction outputs.",
      call. = FALSE
    )
  }
  matched <- match(row_key(new_rows), row_key(existing))
  for (field in c("value", "se", "lwr", "upr")) {
    expected <- suppressWarnings(as.numeric(new_rows[[field]]))
    actual <- suppressWarnings(as.numeric(existing[[field]][matched]))
    if (!isTRUE(all.equal(expected, actual, tolerance = 1e-12,
      check.attributes = FALSE))) {
      stop("Existing fitted output differs from the SAM fit: ", field,
        call. = FALSE
      )
    }
  }
  for (field in setdiff(output_header, c(key_fields, "value", "se", "lwr", "upr"))) {
    if (!identical(as.character(new_rows[[field]]),
      as.character(existing[[field]][matched]))) {
      stop("Existing fitted output differs from the SAM fit: ", field,
        call. = FALSE
      )
    }
  }
  message("Verified existing q and fitted prediction outputs; no rows added.")
} else {
  utils::write.table(new_rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  message("Added 9 q estimates and 659 fitted catch/index predictions.")
}
