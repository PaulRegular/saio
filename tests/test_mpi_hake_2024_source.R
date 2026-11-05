source("R/read_database.R")

database <- read_database()
hak1 <- read_assessment("mpi_hake_hak1_subantarctic_2024", database)
hak1_age <- read_assessment("mpi_hake_hak1_age_update_2024", database)
hak7 <- read_assessment("mpi_hake_hak7_wcsi_2024", database)
hak7_age <- read_assessment("mpi_hake_hak7_age_update_2024", database)

stopifnot(
  nrow(hak1$stocks) == 1L,
  hak1$stocks$ocean == "Southwest Pacific",
  hak1$stocks$region == "New Zealand waters",
  hak1$stocks$area == "Sub-Antarctic biological stock, including Puysegur Bank",
  hak1$stocks$authority_stock_id == "HAK 1",
  hak7$stocks$authority_stock_id == "HAK 7",
  hak7$stocks$area == "West Coast South Island biological stock",
  hak1$assessment$assessment_year == 2025L,
  hak1$assessment$terminal_year == 2025L,
  hak7$assessment$assessment_year == 2024L,
  hak7$assessment$terminal_year == 2024L,
  hak1_age$assessment$record_type == "data_update",
  hak7_age$assessment$record_type == "data_update",
  hak1_age$assessment$inputs_status == "complete",
  hak7_age$assessment$inputs_status == "complete"
)

hak1_catch <- hak1$inputs[hak1$inputs$type == "catch" &
  hak1$inputs$measure == "total_biomass", ]
hak1_index <- hak1$inputs[hak1$inputs$type == "index" &
  hak1$inputs$measure == "total_biomass", ]
hak1_cv <- hak1$inputs[hak1$inputs$measure == "biomass_index_cv", ]
hak1_maturity <- hak1$inputs[hak1$inputs$measure == "maturity_at_age", ]
hak7_catch <- hak7$inputs[hak7$inputs$type == "catch" &
  hak7$inputs$measure == "total_biomass", ]
hak7_index <- hak7$inputs[hak7$inputs$type == "index" &
  hak7$inputs$measure == "total_biomass", ]
hak7_cv <- hak7$inputs[hak7$inputs$measure == "biomass_index_cv", ]
hak7_maturity <- hak7$inputs[hak7$inputs$measure == "maturity_at_age", ]

stopifnot(
  nrow(hak1_catch) == 102L,
  min(hak1_catch$year) == 1975L, max(hak1_catch$year) == 2025L,
  hak1_catch$value[hak1_catch$year == 2025L & hak1_catch$season == "summer"] == 1073.2,
  nrow(hak1_index) == 24L, nrow(hak1_cv) == 24L,
  all(hak1_index$unit == "tonnes"), all(hak1_cv$unit == "ratio"),
  all(is.na(hak1_index$sampling_time)),
  nrow(hak1_maturity) == 28L,
  nrow(hak7_catch) == 35L,
  min(hak7_catch$year) == 1990L, max(hak7_catch$year) == 2024L,
  hak7_catch$value[hak7_catch$year == 2024L] == 1695,
  nrow(hak7_index) == 6L, nrow(hak7_cv) == 6L,
  all(hak7_index$unit == "tonnes"), all(hak7_cv$unit == "ratio"),
  all(is.na(hak7_index$sampling_time)),
  nrow(hak7_maturity) == 20L,
  all(grepl("10\\+", hak7_maturity$notes[hak7_maturity$age == 10]))
)

hak1_age_numbers <- hak1_age$inputs[hak1_age$inputs$measure == "numbers_at_age", ]
hak1_age_cv <- hak1_age$inputs[hak1_age$inputs$measure == "numbers_at_age_cv", ]
hak7_age_numbers <- hak7_age$inputs[hak7_age$inputs$measure == "numbers_at_age", ]
hak7_age_cv <- hak7_age$inputs[hak7_age$inputs$measure == "numbers_at_age_cv", ]
age_key <- c("type", "fleet", "survey", "sex", "region", "season", "year",
  "year_basis", "age", "observation_id")
key_for <- function(x) do.call(paste, c(x[age_key], sep = "\r"))

stopifnot(
  nrow(hak1_age_numbers) == 68L, nrow(hak1_age_cv) == 68L,
  nrow(hak1_age_numbers[hak1_age_numbers$type == "catch", ]) == 37L,
  nrow(hak1_age_numbers[hak1_age_numbers$type == "index", ]) == 31L,
  all(hak1_age_numbers$year[hak1_age_numbers$type == "catch"] == 2024L),
  all(hak1_age_numbers$year[hak1_age_numbers$type == "index"] == 2025L),
  nrow(hak7_age_numbers) == 112L, nrow(hak7_age_cv) == 112L,
  nrow(hak7_age_numbers[hak7_age_numbers$type == "catch", ]) == 40L,
  nrow(hak7_age_numbers[hak7_age_numbers$type == "index", ]) == 72L,
  all(hak7_age_numbers$year == 2024L),
  identical(sort(key_for(hak1_age_numbers)), sort(key_for(hak1_age_cv))),
  identical(sort(key_for(hak7_age_numbers)), sort(key_for(hak7_age_cv))),
  !any(hak1$inputs$measure %in% c("numbers_at_age", "numbers_at_age_cv")),
  !any(hak7$inputs$measure %in% c("numbers_at_age", "numbers_at_age_cv"))
)

hak1_ssb <- hak1$outputs[hak1$outputs$measure == "SSB", ]
hak7_ssb <- hak7$outputs[hak7$outputs$measure == "SSB", ]
stopifnot(
  nrow(hak1_ssb) == 1L, hak1_ssb$year == 2025L,
  hak1_ssb$value == 47023, hak1_ssb$lwr == 33165, hak1_ssb$upr == 70417,
  nrow(hak7_ssb) == 1L, hak7_ssb$year == 2024L,
  hak7_ssb$value == 35580, hak7_ssb$lwr == 24640, hak7_ssb$upr == 54660,
  all(grepl("MCMC median", c(hak1_ssb$notes, hak7_ssb$notes)))
)

hak1_sources <- read.csv("provenance/mpi_hake_hak1_2024_sources.csv",
  stringsAsFactors = FALSE)
hak7_sources <- read.csv("provenance/mpi_hake_hak7_2024_sources.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(hak1_sources) == 4L, nrow(hak7_sources) == 3L,
  all(grepl("^[[:xdigit:]]{64}$", c(hak1_sources$sha256, hak7_sources$sha256))),
  all(grepl("^https://fs\\.fish\\.govt\\.nz/", c(hak1_sources$source_url, hak7_sources$source_url)))
)

cat("HAK1 and HAK7 assessment inputs, age-data updates, outputs, and provenance passed.\n")
