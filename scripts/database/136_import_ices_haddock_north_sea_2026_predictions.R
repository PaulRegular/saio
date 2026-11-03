assessment_id <- "ices_haddock_north_sea_2026"
root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", assessment_id)
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NShaddock_WGNSSK2026_Run1/run/model.RData"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "run_model.RData"), envir = model_env)
fit <- model_env$fit
if (is.null(fit) || fit$opt$convergence != 0L) {
  stop("The cached official SAM fit is missing or did not converge.", call. = FALSE)
}
aux <- as.data.frame(fit$data$aux)
prediction <- exp(as.numeric(fit$rep$predObs))
fleet_names <- c("Residual catch", "", "")
survey_names <- c("", "delta-GAMNS-WCQ1", "delta-GAMNS-WCQ3+Q4")
expected_counts <- c(486L, 352L, 315L)
if (!identical(names(aux), c("year", "fleet", "age")) ||
  !identical(as.integer(table(factor(aux$fleet, levels = 1:3))), expected_counts) ||
  length(prediction) != nrow(aux) || any(!is.finite(prediction))) {
  stop("The cached 2026 SAM fit or fitted observation rows differ from the reviewed run.",
    call. = FALSE
  )
}

output_header <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0L,
  colClasses = "character", check.names = FALSE
))
output_rows <- function(type, measure, year, age, value, unit, source_reference,
                        notes, fleet = "", survey = "") {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_header)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_header
  put <- function(field, x) {
    x <- rep_len(x, n)
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
  put("value", format(value, digits = 15, scientific = FALSE, trim = TRUE))
  put("unit", unit)
  put("source_type", "native_model")
  put("source_reference", source_reference)
  put("notes", notes)
  out
}

prediction_rows <- list()
for (model_fleet in 1:3) {
  rows <- which(as.integer(aux$fleet) == model_fleet)
  is_catch <- model_fleet == 1L
  prediction_rows[[model_fleet]] <- output_rows(
    type = if (is_catch) "catch" else "index",
    measure = if (is_catch) "predicted_catch" else "predicted_index",
    year = as.integer(aux$year[rows]), age = as.integer(aux$age[rows]),
    value = prediction[rows],
    unit = if (is_catch) "thousand fish" else "native survey index",
    source_reference = paste0(
      model_url, "; fit$rep$predObs aligned to fit$data$aux"
    ),
    notes = paste(
      "Exponentiated fitted SAM log-observation prediction in native row order.",
      "No prediction uncertainty is available in the reported fit output."
    ),
    fleet = fleet_names[[model_fleet]], survey = survey_names[[model_fleet]]
  )
}
new_rows <- do.call(rbind, prediction_rows)
new_rows <- new_rows[output_header]

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
expected_key <- do.call(rbind, lapply(1:3, function(model_fleet) {
  rows <- which(as.integer(aux$fleet) == model_fleet)
  data.frame(
    assessment_id = assessment_id,
    type = if (model_fleet == 1L) "catch" else "index",
    measure = if (model_fleet == 1L) "predicted_catch" else "predicted_index",
    fleet = fleet_names[[model_fleet]], survey = survey_names[[model_fleet]],
    sex = "", region = "", season = "", year = as.integer(aux$year[rows]),
    age = as.integer(aux$age[rows]), age_group = "",
    stringsAsFactors = FALSE
  )
}))
if (nrow(new_rows) != 1153L || anyDuplicated(row_key(new_rows)) ||
  !setequal(row_key(new_rows), row_key(expected_key))) {
  stop("The expected 1,153 unique fitted catch/index predictions were not created.",
    call. = FALSE
  )
}

outputs_path <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = c("", "NA"),
  check.names = FALSE, stringsAsFactors = FALSE
)
existing <- outputs[outputs$assessment_id == assessment_id &
  outputs$measure %in% c("predicted_catch", "predicted_index"), , drop = FALSE]
if (nrow(existing)) {
  if (!setequal(row_key(existing), row_key(new_rows))) {
    stop("The database contains only part of the expected fitted prediction rows.",
      call. = FALSE
    )
  }
  matched <- match(row_key(new_rows), row_key(existing))
  if (!isTRUE(all.equal(
    as.numeric(new_rows$value), as.numeric(existing$value[matched]),
    tolerance = 1e-12, check.attributes = FALSE
  ))) stop("Existing fitted predictions differ from the cached SAM fit.", call. = FALSE)
  for (field in setdiff(output_header, c(key_fields, "value", "se", "lwr", "upr"))) {
    if (!identical(as.character(new_rows[[field]]),
      as.character(existing[[field]][matched]))) {
      stop("Existing prediction metadata differs from the source: ", field,
        call. = FALSE
      )
    }
  }
  message("Verified existing fitted predictions; no rows added.")
} else {
  utils::write.table(new_rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  message("Added 1,153 fitted catch and survey predictions.")
}
