root <- "."
source(file.path(root, "scripts", "database", "pacific_tables.R"))
cache <- file.path(root, "source_cache", "noaa_goa_pop_20261029")
model <- file.path(cache, "model_files")
processed <- file.path(model, "processed")
assessment_id <- "noaa_goa_pop_2023"
stock_id <- "afsc_goa_pacific_ocean_perch"
dry_run <- identical(Sys.getenv("SAIO_IMPORT_DRY_RUN"), "1")

manifest <- utils::read.csv(
  file.path(cache, "sources.csv"), stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA")
)
sha256_file <- function(path) {
  result <- system2("certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\")), "SHA256"),
    stdout = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE)))
  if (length(hashes) != 1L) stop("Could not verify source checksum.", call. = FALSE)
  hashes
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$local_file[i])
  if (!file.exists(path) ||
      file.info(path)$size != as.numeric(manifest$bytes[i]) ||
      !identical(tolower(manifest$sha256[i]), sha256_file(path))) {
    stop("Cached source is missing or differs from its manifest: ",
      manifest$local_file[i], call. = FALSE)
  }
}
source_url <- function(local_file) {
  i <- match(local_file, manifest$local_file)
  if (is.na(i)) stop("Source is missing from manifest: ", local_file, call. = FALSE)
  manifest$url[i]
}
repository_revision <- "e87bbfc60ab8bfc87d05e02ed1b4b39b76059d7e"
repository <- paste0(
  "https://github.com/noaa-afsc/goa_pop/tree/", repository_revision,
  "/2023/mgmt/2020.1-2023"
)
dat_path <- file.path(model, "goa_pop_2023.dat")
dat_lines <- readLines(dat_path, warn = FALSE)
ctl_lines <- readLines(file.path(model, "goa_pop_2023.ctl"), warn = FALSE)
mat_lines <- readLines(file.path(model, "MAT.DAT"), warn = FALSE)
par_lines <- readLines(file.path(model, "model_20_1.par"), warn = FALSE)
rep_lines <- readLines(file.path(model, "model_20_1.rep"), warn = FALSE)

read_values_after <- function(pattern, n, lines = dat_lines) {
  at <- grep(pattern, lines)
  if (length(at) != 1L) stop("Source label is not unique: ", pattern, call. = FALSE)
  values <- scan(
    text = paste(lines[seq.int(at + 1L, length(lines))], collapse = "\n"),
    nmax = n, quiet = TRUE, comment.char = "#")
  if (length(values) != n) stop("Unexpected value count after: ", pattern, call. = FALSE)
  values
}
read_section <- function(start, end, lines = dat_lines) {
  first <- grep(start, lines)
  last <- grep(end, lines)
  if (length(first) != 1L || length(last) != 1L || first >= last) {
    stop("Could not isolate source section: ", start, call. = FALSE)
  }
  lines[seq.int(first, last - 1L)]
}
get_scalar <- function(pattern) as.integer(read_values_after(pattern, 1L))

start_year <- get_scalar("^# Model start year")
terminal_year <- get_scalar("^# Model end year")
recruitment_age <- get_scalar("^# Age at recruitment")
n_data_ages <- get_scalar("^# Number of ages in data")
n_model_ages <- get_scalar("^# Number of ages in model")
n_length_bins <- get_scalar("^# Number of length bins")
years <- seq.int(start_year, terminal_year)
ages <- seq.int(recruitment_age, length.out = n_model_ages)
observed_ages <- seq.int(recruitment_age, length.out = n_data_ages)
length_bins <- read_values_after("^# Length bin labels", n_length_bins)
spawn_month <- read_values_after("^# Spawn month", 1L)
model_weight <- read_values_after("^# Weight-at-age", n_model_ages)

catch_year_line <- grep("^#! 1961 1962 1963", dat_lines)
if (length(catch_year_line) != 1L) stop("Could not locate catch years in model data.")
catch <- scan(text = dat_lines[catch_year_line + 1L], nmax = length(years), quiet = TRUE)

n_fish_age <- get_scalar("^#! Number of years: nyrs_fish_age")
fish_age_years <- read_values_after("Fishery age comp years", n_fish_age)
fish_age_n <- read_values_after("nsamples_fish_age", n_fish_age)
fish_age_hauls <- read_values_after("nhauls_fish_age", n_fish_age)
fish_age_lines <- read_section("^# Fishery Age Composition", "^# Trawl Survey Age Composition")
fish_age_error <- read_values_after("^#- Index for age-age error matrix", n_fish_age, fish_age_lines)
fish_age_comp <- matrix(
  read_values_after("Observed fishery age compositions", n_fish_age * n_data_ages),
  nrow = n_fish_age, byrow = TRUE)

n_survey <- get_scalar("^#! Number of trawl surveys")
survey_years <- read_values_after("Trawl survey years", n_survey)
survey_biomass <- read_values_after("Observed trawl survey biomass", n_survey)
survey_se <- read_values_after("SE of observed trawl survey biomass", n_survey)

n_survey_age <- get_scalar("^#! Number of years: nyrs_srv1_age")
survey_age_years <- read_values_after("Trawl Survey age comp years", n_survey_age)
survey_age_n <- read_values_after("nsamples_srv1_age", n_survey_age)
survey_age_hauls <- read_values_after("nhauls_srv1_age", n_survey_age)
survey_age_lines <- read_section("^# Trawl Survey Age Composition", "^# Fishery Size Composition")
survey_age_error <- read_values_after("^#- Index for age-age error matrix", n_survey_age, survey_age_lines)
survey_age_comp <- matrix(
  read_values_after("Observed trawl survey age compositions", n_survey_age * n_data_ages),
  nrow = n_survey_age, byrow = TRUE)

fish_size_lines <- read_section("^# Fishery Size Composition", "^# Trawl Survey Size Composition")
n_fish_size <- as.integer(read_values_after("^#! Number of years:", 1L, fish_size_lines))
fish_size_years <- read_values_after("Fishery size comp years", n_fish_size, fish_size_lines)
fish_size_n <- read_values_after("Number of samples", n_fish_size, fish_size_lines)
fish_size_hauls <- read_values_after("Number of hauls", n_fish_size, fish_size_lines)
fish_size_key <- read_values_after("Index for size-age error matrix", n_fish_size, fish_size_lines)
fish_size_comp <- matrix(
  read_values_after("Observed fishery size compositions", n_fish_size * n_length_bins, fish_size_lines),
  nrow = n_fish_size, byrow = TRUE)

survey_size_lines <- read_section("^# Trawl Survey Size Composition", "^# Longline Survey Size Composition")
n_survey_size <- as.integer(read_values_after("^#! Number of years:", 1L, survey_size_lines))
survey_size_years <- read_values_after("Survey Years", n_survey_size, survey_size_lines)
survey_size_n <- read_values_after("Number of samples", n_survey_size, survey_size_lines)
survey_size_hauls <- read_values_after("Number of hauls", n_survey_size, survey_size_lines)
survey_size_key <- read_values_after("Index for size-age error matrix", n_survey_size, survey_size_lines)
survey_size_comp <- matrix(
  read_values_after("Observed survey size compositions", n_survey_size * n_length_bins, survey_size_lines),
  nrow = n_survey_size, byrow = TRUE)

n_age_age_matrices <- get_scalar("^# Number of age-age transition matrices")
n_size_age_matrices <- get_scalar("^# Number of size-age transition matrices")
age_error_values <- read_values_after("Ageing error matrix",
  n_age_age_matrices * n_data_ages * n_model_ages)
size_age_values <- read_values_after("Size-age transition matrix",
  n_size_age_matrices * n_model_ages * n_length_bins)
age_error <- array(NA_real_, c(n_age_age_matrices, n_model_ages, n_data_ages))
for (i in seq_len(n_age_age_matrices)) {
  from <- (i - 1L) * n_data_ages * n_model_ages + 1L
  to <- i * n_data_ages * n_model_ages
  age_error[i, , ] <- matrix(age_error_values[from:to],
    nrow = n_model_ages, ncol = n_data_ages, byrow = TRUE)
}
size_age <- array(NA_real_, c(n_size_age_matrices, n_model_ages, n_length_bins))
for (i in seq_len(n_size_age_matrices)) {
  from <- (i - 1L) * n_model_ages * n_length_bins + 1L
  to <- i * n_model_ages * n_length_bins
  size_age[i, , ] <- matrix(size_age_values[from:to],
    nrow = n_model_ages, ncol = n_length_bins, byrow = TRUE)
}

mat_n <- as.integer(read_values_after("^# Number of ages", 1L, mat_lines))
mat_ages <- read_values_after("Ages observed", mat_n, mat_lines)
l_total <- read_values_after("L_tot_na", mat_n, mat_lines)
l_mature <- read_values_after("L_mat_na", mat_n, mat_lines)
c_total <- read_values_after("C_tot_na", mat_n, mat_lines)
c_mature <- read_values_after("C_mat_na", mat_n, mat_lines)

parameter_value <- function(name) {
  at <- grep(paste0("^# ", name, ":"), par_lines)
  if (length(at) != 1L) stop("Parameter is not unique in .par: ", name, call. = FALSE)
  scan(text = par_lines[at + 1L], nmax = 1L, quiet = TRUE)
}
m_estimate <- exp(parameter_value("logm"))
q_estimate <- exp(parameter_value("log_q_srv1"))
par_header <- par_lines[1L]
objective <- as.numeric(sub(".*Objective function value = ([^ ]+).*", "\\1", par_header))
max_gradient <- as.numeric(sub(".*Maximum gradient component = ([^ ]+).*", "\\1", par_header))

bio <- utils::read.csv(file.path(processed, "bio_rec_f.csv"), check.names = FALSE)
naa_raw <- utils::read.csv(file.path(processed, "naa.csv"), check.names = FALSE)
naa <- as.matrix(naa_raw[, -1L, drop = FALSE])
storage.mode(naa) <- "numeric"
colnames(naa) <- as.character(ages)
rownames(naa) <- naa_raw$Year
survey_fit <- utils::read.csv(file.path(processed, "survey.csv"), check.names = FALSE)
catch_fit <- utils::read.csv(file.path(processed, "catch.csv"), check.names = FALSE)
selex <- utils::read.csv(file.path(processed, "selex.csv"), check.names = FALSE)
waa_mat <- utils::read.csv(file.path(processed, "waa_mat.csv"), check.names = FALSE)
exec <- utils::read.csv(file.path(processed, "exec_summ.csv"), check.names = FALSE)
key <- utils::read.csv(file.path(processed, "key_param.csv"), check.names = FALSE)
model_waa <- utils::read.csv(file.path(model, "2023", "data", "output", "waa.csv"))
fishery_weight <- utils::read.csv(file.path(model, "2023", "data", "output", "fisherywaa.csv"))[[2L]]
survey_weight <- utils::read.csv(file.path(model, "2023", "data", "output", "survey_waa.csv"))[[2L]]

checks <- c(
  years = identical(as.integer(rownames(naa)), years),
  bio_years = identical(as.integer(bio$year), years),
  recruitment = isTRUE(all.equal(as.numeric(naa[, 1L]), bio$recruits, tolerance = 1e-8)),
  survey_years = identical(as.integer(survey_fit$year), as.integer(survey_years)),
  survey_biomass = isTRUE(all.equal(survey_fit$biomass, survey_biomass, tolerance = 1e-5)),
  survey_se = isTRUE(all.equal(survey_fit$se, survey_se, tolerance = 1e-8)),
  catch = isTRUE(all.equal(catch_fit$obs, catch, tolerance = 1e-5)),
  weight = isTRUE(all.equal(model_weight, model_waa[[2L]], tolerance = 1e-8)),
  M = isTRUE(all.equal(m_estimate, key$nat_mort, tolerance = 1e-6)),
  q = isTRUE(all.equal(q_estimate, key$q_trawl, tolerance = 5e-6)),
  age_error = isTRUE(all.equal(age_error[1L, , ], matrix(age_error_values, nrow = n_model_ages, byrow = TRUE), tolerance = 1e-12))
)
if (!all(checks)) stop("Processed tables do not reconcile with the pinned model input and fit.", call. = FALSE)
if (any(abs(rowSums(fish_age_comp) - 1) > 1e-8) ||
    any(abs(rowSums(survey_age_comp) - 1) > 1e-8) ||
    any(abs(rowSums(fish_size_comp) - 1) > 1e-8) ||
    any(abs(rowSums(survey_size_comp) - 1) > 1e-8) ||
    any(abs(rowSums(age_error[1L, , ]) - 1) > 5e-4) ||
    any(abs(rowSums(size_age[1L, , ]) - 1) > 5e-4) ||
    any(abs(rowSums(size_age[2L, , ]) - 1) > 5e-4)) {
  stop("A composition or transition row failed normalization checks.", call. = FALSE)
}
ages_at_length <- utils::read.csv(file.path(processed, "ages_yrs.csv"))
if (!identical(sort(unique(as.integer(ages_at_length$ages))), 2:29) ||
    !identical(as.integer(waa_mat$age), ages)) {
  stop("Model output age grid differs from the source model.", call. = FALSE)
}

dat_ref <- source_url("model_files/goa_pop_2023.dat")
ctl_ref <- source_url("model_files/goa_pop_2023.ctl")
mat_ref <- source_url("model_files/MAT.DAT")
rep_ref <- source_url("model_files/model_20_1.rep")
par_ref <- source_url("model_files/model_20_1.par")
bio_ref <- source_url("model_files/processed/bio_rec_f.csv")
naa_ref <- source_url("model_files/processed/naa.csv")
selex_ref <- source_url("model_files/processed/selex.csv")
maturity_ref <- source_url("model_files/processed/waa_mat.csv")
survey_ref <- source_url("model_files/processed/survey.csv")
catch_ref <- source_url("model_files/processed/catch.csv")
fish_weight_ref <- source_url("model_files/2023/data/output/fisherywaa.csv")
survey_weight_ref <- source_url("model_files/2023/data/output/survey_waa.csv")

input <- function(type, measure, basis, value, unit, year = NA_integer_,
                  age = NA_integer_, fleet = "", survey = "", sex = "combined",
                  season = "", sample_size = NA_real_, age_error = NA_integer_,
                  observation_id = "", length_bin = NA_real_, notes = "",
                  source_type = "native_model", source_reference = dat_ref) {
  n <- length(value)
  pacific_database_row("inputs", n = n, assessment_id = assessment_id,
    type = type, measure = measure, basis = basis, fleet = fleet, survey = survey,
    sex = sex, region = "GOA", season = season, year = year,
    year_basis = ifelse(is.na(rep_len(year, n)), "", "calendar_year"),
    age = age, value = value, unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes,
    sample_size = sample_size, age_error = age_error,
    observation_id = observation_id, length_bin = length_bin)
}
output <- function(type, measure, value, unit, year = NA_integer_,
                   age = NA_integer_, age_group = "", fleet = "", survey = "",
                   sex = "combined", notes = "", source_type = "native_model",
                   source_reference = rep_ref) {
  pacific_database_row("outputs", n = length(value), assessment_id = assessment_id,
    type = type, measure = measure, fleet = fleet, survey = survey,
    sex = sex, region = "GOA", year = year, age = age,
    age_group = age_group, value = value, unit = unit,
    source_type = source_type, source_reference = source_reference,
    notes = notes)
}
matrix_long <- function(x, y, a) {
  data.frame(year = rep(y, times = ncol(x)), age = rep(a, each = nrow(x)),
             value = as.vector(x))
}
composition_rows <- function(x, obs_years, bins, type, measure, basis, unit,
                             n_samples, n_hauls, key, fleet = "", survey = "",
                             age_based = TRUE, source_reference = dat_ref,
                             likelihood_note = "") {
  values <- as.vector(t(x))
  n <- ncol(x)
  observation_id <- paste0(if (nzchar(fleet)) "fishery" else "survey", "_",
    if (age_based) "age_" else "length_", rep(obs_years, each = n))
  notes <- paste0("Native n_s=", rep(n_samples, each = n),
    "; hauls n_h=", rep(n_hauls, each = n),
    "; transition key=", rep(key, each = n), ". ", likelihood_note)
  input(type, measure, basis, values, unit,
    year = rep(obs_years, each = n),
    age = if (age_based) rep(bins, times = nrow(x)) else NA_integer_,
    fleet = fleet, survey = survey, season = "annual",
    sample_size = rep(n_samples, each = n),
    age_error = if (age_based) rep(key, each = n) else NA_integer_,
    observation_id = observation_id,
    length_bin = if (age_based) NA_real_ else rep(bins, times = nrow(x)),
    notes = notes, source_reference = source_reference)
}

input_rows <- list(
  input("catch", "total_biomass", "biomass", catch, "t", years,
    fleet = "Combined fishery", season = "annual",
    notes = "Observed catch biomass; 2023 is an in-year estimate."),
  input("index", "total_biomass", "biomass", survey_biomass, "t", survey_years,
    survey = "GOA bottom trawl survey", season = "annual",
    notes = "Observed design-based biomass; 2001 includes the source model's Eastern GOA ABL substitution."),
  input("index", "index_sd", "index_scale", survey_se, "t", survey_years,
    survey = "GOA bottom trawl survey", season = "annual",
    notes = "Natural-scale survey-index standard error; the fitted lognormal likelihood uses SE/observed biomass."),
  composition_rows(fish_age_comp, fish_age_years, observed_ages, "catch",
    "proportion_at_age", "proportion_numbers", "proportion",
    fish_age_n, fish_age_hauls, fish_age_error, fleet = "Combined fishery",
    likelihood_note = "Native proportions; the model applies its age-error matrix and uses sqrt(n_s) as the multinomial weight."),
  composition_rows(survey_age_comp, survey_age_years, observed_ages, "index",
    "proportion_at_age", "proportion_numbers", "proportion",
    survey_age_n, survey_age_hauls, survey_age_error,
    survey = "GOA bottom trawl survey",
    likelihood_note = "Age 25 is the terminal observed group (25+); the model applies its age-error matrix and uses sqrt(n_s)."),
  composition_rows(fish_size_comp, fish_size_years, length_bins, "catch",
    "proportion_at_length", "native_frequency", "proportion",
    fish_size_n, fish_size_hauls, fish_size_key, fleet = "Combined fishery",
    age_based = FALSE,
    likelihood_note = "Source length labels in cm; the model applies the keyed size-age matrix and scales haul weights to a maximum of 100."),
  composition_rows(survey_size_comp, survey_size_years, length_bins, "index",
    "proportion_at_length", "native_frequency", "proportion",
    survey_size_n, survey_size_hauls, survey_size_key,
    survey = "GOA bottom trawl survey", age_based = FALSE,
    likelihood_note = "Supplied but unused in the fitted likelihood (control weight 0); retained as source data.")
)
input_rows[[length(input_rows) + 1L]] <- input(
  "weight", "weight_at_age", "g_per_fish", model_weight, "g/fish", age = ages,
  notes = "Single model weight vector entered in the .dat file and used for population biomass and SSB.")
input_rows[[length(input_rows) + 1L]] <- input(
  "catch_weight", "weight_at_age", "g_per_fish", fishery_weight, "g/fish",
  age = ages, fleet = "Combined fishery",
  source_type = "official_machine_readable", source_reference = fish_weight_ref,
  notes = "Supporting official fishery weight vector; not the single weight vector entered into the fitted model.")
input_rows[[length(input_rows) + 1L]] <- input(
  "weight", "weight_at_age", "g_per_fish", survey_weight, "g/fish", age = ages,
  survey = "GOA bottom trawl survey", source_type = "official_machine_readable",
  source_reference = survey_weight_ref,
  notes = "Supporting official survey weight vector; the fitted model uses its separate single weight vector.")

maturity_rows <- function(dataset, total, mature) {
  observed <- !is.na(total) & total >= 0
  if (any(observed & (is.na(mature) | mature < 0)) ||
      any(mature[observed] > total[observed])) {
    stop("Maturity sample totals and mature counts are inconsistent.", call. = FALSE)
  }
  list(
    input("biology", "maturity_sample_size", "numbers", total[observed],
      "fish", age = mat_ages[observed], sex = "female",
      observation_id = dataset, source_reference = mat_ref,
      notes = "Female maturity sample size used by the official binomial likelihood."),
    input("biology", "mature_sample_count", "numbers", mature[observed],
      "fish", age = mat_ages[observed], sex = "female",
      observation_id = dataset, source_reference = mat_ref,
      notes = "Female mature-fish count used by the official binomial likelihood.")
  )
}
input_rows <- c(input_rows, maturity_rows("Lunsford", l_total, l_mature))
input_rows <- c(input_rows, maturity_rows("Conrath", c_total, c_mature))
inputs <- do.call(rbind, input_rows)

assume <- function(component, setting, value, source_reference = ctl_ref, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    region = "GOA", source_reference = source_reference, notes = notes)
}
assumptions <- list()
control_values <- strsplit(ctl_lines[grepl("#", ctl_lines)], "\\s+#\\s*")
control_values <- control_values[lengths(control_values) == 2L]
for (entry in control_values) {
  assumptions[[length(assumptions) + 1L]] <- assume(
    "control", entry[2L], entry[1L], ctl_ref,
    "Exact scalar from the pinned 2023 Model 20.1 control file.")
}
assumptions <- c(assumptions, list(
  assume("assessment", "model_run", "2023 operational update, Model 20.1",
    source_url("model_files/2023/README.md"),
    "Data through 2023; configuration matches the 2021 full assessment. 2024-2025 aggregate estimates are management projections."),
  assume("population", "dimensions", "1961-2023; ages 2-29+; GOA; combined-sex numbers",
    dat_ref, "The terminal modeled age is an accumulated plus group."),
  assume("population", "recruitment_age", "2", dat_ref,
    "Recruitment is age-2 abundance."),
  assume("N", "initialization", "Pre-assessment ages use mean recruitment and constant M; annual age-2 recruitment deviations are estimated.",
    source_url("model_files/Model_20_1.tpl")),
  assume("F", "process", "Annual fully-selected F is exp(log_avg_F + log_F_devs); age-specific F applies four time-block selectivity curves.",
    source_url("model_files/Model_20_1.tpl"),
    "Blocks: 1961-1976, 1977-1995, 1996-2006 and 2007-2023."),
  assume("M", "process", paste0("One estimated constant over ages and years; estimate=", format(m_estimate, digits = 8)),
    source_url("model_files/model_20_1.par"),
    "Lognormal prior is in the control file; M is estimated, not fixed."),
  assume("q", "process", paste0("One estimated bottom-trawl survey q; estimate=", format(q_estimate, digits = 8)),
    source_url("model_files/model_20_1.par"),
    "Alternative survey q and CPUE are inactive."),
  assume("index", "observation_model", "Lognormal biomass index uses the supplied natural-scale SE as a CV; no within-year survey timing fraction.",
    source_url("model_files/Model_20_1.tpl")),
  assume("age_composition", "observation_model", "Multinomial likelihood applies age-error matrices; fishery and survey composition weights use sqrt(n_s).",
    dat_ref, "Raw sample and haul counts are retained."),
  assume("length_composition", "observation_model", "Fishery size likelihood rescales haul counts to maximum 100; survey size rows are supplied but control weight is zero.",
    dat_ref),
  assume("biology", "maturity_model", "Estimated logistic maturity ogive fitted to female Lunsford and Conrath binomial samples; biomass uses a 0.5 sex fraction.",
    paste(source_url("model_files/Model_20_1.tpl"), source_url("model_files/MAT.DAT"), sep = "; ")),
  assume("biology", "spawning_time", paste0("Spawn month 5; fraction=(5-1)/12=", format((spawn_month - 1) / 12, digits = 8)),
    dat_ref, "This is spawning timing, not survey timing."),
  assume("biology", "SSB_definition", "Historical years 1961-2022 use N*weight*maturity*0.5 without survival to spawning; terminal 2023 applies exp(-Z/3).",
    source_url("model_files/Model_20_1.tpl"),
    "This reproduces the source model's historical/terminal definition difference."),
  assume("observation", "inactive_placeholders", "No CPUE series; one dummy 1999 longline biomass record and a dummy longline size row have zero likelihood weight.",
    paste(dat_ref, ctl_ref, sep = "; "), "Not imported as observed stock data."),
  assume("fit", "objective", format(objective, digits = 15),
    source_url("model_files/model_20_1.par"), "Final .par objective function value."),
  assume("fit", "maximum_gradient", format(max_gradient, digits = 15),
    source_url("model_files/model_20_1.par"), "Final .par maximum gradient component."),
  assume("uncertainty", "available_outputs", "Annual age-specific N and F uncertainty was not recovered; imported output rows contain point estimates only.",
    rep_ref, "No standard errors or intervals are invented.")
))

for (matrix_id in seq_len(n_age_age_matrices)) {
  for (i in seq_along(ages)) {
    assumptions[[length(assumptions) + 1L]] <- assume(
      "age_error", paste0("matrix_", matrix_id, "_true_age_", ages[i]),
      paste(format(age_error[matrix_id, i, ], digits = 17,
        scientific = FALSE, trim = TRUE), collapse = " "),
      dat_ref, "Row is true model age; columns are observed-reader ages 2-25.")
  }
}
for (matrix_id in seq_len(n_size_age_matrices)) {
  for (i in seq_along(ages)) {
    assumptions[[length(assumptions) + 1L]] <- assume(
      "size_age", paste0("matrix_", matrix_id, "_age_", ages[i]),
      paste(format(size_age[matrix_id, i, ], digits = 17,
        scientific = FALSE, trim = TRUE), collapse = " "),
      dat_ref, "Row is true age; columns are source length-bin labels 16-45 cm.")
  }
}
assumptions <- do.call(rbind, assumptions)

output_rows <- list()
z <- matrix_long(naa, years, ages)
output_rows[[length(output_rows) + 1L]] <- output(
  "population", "numbers_at_age", z$value, "million fish",
  year = z$year, age = z$age, age_group = ifelse(z$age == 29, "29+", ""),
  notes = "Official Model 20.1 point estimates; age 29 is the 29+ group.",
  source_type = "native_model", source_reference = naa_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "population", "total_abundance", rowSums(naa), "million fish", year = years,
  notes = "Derived by summing reported N-at-age, including 29+; joint uncertainty is unavailable.",
  source_type = "derived_source_output", source_reference = naa_ref)

selectivity <- as.matrix(selex[, c("fish1", "fish2", "fish3", "fish4")])
storage.mode(selectivity) <- "numeric"
f_at_age <- matrix(NA_real_, nrow = length(years), ncol = length(ages))
for (i in seq_along(years)) {
  block <- if (years[i] <= 1976) 1L else if (years[i] <= 1995) 2L else if (years[i] <= 2006) 3L else 4L
  f_at_age[i, ] <- bio$F[i] * selectivity[, block]
}
z <- matrix_long(f_at_age, years, ages)
output_rows[[length(output_rows) + 1L]] <- output(
  "mortality", "fishing_mortality_at_age", z$value, "per year",
  year = z$year, age = z$age, age_group = ifelse(z$age == 29, "29+", ""),
  notes = "Derived from official fully-selected annual F times the applicable time-block selectivity; point estimates only.",
  source_type = "derived_source_output",
  source_reference = paste(bio_ref, selex_ref, source_url("model_files/Model_20_1.tpl"), sep = "; "))

m_at_age <- matrix(m_estimate, nrow = length(years), ncol = length(ages))
z <- matrix_long(m_at_age, years, ages)
output_rows[[length(output_rows) + 1L]] <- output(
  "mortality", "natural_mortality_at_age", z$value, "per year",
  year = z$year, age = z$age, age_group = ifelse(z$age == 29, "29+", ""),
  notes = "Single estimated constant M, exp(logm), repeated over the year-age surface; point estimate only.",
  source_type = "derived_source_output", source_reference = source_url("model_files/model_20_1.par"))

output_rows[[length(output_rows) + 1L]] <- output(
  "biomass", "SSB", bio$sp_biom, "t", years,
  notes = "Official point estimates; historical/terminal definition difference is documented in assumptions.",
  source_type = "native_model", source_reference = bio_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "biomass", "total_biomass", bio$tot_biom, "t", years,
  notes = "Official point estimates for ages 2-29+.",
  source_type = "native_model", source_reference = bio_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "recruitment", "recruitment", bio$recruits, "million fish", years, age = 2,
  notes = "Age-2 recruitment point estimates.",
  source_type = "native_model", source_reference = bio_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "catch", "total_biomass", catch_fit$pred, "t", catch_fit$year,
  fleet = "Combined fishery",
  notes = "Fitted catch biomass; observed catch is retained in inputs.csv.",
  source_type = "native_model", source_reference = catch_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "index", "total_biomass", survey_fit$pred, "t", survey_fit$year,
  survey = "GOA bottom trawl survey",
  notes = "Fitted survey biomass; observed index and SE are retained in inputs.csv.",
  source_type = "native_model", source_reference = survey_ref)
output_rows[[length(output_rows) + 1L]] <- output(
  "catchability", "q", q_estimate, "relative scale",
  notes = "Estimated bottom-trawl catchability, exp(log_q_srv1); no uncertainty recovered.",
  source_type = "derived_source_output", source_reference = source_url("model_files/model_20_1.par"))

maturity_matrix <- matrix(rep(waa_mat$maturity, times = length(years)),
  nrow = length(years), byrow = TRUE)
z <- matrix_long(maturity_matrix, years, ages)
output_rows[[length(output_rows) + 1L]] <- output(
  "biology", "maturity_at_age", z$value, "proportion",
  year = z$year, age = z$age, age_group = ifelse(z$age == 29, "29+", ""),
  sex = "female", notes = "Estimated logistic maturity-at-age point estimate.",
  source_type = "native_model", source_reference = maturity_ref)

output_rows[[length(output_rows) + 1L]] <- output(
  "biomass", "total_biomass", exec$tb_proj, "t", exec$year,
  notes = "Official 2024-2025 management projection, not a fitted historical estimate.",
  source_type = "native_model",
  source_reference = source_url("model_files/processed/exec_summ.csv"))
output_rows[[length(output_rows) + 1L]] <- output(
  "biomass", "SSB", exec$ssb_proj, "t", exec$year,
  notes = "Official 2024-2025 management projection, not a fitted historical estimate.",
  source_type = "native_model",
  source_reference = source_url("model_files/processed/exec_summ.csv"))
outputs <- do.call(rbind, output_rows)

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = NA_character_, authority = "NOAA-AFSC",
  authority_stock_id = "Stock SMART 11056", scientific_name = "Sebastes alutus",
  common_name = "Pacific ocean perch - Gulf of Alaska",
  area = "Gulf of Alaska", region = "Gulf of Alaska", ocean = "Northeast Pacific",
  notes = "NOAA GOA assessment unit, distinct from BSAI and British Columbia POP. No Charbonneau-Keith GOA identifier was verified.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2023L, terminal_year = terminal_year,
  estimate_terminal_year = 2025L, assessment_type = "operational update",
  model_family = "ADMB statistical catch-at-age",
  model_version = "Model 20.1 (2020.1-2023)",
  is_current = TRUE, is_applied = TRUE, framework_year = 2021L,
  assessment_url = "https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOApop.pdf",
  framework_url = NA_character_, data_url = dat_ref, model_url = repository,
  repository_url = "https://github.com/noaa-afsc/goa_pop",
  assumptions_status = "complete", inputs_status = "complete",
  outputs_status = "partial",
  notes = paste(
    "Latest completed detailed fit located as of 2026-11-02; 2024 was a harvest projection, the scheduled 2025 full assessment was cancelled, and the next full GOA POP assessment is scheduled for December 2026.",
    "This 2023 operational update uses data through 2023 and the configuration accepted in 2021. 2024-2025 aggregate rows are management projections. Point estimates are imported; annual age-specific uncertainty is unavailable."
  ))

input_key <- paste(inputs$type, inputs$measure, inputs$fleet, inputs$survey,
  inputs$sex, inputs$region, inputs$season, inputs$year, inputs$age,
  inputs$observation_id, inputs$length_bin, sep = "|")
assumption_key <- paste(assumptions$component, assumptions$setting, sep = "|")
if (nrow(inputs) < 2000L || nrow(outputs) < 5000L ||
    anyDuplicated(input_key) || anyDuplicated(assumption_key)) {
  stop("NOAA GOA POP additions failed size or uniqueness checks.", call. = FALSE)
}

register_path <- file.path(root, "discovery", "candidates.csv")
register <- utils::read.csv(register_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
candidate_row <- match("NOAA:11056", register$candidate_id)
if (is.na(candidate_row)) stop("NOAA GOA POP candidate row is missing.", call. = FALSE)
register$matched_stock_id[candidate_row] <- stock_id
register$match_status[candidate_row] <- "matched"
register$import_status[candidate_row] <- "partial"
register$review_date[candidate_row] <- "2026-11-02"
register$notes[candidate_row] <- paste(
  register$notes[candidate_row],
  "Imported source-exact 2023 Model 20.1 inputs and point outputs; uncertainty outputs remain partial. See source_reviews/noaa_goa_pacific_ocean_perch.md."
)

db <- file.path(root, "database")
existing <- utils::read.csv(file.path(db, "assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)$assessment_id
if (!dry_run && assessment_id %in% existing) {
  stop("The assessment already exists; do not append it twice.", call. = FALSE)
}
register_tmp <- tempfile(tmpdir = dirname(register_path), fileext = ".csv")
utils::write.csv(register, register_tmp, row.names = FALSE, na = "",
  fileEncoding = "UTF-8")
if (dry_run) {
  unlink(register_tmp)
  cat("Dry run validated ", nrow(assumptions), " assumptions, ",
    nrow(inputs), " inputs, and ", nrow(outputs), " outputs for ",
    assessment_id, ". Database and candidate register were not changed.\n", sep = "")
} else {
  append_rows <- function(rows, path) {
    utils::write.table(rows, path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
  }
  append_rows(stock, file.path(db, "stocks.csv"))
  append_rows(assessment, file.path(db, "assessments.csv"))
  append_rows(assumptions, file.path(db, "assumptions.csv"))
  append_rows(inputs, file.path(db, "inputs.csv"))
  append_rows(outputs, file.path(db, "outputs.csv"))

  if (!file.copy(register_tmp, register_path, overwrite = TRUE)) {
    stop("Could not update the candidate register.", call. = FALSE)
  }
  unlink(register_tmp)
  cat("Imported ", stock_id, ": ", nrow(inputs), " source inputs, ",
    nrow(assumptions), " assumptions, and ", nrow(outputs),
    " point outputs; uncertainty status remains partial.\n", sep = "")
}




