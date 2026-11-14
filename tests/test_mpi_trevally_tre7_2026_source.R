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

stock_id <- "mpi_trevally_tre7"
assessment_id <- "mpi_trevally_tre7_2026"
stock <- read_matching_rows("database/stocks.csv", stock_id)
assessment <- read_matching_rows("database/assessments.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)
candidate <- read_matching_rows("discovery/candidates.csv", "MPI:TRE7")
manifest <- read.csv("provenance/mpi_trevally_tre7_2026_sources.csv",
                     stringsAsFactors = FALSE)
review <- readLines("discovery/source_reviews/mpi_trevally_tre7_2026.md",
                    warn = FALSE)

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "TRE 7",
  stock$scientific_name == "Pseudocaranx dentex",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2025L,
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.23.1",
  assessment$is_current,
  assessment$is_applied,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 2L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(file.exists(manifest$local_file)),
  !grepl("tinyAM", paste(review, collapse = " "), ignore.case = TRUE)
)

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
stopifnot(
  nrow(catch) == 204L,
  identical(sort(unique(catch$year)), 1975:2025),
  setequal(catch$fleet, c(
    "NMB bottom trawl", "KMNTB bottom trawl",
    "NMB and KMNTB bottom pair trawl",
    "STB bottom trawl and bottom pair trawl"
  )),
  subset(catch, year == 1975L & fleet == "NMB and KMNTB bottom pair trawl")$value == 1464,
  subset(catch, year == 2025L & fleet == "KMNTB bottom trawl")$value == 682,
  subset(catch, year == 2025L & fleet == "STB bottom trawl and bottom pair trawl")$value == 342,
  all(catch$unit == "tonnes"),
  all(catch$year_basis == "model_year")
)

cpue <- subset(inputs, type == "index" & measure == "relative_biomass_index")
stopifnot(
  nrow(cpue) == 32L,
  min(cpue$year) == 1994L,
  max(cpue$year) == 2025L,
  subset(cpue, year == 1994L)$value == 0.574,
  subset(cpue, year == 2025L)$value == 1.0489,
  all(grepl("95% limits", cpue$notes, fixed = TRUE))
)

survey_biomass <- subset(inputs, type == "index" & measure == "total_biomass")
survey_biomass_cv <- subset(inputs, type == "index" & measure == "biomass_index_cv")
survey_one_year <- subset(inputs, type == "index" & measure == "numbers_at_age")
survey_one_year_cv <- subset(inputs, type == "index" & measure == "numbers_at_age_cv")
stopifnot(
  nrow(survey_biomass) == 13L,
  nrow(survey_biomass_cv) == 13L,
  nrow(survey_one_year) == 8L,
  nrow(survey_one_year_cv) == 8L,
  subset(survey_biomass, year == 1992L & region == "Northern NMB/KMNTB core")$value == 1026,
  subset(survey_one_year, year == 2000L)$value == 88.8,
  subset(survey_one_year_cv, year == 2000L)$value == 9.26,
  grepl("Table 4 gives 9.26", subset(survey_one_year_cv, year == 2000L)$notes, fixed = TRUE)
)

age_comp <- subset(inputs, type == "catch" & measure == "proportion_at_age")
age_comp_cv <- subset(inputs, type == "catch" & measure == "relative_standard_error")
stopifnot(
  nrow(age_comp) == 160L,
  nrow(age_comp_cv) == 160L,
  setequal(unique(age_comp$year), c(2023L, 2024L)),
  setequal(unique(age_comp$age), 1:20),
  setequal(unique(age_comp$region), c(
    "Ninety Mile Beach (NMB)", "Kaipara-Manukau (KMH)",
    "North Taranaki Bight (NTB)", "South Taranaki Bight (STB)"
  )),
  all(vapply(split(age_comp$value, age_comp$observation_id), function(x) {
    abs(sum(x) - 1) < 0.002
  }, logical(1))),
  all(vapply(split(age_comp$age, age_comp$observation_id), function(x) {
    identical(sort(x), 1:20)
  }, logical(1))),
  all(age_comp$sample_size[age_comp$year == 2023L] %in% c(118, 385, 394, 586)),
  all(grepl("not the assessment effective sample size", age_comp$notes, fixed = TRUE))
)

stopifnot(
  nrow(assumptions) == 17L,
  any(assumptions$component == "mortality" &
        assumptions$setting == "natural_mortality" &
        grepl("0.10 per year", assumptions$value, fixed = TRUE)),
  any(assumptions$component == "index" &
        assumptions$setting == "survey_timing" &
        grepl("not stated", assumptions$value, fixed = TRUE)),
  any(assumptions$component == "composition" &
        assumptions$setting == "age_composition_weighting" &
        grepl("5.9-27.8", assumptions$value, fixed = TRUE))
)

stopifnot(
  nrow(outputs) == 12L,
  all(outputs$scenario == "Base"),
  subset(outputs, measure == "spawning_biomass")$value == 34648,
  subset(outputs, measure == "spawning_biomass")$lwr == 23425,
  subset(outputs, measure == "spawning_biomass")$upr == 58260,
  subset(outputs, measure == "SSB_ratio_to_B0")$value == 0.594,
  subset(outputs, measure == "fishing_mortality_ratio_to_target")$value == 0.368,
  subset(outputs, measure == "SSB2030_ratio_to_B0")$value == 0.568,
  !any(outputs$measure %in% c(
    "numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"
  ))
)

cat("TRE 7 2026 source checks passed.\n")

