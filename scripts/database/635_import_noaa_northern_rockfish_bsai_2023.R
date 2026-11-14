root <- "."
stock_id <- "noaa_northern_rockfish_bsai"
assessment_id <- paste0(stock_id, "_2023")
candidate_id <- "NOAA:10416"
source_url <- "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAInork.pdf"
cache <- file.path(root, "source_cache", "noaa_northern_rockfish_bsai_2023")
manifest_path <- file.path(root, "provenance", "noaa_northern_rockfish_20261029", "sources.csv")
transcription_dir <- file.path(root, "provenance", assessment_id, "transcriptions")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)

verify_source <- function(name) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(row$bytes) ||
      !identical(toupper(unname(tools::sha256sum(path))), toupper(row$sha256))) {
    stop("Cached NOAA source differs from its provenance manifest: ", name,
      call. = FALSE)
  }
  path
}

report_path <- verify_source("BSAI_Northern_Rockfish_2023_SAFE.pdf")
.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to verify the cached NOAA SAFE.", call. = FALSE)
}
report_pages <- pdftools::pdf_text(report_path)
report_text <- paste(report_pages, collapse = "\n")
if (length(report_pages) < 49L ||
    !grepl("BSAI Northern rockfish", report_text, fixed = TRUE) ||
    !grepl("Model 21", report_text, fixed = TRUE) ||
    !grepl("Table 23", report_text, fixed = TRUE) ||
    !grepl("Table 24", report_text, fixed = TRUE)) {
  stop("The pinned SAFE does not contain the reviewed 2023 northern-rockfish tables.",
    call. = FALSE)
}

read_transcription <- function(name) {
  path <- file.path(transcription_dir, name)
  if (!file.exists(path)) stop("Missing reviewed transcription: ", name, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

catch <- read_transcription("catch_totals.csv")
survey_all <- read_transcription("survey_biomass.csv")
fish_comp <- read_transcription("fishery_age_composition.csv")
survey_comp <- read_transcription("survey_age_composition.csv")
fish_comp$age <- as.integer(sub("\\+$", "", as.character(fish_comp$age)))
survey_comp$age <- as.integer(sub("\\+$", "", as.character(survey_comp$age)))
sample_sizes <- read_transcription("age_composition_sample_sizes.csv")
biology <- read_transcription("average_biology.csv")
ts <- read_transcription("time_series.csv")
n_small <- read_transcription("numbers_at_age_3_22.csv")
n_large <- read_transcription("numbers_at_age_21_40plus.csv")
parameters <- read_transcription("selected_parameters.csv")

fish_years <- as.integer(setdiff(names(fish_comp), "age"))
survey_years <- as.integer(setdiff(names(survey_comp), "age"))
survey <- survey_all[!survey_all$year %in% c(1980L, 1983L, 1986L), , drop = FALSE]
if (!identical(as.integer(catch$year), 1977:2023) ||
    !identical(as.integer(survey$year), c(1991L, 1994L, 1997L, 2000L, 2002L,
      2004L, 2006L, 2010L, 2012L, 2014L, 2016L, 2018L, 2022L)) ||
    !identical(fish_years, c(2000:2009, 2011L, 2013L, 2015L, 2017L, 2019:2021)) ||
    !identical(survey_years, as.integer(survey$year)) ||
    nrow(fish_comp) != 38L || nrow(survey_comp) != 38L ||
    !identical(as.integer(fish_comp$age), 3:40) ||
    !identical(as.integer(survey_comp$age), 3:40) ||
    !identical(as.integer(biology$age), 3:40) ||
    !identical(as.integer(ts$year), 1977:2024)) {
  stop("Reviewed northern-rockfish source tables have unexpected years or ages.",
    call. = FALSE)
}
if (any(abs(colSums(fish_comp[-1L]) - 1) > 0.021) ||
    any(abs(colSums(survey_comp[-1L]) - 1) > 0.021)) {
  stop("Printed age proportions exceed the documented rounding tolerance.",
    call. = FALSE)
}
if (!all(sample_sizes$otoliths_read > 0) ||
    !identical(sort(unique(sample_sizes$year[sample_sizes$series == "fishery"])),
      fish_years) ||
    !identical(sort(unique(sample_sizes$year[sample_sizes$series == "survey"])),
      survey_years)) {
  stop("Reported otolith counts do not match the age-composition years.",
    call. = FALSE)
}

age_values <- function(x, prefix) {
  out <- x
  names(out) <- sub(prefix, "", names(out), fixed = TRUE)
  names(out)[names(out) == "40plus"] <- "40"
  out
}
small_values <- age_values(n_small, "age")
large_values <- age_values(n_large, "age")
n_years <- as.integer(small_values$year)
if (!identical(n_years, 1977:2023) ||
    !identical(as.integer(large_values$year), n_years)) {
  stop("Table 24 age tables do not share the expected years.", call. = FALSE)
}
n_matrix <- matrix(NA_real_, nrow = length(n_years), ncol = 38L,
  dimnames = list(n_years, as.character(3:40)))
for (age in 3:22) n_matrix[, as.character(age)] <- small_values[[as.character(age)]]
for (age in 21:40) {
  values <- large_values[[as.character(age)]]
  if (age %in% 21:22 &&
      any(abs(n_matrix[, as.character(age)] - values) > 1e-8)) {
    stop("Table 24 overlap differs between pages 48 and 49.", call. = FALSE)
  }
  n_matrix[, as.character(age)] <- values
}
if (any(!is.finite(n_matrix)) || any(n_matrix < 0)) {
  stop("Table 24 numbers-at-age contains missing or invalid values.", call. = FALSE)
}

stock_row <- data.frame(
  stock_id = stock_id, charbonneau_id = NA_character_, authority = "NOAA",
  authority_stock_id = "10416",
  scientific_name = "Sebastes polyspinis", common_name = "Northern rockfish",
  area = "Bering Sea / Aleutian Islands",
  region = "Bering Sea / Aleutian Islands", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART unit 10416; Bering Sea / Aleutian Islands. The 2023 SAFE is the latest full model fit located; the 2026 report is a projection update.",
  stringsAsFactors = FALSE
)

assessment_row <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2023L, terminal_year = 2023L, estimate_terminal_year = 2023L,
  assessment_type = "full_assessment",
  model_family = "AD Model Builder age-structured model",
  model_version = "Model 21 (2023)", is_current = TRUE, is_applied = TRUE,
  framework_year = NA_integer_, assessment_url = source_url,
  framework_url = "", data_url = source_url, model_url = "",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "Latest full fit located. The planned 2025 full assessment was cancelled; the 2026 BSAI chapter carries the 2023 estimates into a harvest projection and does not re-fit the assessment.",
  stringsAsFactors = FALSE
)

assumption <- function(component, setting, value, source_reference, notes = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = "", survey = "", sex = "", region = "BSAI", season = "",
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions_new <- do.call(rbind, list(
  assumption("model", "software", "AD Model Builder",
    "2023 BSAI SAFE, December 2023, p. 11"),
  assumption("model", "model_version", "Model 21",
    "2023 BSAI SAFE, Table 22, p. 46",
    "The report states that the model is unchanged from the accepted 2021 model."),
  assumption("population", "age_range", "Ages 3-40; age 40 is the 40+ group",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("population", "recruitment_age", "Age 3",
    "2023 BSAI SAFE, Table 23, p. 47"),
  assumption("population", "spawning_biomass_definition",
    "Mature biomass, ages 3+",
    "2023 BSAI SAFE, Table 18, p. 42"),
  assumption("M", "prior", "Mean 0.06 per year; log-scale SD 0.15",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("q", "prior", "Mean 1.0; log-scale SD 0.001",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("composition", "weighting",
    "McAllister-Ianelli composition weighting",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("catch", "likelihood_weight", "200",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("index", "survey_likelihood_weight", "1",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("F", "deviation_penalty", "0.1",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("recruitment", "process_variability", "0.75",
    "2023 BSAI SAFE, Table 18, pp. 41-42"),
  assumption("index", "survey_selectivity_constraint_sd", "0.003",
    "2023 BSAI SAFE, Table 18, pp. 41-42")
))

input_row <- function(type, measure, basis, value, unit,
                      year = NA_integer_, age = NA_real_, fleet = "",
                      survey = "", sex = "", region = "BSAI", season = "",
                      sampling_time = NA_real_, source_type = "official_table",
                      source_reference, transformation = "", notes = "",
                      observation_id = "", sample_size = NA_real_) {
  n <- length(value)
  repn <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = repn(type),
    measure = repn(measure), basis = repn(basis), fleet = repn(fleet),
    survey = repn(survey), sex = repn(sex), region = repn(region),
    season = repn(season), year = repn(year),
    year_basis = ifelse(is.na(repn(year)), "", "calendar_year"),
    age = repn(age), value = value, unit = repn(unit),
    sampling_time = repn(sampling_time), source_type = repn(source_type),
    source_reference = repn(source_reference),
    transformation = repn(transformation), notes = repn(notes),
    observation_id = repn(observation_id),
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = repn(sample_size),
    age_error = NA_real_, partition = "", weight_bin = NA_real_,
    stringsAsFactors = FALSE
  )
}

input_rows <- list()
input_rows[[length(input_rows) + 1L]] <- input_row(
  "catch", "catch_biomass", "biomass", catch$catch_t, "t",
  year = as.integer(catch$year), fleet = "BSAI fishery", season = "annual",
  source_reference = "2023 BSAI SAFE, Table 3, p. 26",
  notes = "Annual total BSAI fishery catch as reported. The 2023 value is retained as shown in the SAFE; the table notes data through September 16."
)

survey_name <- "Aleutian Islands bottom trawl survey"
input_rows[[length(input_rows) + 1L]] <- input_row(
  "index", "total_biomass", "biomass", survey$total_ai_biomass_t, "t",
  year = as.integer(survey$year), survey = survey_name, season = "summer",
  source_reference = "2023 BSAI SAFE, Table 13, p. 37",
  notes = "Aleutian Islands survey biomass observations included in the 2023 Model 21 likelihood. Cooperative survey estimates for 1980, 1983 and 1986 are preserved in the transcription but excluded from this input series because of vessel and gear differences."
)
input_rows[[length(input_rows) + 1L]] <- input_row(
  "index", "biomass_index_cv", "relative_scale", survey$cv, "ratio",
  year = as.integer(survey$year), survey = survey_name, season = "summer",
  source_reference = "2023 BSAI SAFE, Table 13, p. 37",
  notes = "Source-reported coefficient of variation paired with the Model 21 survey biomass observation. Table 13 value 0.23 is retained for 2022."
)

composition_rows <- function(table, years, series, type, fleet = "",
                             survey = "", season, reference) {
  rows <- list()
  for (year in years) {
    sample_row <- sample_sizes[
      sample_sizes$series == series & sample_sizes$year == year, , drop = FALSE
    ]
    if (nrow(sample_row) != 1L) stop("Missing one reported age sample size.", call. = FALSE)
    id <- paste0("NORTHERN_ROCKFISH_", toupper(series), "_AGE_", year)
    values <- table[[as.character(year)]]
    label <- ifelse(as.integer(table$age) == 40,
      " Age 40 is the source's 40+ group.", "")
    notes <- paste0(
      "Observed age composition as printed; values are rounded to three decimals and are not renormalized.",
      label,
      " sample_size is the report's number of otoliths read, not a separately reported effective likelihood sample size."
    )
    rows[[length(rows) + 1L]] <- input_row(
      type, "proportion_at_age", "proportion_numbers", values, "proportion",
      year = rep(as.integer(year), length(values)), age = as.integer(table$age),
      fleet = fleet, survey = survey, season = season,
      source_reference = reference, notes = notes,
      observation_id = rep(id, length(values)),
      sample_size = rep(sample_row$otoliths_read, length(values))
    )
    rows[[length(rows) + 1L]] <- input_row(
      "biology", "composition_sample_count", "numbers",
      sample_row$otoliths_read, "otoliths",
      year = as.integer(year), fleet = fleet, survey = survey, season = season,
      source_reference = if (series == "fishery")
        "2023 BSAI SAFE, Table 10, p. 34" else "2023 BSAI SAFE, Table 15, p. 39",
      notes = "Raw number of otoliths read for the associated composition; distinct from any effective sample size or likelihood reweighting.",
      observation_id = id
    )
  }
  do.call(rbind, rows)
}
input_rows[[length(input_rows) + 1L]] <- composition_rows(
  fish_comp, fish_years, "fishery", "catch", fleet = "BSAI fishery",
  season = "annual", reference = "2023 BSAI SAFE, Table 12, p. 36"
)
input_rows[[length(input_rows) + 1L]] <- composition_rows(
  survey_comp, survey_years, "survey", "index", survey = survey_name,
  season = "summer", reference = "2023 BSAI SAFE, Table 14, p. 38"
)
inputs_new <- do.call(rbind, input_rows)

output_row <- function(type, measure, value, unit, year = NA_integer_,
                       age = NA_real_, age_group = "", se = NA_real_,
                       sex = "", fleet = "", survey = "", region = "BSAI",
                       scenario = "", source_type = "official_table",
                       source_reference, notes = "") {
  n <- length(value)
  repn <- function(x) rep_len(x, n)
  data.frame(
    assessment_id = rep(assessment_id, n), type = repn(type),
    measure = repn(measure), fleet = repn(fleet), survey = repn(survey),
    sex = repn(sex), region = repn(region), season = "",
    year = repn(year), age = repn(age), age_group = repn(age_group),
    value = value, se = repn(se), lwr = NA_real_, upr = NA_real_,
    unit = repn(unit), source_type = repn(source_type),
    source_reference = repn(source_reference), notes = repn(notes),
    scenario = repn(scenario), stringsAsFactors = FALSE
  )
}

outputs <- list()
ts_scenario <- ifelse(ts$year == 2024L, "2024 projection", "")
add_series <- function(type, measure, values, unit, reference, note,
                       cv_measure = NULL, cv_values = NULL, cv_note = "") {
  keep <- !is.na(values)
  outputs[[length(outputs) + 1L]] <<- output_row(
    type, measure, values[keep], unit, year = as.integer(ts$year[keep]),
    scenario = ts_scenario[keep], source_reference = reference, notes = note
  )
  if (!is.null(cv_measure)) {
    cv_keep <- !is.na(cv_values)
    outputs[[length(outputs) + 1L]] <<- output_row(
      type, cv_measure, cv_values[cv_keep], "ratio",
      year = as.integer(ts$year[cv_keep]), source_reference = reference,
      notes = cv_note
    )
  }
}
add_series("biomass", "total_biomass", ts$total_biomass_2023_t, "t",
  "2023 BSAI SAFE, Table 23, p. 47",
  "Estimated total biomass, age 3+, from the 2023 Model 21. The 2024 value is the official projection shown in Table 23.",
  "total_biomass_cv", ts$total_biomass_2023_cv,
  "Source-reported CV for the 2023 Model 21 total biomass estimate; no CV is listed for the 2024 projection.")
add_series("biomass", "SSB", ts$spawning_biomass_2023_t, "t",
  "2023 BSAI SAFE, Table 23, p. 47",
  "Estimated spawning biomass, age 3+, from the 2023 Model 21. The 2024 value is the official projection shown in Table 23.",
  "SSB_cv", ts$spawning_biomass_2023_cv,
  "Source-reported CV for the 2023 Model 21 spawning biomass estimate; no CV is listed for the 2024 projection.")
add_series("recruitment", "recruitment", ts$recruitment_2023_thousand_fish,
  "thousand fish", "2023 BSAI SAFE, Table 23, p. 47",
  "Recruitment at age 3 from the 2023 Model 21. The report does not tabulate estimates after 2020.",
  "recruitment_cv", ts$recruitment_2023_cv,
  "Source-reported CV for the age-3 recruitment estimate.")
outputs[[length(outputs) + 1L]] <- output_row(
  "population", "numbers_at_age", as.vector(t(n_matrix)), "million fish",
  year = rep(n_years, each = ncol(n_matrix)),
  age = rep(3:40, times = nrow(n_matrix)),
  age_group = rep(ifelse(3:40 == 40, "40+", ""), times = nrow(n_matrix)),
  source_reference = "2023 BSAI SAFE, Table 24, pp. 48-49",
  notes = "Estimated numbers-at-age in millions. Age 40 is the source's 40+ group; printed values retained."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "population", "total_numbers", rowSums(n_matrix), "million fish",
  year = n_years, source_type = "derived_source_output",
  source_reference = "Derived by summing 2023 BSAI SAFE, Table 24, pp. 48-49",
  notes = "Derived annual total abundance for ages 3+ by summing the reported N-at-age cells, including the age-40 plus group. No uncertainty is available or calculated."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "biology", "weight_at_age", biology$ai_survey_weight_g, "g/fish",
  age = as.integer(biology$age),
  survey = survey_name, scenario = "reported average predictions",
  source_reference = "2023 BSAI SAFE, Table 17, p. 40",
  notes = "Model-predicted average Aleutian Islands survey weight-at-age, in grams. This is a reported fitted biological surface, not the original weight-at-age input schedule; Table 17's caption says kilograms, while its column heading and plausible values indicate grams."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "biology", "weight_at_age", biology$fishery_weight_g, "g/fish",
  age = as.integer(biology$age), fleet = "BSAI fishery",
  scenario = "reported average predictions",
  source_reference = "2023 BSAI SAFE, Table 17, p. 40",
  notes = "Model-predicted average fishery weight-at-age, in grams. This is a reported fitted biological surface, not the original weight-at-age input schedule; Table 17's caption says kilograms, while its column heading and plausible values indicate grams."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "biology", "maturity_at_age", biology$maturity, "proportion",
  age = as.integer(biology$age), scenario = "reported average predictions",
  source_reference = "2023 BSAI SAFE, Table 17, p. 40",
  notes = "Reported model maturity-at-age estimate. The values are an estimated biological surface, not a recovered original maturity input schedule."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "mortality", "natural_mortality_average_parameter",
  parameters$estimate[parameters$parameter == "M"], "per year",
  se = parameters$standard_deviation[parameters$parameter == "M"],
  source_reference = "2023 BSAI SAFE, Table 22, p. 46",
  notes = "Estimated constant M and its source-reported standard deviation; not an age-specific M-at-age series."
)
outputs[[length(outputs) + 1L]] <- output_row(
  "catchability", "q", parameters$estimate[parameters$parameter == "q_srv"],
  "dimensionless", se = parameters$standard_deviation[parameters$parameter == "q_srv"],
  survey = survey_name, source_reference = "2023 BSAI SAFE, Table 22, p. 46",
  notes = "Estimated Aleutian Islands survey catchability and source-reported standard deviation."
)
parameter_types <- c(
  sel_aslope_fish = "per year", sel_a50_fish = "year",
  sel_aslope_srv = "per year", sel_a50_srv = "year",
  log_avg_fmort = "log scale", mat_beta1 = "logit",
  mat_beta2 = "logit per year"
)
for (parameter in names(parameter_types)) {
  row <- parameters[parameters$parameter == parameter, , drop = FALSE]
  outputs[[length(outputs) + 1L]] <- output_row(
    "parameter", parameter, row$estimate, parameter_types[[parameter]],
    se = row$standard_deviation,
    source_reference = "2023 BSAI SAFE, Table 22, p. 46",
    notes = "Selected scalar fitted parameter and source-reported standard deviation. log_avg_fmort is retained on the log scale and is not exponentiated."
  )
}
outputs_new <- do.call(rbind, outputs)

input_key_columns <- c("assessment_id", "type", "measure", "basis", "fleet",
  "survey", "sex", "region", "season", "year", "year_basis", "age",
  "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition", "weight_bin")
output_key_columns <- c("assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "scenario")
if (nrow(assumptions_new) != 13L ||
    sum(inputs_new$type == "catch" & inputs_new$measure == "catch_biomass") != 47L ||
    sum(inputs_new$measure == "proportion_at_age" & inputs_new$type == "catch") != 646L ||
    sum(inputs_new$measure == "proportion_at_age" & inputs_new$type == "index") != 494L ||
    sum(inputs_new$measure == "total_biomass" & inputs_new$type == "index") != 13L ||
    sum(outputs_new$measure == "numbers_at_age") != 1786L ||
    sum(outputs_new$measure == "total_numbers") != 47L ||
    anyDuplicated(inputs_new[input_key_columns]) ||
    anyDuplicated(outputs_new[output_key_columns])) {
  stop("Northern-rockfish import has unexpected dimensions or duplicate rows.",
    call. = FALSE)
}

row_signature <- function(data, columns = names(data)) {
  values <- lapply(data[columns], function(x) {
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
  prefix <- paste0('"', id, '",')
  found <- found[startsWith(found, prefix)]
  if (!length(found)) return(data.frame())
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, found), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assert_rows_match_or_absent <- function(existing, expected, label) {
  if (!nrow(existing)) return(invisible(FALSE))
  if (nrow(existing) != nrow(expected) ||
      !setequal(row_signature(existing), row_signature(expected))) {
    stop("Existing NOAA BSAI Northern Rockfish ", label,
      " rows differ from the reviewed source records.", call. = FALSE)
  }
  invisible(TRUE)
}
append_csv <- function(x, path) {
  write.table(x, path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "", qmethod = "double", eol = "\n")
}

stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
assumptions_path <- file.path(root, "database", "assumptions.csv")
inputs_path <- file.path(root, "database", "inputs.csv")
outputs_path <- file.path(root, "database", "outputs.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(assessments_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions_existing <- read_matching_rows(assumptions_path, assessment_id)
inputs_existing <- read_matching_rows(inputs_path, assessment_id)
outputs_existing <- read_matching_rows(outputs_path, assessment_id)
stock_existing <- stocks[!is.na(stocks$stock_id) & stocks$stock_id == stock_id,
  , drop = FALSE]
assessment_existing <- assessments[
  !is.na(assessments$assessment_id) & assessments$assessment_id == assessment_id,
  , drop = FALSE
]
if (nrow(stock_existing) > 1L || nrow(assessment_existing) > 1L) {
  stop("Northern-rockfish stock or assessment identifiers are duplicated.", call. = FALSE)
}
if (nrow(stock_existing) &&
    !setequal(row_signature(stock_existing), row_signature(stock_row))) {
  stop("Existing NOAA BSAI Northern Rockfish stock row differs from reviewed identity.",
    call. = FALSE)
}
if (nrow(assessment_existing) &&
    !setequal(row_signature(assessment_existing), row_signature(assessment_row))) {
  stop("Existing NOAA BSAI Northern Rockfish assessment differs from reviewed run.",
    call. = FALSE)
}
assert_rows_match_or_absent(assumptions_existing, assumptions_new, "assumption")
assert_rows_match_or_absent(inputs_existing, inputs_new, "input")
assert_rows_match_or_absent(outputs_existing, outputs_new, "output")

cat("Verified NOAA BSAI Northern Rockfish 2023 Model 21 source import.\n")
cat("Inputs:", nrow(inputs_new), "rows with catch, fishery and survey age compositions, survey biomass and CVs.\n")
cat("Outputs:", nrow(outputs_new), "rows including age-specific N, derived total abundance, biomass, recruitment, biology and selected parameters.\n")
cat("Proportions are not renormalized; age 40 remains the reported 40+ group.\n")
cat("Unresolved: original fitted weight/maturity input schedules, age-specific survey abundance, annual F-at-age, exact survey timing and some likelihood details.\n")

if (write_mode) {
  if (!nrow(stock_existing)) append_csv(stock_row, stocks_path)
  if (!nrow(assessment_existing)) append_csv(assessment_row, assessments_path)
  if (!nrow(assumptions_existing)) append_csv(assumptions_new, assumptions_path)
  if (!nrow(inputs_existing)) append_csv(inputs_new, inputs_path)
  if (!nrow(outputs_existing)) append_csv(outputs_new, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidate_rows <- which(!is.na(candidates$candidate_id) &
    candidates$candidate_id == candidate_id &
    candidates$official_stock_id == "10416")
  if (length(candidate_rows) != 1L ||
      candidates$eligibility[candidate_rows] != "eligible" ||
      candidates$screening_status[candidate_rows] != "screened") {
    stop("Expected one screened eligible NOAA:10416 candidate.", call. = FALSE)
  }
  ci <- candidate_rows
  existing_match <- candidates$matched_stock_id[ci]
  if (!is.na(existing_match) && nzchar(existing_match) &&
      existing_match != stock_id) {
    stop("NOAA:10416 is already matched to a different stock.", call. = FALSE)
  }
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- source_url
  candidates$catch_age_evidence[ci] <- paste(
    "The 2023 SAFE reports total fishery catch for 1977-2023 and age compositions for 17 sampled years.",
    "The composition table is an observation likelihood input, not direct catch numbers-at-age."
  )
  candidates$survey_age_evidence[ci] <- paste(
    "The model uses Aleutian Islands survey biomass and CVs for 13 years, paired with age compositions for those years.",
    "Age-specific survey abundance is not reported and cannot be derived without annual survey weights and expansion conventions."
  )
  candidates$weights_evidence[ci] <- paste(
    "Table 17 reports average model-predicted fishery and survey weight-at-age in grams.",
    "These fitted surfaces do not provide the original biological input schedules."
  )
  candidates$maturity_evidence[ci] <- paste(
    "Table 17 reports estimated maturity-at-age and Table 22 reports maturity parameters.",
    "The original input maturity schedule is not recovered."
  )
  candidates$mortality_evidence[ci] <- paste(
    "The model estimates a constant M parameter; Table 22 reports 0.0523 per year (SD 0.0044).",
    "No age-specific M-at-age surface is tabulated."
  )
  candidates$timing_evidence[ci] <- "The report identifies the annual Aleutian Islands bottom-trawl survey but does not report a fractional within-year observation timing."
  candidates$output_evidence[ci] <- paste(
    "Tables 23-24 provide total and spawning biomass, age-3 recruitment, and N-at-age with biomass/recruitment CVs.",
    "Total abundance was derived by summing N-at-age.",
    "The report gives scalar F parameters, but no numeric annual F-at-age surface was recovered."
  )
  candidates$review_date[ci] <- "2026-11-11"
  candidates$decision_reason[ci] <- paste(
    "Partial import completed from the latest full official fit.",
    "Source tables preserve catch, age-composition and survey biomass likelihood inputs plus official outputs; original biological input arrays, exact timing and annual F-at-age remain unavailable."
  )
  candidates$notes[ci] <- paste(
    "The 2023 full SAFE remains the latest full fit; the 2026 chapter is a harvest-projection update after the planned 2025 full assessment was cancelled.",
    "The 2023 SAFE's printed age-composition values are rounded; they are retained without renormalization."
  )
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)

  inventory_path <- file.path(root, "discovery", "inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  inventory_ids <- strsplit(as.character(inventory$candidate_ids), " | ", fixed = TRUE)
  ui <- which(vapply(inventory_ids, function(ids) candidate_id %in% ids, logical(1L)))
  if (length(ui) != 1L || inventory$unit_key[ui] != "candidate:noaa_stocksmart_10416" ||
      inventory$candidate_unit_id[ui] != "noaa_stocksmart_10416") {
    stop("Expected one unambiguous NOAA:10416 inventory unit.", call. = FALSE)
  }
  old_unit_key <- inventory$unit_key[ui]
  inventory$matched_stock_id[ui] <- stock_id
  inventory$match_status[ui] <- "matched"
  inventory$import_status[ui] <- "partial"
  replace_csv_register_row(inventory_path, ui, inventory[ui, , drop = FALSE],
    "unit_key", old_unit_key)

  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = TRUE)
  cat("Import written and database validation passed.\n")
}









