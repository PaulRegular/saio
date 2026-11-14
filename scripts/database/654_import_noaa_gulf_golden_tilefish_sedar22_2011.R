import_noaa_gulf_golden_tilefish <- function(root = ".", write = FALSE) {
  assessment_id <- "noaa_gulf_golden_tilefish_2011"
  stock_id <- "noaa_gulf_golden_tilefish"
  candidate_id <- "NOAA:10383"
  candidate_unit_id <- stock_id
  source_dir <- file.path(root, "source_cache/discovery_noaa_gulf_tilefish_sedar22_2011")
  manifest_path <- file.path(root, "provenance/discovery_noaa_gulf_tilefish_sedar22_2011/sources.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE,
    colClasses = "character")

  sha256_file <- function(path) {
    path <- normalizePath(path, winslash = if (.Platform$OS.type == "windows") "\\" else "/",
      mustWork = TRUE)
    if (.Platform$OS.type == "windows") {
      output <- system2("certutil.exe", c("-hashfile", path, "SHA256"), stdout = TRUE)
      hash <- trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE))
    } else {
      output <- system2("sha256sum", shQuote(path), stdout = TRUE)
      hash <- sub("[[:space:]].*$", "", output[1L])
    }
    if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
    tolower(hash)
  }
  verify_sources <- function() {
    if (anyDuplicated(manifest$file) || any(!grepl("^[[:xdigit:]]{64}$", manifest$sha256)))
      stop("The tilefish provenance manifest is invalid.", call. = FALSE)
    paths <- file.path(source_dir, manifest$file)
    if (any(!file.exists(paths))) stop("A cached tilefish source is missing.", call. = FALSE)
    sizes <- as.numeric(file.info(paths)$size)
    if (!identical(sizes, as.numeric(manifest$bytes)))
      stop("Cached tilefish source sizes differ from the provenance manifest.", call. = FALSE)
    files_to_hash <- "sedar22_gulf_tilefish_assessment_2011.pdf"
    selected <- match(files_to_hash, manifest$file)
    if (anyNA(selected)) stop("A required tilefish source is absent from provenance.", call. = FALSE)
    hashes <- vapply(paths[selected], sha256_file, character(1L))
    if (!identical(unname(hashes), tolower(manifest$sha256[selected])))
      stop("Cached tilefish sources differ from the provenance manifest.", call. = FALSE)
    paths
  }
  source_paths <- verify_sources()
  sar_name <- "sedar22_gulf_tilefish_assessment_2011.pdf"
  sar_path <- file.path(source_dir, sar_name)
  text_path <- paste0(sar_path, ".txt")
  if (!file.exists(text_path)) {
    if (!requireNamespace("pdftools", quietly = TRUE))
      stop("Install pdftools or provide the extracted text beside the assessment PDF.", call. = FALSE)
    writeLines(pdftools::pdf_text(sar_path), text_path, useBytes = TRUE)
  }
  lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
  trimmed <- trimws(lines)

  numeric_tokens <- function(tokens) {
    tokens <- gsub(",", "", tokens, fixed = TRUE)
    tokens <- gsub("<U\\+201[0-5]>", "-", tokens)
    pattern <- "^[-+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?$"
    out <- rep(NA_real_, length(tokens))
    valid <- grepl(pattern, tokens, perl = TRUE)
    out[valid] <- as.numeric(tokens[valid])
    out
  }
  tokens <- function(line) strsplit(trimws(line), "[[:space:]]+", perl = TRUE)[[1L]]
  table_section <- function(pattern) {
    at <- grep(pattern, trimmed, perl = TRUE)
    if (length(at) != 1L) stop("Expected one source table matching: ", pattern, call. = FALSE)
    later <- grep("^Table [0-9]+\\.[0-9]+\\.", trimmed, perl = TRUE)
    later <- later[later > at]
    end <- if (length(later)) min(later) - 1L else length(lines)
    lines[at:end]
  }
  table_rows <- function(section, pattern, n_values, label) {
    selected <- section[grepl(pattern, section, perl = TRUE)]
    if (!length(selected)) stop("No numeric rows found in ", label, ".", call. = FALSE)
    values <- lapply(selected, function(line) {
      x <- numeric_tokens(tokens(line))
      if (length(x) != n_values || any(!is.finite(x)))
        stop("Unexpected numeric row in ", label, ": ", line, call. = FALSE)
      x
    })
    do.call(rbind, values)
  }

  input_columns <- names(read.csv(file.path(root, "database/inputs.csv"), nrows = 0L,
    check.names = FALSE))
  output_columns <- names(read.csv(file.path(root, "database/outputs.csv"), nrows = 0L,
    check.names = FALSE))
  input_matrix <- matrix("", nrow = 40000L, ncol = length(input_columns),
    dimnames = list(NULL, input_columns))
  output_matrix <- matrix("", nrow = 400L, ncol = length(output_columns),
    dimnames = list(NULL, output_columns))
  input_n <- 0L
  output_n <- 0L
  format_value <- function(x) {
    if (!length(x) || is.na(x)) return("")
    if (is.numeric(x)) return(format(x, scientific = FALSE, trim = TRUE, digits = 15))
    as.character(x)
  }
  add_input <- function(type, measure, basis, value, unit, source_reference, notes,
                        year = NA, fleet = "", survey = "", sex = "", region = "",
                        age = NA, sampling_time = NA, transformation = "",
                        observation_id = "", length_bin = NA, length_bin_lower = NA,
                        length_bin_upper = NA, sample_size = NA, age_error = "",
                        partition = "", weight_bin = NA, year_basis = "calendar_year") {
    input_n <<- input_n + 1L
    values <- list(assessment_id = assessment_id, type = type, measure = measure,
      basis = basis, fleet = fleet, survey = survey, sex = sex, region = region,
      season = "", year = year, year_basis = if (is.na(year)) "" else year_basis,
      age = age, value = value, unit = unit, sampling_time = sampling_time,
      source_type = "official_table", source_reference = source_reference,
      transformation = transformation, notes = notes, observation_id = observation_id,
      length_bin = length_bin, length_bin_lower = length_bin_lower,
      length_bin_upper = length_bin_upper, sample_size = sample_size,
      age_error = age_error, partition = partition, weight_bin = weight_bin)
    for (name in intersect(names(values), input_columns))
      input_matrix[input_n, name] <<- format_value(values[[name]])
  }
  add_output <- function(type, measure, value, unit, source_reference, notes,
                         year = NA, age = NA, age_group = "", fleet = "",
                         survey = "", sex = "", region = "", season = "",
                         scenario = "") {
    output_n <<- output_n + 1L
    values <- list(assessment_id = assessment_id, type = type, measure = measure,
      fleet = fleet, survey = survey, sex = sex, region = region, season = season,
      year = year, age = age, age_group = age_group, value = value, se = NA,
      lwr = NA, upr = NA, unit = unit, source_type = "official_table",
      source_reference = source_reference, notes = notes, scenario = scenario)
    for (name in intersect(names(values), output_columns))
      output_matrix[output_n, name] <<- format_value(values[[name]])
  }

  commercial <- table_rows(table_section("^Table 2\\.1\\. Commercial landings"),
    "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", 5L, "SEDAR 22 Table 2.1")
  expected_commercial_years <- c(1965:1969, 1971:2009)
  if (nrow(commercial) != 44L || !identical(as.integer(commercial[, 1L]), expected_commercial_years))
    stop("SEDAR 22 Table 2.1 year coverage changed; do not fill the unreported 1970 row.", call. = FALSE)
  commercial_names <- c("Commercial Handline East", "Commercial Handline West",
    "Commercial Longline East", "Commercial Longline West")
  commercial_fleet <- c("Commercial Handline", "Commercial Handline",
    "Commercial Longline", "Commercial Longline")
  commercial_region <- c("East", "West", "East", "West")
  for (j in seq_along(commercial_names)) for (i in seq_len(nrow(commercial)))
    add_input("catch", "landings_biomass", "biomass", commercial[i, j + 1L],
      "gutted pounds", paste0(sar_name, ", Table 2.1"),
      "Source-native commercial landings. The printed 1970 row is absent and has not been imputed.",
      year = commercial[i, 1L], fleet = commercial_fleet[j],
      region = commercial_region[j], partition = "landings")

  recreational <- table_rows(table_section("^Table 2\\.2\\. Recreational landings"),
    "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", 3L, "SEDAR 22 Table 2.2")
  if (nrow(recreational) != 23L || !identical(as.integer(recreational[, 1L]), 1987:2009))
    stop("SEDAR 22 Table 2.2 year coverage changed.", call. = FALSE)
  for (j in 1:2) for (i in seq_len(nrow(recreational)))
    add_input("catch", "landings_biomass", "biomass", recreational[i, j + 1L],
      "gutted pounds", paste0(sar_name, ", Table 2.2"),
      "Source-native recreational landings by Gulf region.",
      year = recreational[i, 1L], fleet = "Recreational", region = c("East", "West")[j],
      partition = "landings")

  discard_section <- table_section("^Table 2\\.3\\. Commercial discards")
  discard_line <- discard_section[grepl("981[[:space:]]+3,?509", discard_section)]
  if (length(discard_line) != 1L) stop("Could not uniquely recover Table 2.3 aggregate discards.", call. = FALSE)
  discard_values <- numeric_tokens(tokens(discard_line))
  discard_values <- discard_values[is.finite(discard_values)]
  if (!identical(as.integer(discard_values), c(981L, 3509L)))
    stop("SEDAR 22 Table 2.3 discard totals changed.", call. = FALSE)
  for (j in 1:2) add_input("catch", "discard_numbers", "numbers", discard_values[j],
    "fish", paste0(sar_name, ", Table 2.3"),
    "Confidentiality combines the total across 2002-2009; no annual or area allocation is reported.",
    year = NA, fleet = c("Commercial Handline", "Commercial Longline")[j],
    partition = "2002-2009 aggregate")

  age_error_section <- table_section("^Table 2\\.4\\. Age estimation error matrix")
  mean_age_lines <- age_error_section[grepl("^[[:space:]]*Mean Age", age_error_section)]
  sd_lines <- age_error_section[grepl("^[[:space:]]*SD of Age", age_error_section)]
  mean_ages <- unlist(lapply(mean_age_lines, function(line) {
    z <- numeric_tokens(tokens(line)); z[is.finite(z)]
  }), use.names = FALSE)
  age_sds <- unlist(lapply(sd_lines, function(line) {
    z <- numeric_tokens(tokens(line)); z[is.finite(z)]
  }), use.names = FALSE)
  if (!isTRUE(all.equal(as.numeric(mean_ages), seq(0.5, 30.5, by = 1),
        check.attributes = FALSE)) || length(age_sds) != 31L ||
      any(!is.finite(age_sds)) || any(age_sds <= 0))
    stop("SEDAR 22 Table 2.4 age-error values changed.", call. = FALSE)
  for (i in seq_along(mean_ages)) add_input("biology", "ageing_error_sd", "age_error_sd",
    age_sds[i], "years", paste0(sar_name, ", Table 2.4"),
    "SD of assigned age by mean coded age; estimated from two independent readers and smoothed with the reported power function.",
    year = NA, age = mean_ages[i])

  index_start <- grep("^Table 2\\.5\\. Standardized indices", trimmed, perl = TRUE)
  index_end <- grep("^2\\.9\\. FIGURES", trimmed, perl = TRUE)
  if (length(index_start) != 1L || length(index_end) != 1L || index_end <= index_start)
    stop("Could not isolate SEDAR 22 Table 2.5.", call. = FALSE)
  index_section <- lines[index_start:(index_end - 1L)]
  index_lines <- index_section[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]", index_section)]
  index_values <- do.call(rbind, lapply(index_lines, function(line) numeric_tokens(tokens(line))))
  if (!length(index_lines) || ncol(index_values) != 9L || any(!is.finite(index_values[, 1L])))
    stop("Unexpected numeric rows in SEDAR 22 Table 2.5.", call. = FALSE)
  if (nrow(index_values) != 18L || !identical(as.integer(index_values[, 1L]), 1992:2009))
    stop("SEDAR 22 Table 2.5 year coverage changed.", call. = FALSE)
  index_series <- data.frame(
    fleet = c("Commercial Longline", "Commercial Longline", "", ""),
    survey = c("", "", "NMFS Bottom Longline Survey", "NMFS Bottom Longline Survey"),
    region = c("East", "West", "East", "West"),
    label = c("commercial longline east", "commercial longline west",
      "NMFS bottom longline survey east", "NMFS bottom longline survey west"),
    stringsAsFactors = FALSE)
  n_index <- 0L
  for (j in seq_len(nrow(index_series))) for (i in seq_len(nrow(index_values))) {
    index <- index_values[i, 2L + 2L * (j - 1L)]
    log_sd <- index_values[i, 3L + 2L * (j - 1L)]
    if (is.finite(index) != is.finite(log_sd))
      stop("SEDAR 22 Table 2.5 has an unpaired index and log SD.", call. = FALSE)
    if (!is.finite(index)) next
    if (index <= 0 || log_sd <= 0) stop("SEDAR 22 Table 2.5 contains invalid values.", call. = FALSE)
    n_index <- n_index + 1L
    add_input("index", "relative_abundance_index", "index_scale", index,
      "relative index", paste0(sar_name, ", Table 2.5"),
      paste0("Observed standardized relative-abundance index for the ", index_series$label[j], "."),
      year = index_values[i, 1L], fleet = index_series$fleet[j],
      survey = index_series$survey[j], region = index_series$region[j])
    add_input("index", "log_index_sd", "log_scale", log_sd,
      "log scale SD", paste0(sar_name, ", Table 2.5"),
      paste0("Source-reported log-scale standard error for the ", index_series$label[j],
        "; the report converts index CVs using sqrt(log(1 + CV^2))."),
      year = index_values[i, 1L], fleet = index_series$fleet[j],
      survey = index_series$survey[j], region = index_series$region[j])
  }
  if (n_index != 52L) stop("Unexpected number of non-missing SEDAR 22 index observations.", call. = FALSE)

  context_header <- function(line) {
    match <- regexec("^(Commercial Hand Line|Commercial Long Line|NMFS Bottom Long Line Survey) (East|West)( \\(continued\\))?$",
      trimws(line), perl = TRUE)
    parts <- regmatches(trimws(line), match)[[1L]]
    if (!length(parts)) return(NULL)
    gear <- parts[2L]
    list(name = paste(gear, parts[3L]),
      fleet = if (gear == "Commercial Hand Line") "Commercial Handline" else
        if (gear == "Commercial Long Line") "Commercial Longline" else "",
      survey = if (gear == "NMFS Bottom Long Line Survey") "NMFS Bottom Longline Survey" else "",
      region = parts[3L], type = if (gear == "NMFS Bottom Long Line Survey") "index" else "catch",
      half = if (length(parts) >= 4L && nzchar(parts[4L])) "second" else "first")
  }
  parse_composition_rows <- function(section, composition_kind) {
    contexts <- list()
    current <- NULL
    for (line in section) {
      header <- context_header(line)
      if (!is.null(header)) {
        current <- header
        if (is.null(contexts[[current$name]])) contexts[[current$name]] <- list()
        next
      }
      if (is.null(current)) next
      row_pattern <- if (composition_kind == "length")
        "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+(Female|Male|Unknown)[[:space:]]+[0-9,]+[[:space:]]+" else
        "^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+(Female|Male|Unknown)[[:space:]]+[0-9,]+[[:space:]]+[0-9,]+[[:space:]]+"
      if (!grepl(row_pattern, line, perl = TRUE)) next
      raw_tokens <- tokens(line)
      if (composition_kind == "length") {
        if (length(raw_tokens) != 27L) stop("Unexpected Appendix A row width: ", line, call. = FALSE)
        row <- list(year = as.integer(raw_tokens[1L]), sex = raw_tokens[2L],
          sample_count = as.integer(gsub(",", "", raw_tokens[3L], fixed = TRUE)),
          bin = NA_integer_, counts = as.integer(gsub(",", "", raw_tokens[4:27], fixed = TRUE)))
      } else {
        if (length(raw_tokens) != 33L) stop("Unexpected Appendix B row width: ", line, call. = FALSE)
        row <- list(year = as.integer(raw_tokens[1L]), sex = raw_tokens[2L],
          bin = as.integer(gsub(",", "", raw_tokens[3L], fixed = TRUE)),
          sample_count = as.integer(gsub(",", "", raw_tokens[4L], fixed = TRUE)),
          counts = as.integer(gsub(",", "", raw_tokens[5:33], fixed = TRUE)))
      }
      invalid_total <- composition_kind == "age" && sum(row$counts) != row$sample_count
      if (anyNA(c(row$year, row$sample_count, row$counts)) || row$sample_count < 0L ||
          any(row$counts < 0L) || invalid_total)
        stop("A tilefish composition row does not match its printed sample size: ", line, call. = FALSE)
      contexts[[current$name]][[current$half]] <- c(contexts[[current$name]][[current$half]], list(row))
    }
    expected_contexts <- c("Commercial Hand Line East", "Commercial Hand Line West",
      "Commercial Long Line East", "Commercial Long Line West",
      "NMFS Bottom Long Line Survey East", "NMFS Bottom Long Line Survey West")
    if (!setequal(names(contexts), expected_contexts))
      stop("Unexpected tilefish composition strata in Appendix ", if (composition_kind == "length") "A" else "B", call. = FALSE)
    contexts
  }
  parse_length_samples <- function() {
    section_start <- grep("^3\\.7\\. Appendix A\\.\\s+Length Composition Data", trimmed, perl = TRUE)
    section_end <- grep("^3\\.8\\. Appendix B\\.\\s+Age Composition Data", trimmed, perl = TRUE)
    if (length(section_start) != 1L || length(section_end) != 1L || section_end <= section_start)
      stop("Could not isolate SEDAR 22 Appendix A.", call. = FALSE)
    contexts <- parse_composition_rows(lines[section_start:section_end], "length")
    samples <- list()
    for (context in names(contexts)) {
      halves <- contexts[[context]]
      first <- halves$first
      second <- halves$second
      if (!length(first) || length(first) != length(second))
        stop("Appendix A length ranges are not paired for ", context, call. = FALSE)
      sample_key <- function(rows) vapply(rows, function(x)
        paste(x$year, x$sex, x$sample_count, sep = "|"), character(1L))
      if (!identical(sample_key(first), sample_key(second)))
        stop("Appendix A split length ranges do not align for ", context, call. = FALSE)
      for (i in seq_along(first)) {
        if (sum(first[[i]]$counts) + sum(second[[i]]$counts) != first[[i]]$sample_count)
          stop("Appendix A split length counts do not sum to sample size for ", context, call. = FALSE)
        samples[[length(samples) + 1L]] <- list(context = context,
          metadata = first[[i]], counts = c(first[[i]]$counts, second[[i]]$counts))
      }
    }
    samples
  }
  parse_age_samples <- function() {
    section_start <- grep("^3\\.8\\. Appendix B\\.\\s+Age Composition Data", trimmed, perl = TRUE)
    section_end <- grep("^3\\.9\\. Appendix C\\.", trimmed, perl = TRUE)
    if (length(section_start) != 1L || length(section_end) != 1L || section_end <= section_start)
      stop("Could not isolate SEDAR 22 Appendix B.", call. = FALSE)
    contexts <- parse_composition_rows(lines[section_start:section_end], "age")
    samples <- list()
    for (context in names(contexts)) {
      for (half in names(contexts[[context]])) for (row in contexts[[context]][[half]])
        samples[[length(samples) + 1L]] <- list(context = context, metadata = row, counts = row$counts)
    }
    samples
  }
  append_context_data <- function(samples, kind) {
    per_context <- integer()
    for (sample in samples) {
      context <- context_header(sample$context)
      key_context <- gsub("[^A-Za-z0-9]+", "_", tolower(sample$context))
      per_context[key_context] <- (per_context[key_context] %||% 0L) + 1L
      meta <- sample$metadata
      observation_id <- paste0(if (kind == "length") "tilefish_length_" else "tilefish_age_",
        key_context, "_", meta$year, "_", tolower(meta$sex), "_", sprintf("%03d", per_context[key_context]))
      if (kind == "length") {
        bins <- c(seq(20L, 66L, by = 2L), seq(68L, 114L, by = 2L))
        for (j in seq_along(bins)) add_input(context$type, "frequency_at_length", "native_frequency",
          sample$counts[j], "fish", paste0(sar_name, ", Appendix A, ", sample$context),
          "Raw fish count by 2-cm total-length bin; bin value is the lower bound in cm. The assessment capped effective length-composition sample size at 200; sample_size is min(raw count, 200), while composition_sample_count retains the source total.",
          year = meta$year, fleet = context$fleet, survey = context$survey,
          sex = meta$sex, region = context$region, observation_id = observation_id,
          length_bin = bins[j], sample_size = min(meta$sample_count, 200L))
      } else {
        ages <- 2:30
        for (j in seq_along(ages)) add_input("biology", "conditional_frequency_at_age", "native_frequency",
          sample$counts[j], "fish", paste0(sar_name, ", Appendix B, ", sample$context),
          "Raw age count conditional on a 2-cm total-length bin. Age 30 is the plus group; sample_size is the assessment input count capped at 100 if needed, and composition_sample_count retains the source total.",
          year = meta$year, fleet = context$fleet, survey = context$survey,
          sex = meta$sex, region = context$region, age = ages[j],
          observation_id = observation_id, length_bin_lower = meta$bin,
          length_bin_upper = meta$bin + 2L, sample_size = min(meta$sample_count, 100L))
      }
      add_input("biology", "composition_sample_count", "numbers", meta$sample_count,
        "fish", paste0(sar_name, ", Appendix ", if (kind == "length") "A" else "B", ", ", sample$context),
        "Raw number of sampled fish in the source composition; retained separately from the capped likelihood sample_size.",
        year = meta$year, fleet = context$fleet, survey = context$survey,
        sex = meta$sex, region = context$region, observation_id = observation_id)
    }
  }
  `%||%` <- function(x, y) if (length(x) && !is.na(x)) x else y
  length_samples <- parse_length_samples()
  age_samples <- parse_age_samples()
  if (length(length_samples) != 150L || length(age_samples) != 967L)
    stop("Unexpected SEDAR 22 composition sample counts.", call. = FALSE)
  append_context_data(length_samples, "length")
  append_context_data(age_samples, "age")

  output_section <- table_section("^Table 3\\.7\\. Predicted total biomass")
  output_lines <- output_section[grepl("^[[:space:]]*(Virgin|(19|20)[0-9]{2})[[:space:]]", output_section)]
  if (length(output_lines) != 46L) stop("Unexpected SEDAR 22 Table 3.7 row count.", call. = FALSE)
  output_rows <- lapply(output_lines, function(line) {
    word <- tokens(line)
    label <- word[1L]
    values <- numeric_tokens(word[-1L])
    if (length(values) != 7L || any(!is.finite(values)))
      stop("Unexpected SEDAR 22 Table 3.7 row: ", line, call. = FALSE)
    list(label = label, values = values)
  })
  labels <- vapply(output_rows, `[[`, character(1L), "label")
  if (!identical(labels, c("Virgin", as.character(1965:2009))))
    stop("SEDAR 22 Table 3.7 year coverage changed.", call. = FALSE)
  output_year <- function(row) if (row$label == "Virgin") NA_integer_ else as.integer(row$label)
  for (row in output_rows) {
    virgin <- row$label == "Virgin"
    year <- output_year(row)
    scenario <- if (virgin) "Virgin" else ""
    for (region in c("East", "West")) {
      col <- if (region == "East") 1L else 4L
      add_output("biomass", "total_biomass", row$values[col], "pounds gutted weight",
        paste0(sar_name, ", Table 3.7"),
        "Regional total biomass from the central Stock Synthesis run.", year = year,
        region = region, scenario = scenario)
      add_output("biomass", "SSB", row$values[col + 1L], "thousand pounds gonad weight",
        paste0(sar_name, ", Table 3.7"),
        "Female gonad-weight spawning biomass; this is not conventional mature somatic biomass.",
        year = year, region = region, scenario = scenario)
      add_output("recruitment", "recruitment", row$values[col + 2L], "thousand fish",
        paste0(sar_name, ", Table 3.7"),
        "Age-0 recruitment from the central Stock Synthesis run.", year = year,
        age = 0L, region = region, scenario = scenario)
    }
    add_output("mortality", "exploitation_rate", row$values[7L], "ratio",
      paste0(sar_name, ", Table 3.7"),
      "Gulf-wide exploitation rate (catch / total biomass) used as a proxy for instantaneous F; it is not an age-specific instantaneous fishing mortality rate.",
      year = year, region = "Gulf", scenario = scenario)
  }

  if (input_n != 36719L || output_n != 322L)
    stop("Unexpected parsed tilefish row totals: ", input_n, " inputs; ", output_n,
      " outputs.", call. = FALSE)
  inputs <- as.data.frame(input_matrix[seq_len(input_n), , drop = FALSE],
    stringsAsFactors = FALSE, check.names = FALSE)
  outputs <- as.data.frame(output_matrix[seq_len(output_n), , drop = FALSE],
    stringsAsFactors = FALSE, check.names = FALSE)
  if (any(!is.finite(as.numeric(inputs$value))) || any(!is.finite(as.numeric(outputs$value))))
    stop("Tilefish import contains non-finite data.", call. = FALSE)

  assessment_url <- manifest$url[match(sar_name, manifest$file)]
  dw_url <- manifest$url[match("sedar22_dw01_golden_tilefish_age_growth_reproduction_2010.pdf", manifest$file)]
  aw_url <- manifest$url[match("sedar22_aw01_commercial_tilefish_index_1992-2009.pdf", manifest$file)]
  source_label <- paste0(sar_name, ", section 3, Tables 2.1-2.5, Table 3.7, Appendices A-B")
  assumptions <- data.frame(
    assessment_id = assessment_id,
    component = c("assessment", "assessment", "model", "population", "population",
      "catch", "catch", "observation", "observation", "biology", "M", "biology",
      "index", "survey", "output", "mortality"),
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = c("run_identity", "certification_status", "model_version", "spatial_structure",
      "age_structure", "discard_treatment", "catch_units", "length_composition",
      "conditional_age_composition", "age_error", "natural_mortality", "weight_and_maturity",
      "index_series", "sampling_time", "spawning_biomass_definition", "Gulf_F_proxy"),
    value = c(
      "SEDAR 22 final assessment; central SS Run 1; terminal data year 2009.",
      "Partial acceptance - Status determinations only.",
      "Stock Synthesis 3.10g.",
      "East and West Gulf regions; the model specified no movement between regions.",
      "Female and male growth patterns; age-0 recruitment; age 30 plus group.",
      "Commercial discards were combined with commercial landings; discard mortality was 100%; source totals are combined over 2002-2009 and cannot be allocated by year or region.",
      "Commercial and recreational landings are reported as gutted pounds.",
      "Numbers at total length in 2-cm bins from 20 to 114 cm; effective sample size capped at 200.",
      "Age counts are conditional on 2-cm total-length bins; age 30 is a plus group; effective sample size capped at 100.",
      "Mean coded ages 0.5-30.5; SD estimates from two readers, smoothed by the reported power function.",
      "Fixed M reference 0.137 at age 4; region- and sex-specific Lorenzen curves derived from growth. No year-varying M process.",
      "Region- and sex-specific growth and fixed weight-length inputs are described in the Data Workshop sources. Numerical annual stock weights-at-age and full maturity-at-age surfaces are not tabulated in the reviewed run sources. Female maturity is 50% at age 2.",
      "Standardized commercial longline and NMFS bottom-longline indices are reported separately for east and west Gulf regions; log-scale SEs are reported.",
      "The reviewed production report does not provide a fractional within-year timing for the annual index series; no timing value is imputed.",
      "SSB is female gonad weight in thousand pounds, not conventional mature somatic biomass.",
      "The Table 3.7 Gulf-wide F proxy is catch divided by total biomass (exploitation rate), not instantaneous age-specific F."),
    source_reference = c(rep(source_label, 11L), paste(dw_url, assessment_url, sep = "; "),
      source_label, source_label, source_label, source_label),
    notes = c(
      "The report identifies the Stock Synthesis central run as the assessment selected for reporting.",
      "NOAA Stock SMART records partial acceptance for status determinations. The Gulf SSC concluded the model did not capture dynamics well enough for quantitative OFL/ABC advice and recommended a landings-based approach.",
      "The assessment report names Stock Synthesis 3.10g in the process section.",
      "East and West are assessment areas within the Gulf unit, not separate stocks.",
      "Appendix B age observations begin at age 2; the model's reported age-0 recruits are separate population outputs.",
      "Table 2.3 reports aggregate discard counts for the full 2002-2009 period because of confidentiality. The assessment converts discards to weight using 5.2 gutted pounds per fish; no annual/area allocation is invented here.",
      "The database preserves the original weight units; no conversion to biomass tonnes is applied.",
      "Appendix A provides raw frequency counts. The separate composition_sample_count rows preserve raw sample totals; sample_size applies the reported maximum effective-size rule.",
      "Appendix B provides native age-by-length cells, not population age compositions or catch-at-age totals.",
      "Table 2.4 provides the age-error SD vector; age is retained as the mean coded age.",
      "The numeric full M-at-age vector is not tabulated in the reviewed production report and has not been reconstructed.",
      "Do not substitute fitted biological surfaces or values from another assessment for absent input vectors.",
      "Table 2.5 is the source-reported index scale and log-scale SE; missing years/series remain absent.",
      "Annual observation timing remains unresolved in the reviewed source; no seasonal default is supplied.",
      "Table 3.7 has no uncertainty intervals. Preserve the native female gonad-weight definition.",
      "Region- and fishery-specific instantaneous F estimates are described, but the table's Gulf-wide value is an exploitation-rate proxy."),
    stringsAsFactors = FALSE, check.names = FALSE)
  assumptions$source_reference[2L] <- paste(
    "sedar22_gulf_tilefish_ssc_review_2011.pdf;", source_label)

  stock_columns <- names(read.csv(file.path(root, "database/stocks.csv"), nrows = 0L,
    check.names = FALSE))
  assessment_columns <- names(read.csv(file.path(root, "database/assessments.csv"), nrows = 0L,
    check.names = FALSE))
  assumption_columns <- names(read.csv(file.path(root, "database/assumptions.csv"), nrows = 0L,
    check.names = FALSE))
  make_row <- function(columns, values) {
    out <- as.data.frame(setNames(rep(list(""), length(columns)), columns),
      stringsAsFactors = FALSE, check.names = FALSE)
    for (name in intersect(names(values), columns)) out[[name]] <- format_value(values[[name]])
    out
  }
  stock <- make_row(stock_columns, list(stock_id = stock_id, charbonneau_id = "",
    authority = "NOAA Fisheries", authority_stock_id = "10383",
    scientific_name = "Lopholatilus chamaeleonticeps", common_name = "Gulf of Mexico golden tilefish",
    area = "Gulf of Mexico", region = "United States Gulf of Mexico",
    ocean = "Northwest Atlantic",
    notes = "NOAA Stock SMART unit 10383. Distinct from South Atlantic and Mid-Atlantic golden tilefish units."))
  assessment <- make_row(assessment_columns, list(assessment_id = assessment_id,
    stock_id = stock_id, assessment_year = 2011, terminal_year = 2009,
    estimate_terminal_year = 2009, assessment_type = "full_assessment",
    model_family = "Stock Synthesis", model_version = "3.10g", is_current = TRUE,
    is_applied = TRUE, assessment_url = assessment_url, framework_url = "",
    data_url = paste(dw_url, aw_url, sep = "; "), model_url = assessment_url,
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "Current detailed assessment selected for the Gulf unit. NOAA records partial acceptance for status determinations only; Gulf SSC recommended landings-based OFL/ABC rather than quantitative advice from this model."))

  rows_for <- function(path, key, value) {
    prefix <- paste0('"', value, '",')
    result <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
      "--no-line-number", "-F", value, path), stdout = TRUE, stderr = FALSE))
    status <- attr(result, "status"); if (is.null(status)) status <- 0L
    if (status == 1L) result <- character() else if (status != 0L)
      stop("Could not inspect existing rows in ", path, call. = FALSE)
    result <- result[startsWith(result, prefix)]
    header <- readLines(path, n = 1L, warn = FALSE)
    if (!length(result)) return(read.csv(text = header, nrows = 0L,
      stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character"))
    read.csv(text = paste(c(header, result), collapse = "\n"), stringsAsFactors = FALSE,
      na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
  }
  normalize_frame <- function(x) {
    y <- as.data.frame(lapply(x, function(z) {z <- as.character(z); z[is.na(z)] <- ""; z}),
      stringsAsFactors = FALSE, check.names = FALSE)
    apply(y, 1L, paste, collapse = "\r")
  }
  identical_rows <- function(existing, expected, label) {
    if (!nrow(existing)) return(FALSE)
    if (!identical(names(existing), names(expected)) || nrow(existing) != nrow(expected) ||
        !identical(sort(normalize_frame(existing)), sort(normalize_frame(expected))))
      stop("Existing ", label, " rows differ from the source extraction.", call. = FALSE)
    TRUE
  }
  database <- file.path(root, "database")
  already_imported <- FALSE
  stock_exists <- data.frame()
  assessment_exists <- data.frame()
  if (write) {
    existing_stock <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
      na.strings = c("", "NA"), check.names = FALSE)
    stock_exists <- existing_stock[existing_stock$stock_id == stock_id, , drop = FALSE]
    existing_assessments <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
      na.strings = c("", "NA"), check.names = FALSE)
    assessment_exists <- existing_assessments[existing_assessments$assessment_id == assessment_id, , drop = FALSE]
    existing_assumptions <- rows_for(file.path(database, "assumptions.csv"), "assessment_id", assessment_id)
    existing_inputs <- rows_for(file.path(database, "inputs.csv"), "assessment_id", assessment_id)
    existing_outputs <- rows_for(file.path(database, "outputs.csv"), "assessment_id", assessment_id)
    already_imported <- nrow(stock_exists) == 1L && nrow(assessment_exists) == 1L &&
      identical_rows(existing_stock[names(stock), , drop = FALSE][existing_stock$stock_id == stock_id, , drop = FALSE], stock, "stock") &&
      identical_rows(existing_assessments[names(assessment), , drop = FALSE][existing_assessments$assessment_id == assessment_id, , drop = FALSE], assessment, "assessment") &&
      identical_rows(existing_assumptions, assumptions, "assumption") &&
      identical_rows(existing_inputs, inputs, "input") && identical_rows(existing_outputs, outputs, "output")
    has_any <- nrow(stock_exists) || nrow(assessment_exists) || nrow(existing_assumptions) ||
      nrow(existing_inputs) || nrow(existing_outputs)
    if (has_any && !already_imported)
      stop("A partial or conflicting Gulf golden tilefish canonical import exists; review it before writing.", call. = FALSE)
  }

  candidates_path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidate_row <- match(candidate_id, candidates$candidate_id)
  if (is.na(candidate_row) || candidates$official_stock_id[candidate_row] != "10383" ||
      candidates$scientific_name[candidate_row] != "Lopholatilus chamaeleonticeps")
    stop("The selected NOAA Gulf golden tilefish candidate identity changed.", call. = FALSE)
  candidate_updates <- list(matched_stock_id = stock_id, match_status = "matched",
    import_status = "partial",
    catch_age_evidence = paste("Imported commercial and recreational landings, aggregate commercial discard counts, and age counts conditional on 2-cm length bins for ages 2-30+. The age counts are not direct catch numbers-at-age; exact annual catch-at-age totals are not reported."),
    survey_age_evidence = paste("Imported commercial longline and NMFS bottom-longline relative indices by east/west region. Appendix B includes NMFS conditional age-at-length samples, not an age-specific abundance index."),
    weights_evidence = paste("The report and DW-01 document growth and weight-length assumptions, but the reviewed sources do not give a complete numerical model-compatible stock weight-at-age surface."),
    maturity_evidence = paste("The report documents female maturity at 50% near age 2 and gonad-weight spawning biomass, but a numerical age-specific maturity vector is not tabulated."),
    mortality_evidence = paste("The central run fixes reference M at 0.137 at age 4 and uses region/sex-specific Lorenzen curves derived from growth; the full numeric M-at-age input vector is not tabulated."),
    timing_evidence = paste("The annual commercial and NMFS bottom-longline index series are imported; fractional within-year sampling times are not specified in the reviewed production sources."),
    output_evidence = paste("Imported Table 3.7 regional total biomass, female gonad-weight spawning biomass, age-0 recruitment, and Gulf-wide exploitation-rate proxy for 1965-2009. The report does not provide numerical annual N-at-age or age-specific F surfaces."),
    review_date = "2026-11-12",
    decision_reason = paste("Partial source import complete from the latest detailed Gulf assessment located. Native annual catch/index series, raw length compositions, conditional age-at-length observations, age-error SDs and aggregate outputs are retained. Missing model inputs and unreported age-specific outputs remain explicit; no data from the 2026 triage papers were mixed in."),
    notes = paste("NOAA Stock SMART 10383 identifies the Gulf unit as SEDAR 22 (2011), data through 2009, partially accepted for status determinations only. The Gulf SSC advised against using this model for quantitative OFL/ABC. Canonical extraction is partial; no age-specific N/F outputs are reported. Separate 2026 data-triage materials are not part of this historical run."))
  if (!identical(candidates$import_status[candidate_row], "not_started") &&
      !identical(candidates$import_status[candidate_row], "partial"))
    stop("The candidate register has an unexpected import status.", call. = FALSE)
  if (!identical(candidates$match_status[candidate_row], "new") &&
      !identical(candidates$match_status[candidate_row], "matched"))
    stop("The candidate register has an unexpected match status.", call. = FALSE)

  selected_path <- file.path(root, "discovery/selected_batch_38_2026.csv")
  selected <- read.csv(selected_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  selected_row <- match(candidate_id, selected$candidate_id)
  if (is.na(selected_row)) stop("The tilefish candidate is absent from selected_batch_38_2026.csv.", call. = FALSE)
  selected_status <- "partial_source_import"
  if (!selected$curation_status[selected_row] %in% c("selected_for_source_curation", selected_status))
    stop("The tilefish selected-batch curation status changed unexpectedly.", call. = FALSE)

  if (write && !already_imported) {
    if (nrow(stock_exists)) stop("The Gulf tilefish stock row already exists.", call. = FALSE)
    if (nrow(assessment_exists)) stop("The Gulf tilefish assessment row already exists.", call. = FALSE)
    append_table <- function(table, rows) {
      path <- file.path(database, paste0(table, ".csv"))
      if (nrow(rows)) write.table(rows, path, sep = ",", row.names = FALSE,
        col.names = FALSE, append = TRUE, na = "", qmethod = "double", eol = "\n")
    }
    append_table("stocks", stock)
    append_table("assessments", assessment)
    append_table("assumptions", assumptions[, assumption_columns, drop = FALSE])
    append_table("inputs", inputs)
    append_table("outputs", outputs)
    source(file.path(root, "scripts/database/candidate_register_io.R"))
    for (name in names(candidate_updates)) candidates[[name]][candidate_row] <- candidate_updates[[name]]
    replace_candidate_register_row(candidates_path, candidate_row,
      candidates[candidate_row, , drop = FALSE], candidate_id)
    selected$curation_status[selected_row] <- selected_status
    replace_candidate_register_row(selected_path, selected_row,
      selected[selected_row, , drop = FALSE], candidate_id)
  }
  list(stock = stock, assessment = assessment, assumptions = assumptions,
    inputs = inputs, outputs = outputs, already_imported = already_imported,
    source_paths = source_paths)
}

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  result <- import_noaa_gulf_golden_tilefish(write = "--write" %in% args)
  cat("Gulf golden tilefish SEDAR 22 extraction: ", nrow(result$inputs),
    " inputs, ", nrow(result$outputs), " outputs; already imported = ",
    result$already_imported, ".\n", sep = "")
}
