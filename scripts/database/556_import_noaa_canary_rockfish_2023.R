root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_canary_2023")
assessment_id <- "noaa_canary_rockfish_2023"
stock_id <- "noaa_canary_rockfish_pacific_coast"
candidate_unit_id <- "noaa_stocksmart_10415"
candidate_id <- "NOAA:10415"
archive_file <- "canary_rockfish_2023_model_files.zip"
report_file <- "noaa_canary_assessment_2023.pdf"
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
make_rows <- function(fields, values, n) {
  x <- lapply(fields, function(nm) {
    value <- values[[nm]]
    if (is.null(value)) return(rep("", n))
    value <- as.character(value)
    value[is.na(value)] <- ""
    rep_len(value, n)
  })
  names(x) <- fields
  as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
}
input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))

make_input <- function(n, type, measure, basis, value, unit, year = NA_real_,
  year_basis = "calendar_year", age = NA_real_, fleet = "", survey = "",
  sex = "", season = "", sampling_time = NA_real_, source_reference,
  notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = NA_real_,
  source_type = "native_model") {
  make_rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = year_basis, age = age, fleet = fleet, survey = survey,
    sex = sex, region = "U.S. West Coast", season = season,
    sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, notes = notes,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition), n)
}
make_output <- function(n, type, measure, value, unit, year = NA_real_,
  age = NA_real_, age_group = "", fleet = "", sex = "combined",
  se = NA_real_, lwr = NA_real_, upr = NA_real_,
  source_type = "native_model", source_reference, notes = "") {
  make_rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    age_group = age_group, fleet = fleet, survey = "", sex = sex,
    region = "U.S. West Coast", season = "", se = se, lwr = lwr, upr = upr,
    source_type = source_type, source_reference = source_reference,
    notes = notes), n)
}
assumptions <- list()
add_assumption <- function(component, setting, value, source_reference,
  notes = "", fleet = "", survey = "", sex = "") {
  assumptions[[length(assumptions) + 1L]] <<- make_rows(assumption_fields,
    list(assessment_id = assessment_id, component = component, setting = setting,
      value = value, source_reference = source_reference, notes = notes,
      fleet = fleet, survey = survey, sex = sex, region = "U.S. West Coast"), 1L)
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
manifest_path <- file.path(cache, "sources.csv")
manifest <- read_csv(manifest_path)
verify_cached <- function(source_name, path) {
  source <- manifest[!is.na(manifest$cached_file) &
    manifest$cached_file == basename(path), , drop = FALSE]
  if (nrow(source) != 1L || !file.exists(path) ||
      tolower(source$sha256) != sha256_file(path))
    stop("Cached source differs from its manifest: ", source_name, call. = FALSE)
  if ("bytes" %in% names(source) && as.numeric(source$bytes) != file.info(path)$size)
    stop("Cached source size differs from its manifest: ", source_name, call. = FALSE)
  path
}
invisible(verify_cached("assessment PDF", file.path(cache, report_file)))
invisible(verify_cached("native model archive", file.path(cache, archive_file)))
data_file <- file.path(cache, "model_files", "data.ss")
control_file <- file.path(cache, "model_files", "control.ss")
report_output <- file.path(cache, "model_files", "Report.sso")
summary_output <- file.path(cache, "model_files", "ss_summary.sso")
for (path in c(data_file, control_file, report_output, summary_output))
  if (!file.exists(path)) stop("Missing cached native model file: ", basename(path),
    call. = FALSE)

read_numeric_block <- function(lines, marker, n_fields, regex = FALSE) {
  start <- if (regex) grep(marker, trimws(lines), perl = TRUE) else
    which(trimws(lines) == marker)
  if (length(start) != 1L) stop("Expected one data block: ", marker,
    call. = FALSE)
  rows <- list()
  for (i in seq.int(start + 1L, length(lines))) {
    text <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(text)) next
    fields <- strsplit(text, "[[:space:]]+")[[1L]]
    if (fields[1L] == "-9999") break
    if (length(fields) != n_fields)
      stop("Unexpected field count in ", marker, " at line ", i, call. = FALSE)
    values <- suppressWarnings(as.numeric(fields))
    if (anyNA(values)) stop("Invalid numeric value in ", marker, call. = FALSE)
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop("No rows in data block: ", marker, call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}
read_age_bins <- function(lines) {
  marker <- which(trimws(lines) == "#_agebin_vector")
  if (length(marker) != 1L) stop("Could not locate age-bin vector.", call. = FALSE)
  value_line <- marker + 1L
  while (value_line <= length(lines) && !nzchar(trimws(lines[value_line])))
    value_line <- value_line + 1L
  values <- suppressWarnings(as.integer(strsplit(
    trimws(sub("#.*$", "", lines[value_line])), "[[:space:]]+")[[1L]]))
  if (length(values) != 35L || anyNA(values))
    stop("Unexpected age-bin vector.", call. = FALSE)
  values
}
read_fleets <- function(lines) {
  start <- which(trimws(lines) == "#_fleetinfo")
  end <- which(trimws(lines) == "#_Catch data")
  if (length(start) != 1L || length(end) != 1L || end <= start)
    stop("Could not locate fleet configuration.", call. = FALSE)
  rows <- lines[seq.int(start + 1L, end - 1L)]
  rows <- rows[grepl("^[[:space:]]*[0-9]+[[:space:]]", rows)]
  fields <- lapply(rows, function(x)
    strsplit(trimws(sub("#.*$", "", x)), "[[:space:]]+")[[1L]])
  if (any(lengths(fields) < 6L)) stop("Malformed fleet configuration.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, lapply(fields, function(x) x[1:6])),
    stringsAsFactors = FALSE)
  names(out) <- c("type", "timing", "area", "units", "catch_mult", "name")
  for (nm in names(out)[1:5]) out[[nm]] <- as.numeric(out[[nm]])
  out
}
read_index_units <- function(lines) {
  start <- which(trimws(lines) == "#_CPUE_and_surveyabundance_observations")
  end <- which(trimws(lines) == "#_CPUE_data")
  if (length(start) != 1L || length(end) != 1L || end <= start)
    stop("Could not locate index unit table.", call. = FALSE)
  rows <- lines[seq.int(start + 1L, end - 1L)]
  rows <- rows[grepl("^[[:space:]]*[0-9]+[[:space:]]", rows)]
  out <- do.call(rbind, lapply(rows, function(x)
    as.numeric(strsplit(trimws(sub("#.*$", "", x)), "[[:space:]]+")[[1L]])))
  out <- as.data.frame(out, stringsAsFactors = FALSE)
  names(out) <- c("fleet", "units", "error", "sd_report")
  out
}

data_lines <- readLines(data_file, warn = FALSE)
fleet_info <- read_fleets(data_lines)
index_info <- read_index_units(data_lines)
fleet_names <- setNames(fleet_info$name, seq_len(nrow(fleet_info)))
catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "season", "fleet", "catch", "catch_se")
index <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(index) <- c("year", "month", "fleet", "value", "se_log")
length_comp <- read_numeric_block(data_lines, "#_lencomp", 62L)
length_bins <- seq(12, 66, 2)
names(length_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "sample_size", paste0("f", length_bins), paste0("m", length_bins))
age_comp <- read_numeric_block(data_lines,
  "^#_Yr[[:space:]]+Seas[[:space:]]+FltSvy[[:space:]]+Gender[[:space:]]+Part[[:space:]]+Ageerr",
  79L, regex = TRUE)
names(age_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "age_error", "length_lower", "length_upper", "sample_size",
  paste0("f", 1:35), paste0("m", 1:35))

checks <- c(
  fleet_count = nrow(fleet_info) == 31L,
  catch_count = nrow(catch) == 1965L,
  index_unit_count = nrow(index_info) == 31L,
  index_count = nrow(index) == 178L,
  length_composition_count = nrow(length_comp) == 606L,
  age_composition_count = nrow(age_comp) == 3829L,
  catch_years = min(catch$year) == 1892 && max(catch$year) == 2022,
  catch_fleets = identical(sort(unique(as.integer(catch$fleet))), 1:15),
  index_years = min(abs(index$year)) == 1980 && max(abs(index$year)) == 2022,
  index_fleets = all(index$fleet %in% 16:31),
  index_units = all(index_info$units %in% c(1, 32)),
  index_errors = all(index_info$error == 0),
  length_years = min(abs(length_comp$year)) == 1968 && max(abs(length_comp$year)) == 2022,
  length_months = all(length_comp$month == 7),
  length_bins = identical(names(length_comp)[7:62],
    c(paste0("f", length_bins), paste0("m", length_bins))),
  age_years = min(abs(age_comp$year)) == 1980 && max(abs(age_comp$year)) == 2022,
  age_months = all(age_comp$month == 7),
  age_bins = identical(read_age_bins(data_lines), 1:35),
  age_errors = all(age_comp$age_error %in% 1:8),
  catch_units = all(fleet_info$units[1:15] == 1),
  catch_se = all(catch$catch_se == 0.05))
if (!all(checks)) stop("Native data structure checks failed: ",
  paste(names(checks)[!checks], collapse = ", "), call. = FALSE)
if (any(catch$catch < 0) || any(index$value <= 0 | index$se_log <= 0) ||
    any(length_comp$sample_size <= 0) || any(age_comp$sample_size <= 0) ||
    any(as.matrix(length_comp[, paste0("f", seq(12, 66, 2))]) < 0) ||
    any(as.matrix(length_comp[, paste0("m", seq(12, 66, 2))]) < 0) ||
    any(as.matrix(age_comp[, paste0("f", 1:35)]) < 0) ||
    any(as.matrix(age_comp[, paste0("m", 1:35)]) < 0))
  stop("Invalid native input values.", call. = FALSE)

input_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
catch_fleet <- unname(fleet_names[as.character(as.integer(catch$fleet))])
add_input(make_input(nrow(catch), "catch", "total_biomass", "biomass",
  catch$catch, "metric tonnes", year = abs(catch$year), fleet = catch_fleet,
  source_reference = paste0(archive_file, ", data.ss, Catch data"),
  notes = "Native annual total removals. The assessment describes these as landings plus dead discards; catch_se = 0.05 is recorded separately as a model setting."))
for (i in seq_len(nrow(index))) {
  fleet_code <- as.integer(index$fleet[i])
  unit_code <- index_info$units[match(fleet_code, index_info$fleet)]
  series <- unname(fleet_names[as.character(fleet_code)])
  measure <- if (unit_code == 1) "relative_biomass_index" else "relative_abundance_index"
  unit <- if (unit_code == 1)
    "native relative biomass-index units (SS3 unit code 1; multiplier not stated)" else
    "native pre-recruit index units (SS3 unit code 32; standardized catch per tow)"
  season <- paste0("month ", format(index$month[i], trim = TRUE))
  timing <- (index$month[i] - 1) / 12
  note <- paste0("Native aggregate lognormal index. Fleet codes 16-27 are retained legacy entries not used in the 2023 base assessment; fleets 28-31 are the active adult and pre-recruit series. The native signed year was ", index$year[i], "; negative years are provisional and excluded from the working likelihood.")
  add_input(make_input(1L, "index", measure, "index_scale", index$value[i], unit,
    year = abs(index$year[i]), survey = series, season = season,
    sampling_time = timing, source_reference = paste0(archive_file,
      ", data.ss, CPUE_data"), notes = note))
  add_input(make_input(1L, "index", "log_index_sd", "log_scale", index$se_log[i],
    "log-scale standard error", year = abs(index$year[i]), survey = series,
    season = season, sampling_time = timing,
    source_reference = paste0(archive_file, ", data.ss, CPUE_data se_log"),
    notes = "Native log-scale standard error; SS3 error type 0 is lognormal."))
}

composition_rows <- function(x, is_age = FALSE) {
  bins <- if (is_age) 1:35 else seq(12, 66, 2)
  female_cols <- paste0("f", bins)
  male_cols <- paste0("m", bins)
  active_fleets <- if (is_age) c(1:6, 8:9, 11:12, 28:30) else c(1:9, 11:12, 28:30)
  result <- vector("list", nrow(x))
  for (i in seq_len(nrow(x))) {
    sex_code <- as.integer(x$sex_code[i])
    female_values <- as.numeric(x[i, female_cols, drop = TRUE])
    male_values <- as.numeric(x[i, male_cols, drop = TRUE])
    if (sex_code == 3L) {
      sex_vectors <- list(female = female_values, male = male_values)
    } else {
      sex <- switch(as.character(sex_code), "0" = "combined",
        "1" = "female", "2" = "male",
        stop("Unexpected composition sex code.", call. = FALSE))
      if (!isTRUE(all.equal(female_values, male_values, tolerance = 1e-10)))
        stop("Single-sex composition has different duplicate vectors.", call. = FALSE)
      sex_vectors <- setNames(list(female_values), sex)
    }
    signed_fleet <- as.integer(x$fleet[i])
    fleet_code <- abs(signed_fleet)
    fleet_name <- unname(fleet_names[as.character(fleet_code)])
    if (is.na(fleet_name)) stop("Unmapped composition fleet.", call. = FALSE)
    is_fishery <- fleet_info$type[fleet_code] == 1
    conditional <- is_age && (x$length_lower[i] >= 0 || x$length_upper[i] >= 0)
    if (is_age && !conditional && !(x$length_lower[i] == -1 && x$length_upper[i] == -1))
      stop("Unrecognized conditional-age length range.", call. = FALSE)
    base_note <- if (is_age) {
      if (conditional) "Conditional age-at-length frequency from the native age-composition block; Lbin_method=2 makes length limits data-bin indices, not cm."
      else "Marginal age-composition frequency from the native age-composition block."
    } else {
      "Native length-composition frequency; source bins 12-66 are 2 cm lower edges."
    }
    base_note <- paste(base_note,
      "Frequency vectors are preserved without renormalization; native frequency scales vary and sample size is stored separately.")
    if (sex_code == 3L)
      base_note <- paste(base_note, "Native sex code 3 is one joint observation with separate female and male vectors; sample_size is repeated on the sex-labeled rows and must not be added across them.")
    else
      base_note <- paste(base_note, "Native sex codes 0/1/2 provide identical placeholder vectors in the female and male blocks; one copy is retained.")
    if (x$year[i] < 0)
      base_note <- paste(base_note, "Native signed year was negative; the absolute calendar year is stored and SS3 excludes the provisional row from the working likelihood.")
    if (signed_fleet < 0L)
      base_note <- paste(base_note, "Native signed fleet code was negative; SS3 calculates expected values but excludes this composition from the total likelihood.")
    if (fleet_code %in% 16:27)
      base_note <- paste(base_note, "This retained legacy fleet row is not used in the 2023 base assessment.")
    else if (!fleet_code %in% active_fleets)
      base_note <- paste(base_note, "The observation is retained from data.ss but the assessment report does not list this fleet in the active composition likelihood.")
    season <- paste0("month ", format(x$month[i], trim = TRUE))
    input_type <- if (is_fishery) "catch" else "index"
    measure <- if (is_age) "frequency_at_age" else "frequency_at_length"
    observation_base <- paste0(if (is_age) "agecomp-" else "lencomp-", i)
    values <- list()
    for (sex in names(sex_vectors)) {
      note <- paste(base_note,
        if (is_age) paste("Native age error code", x$age_error[i], "is retained.") else "")
      values[[length(values) + 1L]] <- make_input(length(bins), input_type,
        measure, "native_frequency", sex_vectors[[sex]], "source frequency",
        year = abs(x$year[i]), age = if (is_age) bins else NA_real_,
        fleet = if (is_fishery) fleet_name else "",
        survey = if (is_fishery) "" else fleet_name, sex = sex,
        season = season, sampling_time = (x$month[i] - 1) / 12,
        source_reference = paste0(archive_file, ", data.ss, ",
          if (is_age) "age composition" else "length composition"),
        notes = note, observation_id = paste(observation_base, sex, sep = "-"),
        length_bin = if (is_age) NA_real_ else bins,
        length_bin_lower = if (is_age) x$length_lower[i] else bins,
        length_bin_upper = if (is_age) x$length_upper[i] else bins + 2,
        sample_size = x$sample_size[i], age_error = if (is_age) x$age_error[i] else NA_real_,
        partition = x$partition[i])
    }
    result[[i]] <- do.call(rbind, values)
  }
  do.call(rbind, result)
}
add_input(composition_rows(length_comp))
add_input(composition_rows(age_comp, is_age = TRUE))

report_lines <- readLines(report_output, warn = FALSE)
read_report <- function(name, header_pattern) {
  marker <- tail(which(startsWith(trimws(report_lines), paste0(name, " report:"))), 1L)
  header <- grep(header_pattern, report_lines, perl = TRUE)
  header <- header[header > marker][1L]
  ends <- grep(" report:", report_lines, fixed = TRUE)
  end <- ends[ends > header][1L]
  if (is.na(marker) || is.na(header) || is.na(end))
    stop("Could not parse Report.sso table: ", name, call. = FALSE)
  body <- report_lines[header:(end - 1L)]
  body <- body[!grepl("^[[:space:]]*#", body)]
  utils::read.table(text = body, header = TRUE, check.names = FALSE,
    stringsAsFactors = FALSE, quote = "", comment.char = "")
}
long_age <- function(x, columns) data.frame(
  row = rep(seq_len(nrow(x)), each = length(columns)),
  age = rep(as.integer(columns), times = nrow(x)),
  value = as.vector(t(as.matrix(x[, columns, drop = FALSE]))))
age_columns <- as.character(0:40)
years <- 1892:2034
eras <- c("TIME", "FORE")
n <- read_report("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
b <- read_report("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
m <- read_report("Natural_Mortality", "^Area Bio_Pattern Sex")
f <- read_report("F_AT_AGE", "^Area Fleet Sex")
catch_age <- read_report("CATCH_AT_AGE", "^Area Fleet Sex")
annual <- read_report("TIME_SERIES", "^Area Yr Era")
weight <- read_report("MEAN_BODY_WT(Begin)", "^Morph Yr Seas")
biology <- read_report("Biology_at_age_in_endyr", "^Seas Morph Bio_Pattern Sex")
keep_population <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
  x$Sex %in% 1:2 & x$BirthSeas == 1 & x$Settlement == 1 &
  x$Platoon == 1 & x$Morph %in% 1:2 & x$Seas == 1 &
  x[["Beg/Mid"]] == "B" & x$Era %in% eras & x$Yr %in% years
n <- n[keep_population(n), , drop = FALSE]
b <- b[keep_population(b), , drop = FALSE]
m <- m[m$Area == 1 & m$Bio_Pattern == 1 & m$Sex %in% 1:2 &
  m$BirthSeas == 1 & m$Settlement == 1 & m$Platoon == 1 &
  m$Morph %in% 1:2 & m$Seas == 1 & m$Era %in% eras & m$Yr %in% years,
  , drop = FALSE]
f <- f[f$Area == 1 & f$Fleet %in% 1:15 & f$Sex %in% 1:2 &
  f$Morph %in% 1:2 & f$Seas == 1 & f$Era %in% eras & f$Yr %in% years,
  , drop = FALSE]
catch_age <- catch_age[catch_age$Area == 1 & catch_age$Fleet %in% 1:15 &
  catch_age$Sex %in% 1:2 & catch_age$Type == "dead" & catch_age$Morph %in% 1:2 &
  catch_age$Seas == 1 & catch_age$Era %in% eras & catch_age$Yr %in% years,
  , drop = FALSE]
annual <- annual[annual$Area == 1 & annual$Era %in% eras & annual$Yr %in% years,
  , drop = FALSE]
weight <- weight[weight$Morph %in% 1:2 & weight$Seas == 1 & weight$Yr %in% years,
  , drop = FALSE]
biology <- biology[biology$Seas == 1 & biology$Morph %in% 1:2 &
  biology$Bio_Pattern == 1 & biology$Settlement == 1 & biology$Platoon == 1 &
  biology$int_Age %in% 0:40 & biology$Sex %in% 1:2, , drop = FALSE]
actual <- c(numbers = nrow(n), biomass = nrow(b), natural_mortality = nrow(m),
  fishing_mortality = nrow(f), catch_at_age = nrow(catch_age),
  annual = nrow(annual), weight_at_age = nrow(weight), biology_at_age = nrow(biology))
expected <- c(numbers = 286L, biomass = 286L, natural_mortality = 286L,
  fishing_mortality = 4290L, catch_at_age = 4290L, annual = 143L,
  weight_at_age = 286L, biology_at_age = 82L)
if (!identical(actual, expected) ||
    !identical(sort(unique(as.integer(n$Yr))), years) ||
    !identical(sort(unique(as.integer(f$Fleet))), 1:15) ||
    !all(n$Sex %in% 1:2) || !all(m$Sex %in% 1:2) ||
    !all(n$Morph == n$Sex) || !all(b$Morph == b$Sex) ||
    !all(m$Morph == m$Sex) || !all(f$Morph == f$Sex) ||
    !all(catch_age$Morph == catch_age$Sex) ||
    !all(weight$Morph %in% 1:2) || !all(biology$Morph == biology$Sex))
  stop("Report output checks differ from the reviewed run. Observed: ",
    paste(names(actual), actual, sep = "=", collapse = ", "),
    "; expected: ", paste(names(expected), expected, sep = "=", collapse = ", "),
    "; N years: ", min(n$Yr), "-", max(n$Yr), "; F fleets: ",
    paste(sort(unique(as.integer(f$Fleet))), collapse = ","), call. = FALSE)
m_long <- long_age(m, age_columns)
if (!all(abs(m_long$value[m$Sex[m_long$row] == 1] - 0.0779404) < 1e-7) ||
    !all(abs(m_long$value[m$Sex[m_long$row] == 2] - 0.0643) < 1e-7))
  stop("Natural mortality values differ from the pinned base model.", call. = FALSE)
if (!all(biology$Age_Mat >= 0 & biology$Age_Mat <= 1) ||
    anyDuplicated(paste(biology$Sex, biology$int_Age)))
  stop("Biology-at-age output is outside the expected range.", call. = FALSE)

output_rows <- list()
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
report_ref <- paste0(archive_file, ", Report.sso, ")
sex_names <- c("1" = "female", "2" = "male")
age_specs <- list(
  list(n, "population", "numbers_at_age", "thousand fish", "NUMBERS_AT_AGE report:35",
    "Beginning-of-year numbers at age; source report columns 0-40 are retained."),
  list(b, "biomass", "biomass_at_age", "metric tonnes", "BIOMASS_AT_AGE report:36",
    "Beginning-of-year biomass at age; source report columns 0-40 are retained."),
  list(m, "mortality", "natural_mortality_at_age", "per year", "Natural_Mortality report:43",
    "Natural-mortality surface; female M is estimated and male M is fixed at 0.0643 per year."),
  list(catch_age, "catch", "numbers_at_age", "thousand fish", "CATCH_AT_AGE report:40",
    "Model-estimated dead-catch numbers at age by fleet; this is an output, not an observed catch-at-age input."))
for (spec in age_specs) {
  x <- spec[[1L]]
  z <- long_age(x, age_columns)
  note <- ifelse(x$Era[z$row] == "FORE",
    paste(spec[[6L]], "Era FORE denotes management projections after fitted year 2022."),
    spec[[6L]])
  add_output(make_output(nrow(z), spec[[2L]], spec[[3L]], z$value, spec[[4L]],
    year = x$Yr[z$row], age = z$age,
    fleet = if ("Fleet" %in% names(x)) unname(fleet_names[as.character(x$Fleet[z$row])]) else "",
    sex = unname(sex_names[as.character(x$Sex[z$row])]),
    source_reference = paste0(report_ref, spec[[5L]]), notes = note))
}
z <- long_age(f, age_columns)
add_output(make_output(nrow(z), "mortality", "fishing_mortality_at_age", z$value,
  "per year", year = f$Yr[z$row], age = z$age,
  fleet = unname(fleet_names[as.character(f$Fleet[z$row])]),
  sex = unname(sex_names[as.character(f$Sex[z$row])]),
  source_reference = paste0(report_ref, "F_AT_AGE report:39"),
  notes = ifelse(f$Era[z$row] == "FORE",
    "Fleet-specific fishing-mortality output; Era FORE denotes projections after fitted year 2022.",
    "Fleet-specific fishing-mortality output.")))
z <- long_age(weight, age_columns)
add_output(make_output(nrow(z), "biology", "weight_at_age", z$value, "kg per fish",
  year = weight$Yr[z$row], age = z$age,
  sex = unname(sex_names[as.character(weight$Morph[z$row])]),
  source_reference = paste0(report_ref, "MEAN_BODY_WT(Begin) report:48"),
  notes = ifelse(weight$Yr[z$row] > 2022,
    "Model-generated beginning-of-year weight; years after 2022 are projections, not observed weight-at-age inputs.",
    "Model-generated beginning-of-year weight; not an observed weight-at-age input.")))
add_output(make_output(nrow(biology), "biology", "maturity_at_age",
  biology$Age_Mat, "proportion", year = 2022L, age = biology$int_Age,
  sex = unname(sex_names[as.character(biology$Sex)]),
  source_reference = paste0(report_ref, "Biology_at_age_in_endyr report:47"),
  notes = "Model-generated terminal-year age-maturity surface from the fixed age-logistic specification; not a standalone observed maturity-at-age input."))

recruitment_ci <- data.frame(year = 2013:2023,
  lwr = c(2141.07, 1074.34, 1039.05, 1358.40, 618.12, 549.61, 914.58,
    914.62, 1408.69, 1114.56, 1237.02),
  upr = c(3875.83, 2203.74, 2185.58, 2781.17, 1534.08, 1562.91, 3590.84,
    5460.59, 7268.58, 7161.05, 8021.15))
recruitment_estimate <- c(2880.70, 1538.69, 1506.96, 1943.69, 973.78,
  926.82, 1812.21, 2234.81, 3199.87, 2825.14, 3149.97)
recruitment_ci$value <- recruitment_estimate
spawning_ci <- data.frame(year = 2023L, value = 2808.87,
  lwr = 2050.19, upr = 3567.55)
for (measure in c("total_biomass", "summary_biomass_age5plus",
  "spawning_output", "recruitment")) {
  value <- switch(measure, total_biomass = annual$Bio_all,
    summary_biomass_age5plus = annual$Bio_smry,
    spawning_output = annual$SpawnBio, recruitment = annual$Recruit_0)
  unit <- switch(measure, total_biomass = "metric tonnes",
    summary_biomass_age5plus = "metric tonnes", spawning_output = "million eggs",
    recruitment = "thousand fish")
  type <- switch(measure, total_biomass = "biomass",
    summary_biomass_age5plus = "biomass", spawning_output = "biomass",
    recruitment = "recruitment")
  lower <- upper <- rep(NA_real_, nrow(annual))
  source_type <- rep("native_model", nrow(annual))
  reference <- rep(paste0(report_ref, "TIME_SERIES report:16"), nrow(annual))
  if (measure == "summary_biomass_age5plus") {
    note <- "Bio_smry is the source model's age-5+ summary biomass in metric tonnes."
  } else if (measure == "total_biomass") {
    note <- "Bio_all is the source model's total biomass in metric tonnes."
  } else if (measure == "spawning_output") {
    ci_rows <- match(annual$Yr, spawning_ci$year)
    use <- !is.na(ci_rows)
    lower[use] <- spawning_ci$lwr[ci_rows[use]]
    upper[use] <- spawning_ci$upr[ci_rows[use]]
    source_type[use] <- "official_table"
    reference[use] <- "2023 Canary Rockfish assessment report, Table v, p. 9"
    if (sum(use) != 1L || abs(value[use] - spawning_ci$value[ci_rows[use]]) > 0.02)
      stop("2023 spawning output differs from the official table.", call. = FALSE)
    note <- "Native SpawnBio is spawning output in millions of eggs, not SSB. The 2023 95% confidence interval is reported in Table v; forecast values after 2022 are distinguished in notes."
  } else {
    ci_rows <- match(annual$Yr, recruitment_ci$year)
    use <- !is.na(ci_rows)
    lower[use] <- recruitment_ci$lwr[ci_rows[use]]
    upper[use] <- recruitment_ci$upr[ci_rows[use]]
    source_type[use] <- "official_table"
    reference[use] <- "2023 Canary Rockfish assessment report, Table iii, p. vii"
    if (sum(use) != nrow(recruitment_ci) ||
        any(abs(value[use] - recruitment_ci$value[ci_rows[use]]) > 0.02))
      stop("Recruitment series differs from official Table iii.", call. = FALSE)
    note <- "Native Recruit_0 is age-0 recruitment in thousands of fish. The report's 95% confidence limits are retained for 2013-2023 only."
  }
  note <- ifelse(annual$Yr > 2022,
    paste(note, "Era FORE values are management projections, not fitted historical years."), note)
  add_output(make_output(nrow(annual), type, measure, value, unit,
    year = annual$Yr, lwr = lower, upr = upper, source_type = source_type,
    source_reference = reference, notes = note))
}
n_long <- long_age(n, age_columns)
total_n <- aggregate(n_long$value, list(year = n$Yr[n_long$row]), sum)
add_output(make_output(nrow(total_n), "population", "total_numbers", total_n$x,
  "thousand fish", year = total_n$year, source_type = "derived_source_output",
  source_reference = paste0(report_ref, "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing beginning-of-year N across sexes and ages 0-40 for each year. No uncertainty is calculated."))

source_ref <- paste0(archive_file, ", data.ss and control.ss; ")
for (i in seq_len(nrow(fleet_info))) {
  fleet_note <- if (i %in% 16:27)
    "Retained legacy fleet configuration; the 2023 assessment report says fleets 16-27 were not used in the final model."
  else if (i %in% 28:31) "Active survey/index fleet in the 2023 base assessment."
  else "Fishery catch fleet; fleet identity retains state and gear group."
  add_assumption("fleet", "native_fleet_configuration",
    paste0("type=", fleet_info$type[i], "; timing=", fleet_info$timing[i],
      "; area=", fleet_info$area[i], "; units=", fleet_info$units[i],
      "; catch multiplier=", fleet_info$catch_mult[i]),
    source_reference = paste0(archive_file, ", data.ss, fleetinfo"),
    fleet = fleet_info$name[i], notes = paste("Native SS3 fleet code", i, fleet_note))
}
add_assumption("model", "model_run", "Official 2023 full assessment; Stock Synthesis 3.30.21",
  paste0(report_file, ", cover; ", archive_file, ", ss_summary.sso"),
  "Report published in 2024; the model is fitted through 2022 and projects through 2034.")
add_assumption("model", "dimensions", "One coastwide area; two sexes; one annual season; Report.sso columns age 0-40",
  source_ref, "The assessment report describes observed/model age groups 1-35 and age 35+ composition bins; the native Report.sso surfaces have columns 0-40, which are preserved without pooling.")
add_assumption("model", "assessment_years", "1892-2022 fitted; 2023-2034 projected",
  paste0(report_ref, "TIME_SERIES report:16"), "FORE rows are kept but are not fitted historical estimates.")
add_assumption("model", "spawning_timing", "January spawning; annual time step",
  paste0(archive_file, ", data.ss, spawn_month and control.ss"),
  "The native data file specifies spawn month 1.")
add_assumption("catch", "catch_definition", "Total removals by 15 fishery fleets; biomass units",
  paste0(report_file, ", Section 2.2; ", archive_file, ", data.ss, Catch data and fleetinfo"),
  "The report describes catch as landings plus dead discards. Native values are retained in metric tonnes; no observed catch-at-age is supplied.")
add_assumption("catch", "catch_se_field", "0.05 for each native catch row",
  paste0(archive_file, ", data.ss, Catch data"),
  "The native catch_se field is preserved as supplied; no conversion to another error scale is applied.")
add_assumption("index", "native_index_units", "Survey unit codes 1 (relative biomass scale) and 32 (pre-recruit special index)",
  paste0(archive_file, ", data.ss, CPUE unit table"),
  "Index multipliers are not stated; no conversion to abundance-at-age or physical biomass is made.")
add_assumption("index", "index_likelihood", "Error type 0 lognormal; input log standard errors retained",
  paste0(archive_file, ", data.ss, CPUE unit table and CPUE_data"))
add_assumption("index", "active_series", "Fleet 28 WCGBTS; fleet 29 early Triennial; fleet 30 late Triennial; fleet 31 pre-recruit",
  paste0(report_file, ", Section 3.3.5; ", archive_file, ", control.ss, Q_setup"),
  "Fleets 16-27 remain in the file as legacy data but are not used in the 2023 assessment.")
add_assumption("index", "catchability", "WCGBTS and pre-recruit q solved analytically; Triennial q estimated and shared across early/late series",
  paste0(report_file, ", Section 3.4.1.3; ", archive_file, ", control.ss, Q_setup"),
  "Pre-recruit index has an additional estimated standard deviation.")
add_assumption("index", "survey_timing", "Native observation month retained; sampling_time=(month-1)/12",
  paste0(archive_file, ", data.ss, CPUE_data and composition blocks"),
  "Model observations use month 7; the resulting fractional-year value is 0.5 and follows the supplied model code, not an annual survey-date average.")
add_assumption("composition", "length_composition", "606 native records; 2 cm bins with labels 12-66; sexes and source sample sizes retained",
  paste0(archive_file, ", data.ss, lencomp"),
  "Frequency values are preserved without normalization; sex code 3 carries one joint sample with separate female/male vectors.")
add_assumption("composition", "age_composition", "3,829 native records; observed age bins 1-35; marginal and conditional age-at-length data",
  paste0(archive_file, ", data.ss, agebin_vector and age composition"),
  "Age error codes 1-8, sample sizes, signed year/fleet, and Lbin limits are retained. Lbin_method=2 makes conditional-age limits data-bin indices, not cm.")
add_assumption("composition", "ageing_error_matrices", "Eight native ageing-error definitions; codes 1-8",
  paste0(archive_file, ", data.ss, ageing_error"),
  "Matrices remain in the cached source file; the canonical schema does not expose both true-age and observed-age dimensions.")
add_assumption("composition", "composition_likelihood", "Multinomial age and length compositions with assessment data weights",
  paste0(report_file, ", Section 3.3.6.1"),
  "Native frequency vectors and sample sizes are preserved; assessment weighting is not recomputed.")
add_assumption("composition", "negative_year_codes", "Negative signed years are retained as provisional source rows",
  paste0(archive_file, ", data.ss; Stock Synthesis 3.30 User Manual"),
  "SS3 excludes observations with negative year values from its working likelihood arrays; the canonical year stores the absolute calendar year and the original sign in notes.")
add_assumption("composition", "negative_fleet_codes", "Negative signed fleet IDs are retained on composition observations",
  paste0(archive_file, ", data.ss; Stock Synthesis 3.30 User Manual"),
  "SS3 calculates expected values for these compositions but excludes their likelihood from the total objective; the sign is preserved in notes.")
add_assumption("mortality", "natural_mortality", "One age-constant scalar per sex; female estimated and male fixed at 0.0643 per year",
  paste0(archive_file, ", control.ss and Report.sso, Natural_Mortality report:43"),
  "The fitted female value is reported in the model output as 0.0779404 per year.")
add_assumption("biology", "growth_model", "Sex-specific von Bertalanffy growth model",
  paste0(archive_file, ", control.ss, GrowthModel and growth_parms"),
  "Growth parameters are estimated; reported beginning-of-year weights-at-age are model-generated outputs.")
add_assumption("biology", "maturity", "Fixed age-logistic maturity; first mature age 2; female Mat50=10.87 and slope=-0.688",
  paste0(archive_file, ", control.ss, maturity and growth_parms"),
  "The model-generated Age_Mat surface is included as an output; it is not a separate observed maturity input.")
add_assumption("biology", "fecundity", "Egg production follows alpha times length raised to beta; parameters fixed",
  paste0(archive_file, ", control.ss, fecundity option and growth_parms"),
  "Native spawning output is reported in millions of eggs and is not SSB.")
add_assumption("recruitment", "spawner_recruit_function", "Standard Beverton-Holt; ln(R0) estimated",
  paste0(archive_file, ", control.ss, Spawner-Recruitment"))
add_assumption("recruitment", "steepness_and_sigma", "Steepness=0.72 fixed; sigmaR=0.5 fixed",
  paste0(archive_file, ", control.ss, SR_BH_steep and SR_sigmaR"),
  "Recruitment deviations are estimated from 1892 through 2022.")

input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumptions)
assumption_key <- do.call(paste, c(assumption_data[c("component", "fleet",
  "survey", "sex", "region", "season", "setting")], sep = "\r"))
if (anyDuplicated(assumption_key)) stop("Duplicate assumption keys are present.",
  call. = FALSE)
if (anyNA(input_data$source_reference) || any(!nzchar(input_data$source_reference)) ||
    anyNA(output_data$source_reference) || any(!nzchar(output_data$source_reference)))
  stop("An input or output lacks a source reference.", call. = FALSE)

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
  stop("Candidate is missing, duplicated, or not eligible.", call. = FALSE)
if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id))
  stop("Canary rockfish records already exist; inspect before importing.", call. = FALSE)
first_column <- function(path) {
  fields <- read_fields(path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", length(fields) - 1L)))[[1L]]
}
for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv")))
  if (assessment_id %in% first_column(path))
    stop("Observations already exist for this assessment.", call. = FALSE)
blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks), list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "10415", scientific_name = "Sebastes pinniger",
  common_name = "Canary rockfish - U.S. West Coast", area = "U.S. West Coast",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10415. U.S. West Coast management unit; distinct from the Canadian British Columbia canary rockfish record."))
report_url <- "https://repository.library.noaa.gov/view/noaa/72904"
model_url <- manifest$url[match(archive_file, manifest$cached_file)]
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2022L, estimate_terminal_year = 2034L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.21", is_current = TRUE, is_applied = TRUE,
  assessment_url = report_url, data_url = model_url, model_url = model_url,
  repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste("Official 2023 production assessment, published in 2024; fitted through 2022 with management projections through 2034.",
    "Native catch, aggregate indices, composition data and fitted age-specific N/B/M/F/catch outputs are preserved.",
    "No observed catch-at-age or direct age-specific survey index is supplied; compositions remain separate samples.",
    "The report provides 95% intervals for recent recruitment and 2023 spawning output, but not for age-specific surfaces.")))
candidate_row <- candidate[ci, , drop = FALSE]
candidate_row$matched_stock_id <- stock_id
candidate_row$match_status <- "new"
candidate_row$import_status <- "partial"
candidate_row$catch_age_evidence <- "Native 2023 model supplies total catch biomass by fleet plus marginal fishery age compositions; it does not fit observed catch-at-age."
candidate_row$survey_age_evidence <- "Aggregate adult survey indices and a special pre-recruit index are supplied; survey conditional age-at-length compositions are separate likelihood samples, not age-specific abundance indices."
candidate_row$weights_evidence <- "Beginning-of-year weight-at-age is model-generated in Report.sso; no standalone observed weight-at-age input was identified."
candidate_row$maturity_evidence <- "Fixed age-logistic maturity parameters are supplied in control.ss; Report.sso includes a derived age-maturity surface."
candidate_row$mortality_evidence <- "Female scalar natural mortality is estimated; male M is fixed at 0.0643 per year."
candidate_row$timing_evidence <- "Native index and composition rows use month 7; sampling_time=(month-1)/12 is retained as a model timing code."
candidate_row$output_evidence <- "Report.sso includes N/B/M, fleet F, dead catch-at-age, annual biomass, spawning output and recruitment through projection year 2034; the report provides recent recruitment and 2023 spawning-output intervals."
candidate_row$review_date <- format(Sys.Date(), "%Y-%m-%d")
candidate_row$decision_reason <- "Imported the official 2023 U.S. West Coast Canary Rockfish assessment from its run-matched Stock Synthesis archive and report."
candidate_row$notes <- "Partial source import completed. Raw compositions are not converted to catch-at-age or age-specific survey indices; source age-error matrices are referenced in the cached native file but not expanded into the canonical table schema."
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
  qmethod = "double", na = "", append = TRUE, eol = "\n", fileEncoding = "UTF-8")

if (!dry_run) {
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
  " inputs, ", nrow(assumption_data), " assumptions, and ", nrow(output_data),
  " outputs for the 2023 NOAA Pacific Coast Canary Rockfish assessment.\n", sep = "")
