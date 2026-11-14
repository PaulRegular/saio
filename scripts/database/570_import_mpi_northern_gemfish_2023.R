root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args

stock_id <- "mpi_gemfish_northern_ski1_ski2"
assessment_id <- "mpi_gemfish_ski1_ski2_2023"
candidate_id <- "MPI:SKI1+SKI2"
source_files <- c(
  "source_cache/mpi_gemfish_ski1_ski2_2023/FAR-2024-45-northern-gemfish-SKI1-SKI2-assessment.pdf",
  "source_cache/mpi_gemfish_ski1_ski2_2023/FAR-2024-44-northern-gemfish-age-composition.pdf",
  "source_cache/mpi_gemfish_ski1_ski2_2023/GEMFISH-Plenary-2025-volume-1.pdf"
)
source_urls <- c(
  "https://fs.fish.govt.nz/Doc/25773/FAR-2024-45-2023-stock-assessment-gemfish-SKI1-SKI2.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/25772/FAR-2024-44-Age-composition-northern-gemfish-2012-2014-2022.pdf.ashx",
  "https://fs.fish.govt.nz/Doc/26039/gemfish-ski-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx"
)
expected_hash <- c(
  "C4BCFABC82A35546C0755A1B9DF2C21B41E377F14933E66C0A082195A67ECE7D",
  "9825B401571CCDAA6360532D29629D1060C8E56A19579FD283C77F75A3CCB6D6",
  "2B727F81A9C2E2A962E2257FBD088859211E31DC33DAACF3FF66D6A42A5549BC"
)
if (!all(file.exists(source_files))) stop("Cache the three reviewed Fisheries New Zealand reports before importing.", call. = FALSE)
actual_hash <- unname(toupper(tools::sha256sum(source_files)))
if (!identical(actual_hash, expected_hash)) stop("A cached gemfish source differs from the reviewed file.", call. = FALSE)

manifest <- data.frame(
  local_file = sub("^source_cache/", "", source_files),
  source_url = source_urls,
  retrieved_on = "2026-11-05",
  sha256 = expected_hash,
  stringsAsFactors = FALSE
)

section_lines <- function(lines, start, end = NULL) {
  first <- which(grepl(start, lines, fixed = TRUE))[1L]
  if (is.na(first)) stop("Source table not found: ", start, call. = FALSE)
  last <- length(lines) + 1L
  if (!is.null(end)) {
    later <- which(seq_along(lines) > first & grepl(end, lines, fixed = TRUE))
    if (!length(later)) stop("End of source table not found: ", end, call. = FALSE)
    last <- later[1L]
  }
  lines[seq.int(first, last - 1L)]
}

number_tokens <- function(line) {
  tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  values <- character()
  i <- 1L
  while (i <= length(tokens)) {
    if (grepl("^[0-9]{1,3}$", tokens[i]) && i < length(tokens) &&
        grepl("^[0-9]{3}\\.[0-9]+$", tokens[i + 1L])) {
      values <- c(values, paste0(tokens[i], tokens[i + 1L]))
      i <- i + 2L
    } else {
      values <- c(values, tokens[i])
      i <- i + 1L
    }
  }
  suppressWarnings(as.numeric(values))
}

parse_catch <- function(lines) {
  years <- list()
  catches <- list()
  for (line in lines) {
    year <- regmatches(line, regexec("^[[:space:]]*(19[0-9]{2}|20[0-9]{2})[[:space:]]+", line, perl = TRUE))[[1L]]
    if (!length(year)) next
    year <- as.integer(year[2L])
    if (year < 1950L || year > 2023L) next
    numbers <- number_tokens(sub("^[[:space:]]*[0-9]{4}[[:space:]]+", "", line, perl = TRUE))
    if (length(numbers) != 8L) stop("Could not parse eight catch cells for ", year, ".", call. = FALSE)
    years[[length(years) + 1L]] <- year
    catches[[length(catches) + 1L]] <- numbers
  }
  data.frame(year = unlist(years), do.call(rbind, catches), check.names = FALSE)
}

parse_cpue <- function(lines) {
  rows <- list()
  for (line in lines) {
    match <- regmatches(line, regexec("^[[:space:]]*(19[0-9]{2}|20[0-9]{2})[[:space:]]+", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    year <- as.integer(match[2L])
    if (year < 1990L || year > 2022L) next
    values <- number_tokens(sub("^[[:space:]]*[0-9]{4}[[:space:]]+", "", line, perl = TRUE))
    if (length(values) != 2L) stop("Could not parse CPUE index and standard error for ", year, ".", call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(year = year, index = values[1L], se = values[2L])
  }
  do.call(rbind, rows)
}

parse_age_table <- function(lines, start, end = NULL) {
  table <- section_lines(lines, start, end)
  header <- grep("Age \\(y\\)", table, value = TRUE)[1L]
  if (is.na(header)) stop("Age table header is incomplete: ", start, call. = FALSE)
  years <- as.integer(regmatches(header, gregexpr("\\b(19|20)[0-9]{2}\\b", header, perl = TRUE))[[1L]])
  if (!length(years)) stop("Age table years are missing: ", start, call. = FALSE)
  rows <- list()
  sex <- NA_character_
  for (line in table) {
    match <- regmatches(line, regexec("^[[:space:]]*(Females|Males)?[[:space:]]*(15\\+|[0-9]+)[[:space:]]+(.+)$", line, perl = TRUE))[[1L]]
    if (!length(match)) next
    if (match[3L] != "15+" && !as.integer(match[3L]) %in% 1:14) next
    if (nzchar(match[2L])) sex <- if (match[2L] == "Females") "female" else "male"
    if (is.na(sex)) stop("Age composition row has no sex label.", call. = FALSE)
    age <- if (match[3L] == "15+") 15L else as.integer(match[3L])
    values <- suppressWarnings(as.numeric(strsplit(trimws(match[4L]), "[[:space:]]+")[[1L]]))
    if (length(values) != length(years)) stop("Age composition row does not match its year header in ", start,
      ": expected ", length(years), " values but found ", length(values), " in: ", line, call. = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(sex = sex, age = age, t(values), check.names = FALSE)
  }
  result <- do.call(rbind, rows)
  if (nrow(result) != 30L) stop("Expected 15 age groups for each sex in ", start, ".", call. = FALSE)
  names(result)[seq_len(2L + length(years))] <- c("sex", "age", as.character(years))
  result
}

build_import <- function() {
  pdf_pages <- pdftools::pdf_text(source_files[1L])
  lines <- unlist(strsplit(pdf_pages, "\n", fixed = TRUE), use.names = FALSE)
  catch_table <- parse_catch(section_lines(lines, "Table C.1:", "Table C.2:"))
  cpue_table <- parse_cpue(section_lines(lines, "Table C.2:", "Table C.3:"))
  age_1 <- parse_age_table(lines, "Table C.3:", "Table C.4:")
  age_2 <- parse_age_table(lines, "Table C.4:", "Table C.5:")
  age_3 <- parse_age_table(lines, "Table C.5:")

  if (!identical(catch_table$year, 1950:2023) ||
      !identical(cpue_table$year, 1990:2022) ||
      ncol(catch_table) != 9L ||
      length(unique(age_1[["sex"]])) != 2L ||
      length(unique(age_2[["sex"]])) != 2L ||
      length(unique(age_3[["sex"]])) != 2L) {
    stop("Parsed gemfish coverage does not match the published tables.", call. = FALSE)
  }

  input_rows <- list()
  add_input <- function(type, measure, basis, value, unit, year = NA_integer_,
                       year_basis = "", age = NA_real_, fleet = "", survey = "",
                       sex = "", region = "", season = "", sampling_time = NA_real_,
                       source_reference, notes = "", observation_id = "",
                       source_type = "official_table") {
    input_rows[[length(input_rows) + 1L]] <<- data.frame(
      assessment_id, type, measure, basis, fleet, survey, sex, region, season,
      year = as.integer(year), year_basis, age = as.numeric(age),
      value = as.numeric(value), unit, sampling_time, source_type, source_reference,
      transformation = "", notes, observation_id, length_bin = NA_real_,
      length_bin_lower = NA_real_, length_bin_upper = NA_real_, sample_size = NA_real_,
      age_error = NA_real_, partition = NA_character_, stringsAsFactors = FALSE
    )
  }

  catch_labels <- data.frame(
    region = rep(c("SKI 1", "SKI 2"), each = 4L),
    fleet = rep(c("Non-target", "Target", "Non-target", "Target"), each = 2L),
    season = rep(c("S1 (October-April)", "S2 (May-September)"), 4L),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(catch_table))) for (j in seq_len(8L)) {
    year <- catch_table$year[i]
    note <- if (year == 2023L) {
      "The source report assumes the 2023 catch equals the 2022 catch."
    } else {
      "Year is labelled at 1 January for the October-September model year; S1 is October-April and S2 is May-September."
    }
    add_input("catch", "total_biomass", "biomass", catch_table[i, j + 1L], "tonnes",
      year = year, year_basis = "model_year", fleet = catch_labels$fleet[j],
      region = catch_labels$region[j], season = catch_labels$season[j],
      source_reference = "Fisheries New Zealand FAR 2024/45, Table C.1, pp. 110-112",
      notes = note, observation_id = paste("catch", catch_labels$region[j],
        catch_labels$fleet[j], paste0("S", (j - 1L) %% 2L + 1L), year, sep = "_"))
  }

  cpue_name <- "Daily SKI1-SKI2 HOK-SKI target CPUE"
  for (i in seq_len(nrow(cpue_table))) {
    add_input("index", "relative_abundance_index", "index_scale",
      cpue_table$index[i], "relative index units", year = cpue_table$year[i],
      year_basis = "model_year", fleet = cpue_name, region = "SKI 1 and SKI 2",
      source_reference = "Fisheries New Zealand FAR 2024/45, Table C.2, p. 112",
      notes = "Fishery-based abundance index included in the selected base case; it is not a survey index.",
      observation_id = paste0("daily_hok_ski_cpue_", cpue_table$year[i]))
    add_input("index", "index_sd", "index_scale", cpue_table$se[i],
      "relative index units", year = cpue_table$year[i], year_basis = "model_year",
      fleet = cpue_name, region = "SKI 1 and SKI 2",
      source_reference = "Fisheries New Zealand FAR 2024/45, Table C.2, p. 112",
      notes = "Source-reported standard error on the index scale; not a coefficient of variation.",
      observation_id = paste0("daily_hok_ski_cpue_", cpue_table$year[i]))
  }

  add_age_rows <- function(table, years, fleet, region, table_ref, prefix) {
    age_start <- which(names(table) == "age")[1L]
    year_names <- names(table)[-(seq_len(age_start))]
    for (i in seq_len(nrow(table))) for (j in seq_along(year_names)) {
      year <- as.integer(year_names[j])
      add_input("catch", "proportion_at_age", "proportion_numbers",
        table[[year_names[j]]][i], "proportion", year = year, year_basis = "model_year",
        age = table$age[i], fleet = fleet, sex = table$sex[i], region = region,
        source_reference = table_ref,
        notes = paste("Published joint sex-age catch proportion; rows across both sexes sum to approximately one and were not renormalized. Age 15 represents the source 15+ group.",
          "Individual model effective sample sizes are not tabulated; the assessment reports only group-specific ranges."),
        observation_id = paste0(prefix, "_", year))
    }
  }

  age_tables <- list(
    list(data = age_1, fleet = "SKI 1 target trawl fishery", region = "SKI 1",
      reference = "Fisheries New Zealand FAR 2024/45, Table C.3, p. 113", prefix = "ski1_target"),
    list(data = age_2, fleet = "SKI 2 target trawl fishery", region = "SKI 2",
      reference = "Fisheries New Zealand FAR 2024/45, Table C.4, p. 114", prefix = "ski2_target"),
    list(data = age_3, fleet = "SKI 2 non-target trawl fishery", region = "SKI 2",
      reference = "Fisheries New Zealand FAR 2024/45, Table C.5, pp. 114-115", prefix = "ski2_nontarget")
  )
  for (spec in age_tables) add_age_rows(spec$data, NULL, spec$fleet,
    spec$region, spec$reference, spec$prefix)

  inputs <- do.call(rbind, input_rows)
  comp <- inputs[inputs$measure == "proportion_at_age", ]
  comp_sums <- aggregate(value ~ observation_id, comp, sum)
  if (nrow(inputs) != 1498L || nrow(comp) != 840L ||
      nrow(comp_sums) != 28L || max(abs(comp_sums$value - 1)) > 0.002) {
    worst <- comp_sums[which.max(abs(comp_sums$value - 1)), ]
    stop("Parsed gemfish rows failed: inputs=", nrow(inputs), ", compositions=", nrow(comp),
      ", observations=", nrow(comp_sums), ", maximum composition sum error=",
      max(abs(comp_sums$value - 1)), " for ", worst$observation_id,
      " (sum ", worst$value, ").", call. = FALSE)
  }

  assumptions <- data.frame(
    assessment_id = assessment_id,
    component = c("assessment", "population", "timing", "timing", "population",
      "mortality", "growth", "maturity", "recruitment", "index", "composition",
      "composition", "uncertainty"),
    fleet = "", survey = "", sex = "", region = "", season = "",
    setting = c("selected_base_case", "biological_stock_definition", "model_year",
      "seasonal_structure", "age_range", "natural_mortality", "growth_and_length_weight",
      "maturity_ogive", "stock_recruitment", "CPUE_likelihood",
      "age_composition_likelihood", "composition_weighting", "uncertainty_method"),
    value = c(
      "2023 full quantitative base case; Stock Synthesis 3.30.17",
      "SKI 1 and SKI 2 are represented as one biological stock; fisheries are partitioned by area and selectivity.",
      "Calendar-year label at 1 January denotes the October-September fishing year.",
      "Season 1 is October-April and Season 2 is May-September; spawning is in Season 2.",
      "Twenty population age classes per sex; age 20+ is the population plus group. Published composition data use ages 1-14 and 15+.",
      "Natural mortality fixed at 0.25 per year for both sexes.",
      "Von Bertalanffy: length at age 1 = 26.8 cm; male k=0.235 and Linf=88.4 cm; female k=0.167 and Linf=108.5 cm; CV length-at-age=0.10. Length-weight: males a=8.0e-7, b=3.55; females a=3.4e-6, b=3.22 (length cm, weight kg).",
      "Female maturity logistic with A50=7.2 years and width=3.5 years; no complete maturity-at-age vector is tabulated.",
      "Beverton-Holt stock-recruit relationship with fixed steepness h=0.90; recruitment deviations estimated for 1975-2017 with sigmaR=0.8; recruitment deviations for 2018-2023 fixed at zero.",
      "Daily HOK-SKI target CPUE is fitted with lognormal observation error; source standard errors are reported in Table C.2 and additional process error is 0.1.",
      "Sex-specific age proportions are fitted for SKI 1 target, SKI 2 target, and SKI 2 non-target fisheries; ageing error CV=0.08.",
      "Francis (2011) TA1.8 weighting; the report gives effective sample-size ranges (SKI 1: 6-20; SKI 2 target: 21-82; SKI 2 non-target: 7-23) but not individual observation values.",
      "MCMC uncertainty uses 1,000 retained samples at 1,000-iteration intervals after a 100,000-iteration burn-in."
    ),
    source_reference = c(
      "Fisheries New Zealand FAR 2024/45, pp. 1, 9-12",
      "Fisheries New Zealand FAR 2024/45, section 3.1 and p. 10",
      "Fisheries New Zealand FAR 2024/45, Table C.1, pp. 110-112",
      "Fisheries New Zealand FAR 2024/45, sections 3.1 and 3.3",
      "Fisheries New Zealand FAR 2024/45, section 3.3 and Tables C.3-C.5",
      "Fisheries New Zealand FAR 2024/45, Table 3, p. 10",
      "Fisheries New Zealand FAR 2024/45, Table 3, p. 10",
      "Fisheries New Zealand FAR 2024/45, Table 3, p. 10",
      "Fisheries New Zealand FAR 2024/45, Table 4 and section 3.3",
      "Fisheries New Zealand FAR 2024/45, Table 5 and section 3.3",
      "Fisheries New Zealand FAR 2024/45, sections 3.3 and Table 5",
      "Fisheries New Zealand FAR 2024/45, Table 5, p. 12",
      "Fisheries New Zealand FAR 2024/45, section 3.3"
    ),
    notes = c(
      "The 2025 Fisheries Assessment Plenary still identifies publication year 2023 as the most recent full assessment for SKI 1+2.",
      rep("", 11L),
      "The report's intervals are MCMC percentile intervals, described there as 95% confidence intervals."
    ),
    stringsAsFactors = FALSE
  )

  output_values <- data.frame(
    type = c("biomass", "biomass", "biomass", "biomass", "biomass",
      "mortality", "mortality"),
    measure = c("unfished_spawning_biomass", "SSB",
      "spawning_biomass_at_40_percent_SB0", "SSB_ratio_to_B0",
      "SSB_ratio_to_SB40", "F_reference_at_SB40", "F_ratio_to_FSB40"),
    year = c(NA_integer_, 2023L, NA_integer_, 2023L, 2023L, NA_integer_, 2023L),
    value = c(9041, 9401, 3616, 1.04, 2.59, 0.11, 0.17),
    lwr = c(7442, 6312, 2977, 0.76, 1.89, NA, 0.10),
    upr = c(11244, 14825, 4498, 1.49, 3.74, NA, 0.24),
    unit = c("tonnes", "tonnes", "tonnes", "ratio", "ratio", "per year", "ratio"),
    stringsAsFactors = FALSE
  )
  outputs <- do.call(rbind, lapply(seq_len(nrow(output_values)), function(i) data.frame(
    assessment_id = assessment_id, type = output_values$type[i],
    measure = output_values$measure[i], fleet = "", survey = "",
    sex = if (output_values$type[i] == "biomass") "female" else "",
    region = "", season = "", year = output_values$year[i], age = NA_real_,
    age_group = "", value = output_values$value[i], se = NA_real_,
    lwr = output_values$lwr[i], upr = output_values$upr[i],
    unit = output_values$unit[i], source_type = "official_table",
    source_reference = "Fisheries New Zealand FAR 2024/45, Table 7, p. 26",
    notes = paste("Base case MCMC median; source reports the 95% interval in parentheses.",
      if (output_values$measure[i] == "F_reference_at_SB40") "This is a reference fishing-mortality rate, not estimated annual F-at-age." else ""),
    scenario = "", stringsAsFactors = FALSE
  )))

  stocks <- data.frame(
    stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
    authority_stock_id = "SKI 1 + SKI 2", scientific_name = "Rexea solandri",
    common_name = "Northern gemfish",
    area = "Northern biological stock (SKI 1 and SKI 2)",
    region = "New Zealand waters", ocean = "Southwest Pacific",
    notes = "The assessment treats SKI 1 and SKI 2 fisheries as one biological stock.",
    stringsAsFactors = FALSE
  )
  assessments <- data.frame(
    assessment_id = assessment_id, stock_id = stock_id,
    assessment_year = 2023L, terminal_year = 2023L, estimate_terminal_year = 2023L,
    assessment_type = "full_assessment", model_family = "Stock Synthesis",
    model_version = "3.30.17; 2023 base case",
    is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
    assessment_url = source_urls[1L], framework_url = "", data_url = source_urls[2L],
    model_url = "", repository_url = "", assumptions_status = "partial",
    inputs_status = "partial", outputs_status = "partial",
    notes = paste(
      "Latest detailed full quantitative production assessment located for the single northern gemfish stock in SKI 1+2; the 2025 Fisheries Assessment Plenary still lists publication year 2023 as most recent.",
      "Catch history is tabulated through 2023, with the 2023 catch assumed equal to 2022. Inputs include sex-specific proportions at age and a fishery-based CPUE index, not a survey age series.",
      "The report does not tabulate individual effective sample sizes, an age-specific weight surface, or numeric annual population trajectories and age-specific outputs."
    ),
    stringsAsFactors = FALSE
  )

  list(
    stocks = stocks, assessments = assessments, inputs = inputs,
    assumptions = assumptions, outputs = outputs, manifest = manifest,
    catch_table = catch_table, cpue_table = cpue_table,
    compositions = list(age_1, age_2, age_3)
  )
}

gemfish <- build_import()
cat("Gemfish extraction validated: ", nrow(gemfish$inputs),
  " inputs (", sum(gemfish$inputs$type == "catch" & gemfish$inputs$measure == "total_biomass"),
  " catch values, ", sum(gemfish$inputs$measure == "relative_abundance_index"),
  " CPUE indices, ", sum(gemfish$inputs$measure == "proportion_at_age"),
  " age-composition cells), ", nrow(gemfish$assumptions), " assumptions, and ",
  nrow(gemfish$outputs), " Table 7 outputs.\n", sep = "")

if (write_mode) {
  database_dir <- file.path(root, "database")
  for (file_name in c("stocks.csv", "assessments.csv", "inputs.csv", "assumptions.csv", "outputs.csv")) {
    id <- if (file_name == "stocks.csv") stock_id else assessment_id
    path <- file.path(database_dir, file_name)
    connection <- file(path, open = "r")
    duplicate <- FALSE
    repeat {
      chunk <- readLines(connection, n = 20000L, warn = FALSE)
      if (!length(chunk)) break
      if (any(startsWith(chunk, paste0('"', id, '"')))) {
        duplicate <- TRUE
        break
      }
    }
    close(connection)
    if (duplicate) stop("Refusing to duplicate ", id, " in ", file_name, ".", call. = FALSE)
  }

  append_csv <- function(data, path) write.table(data, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  append_csv(gemfish$stocks, file.path(database_dir, "stocks.csv"))
  append_csv(gemfish$assessments, file.path(database_dir, "assessments.csv"))
  append_csv(gemfish$inputs, file.path(database_dir, "inputs.csv"))
  append_csv(gemfish$assumptions, file.path(database_dir, "assumptions.csv"))
  append_csv(gemfish$outputs, file.path(database_dir, "outputs.csv"))
  write.csv(gemfish$manifest, "provenance/mpi_gemfish_ski1_ski2_2023_sources.csv",
    row.names = FALSE, na = "")

  candidate <- data.frame(
    candidate_id = candidate_id, candidate_unit_id = "nz_gemfish_ski1_ski2",
    organization = "Fisheries New Zealand", official_stock_id = "SKI 1 + SKI 2",
    scientific_name = "Rexea solandri", stock_name = "Northern gemfish",
    assessment_area = "Northern biological stock (SKI 1 and SKI 2)",
    inventory_assessment_year = 2023L,
    inventory_url = source_urls[3L], retrieved_on = "2026-11-05",
    matched_stock_id = stock_id, match_status = "new",
    screening_status = "screened", eligibility = "eligible",
    import_status = "partial",
    catch_age_evidence = "Imported commercial catch biomass by SKI area, fishery and season for 1950-2023, plus joint sex-age proportions for 28 fitted observations across 1989-2022. Direct catch numbers at age and individual composition effective sample sizes are not tabulated.",
    survey_age_evidence = "No survey index or survey age compositions were used in the selected run. The abundance index is daily, fishery-based HOK-SKI target CPUE for 1990-2022, with source-reported index standard errors.",
    weights_evidence = "No direct age-specific weight surface is tabulated. The report gives sex-specific von Bertalanffy growth and length-weight parameters; deriving weights at age would be a separate reconstruction.",
    maturity_evidence = "The selected run uses a female logistic maturity ogive with A50 7.2 years and width 3.5 years; no numeric maturity-at-age vector is tabulated.",
    mortality_evidence = "Natural mortality is fixed at 0.25 per year for both sexes.",
    timing_evidence = "Model years are October-September labelled at 1 January; catch steps are October-April and May-September. CPUE is annual fishery data with no single source-reported sampling fraction.",
    output_evidence = "Imported base-case MCMC medians and 95% intervals for SB0, terminal 2023 spawning biomass, SB40%, biomass ratios, and the fishing-mortality reference ratio. Numeric annual trajectories and age-specific N/F are not tabulated.",
    detailed_source_url = paste(source_urls, collapse = "; "),
    review_date = "2026-11-05",
    decision_reason = "Selected because the latest full quantitative assessment has tabulated catch inputs, CPUE with uncertainty, complete age-composition vectors for the three fitted fishery groups, biological assumptions, and terminal biomass outputs. Inputs and outputs remain partial where run-specific sample weights, direct age weights, and numerical annual fitted states are unavailable.",
    notes = "One biological unit spans SKI 1 and SKI 2; do not split it into separate stock records. 2025 Plenary identifies the 2023 full assessment as the most recent."
  )
  candidates_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidates_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  if (candidate_id %in% candidates$candidate_id) {
    stop("Candidate already exists; review identity before importing.", call. = FALSE)
  }
  append_csv(candidate, candidates_path)
  sys.source("scripts/database/195_summarize_discovery.R", envir = new.env(parent = globalenv()))
  sys.source("scripts/database/196_summarize_inventory_units.R", envir = new.env(parent = globalenv()))
}
