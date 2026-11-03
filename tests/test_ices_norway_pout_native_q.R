root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database_dir <- file.path(root, "analysis", "comp_assessments", "database")
assessment_id <- "ices_norway_pout_north_sea_2026_benchmark"
read_table <- function(name) read.csv(
  file.path(database_dir, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)

outputs <- read_table("outputs.csv")
q <- outputs[
  outputs$assessment_id == assessment_id & outputs$type == "catchability" &
    outputs$measure == "q", , drop = FALSE
]
fit_env <- new.env(parent = baseenv())
load(file.path(root, "analysis", "comp_assessments", "source_cache",
  assessment_id, "native", "sum.RData"), envir = fit_env)
fit <- fit_env$sesamsum
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
  as.integer(fit$data$keyLogQ), nrow = nrow(fit$data$keyLogQ),
  ncol = ncol(fit$data$keyLogQ)
)

normalize <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
stopifnot(
  nrow(q) == 13L,
  identical(keys, expected_keys),
  fit$opt$convergence == 0L,
  identical(as.numeric(fit$plsd$logQ), as.numeric(fit$pl$logQ)),
  all(q$source_type == "native_model"),
  all(q$unit == "native index coefficient"),
  all(is.na(q$year)),
  all(is.na(q$se)),
  all(is.na(q$lwr)),
  all(is.na(q$upr)),
  setequal(q$survey, survey_names)
)

for (survey_index in seq_along(survey_names)) {
  survey <- survey_names[[survey_index]]
  key_row <- keys[survey_index + 1L, ]
  for (key in sort(unique(key_row[!is.na(key_row)]))) {
    ages <- which(key_row == key) - 1L
    age_group <- if (length(ages) > 1L) {
      paste(range(ages), collapse = "-")
    } else if (ages == 3L) {
      "3+"
    } else {
      ""
    }
    row <- q[q$survey == survey & normalize(q$age_group) == age_group, , drop = FALSE]
    if (length(ages) == 1L) {
      row <- row[as.integer(row$age) == ages, , drop = FALSE]
    } else {
      row <- row[is.na(row$age), , drop = FALSE]
    }
    stopifnot(
      nrow(row) == 1L,
      abs(as.numeric(row$value) - exp(fit$pl$logQ[key + 1L])) < 1e-12,
      grepl("fit\\$pl\\$logQ and fit\\$data\\$keyLogQ", row$source_reference)
    )
  }
}

cat("Norway pout native q outputs passed.\n")
