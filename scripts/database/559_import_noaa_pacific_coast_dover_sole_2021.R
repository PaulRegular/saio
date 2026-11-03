root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "noaa_pacific_coast_dover_sole_20261029")
model_dir <- file.path(cache, "model_files", "DoverSole_Model_For_DeVore")
assessment_id <- "noaa_pacific_coast_dover_sole_2021"
stock_id <- "noaa_pacific_coast_dover_sole"
candidate_unit_id <- "noaa_stocksmart_10022"
candidate_id <- "NOAA:10022"
report_file <- "2021_US_West_Coast_Dover_Sole_Assessment.pdf"
archive_file <- "Dover_Sole_2021_Model_Files.zip"
data_file <- file.path(model_dir, "2021_dover.dat")
control_file <- file.path(model_dir, "2021_dover.ctl")
report_output <- file.path(model_dir, "Report.sso")
summary_output <- file.path(model_dir, "ss_summary.sso")
report_text <- file.path(cache, "2021_US_West_Coast_Dover_Sole_Assessment.txt")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
make_rows <- function(fields, values, n) {
  out <- lapply(fields, function(name) {
    value <- values[[name]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(out) <- fields
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))

make_input <- function(n, type, measure, basis, value, unit,
  year = NA_real_, age = NA_real_, fleet = "", survey = "", sex = "",
  season = "", sampling_time = NA_real_, source_reference, notes = "",
  transformation = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = NA_real_,
  source_type = "native_model") {
  make_rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = if (all(is.na(year))) "" else "calendar_year",
    age = age, fleet = fleet, survey = survey,
    sex = sex, region = "U.S. West Coast", season = season,
    sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition), n)
}
make_output <- function(n, type, measure, value, unit, year = NA_real_,
  age = NA_real_, fleet = "", sex = "combined", se = NA_real_,
  lwr = NA_real_, upr = NA_real_, source_type = "native_model",
  source_reference, notes = "") {
  make_rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    fleet = fleet, sex = sex, region = "U.S. West Coast", season = "",
    se = se, lwr = lwr, upr = upr, source_type = source_type,
    source_reference = source_reference, notes = notes), n)
}
assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference,
  notes = "", fleet = "", survey = "", sex = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(
    assumption_fields, list(assessment_id = assessment_id,
      component = component, fleet = fleet, survey = survey, sex = sex,
      region = "U.S. West Coast", setting = setting, value = value,
      source_reference = source_reference, notes = notes), 1L)
}

sha256_file <- function(path) {
  hash <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    hash, value = TRUE)))
  if (length(hash) != 1L) stop("Could not calculate SHA-256: ", path,
    call. = FALSE)
  hash
}
manifest <- read_csv(file.path(cache, "sources.csv"))
verify_cached <- function(path, source_name) {
  source <- manifest[manifest$source_file == source_name, , drop = FALSE]
  if (nrow(source) != 1L || !file.exists(path) ||
      tolower(source$sha256) != sha256_file(path) ||
      as.numeric(source$bytes) != file.info(path)$size)
    stop("Cached source differs from its manifest: ", source_name,
      call. = FALSE)
  path
}
invisible(verify_cached(file.path(cache, report_file), report_file))
invisible(verify_cached(file.path(cache, archive_file), archive_file))
for (path in c(data_file, control_file, report_output, summary_output, report_text))
  if (!file.exists(path)) stop("Missing cached assessment file: ", path,
    call. = FALSE)

read_numeric_block <- function(lines, marker, n_fields, regex = FALSE) {
  start <- if (regex) grep(marker, trimws(lines), perl = TRUE) else
    which(trimws(lines) == marker)
  if (length(start) != 1L) stop("Expected one source block: ", marker,
    call. = FALSE)
  rows <- list()
  for (i in seq.int(start + 1L, length(lines))) {
    line <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(line)) next
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (fields[1L] == "-9999") break
    if (length(fields) != n_fields)
      stop("Unexpected field count in ", marker, " at line ", i,
        call. = FALSE)
    value <- suppressWarnings(as.numeric(fields))
    if (anyNA(value)) stop("Invalid numeric value in ", marker,
      " at line ", i, call. = FALSE)
    rows[[length(rows) + 1L]] <- value
  }
  if (!length(rows)) stop("No source records in block: ", marker,
    call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}
read_fleet_table <- function(lines) {
  first <- which(trimws(lines) == "#_fleetinfo")
  last <- which(trimws(lines) == "#_Catch data")
  if (length(first) != 1L || length(last) != 1L || last <= first)
    stop("Could not locate native fleet configuration.", call. = FALSE)
  source <- lines[seq.int(first + 1L, last - 1L)]
  source <- source[grepl("^[[:space:]]*[0-9]+[[:space:]]", source)]
  rows <- lapply(source, function(line) strsplit(trimws(sub("#.*$", "", line)),
    "[[:space:]]+")[[1L]])
  if (any(lengths(rows) < 6L)) stop("Malformed fleet configuration.",
    call. = FALSE)
  out <- as.data.frame(do.call(rbind, lapply(rows, `[`, seq_len(6L))),
    stringsAsFactors = FALSE)
  names(out) <- c("type", "timing", "area", "units", "catch_mult", "name")
  for (name in names(out)[1:5]) out[[name]] <- as.numeric(out[[name]])
  out
}
read_table_between <- function(lines, start_pattern, end_marker, n_fields) {
  first <- grep(start_pattern, trimws(lines), perl = TRUE)
  last <- which(trimws(lines) == end_marker)
  if (length(first) != 1L || length(last) != 1L || last <= first)
    stop("Could not locate source configuration table: ", start_pattern,
      call. = FALSE)
  source <- lines[seq.int(first + 1L, last - 1L)]
  source <- source[grepl("^[[:space:]]*[0-9]+[[:space:]]", source)]
  rows <- lapply(source, function(line) {
    fields <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
    if (length(fields) != n_fields) stop("Malformed source configuration row.",
      call. = FALSE)
    as.numeric(fields)
  })
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}
read_header_block <- function(lines, header_pattern, n_fields) {
  read_numeric_block(lines, header_pattern, n_fields, regex = TRUE)
}
next_numeric_line <- function(lines, start) {
  for (i in seq.int(start, length(lines))) {
    line <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(line)) next
    values <- suppressWarnings(as.numeric(strsplit(line,
      "[[:space:]]+")[[1L]]))
    if (anyNA(values)) stop("Expected a numeric age-error vector at line ", i,
      call. = FALSE)
    return(list(index = i, values = values))
  }
  stop("Unexpected end of native age-error section.", call. = FALSE)
}
read_age_error <- function(lines) {
  header <- grep("^#_age0[[:space:]]+age1", trimws(lines), perl = TRUE)
  if (length(header) != 1L) stop("Could not locate age-error vectors.",
    call. = FALSE)
  out <- vector("list", 2L)
  cursor <- header + 1L
  for (i in seq_len(2L)) {
    age_line <- next_numeric_line(lines, cursor)
    sd_line <- next_numeric_line(lines, age_line$index + 1L)
    out[[i]] <- data.frame(age = age_line$values, sd = sd_line$values)
    cursor <- sd_line$index + 1L
  }
  if (any(vapply(out, nrow, integer(1L)) != 61L) ||
      !isTRUE(all.equal(out[[1L]]$age, out[[2L]]$age)))
    stop("Native age-error vectors do not match the reviewed 61-age layout.",
      call. = FALSE)
  out
}

data_lines <- readLines(data_file, warn = FALSE)
fleet_info <- read_fleet_table(data_lines)
fleet_names <- setNames(fleet_info$name, seq_len(nrow(fleet_info)))
index_info <- read_table_between(data_lines,
  "^#_Fleet[[:space:]]+Units[[:space:]]+Errtype[[:space:]]+SD_Report$",
  "#_CPUE_data", 4L)
names(index_info) <- c("fleet", "units", "error", "sd_report")
discard_info <- read_table_between(data_lines,
  "^#_Fleet[[:space:]]+units[[:space:]]+errtype$", "#_discard_data", 3L)
names(discard_info) <- c("fleet", "units", "error")

catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "month", "fleet", "value", "catch_se")
index <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(index) <- c("year", "month", "fleet", "value", "se_log")
discard <- read_numeric_block(data_lines, "#_discard_data", 5L)
names(discard) <- c("year", "month", "fleet", "value", "std_in")
mean_weight <- read_header_block(data_lines,
  "^#_Year[[:space:]]+Seas[[:space:]]+Fleet[[:space:]]+Partition[[:space:]]+Type[[:space:]]+Value[[:space:]]+Std_in",
  7L)
names(mean_weight) <- c("year", "month", "fleet", "partition", "type",
  "value", "cv")
length_comp <- read_header_block(data_lines,
  "^#year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+inputN",
  60L)
age_comp <- read_header_block(data_lines,
  "^#fishyr[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+age_err",
  129L)
names(length_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "sample_size", paste0("female_", seq_len(27L)),
  paste0("male_", seq_len(27L)))
names(age_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "age_error", "length_lower", "length_upper", "sample_size",
  paste0("female_", seq_len(60L)), paste0("male_", seq_len(60L)))
read_vector <- function(lines, marker, expected) {
  i <- which(trimws(lines) == marker)
  if (length(i) != 1L) stop("Could not locate vector: ", marker,
    call. = FALSE)
  value <- next_numeric_line(lines, i + 1L)$values
  if (length(value) != expected) stop("Unexpected vector length: ", marker,
    call. = FALSE)
  value
}
length_bins <- read_vector(data_lines, "#_lbin_vector", 27L)
age_bins <- read_vector(data_lines, "#_agebin_vector", 60L)
age_error <- read_age_error(data_lines)

if (nrow(fleet_info) != 6L ||
    !identical(as.integer(fleet_info$type), c(1L, 1L, 3L, 3L, 3L, 3L)) ||
    !identical(as.character(fleet_info$name),
      c("CA", "OR_WA", "AFSC_Slope", "Triennial", "NWFSC_Slope", "NWFSC_WCGBT")) ||
    !identical(as.integer(length_bins), seq(8L, 60L, 2L)) ||
    !identical(as.integer(age_bins), 1:60) ||
    nrow(catch) != 220L || nrow(index) != 35L || nrow(discard) != 44L ||
    nrow(mean_weight) != 36L || nrow(length_comp) != 175L ||
    nrow(age_comp) != 925L ||
    any(!index$fleet %in% index_info$fleet) ||
    any(!discard$fleet %in% discard_info$fleet))
  stop("Native input coverage differs from the reviewed 2021 assessment.",
    " fleets=", nrow(fleet_info), ", index_configs=", nrow(index_info),
    ", discard_configs=", nrow(discard_info), ", catch=", nrow(catch),
    ", index=", nrow(index), ", discard=", nrow(discard),
    ", mean_weight=", nrow(mean_weight), ", length_comp=", nrow(length_comp),
    ", age_comp=", nrow(age_comp), ", fleets_match=",
    paste(as.character(fleet_info$name), collapse = ","),
    ", length_bins_match=", identical(as.integer(length_bins), seq(8L, 60L, 2L)),
    ", age_bins_match=", identical(as.integer(age_bins), 1:60), call. = FALSE)
value_checks <- c(catch = all(catch$value >= 0), index = all(index$value > 0),
  index_se_log = all(index$se_log > 0), discard_fraction = all(discard$value >= 0 &
    discard$value <= 1), mean_body_weight = all(mean_weight$value > 0),
  mean_body_weight_cv = all(mean_weight$cv > 0),
  length_sample_size = all(length_comp$sample_size > 0),
  age_sample_size = all(age_comp$sample_size > 0),
  length_frequency = all(as.matrix(length_comp[, 7:60]) >= 0),
  age_frequency = all(as.matrix(age_comp[, 10:129]) >= 0))
if (!all(value_checks)) stop("Native input values fail range checks: ",
  paste(names(value_checks)[!value_checks], collapse = ", "), call. = FALSE)

input_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
source_ref <- function(file, section) paste0(file, "; ", section)
for (i in seq_len(nrow(catch))) {
  fleet <- unname(fleet_names[as.character(as.integer(catch$fleet[i]))])
  add_input(make_input(1L, "catch", "landings_biomass", "biomass",
    catch$value[i], "metric tonnes", year = abs(catch$year[i]), fleet = fleet,
    season = paste0("month ", catch$month[i]),
    sampling_time = (catch$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "Catch data"),
    notes = "Native retained commercial catch (landings); SS3 treats discards in the separate discard section."))
  add_input(make_input(1L, "catch", "catch_se", "native_scale",
    catch$catch_se[i], "native catch_se", year = abs(catch$year[i]),
    fleet = fleet, season = paste0("month ", catch$month[i]),
    sampling_time = (catch$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "Catch data catch_se"),
    notes = "Retained exactly as the native catch_se field; its source model error settings are recorded separately."))
}
for (i in seq_len(nrow(index))) {
  fleet_code <- as.integer(index$fleet[i])
  survey <- unname(fleet_names[as.character(fleet_code)])
  add_input(make_input(1L, "index", "relative_abundance_index", "index_scale",
    index$value[i], "native index units; scale multiplier not stated",
    year = abs(index$year[i]), survey = survey,
    season = paste0("month ", index$month[i]),
    sampling_time = (index$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "CPUE_data"),
    notes = paste0("Native aggregate survey abundance index; original signed year ",
      index$year[i], " is retained in this note. Values are not converted to an absolute abundance scale.")))
  add_input(make_input(1L, "index", "log_index_sd", "log_scale",
    index$se_log[i], "log-scale standard error", year = abs(index$year[i]),
    survey = survey, season = paste0("month ", index$month[i]),
    sampling_time = (index$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "CPUE_data se_log"),
    notes = "Native se_log value; its use depends on the survey error distribution recorded in the fleet configuration."))
}
for (i in seq_len(nrow(discard))) {
  fleet <- unname(fleet_names[as.character(as.integer(discard$fleet[i]))])
  add_input(make_input(1L, "catch", "discard_fraction", "proportion_biomass",
    discard$value[i], "proportion", year = abs(discard$year[i]), fleet = fleet,
    season = paste0("month ", discard$month[i]),
    sampling_time = (discard$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "discard_data"),
    notes = "Native discard fraction; units code 2 means fraction of total catch, on the fleet's biomass or numbers basis."))
  add_input(make_input(1L, "catch", "discard_fraction_cv", "relative_scale",
    discard$std_in[i], "ratio", year = abs(discard$year[i]), fleet = fleet,
    season = paste0("month ", discard$month[i]),
    sampling_time = (discard$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "discard_data Std_in"),
    notes = "Native Std_in retained as the observation CV for the Student-t discard likelihood."))
}
for (i in seq_len(nrow(mean_weight))) {
  fleet <- unname(fleet_names[as.character(as.integer(mean_weight$fleet[i]))])
  add_input(make_input(1L, "weight", "mean_body_weight", "weight_per_fish",
    mean_weight$value[i], "kg per fish", year = mean_weight$year[i],
    fleet = fleet, season = paste0("month ", mean_weight$month[i]),
    sampling_time = (mean_weight$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "meanbodywt"),
    notes = paste0("Native Type=", mean_weight$type[i], " mean-body-weight input; Partition=",
      mean_weight$partition[i], " identifies the source catch group."),
    partition = mean_weight$partition[i]))
  add_input(make_input(1L, "weight", "mean_body_weight_cv", "relative_scale",
    mean_weight$cv[i], "ratio", year = mean_weight$year[i], fleet = fleet,
    season = paste0("month ", mean_weight$month[i]),
    sampling_time = (mean_weight$month[i] - 1) / 12,
    source_reference = source_ref("2021_dover.dat", "meanbodywt Std_in"),
    notes = "Native Std_in retained as the coefficient of variation for the mean-body-weight observation.",
    partition = mean_weight$partition[i]))
}
composition_rows <- function(x, is_age = FALSE) {
  bins <- if (is_age) age_bins else length_bins
  female_cols <- paste0("female_", seq_along(bins))
  male_cols <- paste0("male_", seq_along(bins))
  out <- vector("list", nrow(x))
  for (i in seq_len(nrow(x))) {
    female <- as.numeric(x[i, female_cols, drop = TRUE])
    male <- as.numeric(x[i, male_cols, drop = TRUE])
    sex_code <- as.integer(x$sex_code[i])
    if (sex_code == 3L) {
      sex_values <- list(female = female, male = male)
    } else {
      sex <- switch(as.character(sex_code), "0" = "combined",
        "1" = "female", "2" = "male",
        stop("Unexpected native composition sex code.", call. = FALSE))
      sex_values <- setNames(list(if (sex == "male") male else female), sex)
    }
    signed_fleet <- as.integer(x$fleet[i])
    fleet_code <- abs(signed_fleet)
    fleet <- unname(fleet_names[as.character(fleet_code)])
    if (is.na(fleet)) stop("Composition fleet is not in fleetinfo.", call. = FALSE)
    is_fishery <- fleet_info$type[fleet_code] == 1
    month <- x$month[i]
    age_err <- if (is_age) x$age_error[i] else NA_real_
    llo <- if (is_age) x$length_lower[i] else bins
    lhi <- if (is_age) x$length_upper[i] else bins + 2
    description <- if (is_age) {
      if (x$length_lower[i] >= 0 || x$length_upper[i] >= 0)
        "Conditional age-at-length frequency; native Lbin_method=3 stores length limits in cm."
      else "Marginal age-composition frequency; native length bounds are -1,-1."
    } else "Native length-composition frequency; bins use source 2 cm lower edges."
    description <- paste(description,
      "Frequency vectors are preserved without normalization; Ninput is retained as sample_size.")
    if (sex_code == 3L)
      description <- paste(description,
        "Native sex code 3 carries one joint observation with separate female and male vectors; sample_size repeats by sex and must not be added across them.")
    if (sex_code == 0L)
      description <- paste(description,
        "Native sex code 0 is a combined-sex sample stored in the female vector; the male vector is retained in the source file and ignored by SS3.")
    if (sex_code %in% 1:2)
      description <- paste(description,
        paste0("Native sex code ", sex_code, " uses the ",
          if (sex_code == 1L) "female" else "male",
          " vector; the unused sex vector is retained in the source file and ignored by SS3."))
    if (x$year[i] < 0) description <- paste(description,
      "The original signed year was negative; its absolute calendar year is stored. SS3 excludes negative-year composition rows from its active working matrix.")
    if (signed_fleet < 0L) description <- paste(description,
      "The original signed fleet code was negative; its absolute fleet key is stored. SS3 retains the predicted value but excludes this row from the likelihood.")
    if (fleet_code == 6L && is_age && x$length_lower[i] == -1 &&
        x$length_upper[i] == -1)
      description <- paste(description,
        "This is a derived marginal WCGBTS age-composition record included in the input file; it is not an independent observation from the conditional age-at-length records.")
    observation_id <- paste0(if (is_age) "agecomp-" else "lencomp-", i)
    values <- list()
    for (sex in names(sex_values)) {
      values[[length(values) + 1L]] <- make_input(length(bins),
        if (is_fishery) "catch" else "index",
        if (is_age) "frequency_at_age" else "frequency_at_length",
        "native_frequency", sex_values[[sex]], "source frequency",
        year = abs(x$year[i]), age = if (is_age) bins else NA_real_,
        fleet = if (is_fishery) fleet else "",
        survey = if (!is_fishery) fleet else "", sex = sex,
        season = paste0("month ", month), sampling_time = (month - 1) / 12,
        source_reference = source_ref("2021_dover.dat",
          if (is_age) "age-composition data" else "length-composition data"),
        notes = description, observation_id = paste(observation_id, sex, sep = "-"),
        length_bin = if (is_age) NA_real_ else bins,
        length_bin_lower = llo, length_bin_upper = lhi,
        sample_size = x$sample_size[i], age_error = age_err,
        partition = x$partition[i])
    }
    out[[i]] <- do.call(rbind, values)
  }
  do.call(rbind, out)
}
add_input(composition_rows(length_comp))
add_input(composition_rows(age_comp, is_age = TRUE))
age_error_rows <- list()
for (i in seq_along(age_error)) {
  code <- i
  for (j in seq_along(age_error[[i]]$age)) {
    age_error_rows[[length(age_error_rows) + 1L]] <- make_input(1L,
      "biology", "ageing_error_sd", "age_error_sd",
      age_error[[i]]$sd[j], "years", age = age_error[[i]]$age[j],
      age_error = code,
      source_reference = source_ref("2021_dover.dat", "ageing_error"),
      notes = if (code == 1L) "Native age-error standard-deviation vector; code 1 is 2021 CAP." else
        "Native age-error standard-deviation vector; code 2 is 2021 CDFW.")
  }
}
add_input(do.call(rbind, age_error_rows))

report_lines <- readLines(report_output, warn = FALSE)
read_report_table <- function(name, header_pattern) {
  marker <- tail(which(startsWith(trimws(report_lines), paste0(name,
    " report:"))), 1L)
  header <- grep(header_pattern, report_lines, perl = TRUE)
  header <- header[header > marker][1L]
  if (is.na(marker) || is.na(header)) stop("Could not locate report table: ",
    name, call. = FALSE)
  columns <- strsplit(trimws(report_lines[header]), "[[:space:]]+")[[1L]]
  rows <- list()
  for (i in seq.int(header + 1L, length(report_lines))) {
    line <- trimws(report_lines[i])
    if (!nzchar(line) || startsWith(line, "#") || grepl(" report:", line,
        fixed = TRUE)) break
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (length(fields) != length(columns)) break
    rows[[length(rows) + 1L]] <- fields
  }
  if (!length(rows)) stop("No data rows in report table: ", name,
    call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE,
    check.names = FALSE)
  names(out) <- columns
  for (j in seq_along(out)) {
    numeric <- suppressWarnings(as.numeric(out[[j]]))
    if (sum(!is.na(numeric)) == sum(!is.na(out[[j]]))) out[[j]] <- numeric
  }
  out
}
annual <- read_report_table("TIME_SERIES", "^Area Yr Era")
n <- read_report_table("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
b <- read_report_table("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
f <- read_report_table("F_AT_AGE", "^Area Fleet Sex")
catch_age <- read_report_table("CATCH_AT_AGE", "^Area Fleet Sex")
m <- read_report_table("Natural_Mortality", "^Bio_Pattern Sex Settlement Seas")
biology <- read_report_table("Biology_at_age_in_endyr",
  "^Seas Morph Bio_Pattern Sex Settlement Platoon int_Age")
weight <- read_report_table("MEAN_BODY_WT(Begin)", "^Morph Yr Seas")

years <- 1911:2032
model_eras <- c("TIME", "FORE")
keep_population <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
  x$Sex %in% 1:2 & x$BirthSeas == 1 & x$Settlement == 1 &
  x$Platoon == 1 & x$Morph %in% 1:2 & x$Seas == 1 &
  x[["Beg/Mid"]] == "B" & x$Era %in% model_eras & x$Yr %in% years
n <- n[keep_population(n), , drop = FALSE]
b <- b[keep_population(b), , drop = FALSE]
m <- m[m$Bio_Pattern == 1 & m$Sex %in% 1:2 & m$Settlement == 1 &
  m$Seas == 1, , drop = FALSE]
f <- f[f$Area == 1 & f$Fleet %in% 1:2 & f$Sex %in% 1:2 &
  f$Morph %in% 1:2 & f$Seas == 1 & f$Era %in% model_eras & f$Yr %in% years,
  , drop = FALSE]
catch_age <- catch_age[catch_age$Area == 1 & catch_age$Fleet %in% 1:2 &
  catch_age$Morph %in% 1:2 & catch_age$Type == "dead" &
  catch_age$Seas == 1 & catch_age$Era %in% model_eras &
  catch_age$Yr %in% years, , drop = FALSE]
annual <- annual[annual$Area == 1 & annual$Era %in% model_eras &
  annual$Yr %in% years, , drop = FALSE]
weight <- weight[weight$Morph %in% 1:2 & weight$Seas == 1 &
  weight$Yr %in% years, , drop = FALSE]
biology <- biology[biology$Seas == 1 & biology$Morph %in% 1:2 &
  biology$Bio_Pattern == 1 & biology$Settlement == 1 &
  biology$Platoon == 1 & biology$int_Age %in% 0:60 & biology$Sex %in% 1:2,
  , drop = FALSE]
expected_rows <- c(annual = 122L, numbers = 244L, biomass = 244L,
  natural_mortality = 2L, fishing_mortality = 488L, catch_at_age = 488L,
  weight_at_age = 244L, maturity_at_age = 122L)
actual_rows <- c(annual = nrow(annual), numbers = nrow(n), biomass = nrow(b),
  natural_mortality = nrow(m), fishing_mortality = nrow(f),
  catch_at_age = nrow(catch_age), weight_at_age = nrow(weight),
  maturity_at_age = nrow(biology))
if (!identical(actual_rows, expected_rows) ||
    !identical(sort(unique(as.integer(n$Yr))), years) ||
    !identical(sort(unique(as.integer(f$Fleet))), 1:2) ||
    !identical(sort(unique(as.integer(catch_age$Fleet))), 1:2) ||
    !all(n$Morph == n$Sex) || !all(b$Morph == b$Sex) ||
    !all(f$Morph == f$Sex) || !all(catch_age$Morph == catch_age$Sex) ||
    !all(weight$Morph %in% 1:2) || !all(biology$Morph == biology$Sex))
  stop("Report output dimensions differ from the pinned 2021 base run: ",
    paste(names(actual_rows), actual_rows, sep = "=", collapse = ", "),
    call. = FALSE)
age_columns <- as.character(0:60)
long_age <- function(x) {
  z <- as.matrix(x[, age_columns, drop = FALSE])
  list(row = rep(seq_len(nrow(x)), each = length(age_columns)),
    age = rep(as.integer(age_columns), times = nrow(x)),
    value = as.vector(t(z)))
}
n_long <- long_age(n)
b_long <- long_age(b)
m_long <- long_age(m)
f_long <- long_age(f)
catch_long <- long_age(catch_age)
weight_long <- long_age(weight)
surface_key <- function(x, long) {
  sex_column <- if ("Sex" %in% names(x)) "Sex" else "Morph"
  paste(x$Yr[long$row], x[[sex_column]][long$row], long$age, sep = "|")
}
weight_match <- match(surface_key(n, n_long), surface_key(weight, weight_long))
biomass_match <- match(surface_key(n, n_long), surface_key(b, b_long))
if (anyNA(weight_match) || anyNA(biomass_match) ||
    max(abs(n_long$value * weight_long$value[weight_match] -
      b_long$value[biomass_match]) / pmax(1, b_long$value[biomass_match])) > 0.01)
  stop("Reported N, weight, and biomass age surfaces do not reconcile.",
    call. = FALSE)
if (any(abs(m_long$value[m$Sex[m_long$row] == 1] - 0.108) > 1e-8) ||
    any(abs(m_long$value[m$Sex[m_long$row] == 2] - 0.11398) > 1e-5) ||
    !all(biology$Age_Mat >= 0 & biology$Age_Mat <= 1))
  stop("Reported M or maturity surfaces differ from the reviewed model.",
    call. = FALSE)

parse_official_interval_table <- function(lines, start_pattern, end_pattern) {
  start <- grep(start_pattern, lines, perl = TRUE)
  end <- grep(end_pattern, lines, perl = TRUE)
  if (length(start) != 1L || length(end) != 1L || end <= start)
    stop("Could not locate official interval table.", call. = FALSE)
  segment <- lines[seq.int(start + 1L, end - 1L)]
  rows <- lapply(segment, function(line) strsplit(trimws(line),
    "[[:space:]]+")[[1L]])
  rows <- rows[lengths(rows) == 7L]
  rows <- rows[vapply(rows, function(x) grepl("^20[0-9]{2}$", x[1L]), logical(1L))]
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "value", "lwr", "upr", "extra1", "extra2", "extra3")
  for (name in names(out)) out[[name]] <- as.numeric(out[[name]])
  out
}
assessment_text <- readLines(report_text, warn = FALSE)
spawning_ci <- parse_official_interval_table(assessment_text,
  "^Table ii: Estimated recent trend in spawning biomass",
  "Figure ii: Estimated time series of spawning biomass")
recruitment_ci <- parse_official_interval_table(assessment_text,
  "^Table iii: Estimated recent trend in recruitment",
  "Figure iv: Estimated time series of age-0 recruits")
if (nrow(spawning_ci) != 11L || nrow(recruitment_ci) != 11L ||
    !identical(as.integer(spawning_ci$year), 2011:2021) ||
    !identical(as.integer(recruitment_ci$year), 2011:2021))
  stop("Official recent-series interval tables do not cover 2011-2021.",
    call. = FALSE)
match_spawn <- match(spawning_ci$year, annual$Yr)
match_recruit <- match(recruitment_ci$year, annual$Yr)
if (anyNA(match_spawn) || anyNA(match_recruit) ||
    any(abs(annual$SpawnBio[match_spawn] - spawning_ci$value) > 1.01) ||
    any(abs(annual$Recruit_0[match_recruit] - recruitment_ci$value) > 1.01))
  stop("Official report interval values do not match the pinned model outputs.",
    call. = FALSE)
spawn_lwr <- spawn_upr <- rep(NA_real_, nrow(annual))
recruit_lwr <- recruit_upr <- rep(NA_real_, nrow(annual))
spawn_idx <- match(annual$Yr, spawning_ci$year)
recruit_idx <- match(annual$Yr, recruitment_ci$year)
use <- !is.na(spawn_idx)
spawn_lwr[use] <- spawning_ci$lwr[spawn_idx[use]]
spawn_upr[use] <- spawning_ci$upr[spawn_idx[use]]
use <- !is.na(recruit_idx)
recruit_lwr[use] <- recruitment_ci$lwr[recruit_idx[use]]
recruit_upr[use] <- recruitment_ci$upr[recruit_idx[use]]

output_rows <- list()
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
sex_names <- c("1" = "female", "2" = "male")
report_ref <- "Dover_Sole_2021_Model_Files.zip; Report.sso"
era_note <- function(era) ifelse(era == "FORE",
  "Stock Synthesis forecast output after the terminal fitted year 2020; no uncertainty is supplied for these rows.",
  "Stock Synthesis fitted historical output.")
for (spec in list(
  list("biomass", "total_biomass", annual$Bio_all, "metric tonnes",
    "TIME_SERIES report:16", "Total model biomass."),
  list("biomass", "summary_biomass_age3plus", annual$Bio_smry,
    "metric tonnes", "TIME_SERIES report:16",
    "Source Bio_smry summary biomass; the report header identifies a 3+ summary age."),
  list("biomass", "spawning_biomass", annual$SpawnBio, "metric tonnes",
    "TIME_SERIES report:16", "Spawning biomass; official Table ii reports 95% intervals for 2011-2021."),
  list("recruitment", "recruitment", annual$Recruit_0, "thousand fish",
    "TIME_SERIES report:16", "Age-0 recruitment; official Table iii reports 95% intervals for 2011-2021."))) {
  value <- spec[[3L]]
  lower <- upper <- rep(NA_real_, nrow(annual))
  source_type <- rep("native_model", nrow(annual))
  reference <- rep(paste(report_ref, spec[[5L]], sep = "; "), nrow(annual))
  if (spec[[2L]] == "spawning_biomass") {
    lower <- spawn_lwr; upper <- spawn_upr
    use <- !is.na(lower)
    source_type[use] <- "official_table"
    reference[use] <- "2021 US West Coast Dover Sole assessment report, Table ii"
  }
  if (spec[[2L]] == "recruitment") {
    lower <- recruit_lwr; upper <- recruit_upr
    use <- !is.na(lower)
    source_type[use] <- "official_table"
    reference[use] <- "2021 US West Coast Dover Sole assessment report, Table iii"
  }
  notes <- paste(spec[[6L]], era_note(annual$Era))
  add_output(make_output(nrow(annual), spec[[1L]], spec[[2L]], value,
    spec[[4L]], year = annual$Yr, lwr = lower, upr = upper,
    source_type = source_type, source_reference = reference, notes = notes))
}
add_output(make_output(length(n_long$value), "population", "numbers_at_age",
  n_long$value, "thousand fish", year = n$Yr[n_long$row], age = n_long$age,
  sex = unname(sex_names[as.character(n$Sex[n_long$row])]),
  source_reference = paste(report_ref, "NUMBERS_AT_AGE report:35", sep = "; "),
  notes = paste("Beginning-of-year numbers at age; report age columns 0-60 are retained.",
    era_note(n$Era[n_long$row]))))
add_output(make_output(length(b_long$value), "biomass", "biomass_at_age",
  b_long$value, "metric tonnes", year = b$Yr[b_long$row], age = b_long$age,
  sex = unname(sex_names[as.character(b$Sex[b_long$row])]),
  source_reference = paste(report_ref, "BIOMASS_AT_AGE report:36", sep = "; "),
  notes = paste("Beginning-of-year biomass at age; report age columns 0-60 are retained.",
    era_note(b$Era[b_long$row]))))
add_output(make_output(length(m_long$value), "mortality",
  "natural_mortality_at_age", m_long$value, "per year", age = m_long$age,
  sex = unname(sex_names[as.character(m$Sex[m_long$row])]),
  source_reference = paste(report_ref, "Natural_Mortality report:43", sep = "; "),
  notes = "Age-constant M by sex. Female M is fixed at 0.108 per year; male M is estimated and reported as 0.11398 per year."))
add_output(make_output(length(f_long$value), "mortality",
  "fishing_mortality_at_age", f_long$value, "per year",
  year = f$Yr[f_long$row], age = f_long$age,
  fleet = unname(fleet_names[as.character(f$Fleet[f_long$row])]),
  sex = unname(sex_names[as.character(f$Sex[f_long$row])]),
  source_reference = paste(report_ref, "F_AT_AGE report:39", sep = "; "),
  notes = paste("Fleet-specific fishing mortality at age.", era_note(f$Era[f_long$row]))))
add_output(make_output(length(catch_long$value), "catch", "numbers_at_age",
  catch_long$value, "thousand fish", year = catch_age$Yr[catch_long$row],
  age = catch_long$age,
  fleet = unname(fleet_names[as.character(catch_age$Fleet[catch_long$row])]),
  sex = unname(sex_names[as.character(catch_age$Morph[catch_long$row])]),
  source_reference = paste(report_ref, "CATCH_AT_AGE report:40", sep = "; "),
  notes = paste("Model-estimated dead catch numbers at age; this is an output, not observed catch-at-age.",
    era_note(catch_age$Era[catch_long$row]))))
add_output(make_output(length(weight_long$value), "biology", "weight_at_age",
  weight_long$value, "kg per fish", year = weight$Yr[weight_long$row],
  age = weight_long$age,
  sex = unname(sex_names[as.character(weight$Morph[weight_long$row])]),
  source_reference = paste(report_ref, "MEAN_BODY_WT(Begin) report:48", sep = "; "),
  notes = paste("Model-generated beginning-of-year body weight at age; not an observed weight-at-age input.",
    ifelse(weight$Yr[weight_long$row] > 2020,
      "Stock Synthesis forecast output after the terminal fitted year 2020; no uncertainty is supplied for these rows.",
      "Stock Synthesis fitted historical output."))))
add_output(make_output(nrow(biology), "biology", "maturity_at_age",
  biology$Age_Mat, "proportion", year = 2020L, age = biology$int_Age,
  sex = unname(sex_names[as.character(biology$Sex)]),
  source_reference = paste(report_ref, "Biology_at_age_in_endyr report:47", sep = "; "),
  notes = "Model-generated terminal-year age-maturity output from the length-based maturity function; not an observed maturity-at-age input."))
total_n <- aggregate(n_long$value, list(year = n$Yr[n_long$row]), sum)
add_output(make_output(nrow(total_n), "population", "total_numbers", total_n$x,
  "thousand fish", year = total_n$year, source_type = "derived_source_output",
  source_reference = paste(report_ref, "NUMBERS_AT_AGE report:35", sep = "; "),
  notes = "Derived by summing reported beginning-of-year N across sexes and ages 0-60; no uncertainty is calculated."))

source_ref <- "Dover_Sole_2021_Model_Files.zip; 2021_dover.dat and 2021_dover.ctl"
for (i in seq_len(nrow(fleet_info))) {
  add_assumption("fleet", "fleet_configuration",
    paste0("type=", fleet_info$type[i], "; timing=", fleet_info$timing[i],
      "; area=", fleet_info$area[i], "; units=", fleet_info$units[i],
      "; catch multiplier=", fleet_info$catch_mult[i]),
    "2021_dover.dat; fleetinfo", fleet = fleet_info$name[i],
    notes = paste("Native SS3 fleet code", i,
      if (fleet_info$type[i] == 1) "is a commercial fishery." else
        "is a survey/index fleet."))
}
for (i in seq_len(nrow(index_info))) {
  code <- as.integer(index_info$fleet[i])
  add_assumption("index", "native_index_likelihood",
    paste0("units=", index_info$units[i], "; error_type=", index_info$error[i],
      "; sd_report=", index_info$sd_report[i]),
    "2021_dover.dat; CPUE fleet configuration",
    "Native codes are retained; no physical scale multiplier or error-distribution conversion is inferred.",
    survey = unname(fleet_names[as.character(code)]))
}
add_assumption("model", "model_run",
  "Official 2021 benchmark assessment; Stock Synthesis 3.30.16.02",
  paste(report_file, "Dover_Sole_2021_Model_Files.zip; Report.sso and ss_summary.sso", sep = "; "),
  "Input data through 2020; model Report.sso includes fitted TIME rows and forecasts through 2032.")
add_assumption("model", "dimensions",
  "One area; two sexes; one annual season; 60 maximum age; report age surfaces 0-60",
  source_ref, "Native model age-composition bins are 1-60; the first and last bins are model accumulators.")
add_assumption("model", "fit_diagnostics",
  "Final phase 6; 1,185 iterations; final gradient 5.48845e-05",
  "Dover_Sole_2021_Model_Files.zip; ss_summary.sso and Report.sso",
  "The 2021 STAR review describes the base-model convergence diagnostics as good.")
add_assumption("catch", "catch_definition", "Commercial retained catch (landings), supplied as biomass",
  "2021_dover.dat; fleetinfo and Catch data",
  "SS3 distinguishes retained catch/landings from discards; catches are not total dead removals.")
add_assumption("catch", "discard_definition",
  "Two fleet-specific discard series; units code 2 is fraction of total catch; Student-t error with 30 degrees of freedom",
  "2021_dover.dat; discard_fleet_info and discard_data",
  "Discard fractions are on the same biomass or numbers basis as retained catch; retained catch units are biomass.")
add_assumption("biology", "mean_body_weight_data",
  "Native mean-body-weight observations, 2002-2019; Type=2; Partition=1; CV supplied",
  "2021_dover.dat; meanbodywt",
  "Partition 1 denotes the discarded catch; these observed weights are not stock weight-at-age.")
add_assumption("index", "survey_timing",
  "AFSC Slope month 10; Triennial month 7 before 1995 and month 9 thereafter; NWFSC Slope month 9; WCGBTS month 8",
  "2021_dover.dat; fleetinfo and CPUE_data",
  "Input observation months are retained; sampling_time=(month-1)/12 for translated annual timing.")
add_assumption("index", "index_scale",
  "Four aggregate survey-abundance index series; native observations retained without an absolute-unit multiplier",
  "2021_dover.dat; CPUE_data; 2021 assessment report, Sections 2.2 and 2.2.5",
  "Index values and their native se_log are preserved; age compositions are separate observations, not age-specific indices.")
add_assumption("composition", "length_compositions",
  paste(nrow(length_comp), "source rows; native 2 cm bins from 8 to 60 cm"),
  "2021_dover.dat; lencomp",
  "Source frequencies are retained without normalization, by sex, fleet, year, month, and partition.")
add_assumption("composition", "age_compositions",
  paste(nrow(age_comp), "source rows; observed age bins 1-60; marginal and conditional age-at-length data"),
  "2021_dover.dat; agebin_vector and age composition",
  "Raw native frequency vectors, sample sizes, age-error codes, sex, fleet, year sign, and length bounds are preserved. These are composition samples, not catch-at-age inputs or age-specific survey indices.")
add_assumption("composition", "ageing_error_definitions",
  "Code 1: 2021 CAP; code 2: 2021 CDFW; age-specific normal SD vectors retained",
  "2021_dover.dat; ageing_error",
  "The canonical age_error dimension stores the source code; cached native files retain the complete model specification.")
add_assumption("mortality", "natural_mortality",
  "One age-constant scalar per sex; female M fixed at 0.108 per year; male M estimated as an offset",
  "2021_dover.ctl; NatM parameters; Report.sso, Natural_Mortality report:43",
  "The fitted male vector is 0.11398 per year across ages 0-60.")
add_assumption("biology", "growth_and_weight",
  "Sex-specific length-based growth and weight-length relationships",
  "2021_dover.ctl; growth and weight-length parameter sections",
  "Model-generated weight-at-age outputs are not observed stock-weight inputs.")
add_assumption("biology", "maturity_and_fecundity",
  "Female length-logistic maturity (Mat50=32.84 cm; slope=-0.278); fecundity option 2 with fixed parameters",
  "2021_dover.ctl; maturity and fecundity settings",
  "No standalone observed maturity-at-age input is supplied; the terminal-year maturity-at-age surface is a model output.")
add_assumption("recruitment", "spawner_recruit_function",
  "Beverton-Holt; steepness fixed at 0.8; sigmaR fixed at 0.35; ln(R0) estimated",
  "2021_dover.ctl; Spawner-Recruitment; ss_summary.sso")
add_assumption("model", "unexpanded_control_settings",
  "Detailed fleet selectivity, retention, catchability, likelihood weights, and parameter activation remain in the cached native control and summary files",
  "2021_dover.ctl and ss_summary.sso",
  "These settings are not expanded parameter by parameter in the canonical assumptions table; assumptions_status remains partial.")

input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumption_rows)
key <- do.call(paste, c(assumption_data[c("component", "fleet", "survey",
  "sex", "region", "season", "setting")], sep = "\r"))
if (anyDuplicated(key) || any(!nzchar(input_data$source_reference)) ||
    any(!nzchar(output_data$source_reference)))
  stop("Duplicate assumptions or missing input/output provenance.",
    call. = FALSE)

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
stocks <- read_csv(stocks_path)
assessments <- read_csv(assessments_path)
candidate <- read_csv(candidate_path)
inventory <- read_csv(inventory_path)
selected <- read_csv(selected_path)
ci <- which(candidate$candidate_id == candidate_id)
ii <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
si <- which(selected$candidate_unit_id == candidate_unit_id)
if (length(ci) != 1L || length(ii) != 1L || length(si) != 1L ||
    candidate$eligibility[ci] != "eligible" ||
    !candidate$import_status[ci] %in% c("not_started", "partial"))
  stop("Dover sole candidate is missing, duplicated, or not eligible.",
    call. = FALSE)
if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id))
  stop("Dover sole stock or assessment already exists; inspect before importing.",
    call. = FALSE)
first_column <- function(path) {
  fields <- read_fields(path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", length(fields) - 1L)))[[1L]]
}
for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv")))
  if (assessment_id %in% first_column(path))
    stop("Input or output rows already exist for this Dover sole assessment.",
      call. = FALSE)
blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks), list(stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NWFSC", authority_stock_id = "10022",
  scientific_name = "Microstomus pacificus",
  common_name = "Dover sole - U.S. West Coast",
  area = "U.S. West Coast, Washington/Oregon/California",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10022; coastwide U.S. management unit, distinct from Canadian Dover sole."))
report_url <- "https://www.pcouncil.org/documents/2021/10/status-of-dover-sole-microstomus-pacificus-along-the-u-s-west-coast-in-2021.pdf"
model_url <- manifest$url[match(archive_file, manifest$source_file)]
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2021L,
  terminal_year = 2020L, estimate_terminal_year = 2032L,
  assessment_type = "full_benchmark", model_family = "Stock Synthesis",
  model_version = "3.30.16.02", is_current = TRUE, is_applied = TRUE,
  assessment_url = report_url, data_url = model_url, model_url = model_url,
  repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste("Official 2021 U.S. West Coast assessment; source data are fitted through 2020 and Report.sso contains forecasts through 2032.",
    "Native landings, aggregate indices, discard and mean-weight observations, and length/age compositions are retained.",
    "No observed catch-at-age, age-specific survey index, stock weight-at-age, or maturity-at-age input is supplied; fitted age surfaces are outputs.",
    "Published 95% intervals for spawning biomass and recruitment are retained for 2011-2021; age-specific uncertainty is unavailable in the report tables.")))
candidate_row <- candidate[ci, , drop = FALSE]
candidate_row$matched_stock_id <- stock_id
candidate_row$match_status <- "new"
candidate_row$import_status <- "partial"
candidate_row$catch_age_evidence <- "Imported retained catch biomass and native age compositions; no observed catch-at-age input is supplied."
candidate_row$survey_age_evidence <- "Imported four aggregate survey indices and native conditional age-at-length samples; no direct age-specific abundance index is supplied."
candidate_row$weights_evidence <- "Imported discarded-catch mean body-weight observations; stock weight-at-age is a model output derived from length-based growth and weight functions."
candidate_row$maturity_evidence <- "Length-logistic maturity parameters are input; no observed maturity-at-age surface is supplied. Terminal-year age maturity is a model output."
candidate_row$mortality_evidence <- "Female M is fixed at 0.108 per year; male M is estimated as a scalar offset. Reported M-at-age is available for both sexes."
candidate_row$timing_evidence <- "Native month fields are retained; survey months are AFSC Slope 10, Triennial 7/9, NWFSC Slope 9, and WCGBTS 8."
candidate_row$output_evidence <- "Imported N, biomass, M, F, dead catch, weight-at-age and maturity outputs through 2032; published SSB and recruitment intervals are available for 2011-2021."
candidate_row$review_date <- format(Sys.Date(), "%Y-%m-%d")
candidate_row$decision_reason <- "Imported the run-matched 2021 production benchmark from its official assessment report and Stock Synthesis archive."
candidate_row$notes <- "Partial source import completed. Source compositions remain compositions; no fitted model surface is treated as an observed input. See discovery/source_reviews/noaa_pacific_coast_dover_sole.md."
inventory_row <- inventory[ii, , drop = FALSE]
inventory_row$matched_stock_id <- stock_id
inventory_row$import_status <- "partial"
selected_row <- selected[si, , drop = FALSE]
selected_row$curation_status <- "partial_source_import"

replace_csv_row <- function(path, key_column, key_value, row_index, row) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  current <- read_csv(path)
  if (row_index > nrow(current) || as.character(current[[key_column]][row_index]) != key_value)
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L))
    replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L))
    replacement <- replacement[-length(replacement)]
  record <- as.integer(row_index) + 1L
  first <- bounds$start[record]
  last <- bounds$end[record]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L))
    next_byte <- next_byte + 1L
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, replacement, after), path)
  updated <- read_csv(path)
  if (nrow(updated) != nrow(current) ||
      sum(as.character(updated[[key_column]]) == key_value) != 1L)
    stop("Updated CSV failed identity checks: ", basename(path), call. = FALSE)
}
append_rows <- function(path, rows) if (nrow(rows)) utils::write.table(rows,
  file = path, sep = ",", row.names = FALSE, col.names = FALSE, quote = TRUE,
  qmethod = "double", na = "", append = TRUE, eol = "\n")

if (!dry_run) {
  existing_stocks <- read_csv(stocks_path)
  existing_assessments <- read_csv(assessments_path)
  if (stock_id %in% existing_stocks$stock_id ||
      assessment_id %in% existing_assessments$assessment_id)
    stop("The Dover sole assessment is already present; refusing to append duplicates.",
      call. = FALSE)
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), output_data)
  append_rows(file.path(database, "assumptions.csv"), assumption_data)
  replace_candidate_register_row(candidate_path, ci, candidate_row, candidate_id)
  replace_csv_row(inventory_path, "unit_key", paste0("candidate:", candidate_unit_id), ii, inventory_row)
  replace_csv_row(selected_path, "candidate_unit_id", candidate_unit_id, si, selected_row)
}
cat(if (dry_run) "Dry run parsed " else "Imported ", nrow(input_data),
  " input rows, ", nrow(assumption_data), " assumptions, and ",
  nrow(output_data), " output rows for the 2021 NOAA Pacific Coast Dover Sole assessment.\n",
  "Native inputs: catch=", nrow(catch), ", indices=", nrow(index),
  ", discards=", nrow(discard), ", mean weights=", nrow(mean_weight),
  ", length compositions=", nrow(length_comp), ", age compositions=",
  nrow(age_comp), ".\n", sep = "")
