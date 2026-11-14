read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

assessment_id <- "mpi_red_gurnard_gur7_2022"
stock_id <- "mpi_red_gurnard_gur7"
inputs_all <- read_table("database/inputs.csv")
inputs <- inputs_all[inputs_all$assessment_id == assessment_id, , drop = FALSE]
assumptions_all <- read_table("database/assumptions.csv")
assumptions <- assumptions_all[assumptions_all$assessment_id == assessment_id, , drop = FALSE]
outputs_all <- read_table("database/outputs.csv")
outputs <- outputs_all[outputs_all$assessment_id == assessment_id, , drop = FALSE]
assessments <- read_table("database/assessments.csv")
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidates <- read_table("discovery/candidates.csv")
candidate <- candidates[candidates$candidate_id == "MPI:GUR7", , drop = FALSE]
selected <- read_table("discovery/selected_batch_18_2026.csv")
selected <- selected[selected$candidate_id == "MPI:GUR7", , drop = FALSE]
manifest <- read_table("provenance/mpi_red_gurnard_gur7_2022_sources.csv")

catch <- inputs[inputs$type == "catch" & inputs$measure == "catch_biomass", , drop = FALSE]
biomass <- inputs[inputs$type == "index" & inputs$measure == "total_biomass", , drop = FALSE]
cv <- inputs[inputs$type == "index" & inputs$measure == "biomass_index_cv", , drop = FALSE]
age <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
length <- inputs[inputs$measure == "proportion_at_length", , drop = FALSE]
M <- inputs[inputs$measure == "natural_mortality_at_age", , drop = FALSE]
maturity <- inputs[inputs$measure == "maturity_at_age", , drop = FALSE]

stopifnot(
  nrow(assessment) == 1L,
  assessment$inputs_status == "partial",
  assessment$assumptions_status == "partial",
  assessment$outputs_status == "partial",
  assessment$assessment_year == "2022",
  assessment$terminal_year == "2021",
  nrow(inputs) == 1115L,
  nrow(catch) == 35L,
  identical(sort(as.integer(catch$year)), 1987:2021),
  catch$value[match(c(1987, 2004, 2021), as.integer(catch$year))] == c(421, 717, 1073),
  all(catch$unit == "tonnes"),
  all(catch$source_type == "official_table"),
  nrow(biomass) == 15L,
  identical(sort(as.integer(biomass$year)), c(1992L, 1994L, 1995L, 1997L, 2000L,
    2003L, 2005L, 2007L, 2009L, 2011L, 2013L, 2015L, 2017L, 2019L, 2021L)),
  biomass$value[match(c(1992, 2011, 2021), as.integer(biomass$year))] == c(572, 1070, 2019),
  nrow(cv) == 15L,
  cv$value[match(c(1992, 2011, 2021), as.integer(cv$year))] == c(0.15, 0.17, 0.18),
  all(cv$unit == "ratio"),
  all(grepl("divided by 100", cv$transformation, fixed = TRUE)),
  nrow(age) == 100L,
  identical(sort(unique(as.integer(age$year))), c(1994L, 1995L, 2003L, 2005L, 2007L)),
  setequal(age$sex, c("female", "male")),
  identical(sort(unique(as.integer(age$age))), 1:10),
  all(is.na(age$sample_size)),
  all(grepl("sample_size is left blank", age$notes, fixed = TRUE)),
  all(abs(aggregate(value ~ year, age, sum)$value - 1) < 0.001),
  nrow(length) == 920L,
  identical(sort(unique(as.integer(length$year))), c(1992L, 1997L, 2000L, 2009L,
    2011L, 2013L, 2015L, 2017L, 2019L, 2021L)),
  setequal(length$sex, c("female", "male")),
  identical(sort(unique(as.integer(length$length_bin))), 10:55),
  all(is.na(length$sample_size)),
  all(grepl("sample_size is left blank", length$notes, fixed = TRUE)),
  all(abs(aggregate(value ~ year, length, sum)$value - 1) < 0.002),
  nrow(M) == 20L,
  setequal(M$sex, c("female", "male")),
  all(as.numeric(M$value) == 0.31),
  all(M$unit == "year^-1"),
  all(is.na(M$year) & is.na(M$year_basis)),
  nrow(maturity) == 10L,
  all(maturity$sex == "female"),
  identical(as.numeric(maturity$value[order(as.integer(maturity$age))]),
    c(0, 0.5, rep(1, 8))),
  nrow(assumptions) == 29L,
  nrow(outputs) == 19L,
  outputs$value[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base; MPD"] == 4500,
  outputs$value[outputs$measure == "unfished_spawning_biomass" & outputs$scenario == "Base; MCMC median"] == 4990,
  outputs$value[outputs$measure == "SSB_ratio_to_B0" & outputs$year == "2021" & outputs$scenario == "Base; MCMC median"] == 1.108,
  outputs$value[outputs$measure == "F_ratio_to_FSB40" & outputs$year == "2021" & outputs$scenario == "Base; MPD"] == 0.474,
  outputs$value[outputs$measure == "SSB_ratio_to_B0" & outputs$year == "2026"] == 0.969,
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age")),
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "ineligible",
  candidate$import_status == "partial",
  selected$curation_status == "partial_source_import",
  nrow(manifest) == 2L
)

source_paths <- file.path("source_cache", manifest$local_file)
if (all(file.exists(source_paths))) {
  stopifnot(identical(toupper(unname(tools::sha256sum(source_paths))),
    toupper(manifest$sha256)))
}

cat("GUR 7 source values, coverage, units, composition totals, uncertainty, and provenance passed.\n")
