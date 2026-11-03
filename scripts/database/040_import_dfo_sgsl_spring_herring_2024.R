assessment_id <- "dfo_herring_4tvn_spring_2024"
summary_id <- "dfo_herring_4tvn_spring_2026"
stock_id <- "dfo_herring_4tvn_spring"
root <- "."
source_dir <- file.path(root, "source_cache", "dfo_sgsl_herring_spring_2023")
support_file <- file.path(source_dir, "2024_058_support.txt")
if (!file.exists(support_file)) stop("The cached 2024/058 text is missing.")
lines <- readLines(support_file, warn = FALSE, encoding = "UTF-8")

assessment_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41256384.pdf"
methods_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf"
acoustic_scale_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/365860.pdf"
summary_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-028-eng.pdf"
acoustic_data_url <- paste0(
  "https://open.canada.ca/data/en/dataset/",
  "7c17f4eb-93fc-11ea-b1dd-f48c505b2a29"
)
acoustic_biomass_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "7c17f4eb-93fc-11ea-b1dd-f48c505b2a29/attachments/",
  "7C17f4eb_herring_historic_biomass_2025.csv"
)
acoustic_dictionary_url <- paste0(
  "https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
  "7c17f4eb-93fc-11ea-b1dd-f48c505b2a29/attachments/",
  "7c17f4eb_herring_data_dictionary.csv"
)
assessment_ref <- "DFO Research Document 2024/058"

table_rows <- function(number, next_number, value_count, years,
                       section = NULL) {
  starts <- grep(paste0("^\\s*Table ", number, "\\."), lines)
  if (!length(starts)) stop("Cannot find Table ", number, ".")
  start <- tail(starts, 1L)
  ends <- grep(paste0("^\\s*Table ", next_number, "\\."), lines)
  ends <- ends[ends > start]
  end <- if (length(ends)) ends[[1]] else length(lines) + 1L
  x <- lines[seq.int(start + 1L, end - 1L)]
  if (!is.null(section)) {
    section_start <- grep(paste0("^\\s*", section, "\\s*$"), x)
    if (!length(section_start)) stop("Cannot find ", section, " in Table ", number, ".")
    x <- x[seq.int(section_start[[1]] + 1L, length(x))]
    if (section == "Spring spawners") {
      next_section <- grep("^\\s*Fall spawners\\s*$", x)
      if (length(next_section)) x <- x[seq_len(next_section[[1]] - 1L)]
    }
  }
  x <- x[grepl("^\\s*(19|20)[0-9]{2}\\s+", x)]
  tokens <- strsplit(gsub(",", "", trimws(x), fixed = TRUE), "[[:space:]]+")
  expected <- value_count + 1L
  tokens <- tokens[lengths(tokens) == expected]
  parsed_years <- as.integer(vapply(tokens, `[[`, character(1), 1L))
  if (!identical(parsed_years, as.integer(years))) {
    stop(
      "Unexpected years in Table ", number, ": ",
      paste(parsed_years, collapse = ", ")
    )
  }
  values <- lapply(tokens, function(row) {
    z <- row[-1L]
    z[z == "-"] <- NA_character_
    suppressWarnings(as.numeric(z))
  })
  if (any(vapply(values, function(z) any(!is.na(z) & !is.finite(z)), logical(1)))) {
    stop("Non-numeric values in Table ", number, ".")
  }
  cbind(year = parsed_years, do.call(rbind, values))
}

years <- 1978:2023
ages <- 2:11
catch_fixed <- table_rows(4, 5, 11, years)
weight_fixed <- table_rows(5, 6, 10, years)
catch_mobile <- table_rows(8, 9, 11, 1978:2022)
weight_mobile <- table_rows(9, 10, 10, 1978:2022)
cpue <- table_rows(13, 14, 8, 1990:2021)
acoustic <- table_rows(15, 16, 9, 1994:2023, "Spring spawners")
acoustic_biomass_file <- file.path(source_dir, "herring_historic_biomass_2025.csv")
acoustic_dictionary_file <- file.path(source_dir, "herring_data_dictionary.csv")
if (!file.exists(acoustic_biomass_file) || !file.exists(acoustic_dictionary_file)) {
  stop("The cached acoustic biomass CSV or data dictionary is missing.")
}
biomass_lines <- readLines(acoustic_biomass_file, warn = FALSE, encoding = "latin1")
acoustic_biomass_data <- read.csv(
  text = paste(biomass_lines[-1L], collapse = "\n"), header = FALSE,
  col.names = c(
    "year", "fall_biomass", "spring_biomass", "total_biomass",
    "prop_fall", "prop_spring"
  ), check.names = FALSE
)
dictionary_lines <- readLines(acoustic_dictionary_file,
  warn = FALSE,
  encoding = "latin1"
)
if (ncol(acoustic_biomass_data) != 6L ||
  !identical(as.integer(acoustic_biomass_data[[1L]]), 1994:2025) ||
  !all(is.finite(as.numeric(acoustic_biomass_data[[3L]])))) {
  stop("Unexpected years, columns, or values in the acoustic biomass CSV.")
}
if (sum(grepl(
  "^Spring_acoustic_biomass.*Spring spawners acoustic biomass in tons \\(t\\)",
  dictionary_lines
)) != 1L) {
  stop("The acoustic data dictionary does not confirm spring biomass in tonnes.")
}
biomass <- table_rows(18, 19, 11, years)
abundance <- table_rows(19, 20, 11, years)
fishing_mortality <- table_rows(20, 21, 11, years)

long_rows <- function(table, value_columns, ages, type, measure, basis, unit,
                      fleet = "", survey = "", season = "",
                      source_table, source_type = "official_table",
                      notes = "") {
  indices <- expand.grid(
    year = table[, 1], age_index = seq_along(ages),
    KEEP.OUT.ATTRS = FALSE
  )
  indices <- indices[order(indices$year, indices$age_index), ]
  value <- as.vector(t(table[, value_columns, drop = FALSE]))
  keep <- !is.na(value)
  indices <- indices[keep, , drop = FALSE]
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    basis = basis, fleet = fleet, survey = survey, sex = "", region = "",
    season = season, year = indices$year, year_basis = "calendar_year",
    age = ages[indices$age_index], value = value[keep], unit = unit,
    sampling_time = NA_real_, source_type = source_type,
    source_reference = paste(assessment_ref, "Table", source_table),
    transformation = "", notes = notes, stringsAsFactors = FALSE
  )
}

inputs <- rbind(
  long_rows(catch_fixed, 2:11, ages, "catch", "numbers_at_age", "numbers",
    "thousand fish", "Fixed gear",
    season = "spring", source_table = 4,
    notes = "Spring-spawner catch at age; age 11 is the 11+ group."
  ),
  long_rows(catch_mobile, 2:11, ages, "catch", "numbers_at_age", "numbers",
    "thousand fish", "Mobile gear",
    season = "spring", source_table = 8,
    notes = "Spring-spawner catch at age; age 11 is the 11+ group."
  ),
  long_rows(weight_fixed, 2:11, ages, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "Fixed gear",
    season = "spring", source_table = 5,
    notes = "Published fishery weight at age; a dash denotes an unreported value."
  ),
  long_rows(weight_mobile, 2:11, ages, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", "Mobile gear",
    season = "spring", source_table = 9,
    notes = "Published fishery weight at age; a dash denotes an unreported value."
  ),
  long_rows(cpue, 2:9, 4:11, "index", "numbers_at_age", "numbers",
    "number per net-haul",
    survey = "Spring fixed-gear CPUE",
    season = "spring", source_table = 13,
    notes = "Age-specific CPUE values. The source SCA used the aggregate index with age composition; direct age-specific use is a tinyAM approximation."
  ),
  long_rows(acoustic, 2:10, 2:10, "index", "numbers_at_age", "numbers",
    "thousand fish",
    survey = "4Tmno acoustic survey", season = "fall",
    source_table = 15,
    notes = paste(
      "Spring-spawner age-disaggregated acoustic abundance-index values.",
      "Table 15 omits the unit; DFO Research Document 2016/060 Table 16",
      "explicitly identifies the same historical series as thousands of fish.",
      "Table 15 values are retained unchanged in thousand fish; conversion",
      "to fish requires multiplication by 1000. The 2022 methods describe the source",
      "likelihood as age composition plus an aggregate biomass index."
    )
  )
)
acoustic_rows <- inputs$survey == "4Tmno acoustic survey"
inputs$source_reference[acoustic_rows] <- paste(
  assessment_ref, "Table 15; DFO Research Document 2016/060 Table 16 (unit clarification)",
  acoustic_scale_url
)
inputs$transformation[acoustic_rows] <- paste(
  "Resolved the omitted unit as thousand fish using the historical acoustic",
  "table in DFO 2016/060; retained the 2024 Table 15 numerical values."
)
acoustic_biomass_2026 <- data.frame(
  assessment_id = summary_id,
  type = "index", measure = "total_biomass", basis = "biomass",
  fleet = "", survey = "4Tmno acoustic survey", sex = "", region = "",
  season = "fall", year = as.integer(acoustic_biomass_data[[1L]]),
  year_basis = "calendar_year", age = NA_real_,
  value = as.numeric(acoustic_biomass_data[[3L]]), unit = "tonnes",
  sampling_time = NA_real_, source_type = "official_machine_readable",
  source_reference = paste0(
    acoustic_biomass_url, " (Spring_acoustic_biomass); ", acoustic_dictionary_url
  ),
  transformation = "",
  notes = paste(
    "Spring-spawner acoustic biomass from the 2025 data release.",
    "Kept with the separate 2026 summary assessment record; values are not",
    "used as inputs to the official 2024 assessment."
  ),
  stringsAsFactors = FALSE
)
mobile_zero <- long_rows(
  matrix(c(2023, rep(0, 11)), nrow = 1L), 2:11, ages,
  "catch", "numbers_at_age", "numbers", "thousand fish",
  "Mobile gear",
  season = "spring", source_table = 1,
  source_type = "reconstructed_source_input",
  notes = "The annual landings table reports zero 2023 spring mobile-gear catch; zero catch was assigned to each age."
)
mobile_zero$transformation <- "Expanded the reported zero annual mobile-gear catch into zero catch-at-age values."
inputs <- rbind(inputs, mobile_zero)
maturity <- data.frame(
  assessment_id = assessment_id, type = "maturity", measure = "maturity_at_age",
  basis = "proportion", fleet = "", survey = "", sex = "", region = "",
  season = "spring", year = NA_real_, year_basis = "", age = ages,
  value = c(0, 0, rep(1, length(ages) - 2L)), unit = "proportion",
  sampling_time = NA_real_, source_type = "official_document",
  source_reference = "DFO Research Document 2022/068, p. 10",
  transformation = "",
  notes = "The assessment assumes knife-edge maturity between ages 3 and 4.",
  stringsAsFactors = FALSE
)
inputs <- rbind(inputs, maturity)

make_output <- function(table, columns, ages, type, measure, unit,
                        source_table, notes) {
  long_rows(table, columns, ages, type, measure, "", unit,
    source_table = source_table, notes = notes
  )[
    c(
      "assessment_id", "type", "measure", "fleet", "survey", "sex",
      "region", "season", "year", "age", "value", "unit",
      "source_type", "source_reference", "notes"
    )
  ]
}

outputs <- rbind(
  make_output(
    abundance, 2:11, ages, "population", "numbers_at_age",
    "thousand fish", 19, "January 1 MLE abundance; age 11 is 11+."
  ),
  make_output(
    biomass, 2:11, ages, "biomass", "biomass_at_age",
    "tonnes", 18, "January 1 MLE biomass; this is not April 1 spawning biomass; age 11 is 11+."
  ),
  make_output(
    fishing_mortality, 2:11, ages, "mortality",
    "fishing_mortality_at_age", "per_year", 20,
    "January 1 fishing mortality; age 11 is 11+."
  )
)
outputs$age_group <- ""
outputs$se <- NA_real_
outputs$lwr <- NA_real_
outputs$upr <- NA_real_
annual_output <- function(measure, type, year, value, unit, source_table,
                          age = NA_real_, age_group = "", notes = "",
                          source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = year, age = age, age_group = age_group, value = value,
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = source_type,
    source_reference = paste(assessment_ref, "Table", source_table),
    notes = notes, stringsAsFactors = FALSE
  )
}
outputs <- rbind(
  outputs,
  annual_output("recruitment", "recruitment", abundance[, 1],
    abundance[, 2], "thousand fish", 19,
    age = 2,
    notes = "Recruitment is the estimated abundance at age 2."
  ),
  annual_output("total_numbers", "population", abundance[, 1],
    abundance[, 12], "thousand fish", 19,
    age_group = "4+",
    notes = "January 1 abundance summed over ages 4+."
  ),
  annual_output("total_biomass", "biomass", biomass[, 1],
    biomass[, 12], "tonnes", 18,
    age_group = "4+",
    notes = "January 1 biomass summed over ages 4+; not April 1 SSB."
  ),
  annual_output("Fbar", "mortality", fishing_mortality[, 1],
    fishing_mortality[, 12], "per_year", 20,
    age_group = "6-8",
    notes = "January 1 abundance-weighted F for ages 6-8."
  )
)
derived <- rbind(
  annual_output("total_numbers", "population", abundance[, 1],
    rowSums(abundance[, 2:11, drop = FALSE]), "thousand fish", 19,
    source_type = "derived_source_output",
    notes = "Sum of January 1 MLE abundance over ages 2-11+ from Table 19; no aggregate uncertainty is available."
  ),
  annual_output("total_biomass", "biomass", biomass[, 1],
    rowSums(biomass[, 2:11, drop = FALSE]), "tonnes", 18,
    source_type = "derived_source_output",
    notes = "Sum of January 1 MLE biomass over ages 2-11+ from Table 18; no aggregate uncertainty is available."
  ),
  annual_output("SSB", "biomass", biomass[, 1],
    rowSums(sweep(biomass[, 2:11, drop = FALSE], 2, maturity$value, `*`)),
    "tonnes", 18,
    source_type = "derived_source_output",
    notes = paste(
      "January 1 mature biomass: sum of Table 18 MLE biomass-at-age",
      "times the knife-edge maturity schedule in DFO 2022/068, p. 10.",
      "This is a common January 1 definition, not the assessment's",
      "April 1 SSB; pre-spawning mortality and aggregate uncertainty are unavailable."
    )
  )
)
derived$source_reference[derived$measure == "SSB"] <- paste(
  assessment_ref, "Table 18; DFO Research Document 2022/068, p. 10"
)
mature_biomass <- make_output(
  cbind(year = biomass[, 1], sweep(biomass[, 2:11, drop = FALSE], 2, maturity$value, `*`)),
  2:11, ages, "biomass", "mature_biomass_at_age", "tonnes", 18,
  "January 1 MLE biomass-at-age times knife-edge maturity; not April 1 spawning biomass. Uncertainty unavailable."
)
mature_biomass$age_group <- ""
mature_biomass$se <- mature_biomass$lwr <- mature_biomass$upr <- NA_real_
mature_biomass$source_type <- "derived_source_output"
mature_biomass$source_reference <- paste(
  assessment_ref, "Table 18; DFO Research Document 2022/068, p. 10"
)
outputs <- rbind(outputs, derived, mature_biomass[names(outputs)])
outputs <- outputs[c(
  "assessment_id", "type", "measure", "fleet", "survey",
  "sex", "region", "season", "year", "age", "age_group", "value",
  "se", "lwr", "upr", "unit", "source_type",
  "source_reference", "notes"
)]

assumptions_2024 <- data.frame(
  component = c(
    "model", "population", "population", "population", "N", "N",
    "F", "M", "M", "index", "index", "biology", "biology", "catch"
  ),
  setting = c(
    "model_family", "years", "ages", "spatial_scale", "recruitment_age",
    "initial_abundance", "selectivity", "age_groups", "process",
    "spring_CPUE", "acoustic_survey", "maturity", "weights", "catch_input"
  ),
  value = c(
    "Statistical catch-at-age model implemented in AD Model Builder",
    "1978-2023", "2-11+", "One spring-spawner population for the sGSL; no regional disaggregation",
    "Age 2", "Age-2 recruitment is estimated annually; older initial cohorts are reconstructed from recruitment and survival",
    "Logistic fishery selectivity with three documented time blocks: 1978-1989, 1990-2004, 2005-2021; 2022-2023 update not separately described",
    "M is estimated for ages 2-6 and 7-11+",
    "Log-M random walks; increment SD fixed at 0.075; initial M prior mean 0.2 and SD 0.1",
    "Fixed-gear spring CPUE, age values 4-11 published for 1990-2021; the documented SCA used an age-aggregated biomass index and age composition",
    "Fishery-independent acoustic survey in September-October; spring-spawner age-disaggregated index values for ages 2-10, 1994-2023; the documented SCA used age composition and a separate age-aggregated biomass index",
    "Knife-edge: ages 2-3 immature and ages 4-11+ mature",
    "Annual fixed- and mobile-gear fishery weights are published separately; the combined beginning-of-year stock-weight construction is described but not fully specified in the support document",
    "Fixed- and mobile-gear catch-at-age, ages 2-11+, 1978-2023"
  ),
  survey = c(
    "", "", "", "", "", "", "", "", "", "Spring fixed-gear CPUE",
    "4Tmno acoustic survey", "", "", ""
  ),
  source_reference = c(
    paste(assessment_ref, "p. 6"), paste(assessment_ref, "Tables 4 and 8"),
    paste(assessment_ref, "p. 6"), paste(assessment_ref, "p. 6"),
    paste("DFO Research Document 2022/068, p. 12"),
    paste("DFO Research Document 2022/068, p. 12"),
    paste("DFO Research Document 2022/068, pp. 10-13"),
    paste("DFO Research Document 2022/068, p. 11"),
    paste("DFO Research Document 2022/068, p. 11"),
    paste(assessment_ref, "Table 13; DFO Research Document 2022/068, pp. 8-9"),
    paste(assessment_ref, "Table 15; DFO Research Document 2022/068, p. 10"),
    paste("DFO Research Document 2022/068, p. 10"),
    paste(assessment_ref, "Tables 5 and 9; DFO Research Document 2022/068, p. 6"),
    paste(assessment_ref, "Tables 4 and 8")
  ),
  notes = rep("", 14), stringsAsFactors = FALSE
)
assumptions_2024$notes[assumptions_2024$setting == "selectivity"] <-
  "The 2024/058 support report does not repeat the model methods; these blocks are the last detailed description in 2022/068 and may not fully describe the 2022-2023 run."
assumptions_2024$notes[assumptions_2024$setting == "weights"] <-
  "Source methods calculate beginning-of-year weights from fixed and mobile gear weights combined, then use the geometric mean of age a-1 in year t-1 and age a in year t. The report does not publish the complete fitted stock-weight matrix or specify how the two gear series are combined."
assumptions_2024$notes[assumptions_2024$setting == "spring_CPUE"] <-
  "No commercial spring CPUE was available for 2022-2023 after the fishery closure."
assumptions_2024$notes[assumptions_2024$setting == "acoustic_survey"] <- paste(
  "The 2022/068 methods describe a multivariate-logistic likelihood for",
  "age composition and a separate lognormal age-aggregated biomass index,",
  "with the acoustic biomass likelihood weighted by 3. The spring biomass",
  "index uses ages 4-8; the 2024/058 support report does not restate the",
  "observation weighting or full likelihood. Table 15 values are recorded",
  "in thousand fish, following the explicit units for the same acoustic",
  "series in DFO 2016/060 Table 16; conversion to fish multiplies by 1000."
)

assumptions_2026 <- data.frame(
  component = c(
    "assessment", "model", "population", "population", "N", "F", "M",
    "index", "index", "index", "biology"
  ),
  setting = c(
    "assessment_type", "model_family", "spatial_scale", "year_range",
    "process", "process", "process", "commercial_CPUE", "acoustic",
    "multispecies_RV", "maturity"
  ),
  value = c(
    "Full assessment", "State-space model; detailed methods are in preparation",
    "Whole sGSL; spring spawning component", "Input data through 2025",
    "Process errors allowed on recruitment", "Process errors allowed on selectivity",
    "Process errors allowed on natural mortality",
    "Telephone survey and DMP inform commercial CPUE through 2021; no spring commercial CPUE in 2022-2025",
    "Catch-at-age and abundance information through 2025",
    "Biomass index added for 1994-2025",
    "Data-driven year-by-age maturity estimates replace the historical knife-edge assumption"
  ),
  survey = c(
    "", "", "", "", "", "", "", "Spring fixed-gear CPUE",
    "4Tmno acoustic survey", "DFO multispecies RV survey", ""
  ),
  source_reference = summary_url,
  notes = c(
    "DFO Science Advisory Report 2026/028; peer-reviewed March 18-19, 2026.",
    "Detailed Research Document is listed as in preparation.",
    rep("", 9)
  ), stringsAsFactors = FALSE
)
assumptions_2024$assessment_id <- assessment_id
assumptions_2024 <- assumptions_2024[c("assessment_id", setdiff(names(assumptions_2024), "assessment_id"))]
assumptions_2026$assessment_id <- summary_id
assumptions_2026 <- assumptions_2026[c("assessment_id", setdiff(names(assumptions_2026), "assessment_id"))]
assumptions_2026$source_reference[
  assumptions_2026$setting == "acoustic"
] <- paste(acoustic_biomass_url, acoustic_dictionary_url)
assumptions_2026$notes[
  assumptions_2026$setting == "acoustic"
] <- paste(
  "The CSV and dictionary are cached locally. The series is linked to the",
  "2026 summary-only record and is not mixed into the 2024 assessment."
)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "DFO",
  authority_stock_id = "NAFO Division 4TVn spring-spawning component",
  scientific_name = "Clupea harengus",
  common_name = "Southern Gulf of St. Lawrence spring-spawning Atlantic herring",
  area = "NAFO Division 4TVn", region = "Gulf Region",
  ocean = "Northwest Atlantic",
  notes = "Spring-spawning component is distinct from the fall-spawning component. No Charbonneau identifier is recorded in the current database."
)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id, assessment_year = 2024,
  terminal_year = 2023, estimate_terminal_year = 2023,
  assessment_type = "full_assessment", model_family = "SCA",
  model_version = "2020 SCA model updated for the 2022-2023 assessment",
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = assessment_url, framework_url = methods_url,
  data_url = "", model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = "Most recent official assessment with recoverable detailed source. The 2024/058 document provides support tables and data changes, not a full mathematical model description; 2022/068 is used for method context. The 2026 full assessment is recorded separately because its detailed report is still in preparation.",
  stringsAsFactors = FALSE
)
summary_assessment <- data.frame(
  assessment_id = summary_id, stock_id = stock_id, assessment_year = 2026,
  terminal_year = 2025, estimate_terminal_year = 2025,
  assessment_type = "full_assessment", model_family = "state-space",
  model_version = "2026 official assessment; detailed report in preparation",
  is_current = FALSE, is_applied = TRUE, framework_year = "",
  assessment_url = summary_url, framework_url = "", data_url = acoustic_data_url,
  model_url = "", repository_url = "", assumptions_status = "partial",
  inputs_status = "partial", outputs_status = "partial",
  notes = "Official at the March 2026 peer review and reported through 2025. Numerical input tables, full methods, and model outputs remain unavailable because the detailed DFO Research Document is in preparation. No 2026-run values are mixed into the 2024 detailed record.",
  stringsAsFactors = FALSE
)
assumptions <- rbind(assumptions_2024, assumptions_2026)
assumptions$fleet <- ""
assumptions$sex <- ""
assumptions$region <- ""
assumptions$season <- ""

inputs$observation_id <- ""
inputs$length_bin <- NA_real_
inputs$length_bin_lower <- NA_real_
inputs$length_bin_upper <- NA_real_
inputs$sample_size <- NA_real_
inputs$age_error <- NA_real_
inputs$partition <- NA_real_
acoustic_biomass_2026$observation_id <- ""
acoustic_biomass_2026$length_bin <- NA_real_
acoustic_biomass_2026$length_bin_lower <- NA_real_
acoustic_biomass_2026$length_bin_upper <- NA_real_
acoustic_biomass_2026$sample_size <- NA_real_
acoustic_biomass_2026$age_error <- NA_real_
acoustic_biomass_2026$partition <- NA_real_
acoustic_biomass_2026 <- acoustic_biomass_2026[names(inputs)]
inputs_all <- rbind(inputs, acoustic_biomass_2026)

write_updated <- function(name, new_rows, key) {
  path <- file.path(root, "database", name)
  columns <- names(read.csv(path, nrows = 0, check.names = FALSE))
  new_rows <- new_rows[columns]
  ids <- unique(as.character(new_rows[[key]]))
  for (id in ids) {
    current <- new_rows[as.character(new_rows[[key]]) == id, , drop = FALSE]
    lines_existing <- readLines(path, warn = FALSE, encoding = "UTF-8")
    starts <- paste0(id, ",")
    existing <- lines_existing[startsWith(lines_existing, starts) |
      startsWith(lines_existing, paste0('"', id, '",'))]
    csv_field <- function(x) {
      if (is.na(x)) {
        return("")
      }
      x <- enc2utf8(as.character(x))
      if (grepl('[",\r\n]', x) || grepl("^\\s|\\s$", x)) {
        paste0('"', gsub('"', '""', x, fixed = TRUE), '"')
      } else {
        x
      }
    }
    new_lines <- vapply(seq_len(nrow(current)), function(i) {
      paste(vapply(current, function(column) csv_field(column[i]), character(1)),
        collapse = ","
      )
    }, character(1))
    if (identical(existing, new_lines)) next
    original <- readBin(path, "raw", n = file.info(path)[["size"]])
    crlf <- length(original) > 1L && any(original[-1L] == as.raw(10) &
      original[-length(original)] == as.raw(13))
    eol <- if (crlf) "\r\n" else "\n"
    existing_rows <- which(startsWith(lines_existing, starts) |
      startsWith(lines_existing, paste0('"', id, '",')))
    if (length(existing_rows)) {
      first <- min(existing_rows)
      rows <- append(lines_existing[-existing_rows], new_lines, after = first - 1L)
    } else {
      rows <- c(lines_existing, new_lines)
    }
    suffix <- if (length(original) && tail(original, 1L) == as.raw(10)) eol else ""
    con <- file(path, open = "wb")
    writeBin(charToRaw(enc2utf8(paste0(paste(rows, collapse = eol), suffix))), con)
    close(con)
  }
}

write_database <- if (exists("write_database", inherits = FALSE)) {
  isTRUE(write_database)
} else {
  FALSE
}
if (write_database) {
  write_updated("stocks.csv", stock, "stock_id")
  write_updated("assessments.csv", rbind(assessment, summary_assessment), "assessment_id")
  write_updated("assumptions.csv", assumptions, "assessment_id")
  write_updated("inputs.csv", inputs_all, "assessment_id")
  write_updated("outputs.csv", outputs, "assessment_id")
}

cat(
  "Prepared", nrow(inputs_all), "source inputs and", nrow(outputs),
  "reported outputs for", assessment_id, "and summary record", summary_id, ".\n"
)
