root <- "."
assessment_id <- "noaa_alaska_sablefish_2024"
register <- read.csv(file.path(root, "discovery", "candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidate <- register[register$candidate_id == "NOAA:10956", , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_alaska_sablefish_2024.md"), warn = FALSE), collapse = " ")
cache <- file.path(root, "source_cache", "discovery_noaa_alaska_sablefish_2024_2025")
manifest <- read.csv(file.path(root, "provenance", "discovery_noaa_alaska_sablefish_2024_2025",
  "sources.csv"), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, "database", "stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv(file.path(root, "database", "assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
assumptions <- read.csv(file.path(root, "database", "assumptions.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
inputs <- read.csv(file.path(root, "database", "inputs.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))
outputs <- read.csv(file.path(root, "database", "outputs.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"))

stock <- stocks[stocks$stock_id == "noaa_alaska_sablefish", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumption <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
age_comp <- i[i$measure == "proportion_at_age", , drop = FALSE]
length_comp <- i[i$measure == "proportion_at_length", , drop = FALSE]
sample_counts <- i[i$measure == "composition_sample_count", , drop = FALSE]
index_sd <- i[i$measure == "index_sd", , drop = FALSE]
age_output <- o[o$measure == "numbers_at_age", , drop = FALSE]
total_abundance <- o[o$measure == "total_abundance", , drop = FALSE]
recruitment <- o[o$measure == "recruitment", , drop = FALSE]
ssb <- o[o$measure == "SSB", , drop = FALSE]
total_biomass <- o[o$measure == "total_biomass", , drop = FALSE]
m_output <- o[o$measure == "natural_mortality_at_age", , drop = FALSE]

model_output <- dget(file.path(cache, "alaska_sablefish_2024_output.rdat"))
expected_total <- rowSums(model_output$natage.female + model_output$natage.male)
expected_years <- 1960:2024

stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "noaa_alaska_sablefish",
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "imported",
  grepl("trawl fishery contributes length, not age, compositions", candidate$catch_age_evidence, fixed = TRUE),
  grepl("Gulf of Alaska trawl survey age compositions in 1984, 1987, 1996 and 1999", candidate$survey_age_evidence, fixed = TRUE),
  grepl("age-composition likelihood weight is zero", candidate$survey_age_evidence, fixed = TRUE),
  grepl("fractional within-year survey timing value", candidate$timing_evidence, fixed = TRUE),
  grepl("input contains age compositions rather than direct catch numbers-at-age", candidate$notes, fixed = TRUE),
  nrow(stock) == 1L,
  stock$authority == "NOAA",
  stock$authority_stock_id == "10956",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$model_version == "Model 23.5",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(i) == 10805L,
  nrow(o) == 6110L,
  nrow(age_comp) == 1920L,
  nrow(length_comp) == 7980L,
  nrow(sample_counts) == 183L,
  nrow(index_sd) == 161L,
  !anyDuplicated(index_sd$observation_id),
  all(age_comp$sample_size[!is.na(age_comp$survey) & age_comp$survey == "Gulf of Alaska trawl survey"] == 30),
  all(age_comp$sample_size[!is.na(age_comp$survey) & age_comp$survey != "Gulf of Alaska trawl survey"] == 20),
  all(age_comp$sample_size[!is.na(age_comp$fleet)] == 20),
  all(age_comp$unit == "proportion"),
  all(age_comp$age %in% 2:31),
  all(age_comp$year_basis == "calendar_year"),
  setequal(unique(age_comp$survey[!is.na(age_comp$survey)]), c(
    "NOAA domestic longline survey", "Japanese cooperative longline survey",
    "Gulf of Alaska trawl survey")),
  setequal(sort(unique(age_comp$year[age_comp$survey == "Gulf of Alaska trawl survey"])),
    c(1984L, 1987L, 1996L, 1999L)),
  identical(sort(unique(age_comp$year[age_comp$fleet == "U.S. fixed-gear fishery"])), 1999:2023),
  all(sample_counts$unit == "fish"),
  all(grepl("distinct from the model's supplied relative likelihood sample-size weight", sample_counts$notes, fixed = TRUE)),
  all(length_comp$length_bin %in% seq(41, 99, by = 2)),
  all(i$year[!is.na(i$year)] %in% expected_years),
  all(assumption$value[assumption$setting == "active_weight_time_blocks"] == "1"),
  all(assumption$value[assumption$setting == "active_maturity_time_blocks"] == "1"),
  all(assumption$value[assumption$setting == "supplied_likelihood_sample_size"] ==
    "20 for most series; 30 for Gulf of Alaska trawl age compositions"),
  all(assumption$value[assumption$setting == "data_reweight_switch"] == "1"),
  all(assumption$value[assumption$setting == "final_likelihood_weight_goa_trawl_age"] == "0"),
  all(assumption$value[assumption$setting == "final_likelihood_weight_noaa_domestic_longline_survey_rpn"] == "0.448"),
  all(assumption$value[assumption$setting == "final_likelihood_weight_noaa_domestic_longline_survey_rpw"] == "0"),
  all(assumption$value[assumption$setting == "within_year_timing"] == "Not reported"),
  nrow(age_output) == 3900L,
  nrow(total_abundance) == 65L,
  identical(sort(unique(total_abundance$year)), expected_years),
  all(total_abundance$unit == "million fish"),
  all(is.na(total_abundance$se)),
  isTRUE(all.equal(total_abundance$value[order(total_abundance$year)],
    unname(expected_total), tolerance = 1e-10)),
  nrow(recruitment) == 65L,
  nrow(ssb) == 65L,
  nrow(total_biomass) == 65L,
  all(!is.na(ssb$lwr) & !is.na(ssb$upr)),
  all(!is.na(total_biomass$lwr) & !is.na(total_biomass$upr)),
  all(is.na(recruitment$lwr[recruitment$year == 2024]) & is.na(recruitment$upr[recruitment$year == 2024])),
  nrow(m_output) == 1950L,
  all(abs(m_output$value - 0.114303) < 1e-6),
  nrow(manifest) == 14L,
  all(file.exists(file.path(cache, manifest$file))),
  grepl("The source data and outputs are imported", review, fixed = TRUE),
  grepl("No survey index exists for 2024", review, fixed = TRUE),
  grepl("final run assigns iterative likelihood weights", review, fixed = TRUE),
  grepl("Numeric F-at-age output was not located", review, fixed = TRUE),
  grepl("both carry the label", review, fixed = TRUE),
  any(grepl("source labels both vectors Male", length_comp$notes, fixed = TRUE))
)

cat("NOAA Alaska sablefish source rows, units, outputs, and provenance checks passed.\n")

dry_run_script <- tempfile(fileext = ".R")
writeLines(c(
  'Sys.setenv(TAM_SOURCE_DRY_RUN = "1")',
  'source("scripts/database/396_import_noaa_alaska_sablefish_2024.R")'
), dry_run_script)
dry_run <- system2(
  file.path(R.home("bin"), paste0("Rscript", .Platform$exe)),
  shQuote(dry_run_script), stdout = TRUE, stderr = TRUE
)
unlink(dry_run_script)
dry_run_status <- attr(dry_run, "status")
stopifnot(
  is.null(dry_run_status) || identical(as.integer(dry_run_status), 0L),
  any(grepl("inputs: 10805", dry_run, fixed = TRUE)),
  any(grepl("outputs: 6110", dry_run, fixed = TRUE))
)
cat("NOAA Alaska sablefish importer dry run and report-table checks passed.\n")
