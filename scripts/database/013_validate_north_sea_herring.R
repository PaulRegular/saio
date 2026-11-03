source("scripts/database/002_validate_database.R")
id <- "ices_herring_north_sea_2026"
x <- inputs[inputs$assessment_id == id, ]
y <- outputs[outputs$assessment_id == id, ]
a <- assessments[assessments$assessment_id == id, ]
stopifnot(
  nrow(x) == 4455L, nrow(y) == 1860L,
  a$inputs_status == "partial", a$outputs_status == "partial",
  a$assumptions_status == "partial", a$terminal_year == 2026
)
expected <- c(
  "HERAS", "IBTS0", "IBTS-Q1", "IBTS-Q3",
  "LAI-SNS", "LAI-CNS", "LAI-BUN", "LAI-ORSH"
)
stopifnot(setequal(unique(na.omit(x$survey)), expected))
lai <- x[x$measure == "larval_abundance_index", ]
stopifnot(
  all(is.na(lai$age)), all(lai$sampling_time == 0.67),
  all(lai$year >= 1973), all(!is.na(lai$season)),
  all(!is.na(lai$region))
)
catch <- x[x$type == "catch", ]
stopifnot(
  !any(catch$year %in% 1978:1979), all(catch$unit == "thousand fish"),
  all(catch$year <= 2025), any(catch$value == 0)
)
m <- x[x$type == "M", ]
raw_m <- read.csv(file.path("source_cache/ices_herring_north_sea_2026", "report_tables_raw.csv"))
raw_m <- raw_m[raw_m$table == "2.6.1.3", ]
key <- function(year, age) paste(year, age, sep = ":")
matched_m <- match(key(m$year, m$age), key(raw_m$year, raw_m$native_column))
stopifnot(
  nrow(m) == 711L, all(m$year %in% 1947:2025),
  all(m$age %in% 0:8), !any(is.na(matched_m)),
  all(m$value == as.numeric(raw_m$value[matched_m]))
)
timed <- x[x$type == "index" & x$survey %in% c("HERAS", "IBTS-Q1", "IBTS0", "IBTS-Q3"), ]
expected_time <- c(HERAS = 0.5, `IBTS-Q1` = 0.125, IBTS0 = 0.125, `IBTS-Q3` = 0.625)
stopifnot(
  all(!is.na(timed$sampling_time)),
  all(timed$sampling_time == expected_time[timed$survey]),
  all(!is.na(timed$season))
)
n <- y[y$measure == "numbers_at_age", ]
r <- y[y$measure == "recruitment", ]
stopifnot(
  nrow(n) == 720L, nrow(r) == 80L,
  identical(n$value[n$age == 0], r$value)
)
f <- y[y$measure == "fishing_mortality_at_age", ]
fbar <- y[y$measure == "Fbar", ]
stopifnot(identical(f$value[f$age == 7], f$value[f$age == 8]))
means <- aggregate(value ~ year, f[f$age %in% 2:6, ], mean)
stopifnot(
  all(abs(means$value - fbar$value) < 0.0006),
  all(fbar$age_group == "2–6 winter rings")
)
source("tests/test_ices_herring_north_sea_outputs.R")
message("Herring coverage, native dimensions, exclusions, recruitment, Fbar and q checks passed.")
