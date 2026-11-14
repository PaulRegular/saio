read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

source_root <- "source_cache/nz_red_gurnard_gur3_2022"
report <- file.path(source_root,
  "FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf")
source_hash <- "D5626CA8A0C9A6E6989291EBE7BFB0BFD7EB02E232E41CA62A810B2F31FA9DE7"
stopifnot(file.exists(report))

import <- new.env(parent = globalenv())
source("scripts/import_mpi_red_gurnard_gur3_2022.R", local = import)
stopifnot(identical(toupper(import$sha256_file(report)), source_hash))

numeric_values <- function(x) as.numeric(x$value)
length_groups <- split(numeric_values(import$length_inputs),
  interaction(import$length_inputs$year, import$length_inputs$survey,
    import$length_inputs$survey, drop = TRUE))
survey_biomass <- import$biomass_inputs[
  import$biomass_inputs$measure == "total_biomass", , drop = FALSE]
survey_cv <- import$biomass_inputs[
  import$biomass_inputs$measure == "biomass_index_cv", , drop = FALSE]
catch_mix <- import$catch_inputs[import$catch_inputs$fleet == "BT-MIX", , drop = FALSE]
catch_fla <- import$catch_inputs[import$catch_inputs$fleet == "BT-FLA", , drop = FALSE]

stopifnot(
  nrow(import$catch_inputs) == 74L,
  identical(as.integer(catch_mix$year), 1985:2021),
  identical(as.integer(catch_fla$year), 1985:2021),
  numeric_values(catch_mix)[1L] == 228.5,
  tail(numeric_values(catch_fla), 1L) == 542.9,
  nrow(survey_biomass) == 30L,
  nrow(survey_cv) == 30L,
  setequal(survey_biomass$observation_id, sub("_CV$", "", survey_cv$observation_id)),
  nrow(import$age_inputs) == 60L,
  setequal(import$age_inputs$year, as.character(1992:1994)),
  setequal(import$age_inputs$age, as.character(1:10)),
  setequal(import$age_inputs$sex, c("female", "male")),
  all(numeric_values(import$age_inputs) >= 0 & numeric_values(import$age_inputs) <= 1),
  all(vapply(split(numeric_values(import$age_inputs),
    import$age_inputs$year),
    function(x) abs(sum(x) - 1) < 0.001, logical(1))),
  nrow(import$length_inputs) == 1932L,
  all(grepl("sample_size is left blank", import$age_inputs$notes, fixed = TRUE)),
  all(grepl("sample_size is left blank", import$length_inputs$notes, fixed = TRUE)),
  length(length_groups) == 21L,
  all(lengths(length_groups) == 92L),
  all(vapply(length_groups, function(x) abs(sum(x) - 1) < 0.005, logical(1))),
  nrow(import$assumptions) == 29L,
  nrow(import$outputs) == 19L,
  sum(import$biology_inputs$measure == "natural_mortality_at_age") == 20L,
  sum(import$biology_inputs$measure == "maturity_at_age") == 10L,
  all(import$biology_inputs$value[import$biology_inputs$measure ==
    "natural_mortality_at_age" & import$biology_inputs$sex == "female"] == "0.29"),
  all(import$biology_inputs$value[import$biology_inputs$measure ==
    "natural_mortality_at_age" & import$biology_inputs$sex == "male"] == "0.35"),
  all(import$biology_inputs$value[import$biology_inputs$measure == "maturity_at_age"] ==
    c("0", "0.5", rep("1", 8L))),
  import$outputs$value[import$outputs$measure == "spawning_biomass" &
    import$outputs$year == "2021"] == "4061",
  any(grepl("Fixed M=0.29 y-1 for females and M=0.35 y-1 for males",
    import$assumptions$value, fixed = TRUE)),
  !any(import$inputs$measure == "cpue"),
  !any(import$outputs$measure %in% c("abundance_at_age", "fishing_mortality_at_age"))
)

existing_inputs <- read_table("database/inputs.csv")
existing_assessments <- read_table("database/assessments.csv")
canonical_inputs <- existing_inputs[
  existing_inputs$assessment_id == "mpi_red_gurnard_gur3_2022", , drop = FALSE]
canonical_assessments <- existing_assessments[
  existing_assessments$assessment_id == "mpi_red_gurnard_gur3_2022", , drop = FALSE]
canonical_key <- paste(canonical_inputs$type, canonical_inputs$measure,
  canonical_inputs$observation_id, canonical_inputs$age,
  canonical_inputs$length_bin, sep = "|")
canonical_age <- canonical_inputs[
  canonical_inputs$measure == "proportion_at_age", , drop = FALSE]
expected_age <- import$age_inputs
age_key <- function(x) paste(x$year, x$age, x$sex, sep = "|")
age_match <- match(age_key(expected_age), age_key(canonical_age))
stopifnot(
  nrow(canonical_inputs) %in% c(0L, nrow(import$inputs)),
  nrow(canonical_assessments) %in% c(0L, 1L),
  !anyDuplicated(canonical_key),
  nrow(canonical_age) %in% c(0L, nrow(expected_age)),
  if (nrow(canonical_age)) !anyNA(age_match) &&
    all(as.numeric(canonical_age$value[age_match]) == as.numeric(expected_age$value)) else TRUE
)

cat("GUR 3 report parsing, coverage, selected values, and source gaps passed.\n")
