root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_petrale_10011")
assessment_id <- "noaa_petrale_sole_pacific_coast_2023"
projection_id <- "noaa_petrale_sole_pacific_coast_2025_projection"
stock_id <- "noaa_petrale_sole_pacific_coast"
candidate_id <- "NOAA:10011"
candidate_unit_id <- "noaa_stocksmart_10011"
report_file <- "petrale_2023_report.pdf"
archive_file <- "petrale_2023_models.zip"
projection_file <- "petrale_2025_projection.pdf"
data_file <- file.path(cache, "inputs", "petrale_data.ss")
control_file <- file.path(cache, "inputs", "petrale_control.ss")
report_output <- file.path(cache, "outputs", "Report.sso")
report_text <- file.path(cache, "petrale_2023_report.txt")
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

make_input <- function(n, type, measure, basis, value, unit, year = NA_real_,
  age = NA_real_, fleet = "", survey = "", sex = "", season = "",
  sampling_time = NA_real_, source_type = "native_model", source_reference,
  transformation = "", notes = "", observation_id = "",
  length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = NA_real_) {
  make_rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = if (all(is.na(year))) "" else "calendar_year", age = age,
    fleet = fleet, survey = survey, sex = sex, region = "Pacific Coast",
    season = season, sampling_time = sampling_time, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition), n)
}
make_projection_input <- function(year, value, scenario, note) {
  make_rows(input_fields, list(assessment_id = projection_id, type = "catch",
    measure = "catch_biomass", basis = "biomass", value = value,
    unit = "metric tonnes", year = year, year_basis = "calendar_year",
    region = "Pacific Coast", source_type = "official_table",
    source_reference = paste("2025 catch-only projection,", scenario),
    transformation = "Transcribed from the published projection table.",
    notes = note, observation_id = scenario), 1L)
}
make_output <- function(n, assessment = assessment_id, type, measure, value,
  unit, year = NA_real_, age = NA_real_, fleet = "", sex = "combined",
  region = "Pacific Coast", se = NA_real_, lwr = NA_real_, upr = NA_real_,
  source_type = "native_model", source_reference, notes = "", scenario = "") {
  make_rows(output_fields, list(assessment_id = assessment, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    fleet = fleet, sex = sex, region = region, season = "", se = se,
    lwr = lwr, upr = upr, source_type = source_type,
    source_reference = source_reference, notes = notes, scenario = scenario), n)
}
make_assumption <- function(assessment, component, setting, value,
  source_reference, notes = "", fleet = "", survey = "", sex = "") {
  make_rows(assumption_fields, list(assessment_id = assessment,
    component = component, fleet = fleet, survey = survey, sex = sex,
    region = "Pacific Coast", setting = setting, value = value,
    source_reference = source_reference, notes = notes), 1L)
}

sha256_file <- function(path) {
  hash <- tools::sha256sum(path)
  if (length(hash) != 1L || is.na(hash)) stop("Could not hash file: ", path,
    call. = FALSE)
  toupper(unname(hash))
}
source_manifest <- read_csv(file.path(cache, "sources.csv"))
verify_cached <- function(path, source_name) {
  source <- source_manifest[source_manifest$file == source_name, , drop = FALSE]
  if (nrow(source) != 1L || !file.exists(path) ||
      toupper(source$sha256) != sha256_file(path) ||
      ("bytes" %in% names(source) &&
        as.numeric(source$bytes) != file.info(path)$size))
    stop("Cached source differs from its manifest: ", source_name,
      call. = FALSE)
  path
}
invisible(verify_cached(file.path(cache, report_file), report_file))
invisible(verify_cached(file.path(cache, archive_file), archive_file))
invisible(verify_cached(file.path(cache, projection_file), projection_file))
for (path in c(data_file, control_file, report_output, report_text))
  if (!file.exists(path)) stop("Missing cached assessment file: ", path,
    call. = FALSE)

read_numeric_block <- function(lines, header_pattern, n_fields) {
  header <- grep(header_pattern, trimws(lines), perl = TRUE)
  if (length(header) != 1L) stop("Expected one source block: ",
    header_pattern, call. = FALSE)
  rows <- list()
  for (i in seq.int(header + 1L, length(lines))) {
    line <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(line)) next
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (fields[1L] == "-9999") break
    values <- suppressWarnings(as.numeric(fields))
    if (length(values) != n_fields || anyNA(values))
      stop("Malformed row in source block ", header_pattern, " at line ", i,
        call. = FALSE)
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop("No source rows in block: ", header_pattern,
    call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}
read_report_table <- function(lines, name, header_pattern) {
  marker <- tail(which(startsWith(trimws(lines), paste0(name, " report:"))), 1L)
  header <- grep(header_pattern, lines, perl = TRUE)
  header <- header[header > marker][1L]
  if (length(marker) != 1L || length(header) != 1L || is.na(header))
    stop("Could not locate report table: ", name, call. = FALSE)
  columns <- strsplit(trimws(lines[header]), "[[:space:]]+")[[1L]]
  rows <- list()
  for (i in seq.int(header + 1L, length(lines))) {
    line <- trimws(lines[i])
    if (!nzchar(line) || startsWith(line, "#") ||
        grepl(" report:", line, fixed = TRUE)) break
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (length(fields) != length(columns)) break
    rows[[length(rows) + 1L]] <- fields
  }
  if (!length(rows)) stop("No report rows in table: ", name, call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE,
    check.names = FALSE)
  names(out) <- columns
  for (j in seq_along(out)) {
    values <- suppressWarnings(as.numeric(out[[j]]))
    if (sum(!is.na(values)) == sum(!is.na(out[[j]]))) out[[j]] <- values
  }
  out
}
read_vector <- function(lines, header_pattern) {
  header <- grep(header_pattern, trimws(lines), perl = TRUE)
  if (length(header) != 1L) stop("Could not locate vector: ", header_pattern,
    call. = FALSE)
  for (i in seq.int(header + 1L, length(lines))) {
    line <- trimws(sub("#.*$", "", lines[i]))
    if (!nzchar(line)) next
    value <- suppressWarnings(as.numeric(strsplit(line,
      "[[:space:]]+")[[1L]]))
    if (anyNA(value)) stop("Malformed vector after: ", header_pattern,
      call. = FALSE)
    return(value)
  }
  stop("Missing values after: ", header_pattern, call. = FALSE)
}

data_lines <- readLines(data_file, warn = FALSE)
fleet_start <- which(trimws(data_lines) == "#_fleetinfo")
fleet_end <- grep("^#_Catch data", trimws(data_lines))
if (length(fleet_start) != 1L || length(fleet_end) != 1L ||
    fleet_end <= fleet_start) stop("Could not locate fleet configuration.",
  call. = FALSE)
fleet_lines <- data_lines[seq.int(fleet_start + 2L, fleet_end - 1L)]
fleet_lines <- fleet_lines[grepl("^[[:space:]]*[0-9]+[[:space:]]", fleet_lines)]
fleet_table <- lapply(fleet_lines, function(line) {
  fields <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
  if (length(fields) < 6L) stop("Malformed fleet configuration.",
    call. = FALSE)
  fields[1:6]
})
fleet_table <- as.data.frame(do.call(rbind, fleet_table),
  stringsAsFactors = FALSE)
names(fleet_table) <- c("type", "timing", "area", "units", "catch_mult", "name")
for (column in names(fleet_table)[1:5])
  fleet_table[[column]] <- as.numeric(fleet_table[[column]])
fleet_names <- setNames(trimws(fleet_table$name), seq_len(nrow(fleet_table)))
if (!identical(unname(fleet_names), c("North", "South", "Triennial", "WCGBTS")))
  stop("Fleet identities differ from the reviewed assessment.", call. = FALSE)

catch <- read_numeric_block(data_lines,
  "^#_year[[:space:]]+season[[:space:]]+fleet[[:space:]]+catch[[:space:]]+catch_se$", 5L)
names(catch) <- c("year", "season", "fleet", "value", "catch_se")
index <- read_numeric_block(data_lines,
  "^#_year[[:space:]]+seas[[:space:]]+index[[:space:]]+obs[[:space:]]+se_log$", 5L)
names(index) <- c("year", "season", "fleet", "value", "se_log")
discard <- read_numeric_block(data_lines,
  "^#_Yr[[:space:]]+Seas[[:space:]]+Flt[[:space:]]+Discard[[:space:]]+Std_in$", 5L)
names(discard) <- c("year", "season", "fleet", "value", "std_in")
mean_weight <- read_numeric_block(data_lines,
  "^#_Year[[:space:]]+Seas[[:space:]]+Fleet[[:space:]]+Partition[[:space:]]+Type[[:space:]]+Value[[:space:]]+Std_in$", 7L)
names(mean_weight) <- c("year", "season", "fleet", "partition", "type",
  "value", "std_in")
length_comp <- read_numeric_block(data_lines,
  "^#_Yr[[:space:]]+Seas[[:space:]]+FltSvy[[:space:]]+Gender[[:space:]]+Part[[:space:]]+Nsamp", 58L)
names(length_comp) <- c("year", "season", "fleet", "sex_code", "partition",
  "sample_size", paste0("female_", seq_len(26L)),
  paste0("male_", seq_len(26L)))
age_comp <- read_numeric_block(data_lines,
  "^#_Yr[[:space:]]+Seas[[:space:]]+FltSvy[[:space:]]+Gender[[:space:]]+Part[[:space:]]+Ageerr[[:space:]]+Lbin_lo[[:space:]]+Lbin_hi[[:space:]]+Nsamp", 43L)
names(age_comp) <- c("year", "season", "fleet", "sex_code", "partition",
  "age_error", "length_lower", "length_upper", "sample_size",
  paste0("female_", seq_len(17L)), paste0("male_", seq_len(17L)))
length_bins <- read_vector(data_lines, "^#_lbin_vector$")
age_bins <- read_vector(data_lines, "^#_agebin_vector$")
if (!identical(as.integer(length_bins), seq(12L, 62L, 2L)) ||
    !identical(as.integer(age_bins), 1:17))
  stop("Composition bins differ from the reviewed native data file.",
    call. = FALSE)
if (!identical(nrow(catch), 274L) || !identical(nrow(index), 28L) ||
    !identical(nrow(discard), 43L) || !identical(nrow(mean_weight), 40L) ||
    !identical(nrow(length_comp), 177L) || !identical(nrow(age_comp), 809L))
  stop("Native input row counts differ from the pinned assessment run.",
    call. = FALSE)
if (any(catch$value < 0) || any(index$value <= 0) ||
    any(index$se_log <= 0) || any(discard$value < 0 | discard$value > 1) ||
    any(mean_weight$value <= 0) || any(mean_weight$std_in < 0) ||
    any(length_comp$sample_size <= 0) || any(age_comp$sample_size <= 0) ||
    any(as.matrix(length_comp[, paste0("female_", 1:26)]) < 0) ||
    any(as.matrix(length_comp[, paste0("male_", 1:26)]) < 0) ||
    any(as.matrix(age_comp[, paste0("female_", 1:17)]) < 0) ||
    any(as.matrix(age_comp[, paste0("male_", 1:17)]) < 0))
  stop("Native observation values failed range checks.", call. = FALSE)

input_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
source_ref <- function(file, section) paste0(file, "; ", section)
for (i in seq_len(nrow(catch))) {
  fleet <- unname(fleet_names[as.character(as.integer(catch$fleet[i]))])
  year <- abs(catch$year[i])
  season <- paste("model season", as.integer(catch$season[i]))
  add_input(make_input(1L, "catch", "catch_biomass", "biomass",
    catch$value[i], "metric tonnes", year = year, fleet = fleet,
    season = season, source_reference = source_ref("petrale_data.ss", "Catch data"),
    transformation = "Source value copied without rescaling.",
    notes = "Native annual North/South catch. Stock Synthesis models discard observations in a separate section; this is not catch-at-age."))
  add_input(make_input(1L, "catch", "catch_se", "native_scale",
    catch$catch_se[i], "native catch_se", year = year, fleet = fleet,
    season = season, source_reference = source_ref("petrale_data.ss", "Catch data catch_se"),
    notes = "Native catch_se value retained as supplied; no conversion is inferred."))
}
for (i in seq_len(nrow(index))) {
  survey <- unname(fleet_names[as.character(as.integer(index$fleet[i]))])
  month <- as.integer(index$season[i])
  add_input(make_input(1L, "index", "relative_biomass_index", "index_scale",
    index$value[i], "native survey index units", year = abs(index$year[i]),
    survey = survey, season = paste0("month ", month),
    sampling_time = (month - 1) / 12,
    source_reference = source_ref("petrale_data.ss", "CPUE_data"),
    transformation = "Source observation copied without rescaling.",
    notes = paste0("Aggregate survey biomass index; it is not an age-specific index or absolute biomass estimate. Original signed year ", index$year[i], " is retained here.")))
  add_input(make_input(1L, "index", "log_index_sd", "log_scale",
    index$se_log[i], "log-scale standard error", year = abs(index$year[i]),
    survey = survey, season = paste0("month ", month),
    sampling_time = (month - 1) / 12,
    source_reference = source_ref("petrale_data.ss", "CPUE_data se_log"),
    notes = "Native se_log; its likelihood interpretation depends on the fleet configuration in the control file."))
}
for (i in seq_len(nrow(discard))) {
  fleet <- unname(fleet_names[as.character(as.integer(discard$fleet[i]))])
  add_input(make_input(1L, "catch", "discard_fraction", "proportion",
    discard$value[i], "proportion", year = abs(discard$year[i]), fleet = fleet,
    season = paste0("model season ", as.integer(discard$season[i])),
    source_reference = source_ref("petrale_data.ss", "discard_data"),
    notes = "Native discard fraction. The source control declares fraction units; Std_in is retained separately."))
  add_input(make_input(1L, "catch", "discard_fraction_cv", "relative_scale",
    discard$std_in[i], "ratio", year = abs(discard$year[i]), fleet = fleet,
    season = paste0("model season ", as.integer(discard$season[i])),
    source_reference = source_ref("petrale_data.ss", "discard_data Std_in"),
    notes = "Native Std_in coefficient of variation for the discard observation."))
}
for (i in seq_len(nrow(mean_weight))) {
  fleet <- unname(fleet_names[as.character(as.integer(mean_weight$fleet[i]))])
  year <- abs(mean_weight$year[i])
  month <- as.integer(mean_weight$season[i])
  add_input(make_input(1L, "weight", "mean_body_weight", "weight_per_fish",
    mean_weight$value[i], "kg per fish", year = year, fleet = fleet,
    season = paste0("month ", month), sampling_time = (month - 1) / 12,
    partition = mean_weight$partition[i],
    source_reference = source_ref("petrale_data.ss", "meanbodywt"),
    notes = paste0("Native mean-body-weight observation; Type=", mean_weight$type[i],
      " and Partition=", mean_weight$partition[i], " are retained.")))
  add_input(make_input(1L, "weight", "mean_body_weight_cv", "relative_scale",
    mean_weight$std_in[i], "ratio", year = year, fleet = fleet,
    season = paste0("month ", month), sampling_time = (month - 1) / 12,
    partition = mean_weight$partition[i],
    source_reference = source_ref("petrale_data.ss", "meanbodywt Std_in"),
    notes = "Native Std_in retained as the mean-body-weight observation CV."))
}
composition_rows <- function(x, bins, is_age = FALSE) {
  out <- list()
  female_columns <- paste0("female_", seq_along(bins))
  male_columns <- paste0("male_", seq_along(bins))
  for (i in seq_len(nrow(x))) {
    sex_code <- as.integer(x$sex_code[i])
    sex_values <- switch(as.character(sex_code),
      "0" = list(combined = as.numeric(x[i, female_columns, drop = TRUE])),
      "1" = list(female = as.numeric(x[i, female_columns, drop = TRUE])),
      "2" = list(male = as.numeric(x[i, male_columns, drop = TRUE])),
      "3" = list(female = as.numeric(x[i, female_columns, drop = TRUE]),
        male = as.numeric(x[i, male_columns, drop = TRUE])),
      stop("Unexpected native composition sex code.", call. = FALSE))
    signed_fleet <- as.integer(x$fleet[i])
    fleet_code <- abs(signed_fleet)
    fleet_name <- unname(fleet_names[as.character(fleet_code)])
    if (is.na(fleet_name)) stop("Composition fleet is not in fleetinfo.",
      call. = FALSE)
    is_fishery <- fleet_table$type[fleet_code] == 1L
    month <- as.integer(x$season[i])
    year <- abs(x$year[i])
    observation_id <- paste0(if (is_age) "agecomp-" else "lencomp-",
      sprintf("%04d", i))
    notes <- if (is_age) {
      if (x$length_lower[i] >= 0 || x$length_upper[i] >= 0)
        "Native conditional age-at-length frequencies; source length limits are in cm."
      else "Native marginal age-composition frequencies; source length limits are -1,-1."
    } else "Native length-composition frequencies; source bins use 2 cm lower edges."
    notes <- paste(notes, "Values are copied without normalization; sample size is retained.")
    if (sex_code == 3L) notes <- paste(notes,
      "Native sex code 3 contains one joint sample with separate female and male vectors; sample_size is repeated and must not be summed across sexes.")
    if (sex_code == 0L) notes <- paste(notes,
      "Native sex code 0 is combined-sex data stored in the female vector; the unused male vector remains in the cached source.")
    if (signed_fleet < 0L) notes <- paste(notes,
      paste0("Original signed fleet code ", signed_fleet,
        " is retained here; its absolute fleet identifies the source row. Stock Synthesis excludes negative-fleet rows from the likelihood."))
    if (x$year[i] < 0) notes <- paste(notes,
      paste0("Original signed year ", x$year[i],
        " is retained here; Stock Synthesis excludes negative-year composition rows from the likelihood."))
    for (sex in names(sex_values)) {
      values <- sex_values[[sex]]
      for (j in seq_along(bins)) {
        common <- list(year = year, sex = sex,
          fleet = if (is_fishery) fleet_name else "",
          survey = if (is_fishery) "" else fleet_name,
          season = paste0("month ", month), sampling_time = (month - 1) / 12,
          source_reference = source_ref("petrale_data.ss",
            if (is_age) "age_info" else "lencomp"),
          transformation = "Native frequency value copied without normalization.",
          notes = notes, observation_id = observation_id,
          sample_size = x$sample_size[i], partition = x$partition[i])
        if (is_age) {
          common$age <- bins[j]
          common$age_error <- x$age_error[i]
          common$length_bin_lower <- x$length_lower[i]
          common$length_bin_upper <- x$length_upper[i]
          measure <- "frequency_at_age"
        } else {
          common$length_bin <- bins[j]
          common$length_bin_lower <- bins[j]
          common$length_bin_upper <- bins[j] + 2
          measure <- "frequency_at_length"
        }
        add_input(do.call(make_input, c(list(n = 1L,
          type = if (is_fishery) "catch" else "index", measure = measure,
          basis = "native_frequency", value = values[j], unit = "source frequency"),
          common)))
      }
    }
  }
  invisible(NULL)
}
composition_rows(length_comp, length_bins)
composition_rows(age_comp, age_bins, is_age = TRUE)

report_lines <- readLines(report_output, warn = FALSE)
annual <- read_report_table(report_lines, "TIME_SERIES", "^Area Yr Era")
n_at_age <- read_report_table(report_lines, "NUMBERS_AT_AGE",
  "^Area Bio_Pattern Sex")
biomass_at_age <- read_report_table(report_lines, "BIOMASS_AT_AGE",
  "^Area Bio_Pattern Sex")
f_at_age <- read_report_table(report_lines, "F_AT_AGE", "^Area Fleet Sex")
catch_at_age <- read_report_table(report_lines, "CATCH_AT_AGE",
  "^Area Fleet Sex")
m_at_age <- read_report_table(report_lines, "Natural_Mortality",
  "^Area Bio_Pattern Sex")
biology <- read_report_table(report_lines, "Biology_at_age_in_endyr",
  "^Seas Morph Bio_Pattern Sex Settlement Platoon int_Age")
weight_at_age <- read_report_table(report_lines, "MEAN_BODY_WT(Begin)",
  "^Morph Yr Seas")
years <- 1876:2034
keep_time <- function(x) x$Yr %in% years & x$Era %in% c("TIME", "FORE")
annual <- annual[annual$Area == 1 & keep_time(annual), , drop = FALSE]
population_rows <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
  x$Sex %in% 1:2 & x$Morph == x$Sex & x$BirthSeas == 1 &
  x$Settlement == 1 & x$Platoon == 1 & x$Seas == 1 &
  x[["Beg/Mid"]] == "B" & keep_time(x)
n_at_age <- n_at_age[population_rows(n_at_age), , drop = FALSE]
biomass_at_age <- biomass_at_age[population_rows(biomass_at_age), , drop = FALSE]
m_at_age <- m_at_age[m_at_age$Area == 1 & m_at_age$Bio_Pattern == 1 &
  m_at_age$Sex %in% 1:2 & m_at_age$Morph == m_at_age$Sex &
  m_at_age$Settlement == 1 & m_at_age$Seas == 1 & keep_time(m_at_age),
  , drop = FALSE]
f_at_age <- f_at_age[f_at_age$Area == 1 & f_at_age$Fleet %in% 1:2 &
  f_at_age$Sex %in% 1:2 & f_at_age$Morph == f_at_age$Sex &
  f_at_age$Seas == 1 & keep_time(f_at_age), , drop = FALSE]
catch_at_age <- catch_at_age[catch_at_age$Area == 1 &
  catch_at_age$Fleet %in% 1:2 & catch_at_age$Sex %in% 1:2 &
  catch_at_age$Morph == catch_at_age$Sex & catch_at_age$Type == "dead" &
  catch_at_age$Seas == 1 & keep_time(catch_at_age), , drop = FALSE]
m_at_age <- m_at_age[order(m_at_age$Yr, m_at_age$Sex), , drop = FALSE]
weight_at_age <- weight_at_age[weight_at_age$Morph %in% 1:2 &
  weight_at_age$Yr %in% years & weight_at_age$Seas == 1, , drop = FALSE]
biology <- biology[biology$Seas == 1 & biology$Morph %in% 1:2 &
  biology$Bio_Pattern == 1 & biology$Settlement == 1 &
  biology$Platoon == 1 & biology$int_Age %in% 0:40 &
  biology$Sex %in% 1:2 & biology$Morph == biology$Sex, , drop = FALSE]
expected <- c(annual = 159L, numbers = 318L, biomass = 318L,
  mortality = 318L, fishing_mortality = 636L, catch_at_age = 636L,
  weight_at_age = 318L, maturity_at_age = 82L)
actual <- c(annual = nrow(annual), numbers = nrow(n_at_age),
  biomass = nrow(biomass_at_age), mortality = nrow(m_at_age),
  fishing_mortality = nrow(f_at_age), catch_at_age = nrow(catch_at_age),
  weight_at_age = nrow(weight_at_age), maturity_at_age = nrow(biology))
if (any(actual != expected) ||
    !setequal(as.integer(unique(annual$Yr)), years) ||
    !setequal(unique(n_at_age$`Beg/Mid`), "B") ||
    !setequal(as.integer(unique(f_at_age$Fleet)), 1:2) ||
    !setequal(as.integer(unique(catch_at_age$Fleet)), 1:2))
  stop("Report output dimensions differ from the pinned run: ",
    paste(names(actual), actual, sep = "=", collapse = ", "), call. = FALSE)
age_columns <- as.character(0:40)
long_age <- function(x) {
  values <- as.matrix(x[, age_columns, drop = FALSE])
  list(row = rep(seq_len(nrow(x)), each = length(age_columns)),
    age = rep(as.integer(age_columns), times = nrow(x)),
    value = as.vector(t(values)))
}
n_long <- long_age(n_at_age)
b_long <- long_age(biomass_at_age)
m_long <- long_age(m_at_age)
f_long <- long_age(f_at_age)
catch_long <- long_age(catch_at_age)
weight_long <- long_age(weight_at_age)
key <- function(x, row, age, sex_name = "Sex")
  paste(x$Yr[row], x[[sex_name]][row], age, sep = "|")
weight_match <- match(key(n_at_age, n_long$row, n_long$age),
  paste(weight_at_age$Yr[weight_long$row], weight_at_age$Morph[weight_long$row],
    weight_long$age, sep = "|"))
biomass_match <- match(key(n_at_age, n_long$row, n_long$age),
  key(biomass_at_age, b_long$row, b_long$age))
if (anyNA(weight_match) || anyNA(biomass_match) ||
    max(abs(n_long$value * weight_long$value[weight_match] -
      b_long$value[biomass_match]) / pmax(1, b_long$value[biomass_match])) > 0.02)
  stop("Reported N, weight, and biomass surfaces do not reconcile.",
    call. = FALSE)
if (any(!is.finite(c(n_long$value, b_long$value, m_long$value,
    f_long$value, catch_long$value, weight_long$value))) ||
    any(m_long$value <= 0) || any(f_long$value < 0) ||
    any(catch_long$value < 0) || any(weight_long$value <= 0))
  stop("Model output surfaces contain invalid values.", call. = FALSE)

parse_interval_table <- function(lines, start_pattern, end_pattern) {
  start <- grep(start_pattern, lines, perl = TRUE)
  end <- grep(end_pattern, lines, perl = TRUE)
  if (length(start) != 1L || length(end) != 1L || end <= start)
    stop("Could not locate official interval table.", call. = FALSE)
  segment <- lines[seq.int(start + 1L, end - 1L)]
  rows <- lapply(segment, function(line) strsplit(trimws(line),
    "[[:space:]]+")[[1L]])
  rows <- rows[lengths(rows) == 7L]
  rows <- rows[vapply(rows, function(x) grepl("^20[0-9]{2}$", x[1L]),
    logical(1L))]
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "value", "lwr", "upr", "extra1", "extra2", "extra3")
  for (column in names(out)) out[[column]] <- as.numeric(out[[column]])
  out
}
assessment_text <- readLines(report_text, warn = FALSE)
spawning_ci <- parse_interval_table(assessment_text,
  "^Table ii: Estimated recent trend in spawning output",
  "^Figure ii: Estimated time series of spawning output")
recruitment_ci <- parse_interval_table(assessment_text,
  "^Table iii: Estimated recent trend in recruitment",
  "^Figure iv: Estimated time series of age-0 recruits")
if (nrow(spawning_ci) != 11L || nrow(recruitment_ci) != 11L ||
    !identical(as.integer(spawning_ci$year), 2013:2023) ||
    !identical(as.integer(recruitment_ci$year), 2013:2023))
  stop("Recent uncertainty tables do not cover 2013-2023.", call. = FALSE)
spawn_match <- match(spawning_ci$year, annual$Yr)
recruit_match <- match(recruitment_ci$year, annual$Yr)
if (anyNA(spawn_match) || anyNA(recruit_match) ||
    any(abs(annual$SpawnBio[spawn_match] - spawning_ci$value) > 0.02) ||
    any(abs(annual$Recruit_0[recruit_match] - recruitment_ci$value) > 1.01))
  stop("Report interval table estimates do not match Report.sso.", call. = FALSE)

output_rows <- list()
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
year_note <- function(year) ifelse(year > 2022,
  "Stock Synthesis forecast after the terminal fitted data year 2022; no age-surface uncertainty is reported.",
  "Stock Synthesis fitted historical model output; no age-surface uncertainty is reported.")
annual_output <- function(measure, values, unit, type, section,
  interval = NULL, notes = "") {
  lwr <- upr <- rep(NA_real_, nrow(annual))
  if (!is.null(interval)) {
    index <- match(annual$Yr, interval$year)
    use <- !is.na(index)
    lwr[use] <- interval$lwr[index[use]]
    upr[use] <- interval$upr[index[use]]
  }
  note_values <- if (length(notes) == 1L && nzchar(notes))
    paste(notes, year_note(annual$Yr)) else if (length(notes) == 1L)
      year_note(annual$Yr) else notes
  add_output(make_output(nrow(annual), type = type, measure = measure,
    value = values, unit = unit, year = annual$Yr, lwr = lwr, upr = upr,
    source_reference = source_ref("Report.sso", section),
    notes = note_values))
}
annual_output("total_biomass", annual$Bio_all, "metric tonnes", "biomass",
  "TIME_SERIES report:16", notes = year_note(annual$Yr))
annual_output("summary_biomass_age3plus", annual$Bio_smry, "metric tonnes",
  "biomass", "TIME_SERIES report:16",
  notes = paste("Bio_smry is the model's age-3+ summary biomass.",
    year_note(annual$Yr)))
annual_output("spawning_output", annual$SpawnBio, "trillion eggs", "biomass",
  "TIME_SERIES report:16", interval = spawning_ci,
  notes = paste("Official assessment term is spawning output, not spawning biomass.",
    year_note(annual$Yr),
    "Published Table ii 95% bounds are available for 2013-2023; other years are blank."))
annual_output("recruitment", annual$Recruit_0, "thousand fish", "recruitment",
  "TIME_SERIES report:16", interval = recruitment_ci,
  notes = paste("Age-0 recruits.", year_note(annual$Yr),
    "Published Table iii 95% bounds are available for 2013-2023; other years are blank."))
add_output(make_output(nrow(spawning_ci), type = "biomass",
  measure = "fraction_unfished_spawning_output",
  value = spawning_ci$extra1, unit = "proportion", year = spawning_ci$year,
  lwr = spawning_ci$extra2, upr = spawning_ci$extra3,
  source_type = "official_table",
  source_reference = "2023 assessment report, Table ii",
  notes = "Spawning output relative to the unfished level, with published 95% intervals."))
surface_output <- function(x, long, type, measure, unit, section,
  sex_column = "Sex", fleet_column = NULL, notes = "") {
  years_for_rows <- x$Yr[long$row]
  sex <- c("1" = "female", "2" = "male")[as.character(x[[sex_column]][long$row])]
  fleet <- if (is.null(fleet_column)) "" else
    unname(fleet_names[as.character(x[[fleet_column]][long$row])])
  add_output(make_output(length(long$value), type = type, measure = measure,
    value = long$value, unit = unit, year = years_for_rows, age = long$age,
    fleet = fleet, sex = sex,
    source_reference = source_ref("Report.sso", section),
    notes = if (nzchar(notes)) notes else year_note(years_for_rows)))
}
surface_output(n_at_age, n_long, "population", "numbers_at_age",
  "thousand fish", "NUMBERS_AT_AGE report:35")
surface_output(biomass_at_age, b_long, "biomass", "biomass_at_age",
  "metric tonnes", "BIOMASS_AT_AGE report:36")
surface_output(m_at_age, m_long, "mortality", "natural_mortality_at_age",
  "per year", "Natural_Mortality report:43",
  notes = "Sex-specific model-generated M-at-age surface; no uncertainty by age is reported.")
surface_output(f_at_age, f_long, "mortality", "fishing_mortality_at_age",
  "per year", "F_AT_AGE report:39", fleet_column = "Fleet")
surface_output(catch_at_age, catch_long, "catch", "numbers_at_age",
  "thousand fish", "CATCH_AT_AGE report:40", fleet_column = "Fleet",
  notes = "Model-estimated dead catch numbers at age; not an observed catch-at-age input.")
surface_output(weight_at_age, weight_long, "biology", "weight_at_age",
  "kg per fish", "MEAN_BODY_WT(Begin) report:48", sex_column = "Morph",
  notes = "Beginning-of-year stock weight-at-age generated by the model, not an observed input.")
add_output(make_output(nrow(biology), type = "biology",
  measure = "proportion_mature_at_age", value = biology$Age_Mat,
  unit = "proportion", year = 2034L, age = biology$int_Age,
  sex = c("1" = "female", "2" = "male")[as.character(biology$Sex)],
  source_reference = source_ref("Report.sso", "Biology_at_age_in_endyr report:47"),
  notes = "Terminal biology-table maturity output; no uncertainty is reported. This is not an observed maturity-at-age input."))
numbers_total <- aggregate(n_long$value,
  list(year = n_at_age$Yr[n_long$row]), sum)
add_output(make_output(nrow(numbers_total), type = "population",
  measure = "total_numbers", value = numbers_total$x, unit = "thousand fish",
  year = numbers_total$year, source_type = "derived_source_output",
  source_reference = source_ref("Report.sso", "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing the native numbers-at-age output across ages 0-40 and both sexes; no uncertainty is available."))

projection_input_rows <- list()
for (scenario in c("Table 1: GMT 2026 removals", "Table 2: 92% of 2026 ACL")) {
  removals <- if (startsWith(scenario, "Table 1")) c(2902, 2927, 2157, 2052) else
    c(2902, 2927, 2157, 2290)
  for (i in seq_along(2023:2026))
    projection_input_rows[[length(projection_input_rows) + 1L]] <-
      make_projection_input(2022L + i, removals[i], scenario,
        if (i <= 2L) "Updated observed removals supplied by the Groundfish Management Team." else
          "Assumed removals in the catch-only projection; values for 2025-2026 come from projected removals or 92% ACL as identified by scenario.")
}
projection_outputs <- list()
add_projection_output <- function(year, measure, value, unit, scenario,
  source_reference, notes) {
  projection_outputs[[length(projection_outputs) + 1L]] <<- make_output(1L,
    assessment = projection_id, type = if (measure == "spawning_output" ||
      measure == "fraction_unfished_spawning_output") "biomass" else "management",
    measure = measure, value = value, unit = unit, year = year,
    source_type = "official_table", source_reference = source_reference,
    notes = notes, scenario = scenario)
}
add_projection_series <- function(years, measure, values, unit, scenario,
  table_number, notes) {
  if (length(years) != length(values)) stop("Projection table dimensions differ.",
    call. = FALSE)
  for (i in seq_along(years))
    add_projection_output(years[i], measure, values[i], unit, scenario,
      paste0("2025 catch-only projection, Table ", table_number), notes)
}
for (scenario in c("Table 1: GMT 2026 removals", "Table 2: 92% of 2026 ACL")) {
  table_number <- if (startsWith(scenario, "Table 1")) 1L else 2L
  if (table_number == 1L) {
    projection_years <- 2023:2036
    spawning <- c(7.69, 6.98, 6.29, 6.09, 6.06, 5.97, 5.99, 6.07,
      6.15, 6.21, 6.26, 6.30, 6.32, 6.34)
    fraction <- c(0.336, 0.305, 0.275, 0.266, 0.265, 0.261, 0.262,
      0.265, 0.268, 0.271, 0.273, 0.275, 0.276, 0.277)
    management_years <- 2027:2036
    ofl <- c(2701, 2670, 2682, 2710, 2738, 2761, 2778, 2789, 2798, 2807)
    buffer <- c(0.926, 0.922, 0.917, 0.913, 0.909, 0.904, 0.900, 0.896,
      0.892, 0.887)
    abc <- c(2501, 2462, 2459, 2474, 2489, 2496, 2500, 2499, 2496, 2490)
  } else {
    projection_years <- 2023:2036
    spawning <- c(7.69, 6.98, 6.29, 6.09, 5.95, 5.88, 5.93, 6.02,
      6.11, 6.19, 6.24, 6.28, 6.31, 6.33)
    fraction <- c(0.336, 0.305, 0.275, 0.266, 0.260, 0.257, 0.259,
      0.263, 0.267, 0.270, 0.273, 0.274, 0.275, 0.276)
    management_years <- 2026:2036
    ofl <- c(2676, 2645, 2628, 2651, 2688, 2723, 2750, 2769, 2782, 2792, 2801)
    buffer <- c(0.930, 0.926, 0.922, 0.917, 0.913, 0.909, 0.904, 0.900,
      0.896, 0.892, 0.887)
    abc <- c(2489, 2449, 2423, 2431, 2454, 2475, 2486, 2492, 2493, 2491, 2484)
  }
  note <- paste0("Rounded point estimate from the published 2025 catch-only projection Table ",
    table_number, "; no uncertainty interval is reported.")
  add_projection_series(projection_years, "spawning_output", spawning,
    "trillion eggs", scenario, table_number, note)
  add_projection_series(projection_years, "fraction_unfished_spawning_output",
    fraction, "proportion", scenario, table_number, note)
  add_projection_series(management_years, "OFL", ofl, "metric tonnes",
    scenario, table_number, "Published overfishing limit (OFL) point estimates; no uncertainty interval is reported.")
  add_projection_series(management_years, "OFL_buffer", buffer, "proportion",
    scenario, table_number, "Published buffer fraction between OFL and ABC; no uncertainty interval is reported.")
  add_projection_series(management_years, "ABC", abc, "metric tonnes",
    scenario, table_number, "Published acceptable biological catch (ABC) point estimates; no uncertainty interval is reported.")
  add_projection_series(management_years, "ACL", abc, "metric tonnes",
    scenario, table_number, "Published annual catch limit (ACL); values equal ABC in these projected years.")
}

assumption_rows <- list()
add_assumption_row <- function(...) assumption_rows[[length(assumption_rows) + 1L]] <<-
  make_assumption(assessment_id, ...)
add_assumption_row("assessment", "model_structure",
  "One area; two sexes; ages 0-40; native input includes two commercial fleets and two surveys",
  "petrale_data.ss; fleetinfo and age bins",
  "Age- and sex-specific surfaces are model outputs. The original likelihood also fits length and age compositions.")
add_assumption_row("assessment", "fitted_and_projection_years",
  "Fitted data through 2022; Stock Synthesis report contains forecasts through 2034",
  "2023 assessment report; Report.sso TIME_SERIES report:16")
add_assumption_row("mortality", "natural_mortality",
  "Natural mortality is estimated for both sexes with meta-analytical priors; female base estimate is approximately 0.142 per year",
  "2023 assessment report, section 4.1 and Table vii; Report.sso Natural_Mortality report:43",
  "The female M point estimate in the native output is retained as an output surface, not reused as an input.")
add_assumption_row("recruitment", "stock_recruitment",
  "Beverton-Holt; steepness fixed at 0.8; recruitment deviations estimated for 1959-2020",
  "petrale_control.ss; spawner-recruitment and recruitment-deviation sections")
add_assumption_row("biology", "growth_weight_and_maturity",
  "Length-based growth, sex-specific weight-length relationships, maturity and fecundity are modelled; no observed stock weight-at-age or maturity-at-age vector is supplied",
  "petrale_control.ss; biology parameter sections; Report.sso Biology_at_age_in_endyr report:47")
add_assumption_row("survey", "survey_indices_and_timing",
  "Triennial and WCGBTS aggregate biomass indices; both use native season 7 and fleet timing code 1007",
  "petrale_data.ss; fleetinfo and CPUE_data",
  "The database records July timing as (7-1)/12 = 0.5. No age-specific abundance index is a native likelihood input.")
add_assumption_row("composition", "age_and_length_sampling",
  "Length and age frequencies are fitted separately; survey age samples include conditional age-at-length records and a derived marginal WCGBTS series",
  "petrale_data.ss; lencomp and age_info",
  "Native frequencies, sample sizes, bins, sex codes, age-error codes, partition codes, and signed fleet/year flags are preserved. No sample vector is normalized.")
add_assumption_row("projection", "2025_catch_only_projection",
  "2023-2024 removals updated from Groundfish Management Team information; 2025-2026 removals use projected mortality, with an alternative 2026 removal of 92% of ACL; later projections use P*=0.45, category 1, time-varying sigma 0.5",
  "2025 catch-only projection, pp. 1-2 and Tables 1-2",
  "The alternative Table 2 scenario informed the 2026 emergency harvest-specification change. The 2025 projection reuses the 2023 full assessment; it is not a new full assessment.")
assumption_rows[[length(assumption_rows) + 1L]] <- make_assumption(
  projection_id, "projection", "projection_basis",
  "Catch-only projection based on the 2023 Stock Synthesis benchmark; 2023-2024 catches updated, with alternative 2026 assumptions",
  "2025 catch-only projection, pp. 1-2",
  "The PDF tables publish selected aggregate outputs, not annual age-specific state surfaces or their uncertainty.")

input_data <- do.call(rbind, c(input_rows, projection_input_rows))
output_data <- do.call(rbind, c(output_rows, projection_outputs))
assumption_data <- do.call(rbind, assumption_rows)
assumption_key <- do.call(paste, c(assumption_data[c("assessment_id", "component",
  "fleet", "survey", "sex", "region", "season", "setting")], sep = "\r"))
if (anyDuplicated(assumption_key) || any(!nzchar(input_data$source_reference)) ||
    any(!nzchar(output_data$source_reference)))
  stop("Duplicate assumptions or missing input/output provenance.", call. = FALSE)

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_05_2026.csv")
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
    (!dry_run && candidate$import_status[ci] != "not_started") ||
    (!dry_run && !inventory$import_status[ii] %in% c("not_started", "")))
  stop("Selected Petrale Sole candidate is missing, duplicated, or not eligible.",
    call. = FALSE)
if (!dry_run && (any(stocks$stock_id == stock_id) ||
    any(assessments$assessment_id %in% c(assessment_id, projection_id))))
  stop("Petrale Sole records already exist; inspect before importing.",
    call. = FALSE)
first_column <- function(path) {
  fields <- read_fields(path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", length(fields) - 1L)))[[1L]]
}
if (!dry_run) for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv")))
  if (any(c(assessment_id, projection_id) %in% first_column(path)))
    stop("Petrale Sole data rows already exist; refusing to append duplicates.",
      call. = FALSE)
blank_row <- function(fields, values) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks), list(stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-NWFSC", authority_stock_id = "10011",
  scientific_name = "Eopsetta jordani",
  common_name = "Petrale sole - U.S. West Coast",
  area = "Pacific Coast, United States",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART ID 10011; one U.S. Pacific Coast management unit, distinct from Canadian petrale sole and Alaska flatfish-complex records."))
report_url <- source_manifest$url[match(report_file, source_manifest$file)]
model_url <- source_manifest$url[match(archive_file, source_manifest$file)]
projection_url <- source_manifest$url[match(projection_file, source_manifest$file)]
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2022L, estimate_terminal_year = 2034L,
  assessment_type = "full_benchmark", model_family = "Stock Synthesis",
  model_version = "3.30.21.00", is_current = FALSE, is_applied = TRUE,
  framework_year = 2023L, assessment_url = report_url, data_url = model_url,
  model_url = model_url, assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "Official 2023 full benchmark fitted through 2022; native Report.sso includes forecast rows through 2034. The 2025 catch-only projection is stored as a separate later applied assessment event. The database preserves native catch, aggregate indices, discards, mean-body-weight observations and age/length compositions; it does not treat fitted states or biology surfaces as observations."))
projection <- blank_row(names(assessments), list(
  assessment_id = projection_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2036L,
  assessment_type = "catch_only_projection",
  model_family = "Stock Synthesis catch-only projection",
  model_version = "Based on Stock Synthesis 3.30.21.00 benchmark",
  is_current = TRUE, is_applied = TRUE, framework_year = 2023L,
  assessment_url = projection_url, data_url = projection_url,
  model_url = model_url, assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = "2025 projection based on the 2023 benchmark with updated 2023-2024 removals and projected catches through 2026. Table 2 is the alternative 92%-of-ACL 2026 scenario used in the 2026 harvest-specification action. The projection report gives rounded aggregate spawning-output and stock-status values but not age-specific states or their uncertainty."))
candidate_row <- candidate[ci, , drop = FALSE]
candidate_row$matched_stock_id <- stock_id
candidate_row$match_status <- "new"
candidate_row$import_status <- "partial"
candidate_row$catch_age_evidence <- "2023 model fits North/South catch biomass plus fishery age compositions; no observed catch-at-age array is supplied. Catch-at-age reconstruction is analysis-specific."
candidate_row$survey_age_evidence <- "Triennial and WCGBTS biomass indices are aggregate; survey age compositions support a documented downstream approximation but are not native age-specific abundance indices."
candidate_row$weights_evidence <- "Native mean-body-weight observations are retained; stock weight-at-age is generated from modeled growth and weight-length relationships, not an observed input vector."
candidate_row$maturity_evidence <- "Maturity-at-age is a model-generated biological output; native fitted inputs are length-based maturity parameters rather than an observed maturity-at-age vector."
candidate_row$mortality_evidence <- "Natural mortality is estimated for both sexes with meta-analytical priors; Report.sso supplies model-generated M-at-age."
candidate_row$timing_evidence <- "Survey indices use native season 7 and fleet timing code 1007; survey timing is represented as 0.5 using the package's month-to-year convention."
candidate_row$output_evidence <- "Imported annual N/F/M/catch-at-age and biology surfaces from the 2023 Report.sso, recent 95% intervals for spawning output/recruitment, plus selected 2025 catch-only projection outputs."
candidate_row$review_date <- format(Sys.Date(), "%Y-%m-%d")
candidate_row$decision_reason <- "Partial source import of the latest current-unit assessment detail (2025 applied catch-only projection) and its 2023 full-benchmark base; data and outputs remain separated by assessment event."
candidate_row$notes <- "See source_reviews/noaa_petrale_10011.md. The source model uses catches and length/age compositions rather than direct catch-at-age or age-specific abundance-index likelihoods; modeled biology outputs are not inputs."
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

cache_manifest <- data.frame(
  local_file = c(paste0("discovery_noaa_petrale_10011/", report_file),
    paste0("discovery_noaa_petrale_10011/", archive_file),
    paste0("discovery_noaa_petrale_10011/", projection_file),
    "discovery_noaa_petrale_10011/inputs/petrale_data.ss",
    "discovery_noaa_petrale_10011/inputs/petrale_control.ss",
    "discovery_noaa_petrale_10011/outputs/Report.sso",
    "discovery_noaa_petrale_10011/outputs/ss_summary.sso"),
  source_url = c(report_url, model_url, projection_url, rep(model_url, 4L)),
  retrieved_on = c(source_manifest$retrieved_on[match(c(report_file,
    archive_file, projection_file), source_manifest$file)], rep("2026-10-28", 4L)),
  sha256 = c(sha256_file(file.path(cache, report_file)),
    sha256_file(file.path(cache, archive_file)),
    sha256_file(file.path(cache, projection_file)), sha256_file(data_file),
    sha256_file(control_file), sha256_file(report_output),
    sha256_file(file.path(cache, "outputs", "ss_summary.sso"))),
  bytes = c(file.info(file.path(cache, report_file))$size,
    file.info(file.path(cache, archive_file))$size,
    file.info(file.path(cache, projection_file))$size,
    file.info(data_file)$size, file.info(control_file)$size,
    file.info(report_output)$size,
    file.info(file.path(cache, "outputs", "ss_summary.sso"))$size),
  stringsAsFactors = FALSE)

if (!dry_run) {
  append_rows(stocks_path, stock)
  append_rows(assessments_path, rbind(assessment, projection))
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), output_data)
  append_rows(file.path(database, "assumptions.csv"), assumption_data)
  replace_candidate_register_row(candidate_path, ci, candidate_row, candidate_id)
  replace_csv_row(inventory_path, "unit_key", paste0("candidate:", candidate_unit_id), ii, inventory_row)
  replace_csv_row(selected_path, "candidate_unit_id", candidate_unit_id, si, selected_row)
  utils::write.csv(cache_manifest,
    file.path(root, "provenance", "noaa_petrale_10011_sources.csv"),
    row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
cat(if (dry_run) "Dry run parsed " else "Imported ", nrow(input_data),
  " input rows, ", nrow(assumption_data), " assumption rows, and ",
  nrow(output_data), " output rows across two assessment events.\n",
  "Native 2023 inputs: catch=", nrow(catch), ", indices=", nrow(index),
  ", discards=", nrow(discard), ", mean-body-weight=", nrow(mean_weight),
  ", length compositions=", nrow(length_comp), ", age compositions=",
  nrow(age_comp), ".\n", sep = "")
