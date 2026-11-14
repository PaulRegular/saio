root <- "."
assessment_id <- "mpi_snapper_sna1_2023"
stock_id <- "mpi_snapper_sna1"
candidate_id <- "MPI:SNA1"
write_data <- "--write" %in% commandArgs(trailingOnly = TRUE)

## Parse reviewed source tables ----

source_dir <- file.path(root, "source_cache", "mpi_snapper_sna1_2023")
if (dir.exists(file.path(source_dir, "r_lib"))) {
  .libPaths(c(file.path(source_dir, "r_lib"), .libPaths()))
}
assessment_pdf <- file.path(source_dir, "FAR-2024-47-SNA1-assessment-2022-2023.pdf")
composition_pdf <- file.path(source_dir, "FAR-2022-24-SNA1-age-composition-2019-20.pdf")
manifest <- read.csv(file.path(root, "provenance", "mpi_snapper_sna1_2023_sources.csv"),
  stringsAsFactors = FALSE)
verified <- c(
  "FAR-2024-47-SNA1-assessment-2022-2023.pdf" =
    "F63A73EBC4004DD8AEE9E62A59D6192771C023CE45FA1F6C07524AFAF57CAC70",
  "FAR-2022-24-SNA1-age-composition-2019-20.pdf" =
    "7113E13688909E9F2BA89B23AA7BA53AB0A726F8FD2F88716A423C6A10DC9DA9"
)
manifest_rows <- match(names(verified), basename(manifest$local_file))
if (anyNA(manifest_rows) || any(!file.exists(c(assessment_pdf, composition_pdf)))) {
  stop("Reviewed SNA 1 source PDFs or provenance entries are missing.", call. = FALSE)
}
actual <- toupper(unname(tools::sha256sum(c(assessment_pdf, composition_pdf))))
if (!identical(actual, unname(verified)) ||
    !identical(toupper(manifest$sha256[manifest_rows]), unname(verified))) {
  stop("A reviewed SNA 1 PDF differs from its verified SHA-256 checksum.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Package pdftools is needed to parse the cached source tables.", call. = FALSE)
}

assessment_text <- pdftools::pdf_text(assessment_pdf)
composition_text <- pdftools::pdf_text(composition_pdf)

parse_catch_table <- function(page, region, fleets, table_number) {
  lines <- strsplit(assessment_text[[page]], "\n", fixed = TRUE)[[1L]]
  rows <- grep("^\\s*[0-9]{4}\\s+", lines, value = TRUE, perl = TRUE)
  if (length(rows) != 41L) stop("Unexpected row count in catch table ", table_number, ".", call. = FALSE)
  parsed <- lapply(rows, function(line) {
    values <- regmatches(line, gregexpr("[0-9]+", line, perl = TRUE))[[1L]]
    if (length(values) != 18L) stop("Unexpected numeric layout in catch table ", table_number, ".", call. = FALSE)
    matrix(as.integer(values), ncol = 6L, byrow = TRUE)
  })
  wide <- do.call(rbind, parsed)
  wide <- wide[order(wide[, 1L]), , drop = FALSE]
  if (nrow(wide) != 123L || !identical(wide[, 1L], 1900:2022)) {
    stop("Catch table ", table_number, " does not cover source years 1900-2022.", call. = FALSE)
  }
  long <- do.call(rbind, lapply(seq_len(nrow(wide)), function(i) {
    data.frame(year = wide[i, 1L], fleet = fleets,
      value = as.numeric(wide[i, 2:6]), region = region,
      source_reference = paste0("FAR 2024/47, Table Appendix ", table_number, "."),
      stringsAsFactors = FALSE)
  }))
  if (anyDuplicated(long[c("year", "fleet", "region")])) {
    stop("Duplicate fleet/year rows in catch table ", table_number, ".", call. = FALSE)
  }
  long
}

catches <- rbind(
  parse_catch_table(215L, "East Northland", c("LL", "MHS", "PT", "ST", "REC"), 14L),
  parse_catch_table(216L, "Hauraki Gulf", c("LL", "MHS", "BT", "DS", "REC"), 15L),
  parse_catch_table(217L, "Bay of Plenty", c("LL", "MHS", "BT", "DS", "REC"), 16L)
)

parse_age_composition <- function(page, region, fleet, page_reference) {
  lines <- strsplit(composition_text[[page]], "\n", fixed = TRUE)[[1L]]
  rows <- grep("^\\s*(?:[0-9]{1,2}|>29)\\s+", lines, value = TRUE, perl = TRUE)
  if (length(rows) != 30L) stop("Unexpected age count on composition page ", page, ".", call. = FALSE)
  parsed <- lapply(rows, function(line) {
    fields <- strsplit(trimws(line), "\\s+")[[1L]]
    if (length(fields) != 10L) stop("Unexpected age row on composition page ", page, ".", call. = FALSE)
    age <- if (fields[1L] == ">29") 30L else as.integer(fields[1L])
    values <- suppressWarnings(as.numeric(fields[-1L]))
    data.frame(age = age, proportion = values[7L], cv = values[8L],
      n = values[9L], region = region, fleet = fleet,
      source_reference = page_reference, stringsAsFactors = FALSE)
  })
  result <- do.call(rbind, parsed)
  result <- result[order(result$age), , drop = FALSE]
  expected_age <- 1:30
  if (!identical(result$age, expected_age) ||
      abs(sum(result$proportion) - 1) > 0.0002) {
    stop("Composition page ", page, " has unexpected ages or proportion total.", call. = FALSE)
  }
  result
}

age_compositions <- rbind(
  parse_age_composition(115L, "Bay of Plenty", "BT",
    "FAR 2022/24, Appendix 10, printed p. 111."),
  parse_age_composition(116L, "Hauraki Gulf", "DS",
    "FAR 2022/24, Appendix 10, printed p. 112."),
  parse_age_composition(117L, "Bay of Plenty", "DS",
    "FAR 2022/24, Appendix 10, printed p. 113."),
  parse_age_composition(119L, "Bay of Plenty", "MHS",
    "FAR 2022/24, Appendix 10, printed p. 115.")
)
sample_totals <- c(
  sum(age_compositions$n[age_compositions$region == "Bay of Plenty" & age_compositions$fleet == "BT"], na.rm = TRUE),
  sum(age_compositions$n[age_compositions$region == "Hauraki Gulf" & age_compositions$fleet == "DS"], na.rm = TRUE),
  sum(age_compositions$n[age_compositions$region == "Bay of Plenty" & age_compositions$fleet == "DS"], na.rm = TRUE),
  sum(age_compositions$n[age_compositions$region == "Bay of Plenty" & age_compositions$fleet == "MHS"], na.rm = TRUE)
)
if (!identical(as.numeric(sample_totals), c(1354, 1365, 1354, 1354))) {
  stop("The age-composition sample totals do not match the source tables.", call. = FALSE)
}

## Build source records ----

make_input <- function(type, measure, basis, value, unit, year = NA_integer_,
    year_basis = "", age = NA_integer_, fleet = "", survey = "", region = "",
    season = "", source_type = "official_table", source_reference,
    transformation = "", notes = "", observation_id = "", sample_size = NA_real_,
    length_bin = "", length_bin_lower = NA_real_, length_bin_upper = NA_real_) {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = region, season = season,
    year = year, year_basis = year_basis, age = age, value = value, unit = unit,
    sampling_time = NA_real_, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes, observation_id = observation_id, length_bin = length_bin,
    length_bin_lower = length_bin_lower, length_bin_upper = length_bin_upper,
    sample_size = sample_size, age_error = NA_real_, partition = "",
    stringsAsFactors = FALSE
  )
}

catch_inputs <- do.call(rbind, lapply(seq_len(nrow(catches)), function(i) {
  make_input("catch", "catch_biomass", "biomass", catches$value[i], "tonnes",
    year = catches$year[i], year_basis = "model_year", fleet = catches$fleet[i],
    region = catches$region[i], source_reference = catches$source_reference[i],
    notes = paste(
      "Source catch mass by fishery/method, not catch-at-age.",
      "Retain the source year label. The assessment describes its terminal model period as 2021-22.",
      "Values follow the source adjustments; the histories include recreational catch and apportioned foreign longline catch."
    ))
}))

age_inputs <- do.call(rbind, lapply(seq_len(nrow(age_compositions)), function(i) {
  x <- age_compositions[i, ]
  common <- list(
    year = 2020L, year_basis = "model_year", age = x$age, fleet = x$fleet,
    region = x$region, season = "spring-winter",
    source_reference = x$source_reference,
    notes = paste(
      "Source series is spring-winter 2019-20 and is listed as model year 2020 in FAR 2024/47 Table 40.",
      "The source >29 group is stored as age 30, matching the assessment plus group.",
      "Printed proportions are retained without renormalization."
    ),
    observation_id = paste("SNA1", x$region, x$fleet, "2020", sep = "_"),
    sample_size = x$n
  )
  proportion <- do.call(make_input, c(list(
    type = "catch", measure = "proportion_at_age",
    basis = "proportion_numbers", value = x$proportion, unit = "proportion"
  ), common))
  cv_common <- common
  cv_common$notes <- paste(common$notes,
    "CV is the source bootstrap CV, not the assessment effective sample size or a final likelihood weight.")
  cv <- do.call(make_input, c(list(
    type = "catch", measure = "relative_standard_error",
    basis = "relative_scale", value = x$cv, unit = "ratio"
  ), cv_common))
  rbind(proportion, cv)
}))

tag_specs <- data.frame(
  region = c("East Northland", "Hauraki Gulf", "East Northland", "Hauraki Gulf", "Bay of Plenty"),
  model_year = c(1985L, 1984L, 1994L, 1995L, 1995L),
  source_year = c(1985L, 1985L, 1994L, 1994L, 1994L),
  value = c(4443637, 29396763, 4851992, 31534555, 12284935),
  cv = c(0.3, 0.3, 0.2, 0.2, 0.2),
  derived_1985 = c(TRUE, TRUE, FALSE, FALSE, FALSE),
  stringsAsFactors = FALSE
)
tag_inputs <- do.call(rbind, lapply(seq_len(nrow(tag_specs)), function(i) {
  x <- tag_specs[i, ]
  obs <- paste0("SNA1_tag_", x$region, "_", x$model_year)
  source_type <- if (x$derived_1985) "reconstructed_source_input" else "official_table"
  source_ref <- if (x$derived_1985) {
    "FAR 2024/47, Table 32 and text applying Table 30 new-boundary ratios."
  } else {
    "FAR 2024/47, Table 30, new-boundary population estimates."
  }
  detail <- paste0(
    "Petersen tag estimate for snapper 25-40 cm; model year mapping follows FAR 2024/47 Table ",
    if (x$region == "East Northland") "33." else "40.",
    " Source tagging year ", x$source_year, "."
  )
  if (x$derived_1985) detail <- paste(detail,
    "The new-boundary estimate was calculated in the report from the 1985 combined estimate and 1994 area ratio.")
  rbind(
    make_input("index", "total_numbers", "numbers", x$value, "fish",
      year = x$model_year, year_basis = "model_year",
      survey = "Petersen tag estimate (25-40 cm)", region = x$region,
      source_type = source_type, source_reference = source_ref,
      notes = detail, observation_id = obs,
      length_bin = "25-40 cm", length_bin_lower = 25, length_bin_upper = 40),
    make_input("index", "relative_standard_error", "relative_scale", x$cv, "ratio",
      year = x$model_year, year_basis = "model_year",
      survey = "Petersen tag estimate (25-40 cm)", region = x$region,
      source_type = "official_document",
      source_reference = "FAR 2024/47, Section 7.2, tagging population estimates.",
      notes = paste(detail, "Fixed lognormal likelihood CV specified by the Working Group."),
      observation_id = obs)
  )
}))

biology_inputs <- rbind(
  make_input("M", "natural_mortality_at_age", "per_year", rep(0.075, 30L), "per year",
    age = 1:30, source_reference = "FAR 2024/47, Tables 35 and 42.",
    notes = "Fixed natural mortality applied across ages and model areas."),
  make_input("maturity", "maturity_at_age", "proportion_numbers",
    c(0, 0, 0, 0.5, rep(1, 26L)), "proportion", age = 1:30,
    source_reference = "FAR 2024/47, Tables 35 and 42.",
    notes = "Fixed maturity schedule; age 30 represents the 30+ group.")
)

inputs <- rbind(catch_inputs, age_inputs, tag_inputs, biology_inputs)

assumption <- function(component, setting, value, source_reference, notes = "",
    region = "", fleet = "", survey = "", season = "", sex = "") {
  data.frame(assessment_id = assessment_id, component = component,
    fleet = fleet, survey = survey, sex = sex, region = region, season = season,
    setting = setting, value = value, source_reference = source_reference,
    notes = notes, stringsAsFactors = FALSE)
}
assumptions <- rbind(
  assumption("population", "model_structure",
    "East Northland is a single-area model; Hauraki Gulf and Bay of Plenty are a separate two-area model.",
    "FAR 2024/47, Sections 6-8, Tables 33 and 40."),
  assumption("population", "selected_base_model",
    "1968 commencement model; movement between Hauraki Gulf and Bay of Plenty fixed at zero.",
    "FAR 2024/47, Section 8.2, discussion following Table 43.",
    "The report selected this model after movement caused B0/Finitial estimation problems."),
  assumption("population", "age_range_and_plus_group", "Ages 1-30; age 30 is the plus group.",
    "FAR 2024/47, Tables 33 and 40."),
  assumption("population", "time_steps", "Two annual time steps.",
    "FAR 2024/47, Section 6."),
  assumption("recruitment", "stock_recruit_steepness", "0.85, fixed.",
    "FAR 2024/47, Tables 35 and 42."),
  assumption("M", "natural_mortality", "0.075 per year, fixed.",
    "FAR 2024/47, Tables 35 and 42."),
  assumption("biology", "maturity_at_age", "0 at ages 1-3; 0.5 at age 4; 1 above age 4.",
    "FAR 2024/47, Tables 35 and 42."),
  assumption("biology", "growth_and_weight",
    "Mean length-at-age matrices cover 1989-2021; mean growth rates are applied outside those years. Length-weight functions are area-specific.",
    "FAR 2024/47, Tables 35 and 42, Appendix 5.",
    "The full annual weight-at-age surfaces are not tabulated in the reviewed sources."),
  assumption("index", "east_northland_bottom_trawl_cpue_cv", "0.31, fixed.",
    "FAR 2024/47, Section 7.2.",
    "The report states this was carried forward from the 2022 assessment.",
    region = "East Northland", survey = "Bottom trawl CPUE"),
  assumption("index", "survey_index_process_cv", "0.1.",
    "FAR 2024/47, Section 8.2.",
    "Additional process CV for the research trawl survey indices."),
  assumption("tagging", "population_estimate_error_cv", "0.3 for the 1985 tagging estimates; 0.2 for the 1994 estimates.",
    "FAR 2024/47, Section 7.2.",
    "Fixed lognormal CVs include allowance for tagging process error."),
  assumption("composition", "likelihood_and_reweighting",
    "Multinomial likelihood based on analytical CVs; Francis TA1.8 reweighting.",
    "FAR 2024/47, Section 7.2."),
  assumption("initialization", "initial_exploitation_and_transformation",
    "Initial mortality is used to establish an exploited equilibrium from the virgin state; B0 and Finitial are orthogonally transformed for estimation.",
    "FAR 2024/47, Sections 6 and 7.1."),
  assumption("catch", "catch_history_penalty",
    "Strong penalties prevent predicted fishery-available biomass from falling below the true catch history.",
    "FAR 2024/47, Section 8.2.")
)

output_row <- function(type, measure, value, unit, source_reference, notes,
    region = "", year = NA_real_, lwr = NA_real_, upr = NA_real_,
    scenario = "1968 base model") {
  data.frame(assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = region, season = "",
    year = year, age = NA_real_, age_group = "", value = value, se = NA_real_,
    lwr = lwr, upr = upr, unit = unit, source_type = "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE)
}
outputs <- rbind(
  output_row("biomass", "unfished_spawning_biomass", 55873, "tonnes",
    "FAR 2024/47, Table 36.", "MCMC median; 95% interval as reported.",
    region = "East Northland", lwr = 50953, upr = 61892),
  output_row("biomass", "SSB_ratio_to_B0", 0.38, "ratio",
    "FAR 2024/47, Table 36.", "MCMC median B2022/B0; 95% interval as reported.",
    region = "East Northland", year = 2022, lwr = 0.29, upr = 0.46),
  output_row("probability", "probability_SSB_above_0.4B0", 0.29, "proportion",
    "FAR 2024/47, Table 36.", "MCMC probability that B2022 exceeds 40% of B0.",
    region = "East Northland", year = 2022),
  output_row("probability", "probability_SSB_above_0.2B0", 1, "proportion",
    "FAR 2024/47, Table 36.", "MCMC probability that B2022 exceeds 20% of B0.",
    region = "East Northland", year = 2022),
  output_row("mortality", "exploitation_rate_reference_at_SB40", 0.052, "ratio",
    "FAR 2024/47, Table 37.", "U reference at equilibrium biomass of 40% B0.",
    region = "East Northland"),
  output_row("mortality", "exploitation_rate", 0.057, "ratio",
    "FAR 2024/47, Table 37.", "MCMC median 2021-22 fishing-pressure U; 95% interval as reported.",
    region = "East Northland", year = 2022, lwr = 0.039, upr = 0.085),
  output_row("probability", "probability_U_above_reference", 0.74, "proportion",
    "FAR 2024/47, Table 37.", "MCMC probability that U2022 exceeds the U reference at 40% B0.",
    region = "East Northland", year = 2022),
  output_row("probability", "probability_U_below_reference", 0.26, "proportion",
    "FAR 2024/47, Table 37.", "MCMC probability that U2022 is below the U reference at 40% B0.",
    region = "East Northland", year = 2022),
  output_row("biomass", "unfished_spawning_biomass", 449476, "tonnes",
    "FAR 2024/47, Table 43.", "1968 base-model estimate; no uncertainty interval is tabulated.",
    region = "Hauraki Gulf", scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "SSB_ratio_to_B0", 0.32, "ratio",
    "FAR 2024/47, Table 43.", "B2022/B0 point estimate; no uncertainty interval is tabulated.",
    region = "Hauraki Gulf", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "SSB", 143832, "tonnes",
    "FAR 2024/47, Table 43.", "B2022 point estimate; no uncertainty interval is tabulated.",
    region = "Hauraki Gulf", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("mortality", "exploitation_rate_reference_at_SB40", 0.049, "ratio",
    "FAR 2024/47, Table 44.", "U reference at equilibrium biomass of 40% B0.",
    region = "Hauraki Gulf", scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("mortality", "exploitation_rate", 0.031, "ratio",
    "FAR 2024/47, Table 44.", "MCMC median 2021-22 fishing-pressure U; 95% interval as reported.",
    region = "Hauraki Gulf", year = 2022, lwr = 0.027, upr = 0.036,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("probability", "probability_U_above_reference", 0, "proportion",
    "FAR 2024/47, Table 44.", "MCMC probability that U2022 exceeds the U reference at 40% B0.",
    region = "Hauraki Gulf", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("probability", "probability_U_below_reference", 1, "proportion",
    "FAR 2024/47, Table 44.", "MCMC probability that U2022 is below the U reference at 40% B0.",
    region = "Hauraki Gulf", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "unfished_spawning_biomass", 222603, "tonnes",
    "FAR 2024/47, Table 43.", "1968 base-model estimate; no uncertainty interval is tabulated.",
    region = "Bay of Plenty", scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "SSB_ratio_to_B0", 0.14, "ratio",
    "FAR 2024/47, Table 43.", "B2022/B0 point estimate; no uncertainty interval is tabulated.",
    region = "Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "SSB", 31164, "tonnes",
    "FAR 2024/47, Table 43.", "B2022 point estimate; no uncertainty interval is tabulated.",
    region = "Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("mortality", "exploitation_rate_reference_at_SB40", 0.049, "ratio",
    "FAR 2024/47, Table 46.", "U reference at equilibrium biomass of 40% B0.",
    region = "Bay of Plenty", scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("mortality", "exploitation_rate", 0.08, "ratio",
    "FAR 2024/47, Table 46.", "MCMC median 2021-22 fishing-pressure U; 95% interval as reported.",
    region = "Bay of Plenty", year = 2022, lwr = 0.07, upr = 0.11,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("probability", "probability_U_above_reference", 1, "proportion",
    "FAR 2024/47, Table 46.", "MCMC probability that U2022 exceeds the U reference at 40% B0.",
    region = "Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("probability", "probability_U_below_reference", 0, "proportion",
    "FAR 2024/47, Table 46.", "MCMC probability that U2022 is below the U reference at 40% B0.",
    region = "Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty 1968 base model (movement fixed at zero)"),
  output_row("biomass", "SSB", 142878, "tonnes",
    "FAR 2024/47, Table 45.", "Base-case SSB value in the sensitivity summary; differs from Table 43.",
    region = "Hauraki Gulf", year = 2022,
    scenario = "Table 45 sensitivity summary base case"),
  output_row("biomass", "SSB", 31685, "tonnes",
    "FAR 2024/47, Table 47.", "Base-case SSB value in the sensitivity summary; differs from Table 43.",
    region = "Bay of Plenty", year = 2022,
    scenario = "Table 47 sensitivity summary base case")
)
outputs <- rbind(outputs,
  output_row("mortality", "exploitation_rate_reference_at_SB40", 0.05, "ratio",
    "FAR 2024/47, Table 48.", "Combined model reference value at 40% B0.",
    region = "Hauraki Gulf/Bay of Plenty",
    scenario = "Hauraki Gulf/Bay of Plenty combined model"),
  output_row("mortality", "exploitation_rate", 0.041, "ratio",
    "FAR 2024/47, Table 48.", "MCMC median 2021-22 fishing-pressure U; 95% interval as reported.",
    region = "Hauraki Gulf/Bay of Plenty", year = 2022, lwr = 0.036, upr = 0.046,
    scenario = "Hauraki Gulf/Bay of Plenty combined model"),
  output_row("probability", "probability_U_above_reference", 0.0002, "proportion",
    "FAR 2024/47, Table 48.", "MCMC probability U2022 exceeds the U reference at 40% B0 (0.02%).",
    region = "Hauraki Gulf/Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty combined model"),
  output_row("probability", "probability_U_below_reference", 0.9998, "proportion",
    "FAR 2024/47, Table 48.", "MCMC probability U2022 is below the U reference at 40% B0 (99.98%).",
    region = "Hauraki Gulf/Bay of Plenty", year = 2022,
    scenario = "Hauraki Gulf/Bay of Plenty combined model")
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "Fisheries New Zealand",
  authority_stock_id = "SNA 1", scientific_name = "Chrysophrys auratus",
  common_name = "Snapper", area = "East Northland, Hauraki Gulf, and Bay of Plenty",
  region = "North Island, New Zealand", ocean = "Southwest Pacific",
  notes = "One SNA 1 management unit with three distinct modeled areas: East Northland, Hauraki Gulf, and Bay of Plenty.",
  stringsAsFactors = FALSE
)
assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2023L, terminal_year = 2022L, estimate_terminal_year = 2022L,
  assessment_type = "full_assessment", model_family = "Casal2", model_version = "",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://fs.fish.govt.nz/Doc/25775/FAR-2024-47-Assessment-of-SNA1-stocks%20in-2022-and-2023.pdf.ashx",
  framework_url = "", data_url = "https://fs.fish.govt.nz/Doc/25280/FAR-2022-24-Snapper-Age-Composition-SNA1-SNA2-201920-4267.pdf.ashx",
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = paste(
    "The latest detailed production assessment located is the 2023 SNA 1 assessment, confirmed as the most recent by the May 2025 Plenary.",
    "The assessment uses separate East Northland and Hauraki Gulf/Bay of Plenty models; canonical records retain area dimensions.",
    "The source catch table year labels are retained as printed. The assessment reports its terminal fishing year as 2021-22 and terminal B2022.",
    "Numerical CPUE and research-survey index vectors, most fitted age compositions, full annual weight-at-age surfaces, and age-specific population outputs are not fully recovered."
  ),
  stringsAsFactors = FALSE
)

## Append database records ----

append_csv <- function(path, rows) {
  header <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  if (!setequal(header, names(rows))) stop("Unexpected CSV schema for ", path, ".", call. = FALSE)
  rows <- rows[header]
  write.table(rows, path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = "", append = TRUE, qmethod = "double")
}
assessment_rows_exist <- function(path, id) {
  con <- file(path, open = "rt")
  on.exit(close(con))
  prefix <- paste0("\"", id, "\",")
  repeat {
    lines <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(lines)) return(FALSE)
    if (any(startsWith(lines, prefix))) return(TRUE)
  }
}
stocks_path <- file.path(root, "database", "stocks.csv")
assessments_path <- file.path(root, "database", "assessments.csv")
if (stock_id %in% read.csv(stocks_path, stringsAsFactors = FALSE)$stock_id ||
    assessment_id %in% read.csv(assessments_path, stringsAsFactors = FALSE)$assessment_id ||
    any(vapply(file.path(root, "database", c("assumptions.csv", "inputs.csv", "outputs.csv")),
      assessment_rows_exist, logical(1L), id = assessment_id))) {
  stop("The SNA 1 source record already exists; refusing to duplicate it.", call. = FALSE)
}
if (nrow(catches) != 1845L || nrow(age_compositions) != 120L ||
    nrow(inputs) != 1845L + 240L + 10L + 60L ||
    nrow(outputs) != 28L || nrow(assumptions) != 14L) {
  stop("Unexpected SNA 1 source-record counts.", call. = FALSE)
}
if (!write_data) {
  cat("SNA 1 import validated: ", nrow(catches), " catch rows, ",
    nrow(age_compositions), " age observations, ", nrow(tag_inputs),
    " tag value/CV rows, ", nrow(biology_inputs), " fixed biological rows, ",
    nrow(outputs), " outputs, and ", nrow(assumptions), " assumptions.\n",
    sep = "")
} else {
  append_csv(stocks_path, stock)
  append_csv(assessments_path, assessment)
  append_csv(file.path(root, "database", "assumptions.csv"), assumptions)
  append_csv(file.path(root, "database", "inputs.csv"), inputs)
  append_csv(file.path(root, "database", "outputs.csv"), outputs)
  candidate_path <- file.path(root, "discovery", "candidates.csv")
  candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  candidates <- candidates[!is.na(candidates$candidate_id) & nzchar(candidates$candidate_id), , drop = FALSE]
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(candidate_row) != 1L) stop("Expected one SNA 1 candidate row.", call. = FALSE)
  candidates$matched_stock_id[candidate_row] <- stock_id
  candidates$match_status[candidate_row] <- "matched"
  candidates$import_status[candidate_row] <- "partial"
  candidates$catch_age_evidence[candidate_row] <- paste(
    "FAR 2024/47 Tables Appendix 14-16 provide fleet-specific catch mass from source years 1900-2022.",
    "This is not catch-at-age. No fitted fishery catch-at-age vector was tabulated."
  )
  candidates$survey_age_evidence[candidate_row] <- paste(
    "FAR 2024/47 Table 40 lists CPUE, age-specific research-survey indices, and tagging inputs.",
    "Numeric fitted CPUE and survey-index vectors are not present in the reviewed tables; four 2019-20 age-composition series are available."
  )
  candidates$weights_evidence[candidate_row] <- paste(
    "The assessment uses area-specific length-weight functions and mean length-at-age matrices for 1989-2021.",
    "Complete annual model weight-at-age matrices are not tabulated."
  )
  candidates$maturity_evidence[candidate_row] <- "The assessment fixes maturity at 0 for ages 1-3, 0.5 at age 4, and 1 above age 4; imported as the age-1-30 vector."
  candidates$mortality_evidence[candidate_row] <- "The assessment fixes M at 0.075 per year across ages; imported as the age-1-30 vector."
  candidates$timing_evidence[candidate_row] <- paste(
    "The model uses two annual time steps and most observations occur in the spring-summer period.",
    "The extracted composition series are source spring-winter observations for fishing year 2019-20."
  )
  candidates$output_evidence[candidate_row] <- paste(
    "FAR 2024/47 Tables 36-37, 43-44, 46, and 48 report B0/status and exploitation-pressure summaries with uncertainty for selected quantities.",
    "Annual numerical N, F, and M-at-age outputs were not located."
  )
  candidates$notes[candidate_row] <- paste(
    "Imported partial source records: fleet-specific catch mass, four 2019-20 composition series, fixed M and maturity, tag estimates, and selected reported outputs.",
    "Fitted CPUE/survey index vectors, most composition years, full annual weights, and age-specific population outputs remain unavailable."
  )
  source(file.path(root, "scripts", "database", "candidate_register_io.R"))
  row_index <- candidate_row
  replace_candidate_register_row(candidate_path, row_index,
    candidates[candidate_row, , drop = FALSE], candidate_id)
  selection_path <- file.path(root, "discovery", "selected_batch_05_2026.csv")
  selection <- read.csv(selection_path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  selection_row <- which(selection$candidate_id == candidate_id)
  if (length(selection_row) != 1L ||
      !selection$curation_status[selection_row] %in% c("selected", "source_curated_partial")) {
    stop("Expected one selected SNA 1 source-curation row.", call. = FALSE)
  }
  selection$curation_status[selection_row] <- "source_curated_partial"
  write.csv(selection, selection_path, row.names = FALSE, na = "")
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = TRUE)
  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = TRUE)
  cat("Imported SNA 1 source records and updated the candidate register.\n")
}
