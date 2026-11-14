root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_copper_california_2023")
assessment_id <- "noaa_copper_rockfish_california_2023"
stock_id <- "noaa_copper_rockfish_california"
candidate_unit_id <- assessment_id
candidate_ids <- c("NOAA:15332", "NOAA:15333")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(file.path(root, "provenance/discovery_noaa_copper_california_2023/sources.csv"),
  colClasses = "character", check.names = FALSE)
sha256_file <- function(path) {
  output <- system2("certutil.exe",
    c("-hashfile", shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
    stdout = TRUE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
    output, value = TRUE)))
  if (length(hash) != 1L) stop("Could not verify SHA-256 for ", path, call. = FALSE)
  hash
}
files <- c("copper_ca_2023_preassessment_workshop.pdf", "copper_ca_2023_star_panel.pdf",
  "copper_ca_north_2023_assessment.pdf", "copper_ca_north_2023_model_files.zip",
  "copper_ca_south_2023_assessment.pdf", "copper_ca_south_2023_model_files.zip")
hashes <- c("cbf946f472196070b54a5a15a4f8ad63a1469a40bd158928c6c1b017a152693b",
  "b9b652c8a1ba5ab18711375c25aade9735ed45eef933e269c4e5967e997f742d",
  "77d7355d39387321b4cb658cdb4c8278087ce7095bebae55964b37c6741dcc1b",
  "7e73cb89a067a1c2e47a037139951dbbe495bc19bbd9223f69eb4129b6a8507a",
  "ac9f8217c49c958df45c977f391768631ddcce7c8cac9bd2850fe5468a768662",
  "126dca017d25406195fdf7a7f08f5c05702ebbc653dbc1bd5bac33b576400644")
if (!all(c("file", "url", "retrieved_on", "bytes", "sha256") %in% names(manifest)) ||
    !setequal(manifest$file, files) || anyDuplicated(manifest$file))
  stop("The California copper provenance manifest is incomplete.", call. = FALSE)
verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(cache, file)
  expected <- hashes[match(file, files)]
  if (nrow(row) != 1L || !file.exists(path) ||
      row$retrieved_on != "2026-11-11" || as.numeric(row$bytes) != file.info(path)$size ||
      tolower(row$sha256) != expected || sha256_file(path) != expected)
    stop("Cached source differs from the verified manifest: ", file, call. = FALSE)
  path
}
invisible(lapply(files, verify_source))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE))
  stop("Install r4ss and pdftools to read the cached Stock Synthesis sources.", call. = FALSE)

table_fields <- lapply(c("inputs", "outputs", "assumptions"), function(table)
  names(utils::read.csv(file.path(database, paste0(table, ".csv")), nrows = 0L, check.names = FALSE)))
names(table_fields) <- c("inputs", "outputs", "assumptions")
make_rows <- function(table, values, n) {
  fields <- table_fields[[table]]
  out <- as.data.frame(setNames(rep(list(rep("", n)), length(fields)), fields),
    check.names = FALSE, stringsAsFactors = FALSE)
  for (name in names(values)) {
    if (!name %in% fields) stop("Unknown ", table, " field: ", name, call. = FALSE)
    out[[name]] <- rep_len(values[[name]], n)
  }
  out
}
make_input <- function(n, ...) make_rows("inputs",
  c(list(assessment_id = assessment_id, source_type = "native_model"), list(...)), n)
make_output <- function(n, ...) make_rows("outputs",
  c(list(assessment_id = assessment_id, source_type = "native_model"), list(...)), n)
input_rows <- list()
output_rows <- list()
assumption_rows <- list()
add_input <- function(x) input_rows[[length(input_rows) + 1L]] <<- x
add_output <- function(x) output_rows[[length(output_rows) + 1L]] <<- x
add_assumption <- function(region, component, setting, value, source_reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows("assumptions",
    list(assessment_id = assessment_id, region = region, component = component,
      setting = setting, value = value, source_reference = source_reference,
      notes = notes), 1L)
}
model <- list(
  north = list(dir = "nca", data = "2023_ca_n_copper.dat", report = "copper_ca_north_2023_assessment.pdf",
    archive = "copper_ca_north_2023_model_files.zip", region = "North of Point Conception",
    counts = c(catch = 327L, index = 76L, length = 219L, age = 489L, conditional = 450L, marginal = 39L)),
  south = list(dir = "sca", data = "2023_ca_s_copper.dat", report = "copper_ca_south_2023_assessment.pdf",
    archive = "copper_ca_south_2023_model_files.zip", region = "South of Point Conception",
    counts = c(catch = 326L, index = 77L, length = 185L, age = 771L, conditional = 747L, marginal = 24L)))
source_ref <- function(area, section) paste0(model[[area]]$archive, ", ",
  model[[area]]$dir, "/", section)
data_objects <- list()
output_objects <- list()
for (area in names(model)) {
  info <- model[[area]]
  dir <- file.path(cache, "extracted", area, info$dir)
  dat <- suppressWarnings(r4ss::SS_readdat(file.path(dir, info$data),
    version = "3.30.21", verbose = FALSE))
  out <- r4ss::SS_output(dir = dir, covar = FALSE, forecast = FALSE,
    warn = FALSE, readwt = FALSE, verbose = FALSE)
  conditional <- dat$agecomp$Lbin_lo >= 0 & dat$agecomp$Lbin_hi >= 0
  marginal <- dat$agecomp$Lbin_lo == -1 & dat$agecomp$Lbin_hi == -1
  if (dat$styr != 1916L || dat$endyr != 2022L || dat$Nsexes != 2L ||
      dat$Nages != 50L || dat$nseas != 1L ||
      !identical(as.integer(dat$agebin_vector), 0:50) || dat$Lbin_method != 3L ||
      !all(dat$units_of_catch == 1L) || nrow(dat$catch) != info$counts["catch"] ||
      nrow(dat$CPUE) != info$counts["index"] || nrow(dat$lencomp) != info$counts["length"] ||
      nrow(dat$agecomp) != info$counts["age"] ||
      sum(conditional) != info$counts["conditional"] || sum(marginal) != info$counts["marginal"] ||
      !all(range(abs(dat$agecomp$year)) == c(if (area == "north") 1978 else 1975, 2022)) ||
      !identical(sort(unique(as.integer(dat$CPUEinfo$units))), 1L) ||
      !identical(sort(unique(as.integer(dat$CPUEinfo$errtype))), 0L) ||
      any(dat$catch$catch_se != 0.01) || any(dat$catch$catch < 0) ||
      any(dat$CPUE$obs <= 0 | dat$CPUE$se_log <= 0) ||
      (any(dat$agecomp$Nsamp <= 0) || any(dat$lencomp$Nsamp <= 0)) ||
      any(!(conditional | marginal)))
    stop("The ", area, " source data differ from the screened 2023 assessment.", call. = FALSE)
  fleets <- as.character(dat$fleetinfo$fleetname)
  if (sum(dat$fleetinfo$type == 1L) != 4L ||
      !identical(sort(unique(as.integer(dat$agecomp$sex))), 0:3) ||
      !identical(sort(unique(as.integer(dat$lencomp$sex))), c(0L, 3L)))
    stop("The ", area, " fleet or sex structure differs from the screened assessment.", call. = FALSE)

  catch <- dat$catch
  add_input(make_input(nrow(catch), type = "catch", measure = "catch_biomass",
    basis = "biomass", fleet = fleets[as.integer(catch$fleet)],
    region = info$region, year = abs(catch$year), year_basis = "calendar_year",
    season = "annual", value = catch$catch, unit = "metric tons",
    source_reference = source_ref(area, "Catch data"),
    notes = "Native annual fishery catch biomass in metric tons; catch_se=0.01 is retained as a separate model setting."))
  cpue <- dat$CPUE
  timing <- (cpue$month - 1) / 12
  add_input(make_input(nrow(cpue), type = "index",
    measure = "relative_biomass_index", basis = "index_scale",
    survey = fleets[as.integer(cpue$index)], region = info$region,
    year = cpue$year, year_basis = "calendar_year",
    season = paste0("month ", cpue$month), sampling_time = timing,
    value = cpue$obs, unit = "native relative biomass-index units (SS3 unit code 1)",
    source_reference = source_ref(area, "CPUE observations"),
    notes = "Native aggregate index; SS3 error type 0 is lognormal. sampling_time=(month-1)/12 is the model month representation."))
  add_input(make_input(nrow(cpue), type = "index", measure = "log_index_sd",
    basis = "log_scale", survey = fleets[as.integer(cpue$index)],
    region = info$region, year = cpue$year, year_basis = "calendar_year",
    season = paste0("month ", cpue$month), sampling_time = timing,
    value = cpue$se_log, unit = "log-scale standard error",
    source_reference = source_ref(area, "CPUE se_log"),
    notes = "Native standard errors for the aggregate lognormal index likelihood."))

  add_compositions <- function(x, kind, bins) {
    age <- kind == "age"
    for (i in seq_len(nrow(x))) {
      r <- x[i, , drop = FALSE]
      code <- as.integer(r$sex)
      fv <- as.numeric(r[1L, paste0("f", bins), drop = TRUE])
      mv <- as.numeric(r[1L, paste0("m", bins), drop = TRUE])
      if (code == 3L) {
        parts <- list(female = fv, male = mv)
      } else if (code == 0L) {
        if (!isTRUE(all.equal(fv, mv, tolerance = 1e-10)))
          stop("Combined-sex composition placeholders differ in ", area, " row ", i, ".", call. = FALSE)
        parts <- list(combined = fv)
      } else if (code == 1L) {
        parts <- list(female = fv)
      } else if (code == 2L) {
        parts <- list(male = mv)
      } else {
        stop("Unexpected SS3 composition sex code.", call. = FALSE)
      }
      fleet <- abs(as.integer(r$fleet))
      fishery <- dat$fleetinfo$type[fleet] == 1L
      is_conditional <- age && r$Lbin_lo >= 0 && r$Lbin_hi >= 0
      measure <- if (is_conditional) "conditional_frequency_at_age" else
        if (age) "frequency_at_age" else "frequency_at_length"
      type <- if (is_conditional) "biology" else if (fishery) "catch" else "index"
      note <- if (is_conditional) "Conditional age-at-length frequency; Lbin_method=3 stores length limits in centimetres." else
        if (age) "Marginal age-composition frequency." else
          "Native length-composition frequency; length_bin stores the source Stock Synthesis label in centimetres."
      note <- paste(note, "Frequencies are preserved without normalization; sample_size is stored separately.",
        if (code == 3L) "Sex code 3 has separate female/male vectors." else "One identical placeholder vector is retained for sex codes 0, 1 or 2.",
        if (r$year < 0) "The source year was negative; its absolute calendar year is stored." else "",
        if (as.integer(r$fleet) < 0) "The source fleet code was negative; its absolute fleet is stored." else "")
      for (sex in names(parts)) {
        lower <- if (is_conditional) r$Lbin_lo else if (!age) bins else NA_real_
        upper <- if (is_conditional) r$Lbin_hi else NA_real_
        add_input(make_input(length(bins), type = type, measure = measure,
          basis = "native_frequency", value = parts[[sex]], unit = "source frequency",
          fleet = if (type == "catch") fleets[fleet] else "",
          survey = if (type == "index") fleets[fleet] else "",
          sex = sex, region = info$region, year = abs(r$year),
          year_basis = "calendar_year", age = if (age) bins else NA_real_,
          length_bin = if (age) NA_real_ else bins,
          length_bin_lower = lower, length_bin_upper = upper,
          sample_size = r$Nsamp, age_error = if (age) r$ageerr else NA_real_,
          partition = as.character(r$part), season = paste0("month ", r$month),
          sampling_time = (r$month - 1) / 12,
          source_reference = source_ref(area, if (age) "age-composition block" else "length-composition block"),
          notes = paste(note, if (age) paste0("Native age-error code ", r$ageerr, " is retained.") else ""),
          observation_id = paste(area, kind, i, sex, sep = ":")))
      }
    }
  }
  add_compositions(dat$lencomp, "length", dat$lbin_vector)
  add_compositions(dat$agecomp, "age", dat$agebin_vector)

  add_assumption(info$region, "model", "structure",
    "Separate Stock Synthesis subarea model; one annual season; two sexes; ages 0-50, with age 50 as the accumulator group.",
    source_ref(area, "data.ss and control.ss"))
  add_assumption(info$region, "catch", "catch_units",
    "Four fishery fleets; annual catch entered as biomass in metric tons.",
    source_ref(area, "fleet table and catch block"),
    "These are aggregate catch inputs, not observed catch-at-age numbers.")
  add_assumption(info$region, "catch", "catch_se",
    paste(unique(dat$catch$catch_se), collapse = "; "),
    source_ref(area, "catch error field"),
    "Preserved as a model setting; not treated as an observation standard error.")
  add_assumption(info$region, "index", "aggregate_indices",
    paste0(length(unique(cpue$index)), " aggregate biomass-index series; SS3 unit code 1; lognormal error type 0."),
    source_ref(area, "CPUE units and error configuration"),
    "Age compositions are separate samples, not age-specific abundance indices.")
  add_assumption(info$region, "composition", "age_length_samples",
    paste0(nrow(dat$agecomp), " age rows (", sum(conditional), " conditional and ", sum(marginal),
      " marginal) and ", nrow(dat$lencomp), " length-composition rows."),
    source_ref(area, "age/length composition blocks"),
    "Native frequency values and sample sizes are retained. Conditional age-length limits are in cm; age-error codes refer to definitions in the archived control file.")
  add_assumption(info$region, "biology", "weight_maturity",
    "Sex-specific growth and length-weight relationships; length-logistic maturity.",
    source_ref(area, "control.ss and assessment report"),
    "No standalone empirical weight-at-age or maturity-at-age matrices are supplied; age surfaces are model-derived.")
  add_assumption(info$region, "mortality", "natural_mortality",
    "M=0.108 per year, fixed for both sexes.",
    source_ref(area, "control.ss and Report.sso M_at_age"),
    "Natural mortality is fixed, not estimated.")
  add_assumption(info$region, "recruitment", "stock_recruitment",
    paste0("Beverton-Holt; steepness fixed at 0.72; recruitment deviations begin in ",
      if (area == "north") "1970." else "1965."),
    verify_source(info$report), "Recruitment start year differs between the two subarea models.")
  add_assumption(info$region, "timing", "survey_months",
    paste(sort(unique(cpue$month)), collapse = "; "),
    source_ref(area, "CPUE month field"),
    "The native annual model stores survey month; sampling_time=(month-1)/12 is a documented representation.")
  data_objects[[area]] <- dat
  output_objects[[area]] <- out
}
long_age <- function(x, ages) {
  matrix <- as.matrix(x[, as.character(ages), drop = FALSE])
  data.frame(row = rep(seq_len(nrow(x)), each = length(ages)),
    age = rep(ages, times = nrow(x)), value = as.vector(t(matrix)))
}
annuals <- list()
for (area in names(model)) {
  info <- model[[area]]
  dat <- data_objects[[area]]
  z <- output_objects[[area]]
  years <- 1916:2022
  population_rows <- function(x) x$Area == 1 & x$Bio_Pattern == 1 &
    x$Sex %in% 1:2 & x$Morph == x$Sex & x$Seas == 1 &
    x$Era == "TIME" & x$Yr %in% years
  n <- z$natage[population_rows(z$natage) &
    z$natage$BirthSeas == 1 & z$natage$Settlement == 1 &
    z$natage$Platoon == 1 & z$natage[["Beg/Mid"]] == "B", , drop = FALSE]
  b <- z$batage[population_rows(z$batage) &
    z$batage$BirthSeas == 1 & z$batage$Settlement == 1 &
    z$batage$Platoon == 1 & z$batage[["Beg/Mid"]] == "B", , drop = FALSE]
  f <- z$fatage[z$fatage$Area == 1 & z$fatage$Fleet %in% 1:4 &
    z$fatage$Sex %in% 1:2 & z$fatage$Morph == z$fatage$Sex &
    z$fatage$Seas == 1 & z$fatage$Era == "TIME" & z$fatage$Yr %in% years, , drop = FALSE]
  c_age <- z$catage[z$catage$Area == 1 & z$catage$Fleet %in% 1:4 &
    z$catage$Sex %in% 1:2 & z$catage$Type == "dead" &
    z$catage$Morph == z$catage$Sex & z$catage$Seas == 1 &
    z$catage$Era == "TIME" & z$catage$Yr %in% years, , drop = FALSE]
  annual <- z$timeseries[z$timeseries$Area == 1 &
    z$timeseries$Era == "TIME" & z$timeseries$Yr %in% years, , drop = FALSE]
  if (nrow(n) != length(years) * 2L || nrow(b) != length(years) * 2L ||
      nrow(f) != length(years) * 8L || nrow(c_age) != length(years) * 8L ||
      nrow(annual) != length(years) || !identical(sort(unique(as.integer(n$Yr))), years))
    stop("Unexpected fitted output coverage for ", area, ".", call. = FALSE)
  n_long <- long_age(n, 0:50)
  add_output(make_output(nrow(n_long), type = "population", measure = "numbers_at_age",
    region = info$region, year = n$Yr[n_long$row], age = n_long$age,
    age_group = ifelse(n_long$age == 50, "50+", ""),
    sex = ifelse(n$Sex[n_long$row] == 1, "female", "male"),
    value = n_long$value, unit = "thousand fish",
    source_reference = source_ref(area, "NUMBERS_AT_AGE report"),
    notes = "Beginning-of-year fitted N-at-age; age 50 is the accumulator group. No age-year uncertainty is tabulated."))
  b_long <- long_age(b, 0:50)
  add_output(make_output(nrow(b_long), type = "biomass", measure = "biomass_at_age",
    region = info$region, year = b$Yr[b_long$row], age = b_long$age,
    age_group = ifelse(b_long$age == 50, "50+", ""),
    sex = ifelse(b$Sex[b_long$row] == 1, "female", "male"),
    value = b_long$value, unit = "metric tons",
    source_reference = source_ref(area, "BIOMASS_AT_AGE report"),
    notes = "Beginning-of-year model-derived biomass-at-age; age 50 is the accumulator group. No age-year uncertainty is tabulated."))
  catch_long <- long_age(c_age, 0:50)
  add_output(make_output(nrow(catch_long), type = "catch", measure = "catch_numbers_at_age",
    region = info$region, year = c_age$Yr[catch_long$row], age = catch_long$age,
    age_group = ifelse(catch_long$age == 50, "50+", ""),
    fleet = fleets[c_age$Fleet[catch_long$row]],
    sex = ifelse(c_age$Sex[catch_long$row] == 1, "female", "male"),
    value = catch_long$value, unit = "thousand fish",
    source_reference = source_ref(area, "CATCH_AT_AGE report"),
    notes = "Fitted dead catch-at-age output, not an observed catch-at-age input; age 50 is the accumulator group."))
  f_long <- long_age(f, 0:50)
  fleets <- data_objects[[area]]$fleetinfo$fleetname
  add_output(make_output(nrow(f_long), type = "mortality", measure = "fishing_mortality_at_age",
    region = info$region, year = f$Yr[f_long$row], age = f_long$age,
    age_group = ifelse(f_long$age == 50, "50+", ""),
    fleet = fleets[f$Fleet[f_long$row]],
    sex = ifelse(f$Sex[f_long$row] == 1, "female", "male"),
    value = f_long$value, unit = "per year",
    source_reference = source_ref(area, "F_AT_AGE report"),
    notes = "Fitted F-at-age by fishery fleet and sex; age 50 is the accumulator group. No age-year uncertainty is tabulated."))
  total <- aggregate(n_long$value, list(year = n$Yr[n_long$row]), sum)
  add_output(make_output(nrow(total), type = "population", measure = "total_abundance",
    region = info$region, year = total$year, value = total$x,
    unit = "thousand fish", source_type = "derived_source_output",
    source_reference = source_ref(area, "NUMBERS_AT_AGE report; sum of ages 0-50 and both sexes"),
    notes = "Derived by summing beginning-of-year N-at-age across ages and sexes; no uncertainty is calculated."))
  add_output(make_output(nrow(annual), type = "recruitment", measure = "recruitment",
    region = info$region, year = annual$Yr, age = 0, value = annual$Recruit_0,
    unit = "thousand fish", source_reference = source_ref(area, "TIME_SERIES report"),
    notes = "Fitted age-0 recruitment; no annual uncertainty is tabulated."))
  annuals[[area]] <- annual
}
read_spawning_table <- function(path, table_id) {
  lines <- trimws(unlist(strsplit(paste(pdftools::pdf_text(path), collapse = "\n"), "\n")))
  marker <- grep(paste0("^Table ", table_id, ": Estimated recent trend in spawning output"),
    lines, ignore.case = TRUE)[1L]
  if (is.na(marker)) stop("Missing Table ", table_id, " in ", path, call. = FALSE)
  following <- if (table_id == "iii")
    grep("^Table iv:", lines, ignore.case = TRUE)[1L] else
      grep("^Table v:", lines, ignore.case = TRUE)[1L]
  end <- if (is.na(following)) length(lines) else following - 1L
  block <- lines[marker:end]
  rows <- list()
  for (line in block) {
    fields <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (length(fields) != 7L || !grepl("^20[0-9]{2}$", fields[1L])) next
    value <- suppressWarnings(as.numeric(fields))
    if (!anyNA(value) && value[1L] >= 2013 && value[1L] <= 2023)
      rows[[length(rows) + 1L]] <- value
  }
  if (!length(rows)) stop("Table ", table_id, " has no recent spawning-output rows.", call. = FALSE)
  x <- as.data.frame(do.call(rbind, rows))
  names(x) <- c("year", "value", "lwr", "upr", "fraction", "fraction_lwr", "fraction_upr")
  x <- x[!duplicated(x$year), , drop = FALSE]
  x[order(x$year), , drop = FALSE]
}
for (area in names(model)) {
  info <- model[[area]]
  pdf_path <- verify_source(info$report)
  table <- read_spawning_table(pdf_path, if (area == "north") "iv" else "iii")
  annual <- annuals[[area]]
  overlap <- merge(table, annual[, c("Yr", "SpawnBio")], by.x = "year", by.y = "Yr")
  terminal <- if (area == "north") 208.74 else 32.06
  if (!identical(as.integer(table$year), 2013:2023) ||
      max(abs(overlap$value - overlap$SpawnBio)) > 0.03 ||
      table$value[table$year == 2023] != terminal)
    stop("Official spawning-output table does not match the native report for ", area, ".", call. = FALSE)
  recent <- merge(annual, table, by.x = "Yr", by.y = "year", all.x = TRUE)
  add_output(make_output(nrow(recent), type = "biomass", measure = "spawning_output",
    region = info$region, year = recent$Yr, value = recent$SpawnBio,
    lwr = recent$lwr, upr = recent$upr, unit = "billion eggs",
    source_reference = paste(source_ref(area, "TIME_SERIES report"),
      "; official assessment report Table", if (area == "north") "iv" else "iii"),
    notes = "Point estimates from the fitted model; 2013-2022 95% intervals are from the official assessment table."))
  final <- table[table$year == 2023, , drop = FALSE]
  add_output(make_output(1L, type = "biomass", measure = "spawning_output",
    region = info$region, year = 2023, value = final$value,
    lwr = final$lwr, upr = final$upr, unit = "billion eggs",
    source_type = "official_table",
    source_reference = paste(info$report, "Table", if (area == "north") "iv" else "iii"),
    notes = "Official 2023 spawning-output estimate and 95% interval, reported in billions of eggs."))
}
input_data <- do.call(rbind, input_rows)
output_data <- do.call(rbind, output_rows)
assumption_data <- do.call(rbind, assumption_rows)
if (any(!is.finite(input_data$value)) || any(!is.finite(output_data$value)))
  stop("Source rows contain non-finite values.", call. = FALSE)

stock_table <- read.csv(file.path(database, "stocks.csv"), na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE)
assessment_table <- read.csv(file.path(database, "assessments.csv"), na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE)
if (stock_id %in% stock_table$stock_id || assessment_id %in% assessment_table$assessment_id)
  stop("California copper records already exist; inspect before importing.", call. = FALSE)
blank_row <- function(fields, values) {
  x <- as.list(rep("", length(fields)))
  names(x) <- fields
  for (name in names(values)) x[[name]] <- as.character(values[[name]])
  as.data.frame(x, check.names = FALSE, stringsAsFactors = FALSE)
}
stock <- blank_row(names(stock_table), list(
  stock_id = stock_id, authority = "NOAA-NWFSC/SWFSC", authority_stock_id = "15332; 15333",
  scientific_name = "Sebastes caurinus", common_name = "Copper rockfish - California",
  area = "California coast, north and south of Point Conception",
  region = "California", ocean = "Northeast Pacific",
  notes = "One California assessment with separate north and south subarea model records. NOAA Stock SMART IDs 15332 and 15333 refer to these subareas; Washington and Oregon are separate assessment units."))
report_urls <- c(
  north = "https://www.pcouncil.org/documents/2024/03/status-of-copper-rockfish-along-the-u-s-california-coast-north-of-point-conception-in-2023.pdf/",
  south = "https://www.pcouncil.org/documents/2024/02/status-of-copper-rockfish-sebastes-caurinus-along-the-u-s-california-coast-south-of-point-conception-in-2023-november-2023.pdf/")
framework_urls <- c(
  "https://www.pcouncil.org/documents/2023/06/star-panel-1-report-for-copper-rockfish-in-ca-rex-sole-and-shortspine-thornyhead.pdf/",
  "https://www.pcouncil.org/documents/report-of-the-pre-assessment-workshop-for-2023-groundfish-stock-assessments-of-copper-rockfish-canary-rockfish-and-black-rockfish/")
archives <- manifest$url[match(c(model$north$archive, model$south$archive), manifest$file)]
assessment <- blank_row(names(assessment_table), list(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2023L,
  terminal_year = 2022L, estimate_terminal_year = 2023L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "3.30.21.00", is_current = TRUE, is_applied = TRUE,
  assessment_url = paste(report_urls, collapse = "; "),
  framework_url = paste(framework_urls, collapse = "; "),
  data_url = paste(archives, collapse = "; "), model_url = paste(archives, collapse = "; "),
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2023 California assessment; separate north and south models use data through 2022. Native catch biomass, aggregate indices and age/length samples, plus fitted N/B/F/C-at-age surfaces, are retained by subarea. Catch-at-age is an output, not an observed input; standalone empirical weight-at-age and maturity-at-age matrices are unavailable. Spawning-output intervals are reported for 2013-2023; age-specific uncertainties are not."))

candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
candidates <- read.csv(candidate_path, na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE)
inventory <- read.csv(inventory_path, na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE)
candidate_rows <- match(candidate_ids, candidates$candidate_id)
inventory_rows <- which(inventory$candidate_unit_id == candidate_unit_id)
if (anyNA(candidate_rows) || length(inventory_rows) != 1L ||
    any(candidates$candidate_unit_id[candidate_rows] != candidate_unit_id) ||
    any(candidates$eligibility[candidate_rows] != "eligible") ||
    inventory$import_status[inventory_rows] != "not_started")
  stop("The California copper candidate register no longer matches the screened assessment.", call. = FALSE)
candidate_updates <- candidates[candidate_rows, , drop = FALSE]
candidate_updates$matched_stock_id <- stock_id
candidate_updates$match_status <- "new"
candidate_updates$import_status <- "partial"
candidate_updates$catch_age_evidence <- "Imported native catch biomass and age-composition samples; these are not observed annual catch-at-age numbers."
candidate_updates$survey_age_evidence <- "Imported aggregate biomass indices and age-composition samples; no direct age-specific survey abundance series is supplied."
candidate_updates$weights_evidence <- "The fitted model has derived biomass-at-age; a standalone empirical weight-at-age matrix is not supplied."
candidate_updates$maturity_evidence <- "The control files specify length-logistic maturity; a standalone empirical maturity-at-age matrix is not supplied."
candidate_updates$mortality_evidence <- "Natural mortality is fixed at 0.108 per year for both sexes."
candidate_updates$timing_evidence <- "Native survey/composition months are retained; sampling_time=(month-1)/12 is a documented timing representation."
candidate_updates$output_evidence <- "Native fitted N/B/F/C-at-age surfaces are available through 2022; official spawning output is available through 2023 with intervals for 2013-2023."
candidate_updates$review_date <- "2026-11-11"
candidate_updates$decision_reason <- "Imported one 2023 California copper rockfish assessment family with separate north and south subarea model records."
candidate_updates$notes <- "Partial source import; fitted catch-at-age is not observed catch-at-age, and age compositions are not abundance indices."
inventory_update <- inventory[inventory_rows, , drop = FALSE]
inventory_update$matched_stock_id <- stock_id
inventory_update$import_status <- "partial"
if (write_mode) {
  append_pacific_case(stock, assessment, assumption_data, input_data, output_data)
  for (i in seq_along(candidate_rows))
    replace_candidate_register_row(candidate_path, candidate_rows[i],
      candidate_updates[i, , drop = FALSE], candidate_ids[i])
  replace_csv_register_row(inventory_path, inventory_rows, inventory_update,
    "unit_key", inventory_update$unit_key)
}
cat(if (write_mode) "Imported " else "Prepared ",
  nrow(input_data), " inputs, ", nrow(assumption_data), " assumptions, and ",
  nrow(output_data), " outputs for the 2023 NOAA California copper assessment.\n", sep = "")
