root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- file.path(root, "analysis", "comp_assessments", "database")
read_table <- function(name) read.csv(
  file.path(database, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE
)

assessment_id <- "ices_sole_20_24_2025"
summary_id <- "ices_sole_20_24_2026_summary"
assessments <- read_table("assessments.csv")
outputs <- read_table("outputs.csv")
detailed <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
source <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
forecast_n <- source[source$measure == "numbers_at_age" & as.integer(source$year) %in% 2025:2027, , drop = FALSE]
forecast_f <- source[source$measure == "fishing_mortality_at_age" & as.integer(source$year) %in% 2025:2027, , drop = FALSE]
forecast_total <- source[source$measure == "total_numbers" & as.integer(source$year) %in% 2025:2027, , drop = FALSE]
forecast_recruitment <- source[source$measure == "recruitment" & as.integer(source$year) %in% 2025:2026, , drop = FALSE]
forecast_ssb <- source[source$measure == "SSB" & as.integer(source$year) == 2026, , drop = FALSE]
forecast_fbar <- source[source$measure == "Fbar" & as.integer(source$year) == 2025, , drop = FALSE]
forecast_catch <- source[source$type == "catch" & source$year == "2025", , drop = FALSE]
summary_2026 <- outputs[outputs$assessment_id == summary_id & outputs$measure == "SSB" & outputs$year == "2026", , drop = FALSE]

expected_n <- c(
  915, 1142, 523, 588, 510, 455, 487, 348, 807,
  915, 828, 992, 423, 471, 382, 340, 362, 871,
  915, 842, 720, 814, 331, 352, 284, 250, 928
)
expected_f <- rep(c(0, 0.03, 0.09, 0.12, 0.17, 0.18, 0.18, 0.18, 0.18), 3L)

stopifnot(
  nrow(detailed) == 1L,
  detailed$outputs_status == "complete",
  nrow(forecast_n) == 27L,
  identical(as.integer(forecast_n$year), rep(2025:2027, each = 9L)),
  identical(as.integer(forecast_n$age), rep(1:9, 3L)),
  max(abs(as.numeric(forecast_n$value) - expected_n)) < 1e-8,
  all(forecast_n$source_type == "official_table"),
  all(forecast_n$age_group[forecast_n$age == 9L] == "9+"),
  nrow(forecast_f) == 27L,
  max(abs(as.numeric(forecast_f$value) - expected_f)) < 1e-8,
  all(grepl("pF", forecast_f$notes, fixed = TRUE)),
  nrow(forecast_total) == 3L,
  all(forecast_total$source_type == "derived_source_output"),
  max(abs(as.numeric(forecast_total$value) - c(5775, 5584, 5436))) < 1e-8,
  nrow(forecast_recruitment) == 2L,
  identical(as.integer(forecast_recruitment$year), 2025:2026),
  all(as.numeric(forecast_recruitment$value) == 915),
  nrow(forecast_ssb) == 1L,
  as.numeric(forecast_ssb$value) == 1353,
  nrow(forecast_fbar) == 1L,
  as.numeric(forecast_fbar$value) == 0.175,
  forecast_fbar$age_group == "4-8",
  setequal(forecast_catch$measure, c("landings", "discards", "total_catch")),
  setequal(as.numeric(forecast_catch$value), c(204, 6, 210)),
  nrow(summary_2026) == 1L,
  as.numeric(summary_2026$value) == 1491,
  !anyDuplicated(source[c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group")])
)

cat("ICES sole 20–24 forecast outputs passed.\n")
