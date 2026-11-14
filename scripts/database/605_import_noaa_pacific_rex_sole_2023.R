root <- "."
stock_id <- "noaa_pacific_coast_rex_sole"
assessment_id <- "noaa_pacific_coast_rex_sole_2023"
candidate_id <- "NOAA:10059"
candidate_unit_id <- "noaa_pacific_rex_sole"
cache_name <- "discovery_noaa_pacific_rex_2023"
report_url <- "https://www.pcouncil.org/documents/2024/02/status-of-rex-sole-glyptocephalus-zachirus-along-the-u-s-west-coast-in-2023.pdf/"
archive_url <- "https://www.pcouncil.org/documents/2024/02/rex-sole-2023-model-files.zip/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache_options <- c(
  file.path(root, "source_cache", cache_name),
  file.path(root, "..", "..", cache_name)
)
cache <- cache_options[dir.exists(cache_options)][1L]
if (is.na(cache)) stop("The cached Rex Sole sources are unavailable.", call. = FALSE)
cache <- normalizePath(cache, winslash = "/", mustWork = TRUE)
source_manifest <- read.csv(file.path(cache, "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)

sha256_file <- function(path) {
  if (.Platform$OS.type == "windows") {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
  } else {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE)
    hash <- toupper(strsplit(result, "[[:space:]]+")[[1L]][1L])
  }
  if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
  hash
}

verify_source <- function(cached_file) {
  source <- source_manifest[source_manifest$cached_file == cached_file, , drop = FALSE]
  path <- file.path(cache, cached_file)
  if (nrow(source) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(source$sha256))) {
    stop("Cached source differs from its reviewed manifest: ", cached_file,
      call. = FALSE)
  }
  path
}

report_file <- verify_source("rex_sole_assessment_2023.pdf")
archive_file <- verify_source("rex_sole_2023_model_files.zip")
if (!requireNamespace("r4ss", quietly = TRUE)) {
  stop("Install the official r4ss package to read the cached Stock Synthesis files.",
    call. = FALSE)
}

members <- c(
  "rex_sole_2023_base_model/REX_data.ss",
  "rex_sole_2023_base_model/REX_control.ss",
  "rex_sole_2023_base_model/run/Report.sso"
)
archive_members <- utils::unzip(archive_file, list = TRUE)$Name
if (!all(members %in% archive_members)) {
  stop("The pinned archive does not contain the reviewed base-run files.",
    call. = FALSE)
}
extracted <- tempfile("saio_rex_sole_")
dir.create(extracted)
on.exit(unlink(extracted, recursive = TRUE), add = TRUE)
utils::unzip(archive_file, files = members, exdir = extracted)
model_dir <- file.path(extracted, "rex_sole_2023_base_model")
data_file <- file.path(model_dir, "REX_data.ss")
control_file <- file.path(model_dir, "REX_control.ss")
report_output <- file.path(model_dir, "run", "Report.sso")

dat <- r4ss::SS_readdat(data_file, verbose = FALSE)
ctl <- r4ss::SS_readctl(control_file, datlist = dat, verbose = FALSE)
fleet_names <- as.character(dat$fleetinfo$fleetname)
fleet_types <- as.integer(dat$fleetinfo$type)
age_bins <- as.integer(dat$agebin_vector)
length_bins <- as.numeric(dat$lbin_vector)
m_parameters <- ctl$MG_parms[grepl("^NatM_p_1_(Fem|Mal)_GP_1$",
  rownames(ctl$MG_parms)), , drop = FALSE]

if (dat$styr != 1896L || dat$endyr != 2022L || dat$nseas != 1L ||
    dat$Nsexes != 2L || dat$Nages != 34L || dat$N_areas != 1L ||
    dat$Nfleets != 5L || !identical(age_bins, 1:34) ||
    !identical(length_bins, seq(2, 60, by = 2)) ||
    !identical(fleet_names, c("FISHERY_current", "FISHERY_historical",
      "SURVEY1", "SURVEY2", "SURVEY3")) ||
    nrow(dat$catch) != 107L || nrow(dat$CPUE) != 28L ||
    nrow(dat$discard_data) != 20L || nrow(dat$lencomp) != 58L ||
    nrow(dat$agecomp) != 165L || nrow(m_parameters) != 2L ||
    any(m_parameters$PHASE >= 0) ||
    any(abs(m_parameters$INIT - 0.186207) > 1e-7) ||
    ctl$maturity_option != 1L || ctl$fecundity_option != 2L) {
  stop("Native input structure differs from the reviewed 2023 base run.",
    call. = FALSE)
}

input <- function(type, measure, basis, value, unit, year = NA_integer_,
  age = NA_integer_, fleet = "", survey = "", sex = "", season = "",
  source_reference, transformation = "", notes = "", observation_id = "",
  length_bin = NA_real_, length_bin_lower = NA_real_,
  length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = NA_real_) {
  n <- length(value)
  pacific_database_row("inputs", n = n, assessment_id = assessment_id,
    type = type, measure = measure, basis = basis, value = value, unit = unit,
    year = year, year_basis = if (all(is.na(year))) "" else "calendar_year",
    age = age, fleet = fleet, survey = survey, sex = sex,
    region = "U.S. West Coast", season = season, sampling_time = NA_real_,
    source_type = "native_model", source_reference = source_reference,
    transformation = transformation, notes = notes,
    observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = age_error, partition = partition)
}

input_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
source_ref <- function(file, section) paste0(file, "; ", section)

catch <- dat$catch
catch_fleets <- fleet_names[as.integer(catch$fleet)]
add_input(input("catch", "catch_biomass", "biomass", catch$catch,
  "metric tonnes", year = catch$year, fleet = catch_fleets,
  season = paste0("model season ", catch$seas),
  source_reference = source_ref("REX_data.ss", "Catch data"),
  notes = "Native catch biomass copied without rescaling. The assessment models discard fractions separately."))
add_input(input("catch", "catch_se", "native_scale", catch$catch_se,
  "native catch_se field", year = catch$year, fleet = catch_fleets,
  season = paste0("model season ", catch$seas),
  source_reference = source_ref("REX_data.ss", "Catch data catch_se"),
  notes = "Native catch_se values retained without transformation; the source field scale is not relabeled."))

index <- dat$CPUE
index_surveys <- fleet_names[as.integer(index$index)]
add_input(input("index", "relative_biomass_index", "index_scale", index$obs,
  "native survey index units", year = index$year, survey = index_surveys,
  season = paste0("model month ", index$month),
  source_reference = source_ref("REX_data.ss", "CPUE data and CPUEinfo"),
  notes = "Aggregate biomass-scale index as supplied. CPUEinfo unit code 1 identifies a biomass index, but no physical index unit or abundance-at-age scale is given. Model month 1 is not treated as a verified fractional-year survey time."))
add_input(input("index", "log_index_sd", "log_scale", index$se_log,
  "log SD", year = index$year, survey = index_surveys,
  season = paste0("model month ", index$month),
  source_reference = source_ref("REX_data.ss", "CPUE data se_log"),
  notes = "Native log-scale index standard error. The survey timing code is not converted to a fractional year."))

discard <- dat$discard_data
discard_fleet <- fleet_names[as.integer(discard$fleet)]
add_input(input("catch", "discard_fraction", "proportion_biomass", discard$obs,
  "proportion", year = discard$year, fleet = discard_fleet,
  season = paste0("model month ", discard$month),
  source_reference = source_ref("REX_data.ss", "Discard data"),
  notes = "Native discard fraction. Discard unit code 2 is fraction; catch is modeled on a biomass scale."))
add_input(input("catch", "discard_fraction_cv", "relative_scale", discard$stderr,
  "ratio", year = discard$year, fleet = discard_fleet,
  season = paste0("model month ", discard$month),
  source_reference = source_ref("REX_data.ss", "Discard data stderr and discard_fleet_info"),
  notes = "Native error value stored as a CV under the source t-distribution error code 30 (30 degrees of freedom). Not converted to an SE."))

composition_rows <- function(x, component) {
  is_age <- component == "age"
  bins <- if (is_age) age_bins else length_bins
  female_columns <- paste0("f", bins)
  male_columns <- paste0("m", bins)
  if (!all(c(female_columns, male_columns) %in% names(x))) {
    stop("Composition columns differ from the reviewed native data.", call. = FALSE)
  }
  for (i in seq_len(nrow(x))) {
    sex_code <- as.integer(x$sex[i])
    female <- as.numeric(x[i, female_columns, drop = TRUE])
    male <- as.numeric(x[i, male_columns, drop = TRUE])
    sex_vectors <- switch(as.character(sex_code),
      "0" = list(combined = female),
      "1" = list(female = female),
      "2" = list(male = male),
      "3" = list(female = female, male = male),
      stop("Unexpected composition sex code.", call. = FALSE))
    signed_fleet <- as.integer(x$fleet[i])
    fleet_code <- abs(signed_fleet)
    if (fleet_code < 1L || fleet_code > length(fleet_names)) {
      stop("Composition row has an unknown fleet code.", call. = FALSE)
    }
    is_fishery <- fleet_types[fleet_code] == 1L
    fleet_name <- fleet_names[fleet_code]
    year <- as.integer(x$year[i])
    month <- as.integer(x$month[i])
    base_id <- paste0(component, "comp-", sprintf("%03d", i))
    for (sex_name in names(sex_vectors)) {
      values <- sex_vectors[[sex_name]]
      if (length(values) != length(bins) || any(!is.finite(values)) ||
          any(values < 0)) {
        stop("Native composition values failed range checks.", call. = FALSE)
      }
      notes <- paste(
        "Native frequency values copied without normalization.",
        if (sex_code == 0L) "Sex code 0 stores a combined-sex sample in the female vector." else "",
        if (sex_code == 3L) "Sex code 3 is one joint-sex sample; sample_size is repeated across the separate female and male vectors." else "",
        if (is_age && x$Lbin_lo[i] >= 0) "Conditional age-at-length; native length limits are retained in the length-bin fields." else if (is_age) "Marginal age composition across the full length range; native limits are -1,-1." else "Native length-frequency sample.",
        if (signed_fleet < 0L) paste0("Original signed fleet code ", signed_fleet, "; negative fleet rows are excluded from the likelihood."),
        "The model month field is not converted to fractional-year timing.",
        sep = " "
      )
      common <- list(
        type = if (is_fishery) "catch" else "index",
        measure = if (is_age) "frequency_at_age" else "frequency_at_length",
        basis = "native_frequency", value = values, unit = "source frequency",
        year = rep(year, length(bins)), sex = rep(sex_name, length(bins)),
        fleet = if (is_fishery) rep(fleet_name, length(bins)) else "",
        survey = if (is_fishery) "" else rep(fleet_name, length(bins)),
        season = rep(paste0("model month ", month), length(bins)),
        source_reference = source_ref("REX_data.ss", if (is_age) "agecomp" else "lencomp"),
        notes = rep(notes, length(bins)),
        observation_id = rep(paste0(base_id, "-", sex_name), length(bins)),
        sample_size = rep(as.numeric(x$Nsamp[i]), length(bins)),
        partition = rep(as.numeric(x$part[i]), length(bins))
      )
      if (is_age) {
        common$age <- bins
        common$age_error <- rep(as.numeric(x$ageerr[i]), length(bins))
        common$length_bin_lower <- rep(as.numeric(x$Lbin_lo[i]), length(bins))
        common$length_bin_upper <- rep(as.numeric(x$Lbin_hi[i]), length(bins))
      } else {
        common$length_bin <- bins
        common$length_bin_lower <- bins
        common$length_bin_upper <- bins + 2
      }
      add_input(do.call(input, common))
    }
  }
}

composition_rows(dat$lencomp, "length")
composition_rows(dat$agecomp, "age")
inputs <- do.call(rbind, input_rows)

report_lines <- readLines(report_output, warn = FALSE)
read_report_table <- function(label, header_pattern) {
  marker <- tail(which(startsWith(trimws(report_lines), paste0(label, " report:"))), 1L)
  header <- grep(header_pattern, report_lines, perl = TRUE)
  header <- header[header > marker][1L]
  if (length(marker) != 1L || length(header) != 1L || is.na(header)) {
    stop("Could not locate Stock Synthesis report table: ", label, call. = FALSE)
  }
  columns <- strsplit(trimws(report_lines[header]), "[[:space:]]+")[[1L]]
  rows <- list()
  for (i in seq.int(header + 1L, length(report_lines))) {
    line <- trimws(report_lines[i])
    if (!nzchar(line) || startsWith(line, "#") || grepl(" report:", line, fixed = TRUE)) break
    fields <- strsplit(line, "[[:space:]]+")[[1L]]
    if (length(fields) != length(columns)) break
    rows[[length(rows) + 1L]] <- fields
  }
  if (!length(rows)) stop("Report table is empty: ", label, call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE,
    check.names = FALSE)
  names(out) <- columns
  for (column in names(out)) {
    values <- suppressWarnings(as.numeric(out[[column]]))
    if (sum(!is.na(values)) == sum(!is.na(out[[column]]))) out[[column]] <- values
  }
  out
}

annual <- read_report_table("TIME_SERIES", "^Area Yr Era")
numbers <- read_report_table("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
biomass <- read_report_table("BIOMASS_AT_AGE", "^Area Bio_Pattern Sex")
mortality <- read_report_table("Natural_Mortality", "^Area Bio_Pattern Sex")
fishing <- read_report_table("F_AT_AGE", "^Area Fleet Sex")
catch_at_age <- read_report_table("CATCH_AT_AGE", "^Area Fleet Sex")
weight <- read_report_table("MEAN_BODY_WT(Begin)", "^Morph Yr Seas")
biology <- read_report_table("Biology_at_age_in_endyr",
  "^Seas Morph Bio_Pattern Sex")

years <- 1896:2034
age_columns <- as.character(0:34)
keep_year <- function(x) x$Yr %in% years & x$Era %in% c("TIME", "FORE")
annual <- annual[annual$Area == 1 & annual$Seas == 1 & keep_year(annual), , drop = FALSE]
population_rows <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
  x$Sex %in% 1:2 & x$Morph == x$Sex & x$BirthSeas == 1 &
  x$Settlement == 1 & x$Platoon == 1 & x$Seas == 1 &
  x[["Beg/Mid"]] == "B" & keep_year(x)
numbers <- numbers[population_rows(numbers), , drop = FALSE]
biomass <- biomass[population_rows(biomass), , drop = FALSE]
mortality <- mortality[population_rows(mortality), , drop = FALSE]
fishing <- fishing[fishing$Area == 1 & fishing$Fleet %in% 1:2 &
  fishing$Sex %in% 1:2 & fishing$Morph == fishing$Sex &
  fishing$Seas == 1 & keep_year(fishing), , drop = FALSE]
catch_at_age <- catch_at_age[catch_at_age$Area == 1 & catch_at_age$Fleet %in% 1:2 &
  catch_at_age$Sex %in% 1:2 & catch_at_age$Morph == catch_at_age$Sex &
  catch_at_age$Type == "dead" & catch_at_age$Seas == 1 & keep_year(catch_at_age),
  , drop = FALSE]
weight <- weight[weight$Morph %in% 1:2 & weight$Yr %in% years & weight$Seas == 1,
  , drop = FALSE]
biology <- biology[biology$Seas == 1 & biology$Morph %in% 1:2 &
  biology$Bio_Pattern == 1 & biology$Settlement == 1 &
  biology$Platoon == 1 & biology$int_Age %in% 0:34 &
  biology$Sex %in% 1:2 & biology$Morph == biology$Sex, , drop = FALSE]

expected <- c(annual = length(years), numbers = length(years) * 2L,
  biomass = length(years) * 2L, natural_mortality = length(years) * 2L,
  fishing_mortality = length(years) * 2L * 2L,
  catch_at_age = length(years) * 2L * 2L,
  weight = length(years) * 2L, maturity = 70L)
actual <- c(annual = nrow(annual), numbers = nrow(numbers), biomass = nrow(biomass),
  natural_mortality = nrow(mortality), fishing_mortality = nrow(fishing),
  catch_at_age = nrow(catch_at_age), weight = nrow(weight), maturity = nrow(biology))
if (any(actual != expected) ||
    !identical(as.integer(sort(unique(annual$Yr))), years) ||
    !identical(as.integer(sort(unique(numbers$Yr))), years) ||
    !identical(as.integer(sort(unique(weight$Yr))), years) ||
    !setequal(as.integer(unique(numbers$Sex)), 1:2) ||
    !setequal(as.integer(unique(fishing$Fleet)), 1:2)) {
  stop("Report surfaces differ from expected 1896-2034 age/year coverage: ",
    paste(names(actual), actual, sep = "=", collapse = ", "), call. = FALSE)
}

long_age <- function(x) {
  values <- as.matrix(x[, age_columns, drop = FALSE])
  storage.mode(values) <- "double"
  list(row = rep(seq_len(nrow(x)), each = length(age_columns)),
    age = rep(as.integer(age_columns), times = nrow(x)),
    value = as.vector(t(values)))
}
n_long <- long_age(numbers)
b_long <- long_age(biomass)
m_long <- long_age(mortality)
f_long <- long_age(fishing)
c_long <- long_age(catch_at_age)
w_long <- long_age(weight)

surface_rows <- function(x, long, type, measure, unit, section,
  sex_column = "Sex", fleet_column = NULL, notes) {
  row_year <- x$Yr[long$row]
  sex <- c("1" = "female", "2" = "male")[as.character(x[[sex_column]][long$row])]
  fleet <- if (is.null(fleet_column)) "" else
    fleet_names[as.integer(x[[fleet_column]][long$row])]
  forecast_note <- ifelse(row_year > 2022L,
    "Native archived-run forecast after the terminal fitted year 2022; no age-surface uncertainty is reported.",
    "Native fitted historical output; no age-surface uncertainty is reported.")
  pacific_database_row("outputs", n = length(long$value),
    assessment_id = assessment_id, type = type, measure = measure,
    value = long$value, unit = unit, year = row_year, age = long$age,
    fleet = fleet, sex = sex, region = "U.S. West Coast",
    source_type = "native_model",
    source_reference = source_ref("Report.sso", section),
    notes = paste(notes, forecast_note))
}

recent_spawn <- data.frame(
  year = 2013:2023,
  estimate = c(637390000, 687399000, 742168000, 784763000, 819703000,
    846911000, 869378000, 887881000, 901312000, 909284000, 912716000),
  lower = c(479224630, 517131245, 559667914, 591003312, 615457113,
    634446984, 651369246, 666781383, 679302960, 687615993, 692053455),
  upper = c(795555370, 857666755, 924668086, 978522688, 1023948887,
    1059375016, 1087386754, 1108980617, 1123321040, 1130952007, 1133378545),
  fraction = c(.53, .57, .62, .65, .68, .71, .73, .74, .75, .76, .76),
  fraction_lower = c(.46, .50, .54, .57, .59, .61, .63, .64, .66, .66, .67),
  fraction_upper = c(.60, .65, .70, .74, .77, .80, .82, .84, .85, .85, .85)
)
recent_recruitment <- data.frame(
  year = 2013:2023,
  estimate = c(100549.0, 42805.7, 59163.6, 67444.1, 41706.7, 64498.0,
    53606.6, 59397.1, 63114.4, 62659.5, 62691.8),
  lower = c(76545.50, 30103.53, 42059.05, 45484.69, 21842.71, 34147.30,
    25198.33, 26025.24, 24790.01, 24528.07, 24541.35),
  upper = c(132079.63, 60867.55, 83224.22, 100005.22, 79635.19,
    121824.91, 114041.99, 135561.31, 160686.80, 160070.20, 160148.55)
)

annual_rows <- function(measure, type, values, unit, section,
  recent = NULL, notes) {
  value <- values
  lower <- upper <- rep(NA_real_, length(values))
  source_type <- rep("native_model", length(values))
  source_reference <- rep(source_ref("Report.sso", section), length(values))
  if (!is.null(recent)) {
    match_row <- match(annual$Yr, recent$year)
    use <- !is.na(match_row)
    value[use] <- recent$estimate[match_row[use]]
    lower[use] <- recent$lower[match_row[use]]
    upper[use] <- recent$upper[match_row[use]]
    source_type[use] <- "official_table"
    source_reference[use] <- paste0("2023 assessment report, Table ",
      if (measure == "spawning_output") "ii" else "iii", "; ", report_url)
  }
  forecast_note <- ifelse(annual$Yr > 2022L,
    "Archived-run forecast after terminal fitted year 2022; no uncertainty interval is reported for these years.",
    "Point estimate from the selected 2023 base run.")
  notes <- paste(notes, forecast_note)
  pacific_database_row("outputs", n = nrow(annual),
    assessment_id = assessment_id, type = type, measure = measure,
    value = value, unit = unit, year = annual$Yr, region = "U.S. West Coast",
    lwr = lower, upr = upper, source_type = source_type,
    source_reference = source_reference, notes = notes)
}

outputs <- list(
  annual_rows("total_biomass", "biomass", annual$Bio_all, "metric tonnes",
    "TIME_SERIES report:16", notes = "Native all-age total biomass, Bio_all."),
  annual_rows("spawning_output", "biomass", annual$SpawnBio, "eggs",
    "TIME_SERIES report:16", recent_spawn,
    "Spawning output is egg production, not spawning biomass in tonnes. Table ii reports 95% asymptotic intervals for 2013-2023; no SE is calculated."),
  annual_rows("recruitment", "recruitment", annual$Recruit_0, "thousand fish",
    "TIME_SERIES report:16", recent_recruitment,
    "Age-0 recruitment. Table iii reports 95% asymptotic intervals for 2013-2023; no SE is calculated."),
  surface_rows(numbers, n_long, "population", "numbers_at_age", "thousand fish",
    "NUMBERS_AT_AGE report:35",
    notes = "Beginning-of-year fitted numbers by age and sex; age 34 is the terminal model age bin."),
  surface_rows(biomass, b_long, "biomass", "biomass_at_age", "metric tonnes",
    "BIOMASS_AT_AGE report:36",
    notes = "Beginning-of-year model biomass at age; not an observed biomass-at-age input."),
  surface_rows(mortality, m_long, "mortality", "natural_mortality_at_age", "per year",
    "Natural_Mortality report:43",
    notes = "Model-reported M surface; fixed at 0.186207 per year for both sexes, not an estimated M trajectory."),
  surface_rows(fishing, f_long, "mortality", "fishing_mortality_at_age", "per year",
    "F_AT_AGE report:39", fleet_column = "Fleet",
    notes = "Fleet-specific fishing mortality at age; includes fishery fleets 1 and 2 separately."),
  surface_rows(catch_at_age, c_long, "catch", "numbers_at_age", "thousand fish",
    "CATCH_AT_AGE report:40", fleet_column = "Fleet",
    notes = "Model-estimated dead catch numbers at age by fishery fleet; not observed catch-at-age input."),
  surface_rows(weight, w_long, "biology", "weight_at_age", "kg per fish",
    "MEAN_BODY_WT(Begin) report:48", sex_column = "Morph",
    notes = "Model-generated beginning-of-year stock weight-at-age from estimated growth and fixed weight-length parameters; not a supplied weight-at-age input.")
)

total_numbers <- aggregate(n_long$value,
  list(year = numbers$Yr[n_long$row]), sum)
outputs[[length(outputs) + 1L]] <- pacific_database_row("outputs",
  n = nrow(total_numbers), assessment_id = assessment_id, type = "population",
  measure = "total_numbers", value = total_numbers$x, unit = "thousand fish",
  year = total_numbers$year, region = "U.S. West Coast",
  source_type = "derived_source_output",
  source_reference = source_ref("Report.sso", "NUMBERS_AT_AGE report:35"),
  notes = "Derived by summing fitted numbers-at-age across ages 0-34 and both sexes; no uncertainty is available.")

outputs[[length(outputs) + 1L]] <- pacific_database_row("outputs",
  n = nrow(recent_spawn), assessment_id = assessment_id, type = "biomass",
  measure = "fraction_unfished_spawning_output", value = recent_spawn$fraction,
  unit = "proportion", year = recent_spawn$year, region = "U.S. West Coast",
  lwr = recent_spawn$fraction_lower, upr = recent_spawn$fraction_upper,
  source_type = "official_table",
  source_reference = paste0("2023 assessment report, Table ii; ", report_url),
  notes = "Spawning output relative to unfished output; 95% asymptotic intervals as reported. This is not a biomass proportion.")

biology_rows <- pacific_database_row("outputs", n = nrow(biology),
  assessment_id = assessment_id, type = "biology", measure = "maturity_at_age",
  value = biology$Len_Mat, unit = "proportion", year = 2034L,
  age = biology$int_Age, sex = c("1" = "female", "2" = "male")[as.character(biology$Sex)],
  region = "U.S. West Coast", source_type = "native_model",
  source_reference = source_ref("Report.sso", "Biology_at_age_in_endyr report:47"),
  notes = "Terminal forecast-year model-derived maturity at age from the fixed length-logistic maturity curve and predicted mean lengths; not an observed age-maturity input.")
outputs[[length(outputs) + 1L]] <- biology_rows
outputs <- do.call(rbind, outputs)

assume <- function(component, setting, value, source_reference, notes = "",
  fleet = "", survey = "", sex = "", season = "") {
  pacific_database_row("assumptions", n = 1L, assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes, fleet = fleet,
    survey = survey, sex = sex, region = "U.S. West Coast", season = season)
}
assumptions <- do.call(rbind, list(
  assume("assessment", "production_run", "2023 Pacific Coast Rex Sole base assessment; Stock Synthesis 3.30.21; data through 2022",
    source_ref("REX_control.ss and Report.sso", "base run metadata")),
  assume("population", "dimensions", "One U.S. West Coast area; ages 0-34; female and male; one 12-month model season; historical model years 1896-2022; archived forecast through 2034",
    source_ref("REX_data.ss and Report.sso", "model dimensions"),
    notes = "The model age-34 bin is retained as reported; no plus-group label is added."),
  assume("catch", "catch_and_discard_structure", "Two fishery fleets use catch biomass with separate discard-fraction observations from 2002-2021",
    source_ref("REX_data.ss", "Catch data, discard data and fleet information"),
    notes = "Native catch and discard series remain distinct; no catch-at-age observation is present."),
  assume("index", "survey_indices", "Three aggregate biomass-index fleets, SURVEY1-SURVEY3; 28 index observations from 1980-2022",
    source_ref("REX_data.ss", "CPUE data and CPUEinfo"),
    notes = "CPUEinfo unit code 1 denotes biomass-scale indices, not a physical unit. Fleet 5 is associated with WCGBTS CAAL; the other generic fleet-to-survey identities remain unresolved."),
  assume("index", "survey_timing", "Native model month/season code 1; fractional-year timing unresolved",
    source_ref("REX_data.ss", "CPUE, composition and fleet information"),
    notes = "The annual model season does not establish actual sampling dates."),
  assume("composition", "length_and_age_data", "58 length-composition observations; 152 active WCGBTS conditional age-at-length observations for 2007-2019; 13 marginal age-composition rows are excluded from the likelihood by negative fleet code",
    source_ref("REX_data.ss", "lencomp and agecomp"),
    notes = "Native frequency vectors and sample sizes are retained. Age compositions are not age-specific abundance indices."),
  assume("M", "natural_mortality", "Fixed constant M=0.186207 per year for female and male growth patterns; phase -2",
    source_ref("REX_control.ss", "MG_parms NatM_p_1_Fem_GP_1 and NatM_p_1_Mal_GP_1"),
    notes = "M is not estimated in the selected base model."),
  assume("biology", "growth_and_weight", "Sex-specific von Bertalanffy growth is estimated; weight-length parameters are fixed; model-generated weight-at-age is retained as an output",
    source_ref("REX_control.ss and Report.sso", "MG_parms and MEAN_BODY_WT(Begin)")),
  assume("biology", "maturity_and_fecundity", "Length-logistic maturity with fixed Mat50 and slope; egg production is based on length",
    source_ref("REX_control.ss", "maturity_option, fecundity_option and MG_parms"),
    notes = "The model spawning quantity is egg production, not spawning biomass in tonnes."),
  assume("recruitment", "reported_uncertainty", "Tables ii and iii provide 95% asymptotic intervals for spawning output and recruitment for 2013-2023",
    paste0("2023 assessment report, Tables ii-iii; ", report_url),
    notes = "No uncertainty is inferred for age-specific surfaces or other years."),
  assume("outputs", "estimate_convention", "Report.sso fitted historical and default forecast surfaces are retained; recent aggregate spawning-output and recruitment values use the published report tables",
    source_ref("Report.sso and 2023 assessment report", "TIME_SERIES and Tables ii-iii"),
    notes = "Spawning output is recorded in eggs; native age-structured values are point estimates without age-specific uncertainty.")
))

stock <- pacific_database_row("stocks", n = 1L, stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA-NWFSC/SWFSC",
  authority_stock_id = "10059", scientific_name = "Glyptocephalus zachirus",
  common_name = "Pacific Coast rex sole", area = "U.S. West Coast",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "Pacific Coast U.S. stock unit, distinct from NOAA Gulf of Alaska rex sole entities 10058, 15410 and 15411.")
assessment <- pacific_database_row("assessments", n = 1L,
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2022L, estimate_terminal_year = 2034L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.21", is_current = TRUE, is_applied = TRUE,
  framework_year = NA_integer_, assessment_url = report_url,
  framework_url = "", data_url = archive_url, model_url = archive_url,
  repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2023 production base model, fitted through 2022; archived-run forecasts extend through 2034. Catch and aggregate index observations, compositions, and native age-specific outputs are recovered. No observed fishery catch-at-age or age-specific abundance index is present. Spawning output is eggs, not SSB biomass. Recent aggregate spawning-output and recruitment intervals are available for 2013-2023; age-surface uncertainty is unavailable.")

stocks_existing <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
assessments_existing <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
candidates_path <- file.path(root, "discovery/candidates.csv")
selected_path <- file.path(root, "discovery/selected_batch_15_2026.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
selected <- read.csv(selected_path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"), colClasses = "character")
candidate_row <- which(candidates$candidate_id == candidate_id)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(candidate_row) != 1L || length(selected_row) != 1L ||
    candidates$candidate_unit_id[candidate_row] != candidate_unit_id ||
    candidates$eligibility[candidate_row] != "eligible" ||
    candidates$match_status[candidate_row] != "new" ||
    candidates$import_status[candidate_row] != "not_started" ||
    selected$curation_status[selected_row] != "selected_for_source_curation" ||
    any(stocks_existing$stock_id == stock_id) ||
    any(assessments_existing$assessment_id == assessment_id)) {
  stop("Candidate, selection, or canonical database differs from the reviewed state.",
    call. = FALSE)
}

if (any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
    any(inputs$value < 0) || any(outputs$value < 0) ||
    any(inputs$measure == "relative_biomass_index" & inputs$value <= 0) ||
    any(outputs$measure == "natural_mortality_at_age" & outputs$value <= 0) ||
    any(outputs$measure == "maturity_at_age" & outputs$value > 1) ||
    any(!nzchar(inputs$source_reference)) || any(!nzchar(outputs$source_reference))) {
  stop("Prepared source rows failed value, scale, or provenance checks.", call. = FALSE)
}

cat("NOAA Pacific Coast Rex Sole 2023\n")
cat("Inputs:", nrow(inputs), "rows; outputs:", nrow(outputs),
  "rows; assumptions:", nrow(assumptions), "rows\n")
cat("Input measures:\n")
print(table(inputs$measure))
cat("Output measures:\n")
print(table(outputs$measure))

if (write_mode) {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)

  candidate <- candidates[candidate_row, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$matched_stock_id <- stock_id
  candidate$catch_age_evidence <- "The native 2023 run has no fishery catch-at-age likelihood input. Fishery length compositions, WCGBTS conditional age-at-length data, and catch biomass are retained as original inputs; no catch-at-age reconstruction is added to the canonical database."
  candidate$survey_age_evidence <- "WCGBTS conditional age-at-length observations and aggregate survey biomass indices are retained separately. No age-specific abundance index is present; the CAAL sample is not an abundance index."
  candidate$weights_evidence <- "The native control defines fixed weight-at-length relationships and estimated sex-specific growth. Beginning-of-year weight-at-age is imported from Report.sso as a model-derived output, not a supplied weight-at-age input."
  candidate$maturity_evidence <- "The control uses fixed length-logistic maturity and length-based egg production. The report's spawning output is eggs, not mature biomass; no observed maturity-at-age input is supplied."
  candidate$mortality_evidence <- "The selected base run fixes natural mortality at 0.186207 per year for both sexes (control phases -2); M is not estimated. The reported M-at-age surface is retained as a model output."
  candidate$timing_evidence <- "The model uses one 12-month season and a native month/season code of 1. No fractional-year timing is verified; timing is not converted."
  candidate$output_evidence <- "The official report gives spawning-output and recruitment estimates with 95% asymptotic intervals for 2013-2023. Report.sso provides point-estimate age surfaces through the archived forecast year 2034; age-specific uncertainty is unavailable."
  candidate$decision_reason <- "Selected and partially imported from the official 2023 production base run. Native catch, discard, aggregate index, composition, assumption, and fitted-output data are preserved. No observed fishery catch-at-age or age-specific abundance index is present; keep reconstructed age series outside the canonical source record."
  candidate$notes <- "NOAA Stock SMART entity 10059, assessment 12970 (locked); separate from Gulf of Alaska rex sole entities 10058, 15410 and 15411. Stock Synthesis 3.30.21; data through 2022; default archived forecast through 2034. See source_reviews/noaa_pacific_rex_sole_2023.md and source_cache/discovery_noaa_pacific_rex_2023/sources.csv."
  replace_candidate_register_row(candidates_path, candidate_row, candidate, candidate_id)

  selected$curation_status[selected_row] <- "partial_source_import"
  write.csv(selected, selected_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts/database/195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts/database/196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported the verified source record and marked it partial.\n")
}
