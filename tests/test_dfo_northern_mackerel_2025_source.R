root <- "."
cache <- file.path(root, "source_cache", "dfo_northern_mackerel_2025")
repo <- file.path(cache, "model_repository")
csv_dir <- file.path(repo, "csv", "2025")
data_dir <- file.path(repo, "data", "2025")
assessment_id <- "dfo_northern_mackerel_2025"
stock_id <- "ck_dfo_qc_scombrus_4t"

read_db <- function(name) read.csv(file.path(root, "database", name),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
assessments <- read_db("assessments.csv")
stocks <- read_db("stocks.csv")
assumptions <- read_db("assumptions.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")
a <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
s <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]

stopifnot(
  nrow(a) == 1L, nrow(s) == 1L,
  a$assessment_year == 2025, a$terminal_year == 2025,
  a$is_current, a$is_applied,
  a$model_family == "CCAM",
  grepl("fit CCAM RemoteSha 1d1cc18416b2", a$model_version, fixed = TRUE),
  grepl("available CCAM source snapshot 1bcb06473343c13ebeebecdb54acd905220aeb61",
    a$model_version, fixed = TRUE),
  a$inputs_status == "complete",
  a$assumptions_status == "partial",
  a$outputs_status == "partial",
  s$charbonneau_id == "DFO-QC_scombrus_4T",
  s$common_name == "Northern contingent Atlantic mackerel",
  s$region == "Northwest Atlantic"
)

catch_age <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
stopifnot(
  nrow(catch_age) == 570L,
  setequal(catch_age$year, 1969:2025),
  setequal(catch_age$age, 1:10),
  all(catch_age$unit == "thousand fish"),
  catch_age$value[catch_age$year == 1969 & catch_age$age == 1] == 5692,
  catch_age$value[catch_age$year == 2025 & catch_age$age == 10] == 0.9699,
  all(grepl("age 10 is 10\\+", catch_age$notes, ignore.case = TRUE))
)

biological_surfaces <- c(
  "maturity_at_age", "weight_at_age", "start_weight_at_age",
  "fecundity_at_age", "proportion_female_at_age",
  "fraction_F_before_spawning", "fraction_M_before_spawning",
  "natural_mortality_at_age"
)
for (measure in biological_surfaces) {
  x <- i[i$measure == measure, ]
  if (measure == "weight_at_age") x <- x[x$type == "weight", ]
  stopifnot(
    nrow(x) == 570L,
    setequal(x$year, 1969:2025),
    setequal(x$age, 1:10),
    all(is.finite(x$value))
  )
}
catch_weight <- i[i$type == "catch_weight" & i$measure == "weight_at_age", ]
stopifnot(nrow(catch_weight) == 570L,
  setequal(catch_weight$year, 1969:2025), setequal(catch_weight$age, 1:10))
stopifnot(
  all(i$value[i$measure == "fraction_F_before_spawning"] == 0.47),
  all(i$value[i$measure == "fraction_M_before_spawning"] == 0.47)
)
m <- i[i$measure == "natural_mortality_at_age", ]
stopifnot(all(m$value == 0.28), all(m$unit == "1/year"))

read_ices <- function(name, columns) {
  lines <- readLines(file.path(data_dir, name), warn = FALSE)
  x <- read.table(text = paste(lines[-seq_len(5L)], collapse = "\n"),
    header = FALSE, fill = FALSE, na.strings = c("NA", "-"),
    comment.char = "", check.names = FALSE)
  stopifnot(nrow(x) == 58L, ncol(x) == columns)
  as.matrix(x)
}
ct <- read_ices("ct.dat", 2L)[-1L, 1L]
ct_us <- read_ices("ctUSA.dat", 2L)[-1L, 1L]
ct_unaccounted <- read_ices("ctUnaccounted.dat", 2L)[-1L, 1L]
lower <- i[i$measure == "catch_lower_bound", ]
upper <- i[i$measure == "catch_upper_bound", ]
stopifnot(
  nrow(lower) == 57L, nrow(upper) == 57L,
  isTRUE(all.equal(lower$value[order(lower$year)], ct * 1.10 + ct_us * 0.20)),
  isTRUE(all.equal(upper$value[order(upper$year)],
    ct + ct_unaccounted + ct_us * 0.80)),
  all(lower$source_type == "reconstructed_source_input"),
  all(upper$source_type == "reconstructed_source_input")
)

tep_source <- read.csv(file.path(csv_dir, "Intrants_2025.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
tep_source <- tep_source[is.finite(tep_source$TEP_e12), ]
tep <- i[i$measure == "total_egg_production", ]
stopifnot(
  nrow(tep) == nrow(tep_source),
  nrow(tep) == 39L,
  setequal(tep$year, as.numeric(tep_source$year)),
  all(tep$basis == "egg_count"),
  all(tep$unit == "trillion eggs"),
  all(tep$sampling_time == 0.47),
  all(is.na(tep$age)),
  isTRUE(all.equal(tep$value[match(tep_source$year, tep$year)],
    tep_source$TEP_e12)),
  tep$value[tep$year == 1979] == 415.708049,
  tep$value[tep$year == 2025] == 53.0412996,
  !2020 %in% tep$year
)

n <- o[o$measure == "numbers_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
ssb <- o[o$measure == "SSB", ]
rec <- o[o$measure == "recruitment", ]
total_n <- o[o$measure == "total_numbers", ]
fbar <- o[o$measure == "Fbar", ]
fit_env <- new.env(parent = baseenv())
load(file.path(repo, "Rdata", "2025", "fit.Rdata"), envir = fit_env)
fit <- fit_env$fit
key_sel <- fit$conf$keySel
selectivity <- matrix(1, nrow = 57L, ncol = 10L)
for (j in seq_len(ncol(selectivity))) {
  keys <- as.integer(key_sel[, j])
  estimated <- keys != max(key_sel)
  selectivity[estimated, j] <- plogis(fit$pl$logitSel[keys[estimated] + 1L])
}
log_f <- outer(fit$pl$logFy, rep(1, 10L)) + log(selectivity)
native_f <- exp(log_f)
log_f_se <- matrix(fit$plsd$logFy, nrow = 57L, ncol = 10L)
native_se <- native_f * log_f_se
native_lwr <- exp(log_f - 2 * log_f_se)
native_upr <- exp(log_f + 2 * log_f_se)
f_grid <- expand.grid(age = 1:10, year = 1969:2025)
f_row <- match(paste(f$year, f$age), paste(f_grid$year, f_grid$age))
f_export <- read.csv(file.path(repo, "csv", "2025", "f.csv"),
  stringsAsFactors = FALSE, check.names = FALSE
)
stopifnot(
  nrow(n) == 570L, setequal(n$year, 1969:2025), setequal(n$age, 1:10),
  nrow(f) == 570L, setequal(f$year, 1969:2025), setequal(f$age, 1:10),
  nrow(ssb) == 57L, nrow(rec) == 57L, nrow(total_n) == 57L, nrow(fbar) == 57L,
  all(n$lwr > 0 & n$lwr < n$value & n$value < n$upr),
  all(ssb$lwr > 0 & ssb$lwr < ssb$value & ssb$value < ssb$upr),
  all(rec$lwr > 0 & rec$lwr < rec$value & rec$value < rec$upr),
  all(is.finite(f$se) & f$se > 0 & f$lwr > 0 & f$lwr < f$value & f$value < f$upr),
  max(abs(round(native_f, 2) - as.matrix(f_export[as.character(1:10)]))) < 1e-12,
  isTRUE(all.equal(as.numeric(f$value), as.vector(t(native_f))[f_row],
    tolerance = 1e-10)),
  isTRUE(all.equal(as.numeric(f$se), as.vector(t(native_se))[f_row],
    tolerance = 1e-10)),
  isTRUE(all.equal(as.numeric(f$lwr), as.vector(t(native_lwr))[f_row],
    tolerance = 1e-10)),
  isTRUE(all.equal(as.numeric(f$upr), as.vector(t(native_upr))[f_row],
    tolerance = 1e-10)),
  all(grepl("conditional on fitted fixed parameters", f$notes, fixed = TRUE)),
  identical(attr(fit, "RemoteSha"), "1d1cc18416b2"),
  all(abs(sqrt(fit$sdrep$diag.cov.random[
    which(names(fit$sdrep$par.random) == "logFy")
  ]) - fit$plsd$logFy) < 1e-10),
  !any(o$measure == "natural_mortality_at_age"),
  fbar$age_group[1] == "5-10+",
  all(rec$age == 1),
  abs(rec$value[rec$year == 2025] -
    n$value[n$year == 2025 & n$age == 1]) < 0.5,
  ssb$value[ssb$year == 2025] == 21062,
  rec$value[rec$year == 2025] == 56595,
  fbar$value[fbar$year == 2025] == 0.25,
  all(vapply(1969:2025, function(y) {
    abs(total_n$value[total_n$year == y] -
      sum(n$value[n$year == y])) < 1e-8
  }, logical(1)))
)

assumption_rows <- assumptions[assumptions$assessment_id == assessment_id, ]
stopifnot(
  any(assumption_rows$setting == "natural_mortality" &
    grepl("Fixed 0.28", assumption_rows$value)),
  any(assumption_rows$setting == "tep_native_unit" &
    grepl("Trillion eggs", assumption_rows$value))
)

cat("Northern mackerel source-input/output tests passed.\n")

