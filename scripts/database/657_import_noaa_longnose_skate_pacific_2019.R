import_noaa_longnose_skate_pacific_2019 <- function(root = ".", write = FALSE) {
  assessment_id <- "noaa_pacific_coast_longnose_skate_2019"
  stock_id <- "noaa_pacific_coast_longnose_skate"
  candidate_id <- "NOAA:10731"
  cache <- file.path(root, "source_cache/discovery_noaa_longnose_skate_2019")
  manifest_path <- file.path(cache, "sources.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
    check.names = FALSE)
  sha256_file <- function(path) {
    out <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path,
      winslash = "\\", mustWork = TRUE)), "SHA256"), stdout = TRUE)
    tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      out, value = TRUE)))
  }
  verify_source <- function(file) {
    row <- manifest[manifest$file == file, , drop = FALSE]
    path <- file.path(cache, file)
    if (nrow(row) != 1L || !file.exists(path) ||
        as.numeric(row$bytes) != file.info(path)$size ||
        !identical(sha256_file(path), tolower(row$sha256))) {
      stop("Cached Longnose Skate source failed its provenance check: ",
        file, call. = FALSE)
    }
    path
  }
  report_name <- "longnose_skate_assessment_2019.pdf"
  workbook_name <- "longnose_skate_supplementary_tables_2019.xlsx"
  archive_name <- "longnose_skate_model_files_2019.zip"
  report_path <- verify_source(report_name)
  workbook_path <- verify_source(workbook_name)
  verify_source(archive_name)
  data_path <- file.path(cache, "model_files/LSKT2019_data.ss")
  control_path <- file.path(cache, "model_files/LSKT2019_control.ss")
  starter_path <- file.path(cache, "model_files/starter.ss")
  forecast_path <- file.path(cache, "model_files/forecast.ss")
  model_paths <- c(data_path, control_path, starter_path, forecast_path)
  if (any(!file.exists(model_paths))) {
    stop("The official Longnose Skate model archive is incomplete.",
      call. = FALSE)
  }

  text_path <- paste0(report_path, ".txt")
  if (!file.exists(text_path)) {
    lib <- file.path(root, "source_cache/.Rlib")
    if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
    if (!requireNamespace("pdftools", quietly = TRUE)) {
      stop("pdftools is needed to extract the cached assessment report.",
        call. = FALSE)
    }
    writeLines(pdftools::pdf_text(report_path), text_path, useBytes = TRUE)
  }
  report_lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
  data_lines <- readLines(data_path, warn = FALSE, encoding = "UTF-8")
  report_url <- manifest$url[match(report_name, manifest$file)]
  workbook_url <- manifest$url[match(workbook_name, manifest$file)]
  archive_url <- manifest$url[match(archive_name, manifest$file)]
  star_url <- manifest$url[match("longnose_skate_star_2019.pdf", manifest$file)]
  availability_url <- manifest$url[match("longnose_skate_available_data_2023.pdf",
    manifest$file)]
  ref <- function(x) paste("2019 Longnose Skate assessment,", x)

  input_path <- file.path(root, "database/inputs.csv")
  output_path <- file.path(root, "database/outputs.csv")
  assumption_path <- file.path(root, "database/assumptions.csv")
  input_fields <- names(read.csv(text = readLines(input_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  output_fields <- names(read.csv(text = readLines(output_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  assumption_fields <- names(read.csv(text = readLines(assumption_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  make_rows <- function(fields, values, n = NULL) {
    if (is.null(n)) n <- max(c(1L, lengths(values)))
    out <- lapply(fields, function(field) {
      value <- values[[field]]
      if (is.null(value)) return(rep("", n))
      if (length(value) == 1L) return(rep(value, n))
      if (length(value) != n) {
        stop("Wrong row count for database field ", field, ".", call. = FALSE)
      }
      value
    })
    names(out) <- fields
    as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
  }
  input_rows <- list()
  output_rows <- list()
  assumption_rows <- list()
  add_input <- function(values, n = NULL) {
    input_rows[[length(input_rows) + 1L]] <<- make_rows(input_fields,
      values, n)
  }
  add_output <- function(values, n = NULL) {
    output_rows[[length(output_rows) + 1L]] <<- make_rows(output_fields,
      values, n)
  }
  add_assumption <- function(component, setting, value, source_reference,
    notes = "", fleet = "", survey = "", region = "U.S. Pacific Coast") {
    assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(
      assumption_fields, list(assessment_id = assessment_id,
        component = component, setting = setting, value = value,
        source_reference = source_reference, notes = notes, fleet = fleet,
        survey = survey, region = region), 1L)
  }
  input_base <- function(type, measure, basis, value, unit, year = NA_real_,
    age = NA_real_, fleet = "", survey = "", sex = "combined",
    season = "", sampling_time = NA_real_, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_,
    length_bin_upper = NA_real_, sample_size = NA_real_, age_error = NA_real_,
    partition = "", notes = "", source_reference = "", source_type = "native_model") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      basis = basis, value = value, unit = unit, year = year,
      year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
      fleet = fleet, survey = survey, sex = sex, region = "U.S. Pacific Coast",
      season = season, sampling_time = sampling_time, source_type = source_type,
      source_reference = source_reference, notes = notes,
      observation_id = observation_id, length_bin = length_bin,
      length_bin_lower = length_bin_lower,
      length_bin_upper = length_bin_upper, sample_size = sample_size,
      age_error = age_error, partition = partition)
  }
  table_output <- function(type, measure, value, unit, year = NA_real_,
    age = NA_real_, age_group = "", scenario = "", se = NA_real_,
    lwr = NA_real_, upr = NA_real_, notes = "", source_reference = "") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      value = value, unit = unit, year = year, age = age, age_group = age_group,
      scenario = scenario, se = se, lwr = lwr, upr = upr,
      region = "U.S. Pacific Coast", sex = "combined", source_type = "official_table",
      source_reference = source_reference, notes = notes)
  }
  bind_rows <- function(x) {
    if (!length(x)) return(data.frame())
    out <- do.call(rbind, x)
    rownames(out) <- NULL
    out
  }

  numeric_tokens <- function(line) {
    line <- sub("#.*$", "", line)
    line <- trimws(line)
    if (!nzchar(line)) return(numeric())
    suppressWarnings(scan(text = line, what = numeric(), quiet = TRUE))
  }
  data_section <- function(start_pattern, end_pattern) {
    start <- grep(start_pattern, data_lines, perl = TRUE)
    end <- grep(end_pattern, data_lines, perl = TRUE)
    if (length(start) != 1L || length(end) != 1L || start >= end) {
      stop("Could not identify Stock Synthesis data section: ", start_pattern,
        call. = FALSE)
    }
    seq.int(start + 1L, end - 1L)
  }
  model_fleets <- c("Fishery current", "Historical discards",
    "Historical landings", "Tribal fishery")
  survey_names <- c("5" = "NWFSC shelf-slope survey",
    "6" = "AFSC Triennial early survey", "7" = "AFSC Slope survey",
    "8" = "NWFSC Slope survey", "9" = "IPHC index")

  catch_section <- data_section("^#_Catch data:",
    "^#_CPUE_and_surveyabundance_observations$")
  catches <- Filter(function(x) length(x) == 5L && x[1L] >= 1916 &&
    x[1L] <= 2018 && x[3L] %in% 1:4,
    lapply(data_lines[catch_section], numeric_tokens))
  catches <- do.call(rbind, catches)
  if (is.null(dim(catches)) || nrow(catches) == 0L ||
      !identical(sort(unique(as.integer(catches[, 3L]))), 1:4)) {
    stop("Unexpected Longnose Skate catch structure.", call. = FALSE)
  }
  for (fleet_id in 1:4) {
    x <- catches[catches[, 3L] == fleet_id, , drop = FALSE]
    add_input(input_base("catch", "catch_biomass", "biomass", x[, 4L],
      "metric tons", year = as.integer(x[, 1L]), fleet = model_fleets[fleet_id],
      season = as.character(as.integer(x[, 2L])),
      source_reference = ref("native Stock Synthesis data file, catch data"),
      notes = "Source-model annual removals; the initial year -999 row is a Stock Synthesis placeholder and is not a calendar observation."),
      nrow(x))
    add_input(input_base("catch", "log_catch_sd", "log_scale", x[, 5L],
      "log-scale SD", year = as.integer(x[, 1L]), fleet = model_fleets[fleet_id],
      season = as.character(as.integer(x[, 2L])),
      source_reference = ref("native Stock Synthesis data file, catch data"),
      notes = "Source-supplied standard deviation of log catch."), nrow(x))
  }

  cpue_start <- grep("^#_CPUE_and_surveyabundance_observations$",
    data_lines, perl = TRUE)
  cpue_end <- grep("^-9999[[:space:]]+1[[:space:]]+1[[:space:]]+1[[:space:]]+1",
    trimws(data_lines), perl = TRUE)
  if (length(cpue_start) != 1L || length(cpue_end) != 1L ||
      cpue_start >= cpue_end) stop("Could not identify survey index data.",
        call. = FALSE)
  index_rows <- Filter(function(x) length(x) == 5L && x[1L] >= 1916 &&
    x[1L] <= 2018 && x[3L] %in% 5:9,
    lapply(data_lines[seq.int(cpue_start + 1L, cpue_end - 1L)], numeric_tokens))
  index_rows <- do.call(rbind, index_rows)
  if (is.null(dim(index_rows)) || nrow(index_rows) == 0L ||
      !setequal(unique(as.integer(index_rows[, 3L])), 5:9)) {
    stop("Expected five aggregate Longnose Skate index series.", call. = FALSE)
  }
  for (fleet_id in 5:9) {
    x <- index_rows[index_rows[, 3L] == fleet_id, , drop = FALSE]
    unit <- if (fleet_id == 9L) "native numbers-index scale" else
      "native biomass-index scale"
    add_input(input_base("index", "relative_abundance_index", "index_scale",
      x[, 4L], unit, year = as.integer(x[, 1L]), survey = survey_names[as.character(fleet_id)],
      season = as.character(as.integer(x[, 2L])), sampling_time = 0.5,
      source_reference = ref("native Stock Synthesis data file, survey index data"),
      notes = "Aggregate annual index; not an absolute abundance series. Source month is July and fitted fleet timing is 0.5."),
      nrow(x))
    add_input(input_base("index", "log_index_sd", "log_scale", x[, 5L],
      "log-scale SD", year = as.integer(x[, 1L]),
      survey = survey_names[as.character(fleet_id)],
      season = as.character(as.integer(x[, 2L])), sampling_time = 0.5,
      source_reference = ref("native Stock Synthesis data file, survey index data"),
      notes = "Source-supplied standard error of the log index; the native model uses lognormal index errors."),
      nrow(x))
  }

  discard_start <- grep("^#_discard_units", data_lines, perl = TRUE)[1L]
  mean_weight_start <- grep("^# Mean Body Weight$", data_lines, perl = TRUE)
  if (is.na(discard_start) || length(mean_weight_start) != 1L ||
      discard_start >= mean_weight_start) stop("Could not identify discard data.",
        call. = FALSE)
  discard_rows <- Filter(function(x) length(x) == 5L && x[1L] >= 1995 &&
    x[1L] <= 2017 && x[3L] == 1,
    lapply(data_lines[seq.int(discard_start + 1L, mean_weight_start - 1L)], numeric_tokens))
  discard_rows <- do.call(rbind, discard_rows)
  if (is.null(dim(discard_rows)) || nrow(discard_rows) != 23L) {
    stop("Unexpected discard-fraction year coverage.", call. = FALSE)
  }
  for (measure in c("discard_fraction", "discard_fraction_se")) {
    value <- if (measure == "discard_fraction") discard_rows[, 4L] else discard_rows[, 5L]
    basis <- if (measure == "discard_fraction") "proportion" else "native_scale"
    add_input(input_base("catch", measure, basis, value,
      "proportion", year = as.integer(discard_rows[, 1L]),
      fleet = model_fleets[1L], season = as.character(as.integer(discard_rows[, 2L])),
      sampling_time = (discard_rows[, 2L] - 1) / 12,
      source_reference = ref("native Stock Synthesis data file, discard data"),
      notes = if (measure == "discard_fraction")
        "Discard fraction supplied on the proportion scale; source rows distinguish historical Dover-based predictions and later observer-based estimates."
      else "Source-supplied additive normal standard error for the discard fraction; not a CV."),
      nrow(discard_rows))
  }

  weight_end <- grep("^-9999[[:space:]]+0[[:space:]]+0[[:space:]]+0[[:space:]]+0[[:space:]]+0",
    trimws(data_lines), perl = TRUE)
  weight_end <- weight_end[weight_end > mean_weight_start]
  if (!length(weight_end)) stop("Could not identify mean-body-weight rows.",
    call. = FALSE)
  weight_end <- min(weight_end)
  weight_rows <- Filter(function(x) length(x) == 7L && x[1L] >= 2002 &&
    x[1L] <= 2017 && x[3L] == 1 && x[4L] == 1 && x[5L] == 2,
    lapply(data_lines[seq.int(mean_weight_start + 1L, weight_end - 1L)], numeric_tokens))
  weight_rows <- do.call(rbind, weight_rows)
  if (is.null(dim(weight_rows)) || nrow(weight_rows) != 16L) {
    stop("Unexpected mean-body-weight year coverage.", call. = FALSE)
  }
  add_input(input_base("catch_weight", "mean_body_weight", "kg_per_fish",
    weight_rows[, 6L], "kg per fish", year = as.integer(weight_rows[, 1L]),
    fleet = model_fleets[1L], season = as.character(as.integer(weight_rows[, 2L])),
    sampling_time = (weight_rows[, 2L] - 1) / 12,
    partition = as.character(as.integer(weight_rows[, 4L])),
    source_reference = ref("native Stock Synthesis data file, mean body weight"),
    notes = "Discard-partition mean body weights; source input is kilograms per fish."),
    nrow(weight_rows))
  add_input(input_base("catch_weight", "mean_body_weight_cv", "relative_scale",
    weight_rows[, 7L], "ratio", year = as.integer(weight_rows[, 1L]),
    fleet = model_fleets[1L], season = as.character(as.integer(weight_rows[, 2L])),
    sampling_time = (weight_rows[, 2L] - 1) / 12,
    partition = as.character(as.integer(weight_rows[, 4L])),
    source_reference = ref("native Stock Synthesis data file, mean body weight"),
    notes = "Source-reported coefficient of variation for discard mean body weight."),
    nrow(weight_rows))

  length_headers <- grep("^#year[[:space:]]+month[[:space:]]+fleet[[:space:]]+gender[[:space:]]+partition[[:space:]]+Nsamp",
    data_lines, perl = TRUE)
  if (length(length_headers) != 6L) {
    stop("Expected six native length-composition blocks.", call. = FALSE)
  }
  length_bins <- seq(5, 165, by = 5)
  length_record_index <- 0L
  for (h in seq_along(length_headers)) {
    start <- length_headers[h]
    next_comment <- which(seq_along(data_lines) > start &
      grepl("^[[:space:]]*#", data_lines))
    end <- if (length(next_comment)) min(next_comment[next_comment > start]) - 1L else length(data_lines)
    rows <- data_lines[seq.int(start + 1L, end)]
    for (line in rows) {
      f <- numeric_tokens(line)
      if (!length(f) || f[1L] < 1900 || f[1L] > 2018) next
      if (length(f) == 38L) {
        metadata <- f[1:5]
        sample_size <- NA_real_
        frequencies <- f[6:38]
      } else if (length(f) == 39L) {
        metadata <- f[1:5]
        sample_size <- f[6L]
        frequencies <- f[7:39]
      } else {
        stop("Unexpected length-composition row width: ", length(f), call. = FALSE)
      }
      if (length(frequencies) != length(length_bins) || anyNA(metadata) ||
          anyNA(frequencies)) stop("Invalid native length-composition row.",
            call. = FALSE)
      year <- as.integer(metadata[1L]); month <- metadata[2L]
      source_fleet_id <- as.integer(metadata[3L])
      fleet_id <- abs(source_fleet_id)
      sex_code <- as.integer(metadata[4L])
      partition <- as.integer(metadata[5L])
      is_survey <- fleet_id %in% 5:9
      series <- if (is_survey) unname(survey_names[as.character(fleet_id)]) else
        unname(model_fleets[fleet_id])
      type <- if (is_survey) "biology" else "catch"
      length_record_index <- length_record_index + 1L
      observation_id <- sprintf("longnose_length_%03d", length_record_index)
      add_input(input_base(type, "frequency_at_length", "native_frequency",
        frequencies, "source frequency weight", year = year,
        fleet = if (is_survey) "" else series,
        survey = if (is_survey) series else "",
        sex = if (sex_code == 0L) "combined" else as.character(sex_code),
        season = as.character(as.integer(month)),
        sampling_time = (month - 1) / 12, observation_id = observation_id,
        length_bin = length_bins, sample_size = sample_size,
        partition = as.character(partition),
        source_reference = ref("native Stock Synthesis data file, length-composition data"),
        notes = paste(
          "Native expanded length-frequency values retained without normalization; the source sample size is blank where not supplied.",
          if (source_fleet_id < 0L) "The source uses a negative fleet code: this composition is evaluated but excluded from the total likelihood.")),
        length(frequencies))
    }
  }

  age_header <- grep("^#year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr",
    data_lines, perl = TRUE)
  ghost_header <- grep("^# ghost marginal ages$", data_lines, perl = TRUE)
  age_header <- age_header[age_header < ghost_header]
  if (length(age_header) != 1L || length(ghost_header) != 1L) {
    stop("Could not identify conditional-age data.",
        call. = FALSE)
  }
  age_rows <- list()
  for (line in data_lines[seq.int(age_header + 1L, ghost_header - 1L)]) {
    f <- numeric_tokens(line)
    if (!length(f) || f[1L] < 1900 || f[1L] > 2018) next
    if (length(f) != 33L) stop("Unexpected conditional-age row width: ",
      length(f), call. = FALSE)
    age_rows[[length(age_rows) + 1L]] <- f
  }
  age_rows <- do.call(rbind, age_rows)
  if (is.null(dim(age_rows)) || nrow(age_rows) != 91L) {
    stop("Unexpected fishery/survey conditional-age sample coverage.", call. = FALSE)
  }
  for (i in seq_len(nrow(age_rows))) {
    x <- age_rows[i, ]
    year <- as.integer(x[1L]); month <- x[2L]
    source_fleet_id <- as.integer(x[3L])
    fleet_id <- abs(source_fleet_id)
    sex_code <- as.integer(x[4L])
    partition <- as.integer(x[5L]); age_error <- x[6L]
    lbin_hi <- x[7L]; lbin_lo <- x[8L]; sample_size <- x[9L]
    frequency <- x[10:33]
    if (sum(frequency) != sample_size) {
      stop("Conditional-age frequencies do not match sample size.", call. = FALSE)
    }
    is_survey <- fleet_id %in% 5:9
    series <- if (is_survey) unname(survey_names[as.character(fleet_id)]) else
      unname(model_fleets[fleet_id])
    observation_id <- sprintf("longnose_caal_%03d", i)
    add_input(input_base("biology", "conditional_frequency_at_age",
      "native_frequency", frequency, "fish count", year = year,
      age = 0:23, fleet = if (is_survey) "" else series,
      survey = if (is_survey) series else "",
      sex = if (sex_code == 0L) "combined" else as.character(sex_code),
      season = as.character(as.integer(month)),
      sampling_time = (month - 1) / 12, observation_id = observation_id,
      length_bin_lower = lbin_lo, length_bin_upper = lbin_hi,
      sample_size = sample_size, age_error = age_error,
      partition = as.character(partition),
      source_reference = ref("native Stock Synthesis data file, conditional age-at-length data"),
      notes = paste(
        "Native age-frequency counts conditional on Stock Synthesis length-bin bounds; counts were not converted to proportions.",
        if (source_fleet_id < 0L) "The source uses a negative fleet code: this composition is evaluated but excluded from the total likelihood.")),
      24L)
  }

  ghost_end <- grep("^-9999[[:space:]]+0[[:space:]]+0[[:space:]]+0",
    trimws(data_lines), perl = TRUE)
  ghost_end <- ghost_end[ghost_end > ghost_header]
  if (!length(ghost_end)) stop("Could not identify ghost marginal-age rows.",
    call. = FALSE)
  ghost_end <- min(ghost_end)
  ghost_rows <- list()
  for (line in data_lines[seq.int(ghost_header + 1L, ghost_end - 1L)]) {
    f <- numeric_tokens(line)
    if (!length(f) || f[1L] < 1900 || f[1L] > 2018) next
    if (length(f) != 33L) stop("Unexpected ghost marginal-age row width: ",
      length(f), call. = FALSE)
    ghost_rows[[length(ghost_rows) + 1L]] <- f
  }
  ghost_rows <- do.call(rbind, ghost_rows)
  if (is.null(dim(ghost_rows)) || nrow(ghost_rows) != 4L) {
    stop("Unexpected ghost marginal-age sample coverage.", call. = FALSE)
  }
  for (i in seq_len(nrow(ghost_rows))) {
    x <- ghost_rows[i, ]
    year <- as.integer(x[1L]); month <- x[2L]
    fleet_id <- as.integer(x[3L]); sex_code <- as.integer(x[4L])
    partition <- as.integer(x[5L]); age_error <- x[6L]
    lbin_lo <- x[7L]; lbin_hi <- x[8L]; sample_size <- x[9L]
    frequency <- x[10:33]
    if (!all(is.finite(frequency))) {
      stop("Invalid ghost marginal-age frequency.", call. = FALSE)
    }
    is_survey <- abs(fleet_id) %in% 5:9
    series <- if (is_survey) unname(survey_names[as.character(abs(fleet_id))]) else
      unname(model_fleets[abs(fleet_id)])
    add_input(input_base("biology", "frequency_at_age", "native_frequency",
      frequency, "fish count", year = year, age = 0:23,
      fleet = if (is_survey) "" else series,
      survey = if (is_survey) series else "",
      sex = if (sex_code == 0L) "combined" else as.character(sex_code),
      season = as.character(as.integer(month)),
      sampling_time = (month - 1) / 12,
      observation_id = sprintf("longnose_ghost_age_%03d", i),
      length_bin_lower = lbin_lo, length_bin_upper = lbin_hi,
      sample_size = sample_size, age_error = age_error,
      partition = as.character(partition),
      source_reference = ref("native Stock Synthesis data file, ghost marginal ages"),
      notes = paste(
        "Native diagnostic marginal-age record using a negative Stock Synthesis fleet code; not an independent likelihood observation.",
        if (fleet_id < 0L) "Stock Synthesis also excludes the associated composition likelihood contribution.")),
      length(frequency))
  }

  xlsx_lines <- paste(readLines(unz(workbook_path,
    "xl/worksheets/sheet1.xml"), warn = FALSE), collapse = "")
  xml_rows <- regmatches(xlsx_lines,
    gregexpr("<row\\b[^>]*r=\"[0-9]+\"[^>]*>.*?</row>", xlsx_lines,
      perl = TRUE))[[1L]]
  parse_excel_row <- function(xml_row) {
    cells <- regmatches(xml_row,
      gregexpr("<c\\b[^>]*>.*?</c>", xml_row, perl = TRUE))[[1L]]
    out <- list()
    for (cell in cells) {
      if (!grepl("<v>", cell, fixed = TRUE)) next
      column <- sub(".*<c[^>]*r=\"([A-Z]+)[0-9]+\"[^>]*>.*", "\\1",
        cell, perl = TRUE)
      value <- sub(".*<v>([^<]*)</v>.*", "\\1", cell, perl = TRUE)
      out[[column]] <- suppressWarnings(as.numeric(value))
    }
    out
  }
  rows <- lapply(xml_rows, parse_excel_row)
  age_output <- list()
  for (row in rows) {
    year <- row[["B"]]
    if (is.null(year) || is.na(year) || year < 1916 || year > 2018) next
    ages <- vapply(0:30, function(age) {
      n <- age + 3L
      name <- ""
      while (n > 0L) {
        r <- (n - 1L) %% 26L
        name <- paste0(LETTERS[r + 1L], name)
        n <- (n - r - 1L) %/% 26L
      }
      value <- row[[name]]
      if (is.null(value)) NA_real_ else value
    }, numeric(1L))
    if (length(ages) != 31L || anyNA(ages)) {
      stop("The supplementary workbook has an incomplete fitted abundance row.",
        call. = FALSE)
    }
    age_output[[length(age_output) + 1L]] <- c(year = year, ages)
  }
  age_output <- do.call(rbind, age_output)
  if (is.null(dim(age_output)) || nrow(age_output) != 103L ||
      !identical(as.integer(age_output[, 1L]), 1916:2018)) {
    stop("Unexpected supplementary abundance-at-age coverage.", call. = FALSE)
  }
  age_years <- rep(as.integer(age_output[, 1L]), each = 31L)
  age_values <- as.vector(t(age_output[, -1L, drop = FALSE]))
  age_ids <- rep(0:30, times = nrow(age_output))
  age_num <- ifelse(age_ids == 30L, NA_integer_, age_ids)
  age_group <- ifelse(age_ids == 30L, "30+", "")
  add_output(table_output("population", "numbers_at_age", age_values,
    "source count scale (unit not stated)", year = age_years, age = age_num,
    age_group = age_group, source_reference = paste(
      "2019 Longnose Skate supplementary tables, derived output time-series sheet"),
    notes = "Official fitted abundance-at-age output. Ages 0-29 are single ages; age 30 is the Stock Synthesis accumulator plus group. The source workbook does not state a count multiplier; no unit conversion was applied."),
    length(age_values))

  table16_start <- grep("^Table 16\\.Time series", report_lines, perl = TRUE)
  table17_start <- grep("^Table 17\\.", report_lines, perl = TRUE)
  table17_start <- table17_start[table17_start > table16_start]
  if (length(table16_start) != 1L || length(table17_start) != 1L) {
    stop("Could not identify the report's Table 16 time series.", call. = FALSE)
  }
  table_lines <- report_lines[seq.int(table16_start, table17_start - 1L)]
  output_tokens <- function(line) {
    z <- regmatches(line, gregexpr(
      "NA|(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?",
      line, perl = TRUE))[[1L]]
    if (!length(z)) return(numeric())
    suppressWarnings(as.numeric(gsub(",", "", z, fixed = TRUE)))
  }
  table_rows <- lapply(table_lines, function(line) {
    if (!grepl("^[[:space:]]*(191[6-9]|19[2-9][0-9]|20[01][0-9])[[:space:]]+",
      line, perl = TRUE)) return(numeric())
    output_tokens(line)
  })
  table_rows <- Filter(function(x) length(x) == 9L && x[1L] >= 1916 &&
    x[1L] <= 2019, table_rows)
  table_rows <- do.call(rbind, table_rows)
  table_rows <- table_rows[!duplicated(table_rows[, 1L]), , drop = FALSE]
  table_rows <- table_rows[order(table_rows[, 1L]), , drop = FALSE]
  if (is.null(dim(table_rows)) || nrow(table_rows) != 104L ||
      !identical(as.integer(table_rows[, 1L]), 1916:2019)) {
    stop("Unexpected Table 16 year coverage or row layout.", call. = FALSE)
  }

  es8_start <- grep("^Table ES-8: Summary table of the results", report_lines,
    perl = TRUE)
  if (length(es8_start) != 1L) stop("Could not identify Table ES-8.", call. = FALSE)
  es8_lines <- report_lines[seq.int(es8_start, min(length(report_lines), es8_start + 35L))]
  years_line <- grep("^[[:space:]]*Years[[:space:]]+", es8_lines, value = TRUE,
    perl = TRUE)
  if (length(years_line) != 1L) stop("Could not read Table ES-8 years.", call. = FALSE)
  es8_years <- output_tokens(years_line)
  parse_value_line <- function(pattern) {
    line <- grep(pattern, es8_lines, value = TRUE, perl = TRUE)
    if (length(line) != 1L) stop("Could not read Table ES-8 row: ", pattern,
      call. = FALSE)
    values <- output_tokens(line)
    if (length(values) != length(es8_years)) stop("Unexpected Table ES-8 row length.",
      call. = FALSE)
    values
  }
  parse_interval_line <- function(index) {
    line <- grep("^95% Confidence Interval", es8_lines, value = TRUE,
      perl = TRUE)
    if (length(line) != 3L || index < 1L || index > 3L) {
      stop("Could not read the three Table ES-8 confidence-interval rows.",
        call. = FALSE)
    }
    line <- gsub(intToUtf8(8211L), "-", line[index], fixed = TRUE)
    pairs <- regmatches(line, gregexpr(
      "[0-9][0-9,]*(?:\\.[0-9]+)?[[:space:]]*-[[:space:]]*[0-9][0-9,]*(?:\\.[0-9]+)?",
      line, perl = TRUE))[[1L]]
    if (length(pairs) != length(es8_years)) stop("Unexpected Table ES-8 interval count.",
      call. = FALSE)
    do.call(rbind, lapply(pairs, function(x) {
      parts <- strsplit(x, "-", fixed = TRUE)[[1L]]
      as.numeric(gsub(",", "", trimws(parts), fixed = TRUE))
    }))
  }
  es8_ssb <- parse_value_line("^Spawning Biomass \\(mt\\)")
  es8_ssb_ci <- parse_interval_line(1L)
  es8_recruitment <- parse_value_line("^Recruitment[[:space:]]+")
  es8_recruitment_ci <- parse_interval_line(2L)
  es8_depletion <- parse_value_line("^Depletion")
  es8_depletion_ci <- parse_interval_line(3L)

  for (i in seq_len(nrow(table_rows))) {
    year <- as.integer(table_rows[i, 1L])
    value <- table_rows[i, 2:9]
    scenario <- if (year == 2019L) "2019 forecast" else ""
    ci_row <- match(year, es8_years)
    ssb_lwr <- ssb_upr <- recruitment_lwr <- recruitment_upr <-
      depletion_lwr <- depletion_upr <- NA_real_
    if (!is.na(ci_row)) {
      ssb_lwr <- es8_ssb_ci[ci_row, 1L]; ssb_upr <- es8_ssb_ci[ci_row, 2L]
      recruitment_lwr <- es8_recruitment_ci[ci_row, 1L]
      recruitment_upr <- es8_recruitment_ci[ci_row, 2L]
      depletion_lwr <- es8_depletion_ci[ci_row, 1L]
      depletion_upr <- es8_depletion_ci[ci_row, 2L]
      if (abs(value[2L] - es8_ssb[ci_row]) > 0.51 ||
          abs(value[5L] - es8_recruitment[ci_row]) > 0.51 ||
          abs(value[4L] - es8_depletion[ci_row]) > 0.051) {
        stop("Table 16 and Table ES-8 estimates do not reconcile.", call. = FALSE)
      }
    }
    common_ref <- ref("Table 16, pp. 92-94; Table ES-8, p. 22")
    common_note <- "Official rounded estimate; approximate 95% confidence limits are included for 2009-2019 where Table ES-8 reports them."
    add_output(table_output("biomass", "total_biomass", value[1L],
      "metric tons", year, scenario = scenario, source_reference = common_ref,
      notes = common_note), 1L)
    add_output(table_output("biomass", "SSB", value[2L], "metric tons",
      year, scenario = scenario, lwr = ssb_lwr, upr = ssb_upr,
      source_reference = common_ref, notes = common_note), 1L)
    add_output(table_output("biomass", "biomass_by_age_group", value[3L],
      "metric tons", year, age_group = "2+", scenario = scenario,
      source_reference = common_ref,
      notes = "Summary biomass for ages 2 and older, as defined by Stock Synthesis."), 1L)
    add_output(table_output("population", "depletion", value[4L], "percent",
      year, scenario = scenario, lwr = depletion_lwr, upr = depletion_upr,
      source_reference = common_ref,
      notes = "Source-reported percent depletion; 95% confidence limits are available for 2009-2019."), 1L)
    add_output(table_output("recruitment", "recruitment", value[5L],
      "source count scale (unit not stated)", year, age = 0L, scenario = scenario,
      lwr = recruitment_lwr, upr = recruitment_upr,
      source_reference = common_ref,
      notes = "Age-0 recruits as reported; the table does not state a count multiplier. 95% confidence limits are available for 2009-2019."), 1L)
    if (is.finite(value[6L])) add_output(table_output("catch", "catch_biomass",
      value[6L], "metric tons", year, scenario = scenario,
      source_reference = ref("Table 16, pp. 92-94"),
      notes = "Official annual total catch; 2019 is a forecast and is not reported."), 1L)
    if (is.finite(value[7L])) add_output(table_output("mortality", "exploitation_rate",
      value[7L], "ratio", year, scenario = scenario,
      source_reference = ref("Table 16, pp. 92-94"),
      notes = "Source-labelled relative exploitation rate; not instantaneous F or F-at-age."), 1L)
    if (is.finite(value[8L])) add_output(table_output("diagnostic",
      "relative_1_minus_SPR_to_target", value[8L], "ratio", year,
      scenario = scenario, source_reference = ref("Table 16, pp. 92-94"),
      notes = "Source-reported (1-SPR)/(1-SPR50); not an F-at-age estimate."), 1L)
  }
  add_output(table_output("biology", "natural_mortality_average_parameter",
    0.22, "per year", source_reference = ref("Table 14, p. 88"),
    notes = "Estimated scalar natural mortality. Table 14 reports a parameter SD of 0.01; that SD is stored separately, not as an SE."), 1L)
  add_output(table_output("parameter", "natural_mortality_parameter_sd", 0.01,
    "per year", source_reference = ref("Table 14, p. 88"),
    notes = "Source-reported parameter standard deviation for the estimated scalar M; source labels this SD, not SE."), 1L)

  add_assumption("assessment", "run_identity",
    "2019 full assessment; Stock Synthesis; data through 2018; 2019 forecast.",
    ref("cover, executive summary, and Table 16"),
    "The model archive did not identify a version number; no version is inferred.")
  add_assumption("stock", "stock_boundary",
    "U.S. coastwide stock from the U.S.-Canada border to the U.S.-Mexico border.",
    ref("assessment summary"),
    "Distinct from Gulf of Alaska longnose skate NOAA:10730 and Canadian assessment areas.")
  add_assumption("population", "age_grid",
    "Ages 0-30; age 30 is the accumulator plus group.",
    ref("native Stock Synthesis data and control files; supplementary tables"),
    "The supplementary abundance table labels age 30; the control/report define it as the accumulator.")
  add_assumption("population", "sex_representation",
    "Combined-sex population; fixed female fraction 0.5.",
    ref("native Stock Synthesis data and control files"),
    "The native model does not estimate separate female and male population states.")
  add_assumption("catch", "catch_definition",
    "Four annual removal fleets, in metric tons; native catch uncertainty is log-scale SD.",
    ref("native Stock Synthesis data file"),
    "Historical fishery removals, current fishery, and tribal removals retain separate source fleet identities.")
  add_assumption("index", "index_structure",
    "Five aggregate indices: four biomass indices and one numbers index.",
    ref("native Stock Synthesis data file, index units and observation sections"),
    "Index values are not absolute abundance. The IPHC series is the numbers-scale index.")
  add_assumption("index", "index_likelihood",
    "Native Stock Synthesis index error code 0 (lognormal); log-index SDs are supplied.",
    ref("native Stock Synthesis data file, fleet-unit and index sections"),
    "The data-file comments describe some upstream VAST indices as Gamma; the Stock Synthesis observation error code is lognormal.")
  add_assumption("index", "survey_timing",
    "Survey observations are in July; fitted survey fleet timing is 0.5.",
    ref("native Stock Synthesis data file, fleet definitions and index rows"),
    "July records and the explicit fleet timing agree at mid-year.")
  add_assumption("observation", "composition_data",
    "Annual fishery and survey length frequencies, fishery conditional age-at-length data in 2004, NWFSC shelf-slope conditional age-at-length data in 2003, 2011, and 2012, and four ghost marginal-age records.",
    ref("native Stock Synthesis data file, composition sections"),
    "Composition frequencies are retained on their native scale; no catch-at-age or continuous index-at-age is reconstructed.")
  add_assumption("biology", "weight_length",
    "Fixed combined-sex weight-length relationship W = 4.288369e-6 * L^3.068629 kg, with L in cm.",
    ref("native Stock Synthesis control file; Table 14"),
    "Age-specific weights are generated internally from estimated growth; no standalone weight-at-age array is imported.")
  add_assumption("biology", "maturity_at_length",
    "Fixed logistic maturity-at-length curve; inflection 101.5262 cm and slope -0.12997.",
    ref("native Stock Synthesis control file; Table 14"),
    "No annual maturity-at-age surface is published.")
  add_assumption("M", "natural_mortality",
    "Estimated scalar M with an informative Hamel prior; fitted estimate 0.22 per year.",
    ref("native Stock Synthesis control file; Table 14, p. 88"),
    "M is not estimated by age. Table 14 labels the parameter uncertainty SD=0.01.")
  add_assumption("F", "fishing_mortality_reporting",
    "Stock Synthesis forecast settings report exploitation by biomass.",
    ref("native Stock Synthesis starter file"),
    "The published relative exploitation output is not instantaneous F-at-age.")

  inputs <- bind_rows(input_rows)
  outputs <- bind_rows(output_rows)
  assumptions <- bind_rows(assumption_rows)
  stocks_path <- file.path(root, "database/stocks.csv")
  assessments_path <- file.path(root, "database/assessments.csv")
  stocks <- read.csv(stocks_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  assessments <- read.csv(assessments_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (any(stocks$stock_id == stock_id) ||
      any(assessments$assessment_id == assessment_id) ||
      any(stocks$authority_stock_id == "10731", na.rm = TRUE)) {
    stop("Longnose Skate stock or assessment already exists; inspect records before reimporting.",
      call. = FALSE)
  }
  stock_fields <- names(read.csv(text = readLines(stocks_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  assessment_fields <- names(read.csv(text = readLines(assessments_path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  stock <- make_rows(stock_fields, list(stock_id = stock_id,
    charbonneau_id = "", authority = "NOAA Fisheries",
    authority_stock_id = "10731", scientific_name = "Beringraja rhina",
    common_name = "Longnose skate", area = "U.S. Pacific Coast",
    region = "U.S. West Coast", ocean = "Northeast Pacific",
    notes = "NOAA Stock SMART 10731; coastwide U.S. unit from the Canadian to Mexican border."), 1L)
  assessment <- make_rows(assessment_fields, list(assessment_id = assessment_id,
    stock_id = stock_id, assessment_year = 2019, terminal_year = 2018,
    estimate_terminal_year = 2019, assessment_type = "full_assessment",
    model_family = "Stock Synthesis", model_version = "",
    is_current = TRUE, is_applied = TRUE, assessment_url = report_url,
    framework_url = star_url, data_url = workbook_url, model_url = archive_url,
    repository_url = "https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/",
    assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = paste("Latest full assessment located for this current unit; Stock SMART lists 2019 with data through 2018. The supplementary workbook provides fitted abundance-at-age for 1916-2018; no fitted Report.sso or F-at-age surface was found. See discovery/source_reviews/noaa_longnose_skate_pacific_2019.md.")), 1L)

  cat("NOAA Pacific Coast Longnose Skate 2019 source extraction\n")
  cat("Inputs:", nrow(inputs), "rows (catch, indices, discard fractions, mean body weight, and native compositions).\n")
  cat("Outputs:", nrow(outputs), "rows, including 1916-2018 abundance-at-age and Table 16 estimates through 2019.\n")
  cat("Recovered fitted N-at-age; annual catch-at-age, continuous age-specific indices, and F-at-age are not fabricated.\n")
  if (!write) {
    cat("Dry run only. Add --write to append the reviewed source records.\n")
    return(list(stock = stock, assessment = assessment, assumptions = assumptions,
      inputs = inputs, outputs = outputs))
  }

  for (name in c("stocks", "assessments", "assumptions", "inputs", "outputs")) {
    path <- file.path(root, "database", paste0(name, ".csv"))
    expected <- names(read.csv(text = readLines(path, n = 1L, warn = FALSE),
      nrows = 0L, check.names = FALSE))
    rows <- switch(name, stocks = stock, assessments = assessment,
      assumptions = assumptions, inputs = inputs, outputs = outputs)
    if (!identical(names(rows), expected)) {
      stop("Import rows do not match database columns for ", name, ".",
        call. = FALSE)
    }
  }
  append_csv <- function(rows, path) {
    write.table(rows, file = path, sep = ",", row.names = FALSE,
      col.names = FALSE, append = TRUE, na = "", quote = TRUE,
      qmethod = "double", eol = "\n")
  }
  append_csv(stock, stocks_path)
  append_csv(assessment, assessments_path)
  append_csv(assumptions, assumption_path)
  append_csv(inputs, input_path)
  append_csv(outputs, output_path)

  source(file.path(root, "scripts/database/candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ci <- which(candidates$candidate_id == candidate_id)
  if (length(ci) != 1L || candidates$eligibility[ci] != "eligible" ||
      candidates$screening_status[ci] != "screened") {
    stop("Expected one screened, eligible NOAA:10731 candidate.", call. = FALSE)
  }
  candidates$candidate_unit_id[ci] <- stock_id
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- report_url
  candidates$review_date[ci] <- "2026-11-12"
  candidates$catch_age_evidence[ci] <- paste("Imported native annual catch biomass, discard fractions, and length/conditional age-at-length samples.", "These are not annual catch numbers-at-age.")
  candidates$survey_age_evidence[ci] <- paste("Imported five aggregate index series and July timing.", "NWFSC shelf-slope conditional age-at-length is available in 2003, 2011, and 2012; no continuous index-at-age series is available.")
  candidates$weights_evidence[ci] <- "Imported discard mean body weight and CV; fixed weight-length and estimated growth are documented, but no standalone weight-at-age series is published."
  candidates$maturity_evidence[ci] <- "Fixed maturity-at-length parameters are documented; no standalone annual maturity-at-age surface is published."
  candidates$mortality_evidence[ci] <- "Estimated scalar M=0.22 per year with an informative Hamel prior; Table 14 reports parameter SD 0.01. No M-at-age surface is reported."
  candidates$timing_evidence[ci] <- "Survey observations are in July and the fitted fleet timing is 0.5."
  candidates$output_evidence[ci] <- paste("Imported fitted N-at-age for ages 0-29 and 30+ from 1916-2018, plus total biomass, SSB, age-2+ biomass, depletion, recruitment, catch and relative exploitation from Table 16 through the 2019 forecast.", "Table ES-8 supplies 95% intervals for SSB, recruitment and depletion in 2009-2019.", "F-at-age remains unavailable; the archive has no fitted Report.sso.")
  candidates$decision_reason[ci] <- paste("The 2019 full coastwide assessment remains the latest run identified by Stock SMART and the PFMC 2023 data-availability review.", "The native SS3 file and run-matched report/workbook support source import; sparse age-composition coverage and missing F-at-age are documented.")
  candidates$notes[ci] <- paste("Partial source import from the 2019 full assessment and supplementary tables.", "The workbook count unit is unstated, so values are preserved without a multiplier.", "See discovery/source_reviews/noaa_longnose_skate_pacific_2019.md.")
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)

  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ir <- which(vapply(strsplit(inventory$candidate_ids, " | ", fixed = TRUE),
    function(x) candidate_id %in% x, logical(1L)))
  if (length(ir) != 1L) stop("Expected one Longnose Skate inventory unit.",
    call. = FALSE)
  inventory$unit_key[ir] <- paste0("stock:", stock_id)
  inventory$candidate_unit_id[ir] <- stock_id
  inventory$matched_stock_id[ir] <- stock_id
  inventory$match_status[ir] <- "matched"
  inventory$import_status[ir] <- "partial"
  replace_csv_register_row(inventory_path, ir,
    inventory[ir, , drop = FALSE], "candidate_ids", inventory$candidate_ids[ir])

  batch_path <- file.path(root, "discovery/selected_batch_40_2026.csv")
  batch <- read.csv(batch_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  bi <- which(batch$candidate_id == candidate_id)
  if (length(bi) != 1L) stop("Longnose Skate is not in the selected batch.",
    call. = FALSE)
  batch$curation_status[bi] <- "partial_source_import"
  replace_candidate_register_row(batch_path, bi,
    batch[bi, , drop = FALSE], candidate_id)

  provenance_dir <- file.path(root,
    "provenance/discovery_noaa_longnose_skate_2019")
  dir.create(provenance_dir, recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(manifest_path, file.path(provenance_dir, "sources.csv"),
      overwrite = TRUE)) stop("Could not write tracked source provenance.",
        call. = FALSE)
  cat("Longnose Skate rows appended; candidate status set to partial.\n")
  invisible(list(stock = stock, assessment = assessment,
    assumptions = assumptions, inputs = inputs, outputs = outputs))
}

if (!interactive() && sys.nframe() == 0L) {
  result <- import_noaa_longnose_skate_pacific_2019(write =
    "--write" %in% commandArgs(trailingOnly = TRUE))
}
