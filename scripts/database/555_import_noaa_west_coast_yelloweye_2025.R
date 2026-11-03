root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_yelloweye_2025")
assessment_id <- "noaa_west_coast_yelloweye_2025"
stock_id <- "noaa_west_coast_yelloweye"
candidate_unit_id <- "noaa_stocksmart_10426"
candidate_id <- "NOAA:10426"
report_file <- "assessment_2025.pdf"
archive_file <- "model_files_2025.zip"
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
make_rows <- function(fields, values, n) {
  z <- lapply(fields, function(nm) {
    x <- values[[nm]]
    if (is.null(x)) return(rep("", n))
    x <- as.character(x); x[is.na(x)] <- ""; rep_len(x, n)
  })
  names(z) <- fields
  as.data.frame(z, stringsAsFactors = FALSE, optional = TRUE, check.names = FALSE)
}
input_fields <- read_fields(file.path(database, "inputs.csv"))
output_fields <- read_fields(file.path(database, "outputs.csv"))
assumption_fields <- read_fields(file.path(database, "assumptions.csv"))
make_input <- function(n, type, measure, basis, value, unit, year = NA_real_,
  year_basis = "calendar_year", age = NA_real_, fleet = "", survey = "", sex = "",
  region = "U.S. West Coast", season = "", sampling_time = NA_real_,
  source_reference, notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = NA_real_) {
  make_rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = year_basis, age = age, fleet = fleet, survey = survey,
    sex = sex, region = region, season = season, sampling_time = sampling_time,
    source_type = "native_model", source_reference = source_reference,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition), n)
}
make_output <- function(n, type, measure, value, unit, year = NA_real_,
  age = NA_real_, age_group = "", fleet = "", region = "U.S. West Coast",
  sex = "combined", se = NA_real_, lwr = NA_real_, upr = NA_real_,
  source_type = "native_model", source_reference, notes = "") {
  make_rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    age_group = age_group, fleet = fleet, survey = "", sex = sex,
    region = region, season = "", se = se, lwr = lwr, upr = upr,
    source_type = source_type, source_reference = source_reference,
    notes = notes), n)
}
assumptions <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "",
  fleet = "", survey = "", region = "U.S. West Coast") {
  assumptions[[length(assumptions) + 1L]] <<- make_rows(assumption_fields,
    list(assessment_id = assessment_id, component = component, setting = setting,
      value = value, source_reference = source_reference, notes = notes,
      fleet = fleet, survey = survey, region = region), 1L)
}
sha256_file <- function(path) {
  x <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
  h <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value = TRUE)))
  if (length(h) != 1L) stop("Could not calculate SHA-256: ", path, call. = FALSE)
  h
}
manifest <- read_csv(file.path(cache, "sources.csv"))
verify_cached <- function(file, path) {
  x <- manifest[manifest$source == file, , drop = FALSE]
  if (nrow(x) != 1L || !file.exists(path) ||
      tolower(x$sha256) != sha256_file(path) ||
      as.numeric(x$bytes) != file.info(path)$size)
    stop("Cached source differs from manifest: ", file, call. = FALSE)
  path
}
verify_cached(report_file, file.path(cache, report_file))
verify_cached(archive_file, file.path(cache, archive_file))
data_file <- file.path(cache, "yelloweye_data.ss")
control_file <- file.path(cache, "yelloweye_control.ss")
report_output <- file.path(cache, "Report.sso")
for (path in c(data_file, control_file, report_output))
  if (!file.exists(path)) stop("Missing cached native model file: ", basename(path), call. = FALSE)

read_numeric_block <- function(lines, marker, n_fields, regex = FALSE) {
  p <- if (regex) grep(marker, trimws(lines), perl = TRUE) else which(trimws(lines) == marker)
  if (length(p) != 1L) stop("Expected one data block: ", marker, call. = FALSE)
  rows <- list()
  for (i in seq.int(p + 1L, length(lines))) {
    s <- strsplit(trimws(sub("#.*$", "", lines[i])), "[[:space:]]+")[[1L]]
    if (!length(s) || !nzchar(s[1L])) next
    if (s[1L] == "-9999") break
    if (length(s) != n_fields) stop("Unexpected field count in ", marker, call. = FALSE)
    v <- suppressWarnings(as.numeric(s))
    if (anyNA(v)) stop("Invalid numeric source value in ", marker, call. = FALSE)
    rows[[length(rows) + 1L]] <- v
  }
  if (!length(rows)) stop("No source rows in ", marker, call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}
read_fleets <- function(lines) {
  a <- which(trimws(lines) == "#_fleetinfo")
  b <- which(trimws(lines) == "#_Catch data")
  z <- lines[seq.int(a + 1L, b - 1L)]
  z <- z[grepl("^[[:space:]]*[0-9]+[[:space:]]", z)]
  z <- lapply(z, function(s) strsplit(trimws(sub("#.*$", "", s)), "[[:space:]]+")[[1L]])
  d <- as.data.frame(do.call(rbind, lapply(z, function(x) c(as.numeric(x[1:5]), x[6L]))))
  names(d) <- c("type", "timing", "area", "units", "catch_mult", "name")
  for (nm in names(d)[1:5]) d[[nm]] <- as.numeric(d[[nm]])
  d
}
read_index_info <- function(lines) {
  a <- which(trimws(lines) == "#_CPUE_and_surveyabundance_observations")
  b <- which(trimws(lines) == "#_CPUE_data")
  z <- lines[seq.int(a + 4L, b - 1L)]
  z <- z[grepl("^[[:space:]]*[0-9]+[[:space:]]", z)]
  d <- as.data.frame(do.call(rbind, lapply(z, function(s)
    as.numeric(strsplit(trimws(sub("#.*$", "", s)), "[[:space:]]+")[[1L]]))))
  names(d) <- c("fleet", "units", "error", "sd_report")
  d
}
data_lines <- readLines(data_file, warn = FALSE)
fleet_info <- read_fleets(data_lines)
fleet_names <- setNames(fleet_info$name, seq_len(nrow(fleet_info)))
index_info <- read_index_info(data_lines)
catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "season", "fleet", "catch", "catch_se")
catch <- catch[catch$year >= 1889, , drop = FALSE]
cpue <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(cpue) <- c("year", "month", "fleet", "observation", "se_log")
length_comp <- read_numeric_block(data_lines, "#_lencomp", 39L)
names(length_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "sample_size", paste0("l", seq(10, 74, 2)))
age_comp <- read_numeric_block(data_lines,
  "^#_year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr",
  75L, TRUE)
names(age_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "age_error", "length_lower", "length_upper", "sample_size", paste0("a", 0:65))
checks <- c(
  fleets = nrow(fleet_info) == 12L,
  index_units = nrow(index_info) == 12L,
  catch = nrow(catch) == 952L,
  cpue = nrow(cpue) == 150L,
  lencomp = nrow(length_comp) == 354L,
  agecomp = nrow(age_comp) == 2213L,
  catch_years = min(catch$year) == 1889 && max(catch$year) == 2024,
  catch_fleets = identical(sort(unique(as.integer(catch$fleet))), 1:7),
  cpue_years = min(cpue$year) == 1980 && max(cpue$year) == 2024,
  cpue_fleets = identical(sort(unique(as.integer(cpue$fleet))), c(3L, 6L, 7L, 8L, 9L, 10L, 11L, 12L)),
  composition_years = min(length_comp$year) == 1978 && max(length_comp$year) == 2024 &&
    min(age_comp$year) == 1978 && max(age_comp$year) == 2024,
  catch_units = all(fleet_info$units[1:6] == 1) && fleet_info$units[7] == 2,
  index_error = all(index_info$error == 0),
  index_scales = all(index_info$units %in% 0:1),
  catch_se = all(catch$catch_se == 0.01),
  composition_sex = all(length_comp$sex_code == 0) && all(age_comp$sex_code == 0))
if (!all(checks)) stop("Input structure checks failed: ",
  paste(names(checks)[!checks], collapse = ", "), call. = FALSE)
if (any(catch$catch < 0) || any(cpue$observation <= 0 | cpue$se_log <= 0) ||
    any(length_comp$sample_size <= 0) || any(age_comp$sample_size <= 0) ||
    any(as.matrix(length_comp[, paste0("l", seq(10, 74, 2))]) < 0) ||
    any(as.matrix(age_comp[, paste0("a", 0:65)]) < 0))
  stop("Invalid native observations.", call. = FALSE)

input_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
catch_names <- unname(fleet_names[as.character(as.integer(catch$fleet))])
catch_units <- fleet_info$units[as.integer(catch$fleet)]
add_input(make_input(nrow(catch), type = "catch",
  measure = ifelse(catch_units == 1, "total_biomass", "total_numbers"),
  basis = ifelse(catch_units == 1, "biomass", "numbers"), value = catch$catch,
  unit = ifelse(catch_units == 1, "metric tonnes",
    "native SS3 numbers (multiplier not stated)"), year = catch$year,
  fleet = catch_names, source_reference = paste0(archive_file, ", yelloweye_data.ss, Catch data"),
  notes = "Native annual catch. Fleet units follow the Stock Synthesis fleet configuration; fleet 7 is stored in native number scale because no external multiplier was identified."))
for (i in seq_len(nrow(cpue))) {
  code <- as.integer(cpue$fleet[i])
  unit_code <- index_info$units[match(code, index_info$fleet)]
  series <- unname(fleet_names[as.character(code)])
  timing <- (cpue$month[i] - 1) / 12
  measure <- if (unit_code == 0) "relative_abundance_index" else "relative_biomass_index"
  unit <- paste0("native SS3 ", if (unit_code == 0) "number" else "biomass",
    " index units (unit code ", unit_code, "; multiplier not stated)")
  season <- paste0("month ", format(cpue$month[i], trim = TRUE))
  add_input(make_input(1L, "index", measure, "index_scale", cpue$observation[i],
    unit, year = cpue$year[i], survey = series, season = season,
    sampling_time = timing, source_reference = paste0(archive_file,
      ", yelloweye_data.ss, CPUE_data"),
    notes = "Native aggregate lognormal index; source observation month retained and sampling_time=(month-1)/12."))
  add_input(make_input(1L, "index", "log_index_sd", "log_scale", cpue$se_log[i],
    "log-scale standard error", year = cpue$year[i], survey = series,
    season = season, sampling_time = timing,
    source_reference = paste0(archive_file, ", yelloweye_data.ss, CPUE_data se_log"),
    notes = "Native standard error on the log-index scale; fleet error type 0 is lognormal."))
}
composition_rows <- function(x, age = FALSE) {
  bins <- if (age) 0:65 else seq(10, 74, 2)
  result <- vector("list", nrow(x))
  for (i in seq_len(nrow(x))) {
    code <- as.integer(x$sex_code[i])
    sex <- switch(as.character(code), "0" = "combined", "1" = "female",
      "2" = "male", stop("Unexpected composition sex code.", call. = FALSE))
    signed_fleet <- as.integer(x$fleet[i])
    fleet_code <- abs(signed_fleet)
    fleet <- unname(fleet_names[as.character(fleet_code)])
    if (is.na(fleet)) stop("Unmapped composition fleet.", call. = FALSE)
    is_fishery <- fleet_info$type[fleet_code] == 1
    month <- x$month[i]
    note <- if (age) "Raw native age-frequency vector; age bins 0-65, source sample size and age-error code retained."
      else "Raw native length-frequency vector; bins are 2 cm lower edges 10-74 cm."
    if (age && (x$length_lower[i] >= 0 || x$length_upper[i] >= 0))
      note <- paste(note, "The source length interval identifies conditional age-at-length data.")
    if (age && x$length_lower[i] < 0 && x$length_upper[i] < 0)
      note <- paste(note, "The source length interval is -1/-1, identifying a marginal age composition.")
    if (signed_fleet < 0L)
      note <- paste(note, "Negative signed fleet code is retained in this note; SS3 treats this composition as provisional and excludes its likelihood from the total objective.")
    result[[i]] <- make_input(length(bins),
      type = if (is_fishery) "catch" else "index",
      measure = if (age) "frequency_at_age" else "frequency_at_length",
      basis = "native_frequency", value = as.numeric(x[i, paste0(if (age) "a" else "l", bins), drop = TRUE]),
      unit = "source frequency weight", year = x$year[i],
      age = if (age) bins else NA_real_, fleet = if (is_fishery) fleet else "",
      survey = if (is_fishery) "" else fleet, sex = sex,
      region = if (fleet_info$area[fleet_code] == 1) "California" else "Oregon/Washington",
      season = paste0("month ", format(month, trim = TRUE)),
      sampling_time = (month - 1) / 12,
      source_reference = paste0(archive_file, ", yelloweye_data.ss, ", if (age) "agecomp" else "lencomp"),
      notes = note, observation_id = paste0(if (age) "agecomp-" else "lencomp-", i),
      length_bin = if (age) NA_real_ else bins,
      length_bin_lower = if (age) x$length_lower[i] else bins,
      length_bin_upper = if (age) x$length_upper[i] else bins + 2,
      sample_size = x$sample_size[i], age_error = if (age) x$age_error[i] else NA_real_,
      partition = x$partition[i])
  }
  do.call(rbind, result)
}
add_input(composition_rows(length_comp))
add_input(composition_rows(age_comp, TRUE))

report_lines <- readLines(report_output, warn = FALSE)
read_report <- function(name, header_pattern) {
  marker <- tail(which(startsWith(trimws(report_lines), paste0(name, " report:"))), 1L)
  header <- grep(header_pattern, report_lines, perl = TRUE)
  header <- header[header > marker][1L]
  ends <- grep(" report:", report_lines, fixed = TRUE)
  end <- ends[ends > header][1L]
  if (is.na(marker) || is.na(header) || is.na(end))
    stop("Could not parse report table ", name, call. = FALSE)
  body <- report_lines[header:(end - 1L)]
  body <- body[!grepl("^[[:space:]]*#", body)]
  utils::read.table(text = body, header = TRUE, check.names = FALSE,
    stringsAsFactors = FALSE, quote = "", comment.char = "")
}
long_age <- function(x, columns) data.frame(
  row = rep(seq_len(nrow(x)), each = length(columns)),
  age = rep(as.integer(columns), times = nrow(x)),
  value = as.vector(t(as.matrix(x[, columns, drop = FALSE]))))
n <- read_report("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
b <- read_report("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
m <- read_report("Natural_Mortality", "^Area Bio_Pattern Sex")
f <- read_report("F_AT_AGE", "^Area Fleet Sex")
catch_age <- read_report("CATCH_AT_AGE", "^Area Fleet Sex")
annual <- read_report("TIME_SERIES", "^Area Yr Era")
weight <- read_report("MEAN_BODY_WT(Begin)", "^Morph Yr Seas")
years <- 1889:2036
eras <- c("TIME", "FORE")
keep_population <- function(x) x$Area %in% 1:2 & x$Bio_Pattern == 1 &
  x$Sex == 1 & x$Morph == 1 & x$BirthSeas == 1 & x$Settlement == 1 &
  x$Platoon == 1 & x$Seas == 1 & x[["Beg/Mid"]] == "B" &
  x$Era %in% eras & x$Yr %in% years
n <- n[keep_population(n), , drop = FALSE]
b <- b[keep_population(b), , drop = FALSE]
m <- m[keep_population(m), , drop = FALSE]
f <- f[f$Area %in% 1:2 & f$Fleet %in% 1:7 & f$Sex == 1 & f$Morph == 1 &
  f$Seas == 1 & f$Era %in% eras & f$Yr %in% years, , drop = FALSE]
catch_age <- catch_age[catch_age$Area %in% 1:2 & catch_age$Fleet %in% 1:7 &
  catch_age$Sex == 1 & catch_age$Type == "dead" & catch_age$Morph == 1 &
  catch_age$Seas == 1 & catch_age$Era %in% eras & catch_age$Yr %in% years, , drop = FALSE]
annual <- annual[annual$Area %in% 1:2 & annual$Era %in% eras & annual$Yr %in% years, , drop = FALSE]
weight <- weight[weight$Morph == 1 & weight$Seas == 1 & weight$Yr %in% years, , drop = FALSE]
actual <- c(numbers = nrow(n), biomass_at_age = nrow(b), natural_mortality = nrow(m),
  fishing_mortality = nrow(f), catch_at_age = nrow(catch_age), annual = nrow(annual),
  weight_at_age = nrow(weight))
expected <- c(numbers = 296L, biomass_at_age = 296L, natural_mortality = 296L,
  fishing_mortality = 1036L, catch_at_age = 1036L, annual = 296L, weight_at_age = 148L)
if (!identical(actual, expected) || !identical(sort(unique(as.integer(n$Yr))), years) ||
    !identical(sort(unique(as.integer(n$Area))), 1:2))
  stop("Report output dimensions/year coverage differ from the reviewed bundle.", call. = FALSE)
if (!all(abs(unique(as.numeric(unlist(m[as.character(0:100)]))) - 0.0439034) < 1e-7))
  stop("Reported natural-mortality values differ from the pinned base model.", call. = FALSE)

output_rows <- list()
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
report_ref <- paste0(archive_file, ", Report.sso, ")
area_names <- c("1" = "California", "2" = "Oregon/Washington")
age_specs <- list(
  list(n, "population", "numbers_at_age", "thousand fish", "NUMBERS_AT_AGE report:35",
    "Beginning-of-year numbers at age; area-specific; age 100 is the terminal model age bin."),
  list(b, "biomass", "biomass_at_age", "metric tonnes", "BIOMASS_AT_AGE report:36",
    "Beginning-of-year biomass at age; area-specific; age 100 is the terminal model age bin."),
  list(m, "mortality", "natural_mortality_at_age", "per year", "Natural_Mortality report:43",
    "Fixed natural-mortality surface; age 100 is the terminal model age bin."),
  list(catch_age, "catch", "numbers_at_age", "thousand fish", "CATCH_AT_AGE report:40",
    "Fitted dead-catch numbers at age by fishery; model output, not an observed catch-at-age input."))
for (spec in age_specs) {
  x <- spec[[1L]]; z <- long_age(x, as.character(0:100))
  region <- if ("Area" %in% names(x)) unname(area_names[as.character(x$Area[z$row])]) else "U.S. West Coast"
  fleet <- if ("Fleet" %in% names(x)) unname(fleet_names[as.character(x$Fleet[z$row])]) else ""
  note <- ifelse(x$Era[z$row] == "FORE", paste0(spec[[6L]], " Era FORE denotes projections."), spec[[6L]])
  add_output(make_output(nrow(z), spec[[2L]], spec[[3L]], z$value, spec[[4L]],
    year = x$Yr[z$row], age = z$age, fleet = fleet, region = region,
    source_reference = paste0(report_ref, spec[[5L]]), notes = note))
}
z <- long_age(f, as.character(0:100))
add_output(make_output(nrow(z), "mortality", "fishing_mortality_at_age", z$value,
  "per year", year = f$Yr[z$row], age = z$age,
  fleet = unname(fleet_names[as.character(f$Fleet[z$row])]),
  region = unname(area_names[as.character(f$Area[z$row])]),
  source_reference = paste0(report_ref, "F_AT_AGE report:39"),
  notes = ifelse(f$Era[z$row] == "FORE", "Fitted fleet fishing mortality; Era FORE denotes projections.",
    "Fitted fleet fishing mortality by area.")))
z <- long_age(weight, as.character(0:100))
add_output(make_output(nrow(z), "biology", "weight_at_age", z$value, "kg per fish",
  year = weight$Yr[z$row], age = z$age,
  source_reference = paste0(report_ref, "MEAN_BODY_WT(Begin) report:48"),
  notes = ifelse(weight$Yr[z$row] > 2024,
    "Model-generated beginning-of-year weight; shared across the two areas; Era FORE denotes projections; not an observed weight-at-age input.",
    "Model-generated beginning-of-year weight; shared across the two areas; not an observed weight-at-age input.")))

for (measure in c("total_biomass", "spawning_output", "recruitment")) {
  value <- switch(measure, total_biomass = annual$Bio_all,
    spawning_output = annual$SpawnBio, recruitment = annual$Recruit_0)
  unit <- switch(measure, total_biomass = "metric tonnes",
    spawning_output = "billion eggs", recruitment = "thousand fish")
  type <- switch(measure, total_biomass = "biomass",
    spawning_output = "biomass", recruitment = "recruitment")
  lower <- upper <- rep(NA_real_, nrow(annual))
  source_type <- rep("native_model", nrow(annual))
  ref <- rep(paste0(report_ref, "TIME_SERIES report:16"), nrow(annual))
  if (measure == "spawning_output") {
    use <- annual$Yr == 2025
    if (sum(use) != 2L || abs(sum(value[use]) - 477.63) > 0.02)
      stop("2025 spawning output does not match the official reported sum.", call. = FALSE)
  }
  add_output(make_output(nrow(annual), type, measure, value, unit,
    year = annual$Yr, region = unname(area_names[as.character(annual$Area)]),
    lwr = lower, upr = upper, source_type = source_type,
    source_reference = ref,
    notes = if (measure == "spawning_output")
      "Native SpawnBio is retained by area. Table 20 uncertainty applies to the coastwide estimate and is stored only on the derived coastwide row. FORE years are projections."
    else if (measure == "recruitment")
      "Native Recruit_0 is age-0 recruitment in thousands of fish, retained by area. FORE years are projections."
    else "Native Bio_all is beginning-of-year biomass in metric tonnes, retained by area. FORE years are projections."))
}
aggregate_age <- function(x, measure, type, unit, reference, note) {
  z <- long_age(x, as.character(0:100))
  value <- aggregate(z$value, list(year = x$Yr[z$row], age = z$age), sum)
  make_output(nrow(value), type, measure, value$x, unit, year = value$year,
    age = value$age, region = "U.S. West Coast", source_type = "derived_source_output",
    source_reference = paste0(report_ref, reference),
    notes = note)
}
add_output(aggregate_age(n, "numbers_at_age", "population", "thousand fish",
  "NUMBERS_AT_AGE report:35", "Derived coastwide by summing the two area surfaces; no uncertainty was calculated."))
add_output(aggregate_age(b, "biomass_at_age", "biomass", "metric tonnes",
  "BIOMASS_AT_AGE report:36", "Derived coastwide by summing the two area surfaces; no uncertainty was calculated."))
n_long <- long_age(n, as.character(0:100))
total_n <- aggregate(n_long$value, list(year = n$Yr[n_long$row]), sum)
add_output(make_output(nrow(total_n), "population", "total_numbers", total_n$x,
  "thousand fish", year = total_n$year, region = "U.S. West Coast",
  source_type = "derived_source_output", source_reference = paste0(report_ref, "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing beginning-of-year N across both areas and ages 0-100; no uncertainty was calculated."))
for (measure in c("total_biomass", "spawning_output", "recruitment")) {
  value <- switch(measure, total_biomass = annual$Bio_all,
    spawning_output = annual$SpawnBio, recruitment = annual$Recruit_0)
  total <- aggregate(value, list(year = annual$Yr), sum)
  unit <- switch(measure, total_biomass = "metric tonnes",
    spawning_output = "billion eggs", recruitment = "thousand fish")
  type <- switch(measure, total_biomass = "biomass",
    spawning_output = "biomass", recruitment = "recruitment")
  lower <- upper <- rep(NA_real_, nrow(total))
  source_type <- rep("derived_source_output", nrow(total))
  reference <- rep(paste0(report_ref, "TIME_SERIES report:16"), nrow(total))
  if (measure == "spawning_output") {
    use <- total$year == 2025
    lower[use] <- 384
    upper[use] <- 571
    reference[use] <- paste0(reference[use], "; ",
      manifest$url[match(report_file, manifest$source)], ", Table 20")
  }
  add_output(make_output(nrow(total), type, measure, total$x, unit,
    year = total$year, region = "U.S. West Coast",
    lwr = lower, upr = upper, source_type = source_type,
    source_reference = reference,
    notes = if (measure == "spawning_output")
      "Derived coastwide by summing area SpawnBio outputs. Table 20 reports the 2025 coastwide estimate rounded to 478 billion eggs and its 95% interval; bundle value is 477.63. No uncertainty is calculated for other years."
    else "Derived coastwide by summing California and Oregon/Washington area values; no uncertainty was calculated."))
}

source_ref <- paste0(archive_file, ", yelloweye_data.ss and yelloweye_control.ss; ")
for (i in seq_len(nrow(fleet_info))) add_assumption("fleet", "native_fleet_configuration",
  paste0("type=", fleet_info$type[i], "; timing=", fleet_info$timing[i],
    "; area=", fleet_info$area[i], "; units=", fleet_info$units[i],
    "; catch multiplier=", fleet_info$catch_mult[i]),
  source_reference = paste0(archive_file, ", yelloweye_data.ss, fleetinfo"),
  fleet = fleet_info$name[i], region = if (fleet_info$area[i] == 1) "California" else "Oregon/Washington",
  notes = paste0("Native Stock Synthesis fleet code ", i, "."))
add_assumption("model", "model_run", "Official 2025 update; pinned Stock Synthesis output bundle 3.30.23.2",
  source_reference = paste0(archive_file, ", Report.sso and ss_summary.sso"),
  notes = "The assessment is adopted for 2025 advice and is fitted through 2024; projections extend through 2036.")
add_assumption("model", "historical_years", "1889-2024", source_ref,
  "Native model catch years start in 1889; fitted data end in 2024.")
add_assumption("model", "reported_years", "1889-2036", paste0(report_ref, "NUMBERS_AT_AGE and TIME_SERIES"),
  "TIME and FORE years are retained; 2025-2036 are forecasts.")
add_assumption("model", "dimensions", "2 areas; 1 sex; 1 season; model ages 0-100",
  source_ref, "Areas are California and Oregon/Washington; spawning month is January.")
add_assumption("model", "area_mapping", "1=California; 2=Oregon/Washington",
  paste0(archive_file, ", yelloweye_data.ss, fleetinfo and Report.sso"),
  "Area names are taken from the native fleet configuration and report dimensions.")
add_assumption("catch", "native_catch_series", "Annual catch by seven fleets; fleets 1-6 biomass, fleet 7 numbers",
  paste0(archive_file, ", yelloweye_data.ss, Catch data and fleetinfo"),
  "Catch-at-age is a fitted report surface, not an observed annual catch-at-age input.")
add_assumption("catch", "catch_se_field", "0.01 for all 1889-2024 native catch rows",
  paste0(archive_file, ", yelloweye_data.ss, Catch data"),
  "Native SS3 catch_se field is preserved as source setting; no conversion to another error scale is applied.")
add_assumption("index", "native_index_units", "Eight aggregate index series; unit codes 0=numbers, 1=biomass; all use lognormal error type 0",
  paste0(archive_file, ", yelloweye_data.ss, CPUE unit table"),
  "Physical multipliers are not stated; input values are preserved on their native index scales.")
add_assumption("index", "survey_timing", "Observation month retained; sampling_time=(month-1)/12",
  paste0(archive_file, ", yelloweye_data.ss, CPUE_data"),
  "Fractional year is calculated from each observed month without rounding.")
add_assumption("composition", "length_composition", "Raw 2 cm length frequencies; bins 10-74 cm lower edges",
  paste0(archive_file, ", yelloweye_data.ss, lencomp"),
  "Raw frequencies, source sample size, month, fleet, sex code, and partition are retained.")
add_assumption("composition", "age_composition", "Raw age frequencies in native bins 0-65; marginal and conditional age-at-length observations",
  paste0(archive_file, ", yelloweye_data.ss, agecomp"),
  "Raw frequencies, source sample size, age-error code, length interval, month, fleet, sex code, partition, and signed fleet are retained; these are not annual catch-at-age or age-specific abundance observations.")
add_assumption("composition", "negative_fleet_codes",
  paste(sort(unique(age_comp$fleet[age_comp$fleet < 0])), collapse = ", "),
  paste0(archive_file, ", yelloweye_data.ss; Stock Synthesis manual"),
  "Negative signed fleet codes are preserved; SS3 treats these compositions as provisional and excludes their likelihood from the total objective.")
add_assumption("mortality", "natural_mortality", "Fixed M = 0.0439034 per year",
  paste0(report_ref, "Natural_Mortality report:43 and yelloweye_control.ss"),
  "The report surface is constant across age, area, and year; the control parameter has a fixed phase.")
add_assumption("biology", "growth_model", "Von Bertalanffy with fitted growth parameters",
  paste0(archive_file, ", yelloweye_control.ss, GrowthModel and growth_parms"),
  "Growth is represented parametrically; reported weights-at-age are model-generated outputs.")
add_assumption("biology", "maturity", "Length-logistic; first mature age 2; length at 50% maturity 42.0705 cm; slope -0.402214",
  paste0(archive_file, ", yelloweye_control.ss, maturity and growth_parms"),
  "Maturity is fixed in the base model; no standalone observed maturity-at-age input vector is present.")
add_assumption("biology", "fecundity", "Egg production follows a*length^b",
  paste0(archive_file, ", yelloweye_control.ss, fecundity option and growth_parms"),
  "The model reports spawning output in billions of eggs; this is not labelled SSB.")
add_assumption("recruitment", "spawner_recruit_function", "Standard Beverton-Holt",
  paste0(archive_file, ", yelloweye_control.ss, Spawner-Recruitment"),
  "Stock-recruit steepness is fixed at 0.72 in the base model.")
add_assumption("recruitment", "steepness", "0.72 fixed",
  paste0(archive_file, ", yelloweye_control.ss, SR_BH_steep"),
  "Control-file parameter phase is fixed.")

input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumptions)
key <- do.call(paste, c(assumption_data[c("component", "fleet", "survey", "sex", "region", "season", "setting")], sep = "\r"))
if (anyDuplicated(key)) stop("Duplicate assumption keys are present.", call. = FALSE)

stocks_path <- file.path(database, "stocks.csv")
assessments_path <- file.path(database, "assessments.csv")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
stocks <- read_csv(stocks_path); assessments <- read_csv(assessments_path)
candidate <- read_csv(candidate_path); inventory <- read_csv(inventory_path)
selected <- read_csv(selected_path)
ci <- which(candidate$candidate_id == candidate_id)
ii <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
si <- which(selected$candidate_unit_id == candidate_unit_id)
if (length(ci) != 1L || length(ii) != 1L || length(si) != 1L ||
    candidate$eligibility[ci] != "eligible" ||
    !candidate$import_status[ci] %in% c("not_started", "partial"))
  stop("Candidate is missing, duplicated, or not eligible.", call. = FALSE)
if (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id))
  stop("Yelloweye rockfish records already exist; inspect before importing.", call. = FALSE)
first_column <- function(path) {
  fields <- read_fields(path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", length(fields) - 1L)))[[1L]]
}
for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv")))
  if (assessment_id %in% first_column(path))
    stop("Observations already exist for this assessment.", call. = FALSE)
blank_row <- function(fields, values) {
  x <- as.list(rep("", length(fields))); names(x) <- fields
  for (nm in names(values)) x[[nm]] <- as.character(values[[nm]])
  as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks), list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "10426", scientific_name = "Sebastes ruberrimus",
  common_name = "Yelloweye rockfish - U.S. West Coast",
  area = "U.S. West Coast (California, Oregon/Washington)", region = "U.S. West Coast",
  ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10426. Current U.S. West Coast unit; distinct from Gulf of Alaska and Canadian inside/outside Yelloweye units."))
report_url <- manifest$url[match(report_file, manifest$source)]
model_url <- manifest$url[match(archive_file, manifest$source)]
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2036L,
  assessment_type = "update", model_family = "Stock Synthesis", model_version = "3.30.23.2",
  is_current = TRUE, is_applied = TRUE,
  assessment_url = report_url,
  framework_url = "",
  data_url = model_url, model_url = model_url,
  repository_url = "https://github.com/pfmc-assessments/Sebastes_ruberrimus_2025/tree/9356e8267c23a1a5d33bb76f261fcd5622db062c",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Official 2025 production update fitted through 2024; native estimates and forecasts extend through 2036.",
    "Native catch, aggregate indices, raw length and age compositions, fitted N/F/M/catch-at-age and model-generated biological surfaces are recorded.",
    "Direct catch-at-age and age-specific abundance observations are not supplied. Weight-at-age is model generated; maturity is represented by a fixed length schedule, not a standalone age vector.",
    "The coastwide 2025 spawning-output interval is retained; age-specific uncertainty is unavailable.")))
replace_csv_row <- function(path, key_column, key_value, row_index, row) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes); record_index <- as.integer(row_index) + 1L
  current <- read_csv(path)
  if (row_index > nrow(current) || as.character(current[[key_column]][row_index]) != key_value)
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  temporary <- tempfile(fileext = ".csv"); on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  first <- bounds$start[record_index]; last <- bounds$end[record_index]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) next_byte <- next_byte + 1L
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, as.raw(10L)); last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, replacement, after), path)
  updated <- read_csv(path)
  if (nrow(updated) != nrow(current) || sum(as.character(updated[[key_column]]) == key_value) != 1L)
    stop("Updated CSV failed identity checks: ", basename(path), call. = FALSE)
}
append_rows <- function(path, rows) if (nrow(rows)) utils::write.table(rows,
  file = path, sep = ",", row.names = FALSE, col.names = FALSE, quote = TRUE,
  qmethod = "double", na = "", append = TRUE, eol = "\n", fileEncoding = "UTF-8")
candidate_row <- candidate[ci, , drop = FALSE]
candidate_row$matched_stock_id <- stock_id
candidate_row$match_status <- "new"
candidate_row$import_status <- "partial"
candidate_row$catch_age_evidence <- "The 2025 native model supplies annual catch totals and raw age compositions, including conditional age-at-length samples; it does not supply annual observed catch-at-age."
candidate_row$survey_age_evidence <- "Eight aggregate lognormal indices are retained; no age-specific abundance index is supplied. Age compositions remain separate sample observations."
candidate_row$weights_evidence <- "Report.sso contains model-generated beginning-of-year weight-at-age, shared across areas; no standalone observed weight-at-age input was identified."
candidate_row$maturity_evidence <- "The fixed base model uses a length-logistic maturity schedule; no standalone maturity-at-age input vector was identified."
candidate_row$mortality_evidence <- "Natural mortality is fixed at 0.0439034 per year in the native control/output surface."
candidate_row$timing_evidence <- "Index and composition observation months are retained; sampling_time=(month-1)/12 for each record."
candidate_row$output_evidence <- "Pinned output includes area-specific N/B/M, fleet F and catch-at-age through 2036, annual biomass, spawning output and recruitment; 2025 coastwide spawning-output interval is reported."
candidate_row$review_date <- "2026-11-03"
candidate_row$decision_reason <- "Imported the current U.S. West Coast Yelloweye unit from the adopted 2025 production update and its pinned native Stock Synthesis output bundle."
candidate_row$notes <- "Partial source import completed. No observed annual catch-at-age, age-specific index, standalone weight-at-age, or maturity-at-age vector was fabricated."
inventory_row <- inventory[ii, , drop = FALSE]
inventory_row$matched_stock_id <- stock_id
inventory_row$import_status <- "partial"
selected_row <- selected[si, , drop = FALSE]
selected_row$curation_status <- "partial_source_import"
if (!dry_run) {
  append_rows(stocks_path, stock); append_rows(assessments_path, assessment)
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), output_data)
  append_rows(file.path(database, "assumptions.csv"), assumption_data)
  replace_candidate_register_row(candidate_path, ci, candidate_row, candidate_id)
  replace_csv_row(inventory_path, "unit_key", paste0("candidate:", candidate_unit_id), ii, inventory_row)
  replace_csv_row(selected_path, "candidate_unit_id", candidate_unit_id, si, selected_row)
}
cat(if (dry_run) "Dry run parsed " else "Imported ", nrow(input_data),
  " inputs, ", nrow(assumption_data), " assumptions, and ", nrow(output_data),
  " outputs for the 2025 NOAA West Coast Yelloweye Rockfish assessment.\n", sep = "")
