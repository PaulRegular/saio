root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_black_rockfish_2023")
model_dir <- file.path(cache, "oregon_model_files", "Reference model")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

candidate_id <- "NOAA:14407"
candidate_unit_id <- "noaa_black_rockfish_oregon_2023"
stock_id <- "noaa_black_rockfish_oregon"
assessment_id <- "noaa_black_rockfish_oregon_2023"
report_file <- "Black_Rockfish_Oregon_2023_assessment.pdf"
model_archive <- "Black_Rockfish_Oregon_2023_model_files.zip"
report_url <- "https://www.pcouncil.org/documents/2024/02/status-of-black-rockfish-sebastes-melanops-in-2023-in-state-and-federal-waters-off-oregon.pdf/"
archive_url <- "https://www.pcouncil.org/documents/black-rockfish-or-2023-model-files-zip-file/"
manual_url <- "https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html"

source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_table <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

manifest <- read_table(file.path(cache, "sources.csv"))
verify_source <- function(file) {
  source <- manifest[manifest$file == file, , drop = FALSE]
  path <- if (file %in% c("datafile.dat", "controlfile.ctl", "wtatage.ss_new", "Report.sso")) {
    file.path(model_dir, file)
  } else {
    file.path(cache, file)
  }
  if (nrow(source) != 1L || !file.exists(path) ||
      tolower(source$sha256) != sha256_file(path)) {
    stop("Cached NOAA source is missing or differs from its manifest: ", file,
      call. = FALSE)
  }
  path
}

verify_source(report_file)
verify_source(model_archive)
for (file in c("datafile.dat", "controlfile.ctl", "wtatage.ss_new", "Report.sso")) {
  if (!file.exists(file.path(model_dir, file))) stop("Missing extracted model file: ", file, call. = FALSE)
}

make_frame <- function(fields, values, n) {
  columns <- lapply(fields, function(field) {
    x <- values[[field]]
    if (is.null(x)) return(rep("", n))
    x <- as.character(x)
    x[is.na(x)] <- ""
    rep_len(x, n)
  })
  names(columns) <- fields
  as.data.frame(columns, stringsAsFactors = FALSE, optional = TRUE,
    check.names = FALSE)
}

input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))

make_input <- function(n, type, measure, basis, value, unit, year = NA_real_,
  year_basis = "calendar_year", age = NA_real_, fleet = "", survey = "",
  sex = "", region = "Oregon", season = "", sampling_time = NA_real_,
  source_type = "native_model", source_reference, transformation = "",
  notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = NA_real_) {
  values <- list(assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = sex, region = region,
    season = season, year = year, year_basis = year_basis, age = age,
    value = value, unit = unit, sampling_time = sampling_time,
    source_type = source_type, source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition)
  make_frame(input_fields, values, n)
}

make_output <- function(n, type, measure, value, unit, year = NA_real_,
  age = NA_real_, age_group = "", fleet = "", sex = "", region = "Oregon",
  season = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
  source_type = "native_model", source_reference, notes = "") {
  values <- list(assessment_id = assessment_id, type = type, measure = measure,
    fleet = fleet, survey = "", sex = sex, region = region, season = season,
    year = year, age = age, age_group = age_group, value = value, se = se,
    lwr = lwr, upr = upr, unit = unit, source_type = source_type,
    source_reference = source_reference, notes = notes)
  make_frame(output_fields, values, n)
}

input_rows <- list()
output_rows <- list()
assumption_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
add_assumption <- function(component, setting, value, fleet = "", survey = "",
  sex = "", source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_frame(
    assumption_fields,
    list(assessment_id = assessment_id, component = component, fleet = fleet,
      survey = survey, sex = sex, region = "Oregon", season = "",
      setting = setting, value = value, source_reference = source_reference,
      notes = notes), 1L)
}

## Parse native inputs ----

data_path <- file.path(model_dir, "datafile.dat")
data_lines <- readLines(data_path, warn = FALSE)

read_numeric_block <- function(lines, marker, n_fields, pattern = FALSE) {
  starts <- if (pattern) {
    grep(marker, trimws(lines), perl = TRUE)
  } else {
    which(trimws(lines) == marker)
  }
  if (length(starts) != 1L) stop("Expected one source block: ", marker, call. = FALSE)
  rows <- list()
  for (i in seq.int(starts + 1L, length(lines))) {
    line <- sub("#.*$", "", lines[i])
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (!length(tokens) || !nzchar(tokens[1L])) next
    if (tokens[1L] == "-9999") break
    if (length(tokens) != n_fields) {
      stop("Unexpected field count in ", marker, " at source line ", i, ".", call. = FALSE)
    }
    values <- suppressWarnings(as.numeric(tokens))
    if (anyNA(values)) stop("Non-numeric value in ", marker, ".", call. = FALSE)
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop("No records found in ", marker, ".", call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}

read_fleet_info <- function(lines) {
  start <- which(trimws(lines) == "#_fleetinfo")
  end <- which(trimws(lines) == "#_Catch data")
  if (length(start) != 1L || length(end) != 1L || end <= start) stop("Fleet table is malformed.", call. = FALSE)
  body <- lines[seq.int(start + 1L, end - 1L)]
  body <- body[grepl("^[[:space:]]*[0-9]+[[:space:]]", body)]
  rows <- lapply(body, function(line) {
    line <- trimws(sub("#.*$", "", line))
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    c(as.numeric(fields[1:5]), paste(fields[6:length(fields)], collapse = " "))
  })
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("type", "timing", "area", "catch_units", "need_catch_mult", "fleet_name")
  for (field in names(out)[1:5]) out[[field]] <- as.numeric(out[[field]])
  out
}

read_index_info <- function(lines) {
  start <- which(trimws(lines) == "#_CPUE_and_surveyabundance_observations")
  end <- which(trimws(lines) == "#_CPUE_data")
  if (length(start) != 1L || length(end) != 1L || end <= start) stop("Index unit table is malformed.", call. = FALSE)
  body <- lines[seq.int(start + 1L, end - 1L)]
  body <- body[grepl("^[[:space:]]*[0-9]+[[:space:]]", body)]
  values <- lapply(body, function(line) suppressWarnings(as.numeric(
    strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
  )))
  if (any(lengths(values) != 4L)) stop("Index unit table has an unexpected row.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, values), stringsAsFactors = FALSE)
  names(out) <- c("fleet", "units", "error_type", "sd_report")
  out
}

fleet_info <- read_fleet_info(data_lines)
index_info <- read_index_info(data_lines)
catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "season", "fleet", "catch", "catch_se")
catch <- catch[catch$year >= 1892, , drop = FALSE]
cpue <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(cpue) <- c("year", "month", "fleet", "observation", "se_log")
length_comp <- read_numeric_block(data_lines, "#_lencomp", 62L)
names(length_comp) <- c("year", "season", "fleet", "sex_code", "partition", "sample_size",
  paste0("f", seq(10, 64, 2)), paste0("m", seq(10, 64, 2)))
age_comp <- read_numeric_block(data_lines,
  "^#_Yr[[:space:]]+Month[[:space:]]+Fleet[[:space:]]+Sex[[:space:]]+Part[[:space:]]+Ageerr",
  91L, pattern = TRUE)
names(age_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "age_error", "length_bin_lower", "length_bin_upper", "sample_size",
  paste0("f", 0:40), paste0("m", 0:40))

data_checks <- c(
  fleet_count = nrow(fleet_info) == 8L,
  index_unit_count = nrow(index_info) == 8L,
  catch_count = nrow(catch) == 524L,
  cpue_count = nrow(cpue) == 78L,
  length_composition_count = nrow(length_comp) == 179L,
  age_composition_count = nrow(age_comp) == 1816L,
  catch_fleets = identical(as.integer(sort(unique(catch$fleet))), 1:4),
  cpue_fleets = identical(as.integer(sort(unique(cpue$fleet))), c(2L, 3L, 5L, 6L, 7L, 8L)),
  length_sexes = identical(as.integer(sort(unique(length_comp$sex_code))), 0:2),
  age_sexes = identical(as.integer(sort(unique(age_comp$sex_code))), 0:2),
  age_error_codes = identical(as.integer(sort(unique(age_comp$age_error))), c(1L, 2L, 3L, 4L, 5L, 7L)),
  index_fleets = identical(as.integer(index_info$fleet), 1:8),
  index_error_types = all(index_info$error_type == 0)
)
if (!all(data_checks)) {
  stop("Native data checks failed: ", paste(names(data_checks)[!data_checks], collapse = ", "), call. = FALSE)
}

fleet_names <- setNames(fleet_info$fleet_name, seq_len(nrow(fleet_info)))
index_units <- setNames(index_info$units, index_info$fleet)
index_errors <- setNames(index_info$error_type, index_info$fleet)
if (anyNA(index_units[as.character(cpue$fleet)]) || any(index_units[as.character(cpue$fleet)] > 1) ||
    any(index_errors[as.character(cpue$fleet)] != 0) || any(cpue$se_log <= 0) ||
    any(catch$catch < 0) || any(catch$catch_se != 0.01)) {
  stop("Native catch or index values differ from the reviewed source conventions.", call. = FALSE)
}

catch_source <- paste0(model_archive, ", datafile.dat, Catch data")
catch_fleets <- fleet_names[as.character(catch$fleet)]
add_input(make_input(nrow(catch), type = "catch", measure = "total_biomass",
  basis = "biomass", value = catch$catch, unit = "metric tonnes",
  year = catch$year, fleet = catch_fleets, source_reference = catch_source,
  notes = "Native annual catch biomass. SS3 catch units code 1 is biomass; source catch_se is retained as a separate model setting because need_catch_mult is 0."))

for (i in seq_len(nrow(cpue))) {
  code <- as.character(as.integer(cpue$fleet[i]))
  month <- as.integer(cpue$month[i])
  units_code <- as.integer(index_units[code])
  index_measure <- if (units_code == 0L) "total_numbers" else "total_biomass"
  index_label <- if (units_code == 0L) "number" else "biomass"
  survey <- unname(fleet_names[code])
  time <- (month - 1) / 12
  add_input(make_input(1L, type = "index", measure = index_measure,
    basis = "index_scale", value = cpue$observation[i],
    unit = paste0("native SS3 ", index_label, " index units (units code ", units_code,
      "; multiplier not stated)"), year = cpue$year[i], survey = survey,
    season = month.name[month], sampling_time = time,
    source_reference = paste0(model_archive, ", datafile.dat, CPUE_data; controlfile.ctl, CPUE units"),
    notes = paste0("Native aggregate index on its original scale. Error type 0 is lognormal; the supplied se_log is retained below. Source month ",
      month, " maps to sampling_time=(month-1)/12=", time, ".")))
  add_input(make_input(1L, type = "index", measure = "log_index_sd",
    basis = "log_scale", value = cpue$se_log[i], unit = "log-scale standard error",
    year = cpue$year[i], survey = survey, season = month.name[month],
    sampling_time = time,
    source_reference = paste0(model_archive, ", datafile.dat, CPUE_data, se_log field"),
    notes = "Source se_log is retained without transformation; the control file specifies lognormal error type 0."))
}

sex_name <- function(code) switch(as.character(as.integer(code)),
  "0" = "combined", "1" = "female", "2" = "male",
  stop("Unexpected composition sex code: ", code, call. = FALSE))

composition_rows <- function(x, component, ages_or_lengths) {
  age <- component == "age"
  bins <- ages_or_lengths
  result <- list()
  for (code in sort(unique(x$sex_code))) {
    source_rows <- which(x$sex_code == code)
    fields <- if (code == 2) paste0("m", bins) else paste0("f", bins)
    values <- as.matrix(x[source_rows, fields, drop = FALSE])
    row_id <- rep(source_rows, each = length(bins))
    bin_id <- rep(bins, times = length(source_rows))
    value <- as.vector(t(values))
    source_fleet <- as.integer(x$fleet[row_id])
    negative <- source_fleet < 0L
    base_fleet <- abs(source_fleet)
    fleet <- unname(fleet_names[as.character(base_fleet)])
    if (anyNA(fleet)) {
      stop("Composition source row uses an unmapped fleet.", call. = FALSE)
    }
    is_catch <- base_fleet <= 4L
    observation_type <- ifelse(is_catch, "catch", "index")
    destination_fleet <- ifelse(is_catch, fleet, "")
    destination_survey <- ifelse(is_catch, "", fleet)
    if (age) {
      length_lower <- as.numeric(x$length_bin_lower[row_id])
      length_upper <- as.numeric(x$length_bin_upper[row_id])
      length_lower[length_lower < 0] <- NA_real_
      length_upper[length_upper < 0] <- NA_real_
      notes <- ifelse(negative,
        "Negative signed source fleet code identifies a provisional composition: SS3 processes it and calculates its expected value and log likelihood, but excludes that likelihood from the total objective. Age frequencies are conditional on the source length interval where a non-negative interval is supplied; -1/-1 means unconditioned. Age 40 is the accumulator bin.",
        "Native age-frequency values retained without normalization. Frequencies are conditional on the source length interval where a non-negative interval is supplied; -1/-1 means unconditioned. Age-error code and sample size are retained; age 40 is the accumulator bin.")
      result[[length(result) + 1L]] <- make_input(length(value),
        type = observation_type, measure = "frequency_at_age", basis = "native_frequency",
        value = value, unit = "source frequency weight", year = x$year[row_id],
        fleet = destination_fleet, survey = destination_survey,
        sex = sex_name(code), season = month.name[x$month[row_id]],
        sampling_time = (x$month[row_id] - 1) / 12,
        age = bin_id, source_reference = paste0(model_archive, ", datafile.dat, age-composition data"),
        notes = notes, observation_id = paste0("agecomp-row-", row_id),
        length_bin_lower = length_lower, length_bin_upper = length_upper,
        sample_size = x$sample_size[row_id], age_error = x$age_error[row_id],
        partition = x$partition[row_id])
    } else {
      lower <- as.numeric(bins[bin_id])
      upper <- lower + 2
      upper[lower == 64] <- NA_real_
      notes <- ifelse(negative,
        "Negative signed source fleet code identifies a provisional composition: SS3 processes it and calculates its expected value and log likelihood, but excludes that likelihood from the total objective. Raw length-frequency values and sample size are retained; source bin labels are lower edges in cm, with 64 as the terminal bin.",
        "Raw length-frequency values retained without normalization. Source bin labels are lower edges in cm, with 64 as the terminal bin; sample size and partition are retained.")
      result[[length(result) + 1L]] <- make_input(length(value),
        type = observation_type, measure = "frequency_at_length", basis = "native_frequency",
        value = value, unit = "source frequency weight", year = x$year[row_id],
        fleet = destination_fleet, survey = destination_survey,
        sex = sex_name(code), season = paste0("Season ", x$season[row_id]),
        sampling_time = ifelse(x$season[row_id] == 1, NA_real_, (x$season[row_id] - 1) / 12),
        length_bin = bin_id, length_bin_lower = lower, length_bin_upper = upper,
        source_reference = paste0(model_archive, ", datafile.dat, lencomp data"),
        notes = notes, observation_id = paste0("lencomp-row-", row_id),
        sample_size = x$sample_size[row_id], partition = x$partition[row_id])
    }
  }
  do.call(rbind, result)
}

add_input(composition_rows(length_comp, "length", seq(10, 64, 2)))
add_input(composition_rows(age_comp, "age", 0:40))

## Parse fitted outputs ----

read_report_table <- function(name, header_pattern) {
  lines <- readLines(file.path(model_dir, "Report.sso"), warn = FALSE)
  marker <- grep(paste0("^", name, " report:"), lines)
  if (!length(marker)) stop("Missing report table: ", name, call. = FALSE)
  marker <- tail(marker, 1L)
  header <- grep(header_pattern, lines, perl = TRUE)
  header <- header[header > marker][1L]
  ends <- grep(" report:", lines, fixed = TRUE)
  end <- ends[ends > header][1L]
  if (is.na(header) || is.na(end)) stop("Could not locate report-table bounds for ", name, call. = FALSE)
  body <- lines[header:(end - 1L)]
  body <- body[!grepl("^[[:space:]]*#", body)]
  utils::read.table(text = body, header = TRUE, fill = FALSE,
    check.names = FALSE, stringsAsFactors = FALSE, quote = "", comment.char = "")
}

read_weight_rows <- function(path) {
  lines <- readLines(path, warn = FALSE)
  rows <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
    if (length(tokens) != 47L) return(NULL)
    values <- suppressWarnings(as.numeric(tokens))
    if (anyNA(values) || values[1L] == -9999) return(NULL)
    values
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  if (length(rows) != 3146L) stop("Unexpected wtatage.ss_new row count.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("year", "season", "sex", "bio_pattern", "birth_season",
    "fleet", as.character(0:40))
  out
}

long_age <- function(x, columns) {
  n_age <- length(columns)
  data.frame(row = rep(seq_len(nrow(x)), each = n_age),
    age = rep(as.integer(columns), times = nrow(x)),
    value = as.vector(t(as.matrix(x[, columns, drop = FALSE])))
  )
}

report_n <- read_report_table("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
report_b <- read_report_table("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
report_f <- read_report_table("F_AT_AGE", "^Area Fleet Sex")
report_m <- read_report_table("Natural_Mortality", "^Area Bio_Pattern Sex")
annual <- read_report_table("TIME_SERIES", "^Area Yr Era")
weights <- read_weight_rows(file.path(model_dir, "wtatage.ss_new"))

years <- 1892:2034
era <- c("TIME", "FORE")
keep_n <- function(x) x$Area == 1 & x$Bio_Pattern == 1 & x$Sex %in% 1:2 &
  x$Morph == x$Sex & x$BirthSeas == 1 & x$Settlement == 1 & x$Platoon == 1 &
  x$Seas == 1 & x$`Beg/Mid` == "B" & x$Era %in% era & x$Yr %in% years
report_n <- report_n[keep_n(report_n), , drop = FALSE]
report_b <- report_b[keep_n(report_b), , drop = FALSE]
report_f <- report_f[report_f$Area == 1 & report_f$Fleet %in% 1:4 &
  report_f$Sex %in% 1:2 & report_f$Morph == report_f$Sex & report_f$Seas == 1 &
  report_f$Era %in% era & report_f$Yr %in% years, , drop = FALSE]
report_m <- report_m[keep_n(report_m), , drop = FALSE]
annual <- annual[annual$Area == 1 & annual$Era %in% era & annual$Yr %in% years, , drop = FALSE]
weights <- weights[weights$year %in% years & weights$sex %in% 1:2 &
  weights$bio_pattern == 1 & weights$birth_season == 1, , drop = FALSE]

if (nrow(report_n) != 286L || nrow(report_b) != 286L ||
    nrow(report_f) != 1144L || nrow(report_m) != 286L ||
    nrow(annual) != length(years) || nrow(weights) != 3146L ||
    !identical(sort(unique(as.integer(report_n$Yr))), years) ||
    !identical(sort(unique(as.integer(report_f$Yr))), years) ||
    !identical(sort(unique(as.integer(report_m$Yr))), years) ||
    !identical(sort(unique(as.integer(annual$Yr))), years) ||
    !all(abs(unique(as.numeric(unlist(report_m[report_m$Sex == 1, as.character(0:40)]))) - 0.19) < 1e-8) ||
    !all(abs(unique(as.numeric(unlist(report_m[report_m$Sex == 2, as.character(0:40)]))) - 0.17) < 1e-8)) {
  stop("Fitted output dimensions, years, or M values differ from the reviewed reference run.", call. = FALSE)
}

stock_ref <- paste0(model_archive, ", Report.sso, ")
for (spec in list(
  list(report_n, "population", "numbers_at_age", "thousand fish", "Yr", "", "Beginning-of-year N; age 40 is the accumulator group."),
  list(report_b, "biomass", "biomass_at_age", "metric tonnes", "Yr", "", "Beginning-of-year biomass at age; age 40 is the accumulator group."),
  list(report_m, "mortality", "natural_mortality_at_age", "per year", "Yr", "", "Fitted constant sex-specific M surface; age 40 is the accumulator group."))) {
  x <- spec[[1L]]
  z <- long_age(x, as.character(0:40))
  sex <- ifelse(x$Sex[z$row] == 1, "female", "male")
  add_output(make_output(nrow(z), type = spec[[2L]], measure = spec[[3L]],
    value = z$value, unit = spec[[4L]], year = x[[spec[[5L]]]][z$row],
    age = z$age, age_group = ifelse(z$age == 40, "40+", ""), sex = sex,
    source_reference = paste0(stock_ref, if (spec[[3L]] == "numbers_at_age") "NUMBERS_AT_AGE report:35" else if (spec[[3L]] == "biomass_at_age") "BIOMASS_AT_AGE report:36" else "Natural_Mortality report:43"),
    notes = spec[[7L]]))
}

z <- long_age(report_f, as.character(0:40))
f_notes <- ifelse(report_f$Era[z$row] == "FORE",
  "Official fitted fishing-mortality surface; source Era FORE marks a forecast year. Age 40 is the accumulator group.",
  "Official fitted fishing-mortality surface. Age 40 is the accumulator group.")
add_output(make_output(nrow(z), type = "mortality", measure = "fishing_mortality_at_age",
  value = z$value, unit = "per year", year = report_f$Yr[z$row], age = z$age,
  age_group = ifelse(z$age == 40, "40+", ""),
  fleet = unname(fleet_names[as.character(report_f$Fleet[z$row])]),
  sex = ifelse(report_f$Sex[z$row] == 1, "female", "male"),
  source_reference = paste0(stock_ref, "F_AT_AGE report:39"), notes = f_notes))

for (measure in c("total_biomass", "spawning_output", "recruitment")) {
  value <- switch(measure, total_biomass = annual$Bio_all,
    spawning_output = annual$SpawnBio, recruitment = annual$Recruit_0)
  unit <- switch(measure, total_biomass = "metric tonnes",
    spawning_output = "billion eggs", recruitment = "thousand fish")
  type <- switch(measure, total_biomass = "biomass",
    spawning_output = "biomass", recruitment = "recruitment")
  lower <- upper <- rep(NA_real_, nrow(annual))
  source_type <- rep("native_model", nrow(annual))
  source_reference <- rep(paste0(stock_ref, "TIME_SERIES report:16"), nrow(annual))
  if (measure == "spawning_output") {
    is_2023 <- annual$Yr == 2023
    lower[is_2023] <- 487
    upper[is_2023] <- 861
    source_type[is_2023] <- "official_document"
    source_reference[is_2023] <- paste(report_url, "Table V; point estimate cross-checked against Report.sso TIME_SERIES")
  }
  add_output(make_output(nrow(annual), type = type, measure = measure,
    value = value, unit = unit, year = annual$Yr, age = if (measure == "recruitment") 0 else NA_real_,
    lwr = lower, upr = upper, source_type = source_type,
    source_reference = source_reference,
    notes = if (measure == "spawning_output") {
      ifelse(annual$Yr == 2023,
        "SpawnBio from the official 2023 reference model; 2023 Table V gives the 95% asymptotic interval. Era FORE denotes forecasts. The report defines spawning output in billions of eggs.",
        ifelse(annual$Era == "FORE", "SpawnBio from the official model forecast; unit is billion eggs.", "SpawnBio from the official fitted model; unit is billion eggs."))
    } else if (measure == "recruitment") {
      ifelse(annual$Era == "FORE", "Recruit_0; age-0 recruitment in thousands of fish. Era FORE denotes forecasts.", "Recruit_0; age-0 recruitment in thousands of fish.")
    } else {
      ifelse(annual$Era == "FORE", "Bio_all; total beginning-of-year biomass in metric tonnes. Era FORE denotes forecasts.", "Bio_all; total beginning-of-year biomass in metric tonnes.")
    }))
}

total_n <- aggregate(rowSums(report_n[, as.character(0:40), drop = FALSE]),
  list(year = report_n$Yr), sum)
names(total_n)[2L] <- "value"
add_output(make_output(nrow(total_n), type = "population", measure = "total_numbers",
  value = total_n$value, unit = "thousand fish", year = total_n$year,
  source_type = "derived_source_output", source_reference = paste0(stock_ref, "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing beginning-of-year N-at-age over sexes and ages 0-40, including the age-40 accumulator. No uncertainty was calculated."))

weight_rows <- list()
for (code in sort(unique(weights$fleet))) {
  x <- weights[weights$fleet == code, , drop = FALSE]
  z <- long_age(x, as.character(0:40))
  if (code == -2) {
    type <- "biology"; measure <- "maturity_fecundity_at_age"; fleet <- "maturity*fecundity"
    unit <- "native SS3 maturity-fecundity scale"
    notes <- "SS3-generated wtatage.ss_new field for fleet -2; the model manual identifies it as maturity*fecundity. This is not a maturity proportion or a supplied input; no unsupported unit multiplier was added."
  } else if (code == -1) {
    type <- "biology"; measure <- "weight_at_age"; fleet <- "mid-season population"
    unit <- "kg per fish"
    notes <- "SS3-generated wtatage.ss_new mid-season population mean weight-at-age."
  } else if (code == 0) {
    type <- "biology"; measure <- "start_weight_at_age"; fleet <- "beginning-season population"
    unit <- "kg per fish"
    notes <- "SS3-generated wtatage.ss_new beginning-season population mean weight-at-age."
  } else if (code %in% 1:4) {
    type <- "biology"; measure <- "catch_weight_at_age"; fleet <- unname(fleet_names[as.character(code)])
    unit <- "kg per fish"
    notes <- "SS3-generated fleet-specific mean weight-at-age; this output is not a separately supplied catch-weight input."
  } else {
    type <- "biology"; measure <- "weight_at_age"; fleet <- unname(fleet_names[as.character(code)])
    unit <- "kg per fish"
    notes <- "SS3-generated fleet-specific mean weight-at-age for an index fleet."
  }
  weight_rows[[length(weight_rows) + 1L]] <- make_output(nrow(z), type = type,
    measure = measure, value = z$value, unit = unit, year = x$year[z$row],
    age = z$age, age_group = ifelse(z$age == 40, "40+", ""),
    fleet = fleet, sex = ifelse(x$sex[z$row] == 1, "female", "male"),
    source_reference = paste0(model_archive, ", wtatage.ss_new, fleet code ", code),
    notes = notes)
}
add_output(do.call(rbind, weight_rows))

## Record assumptions and add canonical rows ----

control_lines <- readLines(file.path(model_dir, "controlfile.ctl"), warn = FALSE)
value_before <- function(pattern) {
  row <- grep(pattern, control_lines, perl = TRUE, value = TRUE)
  if (length(row) != 1L) stop("Expected one control setting: ", pattern, call. = FALSE)
  suppressWarnings(as.numeric(strsplit(trimws(sub("#.*$", "", row)), "[[:space:]]+")[[1L]][1L]))
}
control_param <- function(name) {
  row <- grep(paste0("#_", name, "[[:space:]]*$"), control_lines, perl = TRUE, value = TRUE)
  if (length(row) != 1L) stop("Expected one control parameter: ", name, call. = FALSE)
  suppressWarnings(as.numeric(strsplit(trimws(sub("#.*$", "", row)), "[[:space:]]+")[[1L]]))
}

nat_female <- control_param("NatM_p_1_Fem_GP_1")
nat_male <- control_param("NatM_p_1_Mal_GP_1")
if (nat_female[7L] <= 0 || nat_male[7L] <= 0) stop("Expected sex-specific M parameters to be estimated.", call. = FALSE)
if (!identical(value_before("_natM_type"), 0) ||
    !identical(value_before("GrowthModel"), 1) ||
    !identical(value_before("maturity_option"), 1) ||
    !identical(value_before("fecundity option"), 2)) {
  stop("Control-file biology settings differ from the reviewed reference model.", call. = FALSE)
}

control_ref <- paste0(model_archive, ", controlfile.ctl; ")
data_ref <- paste0(model_archive, ", datafile.dat; ")
add_assumption("model", "software_version", "Stock Synthesis 3.30.21.00",
  source_reference = paste0(model_archive, ", data_echo.ss_new and Report.sso"),
  notes = "Official Oregon 2023 reference model run.")
add_assumption("model", "historical_years", "1892-2022", source_reference = data_ref,
  notes = "The model is annual; fitted observations end in 2022.")
add_assumption("model", "forecast_years", "2023-2034", source_reference = control_ref,
  notes = "Forecast years are retained in outputs and identified in notes; they are not fitted assessment years.")
add_assumption("model", "dimensions", "1 area; 1 season; 12 months per season; 2 sexes; ages 0-40",
  source_reference = data_ref, notes = "Age 40 is the accumulator group; the official report describes N-at-age in thousands of fish.")
add_assumption("model", "spawn_month", "1", source_reference = data_ref,
  notes = "January spawning month in the source model.")
add_assumption("biology", "growth_model", "1: von Bertalanffy", source_reference = control_ref,
  notes = "Sex-specific growth parameters are specified in the control file.")
add_assumption("biology", "maturity_option", "1: length logistic", source_reference = control_ref,
  notes = "Maturity is represented by the fitted length-based function, not a supplied maturity-at-age vector.")
add_assumption("biology", "fecundity_option", "2: eggs = a * length^b", source_reference = control_ref,
  notes = "Spawning output combines female weight, maturity, and fecundity per weight. The official report defines the output in billions of eggs.")
add_assumption("mortality", "natural_mortality_option", "0: one constant parameter per sex and growth pattern",
  source_reference = control_ref, notes = "The sex-specific parameters have positive estimation phases.")
add_assumption("mortality", "fitted_constant_M", "female=0.19; male=0.17 per year",
  source_reference = paste0(model_archive, ", Report.sso, Natural_Mortality report:43"),
  notes = "Fitted values are constant over age and year in the source report.")
add_assumption("recruitment", "spawner_recruit_function", "3: standard Beverton-Holt",
  source_reference = control_ref, notes = "Source control-file function code retained.")
add_assumption("recruitment", "main_deviation_years", "1988-2017",
  source_reference = control_ref, notes = "These are the main recruitment-deviation years in the source model.")
add_assumption("catch", "catch_se_field", "0.01 for all native rows",
  source_reference = paste0(model_archive, ", datafile.dat, Catch data"),
  notes = "Preserved as the native catch_se field; catch multipliers are disabled, so it is not represented as a separate catch likelihood SD.")
add_assumption("composition", "age_error_codes", paste(sort(unique(age_comp$age_error)), collapse = ", "),
  source_reference = paste0(model_archive, ", datafile.dat and controlfile.ctl"),
  notes = "The source row codes link to age-error definitions in the control file; raw frequencies and codes are retained.")
add_assumption("composition", "negative_fleet_codes", "-1, -2, -3",
  source_reference = paste0(model_archive, ", datafile.dat; ", manual_url),
  notes = "SS3 processes provisional length/age composition rows and calculates their expected values and log likelihood, but excludes their likelihood from the total objective.")
for (i in seq_len(nrow(fleet_info))) {
  add_assumption("fleet", "native_fleet_configuration",
    paste0("type=", fleet_info$type[i], "; timing=", fleet_info$timing[i],
      "; area=", fleet_info$area[i], "; catch_units=", fleet_info$catch_units[i],
      "; need_catch_mult=", fleet_info$need_catch_mult[i]),
    fleet = fleet_info$fleet_name[i], source_reference = data_ref,
    notes = "Raw Stock Synthesis fleet settings are preserved; survey-unit codes are recorded separately.")
}
for (i in seq_len(nrow(index_info))) {
  add_assumption("index", "native_units_and_error_type",
    paste0("units=", index_info$units[i], "; error_type=", index_info$error_type[i],
      "; sd_report=", index_info$sd_report[i]),
    survey = unname(fleet_names[as.character(index_info$fleet[i])]),
    source_reference = paste0(model_archive, ", datafile.dat, CPUE unit table"),
    notes = "Units code 0 means numbers, 1 means biomass; the physical multiplier is not inferred. Error type 0 is lognormal.")
}

input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumptions <- do.call(rbind, assumption_rows)
assumption_key <- do.call(paste, c(assumptions[
  c("component", "fleet", "survey", "sex", "region", "season", "setting")
], sep = "\r"))
if (anyDuplicated(assumption_key) > 0L) {
  stop("New source records contain duplicate assumption identifiers.", call. = FALSE)
}

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
stock_existing <- read_table(stocks_path)
assessment_existing <- read_table(assessments_path)
candidate <- read_table(candidate_path)
inventory <- read_table(inventory_path)
selected <- read_table(selected_path)
candidate_row <- which(candidate$candidate_id == candidate_id)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
selected_row <- which(selected$candidate_unit_id == candidate_unit_id)
if (length(candidate_row) != 1L || length(inventory_row) != 1L || length(selected_row) != 1L ||
    candidate$eligibility[candidate_row] != "eligible" ||
    !candidate$import_status[candidate_row] %in% c("not_started", "partial")) {
  stop("NOAA Stock SMART 14407 is missing, duplicated, or not ready for import.", call. = FALSE)
}
if (any(stock_existing$stock_id == stock_id) || any(assessment_existing$assessment_id == assessment_id)) {
  stop("NOAA Oregon Black Rockfish records already exist; inspect before importing.", call. = FALSE)
}
for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv"))) {
  header <- strsplit(readLines(path, n = 1L, warn = FALSE), ",")[[1L]]
  classes <- c("character", rep("NULL", length(header) - 1L))
  ids <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = classes)[[1L]]
  if (any(ids == assessment_id)) stop("Canonical observations already exist for ", assessment_id, call. = FALSE)
}

blank_row <- function(fields, values = list()) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
}

stock <- blank_row(names(stock_existing), list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "14407", scientific_name = "Sebastes melanops",
  common_name = "Black rockfish - Oregon", area = "Oregon", region = "Oregon",
  ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 14407. The current assessment unit is the Oregon stock, separate from Washington and California black rockfish. The assessment model is one area and two sexes."))
assessment <- blank_row(names(assessment_existing), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2022L, estimate_terminal_year = 2034L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.21.00",
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = report_url,
  framework_url = "https://www.pcouncil.org/documents/2023/11/stock-assessment-review-star-panel-report-for-black-rockfish.pdf/",
  data_url = archive_url, model_url = archive_url,
  repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Official 2023 Oregon production assessment fitted through 2022; the model archive projects through 2034.",
    "Native catch biomass, aggregate indices, raw length and age compositions, fitted N/F/M and biological surfaces, total biomass, recruitment, and spawning output are imported.",
    "Catch-at-age and age-specific survey-abundance indices are not direct likelihood inputs; age data are conditional on length for many rows, and negative-fleet provisional compositions are excluded from the total likelihood.",
    "Maturity is parametric and no standalone supplied maturity-at-age input was found. Age-specific uncertainty is unavailable; the official 2023 spawning-output interval is retained.")))

replace_csv_row <- function(path, key_column, key_value, row_index, row) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  current <- read_table(path)
  if (row_index > nrow(current) || as.character(current[[key_column]][row_index]) != key_value) {
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  }
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, what = "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) next_byte <- next_byte + 1L
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, replacement, after), path)
  updated <- read_table(path)
  if (nrow(updated) != nrow(current) || sum(as.character(updated[[key_column]]) == key_value) != 1L) {
    stop("Updated CSV failed identity checks: ", basename(path), call. = FALSE)
  }
}

append_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  utils::write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n", fileEncoding = "UTF-8")
}

candidate <- candidate[candidate_row, , drop = FALSE]
candidate$matched_stock_id <- stock_id
candidate$match_status <- "new"
candidate$import_status <- "partial"
candidate$catch_age_evidence <- paste("The 2023 native model archive contains annual catch biomass plus raw length and age compositions.",
  "Age composition is conditional on length in many rows.")
candidate$survey_age_evidence <- paste("Six aggregate lognormal index series are represented; five use the biomass scale and Tag uses the number scale.",
  "No age-specific survey-abundance index is supplied; the age-composition data remain separate.")
candidate$weights_evidence <- paste("The parametric model archive supplies generated annual beginning-/mid-season population weights and fleet-specific weights in wtatage.ss_new.",
  "These are fitted biological outputs, not separate observed weight-at-age inputs.")
candidate$maturity_evidence <- paste("Maturity is a sex-specific length-logistic function, with fecundity based on length.",
  "The source provides maturity*fecundity outputs but no standalone supplied maturity-at-age input.")
candidate$mortality_evidence <- "The source control file estimates one constant natural-mortality parameter by sex; Report.sso gives 0.19 female and 0.17 male per year."
candidate$timing_evidence <- "CPUE observations retain source month; sampling_time uses (month-1)/12. Composition month/season codes are preserved; no timing is assigned to fishery compositions."
candidate$output_evidence <- "The official archive contains sex-specific N-at-age, biomass-at-age, F-at-age, and M-at-age for 1892-2034, plus annual biomass, age-0 recruitment, and spawning output in billions of eggs. The report provides a 95% interval for 2023 spawning output; age-specific uncertainty is unavailable."
candidate$review_date <- "2026-11-03"
candidate$decision_reason <- "Eligible and selected as the Oregon current stock unit. The 2023 official production assessment has detailed report and model files; Oregon is kept separate from Washington and California."
candidate$notes <- "Partial native source import completed. The source model is annual, two-sex, ages 0-40, one area; catch-at-age and age-specific abundance indices were not fabricated."

inventory <- inventory[inventory_row, , drop = FALSE]
inventory$matched_stock_id <- stock_id
inventory$import_status <- "partial"
selected <- selected[selected_row, , drop = FALSE]
selected$curation_status <- "partial_source_import"

if (!dry_run) {
  append_rows(stocks_path, stock)
  append_rows(assessments_path, assessment)
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), output_data)
  append_rows(file.path(database, "assumptions.csv"), assumptions)
  replace_csv_row(candidate_path, "candidate_id", candidate_id, candidate_row, candidate)
  replace_csv_row(inventory_path, "unit_key", paste0("candidate:", candidate_unit_id), inventory_row, inventory)
  replace_csv_row(selected_path, "candidate_unit_id", candidate_unit_id, selected_row, selected)
}

cat(if (dry_run) "Dry run parsed " else "Imported ",
  nrow(input_data), " inputs, ", nrow(assumptions), " assumptions, and ",
  nrow(output_data), " outputs for the 2023 NOAA Oregon Black Rockfish assessment.\n", sep = "")
