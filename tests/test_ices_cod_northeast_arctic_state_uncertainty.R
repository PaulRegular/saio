root <- normalizePath(".", winslash = "/", mustWork = TRUE)
assessment_id <- "ices_cod_northeast_arctic_2026"
database_dir <- file.path(root, "analysis", "comp_assessments", "database")
outputs <- read.csv(
  file.path(database_dir, "outputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
assessment <- read.csv(
  file.path(database_dir, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)
fit_env <- new.env(parent = baseenv())
load(file.path(root, "analysis", "comp_assessments", "source_cache",
  assessment_id, "baserun_model.RData"), envir = fit_env)
fit <- fit_env$fit

random_names <- names(fit$sdrep$par.random)
random_variance <- as.numeric(fit$sdrep$diag.cov.random)
n_index <- which(random_names == "logN")
f_index <- which(random_names == "logF")
n_log_se <- matrix(sqrt(random_variance[n_index]), nrow = 13L)
f_log_se <- matrix(sqrt(random_variance[f_index]), nrow = 12L)
z <- qnorm(0.975)

n_expected <- expand.grid(age = 3:15, year = 1946:2026)
n_expected$log_estimate <- as.vector(fit$pl$logN)
n_expected$se_log <- as.vector(n_log_se)

f_expected <- expand.grid(age = 3:15, year = 1946:2025)
f_state_age <- pmin(f_expected$age - 2L, 12L)
f_state_year <- f_expected$year - 1946L + 1L
f_expected$log_estimate <- fit$pl$logF[cbind(f_state_age, f_state_year)]
f_expected$se_log <- f_log_se[cbind(f_state_age, f_state_year)]

check_surface <- function(expected, type, measure) {
  expected$value <- exp(expected$log_estimate)
  expected$se <- expected$value * expected$se_log
  expected$lwr <- exp(expected$log_estimate - z * expected$se_log)
  expected$upr <- exp(expected$log_estimate + z * expected$se_log)
  actual <- outputs[
    outputs$assessment_id == assessment_id & outputs$type == type &
      outputs$measure == measure, , drop = FALSE
  ]
  matched <- match(
    paste(expected$year, expected$age), paste(actual$year, actual$age)
  )
  stopifnot(
    nrow(actual) == nrow(expected), !anyNA(matched), !anyDuplicated(matched),
    isTRUE(all.equal(as.numeric(actual$value[matched]), expected$value, tolerance = 1e-10)),
    isTRUE(all.equal(as.numeric(actual$se[matched]), expected$se, tolerance = 1e-12)),
    isTRUE(all.equal(as.numeric(actual$lwr[matched]), expected$lwr, tolerance = 1e-12)),
    isTRUE(all.equal(as.numeric(actual$upr[matched]), expected$upr, tolerance = 1e-12)),
    all(is.finite(actual$se)), all(actual$se > 0),
    all(actual$lwr <= actual$value), all(actual$value <= actual$upr),
    all(grepl("Conditional random-effect uncertainty", actual$notes, fixed = TRUE)),
    all(grepl("not fully marginal", actual$notes, fixed = TRUE))
  )
  actual[matched, , drop = FALSE]
}

n_actual <- check_surface(n_expected, "population", "numbers_at_age")
f_actual <- check_surface(f_expected, "mortality", "fishing_mortality_at_age")
f14 <- f_actual[f_actual$age == 14L, ]
f15 <- f_actual[f_actual$age == 15L, ]
q <- outputs[outputs$assessment_id == assessment_id & outputs$measure == "q", ]
assessment <- assessment[assessment$assessment_id == assessment_id, ]
stopifnot(
  nrow(n_actual) == 1053L,
  nrow(f_actual) == 1040L,
  isTRUE(all.equal(f14$value, f15$value)),
  isTRUE(all.equal(f14$se, f15$se)),
  isTRUE(all.equal(f14$lwr, f15$lwr)),
  isTRUE(all.equal(f14$upr, f15$upr)),
  nrow(q) == 50L,
  assessment$outputs_status == "partial",
  grepl("not fully marginal", assessment$notes, fixed = TRUE)
)

cat("Northeast Arctic cod conditional state uncertainty passed.\n")
