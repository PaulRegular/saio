root <- "."
stock_id <- "noaa_pacific_mackerel_pacific_coast"
benchmark_id <- "noaa_pacific_mackerel_2023"
current_id <- "noaa_pacific_mackerel_2025"

read_db <- function(name) read.csv(file.path(root, "database", name),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
stocks <- read_db("stocks.csv")
assessments <- read_db("assessments.csv")
assumptions <- read_db("assumptions.csv")
inputs <- read_db("inputs.csv")
outputs <- read_db("outputs.csv")

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
benchmark <- assessments[assessments$assessment_id == benchmark_id, , drop = FALSE]
current <- assessments[assessments$assessment_id == current_id, , drop = FALSE]
source_inputs <- inputs[inputs$assessment_id %in% c(benchmark_id, current_id), , drop = FALSE]
source_outputs <- outputs[outputs$assessment_id %in% c(benchmark_id, current_id), , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Scomber japonicus",
  stock$ocean == "Northeast Pacific",
  nrow(benchmark) == 1L,
  benchmark$assessment_year == 2023L,
  benchmark$terminal_year == 2021L,
  !benchmark$is_current,
  benchmark$is_applied,
  benchmark$model_version == "3.30.20",
  nrow(current) == 1L,
  current$assessment_year == 2025L,
  current$terminal_year == 2023L,
  current$estimate_terminal_year == 2026L,
  current$is_current,
  current$is_applied,
  all(c(benchmark$inputs_status, benchmark$outputs_status,
    current$inputs_status, current$outputs_status) == "partial")
)

i23 <- source_inputs[source_inputs$assessment_id == benchmark_id, , drop = FALSE]
i25 <- source_inputs[source_inputs$assessment_id == current_id, , drop = FALSE]
catch23 <- i23[i23$type == "catch" & i23$measure == "catch_biomass", ]
catch25 <- i25[i25$type == "catch" & i25$measure == "catch_biomass", ]
index23 <- i23[i23$type == "index" & i23$measure == "relative_biomass_index", ]
index25 <- i25[i25$type == "index" & i25$measure == "relative_biomass_index", ]
fishery_age <- i23[i23$type == "catch" & i23$measure == "proportion_at_age", ]
survey_age <- i23[i23$type == "index" & i23$measure == "proportion_at_age", ]
weights <- i23[i23$measure %in% c("weight_at_age", "start_weight_at_age",
  "catch_weight_at_age"), ]
maturity_fecundity <- i23[i23$measure == "maturity_fecundity_at_age", ]
age_error <- i23[i23$measure == "ageing_error_sd", ]

stopifnot(
  nrow(catch23) == 14L,
  setequal(catch23$year, 2008:2021),
  catch23$value[catch23$year == 2008L] == 5346.2,
  all(catch23$unit == "mt"),
  nrow(catch25) == 19L,
  setequal(catch25$year, 2008:2026),
  catch25$value[catch25$year == 2008L] == 5369,
  catch25$value[catch25$year == 2023L] == 15866,
  catch25$value[catch25$year == 2024L] == 24163,
  all(grepl("rounded", catch25$notes, ignore.case = TRUE)),
  nrow(index23) == 10L,
  setequal(index23$year, c(2008L, 2012:2019, 2021L)),
  index23$value[index23$year == 2008L] == 58511,
  nrow(index25) == nrow(index23),
  all(index25$source_reference == "2023 SS3 pmack2023.dat survey observations PFMC 2025 report section 5 confirms it was retained unchanged."),
  nrow(fishery_age) == 117L,
  nrow(survey_age) == 81L,
  setequal(fishery_age$age, 0:8),
  setequal(survey_age$age, 0:8),
  all(fishery_age$sex == "combined"),
  all(survey_age$sex == "combined"),
  all(fishery_age$season == "winter"),
  all(fishery_age$sampling_time == 0.5),
  all(survey_age$season == "summer"),
  all(survey_age$sampling_time == 0.05),
  all(fishery_age$partition == "0"),
  all(survey_age$partition == "0"),
  fishery_age$value[fishery_age$year == 2008L & fishery_age$age == 0L] == 0.45884,
  fishery_age$sample_size[fishery_age$year == 2008L & fishery_age$age == 0L] == 29,
  all(is.finite(weights$value)),
  all(weights$unit == "kg/fish"),
  nrow(maturity_fecundity) == 126L,
  all(maturity_fecundity$unit == "native model scale"),
  all(maturity_fecundity$basis == "native_scale"),
  nrow(age_error) == 18L,
  !any(i23$measure == "maturity_at_age"),
  any(i23$measure == "maturity_fecundity_at_age")
)

o23 <- source_outputs[source_outputs$assessment_id == benchmark_id, , drop = FALSE]
o25 <- source_outputs[source_outputs$assessment_id == current_id, , drop = FALSE]
n_at_age <- o23[o23$measure == "numbers_at_age", ]
biomass_at_age <- o23[o23$measure == "biomass_at_age", ]
f_at_age <- o23[o23$measure == "fishing_mortality_at_age", ]
m_at_age <- o23[o23$measure == "natural_mortality_at_age", ]
ssb <- o23[o23$measure == "SSB", ]
recruitment <- o23[o23$measure == "recruitment", ]
biomass25 <- o25[o25$measure == "biomass_by_age_group", ]
biomass_sd25 <- o25[o25$measure == "biomass_standard_deviation", ]

stopifnot(
  nrow(n_at_age) == 126L,
  nrow(biomass_at_age) == 126L,
  nrow(f_at_age) == 126L,
  nrow(m_at_age) == 126L,
  all(n_at_age$type == "population"),
  all(f_at_age$type == "mortality"),
  all(m_at_age$type == "mortality"),
  setequal(n_at_age$year, 2008:2021),
  setequal(n_at_age$age, 0:8),
  all(is.na(n_at_age$se)),
  all(is.na(f_at_age$se)),
  all(is.na(m_at_age$se)),
  nrow(ssb) == 14L,
  nrow(recruitment) == 14L,
  ssb$value[ssb$year == 2008L] == 129863,
  nrow(biomass25) == 7L,
  isTRUE(all.equal(biomass25$value[match(2020:2026, biomass25$year)],
    c(69823, 50282, 45898, 51060, 58301, 61737, 67954))),
  setequal(biomass_sd25$year, 2025:2026),
  isTRUE(all.equal(biomass_sd25$value[match(2025:2026, biomass_sd25$year)],
    c(41422, 43375))),
  all(grepl("standard deviations", biomass_sd25$notes)),
  !any(o25$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "recruitment"))
)

assumption25 <- assumptions[assumptions$assessment_id == current_id, ]
stopifnot(
  any(assumption25$setting == "natural_mortality"),
  any(assumption25$setting == "maturity_and_fecundity"),
  any(assumption25$setting == "catch_update"),
  any(grepl("only the catch time series changed", assumption25$notes,
    fixed = TRUE))
)

extracted <- read.csv(file.path(root, "provenance",
  "noaa_pacific_mackerel_2023_model_files.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
manifest <- read.csv(file.path(root, "provenance",
  "discovery_noaa_pacific_mackerel_2025", "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
archive_sha <- manifest$sha256[manifest$source_id == "pfmc_2023_model_files"]
stopifnot(
  nrow(extracted) >= 4L,
  all(grepl("^[[:xdigit:]]{64}$", extracted$sha256)),
  all(extracted$archive_sha256 == archive_sha),
  all(c("pmack2023.dat", "pmack2023.ctl", "wtatage.ss", "Report.sso") %in%
    basename(extracted$file))
)

cat("NOAA Pacific chub mackerel source records passed.\n")
