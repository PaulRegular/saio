import_ices_wgnas_2026 <- function(root = ".", write = FALSE) {
  cache <- file.path(root, "source_cache", "discovery_ices_wgnas_2026")
  manifest_path <- file.path(root, "provenance", "ices_wgnas_2026", "sources.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)

  sha256_file <- function(path) {
    result <- system2("certutil.exe", c("-hashfile",
      shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
      stdout = TRUE, stderr = FALSE)
    hash <- toupper(trimws(grep(
      "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
    )))
    if (length(hash) != 1L) stop("Could not hash source file: ", path, call. = FALSE)
    hash
  }

  verify_source <- function(source) {
    row <- manifest[manifest$source == source, , drop = FALSE]
    path <- file.path(cache, source)
    if (nrow(row) != 1L || !file.exists(path) ||
        file.info(path)$size != as.numeric(row$bytes) ||
        !identical(sha256_file(path), toupper(row$sha256))) {
      stop("Cached WGNAS source failed its provenance check: ", source, call. = FALSE)
    }
    path
  }

  report_url <- "https://iceslibrary.figshare.com/articles/report/Working_Group_on_North_Atlantic_Salmon_WGNAS_/32034120"
  data_url <- "https://doi.org/10.17895/ices.pub.32034120.v1"
  invisible(verify_source("wgnas_2026_report.pdf"))
  invisible(verify_source("wgnas_2026_addendum.pdf"))
  invisible(verify_source("section_2_online_tables_2026.zip"))
  invisible(verify_source("neac_online_tables_2026.zip"))
  invisible(verify_source("nac_online_tables_2026.zip"))

  csv_files <- list.files(cache, recursive = TRUE, full.names = TRUE,
    pattern = "[.]csv$")
  find_table <- function(table_number) {
    matches <- csv_files[grepl(paste0("Table ", table_number), basename(csv_files), fixed = TRUE)]
    if (length(matches) != 1L) {
      stop("Expected one WGNAS online table ", table_number, ".", call. = FALSE)
    }
    read.csv(matches, stringsAsFactors = FALSE, check.names = FALSE,
      na.strings = c("", "NA"))
  }

  catch <- find_table("2.1.1.3")
  required_catch_columns <- c("country_name", "year", paste0(
    rep(c("number_", "weight_"), 8L),
    rep(c("1sw", "2sw", "3sw", "4sw", "5sw", "msw", "ps", "total"), each = 2L)
  ))
  if (!identical(names(catch), required_catch_columns) || nrow(catch) != 599L ||
      min(catch$year, na.rm = TRUE) != 1980L ||
      max(catch$year, na.rm = TRUE) != 2025L) {
    stop("WGNAS Table 2.1.1.3 no longer matches the reviewed catch table.", call. = FALSE)
  }

  stock_ids <- c(NAC = "ices_salmo_salar_nac", NEAC = "ices_salmo_salar_neac")
  assessment_ids <- setNames(paste0(unname(stock_ids), "_2026"), names(stock_ids))
  stock_codes <- c(NAC = "sal.nac.all", NEAC = "sal.neac.all")
  country_sets <- list(
    NAC = c("Canada", "SPM", "USA"),
    NEAC = c("Denmark", "Faroes", "Finland", "France", "Germany", "Iceland",
      "Ireland", "Norway", "Portugal", "Russia", "Spain", "Sweden",
      "UK (E&W)", "UK (NI)", "UK (Scot)")
  )
  if (!setequal(unique(catch$country_name), c(country_sets$NAC, country_sets$NEAC, "Greenland"))) {
    stop("WGNAS Table 2.1.1.3 country coverage differs from the reviewed mapping.", call. = FALSE)
  }

  stock_fields <- names(read.csv(file.path(root, "database", "stocks.csv"),
    nrows = 0L, check.names = FALSE))
  assessment_fields <- names(read.csv(file.path(root, "database", "assessments.csv"),
    nrows = 0L, check.names = FALSE))
  assumption_fields <- names(read.csv(file.path(root, "database", "assumptions.csv"),
    nrows = 0L, check.names = FALSE))
  input_fields <- names(read.csv(file.path(root, "database", "inputs.csv"),
    nrows = 0L, check.names = FALSE))
  output_fields <- names(read.csv(file.path(root, "database", "outputs.csv"),
    nrows = 0L, check.names = FALSE))

  make_row <- function(fields, values) {
    numeric_fields <- c("assessment_year", "terminal_year", "estimate_terminal_year",
      "framework_year", "year", "age", "value", "se", "lwr", "upr",
      "sampling_time", "length_bin", "length_bin_lower", "length_bin_upper",
      "sample_size", "age_error", "weight_bin")
    out <- lapply(fields, function(field) {
      value <- values[[field]]
      if (is.null(value)) {
        return(if (field %in% numeric_fields) NA_real_ else "")
      }
      value
    })
    names(out) <- fields
    as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
  }

  stock_row <- function(complex) {
    code <- stock_codes[[complex]]
    area <- if (complex == "NAC") {
      "North American salmon complex (ICES stock key sal.nac.all)"
    } else {
      "Northeast Atlantic and Arctic salmon complex (ICES stock key sal.neac.all)"
    }
    region <- if (complex == "NAC") "North America" else "Northeast Atlantic and Arctic"
    ocean <- if (complex == "NAC") "Northwest Atlantic" else "Northeast Atlantic"
    make_row(stock_fields, list(
      stock_id = stock_ids[[complex]], charbonneau_id = "", authority = "ICES",
      authority_stock_id = code, scientific_name = "Salmo salar",
      common_name = "Atlantic salmon", area = area, region = region, ocean = ocean,
      notes = paste("Official ICES stock key", code,
        "represented in the joint WGNAS 2026 assessment. Greenland mixed-stock fishery data are not assigned to this stock.")
    ))
  }

  assessment_row <- function(complex) {
    stock_id <- stock_ids[[complex]]
    assessment_id <- assessment_ids[[complex]]
    make_row(assessment_fields, list(
      assessment_id = assessment_id, stock_id = stock_id,
      assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2029L,
      assessment_type = "full_assessment",
      model_family = "Run reconstruction model and Bayesian life-cycle model",
      model_version = "WGNAS 2026 assessment",
      is_current = "TRUE", is_applied = "TRUE", framework_year = NA_real_,
      assessment_url = report_url, framework_url = "",
      data_url = data_url, model_url = "", repository_url = "",
      assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
      notes = paste("This row represents ICES stock key", stock_codes[[complex]],
        "within the joint WGNAS 2026 assessment, using data through 2025.",
        "Online tables include forecasts through 2029; forecast rows are labeled.",
        "The public tables do not provide a complete native input set or conventional annual N/F/M-at-age outputs.")
    ))
  }

  input_rows <- list()
  add_input <- function(assessment_id, country, year, category, measure, value, unit, basis) {
    input_rows[[length(input_rows) + 1L]] <<- make_row(input_fields, list(
      assessment_id = assessment_id, type = "catch", measure = measure, basis = basis,
      fleet = "", survey = "", sex = "", region = country, season = "annual",
      year = as.integer(year), year_basis = "calendar_year", value = as.numeric(value),
      unit = unit, source_type = "official_table",
      source_reference = "ICES WGNAS 2026, online Table 2.1.1.3",
      transformation = "Reshaped from the published country-by-year table without unit conversion.",
      notes = paste("Reported nominal catch by sea-age category and country.",
        "The source table does not establish each series as an independent model likelihood input;",
        "published categories and total columns are retained separately and must not be summed together."),
      observation_id = paste0("WGNAS2026_", category, "_", measure)
    ))
  }
  categories <- c("1sw", "2sw", "3sw", "4sw", "5sw", "msw", "ps", "total")
  for (complex in names(country_sets)) {
    selected <- catch[catch$country_name %in% country_sets[[complex]], , drop = FALSE]
    for (i in seq_len(nrow(selected))) {
      for (category in categories) {
        for (kind in c("number", "weight")) {
          value <- selected[[paste0(kind, "_", category)]][i]
          if (is.na(value)) next
          measure <- if (kind == "number") "catch_numbers" else "catch_biomass"
          basis <- if (kind == "number") "numbers" else "biomass"
          unit <- if (kind == "number") "fish" else "tonnes round fresh weight"
          add_input(assessment_ids[[complex]], selected$country_name[i],
            selected$year[i], toupper(category), measure, value, unit, basis)
        }
      }
    }
  }

  assumption_rows <- list()
  add_assumption <- function(complex, component, setting, value, reference, notes,
                             region = "") {
    assumption_rows[[length(assumption_rows) + 1L]] <<- make_row(
      assumption_fields, list(assessment_id = assessment_ids[[complex]],
        component = component, region = region, setting = setting,
        value = as.character(value), source_reference = reference, notes = notes)
    )
  }
  for (complex in names(stock_ids)) {
    add_assumption(complex, "model", "model_approach",
      "Run reconstruction model and Bayesian life-cycle model",
      "WGNAS 2026 report, assessment methods",
      "A stage-based life-cycle assessment; it does not report a conventional annual age-structured F/M model.")
    add_assumption(complex, "model", "multi_sea_winter_proxy", "2SW",
      "WGNAS 2026 report, assessment methods",
      "The report uses 2SW as a proxy for multi-sea-winter salmon.")
  }
  nac_biology <- find_table("4.2.1.1")
  if (!identical(names(nac_biology),
      c("Stock unit", "Region", "Prop_fem_1SW", "Prop_fem_MSW", "Egg_fem_1SW", "Egg_fem_MSW")) ||
      nrow(nac_biology) != 19L) {
    stop("WGNAS Table 4.2.1.1 no longer matches the reviewed NAC biology table.", call. = FALSE)
  }
  biological_settings <- c(
    Prop_fem_1SW = "proportion_female_1SW",
    Prop_fem_MSW = "proportion_female_MSW",
    Egg_fem_1SW = "eggs_per_female_1SW",
    Egg_fem_MSW = "eggs_per_female_MSW"
  )
  for (i in seq_len(nrow(nac_biology))) {
    for (field in names(biological_settings)) {
      add_assumption("NAC", "biology", biological_settings[[field]],
        nac_biology[[field]][i], "WGNAS 2026, online Table 4.2.1.1",
        paste("Published for stock unit", nac_biology[["Stock unit"]][i],
          "and region", nac_biology$Region[i], ". This is not a complete age-specific weight or maturity vector."),
        region = nac_biology$Region[i])
    }
  }

  output_rows <- list()
  add_output <- function(complex, measure, year, value, lower, upper, unit,
                         region, age_group, source_reference, notes, scenario = "") {
    if (is.na(value)) return(invisible(NULL))
    output_rows[[length(output_rows) + 1L]] <<- make_row(output_fields, list(
      assessment_id = assessment_ids[[complex]], type = "population",
      measure = measure, region = region, year = as.integer(year),
      age_group = age_group, value = as.numeric(value), se = NA_real_,
      lwr = as.numeric(lower), upr = as.numeric(upper), unit = unit,
      source_type = "official_table", source_reference = source_reference,
      notes = notes, scenario = scenario
    ))
  }
  parse_year <- function(value) {
    raw <- trimws(as.character(value))
    year <- suppressWarnings(as.integer(sub(".*?((19|20)[0-9]{2}).*", "\\1", raw, perl = TRUE)))
    forecast <- grepl("^Forecast", raw, ignore.case = TRUE)
    list(year = year, scenario = ifelse(forecast, "Forecast", ""))
  }
  interval_note <- paste(
    "The source estimate is a median; lwr/upr preserve the 5th/95th percentile quantiles (90% interval), not a 95% confidence interval."
  )

  add_neac_table <- function(table_number, complex, measure, age_group, reference) {
    data <- find_table(table_number)
    years <- parse_year(data$Year)
    median_columns <- grep("_median$", names(data), value = TRUE)
    if (!length(median_columns)) stop("No median columns in WGNAS Table ", table_number, ".", call. = FALSE)
    for (i in seq_len(nrow(data))) {
      if (is.na(years$year[i]) || years$year[i] < 1971L || years$year[i] > 2025L) next
      for (median_column in median_columns) {
        source_region <- sub("_median$", "", median_column)
        quantile_region <- if (source_region == "NO") "Norway" else source_region
        lower_column <- paste0(quantile_region, "_5%")
        upper_column <- paste0(quantile_region, "_95%")
        value <- suppressWarnings(as.numeric(data[[median_column]][i]))
        lower <- if (lower_column %in% names(data)) suppressWarnings(as.numeric(data[[lower_column]][i])) else NA_real_
        upper <- if (upper_column %in% names(data)) suppressWarnings(as.numeric(data[[upper_column]][i])) else NA_real_
        region <- if (source_region == "NO") "Norway" else source_region
        add_output(complex, measure, years$year[i], value, lower, upper,
          "thousand fish", region, age_group, reference, interval_note)
      }
    }
  }
  neac_specs <- data.frame(
    table = paste0("3.3.4.", 1:8),
    complex = c("NEAC", "NEAC", "NEAC", "NEAC", "NEAC", "NEAC", "NEAC", "NEAC"),
    measure = c("returns", "returns", "spawners", "spawners", "returns", "returns", "spawners", "spawners"),
    age_group = c("1SW", "MSW", "1SW", "MSW", "1SW", "MSW", "1SW", "MSW"),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(neac_specs))) {
    table_number <- neac_specs$table[i]
    add_neac_table(table_number, neac_specs$complex[i], neac_specs$measure[i],
      paste0(neac_specs$age_group[i], " ",
        if (i <= 4L) "N-NEAC" else "S-NEAC"),
      paste0("WGNAS 2026, online Table ", table_number))
  }

  add_nac_table <- function(table_number, measure, age_group) {
    data <- find_table(table_number)
    years <- parse_year(data$Year)
    estimate_columns <- grep("p50$", names(data), value = TRUE)
    if (!length(estimate_columns)) stop("No median columns in WGNAS Table ", table_number, ".", call. = FALSE)
    for (i in seq_len(nrow(data))) {
      if (is.na(years$year[i]) || years$year[i] < 1970L || years$year[i] > 2029L) next
      for (estimate_column in estimate_columns) {
        region <- sub("p50$", "", estimate_column)
        add_output("NAC", measure, years$year[i],
          suppressWarnings(as.numeric(data[[estimate_column]][i])),
          suppressWarnings(as.numeric(data[[paste0(region, "p05")]][i])),
          suppressWarnings(as.numeric(data[[paste0(region, "p95")]][i])),
          "thousand fish", region, age_group,
          paste0("WGNAS 2026, online Table ", table_number), interval_note,
          scenario = ifelse(years$scenario[i] != "", "Forecast", ""))
      }
    }
  }
  for (i in seq_along(c("Small", "Large", "2SW"))) {
    size_group <- c("Small", "Large", "2SW")[i]
    add_nac_table(paste0("4.3.3.", i), "returns", size_group)
    add_nac_table(paste0("4.3.4.", i), "spawners", size_group)
  }

  add_pfa_wide <- function(data, complex, age_group, table_number, year_column,
                           statistic_column = NULL, pfa_style = c("neac", "nac")) {
    pfa_style <- match.arg(pfa_style)
    years <- parse_year(data[[year_column]])
    if (!is.null(statistic_column)) {
      forecast_status <- tolower(trimws(as.character(data[[statistic_column]]))) == "forecast"
      years$scenario[forecast_status] <- "Forecast"
    }
    if (pfa_style == "neac") {
      median_columns <- grep("_median$", names(data), value = TRUE)
      for (i in seq_len(nrow(data))) {
        if (is.na(years$year[i]) || years$year[i] < 1971L || years$year[i] > 2029L) next
        status <- if (!is.null(statistic_column)) trimws(as.character(data[[statistic_column]][i])) else ""
        if (nzchar(status) && !status %in% c("Hindcast", "Forecast")) next
        for (median_column in median_columns) {
          region <- sub("_median$", "", median_column)
          add_output(complex, "pre_fishery_abundance", years$year[i],
            suppressWarnings(as.numeric(data[[median_column]][i])),
            suppressWarnings(as.numeric(data[[paste0(region, "_q5")]][i])),
            suppressWarnings(as.numeric(data[[paste0(region, "_q95")]][i])),
            "thousand fish", region, age_group,
            paste0("WGNAS 2026, online Table ", table_number), interval_note,
            scenario = ifelse(years$scenario[i] != "", "Forecast", ""))
        }
      }
    } else {
      groups <- c(maturing = "1SW maturing",
        non_maturing = "1SW non-maturing", tot = "total")
      for (i in seq_len(nrow(data))) {
        if (is.na(years$year[i]) || years$year[i] < 1971L || years$year[i] > 2029L) next
        for (suffix in names(groups)) {
          add_output(complex, "pre_fishery_abundance", years$year[i],
            suppressWarnings(as.numeric(data[[paste0("NAC_median_", suffix)]][i])),
            suppressWarnings(as.numeric(data[[paste0("NAC_q5_", suffix)]][i])),
            suppressWarnings(as.numeric(data[[paste0("NAC_q95_", suffix)]][i])),
            "thousand fish", "NAC", groups[[suffix]],
            paste0("WGNAS 2026, online Table ", table_number), interval_note,
            scenario = ifelse(years$scenario[i] != "", "Forecast", ""))
        }
      }
    }
  }

  for (i in 1:4) {
    table_number <- paste0("3.3.5.", i)
    data <- find_table(table_number)
    status <- ifelse(i %in% c(1L, 3L), "maturing", "non-maturing")
    complex <- ifelse(i <= 2L, "NEAC", "NEAC")
    north_south <- ifelse(i <= 2L, "N-NEAC", "S-NEAC")
    age_group <- paste("1SW", status, north_south)
    add_pfa_wide(data, complex, age_group, table_number, "year",
      statistic_column = "statistic", pfa_style = "neac")
  }
  nac_pfa <- find_table("4.3.6.1")
  add_pfa_wide(nac_pfa, "NAC", "NAC 1SW stages", "4.3.6.1",
    "year", pfa_style = "nac")

  nac_biology <- find_table("4.2.1.1")
  for (complex in names(stock_ids)) {
    stock_rows <- stock_row(complex)
    assessment_rows <- assessment_row(complex)
    if (complex == "NAC") {
      for (i in seq_len(nrow(nac_biology))) {
        if (any(!is.finite(as.numeric(nac_biology[i, 3:6])))) {
          stop("WGNAS NAC biology table contains non-numeric cells.", call. = FALSE)
        }
      }
    }
  }

  stocks <- do.call(rbind, lapply(names(stock_ids), stock_row))
  assessments <- do.call(rbind, lapply(names(stock_ids), assessment_row))
  assumptions <- do.call(rbind, assumption_rows)
  inputs <- do.call(rbind, input_rows)
  outputs <- do.call(rbind, output_rows)

  input_key <- c("assessment_id", "type", "measure", "basis", "region",
    "year", "observation_id")
  output_key <- c("assessment_id", "type", "measure", "region", "year",
    "age_group", "scenario")
  if (nrow(stocks) != 2L || nrow(assessments) != 2L ||
      anyDuplicated(inputs[input_key]) || anyDuplicated(outputs[output_key]) ||
      !all(stock_codes %in% stocks$authority_stock_id) ||
      !any(outputs$measure == "returns") || !any(outputs$measure == "spawners") ||
      !any(outputs$measure == "pre_fishery_abundance") ||
      !any(outputs$scenario == "Forecast") || any(outputs$year > 2029L, na.rm = TRUE)) {
    stop("WGNAS records have unexpected identity, dimensions, or duplicates.", call. = FALSE)
  }

  result <- list(stocks = stocks, assessments = assessments,
    assumptions = assumptions, inputs = inputs, outputs = outputs)
  cat("WGNAS 2026 source tables; two official ICES stock keys.
")
  cat("  inputs: ", nrow(inputs), " nominal catch records by country and source sea-age class.
", sep = "")
  cat("  assumptions: ", nrow(assumptions), " model/biological records.
", sep = "")
  cat("  outputs: ", nrow(outputs), " returns, spawners and PFA records.
", sep = "")
  cat("  data through 2025; forecasts are labeled through 2029.
")

  if (!write) {
    cat("Dry run only. Add --write to append the verified rows.
")
    return(invisible(result))
  }

  csv_row_signature <- function(data) {
    values <- lapply(data, function(x) {
      if (is.numeric(x)) {
        out <- format(x, scientific = FALSE, trim = TRUE, digits = 15)
        out[is.na(x)] <- ""
      } else {
        out <- as.character(x)
        out[is.na(x)] <- ""
      }
      out
    })
    do.call(paste, c(values, sep = "\r"))
  }
  assert_record_or_absent <- function(path, proposed, id_field) {
    existing <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
      check.names = FALSE)
    rows <- existing[existing[[id_field]] == proposed[[id_field]][1L], , drop = FALSE]
    if (nrow(rows) && (nrow(rows) != 1L ||
        !identical(csv_row_signature(rows[names(proposed)]),
          csv_row_signature(proposed)))) {
      stop("Existing ", id_field, " row conflicts with WGNAS source record.", call. = FALSE)
    }
    nrow(rows) == 1L
  }
  read_matching_rows <- function(path, id) {
    rg <- Sys.which("rg")
    if (!nzchar(rg)) stop("rg is required to check existing assessment rows.", call. = FALSE)
    found <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading",
      "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
    status <- attr(found, "status")
    if (is.null(status)) status <- 0L
    if (status == 1L) return(data.frame())
    if (status != 0L) stop("Could not scan ", path, call. = FALSE)
    found <- found[startsWith(found, paste0('"', id, '",'))]
    if (!length(found)) return(data.frame())
    header <- readLines(path, n = 1L, warn = FALSE)
    read.csv(text = paste(c(header, found), collapse = "\n"),
      stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  }
  append_csv <- function(data, path) {
    if (!nrow(data)) return(invisible(NULL))
    write.table(data, path, sep = ",", row.names = FALSE, col.names = FALSE,
      append = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8")
  }
  rows_to_add <- function(existing, proposed, keys, label) {
    if (!nrow(existing)) return(proposed)
    key <- function(data) {
      values <- lapply(data[keys], function(x) {
        x <- as.character(x)
        x[is.na(x)] <- ""
        x
      })
      do.call(paste, c(values, sep = "\r"))
    }
    existing_keys <- key(existing)
    proposed_keys <- key(proposed)
    keep <- logical(nrow(proposed))
    for (i in seq_len(nrow(proposed))) {
      match <- which(existing_keys == proposed_keys[i])
      if (!length(match)) {
        keep[i] <- TRUE
      } else if (length(match) != 1L ||
          !identical(csv_row_signature(existing[match, names(proposed), drop = FALSE]),
            csv_row_signature(proposed[i, , drop = FALSE]))) {
        stop("Existing ", label, " rows conflict with the reviewed WGNAS import.", call. = FALSE)
      }
    }
    proposed[keep, , drop = FALSE]
  }

  stock_path <- file.path(root, "database", "stocks.csv")
  assessment_path <- file.path(root, "database", "assessments.csv")
  assumptions_path <- file.path(root, "database", "assumptions.csv")
  inputs_path <- file.path(root, "database", "inputs.csv")
  outputs_path <- file.path(root, "database", "outputs.csv")
  stock_exists <- logical(nrow(stocks))
  assessment_exists <- logical(nrow(assessments))
  for (i in seq_len(nrow(stocks))) {
    stock_exists[i] <- assert_record_or_absent(stock_path, stocks[i, , drop = FALSE], "stock_id")
  }
  for (i in seq_len(nrow(assessments))) {
    assessment_exists[i] <- assert_record_or_absent(assessment_path,
      assessments[i, , drop = FALSE], "assessment_id")
  }

  existing_assumptions <- do.call(rbind, lapply(assessment_ids, function(id) {
    read_matching_rows(assumptions_path, id)
  }))
  existing_inputs <- do.call(rbind, lapply(assessment_ids, function(id) {
    read_matching_rows(inputs_path, id)
  }))
  existing_outputs <- do.call(rbind, lapply(assessment_ids, function(id) {
    read_matching_rows(outputs_path, id)
  }))
  assumption_add <- rows_to_add(existing_assumptions, assumptions,
    c("assessment_id", "component", "region", "setting"), "assumption")
  input_add <- rows_to_add(existing_inputs, inputs,
    c("assessment_id", "type", "measure", "basis", "region", "year", "observation_id"),
    "input")
  output_add <- rows_to_add(existing_outputs, outputs,
    c("assessment_id", "type", "measure", "region", "year", "age_group", "scenario"),
    "output")

  if (any(!stock_exists)) append_csv(stocks[!stock_exists, , drop = FALSE], stock_path)
  if (any(!assessment_exists)) append_csv(assessments[!assessment_exists, , drop = FALSE],
    assessment_path)
  append_csv(assumption_add, assumptions_path)
  append_csv(input_add, inputs_path)
  append_csv(output_add, outputs_path)

  source(file.path(root, "scripts", "database", "candidate_register_io.R"),
    local = TRUE)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  for (complex in names(stock_ids)) {
    candidate_id <- paste0("ICES:", stock_codes[[complex]])
    row <- which(candidates$candidate_id == candidate_id)
    if (length(row) != 1L || candidates$eligibility[row] != "eligible") {
      stop("Expected one eligible WGNAS candidate: ", candidate_id, call. = FALSE)
    }
    candidates$candidate_unit_id[row] <- stock_ids[[complex]]
    candidates$matched_stock_id[row] <- stock_ids[[complex]]
    candidates$match_status[row] <- "matched"
    candidates$inventory_assessment_year[row] <- 2026L
    candidates$review_date[row] <- "2026-11-13"
    candidates$import_status[row] <- "partial"
    candidates$catch_age_evidence[row] <- paste(
      "WGNAS 2026 Table 2.1.1.3 is imported as country-year nominal catches by sea-age label in observation_id.",
      "The source categories are not numeric ages and are not confirmed as independent fitted likelihood inputs."
    )
    candidates$survey_age_evidence[row] <- paste(
      "Regional CPUE, returns and smolt information are presented in the life-cycle assessment.",
      "No conventional independent age-specific abundance index for this stock unit was recovered."
    )
    candidates$weights_evidence[row] <- if (complex == "NAC") {
      "WGNAS 2026 Table 4.2.1.1 supplies sex proportions and eggs per female by stock unit and 1SW/MSW group; a numeric weight-at-age vector was not recovered."
    } else {
      "No numeric NEAC stock-specific weight-at-sea-age input was recovered from the reviewed 2026 online tables."
    }
    candidates$maturity_evidence[row] <- if (complex == "NAC") {
      "Table 4.2.1.1 supplies female proportions and eggs per female for 1SW/MSW; this is not a complete maturity-at-age vector."
    } else {
      "No numeric NEAC maturity-at-sea-age vector was recovered from the reviewed 2026 online tables."
    }
    candidates$mortality_evidence[row] <- paste(
      "WGNAS uses a run-reconstruction and life-cycle framework; no conventional annual F-at-age or M-at-age surface was found."
    )
    candidates$timing_evidence[row] <- paste(
      "The assessment follows smolt, post-smolt, 1SW and MSW stages; conventional survey timing fractions do not apply to the imported output tables."
    )
    candidates$output_evidence[row] <- paste(
      "WGNAS 2026 returns, spawners and pre-fishery abundance are imported with median estimates and 5th/95th percentiles.",
      "The intervals are 90% quantile intervals. Conventional N/F/M-at-age, SSB and recruitment series were not recovered."
    )
    candidates$decision_reason[row] <- paste(
      "Partial source curation of the latest joint WGNAS assessment; the NAC and NEAC keys are retained as separate official ICES stock units."
    )
    candidates$notes[row] <- paste(
      "Data through 2025; forecast rows are labeled through 2029.",
      "See source_reviews/", stock_ids[[complex]], ".md.",
      "WGNAS 2026 report and online tables are shared across NAC and NEAC."
    )
    replace_candidate_register_row(candidate_path, row,
      candidates[row, , drop = FALSE], candidate_id)
  }

  discovery_review <- file.path(root, "discovery", "source_reviews", "ices_final_five_2026.md")
  review_lines <- readLines(discovery_review, warn = FALSE, encoding = "UTF-8")
  old <- grep("^sal[.]nac[.]all and sal[.]neac[.]all are eligible", review_lines)
  if (length(old) == 1L) {
    review_lines[old] <- paste(
      "sal.nac.all and sal.neac.all are distinct official ICES stock keys, represented by the same joint WGNAS 2026 assessment and online report.",
      "Both now have partial source imports; see source_reviews/ices_salmo_salar_nac.md and source_reviews/ices_salmo_salar_neac.md.",
      "No exact canonical stock match existed before this import.",
      "sal.wgc.all is the West Greenland mixed-stock fishery affecting NAC and NEAC populations, not a separate biological stock."
    )
  }
  review_lines <- gsub(
    "Current sources are cached under the gitignored source_cache/discovery_ices_remaining_units_2026/.",
    "Current WGNAS sources are cached under the gitignored source_cache/discovery_ices_wgnas_2026/.",
    review_lines, fixed = TRUE
  )
  writeLines(review_lines, discovery_review, useBytes = TRUE)

  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "002_validate_database.R"),
    local = new.env(parent = globalenv()))
  cat("WGNAS source import written; database validation passed.
")
  invisible(result)
}

if (sys.nframe() == 0L) {
  import_ices_wgnas_2026(write = "--write" %in% commandArgs(trailingOnly = TRUE))
}
