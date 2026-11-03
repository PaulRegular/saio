root <- normalizePath(".", winslash = "/", mustWork = TRUE)
cache <- file.path(root, "source_cache/ices_haddock_north_sea_2026")
input_file <- file.path(root, "database/inputs.csv")
assessment_id <- "ices_haddock_north_sea_2026"
model_url <- paste0(
  "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/",
  "NShaddock_WGNSSK2026_Run1/run/model.RData"
)

model_env <- new.env(parent = baseenv())
load(file.path(cache, "run_model.RData"), envir = model_env)
dat <- model_env$fit$data
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")
weight <- as.numeric(dat$weight)
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)

stopifnot(
  nrow(aux) == length(weight),
  length(fleet_names) >= 3L,
  length(sample_times) >= 3L,
  all(aux$fleet %in% seq_along(fleet_names)),
  all(is.na(weight[aux$fleet == 1L])),
  all(!is.na(weight[aux$fleet %in% 2:3])),
  all(is.finite(weight[!is.na(weight)])),
  all(weight[!is.na(weight)] > 0)
)

take <- which(!is.na(weight))
rows <- data.frame(
  assessment_id = assessment_id,
  type = "index",
  measure = "relative_precision_weight",
  basis = "relative_precision",
  fleet = "",
  survey = as.character(fleet_names[aux$fleet[take]]),
  sex = "",
  region = "",
  season = "",
  year = as.integer(aux$year[take]),
  year_basis = "calendar_year",
  age = as.integer(aux$age[take]),
  value = weight[take],
  unit = "relative precision weight",
  sampling_time = sample_times[aux$fleet[take]],
  source_type = "native_model",
  source_reference = paste0(model_url, "; fit$data$weight"),
  transformation = "",
  notes = paste(
    "Native SAM relative precision weight, assigned by year, survey and age.",
    "Derived from CV as 1/log(1 + CV^2); the corresponding supplied",
    "relative log-scale SD factor is 1/sqrt(weight)."
  ),
  observation_id = "",
  length_bin = "",
  length_bin_lower = "",
  length_bin_upper = "",
  sample_size = "",
  age_error = "",
  partition = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(rows) == 667L,
  identical(
    unname(as.integer(table(rows$survey)[c(
      "delta-GAMNS-WCQ1", "delta-GAMNS-WCQ3+Q4"
    )])),
    c(352L, 315L)
  ),
  !anyDuplicated(paste(rows$survey, rows$year, rows$age, sep = "\034"))
)

native <- read.csv(
  file.path(cache, "native_observations.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
native <- native[!is.na(native$weight), ]
native$survey <- native$fleet_name
joined <- merge(
  rows[, c("survey", "year", "age", "value")],
  native[, c("survey", "year", "age", "weight")],
  by = c("survey", "year", "age"),
  all = TRUE
)
stopifnot(
  nrow(joined) == 667L,
  !anyNA(joined$value),
  !anyNA(joined$weight),
  max(abs(joined$value - joined$weight)) < 1e-12
)

inputs <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)
key_columns <- c("assessment_id", "type", "measure", "survey", "year", "age")
row_key <- function(x) {
  values <- lapply(x[key_columns], function(z) {
    z[is.na(z)] <- ""
    as.character(z)
  })
  do.call(paste, c(values, sep = "\034"))
}
existing <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
if (anyDuplicated(row_key(existing))) {
  stop("Existing Northern Shelf haddock input keys are duplicated.")
}
existing_keys <- row_key(existing)
new_keys <- row_key(rows)
append_rows <- rows[FALSE, , drop = FALSE]

same_value <- function(existing_value, expected_value, column) {
  if (column %in% c("year", "age", "value", "sampling_time")) {
    return(isTRUE(all.equal(
      as.numeric(existing_value),
      as.numeric(expected_value),
      tolerance = 1e-12
    )))
  }
  normalize <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  }
  identical(normalize(existing_value), normalize(expected_value))
}

for (i in seq_len(nrow(rows))) {
  match_row <- which(existing_keys == new_keys[i])
  if (length(match_row) > 1L) {
    stop("Northern Shelf haddock observation-weight key is not unique.")
  }
  if (!length(match_row)) {
    append_rows <- rbind(append_rows, rows[i, , drop = FALSE])
  } else {
    for (column in names(rows)) {
      if (!same_value(existing[match_row, column], rows[i, column], column)) {
        stop("Existing observation-weight record conflicts with the official SAM fit.")
      }
    }
  }
}

if (nrow(append_rows)) {
  write.table(
    append_rows,
    file = input_file,
    sep = ",",
    quote = TRUE,
    row.names = FALSE,
    col.names = FALSE,
    append = TRUE,
    na = ""
  )
}
cat("Added", nrow(append_rows), "native survey precision-weight records.\n")
