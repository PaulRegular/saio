import_noaa_goa_rougheye_blackspotted_2023 <- function(root = ".", write = FALSE) {
  assessment_id <- "noaa_goa_rougheye_blackspotted_2023"
  stock_id <- "noaa_goa_rougheye_blackspotted"
  candidate_id <- "NOAA:11443"
  cache <- file.path(root, "source_cache/discovery_noaa_goa_rougheye_2023")
  manifest_path <- file.path(cache, "sources.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
    check.names = FALSE)
  source_file <- "goa_rougheye_2023_full.pdf"
  source_row <- manifest[manifest$file == source_file, , drop = FALSE]
  report <- file.path(cache, source_file)
  sha256_file <- function(path) {
    out <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path,
      winslash = "\\", mustWork = TRUE)), "SHA256"), stdout = TRUE)
    tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$",
      out, value = TRUE)))
  }
  if (nrow(source_row) != 1L || !file.exists(report) ||
      as.numeric(source_row$bytes) != file.info(report)$size ||
      !identical(sha256_file(report), tolower(source_row$sha256))) {
    stop("Cached 2023 GOA rougheye assessment failed its provenance check.",
      call. = FALSE)
  }
  .libPaths(c(file.path(root, "source_cache/.Rlib"), .libPaths()))
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    stop("pdftools is required to extract the cached NOAA report.",
      call. = FALSE)
  }
  pages <- pdftools::pdf_text(report)
  page_lines <- function(page) strsplit(pages[[page]], "\n", fixed = TRUE)[[1L]]
  number_tokens <- function(x) {
    token <- regmatches(x, gregexpr(
      "(?<![[:alnum:]])-?(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?",
      x, perl = TRUE))[[1L]]
    as.numeric(gsub(",", "", token, fixed = TRUE))
  }
  numeric_cell <- function(x) {
    x <- gsub(",", "", trimws(x), fixed = TRUE)
    if (x %in% c("-", "—", "")) return(NA_real_)
    suppressWarnings(as.numeric(x))
  }
  ref <- function(table, page) paste0(
    "2023 GOA Rougheye and Blackspotted SAFE, Table ", table,
    ", PDF p. ", page)
  input_path <- file.path(root, "database/inputs.csv")
  output_path <- file.path(root, "database/outputs.csv")
  assumption_path <- file.path(root, "database/assumptions.csv")
  csv_fields <- function(path) names(read.csv(text = readLines(path, n = 1L,
    warn = FALSE), nrows = 0L, check.names = FALSE))
  make_rows <- function(fields, values, n = NULL) {
    if (is.null(n)) n <- max(c(1L, lengths(values)))
    out <- lapply(fields, function(field) {
      value <- values[[field]]
      if (is.null(value)) return(rep("", n))
      if (length(value) == 1L) return(rep(value, n))
      if (length(value) != n) stop("Wrong row count for ", field, ".",
        call. = FALSE)
      value
    })
    names(out) <- fields
    as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
  }
  input_fields <- csv_fields(input_path)
  output_fields <- csv_fields(output_path)
  assumption_fields <- csv_fields(assumption_path)
  input_rows <- list()
  output_rows <- list()
  assumption_rows <- list()
  add_input <- function(values) input_rows[[length(input_rows) + 1L]] <<-
    make_rows(input_fields, values, 1L)
  add_output <- function(values) output_rows[[length(output_rows) + 1L]] <<-
    make_rows(output_fields, values, 1L)
  add_assumption <- function(component, setting, value, source_reference,
    notes, fleet = "", survey = "") {
    assumption_rows[[length(assumption_rows) + 1L]] <<- make_rows(
      assumption_fields, list(assessment_id = assessment_id,
        component = component, setting = setting, value = value,
        source_reference = source_reference, notes = notes,
        fleet = fleet, survey = survey, region = "Gulf of Alaska"), 1L)
  }
  input_base <- function(type, measure, basis, value, unit, year = NA_real_,
    age = NA_real_, length_bin = NA_real_, fleet = "", survey = "",
    sex = "combined", region = "Gulf of Alaska", sample_size = NA_real_,
    observation_id = "",
    notes = "", source_reference = "", transformation = "") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      basis = basis, value = value, unit = unit, year = year,
      year_basis = ifelse(is.na(year), "", "calendar_year"), age = age,
      fleet = fleet, survey = survey, sex = sex,
      region = region, sampling_time = NA_real_,
      source_type = "official_table", source_reference = source_reference,
      transformation = transformation, notes = notes,
      observation_id = observation_id, length_bin = length_bin,
      length_bin_lower = NA_real_, length_bin_upper = NA_real_,
      sample_size = sample_size, age_error = NA_real_, partition = "",
      weight_bin = "")
  }
  output_base <- function(type, measure, value, unit, year = NA_real_,
    age = NA_real_, age_group = "", scenario = "", se = NA_real_,
    lwr = NA_real_, upr = NA_real_, notes = "", source_reference = "",
    fleet = "", survey = "", source_type = "official_table") {
    list(assessment_id = assessment_id, type = type, measure = measure,
      fleet = fleet, survey = survey, sex = "combined",
      region = "Gulf of Alaska", year = year, age = age,
      age_group = age_group, scenario = scenario, value = value, se = se,
      lwr = lwr, upr = upr, unit = unit, source_type = source_type,
      source_reference = source_reference, notes = notes)
  }
  bind_rows <- function(x) {
    if (!length(x)) return(data.frame())
    out <- do.call(rbind, x)
    rownames(out) <- NULL
    out
  }

  matrix_table <- function(page_numbers, expected_bins) {
    rows <- list()
    samples <- numeric()
    hauls <- numeric()
    for (page in page_numbers) {
      lines <- page_lines(page)
      header <- grep("^\\s*(Age|Length|\\(cm\\)).*\\b(19|20)[0-9]{2}", lines,
        perl = TRUE)
      if (length(header) != 1L) stop("Could not identify matrix years on PDF p. ",
        page, ".", call. = FALSE)
      years <- as.integer(regmatches(lines[header], gregexpr(
        "(?:19|20)[0-9]{2}", lines[header], perl = TRUE))[[1L]])
      for (line in lines) {
        hit <- regmatches(line, regexec("^\\s*(\\d+\\+?)\\s+(.*)$",
          line, perl = TRUE))[[1L]]
        if (!length(hit)) next
        values <- number_tokens(hit[3L])
        if (length(values) != length(years)) next
        label <- hit[2L]
        bin <- as.numeric(sub("\\+$", "", label))
        rows[[length(rows) + 1L]] <- data.frame(
          bin = bin, plus_group = grepl("\\+$", label),
          year = years, value = values, stringsAsFactors = FALSE)
      }
      sample_line <- grep("^\\s*(?:Sample\\s+)?size\\s+", lines,
        value = TRUE, perl = TRUE)
      if (length(sample_line) == 1L) {
        sample_values <- number_tokens(sub(
          "^\\s*(?:Sample\\s+)?size\\s+", "", sample_line,
          perl = TRUE))
        if (length(sample_values) != length(years)) {
          stop("Unexpected sample sizes on PDF p. ", page, ".", call. = FALSE)
        }
        samples[as.character(years)] <- sample_values
      }
      haul_line <- grep("\\bhauls\\s+", lines, value = TRUE, perl = TRUE)
      if (length(haul_line) == 1L) {
        haul_values <- number_tokens(sub(".*\\bhauls\\s+", "", haul_line,
          perl = TRUE))
        if (length(haul_values) != length(years)) {
          stop("Unexpected haul counts on PDF p. ", page, ".", call. = FALSE)
        }
        hauls[as.character(years)] <- haul_values
      }
    }
    result <- do.call(rbind, rows)
    rownames(result) <- NULL
    if (nrow(result) != length(expected_bins) * length(unique(result$year)) ||
        !setequal(unique(result$bin), expected_bins) ||
        anyDuplicated(paste(result$year, result$bin))) {
      stop("Unexpected age/length matrix coverage on PDF pages ",
        paste(page_numbers, collapse = ", "), ".", call. = FALSE)
    }
    if (any(!as.character(unique(result$year)) %in% names(samples)) ||
        any(!as.character(unique(result$year)) %in% names(hauls))) {
      stop("Published sample sizes or haul counts are missing for a matrix.",
        call. = FALSE)
    }
    result$sample_size <- unname(samples[as.character(result$year)])
    result$haul_count <- unname(hauls[as.character(result$year)])
    result
  }
  add_composition <- function(x, measure, type, fleet, survey, table,
    pages_ref, note, bin_type, check_sum = TRUE) {
    sums <- tapply(x$value, x$year, sum)
    if (check_sum && any(abs(sums - 1) > 0.01)) {
      stop("Rounded proportions do not sum near one in Table ", table, ".",
        call. = FALSE)
    }
    for (i in seq_len(nrow(x))) {
      row <- x[i, ]
      plus_note <- if (row$plus_group) {
        if (bin_type == "age") paste0(" The ", row$bin,
          "+ category is a plus group; age stores its lower bound.") else
          " The 60+ length category is stored at its lower bound."
      } else ""
      add_input(input_base(type, measure, "proportion_numbers", row$value,
        "proportion", year = row$year,
        age = if (bin_type == "age") row$bin else NA_real_,
        length_bin = if (bin_type == "length") row$bin else NA_real_,
        fleet = fleet, survey = survey, sample_size = row$sample_size,
        observation_id = paste0("table13_", table, "_", row$year),
        source_reference = ref(table, pages_ref),
        notes = paste0(note, " First-stage sample size is fish; number of hauls ",
          "is ", row$haul_count, ". Source proportions are not renormalized.",
          plus_note)))
    }
  }

  ## Catch, compositions, indices and biological inputs
  catch_lines <- page_lines(45)
  catch_rows <- list()
  for (line in catch_lines) {
    hit <- regmatches(line, regexec("^\\s*((?:19|20)[0-9]{2})\\s+(.*)$",
      line, perl = TRUE))[[1L]]
    if (!length(hit)) next
    year <- as.integer(hit[2L])
    if (!year %in% 1977:2023) next
    cells <- strsplit(trimws(line), "\\s{2,}", perl = TRUE)[[1L]]
    if (length(cells) < 2L) next
    total <- numeric_cell(cells[2L])
    if (!is.finite(total)) next
    catch_rows[[length(catch_rows) + 1L]] <- data.frame(
      year = year, area = "Gulf of Alaska total", value = total,
      stringsAsFactors = FALSE)
    if (year >= 2005L) {
      if (length(cells) < 5L) stop("Missing area catches in Table 13-2 for ",
        year, ".", call. = FALSE)
      for (j in 3:5) {
        catch_rows[[length(catch_rows) + 1L]] <- data.frame(
          year = year,
          area = c("Western GOA", "Central GOA", "Eastern GOA")[j - 2L],
          value = numeric_cell(cells[j]), stringsAsFactors = FALSE)
      }
    }
  }
  catches <- do.call(rbind, catch_rows)
  if (!setequal(unique(catches$year[catches$area == "Gulf of Alaska total"]),
      1977:2022) || sum(catches$year >= 2005 & catches$area !=
        "Gulf of Alaska total") != 18L * 3L) {
    stop("Unexpected Table 13-2 catch coverage.", call. = FALSE)
  }
  for (i in seq_len(nrow(catches))) {
    x <- catches[i, ]
    add_input(input_base("catch", "catch_biomass", "biomass", x$value,
      "metric tons", year = x$year, fleet = "All fisheries",
      observation_id = paste("catch", x$year, gsub(" ", "_", x$area),
        sep = "_"), source_reference = ref("13-2", "45"),
      region = x$area,
      notes = paste("Reported commercial catch by area. Total and area rows ",
        "are not additive. The report provides catch only through 2022; ",
        "2023 is shown as unavailable.")))
  }

  fishery_age <- matrix_table(c(51L, 52L), c(3:41, 42))
  if (!setequal(unique(fishery_age$year), c(1990, 2004, 2006, 2008, 2009,
      2010, 2012, 2014, 2016, 2018, 2020, 2022))) {
    stop("Unexpected Table 13-8 fishery age years.", call. = FALSE)
  }
  add_composition(fishery_age, "proportion_at_age", "catch",
    "GOA fishery observer samples", "", "13-8", "51-52",
    "Fishery age composition; Table 13-8 reports sample sizes and haul counts.",
    "age")
  fishery_size <- matrix_table(53L, c(seq(20, 58, by = 2), 60))
  add_composition(fishery_size, "proportion_at_length", "catch",
    "GOA fishery observer samples", "", "13-9", "53",
    "Fishery length composition pooled in adjacent 2-cm bins. The printed annual columns sum to roughly 0.5 and the report does not explain the scale; values are retained as printed and not renormalized.",
    "length", check_sum = FALSE)
  survey_age <- matrix_table(c(56L, 57L), c(3:41, 42))
  add_composition(survey_age, "proportion_at_age", "index", "",
    "GOA bottom-trawl survey", "13-11", "56-57",
    "Bottom-trawl survey age composition. The 1984 and 1987 samples are published but excluded from the author-preferred Model 23.1b.",
    "age")
  survey_trawl_size <- matrix_table(58L, c(seq(20, 58, by = 2), 60))
  add_composition(survey_trawl_size, "proportion_at_length", "index", "",
    "GOA bottom-trawl survey", "13-12", "58",
    "Bottom-trawl survey length composition; the report explicitly states these data are not fit in the population model.",
    "length")
  survey_longline_size <- matrix_table(c(59L, 60L), c(seq(20, 58, by = 2), 60))
  add_composition(survey_longline_size, "proportion_at_length", "index", "",
    "GOA longline survey", "13-13", "59-60",
    "Area-weighted longline survey length composition pooled in adjacent 2-cm bins.",
    "length")

  ## GOA-wide bottom-trawl biomass and longline RPN indices
  survey_rows <- list()
  for (page in c(54L, 55L)) {
    for (line in page_lines(page)) {
      hit <- regmatches(line, regexec("^\\s*((?:19|20)[0-9]{2})\\s+",
        line, perl = TRUE))[[1L]]
      if (!length(hit)) next
      year <- as.integer(hit[2L])
      cells <- strsplit(trimws(line), "\\s{2,}", perl = TRUE)[[1L]]
      if (length(cells) < 3L) next
      for (j in 2:3) {
        cell <- trimws(cells[j])
        if (cell %in% c("-", "—")) next
        parsed <- regmatches(cell, regexec(
          "^([0-9,]+(?:\\.[0-9]+)?)\\s*\\(([0-9.]+)\\)$",
          cell, perl = TRUE))[[1L]]
        if (!length(parsed)) stop("Could not parse Table 13-10 index cell: ",
          cell, ".", call. = FALSE)
        survey_rows[[length(survey_rows) + 1L]] <- data.frame(
          year = year, kind = if (j == 2L) "trawl" else "longline",
          value = as.numeric(gsub(",", "", parsed[2L], fixed = TRUE)),
          cv = as.numeric(parsed[3L]), stringsAsFactors = FALSE)
      }
    }
  }
  indices <- do.call(rbind, survey_rows)
  trawl_years <- c(1984, 1987, 1990, 1993, 1996, 1999, 2003, 2005, 2007,
    2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)
  if (!setequal(indices$year[indices$kind == "trawl"], trawl_years) ||
      !setequal(indices$year[indices$kind == "longline"], 1993:2023)) {
    stop("Unexpected Table 13-10 GOA-wide survey-index coverage.",
      call. = FALSE)
  }
  for (i in seq_len(nrow(indices))) {
    x <- indices[i, ]
    survey <- if (x$kind == "trawl") "GOA bottom-trawl survey" else
      "GOA longline survey"
    measure <- if (x$kind == "trawl") "relative_biomass_index" else
      "relative_abundance_index"
    cv_measure <- if (x$kind == "trawl") "biomass_index_cv" else
      "abundance_index_cv"
    unit <- if (x$kind == "trawl") "metric tons (survey biomass scale)" else
      "relative population numbers (RPN)"
    note <- if (x$kind == "trawl" && x$year %in% c(1984, 1987)) {
      "GOA-wide design-based index and CV. The assessment report says 1984 and 1987 bottom-trawl observations were removed from the author-preferred Model 23.1b."
    } else {
      "GOA-wide design-based index and CV used as relative abundance information in the assessment model; this is not an absolute population estimate."
    }
    observation_id <- paste0("table13_10_", x$kind, "_", x$year)
    add_input(input_base("index", measure, "index_scale", x$value, unit,
      year = x$year, survey = survey, observation_id = observation_id,
      source_reference = ref("13-10", if (x$year <= 2014L) "54" else "55"),
      notes = note))
    add_input(input_base("index", cv_measure, "relative_scale", x$cv,
      "ratio", year = x$year, survey = survey,
      observation_id = observation_id, source_reference = ref("13-10",
        if (x$year <= 2014L) "54" else "55"),
      notes = "The coefficient of variation is reported in parentheses in Table 13-10 and is retained separately from its index."))
  }

  biology_lines <- c(page_lines(63L), page_lines(64L))
  biology_rows <- list()
  for (line in biology_lines) {
    hit <- regmatches(line, regexec("^\\s*(\\d+\\+?)\\s+(.*)$",
      line, perl = TRUE))[[1L]]
    if (!length(hit)) next
    values <- number_tokens(hit[3L])
    if (length(values) != 12L) next
    label <- hit[2L]
    biology_rows[[length(biology_rows) + 1L]] <- data.frame(
      age = as.numeric(sub("\\+$", "", label)),
      plus_group = grepl("\\+$", label),
      n_at_age = values[1L], maturity_percent = values[3L],
      weight_g = values[5L], fishery_sel = values[7L],
      trawl_sel = values[9L], longline_sel = values[11L],
      stringsAsFactors = FALSE)
  }
  biology <- do.call(rbind, biology_rows)
  if (nrow(biology) != 50L || !identical(as.integer(biology$age), 3:52)) {
    stop("Unexpected Table 13-16 age surface.", call. = FALSE)
  }
  for (i in seq_len(nrow(biology))) {
    x <- biology[i, ]
    age_group <- if (x$plus_group) "52+" else ""
    suffix <- if (x$plus_group) " The source age group is 52+." else ""
    add_input(input_base("weight", "weight_at_age", "g_per_fish",
      x$weight_g, "g per fish", age = x$age,
      source_reference = ref("13-16", if (x$age <= 39) "63" else "64"),
      notes = paste0("Model 23.1b population weight-at-age; Model 15.4 values appear in parentheses and are not imported.", suffix)))
    add_input(input_base("biology", "maturity_at_age", "proportion",
      x$maturity_percent / 100, "proportion", age = x$age,
      source_reference = ref("13-16", if (x$age <= 39) "63" else "64"),
      transformation = "Source percent divided by 100.",
      notes = paste0("Model 23.1b maturity-at-age, reported as percent and converted to proportion. Model 15.4 values appear in parentheses.", suffix)))
    add_output(output_base("biology", "fleet_selectivity_at_age",
      x$fishery_sel / 100, "proportion", age = x$age, age_group = age_group,
      fleet = "GOA fishery",
      source_reference = ref("13-16", if (x$age <= 39) "63" else "64"),
      notes = paste0("Reported percent selected-at-age converted to a proportion. This is selectivity, not fishing mortality.", suffix)))
    add_output(output_base("biology", "fleet_selectivity_at_age",
      x$trawl_sel / 100, "proportion", age = x$age, age_group = age_group,
      survey = "GOA bottom-trawl survey",
      source_reference = ref("13-16", if (x$age <= 39) "63" else "64"),
      notes = paste0("Reported percent selected-at-age converted to a proportion. This is selectivity, not fishing mortality.", suffix)))
    add_output(output_base("biology", "fleet_selectivity_at_age",
      x$longline_sel / 100, "proportion", age = x$age, age_group = age_group,
      survey = "GOA longline survey",
      source_reference = ref("13-16", if (x$age <= 39) "63" else "64"),
      notes = paste0("Reported percent selected-at-age converted to a proportion. This is selectivity, not fishing mortality.", suffix)))
    add_output(output_base("population", "numbers_at_age", x$n_at_age,
      "thousands of fish", year = 2023L, age = x$age,
      age_group = age_group, source_reference = ref("13-16",
        if (x$age <= 39) "63" else "64"),
      notes = paste0("Model 23.1b point estimate for 2023; no age-specific uncertainty is reported.", suffix)))
  }
  add_output(output_base("population", "total_numbers",
    sum(biology$n_at_age), "thousands of fish", year = 2023L,
    source_type = "derived_source_output",
    source_reference = ref("13-16", "63-64"),
    notes = "Derived as the sum of reported Model 23.1b numbers-at-age for ages 3-51 and the 52+ accumulator. No joint uncertainty is reported."))

  ## Assessment time series, intervals and scalar parameters
  mle_rows <- list()
  for (line in page_lines(65L)) {
    hit <- regmatches(line, regexec("^\\s*((?:19|20)[0-9]{2})\\s+(.*)$",
      line, perl = TRUE))[[1L]]
    if (!length(hit)) next
    values <- number_tokens(hit[3L])
    if (length(values) != 8L) next
    mle_rows[[length(mle_rows) + 1L]] <- data.frame(
      year = as.integer(hit[2L]), ssb = values[2L],
      recruitment = values[4L], biomass = values[6L],
      stringsAsFactors = FALSE)
  }
  mle <- do.call(rbind, mle_rows)
  if (nrow(mle) != 47L || !identical(sort(mle$year), 1977:2023)) {
    stop("Unexpected Table 13-17 Model 23.1b time series.", call. = FALSE)
  }
  for (i in seq_len(nrow(mle))) {
    x <- mle[i, ]
    for (spec in list(
      list(measure = "SSB", value = x$ssb, unit = "metric tons"),
      list(measure = "recruitment", value = x$recruitment,
        unit = "thousands of fish (age 3)"),
      list(measure = "total_biomass", value = x$biomass,
        unit = "metric tons"))) {
      add_output(output_base("population", spec$measure, spec$value,
        spec$unit, year = x$year, scenario = "Model 23.1b MLE",
        source_reference = ref("13-17", "65"),
        notes = "Maximum-likelihood point estimate; Table 13-17 reports no uncertainty intervals."))
    }
  }
  posterior_rows <- list()
  for (line in page_lines(66L)) {
    hit <- regmatches(line, regexec("^\\s*((?:19|20)[0-9]{2})\\s+(.*)$",
      line, perl = TRUE))[[1L]]
    if (!length(hit)) next
    values <- number_tokens(hit[3L])
    if (length(values) != 9L) next
    posterior_rows[[length(posterior_rows) + 1L]] <- data.frame(
      year = as.integer(hit[2L]),
      recruitment = values[1L], recruitment_lwr = values[2L],
      recruitment_upr = values[3L],
      biomass = values[4L], biomass_lwr = values[5L],
      biomass_upr = values[6L],
      ssb = values[7L], ssb_lwr = values[8L], ssb_upr = values[9L],
      stringsAsFactors = FALSE)
  }
  posterior <- do.call(rbind, posterior_rows)
  if (nrow(posterior) != 47L ||
      !identical(sort(posterior$year), 1977:2023)) {
    stop("Unexpected Table 13-18 posterior time series.", call. = FALSE)
  }
  for (i in seq_len(nrow(posterior))) {
    x <- posterior[i, ]
    for (spec in list(
      list(measure = "SSB", value = x$ssb, lwr = x$ssb_lwr,
        upr = x$ssb_upr, unit = "metric tons"),
      list(measure = "recruitment", value = x$recruitment,
        lwr = x$recruitment_lwr, upr = x$recruitment_upr,
        unit = "thousands of fish (age 3)"),
      list(measure = "total_biomass", value = x$biomass,
        lwr = x$biomass_lwr, upr = x$biomass_upr, unit = "metric tons"))) {
      add_output(output_base("population", spec$measure, spec$value,
        spec$unit, year = x$year, scenario = "Model 23.1b MCMC posterior mean",
        lwr = spec$lwr, upr = spec$upr, source_reference = ref("13-18", "66"),
        notes = "Posterior mean with the published 2.5% and 97.5% credible interval."))
    }
  }
  parameter_lines <- page_lines(62L)
  for (spec in list(
    list(label = "Longline q", survey = "GOA longline survey",
      values = c(1.01, 0.92, 1.11, 1.02, 1.02, 0.93, 1.11)),
    list(label = "Trawl q", survey = "GOA bottom-trawl survey",
      values = c(1.06, 0.97, 1.16, 1.06, 1.05, 0.96, 1.15)))) {
    if (!any(grepl(paste0("M23.1b_2023\\s+", spec$label), parameter_lines,
        perl = TRUE))) stop("Table 13-15 is missing ", spec$label, ".",
      call. = FALSE)
    values <- spec$values
    add_output(output_base("catchability", "q", values[1L], "relative scale",
      scenario = "Model 23.1b MLE", lwr = values[2L], upr = values[3L],
      survey = spec$survey, source_reference = ref("13-15", "62"),
      notes = "MLE and Hessian-derived 95% confidence interval."))
    add_output(output_base("catchability", "q", values[4L], "relative scale",
      scenario = "Model 23.1b MCMC posterior mean", lwr = values[6L],
      upr = values[7L], survey = spec$survey,
      source_reference = ref("13-15", "62"),
      notes = "MCMC mean and published 95% Bayesian credible interval."))
  }
  add_assumption("mortality", "natural_mortality",
    "0.042 per year", ref("13-15", "62"),
    "Natural mortality is fixed at 0.042 per year in the author-preferred Model 23.1b; the table reports no uncertainty for this fixed value.")
  add_output(output_base("mortality", "natural_mortality_average_parameter",
    0.042, "per year", scenario = "Model 23.1b fixed",
    source_reference = ref("13-15", "62"),
    notes = "Fixed natural mortality, not an estimated value; no uncertainty is reported."))
  add_assumption("recruitment", "recruitment_sd",
    "1.10", ref("13-15", "62"),
    "Recruitment variability sigmaR is fixed at 1.10 in Model 23.1b.")
  add_assumption("index", "survey_timing",
    "Not reported", ref("13-10", "54-55"),
    "The report gives survey years and index values but does not report within-year sampling-time fractions.")
  add_assumption("observation", "catch_at_age",
    "Not reported", ref("13-2", "45"),
    "Aggregate catches and fishery age compositions are available separately, but the assessment report does not provide catch-at-age numbers or the fishery weight-at-age needed for a documented reconstruction.")
  add_assumption("observation", "composition_likelihood_weights",
    "Fishery ages 1; trawl survey ages 1; fishery sizes 1; trawl survey sizes 0; longline sizes 1",
    ref("13-14", "61"),
    "The likelihood table gives the listed weights for Model 23.1b. The report does not provide an effective sample-size transformation for the proportions.")
  add_assumption("observation", "catch_likelihood_weights",
    "5 for 1977-2005; 50 for 2005-present", ref("13-14", "61"),
    "The source reports these catch likelihood weights; the year 2005 appears in both printed period labels.")
  add_assumption("observation", "survey_index_likelihood_weights",
    "1 for bottom-trawl biomass; 1 for longline biomass/RPN",
    ref("13-14", "61"),
    "The report assigns likelihood weight 1 to both GOA-wide survey index series.")
  add_assumption("observation", "F_regularization_weight",
    "0.1", ref("13-14", "61"),
    "The likelihood table gives 0.1 as the fishing-mortality regularity weight for Model 23.1b.")
  add_assumption("catchability", "survey_q_priors",
    "Lognormal prior mean 1.0 and CV 0.05 for both surveys",
    "2023 GOA SAFE, Table 13-15 and section 'Parameters Estimated Inside the Assessment Model'",
    "The preferred model uses informed priors for catchability; reported estimates and intervals are stored separately.")
  add_assumption("biology", "maturity_curve",
    "Age-50 = 23.17 years; instantaneous maturation rate = -0.164 per year",
    "2023 GOA SAFE, section 'Maturity' and Table 13-16",
    "The logistic maturity curve was estimated from GOA-specific 2009 and 2010 research cruises, bottom-trawl surveys and fishery observer samples, then used as a fixed biological input to the population model.")
  add_assumption("biology", "ageing_error",
    "Numerical age-error matrix not reported", ref("13-16", "63-64"),
    "The assessment describes an updated ageing-error matrix, but the numerical matrix is not tabulated in the reviewed report.")
  add_assumption("biology", "age_length_transition",
    "Numerical age-length transition matrix not reported", ref("13-16", "63-64"),
    "The assessment uses an age-length transition matrix; its numerical entries are not published in the reviewed report.")
  add_assumption("index", "bottom_trawl_early_index_use",
    "1984 and 1987 observations excluded from Model 23.1b",
    ref("13-10", "54"),
    "The observations are retained as source input rows, with their exclusion from the author-preferred model identified in each row.")

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
      any(stocks$authority_stock_id == "11443", na.rm = TRUE) ||
      any(assessments$assessment_id == assessment_id)) {
    stop("GOA rougheye stock or assessment already exists; inspect before reimporting.",
      call. = FALSE)
  }
  stock_fields <- csv_fields(stocks_path)
  assessment_fields <- csv_fields(assessments_path)
  stock <- make_rows(stock_fields, list(stock_id = stock_id,
    charbonneau_id = "", authority = "NOAA Fisheries",
    authority_stock_id = "11443",
    scientific_name = "Sebastes aleutianus; Sebastes melanostictus",
    common_name = "Rougheye and blackspotted rockfish complex",
    area = "Gulf of Alaska", region = "Gulf of Alaska",
    ocean = "Northeast Pacific",
    notes = "NOAA Stock SMART ID 11443. This is the current Gulf of Alaska management unit; the complex is assessed together."), 1L)
  assessment <- make_rows(assessment_fields, list(
    assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2023, terminal_year = 2023,
    estimate_terminal_year = 2023, assessment_type = "full_assessment",
    model_family = "AD Model Builder statistical catch-at-age",
    model_version = "Model 23.1b",
    is_current = TRUE, is_applied = TRUE,
    assessment_url = source_row$url,
    data_url = manifest$url[manifest$file ==
      "goa_rougheye_2025_catch_report.pdf"],
    assumptions_status = "partial", inputs_status = "partial",
    outputs_status = "partial",
    notes = paste("The December 2023 SAFE recommends Model 23.1b. The official December 2025 GOA catch report says the most recent full assessment was 2023 and no assessment was conducted in 2025. A 2026 full-assessment document was uploaded for November Plan Team review but had not yet been reviewed as of 2026-11-12. The source import retains published age compositions, aggregate catches, survey indices, biological inputs, scalar parameters and population outputs; catch-at-age, F-at-age and several model matrices are unavailable. See discovery/source_reviews/noaa_goa_rougheye_blackspotted_2023.md.")), 1L)

  cat("NOAA GOA rougheye/blackspotted 2023 source extraction\n")
  cat("Inputs:", nrow(inputs), "rows (catch, age/length compositions, survey indices, weight and maturity at age).\n")
  cat("Outputs:", nrow(outputs), "rows (2023 N-at-age, selectivity, MLE and MCMC biomass/recruitment/SSB, and q).\n")
  cat("Catch-at-age, fishing mortality at age, survey timing and numerical model matrices are not invented.\n")
  if (!write) {
    cat("Dry run only. Add --write to append the reviewed source records.\n")
    return(list(stock = stock, assessment = assessment,
      assumptions = assumptions, inputs = inputs, outputs = outputs))
  }
  for (name in c("stocks", "assessments", "assumptions", "inputs", "outputs")) {
    path <- file.path(root, "database", paste0(name, ".csv"))
    expected <- csv_fields(path)
    rows <- switch(name, stocks = stock, assessments = assessment,
      assumptions = assumptions, inputs = inputs, outputs = outputs)
    if (!identical(names(rows), expected)) {
      stop("Import rows do not match database columns for ", name, ".",
        call. = FALSE)
    }
  }
  append_csv <- function(rows, path) write.table(rows, file = path, sep = ",",
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    quote = TRUE, qmethod = "double", eol = "\n")
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
    stop("Expected one screened, eligible NOAA:11443 candidate.",
      call. = FALSE)
  }
  candidates$candidate_unit_id[ci] <- stock_id
  candidates$matched_stock_id[ci] <- stock_id
  candidates$match_status[ci] <- "matched"
  candidates$import_status[ci] <- "partial"
  candidates$detailed_source_url[ci] <- source_row$url
  candidates$review_date[ci] <- "2026-11-12"
  candidates$catch_age_evidence[ci] <- paste(
    "Imported 1977-2022 aggregate catch and fishery age compositions.",
    "Annual catch-at-age numbers and separate fishery weight-at-age are not reported, so catch-at-age is not reconstructed.")
  candidates$survey_age_evidence[ci] <- paste(
    "Imported bottom-trawl age compositions, GOA-wide bottom-trawl biomass and longline RPN indices with CVs.",
    "Longline age compositions are unavailable; 1984/1987 trawl ages and indices are retained but identified as excluded from Model 23.1b.")
  candidates$weights_evidence[ci] <- "Imported Model 23.1b population weight-at-age in grams; fishery-specific weight-at-age is not reported."
  candidates$maturity_evidence[ci] <- "Imported Model 23.1b maturity-at-age, converted from reported percent to proportion; the underlying samples and uncertainty are not fully tabulated."
  candidates$mortality_evidence[ci] <- "Natural mortality is fixed at 0.042 per year in Model 23.1b; no age-specific M or uncertainty is reported."
  candidates$timing_evidence[ci] <- "Survey years and index series are reported; within-year survey timing fractions are not stated."
  candidates$output_evidence[ci] <- paste(
    "Imported MLE and MCMC posterior mean time series for SSB, age-3 recruitment, and age-3+ biomass through 2023, with MCMC credible intervals.",
    "2023 N-at-age and selectivity-at-age are reported without uncertainty; F-at-age is unavailable.")
  candidates$decision_reason[ci] <- paste(
    "The 2025 official catch report states that the most recent full assessment was 2023 and no assessment was conducted in 2025.",
    "The 2026 full-assessment document uploaded for the upcoming November Plan Team meeting was not yet reviewed as of 2026-11-12.")
  candidates$notes[ci] <- paste(
    "Partial source import from the 2023 SAFE, Model 23.1b. Rounded proportions are retained without renormalization; source sample sizes and haul counts are recorded.",
    "See discovery/source_reviews/noaa_goa_rougheye_blackspotted_2023.md and provenance/discovery_noaa_goa_rougheye_2023/sources.csv.")
  replace_candidate_register_row(candidate_path, ci,
    candidates[ci, , drop = FALSE], candidate_id)
  inventory_path <- file.path(root, "discovery/inventory_units.csv")
  inventory <- read.csv(inventory_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  ir <- candidate_inventory_row(inventory, candidate_id, stock_id)
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
  if (length(bi) > 1L) stop("NOAA:11443 appears more than once in the selected batch.",
    call. = FALSE)
  if (length(bi) == 1L) {
    batch$curation_status[bi] <- "partial_source_import"
    replace_candidate_register_row(batch_path, bi,
      batch[bi, , drop = FALSE], candidate_id)
  }
  provenance_dir <- file.path(root,
    "provenance/discovery_noaa_goa_rougheye_2023")
  dir.create(provenance_dir, recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(manifest_path, file.path(provenance_dir, "sources.csv"),
      overwrite = TRUE)) stop("Could not write tracked source provenance.",
        call. = FALSE)
  cat("GOA rougheye rows appended; candidate status set to partial.\n")
  invisible(list(stock = stock, assessment = assessment,
    assumptions = assumptions, inputs = inputs, outputs = outputs))
}

if (!interactive() && sys.nframe() == 0L) {
  import_noaa_goa_rougheye_blackspotted_2023(write =
    "--write" %in% commandArgs(trailingOnly = TRUE))
}
