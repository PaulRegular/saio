assessment_id <- "ices_norway_pout_north_sea_2026_benchmark"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
database <- file.path(base, "database")
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NP_Sep2025_bench_final_Mfor/run/sum.RData"
)
model_path <- file.path(
  base, "source_cache", assessment_id, "native", "sum.RData"
)

if (!file.exists(model_path)) {
  stop("The cached official SESAM fit is missing.", call. = FALSE)
}

model_env <- new.env(parent = baseenv())
load(model_path, envir = model_env)
fit <- model_env$sesamsum
dat <- fit$data
survey_names <- c(
  "IBTS Q1 (north of 57N)",
  "EGFS Q3",
  "SGFS Q3 (age-0 through 2012; ages 1-3+ thereafter)",
  "IBTS other countries Q3",
  "SGFS Q3 age 0 (2013 onward)"
)
expected_fleets <- c(668L, 126L, 108L, 99L, 78L, 13L)

if (fit$opt$convergence != 0L ||
  length(dat$obs) != 1092L || length(fit$rep$predObs) != 1092L ||
  !identical(as.integer(table(dat$fleet)), expected_fleets) ||
  any(!is.finite(fit$rep$predObs))) {
  stop("The cached fitted predictions do not match the reviewed SESAM run.",
    call. = FALSE
  )
}

schema <- names(utils::read.csv(
  file.path(database, "outputs.csv"), nrows = 0L,
  colClasses = "character", check.names = FALSE
))
observations <- data.frame(
  year = floor(dat$t1 + 1e-8),
  quarter = as.integer(round((dat$t1 - floor(dat$t1 + 1e-8)) * 4) + 1),
  age_from = as.integer(dat$ageFrom),
  age_to = as.integer(dat$ageTo),
  fleet = as.integer(dat$fleet),
  value = exp(as.numeric(fit$rep$predObs)),
  stringsAsFactors = FALSE
)
if (any(!is.finite(observations$value)) || any(observations$value <= 0)) {
  stop("The exponentiated SESAM fitted predictions are invalid.", call. = FALSE)
}

age_group <- ifelse(
  observations$age_from == observations$age_to,
  ifelse(observations$age_from == 3L, "3+", ""),
  paste0(observations$age_from, "-", observations$age_to, "+")
)
is_catch <- observations$fleet == 1L
survey_id <- observations$fleet - 1L
value_text <- function(x) format(x, digits = 15, scientific = FALSE, trim = TRUE)
rows <- data.frame(
  assessment_id = assessment_id,
  type = ifelse(is_catch, "catch", "index"),
  measure = ifelse(is_catch, "predicted_catch", "predicted_index"),
  fleet = ifelse(is_catch, "Total catch", ""),
  survey = ifelse(is_catch, "", survey_names[pmax(survey_id, 1L)]),
  sex = "", region = "",
  season = paste0("Q", observations$quarter),
  year = as.character(observations$year),
  age = as.character(observations$age_from),
  age_group = age_group,
  value = value_text(observations$value),
  se = "", lwr = "", upr = "",
  unit = ifelse(is_catch, "million fish", "native survey-index units"),
  source_type = "native_model",
  source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$obs, t1, ageFrom, ageTo, fleet"),
  notes = paste(
    "Exponentiated the native log-scale SESAM fitted observation value and",
    "aligned it to the fitted observation row. Point estimates only; no",
    "bias correction or prediction uncertainty is added."
  ),
  stringsAsFactors = FALSE, check.names = FALSE
)
rows <- rows[schema]
key_fields <- c(
  "assessment_id", "type", "measure", "fleet", "survey", "season",
  "year", "age", "age_group"
)
row_key <- function(x) {
  values <- lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\r"))
}

if (anyDuplicated(row_key(rows)) || nrow(rows) != 1092L ||
  sum(rows$measure == "predicted_catch") != 668L ||
  sum(rows$measure == "predicted_index") != 424L) {
  stop("The fitted predictions do not form the expected unique observation rows.",
    call. = FALSE
  )
}

outputs_path <- file.path(database, "outputs.csv")
outputs <- utils::read.csv(
  outputs_path, colClasses = "character", na.strings = "",
  check.names = FALSE, stringsAsFactors = FALSE
)
existing <- outputs[
  outputs$assessment_id == assessment_id &
    outputs$measure %in% c("predicted_catch", "predicted_index"), , drop = FALSE
]
if (nrow(existing)) {
  if (nrow(existing) != nrow(rows) ||
    !setequal(row_key(existing), row_key(rows))) {
    stop("The database contains only part of the expected native predictions.",
      call. = FALSE
    )
  }
  matched <- match(row_key(rows), row_key(existing))
  if (!isTRUE(all.equal(
    as.numeric(rows$value), as.numeric(existing$value[matched]),
    tolerance = 1e-12
  ))) {
    stop("Existing prediction values differ from the cached SESAM fit.",
      call. = FALSE
    )
  }
  rows <- rows[FALSE, , drop = FALSE]
}

if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) {
  cat("Dry run passed: ", nrow(rows), " new fitted predictions would be written.\n", sep = "")
  print(table(rows$type, rows$measure))
} else if (nrow(rows)) {
  utils::write.table(
    rows, outputs_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
  cat("Imported 1,092 native SESAM fitted observation predictions.\n")
} else {
  cat("The 1,092 native SESAM fitted predictions already match the database.\n")
}
