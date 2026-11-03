root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "noaa_pacific_coast_widow_rockfish_20261029")
model_dir <- file.path(cache, "model_files")
assessment_id <- "noaa_west_coast_widow_2025"
stock_id <- "noaa_west_coast_widow"
candidate_unit_id <- "noaa_stocksmart_10568"
candidate_id <- "NOAA:10568"
report_file <- "2025_Widow_Rockfish_Assessment.pdf"
archive_file <- "Widow_Rockfish_2025_Model_Files.zip"
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
  year_basis = "calendar_year", age = NA_real_, fleet = "", survey = "", sex = "", season = "",
  sampling_time = NA_real_, source_reference, notes = "", observation_id = "",
  length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
  sample_size = NA_real_, age_error = NA_real_, partition = NA_real_) {
  make_rows(input_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, basis = basis, value = value, unit = unit, year = year,
    year_basis = year_basis,
    age = age, fleet = fleet, survey = survey, sex = sex, region = "U.S. West Coast",
    season = season, sampling_time = sampling_time, source_type = "native_model",
    source_reference = source_reference, notes = notes, observation_id = observation_id,
    length_bin = length_bin, length_bin_lower = length_bin_lower,
    length_bin_upper = length_bin_upper, sample_size = sample_size,
    age_error = age_error, partition = partition), n)
}
make_output <- function(n, type, measure, value, unit, year = NA_real_, age = NA_real_,
  age_group = "", fleet = "", sex = "", se = NA_real_, lwr = NA_real_, upr = NA_real_,
  source_type = "native_model", source_reference, notes = "") {
  make_rows(output_fields, list(assessment_id = assessment_id, type = type,
    measure = measure, value = value, unit = unit, year = year, age = age,
    age_group = age_group, fleet = fleet, survey = "", sex = sex,
    region = "U.S. West Coast", season = "", se = se, lwr = lwr, upr = upr,
    source_type = source_type, source_reference = source_reference, notes = notes), n)
}
assumptions <- list()
add_assumption <- function(component, setting, value, source_reference, notes = "",
  fleet = "", survey = "", sex = "") {
  assumptions[[length(assumptions) + 1L]] <<- make_rows(assumption_fields,
    list(assessment_id = assessment_id, component = component, setting = setting,
      value = value, source_reference = source_reference, notes = notes,
      fleet = fleet, survey = survey, sex = sex, region = "U.S. West Coast"), 1L)
}
sha256_file <- function(path) {
  x <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
  h <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", x, value = TRUE)))
  if (length(h) != 1L) stop("Could not calculate SHA-256: ", path, call. = FALSE)
  h
}
manifest <- read_csv(file.path(cache, "sources.csv"))
verify_cached <- function(file, path) {
  x <- manifest[manifest$source_file == file, , drop = FALSE]
  if (nrow(x) != 1L || !file.exists(path) || tolower(x$sha256) != sha256_file(path))
    stop("Cached source differs from manifest: ", file, call. = FALSE)
  path
}
verify_cached(report_file, file.path(cache, report_file))
verify_cached(archive_file, file.path(cache, archive_file))
for (f in c("2025widow.dat", "2025widow.ctl", "Report.sso", "ss_summary.sso"))
  if (!file.exists(file.path(model_dir, f))) stop("Missing cached model file: ", f, call. = FALSE)

read_numeric_block <- function(lines, marker, n_fields, regex = FALSE) {
  p <- if (regex) grep(marker, trimws(lines), perl = TRUE) else which(trimws(lines) == marker)
  if (length(p) != 1L) stop("Expected data block: ", marker, call. = FALSE)
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
  a <- which(trimws(lines) == "#_fleetinfo"); b <- which(trimws(lines) == "#_Catch data")
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
data_lines <- readLines(file.path(model_dir, "2025widow.dat"), warn = FALSE)
fleet_info <- read_fleets(data_lines)
fleet_names <- setNames(fleet_info$name, seq_len(nrow(fleet_info)))
index_info <- read_index_info(data_lines)
catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "season", "fleet", "catch", "catch_se")
catch <- catch[catch$year >= 1900, , drop = FALSE]
cpue <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(cpue) <- c("year", "month", "fleet", "observation", "se_log")
length_comp <- read_numeric_block(data_lines, "#_lencomp", 56L)
names(length_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "sample_size", paste0("f", seq(8, 56, 2)), paste0("m", seq(8, 56, 2)))
age_comp <- read_numeric_block(data_lines,
  "^#_year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr",
  91L, TRUE)
names(age_comp) <- c("year", "month", "fleet", "sex_code", "partition",
  "age_error", "length_lower", "length_upper", "sample_size",
  paste0("f", 0:40), paste0("m", 0:40))
checks <- c(fleets = nrow(fleet_info) == 9L, index_units = nrow(index_info) == 9L,
  catch = nrow(catch) == 545L, cpue = nrow(cpue) == 90L,
  lencomp = nrow(length_comp) == 162L, agecomp = nrow(age_comp) == 616L,
  catch_years = min(catch$year) == 1916 && max(catch$year) == 2024,
  catch_fleets = identical(sort(unique(as.integer(catch$fleet))), 1:5),
  index_fleets = identical(sort(unique(as.integer(cpue$fleet))), c(1L, 3L, 6L, 7L, 8L, 9L)),
  index_error = all(index_info$error == 0), index_scales = all(index_info$units %in% 0:1),
  catch_se = all(catch$catch_se %in% c(0.01, 0.1)))
if (!all(checks)) stop("Input structure checks failed: ",
  paste(names(checks)[!checks], collapse = ", "), call. = FALSE)
if (any(catch$catch < 0) || any(cpue$observation <= 0 | cpue$se_log <= 0) ||
    any(length_comp$sample_size <= 0) || any(age_comp$sample_size <= 0))
  stop("Invalid native observations.", call. = FALSE)

input_rows <- list(); add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
add_input(make_input(nrow(catch), type = "catch", measure = "total_biomass",
  basis = "biomass", value = catch$catch, unit = "metric tonnes", year = catch$year,
  fleet = unname(fleet_names[as.character(as.integer(catch$fleet))]),
  source_reference = paste0(archive_file, ", 2025widow.dat, Catch data"),
  notes = "Native annual catch biomass. Fleets 4 and 5 are zero-catch placeholders; native catch_se and catch-multiplier settings are recorded separately."))
for (i in seq_len(nrow(cpue))) {
  code <- as.character(as.integer(cpue$fleet[i]))
  units <- index_info$units[match(as.integer(code), index_info$fleet)]
  fleet <- unname(fleet_names[code]); time <- (cpue$month[i] - 1) / 12
  measure <- if (units == 0) "total_numbers" else "total_biomass"
  season <- paste0("month ", format(cpue$month[i], trim = TRUE))
  unit <- paste0("native SS3 ", if (units == 0) "number" else "biomass",
    " index units (units code ", units, "; multiplier not stated)")
  add_input(make_input(1L, "index", measure, "index_scale", cpue$observation[i],
    unit, year = cpue$year[i], survey = fleet, season = season, sampling_time = time,
    source_reference = paste0(archive_file, ", 2025widow.dat, CPUE_data"),
    notes = "Native aggregate lognormal index. Original fractional month is retained; sampling_time=(month-1)/12."))
  add_input(make_input(1L, "index", "log_index_sd", "log_scale", cpue$se_log[i],
    "log-scale standard error", year = cpue$year[i], survey = fleet, season = season,
    sampling_time = time, source_reference = paste0(archive_file, ", 2025widow.dat, CPUE_data se_log"),
    notes = "Native standard error on log index scale; error type 0 is lognormal."))
}
composition_rows <- function(x, age = FALSE) {
  bins <- if (age) 0:40 else seq(8, 56, 2); result <- list()
  for (i in seq_len(nrow(x))) {
    code <- as.integer(x$sex_code[i])
    sexes <- switch(as.character(code), "0" = "combined", "1" = "female",
      "2" = "male", "3" = c("female", "male"),
      stop("Unexpected composition sex code.", call. = FALSE))
    for (sex in sexes) {
      vals <- as.numeric(x[i, paste0(if (sex == "male") "m" else "f", bins), drop = TRUE])
      sf <- as.integer(x$fleet[i]); base <- abs(sf)
      fleet <- unname(fleet_names[as.character(base)])
      if (is.na(fleet)) stop("Unmapped composition fleet.", call. = FALSE)
      is_catch <- base <= 5L; negative <- sf < 0L
      note <- paste(if (age) "Raw age frequencies retained without normalization."
        else "Raw length frequencies retained without normalization; bins are 2 cm lower edges in cm.",
        if (code == 3L) "Source sex code 3 is one joint observation; female and male vectors preserve the joint sex ratio and share one observation ID and sample size." else "",
        if (negative) "Negative signed fleet is provisional: SS3 calculates this composition but excludes its likelihood from the total objective." else "",
        if (age) "Age-error code and sample size are retained; age 40 is the accumulator bin." else "")
      month <- x$month[i]
      result[[length(result) + 1L]] <- make_input(length(bins),
        type = if (is_catch) "catch" else "index",
        measure = if (age) "frequency_at_age" else "frequency_at_length",
        basis = "native_frequency", value = vals, unit = "source frequency weight",
        year = x$year[i], age = if (age) bins else NA_real_,
        fleet = if (is_catch) fleet else "", survey = if (is_catch) "" else fleet,
        sex = sex, season = paste0("month ", format(month, trim = TRUE)),
        sampling_time = (month - 1) / 12,
        source_reference = paste0(archive_file, ", 2025widow.dat, ", if (age) "agecomp" else "lencomp"),
        notes = note, observation_id = paste0(if (age) "agecomp-" else "lencomp-", i),
        length_bin = if (age) NA_real_ else bins,
        length_bin_lower = if (age) ifelse(x$length_lower[i] >= 0, x$length_lower[i], NA_real_) else bins,
        length_bin_upper = if (age) ifelse(x$length_upper[i] >= 0, x$length_upper[i], NA_real_) else bins + 2,
        sample_size = x$sample_size[i], age_error = if (age) x$age_error[i] else NA_real_,
        partition = x$partition[i])
    }
  }
  do.call(rbind, result)
}
add_input(composition_rows(length_comp))
add_input(composition_rows(age_comp, TRUE))

report_lines <- readLines(file.path(model_dir, "Report.sso"), warn = FALSE)
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
years <- 1916:2036
eras <- c("TIME", "FORE")
keep_pop <- function(x) x$Area == 1 & x$Bio_Pattern == 1 & x$Sex %in% 1:2 &
  x$Morph == x$Sex & x$BirthSeas == 1 & x$Settlement == 1 & x$Platoon == 1 &
  x$Seas == 1 & x[["Beg/Mid"]] == "B" & x$Era %in% eras & x$Yr %in% years
n <- n[keep_pop(n), , drop = FALSE]
b <- b[keep_pop(b), , drop = FALSE]
m <- m[keep_pop(m), , drop = FALSE]
f <- f[f$Area == 1 & f$Fleet %in% 1:5 & f$Sex %in% 1:2 & f$Morph == f$Sex &
  f$Seas == 1 & f$Era %in% eras & f$Yr %in% years, , drop = FALSE]
catch_age <- catch_age[catch_age$Area == 1 & catch_age$Fleet %in% 1:5 &
  catch_age$Sex %in% 1:2 & catch_age$Type == "dead" & catch_age$Morph == catch_age$Sex &
  catch_age$Seas == 1 & catch_age$Era %in% eras & catch_age$Yr %in% years, , drop = FALSE]
annual <- annual[annual$Area == 1 & annual$Era %in% eras & annual$Yr %in% years, , drop = FALSE]
weight <- weight[weight$Morph %in% 1:2 & weight$Seas == 1 & weight$Yr %in% years, , drop = FALSE]
actual <- c(n = nrow(n), biomass_at_age = nrow(b), m = nrow(m), f = nrow(f),
  catch_age = nrow(catch_age), annual = nrow(annual), weight = nrow(weight))
expected <- c(n = 242L, biomass_at_age = 242L, m = 242L, f = 1210L,
  catch_age = 1210L, annual = 121L, weight = 242L)
if (!identical(actual, expected) || !identical(sort(unique(as.integer(n$Yr))), years))
  stop("Output dimensions/year coverage differ from the reviewed bundle.", call. = FALSE)
if (!all(abs(unique(as.numeric(unlist(m[m$Sex == 1, as.character(0:40)]))) - 0.134991) < 1e-6) ||
    !all(abs(unique(as.numeric(unlist(m[m$Sex == 2, as.character(0:40)]))) - 0.146980) < 1e-6))
  stop("Fitted M values differ from the reviewed base model.", call. = FALSE)

output_rows <- list()
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
report_ref <- paste0(archive_file, ", Report.sso, ")
age_specs <- list(
  list(n, "population", "numbers_at_age", "thousand fish", "NUMBERS_AT_AGE report:35",
    "Beginning-of-year N; age 40 is the accumulator group."),
  list(b, "biomass", "biomass_at_age", "metric tonnes", "BIOMASS_AT_AGE report:36",
    "Beginning-of-year biomass at age; age 40 is the accumulator group."),
  list(m, "mortality", "natural_mortality_at_age", "per year", "Natural_Mortality report:43",
    "Fitted natural-mortality surface; age 40 is the accumulator group."),
  list(catch_age, "catch", "numbers_at_age", "thousand fish", "CATCH_AT_AGE report:40",
    "Fitted dead catch numbers-at-age; this is a model output, not an observed input."))
for (spec in age_specs) {
  x <- spec[[1L]]; z <- long_age(x, as.character(0:40))
  fleet <- if ("Fleet" %in% names(x)) unname(fleet_names[as.character(x$Fleet[z$row])]) else ""
  note <- ifelse(x$Era[z$row] == "FORE",
    paste0(spec[[6L]], " Era FORE denotes projections."), spec[[6L]])
  add_output(make_output(nrow(z), spec[[2L]], spec[[3L]], z$value, spec[[4L]],
    year = x$Yr[z$row], age = z$age, age_group = ifelse(z$age == 40, "40+", ""),
    fleet = fleet, sex = ifelse(x$Sex[z$row] == 1, "female", "male"),
    source_reference = paste0(report_ref, spec[[5L]]), notes = note))
}
z <- long_age(f, as.character(0:40))
add_output(make_output(nrow(z), "mortality", "fishing_mortality_at_age", z$value,
  "per year", year = f$Yr[z$row], age = z$age,
  age_group = ifelse(z$age == 40, "40+", ""),
  fleet = unname(fleet_names[as.character(f$Fleet[z$row])]),
  sex = ifelse(f$Sex[z$row] == 1, "female", "male"),
  source_reference = paste0(report_ref, "F_AT_AGE report:39"),
  notes = "Official fitted fishing mortality by fleet and sex; Era FORE identifies projections."))
z <- long_age(weight, as.character(0:40))
weight_note <- ifelse(weight$Yr[z$row] > 2024,
  "Model-generated beginning-of-year body weight; Era FORE denotes projections; stored as a fitted biological output, not an observed input.",
  "Model-generated beginning-of-year body weight; stored as a fitted biological output, not an observed input.")
add_output(make_output(nrow(z), "biology", "weight_at_age", z$value, "kg per fish",
  year = weight$Yr[z$row], age = z$age, age_group = ifelse(z$age == 40, "40+", ""),
  sex = ifelse(weight$Morph[z$row] == 1, "female", "male"),
  source_reference = paste0(report_ref, "MEAN_BODY_WT(Begin) report:48"),
  notes = weight_note))
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
    lower[use] <- 5127; upper[use] <- 16017
    source_type[use] <- "official_document"
    ref[use] <- paste0(manifest$url[match(report_file, manifest$source_file)],
      ", Table V; point estimate cross-checked to the bundle.")
  }
  note <- if (measure == "spawning_output")
    "SpawnBio is spawning output in billions of eggs; the 2025 official report interval is retained. FORE years are projections."
  else if (measure == "recruitment")
    "Recruit_0 is age-0 recruitment in thousands of fish; FORE years are projections."
  else "Bio_all is total beginning-of-year biomass in metric tonnes; FORE years are projections."
  add_output(make_output(nrow(annual), type, measure, value, unit,
    year = annual$Yr, age = if (measure == "recruitment") 0 else NA_real_,
    lwr = lower, upr = upper, source_type = source_type,
    source_reference = ref, notes = note))
}
total_n <- aggregate(rowSums(n[, as.character(0:40), drop = FALSE]), list(year = n$Yr), sum)
names(total_n)[2L] <- "value"
add_output(make_output(nrow(total_n), "population", "total_numbers", total_n$value,
  "thousand fish", year = total_n$year, source_type = "derived_source_output",
  source_reference = paste0(report_ref, "NUMBERS_AT_AGE report:35"),
  notes = ifelse(total_n$year > 2024,
    "Derived by summing beginning-of-year N over sexes and ages 0-40; Era FORE denotes projections; no uncertainty was calculated.",
    "Derived by summing beginning-of-year N over sexes and ages 0-40; no uncertainty was calculated.")))

for (i in seq_len(nrow(fleet_info))) add_assumption("fleet", "native_fleet_configuration",
  paste0("type=", fleet_info$type[i], "; timing=", fleet_info$timing[i],
    "; area=", fleet_info$area[i], "; units=", fleet_info$units[i],
    "; catch multiplier=", fleet_info$catch_mult[i]),
  source_reference = paste0(archive_file, ", 2025widow.dat, fleetinfo"),
  fleet = fleet_info$name[i], notes = paste0("Native fleet code ", i, "."))
source_ref <- paste0(archive_file, ", 2025widow.dat and 2025widow.ctl; ")
add_assumption("model", "model_run", "2025 production assessment; bundled SS3 run dated 2025-12-03",
  source_reference = paste0(archive_file, ", ss_summary.sso and Report.sso"),
  notes = "The report identifies SS 3.30.24.1; supplemental review says 3.30.23.1; bundled summary identifies 3.30.23.2. Preserve this version discrepancy; outputs use the pinned bundle.")
add_assumption("model", "historical_years", "1916-2024", source_ref,
  "Annual input data end in 2024.")
add_assumption("model", "reported_years", "1916-2036",
  paste0(report_ref, "NUMBERS_AT_AGE and TIME_SERIES"),
  "Historical estimates through 2024; 2025-2036 are forecasts.")
add_assumption("model", "dimensions", "1 area; 1 season; 2 sexes; ages 0-40", source_ref,
  "Age 40 is the accumulator group; annual time step.")
add_assumption("catch", "native_catch_series", "Annual biomass by fleets 1-5; fleets 4-5 are zero placeholders",
  paste0(archive_file, ", 2025widow.dat, Catch data"),
  "Catch biomass is in metric tonnes. Catch-at-age is not a direct observed input.")
add_assumption("catch", "catch_se_field",
  paste(sort(unique(catch$catch_se)), collapse = ", "),
  paste0(archive_file, ", 2025widow.dat, Catch data"),
  "Native SS3 catch_se values are retained as a model input setting; no conversion to another error scale is applied.")
add_assumption("index", "native_index_units", "Units code 0=numbers; 1=biomass; all six series use lognormal error type 0",
  paste0(archive_file, ", 2025widow.dat, CPUE units"),
  "Original index scales retained; no multiplier is stated in the source file.")
add_assumption("index", "survey_timing", "Index month retained; sampling_time=(month-1)/12",
  paste0(archive_file, ", 2025widow.dat, CPUE_data"),
  "Fractional months retained without rounding.")
add_assumption("composition", "age_composition", "Marginal age compositions plus conditional age-at-length data for WCGBTS",
  paste0(archive_file, ", 2025widow.dat, agecomp"),
  "Raw frequency vectors, sample size, sex code, length interval, age-error code, and signed fleet are preserved. These are not annual catch-at-age inputs or age-specific survey abundance indices.")
add_assumption("composition", "length_composition", "Raw 2 cm length frequencies; lower edges 8-56 cm",
  paste0(archive_file, ", 2025widow.dat, lencomp"),
  "Source frequency vectors, sex codes, sample sizes and partitions are retained.")
add_assumption("composition", "age_error_codes", paste(sort(unique(age_comp$age_error)), collapse = ", "),
  source_ref, "Codes link to ageing-error matrices in the control file.")
add_assumption("composition", "negative_fleet_codes",
  paste(sort(unique(age_comp$fleet[age_comp$fleet < 0])), collapse = ", "),
  paste0(archive_file, ", 2025widow.dat; Stock Synthesis manual"),
  "Provisional compositions: SS3 calculates expected values but excludes their likelihood from the total objective.")
add_assumption("mortality", "natural_mortality",
  "Estimated constant sex-specific M: female=0.134991; male=0.146980 per year",
  paste0(report_ref, "Natural_Mortality report:43"),
  "Fitted outputs, constant across age and year.")
add_assumption("mortality", "M_prior", "Lognormal prior with median 0.10 per year and log-SD 0.31",
  source_ref, "The prior is applied to sex-specific natural-mortality parameters.")
add_assumption("biology", "weight_at_age", "Model-generated beginning-of-year weight by sex and age",
  paste0(report_ref, "MEAN_BODY_WT(Begin) report:48"),
  "Stored as an output surface; no standalone observed weight-at-age input was present in the pinned bundle.")
add_assumption("biology", "age_at_50_percent_maturity", "5.47 years",
  paste0(report_ref, "2025 assessment report, biology section"),
  "Carried forward from the 2015 benchmark.")
add_assumption("biology", "maturity_and_fecundity",
  "Fitted biological relationships; no standalone maturity-at-age input series",
  paste0(report_ref, "BIOLOGY report:42; Biology_at_age_in_endyr report:47"),
  "")
add_assumption("recruitment", "steepness", "0.72 fixed",
  source_ref, "Stock-recruit steepness is fixed in the base model.")
add_assumption("recruitment", "recruitment_SD", "0.60",
  source_ref, "Base-model recruitment deviation SD.")
input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumptions)

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
  stop("Widow rockfish records already exist.", call. = FALSE)
for (path in c(file.path(database, "inputs.csv"), file.path(database, "outputs.csv"))) {
  header <- read.csv(path, nrows = 0L, check.names = FALSE)
  ids <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = c("character", rep("NULL", ncol(header) - 1L)))[[1L]]
  if (assessment_id %in% ids) stop("Observations already exist for this assessment.", call. = FALSE)
}
blank_row <- function(fields, values) {
  x <- as.list(rep("", length(fields))); names(x) <- fields
  for (nm in names(values)) x[[nm]] <- as.character(values[[nm]])
  as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stocks), list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "10568", scientific_name = "Sebastes entomelas",
  common_name = "Widow rockfish - U.S. West Coast",
  area = "U.S. West Coast (California, Oregon, Washington)",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10568. Current assessment unit is one coastwide U.S. West Coast stock, separate from Canadian and Alaska stocks."))
report_url <- manifest$url[match(report_file, manifest$source_file)]
model_url <- manifest$url[match(archive_file, manifest$source_file)]
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2025L,
  terminal_year = 2024L, estimate_terminal_year = 2036L,
  assessment_type = "update", model_family = "Stock Synthesis",
  model_version = "3.30.23.2 (bundled output; report version differs)",
  is_current = TRUE, is_applied = TRUE,
  assessment_url = report_url,
  framework_url = "https://www.pcouncil.org/documents/2025/10/supplemental-review-panel-report-for-widow-rockfish.pdf",
  data_url = model_url, model_url = model_url,
  repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2025 production assessment fitted through 2024, with projections through 2036. Native catch biomass, aggregate indices, raw length and age compositions, fitted N/F/M, generated weight-at-age, annual biomass, recruitment and spawning output are recorded. Catch-at-age and age-specific survey indices are not direct observed inputs; weight and maturity are not standalone observed input series. The pinned report/model version discrepancy is documented."))
replace_csv_row <- function(path, key, value, idx, row) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes); rec <- as.integer(idx) + 1L
  old <- read_csv(path)
  if (idx > nrow(old) || as.character(old[[key]][idx]) != value)
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  tmp <- tempfile(fileext = ".csv"); on.exit(unlink(tmp), add = TRUE)
  utils::write.table(row, tmp, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")
  repl <- readBin(tmp, "raw", n = file.info(tmp)$size)
  if (tail(repl, 1L) == as.raw(10L)) repl <- repl[-length(repl)]
  first <- bounds$start[rec]; last <- bounds$end[rec]
  next_byte <- last + 1L
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) next_byte <- next_byte + 1L
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    repl <- c(repl, as.raw(10L)); last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, repl, after), path)
  now <- read_csv(path)
  if (nrow(now) != nrow(old) || sum(now[[key]] == value, na.rm = TRUE) != 1L)
    stop("CSV row replacement failed: ", basename(path), call. = FALSE)
}
append_rows <- function(path, rows) if (nrow(rows)) utils::write.table(rows,
  file = path, sep = ",", row.names = FALSE, col.names = FALSE, quote = TRUE,
  qmethod = "double", na = "", append = TRUE, eol = "\n", fileEncoding = "UTF-8")

candidate_row <- candidate[ci, , drop = FALSE]
candidate_row$matched_stock_id <- stock_id
candidate_row$match_status <- "new"
candidate_row$import_status <- "partial"
candidate_row$catch_age_evidence <- "2025 native model provides annual catch biomass plus raw length and age compositions; no observed catch-at-age series was supplied."
candidate_row$survey_age_evidence <- "Six aggregate lognormal indices are retained; no age-specific survey abundance index was identified. WCGBTS age-at-length data are conditional compositions."
candidate_row$weights_evidence <- "Model-generated beginning-of-year weights are in Report.sso; no standalone observed weight-at-age input was found in the pinned bundle."
candidate_row$maturity_evidence <- "Maturity and fecundity are represented in fitted model biology; no standalone maturity-at-age input series was identified."
candidate_row$mortality_evidence <- "Base model estimates constant sex-specific M: female 0.134991 and male 0.146980 per year."
candidate_row$timing_evidence <- "Native month is retained for aggregate indices; sampling_time=(month-1)/12. Composition months are also retained."
candidate_row$output_evidence <- "Pinned model output includes N-at-age, F-at-age by fleet, M-at-age, fitted catch-at-age, generated weight-at-age, total biomass, recruitment and spawning output; the 2025 spawning-output interval is reported."
candidate_row$review_date <- "2026-11-03"
candidate_row$decision_reason <- "Selected as a distinct current U.S. West Coast unit with a detailed 2025 production assessment and native model bundle."
candidate_row$notes <- "Partial source import completed. Native compositions remain sample data; no annual catch-at-age or age-specific survey indices were reconstructed."
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
cat(if (dry_run) "Dry run parsed " else "Imported ", nrow(input_data), " inputs, ",
  nrow(assumption_data), " assumptions, and ", nrow(output_data),
  " outputs for the 2025 NOAA Widow Rockfish assessment.\n", sep = "")
