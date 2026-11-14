root <- "."
stock_id <- "noaa_vermilion_sunset_southern_california"
assessment_id <- paste0(stock_id, "_2021")
candidate_id <- "NOAA:15310"
region <- "Southern California"
years <- 1875:2020
ages <- 0:70
report_url <- "https://www.pcouncil.org/documents/2022/01/the-status-of-vermilion-rockfish-sebastes-miniatus-and-sunset-rockfish-sebastes-crocotulus-in-u-s-waters-off-the-coast-of-california-south-of-point-conception-in-2021-december-2021.pdf/"
model_url <- "https://www.pcouncil.org/documents/vermilion-2021-model-files-southern-ca-zip-file/"
star_url <- "https://www.pcouncil.org/documents/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report/"
safe_url <- "https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/"
status_url <- "https://www.fisheries.noaa.gov/s3/2026-11/final-q3-2026-stock-status-tables-updated-11-02-26.pdf"
cache <- file.path(root, "source_cache/discovery_noaa_vermilion_sunset_south_2021")
manifest_path <- file.path(root, "provenance/noaa_vermilion_sunset_south_2021_sources.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
test_mode <- identical(Sys.getenv("TAM_SOURCE_TEST_MODE"), "1")
if (test_mode && write_mode) stop("Source test mode cannot write database records.", call. = FALSE)

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to read the cached assessment sources.", call. = FALSE)
}

manifest <- read.csv(manifest_path, colClasses = "character",
  stringsAsFactors = FALSE, check.names = FALSE)
source_files <- c("assessment_2021.pdf", "model_files_2021.zip", "star_panel_2021.pdf",
  "groundfish_safe_2025.pdf", "q3_2026_stock_status.pdf")
if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in% names(manifest)) ||
    !setequal(manifest$local_file, source_files) || anyDuplicated(manifest$local_file) ||
    any(manifest$retrieved_on != "2026-11-13")) {
  stop("The southern California Vermilion/Sunset source manifest is incomplete.", call. = FALSE)
}
for (file in source_files) {
  row <- manifest[manifest$local_file == file, , drop = FALSE]
  path <- file.path(cache, file)
  if (nrow(row) != 1L || !file.exists(path) || as.numeric(row$bytes) != file.info(path)$size ||
      !identical(tolower(row$sha256), tolower(unname(tools::sha256sum(path))))) {
    stop("Cached source differs from its pinned manifest: ", file, call. = FALSE)
  }
}

build_records <- function() {
  work <- tempfile("vermilion_sunset_south_2021_")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  utils::unzip(file.path(cache, "model_files_2021.zip"), exdir = work)
  model_root <- file.path(work, "Verm_Sunset_2021_Model_For_DeVore")
  data_path <- file.path(model_root, "Vermilion_SoCA_2021.dat")
  control_path <- file.path(model_root, "Vermilion_SoCA_2021.ctl")
  if (!all(file.exists(c(data_path, control_path, file.path(model_root, "Report.sso"),
                         file.path(model_root, "starter.ss_new"))))) {
    stop("The pinned model archive lacks the reviewed post-STAR input/output files.", call. = FALSE)
  }
  dat <- r4ss::SS_readdat(data_path, version = "3.30.17", verbose = FALSE)
  control <- r4ss::SS_readctl(control_path, verbose = FALSE, datlist = data_path)
  fit <- r4ss::SS_output(model_root, printstats = FALSE, verbose = FALSE,
    covar = FALSE, forecast = FALSE, warn = FALSE)

  if (dat$styr != 1875L || dat$endyr != 2020L || dat$nseas != 1L ||
      dat$Nages != 70L || dat$Nsexes != 2L || dat$N_areas != 1L ||
      dat$Lbin_method != 3L || !identical(as.integer(dat$lbin_vector), seq(8L, 70L, 2L)) ||
      !identical(as.integer(dat$agebin_vector), ages) || nrow(dat$catch) != 510L ||
      any(dat$catch$year == -999L) || nrow(dat$CPUE) != 71L ||
      nrow(dat$lencomp) != 180L || nrow(dat$agecomp) != 631L ||
      !all(dat$CPUE$month == 7L) || !all(dat$CPUE$index %in% c(4L, 6L, 8L, 10L)) ||
      !all(dat$agecomp$sex == 3L) || sum(dat$lencomp$sex == 0L) != 145L ||
      sum(dat$lencomp$sex == 3L) != 35L ||
      sum(dat$agecomp$Lbin_lo == -1L & dat$agecomp$Lbin_hi == -1L) != 34L ||
      sum(dat$lencomp$year < 0L) != 6L || sum(dat$agecomp$year < 0L) != 4L ||
      sum(dat$lencomp$fleet < 0L) != 14L || sum(dat$agecomp$fleet < 0L) != 34L) {
    stop("Native model inputs differ from the reviewed 2021 assessment.", call. = FALSE)
  }
  if (!identical(as.integer(dat$fleetinfo$units[1:3]), rep(1L, 3L)) ||
      !identical(as.integer(dat$fleetinfo$units[4:7]), rep(2L, 4L)) ||
      !identical(as.integer(dat$CPUEinfo$units[c(4L, 6L, 8L, 10L)]), rep(0L, 4L)) ||
      nrow(dat$ageerror) != 2L ||
      !identical(names(dat$ageerror), paste0("age", ages)) ||
      nrow(control$Variance_adjustment_list) == 0L ||
      !all(c(4L, 5L) %in% control$Variance_adjustment_list$factor)) {
    stop("Native fleet units, age-error vectors or variance adjustments differ from review.", call. = FALSE)
  }

  input <- function(type, measure, basis, value, unit, fleet = "", survey = "",
                    sex = "combined", year = NA_integer_, age = NA_integer_,
                    season = "", sampling_time = NA_real_, source_type = "native_model",
                    source_reference, transformation = "", notes = "",
                    observation_id = "", length_bin = NA_real_,
                    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
                    sample_size = NA_real_, age_error = NA_real_, partition = "") {
    args <- list(type, measure, basis, value, unit, fleet, survey, sex, year, age,
      season, sampling_time, source_type, source_reference, transformation, notes,
      observation_id, length_bin, length_bin_lower, length_bin_upper, sample_size,
      age_error, partition)
    n <- max(lengths(args))
    repn <- function(x) rep_len(x, n)
    y <- repn(year)
    pacific_database_row("inputs", n = n, assessment_id = rep(assessment_id, n),
      type = repn(type), measure = repn(measure), basis = repn(basis),
      fleet = repn(fleet), survey = repn(survey), sex = repn(sex), region = rep(region, n),
      season = repn(season), year = as.integer(y),
      year_basis = ifelse(is.na(y), "", "calendar_year"), age = as.numeric(repn(age)),
      value = as.numeric(repn(value)), unit = repn(unit),
      sampling_time = as.numeric(repn(sampling_time)), source_type = repn(source_type),
      source_reference = repn(source_reference), transformation = repn(transformation),
      notes = repn(notes), observation_id = repn(observation_id),
      length_bin = as.numeric(repn(length_bin)),
      length_bin_lower = as.numeric(repn(length_bin_lower)),
      length_bin_upper = as.numeric(repn(length_bin_upper)),
      sample_size = as.numeric(repn(sample_size)), age_error = as.numeric(repn(age_error)),
      partition = repn(partition))
  }
  output <- function(type, measure, year, value, unit, age = NA_integer_, age_group = "",
                     fleet = "", survey = "", sex = "combined", season = "annual",
                     scenario = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                     source_type = "native_model", source_reference, notes = "") {
    args <- list(type, measure, year, value, unit, age, age_group, fleet, survey, sex,
      season, scenario, se, lwr, upr, source_type, source_reference, notes)
    n <- max(lengths(args))
    repn <- function(x) rep_len(x, n)
    pacific_database_row("outputs", n = n, assessment_id = rep(assessment_id, n),
      type = repn(type), measure = repn(measure), fleet = repn(fleet), survey = repn(survey),
      sex = repn(sex), region = rep(region, n), season = repn(season),
      year = as.integer(repn(year)), age = as.numeric(repn(age)), age_group = repn(age_group),
      scenario = repn(scenario), value = as.numeric(repn(value)), se = as.numeric(repn(se)),
      lwr = as.numeric(repn(lwr)), upr = as.numeric(repn(upr)), unit = repn(unit),
      source_type = repn(source_type), source_reference = repn(source_reference), notes = repn(notes))
  }
  assumption <- function(component, setting, value, source_reference, fleet = "",
                         survey = "", sex = "", notes = "") {
    pacific_database_row("assumptions", assessment_id = assessment_id,
      component = component, fleet = fleet, survey = survey, sex = sex,
      region = region, setting = setting, value = value,
      source_reference = source_reference, notes = notes)
  }
  fleet_names <- as.character(dat$fleetinfo$fleetname)
  fleet_types <- as.integer(dat$fleetinfo$type)
  fleet_units <- as.integer(dat$fleetinfo$units)

  catch <- dat$catch[dat$catch$year != -999L, , drop = FALSE]
  catch_fleet <- fleet_names[catch$fleet]
  catch_biomass <- fleet_units[catch$fleet] == 1L
  catch_rows <- input("catch", ifelse(catch_biomass, "catch_biomass", "catch_numbers"),
    ifelse(catch_biomass, "biomass", "numbers"), catch$catch,
    ifelse(catch_biomass, "metric tonnes", "thousand fish"), fleet = catch_fleet,
    year = catch$year, season = "annual",
    observation_id = paste0("catch_f", catch$fleet, "_", catch$year),
    source_reference = "Vermilion_SoCA_2021.dat, catch block",
    notes = "Native annual fleet catch copied without rescaling. Stock Synthesis units code 1 is biomass (metric tonnes); code 2 is numbers (thousand fish).")
  catch_sd <- input("catch", "log_catch_sd", "log_scale", catch$catch_se,
    "log-scale standard deviation", fleet = catch_fleet, year = catch$year,
    season = "annual", observation_id = paste0("catch_f", catch$fleet, "_", catch$year),
    source_reference = "Vermilion_SoCA_2021.dat, catch_se field",
    notes = "Native catch_se values are retained as log-scale observation standard deviations; all observed rows specify 0.01.")

  cpue <- dat$CPUE
  index_survey <- fleet_names[cpue$index]
  index_id <- paste0("index_f", cpue$index, "_", cpue$year)
  index_rows <- input("index", "relative_abundance_index", "index_scale", cpue$obs,
    "native relative index units (Stock Synthesis units code 0)", survey = index_survey,
    year = cpue$year, season = "month 7", sampling_time = (cpue$month - 1) / 12,
    observation_id = index_id, source_reference = "Vermilion_SoCA_2021.dat, CPUE block",
    notes = "Aggregate relative-abundance index; no age-specific index observations are supplied.")
  index_sd <- input("index", "log_index_sd", "log_scale", cpue$se_log,
    "log-index standard deviation", survey = index_survey, year = cpue$year,
    season = "month 7", sampling_time = (cpue$month - 1) / 12,
    observation_id = index_id, source_reference = "Vermilion_SoCA_2021.dat, CPUE se_log field",
    notes = "Native lognormal index error retained without transformation.")

  composition_rows <- list()
  add_composition <- function(x, component, bins, measure) {
    for (i in seq_len(nrow(x))) {
      source_sex <- as.integer(x$sex[i])
      sexes <- switch(as.character(source_sex), "0" = "combined", "1" = "female",
        "2" = "male", "3" = c("female", "male"),
        stop("Unexpected composition sex code.", call. = FALSE))
      row_fleet <- abs(as.integer(x$fleet[i]))
      is_conditional <- component == "age" && !(x$Lbin_lo[i] == -1L && x$Lbin_hi[i] == -1L)
      input_type <- if (is_conditional) "biology" else if (fleet_types[row_fleet] == 1L) "catch" else "index"
      row_id <- paste0(component, "_row", sprintf("%03d", i), "_f", x$fleet[i],
        "_y", x$year[i], "_s", source_sex)
      for (sex_name in sexes) {
        source_prefix <- if (sex_name == "male") "m" else "f"
        columns <- paste0(source_prefix, bins)
        if (length(setdiff(columns, names(x)))) {
          stop(component, " composition lacks source bins for ", sex_name, ".", call. = FALSE)
        }
        values <- as.numeric(unlist(x[i, columns, drop = FALSE], use.names = FALSE))
        if (any(!is.finite(values)) || any(values < 0)) {
          stop(component, " composition contains invalid frequencies.", call. = FALSE)
        }
        notes <- if (component == "length") {
          paste0("Native frequencies copied without normalization. Length bins are lower-edge labels in cm, width 2 cm; the final 70 cm bin is open-ended. Source sex code ",
            source_sex, " and partition code ", x$part[i], " are retained. Negative year means excluded from the working likelihood; negative fleet means expected/log-likelihood values are calculated but excluded from the total likelihood; original signed codes remain in observation_id. For source sex code 0, the combined-sex vector is stored in the female portion and the male portion is ignored. For sex code 3, female and male vectors share one observation_id and the same joint sample_size.")
        } else {
          paste0(if (is_conditional) "Native conditional age-at-length frequencies; raw cell counts are not annual catch-at-age or index-at-age." else "Native marginal age frequencies.",
            " Values are copied without normalization. Age bins 0-70 include the age-70 accumulator. Source sex code ",
            source_sex, ", age-error code ", x$ageerr[i], ", partition code ", x$part[i],
            ", and signed year/fleet status are preserved. Sex code 3 supplies female and male vectors jointly, with the common sample_size repeated for both vectors under one observation_id.")
        }
        composition_rows[[length(composition_rows) + 1L]] <<- input(
          type = input_type, measure = if (is_conditional) "conditional_frequency_at_age" else measure,
          basis = "native_frequency", value = values,
          unit = if (component == "age") "fish" else "source frequency",
          fleet = if (input_type == "catch") fleet_names[row_fleet] else "",
          survey = if (input_type == "index") fleet_names[row_fleet] else "",
          sex = sex_name, year = abs(as.integer(x$year[i])),
          season = paste0("month ", x$month[i]), sampling_time = (x$month[i] - 1) / 12,
          age = if (component == "age") bins else NA_real_,
          length_bin = if (component == "length") bins else NA_real_,
          length_bin_lower = if (is_conditional) as.numeric(x$Lbin_lo[i]) else NA_real_,
          length_bin_upper = if (is_conditional) as.numeric(x$Lbin_hi[i]) else NA_real_,
          sample_size = as.numeric(x$Nsamp[i]),
          age_error = if (component == "age") as.integer(x$ageerr[i]) else NA_integer_,
          partition = as.character(x$part[i]), observation_id = row_id,
          source_reference = paste0("Vermilion_SoCA_2021.dat, ", if (component == "length") "lencomp" else "agecomp", " block"),
          notes = notes)
      }
    }
  }
  add_composition(dat$lencomp, "length", as.integer(dat$lbin_vector), "frequency_at_length")
  add_composition(dat$agecomp, "age", as.integer(dat$agebin_vector), "frequency_at_age")
  age_error_inputs <- list(
    input("biology", "age_error_mean_age", "native_scale", as.numeric(dat$ageerror[1L, ]),
      "years", age = ages, age_error = 1L, source_reference = "Vermilion_SoCA_2021.dat, AgeErr definition 1, mean-age vector",
      notes = "Native mean observed age by true age; half-year values are retained as supplied."),
    input("biology", "ageing_error_sd", "age_error_sd", as.numeric(dat$ageerror[2L, ]),
      "years", age = ages, age_error = 1L, source_reference = "Vermilion_SoCA_2021.dat, AgeErr definition 1, SD vector",
      notes = "Native age-reading standard deviations by true age; no re-scaling.")
  )
  inputs <- do.call(rbind, c(list(catch_rows, catch_sd, index_rows, index_sd),
    composition_rows, age_error_inputs))

  years_keep <- years
  population_filter <- function(x) x$Area == 1L & x$Bio_Pattern == 1L &
    x$Sex %in% 1:2 & x$Morph == x$Sex & x$BirthSeas == 1L &
    x$Settlement == 1L & x$Platoon == 1L & x$Seas == 1L &
    x$Era == "TIME" & x$Yr %in% years_keep & x[["Beg/Mid"]] == "B"
  surface_output <- function(x, age_columns, type, measure, unit, reference, note,
                             fleet_column = NULL, sex_column = "Sex", year_column = "Yr") {
    value_matrix <- as.matrix(x[, age_columns, drop = FALSE])
    storage.mode(value_matrix) <- "numeric"
    keep <- is.finite(value_matrix)
    row_idx <- rep(seq_len(nrow(x)), each = length(age_columns))[as.vector(t(keep))]
    age_idx <- rep(as.integer(age_columns), times = nrow(x))[as.vector(t(keep))]
    values <- as.vector(t(value_matrix))[as.vector(t(keep))]
    output(type, measure, year = x[[year_column]][row_idx], value = values, unit = unit,
      age = age_idx, age_group = ifelse(age_idx == max(ages), "70+", ""),
      fleet = if (is.null(fleet_column)) "" else fleet_names[as.integer(x[[fleet_column]][row_idx])],
      sex = if (is.null(sex_column)) "combined" else ifelse(x[[sex_column]][row_idx] == 1L, "female", "male"),
      source_reference = reference, notes = note)
  }
  n_surface <- fit$natage[population_filter(fit$natage), , drop = FALSE]
  b_surface <- fit$batage[population_filter(fit$batage), , drop = FALSE]
  f_surface <- fit$fatage[fit$fatage$Area == 1L & fit$fatage$Fleet %in% 1:7 &
    fit$fatage$Sex %in% 1:2 & fit$fatage$Morph == fit$fatage$Sex &
    fit$fatage$Seas == 1L & fit$fatage$Era == "TIME" & fit$fatage$Yr %in% years_keep, , drop = FALSE]
  m_surface <- fit$M_at_age[fit$M_at_age$Bio_Pattern == 1L & fit$M_at_age$Sex %in% 1:2 &
    fit$M_at_age$Yr %in% years_keep, , drop = FALSE]
  w_surface <- fit$wtatage[fit$wtatage$seas == 1L & fit$wtatage$sex %in% 1:2 &
    fit$wtatage$bio_pattern == 1L & fit$wtatage$birthseas == 1L &
    fit$wtatage$fleet == -1L & fit$wtatage$year %in% years_keep, , drop = FALSE]
  if (nrow(n_surface) != length(years) * 2L || nrow(b_surface) != length(years) * 2L ||
      nrow(f_surface) != length(years) * 7L * 2L || nrow(m_surface) != length(years) * 2L ||
      nrow(w_surface) != length(years) * 2L) {
    stop("Fitted model surfaces do not have the reviewed historical dimensions.", call. = FALSE)
  }
  n_output <- surface_output(n_surface, as.character(ages), "population", "numbers_at_age",
    "thousand fish", "Report.sso, NUMBERS_AT_AGE, beginning-of-year TIME rows",
    "Beginning-of-year fitted N-at-age by sex; age 70 is the plus group. No age-specific uncertainty is available.")
  biomass_output <- surface_output(b_surface, as.character(ages), "biomass", "biomass_at_age",
    "metric tonnes", "Report.sso, BIOMASS_AT_AGE, beginning-of-year TIME rows",
    "Beginning-of-year fitted biomass-at-age by sex; age 70 is the plus group. No age-specific uncertainty is available.")
  f_output <- surface_output(f_surface, as.character(ages), "mortality", "fishing_mortality_at_age",
    "per year", "Report.sso, F_AT_AGE TIME rows",
    "Annual fishery-specific fitted F-at-age by sex; age 70 is the plus group. No age-specific uncertainty is available.",
    fleet_column = "Fleet")
  m_ages <- grep("^[0-9]+$", names(m_surface), value = TRUE)
  m_ages <- m_ages[vapply(m_surface[m_ages], function(z) any(is.finite(z)), logical(1L))]
  m_output <- surface_output(m_surface, m_ages, "mortality", "natural_mortality_at_age",
    "per year", "Report.sso, NATURAL_MORTALITY, finite M_at_age cells",
    "Fitted M-at-age cells copied where Report.sso provides values; the report surface has finite age columns 13-69 only. The fitted uniform M parameter is separately retained as an estimate.")
  weight_output <- surface_output(w_surface, as.character(ages), "biology", "weight_at_age",
    "kg per fish", "wtatage.ss_new, fleet code -1, mid-season population weights",
    "Model-derived mid-season population weight-at-age by sex; this is a fitted model surface, not an observed empirical weight-at-age series.",
    sex_column = "sex", year_column = "year")

  annual <- fit$timeseries[fit$timeseries$Era %in% c("TIME", "FORE") &
    fit$timeseries$Yr >= min(years) & fit$timeseries$Yr <= 2021L, , drop = FALSE]
  annual <- annual[order(annual$Yr), , drop = FALSE]
  if (!identical(as.integer(annual$Yr), 1875:2021) ||
      any(!is.finite(annual$Bio_all)) || any(!is.finite(annual$SpawnBio)) ||
      any(!is.finite(annual$Recruit_0))) {
    stop("Annual fitted and 2021 forecast outputs do not cover 1875-2021.", call. = FALSE)
  }
  pages <- pdftools::pdf_text(file.path(cache, "assessment_2021.pdf"))
  find_table <- function(pattern) {
    idx <- which(vapply(pages, function(page) grepl(pattern, page, fixed = TRUE), logical(1L)))
    if (length(idx) != 1L) stop("Could not identify report table: ", pattern, call. = FALSE)
    unlist(strsplit(pages[[idx]], "\n", fixed = TRUE))
  }
  parse_table <- function(lines, start_year, end_year) {
    selected <- lines[grepl("^\\s*(201[1-9]|202[01])\\s+", lines, perl = TRUE)]
    tokens <- lapply(selected, function(line) as.numeric(strsplit(trimws(line), "\\s+")[[1L]]))
    rows <- tokens[lengths(tokens) == 7L]
    out <- do.call(rbind, rows)
    out <- out[out[, 1L] >= start_year & out[, 1L] <= end_year, , drop = FALSE]
    out[order(out[, 1L]), , drop = FALSE]
  }
  table_ii <- parse_table(find_table("Table ii: Estimated recent trend in spawning output"), 2011L, 2021L)
  table_iii <- parse_table(find_table("Table iii: Estimated recent trend in recruitment"), 2011L, 2021L)
  if (nrow(table_ii) != 11L || nrow(table_iii) != 11L ||
      any(abs(annual$SpawnBio[match(table_ii[, 1L], annual$Yr)] - table_ii[, 2L]) > 0.0011) ||
      any(abs(annual$Recruit_0[match(table_iii[, 1L], annual$Yr)] - table_iii[, 2L]) > 0.51)) {
    stop("Report Tables ii/iii do not match the native annual output series.", call. = FALSE)
  }
  spawn_lower <- rec_lower <- rep(NA_real_, nrow(annual))
  spawn_upper <- rec_upper <- rep(NA_real_, nrow(annual))
  table_year <- match(annual$Yr, table_ii[, 1L])
  use <- !is.na(table_year)
  spawn_lower[use] <- table_ii[table_year[use], 3L]
  spawn_upper[use] <- table_ii[table_year[use], 4L]
  depletion <- depletion_lower <- depletion_upper <- rep(NA_real_, nrow(annual))
  depletion[use] <- table_ii[table_year[use], 5L]
  depletion_lower[use] <- table_ii[table_year[use], 6L]
  depletion_upper[use] <- table_ii[table_year[use], 7L]
  rec_year <- match(annual$Yr, table_iii[, 1L])
  use_rec <- !is.na(rec_year)
  rec_lower[use_rec] <- table_iii[rec_year[use_rec], 3L]
  rec_upper[use_rec] <- table_iii[rec_year[use_rec], 4L]
  scenario <- ifelse(annual$Yr == 2021L, "2021 forecast", "")
  summary_outputs <- list(
    output("biomass", "total_biomass", annual$Yr, annual$Bio_all, "metric tonnes",
      scenario = scenario, source_reference = "Report.sso, TIME_SERIES$Bio_all",
      notes = "Annual model biomass; the 2021 value is a forecast beyond the fitted data terminal year 2020."),
    output("biomass", "spawning_output", annual$Yr, annual$SpawnBio, "million eggs",
      scenario = scenario, lwr = spawn_lower, upr = spawn_upper,
      source_type = ifelse(is.na(spawn_lower), "native_model", "official_table"),
      source_reference = ifelse(is.na(spawn_lower), "Report.sso, TIME_SERIES$SpawnBio", "Report.sso, TIME_SERIES$SpawnBio; assessment_2021.pdf, Table ii"),
      notes = "Egg-based spawning output, not spawning biomass (SSB). Table ii provides approximate 95% asymptotic intervals for 2011-2021; no intervals are supplied for earlier years."),
    output("recruitment", "recruitment", annual$Yr, annual$Recruit_0, "thousand fish",
      scenario = scenario, lwr = rec_lower, upr = rec_upper,
      source_type = ifelse(is.na(rec_lower), "native_model", "official_table"),
      source_reference = ifelse(is.na(rec_lower), "Report.sso, TIME_SERIES$Recruit_0", "Report.sso, TIME_SERIES$Recruit_0; assessment_2021.pdf, Table iii"),
      notes = "Age-0 recruitment. Table iii provides approximate 95% asymptotic intervals for 2011-2021; no intervals are supplied for earlier years."),
    output("biomass", "spawning_output_ratio_to_unfished", annual$Yr[use], depletion[use], "proportion",
      lwr = depletion_lower[use], upr = depletion_upper[use],
      source_type = "official_table", source_reference = "assessment_2021.pdf, Table ii",
      notes = "Official fraction of unfished spawning output, with approximate 95% asymptotic intervals. This is not SSB depletion."))

  total_numbers <- aggregate(rowSums(n_surface[, as.character(ages), drop = FALSE]),
    list(year = n_surface$Yr), sum)
  names(total_numbers)[2L] <- "value"
  total_numbers <- total_numbers[order(total_numbers$year), , drop = FALSE]
  total_number_output <- output("population", "total_numbers", total_numbers$year,
    total_numbers$value, "thousand fish", source_type = "derived_source_output",
    source_reference = "Report.sso, NUMBERS_AT_AGE; sum of ages 0-70 over female and male surfaces",
    notes = "Derived by summing beginning-of-year numbers-at-age over both sexes and the age-70 plus group; uncertainty was not derived.")
  m_parameter <- fit$parameters[fit$parameters$Label == "NatM_uniform_Fem_GP_1", , drop = FALSE]
  if (nrow(m_parameter) != 1L || abs(m_parameter$Value - 0.13023) > 1e-6 ||
      !is.finite(m_parameter$Parm_StDev)) {
    stop("The fitted female natural mortality parameter differs from the reviewed report.", call. = FALSE)
  }
  m_parameter_output <- output("parameter", "natural_mortality_average_parameter", NA_integer_,
    m_parameter$Value, "per year", se = m_parameter$Parm_StDev,
    source_reference = "Report.sso, NatM_uniform_Fem_GP_1",
    notes = "Estimated uniform natural mortality parameter for females; model applies the same fitted M surface to males. Standard error is on the natural-mortality parameter scale.")

  parameter_value <- function(label) {
    value <- fit$parameters$Value[match(label, fit$parameters$Label)]
    if (length(value) != 1L || !is.finite(value)) stop("Missing fitted parameter: ", label, call. = FALSE)
    value
  }
  variance <- control$Variance_adjustment_list
  assumptions <- list(
    assumption("assessment", "model_dimensions", "One area, two sexes, one annual season; ages 0-70 with age 70 as the plus group; fitted data years 1875-2020; 2021 is a forecast.", "Vermilion_SoCA_2021.dat and Report.sso"),
    assumption("population", "assessment_unit", "Vermilion rockfish and Sunset rockfish complex in U.S. waters off California south of Point Conception; retained as one two-species assessment unit.", "assessment_2021.pdf, stock description and assessment title"),
    assumption("assessment", "current_run", "2021 production assessment, the latest detailed benchmark listed for the Southern California unit in the 2025 Groundfish SAFE.", "assessment_2021.pdf; groundfish_safe_2025.pdf; PFMC Groundfish Assessment Documents"),
    assumption("catch", "observation_model", "510 annual catch observations from seven fleets. Fleets 1-3 are biomass in metric tonnes; fleets 4-7 are numbers in thousands of fish. All native catch_se values are 0.01 on the log scale. The source model does not use catch-at-age.", "Vermilion_SoCA_2021.dat, catch and fleetinfo blocks"),
    assumption("index", "observation_model", "Four aggregate relative-abundance series (fleet IDs 4, 6, 8 and 10), 71 observations in total; all are monthly code 7, represented at 0.5 of the year. No age-specific abundance index is supplied.", "Vermilion_SoCA_2021.dat, CPUE and fleetinfo blocks"),
    assumption("composition", "likelihood_inputs", "180 length-composition rows use 8-70 cm lower-edge bins at 2 cm widths; 145 rows are combined-sex and 35 use joint female/male vectors. 631 age-composition rows use ages 0-70; all use joint sexes, including 597 conditional age-at-length rows and 34 marginal rows. Native frequencies, sample sizes, partition, age error, conditioning lengths and signed inclusion flags are retained without normalization.", "Vermilion_SoCA_2021.dat, lencomp and agecomp blocks; Stock Synthesis 3.30.15 User Manual, composition sex and exclusion codes", notes = "Conditional age samples are biological age-at-length observations, not annual catch-at-age or age-specific abundance indices."),
    assumption("composition", "likelihood_weights", "Native variance-adjustment entries for length compositions (factor 4) and age compositions (factor 5) are retained by fleet without transformation.", "Vermilion_SoCA_2021.ctl, Variance_adjustment_list"),
    assumption("M", "natural_mortality", "Uniform female M estimated at 0.13023 per year (SE 0.01198); the fitted male M surface equals the female surface. The Report.sso M-at-age surface has finite cells only for ages 13-69; other ages are not reconstructed in the output table.", "Report.sso, NatM_uniform_Fem_GP_1 and M_at_age; Vermilion_SoCA_2021.ctl"),
    assumption("biology", "growth", paste0("Sex-specific von Bertalanffy growth parameters and age-varying growth CV are estimated. Female fitted parameters include L_at_Amin=", format(parameter_value("L_at_Amin_Fem_GP_1"), digits = 6), ", L_at_Amax=", format(parameter_value("L_at_Amax_Fem_GP_1"), digits = 6), ", K=", format(parameter_value("VonBert_K_Fem_GP_1"), digits = 6), ", CV_young=", format(parameter_value("CV_young_Fem_GP_1"), digits = 5), ", CV_old=", format(parameter_value("CV_old_Fem_GP_1"), digits = 5), "."), "Report.sso parameter table; Vermilion_SoCA_2021.ctl"),
    assumption("biology", "weight_length", paste0("Fixed weight-length relationship: weight_kg = ", format(parameter_value("Wtlen_1_Fem_GP_1"), scientific = TRUE), " * fork_length_cm^", format(parameter_value("Wtlen_2_Fem_GP_1"), digits = 6), "; male and female coefficients are equal."), "Vermilion_SoCA_2021.ctl, Wtlen parameters"),
    assumption("biology", "maturity", paste0("Fixed logistic maturity-at-length, 50% maturity at ", parameter_value("Mat50%_Fem_GP_1"), " cm with slope ", parameter_value("Mat_slope_Fem_GP_1"), "; no maturity-at-age input vector is supplied."), "Vermilion_SoCA_2021.ctl, maturity parameters"),
    assumption("biology", "fecundity", paste0("Fixed fecundity-at-length relationship: million eggs per female = ", format(parameter_value("Eggs_scalar_Fem_GP_1"), scientific = TRUE), " * fork_length_cm^", format(parameter_value("Eggs_exp_len_Fem_GP_1"), digits = 6), "."), "Vermilion_SoCA_2021.ctl, fecundity parameters"),
    assumption("recruitment", "stock_recruitment", paste0("Beverton-Holt stock-recruitment relationship; fitted steepness = ", format(parameter_value("SR_BH_steep"), digits = 5), "."), "Vermilion_SoCA_2021.ctl and Report.sso parameter table"),
    assumption("biology", "age_error", "Age-composition observations use age-error definition 1; the native mean-age and standard-deviation vectors for ages 0-70 are included in inputs.csv.", "Vermilion_SoCA_2021.dat, AgeErr and agecomp blocks"),
    assumption("outputs", "uncertainty", "Approximate 95% asymptotic confidence intervals for spawning output, fraction unfished and recruitment are available in report Tables ii and iii for 2011-2021. Age-specific uncertainty is not reported in the source archive.", "assessment_2021.pdf, Tables ii-iii; Report.sso")
  )
  for (factor in sort(unique(variance$factor))) {
    label <- if (factor == 4L) "length_composition_variance_adjustment" else if (factor == 5L) "age_composition_variance_adjustment" else paste0("variance_adjustment_factor_", factor)
    for (i in which(variance$factor == factor)) {
      fleet_id <- as.integer(variance$fleet[i])
      assumptions[[length(assumptions) + 1L]] <- assumption("composition", label,
        as.character(variance$value[i]), "Vermilion_SoCA_2021.ctl, Variance_adjustment_list",
        fleet = fleet_names[fleet_id], notes = paste("Native variance adjustment; factor", factor, "copied without transformation."))
    }
  }
  assumptions <- do.call(rbind, assumptions)

  stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
    authority = "NOAA-NWFSC", authority_stock_id = "15310",
    scientific_name = "Sebastes miniatus; Sebastes crocotulus",
    common_name = "Vermilion and Sunset rockfishes (Southern California)",
    area = "U.S. waters off California south of Point Conception",
    region = "Southern California", ocean = "Northeast Pacific",
    notes = "One combined 2021 assessment unit for Vermilion and Sunset rockfishes south of Point Conception. Do not treat as the broader northern or Oregon/Washington units.")
  assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
    stock_id = stock_id, assessment_year = 2021L, terminal_year = 2020L,
    estimate_terminal_year = 2021L, assessment_type = "benchmark",
    model_family = "Stock Synthesis", model_version = "3.30.17.00 post-STAR base model",
    is_current = TRUE, is_applied = TRUE, framework_year = 2021L,
    assessment_url = report_url, data_url = model_url, model_url = model_url,
    repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "Official 2021 Southern California production assessment fitted through 2020 and forecast through 2021. Inputs include mixed-scale aggregate catches, four aggregate CPUE series, length compositions and conditional/marginal age compositions. Catch-at-age and direct age-specific abundance indices are not supplied. SpawnBio is egg-based spawning output, not SSB. Report-based intervals are available only for selected aggregate quantities in 2011-2021.")
  outputs <- do.call(rbind, c(list(n_output, biomass_output, f_output, m_output,
    weight_output, total_number_output, m_parameter_output), summary_outputs))
  list(stock = stock, assessment = assessment, assumptions = assumptions,
    inputs = inputs, outputs = outputs)
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
assessment_exists <- any(read.csv("database/assessments.csv", stringsAsFactors = FALSE)$assessment_id == assessment_id)
if (length(candidate_row) != 1L || length(inventory_row) != 1L ||
    candidates$eligibility[candidate_row] != "eligible" ||
    !candidates$import_status[candidate_row] %in% c("not_started", "partial") ||
    !inventory$import_status[inventory_row] %in% c("not_started", "partial") ||
    (!is.na(candidates$matched_stock_id[candidate_row]) && nzchar(candidates$matched_stock_id[candidate_row]) && candidates$matched_stock_id[candidate_row] != stock_id) ||
    (!is.na(inventory$matched_stock_id[inventory_row]) && nzchar(inventory$matched_stock_id[inventory_row]) && inventory$matched_stock_id[inventory_row] != stock_id) ||
    (write_mode && assessment_exists)) {
  stop("The candidate registers or canonical assessment table no longer match this import.", call. = FALSE)
}
candidate_update <- candidates[candidate_row, , drop = FALSE]
candidate_update$candidate_unit_id <- stock_id
candidate_update$matched_stock_id <- stock_id
candidate_update$match_status <- "matched"
candidate_update$import_status <- "partial"
candidate_update$stock_name <- "Vermilion and Sunset rockfishes (Southern California)"
candidate_update$assessment_area <- "U.S. waters off California south of Point Conception"
candidate_update$catch_age_evidence <- "The post-STAR model archive supplies aggregate annual catch by fleet and length/age compositions; no annual catch-at-age series is present."
candidate_update$survey_age_evidence <- "Four aggregate relative-abundance indices are used; conditional age-at-length and marginal age-composition samples are separate likelihood inputs, not age-specific indices."
candidate_update$weights_evidence <- "The model archive supplies weight-length parameters and fitted weight-at-age surfaces; no empirical annual weight-at-age series is supplied."
candidate_update$maturity_evidence <- "Maturity is specified as a fixed logistic function of length; no maturity-at-age input vector is supplied."
candidate_update$mortality_evidence <- "Uniform natural mortality is estimated; the fitted report supplies M-at-age rows for ages 13-69 and a scalar parameter estimate."
candidate_update$timing_evidence <- "All four aggregate index series and composition rows encode month 7; the model uses one annual season and index timing 0.5."
candidate_update$output_evidence <- "Report.sso provides fitted N-, biomass-, F-, M- and weight-at-age surfaces plus annual biomass, spawning output and recruitment through 2021. Tables ii-iii report selected 2011-2021 intervals."
candidate_update$detailed_source_url <- paste(report_url, model_url, star_url, safe_url, status_url, sep = "; ")
candidate_update$review_date <- "2026-11-13"
candidate_update$decision_reason <- "The 2021 Southern California benchmark is the latest detailed production run identified for the unit; native post-STAR inputs and fitted outputs are publicly available. Import remains partial because direct catch-at-age and age-specific indices are not supplied, and the full source output archive is not exhaustively transcribed."
candidate_update$notes <- "Partial canonical source import completed from the input data/control files named by starter.ss_new. The generated data.ss_new file is retained for reference but is not substituted for the original .dat input. The assessment's SpawnBio is millions of eggs and is not SSB. Source PDFs and the model archive are locally cached with checksums in provenance/noaa_vermilion_sunset_south_2021_sources.csv."
inventory_update <- inventory[inventory_row, , drop = FALSE]
inventory_update$matched_stock_id <- stock_id
inventory_update$candidate_unit_id <- stock_id
inventory_update$match_status <- "matched"
inventory_update$import_status <- "partial"

cat("Prepared", nrow(source_records$inputs), "inputs,", nrow(source_records$assumptions),
  "assumptions, and", nrow(source_records$outputs), "outputs for", assessment_id, "\n")
cat("No catch-at-age or direct age-specific abundance index is present; source status remains partial.\n")
if (write_mode) {
  append_pacific_case(source_records$stock, source_records$assessment,
    source_records$assumptions, source_records$inputs, source_records$outputs)
  replace_candidate_register_row(candidate_path, candidate_row, candidate_update, candidate_id)
  replace_csv_register_row(inventory_path, inventory_row, inventory_update,
    "unit_key", inventory$unit_key[inventory_row])
  source(file.path(root, "scripts/database/002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("The Southern California Vermilion/Sunset source rows were appended and database validation passed.\n")
}
