root <- "."
stock_id <- "noaa_lingcod_northern_pacific_coast"
assessment_id <- "noaa_lingcod_northern_pacific_coast_2021"
candidate_id <- "NOAA:12194"
cache <- file.path(root, "source_cache", "discovery_noaa_lingcod_northern_2021")
manifest_path <- file.path(root, "provenance", assessment_id, "manifest.csv")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("r4ss", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install r4ss and pdftools to parse the cached lingcod assessment.", call. = FALSE)
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
report_path <- verify_source("lingcod_north_2021_assessment.pdf")
model_zip <- verify_source("lingcod_2021_model_files.zip")
verify_source("lingcod_2021_star_panel.pdf")
work <- tempfile("lingcod_north_2021_")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)
unzip(model_zip, exdir = work)
data_files <- list.files(work, "^data\\.ss_new$", recursive = TRUE, full.names = TRUE)
north_data <- data_files[grepl("[/\\\\]north[/\\\\]data\\.ss_new$", data_files, ignore.case = TRUE)]
if (length(north_data) != 1L) stop("Expected one northern data.ss_new in the official archive.", call. = FALSE)
model_dir <- dirname(north_data)
for (file in c("control.ss_new", "Report.sso", "wtatage.ss_new", "ss.par", "ss.cor", "covar.sso")) {
  if (!file.exists(file.path(model_dir, file))) stop("Official north archive lacks ", file, call. = FALSE)
}
control_header <- readLines(file.path(model_dir, "control.ss_new"), n = 1L, warn = FALSE)
if (!any(grepl("V3\\.30\\.17\\.01", control_header))) stop("Stock Synthesis version differs from 3.30.17.01.", call. = FALSE)
dat <- r4ss::SS_readdat(north_data, verbose = FALSE)
out <- r4ss::SS_output(model_dir, printstats = FALSE, verbose = FALSE)
pdf_pages <- pdftools::pdf_text(report_path)
if (dat$styr != 1889L || dat$endyr != 2020L || dat$nseas != 1L || dat$Nages != 25L ||
    dat$Nsexes != 2L || dat$N_areas != 1L || dat$Nfleets != 10L ||
    nrow(dat$catch) != 665L || nrow(dat$CPUE) != 137L ||
    nrow(dat$lencomp) != 383L || nrow(dat$agecomp) != 7115L ||
    !identical(as.integer(dat$agebin_vector), 0:20) ||
    !identical(as.numeric(dat$lbin_vector), seq(10, 130, 2)) ||
    dat$lbin_method != 2L || dat$Lbin_method != 3L ||
    sum(dat$catch$year == -999L) != 5L ||
    sum(dat$agecomp$fleet < 0L) != 218L ||
    !all(dat$fleetinfo$units[1:5] == 1L) ||
    !setequal(as.integer(dat$CPUEinfo$units), c(0L, 1L)) ||
    !all(dat$CPUE$month == 7L) || any(dat$CPUE$se_log <= 0)) {
  stop("Northern lingcod model inputs differ from the pinned assessment structure.", call. = FALSE)
}
if (!all(dat$catch$year[dat$catch$year != -999L] %in% 1889:2020) ||
    length(unique(dat$catch$fleet[dat$catch$year != -999L])) != 5L ||
    !setequal(unique(dat$agecomp$sex), 0:3) ||
    !setequal(unique(dat$lencomp$sex), c(0L, 3L)) ||
    !setequal(unique(dat$agecomp$part), c(0L, 2L))) {
  stop("Northern lingcod catch or composition coverage differs from the source review.", call. = FALSE)
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
region_name <- "Northern U.S. West Coast"
frame_input <- function(type, measure, basis, value, unit, fleet = "", survey = "", sex = "",
                        region = region_name, season = "", year = NA_integer_, age = NA_integer_,
                        sampling_time = NA_real_, source_type = "native_model", source_reference,
                        transformation = "", notes = "", observation_id = "", length_bin = NA_real_,
                        length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
                        age_error = NA_real_, partition = "", weight_bin = NA_real_) {
  args <- list(type, measure, basis, value, unit, fleet, survey, sex, region, season, year, age,
    sampling_time, source_type, source_reference, transformation, notes, observation_id,
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
catch_id <- paste0("LING_CATCH_F", catch_fleet_id, "_", catch_year)
catch_rows <- frame_input("catch", "catch_biomass", "biomass", dat$catch$catch[valid_catch],
  "metric tonnes", fleet = catch_fields$fleet, region = region_name, season = "annual",
  year = catch_year, source_reference = "data.ss_new, catch block",
  notes = "Native annual retained catch biomass; five zero-valued -999 placeholders are not calendar-year observations and are excluded.",
  observation_id = catch_id)
catch_sd <- frame_input("catch", "log_catch_sd", "log_scale", dat$catch$catch_se[valid_catch],
  "log-scale SD", fleet = catch_fields$fleet, region = region_name, season = "annual",
  year = catch_year, source_reference = "data.ss_new, catch block, catch_se",
  notes = "Source catch_se is the standard error of log(catch).", observation_id = catch_id)
index_id <- as.integer(dat$CPUE$index)
index_year <- as.integer(dat$CPUE$year)
index_month <- as.integer(dat$CPUE$month)
cpue_info <- dat$CPUEinfo[match(index_id, as.integer(dat$CPUEinfo$fleet)), , drop = FALSE]
if (anyNA(cpue_info$units)) stop("A CPUE fleet has no CPUEinfo unit code.", call. = FALSE)
index_fields <- fleet_fields(index_id)
index_measure <- ifelse(cpue_info$units == 0L, "relative_abundance_index", "relative_biomass_index")
index_unit <- ifelse(cpue_info$units == 0L,
  "native abundance-index scale (Stock Synthesis unit code 0)",
  "native biomass-index scale (Stock Synthesis unit code 1)")
index_time <- (index_month - 1) / 12
index_obs <- paste0("LING_INDEX_F", index_id, "_", index_year, "_m", index_month)
index_note <- paste0("Native relative index from ", fleet_name(index_id), "; Stock Synthesis CPUE unit code ",
  cpue_info$units, " selects a numbers or biomass prediction, but fitted catchability means this is not treated as an absolute abundance observation.")
index_rows <- frame_input("index", index_measure, "index_scale", dat$CPUE$obs, index_unit,
  fleet = index_fields$fleet, survey = index_fields$survey, region = region_name,
  season = paste0("month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "data.ss_new, CPUE and CPUEinfo blocks", notes = index_note,
  observation_id = index_obs)
index_sd <- frame_input("index", "log_index_sd", "log_scale", dat$CPUE$se_log, "log-scale SD",
  fleet = index_fields$fleet, survey = index_fields$survey, region = region_name,
  season = paste0("month ", index_month), year = index_year, sampling_time = index_time,
  source_reference = "data.ss_new, CPUE block, se_log",
  notes = "Native observation SD on log index scale; July maps to within-year time 0.5.",
  observation_id = index_obs)
make_composition <- function(x, kind) {
  if (kind == "length") {
    bins <- as.numeric(dat$lbin_vector); cols_f <- paste0("f", bins); cols_m <- paste0("m", bins)
    measure <- "frequency_at_length"; table_ref <- "data.ss_new, length-composition block"
    sex_codes <- c(0L, 3L)
  } else {
    bins <- as.numeric(dat$agebin_vector); cols_f <- paste0("f", bins); cols_m <- paste0("m", bins)
    measure <- "conditional_frequency_at_age"; table_ref <- "data.ss_new, conditional age-at-length block"
    sex_codes <- 0:3
  }
  result <- vector("list", nrow(x) * 2L); cursor <- 0L
  for (i in seq_len(nrow(x))) {
    source_sex <- as.integer(x$sex[i])
    if (!source_sex %in% sex_codes) stop("Unexpected composition sex code.", call. = FALSE)
    source_fleet <- as.integer(x$fleet[i]); fields <- fleet_fields(source_fleet)
    source_year <- as.integer(x$year[i]); month <- as.integer(x$month[i]); part <- as.integer(x$part[i])
    age_error <- if (kind == "age") as.integer(x$ageerr[i]) else NA_integer_
    state <- if (source_fleet < 0L) "ghost; negative source fleet excludes this composition from the likelihood" else "active source fleet"
    id <- paste0("LING_", ifelse(kind == "length", "LEN", "CAAL"), "_F", abs(source_fleet),
      "_", source_year, "_m", month, "_p", part, "_s", source_sex, "_r", sprintf("%04d", i))
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
        "Source sex code 3 uses female and male vectors jointly; both share one observation ID and are not separate samples."
      } else if (source_sex == 0L) {
        "Source sex code 0 is combined sexes in the female vector; the required male vector is ignored by Stock Synthesis."
      } else if (source_sex == 1L) {
        "Source sex code 1 fits the female vector only; the male vector is retained but ignored by Stock Synthesis."
      } else {
        "Source sex code 2 fits the male vector only; the female vector is retained but ignored by Stock Synthesis."
      }
      bin_note <- if (kind == "age") "Age bin 20 represents 20+; length bounds use Lbin_method=3 actual lengths." else
        "Length labels run from 10 to 130+ cm in 2-cm bins."
      ignored_note <- if (ignored[j]) "This vector is retained for source fidelity but ignored by the fitted likelihood." else ""
      note <- paste(source_note, state, bin_note, ignored_note,
        if (!is.na(age_error) && age_error > 0L) paste("Age-error code", age_error, ".") else "")
      result[[cursor]] <- frame_input(
        type = if (kind == "age") "biology" else ifelse(fields$fleet != "", "catch", "index"), measure = measure,
        basis = "native_frequency", value = vectors[[j]], unit = "native composition frequency units",
        fleet = fields$fleet, survey = fields$survey, sex = vector_sex[j], region = region_name,
        season = paste0("month ", month), year = abs(source_year), sampling_time = (month - 1) / 12,
        source_type = "native_model", source_reference = paste0(table_ref, ", source row ", i),
        transformation = if (kind == "age") "Retain native conditional age-at-length vector; do not convert to marginal catch-at-age." else "Retain native length-composition vector.",
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
                         age_group = "", fleet = "", survey = "", sex = "", region = region_name,
                         season = "annual", se = NA_real_, lwr = NA_real_, upr = NA_real_,
                         source_type = "native_model", source_reference, notes = "", scenario = "") {
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
sex_label <- function(x) ifelse(as.integer(x) == 1L, "female", "male")
surface_rows <- function(x, type, measure, unit, reference, notes, fleet_column = NULL,
                         age_values = 0:25) {
  cols <- as.character(age_values)
  if (!all(cols %in% names(x))) stop("Report.sso surface lacks expected age columns.", call. = FALSE)
  n <- nrow(x)
  frame_output(type, measure, rep(as.integer(x$Yr), each = length(age_values)),
    as.vector(t(as.matrix(x[, cols, drop = FALSE]))), unit,
    age = rep(age_values, times = n),
    fleet = if (is.null(fleet_column)) "" else rep(fleet_name(x[[fleet_column]]), each = length(age_values)),
    sex = rep(sex_label(x$Sex), each = length(age_values)), season = "annual",
    source_reference = reference, notes = notes,
    scenario = ifelse(rep(as.integer(x$Yr), each = length(age_values)) == 2021L, "one-year forecast", ""))
}
report_rows <- function(page_title, years, expected_fields = 7L) {
  pages <- which(vapply(pdf_pages, function(page) grepl(page_title, page, fixed = TRUE), logical(1)))
  if (length(pages) != 1L) stop("Could not uniquely locate report table: ", page_title, call. = FALSE)
  lines <- strsplit(pdf_pages[[pages]], "\n", fixed = TRUE)[[1L]]
  lines <- lines[grepl("^\\s*20(1[1-9]|2[01])\\s+", lines, perl = TRUE)]
  parsed <- lapply(lines, function(line) {
    token <- regmatches(line, gregexpr("(?<![[:alpha:]])[-+]?[0-9]+(?:\\.[0-9]+)?(?![[:alpha:]])", line, perl = TRUE))[[1L]]
    as.numeric(gsub(",", "", token, fixed = TRUE))
  })
  parsed <- Filter(function(row) length(row) == expected_fields, parsed)
  values <- as.data.frame(do.call(rbind, parsed))
  names(values) <- c("year", "estimate", "lwr", "upr", "other", "other_lwr", "other_upr")
  values$year <- as.integer(values$year)
  values <- values[values$year %in% years, , drop = FALSE]
  values <- values[order(values$year), , drop = FALSE]
  if (!identical(values$year, as.integer(years))) stop("Report table coverage differs for ", page_title, call. = FALSE)
  values
}
ssb_table <- report_rows("Table ii: Estimated recent trend in spawning biomass", 2011:2021)
recruit_table <- report_rows("Table iii: Estimated recent trend in recruitment", 2011:2021)
years_out <- 1889:2021
ages <- 0:25
age_cols <- as.character(ages)
n_surface <- out$natage[out$natage$Era %in% c("TIME", "FORE") & out$natage[["Beg/Mid"]] == "B" & out$natage$Yr %in% years_out, , drop = FALSE]
b_surface <- out$batage[out$batage$Era %in% c("TIME", "FORE") & out$batage[["Beg/Mid"]] == "B" & out$batage$Yr %in% years_out, , drop = FALSE]
fleet_codes <- 1:5
f_surface <- out$fatage[out$fatage$Era %in% c("TIME", "FORE") & out$fatage$Yr %in% years_out & out$fatage$Fleet %in% fleet_codes, , drop = FALSE]
if (nrow(n_surface) != length(years_out) * 2L || nrow(b_surface) != length(years_out) * 2L ||
    nrow(f_surface) != length(years_out) * 2L * length(fleet_codes) ||
    !setequal(as.integer(n_surface$Yr), years_out) ||
    !setequal(as.integer(b_surface$Yr), years_out) ||
    !all(age_cols %in% names(n_surface)) || !all(age_cols %in% names(b_surface)) ||
    !all(age_cols %in% names(f_surface))) {
  stop("Report.sso age-surface dimensions differ from the expected 1889-2021 output.", call. = FALSE)
}
N_rows <- surface_rows(n_surface, "population", "numbers_at_age", "thousand fish",
  "Report.sso TIME/FORE, beginning-year N-at-age", "Age 25 is the terminal plus group.")
B_rows <- surface_rows(b_surface, "biomass", "biomass_at_age", "metric tonnes",
  "Report.sso TIME/FORE, beginning-year biomass-at-age", "Age 25 is the terminal plus group.")
F_rows <- surface_rows(f_surface, "mortality", "fishing_mortality_at_age", "per year",
  "Report.sso TIME/FORE, fleet-specific F-at-age", "Annual fishery F; fleet identity retained.", "Fleet")

f_total <- do.call(rbind, lapply(years_out, function(year) {
  z <- f_surface[f_surface$Yr == year, , drop = FALSE]
  vals <- lapply(1:2, function(sex_code) {
    rows <- z[z$Sex == sex_code, , drop = FALSE]
    if (nrow(rows) != length(fleet_codes)) stop("Missing fishery F surfaces for year ", year, call. = FALSE)
    colSums(as.matrix(rows[, age_cols, drop = FALSE]))
  })
  rbind(data.frame(year = year, Sex = 1L, as.list(vals[[1L]]), check.names = FALSE),
    data.frame(year = year, Sex = 2L, as.list(vals[[2L]]), check.names = FALSE))
}))
F_total <- frame_output("mortality", "fishing_mortality_at_age",
  rep(f_total$year, each = length(ages)), as.vector(t(as.matrix(f_total[, age_cols, drop = FALSE]))),
  "per year", age = rep(ages, times = nrow(f_total)),
  sex = rep(sex_label(f_total$Sex), each = length(ages)),
  source_type = "derived_source_output", source_reference = "Derived from Report.sso fleet-specific F-at-age",
  notes = "Total fishery F-at-age is the sum of the five reported fishing fleets; age 25 is the plus group.",
  scenario = ifelse(rep(f_total$year, each = length(ages)) == 2021L, "one-year forecast", ""))
m_parameters <- out$parameters[match(c("NatM_uniform_Fem_GP_1", "NatM_uniform_Mal_GP_1"), out$parameters$Label), , drop = FALSE]
if (nrow(m_parameters) != 2L || anyNA(m_parameters$Value) || anyNA(m_parameters$Parm_StDev)) {
  stop("Could not recover the two sex-specific natural-mortality estimates and standard errors.", call. = FALSE)
}
M_rows <- do.call(rbind, lapply(seq_len(nrow(m_parameters)), function(i) {
  sex <- ifelse(grepl("Fem", m_parameters$Label[i]), "female", "male")
  frame_output("mortality", "natural_mortality_average_parameter", value = m_parameters$Value[i],
    unit = "per year", sex = sex, se = m_parameters$Parm_StDev[i], source_type = "native_model",
    source_reference = "Report.sso parameter table; assessment report Table 15",
    notes = paste0("Fitted time-invariant uniform M parameter for ", sex, "; control applies it across all ages."))
}))
M_surface <- frame_output("mortality", "natural_mortality_at_age",
  rep(years_out, each = length(ages) * 2L),
  rep(rep(m_parameters$Value, each = length(ages)), times = length(years_out)),
  "per year", age = rep(ages, times = length(years_out) * 2L),
  sex = rep(c("female", "male"), each = length(ages), times = length(years_out)),
  source_type = "derived_source_output", source_reference = "Derived from Report.sso sex-specific uniform-M parameters and control.ss_new NatM_type=0",
  notes = "Uniform fitted M is expanded across age and year as defined by the official model; age 25 is the plus group.",
  scenario = ifelse(rep(years_out, each = length(ages) * 2L) == 2021L, "one-year forecast", ""))
wt <- out$wtatage
wt$year <- as.integer(wt$year); wt$sex <- as.integer(wt$sex); wt$fleet <- as.integer(wt$fleet)
wt <- wt[wt$year %in% years_out, , drop = FALSE]
wt_population <- wt[wt$fleet == 0L, , drop = FALSE]
wt_fecundity <- wt[wt$fleet == -2L & wt$sex == 1L, , drop = FALSE]
if (nrow(wt_population) != length(years_out) * 2L || nrow(wt_fecundity) != length(years_out)) {
  stop("wtatage.ss_new lacks expected beginning-year and female maturity-fecundity surfaces.", call. = FALSE)
}
W_rows <- frame_output("biology", "weight_at_age", rep(wt_population$year, each = length(ages)),
  as.vector(t(as.matrix(wt_population[, age_cols, drop = FALSE]))), "kg per fish",
  age = rep(ages, times = nrow(wt_population)), sex = rep(sex_label(wt_population$sex), each = length(ages)),
  source_type = "derived_source_output", source_reference = "wtatage.ss_new, fleet 0 beginning-season population weights",
  notes = "Model-generated weight-at-age from sex-specific growth and fixed weight-length parameters; age 25 is the plus group.",
  scenario = ifelse(rep(wt_population$year, each = length(ages)) == 2021L, "one-year forecast", ""))
wt_female <- wt_population[wt_population$sex == 1L, , drop = FALSE]
wt_fecundity <- wt_fecundity[match(wt_female$year, wt_fecundity$year), , drop = FALSE]
if (anyNA(wt_fecundity$year)) stop("Female maturity-fecundity rows do not align with weights.", call. = FALSE)
maturity <- as.matrix(wt_fecundity[, age_cols, drop = FALSE]) / as.matrix(wt_female[, age_cols, drop = FALSE])
if (any(!is.finite(maturity)) || any(maturity < 0 | maturity > 1)) stop("Derived maturity-at-age falls outside [0,1].", call. = FALSE)
Mat_rows <- frame_output("biology", "maturity_at_age", rep(wt_female$year, each = length(ages)),
  as.vector(t(maturity)), "proportion", age = rep(ages, times = nrow(wt_female)), sex = "female",
  source_type = "derived_source_output", source_reference = "wtatage.ss_new, fleet -2 maturity*fecundity divided by fleet 0 body weight",
  notes = "Derived maturity-at-age; control fecundity option 1 has intercept 1 and slope 0, so fecundity equals body weight. Age 25 is the plus group.",
  scenario = ifelse(rep(wt_female$year, each = length(ages)) == 2021L, "one-year forecast", ""))
ts <- out$timeseries[out$timeseries$Era %in% c("TIME", "FORE") & out$timeseries$Yr %in% years_out, , drop = FALSE]
if (nrow(ts) != length(years_out)) stop("Report.sso annual time-series does not cover 1889-2021.", call. = FALSE)
ssb_derived <- out$derived_quants[match(paste0("SSB_", years_out), out$derived_quants$Label), , drop = FALSE]
rec_derived <- out$derived_quants[match(paste0("Recr_", years_out), out$derived_quants$Label), , drop = FALSE]
if (anyNA(ssb_derived$Value) || anyNA(rec_derived$Value)) stop("Annual SSB or recruitment derived quantities are missing.", call. = FALSE)
ssb_match <- match(ssb_table$year, ts$Yr); rec_match <- match(recruit_table$year, ts$Yr)
if (anyNA(ssb_match) || anyNA(rec_match) ||
    max(abs(ts$SpawnBio[ssb_match] - ssb_table$estimate)) > 0.6 ||
    max(abs(ts$Recruit_0[rec_match] - recruit_table$estimate)) > 0.6) {
  stop("Report.sso point estimates do not match Tables ii-iii within report rounding.", call. = FALSE)
}
scenario <- ifelse(ts$Yr == 2021L, "one-year forecast", "")
ssb_interval <- match(ts$Yr, ssb_table$year); rec_interval <- match(ts$Yr, recruit_table$year)
ssb_lwr <- ssb_upr <- rec_lwr <- rec_upr <- rep(NA_real_, nrow(ts))
has_ssb <- !is.na(ssb_interval); has_rec <- !is.na(rec_interval)
ssb_lwr[has_ssb] <- ssb_table$lwr[ssb_interval[has_ssb]]
ssb_upr[has_ssb] <- ssb_table$upr[ssb_interval[has_ssb]]
rec_lwr[has_rec] <- recruit_table$lwr[rec_interval[has_rec]]
rec_upr[has_rec] <- recruit_table$upr[rec_interval[has_rec]]
SSB_rows <- frame_output("biomass", "SSB", ts$Yr, ts$SpawnBio, "metric tonnes",
  se = ssb_derived$StdDev, lwr = ssb_lwr, upr = ssb_upr,
  source_type = ifelse(has_ssb, "official_table", "native_model"),
  source_reference = ifelse(has_ssb, "Report.sso derived quantities; assessment report Table ii", "Report.sso TIME-era SpawnBio and derived quantities"),
  notes = ifelse(has_ssb, "Point estimate and delta-method SE from Report.sso; rounded 95% interval from Table ii.", "Native annual spawning biomass and delta-method SE from fitted covariance output."),
  scenario = scenario)
Recruit_rows <- frame_output("recruitment", "recruitment", ts$Yr, ts$Recruit_0, "thousand fish",
  age = 0L, se = rec_derived$StdDev, lwr = rec_lwr, upr = rec_upr,
  source_type = ifelse(has_rec, "official_table", "native_model"),
  source_reference = ifelse(has_rec, "Report.sso derived quantities; assessment report Table iii", "Report.sso TIME-era Recruit_0 and derived quantities"),
  notes = ifelse(has_rec, "Age-0 point estimate and delta-method SE from Report.sso; rounded 95% interval from Table iii.", "Native annual age-0 recruitment and delta-method SE from fitted covariance output."),
  scenario = scenario)

Biomass_rows <- frame_output("biomass", "total_biomass", ts$Yr, ts$Bio_all, "metric tonnes",
  age_group = "all ages", source_type = "native_model", source_reference = "Report.sso TIME/FORE-era Bio_all",
  notes = "Total biomass over both sexes and all modeled ages.", scenario = scenario)
Biomass_3plus_rows <- frame_output("biomass", "total_biomass", ts$Yr, ts$Bio_smry, "metric tonnes",
  age_group = "3+", source_type = "native_model", source_reference = "Report.sso TIME/FORE-era Bio_smry",
  notes = "Stock Synthesis summary biomass for ages 3+.", scenario = scenario)
N_by_year <- lapply(years_out, function(year) {
  z <- n_surface[n_surface$Yr == year, , drop = FALSE]
  if (nrow(z) != 2L) stop("Expected female and male N-at-age in year ", year, call. = FALSE)
  sum(as.matrix(z[, age_cols, drop = FALSE]))
})
Total_numbers <- frame_output("population", "total_numbers", years_out,
  unlist(N_by_year, use.names = FALSE), "thousand fish", age_group = "0-25",
  source_type = "derived_source_output", source_reference = "Derived by summing Report.sso beginning-year N-at-age across sexes and ages",
  notes = "No separate uncertainty interval is available; age 25 is the plus group.",
  scenario = ifelse(years_out == 2021L, "one-year forecast", ""))
assumption <- function(component, setting, value, source_reference, notes = "", sex = "", fleet = "", survey = "") {
  data.frame(assessment_id = assessment_id, component = component, fleet = fleet, survey = survey,
    sex = sex, region = "", season = "", setting = setting, value = as.character(value),
    source_reference = source_reference, notes = notes, stringsAsFactors = FALSE)
}
parameter <- function(label) {
  i <- match(label, out$parameters$Label)
  if (is.na(i)) stop("Missing source parameter: ", label, call. = FALSE)
  out$parameters[i, , drop = FALSE]
}
M_f <- parameter("NatM_uniform_Fem_GP_1"); M_m <- parameter("NatM_uniform_Mal_GP_1")
mat50 <- parameter("Mat50%_Fem_GP_1"); mat_slope <- parameter("Mat_slope_Fem_GP_1")
wtlen_f1 <- parameter("Wtlen_1_Fem_GP_1"); wtlen_f2 <- parameter("Wtlen_2_Fem_GP_1")
wtlen_m1 <- parameter("Wtlen_1_Mal_GP_1"); wtlen_m2 <- parameter("Wtlen_2_Mal_GP_1")
h <- parameter("SR_BH_steep"); sigma_r <- parameter("SR_sigmaR")
assumptions_new <- rbind(
  assumption("population", "dimensions", "One area, two sexes, annual season, population ages 0-25; age 25 is the plus group; fitted data through 2020.", "data.ss_new; Report.sso"),
  assumption("model", "software", "Stock Synthesis 3.30.17.01.", "control.ss_new; Report.sso"),
  assumption("catch", "likelihood", "Five annual fishery catch-biomass series in metric tonnes, 1889-2020; catch_se is 0.01 on the log scale.", "data.ss_new catch block", "Five zero-valued -999 placeholders are not calendar-year observations."),
  assumption("index", "series", "137 aggregate CPUE observations across ten fishery and survey fleets; all are retained as relative indices with native model scales.", "data.ss_new CPUE and CPUEinfo blocks", "CPUE unit codes specify the biomass or numbers prediction; fitted fleet catchability means the observations are not treated as absolute abundance."),
  assumption("index", "timing", "All CPUE observations are from July; within-year time is 0.5.", "data.ss_new CPUE block"),
  assumption("biology", "composition_inputs", "383 length-composition strata and 7,115 conditional-age-at-length strata; age data are conditional on actual length bounds, not marginal catch-at-age.", "data.ss_new lencomp and agecomp blocks", "218 negative-fleet age strata are ghost compositions excluded from the likelihood. Source vectors, sex codes, partitions, sample sizes and age errors are preserved."),
  assumption("biology", "population_age_bins", "Internal ages 0-25 with age 25 plus group; composition age bins 0-20 with age 20 plus group.", "data.ss_new; Report.sso"),
  assumption("biology", "growth", "Sex-specific von Bertalanffy growth is estimated.", "control.ss_new; assessment report section 2.3"),
  assumption("biology", "female_maturity", paste0("Fixed age-logistic maturity parameters Mat50=", format(mat50$Value, digits = 8), " and slope=", format(mat_slope$Value, digits = 8), "."), "control.ss_new; assessment report sections 2.3.2 and 3.2.3.3"),
  assumption("biology", "weight_length", paste0("Fixed female WtLen parameters ", format(wtlen_f1$Value, digits = 8), ", ", format(wtlen_f2$Value, digits = 8), "; male ", format(wtlen_m1$Value, digits = 8), ", ", format(wtlen_m2$Value, digits = 8), "."), "control.ss_new; assessment report section 2.3.4"),
  assumption("biology", "generated_surfaces", "Annual weight-at-age is read from wtatage.ss_new fleet 0; female maturity is derived from fleet -2 maturity*fecundity divided by fleet 0 weight, using fecundity option 1 with intercept 1 and slope 0.", "wtatage.ss_new; control.ss_new"),
  assumption("mortality", "natural_mortality", paste0("Estimated sex-specific uniform M: female ", format(M_f$Value, digits = 8), " (SE ", format(M_f$Parm_StDev, digits = 6), "); male ", format(M_m$Value, digits = 8), " (SE ", format(M_m$Parm_StDev, digits = 6), ") per year."), "Report.sso parameter table; assessment report Table 15"),
  assumption("recruitment", "stock_recruitment", paste0("Beverton-Holt; estimated steepness h=", format(h$Value, digits = 6), "; recruitment SD fixed at ", format(sigma_r$Value, digits = 4), ". Main recruitment deviations cover 1960-2018, with early and late deviations also in the model."), "control.ss_new; assessment report sections 2.3.5 and 3.2.3"),
  assumption("fishery", "discard_treatment", "Commercial discards are modeled with retention curves; discard mortality is 50% for trawl and 7% for fixed gear and recreational fleets.", "2021 assessment report executive summary and methods section"),
  assumption("uncertainty", "reported_uncertainty", "Annual SSB and recruitment covariance-based delta-method SEs are available from Report.sso; Tables ii and iii report 95% intervals for 2011-2021. Age-specific N/F/M/weight/maturity uncertainty surfaces are not provided.", "Report.sso derived quantities and covariance output; assessment report Tables ii-iii"),
  assumption("output", "derived_total_abundance", "Total abundance is derived by summing female and male beginning-year N-at-age across ages 0-25.", "Report.sso TIME/FORE natage"))

output_key_cols <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group", "scenario")
key <- function(x, cols) do.call(paste, c(lapply(x[cols], function(z) {
  z <- as.character(z); z[is.na(z)] <- ""; z
}), sep = "\r"))
outputs_new <- do.call(rbind, list(N_rows, B_rows, F_rows, F_total, M_rows, M_surface,
  W_rows, Mat_rows, SSB_rows, Recruit_rows, Biomass_rows, Biomass_3plus_rows, Total_numbers))
input_key_cols <- c("assessment_id", "type", "measure", "basis", "fleet", "survey", "sex",
  "region", "season", "year", "year_basis", "age", "observation_id", "length_bin",
  "length_bin_lower", "length_bin_upper", "sample_size", "age_error", "partition", "weight_bin")
if (anyDuplicated(key(inputs_new, input_key_cols)) || anyDuplicated(key(outputs_new, output_key_cols))) {
  stop("Lingcod source records contain duplicate canonical keys.", call. = FALSE)
}
candidate_path <- file.path(root, "discovery", "candidates.csv")
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
ci <- match(candidate_id, candidates$candidate_id)
if (is.na(ci) || candidates$candidate_unit_id[ci] != "noaa_lingcod_north_pacific_coast_2021" ||
    candidates$screening_status[ci] != "screened" || candidates$eligibility[ci] != "eligible" ||
    !candidates$match_status[ci] %in% c("new", "matched") ||
    (!is.na(candidates$matched_stock_id[ci]) && candidates$matched_stock_id[ci] != stock_id)) {
  stop("NOAA northern lingcod candidate status differs from the reviewed stock unit.", call. = FALSE)
}
candidates$match_status[ci] <- "matched"
candidates$matched_stock_id[ci] <- stock_id
candidates$import_status[ci] <- "partial"
candidates$notes[ci] <- paste("Official 2021 northern U.S. Coast lingcod assessment imported from its native Stock Synthesis archive and report.",
  "Inputs retain catch, CPUE, length compositions, and conditional age-at-length data on native model scales; age-at-length is not represented as catch-at-age.",
  "Outputs include N/F/M, model-generated biological surfaces, SSB, recruitment, and derived total abundance; age-specific uncertainty and direct catch-at-age/survey-at-age inputs are unavailable.",
  "See source_reviews/noaa_lingcod_northern_pacific_coast_2021.md.")
inventory_unit_path <- file.path(root, "discovery", "inventory_units.csv")
unit_lines <- readLines(inventory_unit_path, warn = FALSE, encoding = "UTF-8")
unit_hit <- grep('"candidate:noaa_lingcod_north_pacific_coast_2021"', unit_lines, fixed = TRUE)
if (length(unit_hit) != 1L) stop("Expected one northern lingcod inventory unit row.", call. = FALSE)
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
  found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
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
cat("NOAA northern lingcod 2021 source import: ", nrow(inputs_new), " inputs; ", nrow(outputs_new), " outputs.\n",
  "Catch ", sum(valid_catch), " observations; CPUE ", nrow(dat$CPUE), "; length compositions ", nrow(dat$lencomp),
  "; conditional age-at-length ", nrow(dat$agecomp), " (", sum(dat$agecomp$fleet < 0L), " ghost).\n", sep = "")
if (!write_mode) {
  cat("Dry run only; add --write to append the source records and reconcile the candidate unit.\n")
  quit(save = "no", status = 0L)
}
stock_row <- data.frame(stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC",
  authority_stock_id = "12194", scientific_name = "Ophiodon elongatus", common_name = "Lingcod",
  area = "Northern U.S. West Coast, north of 40 deg 10 min N to the Canada-U.S. border",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART unit 12194; distinct from southern U.S. lingcod and Canadian assessment units.",
  stringsAsFactors = FALSE)
assessment_row <- data.frame(assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2021L, terminal_year = 2020L, estimate_terminal_year = 2021L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis", model_version = "3.30.17.01",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-northern-u-s-west-coast-in-2021-december-2021.pdf/",
  framework_url = "https://www.pcouncil.org/documents/2021/10/lingcod-stock-assessment-review-star-panel-report.pdf/",
  data_url = "https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/",
  model_url = "https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/",
  repository_url = "https://github.com/iantaylor-NOAA/Lingcod_2021",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Official 2021 assessment fitted through 2020, with a 2021 status estimate and one-year forecast. Direct observed catch-at-age and age-specific index observations are not in the native inputs; conditional age-at-length and aggregate indices are preserved separately. Age-specific uncertainty surfaces are unavailable.",
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
cat("Import written and database validation passed.\n")

