root <- normalizePath(".", winslash = "/", mustWork = TRUE)
database <- file.path(root, "analysis", "comp_assessments", "database")
stocks <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE)
assumptions <- read.csv(file.path(database, "assumptions.csv"), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(database, "inputs.csv"), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(database, "outputs.csv"), stringsAsFactors = FALSE)

stock_id <- "ck_ices_wgnssk_solea_ns_4"
detailed_id <- "ices_sole_north_sea_2025"
summary_id <- "ices_sole_north_sea_2026_summary"
stock <- stocks[stocks$stock_id == stock_id, ]
detailed <- assessments[assessments$assessment_id == detailed_id, ]
summary <- assessments[assessments$assessment_id == summary_id, ]
source_inputs <- inputs[inputs$assessment_id == detailed_id, ]
current_inputs <- inputs[inputs$assessment_id == summary_id, ]
source_outputs <- outputs[outputs$assessment_id %in% c(detailed_id, summary_id), ]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "sol.27.4",
  stock$common_name == "North Sea sole",
  nrow(detailed) == 1L,
  !detailed$is_current,
  detailed$assessment_year == 2025,
  detailed$terminal_year == 2024,
  detailed$estimate_terminal_year == 2025,
  nrow(summary) == 1L,
  summary$is_current,
  summary$inputs_status == "partial",
  summary$outputs_status == "partial",
  nrow(current_inputs) == 3394L,
  sum(source_inputs$type == "catch" & source_inputs$fleet == "Landings") == 680L,
  sum(source_inputs$type == "catch" & source_inputs$fleet == "Discards") == 230L,
  sum(source_inputs$measure == "landings_weight_at_age") == 748L,
  sum(source_inputs$measure == "discard_weight_at_age") == 748L,
  sum(source_inputs$type == "weight") == 748L,
  sum(source_inputs$type == "maturity") == 11L,
  sum(source_inputs$type == "M") == 11L,
  sum(source_inputs$survey == "BTS Q3" & source_inputs$measure == "numbers_at_age") == 385L,
  sum(source_inputs$survey == "BTS Q3" & source_inputs$measure == "relative_biomass_index") == 35L,
  sum(source_inputs$survey == "COAST (SNS + DYFS)" & source_inputs$measure == "numbers_at_age") == 210L,
  sum(source_inputs$survey == "COAST (SNS + DYFS)" & source_inputs$measure == "relative_biomass_index") == 35L,
  !any(source_inputs$type == "catch" & source_inputs$age == 0),
  !any(source_inputs$survey == "COAST (SNS + DYFS)" & source_inputs$measure == "numbers_at_age" & source_inputs$age > 5),
  all(source_inputs$sampling_time[source_inputs$type == "index"] == 0.625),
  all(source_inputs$age[source_inputs$measure == "numbers_at_age" & source_inputs$type == "catch"] <= 10),
  all(source_inputs$value[source_inputs$measure == "natural_mortality_at_age"] > 0)
)

landings_1957_age2 <- source_inputs[
  source_inputs$type == "catch" & source_inputs$fleet == "Landings" &
    source_inputs$year == 1957 & source_inputs$age == 2, "value"
]
discards_2002_age1 <- source_inputs[
  source_inputs$type == "catch" & source_inputs$fleet == "Discards" &
    source_inputs$year == 2002 & source_inputs$age == 1, "value"
]
maturity_age3 <- source_inputs[
  source_inputs$type == "maturity" & source_inputs$age == 3, "value"
]
M_age0 <- source_inputs[
  source_inputs$type == "M" & source_inputs$age == 0, "value"
]
N_1957_age0 <- source_outputs[
  source_outputs$assessment_id == detailed_id & source_outputs$measure == "numbers_at_age" &
    source_outputs$year == 1957 & source_outputs$age == 0, "value"
]
F_1957_age2 <- source_outputs[
  source_outputs$assessment_id == detailed_id & source_outputs$measure == "fishing_mortality_at_age" &
    source_outputs$year == 1957 & source_outputs$age == 2, "value"
]
SSB_2024 <- source_outputs[
  source_outputs$assessment_id == detailed_id & source_outputs$measure == "SSB" &
    source_outputs$year == 2024, ]
Fbar_2024 <- source_outputs[
  source_outputs$assessment_id == detailed_id & source_outputs$measure == "Fbar" &
    source_outputs$year == 2024, ]
Fbar_2026 <- source_outputs[
  source_outputs$assessment_id == summary_id & source_outputs$measure == "Fbar" &
    source_outputs$year == 2026, ]

stopifnot(
  length(landings_1957_age2) == 1L, landings_1957_age2 == 1472,
  length(discards_2002_age1) == 1L, discards_2002_age1 == 10963,
  length(maturity_age3) == 1L, maturity_age3 == 1,
  length(M_age0) == 1L, M_age0 == 1.302,
  length(N_1957_age0) == 1L, N_1957_age0 == 1901560,
  length(F_1957_age2) == 1L, F_1957_age2 == 0.009,
  nrow(SSB_2024) == 1L, SSB_2024$value == 61914,
  SSB_2024$lwr == 56943, SSB_2024$upr == 66886,
  nrow(Fbar_2024) == 1L, Fbar_2024$age_group == "2-6",
  abs(Fbar_2024$value - 0.05801) < 1e-8,
  Fbar_2024$lwr == 0.05177, Fbar_2024$upr == 0.06425,
  !nrow(Fbar_2026)
)

cat("North Sea sole source records passed.\n")
