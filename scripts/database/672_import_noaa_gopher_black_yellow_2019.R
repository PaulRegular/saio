root <- "."
stock_id <- "noaa_gopher_black_yellow_s_of_4010n"
assessment_id <- paste0(stock_id, "_2019")
candidate_id <- "NOAA:15052"
candidate_unit_id <- stock_id
region <- "South of 40°10' N latitude"
years <- 1916:2018
ages <- 0:28
report_url <- "https://www.pcouncil.org/documents/2019/10/gopher-black-and-yellow-assessment-2019.pdf"
supplement_url <- "https://www.pcouncil.org/documents/2019/10/gopher-black-and-yellow-supplementary-tables.xlsx"
model_url <- "https://www.pcouncil.org/documents/gopher-black-and-yellow-post-model-files-zip-file/"
star_url <- "https://www.pcouncil.org/documents/2019/10/2019-gopher-black-and-yellow-star-panel-report.pdf"
safe_url <- "https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/"
boundary_url <- "https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf"
cache <- file.path(root, "source_cache/discovery_noaa_gopher_black_yellow_2019")
manifest_path <- file.path(root, "provenance/noaa_gopher_black_yellow_2019_sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
test_mode <- identical(Sys.getenv("TAM_SOURCE_TEST_MODE"), "1")
if (test_mode && write_mode) {
  stop("Source test mode cannot write database records.", call. = FALSE)
}

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
if (!requireNamespace("r4ss", quietly = TRUE) ||
    !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to read the cached assessment sources.", call. = FALSE)
}

manifest <- read.csv(manifest_path, colClasses = "character",
  stringsAsFactors = FALSE, check.names = FALSE)
source_files <- c(
  "assessment_2019.pdf", "supplementary_tables_2019.xlsx",
  "post_model_files_2019.zip", "star_panel_2019.pdf",
  "groundfish_safe_2025.pdf", "amendment37_stock_definitions_2026.pdf"
)
if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in%
    names(manifest)) || !setequal(manifest$local_file, source_files) ||
    anyDuplicated(manifest$local_file) || any(manifest$retrieved_on != "2026-11-13")) {
  stop("The pinned Gopher/Black-and-Yellow source manifest is incomplete.", call. = FALSE)
}
sha256_file <- function(path) unname(tools::sha256sum(path))
for (file in source_files) {
  row <- manifest[manifest$local_file == file, , drop = FALSE]
  path <- file.path(cache, file)
  if (nrow(row) != 1L || !file.exists(path) ||
      as.numeric(row$bytes) != file.info(path)$size ||
      !identical(tolower(row$sha256), tolower(sha256_file(path)))) {
    stop("Cached source differs from its pinned manifest: ", file, call. = FALSE)
  }
}

build_records <- function() {
  model_zip <- file.path(cache, "post_model_files_2019.zip")
  work <- tempfile("gopher_black_yellow_2019_")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  members <- utils::unzip(model_zip, list = TRUE)$Name
  model_files <- members[grepl(
    "/(data[.]ss_new|control[.]ss_new|Report[.]sso|CompReport[.]sso|Forecast-report[.]sso|starter[.]ss_new|wtatage[.]ss_new|ss[.]par)$",
    members
  )]
  if (length(model_files) != 8L) {
    stop("The post-STAR archive does not contain the reviewed model files.", call. = FALSE)
  }
  utils::unzip(model_zip, files = model_files, exdir = work)
  one_file <- function(pattern) {
    paths <- list.files(work, pattern = pattern, recursive = TRUE, full.names = TRUE)
    if (length(paths) != 1L) stop("Expected one ", pattern, " in the model archive.", call. = FALSE)
    paths
  }
  data_path <- one_file("^data[.]ss_new$")
  control_path <- one_file("^control[.]ss_new$")
  report_path <- one_file("^Report[.]sso$")
  dat <- r4ss::SS_readdat(data_path, version = "3.30.13", verbose = FALSE)
  control <- r4ss::SS_readctl(control_path, verbose = FALSE, datlist = data_path)
  fit <- r4ss::SS_output(dirname(report_path), printstats = FALSE,
    verbose = FALSE, covar = FALSE, readwt = TRUE, forecast = TRUE, warn = FALSE)

  if (dat$styr != 1916L || dat$endyr != 2018L || dat$nseas != 1L ||
      dat$Nages != 28L || dat$Nsexes != 1L || dat$N_areas != 1L ||
      !identical(as.integer(dat$lbin_vector), 4:40) ||
      !identical(as.integer(dat$agebin_vector), ages) || nrow(dat$catch) != 312L ||
      nrow(dat$CPUE) != 84L || nrow(dat$lencomp) != 151L ||
      nrow(dat$agecomp) != 362L || !all(dat$CPUE$month == 7L) ||
      !all(dat$lencomp$sex == 0L) || !all(dat$agecomp$sex == 0L)) {
    stop("Native input dimensions differ from the reviewed 2019 assessment.", call. = FALSE)
  }
  if (sum(dat$catch$year == -999L) != 3L ||
      any(!dat$CPUE$index %in% seq_len(nrow(dat$fleetinfo))) ||
      any(dat$fleetinfo$units[dat$CPUE$index] != 0L) ||
      any(dat$agecomp$Lbin_lo < 0 | dat$agecomp$Lbin_hi < dat$agecomp$Lbin_lo) ||
      !all(c(4L, 5L) %in% control$Variance_adjustment_list$factor)) {
    stop("Native observations or control settings differ from the reviewed assessment.", call. = FALSE)
  }

  fleet_names <- as.character(dat$fleetinfo$fleetname)
  fleet_types <- as.integer(dat$fleetinfo$type)
  input <- function(type, measure, basis, value, unit, fleet = "", survey = "",
                    sex = "combined", year = NA_integer_, age = NA_integer_,
                    season = "", sampling_time = NA_real_, source_type = "native_model",
                    source_reference, transformation = "", notes = "",
                    observation_id = "", length_bin = NA_real_,
                    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
                    sample_size = NA_real_, age_error = NA_real_, partition = "",
                    n = NULL) {
    args <- list(type, measure, basis, value, unit, fleet, survey, sex, year,
      age, season, sampling_time, source_type, source_reference, transformation,
      notes, observation_id, length_bin, length_bin_lower, length_bin_upper,
      sample_size, age_error, partition)
    if (is.null(n)) n <- max(lengths(args))
    repn <- function(x) rep_len(x, n)
    y <- repn(year)
    pacific_database_row("inputs", n = n,
      assessment_id = rep(assessment_id, n), type = repn(type),
      measure = repn(measure), basis = repn(basis), fleet = repn(fleet),
      survey = repn(survey), sex = repn(sex), region = rep(region, n),
      season = repn(season), year = as.integer(y),
      year_basis = ifelse(is.na(y), "", "calendar_year"),
      age = as.numeric(repn(age)), value = as.numeric(repn(value)),
      unit = repn(unit), sampling_time = as.numeric(repn(sampling_time)),
      source_type = repn(source_type), source_reference = repn(source_reference),
      transformation = repn(transformation), notes = repn(notes),
      observation_id = repn(observation_id), length_bin = as.numeric(repn(length_bin)),
      length_bin_lower = as.numeric(repn(length_bin_lower)),
      length_bin_upper = as.numeric(repn(length_bin_upper)),
      sample_size = as.numeric(repn(sample_size)),
      age_error = as.numeric(repn(age_error)), partition = repn(partition))
  }
  output <- function(type, measure, year, value, unit, age = NA_integer_,
                     age_group = "", fleet = "", survey = "", sex = "combined",
                     season = "annual", scenario = "", se = NA_real_,
                     lwr = NA_real_, upr = NA_real_,
                     source_type = "native_model", source_reference, notes = "") {
    args <- list(type, measure, year, value, unit, age, age_group, fleet,
      survey, sex, season, scenario, se, lwr, upr, source_type, source_reference, notes)
    n <- max(lengths(args))
    repn <- function(x) rep_len(x, n)
    pacific_database_row("outputs", n = n,
      assessment_id = rep(assessment_id, n), type = repn(type),
      measure = repn(measure), fleet = repn(fleet), survey = repn(survey),
      sex = repn(sex), region = rep(region, n), season = repn(season),
      year = as.integer(repn(year)), age = as.numeric(repn(age)),
      age_group = repn(age_group), scenario = repn(scenario),
      value = as.numeric(repn(value)), se = as.numeric(repn(se)),
      lwr = as.numeric(repn(lwr)), upr = as.numeric(repn(upr)),
      unit = repn(unit), source_type = repn(source_type),
      source_reference = repn(source_reference), notes = repn(notes))
  }
  assumption <- function(component, setting, value, source_reference, notes = "") {
    pacific_database_row("assumptions", assessment_id = assessment_id,
      component = component, region = region, setting = setting, value = value,
      source_reference = source_reference, notes = notes)
  }

  catch <- dat$catch[dat$catch$year != -999L, , drop = FALSE]
  catch_id <- paste0("catch_f", catch$fleet, "_", catch$year)
  catch_rows <- input("catch", "catch_biomass", "biomass", catch$catch,
    "metric tonnes", fleet = fleet_names[catch$fleet], year = catch$year,
    season = "annual", observation_id = catch_id,
    source_reference = "data.ss_new, catch block",
    notes = "Final post-STAR model catch values by fishery. The three year=-999 control rows are excluded; no catch-at-age values are supplied.")
  positive_catch_sd <- catch$catch_se > 0
  catch_sd <- input("catch", "log_catch_sd", "log_scale", catch$catch_se[positive_catch_sd],
    "log-scale standard deviation", fleet = fleet_names[catch$fleet[positive_catch_sd]],
    year = catch$year[positive_catch_sd], season = "annual",
    observation_id = catch_id[positive_catch_sd],
    source_reference = "data.ss_new, catch_se field",
    notes = "Native log-scale catch uncertainty retained separately from the catch observations.")

  cpue <- dat$CPUE
  survey_names <- fleet_names[cpue$index]
  survey_id <- paste0("index_f", cpue$index, "_", cpue$year)
  index_measure <- ifelse(survey_names == "PISCOage0", "recruitment_index",
    "relative_abundance_index")
  index_rows <- input("index", index_measure, "index_scale", cpue$obs,
    "native relative index units (Stock Synthesis units code 0)",
    survey = survey_names, year = cpue$year, season = "month 7",
    sampling_time = (cpue$month - 1) / 12, observation_id = survey_id,
    source_reference = "data.ss_new, CPUE block",
    notes = "Aggregate lognormal series; July is represented at 0.5 of the year. PISCOage0 is an age-0 recruitment index, not an age-specific abundance index.")
  index_sd <- input("index", "log_index_sd", "log_scale", cpue$se_log,
    "log-index standard error", survey = survey_names, year = cpue$year,
    season = "month 7", sampling_time = (cpue$month - 1) / 12,
    observation_id = survey_id, source_reference = "data.ss_new, CPUE se_log field",
    notes = "Native log-scale observation errors for the aggregate index series.")

  variance_adjustment <- control$Variance_adjustment_list
  composition_inputs <- list()
  composition_weights <- list()
  add_composition <- function(x, component, bins, prefix, measure) {
    is_length <- component == "length"
    value_matrix <- as.matrix(x[, paste0(prefix, bins), drop = FALSE])
    storage.mode(value_matrix) <- "numeric"
    if (any(!is.finite(value_matrix)) || any(value_matrix < 0)) {
      stop(component, " compositions contain invalid native frequency values.", call. = FALSE)
    }
    fleet_id <- abs(as.integer(x$fleet))
    type <- if (is_length) ifelse(fleet_types[fleet_id] == 1L, "catch", "index") else rep("biology", nrow(x))
    fleet <- ifelse(type == "catch" | (!is_length & fleet_types[fleet_id] == 1L),
      fleet_names[fleet_id], "")
    survey <- ifelse(type == "index" | (!is_length & fleet_types[fleet_id] == 3L),
      fleet_names[fleet_id], "")
    id <- paste0(component, "_row", seq_len(nrow(x)), "_f", x$fleet, "_", x$year)
    n_cell <- nrow(x) * length(bins)
    values <- as.vector(t(value_matrix))
    composition_inputs[[length(composition_inputs) + 1L]] <<- input(
      rep(type, each = length(bins)), measure, "native_frequency", values,
      "native Stock Synthesis composition frequency",
      fleet = rep(fleet, each = length(bins)), survey = rep(survey, each = length(bins)),
      year = rep(abs(as.integer(x$year)), each = length(bins)),
      season = rep(paste0("month ", x$month), each = length(bins)),
      sampling_time = rep((x$month - 1) / 12, each = length(bins)),
      age = if (!is_length) rep(bins, times = nrow(x)) else NA_integer_,
      length_bin = if (is_length) rep(bins, times = nrow(x)) else NA_real_,
      length_bin_lower = if (!is_length) rep(as.numeric(x$Lbin_lo), each = length(bins)) else NA_real_,
      length_bin_upper = if (!is_length) rep(as.numeric(x$Lbin_hi), each = length(bins)) else NA_real_,
      sample_size = rep(as.numeric(x$Nsamp), each = length(bins)),
      age_error = if (!is_length) rep(as.integer(x$ageerr), each = length(bins)) else NA_integer_,
      partition = rep(as.character(x$part), each = length(bins)),
      observation_id = rep(id, each = length(bins)),
      source_reference = if (is_length) "data.ss_new, lencomp block" else "data.ss_new, conditional age-at-length block",
      notes = if (is_length) paste0("Native composition frequencies by one-centimetre length bin (", min(bins), "-", max(bins), " cm); values and source sample size are preserved without normalization. A negative source year code marks an evaluation-only row; the year field stores its absolute calendar year and the signed code remains in observation_id.") else "Native conditional age-at-length frequencies. Counts and sample sizes are preserved without normalization. These samples are not an age-specific abundance index; fleet 9 Dummy1 is retained as the model's auxiliary age-sampling group.",
      n = n_cell)
    adjustment_factor <- if (is_length) 4L else 5L
    adj <- variance_adjustment[variance_adjustment$factor == adjustment_factor, , drop = FALSE]
    for (i in seq_len(nrow(x))) {
      match_row <- which(adj$fleet == fleet_id[i])
      if (length(match_row) == 1L) {
        composition_weights[[length(composition_weights) + 1L]] <<- input(
          type[i], "observation_likelihood_weight", "relative_scale",
          adj$value[match_row], "native variance-adjustment value",
          fleet = fleet[i], survey = survey[i], year = abs(as.integer(x$year[i])),
          season = paste0("month ", x$month[i]),
          sampling_time = (x$month[i] - 1) / 12,
          observation_id = id[i],
          source_reference = "control.ss_new, Variance_adjustment_list",
      notes = paste0("Factor ", adjustment_factor,
            " composition variance-adjustment entry copied without transformation; interpretation is retained as the native relative-scale likelihood setting."))
      }
    }
  }
  add_composition(dat$lencomp, "length", as.integer(dat$lbin_vector), "l", "frequency_at_length")
  add_composition(dat$agecomp, "age", as.integer(dat$agebin_vector), "a", "conditional_frequency_at_age")

  m_parameter <- fit$parameters$Value[match("NatM_p_1_Fem_GP_1", fit$parameters$Label)]
  if (length(m_parameter) != 1L || !is.finite(m_parameter) || m_parameter != 0.193) {
    stop("The fixed natural-mortality parameter differs from the reviewed model.", call. = FALSE)
  }
  m_input <- input("M", "natural_mortality_at_age", "per_year",
    rep(m_parameter, length(ages)), "per year", age = ages,
    source_reference = "control.ss_new and Report.sso, NatM_p_1_Fem_GP_1",
    transformation = "Expanded the single age-independent fixed M parameter across the model ages 0-28.",
    notes = "Fixed scalar M applies to all modeled ages, including the age-28 plus group; it is not an estimated age-specific vector.")
  error_age <- ages
  error_values <- as.numeric(dat$ageerror[2L, paste0("age", ages)])
  age_error_input <- input("biology", "ageing_error_sd", "native_scale",
    error_values, "native Stock Synthesis age-error scale", age = error_age,
    source_reference = "data.ss_new, AgeErr block",
    notes = "Native age-error values are retained without rescaling. The report describes reader SDs of 0.74 years at age 0 to 2.07 at age 28, which do not match the native vector endpoints; interpretation remains unresolved.")

  input_rows <- do.call(rbind, c(list(catch_rows, catch_sd, index_rows, index_sd,
    m_input, age_error_input), composition_inputs, composition_weights))

  population_filter <- function(x) x$Area == 1L & x$Bio_Pattern == 1L &
    x$Sex == 1L & x$BirthSeas == 1L & x$Settlement == 1L &
    x$Platoon == 1L & x$Morph == 1L & x$Seas == 1L &
    x$Era == "TIME" & x$Yr %in% years & x[["Beg/Mid"]] == "B"
  n_surface <- fit$natage[population_filter(fit$natage), , drop = FALSE]
  b_surface <- fit$batage[population_filter(fit$batage), , drop = FALSE]
  f_surface <- fit$fatage[fit$fatage$Area == 1L & fit$fatage$Fleet %in% 1:3 &
    fit$fatage$Sex == 1L & fit$fatage$Morph == 1L & fit$fatage$Seas == 1L &
    fit$fatage$Era == "TIME" & fit$fatage$Yr %in% years, , drop = FALSE]
  m_surface <- fit$M_at_age[fit$M_at_age$Bio_Pattern == 1L &
    fit$M_at_age$Sex == 1L & fit$M_at_age$Yr %in% years, , drop = FALSE]
  w_surface <- fit$mean_body_wt[fit$mean_body_wt$Morph == 1L &
    fit$mean_body_wt$Seas == 1L & fit$mean_body_wt$Yr %in% years, , drop = FALSE]
  if (nrow(n_surface) != length(years) || nrow(b_surface) != length(years) ||
      nrow(f_surface) != length(years) * 3L || nrow(m_surface) != length(years) ||
      nrow(w_surface) != length(years)) {
    stop("The fitted model surfaces do not have the reviewed historical dimensions.", call. = FALSE)
  }
  surface_output <- function(x, surface_ages, type, measure, unit, reference, notes,
                             fleet_column = NULL) {
    value_matrix <- as.matrix(x[, as.character(surface_ages), drop = FALSE])
    storage.mode(value_matrix) <- "numeric"
    if (any(!is.finite(value_matrix))) stop("Non-finite fitted surface values.", call. = FALSE)
    n <- length(value_matrix)
    output(type, measure,
      year = rep(as.integer(x$Yr), each = length(surface_ages)),
      value = as.vector(t(value_matrix)), unit = unit,
      age = rep(surface_ages, times = nrow(x)),
      age_group = ifelse(rep(surface_ages, times = nrow(x)) == max(ages), "28+", ""),
      fleet = if (is.null(fleet_column)) "" else rep(fleet_names[as.integer(x[[fleet_column]])], each = length(surface_ages)),
      scenario = "",
      source_type = "native_model", source_reference = reference, notes = notes)
  }
  n_output <- surface_output(n_surface, ages, "population", "numbers_at_age",
    "thousand fish", "Report.sso, natage, beginning-of-year TIME rows",
    "Beginning-of-year numbers at age from the fitted post-STAR model; age 28 is the plus group.")
  b_output <- surface_output(b_surface, ages, "biomass", "biomass_at_age",
    "metric tonnes", "Report.sso, batage, beginning-of-year TIME rows",
    "Beginning-of-year biomass at age from the fitted post-STAR model; age 28 is the plus group.")
  f_output <- surface_output(f_surface, ages, "mortality", "fishing_mortality_at_age",
    "per year", "Report.sso, fatage, TIME rows",
    "Fishery-specific annual fishing mortality at age; fleet identities are retained.",
    fleet_column = "Fleet")
  m_ages <- 0:27
  m_output <- surface_output(m_surface, m_ages, "mortality", "natural_mortality_at_age",
    "per year", "Report.sso, M_at_age",
    "Fixed annual natural mortality. The Report.sso surface is finite for ages 0-27; age 28 is represented only by the common fixed M input.")
  w_output <- surface_output(w_surface, ages, "biology", "weight_at_age",
    "kg per fish", "Report.sso, mean_body_wt",
    "Model-derived mean body weight at age; no separate observed weight-at-age input vector was found.")

  fitted_summary <- fit$timeseries[fit$timeseries$Era %in% c("TIME", "FORE") &
    fit$timeseries$Yr %in% 1916:2019, , drop = FALSE]
  fitted_summary <- fitted_summary[order(fitted_summary$Yr), , drop = FALSE]
  if (!identical(as.integer(fitted_summary$Yr), 1916:2019) ||
      any(!is.finite(fitted_summary$Bio_all)) ||
      any(!is.finite(fitted_summary$SpawnBio)) ||
      any(!is.finite(fitted_summary$Recruit_0))) {
    stop("Report.sso time-series coverage differs from 1916-2019.", call. = FALSE)
  }
  forecast_scenario <- ifelse(fitted_summary$Yr > 2018L, "2019 forecast", "")
  summary_outputs <- list(
    output("biomass", "total_biomass", fitted_summary$Yr, fitted_summary$Bio_all,
      "metric tonnes", scenario = forecast_scenario,
      source_reference = "Report.sso, timeseries$Bio_all",
      notes = "Total model biomass; the 2019 row is a forecast beyond the 2018 terminal data year."),
    output("biomass", "SSB", fitted_summary$Yr, fitted_summary$SpawnBio,
      "metric tonnes", scenario = forecast_scenario,
      source_reference = "Report.sso, timeseries$SpawnBio; Table 28",
      notes = "Report Table 28 labels SpawnBio as spawning biomass in metric tonnes. The narrative and Table b/Table i label the same numeric series as spawning output in million eggs; these source labels conflict, so no conversion or interval is inferred."),
    output("recruitment", "recruitment", fitted_summary$Yr, fitted_summary$Recruit_0,
      "thousand fish", scenario = forecast_scenario,
      source_reference = "Report.sso, timeseries$Recruit_0",
      notes = "Age-0 recruitment; the 2019 row is a forecast beyond the 2018 terminal data year.")
  )
  total_numbers <- data.frame(year = n_surface$Yr,
    value = rowSums(n_surface[, as.character(ages), drop = FALSE]))
  summary_outputs[[length(summary_outputs) + 1L]] <- output(
    "population", "total_numbers", total_numbers$year, total_numbers$value,
    "thousand fish", source_type = "derived_source_output",
    source_reference = "Report.sso, natage; sum of ages 0-28",
    notes = "Derived total abundance by summing beginning-of-year N-at-age, including the age-28 plus group.")

  pages <- pdftools::pdf_text(file.path(cache, "assessment_2019.pdf"))
  table_page <- which(grepl("Table i: Base case results summary", pages, fixed = TRUE))
  if (length(table_page) != 1L) stop("Could not identify the official Table i page.", call. = FALSE)
  table_lines <- unlist(strsplit(pages[[table_page]], "\n", fixed = TRUE))
  numeric_tokens <- function(line) as.numeric(unlist(regmatches(line,
    gregexpr("[0-9]+(?:\\.[0-9]+)?", line, perl = TRUE))))
  row_index <- function(label) {
    i <- grep(paste0("^\\s*", label, "\\s+"), table_lines, perl = TRUE)
    if (length(i) != 1L) stop("Could not identify Table i row ", label, ".", call. = FALSE)
    i
  }
  row_numbers <- function(index, label) {
    numeric_tokens(sub(paste0("^\\s*", label, "\\s+"), "", table_lines[index], perl = TRUE))
  }
  ci_after <- function(index) {
    if (index >= length(table_lines) ||
        !grepl("^\\s*95% CI\\s+", table_lines[index + 1L], perl = TRUE)) {
      stop("Table i lacks the expected confidence-limit row.", call. = FALSE)
    }
    numeric_tokens(sub("^\\s*95% CI\\s+", "", table_lines[index + 1L], perl = TRUE))
  }
  rec_index <- row_index("Recruits")
  rec_points <- row_numbers(rec_index, "Recruits")
  rec_ci <- ci_after(rec_index)
  if (length(rec_points) != 10L || length(rec_ci) != 20L) {
    stop("Table i recruitment values or intervals could not be read unambiguously.", call. = FALSE)
  }
  rec_limits <- matrix(rec_ci, ncol = 2L, byrow = TRUE)
  rec_years <- 2010:2019
  model_recruits <- fitted_summary$Recruit_0[match(rec_years, fitted_summary$Yr)]
  if (any(abs(rec_points - model_recruits) > 0.51)) {
    stop("Table i recruits do not match Report.sso within rounding.", call. = FALSE)
  }
  recruit_rows <- summary_outputs[[3L]]
  recruit_index <- match(rec_years, recruit_rows$year)
  recruit_rows$lwr[recruit_index] <- rec_limits[, 1L]
  recruit_rows$upr[recruit_index] <- rec_limits[, 2L]
  recruit_rows$source_type[recruit_index] <- "official_table"
  recruit_rows$source_reference[recruit_index] <- paste(
    "Report.sso, timeseries$Recruit_0; assessment_2019.pdf, Table i")
  recruit_rows$notes[recruit_index] <- paste(
    "Full-precision age-0 recruit estimates from Report.sso with approximate 95% asymptotic confidence limits from Table i; table points agree within rounding.")
  summary_outputs[[3L]] <- recruit_rows
  depletion_index <- row_index("Depletion")
  depletion_table_i <- row_numbers(depletion_index, "Depletion")
  table_b_page <- which(grepl("Table b: Recent trend", pages, fixed = TRUE))
  if (length(table_b_page) != 1L) stop("Could not identify the official Table b page.", call. = FALSE)
  table_b_lines <- unlist(strsplit(pages[[table_b_page]], "\n", fixed = TRUE))
  table_b_rows <- table_b_lines[grepl("^\\s*201[0-9]\\s+", table_b_lines, perl = TRUE)]
  table_b_values <- lapply(table_b_rows, numeric_tokens)
  keep_table_b <- vapply(table_b_values, function(x) length(x) == 7L &&
    x[1L] %in% rec_years, logical(1L))
  table_b_values <- table_b_values[keep_table_b]
  if (length(table_b_values) != 10L || any(lengths(table_b_values) != 7L) ||
      length(depletion_table_i) != 10L) {
    stop("Table b depletion values or intervals could not be read unambiguously.", call. = FALSE)
  }
  table_b_matrix <- do.call(rbind, table_b_values)
  if (!identical(as.integer(table_b_matrix[, 1L]), rec_years) ||
      any(abs(table_b_matrix[, 5L] - depletion_table_i) > 0.051)) {
    stop("Table b and Table i depletion values do not agree within rounding.", call. = FALSE)
  }
  depletion <- table_b_matrix[, 5L]
  depletion_limits <- table_b_matrix[, 6:7, drop = FALSE]
  summary_outputs[[length(summary_outputs) + 1L]] <- output(
    "biomass", "spawning_output_ratio_to_unfished", rec_years, depletion,
    "percent", lwr = depletion_limits[, 1L], upr = depletion_limits[, 2L],
    scenario = ifelse(rec_years > 2018L, "2019 forecast", ""),
    source_type = "official_table", source_reference = "assessment_2019.pdf, Table b",
    notes = "Source-reported depletion as a percentage of unfished spawning output; approximate 95% asymptotic intervals are retained on the same percent scale.")

  parameter_value <- function(label) fit$parameters$Used[match(label, fit$parameters$Label)]
  param_labels <- c("NatM_p_1_Fem_GP_1", "L_at_Amin_Fem_GP_1",
    "L_at_Amax_Fem_GP_1", "VonBert_K_Fem_GP_1", "CV_young_Fem_GP_1",
    "CV_old_Fem_GP_1", "Wtlen_1_Fem_GP_1", "Wtlen_2_Fem_GP_1",
    "Mat50%_Fem_GP_1", "Mat_slope_Fem_GP_1",
    "Eggs/kg_inter_Fem_GP_1", "Eggs/kg_slope_wt_Fem_GP_1")
  param_values <- vapply(param_labels, parameter_value, numeric(1L))
  if (any(!is.finite(param_values))) stop("A reviewed biological parameter is missing.", call. = FALSE)
  param_text <- paste(paste0(param_labels, "=", format(param_values, digits = 7)), collapse = "; ")
  assumptions <- do.call(rbind, list(
    assumption("assessment", "model_dimensions", "One area, one model sex, one annual season; ages 0-28 with age 28 as the plus group; data years 1916-2018 and 2019 forecast.", "data.ss_new and Report.sso"),
    assumption("population", "stock_unit", "Gopher and Black-and-Yellow Rockfishes combined south of 40°10' N latitude, from Cape Mendocino to the US-Mexico border; both species are represented in one assessment model.", "assessment_2019.pdf; groundfish_safe_2025.pdf; amendment37_stock_definitions_2026.pdf"),
    assumption("assessment", "current_run", "2019 benchmark assessment; latest assessment year listed for the current southern stock unit in the 2025 Groundfish SAFE.", "groundfish_safe_2025.pdf, stock summary; PFMC Groundfish Assessment Documents, 2019 entry"),
    assumption("catch", "observation_model", "Three annual fishery catch-biomass series (Com, RecNorth, RecSouth), in metric tonnes. Positive catch records have log-scale SD 0.01; 24 early zero-catch rows have catch_se=0 and are retained without representing zero as a valid log SD. Observed model input is not catch-at-age.", "data.ss_new, catch block"),
    assumption("index", "observation_model", "Six aggregate lognormal index series: five relative-abundance indices and PISCOage0 as an age-0 recruitment index; all use month 7 (time 0.5) and Stock Synthesis units code 0.", "data.ss_new, CPUE and fleetinfo blocks"),
    assumption("composition", "likelihood_inputs", "151 native length-composition rows across 4-40 cm bins and 362 conditional age-at-length frequency rows for ages 0-28; original frequency values, sample sizes, signed source-year status, source parts, length bounds, age-error code, and control variance-adjustment values are retained without normalization.", "data.ss_new, lencomp and agecomp blocks; control.ss_new, Variance_adjustment_list", "Composition samples are not age-specific abundance indices or catch-at-age observations."),
    assumption("F", "fishery_structure", "Three fishery fleets have separate age-specific fishing-mortality surfaces in the post-STAR Report.sso.", "Report.sso, fatage"),
    assumption("M", "natural_mortality", "Fixed age-independent M=0.193 per year across modeled ages; parameter phase -2.", "control.ss_new and Report.sso, NatM_p_1_Fem_GP_1"),
    assumption("recruitment", "stock_recruitment", "Beverton-Holt stock-recruitment relationship with steepness fixed at 0.72; annual age-0 recruitment is reported.", "control.ss_new and assessment_2019.pdf, model description"),
    assumption("biology", "growth_parameters", param_text, "Report.sso, parameter table; assessment_2019.pdf, Table 24", "Growth uses a von Bertalanffy model; listed values are final post-STAR parameter estimates."),
    assumption("biology", "weight_length", "Fixed weight-length relationship: weight_kg = 8.84e-6 * length_cm^3.25584.", "control.ss_new, Wtlen_1_Fem_GP_1 and Wtlen_2_Fem_GP_1"),
    assumption("biology", "maturity", "Fixed logistic maturity-at-length with 50% maturity at 21.6658 cm and slope -0.905692; no numeric maturity-at-age input vector is supplied.", "control.ss_new, Mat50%_Fem_GP_1 and Mat_slope_Fem_GP_1"),
    assumption("biology", "fecundity", "Stock Synthesis fecundity option 1 with fixed parameters 1 and 0; spawning output units are configured as biomass.", "control.ss_new, fecundity parameters; Report.sso, SpawnOutputUnits"),
    assumption("biology", "age_error", "Conditional age-at-length rows use age-error code 1. Native AgeErr values are retained, but their scale is unresolved: the report describes reader SDs from 0.74 years at age 0 to 2.07 at age 28, unlike the native values.", "data.ss_new, AgeErr and agecomp blocks; assessment_2019.pdf, ageing-error description"),
    assumption("outputs", "spawning_output_label", "Report.sso and Table 28 label SpawnBio as spawning biomass in metric tonnes; narrative and Tables b/i label the identical numeric series spawning output in million eggs. The unit discrepancy is unresolved.", "Report.sso, SpawnOutputUnits; assessment_2019.pdf, Tables b, i, and 28"),
    assumption("outputs", "uncertainty", "Table i reports approximate 95% asymptotic intervals for recruitment and depletion in 2010-2019. These intervals are not attached to the mass-scale SpawnBio series because its published unit labels conflict; no age-specific uncertainty table was found.", "assessment_2019.pdf, Table i")
  ))

  stock <- pacific_database_row("stocks", stock_id = stock_id,
    charbonneau_id = "", authority = "NOAA", authority_stock_id = "15052",
    scientific_name = "Sebastes carnatus; Sebastes chrysomelas",
    common_name = "Gopher and Black-and-Yellow Rockfishes",
    area = "South of 40°10' N latitude (Cape Mendocino to the US-Mexico border)",
    region = "California Current", ocean = "Northeast Pacific",
    notes = "One combined assessment unit for two closely related species; the 2019 model is one area and one sex. No verified Charbonneau-Keith identifier was found.")
  assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
    stock_id = stock_id, assessment_year = 2019L, terminal_year = 2018L,
    estimate_terminal_year = 2019L, assessment_type = "benchmark",
    model_family = "Stock Synthesis", model_version = "3.30.13.09 post-STAR base model",
    is_current = TRUE, is_applied = TRUE, framework_year = 2019L,
    assessment_url = report_url, data_url = supplement_url, model_url = model_url,
    repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "The 2025 Groundfish SAFE lists 2019 as the latest assessment for the current Gopher and Black-and-Yellow Rockfish unit south of 40°10' N. Native observations include aggregate catch, aggregate indices, length compositions, and conditional age-at-length data, but no catch-at-age or age-specific abundance index. Outputs include fitted age surfaces and annual estimates, with source uncertainty only for selected recent summary quantities.")
  outputs <- do.call(rbind, c(list(n_output, b_output, f_output, m_output, w_output), summary_outputs))
  list(stock = stock, assessment = assessment, assumptions = assumptions,
    inputs = input_rows, outputs = outputs)
}

source_records <- build_records()
candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(candidates$candidate_id == candidate_id)
inventory_ids <- strsplit(as.character(inventory$candidate_ids), " | ", fixed = TRUE)
inventory_row <- which(vapply(inventory_ids, function(x) candidate_id %in% x, logical(1L)))
assessment_exists <- any(read.csv("database/assessments.csv",
  stringsAsFactors = FALSE)$assessment_id == assessment_id)
if (length(candidate_row) != 1L || length(inventory_row) != 1L ||
    candidates$eligibility[candidate_row] != "eligible" ||
    !candidates$import_status[candidate_row] %in% c("not_started", "partial") ||
    !inventory$import_status[inventory_row] %in% c("not_started", "partial") ||
    (!is.na(candidates$matched_stock_id[candidate_row]) &&
      nzchar(candidates$matched_stock_id[candidate_row]) &&
      candidates$matched_stock_id[candidate_row] != stock_id) ||
    (!is.na(inventory$matched_stock_id[inventory_row]) &&
      nzchar(inventory$matched_stock_id[inventory_row]) &&
      inventory$matched_stock_id[inventory_row] != stock_id) ||
    !inventory$candidate_unit_id[inventory_row] %in% c(candidate_unit_id,
      "noaa_gopher_black_yellow_northern_california") ||
    (write_mode && assessment_exists)) {
  stop("The candidate registers or canonical assessment table no longer match this import.", call. = FALSE)
}
candidate_update <- candidates[candidate_row, , drop = FALSE]
candidate_update$candidate_unit_id <- stock_id
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "matched"
candidate_update$import_status <- "partial"
candidate_update$stock_name <- "Gopher and Black-and-Yellow Rockfishes (south of 40°10' N)"
candidate_update$assessment_area <- "South of 40°10' N latitude; Cape Mendocino to US-Mexico border"
candidate_update$catch_age_evidence <- "Native files provide annual catch biomass and length compositions, but no catch-at-age series; no defensible age-specific catch reconstruction was recovered."
candidate_update$survey_age_evidence <- "Six aggregate index series are supplied: five relative-abundance indices and one age-0 recruitment index. Conditional age-at-length samples are retained separately; there is no age-specific abundance index."
candidate_update$weights_evidence <- "The model archive supplies growth parameters and a fixed weight-length relationship; model-derived weight-at-age is available in Report.sso. No observed weight-at-age input vector was found."
candidate_update$maturity_evidence <- "Fixed logistic maturity-at-length parameters are supplied in the control file; no numeric maturity-at-age input vector was found."
candidate_update$mortality_evidence <- "Natural mortality is fixed at 0.193 per year across ages, with the model applying the common scalar to age 28+."
candidate_update$timing_evidence <- "All six aggregate index series are sampled in month 7; sampling_time is preserved as 0.5. The model has one annual season."
candidate_update$output_evidence <- "The native Report.sso provides N, biomass, fishery F, M, and weight at age for 1916-2018, plus total biomass, SpawnBio, and recruitment through the 2019 forecast. Table i provides recent recruitment and depletion intervals."
candidate_update$detailed_source_url <- paste(report_url, supplement_url,
  model_url, star_url, safe_url, boundary_url, sep = "; ")
candidate_update$review_date <- "2026-11-13"
candidate_update$decision_reason <- "The current south-of-40°10' N Gopher/Black-and-Yellow unit has a detailed 2019 benchmark assessment and native post-STAR model files; the 2025 Groundfish SAFE lists 2019 as its latest assessment. Imported as partial because catch-at-age and age-specific abundance indices are absent, and spawning-output labels conflict across report tables."
candidate_update$notes <- "Cached authoritative 2019 assessment, supplementary tables, post-STAR model archive, STAR panel report, 2025 Groundfish SAFE, and 2026 stock-definition analysis under source_cache/discovery_noaa_gopher_black_yellow_2019/ with checksums in provenance. The combined two-species assessment is one stock record."
inventory_update <- inventory[inventory_row, , drop = FALSE]
inventory_update$matched_stock_id <- stock_id
inventory_update$candidate_unit_id <- stock_id
inventory_update$match_status <- "matched"
inventory_update$import_status <- "partial"

cat("Prepared", nrow(source_records$inputs), "inputs,",
  nrow(source_records$assumptions), "assumptions, and",
  nrow(source_records$outputs), "outputs for", assessment_id, "\n")
cat("No catch-at-age or age-specific abundance index is present; the source import remains partial.\n")
if (write_mode) {
  append_pacific_case(source_records$stock, source_records$assessment,
    source_records$assumptions, source_records$inputs, source_records$outputs)
  replace_candidate_register_row(candidate_path, candidate_row, candidate_update, candidate_id)
  replace_csv_register_row(inventory_path, inventory_row, inventory_update,
    "unit_key", inventory$unit_key[inventory_row])
  source(file.path(root, "scripts/database/002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("The Gopher/Black-and-Yellow source records were appended and database validation passed.\n")
}
