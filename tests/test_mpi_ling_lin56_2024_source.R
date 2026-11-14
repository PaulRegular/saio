stock_id <- "mpi_ling_lin56_lin6b"
assessment_id <- "mpi_ling_lin56_lin6b_2024"
candidate_id <- "MPI:LIN56+LIN6B"

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- read.csv("database/inputs.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
outputs <- read.csv("database/outputs.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selection <- read.csv("discovery/selected_batch_06_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock <- subset(stocks, stock_id == "mpi_ling_lin56_lin6b")
assessment <- subset(assessments, assessment_id == "mpi_ling_lin56_lin6b_2024")
input <- subset(inputs, assessment_id == "mpi_ling_lin56_lin6b_2024")
assumption <- subset(assumptions, assessment_id == "mpi_ling_lin56_lin6b_2024")
output <- subset(outputs, assessment_id == "mpi_ling_lin56_lin6b_2024")
candidate_row <- subset(candidate, candidate_id == "MPI:LIN56+LIN6B")
selection_row <- subset(selection, candidate_id == "MPI:LIN56+LIN6B")

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "LIN 5&6 and LIN 6B",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2023L,
  assessment$estimate_terminal_year == 2029L,
  assessment$is_current,
  assessment$is_applied,
  assessment$model_version == "Casal2 v24.02",
  nrow(input) == 234L,
  sum(input$measure == "catch_biomass") == 156L,
  sum(input$measure == "natural_mortality_at_age") == 56L,
  sum(input$measure == "maturity_at_age") == 22L,
  !any(input$type == "index"),
  !any(input$measure %in% c("numbers_at_age", "proportion_at_age")),
  identical(sort(unique(as.integer(input$year[input$measure == "catch_biomass"]))), 1972:2023),
  setequal(unique(input$fleet[input$measure == "catch_biomass"]),
    c("LIN 5&6 bottom trawl", "LIN 5&6 bottom longline", "LIN 6B bottom longline")),
  all(as.numeric(input$value[input$measure == "natural_mortality_at_age"]) == 0.18),
  setequal(unique(as.integer(input$age[input$measure == "natural_mortality_at_age"])), 1:28),
  setequal(unique(input$sex[input$measure == "natural_mortality_at_age"]), c("male", "female")),
  all(as.numeric(input$value[input$measure == "maturity_at_age"]) >= 0 &
    as.numeric(input$value[input$measure == "maturity_at_age"]) <= 1),
  setequal(unique(as.integer(input$age[input$measure == "maturity_at_age"])), 3:13),
  nrow(assumption) == 24L,
  nrow(output) == 80L,
  all(is.na(output$se) | output$se == ""),
  !any(output$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "recruitment")),
  nrow(candidate_row) == 1L,
  candidate_row$matched_stock_id == stock_id,
  candidate_row$match_status == "matched",
  candidate_row$eligibility == "unresolved",
  candidate_row$import_status == "partial",
  selection_row$curation_status == "source_curated_partial"
)

catch <- subset(input, measure == "catch_biomass")
catch_1972 <- subset(catch, year == 1972L)
catch_2023 <- subset(catch, year == 2023L)
stopifnot(
  nrow(catch_1972) == 3L,
  all(as.numeric(catch_1972$value) == 0),
  nrow(catch_2023) == 3L,
  as.numeric(catch_2023$value[catch_2023$fleet == "LIN 5&6 bottom trawl"]) == 6325,
  as.numeric(catch_2023$value[catch_2023$fleet == "LIN 5&6 bottom longline"]) == 3318,
  as.numeric(catch_2023$value[catch_2023$fleet == "LIN 6B bottom longline"]) == 303
)

male_maturity <- subset(input, measure == "maturity_at_age" & sex == "male" & age == 13L)
female_maturity <- subset(input, measure == "maturity_at_age" & sex == "female" & age == 13L)
stopifnot(
  nrow(male_maturity) == 1L, as.numeric(male_maturity$value) == 1,
  nrow(female_maturity) == 1L, as.numeric(female_maturity$value) == 1
)

get_output <- function(measure, scenario, year = NA_integer_) {
  rows <- output[output$measure == measure & output$scenario == scenario, , drop = FALSE]
  if (!is.na(year)) rows <- rows[as.integer(rows$year) == year, , drop = FALSE]
  rows
}
base8_B0 <- get_output("unfished_spawning_biomass", "Table 8 R7.0")
base8_status <- get_output("SSB_ratio_to_B0", "Table 8 R7.0", 2024L)
base9_B0 <- get_output("unfished_spawning_biomass", "Table 9 Base model")
base9_status <- get_output("SSB_ratio_to_B0", "Table 9 Base model", 2024L)
projection <- get_output("SSB", "Table 10 1973-2017 YCS; 2020-23 catch", 2029L)
lin5_below <- get_output("probability_lin5_exploitation_below_u40",
  "Table 11 1973-2017 YCS; 2020-23 catch LIN5 assumed 30% of total SSB", 2029L)
stopifnot(
  nrow(base8_B0) == 1L, as.numeric(base8_B0$value) == 205459,
  as.numeric(base8_B0$lwr) == 171639, as.numeric(base8_B0$upr) == 262863,
  nrow(base8_status) == 1L, as.numeric(base8_status$value) == 67.5,
  nrow(base9_B0) == 1L, as.numeric(base9_B0$value) == 204628,
  nrow(base9_status) == 1L, as.numeric(base9_status$value) == 66.3,
  nrow(projection) == 1L, as.numeric(projection$value) == 133874,
  as.numeric(projection$lwr) == 95594, as.numeric(projection$upr) == 194403,
  nrow(lin5_below) == 1L, as.numeric(lin5_below$value) == 0.96,
  grepl("Table 11", assumption$value[assumption$setting == "table_11_probability_label"], fixed = TRUE)
)

manifest <- read.csv("provenance/mpi_ling_lin56_2024_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
plenary_2026 <- subset(manifest,
  local_file == "mpi_ling_lin56_2026/Fisheries-Assessment-Plenary-May-2026-Volume-2.pdf")
stopifnot(
  nrow(plenary_2026) == 1L,
  grepl("last assessed in 2024", plenary_2026$represented_source, fixed = TRUE),
  grepl("26242", plenary_2026$source_url, fixed = TRUE)
)
if (all(file.exists(file.path("source_cache", manifest$local_file)))) {
  actual <- toupper(unname(tools::sha256sum(file.path("source_cache", manifest$local_file))))
  stopifnot(identical(actual, toupper(manifest$sha256)))
}

cat("Sub-Antarctic ling canonical source data checks passed.\n")
