read_matching_rows <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
           stringsAsFactors = FALSE, na.strings = c("", "NA"),
           check.names = FALSE)
}

stock_id <- "mpi_snapper_sna7"
assessment_id <- "mpi_snapper_sna7_2024"
stock <- read_matching_rows("database/stocks.csv", stock_id)
assessment <- read_matching_rows("database/assessments.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "SNA 7",
  stock$scientific_name == "Chrysophrys auratus",
  stock$ocean == "Southwest Pacific",
  is.na(stock$charbonneau_id),
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2023L,
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.22",
  assessment$is_current,
  assessment$is_applied,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(inputs) == 2209L
)

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
stopifnot(
  nrow(catch) == 372L,
  identical(sort(unique(catch$year)), 1931:2023),
  setequal(catch$fleet, c("BT1", "BT2", "BPT", "Recreational")),
  subset(catch, year == 1931 & fleet == "BT1")$value == 83,
  subset(catch, year == 2023 & fleet == "BT1")$value == 208,
  subset(catch, year == 2023 & fleet == "BT2")$value == 287,
  subset(catch, year == 2023 & fleet == "Recreational")$value == 132,
  all(catch$unit == "tonnes"),
  all(catch$year_basis == "model_year")
)

bt1 <- subset(inputs, type == "index" & measure == "relative_biomass_index" &
                fleet == "BT1")
bt2 <- subset(inputs, type == "index" & measure == "relative_biomass_index" &
                fleet == "BT2")
survey <- subset(inputs, type == "index" & measure == "relative_biomass_index" &
                   grepl("Kaharoa trawl survey, core strata", survey, fixed = TRUE))
stopifnot(
  nrow(bt1) == 21L,
  min(bt1$year) == 1989L,
  max(bt1$year) == 2009L,
  subset(bt1, year == 1989)$value == 0.841,
  subset(bt1, year == 2009)$value == 0.298,
  nrow(bt2) == 34L,
  min(bt2$year) == 1989L,
  max(bt2$year) == 2022L,
  subset(bt2, year == 1989)$value == 0.591,
  subset(bt2, year == 2022)$value == 10.782,
  nrow(survey) == 16L,
  min(survey$year) == 1991L,
  max(survey$year) == 2022L,
  subset(survey, year == 2022)$value == 3633
)

cpue_cv <- subset(inputs, type == "index" & measure == "biomass_index_cv" &
                    fleet %in% c("BT1", "BT2"))
stopifnot(nrow(cpue_cv) == 0L)

survey_cv <- subset(inputs, type == "index" & measure == "biomass_index_cv" &
                      grepl("Kaharoa trawl survey, core strata", survey, fixed = TRUE))
tag <- subset(inputs, type == "index" & measure == "total_biomass")
stopifnot(
  nrow(survey_cv) == 16L,
  subset(survey_cv, year == 2022)$value == 0.21,
  nrow(tag) == 1L,
  tag$year == 1987L,
  tag$value == 1549,
  tag$unit == "tonnes"
)

catch_age <- subset(inputs, type == "catch" & measure == "proportion_at_age")
survey_age <- subset(inputs, type == "index" & measure == "proportion_at_age")
stopifnot(
  nrow(catch_age) == 600L,
  setequal(unique(catch_age$fleet[catch_age$fleet == "BPT"]), "BPT"),
  setequal(unique(catch_age$year[catch_age$fleet == "BPT"]), c(1978L, 1979L, 1980L, 1983L)),
  !any(catch_age$year == 1974L),
  nrow(subset(catch_age, fleet == "BT1")) == 330L,
  nrow(subset(catch_age, fleet == "BT2")) == 150L,
  all(subset(catch_age, fleet == "BPT")$sample_size == 17),
  all(is.na(subset(catch_age, fleet %in% c("BT1", "BT2"))$sample_size)),
  any(is.na(catch_age$value)),
  nrow(survey_age) == 210L,
  setequal(unique(survey_age$year), c(2016L, 2018L, 2020L, 2022L)),
  setequal(unique(survey_age$age), 1:30),
  all(vapply(split(survey_age$value, survey_age$observation_id), function(x) {
    abs(sum(x, na.rm = TRUE) - 1) < 0.01
  }, logical(1)))
)

sample_counts <- subset(inputs, type == "biology" &
                          measure == "composition_sample_count")
survey_length <- subset(inputs, measure == "proportion_at_length")
recreational_length <- subset(inputs, measure == "frequency_at_length")
stopifnot(
  nrow(sample_counts) == 15L,
  subset(sample_counts, year == 2022)$value == 897,
  nrow(survey_length) == 284L,
  setequal(unique(survey_length$year), c(2008L, 2010L, 2012L, 2014L)),
  setequal(unique(survey_length$length_bin), as.character(10:80)),
  all(vapply(split(survey_length$value, survey_length$observation_id), function(x) {
    abs(sum(x, na.rm = TRUE) - 1) < 0.01
  }, logical(1))),
  nrow(recreational_length) == 639L,
  setequal(unique(recreational_length$year), c(2005L, 2011L, 2015L:2021L)),
  setequal(unique(recreational_length$length_bin), as.character(10:80)),
  all(recreational_length$sample_size == 1)
)

stopifnot(
  nrow(assumptions) == 26L,
  any(assumptions$component == "M" & assumptions$setting == "natural_mortality" &
        grepl("0.075", assumptions$value, fixed = TRUE)),
  any(assumptions$component == "index" & assumptions$fleet == "BT1" &
        assumptions$setting == "observation_error_cv_range" &
        assumptions$value == "0.09-0.16"),
  any(assumptions$component == "index" & assumptions$fleet == "BT2" &
        assumptions$setting == "observation_error_cv_range" &
        assumptions$value == "0.14-0.20"),
  any(assumptions$component == "index" & assumptions$setting == "survey_timing" &
        grepl("unknown", assumptions$value, fixed = TRUE)),
  any(assumptions$component == "catch" & assumptions$fleet == "BT1" &
        assumptions$setting == "age_composition_ess" & assumptions$value == "10-25"),
  any(assumptions$component == "catch" & assumptions$fleet == "BT2" &
        assumptions$setting == "age_composition_ess" & assumptions$value == "6-12")
)

stopifnot(
  nrow(outputs) == 6L,
  all(outputs$scenario == "Base_RecCatch"),
  subset(outputs, measure == "spawning_biomass")$value == 13816,
  subset(outputs, measure == "spawning_biomass")$lwr == 9810,
  subset(outputs, measure == "spawning_biomass")$upr == 18530,
  subset(outputs, measure == "fishing_mortality_ratio_to_target")$value == 0.376,
  subset(outputs, measure == "fishing_mortality_ratio_to_target")$lwr == 0.278,
  subset(outputs, measure == "fishing_mortality_ratio_to_target")$upr == 0.532,
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
                              "natural_mortality_at_age"))
)

candidate <- read_matching_rows("discovery/candidates.csv", "MPI:SNA7")
manifest <- read.csv("provenance/mpi_snapper_sna7_2024_sources.csv",
                     stringsAsFactors = FALSE)
review <- readLines("discovery/source_reviews/mpi_snapper_sna7_2024.md",
                    warn = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 3L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(file.exists(manifest$local_file)),
  !grepl("tinyAM", paste(review, collapse = " "), ignore.case = TRUE),
  any(grepl("hCaptcha", review, fixed = TRUE))
)

cat("SNA 7 2024 source checks passed.\n")
