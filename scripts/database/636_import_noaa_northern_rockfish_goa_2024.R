root <- "."
stock_id <- "noaa_northern_rockfish_goa"
assessment_id <- paste0(stock_id, "_2024")
candidate_id <- "NOAA:10417"
report_url <- "https://files.npfmc.org/SAFE/2024/GOAnork.pdf"
repository_revision <- "dcf94241c58ad5ccd0056bc7c50c4db338ba61d8"
repository_url <- paste0("https://github.com/noaa-afsc/goa_nork/tree/",
  repository_revision)
cache <- file.path(root, "source_cache", "noaa_northern_rockfish_goa_20261111")
provenance_dir <- file.path(root, "provenance",
  "noaa_northern_rockfish_goa_2024")
manifest_path <- file.path(provenance_dir, "sources.csv")
transcription_dir <- file.path(provenance_dir, "transcriptions")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(row$bytes) ||
      !identical(toupper(unname(tools::sha256sum(path))), toupper(row$sha256))) {
    stop("Cached NOAA source differs from its provenance record: ", name,
      call. = FALSE)
  }
  path
}

source_files <- c("GOA_Northern_Rockfish_2024_SAFE.pdf",
  "2024__R__model_runs.R", "2024__R__models.R",
  "2024__R__2024_goa_nork_assessment.R",
  "2024__data__user_input__goa_nork_catch_1961_1992.csv",
  "2024__data__raw__goa_bts_agecomp_data.csv",
  "2024__data__raw__goa_total_bts_biomass_data.csv",
  "2024__data__raw__goa_bts_sizecomp_data.csv")
invisible(lapply(source_files, verify_source))

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
transcription_env <- new.env(parent = globalenv())
sys.source(file.path(provenance_dir, "transcribe_tables.R"),
  envir = transcription_env)

read_transcription <- function(name) {
  path <- file.path(transcription_dir, name)
  if (!file.exists(path)) stop("Missing transcription: ", name, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

catch <- read_transcription("catch_history.csv")
fishery_age <- read_transcription("fishery_age_composition.csv")
survey_age <- read_transcription("survey_age_composition.csv")
fishery_length <- read_transcription("fishery_length_composition.csv")
survey_vast <- read_transcription("survey_vast_biomass.csv")
survey_design <- read_transcription("survey_design_based_biomass.csv")
biology <- read_transcription("terminal_biology_and_population.csv")
time_series <- read_transcription("time_series.csv")
parameter_summary <- read_transcription("parameter_summary.csv")
sample_sizes <- read_transcription("composition_sample_sizes.csv")
sample_crosscheck <- read_transcription("composition_sample_size_crosscheck.csv")
catch_crosscheck <- read_transcription("catch_history_crosscheck.csv")

fish_years <- c(1998:2002, 2004:2006, 2008L, 2010L, 2012L, 2014L,
  2016L, 2018L, 2020L, 2022L)
survey_years <- c(1990L, 1993L, 1996L, 1999L, 2001L, 2003L, 2005L,
  2007L, 2009L, 2011L, 2013L, 2015L, 2017L, 2019L, 2021L, 2023L)
length_years <- c(1991:1997, 2003L, 2007L, 2009L, 2011L, 2013L, 2015L,
  2017L, 2019L, 2021L, 2023L)
if (!identical(as.integer(catch$year), 1961:2024) ||
    anyNA(catch$total_t) || any(!is.finite(catch$total_t)) ||
    !identical(sort(unique(as.integer(fishery_age$year))), fish_years) ||
    !identical(sort(unique(as.integer(survey_age$year))), survey_years) ||
    !identical(sort(unique(as.integer(fishery_length$year))), length_years) ||
    !identical(as.integer(survey_vast$year), survey_years) ||
    !identical(as.integer(survey_design$year), survey_years) ||
    !identical(as.integer(biology$age), 2:51) ||
    !identical(as.integer(time_series$year), 1977:2024) ||
    !setequal(parameter_summary$metric, c("F40", "spawn_bio", "ABC", "M", "q")) ||
    any(!is.finite(sample_sizes$sample_size)) ||
    any(abs(sample_crosscheck$difference) > 0.11) ||
    any(!is.na(catch_crosscheck$difference_t) & catch_crosscheck$difference_t != 0)) {
  stop("GOA northern-rockfish transcriptions differ from the reviewed years, ages, or cross-checks.",
    call. = FALSE)
}

composition_totals <- function(data, key) {
  rows <- split(data$value, data[[key]])
  vapply(rows, sum, numeric(1L))
}
if (any(abs(composition_totals(fishery_age, "year") - 1) > 0.006) ||
    any(abs(composition_totals(survey_age, "year") - 1) > 0.006) ||
    any(abs(composition_totals(fishery_length, "year") - 1) > 0.006) ||
    any(!is.finite(survey_vast$se_t) | survey_vast$se_t <= 0) ||
    any(!is.finite(survey_vast$biomass_t) | survey_vast$biomass_t <= 0) ||
    any(!is.finite(biology$weight_g) | biology$weight_g <= 0) ||
    any(biology$maturity_percent < 0 | biology$maturity_percent > 100) ||
    any(biology$fishery_selectivity < 0 | biology$fishery_selectivity > 1) ||
    any(biology$survey_selectivity < 0 | biology$survey_selectivity > 1)) {
  stop("GOA northern-rockfish values failed range or composition checks.",
    call. = FALSE)
}

model_script <- readLines(verify_source("2024__R__model_runs.R"), warn = FALSE)
model_text <- paste(model_script, collapse = "\n")
extract_vector <- function(name, occurrence = c("first", "last")) {
  occurrence <- match.arg(occurrence)
  pattern <- paste0("\\b", name, "\\s*=\\s*c\\(([^)]*)\\)")
  matches <- regmatches(model_text, gregexpr(pattern, model_text, perl = TRUE))[[1L]]
  if (!length(matches)) stop("Model setting not found: ", name, call. = FALSE)
  selected <- if (occurrence == "first") matches[1L] else matches[length(matches)]
  value <- sub(pattern, "\\1", selected, perl = TRUE)
  suppressWarnings(as.numeric(strsplit(value, ",", fixed = TRUE)[[1L]]))
}
fishery_age_iss <- extract_vector("fish_age_iss")
survey_age_iss <- extract_vector("srv_age_iss", "last")
fishery_length_iss <- extract_vector("fish_size_iss")
if (length(fishery_age_iss) != length(fish_years) ||
    length(survey_age_iss) != length(survey_years) ||
    length(fishery_length_iss) != length(length_years)) {
  stop("The pinned model script's composition sample sizes do not align with the report.",
    call. = FALSE)
}

sample_size <- function(series, year) {
  row <- sample_sizes[sample_sizes$series == series &
    sample_sizes$year == year, , drop = FALSE]
  if (nrow(row) != 1L) stop("Missing model sample size: ", series, " ", year,
    call. = FALSE)
  row$sample_size
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "NOAA",
  authority_stock_id = "10417", scientific_name = "Sebastes polyspinis",
  common_name = "Northern rockfish", area = "Western / Central Gulf of Alaska",
  region = "Gulf of Alaska", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART unit 10417, distinct from Bering Sea/Aleutian Islands unit 10416.",
  stringsAsFactors = FALSE)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2024L, terminal_year = 2024L,
  estimate_terminal_year = 2024L, assessment_type = "full_assessment",
  model_family = "RTMB age-structured model", model_version = "m24 preferred model",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = "",
  data_url = paste0(repository_url, "/2024/data"),
  model_url = paste0(repository_url, "/2024/R"),
  repository_url = repository_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The 2024 m24 full assessment is the latest finalized production run found.",
    "A 2026 update draft was posted for November Plan Team review and is not treated as a finalized assessment.",
    "The report's Table 10-3 caption says dusky rockfish, while the chapter text identifies the series as northern-rockfish catch; values for 1961-1992 match the pinned AFSC northern-rockfish catch file.",
    "Some native matrices and full annual N/F surfaces are not publicly available."),
  stringsAsFactors = FALSE)

assumption <- function(component, setting, value, source_reference, notes = "",
                       fleet = "", survey = "", season = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = fleet, survey = survey, sex = "", region = "GOA", season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
repo_ref <- paste0("AFSC goa_nork repository, revision ", repository_revision,
  ", 2024/R/model_runs.R and 2024/R/models.R")
table_ref <- "2024 GOA Northern Rockfish SAFE, Tables 10-3, 10-9 to 10-19"
assumptions_new <- do.call(rbind, list(
  assumption("model", "software", "RTMB", repo_ref),
  assumption("model", "model_version", "m24 preferred model", table_ref),
  assumption("population", "composition_age_range", "Ages 2-45", repo_ref),
  assumption("population", "reported_terminal_age_range", "Ages 2-51 as printed",
    "2024 GOA Northern Rockfish SAFE, Table 10-16",
    "The report does not print a plus sign at age 51; values are preserved as printed."),
  assumption("population", "recruitment_age", "Age 2", table_ref),
  assumption("population", "spawning_biomass_definition", "Female spawning biomass",
    "2024 GOA Northern Rockfish SAFE, Table 10-19",
    "The model forms mature weight as weight-at-age times female maturity divided by two."),
  assumption("biology", "female_fraction", "0.5", repo_ref,
    "Used in the model's mature-weight construction."),
  assumption("biology", "age_error_matrix", "unknown", repo_ref,
    "The model code reads ae_model.csv, but the matrix is not present in the pinned public repository files reviewed."),
  assumption("biology", "length_at_age_matrix", "unknown", repo_ref,
    "The model code reads saa.csv, but the matrix is not present in the pinned public repository files reviewed."),
  assumption("M", "parameterization", "One estimated constant scalar M", repo_ref),
  assumption("M", "prior", "Lognormal prior; mean 0.06 per year; CV 0.05", repo_ref,
    "The model applies a normal prior to log(M) with the stated relative scale."),
  assumption("q", "parameterization", "One estimated survey catchability q", repo_ref),
  assumption("q", "prior", "Lognormal prior; mean 1; CV 0.45", repo_ref,
    "The model applies a normal prior to log(q) with the stated relative scale.",
    survey = "GOA bottom-trawl survey"),
  assumption("recruitment", "process_sd", "Fixed at 1.5", repo_ref,
    "sigmaR is mapped as fixed in the preferred model; the supplied CV setting is 0.01."),
  assumption("recruitment", "process_variance_weight", "1", repo_ref),
  assumption("F", "regularity_penalty_weight", "0.1", repo_ref),
  assumption("catch", "likelihood_weight", "5 for 1961-1977; 50 for 1978-2024",
    repo_ref, "Aggregate catch weights are recorded here because they do not have an age dimension in the input schema."),
  assumption("index", "likelihood_weight", "0.25", repo_ref,
    "Applies to the preferred VAST biomass index; also stored by year in inputs.csv.",
    survey = "GOA bottom-trawl survey"),
  assumption("composition", "fishery_age_likelihood_weight", "0.5", repo_ref,
    survey = ""),
  assumption("composition", "survey_age_likelihood_weight", "0.5", repo_ref,
    survey = "GOA bottom-trawl survey"),
  assumption("composition", "fishery_length_likelihood_weight", "0.5", repo_ref),
  assumption("population", "spawning_month", "May", repo_ref),
  assumption("index", "sampling_time", "unknown", table_ref,
    "The assessment uses an annual survey index but the exact fractional within-year timing is not reported.",
    survey = "GOA bottom-trawl survey"),
  assumption("index", "preferred_biomass_series", "VAST lognormal biomass index",
    repo_ref, "The design-based biomass series in Table 10-12 is an alternative and is not used in m24.",
    survey = "GOA bottom-trawl survey"),
  assumption("biology", "weight_schedule", "Age-specific g/fish schedule",
    "2024 GOA Northern Rockfish SAFE, Table 10-16",
    "Reported as the age-specific weight schedule used by the preferred model."),
  assumption("biology", "maturity_schedule", "Female age-specific maturity percent",
    "2024 GOA Northern Rockfish SAFE, Table 10-16",
    "Percent values are converted to proportions in inputs.csv.")))

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
    age = NA_real_, fleet = "", survey = "", season = "", sampling_time = NA_real_,
    source_type = "official_table", source_reference, transformation = "",
    notes = "", observation_id = "", length_bin = NA_real_,
    sample_size = NA_real_) {
  n <- length(value)
  repn <- function(x) rep_len(x, n)
  y <- repn(year)
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = rep(assessment_id, n), type = repn(type),
    measure = repn(measure), basis = repn(basis), fleet = repn(fleet),
    survey = repn(survey), sex = "", region = "GOA", season = repn(season),
    year = y, year_basis = ifelse(is.na(y), "", "calendar_year"),
    age = repn(age), value = as.numeric(value), unit = repn(unit),
    sampling_time = repn(sampling_time), source_type = repn(source_type),
    source_reference = repn(source_reference), transformation = repn(transformation),
    notes = repn(notes), observation_id = repn(observation_id),
    length_bin = repn(length_bin), length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = repn(sample_size),
    age_error = "", partition = "", weight_bin = "",
    stringsAsFactors = FALSE)
}

catch_id <- paste0("GOA_NORK_CATCH_", catch$year)
add_input("catch", "catch_biomass", "biomass", catch$total_t, "t",
  year = catch$year, fleet = "GOA fishery", season = "annual",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-3, pp. 34-35",
  notes = paste(
    "Total commercial fishery catch as used in the assessment; foreign, joint-venture, and domestic components are not represented as independent fleets.",
    "The table caption says dusky rockfish, but the Northern Rockfish chapter text identifies this series as northern-rockfish catch. Values for 1961-1992 match the pinned AFSC GOA northern-rockfish catch file.",
    "2024 catch is reported through 2024-10-16."),
  observation_id = catch_id)
add_composition <- function(data, series, type, measure, basis, unit, years,
    id_prefix, fleet = "", survey = "", season = "annual", dimension = "age",
    source_reference, weight = 0.5, notes) {
  for (year in years) {
    cells <- data[data$year == year, , drop = FALSE]
    size <- sample_size(series, year)
    if (!nrow(cells)) stop("Composition cells are missing for ", series, " ", year,
      call. = FALSE)
    id <- paste0(id_prefix, year)
    add_input(type, measure, basis,
      cells$value, unit, year = rep(year, nrow(cells)),
      age = if (dimension == "age") cells$age else NA_real_,
      length_bin = if (dimension == "length_bin") cells$length_bin else NA_real_,
      fleet = fleet, survey = survey, season = season,
      source_reference = source_reference,
      notes = notes, observation_id = id, sample_size = rep(size, nrow(cells)))
    add_input(type,
      "observation_likelihood_weight", "relative_scale", weight,
      "relative likelihood weight", year = year, fleet = fleet, survey = survey,
      season = season, source_type = "official_machine_readable",
      source_reference = repo_ref,
      notes = "Likelihood weight supplied in the m24 model script.",
      observation_id = id)
  }
  invisible(NULL)
}

add_composition(fishery_age, "fishery_age",
  "catch", "proportion_at_age", "proportion_numbers", "proportion", fish_years,
  "GOA_NORK_FISHERY_AGE_", fleet = "GOA fishery", season = "annual",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-10",
  notes = paste(
    "Fishery age-composition proportions are retained as printed and not renormalized.",
    "sample_size is the exact model-supplied likelihood sample size from the pinned m24 script, not a raw fish count."))
add_composition(fishery_length, "fishery_length",
  "catch", "proportion_at_length", "proportion_numbers", "proportion", length_years,
  "GOA_NORK_FISHERY_LENGTH_", fleet = "GOA fishery", season = "annual",
  dimension = "length_bin",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-9",
  notes = paste(
    "Fishery length-composition proportions are retained as printed and not renormalized.",
    "Length bins 15 and 45 include the source's pooled tails. sample_size is the exact model-supplied likelihood value, not a raw fish count; the 1996 code value 46.4495 rounds to the report's 46.5."))
add_composition(survey_age, "survey_age",
  "index", "proportion_at_age", "proportion_numbers", "proportion", survey_years,
  "GOA_NORK_SURVEY_AGE_", survey = "GOA bottom-trawl survey", season = "summer",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-13",
  notes = paste(
    "Survey age-composition proportions are retained as printed and not renormalized.",
    "sample_size is the exact model-supplied likelihood sample size from the pinned m24 script."))

survey_name <- "GOA bottom-trawl survey"
survey_id <- paste0("GOA_NORK_VAST_BIOMASS_", survey_vast$year)
add_input("index", "total_biomass", "biomass", survey_vast$biomass_t, "t",
  year = survey_vast$year, survey = survey_name, season = "summer",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-11",
  notes = "Preferred m24 VAST lognormal survey biomass index.",
  observation_id = survey_id)
add_input("index", "index_sd", "biomass", survey_vast$se_t, "t",
  year = survey_vast$year, survey = survey_name, season = "summer",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-11",
  notes = paste0("Source-reported natural-scale standard error; the table also gives 95% bounds.",
    " The m24 model script passes this standard error as srv_sd."),
  observation_id = survey_id)
add_input("index", "relative_precision_weight", "relative_precision",
  rep(0.25, nrow(survey_vast)), "relative likelihood weight",
  year = survey_vast$year, survey = survey_name, season = "summer",
  source_type = "official_machine_readable", source_reference = repo_ref,
  notes = "VAST biomass-index likelihood weight supplied in the m24 model script.",
  observation_id = survey_id)

add_input("biology", "weight_at_age", "g_per_fish", biology$weight_g, "g/fish",
  age = biology$age,
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-16",
  notes = "Reported age-specific weight schedule used by the preferred model.")
add_input("biology", "maturity_at_age", "proportion",
  biology$maturity_percent / 100, "proportion", age = biology$age,
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-16",
  transformation = "Reported percent maturity divided by 100 to store a proportion.",
  notes = "Female age-specific maturity schedule; source reports whole percentages.")
inputs_new <- do.call(rbind, input_rows)

output_row <- function(type, measure, value, unit, year = NA_integer_,
    age = NA_real_, age_group = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
    fleet = "", survey = "", scenario = "", source_type = "official_table",
    source_reference, notes = "") {
  n <- length(value)
  repn <- function(x) rep_len(x, n)
  data.frame(assessment_id = assessment_id, type = repn(type),
    measure = repn(measure), fleet = repn(fleet), survey = repn(survey),
    sex = "", region = "GOA", season = "", year = repn(year),
    age = repn(age), age_group = repn(age_group), value = as.numeric(value),
    se = repn(se), lwr = repn(lwr), upr = repn(upr), unit = repn(unit),
    source_type = repn(source_type), source_reference = repn(source_reference),
    notes = repn(notes), scenario = repn(scenario), stringsAsFactors = FALSE)
}

output_rows <- list()
add_time_series <- function(measure, values, unit, age = NA_integer_,
    source_reference, notes) {
  output_rows[[length(output_rows) + 1L]] <<- output_row(
    if (measure == "recruitment") "recruitment" else "biomass",
    measure, values, unit, year = time_series$year, age = age,
    lwr = if (measure == "recruitment") time_series$recruitment_lwr_thousand else
      if (measure == "total_biomass") time_series$total_biomass_lwr_t else time_series$ssb_lwr_t,
    upr = if (measure == "recruitment") time_series$recruitment_upr_thousand else
      if (measure == "total_biomass") time_series$total_biomass_upr_t else time_series$ssb_upr_t,
    scenario = "MCMC mean", source_reference = source_reference, notes = notes)
}
series_note <- paste(
  "MCMC mean with the source-reported 2.5% and 97.5% confidence bounds.",
  "No standard error is tabulated; intervals are retained on the natural scale.")
add_time_series("recruitment", time_series$recruitment_mean_thousand,
  "thousand fish", age = 2L,
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-19",
  notes = paste("Age-2 recruitment.", series_note))
add_time_series("total_biomass", time_series$total_biomass_mean_t, "t",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-19",
  notes = paste("Annual total-biomass series from m24.", series_note))
add_time_series("SSB", time_series$ssb_mean_t, "t",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-19",
  notes = paste("Annual female spawning-biomass series from m24.", series_note))

output_rows[[length(output_rows) + 1L]] <- output_row(
  "population", "numbers_at_age", biology$abundance_thousand, "thousand fish",
  year = 2024L, age = biology$age, scenario = "terminal-year estimate",
  source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-16",
  notes = "Estimated 2024 abundance at age; the report prints ages 2-51 without a plus-group suffix and does not tabulate uncertainty.")
output_rows[[length(output_rows) + 1L]] <- output_row(
  "population", "total_abundance", sum(biology$abundance_thousand), "thousand fish",
  year = 2024L, age_group = "2-51", source_type = "derived_source_output",
  source_reference = "Derived by summing 2024 GOA Northern Rockfish SAFE, Table 10-16",
  notes = "Derived terminal-year abundance by summing all reported age-specific numbers. No joint uncertainty is available; the source age labels 2-51 are preserved.")
output_rows[[length(output_rows) + 1L]] <- output_row(
  "biology", "fleet_selectivity_at_age", biology$fishery_selectivity,
  "proportion", age = biology$age, fleet = "GOA fishery",
  scenario = "preferred m24", source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-16",
  notes = "Estimated fishery selectivity at age from the preferred model.")
output_rows[[length(output_rows) + 1L]] <- output_row(
  "biology", "fleet_selectivity_at_age", biology$survey_selectivity,
  "proportion", age = biology$age, survey = survey_name,
  scenario = "preferred m24", source_reference = "2024 GOA Northern Rockfish SAFE, Table 10-16",
  notes = "Estimated survey selectivity at age from the preferred model.")

parameter_specs <- list(
  F40 = c(type = "parameter", measure = "F40_percent", unit = "per year"),
  M = c(type = "mortality", measure = "natural_mortality_average_parameter", unit = "per year"),
  q = c(type = "catchability", measure = "q", unit = "dimensionless"))
for (metric in names(parameter_specs)) {
  x <- parameter_summary[parameter_summary$metric == metric, , drop = FALSE]
  spec <- parameter_specs[[metric]]
  survey <- if (metric == "q") survey_name else ""
  reference <- "2024 GOA Northern Rockfish SAFE, Table 10-18"
  notes <- paste0("Table 10-18 source-reported MCMC standard deviation is ",
    x$mcmc_sd, "; it is not stored as a standard error.")
  output_rows[[length(output_rows) + 1L]] <- output_row(
    spec[["type"]], spec[["measure"]], x$estimate, spec[["unit"]],
    survey = survey, scenario = "point estimate", source_reference = reference,
    notes = "Source-reported point estimate.")
  output_rows[[length(output_rows) + 1L]] <- output_row(
    spec[["type"]], spec[["measure"]], x$mcmc_mean, spec[["unit"]],
    survey = survey, scenario = "MCMC mean", lwr = x$bci_lower, upr = x$bci_upper,
    source_reference = reference,
    notes = paste(notes, "The lower and upper bounds are 95% Bayesian credible intervals."))
  output_rows[[length(output_rows) + 1L]] <- output_row(
    spec[["type"]], spec[["measure"]], x$mcmc_median, spec[["unit"]],
    survey = survey, scenario = "MCMC median", source_reference = reference,
    notes = paste(notes, "The Table 10-18 credible interval is stored with the MCMC mean row."))
}
outputs_new <- do.call(rbind, output_rows)

input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey",
  "sex", "region", "season", "year", "year_basis", "age", "observation_id",
  "length_bin", "length_bin_lower", "length_bin_upper", "sample_size",
  "age_error", "partition", "weight_bin")
output_key <- c("assessment_id", "type", "measure", "fleet", "survey", "sex",
  "region", "season", "year", "age", "age_group", "scenario")
if (nrow(inputs_new) != 2196L || nrow(outputs_new) != 304L ||
    nrow(assumptions_new) != 26L || anyDuplicated(inputs_new[input_key]) ||
    anyDuplicated(outputs_new[output_key]) ||
    sum(inputs_new$measure == "catch_biomass") != 64L ||
    sum(inputs_new$measure == "proportion_at_age" & inputs_new$type == "catch") != 704L ||
    sum(inputs_new$measure == "proportion_at_age" & inputs_new$type == "index") != 704L ||
    sum(inputs_new$measure == "proportion_at_length") != 527L ||
    sum(inputs_new$measure == "total_biomass" & inputs_new$type == "index") != 16L ||
    sum(outputs_new$measure == "SSB") != 48L ||
    sum(outputs_new$measure == "numbers_at_age") != 50L) {
  stop("GOA northern-rockfish import has unexpected row counts or duplicate keys.",
    call. = FALSE)
}

row_signature <- function(data) {
  values <- lapply(data, function(x) {
    if (is.numeric(x)) {
      out <- format(x, scientific = FALSE, trim = TRUE, digits = 15)
      out[is.na(x)] <- ""
    } else {
      out <- as.character(x)
      out[is.na(x)] <- ""
    }
    out
  })
  do.call(paste, c(values, sep = "\r"))
}
read_matching_rows <- function(path, id) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to check existing assessment rows.", call. = FALSE)
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  found <- found[startsWith(found, paste0('"', id, '",'))]
  if (!length(found)) return(data.frame())
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, found), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}
assert_rows_match_or_absent <- function(existing, expected, label) {
  if (!nrow(existing)) return(invisible(FALSE))
  if (nrow(existing) != nrow(expected) ||
      !setequal(row_signature(existing), row_signature(expected))) {
    stop("Existing GOA northern-rockfish ", label,
      " rows differ from the reviewed transcriptions.", call. = FALSE)
  }
  invisible(TRUE)
}

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stock_existing <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment_existing <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions_existing <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L ||
    (nrow(stock_existing) && !setequal(row_signature(stock_existing), row_signature(stock_row))) ||
    (nrow(assessment_existing) && !setequal(row_signature(assessment_existing), row_signature(assessment_row)))) {
  stop("Existing GOA northern-rockfish stock or assessment differs from the reviewed identity.",
    call. = FALSE)
}
assert_rows_match_or_absent(assumptions_existing, assumptions_new, "assumption")
assert_rows_match_or_absent(inputs_existing, inputs_new, "input")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified NOAA GOA Northern Rockfish 2024 m24 source import.\n")
cat("Inputs:", nrow(inputs_new), "rows, including catch biomass, age/length compositions, VAST biomass and uncertainty, biological schedules, and likelihood weights.\n")
cat("Outputs:", nrow(outputs_new), "rows, including annual MCMC mean series, 2024 N-at-age, derived abundance, selectivity, and scalar parameter summaries.\n")
cat("Catch totals were cross-checked to the pinned AFSC file for 1961-1992; no composition rows were renormalized.\n")
cat("Unresolved: survey timing, exact age-error and length-age matrices, complete annual N/F surfaces, and the year represented by Table 10-18 spawn_bio/ABC.\n")

if (write_mode) {
  append_csv <- function(x, path) write.table(x, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    qmethod = "double", eol = "\n")
  expected_columns <- list(
    stocks = names(read.csv(stocks_path, nrows = 0L, check.names = FALSE)),
    assessments = names(read.csv(assessments_path, nrows = 0L, check.names = FALSE)),
    assumptions = names(read.csv(assumptions_path, nrows = 0L, check.names = FALSE)),
    inputs = names(read.csv(inputs_path, nrows = 0L, check.names = FALSE)),
    outputs = names(read.csv(outputs_path, nrows = 0L, check.names = FALSE)))
  row_sets <- list(stocks = stock_row, assessments = assessment_row,
    assumptions = assumptions_new, inputs = inputs_new, outputs = outputs_new)
  if (!all(vapply(names(row_sets), function(name)
      identical(names(row_sets[[name]]), expected_columns[[name]]), logical(1L)))) {
    stop("An import table does not match the canonical database column order.", call. = FALSE)
  }
  if (nrow(stock_existing) && !nrow(assessment_existing) &&
      (nrow(assumptions_existing) || nrow(inputs_existing) || nrow(outputs_existing))) {
    stop("Database contains partial GOA northern-rockfish rows; refusing an unsafe append.",
      call. = FALSE)
  }
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions_existing)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(inputs_existing)) append_csv(inputs_new, inputs_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"), local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id &
    candidates$official_stock_id == "10417")
  if (length(ci) != 1L || candidates$screening_status[ci] != "screened" ||
      candidates$eligibility[ci] != "eligible" ||
      candidates$match_status[ci] %in% c("ambiguous", "unreviewed")) {
    stop("Expected one screened, eligible NOAA:10417 candidate.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- report_url
  candidates$review_date[ci] <- "2026-11-11"
  candidates$catch_age_evidence[ci] <- paste(
    "Imported 1961-2024 total commercial catch biomass and fishery age compositions for 16 years (ages 2-45), plus fishery length compositions for 17 years.",
    "The source does not provide direct catch numbers-at-age; the Table 10-3 caption mismatch is documented in the review.")
  candidates$survey_age_evidence[ci] <- paste(
    "Imported the preferred m24 VAST survey biomass estimates and source-reported standard errors for 16 years, plus survey age compositions for 16 years (ages 2-45).",
    "The design-based biomass series is an alternative not used in m24; age-specific abundance indices are not separately reported.")
  candidates$weights_evidence[ci] <- paste(
    "Imported the age-specific g/fish weight schedule from Table 10-16.",
    "The original annual weight file is not in the pinned public repository.")
  candidates$maturity_evidence[ci] <- paste(
    "Imported the female maturity schedule from Table 10-16, converting whole percentages to proportions.",
    "The raw preferred-run report file is not in the pinned public repository.")
  candidates$mortality_evidence[ci] <- paste(
    "M is an estimated constant scalar with a prior mean of 0.06 per year and CV 0.05.",
    "Table 10-18 reports the scalar M estimate; an M-at-age surface is not reported.")
  candidates$timing_evidence[ci] <- paste(
    "The index is an annual summer bottom-trawl survey series.",
    "The fitted fractional within-year timing is not reported.")
  candidates$output_evidence[ci] <- paste(
    "Imported 1977-2024 MCMC mean recruitment at age 2, total biomass and female spawning biomass with 95% confidence bounds; 2024 N-at-age and selectivity schedules; and M, q and F40 parameter summaries.",
    "Full annual N-at-age and F-at-age surfaces are not publicly available.")
  candidates$decision_reason[ci] <- paste(
    "The finalized 2024 m24 assessment remains the latest production model located.",
    "The 2026 update draft was posted for November Plan Team review and is not treated as a finalized run.")
  candidates$notes[ci] <- paste(
    "Partial source data imported from the 2024 SAFE and pinned AFSC source repository.",
    "The catch table caption mismatch, rounded sample-size discrepancy, unavailable likelihood matrices, missing survey timing, and draft 2026 update are documented in discovery/source_reviews/noaa_northern_rockfish_goa_2024.md.")
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)

  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("GOA northern-rockfish rows imported and database validation passed.\n")
} else {
  cat("Dry run only. Add --write to append the reviewed records.\n")
}
