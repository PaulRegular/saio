root <- "."
source_cache <- file.path(root, "source_cache/discovery_noaa_china_rockfish_2019")
manifest_path <- file.path(root, "provenance/discovery_noaa_china_rockfish_2019/sources.csv")
report_url <- "https://www.pcouncil.org/documents/2016/04/status-of-china-rockfish-off-the-u-s-pacific-coast-in-2015-april-2016.pdf"
safe_url <- "https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

.libPaths(c(file.path(root, "source_cache/R-library"), file.path(root, "source_cache/R-lib"), .libPaths()))
source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

sha256_file <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(tolower(digest::digest(object = readBin(path, what = "raw", n = file.info(path)$size), algo = "sha256", serialize = FALSE)))
  }
  output <- system2("certutil.exe", c("-hashfile", shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"), stdout = TRUE)
  hash <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", output, value = TRUE)))
  if (length(hash) != 1L) stop("Could not verify a cached source checksum.", call. = FALSE)
  hash
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = "character")
required <- c("china_rockfish_assessment_2015.pdf", "pacific_groundfish_SAFE_2025.pdf",
  "noaa_fy2025_assessment_snapshot.pdf", "china_rockfish_projection_SAFE_2022.pdf")
if (!all(c("file", "url", "retrieved_on", "bytes", "sha256", "revision") %in% names(manifest)) ||
    anyDuplicated(manifest$file) || !all(required %in% manifest$file)) {
  stop("The China rockfish source manifest is incomplete.", call. = FALSE)
}
for (name in required) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(source_cache, name)
  if (nrow(row) != 1L || !file.exists(path) ||
      file.info(path)$size != as.numeric(row$bytes) ||
      sha256_file(path) != tolower(row$sha256)) {
    stop("Cached source failed provenance validation: ", name, call. = FALSE)
  }
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached China rockfish assessment report.", call. = FALSE)
}
report_path <- normalizePath(file.path(source_cache, "china_rockfish_assessment_2015.pdf"), mustWork = TRUE)
lines <- unlist(strsplit(paste(pdftools::pdf_text(report_path), collapse = "\n"), "\n", fixed = TRUE),
  use.names = FALSE)

parse_area <- function(area_index) {
  markers <- grep("^#C data file for China rockfish ", lines)
  if (length(markers) != 3L) stop("Expected three area-specific Stock Synthesis data files.", call. = FALSE)
  start <- markers[area_index]
  end <- if (area_index < 3L) markers[area_index + 1L] - 1L else {
    appendix_b <- which(seq_along(lines) > start & grepl("^Appendix B\\.", lines))
    if (!length(appendix_b)) stop("Could not locate Appendix B after the southern data file.", call. = FALSE)
    appendix_b[1L] - 1L
  }
  section <- lines[start:end]
  value_after <- function(pattern) {
    i <- grep(pattern, section)[1L]
    if (is.na(i)) stop("Missing model-data field: ", pattern, call. = FALSE)
    as.integer(sub(" .*", "", trimws(section[i])))
  }
  n_fleet <- value_after("#_Nfleet")
  n_survey <- value_after("#_Nsurveys")
  n_age <- value_after("#_Nages")
  n_catch <- value_after("#_N_lines_of_catch_to_read")
  fleet_header <- grep("fleet names", section)[1L]
  next_fleet <- fleet_header + which(grepl("^##\\s*[0-9]+_", section[(fleet_header + 1L):length(section)]))[1L]
  if (is.na(fleet_header) || is.na(next_fleet)) stop("Could not parse area fleet names.", call. = FALSE)
  fleet_text <- paste(gsub("\\s+", "", section[(fleet_header + 1L):(next_fleet - 1L)]), collapse = "")
  fleet_names <- sub("^[0-9]+_", "", strsplit(fleet_text, "%", fixed = TRUE)[[1L]])
  if (length(fleet_names) != n_fleet + n_survey) stop("Fleet and survey labels do not align with the native model counts.", call. = FALSE)
  catch_header <- grep("#_catch_biomass", section)[1L]
  catch_rows <- list()
  carry <- numeric()
  for (line in section[(catch_header + 1L):length(section)]) {
    value <- trimws(sub("#.*$", "", line))
    if (!grepl("^[-+0-9.]", value)) next
    tokens <- suppressWarnings(as.numeric(strsplit(value, "\\s+")[[1L]]))
    if (!length(tokens) || anyNA(tokens)) next
    if (length(tokens) == 1L && !length(carry)) next
    carry <- c(carry, tokens)
    while (length(carry) >= n_fleet + 2L) {
      catch_rows[[length(catch_rows) + 1L]] <- carry[seq_len(n_fleet + 2L)]
      carry <- carry[-seq_len(n_fleet + 2L)]
    }
    if (length(catch_rows) == n_catch) break
  }
  if (length(catch_rows) != n_catch || length(carry)) stop("Could not recover complete catch rows from the area model file.", call. = FALSE)
  catch <- as.data.frame(do.call(rbind, catch_rows))
  names(catch) <- c(fleet_names[seq_len(n_fleet)], "year", "season")
  catch$year <- as.integer(catch$year)
  catch$season <- as.integer(catch$season)
  if (!identical(catch$year, 1900:2014) || any(catch$season != 1L)) {
    stop("Unexpected China rockfish catch year or season coverage.", call. = FALSE)
  }
  list(section = section, n_fleet = n_fleet, n_survey = n_survey,
    n_age = n_age, fleets = fleet_names, catch = catch)
}

parse_output_table <- function(table_number) {
  starts <- grep(paste0("^Table ", table_number, ": Time-series of population estimates"), lines)
  if (!length(starts)) stop("Missing population output table ", table_number, ".", call. = FALSE)
  start <- starts[1L]
  captions <- which(grepl("^Table [0-9]+:", lines))
  caption_numbers <- as.integer(sub("^Table ([0-9]+):.*$", "\\1", lines[captions]))
  next_caption <- captions[captions > start & caption_numbers != table_number]
  if (!length(next_caption)) stop("Could not delimit output table ", table_number, ".", call. = FALSE)
  end <- next_caption[1L] - 1L
  rows <- list()
  for (line in lines[start:end]) {
    tokens <- suppressWarnings(as.numeric(strsplit(trimws(line), "\\s+")[[1L]]))
    if (length(tokens) %in% c(5L, 8L) && !anyNA(tokens) && tokens[1L] %in% 1900:2015) {
      rows[[length(rows) + 1L]] <- tokens
    }
  }
  if (length(rows) != 116L || !identical(vapply(rows, `[[`, 0.0, 1L), as.numeric(1900:2015)) ||
      any(lengths(rows)[seq_len(115L)] != 8L) || lengths(rows)[116L] != 5L) {
    stop("Unexpected year or column coverage in population table ", table_number, ".", call. = FALSE)
  }
  row_widths <- lengths(rows)
  rows <- lapply(rows, function(x) c(x, rep(NA_real_, 8L - length(x))))
  out <- do.call(rbind, rows)
  colnames(out) <- c("year", "total_biomass", "spawning_biomass", "depletion",
    "recruitment", "total_catch", "relative_exploitation_rate", "spr")
  out
}

parse_2015_summary <- function(table_letter) {
  start <- grep(paste0("^Table ", table_letter, ": Summary of reference points"), lines)[1L]
  if (is.na(start)) stop("Missing 2015 reference table ", table_letter, ".", call. = FALSE)
  next_table <- which(seq_along(lines) > start & grepl("^Table [A-Za-z0-9]+:", lines))
  section <- lines[start:(next_table[1L] - 1L)]
  values <- function(pattern) {
    row <- grep(pattern, section, value = TRUE)[1L]
    if (is.na(row)) stop("Missing 2015 summary statistic: ", pattern, call. = FALSE)
    numbers <- suppressWarnings(as.numeric(regmatches(row,
      gregexpr("[0-9]+(?:\\.[0-9]+)?", row, perl = TRUE))[[1L]]))
    if (length(numbers) < 4L) stop("Could not parse summary estimate and interval: ", row, call. = FALSE)
    tail(numbers, 3L)
  }
  list(spawning_output = values("Spawning output \\(2015, billions of eggs\\)"),
    depletion = values("Depletion \\(2015\\)"))
}

stock_ids <- c("noaa_china_rockfish_northern_pacific_coast",
  "noaa_china_rockfish_central_pacific_coast",
  "noaa_china_rockfish_southern_pacific_coast")
candidate_ids <- c("NOAA:14410", "NOAA:14430", "NOAA:14429")
areas <- c("Northern", "Central", "Southern")
assessment_ids <- paste0(stock_ids, "_2015")
table_numbers <- 43:45
candidates_path <- file.path(root, "discovery/candidates.csv")
inventory_path <- file.path(root, "discovery/inventory_units.csv")
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
stocks_existing <- read.csv(file.path(root, "database/stocks.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments_existing <- read.csv(file.path(root, "database/assessments.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
has_stock <- stock_ids %in% stocks_existing$stock_id
has_assessment <- assessment_ids %in% assessments_existing$assessment_id
if (any(xor(has_stock, has_assessment)) || any(has_stock) && !all(has_stock)) {
  stop("China rockfish records are only partly present; inspect before continuing.", call. = FALSE)
}
if (any(has_stock) && !dry_run) {
  stop("China rockfish records already exist; inspect before re-importing.", call. = FALSE)
}
ci <- match(candidate_ids, candidates$candidate_id)
ii <- match(paste0("candidate:", stock_ids), inventory$unit_key)
unmatched_inventory <- is.na(ii)
ii[unmatched_inventory] <- match(paste0("stock:", stock_ids[unmatched_inventory]), inventory$unit_key)
if (anyNA(ci) || anyNA(ii) || anyDuplicated(ci) || anyDuplicated(ii) ||
    any(candidates$eligibility[ci] != "eligible") ||
    any(!candidates$import_status[ci] %in% if (dry_run) c("not_started", "partial") else "not_started") ||
    any(!inventory$import_status[ii] %in% if (dry_run) c("not_started", "partial") else "not_started")) {
  stop("China rockfish candidate status differs from the reviewed unimported batch.", call. = FALSE)
}

stock_rows <- list(); assessment_rows <- list(); assumption_rows <- list(); input_rows <- list(); output_rows <- list()
for (i in seq_along(areas)) {
  model <- parse_area(i)
  annual <- parse_output_table(table_numbers[i])
  summary_2015 <- parse_2015_summary(c("k", "l", "m")[i])
  assessment_id <- assessment_ids[i]
  region <- areas[i]
  source_reference <- function(section) paste0("2015 China rockfish assessment, ", section)
  area_text <- c("Washington state management areas 1–4", "Oregon and California north of 40°10′ N", "California south of 40°10′ N")[i]
  stock_rows[[i]] <- pacific_database_row("stocks", stock_id = stock_ids[i], charbonneau_id = "",
    authority = "NOAA-NWFSC/SWFSC", authority_stock_id = sub("NOAA:", "", candidate_ids[i]),
    scientific_name = "Sebastes nebulosus", common_name = paste("China rockfish -", region, "Pacific Coast"),
    area = area_text, region = "U.S. Pacific Coast", ocean = "Northeast Pacific",
    notes = paste0("NOAA Stock SMART unit ", sub("NOAA:", "", candidate_ids[i]), "; ", region,
      " model is a distinct assessment unit from the other China rockfish areas."))
  assessment_rows[[i]] <- pacific_database_row("assessments", assessment_id = assessment_id,
    stock_id = stock_ids[i], assessment_year = 2015L, terminal_year = 2014L,
    estimate_terminal_year = 2015L, assessment_type = "full_assessment",
    model_family = "Stock Synthesis", model_version = "3.24u", is_current = TRUE,
    is_applied = TRUE, assessment_url = report_url, framework_url = "",
    data_url = report_url, model_url = report_url, repository_url = "",
    assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
    notes = "Latest detailed full assessment located; the 2025 SAFE still identifies 2015 as the latest full assessment, and the 2019 Stock SMART action was a catch-only projection based on this model. Appendix A includes native catch data; Tables 43–45 report annual aggregate outputs. Catch compositions, index observations, full biological input schedules and age-specific outputs are not imported here; 2015 depletion and spawning-output intervals are imported from Tables k–m.")
  assumption_rows[[i]] <- rbind(
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "M",
      setting = "natural_mortality", value = "0.07 per year, fixed",
      source_reference = source_reference(paste0("Table ", 35L + i, " and post-STAR base-model description")),
      notes = "The accepted base case fixes M; do not interpret the alternative M sensitivities as the selected model."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "recruitment",
      setting = "recruitment_deviations", value = "Not estimated",
      source_reference = source_reference("model parameter tables and base-case description"),
      notes = "Recruitment deviations are not estimated in the selected model."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "population",
      setting = "sex_structure", value = "Two model genders; output tables are area-level aggregates",
      source_reference = source_reference("Appendix A, Stock Synthesis data file; annual population table"),
      notes = "The report tables do not split the aggregate outputs by sex."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "population",
      setting = "age_range", value = "Ages 0–80; age-composition plus group at 50",
      source_reference = source_reference("Appendix A, Stock Synthesis data file; assessment methods"),
      notes = "The 2015 annual output tables do not report N, F or M at age."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "model",
      setting = "model_years", value = "1900–2014 fitted; 2015 reported as forecast",
      source_reference = source_reference(paste0("Appendix A and Table ", table_numbers[i])),
      notes = "Catch rows begin in 1900 in these model files; 2015 is not part of the fitted terminal year."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "model",
      setting = "time_step", value = "Annual; one season per year",
      source_reference = source_reference("Appendix A, Stock Synthesis data file"), notes = "The model specifies one season and 12 months per season."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "timing",
      setting = "fleet_timing", value = "0.5 of year",
      source_reference = source_reference("Appendix A, survey timing in season field"),
      notes = "The native file gives mid-year timing for the listed fleets; this timing does not imply a fishery-independent survey."),
    pacific_database_row("assumptions", assessment_id = assessment_id, component = "catch",
      setting = "catch_units", value = "Biomass in metric tons",
      source_reference = source_reference("Appendix A, catch biomass block"),
      notes = "Annual catch biomass is imported by source fleet, including structural zeros."))
  fleet_names <- model$fleets[seq_len(model$n_fleet)]
  for (j in seq_along(fleet_names)) {
    rows <- pacific_database_row("inputs", n = nrow(model$catch), assessment_id = assessment_id,
      type = "catch", measure = "catch_biomass", basis = "biomass", fleet = fleet_names[j],
      region = region, year = model$catch$year, year_basis = "calendar_year", season = "annual",
      value = model$catch[[fleet_names[j]]], unit = "metric tons", source_type = "official_document",
      source_reference = source_reference("Appendix A, area-specific Stock Synthesis data file, catch biomass block"),
      notes = "Native annual catch biomass by fishery fleet. Zero values are retained. These values are not catch-at-age numbers.")
    input_rows[[length(input_rows) + 1L]] <- rows
  }
  row_indices <- seq_len(nrow(annual))
  forecast <- annual[, "year"] == 2015
  metric_specs <- list(
    list(type = "biomass", measure = "total_biomass", column = "total_biomass", unit = "metric tons"),
    list(type = "biomass", measure = "spawning_biomass", column = "spawning_biomass", unit = "metric tons"),
    list(type = "biomass", measure = "depletion", column = "depletion", unit = "proportion"),
    list(type = "recruitment", measure = "recruitment", column = "recruitment", unit = "thousand fish"),
    list(type = "catch", measure = "total_catch", column = "total_catch", unit = "metric tons"),
    list(type = "population", measure = "relative_exploitation_rate", column = "relative_exploitation_rate", unit = "reported relative-rate scale"),
    list(type = "mortality", measure = "spawning_potential_ratio", column = "spr", unit = "proportion")
  )
  for (spec in metric_specs) {
    idx <- if (spec$column %in% c("total_catch", "relative_exploitation_rate", "spr")) which(!forecast) else row_indices
    values <- as.numeric(annual[idx, spec$column])
    lwr <- upr <- rep(NA_real_, length(idx))
    reference <- rep(source_reference(paste0("Table ", table_numbers[i])), length(idx))
    if (spec$measure == "depletion") {
      estimate_row <- which(annual[idx, "year"] == 2015)
      values[estimate_row] <- summary_2015$depletion[1L]
      lwr[estimate_row] <- summary_2015$depletion[2L]
      upr[estimate_row] <- summary_2015$depletion[3L]
      reference[estimate_row] <- paste(reference[estimate_row], paste0("Table ", c("k", "l", "m")[i]), sep = "; ")
    }
    output_rows[[length(output_rows) + 1L]] <- pacific_database_row("outputs", n = length(idx),
      assessment_id = assessment_id, type = spec$type, measure = spec$measure,
      region = region, year = as.integer(annual[idx, "year"]),
      scenario = ifelse(annual[idx, "year"] == 2015, "forecast", ""),
      value = values, lwr = lwr, upr = upr, unit = spec$unit,
      source_type = "official_document", source_reference = reference,
      notes = if (spec$measure == "depletion") "Reported relative depletion; the report describes this as relative spawning output. The 2015 point estimate and 95% confidence interval are from the area reference-point table." else
        if (spec$measure == "relative_exploitation_rate") "Preserved under the table's label because its calculation is not defined in the extracted table." else
        if (spec$measure == "spawning_potential_ratio") "SPR as reported in the annual table; unavailable for 2015 forecast." else
        if (spec$measure == "recruitment") "Reported age-0 recruitment in thousands; 2015 value is a forecast." else
        if (spec$measure == "spawning_biomass") "Reported area-level spawning biomass in metric tons; distinct from spawning output in eggs." else
        if (spec$measure == "total_biomass") "Reported aggregate total biomass; 2015 value is a forecast." else
        "Reported total catch by assessment area; 2015 forecast catch is not shown in this table.")
  }
  output_rows[[length(output_rows) + 1L]] <- pacific_database_row("outputs", assessment_id = assessment_id,
    type = "biomass", measure = "spawning_output", region = region, year = 2015L,
    scenario = "forecast", value = summary_2015$spawning_output[1L],
    lwr = summary_2015$spawning_output[2L], upr = summary_2015$spawning_output[3L],
    unit = "billion eggs", source_type = "official_document",
    source_reference = source_reference(paste0("Table ", c("k", "l", "m")[i])),
    notes = "Area-level spawning output in eggs with the report's 95% confidence interval; distinct from spawning biomass in metric tons.")
}

stocks <- do.call(rbind, stock_rows)
assessments <- do.call(rbind, assessment_rows)
assumptions <- do.call(rbind, assumption_rows)
inputs <- do.call(rbind, input_rows)
outputs <- do.call(rbind, output_rows)
if (nrow(stocks) != 3L || nrow(assessments) != 3L || nrow(assumptions) != 24L ||
    nrow(inputs) != 2185L || nrow(outputs) != 2430L || any(!is.finite(inputs$value)) ||
    any(!is.finite(outputs$value)) || anyDuplicated(paste(inputs$assessment_id, inputs$fleet, inputs$year)) ||
    anyDuplicated(paste(outputs$assessment_id, outputs$measure, outputs$year))) {
  stop("China rockfish import values or dimensions failed validation.", call. = FALSE)
}

candidate_updates <- candidates[ci, , drop = FALSE]
inventory_updates <- inventory[ii, , drop = FALSE]
for (i in seq_along(areas)) {
  candidate_updates$matched_stock_id[i] <- stock_ids[i]
  candidate_updates$match_status[i] <- "matched"
  candidate_updates$import_status[i] <- "partial"
  candidate_updates$catch_age_evidence[i] <- "Imported the native annual catch biomass by fleet from Appendix A. The published assessment does not provide observed catch-at-age numbers; the report's age compositions are a separate, sparse input and are not converted to annual age-specific catches here."
  candidate_updates$survey_age_evidence[i] <- "The assessment reports fishery-dependent abundance indices and age compositions, but this import does not recover the complete index series. No annual age-specific abundance index is available directly in the imported tables."
  candidate_updates$weights_evidence[i] <- "The model estimates growth and uses weight-length relationships; a standalone annual weight-at-age input series is not supplied in the imported source tables."
  candidate_updates$maturity_evidence[i] <- "Maturity is informed by sparse maturity-at-length data; an annual maturity-at-age input schedule is not supplied in the imported source tables."
  candidate_updates$mortality_evidence[i] <- "The selected post-STAR base model fixes natural mortality at 0.07 per year; numerical age-specific M outputs are not reported in the imported tables."
  candidate_updates$timing_evidence[i] <- "The native Stock Synthesis data file specifies one annual season and 0.5-year fleet timing."
  candidate_updates$output_evidence[i] <- paste0("Imported Tables ", table_numbers[i], " area-level total biomass, spawning biomass, depletion, age-0 recruitment, catch, relative exploitation rate and SPR through 2014; the table's 2015 row contains four forecast quantities. No N-at-age/F-at-age or annual uncertainty is reported in these tables; the 2015 depletion and spawning-output intervals are available in Tables k–m.")
  candidate_updates$review_date[i] <- as.character(Sys.Date())
  candidate_updates$decision_reason[i] <- "Partial source import from the latest detailed 2015 full assessment; the 2025 SAFE still identifies this as the latest full model for this area."
  candidate_updates$notes[i] <- "Partial source import: native catch biomass by fleet, fixed-M and model-structure assumptions, and area-specific annual population tables. Observed catch-at-age, complete index/composition inputs, standalone age-specific biology and age-specific model outputs remain unavailable from the imported report tables."
  inventory_updates$matched_stock_id[i] <- stock_ids[i]
  inventory_updates$match_status[i] <- "matched"
  inventory_updates$import_status[i] <- "partial"
}
if (write_mode && !dry_run) {
  append_pacific_case(stocks, assessments, assumptions, inputs, outputs)
  for (i in seq_along(areas)) {
    replace_candidate_register_row(candidates_path, ci[i], candidate_updates[i, , drop = FALSE], candidate_ids[i])
    replace_csv_register_row(inventory_path, ii[i], inventory_updates[i, , drop = FALSE],
      "unit_key", inventory$unit_key[ii[i]])
  }
  source(file.path(root, "scripts/database/002_validate_database.R"), local = new.env(parent = globalenv()))
}
cat("Prepared ", nrow(stocks), " China rockfish area stocks, ", nrow(assumptions),
  " assumptions, ", nrow(inputs), " catch inputs, and ", nrow(outputs), " outputs.\n", sep = "")
if (dry_run) cat("Dry run: no canonical records or register rows changed.\n")
if (write_mode && !dry_run) cat("China rockfish source records appended; full database validation passed.\n")
