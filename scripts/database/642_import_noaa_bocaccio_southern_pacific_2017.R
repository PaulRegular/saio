root <- "."
source_dir <- file.path(root, "../../discovery_noaa_bocaccio_southern_pacific_2017")
model_dir <- file.path(source_dir, "bocaccio_2017_model_files")
assessment_id <- "noaa_bocaccio_southern_pacific_2017"
stock_id <- "noaa_bocaccio_southern_pacific_coast"
candidate_id <- "NOAA:10413"
candidate_unit_id <- "noaa_bocaccio_southern_pacific_coast"
report_url <- "https://www.pcouncil.org/documents/2017/02/stock-assessment-update-status-of-bocaccio-sebastes-paucispinis-in-the-conception-monterey-and-eureka-inpfc-areas-for-2017.pdf"
model_url <- "https://www.pcouncil.org/documents/2017-bocaccio-model-files-zip-file-47-kb/"
projection_url <- "https://www.pcouncil.org/documents/2025/08/g-3-attachment-18-catch-only-projection-for-bocaccio-in-2025.pdf/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache/r-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

manifest <- read.csv(file.path(root, "provenance/discovery_noaa_bocaccio_southern_pacific_2017/sources.csv"),
  colClasses = "character", check.names = FALSE)
sha256_file <- function(path) toupper(unname(tools::sha256sum(path)))
verify_source <- function(file) {
  row <- manifest[manifest$file == file, , drop = FALSE]
  path <- file.path(source_dir, file)
  if (nrow(row) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), toupper(row$sha256))) {
    stop("Cached source differs from provenance: ", file, call. = FALSE)
  }
  path
}
report_path <- verify_source("bocaccio_2017_assessment.pdf")
invisible(verify_source("bocaccio_2017_model_files.zip"))
projection_path <- verify_source("bocaccio_2025_catch_only_projection.pdf")
data_path <- file.path(model_dir, "boc1.dat")
control_path <- file.path(model_dir, "boc1.ctl")
if (!all(file.exists(c(data_path, control_path, file.path(model_dir, "forecast.ss"),
    file.path(model_dir, "starter.SS")))) ||
    any(file.exists(file.path(model_dir, c("Report.sso", "CompReport.sso")))) ||
    length(list.files(model_dir, pattern = "\\.par$", ignore.case = TRUE)) > 0L) {
  stop("The cached archive differs from the reviewed input-only model files.", call. = FALSE)
}
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to parse the cached Bocaccio sources.", call. = FALSE)
}

dat <- suppressWarnings(r4ss::SS_readdat(data_path, version = "3.24", verbose = FALSE))
fleet_names <- rownames(dat$fleetinfo)
fleet_type <- as.integer(dat$fleetinfo$type)
fleet_timing <- as.numeric(dat$fleetinfo$surveytiming)
catch_fleets <- setdiff(names(dat$catch), c("year", "seas"))
index_fleets <- as.integer(dat$CPUEinfo$Fleet)
index_units <- as.integer(dat$CPUEinfo$Units)
if (dat$styr != 1892L || dat$endyr != 2016L || dat$nseas != 1L ||
    dat$Nsexes != 2L || dat$Nages != 21L ||
    !identical(as.integer(dat$agebin_vector), 0:21) ||
    !identical(as.integer(dat$lbin_vector), as.integer(seq(10, 76, 2))) ||
    nrow(dat$fleetinfo) != 18L || !identical(catch_fleets, fleet_names[1:6]) ||
    nrow(dat$CPUE) != 232L || nrow(dat$agecomp) != 882L ||
    nrow(dat$lencomp) != 314L || !all(as.integer(dat$units_of_catch) == 1L) || !setequal(index_units, c(0L, 1L)) ||
    any(!index_fleets %in% seq_along(fleet_names))) {
  stop("The cached Stock Synthesis 3.24 data differ from the reviewed run.", call. = FALSE)
}

region_name <- "Southern Pacific Coast"
source_reference <- function(file, section) paste0(file, ", ", section)
input_rows <- list()
add_input <- function(...) {
  input_rows[[length(input_rows) + 1L]] <<- pacific_database_row("inputs",
    assessment_id = assessment_id, source_type = "native_model", ...)
}
catch_long <- do.call(rbind, lapply(catch_fleets, function(name) {
  data.frame(fleet = name, year = as.integer(dat$catch$year),
    value = as.numeric(dat$catch[[name]]), stringsAsFactors = FALSE)
}))
if (!identical(sort(unique(catch_long$year)), 1892:2016) ||
    any(!is.finite(catch_long$value)) || any(catch_long$value < 0)) {
  stop("Native catch rows are incomplete or invalid.", call. = FALSE)
}
add_input(type = "catch", measure = "catch_biomass", basis = "biomass",
  fleet = catch_long$fleet, region = region_name, season = "annual",
  year = catch_long$year, year_basis = "calendar_year", value = catch_long$value,
  unit = "metric tons", source_reference = source_reference("boc1.dat", "catch biomass block"),
  notes = "Native annual catch biomass by fishery fleet. All six fleet catch-unit codes are biomass; zero values are retained.")

index_rows <- dat$CPUE
for (i in seq_len(nrow(index_rows))) {
  x <- index_rows[i, , drop = FALSE]
  fleet_id <- as.integer(x$index)
  unit_code <- index_units[match(fleet_id, index_fleets)]
  measure <- switch(as.character(unit_code),
    "0" = "relative_abundance_index", "1" = "relative_biomass_index",
    "2" = "relative_fishing_mortality_index",
    stop("Unexpected CPUE units code.", call. = FALSE))
  fleet_label <- fleet_names[fleet_id]
  is_survey <- fleet_type[fleet_id] == 3L
  source_year <- as.integer(x$year)
  id <- paste0("CPUE:", i, ":source_year:", source_year)
  fields <- list(fleet = if (is_survey) "" else fleet_label,
    survey = if (is_survey) fleet_label else "",
    year = abs(source_year), sampling_time = fleet_timing[fleet_id])
  unit_text <- switch(as.character(unit_code),
    "0" = "native index scale (numbers; Stock Synthesis units code 0)",
    "1" = "native index scale (biomass; Stock Synthesis units code 1)",
    "2" = "native index scale (fishing mortality; Stock Synthesis units code 2)")
  add_input(type = "index", measure = measure, basis = "index_scale",
    fleet = fields$fleet, survey = fields$survey, region = region_name,
    season = "annual", sampling_time = fields$sampling_time, year = fields$year,
    year_basis = "calendar_year", value = as.numeric(x$obs), unit = unit_text,
    observation_id = id,
    source_reference = source_reference("boc1.dat", "CPUE observations and units"),
    notes = paste("Native aggregate index, not age-specific. Fleet timing is retained. Source year:", source_year,
      "source fleet:", fleet_id, fleet_label, "units code:", unit_code))
  add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
    fleet = fields$fleet, survey = fields$survey, region = region_name,
    season = "annual", sampling_time = fields$sampling_time, year = fields$year,
    year_basis = "calendar_year", value = as.numeric(x$se_log), unit = "log scale",
    observation_id = id, source_reference = source_reference("boc1.dat", "CPUE log-scale errors"),
    notes = "Native se_log values retained on the fitted lognormal-index scale.")
}
if (any(!is.finite(as.numeric(index_rows$obs))) ||
    any(!is.finite(as.numeric(index_rows$se_log))) || any(index_rows$se_log <= 0)) {
  stop("Invalid CPUE observations or log-scale errors.", call. = FALSE)
}

add_compositions <- function(x, component) {
  is_age <- component == "agecomp"
  bins <- if (is_age) as.integer(dat$agebin_vector) else as.integer(dat$lbin_vector)
  rows <- list()
  for (i in seq_len(nrow(x))) {
    source_sex <- as.integer(x$Sex[i])
    parts <- switch(as.character(source_sex),
      "0" = list(list(name = "combined", prefix = "f", add_male = TRUE)),
      "3" = list(list(name = "female", prefix = "f", add_male = FALSE),
                 list(name = "male", prefix = "m", add_male = FALSE)),
      stop("Unexpected composition sex code.", call. = FALSE))
    signed_fleet <- as.integer(x$FltSvy[i])
    fleet_id <- abs(signed_fleet)
    fleet_label <- fleet_names[fleet_id]
    fishery <- fleet_type[fleet_id] %in% c(1L, 2L)
    source_year <- as.integer(x$Yr[i])
    for (part in parts) {
      values <- as.numeric(x[i, paste0(part$prefix, bins), drop = TRUE])
      if (part$add_male) values <- values + as.numeric(x[i, paste0("m", bins), drop = TRUE])
      if (length(values) != length(bins) || any(!is.finite(values))) {
        stop("Invalid frequency vector in ", component, " row ", i, ".", call. = FALSE)
      }
      id <- paste0(component, ":", i, ":", part$name, ":yr:", source_year, ":fleet:", signed_fleet)
      notes <- paste0("Native Stock Synthesis frequency values preserved without normalization. ",
        if (is_age) "Conditional age-at-length composition." else "Length composition.",
        " Source sex code, sample size, partition, age-error code, length bounds, signed year and signed fleet are retained.",
        if (source_year < 0L) " Negative year marks evaluation-only data." else "",
        if (signed_fleet < 0L) " Negative fleet marks evaluation-only data." else "")
      rows[[length(rows) + 1L]] <- pacific_database_row("inputs", n = length(bins),
        assessment_id = assessment_id, type = if (is_age) "biology" else if (fishery) "catch" else "index",
        measure = if (is_age) "conditional_frequency_at_age" else "frequency_at_length",
        basis = "native_frequency", fleet = if (fishery) fleet_label else "",
        survey = if (fishery) "" else fleet_label, sex = part$name,
        region = region_name, season = "annual", year = abs(source_year),
        year_basis = "calendar_year", age = if (is_age) bins else NA_integer_,
        length_bin = if (is_age) NA_integer_ else bins,
        length_bin_lower = if (is_age) as.numeric(x$Lbin_lo[i]) else NA_real_,
        length_bin_upper = if (is_age) as.numeric(x$Lbin_hi[i]) else NA_real_,
        value = values, unit = "native frequency", sample_size = as.numeric(x$Nsamp[i]),
        age_error = if (is_age) as.integer(x$Ageerr[i]) else NA_integer_,
        partition = as.character(x$Part[i]), sampling_time = fleet_timing[fleet_id],
        observation_id = id, source_type = "native_model",
        source_reference = source_reference("boc1.dat", paste(component, "observations")),
        notes = notes)
    }
  }
  do.call(rbind, rows)
}
input_rows[[length(input_rows) + 1L]] <- add_compositions(dat$agecomp, "agecomp")
input_rows[[length(input_rows) + 1L]] <- add_compositions(dat$lencomp, "lencomp")
age_error_rows <- list()
for (definition in 1:2) {
  age_error_rows[[length(age_error_rows) + 1L]] <- pacific_database_row("inputs", n = 22L,
    assessment_id = assessment_id, type = "biology", measure = "age_error_mean_age",
    basis = "native_scale", age = 0:21, age_error = definition,
    value = as.numeric(dat$ageerror[2L * definition - 1L, ]), unit = "years",
    source_type = "native_model",
    source_reference = source_reference("boc1.dat", paste("age-error definition", definition)),
    notes = "Native mean observed age by true age, retained with the paired age-error SD.")
  age_error_rows[[length(age_error_rows) + 1L]] <- pacific_database_row("inputs", n = 22L,
    assessment_id = assessment_id, type = "biology", measure = "ageing_error_sd",
    basis = "age_error_sd", age = 0:21, age_error = definition,
    value = as.numeric(dat$ageerror[2L * definition, ]), unit = "years",
    source_type = "native_model",
    source_reference = source_reference("boc1.dat", paste("age-error definition", definition)),
    notes = "Native age-error SD by true age. Definition 1 is near-perfect; definition 2 is the double-read schedule.")
}
input_rows[[length(input_rows) + 1L]] <- do.call(rbind, age_error_rows)
inputs <- do.call(rbind, input_rows)

assumption_rows <- list()
add_assumption <- function(component, setting, value, reference, notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- pacific_database_row("assumptions",
    assessment_id = assessment_id, component = component, setting = setting,
    value = value, source_reference = reference, notes = notes)
}
add_assumption("population", "model_dimensions",
  "Annual Stock Synthesis 3.24U model; one area; two sexes; ages 0-21; input years 1892-2016; summary estimates through 2017",
  "boc1.dat; boc1.ctl; 2017 assessment report, Table 18",
  "The input has age bins 0-21 and one annual season. Table 18 includes a terminal 2017 summary row.")
catch_se <- as.numeric(dat$se_log_catch)
if (length(catch_se) != length(catch_fleets)) stop("Unexpected catch error vector.", call. = FALSE)
add_assumption("catch", "catch_input",
  paste0("Six fishery fleets; annual catch biomass in metric tons; ", length(unique(dat$catch$year)), " years per fleet"),
  "boc1.dat, catch block",
  "All six catch-unit codes are biomass. Zero values are retained. The separate se_log_catch values are not treated as observation SDs.")
add_assumption("catch", "se_log_catch",
  paste(paste0(catch_fleets, "=", format(catch_se, trim = TRUE), collapse = "; ")),
  "boc1.dat, catch error settings",
  "The native header says these settings are used for equilibrium-catch initialization and F methods 2/3.")
index_ids <- sort(unique(as.integer(dat$CPUE$index)))
unit_codes <- index_units[match(index_ids, index_fleets)]
add_assumption("index", "aggregate_index_series",
  paste0(length(index_ids), " CPUE series and ", nrow(dat$CPUE), " observations; units codes ",
    paste(sort(unique(unit_codes)), collapse = ", ")),
  "boc1.dat, CPUE and units blocks",
  "Unit code 0 is numbers, 1 is biomass, and 2 is fishing mortality. These are aggregate series; age compositions are imported separately.")
add_assumption("index", "fleet_timing",
  paste(paste0(fleet_names, "=", format(fleet_timing, trim = TRUE)), collapse = "; "),
  "boc1.dat, survey timing in season",
  "The single annual season uses fleet-specific within-year timing retained for indices and compositions.")
add_assumption("composition", "frequency_data",
  paste0(nrow(dat$agecomp), " conditional age-at-length rows; ", nrow(dat$lencomp),
    " length-composition rows; ages 0-21; length bins 10-76 cm at 2-cm increments"),
  "boc1.dat, CAAL and length-composition blocks",
  "The 2017 update carries forward 2015 age information. Native CAAL is not direct marginal catch-at-age; no age-specific index is reconstructed.")
add_assumption("composition", "age_error",
  "Two native age-error definitions",
  "boc1.dat, age-error definitions",
  "Definition 1 is near-perfect; definition 2 contains the double-read mean and SD schedules. Both are imported by true age.")
add_assumption("biology", "weight_maturity_fecundity",
  "Length-weight, maturity and fecundity relationships are carried forward from 2015; growth is estimated",
  "2017 assessment report, model description",
  "No standalone observed age-specific weight or maturity input surfaces were supplied.")
add_assumption("M", "natural_mortality",
  "Natural mortality is estimated with a lognormal prior; no age, year or sex variation",
  "2017 assessment report, model description; boc1.ctl",
  "No fitted report or parameter file is in the cached archive, so numeric M and its uncertainty are unavailable.")
add_assumption("output", "available_reported_outputs",
  "Table 18 reports annual summary biomass, spawning output, depletion, age-0 recruitment, total catch, SPR and relative exploitation; Table 5 gives 2007-2017 intervals for spawning output, recruitment and depletion",
  "2017 assessment report, Tables 5 and 18",
  "No fitted Report.sso, numeric N-at-age or F-at-age, or age-specific uncertainty was recovered. The 2025 catch-only projection is not mixed into the fitted 2017 run.")
assumptions <- do.call(rbind, assumption_rows)

pages <- pdftools::pdf_text(report_path)
if (length(pages) < 71L) stop("The cached report lacks the expected table pages.", call. = FALSE)
lines18 <- trimws(unlist(strsplit(paste(pages[60:63], collapse = "\n"), "\n")))
lines18 <- lines18[nzchar(lines18)]
rows18 <- lapply(lines18, function(line) {
  f <- strsplit(line, "[[:space:]]+")[[1]]
  if (length(f) < 5L || !grepl("^[0-9]{4}$", f[1])) return(NULL)
  year <- suppressWarnings(as.integer(f[1]))
  if (is.na(year) || year < 1892L || year > 2017L) return(NULL)
  value <- suppressWarnings(as.numeric(f[-1]))
  if (anyNA(value)) stop("Non-numeric Table 18 row: ", line, call. = FALSE)
  list(year = year, value = value)
})
rows18 <- Filter(Negate(is.null), rows18)
if (length(rows18) != 126L ||
    !identical(vapply(rows18, function(x) as.integer(x[["year"]]), integer(1)), 1892:2017) ||
    !all(vapply(rows18[1:125], function(x) length(x[["value"]]) == 7L, logical(1))) ||
    length(rows18[[126]][["value"]]) != 4L) stop("Table 18 coverage differs from review.", call. = FALSE)
table18 <- data.frame(
  year = vapply(rows18, function(x) as.integer(x[["year"]]), integer(1)),
  summary_biomass = vapply(rows18, function(x) x[["value"]][1], numeric(1)),
  spawning_output = vapply(rows18, function(x) x[["value"]][2], numeric(1)),
  depletion_percent = vapply(rows18, function(x) x[["value"]][3], numeric(1)),
  recruitment = vapply(rows18, function(x) x[["value"]][4], numeric(1)),
  catch = c(vapply(rows18[1:125], function(x) x[["value"]][5], numeric(1)), NA_real_),
  SPR = c(vapply(rows18[1:125], function(x) x[["value"]][6], numeric(1)), NA_real_),
  exploitation = c(vapply(rows18[1:125], function(x) x[["value"]][7], numeric(1)), NA_real_)
)
lines5 <- trimws(strsplit(pages[[17]], "\n")[[1]])
extract_series <- function(predicate, skip) {
  hit <- which(vapply(lines5, predicate, logical(1)))
  if (length(hit) != 1L) stop("Could not uniquely find a Table 5 series.", call. = FALSE)
  f <- strsplit(lines5[hit], "[[:space:]]+")[[1]]
  value <- suppressWarnings(as.numeric(f[seq.int(skip + 1L, length(f))]))
  if (length(value) != 11L || anyNA(value)) stop("Invalid Table 5 series.", call. = FALSE)
  value
}
years5 <- extract_series(function(x) startsWith(x, "Year "), 1L)
if (!identical(as.integer(years5), 2007:2017)) stop("Unexpected Table 5 years.", call. = FALSE)
table5 <- data.frame(
  year = as.integer(years5),
  ssb = extract_series(function(x) startsWith(x, "Spawning output (106"), 3L),
  ssb_lwr = extract_series(function(x) startsWith(x, "Spawning output (low"), 3L),
  ssb_upr = extract_series(function(x) startsWith(x, "Spawning output (high"), 3L),
  recruitment = extract_series(function(x) grepl("^Recruitment[[:space:]]+[0-9]", x), 1L),
  recruitment_lwr = extract_series(function(x) startsWith(x, "Recruitment (low"), 3L),
  recruitment_upr = extract_series(function(x) startsWith(x, "Recruitment (high"), 3L),
  depletion = extract_series(function(x) startsWith(x, "Depletion (%)"), 2L),
  depletion_lwr = extract_series(function(x) startsWith(x, "Depletion (low"), 3L),
  depletion_upr = extract_series(function(x) startsWith(x, "Depletion (high"), 3L)
)
match5 <- match(table5$year, table18$year)
if (anyNA(match5) || !identical(table5$ssb, table18$spawning_output[match5]) ||
    !identical(table5$recruitment, table18$recruitment[match5]) ||
    !identical(table5$depletion, table18$depletion_percent[match5])) {
  stop("Table 5 point estimates do not match Table 18.", call. = FALSE)
}

out_rows <- list()
add_output <- function(type, measure, year, value, unit, ref, notes = "",
                       source_type = "official_table", lwr = NA_real_, upr = NA_real_, age = NA_integer_) {
  out_rows[[length(out_rows) + 1L]] <<- pacific_database_row("outputs",
    assessment_id = assessment_id, type = type, measure = measure, year = year, age = age,
    value = value, lwr = lwr, upr = upr, unit = unit, source_type = source_type,
    source_reference = ref, notes = notes)
}
has_limits <- table18$year %in% table5$year
ssb_lwr <- rep(NA_real_, 126L); ssb_upr <- ssb_lwr
rec_lwr <- ssb_lwr; rec_upr <- ssb_lwr; dep_lwr <- ssb_lwr; dep_upr <- ssb_lwr
ssb_lwr[has_limits] <- table5$ssb_lwr; ssb_upr[has_limits] <- table5$ssb_upr
rec_lwr[has_limits] <- table5$recruitment_lwr; rec_upr[has_limits] <- table5$recruitment_upr
dep_lwr[has_limits] <- table5$depletion_lwr / 100; dep_upr[has_limits] <- table5$depletion_upr / 100
add_output("biomass", "summary_biomass", table18$year, table18$summary_biomass,
  "metric tons", "2017 assessment report, Table 18",
  "Table heading: Age 1+ biomass. Table 5 labels the overlapping 2007-2017 series Age 0+ biomass; the values match but the source labels differ.")
add_output("biomass", "spawning_output", table18$year, table18$spawning_output,
  "million larvae", "2017 assessment report, Table 18; 2007-2017 limits from Table 5",
  "Table 5 limits are the 2.5th and 97.5th percentiles.",
  lwr = ssb_lwr, upr = ssb_upr)
add_output("biomass", "SSB_ratio_to_B0", table18$year, table18$depletion_percent / 100,
  "proportion", "2017 assessment report, Table 18; 2007-2017 limits from Table 5",
  "Derived by dividing source depletion percentages by 100; depletion is relative to unfished spawning output.",
  source_type = "derived_source_output", lwr = dep_lwr, upr = dep_upr)
add_output("recruitment", "recruitment", table18$year, table18$recruitment,
  "thousand age-0 fish", "2017 assessment report, Table 18; 2007-2017 limits from Table 5",
  "Table 5 limits are the 2.5th and 97.5th percentiles.", age = 0L,
  lwr = rec_lwr, upr = rec_upr)
history <- !is.na(table18$catch)
add_output("catch", "catch_biomass", table18$year[history], table18$catch[history],
  "metric tons", "2017 assessment report, Table 18",
  "Published total catch across fisheries; native inputs retain each of the six catch fleets.")
add_output("diagnostic", "SPR", table18$year[history], table18$SPR[history],
  "percent", "2017 assessment report, Table 18", "Source-reported annual SPR percentage.")
add_output("mortality", "exploitation_rate", table18$year[history], table18$exploitation[history],
  "percent", "2017 assessment report, Table 18",
  "Source-reported relative exploitation rate percentage; retained on the report scale.")
outputs <- do.call(rbind, out_rows)

input_key <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "year", "age", "observation_id", "length_bin", "length_bin_lower", "length_bin_upper",
  "sample_size", "age_error", "partition")
row_key <- function(x, columns) do.call(paste, c(lapply(x[columns], function(z) {
  z <- as.character(z); z[is.na(z)] <- ""
  z
}), sep = "\r"))
if (nrow(inputs) != 54326L || nrow(assumptions) != 10L || nrow(outputs) != 879L ||
    any(!is.finite(inputs$value)) || any(!is.finite(outputs$value)) ||
    anyDuplicated(row_key(inputs, input_key)) ||
    anyDuplicated(row_key(outputs, c("assessment_id", "type", "measure", "year", "age", "scenario"))) ||
    sum(inputs$measure == "conditional_frequency_at_age") != 37928L ||
    sum(inputs$measure == "frequency_at_length") != 15096L ||
    sum(inputs$measure == "catch_biomass") != 750L ||
    sum(inputs$measure %in% c("relative_abundance_index", "relative_biomass_index")) != 232L ||
    sum(inputs$measure == "log_index_sd") != 232L) {
  stop("Bocaccio rows differ from reviewed coverage or contain duplicate keys.", call. = FALSE)
}

stock <- pacific_database_row("stocks", stock_id = stock_id, charbonneau_id = "",
  authority = "NOAA-SWFSC", authority_stock_id = "10413",
  scientific_name = "Sebastes paucispinis", common_name = "Bocaccio - Southern Pacific Coast",
  area = "Conception, Monterey and Eureka INPFC areas; south of 43 degrees N to the U.S.-Mexico border",
  region = "Oregon and California", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART ID 10413. This Southern Pacific Coast unit is separate from British Columbia and northern U.S. bocaccio units. The 2026 coastwide stock-definition proposal was not implemented at review.")
assessment <- pacific_database_row("assessments", assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2017L, terminal_year = 2016L, estimate_terminal_year = 2017L,
  assessment_type = "update_assessment", model_family = "Stock Synthesis", model_version = "3.24U",
  is_current = TRUE, is_applied = TRUE, assessment_url = report_url,
  data_url = model_url, model_url = model_url, repository_url = model_url,
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Latest detailed fitted assessment for the current NOAA Southern Pacific Coast unit. The 2017 update uses data through 2016 and carries forward age information from 2015. Native catch, aggregate indices, length frequencies, conditional age-at-length frequencies, age-error definitions and assumptions are imported. The report supplies aggregate trajectories and recent intervals, but the archive has no fitted Report.sso or parameter file and published numerical N-at-age and F-at-age were not found. The 2025 catch-only projection is kept separate.", projection_url))

candidate_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
batch_path <- file.path(root, "discovery/selected_batch_30_2026.csv")
unworked_path <- file.path(root, "discovery/selected_unworked_2026.csv")
candidates <- read.csv(candidate_path, colClasses = "character", check.names = FALSE)
inventory <- read.csv(inventory_path, colClasses = "character", check.names = FALSE)
batch <- read.csv(batch_path, colClasses = "character", check.names = FALSE)
ci <- which(candidates$candidate_id == candidate_id)
ii <- which(inventory$candidate_unit_id == candidate_unit_id)
bi <- which(batch$candidate_id == candidate_id)
if (length(ci) != 1L || length(ii) != 1L || length(bi) != 1L ||
    candidates$import_status[ci] != "not_started" || inventory$import_status[ii] != "not_started" ||
    batch$curation_status[bi] != "selected_for_source_curation") stop("Bocaccio register status changed.", call. = FALSE)
stocks <- read.csv(file.path(root, "database/stocks.csv"), colClasses = "character", check.names = FALSE)
assessments <- read.csv(file.path(root, "database/assessments.csv"), colClasses = "character", check.names = FALSE)
if (stock_id %in% stocks$stock_id || assessment_id %in% assessments$assessment_id ||
    "10413" %in% stocks$authority_stock_id) stop("Bocaccio stock or assessment already exists.", call. = FALSE)

cat("Verified NOAA Bocaccio 2017 source import.\n")
cat("Inputs:", nrow(inputs), "; assumptions:", nrow(assumptions), "; outputs:", nrow(outputs), "\n")
cat("Inputs include native catches, aggregate indices and SDs, conditional age-at-length, length frequencies, and age-error definitions.\n")
cat("Outputs are aggregate Tables 18/5 trajectories and limits; no N-at-age or F-at-age is fabricated.\n")
if (!write_mode) {
  cat("Dry run only. Add --write to append the reviewed records and update the candidate registers.\n")
} else {
  append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  candidate <- candidates[ci, , drop = FALSE]
  candidate$matched_stock_id <- stock_id
  candidate$match_status <- "matched"
  candidate$import_status <- "partial"
  candidate$catch_age_evidence <- "Imported 750 annual fleet catch-biomass rows. The source contains native catch biomass, not observed catch-at-age; no catch-at-age reconstruction was added."
  candidate$survey_age_evidence <- "Imported all 232 aggregate index observations and log-scale errors, plus conditional age-at-length compositions. No age-specific abundance index is supplied."
  candidate$weights_evidence <- "Length-weight relationships are carried forward from the 2015 assessment; no standalone observed age-specific weights were available in the 2017 archive."
  candidate$maturity_evidence <- "Maturity and fecundity relationships are carried forward from 2015; no independent maturity-at-age input surface was supplied."
  candidate$mortality_evidence <- "Natural mortality is estimated with a lognormal prior and has no age, year or sex variation; fitted numeric M output was unavailable."
  candidate$timing_evidence <- "Native fleet-specific within-year timing is preserved for index and composition observations."
  candidate$output_evidence <- "Imported annual summary biomass, spawning output, depletion, recruitment, total catch, SPR and relative exploitation. Table 5 provides 2007-2017 intervals for spawning output, recruitment and depletion; numeric N-at-age and F-at-age were not recovered."
  candidate$detailed_source_url <- paste(report_url, model_url, projection_url,
    "https://www.fisheries.noaa.gov/species/bocaccio",
    "https://www.fisheries.noaa.gov/action/amendment-37-pacific-coast-groundfish-fishery-management-plan-stock-definitions", sep = "; ")
  candidate$review_date <- "2026-11-11"
  candidate$decision_reason <- "The 2017 update is the latest detailed fit for the current Southern Pacific Coast unit; the 2025 document is a catch-only projection, not a refit."
  candidate$notes <- "Partial source import. Native catches, aggregate indices, CAAL and length frequencies, age-error definitions, assumptions and published aggregate outputs are imported. Direct catch-at-age, age-specific indices, standalone age-scale biology, fitted N/F surfaces and age-specific uncertainty remain unavailable."
  replace_candidate_register_row(candidate_path, ci, candidate, candidate_id)
  inv <- inventory[ii, , drop = FALSE]
  inv$matched_stock_id <- stock_id
  inv$match_status <- "matched"
  inv$import_status <- "partial"
  replace_csv_register_row(inventory_path, ii, inv, "unit_key", inventory$unit_key[ii])
  batch$curation_status[bi] <- "partial_source_import"
  write.csv(batch, batch_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  unworked_path <- file.path(root, "discovery/selected_unworked_2026.csv")
  if (file.exists(unworked_path)) {
    unworked <- read.csv(unworked_path, colClasses = "character", check.names = FALSE)
    ui <- which(unworked$candidate_id == candidate_id)
    if (length(ui) == 1L) {
      unworked$curation_status[ui] <- "source_curated_partial"
      write.csv(unworked, unworked_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
    }
  }
  source(file.path(root, "scripts/database/002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("Bocaccio rows appended and database validation passed.\n")
}









