import_noaa_blue_deacon_california_2017 <- function(root = ".", write = FALSE) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  assessment_2017 <- "noaa_blue_deacon_california_2017"
  assessment_2019 <- "noaa_blue_deacon_california_2019"
  stock_id <- "noaa_blue_deacon_california"
  candidate_id <- "NOAA:14821"
  region <- "California"
  cache <- file.path(root, "source_cache/discovery_noaa_blue_deacon_2017")
  manifest <- read.csv(file.path(root,
    "provenance/discovery_noaa_blue_deacon_california_2017/sources.csv"),
    colClasses = "character", stringsAsFactors = FALSE, check.names = FALSE)
  source_files <- c("assessment_2017.pdf", "assessment_2017.txt",
    "model_files_california_2017.zip", "star_panel_2017.pdf",
    "california_catch_update_2019.pdf", "california_catch_update_2019.txt",
    "noaa_q3_2026_stock_status.pdf", "pfmc_2026_assessment_prioritization.pdf")
  if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in% names(manifest)) ||
      !setequal(manifest$local_file, source_files) || anyDuplicated(manifest$local_file)) {
    stop("The California Blue/Deacon source manifest is incomplete.", call. = FALSE)
  }
  for (file in source_files) {
    row <- manifest[manifest$local_file == file, , drop = FALSE]
    path <- file.path(cache, file)
    if (nrow(row) != 1L || !file.exists(path) ||
        as.numeric(row$bytes) != file.info(path)$size ||
        !identical(tolower(row$sha256), tolower(unname(tools::sha256sum(path))))) {
      stop("Cached California Blue/Deacon source differs from manifest: ", file,
        call. = FALSE)
    }
  }
  dat <- readLines(file.path(cache, "ca/BDR CA SS files/B17.dat"), warn = FALSE)
  ctl <- readLines(file.path(cache, "ca/BDR CA SS files/B17.ctl"), warn = FALSE)
  report <- readLines(file.path(cache, "assessment_2017.txt"), warn = FALSE, encoding = "UTF-8")
  update <- readLines(file.path(cache, "california_catch_update_2019.txt"),
    warn = FALSE, encoding = "UTF-8")

  numbers <- function(x) {
    x <- trimws(sub("#.*$", "", x))
    if (!nzchar(x)) return(numeric())
    fields <- strsplit(x, "[[:space:]]+")[[1L]]
    numeric_fields <- !is.na(suppressWarnings(as.numeric(fields)))
    first_text <- which(!numeric_fields)
    if (length(first_text)) fields <- fields[seq_len(first_text[1L] - 1L)]
    if (!length(fields)) numeric() else as.numeric(fields)
  }
  text_numbers <- function(x) {
    x <- gsub("<U\\+[[:xdigit:]]+>", " ", x, perl = TRUE)
    hits <- regmatches(x, gregexpr("(?<![[:alnum:]])-?[0-9][0-9,]*(?:\\.[0-9]+)?",
      x, perl = TRUE))[[1L]]
    if (identical(hits, character(0))) numeric() else
      as.numeric(gsub(",", "", hits, fixed = TRUE))
  }
  parse_block <- function(lines, start_pattern, end_pattern, width, label) {
    a <- grep(start_pattern, lines, perl = TRUE)
    b <- grep(end_pattern, lines, perl = TRUE)
    b <- b[b > a]
    if (length(a) != 1L || !length(b)) stop("Cannot locate ", label, ".")
    b <- min(b)
    rows <- lapply(lines[seq.int(a + 1L, b - 1L)], numbers)
    rows <- rows[lengths(rows) == width]
    if (!length(rows)) stop("No native rows in ", label, ".")
    do.call(rbind, rows)
  }
  parse_year_rows <- function(lines, first_year, last_year, width, label) {
    rows <- lapply(lines[grepl("^\\s*(?:19|20)[0-9]{2}\\s+", lines, perl = TRUE)], text_numbers)
    rows <- rows[lengths(rows) == width]
    rows <- Filter(function(x) x[1L] >= first_year && x[1L] <= last_year, rows)
    if (!length(rows)) stop("No annual rows in ", label, ".")
    do.call(rbind, rows)
  }
  parse_table <- function(lines, start_pattern, end_pattern, label) {
    a <- grep(start_pattern, lines, perl = TRUE)
    b <- grep(end_pattern, lines, perl = TRUE)
    if (length(a) != 1L || length(b) != 1L || a >= b) stop("Cannot locate ", label, ".")
    lines[seq.int(a, b - 1L)]
  }
  table_row <- function(lines, pattern, label) {
    i <- grep(pattern, lines, perl = TRUE)
    if (length(i) != 1L) stop("Cannot identify ", label, ".")
    text_numbers(sub(pattern, "", lines[i], perl = TRUE))
  }
  table_interval <- function(lines, row_pattern, label, n) {
    i <- grep(row_pattern, lines, perl = TRUE)
    if (length(i) != 1L || i == length(lines)) stop("Cannot identify row for ", label, ".")
    ci <- grep("^\\s*~95% CI\\s+", lines[seq.int(i + 1L, length(lines))], perl = TRUE)
    if (!length(ci)) stop("Cannot identify CI for ", label, ".")
    values <- text_numbers(sub("^\\s*~95% CI\\s+", "", lines[i + ci[1L]], perl = TRUE))
    if (length(values) != n * 2L) stop("Unexpected CI count for ", label,
      ": found ", length(values), " values.")
    matrix(values, ncol = 2L, byrow = TRUE,
      dimnames = list(NULL, c("lower", "upper")))
  }
  table_rows <- function(lines, start_pattern, end_pattern, width, label) {
    parse_year_rows(parse_table(lines, start_pattern, end_pattern, label),
      1900L, 2100L, width, label)
  }

  catch_all <- parse_block(dat, "^#_Catch data", "^#_CPUE_and_surveyabundance_observations",
    5L, "California catch block")
  catches <- catch_all[catch_all[, 1L] >= 1900 & catch_all[, 1L] <= 2016 &
    catch_all[, 3L] %in% 1:8, , drop = FALSE]
  cpue_all <- parse_block(dat, "^#_CPUE_and_surveyabundance_observations",
    "^# set up population length bin structure", 5L, "California index block")
  cpue <- cpue_all[cpue_all[, 1L] >= 1900 & cpue_all[, 1L] <= 2016 &
    cpue_all[, 3L] %in% c(1L, 3L, 9L, 10L, 11L), , drop = FALSE]
  scenario_index <- cpue_all[cpue_all[, 3L] == 14L, , drop = FALSE]
  length_comp <- parse_block(dat, "^\\s*22 #_N_LengthBins",
    "^# NEXT LINE SIGNALS END OF LENGTH COMPOSITION DATA", 50L,
    "California length compositions")
  age_comp <- parse_block(dat, "^\\s*36 #_N_age_bins",
    "^-9999[[:space:]]+0[[:space:]]+0[[:space:]]+0", 81L,
    "California age compositions")
  fleet_names <- c("Recreational CPFV", "Recreational private MRFSS",
    "Recreational private CRFS", "Recreational discards", "Commercial hook and line",
    "Commercial net", "Commercial other gear", "Commercial discards",
    "Onboard CPFV 1988-1998", "SWFSC juvenile survey", "Onboard CPFV 2001-2016",
    "Schmidt research age collection", "Abrams research age collection",
    "Decision-table SSB constraint")
  if (nrow(catches) != 641L || anyDuplicated(catches[, c(1L, 3L)]) ||
      nrow(cpue) != 69L || !all(cpue[, 2L] == 7L) ||
      nrow(scenario_index) != 1L || nrow(length_comp) != 162L ||
      nrow(age_comp) != 136L ||
      !identical(as.integer(table(factor(length_comp[, 4L], levels = c(0L, 3L)))),
        c(151L, 11L)) ||
      sum(age_comp[, 7L] >= 0L & age_comp[, 8L] >= age_comp[, 7L]) != 126L ||
      sum(age_comp[, 7L] == -1L & age_comp[, 8L] == -1L) != 10L ||
      !all(age_comp[, 4L] == 3L) || !all(age_comp[, 6L] == 1L) ||
      any(!is.finite(catches)) || any(!is.finite(cpue)) ||
      any(!is.finite(length_comp)) || any(!is.finite(age_comp))) {
    stop("Native California model inputs differ from the reviewed assessment.")
  }
  fleet_heading <- grep("^#_fleet_type, timing, area, units", dat, perl = TRUE)
  catch_heading <- grep("^#_Catch data", dat, perl = TRUE)
  cpue_heading <- grep("^#_Fleet Units Errtype SD_report", dat, perl = TRUE)
  cpue_start <- grep("^#_yr month fleet obs stderr", dat, perl = TRUE)
  fleet_rows <- lapply(dat[seq.int(fleet_heading + 1L, catch_heading - 1L)], numbers)
  fleet_def <- do.call(rbind, Filter(function(x) length(x) == 5L, fleet_rows))
  cpue_info <- lapply(dat[seq.int(cpue_heading + 1L, cpue_start - 1L)], numbers)
  cpue_info <- do.call(rbind, Filter(function(x) length(x) == 4L, cpue_info))
  cpue_info <- cpue_info[cpue_info[, 1L] %in% c(1L, 3L, 9L, 10L, 11L, 14L), , drop = FALSE]
  active_cpue_info <- cpue_info[cpue_info[, 1L] %in% c(1L, 3L, 9L, 10L, 11L), , drop = FALSE]
  scenario_cpue_info <- cpue_info[cpue_info[, 1L] == 14L, , drop = FALSE]
  if (nrow(fleet_def) != 14L || nrow(cpue_info) != 6L ||
      any(active_cpue_info[, 2L] != 0L) || any(active_cpue_info[, 3L] != 0L) ||
      any(active_cpue_info[, 4L] != 0L) ||
      nrow(scenario_cpue_info) != 1L || scenario_cpue_info[1L, 2L] != 30L) {
    stop("Unexpected California index units or fleet setup.")
  }

  age_error_header <- grep("^\\s*2 #_N_ageerror_definitions", dat, perl = TRUE)
  if (length(age_error_header) != 1L) stop("Cannot locate native age-error definitions.")
  age_error <- list(
    list(id = 1L, mean = numbers(dat[age_error_header + 2L]),
      sd = numbers(dat[age_error_header + 3L])),
    list(id = 2L, mean = numbers(dat[age_error_header + 5L]),
      sd = numbers(dat[age_error_header + 6L])))
  if (any(vapply(age_error, function(x) length(x$mean) != 36L || length(x$sd) != 36L,
      logical(1L)))) stop("Unexpected length of native age-error vectors.")

  es19 <- parse_table(report, "^Table ES19\\.", "^Table ES20\\.", "California Table ES19")
  years_recent <- 2005:2017
  landings <- table_row(es19, "^Total landings \\(mt\\)\\s+", "Table ES19 landings")
  removals <- table_row(es19, "^Total removals \\(mt\\)\\s+", "Table ES19 removals")
  spr50 <- table_row(es19, "^\\(1-SPR\\)\\s*/\\s*\\(1-SPR50%\\)\\s+", "Table ES19 SPR ratio")
  exploitation <- table_row(es19, "^Exploitation rate\\s+", "Table ES19 exploitation")
  biomass <- table_row(es19, "^Age 0\\+ biomass \\(mt\\)\\s+", "Table ES19 biomass")
  spawning <- table_row(es19, "^Spawning Output\\s+", "Table ES19 spawning output")
  recruitment <- table_row(es19, "^Recruitment \\(1000s\\)\\s+", "Table ES19 recruitment")
  depletion <- table_row(es19, "^Depletion \\(%\\)\\s+", "Table ES19 depletion")
  spawning_ci <- table_interval(es19, "^Spawning Output\\s+", "spawning output", 13L)
  recruitment_ci <- table_interval(es19, "^Recruitment \\(1000s\\)\\s+", "recruitment", 13L)
  depletion_ci <- table_interval(es19, "^Depletion \\(%\\)\\s+", "depletion", 13L)
  if (length(landings) != 12L || length(removals) != 12L ||
      length(spr50) != 12L || length(exploitation) != 12L ||
      length(biomass) != 13L || length(spawning) != 13L ||
      length(recruitment) != 13L || length(depletion) != 13L) {
    stop("Unexpected annual coverage in California Table ES19.")
  }
  recent_ci <- list(spawning = spawning_ci, recruitment = recruitment_ci,
    depletion = depletion_ci)
  table55 <- parse_table(report, "^Table 55: Time-series of population estimates for BDR in California",
    "^Table 56", "California Table 55")
  table55_rows <- parse_year_rows(table55, 1900L, 2017L, 8L, "California Table 55")
  if (nrow(table55_rows) != 118L || !identical(as.integer(table55_rows[, 1L]), 1900:2017)) {
    stop("Unexpected year coverage in California Table 55.")
  }
  table55_recent <- table55_rows[match(years_recent, table55_rows[, 1L]), 2:4]
  es19_recent <- t(rbind(biomass, spawning, depletion / 100))
  catch_diff <- abs(round(table55_rows[match(2005:2016, table55_rows[, 1L]), 6L], 1) -
    round(removals, 1))
  if (any(catch_diff > 0.1) ||
      any(abs(table55_recent[, 1L] - es19_recent[, 1L]) > 1.1) ||
      any(abs(table55_recent[, 2L] - es19_recent[, 2L]) > 1.1) ||
      any(abs(table55_recent[, 3L] - es19_recent[, 3L]) > 0.006)) {
    stop("Table 55 and Table ES19 California summary values disagree.")
  }

  update_table_a <- table_rows(update, "^\\s*Table a:", "^\\s*Figure a:", 8L,
    "2019 catch update Table a")
  update_table_b <- table_rows(update, "^\\s*Table b:", "^\\s*Recruitment$", 7L,
    "2019 catch update Table b")
  update_table_c <- table_rows(update, "^\\s*Table c:", "^\\s*Exploitation Status$", 7L,
    "2019 catch update Table c")
  update_table_d <- table_rows(update, "^\\s*Table d:", "^\\s*Figure e:", 7L,
    "2019 catch update Table d")
  if (!identical(as.integer(update_table_a[, 1L]), 2010:2018) ||
      !identical(as.integer(update_table_b[, 1L]), 2010:2019) ||
      !identical(as.integer(update_table_c[, 1L]), 2010:2019) ||
      !identical(as.integer(update_table_d[, 1L]), 2009:2019)) {
    stop("Unexpected coverage in 2019 California catch-update tables.")
  }

  db_row <- function(table, n = NULL, ...) {
    header <- readLines(file.path(root, "database", paste0(table, ".csv")), n = 1L)
    columns <- names(utils::read.csv(text = header, nrows = 0L, check.names = FALSE))
    values <- list(...)
    if (is.null(n)) n <- max(lengths(values))
    out <- as.data.frame(setNames(rep(list(rep(NA, n)), length(columns)), columns),
      stringsAsFactors = FALSE, check.names = FALSE)
    for (name in names(values)) {
      if (!name %in% columns) stop("Unknown ", table, " column: ", name)
      out[[name]] <- rep_len(values[[name]], n)
    }
    out
  }
  input <- function(assessment_id, type, measure, basis, value, unit,
                    source_reference, notes, fleet = "", survey = "", sex = "combined",
                    year = NA_integer_, age = NA_integer_, season = "", sampling_time = NA_real_,
                    source_type = "native_model", observation_id = "", length_bin = NA_real_,
                    length_bin_lower = NA_real_, length_bin_upper = NA_real_,
                    sample_size = NA_real_, age_error_code = NA_real_, partition = "") {
    n <- max(lengths(list(assessment_id, type, measure, basis, value, unit,
      source_reference, notes, fleet, survey, sex, year, age, season, sampling_time,
      observation_id, length_bin, length_bin_lower, length_bin_upper, sample_size,
      age_error_code, partition)))
    y <- rep_len(year, n)
    db_row("inputs", n = n, assessment_id = rep_len(assessment_id, n),
      type = rep_len(type, n), measure = rep_len(measure, n), basis = rep_len(basis, n),
      fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = rep_len(sex, n),
      region = rep(region, n), season = rep_len(season, n), year = as.integer(y),
      year_basis = ifelse(is.na(y), "", "calendar_year"), age = as.numeric(rep_len(age, n)),
      value = as.numeric(rep_len(value, n)), unit = rep_len(unit, n),
      sampling_time = as.numeric(rep_len(sampling_time, n)), source_type = rep_len(source_type, n),
      source_reference = rep_len(source_reference, n), notes = rep_len(notes, n),
      observation_id = rep_len(observation_id, n), length_bin = as.numeric(rep_len(length_bin, n)),
      length_bin_lower = as.numeric(rep_len(length_bin_lower, n)),
      length_bin_upper = as.numeric(rep_len(length_bin_upper, n)),
      sample_size = as.numeric(rep_len(sample_size, n)), age_error = as.numeric(rep_len(age_error_code, n)),
      partition = rep_len(partition, n))
  }
  output <- function(assessment_id, type, measure, year = NA_integer_, value, unit,
                     source_reference, notes, age = NA_integer_, sex = "combined",
                     survey = "", scenario = "", se = NA_real_, lwr = NA_real_,
                     upr = NA_real_) {
    n <- max(lengths(list(assessment_id, type, measure, year, value, unit,
      source_reference, notes, age, sex, survey, scenario, se, lwr, upr)))
    db_row("outputs", n = n, assessment_id = rep_len(assessment_id, n),
      type = rep_len(type, n), measure = rep_len(measure, n),
      fleet = rep("", n), survey = rep_len(survey, n), sex = rep_len(sex, n),
      region = rep(region, n), year = as.integer(rep_len(year, n)),
      age = as.numeric(rep_len(age, n)), scenario = rep_len(scenario, n),
      value = as.numeric(rep_len(value, n)), se = as.numeric(rep_len(se, n)),
      lwr = as.numeric(rep_len(lwr, n)), upr = as.numeric(rep_len(upr, n)),
      unit = rep_len(unit, n), source_type = rep("official_table", n),
      source_reference = rep_len(source_reference, n), notes = rep_len(notes, n))
  }
  assumption <- function(assessment_id, component, setting, value,
                         source_reference, notes, fleet = "", survey = "", sex = "") {
    n <- max(lengths(list(assessment_id, component, setting, value, source_reference,
      notes, fleet, survey, sex)))
    db_row("assumptions", n = n, assessment_id = rep_len(assessment_id, n),
      component = rep_len(component, n), fleet = rep_len(fleet, n),
      survey = rep_len(survey, n), sex = rep_len(sex, n), region = rep(region, n),
      setting = rep_len(setting, n), value = rep_len(value, n),
      source_reference = rep_len(source_reference, n), notes = rep_len(notes, n))
  }

  catch_id <- paste0("ca_catch_f", as.integer(catches[, 3L]), "_y", as.integer(catches[, 1L]))
  catch_inputs <- rbind(
    input(assessment_2017, "catch", "catch_biomass", "biomass", catches[, 4L],
      "metric tonnes", "B17.dat, catch block", "Annual aggregate catch in biomass units. Native catch_se is retained separately; the base model has no catch likelihood and treats catch as known.",
      fleet = fleet_names[as.integer(catches[, 3L])], year = as.integer(catches[, 1L]),
      season = "annual", observation_id = catch_id),
    input(assessment_2017, "catch", "catch_se", "log_scale", catches[, 5L],
      "native catch_se field", "B17.dat, catch_se field", "Native log-scale catch_se value retained exactly. The control file does not activate a catch likelihood, so this is not an estimated observation SD.",
      fleet = fleet_names[as.integer(catches[, 3L])], year = as.integer(catches[, 1L]),
      season = "annual", observation_id = catch_id))
  index_id <- paste0("ca_index_f", as.integer(cpue[, 3L]), "_y", as.integer(cpue[, 1L]))
  index_names <- fleet_names[as.integer(cpue[, 3L])]
  index_inputs <- rbind(
    input(assessment_2017, "index", "relative_abundance_index", "index_scale", cpue[, 4L],
      "native Stock Synthesis index units (numbers)", "B17.dat, CPUE and survey block",
      "Aggregate abundance or CPUE series; not index-at-age. Fleet and survey labels retain the source model structure.",
      survey = index_names, year = as.integer(cpue[, 1L]), season = "month 7",
      sampling_time = 0.5, observation_id = index_id),
    input(assessment_2017, "index", "log_index_sd", "log_scale", cpue[, 5L],
      "log-index standard deviation", "B17.dat, CPUE logSE field",
      "Native lognormal index error scale.", survey = index_names,
      year = as.integer(cpue[, 1L]), season = "month 7", sampling_time = 0.5,
      observation_id = index_id))
  scenario_inputs <- rbind(
    input(assessment_2017, "index", "spawning_output_index", "native_scale",
      scenario_index[, 4L], "native Stock Synthesis special index unit code 30",
      "B17.dat, fleet 14 scenario index",
      "Synthetic SSB constraint (special index units code 30) is disabled in the base likelihood (lambda = 0); retained as a decision-table input only.",
      survey = fleet_names[14L], year = as.integer(scenario_index[, 1L]),
      season = "month 12.99", sampling_time = 0.999, observation_id = "ca_fleet14_scenario"),
    input(assessment_2017, "index", "log_index_sd", "log_scale",
      scenario_index[, 5L], "log-index standard deviation", "B17.dat, fleet 14 logSE field",
      "Native error scale for the disabled scenario-only SSB constraint.",
      survey = fleet_names[14L], year = as.integer(scenario_index[, 1L]),
      season = "month 12.99", sampling_time = 0.999, observation_id = "ca_fleet14_scenario"))

  composition_inputs <- list()
  add_compositions <- function(x, kind) {
    is_age <- kind == "age"
    bins <- if (is_age) 0:35 else seq(10, 52, by = 2)
    for (i in seq_len(nrow(x))) {
      r <- x[i, ]
      sfleet <- as.integer(r[3L])
      code <- as.integer(r[4L])
      source_year <- as.integer(r[1L])
      age_conditional <- is_age && !(r[7L] == -1L && r[8L] == -1L)
      measure <- if (age_conditional) "conditional_frequency_at_age" else
        if (is_age) "frequency_at_age" else "frequency_at_length"
      obs_id <- paste0("ca_", kind, "_", sprintf("%03d", i), "_fleet", sfleet,
        "_year", source_year, "_sex", code)
      sex_codes <- if (code == 0L) 0L else if (code == 3L) c(1L, 2L) else
        stop("Unexpected California composition sex code.")
      for (sex_code in sex_codes) {
        sex <- if (sex_code == 0L) "combined" else if (sex_code == 1L) "female" else "male"
        cols <- if (sex_code %in% c(0L, 1L)) { if (is_age) 10:45 else 7:28 } else {
          if (is_age) 46:81 else 29:50
        }
        values <- as.numeric(r[cols])
        notes <- if (is_age) {
          paste0(if (age_conditional) "Conditional age-at-length source frequencies; " else
            "Marginal age-composition source frequencies; ",
            "counts are not annual catch-at-age or survey index-at-age. Sample size is the separate Nfish field; age 35 is the accumulator. ",
            if (sfleet < 0L) "Negative fleet code marks a marginal diagnostic row excluded from the likelihood. " else "",
            "Source signed year/fleet and sex code are retained in observation_id; month 7, sampling time 0.5.")
        } else {
          paste0("Native length-frequency cells, not normalized; sample size is the separate Ntrips field. Length labels are lower bin edges in cm. ",
            if (sfleet %in% 12:13) "Research biological sample. " else "Fleet-linked length composition. ",
            "Source sex code and signed year are retained in observation_id; month 7, sampling time 0.5.")
        }
        type <- if (age_conditional) "biology" else
          if (abs(sfleet) <= 8L) "catch" else if (abs(sfleet) <= 11L) "index" else "biology"
        composition_inputs[[length(composition_inputs) + 1L]] <<- input(
          assessment_2017, type, measure, "native_frequency", values, "source frequency",
          paste0("B17.dat, ", kind, " composition block"), notes,
          fleet = fleet_names[abs(sfleet)], sex = sex, year = abs(source_year),
          season = "month 7", sampling_time = 0.5, observation_id = obs_id,
          age = if (is_age) bins else NA_integer_,
          length_bin = if (!is_age) bins else NA_real_,
          length_bin_lower = if (age_conditional) as.numeric(r[7L]) else NA_real_,
          length_bin_upper = if (age_conditional) as.numeric(r[8L]) else NA_real_,
          sample_size = as.numeric(r[if (is_age) 9L else 6L]),
          age_error_code = if (is_age) as.integer(r[6L]) else NA_integer_,
          partition = as.character(as.integer(r[5L])))
      }
    }
  }
  add_compositions(length_comp, "length")
  add_compositions(age_comp, "age")
  composition_inputs <- do.call(rbind, composition_inputs)
  age_error_inputs <- do.call(rbind, lapply(age_error, function(x) rbind(
    input(assessment_2017, "biology", "age_error_mean_age", "native_scale", x$mean,
      "years", "B17.dat, AgeErr definition", paste0("Mean observed age by true age; definition ", x$id, "."),
      age = 0:35, age_error_code = x$id),
    input(assessment_2017, "biology", "ageing_error_sd", "age_error_sd", x$sd,
      "years", "B17.dat, AgeErr definition", paste0("Observed-age SD by true age; definition ", x$id, "."),
      age = 0:35, age_error_code = x$id))))
  inputs_2017 <- rbind(catch_inputs, index_inputs, scenario_inputs,
    composition_inputs, age_error_inputs)

  years_table55 <- as.integer(table55_rows[, 1L])
  t55 <- table55_rows[, -1L, drop = FALSE]
  older <- which(years_table55 < 2005L)
  es_years <- years_recent
  scenario <- ifelse(es_years == 2017L, "2017 estimate beyond native input terminal year 2016", "")
  source_2017 <- "2017 assessment report, Tables 51, 55 and ES19"
  table55_measure <- function(column, type, measure, unit, notes) {
    output(assessment_2017, type, measure, years_table55[older], t55[older, column],
      unit, "2017 assessment report, Table 55", notes)
  }
  outputs_2017 <- rbind(
    table55_measure(1L, "biomass", "total_biomass", "metric tonnes", "Reported age-0+ total biomass."),
    table55_measure(2L, "biomass", "SSB", "million eggs", "Egg-based spawning output; not mass-based spawning biomass."),
    table55_measure(3L, "biomass", "spawning_output_ratio_to_unfished", "ratio", "Reported depletion, spawning output relative to unfished output."),
    output(assessment_2017, "recruitment", "age0_recruitment", years_table55,
      t55[, 4L], "thousand fish", "2017 assessment report, Table 55",
      "Native Table 55 column labelled Age-0 Recruits. Values differ materially from the separate Recruitment series in Table ES19; both source series are retained."),
    table55_measure(5L, "catch", "catch_biomass", "metric tonnes", "Reported total catch; older years use Table 55 rounded values."),
    table55_measure(6L, "mortality", "exploitation_rate", "ratio", "Reported relative exploitation rate; not instantaneous F."),
    output(assessment_2017, "mortality", "spawning_potential_ratio", years_table55,
      t55[, 7L], "ratio", "2017 assessment report, Table 55", "Reported SPR; not F-at-age."),
    output(assessment_2017, "biomass", "total_biomass", es_years, biomass,
      "metric tonnes", source_2017, "Reported age-0+ total biomass.", scenario = scenario),
    output(assessment_2017, "biomass", "SSB", es_years, spawning,
      "million eggs", source_2017, "Egg-based spawning output; approximate 95% asymptotic intervals; not mass-based SSB.",
      scenario = scenario, lwr = spawning_ci[, 1L], upr = spawning_ci[, 2L]),
    output(assessment_2017, "biomass", "spawning_output_ratio_to_unfished", es_years,
      depletion / 100, "ratio", source_2017,
      "Reported depletion, spawning output relative to unfished output; approximate 95% asymptotic intervals.",
      scenario = scenario, lwr = depletion_ci[, 1L] / 100, upr = depletion_ci[, 2L] / 100),
    output(assessment_2017, "recruitment", "recruitment", es_years, recruitment,
      "thousand fish", source_2017, "Age-0 recruits; approximate 95% asymptotic intervals.",
      age = 0L, scenario = scenario, lwr = recruitment_ci[, 1L], upr = recruitment_ci[, 2L]),
    output(assessment_2017, "catch", "catch_biomass", 2005:2016, removals,
      "metric tonnes", "2017 assessment report, Table ES19", "Reported total removals; replaces Table 55 rounded values for these years."),
    output(assessment_2017, "catch", "landings_biomass", 2005:2016, landings,
      "metric tonnes", "2017 assessment report, Table ES19", "Reported total landings."),
    output(assessment_2017, "mortality", "spr_ratio_to_spr50", 2005:2016, spr50,
      "ratio", "2017 assessment report, Table ES19", "Source-defined (1-SPR)/(1-SPR50%) ratio; not F or F-at-age."),
    output(assessment_2017, "mortality", "exploitation_rate", 2005:2016, exploitation,
      "ratio", "2017 assessment report, Table ES19", "Reported exploitation rate; not instantaneous F."))

  update_fleets <- c("Recreational charter", "Recreational private", "Recreational discards",
    "Commercial discards", "Commercial hook and line", "Commercial other gear")
  update_inputs <- input(assessment_2019, "catch", "catch_biomass", "biomass",
    as.vector(t(update_table_a[, 2:7, drop = FALSE])), "metric tonnes",
    "2019 catch update report, Table a", "Annual total removals by source. 2017 and 2018 values were fixed by PFMC GMT; these are not age-specific catches.",
    fleet = rep(update_fleets, each = nrow(update_table_a)),
    year = rep(as.integer(update_table_a[, 1L]), times = length(update_fleets)),
    season = "annual", observation_id = paste0("ca2019_", rep(update_fleets,
      each = nrow(update_table_a)), "_y", rep(as.integer(update_table_a[, 1L]),
      times = length(update_fleets))))
  update_outputs <- rbind(
    output(assessment_2019, "biomass", "SSB", update_table_b[, 1L], update_table_b[, 2L],
      "million eggs", "2019 catch update report, Table b", "Updated egg-based spawning output; approximate 95% confidence intervals.",
      lwr = update_table_b[, 3L], upr = update_table_b[, 4L]),
    output(assessment_2019, "biomass", "spawning_output_ratio_to_unfished",
      update_table_b[, 1L], update_table_b[, 5L], "ratio", "2019 catch update report, Table b",
      "Updated depletion; approximate 95% confidence intervals.",
      lwr = update_table_b[, 6L], upr = update_table_b[, 7L]),
    output(assessment_2019, "recruitment", "recruitment", update_table_c[, 1L],
      update_table_c[, 2L], "thousand fish", "2019 catch update report, Table c",
      "Age-0 recruitment; approximate 95% confidence intervals. Recruitment deviations for 2017-2019 were fixed at zero.",
      age = 0L, lwr = update_table_c[, 3L], upr = update_table_c[, 4L]),
    output(assessment_2019, "mortality", "spr_ratio_to_target", update_table_d[, 1L],
      update_table_d[, 2L], "ratio", "2019 catch update report, Table d",
      "Source-defined (1-SPR)/(1-SPR target) ratio; not the 2017 SPR50 ratio or F-at-age.",
      lwr = update_table_d[, 3L], upr = update_table_d[, 4L]),
    output(assessment_2019, "mortality", "exploitation_rate", update_table_d[, 1L],
      update_table_d[, 5L], "ratio", "2019 catch update report, Table d",
      "Summary exploitation rate for all-age biomass; not instantaneous F; approximate 95% confidence intervals.",
      lwr = update_table_d[, 6L], upr = update_table_d[, 7L]))

  if (any(fleet_def[1:8, 4L] != 1L) || any(fleet_def[9:14, 4L] != 2L)) {
    stop("Unexpected California catch and index fleet units.")
  }

  parameters <- parse_table(report, "^Table 51: Description of parameters used in the California base case",
    "^Table 52", "California Table 51")
  parameter_estimate <- function(pattern, label) {
    i <- grep(pattern, parameters, perl = TRUE)
    if (length(i) != 1L) stop("Cannot identify Table 51 parameter: ", label)
    z <- text_numbers(parameters[i])
    if (length(z) < 2L) stop("Missing Table 51 estimate and SE for ", label)
    tail(z, 2L)
  }
  m_female <- parameter_estimate("Natural mortality \\(M.*female", "female natural mortality")
  m_male_offset <- parameter_estimate("Natural mortality \\(M.*male \\(offset\\)", "male natural mortality offset")
  index_sd <- list(
    c("MRFSS CPFV dockside", parameter_estimate("Extra SD - MRFSS CPFV dockside", "MRFSS CPFV SD")),
    c("CRFS private dockside", parameter_estimate("Extra SD - CRFS private dockside", "CRFS SD")),
    c("onboard CPFV 1988-1998", parameter_estimate("Extra SD - onboard CPFV 1988-1998", "onboard CPFV 1988-1998 SD")),
    c("SWFSC juvenile survey", parameter_estimate("Extra SD - SWFSC juv\\. survey", "SWFSC juvenile SD")),
    c("onboard CPFV 2001-2016", parameter_estimate("Extra SD - onboard CPFV 2001-2016", "onboard CPFV 2001-2016 SD")))
  parameter_outputs <- rbind(
    output(assessment_2017, "parameter", "natural_mortality_parameter", value = m_female[1L],
      unit = "per year", source_reference = "2017 assessment report, Table 51",
      notes = "Estimated age-invariant female M; reported parameter SE.",
      sex = "female", se = m_female[2L]),
    output(assessment_2017, "parameter", "log_male_natural_mortality_offset", value = m_male_offset[1L],
      unit = "log ratio", source_reference = "2017 assessment report, Table 51",
      notes = "Estimated male offset on log M; this SE is for the offset parameter, not a derived male-M SE.",
      sex = "male", se = m_male_offset[2L]),
    do.call(rbind, lapply(index_sd, function(x) output(assessment_2017,
      "parameter", "extra_log_index_sd", value = as.numeric(x[2L]),
      unit = "log-index SD", source_reference = "2017 assessment report, Table 51",
      notes = "Estimated extra index SD and its reported SE.", survey = x[1L],
      se = as.numeric(x[3L])))))
  outputs_2017 <- rbind(outputs_2017, parameter_outputs)

  assumptions_2017 <- rbind(
    assumption(assessment_2017, "assessment", "model_dimensions",
      "One California assessment area; two sexes; annual model; ages 0-35 with age 35 accumulator; catch observations 1900-2016.",
      "B17.dat header; 2017 report model description",
      "Native B17.dat ends in 2016 while report time-series tables include an estimate for 2017; retained as a post-input-terminal estimate."),
    assumption(assessment_2017, "population", "assessment_unit",
      "Blue and Deacon Rockfish complex from Point Conception to the California-Oregon border.",
      "2017 report Section 1; 2019 catch update Executive Summary",
      "One stock assessment for two species; historical data do not separate species at the model scale."),
    assumption(assessment_2017, "catch", "observation_model",
      "Eight annual aggregate catch fleets; source units are biomass.",
      "B17.dat fleet and catch blocks; B17.ctl likelihood settings",
      "The source catch_se field is retained, but no catch likelihood is active; catches are treated as known."),
    assumption(assessment_2017, "index", "observation_model",
      "Five aggregate fishery-dependent or survey indices (69 observations); all source unit code 0 (numbers), month 7, lognormal errors.",
      "B17.dat CPUE block and fleet units; B17.ctl q settings",
      "Index observations are not age-specific. Fleet 14 is a synthetic SSB constraint disabled in the base likelihood."),
    assumption(assessment_2017, "composition", "likelihood_inputs",
      "162 length samples and 136 age samples; 126 conditional age-at-length and 10 marginal diagnostic rows.",
      "B17.dat length and age composition blocks",
      "Female/male frequency cells are preserved separately. Negative fleet codes identify marginal diagnostics excluded from the likelihood; frequencies are not converted to catch-at-age."),
    assumption(assessment_2017, "composition", "age_range",
      "Ages 0-35; age 35 is the accumulator; all age-composition observations use age-error code 1.",
      "B17.dat age-composition and age-error blocks",
      "Two age-error definitions are retained; the observed composition rows reference definition 1."),
    assumption(assessment_2017, "M", "natural_mortality",
      "Age-invariant female M estimated; male M estimated as a log offset from female M.",
      "2017 report Table 51; B17.ctl mortality parameterization",
      "Table 51 parameter estimates and native-scale standard errors are stored in outputs; no M-at-age or annual M surface is reported."),
    assumption(assessment_2017, "biology", "growth_weight_maturity",
      "Sex-specific growth and length-weight relationships generate weight-at-age; female maturity and fecundity are length-based.",
      "B17.ctl; 2017 report biological methods",
      "No annual weight-at-age or numeric maturity-at-age series is tabulated; do not infer those surfaces from fitted growth parameters."),
    assumption(assessment_2017, "outputs", "uncertainty",
      "Approximate 95% asymptotic intervals are available for SSB, recruitment, and depletion in 2005-2017.",
      "2017 assessment report, Table ES19",
      "No N-at-age, F-at-age or output standard errors beyond the reported intervals were located; no Report.sso is in the public archive."),
    assumption(assessment_2019, "assessment", "update_method",
      "2019 catch update based on the 2017 California base assessment; no new model fit archive located.",
      "2019 catch update report, Sections Data and Assessment; NOAA 2026 Q3 stock status table",
      "Inputs and outputs for this update are kept separate from the 2017 benchmark. Latest official catch-update output located; 2026 status table still lists the stock while 2026 PFMC prioritization notes a 2025 FMP boundary change."),
    assumption(assessment_2019, "catch", "update_inputs",
      "Fleet-resolved removals for 2010-2018; 2017 and 2018 values were fixed by PFMC GMT.",
      "2019 catch update report, Table a",
      "The report's 2019 scenario removals are not imported as observed catch."),
    assumption(assessment_2019, "recruitment", "recent_deviations",
      "Recruitment deviations for 2017-2019 were fixed at zero.",
      "2019 catch update report, Table c",
      "The reported 2017-2019 recruitment estimates follow the stock-recruitment curve."))

  stocks_db <- read.csv(file.path(root, "database/stocks.csv"), colClasses = "character",
    stringsAsFactors = FALSE, check.names = FALSE)
  assessments_db <- read.csv(file.path(root, "database/assessments.csv"), colClasses = "character",
    stringsAsFactors = FALSE, check.names = FALSE)
  candidate_path <- file.path(root, "discovery/candidates.csv")
  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  split_ids <- strsplit(as.character(inventory$candidate_ids), " | ", fixed = TRUE)
  inventory_row <- which(vapply(split_ids, function(x) candidate_id %in% x, logical(1L)))
  if (length(candidate_row) != 1L || length(inventory_row) != 1L ||
      candidates$eligibility[candidate_row] != "eligible" ||
      !candidates$import_status[candidate_row] %in% c("not_started", "partial") ||
      any(stocks_db$stock_id == stock_id) ||
      any(assessments_db$assessment_id %in% c(assessment_2017, assessment_2019))) {
    stop("Candidate registers or canonical records no longer match the California import.")
  }

  report_url <- "https://www.pcouncil.org/documents/2018/01/the-combined-status-of-blue-and-deacon-rockfishes-in-u-s-waters-off-california-and-oregon-in-2017.pdf/"
  model_url <- "https://www.pcouncil.org/documents/2017-blue-and-deacon-rockfishes-california-model-files-1-zip-file-2-mb/"
  star_url <- "https://www.pcouncil.org/documents/2017-star-panel-report-for-blue-deacon-rockfish.pdf/"
  update_url <- "https://www.pcouncil.org/documents/2019/09/agenda-item-h-5-supplemental-revised-attachment-17.pdf/"
  status_url <- "https://www.fisheries.noaa.gov/s3/2026-11/final-q3-2026-stock-status-tables-updated-11-02-26.pdf"
  priority_url <- "https://www.pcouncil.org/documents/2026/02/d-8-attachment-1-groundfish-stock-assessment-prioritization-to-inform-the-selection-of-species-for-assessment-in-2027.pdf/"
  stock <- db_row("stocks", stock_id = stock_id, charbonneau_id = "",
    authority = "NOAA-SWFSC", authority_stock_id = "14821",
    scientific_name = "Sebastes mystinus; Sebastes diaconus",
    common_name = "Blue and Deacon Rockfish Complex (California)",
    area = "Point Conception to the California-Oregon border", region = region,
    ocean = "Northeast Pacific",
    notes = "NOAA:14821 California unit, assessed jointly as Blue and Deacon Rockfish. The 2026 NOAA status table lists this unit; PFMC 2026 assessment-prioritization material notes a 2025 federal FMP boundary change, so management status should be revisited when newer assessment evidence appears.")
  assessment_rows <- rbind(
    db_row("assessments", assessment_id = assessment_2017, stock_id = stock_id,
      assessment_year = 2017L, terminal_year = 2016L, estimate_terminal_year = 2017L,
      assessment_type = "benchmark", model_family = "Stock Synthesis", model_version = "3.30.03.07",
      is_current = FALSE, is_applied = TRUE, framework_year = 2017L,
      assessment_url = report_url, framework_url = star_url, data_url = model_url,
      model_url = model_url, repository_url = "",
      assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
      notes = "Detailed 2017 California base assessment. Native input file ends at 2016; report outputs extend through 2017. The 2019 catch update is represented as a separate current event."),
    db_row("assessments", assessment_id = assessment_2019, stock_id = stock_id,
      assessment_year = 2019L, terminal_year = 2018L, estimate_terminal_year = 2019L,
      assessment_type = "catch_only_update", model_family = "Stock Synthesis",
      model_version = "2017 base model 3.30.03.07, catch update",
      is_current = TRUE, is_applied = TRUE, framework_year = 2017L,
      assessment_url = update_url, framework_url = star_url, data_url = update_url,
      model_url = model_url, repository_url = "",
      assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
      notes = "Official 2019 catch update based on the 2017 base assessment; no updated native run archive located. Tables a-d provide catch removals and updated aggregate outputs through 2019. The current stock-status listing and 2025 management boundary change are documented in the source review."))
  if (any(!is.finite(inputs_2017$value)) || any(!is.finite(update_inputs$value)) ||
      any(!is.finite(outputs_2017$value)) || any(!is.finite(update_outputs$value))) {
    stop("Non-finite source value in the California import.")
  }
  records <- list(stocks = stock, assessments = assessment_rows,
    assumptions = assumptions_2017, inputs = rbind(inputs_2017, update_inputs),
    outputs = rbind(outputs_2017, update_outputs))
  cat("Prepared", nrow(records$inputs), "inputs,", nrow(records$assumptions),
    "assumptions, and", nrow(records$outputs), "outputs across two California assessment events.\n")
  cat("Import remains partial: no catch-at-age, age-specific survey index, numeric weight/maturity-at-age, or fitted N/F-at-age surfaces were located.\n")

  if (write) {
    source(file.path(root, "scripts/database/candidate_register_io.R"), local = environment())
    for (table in names(records)) {
      utils::write.table(records[[table]], file.path(root, "database", paste0(table, ".csv")),
        sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, na = "")
    }
    candidate <- candidates[candidate_row, , drop = FALSE]
    candidate$candidate_unit_id <- stock_id
    candidate$matched_stock_id <- stock_id
    candidate$match_status <- "matched"
    candidate$import_status <- "partial"
    candidate$stock_name <- "California Blue and Deacon Rockfish Complex"
    candidate$inventory_assessment_year <- "2019"
    candidate$assessment_area <- "Point Conception to the California-Oregon border"
    candidate$catch_age_evidence <- "2017 B17.dat provides aggregate fleet catches plus age-composition samples; no catch-at-age series. 2019 Table a adds removals by source through 2018."
    candidate$survey_age_evidence <- "Five aggregate index series (69 observations) and age/length samples are present; the indices are not age-specific."
    candidate$weights_evidence <- "Model uses fitted growth and length-weight relationships; no numerical weight-at-age input surface is tabulated."
    candidate$maturity_evidence <- "Female maturity and fecundity are length-based; no numeric maturity-at-age surface is tabulated."
    candidate$mortality_evidence <- "2017 Table 51 reports estimated female M and a male log-M offset; model M is age-invariant."
    candidate$timing_evidence <- "Annual model; fitted index and composition observations use month 7 (sampling time 0.5)."
    candidate$output_evidence <- "2017 Tables 55/ES19 and 2019 Tables b-d report biomass, egg-based spawning output, recruitment and exploitation; no N-at-age/F-at-age."
    candidate$detailed_source_url <- paste(report_url, model_url, star_url, update_url,
      status_url, priority_url, sep = "; ")
    candidate$review_date <- "2026-11-13"
    candidate$decision_reason <- "Latest detailed production fit is the 2017 California base assessment; the latest reported update is the 2019 catch update. Both are imported as separate events; source completeness remains partial."
    candidate$notes <- "California and Oregon are separate assessment units. The 2019 catch update uses the 2017 base model and has no updated native run archive. NOAA still lists the California unit in 2026 status tables; PFMC 2026 materials note a 2025 management boundary change."
    unit <- inventory[inventory_row, , drop = FALSE]
    unit$matched_stock_id <- stock_id
    unit$candidate_unit_id <- stock_id
    unit$match_status <- "matched"
    unit$import_status <- "partial"
    replace_candidate_register_row(candidate_path, candidate_row, candidate, candidate_id)
    replace_csv_register_row(inventory_path, inventory_row, unit, "unit_key", inventory$unit_key[inventory_row])
    old <- getwd()
    on.exit(setwd(old), add = TRUE)
    setwd(root)
    source("scripts/database/002_validate_database.R", local = new.env(parent = globalenv()))
    cat("California Blue/Deacon source import appended; database validation passed.\n")
  }
  invisible(records)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  import_noaa_blue_deacon_california_2017(write = "--write" %in% args)
}
