root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- file.path(root, "analysis", "comp_assessments", "database")
read_db <- function(name) read.csv(file.path(database, name), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, skipNul = TRUE)
stocks <- read_db("stocks.csv")
assessments <- read_db("assessments.csv")
assumptions <- read_db("assumptions.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")

stock_id <- "ck_ices_wgnssk_maximus_ns_4"
benchmark_id <- "ices_turbot_north_sea_2025_benchmark"
summary_id <- "ices_turbot_north_sea_2026_summary"
benchmark <- assessments[assessments$assessment_id == benchmark_id, ]
summary <- assessments[assessments$assessment_id == summary_id, ]
i <- inputs[inputs$assessment_id == benchmark_id, ]
o <- outputs[outputs$assessment_id %in% c(benchmark_id, summary_id), ]
a <- assumptions[assumptions$assessment_id == benchmark_id, ]

stopifnot(
  sum(stocks$stock_id == stock_id) == 1L,
  stocks$scientific_name[stocks$stock_id == stock_id] == "Scophthalmus maximus",
  stocks$common_name[stocks$stock_id == stock_id] == "Turbot",
  nrow(benchmark) == 1L, benchmark$is_current, !benchmark$is_applied,
  benchmark$assessment_year == 2025L, benchmark$terminal_year == 2023L,
  benchmark$inputs_status == "complete", benchmark$outputs_status == "complete",
  nrow(summary) == 1L, !summary$is_current, summary$is_applied,
  summary$assessment_year == 2026L, summary$terminal_year == 2025L,
  summary$inputs_status == "partial", summary$outputs_status == "partial",
  min(i$year[i$type == "catch" & i$measure == "numbers_at_age"], na.rm = TRUE) == 1981L,
  max(i$year[i$type == "catch" & i$measure == "numbers_at_age"], na.rm = TRUE) == 2023L,
  min(i$age[i$type == "catch" & i$measure == "numbers_at_age"], na.rm = TRUE) == 1L,
  max(i$age[i$type == "catch" & i$measure == "numbers_at_age"], na.rm = TRUE) == 8L,
  setequal(unique(i$survey[i$type == "index"]), c("BTS+COAST", "BSAS")),
  sum(i$type == "weight" & i$measure == "weight_at_age") == 242L,
  !any(i$measure == "spawning_weight_at_age"),
  all(i$sampling_time[i$type == "index"] == 0.705),
  all(i$basis[i$type == "index"] == "index_scale"),
  all(i$unit[i$type == "index"] == "native survey index (unit unresolved)"),
  max(i$age[i$survey == "BTS+COAST"], na.rm = TRUE) == 7L,
  max(i$age[i$survey == "BSAS"], na.rm = TRUE) == 8L,
  sum(i$type == "M" & i$measure == "natural_mortality_at_age") == 8L,
  all(is.na(i$year[i$type == "M"])),
  sum(i$type == "maturity" & i$measure == "maturity_at_age") == 8L,
  any(a$setting == "SAM configuration: keyLogFsta"),
  any(a$setting == "SAM configuration: fbarRange" & a$value == "2 6")
)

catch <- i[i$type == "catch" & i$measure == "numbers_at_age" & i$year == 1981, ]
catch_weight <- i[i$type == "catch_weight" & i$year == 1981, ]
catch_biomass_t <- sum(catch$value * catch_weight$value[match(catch$age, catch_weight$age)], na.rm = TRUE)
stopifnot(abs(catch_biomass_t - 4755) < 10)

n <- o[o$assessment_id == benchmark_id & o$measure == "numbers_at_age", ]
f <- o[o$assessment_id == benchmark_id & o$measure == "fishing_mortality_at_age", ]
w <- o[o$assessment_id == benchmark_id & o$type == "biology" & o$measure == "weight_at_age", ]
stopifnot(
  nrow(n) == 43L * 8L, nrow(f) == 43L * 8L,
  nrow(w) == 43L * 8L,
  all(n$year %in% 1981:2023), all(f$year %in% 1981:2023),
  all(w$year %in% 1981:2023), all(w$age %in% 1:8),
  all(w$value > 0), all(w$se > 0),
  all(w$source_type == "derived_source_output"),
  all(grepl("exp\\(logSW\\)", w$notes)),
  all(n$se > 0), all(f$se > 0),
  all(n$unit == "thousand fish"), all(f$unit == "per year"),
  all(grepl("SE is on the log scale", n$notes)), all(grepl("SE is on the log scale", f$notes)),
  all(f$value[f$year == 2023L & f$age == 7L] == f$value[f$year == 2023L & f$age == 8L]),
  abs(o$value[o$assessment_id == benchmark_id & o$measure == "SSB" & o$year == 2023L] - 3564.575) < 1e-3,
  abs(o$value[o$assessment_id == summary_id & o$measure == "SSB" & o$year == 2023L] - 4685) < 1,
  !any(o$assessment_id == summary_id & o$measure == "Fbar" & o$year == 2026L)
)
