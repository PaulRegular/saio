root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "noaa_black_rockfish_california_2023")
model_root <- file.path(cache, "model_files")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_36_2026.csv")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

candidate_ids <- c("NOAA:17194", "NOAA:17195")
candidate_unit_id <- "noaa_black_rockfish_california_2023"
stock_id <- "noaa_black_rockfish_california"
assessment_id <- "noaa_black_rockfish_california_2023"
archive_file <- "model_files.zip"
archive_url <- "https://www.pcouncil.org/documents/black-rockfish-ca-2023-model-files-zip/"
report_url <- paste0(
  "https://www.pcouncil.org/documents/g-2-situation-summary-adopt-stock-assessments/",
  "g-2-attachment-8-draft-executive-summary-of-status-of-black-rockfish-",
  "sebastes-melanops-in-u-s-waters-off-california-in-2023/"
)
post_star_url <- paste0(
  "https://www.pcouncil.org/documents/2023/08/",
  "black-rockfish-in-california-stock-stock-assessment-executive-summary-post-star-panel.pdf/"
)
star_url <- paste0(
  "https://www.pcouncil.org/documents/2023/11/",
  "stock-assessment-review-star-panel-report-for-black-rockfish.pdf/"
)
manual_url <- "https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html"
report_index_url <- paste0(
  "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-",
  "rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/"
)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
source(file.path(root, "scripts", "database", "pacific_tables.R"))

if (!requireNamespace("r4ss", quietly = TRUE)) {
  stop("Install r4ss to parse the cached Stock Synthesis files.", call. = FALSE)
}

read_table <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) {
    stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  }
  hashes
}

manifest <- read_table(file.path(cache, "sources.csv"))
verify_source <- function(file) {
  source_row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(cache, file)
  if (nrow(source_row) != 1L || !file.exists(path) ||
      tolower(source_row$sha256) != sha256_file(path)) {
    stop("Cached NOAA source is missing or differs from its manifest: ",
      file, call. = FALSE)
  }
  path
}

invisible(verify_source(archive_file))
invisible(verify_source("assessment_report.pdf"))
invisible(verify_source("post_star_executive_summary.pdf"))
invisible(verify_source("star_panel_report.pdf"))

component_names <- c("North", "Central")
component_labels <- c(North = "North sub-area", Central = "Central sub-area")
age_bins <- 0:50
year_range <- 1875:2024

input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))

make_frame <- function(fields, values, n) {
  columns <- lapply(fields, function(field) {
    value <- values[[field]]
    if (is.null(value)) return(rep("", n))
    rep_len(value, n)
  })
  names(columns) <- fields
  as.data.frame(columns, stringsAsFactors = FALSE, optional = TRUE,
    check.names = FALSE)
}

make_input <- function(n, region, type, measure, basis, value, unit,
  year = NA_real_, age = NA_real_, fleet = "", survey = "", sex = "",
  season = "", sampling_time = NA_real_, source_reference,
  notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = NA_real_) {
  make_frame(input_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex,
    region = region, season = season, year = year,
    year_basis = "calendar_year", age = age, value = value, unit = unit,
    sampling_time = sampling_time, source_type = "native_model",
    source_reference = source_reference, notes = notes,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition
  ), n)
}

make_output <- function(n, region, type, measure, value, unit, year = NA_real_,
  age = NA_real_, age_group = "", fleet = "", sex = "", se = NA_real_,
  lwr = NA_real_, upr = NA_real_, source_type = "native_model",
  source_reference, notes = "", scenario = "native model archive") {
  make_frame(output_fields, list(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = "", sex = sex, region = region, season = "",
    year = year, age = age, age_group = age_group, value = value, se = se,
    lwr = lwr, upr = upr, unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes, scenario = scenario
  ), n)
}

input_rows <- list()
output_rows <- list()
assumption_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
add_assumption <- function(region, component, setting, value, fleet = "",
  survey = "", sex = "", source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_frame(
    assumption_fields, list(
      assessment_id = assessment_id, component = component, fleet = fleet,
      survey = survey, sex = sex, region = region, season = "",
      setting = setting, value = value, source_reference = source_reference,
      notes = notes
    ), 1L
  )
}

for (component in component_names) {
  region <- component_labels[[component]]
  model_dir <- file.path(model_root, component)
  data_file <- list.files(model_dir, pattern = "_data[.]ss$", full.names = TRUE)
  control_file <- list.files(model_dir, pattern = "_control[.]ss$", full.names = TRUE)
  if (length(data_file) != 1L || length(control_file) != 1L) {
    stop("Expected one data and control file for ", component, ".", call. = FALSE)
  }
  data_name <- basename(data_file)
  control_name <- basename(control_file)
  invisible(verify_source(file.path("model_files", component, data_name)))
  invisible(verify_source(file.path("model_files", component, control_name)))
  invisible(verify_source(file.path("model_files", component, "Report.sso")))
  invisible(verify_source(file.path("model_files", component, "wtatage.ss_new")))

  dat <- r4ss::SS_readdat_3.30(data_file, verbose = FALSE)
  ctl <- r4ss::SS_readctl(control_file, datlist = dat, verbose = FALSE)
  out <- suppressWarnings(r4ss::SS_output(dir = model_dir, covar = FALSE,
    verbose = FALSE, printstats = FALSE, warn = FALSE))

  if (dat$styr != 1875L || dat$endyr != 2022L || dat$Nsexes != 2L ||
      !identical(as.integer(dat$agebin_vector), age_bins)) {
    stop("Unexpected assessment years, sexes, or age grid in ", component, ".",
      call. = FALSE)
  }
  if (!identical(as.integer(dat$fleetinfo$type), c(
      rep(1L, if (component == "North") 7L else 6L),
      rep(3L, if (component == "North") 6L else 7L)
    ))) {
    stop("Unexpected fleet structure in ", component, ".", call. = FALSE)
  }

  fleet_names <- setNames(as.character(dat$fleetinfo$fleetname),
    seq_len(nrow(dat$fleetinfo)))
  fleet_types <- setNames(as.integer(dat$fleetinfo$type),
    seq_len(nrow(dat$fleetinfo)))
  index_units <- setNames(as.integer(dat$CPUEinfo$units),
    as.character(dat$CPUEinfo$fleet))
  index_errors <- setNames(as.integer(dat$CPUEinfo$errtype),
    as.character(dat$CPUEinfo$fleet))
  catch <- dat$catch[dat$catch$year >= dat$styr & dat$catch$year <= dat$endyr,
    , drop = FALSE]
  cpue <- dat$CPUE
  lencomp <- dat$lencomp
  agecomp <- dat$agecomp
  if (anyNA(fleet_names) || anyNA(index_units[as.character(abs(cpue$index))]) ||
      any(index_errors[as.character(abs(cpue$index))] != 0L) ||
      any(!index_units[as.character(abs(cpue$index))] %in% c(0L, 1L)) ||
      any(cpue$month != 7L) || any(catch$catch < 0) ||
      any(!is.finite(catch$catch)) || any(!is.finite(cpue$obs)) ||
      any(!is.finite(cpue$se_log)) || any(cpue$se_log <= 0)) {
    stop("Unexpected catch or index values in ", component, ".", call. = FALSE)
  }

  catch_ref <- paste0(archive_file, ", ", component, "/", data_name,
    ", catch table")
  index_ref <- paste0(archive_file, ", ", component, "/", data_name,
    ", CPUE table and ", control_name, ", index settings")
  add_input(make_input(nrow(catch), region, type = "catch",
    measure = "total_biomass", basis = "biomass", value = catch$catch,
    unit = "metric tonnes", year = catch$year,
    fleet = unname(fleet_names[as.character(catch$fleet)]),
    source_reference = catch_ref,
    notes = "Native annual catch biomass. The single year -999 initialization row is not an observation and is excluded. SS3 catch multipliers are disabled."))

  for (i in seq_len(nrow(cpue))) {
    fleet_id <- abs(as.integer(cpue$index[i]))
    month <- as.integer(cpue$month[i])
    fleet_or_survey <- unname(fleet_names[as.character(fleet_id)])
    is_fishery <- fleet_types[as.character(fleet_id)] == 1L
    unit_code <- index_units[as.character(fleet_id)]
    index_measure <- if (unit_code == 0L) "total_numbers" else "total_biomass"
    index_unit <- if (unit_code == 0L) {
      "relative numbers index (native SS3 units code 0; multiplier not stated)"
    } else {
      "relative biomass index (native SS3 units code 1; multiplier not stated)"
    }
    excluded <- cpue$index[i] < 0
    time <- (month - 1) / 12
    add_input(make_input(1L, region, type = "index",
      measure = index_measure, basis = "index_scale", value = cpue$obs[i],
      unit = index_unit, year = cpue$year[i],
      fleet = if (is_fishery) fleet_or_survey else "",
      survey = if (is_fishery) "" else fleet_or_survey, sex = "combined",
      season = month.name[month], sampling_time = time,
      source_reference = index_ref,
      notes = paste0("Aggregate index on its native scale; SS3 unit code ",
        unit_code, " denotes ", if (unit_code == 0L) "numbers" else "biomass",
        " but the physical multiplier is not reported. Error type 0 is lognormal. Month 7 gives sampling_time 0.5.",
        if (excluded) " The negative signed fleet code means SS3 computes an expected value but excludes this observation from the total likelihood.")))
    add_input(make_input(1L, region, type = "index",
      measure = "log_index_sd", basis = "log_scale",
      value = cpue$se_log[i], unit = "log-scale standard error",
      year = cpue$year[i],
      fleet = if (is_fishery) fleet_or_survey else "",
      survey = if (is_fishery) "" else fleet_or_survey, sex = "combined",
      season = month.name[month], sampling_time = time,
      source_reference = paste0(archive_file, ", ", component, "/",
        data_name, ", CPUE se_log field"),
      notes = "Native log-scale observation error retained without transformation; the source control specifies lognormal error type 0."))
  }

  composition_rows <- function(x, kind, bins) {
    age_data <- kind == "age"
    result <- list()
    for (row_id in seq_len(nrow(x))) {
      code <- as.integer(x$sex[row_id])
      source_fleet <- as.integer(x$fleet[row_id])
      fleet_id <- abs(source_fleet)
      fleet <- unname(fleet_names[as.character(fleet_id)])
      if (is.na(fleet) || !fleet_id %in% as.integer(names(fleet_types))) {
        stop("Unmapped composition fleet in ", component, ".", call. = FALSE)
      }
      fishery <- fleet_types[as.character(fleet_id)] == 1L
      sexes <- switch(as.character(code),
        "0" = list(list(label = "combined", prefix = "f")),
        "1" = list(list(label = "female", prefix = "f")),
        "2" = list(list(label = "male", prefix = "m")),
        "3" = list(list(label = "female", prefix = "f"),
          list(label = "male", prefix = "m")),
        stop("Unexpected composition sex code: ", code, call. = FALSE))
      for (sex_spec in sexes) {
        value <- as.numeric(x[row_id, paste0(sex_spec$prefix, bins)])
        if (length(value) != length(bins) || any(!is.finite(value))) {
          stop("Invalid composition values in ", component, ".", call. = FALSE)
        }
        year <- abs(as.integer(x$year[row_id]))
        month <- as.integer(x$month[row_id])
        excluded_fleet <- source_fleet < 0L
        excluded_year <- x$year[row_id] < 0L
        common_note <- paste0(
          "Native Stock Synthesis composition frequency retained without normalization. ",
          if (code == 0L) "Sex code 0 stores a combined-sex distribution in the female vector. " else "",
          if (code == 3L) "Sex code 3 supplies female and male vectors jointly; both are retained with the shared source sample size. " else "",
          if (excluded_fleet) "Negative signed fleet code marks a provisional row whose likelihood is excluded from the total objective. " else "",
          if (excluded_year) "Negative source-year sign marks a row excluded from the fitted likelihood; calendar year is stored as its absolute value. " else "",
          if (age_data) "Age 50 is the 50+ accumulator; sample size, partition, age-error code, and conditional length interval are retained." else
            "Length-bin labels are native centimetres in 2-cm bins; sample size and partition are retained."
        )
        input_type <- if (fishery) "catch" else "index"
        result[[length(result) + 1L]] <- make_input(
          length(bins), region, type = input_type,
          measure = if (age_data) "frequency_at_age" else "frequency_at_length",
          basis = "native_frequency", value = value,
          unit = "source frequency weight", year = year,
          fleet = if (fishery) fleet else "",
          survey = if (fishery) "" else fleet,
          sex = sex_spec$label, season = month.name[month],
          sampling_time = (month - 1) / 12,
          age = if (age_data) bins else NA_real_,
          length_bin = if (age_data) NA_real_ else bins,
          length_bin_lower = if (age_data &&
            is.finite(x$Lbin_lo[row_id]) && x$Lbin_lo[row_id] >= 0)
            x$Lbin_lo[row_id] else NA_real_,
          length_bin_upper = if (age_data &&
            is.finite(x$Lbin_hi[row_id]) && x$Lbin_hi[row_id] >= 0)
            x$Lbin_hi[row_id] else NA_real_,
          sample_size = x$Nsamp[row_id],
          age_error = if (age_data) x$ageerr[row_id] else NA_real_,
          partition = x$part[row_id],
          source_reference = paste0(archive_file, ", ", component, "/",
            data_name, ", ", if (age_data) "age-composition" else
              "length-composition", " data"),
          notes = common_note,
          observation_id = paste0(tolower(component), "-", kind, "-row-",
            row_id, "-", sex_spec$label)
        )
      }
    }
    do.call(rbind, result)
  }

  add_input(composition_rows(lencomp, "length",
    as.integer(sub("^f", "", grep("^f[0-9]+$", names(lencomp), value = TRUE)))))
  add_input(composition_rows(agecomp, "age", age_bins))

  pop_filter <- function(x) {
    x$Area == 1 & x$Bio_Pattern == 1 & x$Sex %in% 1:2 &
      x$Morph == x$Sex & x$BirthSeas == 1 & x$Settlement == 1 &
      x$Platoon == 1 & x$Seas == 1 & x$Era %in% c("TIME", "FORE") &
      x$Yr %in% year_range
  }
  report_n <- out$natage[pop_filter(out$natage) &
    out$natage[["Beg/Mid"]] == "B", , drop = FALSE]
  report_b <- out$batage[pop_filter(out$batage) &
    out$batage[["Beg/Mid"]] == "B", , drop = FALSE]
  fishery_ids <- which(dat$fleetinfo$type == 1L)
  report_f <- out$fatage[out$fatage$Area == 1 &
    out$fatage$Fleet %in% fishery_ids & out$fatage$Sex %in% 1:2 &
    out$fatage$Morph == out$fatage$Sex & out$fatage$Seas == 1 &
    out$fatage$Era %in% c("TIME", "FORE") &
    out$fatage$Yr %in% year_range, , drop = FALSE]
  report_m <- out$M_at_age[out$M_at_age$Bio_Pattern == 1 &
    out$M_at_age$Sex %in% 1:2 & out$M_at_age$Yr %in% 1875:2023,
    , drop = FALSE]
  annual <- out$timeseries[out$timeseries$Area == 1 &
    out$timeseries$Era %in% c("TIME", "FORE") &
    out$timeseries$Yr %in% year_range, , drop = FALSE]
  weights <- out$wtatage[out$wtatage$year %in% year_range &
    out$wtatage$sex %in% 1:2 & out$wtatage$bio_pattern == 1 &
    out$wtatage$birthseas == 1 & out$wtatage$seas == 1,
    , drop = FALSE]
  expected_f <- length(year_range) * 2L * length(fishery_ids)
  if (nrow(report_n) != 300L || nrow(report_b) != 300L ||
      nrow(report_f) != expected_f ||
      nrow(report_m) != 298L || nrow(annual) != 150L ||
      anyNA(report_n[as.character(age_bins)]) ||
      anyNA(report_b[as.character(age_bins)]) ||
      anyNA(report_f[as.character(age_bins)]) ||
      !identical(sort(unique(report_n$Yr)), year_range)) {
    stop("Unexpected fitted output dimensions in ", component, ".",
      call. = FALSE)
  }

  long_age <- function(x, columns) {
    values <- as.vector(t(as.matrix(x[, columns, drop = FALSE])))
    rows <- rep(seq_len(nrow(x)), each = length(columns))
    ages <- rep(as.integer(columns), times = nrow(x))
    keep <- is.finite(values)
    data.frame(row = rows[keep], age = ages[keep], value = values[keep])
  }
  output_ref <- paste0(archive_file, ", ", component, "/Report.sso")
  add_population_surface <- function(x, type, measure, unit, table,
    notes) {
    z <- long_age(x, as.character(age_bins))
    add_output(make_output(nrow(z), region, type, measure, z$value,
      unit = unit, year = x$Yr[z$row], age = z$age,
      age_group = ifelse(z$age == 50L, "50+", ""),
      sex = ifelse(x$Sex[z$row] == 1L, "female", "male"),
      source_reference = paste0(output_ref, ", ", table),
      notes = notes))
  }
  add_population_surface(report_n, "population", "numbers_at_age",
    "thousand fish", "NUMBERS_AT_AGE",
    "Beginning-of-year numbers at age; age 50 is the 50+ accumulator. Model forecasts for 2023-2024 are retained.")
  add_population_surface(report_b, "biomass", "biomass_at_age",
    "metric tonnes", "BIOMASS_AT_AGE",
    "Beginning-of-year biomass at age; age 50 is the 50+ accumulator. Model forecasts for 2023-2024 are retained.")
  add_population_surface(report_m, "mortality", "natural_mortality_at_age",
    "per year", "Natural_Mortality",
    "Source M surface is defined for ages 0-49; the report's age-50 accumulator has no separate M value.")

  z <- long_age(report_f, as.character(age_bins))
  add_output(make_output(nrow(z), region, "mortality",
    "fishing_mortality_at_age", z$value, "per year",
    year = report_f$Yr[z$row], age = z$age,
    age_group = ifelse(z$age == 50L, "50+", ""),
    fleet = unname(fleet_names[as.character(report_f$Fleet[z$row])]),
    sex = ifelse(report_f$Sex[z$row] == 1L, "female", "male"),
    source_reference = paste0(output_ref, ", F_AT_AGE"),
    notes = "Official fitted fishing-mortality surface; years 2023-2024 are model forecasts. Age 50 is the 50+ accumulator."))
  for (measure in c("total_biomass", "spawning_output", "recruitment")) {
    value <- switch(measure, total_biomass = annual$Bio_all,
      spawning_output = annual$SpawnBio, recruitment = annual$Recruit_0)
    unit <- switch(measure, total_biomass = "metric tonnes",
      spawning_output = "billion eggs", recruitment = "thousand fish")
    type <- switch(measure, total_biomass = "biomass",
      spawning_output = "biomass", recruitment = "recruitment")
    add_output(make_output(nrow(annual), region, type, measure, value,
      unit = unit, year = annual$Yr,
      age = if (measure == "recruitment") 0L else NA_real_,
      source_reference = paste0(output_ref, ", TIME_SERIES"),
      notes = switch(measure,
        total_biomass = "Bio_all from the reference model; total beginning-of-year biomass. Years 2023-2024 are forecasts.",
        spawning_output = "SpawnBio is spawning output in billions of eggs, not spawning-stock biomass in tonnes. The published report's 2023 table differs for the Central sub-area; both source values are retained separately.",
        recruitment = "Recruit_0 is age-0 recruitment in thousands of fish. Years 2023-2024 are forecasts.")))
  }
  total_n <- aggregate(rowSums(report_n[, as.character(age_bins), drop = FALSE]),
    list(year = report_n$Yr), sum)
  names(total_n)[2L] <- "value"
  add_output(make_output(nrow(total_n), region, "population", "total_numbers",
    total_n$value, "thousand fish", year = total_n$year,
    source_type = "derived_source_output",
    source_reference = paste0(output_ref, ", NUMBERS_AT_AGE"),
    notes = "Derived by summing beginning-of-year N-at-age across ages 0-50 and both sexes for this sub-area. No uncertainty is assigned."))

  weight_outputs <- list()
  weight_codes <- sort(unique(weights$fleet))
  for (fleet_code in weight_codes) {
    x <- weights[weights$fleet == fleet_code, , drop = FALSE]
    z <- long_age(x, as.character(age_bins))
    if (fleet_code == -2L) {
      type <- "biology"; measure <- "maturity_fecundity_at_age"
      fleet <- "maturity*fecundity"
      unit <- "native SS3 maturity-fecundity scale"
      notes <- "Generated maturity*fecundity surface from wtatage.ss_new, not a standalone maturity-at-age input."
    } else if (fleet_code == -1L) {
      type <- "biology"; measure <- "weight_at_age"
      fleet <- "mid-season population"
      unit <- "kg per fish"
      notes <- "Generated mid-season population weight-at-age from wtatage.ss_new; not a separately observed biological input."
    } else if (fleet_code == 0L) {
      type <- "biology"; measure <- "start_weight_at_age"
      fleet <- "beginning-season population"
      unit <- "kg per fish"
      notes <- "Generated beginning-season population weight-at-age from wtatage.ss_new; not a separately observed biological input."
    } else {
      type <- "biology"; measure <- "weight_at_age"
      fleet <- unname(fleet_names[as.character(fleet_code)])
      unit <- "kg per fish"
      notes <- "Generated fleet-specific mean weight-at-age from wtatage.ss_new; not a separately observed biological input."
    }
    weight_outputs[[length(weight_outputs) + 1L]] <- make_output(
      nrow(z), region, type, measure, z$value, unit,
      year = x$year[z$row], age = z$age,
      age_group = ifelse(z$age == 50L, "50+", ""),
      fleet = fleet,
      sex = ifelse(x$sex[z$row] == 1L, "female", "male"),
      source_reference = paste0(archive_file, ", ", component,
        "/wtatage.ss_new, fleet code ", fleet_code),
      notes = notes
    )
  }
  add_output(do.call(rbind, weight_outputs))

  m_by_sex <- lapply(1:2, function(sex_code) {
    values <- unique(as.numeric(unlist(report_m[
      report_m$Sex == sex_code, as.character(0:49), drop = FALSE
    ])))
    if (length(values) != 1L) {
      stop("Natural mortality is not constant over age/time in ", component,
        ".", call. = FALSE)
    }
    values
  })
  names(m_by_sex) <- c("female", "male")
  phase <- ctl$MG_parms[c("NatM_p_1_Fem_GP_1", "NatM_p_1_Mal_GP_1"), "PHASE"]
  mortality_status <- if (all(phase < 0)) "fixed" else "estimated"

  add_assumption(region, "model", "software_version", "Stock Synthesis 3.30.21.00",
    source_reference = paste0(archive_file, ", ", component, "/Report.sso"),
    notes = "Version identified in the native 2023 reference model archive.")
  add_assumption(region, "model", "assessment_period", "1875-2022",
    source_reference = paste0(archive_file, ", ", component, "/", data_name),
    notes = "The model is fitted through 2022.")
  add_assumption(region, "model", "forecast_period", "2023-2024",
    source_reference = paste0(archive_file, ", ", component, "/Report.sso"),
    notes = "Forecast years are retained in outputs and are not fitted assessment years.")
  add_assumption(region, "model", "model_dimensions",
    "1 area; 1 season; 2 sexes; ages 0-50",
    source_reference = paste0(archive_file, ", ", component, "/", data_name),
    notes = "Age 50 is the 50+ accumulator group. California North and Central are separate sub-area model components.")
  add_assumption(region, "model", "sub_area_boundary", "Point Arena",
    source_reference = report_url,
    notes = "The published assessment describes northern and central sub-area models split at Point Arena; do not pool their observations or biological settings.")
  add_assumption(region, "biology", "growth_model",
    as.character(ctl$GrowthModel),
    source_reference = paste0(archive_file, ", ", component, "/", control_name),
    notes = "Native Stock Synthesis growth-model code; sex-specific control parameters remain in the cached source file.")
  add_assumption(region, "biology", "maturity_option",
    as.character(ctl$maturity_option),
    source_reference = paste0(archive_file, ", ", component, "/", control_name),
    notes = "Maturity is represented by the source model's parametric length-based specification; no standalone maturity-at-age input vector was located.")
  add_assumption(region, "biology", "fecundity_option",
    as.character(ctl$fecundity_option),
    source_reference = paste0(archive_file, ", ", component, "/", control_name),
    notes = "The model's spawning output uses its length-based fecundity specification; published units are billions of eggs.")
  add_assumption(region, "mortality", "natural_mortality_model",
    paste0(ctl$natM_type, ": constant M parameterization"),
    source_reference = paste0(archive_file, ", ", component, "/", control_name),
    notes = "The source model reports a constant M surface over age and year; the age-50 accumulator has no separate M output.")
  for (sex in names(m_by_sex)) {
    sex_code <- match(sex, c("female", "male"))
    add_assumption(region, "mortality", "natural_mortality_at_age",
      as.character(m_by_sex[[sex]]), sex = sex,
      source_reference = paste0(archive_file, ", ", component,
        "/Report.sso, Natural_Mortality"),
      notes = paste0("Constant M in the native fitted report; control-file phase ",
        phase[sex_code], " gives this parameter status ", mortality_status, "."))
  }
  add_assumption(region, "catch", "catch_se",
    paste(sort(unique(dat$catch$catch_se)), collapse = ", "),
    source_reference = paste0(archive_file, ", ", component, "/", data_name,
      ", catch table"),
    notes = "Native catch_se field retained. The model has catch multipliers disabled; do not interpret this field as an estimated catch-error distribution.")
  add_assumption(region, "composition", "age_error_codes",
    paste(sort(unique(agecomp$ageerr)), collapse = ", "),
    source_reference = paste0(archive_file, ", ", component, "/", data_name,
      ", age-composition data"),
    notes = "Native ageing-error codes are preserved on age-composition rows.")
  add_assumption(region, "composition", "negative_fleet_codes",
    paste(sort(unique(agecomp$fleet[agecomp$fleet < 0])),
      collapse = ", "),
    source_reference = paste0(archive_file, ", ", component, "/", data_name,
      "; ", manual_url),
    notes = "Negative signed fleet codes mark provisional composition rows that SS3 excludes from the total likelihood.")
  for (i in seq_len(nrow(dat$fleetinfo))) {
    add_assumption(region, "fleet", "native_fleet_configuration",
      paste0("type=", dat$fleetinfo$type[i],
        "; survey_timing=", dat$fleetinfo$surveytiming[i],
        "; area=", dat$fleetinfo$area[i],
        "; catch_units=", dat$fleetinfo$units[i],
        "; need_catch_mult=", dat$fleetinfo$need_catch_mult[i]),
      fleet = dat$fleetinfo$fleetname[i],
      source_reference = paste0(archive_file, ", ", component, "/", data_name),
      notes = "Native Stock Synthesis fleet configuration.")
  }
  cpue_fleets <- sort(unique(abs(as.integer(cpue$index))))
  for (i in which(dat$CPUEinfo$fleet %in% cpue_fleets)) {
    fleet_id <- as.integer(dat$CPUEinfo$fleet[i])
    is_fishery <- fleet_types[as.character(fleet_id)] == 1L
    add_assumption(region, "index", "native_units_and_error_type",
      paste0("units=", dat$CPUEinfo$units[i],
        "; error_type=", dat$CPUEinfo$errtype[i],
        "; sd_report=", dat$CPUEinfo$SD_report[i]),
      fleet = if (is_fishery) unname(fleet_names[as.character(fleet_id)]) else "",
      survey = if (is_fishery) "" else unname(fleet_names[as.character(fleet_id)]),
      source_reference = paste0(archive_file, ", ", component, "/",
        data_name, ", index units table"),
      notes = "Unit code 0 denotes a numbers-scale index and code 1 a biomass-scale index; the physical multiplier is not stated. Error type 0 is lognormal.")
  }

}

## Published spawning-output values ----

published_spawn <- data.frame(
  region = c("North sub-area", "Central sub-area", "California statewide"),
  value = c(410, 145, 555),
  lwr = c(175, 36, NA_real_),
  upr = c(645, 253, NA_real_),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(published_spawn))) {
  add_output(make_output(1L, published_spawn$region[i], "biomass",
    "spawning_output", published_spawn$value[i], "billion eggs", year = 2023,
    lwr = published_spawn$lwr[i], upr = published_spawn$upr[i],
    source_type = "official_document",
    source_reference = paste0(post_star_url, ", Tables ES5-ES7"),
    notes = if (i == 3L) {
      "Published California statewide spawning output in Table ES5. The point estimate equals the published North and Central rounded values; no statewide interval is reported."
    } else {
      "Published 2023 sub-area spawning output with 95% asymptotic confidence interval from the post-STAR summary. The archived reference model's Central estimate differs; both records are retained."
    },
    scenario = "published post-STAR summary"))
}

inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
assumptions <- do.call(rbind, assumption_rows)
assumption_key <- do.call(paste, c(assumptions[
  c("component", "fleet", "survey", "sex", "region", "season", "setting")
], sep = "\r"))
if (anyDuplicated(assumption_key)) {
  stop("California source assumptions contain duplicate identifiers.",
    call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
stock_existing <- read_table(stocks_path)
assessment_existing <- read_table(assessments_path)
candidate <- read_table(candidate_path)
inventory <- read_table(inventory_path)
selected <- read_table(selected_path)
candidate_rows <- match(candidate_ids, candidate$candidate_id)
inventory_row <- which(inventory$unit_key ==
  paste0("candidate:", candidate_unit_id))
selected_row <- which(selected$candidate_unit_id == candidate_unit_id)
if (anyNA(candidate_rows) || anyDuplicated(candidate_rows) ||
    length(inventory_row) != 1L || length(selected_row) != 1L ||
    any(candidate$eligibility[candidate_rows] != "eligible") ||
    any(!candidate$import_status[candidate_rows] %in% c("not_started", "partial"))) {
  stop("California black rockfish candidate rows are missing, duplicated, or not ready.",
    call. = FALSE)
}
if (any(stock_existing$stock_id == stock_id) ||
    any(assessment_existing$assessment_id == assessment_id)) {
  stop("California black rockfish records already exist; inspect before importing.",
    call. = FALSE)
}
assessment_rows_exist <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  readLines(con, n = 1L, warn = FALSE)
  first_column <- character()
  repeat {
    block <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(block)) break
    first_column <- c(first_column, sub("^\"?([^\",]+).*$", "\\1", block))
  }
  id %in% first_column
}
for (path in c(file.path(database, "inputs.csv"),
               file.path(database, "outputs.csv"))) {
  if (assessment_rows_exist(path, assessment_id)) {
    stop("Canonical observations already exist for ", assessment_id, ".",
      call. = FALSE)
  }
}

blank_row <- function(fields, values = list()) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
}
stock <- blank_row(names(stock_existing), list(
  stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NWFSC/SWFSC", authority_stock_id = "17194;17195",
  scientific_name = "Sebastes melanops",
  common_name = "Black rockfish - California",
  area = "California, North and Central sub-area models",
  region = "California; North and Central sub-areas",
  ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART records 17194 and 17195 are grouped as one California assessment unit; their area labels do not map one-to-one to the model's Point Arena sub-area boundary. Preserve the North and Central model components separately."
))
assessment <- blank_row(names(assessment_existing), list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2023L, terminal_year = 2022L,
  estimate_terminal_year = 2024L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.21.00",
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = report_url, framework_url = star_url,
  data_url = archive_url, model_url = archive_url,
  repository_url = report_index_url, assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "Official 2023 California production assessment; two independent Stock Synthesis sub-area components, North and Central, fitted through 2022 with forecasts through 2024.",
    "Native catch biomass, aggregate indices, raw length and age-composition likelihood inputs, N/B/F/M-at-age, annual biomass/recruitment/spawning output, and generated biological weight surfaces are retained.",
    "The archive does not provide observed catch numbers-at-age or an age-specific survey-abundance index. Maturity and weights are represented by parametric biology; generated weight surfaces are outputs, not standalone observed inputs.",
    "The post-STAR report's 2023 spawning-output values and intervals are preserved separately from the reference archive, whose Central 2023 value differs. Source PDFs retain provisional front matter; see the source review."
  )
))

candidate_updates <- candidate[candidate_rows, , drop = FALSE]
for (i in seq_len(nrow(candidate_updates))) {
  candidate_updates$matched_stock_id[i] <- stock_id
  candidate_updates$match_status[i] <- "matched"
  candidate_updates$import_status[i] <- "partial"
  candidate_updates$review_date[i] <- "2026-11-12"
  candidate_updates$catch_age_evidence[i] <- paste(
    "The native files supply catch biomass and fishery age/length compositions,",
    "not an observed catch-numbers-at-age matrix. Preserve compositions as",
    "frequency samples; do not expand them into catch at age."
  )
  candidate_updates$survey_age_evidence[i] <- paste(
    "The archive supplies aggregate commercial biomass-scale and survey",
    "numbers-scale indices, plus separate age/length compositions. No",
    "age-specific survey-abundance index was identified; index multipliers",
    "are not stated."
  )
  candidate_updates$weights_evidence[i] <- paste(
    "The model uses parametric growth and generates component-specific",
    "weight-at-age surfaces. Generated tables are retained as outputs;",
    "no standalone observed weight-at-age input was identified."
  )
  candidate_updates$maturity_evidence[i] <- paste(
    "Maturity and fecundity are represented by parametric length-based",
    "control settings. No standalone maturity-at-age input vector was found."
  )
  candidate_updates$mortality_evidence[i] <- paste(
    "North estimates constant sex-specific M in the 2023 reference run;",
    "Central fixes its constant sex-specific M values. The fitted surface is",
    "retained separately for each component."
  )
  candidate_updates$timing_evidence[i] <- paste(
    "All CPUE observations are from July and are recorded at sampling_time=0.5.",
    "Composition months and seasons are preserved from each component's native files."
  )
  candidate_updates$output_evidence[i] <- paste(
    "The archive contains sex-specific N-at-age, biomass-at-age, F-at-age,",
    "natural M-at-age, model-generated catch-at-age, and annual biomass,",
    "recruitment and spawning output for both California sub-area components.",
    "The post-STAR report provides 2023 North/Central spawning-output",
    "estimates and 95% intervals; the Central report and archive values differ."
  )
  candidate_updates$decision_reason[i] <- paste(
    "Eligible and selected as the current California stock unit. The 2023",
    "assessment has separate North and Central models divided at Point Arena;",
    "their observations and biological assumptions remain separate."
  )
  candidate_updates$notes[i] <- paste(
    "Partial source import completed for the single California assessment.",
    "NOAA Stock SMART IDs 17194 and 17195 are grouped to this stock unit,",
    "but their area labels do not map one-to-one to the Point Arena model split.",
    "Native observations and outputs remain separated as North and Central components."
  )
}
inventory_update <- inventory[inventory_row, , drop = FALSE]
inventory_update$matched_stock_id <- stock_id
inventory_update$import_status <- "partial"
selected_update <- selected[selected_row, , drop = FALSE]
selected_update$curation_status <- "partial_source_import"

if (dry_run) {
  cat("Dry run parsed ", nrow(inputs), " inputs, ", nrow(assumptions),
    " assumptions, and ", nrow(outputs),
    " outputs for the California Black Rockfish 2023 assessment.\n", sep = "")
} else {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  for (i in seq_len(nrow(candidate_updates))) {
    replace_candidate_register_row(candidate_path, candidate_rows[i],
      candidate_updates[i, , drop = FALSE], candidate_ids[i])
  }
  replace_csv_register_row(inventory_path, inventory_row, inventory_update,
    "unit_key", paste0("candidate:", candidate_unit_id))
  selected[selected_row, ] <- selected_update
  utils::write.csv(selected, selected_path, row.names = FALSE, na = "")
  cat("Imported ", nrow(inputs), " inputs, ", nrow(assumptions),
    " assumptions, and ", nrow(outputs),
    " outputs for the California Black Rockfish 2023 assessment.\n", sep = "")
}
