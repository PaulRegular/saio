root <- "."
stock_id <- "noaa_spiny_dogfish_pacific_coast"
assessment_id <- "noaa_spiny_dogfish_pacific_coast_2021"
candidate_id <- "NOAA:10702"
candidate_unit_id <- "noaa_spiny_dogfish_pacific_coast_2021"
cache <- file.path(root, "source_cache", "discovery_noaa_spiny_dogfish_pacific_2021")
manifest_path <- file.path(root, "provenance", assessment_id, "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to parse the cached dogfish assessment.", call. = FALSE)
}
manifest <- read.csv(manifest_path, colClasses = "character", stringsAsFactors = FALSE)
verify_source <- function(file) {
  path <- file.path(cache, file)
  i <- which(manifest$source == file)
  if (length(i) != 1L || !file.exists(path) ||
    file.info(path)$size != as.numeric(manifest$bytes[i]) ||
    tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[i])) {
    stop("Source does not match manifest: ", file, call. = FALSE)
  }
  path
}
report_path <- verify_source("spiny_dogfish_2021_assessment.pdf")
model_zip <- verify_source("spiny_dogfish_2021_model_files.zip")
verify_source("spiny_dogfish_2021_supplementary_tables.xlsx")
verify_source("spiny_dogfish_2021_star_panel.pdf")
work <- tempfile("dogfish_2021_")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)
unzip(model_zip, exdir = work)
data_files <- list.files(work, "^data\\.ss_new$", recursive = TRUE, full.names = TRUE)
if (length(data_files) != 1L) stop("Expected one data.ss_new in the official archive.", call. = FALSE)
model_dir <- dirname(data_files)
for (file in c("control.ss_new", "Report.sso", "wtatage.ss_new", "ss.par", "ss.cor", "covar.sso")) {
  if (!file.exists(file.path(model_dir, file))) stop("Official archive lacks ", file, call. = FALSE)
}
control_header <- readLines(file.path(model_dir, "control.ss_new"), n = 1L, warn = FALSE)
if (!any(grepl("3\\.30\\.16", control_header))) stop("Stock Synthesis version differs from 3.30.16.", call. = FALSE)
dat <- r4ss::SS_readdat(data_files, verbose = FALSE)
out <- r4ss::SS_output(model_dir, printstats = FALSE, verbose = FALSE, warn = FALSE)
pdf_pages <- pdftools::pdf_text(report_path)
if (dat$styr != 1916L || dat$endyr != 2020L || dat$nseas != 1L ||
  dat$Nages != 95L || dat$Nsexes != 2L || dat$N_areas != 1L || dat$Nfleets != 13L ||
  nrow(dat$catch) != 848L || nrow(dat$CPUE) != 55L || nrow(dat$lencomp) != 156L ||
  nrow(dat$agecomp) != 33L || !identical(as.integer(dat$agebin_vector), 0:71) ||
  sum(dat$catch$year == -999L) != 8L || !all(dat$fleetinfo$units[1:8] == 1L) ||
  !setequal(as.integer(dat$CPUEinfo$units), c(0L, 1L)) ||
  !all(dat$CPUE$month == 7L) || any(dat$CPUE$se_log <= 0) ||
  !setequal(as.integer(dat$agecomp$year), 2010L) || sum(dat$agecomp$Nsamp) != 515L) {
  stop("Dogfish native model input dimensions differ from the pinned assessment.", call. = FALSE)
}
if (!all(dat$catch$year[dat$catch$year != -999L] %in% 1916:2020) ||
  !setequal(unique(as.integer(dat$catch$fleet[dat$catch$year != -999L])), 1:8) ||
  !setequal(unique(as.integer(dat$CPUE$index)), 9:13) ||
  !all(dat$lencomp$year %in% 1980:2020) ||
  !setequal(unique(as.integer(dat$agecomp$sex)), c(1L, 2L))) {
  stop("Dogfish native catch, index or composition coverage differs from source review.", call. = FALSE)
}
fleet_name <- function(id) {
  id <- abs(as.integer(id))
  if (any(id < 1L | id > nrow(dat$fleetinfo))) stop("Unexpected source fleet code.", call. = FALSE)
  as.character(dat$fleetinfo$fleetname[id])
}
fleet_type <- function(id) {
  id <- abs(as.integer(id))
  if (any(id < 1L | id > nrow(dat$fleetinfo))) stop("Unexpected source fleet code.", call. = FALSE)
  as.integer(dat$fleetinfo$type[id])
}
fleet_fields <- function(id) {
  type <- fleet_type(id)
  list(fleet = ifelse(type == 1L, fleet_name(id), ""),
    survey = ifelse(type == 3L, fleet_name(id), ""))
}
partition_name <- function(code) c("combined", "discard", "retained")[as.integer(code) + 1L]
region_name <- "U.S. Pacific Coast"
frame_input <- function(type, measure, basis, value, unit, fleet = "", survey = "", sex = "",
  region = region_name, season = "", year = NA_integer_, age = NA_integer_,
  sampling_time = NA_real_, source_type = "native_model", source_reference,
  transformation = "", notes = "", observation_id = "", length_bin = NA_real_,
  length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
  age_error = NA_real_, partition = "", weight_bin = NA_real_) {
  args <- list(type, measure, basis, value, unit, fleet, survey, sex, region, season, year,
    age, sampling_time, source_type, source_reference, transformation, notes, observation_id,
    length_bin, length_bin_lower, length_bin_upper, sample_size, age_error, partition, weight_bin)
  n <- max(lengths(args))
  repn <- function(x) rep_len(x, n)
  year_value <- as.numeric(repn(year))
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure),
    basis = repn(basis), fleet = repn(fleet), survey = repn(survey), sex = repn(sex),
    region = repn(region), season = repn(season), year = as.integer(year_value),
    year_basis = ifelse(is.na(year_value), "", "calendar_year"), age = as.numeric(repn(age)),
    value = as.numeric(repn(value)), unit = repn(unit), sampling_time = as.numeric(repn(sampling_time)),
    source_type = repn(source_type), source_reference = repn(source_reference),
    transformation = repn(transformation), notes = repn(notes), observation_id = repn(observation_id),
    length_bin = as.numeric(repn(length_bin)), length_bin_lower = as.numeric(repn(length_bin_lower)),
    length_bin_upper = as.numeric(repn(length_bin_upper)), sample_size = as.numeric(repn(sample_size)),
    age_error = as.numeric(repn(age_error)), partition = repn(partition),
    weight_bin = as.numeric(repn(weight_bin)), stringsAsFactors = FALSE)
}
valid_catch <- dat$catch$year != -999L
catch_year <- as.integer(dat$catch$year[valid_catch])
catch_fleet_id <- as.integer(dat$catch$fleet[valid_catch])
catch_fields <- fleet_fields(catch_fleet_id)
catch_id <- paste0("DOG_CATCH_F", catch_fleet_id, "_", catch_year)
catch_rows <- frame_input("catch", "catch_biomass", "biomass", dat$catch$catch[valid_catch],
  "metric tonnes", fleet = catch_fields$fleet, region = region_name, season = "annual",
  year = catch_year, source_reference = "data.ss_new catch block",
  notes = "Native annual fishery catch biomass; eight -999 placeholders are not calendar observations and are excluded.",
  observation_id = catch_id)
catch_sd <- frame_input("catch", "log_catch_sd", "log_scale", dat$catch$catch_se[valid_catch],
  "log-scale SD", fleet = catch_fields$fleet, region = region_name, season = "annual",
  year = catch_year, source_reference = "data.ss_new catch block, catch_se",
  notes = "Native standard error on log catch scale.", observation_id = catch_id)
index_id <- as.integer(dat$CPUE$index)
index_year <- as.integer(dat$CPUE$year)
index_month <- as.integer(dat$CPUE$month)
cpue_info <- dat$CPUEinfo[match(index_id, as.integer(dat$CPUEinfo$fleet)), , drop = FALSE]
if (anyNA(cpue_info$units)) stop("A CPUE fleet has no CPUEinfo unit code.", call. = FALSE)
index_fields <- fleet_fields(index_id)
index_measure <- ifelse(cpue_info$units == 0L, "relative_abundance_index", "relative_biomass_index")
index_unit <- ifelse(cpue_info$units == 0L,
  "native relative abundance-index scale (Stock Synthesis unit code 0)",
  "native relative biomass-index scale (Stock Synthesis unit code 1)")
index_time <- (index_month - 1) / 12
index_obs <- paste0("DOG_INDEX_F", index_id, "_", index_year, "_m", index_month)
index_rows <- frame_input("index", index_measure, "index_scale", dat$CPUE$obs, index_unit,
  fleet = index_fields$fleet, survey = index_fields$survey, region = region_name,
  season = paste0("model month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "data.ss_new CPUE and CPUEinfo blocks",
  notes = paste0("Native relative index from ", fleet_name(index_id),
    "; unit code selects a numbers or biomass prediction, and fitted catchability means the value is not absolute abundance."),
  observation_id = index_obs)
index_sd <- frame_input("index", "log_index_sd", "log_scale", dat$CPUE$se_log, "log-scale SD",
  fleet = index_fields$fleet, survey = index_fields$survey, region = region_name,
  season = paste0("model month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "data.ss_new CPUE block, se_log",
  notes = "Native log-scale observation SD; the model assigns all observations to July (within-year time 0.5).",
  observation_id = index_obs)
make_composition <- function(x, kind) {
  if (kind == "length") {
    bins <- as.numeric(dat$lbin_vector); cols_f <- paste0("f", bins); cols_m <- paste0("m", bins)
    measure <- "frequency_at_length"; table_ref <- "data.ss_new length-composition block"
  } else {
    bins <- as.numeric(dat$agebin_vector); cols_f <- paste0("f", bins); cols_m <- paste0("m", bins)
    measure <- "conditional_frequency_at_age"; table_ref <- "data.ss_new conditional age-at-length block"
  }
  result <- vector("list", nrow(x) * 2L); cursor <- 0L
  for (i in seq_len(nrow(x))) {
    source_sex <- as.integer(x$sex[i])
    if (!source_sex %in% 0:3) stop("Unexpected composition sex code.", call. = FALSE)
    source_fleet <- as.integer(x$fleet[i]); fields <- fleet_fields(source_fleet)
    source_year <- as.integer(x$year[i]); month <- as.integer(x$month[i]); part <- as.integer(x$part[i])
    age_error <- if (kind == "age") as.integer(x$ageerr[i]) else NA_integer_
    state <- if (source_fleet < 0L) "negative fleet: ghost composition excluded from likelihood" else "active source composition"
    id <- paste0("DOG_", ifelse(kind == "length", "LEN", "CAAL"), "_F", abs(source_fleet),
      "_", abs(source_year), "_m", month, "_p", part, "_s", source_sex, "_r", sprintf("%04d", i))
    if (source_sex == 0L) {
      vector_sex <- c("combined", "male"); ignored <- c(FALSE, TRUE)
    } else if (source_sex == 1L) {
      vector_sex <- c("female", "male"); ignored <- c(FALSE, TRUE)
    } else if (source_sex == 2L) {
      vector_sex <- c("female", "male"); ignored <- c(TRUE, FALSE)
    } else {
      vector_sex <- c("female", "male"); ignored <- c(FALSE, FALSE)
    }
    vectors <- list(as.numeric(x[i, cols_f, drop = TRUE]), as.numeric(x[i, cols_m, drop = TRUE]))
    for (j in 1:2) {
      cursor <- cursor + 1L
      source_note <- if (source_sex == 3L) {
        "Source sex code 3 fits female and male vectors jointly; both share one observation ID."
      } else if (source_sex == 0L) {
        "Source sex code 0 uses a combined-sex female vector; the male vector is ignored."
      } else if (source_sex == 1L) {
        "Source sex code 1 fits the female vector only; the male vector is ignored."
      } else if (source_sex == 2L) {
        "Source sex code 2 fits the male vector only; the female vector is ignored."
      } else {
        ""
      }
      ignored_note <- if (ignored[j]) "Retained source vector; not fitted by the likelihood." else ""
      note <- paste(source_note, state, ignored_note,
        if (!is.na(age_error) && age_error > 0L) paste("Age-error code", age_error, ".") else "")
      result[[cursor]] <- frame_input(
        type = if (kind == "age") "biology" else ifelse(fields$fleet != "", "catch", "index"),
        measure = measure, basis = "native_frequency", value = vectors[[j]],
        unit = "native composition frequency units", fleet = fields$fleet, survey = fields$survey,
        sex = vector_sex[j], region = region_name, season = paste0("month ", month),
        year = abs(source_year), sampling_time = (month - 1) / 12,
        source_reference = paste0(table_ref, ", source row ", i),
        transformation = if (kind == "age") "Retain native conditional age-at-length vector; not marginal catch-at-age." else "Retain native length-frequency vector.",
        notes = note, observation_id = id,
        age = if (kind == "age") bins else NA_integer_,
        length_bin = if (kind == "length") bins else NA_real_,
        length_bin_lower = if (kind == "age") as.numeric(x$Lbin_lo[i]) else NA_real_,
        length_bin_upper = if (kind == "age") as.numeric(x$Lbin_hi[i]) else NA_real_,
        sample_size = as.numeric(x$Nsamp[i]), age_error = age_error,
        partition = partition_name(part))
    }
  }
  do.call(rbind, result[seq_len(cursor)])
}
length_rows <- make_composition(dat$lencomp, "length")
age_rows <- make_composition(dat$agecomp, "age")
inputs_new <- do.call(rbind, list(catch_rows, catch_sd, index_rows, index_sd, length_rows, age_rows))

frame_output <- function(type, measure, year = NA_integer_, value, unit, age = NA_integer_,
  age_group = "", fleet = "", survey = "", sex = "", region = region_name, season = "annual",
  se = NA_real_, lwr = NA_real_, upr = NA_real_, source_type = "native_model",
  source_reference, notes = "", scenario = "") {
  args <- list(type, measure, year, value, unit, age, age_group, fleet, survey, sex,
    region, season, se, lwr, upr, source_type, source_reference, notes, scenario)
  n <- max(lengths(args)); repn <- function(x) rep_len(x, n)
  data.frame(assessment_id = rep(assessment_id, n), type = repn(type), measure = repn(measure),
    fleet = repn(fleet), survey = repn(survey), sex = repn(sex), region = repn(region),
    season = repn(season), year = as.integer(repn(year)), age = as.numeric(repn(age)),
    age_group = repn(age_group), value = as.numeric(repn(value)), se = as.numeric(repn(se)),
    lwr = as.numeric(repn(lwr)), upr = as.numeric(repn(upr)), unit = repn(unit),
    source_type = repn(source_type), source_reference = repn(source_reference),
    notes = repn(notes), scenario = repn(scenario), stringsAsFactors = FALSE)
}
ages <- 0:95
age_cols <- as.character(ages)
years <- 1916:2021
forecast_scenario <- ifelse(years == 2021L, "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43")
surface_rows <- function(x, type, measure, unit, reference, notes, fleet_column = NULL) {
  if (nrow(x) == 0L || !all(age_cols %in% names(x))) stop("Report.sso surface lacks expected ages.", call. = FALSE)
  frame_output(type, measure, rep(as.integer(x$Yr), each = length(ages)),
    as.vector(t(as.matrix(x[, age_cols, drop = FALSE]))), unit,
    age = rep(ages, times = nrow(x)),
    fleet = if (is.null(fleet_column)) "" else rep(fleet_name(x[[fleet_column]]), each = length(ages)),
    sex = rep(ifelse(as.integer(x$Sex) == 1L, "female", "male"), each = length(ages)),
    season = "annual", source_reference = reference, notes = notes,
    scenario = ifelse(rep(as.integer(x$Yr), each = length(ages)) == 2021L,
      "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43"))
}
n_surface <- out$natage[out$natage$Era %in% c("TIME", "FORE") &
  out$natage[["Beg/Mid"]] == "B" & out$natage$Yr %in% years, , drop = FALSE]
b_surface <- out$batage[out$batage$Era %in% c("TIME", "FORE") &
  out$batage[["Beg/Mid"]] == "B" & out$batage$Yr %in% years, , drop = FALSE]
fishery_fleets <- 1:8
f_surface <- out$fatage[out$fatage$Era %in% c("TIME", "FORE") &
  out$fatage$Yr %in% years & out$fatage$Fleet %in% fishery_fleets, , drop = FALSE]
if (nrow(n_surface) != length(years) * 2L || nrow(b_surface) != length(years) * 2L ||
  nrow(f_surface) != length(years) * 2L * length(fishery_fleets) ||
  !all(age_cols %in% names(n_surface)) || !all(age_cols %in% names(b_surface)) ||
  !all(age_cols %in% names(f_surface))) {
  stop("Dogfish Report.sso age-surface dimensions differ from expected years or sexes.", call. = FALSE)
}
N_rows <- surface_rows(n_surface, "population", "numbers_at_age", "thousand fish",
  "Report.sso TIME/FORE beginning-year N-at-age", "Beginning-year abundance; age 95 is the plus group.")
B_rows <- surface_rows(b_surface, "biomass", "biomass_at_age", "metric tonnes",
  "Report.sso TIME/FORE beginning-year biomass-at-age", "Beginning-year biomass; age 95 is the plus group.")
F_fleet_rows <- surface_rows(f_surface, "mortality", "fishing_mortality_at_age", "per year",
  "Report.sso TIME/FORE fleet-specific fishing mortality-at-age",
  "Annual fleet-specific fishing mortality; age 95 is the plus group.", "Fleet")
F_total <- do.call(rbind, lapply(years, function(year) {
  z <- f_surface[f_surface$Yr == year, , drop = FALSE]
  do.call(rbind, lapply(1:2, function(sex_code) {
    sz <- z[z$Sex == sex_code, , drop = FALSE]
    if (nrow(sz) != length(fishery_fleets)) stop("Missing fishery F rows in year ", year, call. = FALSE)
    values <- as.list(colSums(sz[, age_cols, drop = FALSE]))
    row <- data.frame(year = year, Sex = sex_code, values, check.names = FALSE)
    row[, c("year", "Sex", age_cols), drop = FALSE]
  }))
}))
F_total_rows <- frame_output("mortality", "fishing_mortality_at_age",
  rep(F_total$year, each = length(ages)),
  as.vector(t(as.matrix(F_total[, age_cols, drop = FALSE]))), "per year",
  age = rep(ages, times = nrow(F_total)),
  sex = rep(ifelse(F_total$Sex == 1L, "female", "male"), each = length(ages)),
  source_type = "derived_source_output",
  source_reference = "Derived from Report.sso fleet-specific fishing mortality-at-age",
  notes = "Total fishery F-at-age sums the eight source fishery fleets; age 95 is the plus group.",
  scenario = ifelse(rep(F_total$year, each = length(ages)) == 2021L,
    "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43"))
M_surface <- out$M_at_age[out$M_at_age$Yr %in% years, , drop = FALSE]
if (nrow(M_surface) != length(years) * 2L || !all(age_cols %in% names(M_surface)) ||
  any(!is.finite(as.matrix(M_surface[, as.character(0:94), drop = FALSE]))) ||
  !all(is.na(M_surface[["95"]]))) {
  stop("Report.sso fixed-M surface differs from the expected ages or terminal-age convention.", call. = FALSE)
}
M_surface[["95"]] <- 0.065
M_rows <- surface_rows(M_surface, "mortality", "natural_mortality_at_age", "per year",
  "Report.sso M_at_age ages 0-94; control.ss_new NatM_type=0 for age 95",
  "Fixed uniform natural mortality is 0.065 per year for both sexes and all ages. Report.sso leaves the terminal age-95 plus-group cell blank; it is expanded from the fixed uniform-M setting.")
terminal_m <- M_rows$age == 95L
M_rows$source_type[terminal_m] <- "derived_source_output"
wt <- out$wtatage
wt$year <- as.integer(wt$year); wt$sex <- as.integer(wt$sex); wt$fleet <- as.integer(wt$fleet)
wt <- wt[wt$year %in% years & wt$seas == 1L, , drop = FALSE]
wt_pop <- wt[wt$fleet == 0L, , drop = FALSE]
matfec <- wt[wt$fleet == -2L & wt$sex == 1L, , drop = FALSE]
fec <- wt[wt$fleet == -1L & wt$sex == 1L, , drop = FALSE]
if (nrow(wt_pop) != length(years) * 2L || nrow(matfec) != length(years) ||
  nrow(fec) != length(years) || !all(age_cols %in% names(wt_pop))) {
  stop("wtatage.ss_new lacks expected population and female biological surfaces.", call. = FALSE)
}
W_rows <- frame_output("biology", "weight_at_age",
  rep(wt_pop$year, each = length(ages)),
  as.vector(t(as.matrix(wt_pop[, age_cols, drop = FALSE]))), "kg per fish",
  age = rep(ages, times = nrow(wt_pop)),
  sex = rep(ifelse(wt_pop$sex == 1L, "female", "male"), each = length(ages)),
  source_type = "derived_source_output",
  source_reference = "wtatage.ss_new fleet 0 beginning-season population weight",
  notes = "Model-generated body weight-at-age; age 95 is the plus group.",
  scenario = ifelse(rep(wt_pop$year, each = length(ages)) == 2021L,
    "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43"))
matfec <- matfec[match(years, matfec$year), , drop = FALSE]
fec <- fec[match(years, fec$year), , drop = FALSE]
if (anyNA(matfec$year) || anyNA(fec$year)) stop("Female fecundity surfaces do not align by year.", call. = FALSE)
maturity <- as.matrix(matfec[, age_cols, drop = FALSE]) / as.matrix(fec[, age_cols, drop = FALSE])
if (any(!is.finite(maturity)) || any(maturity < 0 | maturity > 1)) stop("Derived maturity-at-age falls outside [0,1].", call. = FALSE)
Mat_rows <- frame_output("biology", "maturity_at_age", rep(years, each = length(ages)),
  as.vector(t(maturity)), "proportion", age = rep(ages, times = length(years)), sex = "female",
  source_type = "derived_source_output",
  source_reference = "wtatage.ss_new fleet -2 maturity*fecundity divided by fleet -1 fecundity",
  notes = "Derived from the official model's annual maturity*fecundity and fecundity surfaces; age 95 is the plus group.",
  scenario = ifelse(rep(years, each = length(ages)) == 2021L,
    "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43"))
report_rows <- function(title, years, expected_fields) {
  pages <- which(vapply(pdf_pages, function(page) grepl(title, page, fixed = TRUE), logical(1)))
  if (length(pages) != 1L) stop("Could not uniquely locate report table: ", title, call. = FALSE)
  lines <- strsplit(pdf_pages[[pages]], "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^\\s*20(1[1-9]|2[01])\\s+", lines, perl = TRUE)]
  parsed <- lapply(lines, function(line) {
    token <- regmatches(line, gregexpr("(?<![[:alpha:]])[-+]?[0-9][0-9,]*(?:\\.[0-9]+)?(?![[:alpha:]])",
      line, perl = TRUE))[[1L]]
    as.numeric(gsub(",", "", token, fixed = TRUE))
  })
  parsed <- Filter(function(row) length(row) == expected_fields, parsed)
  if (!length(parsed)) stop("Could not parse rows from ", title, call. = FALSE)
  values <- as.data.frame(do.call(rbind, parsed))
  values <- values[values[[1L]] %in% years, , drop = FALSE]
  values <- values[order(values[[1L]]), , drop = FALSE]
  if (!identical(as.integer(values[[1L]]), as.integer(years))) stop("Report table coverage differs for ", title, call. = FALSE)
  values
}
report <- report_rows("Table ES-2. Recent trend in estimated spiny dogfish spawning output", 2011:2021, 10L)
names(report) <- c("year", "spawning_output", "ssb_lwr", "ssb_upr", "recruitment",
  "rec_lwr", "rec_upr", "relative_spawning_output", "relative_lwr", "relative_upr")
report$year <- as.integer(report$year)
ts <- out$timeseries[out$timeseries$Era %in% c("TIME", "FORE") & out$timeseries$Yr %in% years, , drop = FALSE]
if (nrow(ts) != length(years)) stop("Report.sso time series does not cover 1916-2021.", call. = FALSE)
ssb_derived <- out$derived_quants[match(paste0("SSB_", years), out$derived_quants$Label), , drop = FALSE]
rec_derived <- out$derived_quants[match(paste0("Recr_", years), out$derived_quants$Label), , drop = FALSE]
if (anyNA(ssb_derived$Value) || anyNA(rec_derived$Value)) stop("Annual spawning output or recruitment estimates are missing.", call. = FALSE)
report_rows_match <- match(report$year, ts$Yr)
if (anyNA(report_rows_match) ||
  max(abs(ts$SpawnBio[report_rows_match] - report$spawning_output)) > 0.6 ||
  max(abs(ts$Recruit_0[report_rows_match] - report$recruitment)) > 0.6) {
  stop("Archived run does not match report Table ES-2 estimates within rounding.", call. = FALSE)
}
scenario_by_year <- ifelse(ts$Yr == 2021L, "one-year forecast; WCGBTS q=0.43", "WCGBTS q=0.43")
report_match <- match(ts$Yr, report$year)
has_report <- !is.na(report_match)
ssb_lwr <- ssb_upr <- rec_lwr <- rec_upr <- rep(NA_real_, nrow(ts))
ssb_lwr[has_report] <- report$ssb_lwr[report_match[has_report]]
ssb_upr[has_report] <- report$ssb_upr[report_match[has_report]]
rec_lwr[has_report] <- report$rec_lwr[report_match[has_report]]
rec_upr[has_report] <- report$rec_upr[report_match[has_report]]
SSB_rows <- frame_output("population", "spawning_output", ts$Yr, ts$SpawnBio,
  "thousand pups", se = ssb_derived$StdDev, lwr = ssb_lwr, upr = ssb_upr,
  source_type = ifelse(has_report, "official_table", "native_model"),
  source_reference = ifelse(has_report, "Report.sso derived quantities; assessment report Table ES-2",
    "Report.sso TIME/FORE SpawnBio and covariance-derived quantities"),
  notes = ifelse(has_report,
    "Spawning output is a pup-count metric, not spawning biomass; SE comes from fitted covariance output and interval from Table ES-2.",
    "Native annual spawning output in thousand pups; SE from fitted covariance output."),
  scenario = scenario_by_year)
Recruit_rows <- frame_output("recruitment", "recruitment", ts$Yr, ts$Recruit_0,
  "thousand pups", age = 0L, se = rec_derived$StdDev, lwr = rec_lwr, upr = rec_upr,
  source_type = ifelse(has_report, "official_table", "native_model"),
  source_reference = ifelse(has_report, "Report.sso derived quantities; assessment report Table ES-2",
    "Report.sso TIME/FORE Recruit_0 and covariance-derived quantities"),
  notes = ifelse(has_report,
    "Age-0 recruitment is reported in thousand pups; SE comes from fitted covariance output and interval from Table ES-2.",
    "Native annual age-0 recruitment in thousand pups; SE from fitted covariance output."),
  scenario = scenario_by_year)
Bio_all_rows <- frame_output("biomass", "total_biomass", ts$Yr, ts$Bio_all,
  "metric tonnes", age_group = "all ages", source_type = "native_model",
  source_reference = "Report.sso TIME/FORE Bio_all",
  notes = "Total biomass across model ages and sexes; age-95 is the plus group.",
  scenario = scenario_by_year)
Bio_1plus_rows <- frame_output("biomass", "biomass_by_age_group", ts$Yr, ts$Bio_smry,
  "metric tonnes", age_group = "1+", source_type = "native_model",
  source_reference = "Report.sso TIME/FORE Bio_smry",
  notes = "Native model summary biomass for ages 1+; this matches report Table ES-8 through 2020.",
  scenario = scenario_by_year)
bio_table_line <- vapply(pdf_pages, function(page) {
  lines <- strsplit(page, "\n", fixed = TRUE)[[1L]]
  rows <- lines[grepl("^\\s*Age 1\\+ Biomass", lines, perl = TRUE)]
  if (length(rows) == 1L) rows else NA_character_
}, character(1))
bio_table_line <- bio_table_line[!is.na(bio_table_line)]
if (length(bio_table_line) != 1L) stop("Could not uniquely locate the report's age-1+ biomass row.", call. = FALSE)
bio_tokens <- regmatches(bio_table_line, gregexpr("(?<![[:alpha:]])[-+]?[0-9][0-9,]*(?:\\.[0-9]+)?(?![[:alpha:]])",
  bio_table_line, perl = TRUE))[[1L]]
bio_values <- as.numeric(gsub(",", "", bio_tokens, fixed = TRUE))
bio_values <- bio_values[-1L]
if (length(bio_values) != 11L || any(!is.finite(bio_values))) stop("Unexpected Table ES-8 age-1+ biomass values.", call. = FALSE)
reported_bio <- frame_output("biomass", "biomass_by_age_group", 2011:2021, bio_values,
  "metric tonnes", age_group = "1+", source_type = "official_table",
  source_reference = "2021 assessment report Table ES-8, Age 1+ Biomass row",
  notes = "Values transcribed from the official table. The 2021 report value conflicts with the archived run forecast; both source values are retained without adjustment.",
  scenario = "report Table ES-8")
N_total <- vapply(years, function(year) {
  z <- n_surface[n_surface$Yr == year, , drop = FALSE]
  if (nrow(z) != 2L) stop("Missing female/male N-at-age in year ", year, call. = FALSE)
  sum(as.matrix(z[, age_cols, drop = FALSE]))
}, numeric(1))
Total_numbers <- frame_output("population", "total_numbers", years, N_total,
  "thousand fish", age_group = "0-95", source_type = "derived_source_output",
  source_reference = "Derived by summing Report.sso beginning-year N-at-age across sexes and ages",
  notes = "Derived total abundance; no separate uncertainty interval is available; age 95 is the plus group.",
  scenario = forecast_scenario)
q_row <- out$parameters[grepl("^LnQ_base_WCGBTS", out$parameters$Label), , drop = FALSE]
if (nrow(q_row) != 1L || abs(exp(q_row$Value) - 0.43) > 1e-6) {
  stop("Selected model archive is not the q=0.43 middle state of nature.", call. = FALSE)
}
assumption <- function(component, setting, value, source_reference, notes = "", sex = "", fleet = "", survey = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = sex, region = "", season = "", setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE)
}
assumptions_new <- rbind(
  assumption("model", "software", "Stock Synthesis 3.30.16.", "control.ss_new; Report.sso"),
  assumption("population", "dimensions", "One U.S. Pacific Coast area, two sexes, annual model season, ages 0-95 with age 95 as the plus group; fitted observations through 2020.", "data.ss_new; Report.sso"),
  assumption("population", "stock_definition", "The assessment models a single coastwide U.S. West Coast stock from the U.S.-Canada border to the U.S.-Mexico border and excludes inland waters.", "2021 assessment report, model description"),
  assumption("catch", "series", "Eight annual fishery catch-biomass series, 1916-2020, in metric tonnes; source catch uncertainty is retained on the log scale.", "data.ss_new catch block; assessment report Table ES-5"),
  assumption("index", "series", "55 aggregate relative index observations from five survey series, 1980-2019; four use biomass predictions and IPHC uses numbers predictions.", "data.ss_new CPUE and CPUEinfo blocks"),
  assumption("index", "model_timing", "All CPUE rows use model month 7, corresponding to within-year time 0.5.", "data.ss_new CPUE block", "Model timing code, not verified actual sampling month for every survey."),
  assumption("biology", "composition_inputs", "156 length-composition strata and 33 conditional age-at-length strata. The age key is a 2010 WCGBTS sample of 515 fish, ages 0-71.", "data.ss_new lencomp and agecomp blocks"),
  assumption("biology", "missing_age_observations", "Native inputs do not include catch numbers-at-age or age-specific abundance-index observations.", "data.ss_new; 2021 assessment report", "The one-year age key could support a separate reconstruction from length data, but no reconstructed values are stored as observed data."),
  assumption("mortality", "natural_mortality", "Natural mortality is fixed at 0.065 per year for both sexes and all ages.", "control.ss_new; Report.sso M_at_age"),
  assumption("biology", "female_maturity", "Female maturity is a fixed length-based logistic ogive with Mat50=88.2 cm and slope=-0.27.", "control.ss_new; 2021 assessment report"),
  assumption("biology", "fecundity", "Fecundity uses a fixed model relationship with parameters -7.35 and 0.107; the assessment expresses reproductive output as pups.", "control.ss_new; Report.sso"),
  assumption("biology", "growth_and_weight", "Sex-specific growth and weight-at-length are represented by model-estimated biological parameters; annual population weight-at-age surfaces are provided by the fitted model.", "control.ss_new; wtatage.ss_new"),
  assumption("recruitment", "stock_recruitment", "The assessment uses a deterministic stock-recruit relationship without annual recruitment deviations.", "2021 assessment report, recruitment section; control.ss_new"),
  assumption("catchability", "WCGBTS_q", "The imported archive fixes WCGBTS catchability at q=0.43 for the management middle state of nature.", "control.ss_new; Report.sso; 2021 assessment report"),
  assumption("catchability", "alternative_main_base_model", "The report's main base-model estimate of WCGBTS q is 0.586; this different model state is not combined with imported q=0.43 outputs.", "2021 assessment report, model results"),
  assumption("uncertainty", "reported_uncertainty", "The report gives 95% intervals for annual spawning output and recruitment over 2011-2021. No age-specific N/F/M/weight/maturity uncertainty surfaces are available.", "2021 assessment report Table ES-2; Report.sso covariance output"),
  assumption("output", "report_model_biomass_conflict", "Table ES-8 reports 2021 age-1+ biomass of 255,602 mt, while the q=0.43 Report.sso forecast gives 110,047 mt; 2011-2020 agree. Both are stored with distinct scenarios.", "2021 assessment report Table ES-8; Report.sso TIME/FORE Bio_smry"))
outputs_new <- do.call(rbind, list(N_rows, B_rows, F_fleet_rows, F_total_rows, M_rows,
  W_rows, Mat_rows, SSB_rows, Recruit_rows, Bio_all_rows, Bio_1plus_rows,
  reported_bio, Total_numbers))
q_output <- frame_output("catchability", "q", value = 0.43, unit = "ratio",
  source_type = "native_model", source_reference = "Report.sso parameter LnQ_base_WCGBTS; control.ss_new",
  notes = "WCGBTS q fixed at 0.43 in the imported management middle-state run; the report's main base model uses a different q.")
outputs_new <- rbind(outputs_new, q_output)

input_key_cols <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "observation_id", "length_bin",
  "length_bin_lower", "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
output_key_cols <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region",
  "season", "year", "age", "age_group", "scenario")
key <- function(x, cols) do.call(paste, c(lapply(x[cols], function(z) {
  z <- as.character(z); z[is.na(z)] <- ""; z
}), sep = "\r"))
if (anyDuplicated(key(inputs_new, input_key_cols)) || anyDuplicated(key(outputs_new, output_key_cols))) {
  stop("Dogfish records contain duplicate canonical keys.", call. = FALSE)
}
candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
ci <- match(candidate_id, candidates$candidate_id)
if (is.na(ci) || candidates$candidate_unit_id[ci] != candidate_unit_id ||
  candidates$screening_status[ci] != "screened" || candidates$eligibility[ci] != "eligible" ||
  !candidates$match_status[ci] %in% c("new", "matched") ||
  (!is.na(candidates$matched_stock_id[ci]) && candidates$matched_stock_id[ci] != stock_id)) {
  stop("NOAA Pacific spiny dogfish candidate status differs from the reviewed unit.", call. = FALSE)
}
candidates$scientific_name[ci] <- "Squalus suckleyi"
candidates$match_status[ci] <- "matched"
candidates$matched_stock_id[ci] <- stock_id
candidates$import_status[ci] <- "partial"
candidates$notes[ci] <- paste(
  "Official 2021 U.S. Pacific Coast production assessment imported from the pinned report and native Stock Synthesis archive.",
  "Inputs retain aggregate catch, relative indices, length compositions and the single 2010 conditional age-at-length sample; there are no direct catch-at-age or age-specific index observations.",
  "Outputs retain N/F/M and biological surfaces; spawning output and recruitment use pup-count units. Published 2021 age-1+ biomass conflicts with archived forecast and both are retained. See source review.")
inventory_unit_path <- file.path(root, "discovery", "inventory_units.csv")
unit_lines <- readLines(inventory_unit_path, warn = FALSE, encoding = "UTF-8")
unit_hit <- grep(paste0('"candidate:', candidate_unit_id, '"'), unit_lines, fixed = TRUE)
if (length(unit_hit) != 1L) stop("Expected one dogfish inventory unit row.", call. = FALSE)
unit_row <- read.csv(text = c(unit_lines[1L], unit_lines[unit_hit]), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit_row$matched_stock_id <- stock_id
unit_row$match_status <- "matched"
unit_row$import_status <- "partial"
tmp_unit <- tempfile(fileext = ".csv")
write.csv(unit_row, tmp_unit, row.names = FALSE, na = "", fileEncoding = "UTF-8")
unit_lines[unit_hit] <- readLines(tmp_unit, warn = FALSE, encoding = "UTF-8")[-1L]
unlink(tmp_unit)
existing_rows <- function(path) {
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to check for duplicate assessment records.", call. = FALSE)
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading", "-F", assessment_id, path),
    stdout = TRUE, stderr = FALSE))
  status <- attr(found, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) return(character())
  if (status != 0L) stop("Could not scan ", path, call. = FALSE)
  found[startsWith(found, paste0('"', assessment_id, '",'))]
}
for (name in c("stocks", "assessments", "assumptions", "inputs", "outputs")) {
  if (length(existing_rows(file.path(root, "database", paste0(name, ".csv"))))) {
    stop("Rows for this assessment already exist in ", name, ".csv; refusing duplicate import.", call. = FALSE)
  }
}
cat("NOAA Pacific spiny dogfish 2021 import: ", nrow(inputs_new), " inputs; ",
  nrow(outputs_new), " outputs.\nCatch ", sum(valid_catch),
  " observations; CPUE ", nrow(dat$CPUE), "; length-composition strata ",
  nrow(dat$lencomp), "; conditional age-at-length strata ", nrow(dat$agecomp),
  " (", sum(dat$agecomp$Nsamp), " fish).\n", sep = "")
if (!write_mode) {
  cat("Dry run only; add --write to append records and reconcile the candidate unit.\n")
  quit(save = "no", status = 0L)
}
stock_row <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "10702", scientific_name = "Squalus suckleyi",
  common_name = "Pacific spiny dogfish",
  area = "Continental U.S. Pacific Coast, Washington, Oregon and California; excludes inland waters",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART unit 10702; distinct from the Canadian British Columbia outside-waters assessment. The 2021 report uses the current species name Squalus suckleyi; older sources may use Squalus acanthias.",
  stringsAsFactors = FALSE)
assessment_row <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2021L, terminal_year = 2020L, estimate_terminal_year = 2021L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis", model_version = "3.30.16",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2022/01/status-of-the-pacific-spiny-dogfish-shark-resource-off-the-continental-u-s-pacific-coast-in-2021-october-19-2021.pdf/",
  framework_url = "https://www.pcouncil.org/documents/spiny-dogfish-stock-assessment-review-star-panel-report/",
  data_url = "https://www.pcouncil.org/documents/spiny-dogfish-assessment-supplementary-table-excel/",
  model_url = "https://www.pcouncil.org/documents/spiny-dogfish-2021-model-files-zip-file/",
  repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Latest detailed U.S. Pacific Coast assessment package located is the 2021 full assessment. Native model data end in 2020; 2021 is a one-year forecast. Direct catch-at-age and age-specific abundance-index observations are unavailable. Official Table ES-8 and the selected q=0.43 archive disagree on 2021 age-1+ biomass; both are preserved with distinct source scenarios.",
  stringsAsFactors = FALSE)
append_csv <- function(x, path) write.table(x, file = path, sep = ",", row.names = FALSE,
  col.names = FALSE, append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
append_csv(stock_row, file.path(root, "database", "stocks.csv"))
append_csv(assessment_row, file.path(root, "database", "assessments.csv"))
append_csv(assumptions_new, file.path(root, "database", "assumptions.csv"))
append_csv(inputs_new, file.path(root, "database", "inputs.csv"))
append_csv(outputs_new, file.path(root, "database", "outputs.csv"))
candidate_lines <- readLines(candidate_path, warn = FALSE, encoding = "UTF-8")
if (length(candidate_lines) != nrow(candidates) + 1L) stop("Candidate register has multiline CSV records; refusing row-unsafe update.", call. = FALSE)
tmp_candidate <- tempfile(fileext = ".csv")
write.csv(candidates[ci, , drop = FALSE], tmp_candidate, row.names = FALSE, na = "", fileEncoding = "UTF-8")
candidate_lines[ci + 1L] <- readLines(tmp_candidate, warn = FALSE, encoding = "UTF-8")[-1L]
unlink(tmp_candidate)
writeLines(candidate_lines, candidate_path, useBytes = TRUE)
writeLines(unit_lines, inventory_unit_path, useBytes = TRUE)
source(file.path(root, "scripts", "database", "002_validate_database.R"), local = TRUE)
cat("Dogfish source import written and database validation passed.\n")



