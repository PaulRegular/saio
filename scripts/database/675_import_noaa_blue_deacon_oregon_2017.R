import_noaa_blue_deacon_oregon_2017 <- function(root = ".", write = FALSE) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  assessment_id <- "noaa_blue_deacon_oregon_2017"
  stock_id <- "noaa_blue_deacon_oregon"
  candidate_id <- "NOAA:14822"
  region <- "Oregon"
  cache <- file.path(root, "source_cache/discovery_noaa_blue_deacon_2017")
  manifest <- read.csv(file.path(root, "provenance/discovery_noaa_blue_deacon_2017/sources.csv"),
    colClasses = "character", stringsAsFactors = FALSE, check.names = FALSE)
  report_url <- "https://www.pcouncil.org/documents/2018/01/the-combined-status-of-blue-and-deacon-rockfishes-in-u-s-waters-off-california-and-oregon-in-2017.pdf/"
  model_url <- "https://www.pcouncil.org/documents/2017-blue-and-deacon-rockfishes-oregon-model-files-2-zip-file-2-mb/"
  star_url <- "https://www.pcouncil.org/documents/2017-star-panel-report-for-blue-deacon-rockfish.pdf/"
  status_url <- "https://www.fisheries.noaa.gov/s3/2026-11/final-q3-2026-stock-status-tables-updated-11-02-26.pdf"
  pfmc_status_url <- "https://www.pcouncil.org/documents/2026/02/d-8-attachment-1-groundfish-stock-assessment-prioritization-to-inform-the-selection-of-species-for-assessment-in-2027.pdf/"
  source_files <- c("assessment_2017.pdf", "assessment_2017.txt",
    "model_files_oregon_2017.zip", "star_panel_2017.pdf")
  if (!all(c("local_file", "source_url", "retrieved_on", "sha256", "bytes") %in% names(manifest)) ||
      !setequal(manifest$local_file, source_files) || anyDuplicated(manifest$local_file) ||
      any(manifest$retrieved_on != "2026-11-13")) {
    stop("The pinned Oregon Blue/Deacon source manifest is incomplete.", call. = FALSE)
  }
  for (file in source_files) {
    row <- manifest[manifest$local_file == file, , drop = FALSE]
    path <- file.path(cache, file)
    if (nrow(row) != 1L || !file.exists(path) ||
        as.numeric(row$bytes) != file.info(path)$size ||
        !identical(tolower(row$sha256), tolower(unname(tools::sha256sum(path))))) {
      stop("Cached Oregon Blue/Deacon source differs from manifest: ", file, call. = FALSE)
    }
  }
  dat <- readLines(file.path(cache, "or/BDR OR SS files/B17.dat"), warn = FALSE)
  ctl <- readLines(file.path(cache, "or/BDR OR SS files/B17.ctl"), warn = FALSE)
  report <- readLines(file.path(cache, "assessment_2017.txt"), warn = FALSE, encoding = "UTF-8")

  numbers <- function(x) {
    x <- trimws(sub("#.*$", "", x))
    if (!nzchar(x)) return(numeric())
    fields <- strsplit(x, "[[:space:]]+")[[1L]]
    numeric_fields <- !is.na(suppressWarnings(as.numeric(fields)))
    first_text <- which(!numeric_fields)
    if (length(first_text)) fields <- fields[seq_len(first_text[1L] - 1L)]
    if (!length(fields)) numeric() else as.numeric(fields)
  }
  parse_block <- function(lines, start_pattern, end_pattern, width, label) {
    a <- grep(start_pattern, lines, perl = TRUE)
    b <- grep(end_pattern, lines, perl = TRUE)
    if (length(a) != 1L || length(b) != 1L || a >= b) stop("Cannot locate ", label, ".")
    rows <- lapply(lines[seq.int(a + 1L, b - 1L)], numbers)
    rows <- rows[lengths(rows) == width]
    if (!length(rows)) stop("No native rows in ", label, ".")
    do.call(rbind, rows)
  }
  catch_all <- parse_block(dat, "^#year[[:space:]]+season[[:space:]]+fleet[[:space:]]+catch",
    "^#_CPUE_and_surveyabundance_observations", 5L, "catch block")
  catches <- catch_all[catch_all[, 1L] >= 1892 & catch_all[, 1L] <= 2016 &
    catch_all[, 3L] %in% 1:5, , drop = FALSE]
  cpue_all <- parse_block(dat, "^#_CPUE_and_surveyabundance_observations",
    "^# set up population length bin structure", 5L, "CPUE block")
  cpue <- cpue_all[cpue_all[, 1L] >= 1980 & cpue_all[, 1L] <= 2016 &
    cpue_all[, 3L] %in% 6:9, , drop = FALSE]
  length_comp <- parse_block(dat, "^# Commercial landings length comps",
    "^# NEXT LINE SIGNALS END OF LENGTH COMPOSITION DATA", 50L, "length compositions")
  age_comp <- parse_block(dat, "^# NEXT LINE SIGNALS END OF LENGTH COMPOSITION DATA",
    "^#End of age comp data", 81L, "age compositions")
  fleet_names <- c("Commercial landings", "Commercial discards",
    "Recreational ocean-boat landings", "Recreational ocean-boat discards",
    "Recreational shore landings", "Commercial logbook CPUE",
    "Onboard observer recreational CPUE", "ORBS dockside recreational CPUE",
    "MRFSS dockside recreational CPUE", "ODFW research age collection")
  fleet_heading <- grep("^#_fleet_type, timing, area, units", dat, perl = TRUE)
  cpue_heading <- grep("^#_Fleet Units Errtype SD_report", dat, perl = TRUE)
  cpue_start <- grep("^# Commercial Logbook[[:space:]]+CPUE", dat, perl = TRUE)
  fleet_def <- do.call(rbind, lapply(dat[seq.int(fleet_heading + 1L, length.out = 10L)], numbers))
  cpue_info <- lapply(dat[seq.int(cpue_heading + 1L, cpue_start - 1L)], numbers)
  cpue_info <- do.call(rbind, Filter(function(x) length(x) == 4L, cpue_info))
  cpue_info <- cpue_info[cpue_info[, 1L] %in% 6:9, , drop = FALSE]
  if (nrow(catches) != 625L || anyDuplicated(catches[, c(1L, 3L)]) ||
      !all(vapply(1:5, function(f) sum(catches[, 3L] == f) == 125L, logical(1L))) ||
      sum(catches[, 5L] == 0L) != 146L ||
      nrow(cpue) != 60L || !all(cpue[, 2L] == 7L) ||
      !identical(as.integer(cpue_info[, 1L]), 6:9) ||
      !identical(as.integer(cpue_info[, 2L]), c(1L, 0L, 0L, 0L)) ||
      any(cpue_info[, 3L] != 0L) || nrow(length_comp) != 101L ||
      !identical(sort(unique(as.integer(length_comp[, 4L]))), c(0L, 3L)) ||
      sum(length_comp[, 4L] == 0L) != 83L || sum(length_comp[, 4L] == 3L) != 18L ||
      nrow(age_comp) != 418L ||
      !identical(as.integer(table(factor(age_comp[, 4L], levels = 0:2))), c(41L,219L,158L)) ||
      sum(age_comp[, 7L] == -1L & age_comp[, 8L] == -1L) != 47L ||
      sum(age_comp[, 7L] >= 0L & age_comp[, 8L] >= age_comp[, 7L]) != 371L ||
      !identical(as.integer(table(factor(age_comp[, 3L],
        levels = c(-10L,-3L,-1L,1L,3L,10L)))), c(3L,26L,18L,138L,213L,20L)) ||
      !all(age_comp[, 6L] %in% 1:2) || !all(length_comp[, 5L] == 2L) ||
      !all(age_comp[, 5L] == 2L) || any(!is.finite(catches)) ||
      any(!is.finite(cpue)) || any(!is.finite(length_comp)) ||
      any(!is.finite(age_comp)) || any(length_comp[, 7:50] < 0) ||
      any(age_comp[, 10:81] < 0) || nrow(fleet_def) != 10L ||
      any(fleet_def[1:5, 4L] != 1L)) {
    stop("Native model inputs differ from the reviewed Oregon assessment.")
  }
  vector_after <- function(pattern, label) {
    i <- grep(pattern, dat, perl = TRUE)
    if (length(i) != 1L) stop("Missing age-error vector label: ", label)
    value <- numbers(dat[i + 1L])
    if (length(value) != 36L) stop("Could not parse age-error vector: ", label)
    value
  }
  age_error <- list(
    list(id = 1L, mean = vector_after("^# First VECTOR OF MEAN OBSERVED AGE", "definition 1 mean"),
      sd = vector_after("^# First VECTOR OF STANDARD DEVIATION OF OBSERVED AGE", "definition 1 SD")),
    list(id = 2L, mean = vector_after("^# Second VECTOR OF MEAN OBSERVED AGE", "definition 2 mean"),
      sd = vector_after("^# Second VECTOR OF STANDARD DEVIATION OF OBSERVED AGE", "definition 2 SD"))
  )
  control_parameter <- function(name) {
    i <- grep(paste0("#.*", name, "[[:space:]]*$"), ctl, perl = TRUE)
    if (length(i) != 1L) stop("Missing unique control parameter: ", name)
    numbers(ctl[i])
  }
  female_m <- control_parameter("NatM_p_1_Fem_GP_1")
  male_m <- control_parameter("NatM_p_1_Mal_GP_1")
  mat50 <- control_parameter("Mat50%_Fem")
  mat_slope <- control_parameter("Mat_slope_Fem")
  if (length(female_m) < 7L || length(male_m) < 7L ||
      abs(female_m[3L] - 0.1588) > 1e-8 || female_m[7L] != -2L ||
      abs(male_m[3L] - 0.159) > 1e-8 || male_m[7L] != -2L ||
      abs(mat50[3L] - 28.8) > 1e-8 || abs(mat_slope[3L] + 0.98) > 1e-8) {
    stop("The base biology in B17.ctl differs from the reviewed model.")
  }

  table_start <- grep("^Table ES20\\. Summary of base case model results for BDR in Oregon waters",
    report, perl = TRUE)
  if (length(table_start) != 1L) stop("Could not identify Oregon Table ES20.")
  table_lines <- report[seq.int(table_start, min(length(report), table_start + 30L))]
  parse_values <- function(x) {
    hits <- regmatches(x, gregexpr("(?<![[:alnum:]])[0-9]+(?:,[0-9]{3})*(?:\\.[0-9]+)?",
      x, perl = TRUE))[[1L]]
    if (identical(hits, character(0))) return(numeric())
    as.numeric(gsub(",", "", hits, fixed = TRUE))
  }
  table_row <- function(pattern, label) {
    i <- grep(pattern, table_lines, perl = TRUE)
    if (length(i) != 1L) stop("Could not identify Table ES20 row: ", label)
    list(index = i, values = parse_values(sub(pattern, "", table_lines[i], perl = TRUE)))
  }
  table_interval <- function(row, label) {
    line <- table_lines[row$index + 1L]
    if (!grepl("^\\s*~95% CI", line, perl = TRUE)) stop("Missing CI row for ", label)
    line <- gsub("<U+2013>", "-", line, fixed = TRUE)
    line <- gsub("–", "-", line, fixed = TRUE)
    # The text extraction merged the adjacent 2006 upper and 2007 lower bounds.
    line <- sub("172-792483-1,903", "172-792 483-1,903", line, fixed = TRUE)
    ranges <- regmatches(line, gregexpr(
      "[0-9][0-9,]*(?:\\.[0-9]+)?-[0-9][0-9,]*(?:\\.[0-9]+)?",
      line, perl = TRUE))[[1L]]
    if (length(ranges) != 13L) stop("Unexpected CI count for ", label,
      ": ", length(ranges), " ranges in ", line)
    bounds <- do.call(rbind, strsplit(ranges, "-", fixed = TRUE))
    bounds <- matrix(as.numeric(gsub(",", "", bounds, fixed = TRUE)), ncol = 2L)
    list(lower = bounds[, 1L], upper = bounds[, 2L])
  }
  landings <- table_row("^Total landings \\(mt\\)\\s+", "landings")
  removals <- table_row("^Total removals \\(mt\\)\\s+", "removals")
  spr <- table_row("^\\(1-SPR\\)\\s*/\\s*\\(1-SPR50%\\)\\s+", "relative SPR intensity")
  exploitation <- table_row("^Exploitation rate\\s+", "exploitation rate")
  biomass <- table_row("^Age 0\\+ biomass \\(mt\\)\\s+", "age-0+ biomass")
  spawning <- table_row("^Spawning Output\\s+", "spawning output")
  recruitment <- table_row("^Recruitment \\(1,000s\\)\\s+", "recruitment")
  depletion <- table_row("^Depletion \\(%\\)\\s+", "depletion")
  if (length(landings$values) != 12L || length(removals$values) != 12L ||
      length(spr$values) != 12L || length(exploitation$values) != 12L ||
      length(biomass$values) != 13L || length(spawning$values) != 13L ||
      length(recruitment$values) != 13L || length(depletion$values) != 13L) {
    stop("Unexpected annual coverage in Table ES20.")
  }
  spawning_ci <- table_interval(spawning, "spawning output")
  recruitment_ci <- table_interval(recruitment, "recruitment")
  depletion_ci <- table_interval(depletion, "depletion")
  years <- 2005:2017
  historical_years <- 2005:2016
  scenario <- ifelse(years == 2017L, "2017 forecast", "")

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
  input <- function(type, measure, basis, value, unit, source_reference, notes,
                    fleet = "", survey = "", sex = "combined", year = NA_integer_,
                    age = NA_integer_, season = "", sampling_time = NA_real_,
                    source_type = "native_model", observation_id = "",
                    length_bin = NA_real_, length_bin_lower = NA_real_,
                    length_bin_upper = NA_real_, sample_size = NA_real_,
                    age_error_code = NA_real_, partition = "") {
    n <- max(lengths(list(type, measure, basis, value, unit, source_reference,
      notes, fleet, survey, sex, year, age, season, sampling_time, observation_id,
      length_bin, length_bin_lower, length_bin_upper, sample_size, age_error_code, partition)))
    y <- rep_len(year, n)
    db_row("inputs", n = n, assessment_id = rep(assessment_id, n),
      type = rep_len(type, n), measure = rep_len(measure, n), basis = rep_len(basis, n),
      fleet = rep_len(fleet, n), survey = rep_len(survey, n), sex = rep_len(sex, n),
      region = rep(region, n), season = rep_len(season, n), year = as.integer(y),
      year_basis = ifelse(is.na(y), "", "calendar_year"), age = as.numeric(rep_len(age, n)),
      value = as.numeric(rep_len(value, n)), unit = rep_len(unit, n),
      sampling_time = as.numeric(rep_len(sampling_time, n)),
      source_type = rep_len(source_type, n), source_reference = rep_len(source_reference, n),
      notes = rep_len(notes, n), observation_id = rep_len(observation_id, n),
      length_bin = as.numeric(rep_len(length_bin, n)),
      length_bin_lower = as.numeric(rep_len(length_bin_lower, n)),
      length_bin_upper = as.numeric(rep_len(length_bin_upper, n)),
      sample_size = as.numeric(rep_len(sample_size, n)),
      age_error = as.numeric(rep_len(age_error_code, n)), partition = rep_len(partition, n))
  }
  output <- function(type, measure, year, value, unit, source_reference, notes,
                     age = NA_integer_, scenario = "", lwr = NA_real_,
                     upr = NA_real_, source_type = "official_table") {
    n <- max(lengths(list(type, measure, year, value, unit, source_reference,
      notes, age, scenario, lwr, upr)))
    db_row("outputs", n = n, assessment_id = rep(assessment_id, n),
      type = rep_len(type, n), measure = rep_len(measure, n), region = rep(region, n),
      year = as.integer(rep_len(year, n)), age = as.numeric(rep_len(age, n)),
      scenario = rep_len(scenario, n), value = as.numeric(rep_len(value, n)),
      lwr = as.numeric(rep_len(lwr, n)), upr = as.numeric(rep_len(upr, n)),
      unit = rep_len(unit, n), source_type = rep_len(source_type, n),
      source_reference = rep_len(source_reference, n), notes = rep_len(notes, n))
  }
  assumption <- function(component, setting, value, source_reference, notes,
                         fleet = "", survey = "", sex = "") {
    n <- max(lengths(list(component, setting, value, source_reference, notes, fleet, survey, sex)))
    db_row("assumptions", n = n, assessment_id = rep(assessment_id, n),
      component = rep_len(component, n), fleet = rep_len(fleet, n),
      survey = rep_len(survey, n), sex = rep_len(sex, n), region = rep(region, n),
      setting = rep_len(setting, n), value = rep_len(value, n),
      source_reference = rep_len(source_reference, n), notes = rep_len(notes, n))
  }

  catch_obs_id <- paste0("catch_f", as.integer(catches[, 3L]), "_y", as.integer(catches[, 1L]))
  catch_inputs <- rbind(
    input("catch", "catch_biomass", "biomass", catches[, 4L], "metric tonnes",
      "B17.dat, catch block", "Native annual fleet catch; units code 1 is biomass. These are aggregate fleet totals, not catch numbers-at-age.",
      fleet = fleet_names[as.integer(catches[, 3L])], year = as.integer(catches[, 1L]),
      season = "annual", observation_id = catch_obs_id),
    input("catch", "catch_se", "log_scale", catches[, 5L],
      "native catch_se field", "B17.dat, catch_se field",
      "Native catch_se values retained exactly. The report treats catches as known and the control file has no catch likelihood; zero values are source values, not supplied observation SDs.",
      fleet = fleet_names[as.integer(catches[, 3L])], year = as.integer(catches[, 1L]),
      season = "annual", observation_id = catch_obs_id))
  index_id <- paste0("index_f", as.integer(cpue[, 3L]), "_y", as.integer(cpue[, 1L]))
  index_survey <- fleet_names[as.integer(cpue[, 3L])]
  cpue_unit <- ifelse(cpue_info[match(cpue[, 3L], cpue_info[, 1L]), 2L] == 1L,
    "relative index, source units code 1 (biomass)", "relative index, source units code 0 (numbers)")
  index_inputs <- rbind(
    input("index", "relative_abundance_index", "index_scale", cpue[, 4L], cpue_unit,
      "B17.dat, CPUE block",
      "Aggregate fishery-dependent CPUE; not an age-specific index or fishery-independent survey.",
      survey = index_survey, year = as.integer(cpue[, 1L]), season = "month 7",
      sampling_time = (cpue[, 2L] - 1) / 12, observation_id = index_id),
    input("index", "log_index_sd", "log_scale", cpue[, 5L], "log-index standard deviation",
      "B17.dat, CPUE stderr field", "Native lognormal index error scale.",
      survey = index_survey, year = as.integer(cpue[, 1L]), season = "month 7",
      sampling_time = (cpue[, 2L] - 1) / 12, observation_id = index_id))

  comp_inputs <- list()
  add_compositions <- function(x, kind) {
    is_age <- kind == "age"
    bins <- if (is_age) 0:35 else seq(10, 52, by = 2)
    for (i in seq_len(nrow(x))) {
      r <- x[i, ]
      code <- as.integer(r[4L])
      sexes <- switch(as.character(code), "0" = 0L, "1" = 1L,
        "2" = 2L, "3" = c(1L, 2L), stop("Unexpected composition sex code."))
      sfleet <- as.integer(r[3L])
      syear <- as.integer(r[1L])
      conditional <- is_age && !(r[7L] == -1L && r[8L] == -1L)
      measure <- if (conditional) "conditional_frequency_at_age" else
        if (is_age) "frequency_at_age" else "frequency_at_length"
      obs <- paste0("bdr_", kind, "_", sprintf("%03d", i),
        "_fleet", sfleet, "_year", syear, "_sex", code)
      for (sex_code in sexes) {
        sex <- if (sex_code == 0L) "combined" else if (sex_code == 1L) "female" else "male"
        cols <- if (sex_code == 2L) { if (is_age) 46:81 else 29:50 } else {
          if (is_age) 10:45 else 7:28
        }
        values <- as.numeric(r[cols])
        note <- if (is_age) {
          paste0(if (conditional) "Conditional age-at-length cells; not annual catch-at-age or index-at-age. " else "Marginal age composition. ",
            "Source frequency cells retained exactly; sample_size is the separate Nfish field. Age 35 is the accumulator. Source sex, age-error, partition and signed fleet/year codes are retained in observation_id. ",
            if (code == 0L) "Combined-sex data are in the source female vector; the male vector is not used. " else "",
            if (sfleet < 0L) "Negative fleet code is retained; Stock Synthesis computes expected values but excludes the row from total likelihood. " else "",
            if (conditional) "Conditioning length bounds are in cm. " else "",
            "Month 7; sampling time 0.5.")
        } else {
          paste0("Native length-frequency cells copied without normalization; sample_size is Ntows. Length-bin labels are lower edges in cm. Source sex code and retained partition are in observation_id. ",
            if (code == 0L) "Combined-sex data are in the source female vector; the male vector is not used. " else "",
            if (syear < 0L) "Signed source year is retained in observation_id; canonical year is absolute calendar year. " else "",
            "Month 7; sampling time 0.5.")
        }
        comp_inputs[[length(comp_inputs) + 1L]] <<- input(
          type = if (conditional || (is_age && abs(sfleet) == 10L) ||
              (!is_age && abs(sfleet) == 10L)) "biology" else "catch",
          measure = measure, basis = "native_frequency", value = values,
          unit = "source frequency", source_reference = paste0("B17.dat, ", kind, " composition block"),
          notes = note, fleet = fleet_names[abs(sfleet)], sex = sex,
          year = abs(syear), season = "month 7", sampling_time = (as.numeric(r[2L]) - 1) / 12,
          observation_id = obs, age = if (is_age) bins else NA_integer_,
          length_bin = if (!is_age) bins else NA_real_,
          length_bin_lower = if (conditional) as.numeric(r[7L]) else NA_real_,
          length_bin_upper = if (conditional) as.numeric(r[8L]) else NA_real_,
          sample_size = as.numeric(r[if (is_age) 9L else 6L]),
          age_error_code = if (is_age) as.integer(r[6L]) else NA_integer_,
          partition = "2")
      }
    }
  }
  add_compositions(length_comp, "length")
  add_compositions(age_comp, "age")
  comp_inputs <- do.call(rbind, comp_inputs)
  age_error_inputs <- do.call(rbind, lapply(age_error, function(x) rbind(
    input("biology", "age_error_mean_age", "native_scale", x$mean, "years",
      "B17.dat, AgeErr definition", paste0("Mean observed age by true age; definition ", x$id, "."),
      age = 0:35, age_error_code = x$id),
    input("biology", "ageing_error_sd", "age_error_sd", x$sd, "years",
      "B17.dat, AgeErr definition", paste0("Observed-age SD by true age; definition ", x$id, "."),
      age = 0:35, age_error_code = x$id))))
  inputs <- rbind(catch_inputs, index_inputs, comp_inputs, age_error_inputs)

  ci_source <- "assessment_2017.pdf, Table ES20"
  outputs <- rbind(
    output("catch", "landings_biomass", 2005:2016, landings$values,
      "metric tonnes", ci_source, "Official annual total landings."),
    output("catch", "catch_biomass", 2005:2016, removals$values,
      "metric tonnes", ci_source, "Official annual total removals."),
    output("mortality", "fishing_intensity_1_minus_spr", 2005:2016, spr$values,
      "ratio", ci_source, "Source-defined (1-SPR)/(1-SPR50%) ratio; not F or F-at-age."),
    output("mortality", "exploitation_rate", 2005:2016, exploitation$values,
      "ratio", ci_source, "Source-defined exploitation rate; not instantaneous F or F-at-age."),
    output("biomass", "total_biomass", years, biomass$values,
      "metric tonnes", ci_source, "Reported age-0+ biomass; 2017 is forecast beyond data year 2016.",
      scenario = scenario),
    output("biomass", "SSB", years, spawning$values, "million eggs", ci_source,
      "Egg-based spawning output, called spawning biomass in the report; not mass-based SSB. Approximate 95% asymptotic intervals.",
      scenario = scenario, lwr = spawning_ci$lower, upr = spawning_ci$upper),
    output("recruitment", "recruitment", years, recruitment$values, "thousand fish", ci_source,
      "Age-0 recruitment. Approximate 95% asymptotic intervals.",
      age = 0L, scenario = scenario, lwr = recruitment_ci$lower, upr = recruitment_ci$upper),
    output("biomass", "spawning_output_ratio_to_unfished", years, depletion$values,
      "percent", ci_source, "Native depletion percentage: spawning output relative to unfished spawning output.",
      scenario = scenario, lwr = depletion_ci$lower, upr = depletion_ci$upper))

  likelihood_header <- grep("^#like_comp[[:space:]]+fleet", ctl, perl = TRUE)
  likelihood_end <- grep("^[[:space:]]*-9999[[:space:]]+1[[:space:]]+1[[:space:]]+1[[:space:]]+1", ctl, perl = TRUE)
  likelihood_end <- likelihood_end[likelihood_end > likelihood_header]
  if (length(likelihood_header) != 1L || length(likelihood_end) != 1L) {
    stop("Cannot locate likelihood settings.")
  }
  likelihood_rows <- lapply(ctl[seq.int(likelihood_header + 1L, likelihood_end - 1L)], numbers)
  likelihood_rows <- do.call(rbind, Filter(function(x) length(x) == 5L, likelihood_rows))
  if (nrow(likelihood_rows) != 12L || any(likelihood_rows[, 1L] == 8L)) {
    stop("Unexpected catch-likelihood settings.")
  }
  variance_header <- grep("^[[:space:]]*#_Factor[[:space:]]+Fleet[[:space:]]+Value", ctl, perl = TRUE)
  variance_end <- grep("^[[:space:]]*-9999[[:space:]]+1[[:space:]]+0", ctl, perl = TRUE)
  variance <- lapply(ctl[seq.int(variance_header + 1L, variance_end - 1L)], numbers)
  variance <- do.call(rbind, Filter(function(x) length(x) == 3L, variance))
  if (nrow(variance) != 13L || sum(variance[, 1L] == 4L) != 10L ||
      sum(variance[, 1L] == 5L) != 3L) stop("Unexpected composition variance adjustments.")
  assumptions <- rbind(
    assumption("assessment", "model_dimensions",
      "One area, two sexes, annual time step; ages 0-35 with age 35 as accumulator; catch data 1892-2016; 2017 forecast.",
      "B17.dat header and assessment report", "2017 is beyond the data terminal year."),
    assumption("population", "assessment_unit", "Blue and Deacon Rockfish complex in Oregon coastal waters.",
      "2017 report Section 1; NOAA 2026 Q3 status table",
      "NOAA's 2026 table continues to list Oregon Blue/Deacon as a current stock."),
    assumption("catch", "observation_model", "Five annual catch fleets; native biomass units code 1.",
      "B17.dat fleet and catch blocks; B17.ctl likelihood settings",
      "Aggregate fleet totals, not catch-at-age. Native catch_se is retained; the report treats catch as known and catch likelihood is inactive."),
    assumption("index", "observation_model",
      "Four aggregate lognormal fishery-dependent CPUE series; one biomass-index code and three number-index codes.",
      "B17.dat CPUE block", "60 observations, all month 7 (sampling time 0.5); not age-specific survey indices."),
    assumption("index", "catchability", "Simple q for fleets 6-9; q floated analytically; additional index SD estimated; no bias adjustment.",
      "B17.ctl Q_setup and Q_parms", "Settings are separate for the four index fleets."),
    assumption("composition", "likelihood_inputs",
      "101 length-composition and 418 age-composition rows; 371 conditional age-at-length and 47 marginal age rows.",
      "B17.dat lencomp and agecomp blocks",
      "Native frequency cells, sample sizes, source sex codes, partitions, age-error IDs, and signed fleet/year codes are preserved. Composition observations are not catch-at-age or index-at-age."),
    assumption("composition", "likelihood_weights",
      "Variance adjustment factors 4 for length compositions and 5 for age compositions.",
      "B17.ctl input variance adjustment factors", "Native fleet-specific values are recorded below."),
    assumption("M", "natural_mortality",
      "Female M fixed at 0.1588 per year; male M is a fixed 0.159 exponential offset (about 0.186 per year).",
      "B17.ctl NatM parameters; 2017 report Section 3.4.1",
      "Report rounds base values to 0.159 and 0.186. M is age-invariant. California's 0.119 estimate is not used here."),
    assumption("biology", "growth",
      "Sex-specific von Bertalanffy growth is fitted; weight-at-age is generated from growth and weight-length relationships.",
      "B17.ctl; 2017 report Sections 3.4.2-3.4.3",
      "No empirical annual weight-at-age input vector is supplied."),
    assumption("biology", "maturity",
      "Female maturity is fixed logistic at length, L50 28.8 cm, source slope parameter -0.98.",
      "B17.ctl maturity option and parameters", "No direct maturity-at-age vector is supplied."),
    assumption("biology", "fecundity",
      "Egg production is a fixed length-based power function; spawning output is in millions of eggs.",
      "B17.ctl fecundity settings; assessment report", "Egg production differs from mass-based SSB."),
    assumption("recruitment", "stock_recruitment",
      "Beverton-Holt relationship; recruitment variability is fixed at 0.50.",
      "B17.ctl spawner-recruitment settings", "Recruitment output is age 0, in thousands of fish."),
    assumption("outputs", "uncertainty",
      "Table ES20 supplies approximate 95% intervals for spawning output, recruitment, and depletion only.",
      "2017 assessment report, Table ES20",
      "No fitted N-at-age or F-at-age surface was found; the archive has no Report.sso."),
    do.call(rbind, lapply(seq_len(nrow(variance)), function(i) assumption(
      "composition", if (variance[i, 1L] == 4L) "length_composition_variance_adjustment" else
        "age_composition_variance_adjustment",
      format(variance[i, 3L], scientific = FALSE, trim = TRUE, digits = 8),
      "B17.ctl input variance adjustment factors",
      paste("Native factor", as.integer(variance[i, 1L]), "value."),
      fleet = fleet_names[as.integer(variance[i, 2L])]))))

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
      !candidates$eligibility[candidate_row] %in% c("eligible", "screened") ||
      !candidates$import_status[candidate_row] %in% c("not_started", "partial") ||
      !inventory$import_status[inventory_row] %in% c("not_started", "partial") ||
      any(stocks_db$stock_id == stock_id) || any(assessments_db$assessment_id == assessment_id)) {
    stop("Candidate registers or canonical records no longer match this import.")
  }

  stock <- db_row("stocks", stock_id = stock_id, charbonneau_id = "",
    authority = "NOAA-NWFSC", authority_stock_id = "14822",
    scientific_name = "Sebastes mystinus; Sebastes diaconus",
    common_name = "Blue and Deacon Rockfish Complex (Oregon)",
    area = "Oregon coastal waters, U.S. West Coast", region = region,
    ocean = "Northeast Pacific",
    notes = "Current Oregon Blue/Deacon assessment unit; distinct from California. NOAA's 2026 Q3 status table continues to list the Oregon complex.")
  assessment <- db_row("assessments", assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2017L, terminal_year = 2016L, estimate_terminal_year = 2017L,
    assessment_type = "benchmark", model_family = "Stock Synthesis",
    model_version = "3.30.03.07", is_current = TRUE, is_applied = TRUE,
    framework_year = 2017L, assessment_url = report_url, framework_url = star_url,
    data_url = model_url, model_url = model_url,
    repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "Latest detailed production assessment located for the current Oregon unit. Includes aggregate catches and CPUE, length and marginal/conditional age compositions, but no direct catch-at-age or age-specific indices. Published outputs are aggregate; 2017 is forecast beyond data year 2016 and spawning output is in eggs.")
  if (any(!is.finite(inputs$value)) || any(!is.finite(outputs$value))) stop("Non-finite source value.")
  records <- list(stocks = stock, assessments = assessment, assumptions = assumptions,
    inputs = inputs, outputs = outputs)
  cat("Prepared", nrow(inputs), "inputs,", nrow(assumptions), "assumptions, and",
    nrow(outputs), "outputs for", assessment_id, ".\n")
  cat("Import remains partial: no direct catch-at-age or fitted N/F-at-age surfaces.\n")

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
    candidate$stock_name <- "Blue and Deacon Rockfish Complex (Oregon)"
    candidate$inventory_assessment_year <- 2017L
    candidate$assessment_area <- "Oregon coastal waters"
    candidate$catch_age_evidence <- "B17.dat supplies 625 aggregate annual catches and 418 age-composition rows; no annual catch-at-age series."
    candidate$survey_age_evidence <- "Four aggregate fishery-dependent CPUE series (60 observations); composition ages are not age-specific indices."
    candidate$weights_evidence <- "Sex-specific growth and weight-length model specifications; no empirical age-specific weight input vector."
    candidate$maturity_evidence <- "Fixed female logistic maturity-at-length; no direct maturity-at-age vector."
    candidate$mortality_evidence <- "Female M fixed at 0.1588; male fixed log offset 0.159 (about 0.186 per year)."
    candidate$timing_evidence <- "Annual model; all indices and compositions use month 7 (sampling time 0.5)."
    candidate$output_evidence <- "Table ES20 reports age-0+ biomass, egg-based spawning output, recruitment, depletion, exploitation and relative SPR intensity; no fitted N/F-at-age table."
    candidate$detailed_source_url <- paste(report_url, model_url, star_url, status_url, pfmc_status_url, sep = "; ")
    candidate$review_date <- "2026-11-13"
    candidate$decision_reason <- "Latest detailed production assessment located is the 2017 Oregon Stock Synthesis base model. Import is partial: aggregate catch and CPUE plus age-composition samples are available, but no direct catch-at-age or fitted N/F-at-age surfaces."
    candidate$notes <- "The 2017 estimates include a forecast year. Spawning output is egg-based. Native age compositions are not converted to catch-at-age."
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
    cat("Oregon Blue/Deacon source import appended; database validation passed.\n")
  }
  invisible(records)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  import_noaa_blue_deacon_oregon_2017(write = "--write" %in% args)
}
