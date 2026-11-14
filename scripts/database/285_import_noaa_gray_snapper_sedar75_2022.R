root <- "."
stock_id <- "noaa_gray_snapper_gulf"
assessment_id <- "noaa_gray_snapper_gulf_sedar75_2022"
candidate_id <- "NOAA:10221"
cache_name <- "discovery_noaa_gray_snapper_2022"
report_url <- "https://sedarweb.org/assessments/sedar-75/"

source(file.path(root, "scripts/database/pacific_tables.R"))
source(file.path(root, "scripts/database/candidate_register_io.R"))

cache <- file.path(root, "source_cache", cache_name)
manifest <- read.csv(file.path(root, "provenance", cache_name, "sources.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = FALSE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not hash cached source: ", path, call. = FALSE)
  hashes
}

verify_source <- function(name) {
  record <- manifest[manifest$file == name, , drop = FALSE]
  path <- file.path(cache, name)
  if (nrow(record) != 1L || !file.exists(path) ||
      !identical(sha256_file(path), tolower(record$sha256))) {
    stop("Cached source differs from its provenance record: ", name, call. = FALSE)
  }
  path
}

invisible(lapply(manifest$file, verify_source))
report_file <- verify_source("sedar75_final_assessment.pdf")
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to parse the cached SEDAR 75 tables.", call. = FALSE)
}
report_pages <- pdftools::pdf_text(report_file)
report_layout <- pdftools::pdf_data(report_file)

parse_number <- function(x) {
  x <- gsub(",", "", as.character(x), fixed = TRUE)
  x <- sub("\\*$", "", x)
  suppressWarnings(as.numeric(x))
}

parse_layout_table <- function(page_ids, expected_years, year_x, centers,
                               year_tolerance = 18, value_tolerance = 25) {
  rows <- list()
  for (page_id in page_ids) {
    page <- as.data.frame(report_layout[[page_id]])
    page <- page[is.finite(page$x) & is.finite(page$y), , drop = FALSE]
    year_value <- suppressWarnings(as.integer(gsub("[^0-9]", "", page$text)))
    year_rows <- which(year_value %in% expected_years &
      abs(page$x - year_x) <= year_tolerance)
    for (i in year_rows) {
      year <- year_value[[i]]
      line <- page[abs(page$y - page$y[[i]]) < 0.6, , drop = FALSE]
      values <- rep(NA_real_, length(centers))
      for (j in seq_along(centers)) {
        distance <- abs(line$x - centers[[j]])
        candidates <- which(distance <= value_tolerance &
          grepl("^[0-9][0-9,]*(\\.[0-9]+)?\\*?$", line$text))
        if (length(candidates)) {
          nearest <- candidates[which.min(distance[candidates])]
          values[[j]] <- parse_number(line$text[[nearest]])
        }
      }
      row <- as.data.frame(setNames(
        as.list(c(year, values)), c("year", paste0("v", seq_along(centers)))
      ), check.names = FALSE)
      rows[[length(rows) + 1L]] <- row
    }
  }
  if (!length(rows)) stop("No numeric rows found in a source table on pages ", paste(page_ids, collapse = ","), ".", call. = FALSE)
  out <- do.call(rbind, rows)
  names(out) <- c("year", paste0("v", seq_along(centers)))
  out <- out[order(out$year), , drop = FALSE]
  if (anyDuplicated(out$year) || !setequal(out$year, expected_years)) {
    stop("Source table years are incomplete or duplicated on pages ", paste(page_ids, collapse = ","), ": missing ", paste(setdiff(expected_years, out$year), collapse = ","), "; duplicates ", paste(unique(out$year[duplicated(out$year)]), collapse = ","), call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

parse_mortality <- function() {
  lines <- unlist(lapply(report_pages[c(55L, 56L)], function(x) {
    strsplit(x, "\n", fixed = TRUE)[[1L]]
  }), use.names = FALSE)
  candidate_lines <- grep(
    "^[[:space:]]*[0-9]+[[:space:]]+[0-9.]+[[:space:]]+[0-9.]+[[:space:]]+[0-9.]+[[:space:]]*$",
    lines, value = TRUE, perl = TRUE
  )
  rows <- lapply(candidate_lines, function(line) {
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    as.numeric(tokens)
  })
  rows <- rows[lengths(rows) == 4L]
  out <- as.data.frame(do.call(rbind, rows))
  names(out) <- c("age", "base", "upper", "lower")
  out$age <- as.integer(out$age)
  out <- out[order(out$age), , drop = FALSE]
  if (!identical(out$age, 0:28)) {
    stop("SEDAR 75 Table 3 M ages did not parse as 0-28.", call. = FALSE)
  }
  out
}

table13 <- rbind(
  parse_layout_table(101, 1945:1971, year_x = 93,
    centers = c(146, 211, 276, 359, 431, 514), value_tolerance = 30),
  parse_layout_table(102:103, 1972:2020, year_x = 40,
    centers = c(98, 200, 283, 420, 475, 555), value_tolerance = 30)
)
names(table13) <- c("year", "biomass_all", "biomass_2plus", "ssb",
  "numbers_2plus", "recruitment", "ssb_ratio")

table35 <- parse_layout_table(
  149:151, 1945:2020, year_x = 86,
  centers = c(169, 256, 300, 393, 457, 514),
  value_tolerance = 30
)
names(table35) <- c("year", "harvest_rate", "f_over_fspr30", "ssb",
  "ssb_over_spr30", "ssb_over_msst", "ssb_ratio")

mortality <- parse_mortality()

commercial_landings <- list(
  list(pages = 104:106, fleet = "Commercial Vertical Line"),
  list(pages = 107:109, fleet = "Commercial Longline"),
  list(pages = 110:112, fleet = "Commercial Nets & Traps")
)
recreational_landings <- list(
  list(pages = 113:115, fleet = "Recreational Private"),
  list(pages = 116:118, fleet = "Recreational Shore"),
  list(pages = 119:121, fleet = "Recreational Charter & Headboat")
)

parse_model_landings <- function(spec, biomass) {
  year_values <- if (biomass) 1944:2020 else 1945:2020
  centers <- if (biomass) c(249, 297) else c(254, 312)
  table <- parse_layout_table(spec$pages, year_values, 177, centers,
    year_tolerance = 20, value_tolerance = 28)
  names(table) <- c("year", "log_sd", "value")
  table <- table[table$year >= 1945, , drop = FALSE]
  if (!setequal(table$year, 1945:2020) || anyDuplicated(table$year) ||
      any(!is.finite(table$value)) || any(!is.finite(table$log_sd))) {
    stop("SEDAR 75 landings table is missing a model-year input for ", spec$fleet, "; missing years ", paste(setdiff(1945:2020, table$year), collapse = ","), "; non-finite years ", paste(table$year[!is.finite(table$value) | !is.finite(table$log_sd)], collapse = ","), call. = FALSE)
  }
  table$fleet <- spec$fleet
  table$basis <- if (biomass) "biomass" else "numbers"
  table$measure <- if (biomass) "landings_biomass" else "landings_numbers"
  table$unit <- if (biomass) "million pounds whole weight" else "thousand fish"
  table_number <- if (biomass) {
    match(spec$fleet, vapply(commercial_landings, function(x) x$fleet, character(1))) + 13L
  } else {
    match(spec$fleet, vapply(recreational_landings, function(x) x$fleet, character(1))) + 16L
  }
  table$source_reference <- paste0("SEDAR75_SAR.pdf, Table ", table_number)
  table
}

commercial_inputs <- lapply(commercial_landings, parse_model_landings, biomass = TRUE)
recreational_inputs <- lapply(recreational_landings, parse_model_landings, biomass = FALSE)

index_years <- 1981:2020
index_centers <- c(152, 210, 268, 325, 383, 440, 498)
index_names <- c(
  "MRIP Private CPUE", "MRIP Shore CPUE", "FWRI Age-0 FIM",
  "FWRI Age-1 FIM", "SEAMAP Summer Groundfish Trawl",
  "Combined Video Survey", "Reef Fish Visual Census"
)
index_values <- parse_layout_table(66:67, index_years, 98, index_centers,
  value_tolerance = 28)
index_sds <- parse_layout_table(68:69, index_years, 98, index_centers,
  value_tolerance = 28)
names(index_values) <- names(index_sds) <- c("year", index_names)
if (!identical(index_values$year, index_sds$year) ||
    !identical(names(index_values), names(index_sds))) {
  stop("SEDAR 75 index and log-SD tables do not align.", call. = FALSE)
}
for (survey in index_names) {
  if (!identical(is.na(index_values[[survey]]), is.na(index_sds[[survey]]))) {
    stop("Index observations and log-SDs differ for ", survey, ".", call. = FALSE)
  }
}

commercial_discard <- parse_layout_table(62:63, 1993:2020, 142,
  centers = c(221, 317, 391, 451), year_tolerance = 16,
  value_tolerance = 28)
names(commercial_discard) <- c("year", "vl_numbers", "vl_log_sd",
  "ll_numbers", "ll_log_sd")

recreational_discard <- parse_layout_table(64:65, 1981:2020, 52,
  centers = c(100, 164, 215, 279, 332, 409, 460, 538),
  year_tolerance = 16, value_tolerance = 25)
names(recreational_discard) <- c("year", "charter_numbers", "charter_log_sd",
  "headboat_numbers", "headboat_log_sd", "private_numbers", "private_log_sd",
  "shore_numbers", "shore_log_sd")

output_row <- function(type, measure, value, unit, year, age = NA_integer_,
                       age_group = NA_character_, source_reference,
                       notes = "") {
  pacific_database_row("outputs", assessment_id = assessment_id,
    type = type, measure = measure, value = value, unit = unit,
    year = year, age = age, age_group = age_group,
    source_type = "official_table", source_reference = source_reference,
    notes = notes)
}

outputs <- do.call(rbind, list(
  output_row("biomass", "total_biomass", table13$biomass_all,
    "metric tons", table13$year, source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "Expected total biomass, all ages; rounded source estimates; annual uncertainty is not tabulated."),
  output_row("biomass", "biomass_by_age_group", table13$biomass_2plus,
    "metric tons", table13$year, age_group = "2+",
    source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "Expected exploited biomass for ages 2+; rounded source estimates."),
  output_row("biomass", "SSB", table13$ssb, "metric tons", table13$year,
    source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "Spawning stock biomass, sexes combined; rounded source estimates."),
  output_row("population", "total_numbers", table13$numbers_2plus,
    "thousand fish", table13$year, age_group = "2+",
    source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "Exploited abundance for ages 2+ only; this is not total abundance."),
  output_row("recruitment", "recruitment", table13$recruitment,
    "thousand fish", table13$year, age = 0L,
    source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "Age-0 recruits; rounded source estimates."),
  output_row("biomass", "SSB_ratio_to_B0", table13$ssb_ratio,
    "proportion", table13$year, source_reference = "SEDAR75_SAR.pdf, Table 13",
    notes = "SSB divided by unfished SSB; source table identifies SSB0 as 21,718 metric tons."),
  output_row("mortality", "exploitation_rate", table35$harvest_rate,
    "proportion", table35$year, source_reference = "SEDAR75_SAR.pdf, Table 35",
    notes = "Source-defined harvest rate: total biomass killed at ages 2+ divided by total biomass at ages 2+; not instantaneous F.")
))

input_row <- function(type, measure, value, unit, basis,
                      year = NA_integer_, age = NA_integer_,
                      fleet = NA_character_, survey = NA_character_,
                      partition = NA_character_,
                      source_reference, notes = "", transformation = "") {
  pacific_database_row("inputs", assessment_id = assessment_id,
    type = type, measure = measure, value = value, unit = unit, basis = basis,
    year = year, year_basis = ifelse(is.na(year), NA_character_, "calendar_year"),
    age = age, fleet = fleet, survey = survey, partition = partition,
    source_type = "official_table", source_reference = source_reference,
    transformation = transformation, notes = notes)
}

inputs <- list()
for (series in c(commercial_inputs, recreational_inputs)) {
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", series$measure, series$value, series$unit, series$basis,
    year = series$year, fleet = series$fleet,
    partition = "landings",
    source_reference = series$source_reference,
    notes = "SEDAR table-reported model input, rounded to displayed precision; 1945-2020 model years."
  )
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", "log_catch_sd", series$log_sd, "log scale", "log_scale",
    year = series$year, fleet = series$fleet,
    partition = "landings",
    source_reference = series$source_reference,
    notes = "Log-scale standard error shown in the detailed input/expected table."
  )
}

for (j in seq_along(index_names)) {
  survey <- index_names[[j]]
  years <- index_values$year[!is.na(index_values[[survey]])]
  values <- index_values[[survey]][!is.na(index_values[[survey]])]
  sds <- index_sds[[survey]][!is.na(index_sds[[survey]])]
  index_age <- if (survey == "FWRI Age-0 FIM") 0L else if (
    survey == "FWRI Age-1 FIM"
  ) 1L else NA_integer_
  inputs[[length(inputs) + 1L]] <- input_row(
    "index", "relative_abundance_index", values, "relative index (standardized)",
    "index_scale", year = years, age = index_age, survey = survey,
    source_reference = "SEDAR75_SAR.pdf, Table 8",
    notes = if (is.na(index_age)) {
      "Standardized annual relative abundance index; source scale retained."
    } else {
      paste0("Age-specific FIM abundance index for age ", index_age,
        "; source scale retained.")
    }
  )
  inputs[[length(inputs) + 1L]] <- input_row(
    "index", "log_index_sd", sds, "log scale", "log_scale",
    year = years, age = index_age, survey = survey,
    source_reference = "SEDAR75_SAR.pdf, Table 9",
    notes = "Source-reported log-scale standard error for the annual index."
  )
}

for (j in seq_len(nrow(mortality))) {
  inputs[[length(inputs) + 1L]] <- input_row(
    "M", "natural_mortality_at_age", mortality$base[[j]], "per year",
    "per_year", age = mortality$age[[j]],
    source_reference = "SEDAR75_SAR.pdf, Table 3",
    notes = "Fixed base-case M; source reports identical male and female M."
  )
}

for (fleet in c("Commercial Vertical Line", "Commercial Longline")) {
  numbers_col <- if (fleet == "Commercial Vertical Line") "vl_numbers" else "ll_numbers"
  sd_col <- if (fleet == "Commercial Vertical Line") "vl_log_sd" else "ll_log_sd"
  values <- commercial_discard[[numbers_col]]
  keep <- !is.na(values)
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", "discard_numbers", values[keep], "fish", "numbers",
    year = commercial_discard$year[keep], fleet = fleet,
    partition = "discards",
    source_reference = "SEDAR75_SAR.pdf, Table 6",
    notes = "Pre-dead-discard count in fish as tabulated; assessment text says SS input is in thousands of fish."
  )
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", "log_catch_sd", commercial_discard[[sd_col]][keep],
    "log scale", "log_scale", year = commercial_discard$year[keep],
    fleet = fleet, partition = "discards",
    source_reference = "SEDAR75_SAR.pdf, Table 6",
    notes = "Table 6 log-scale SE. The narrative also describes a fixed 0.3 SE; the difference is retained for source review."
  )
}

recreational_discard_series <- list(
  list(fleet = "Recreational Charter", value = "charter_numbers", sd = "charter_log_sd"),
  list(fleet = "Recreational Headboat", value = "headboat_numbers", sd = "headboat_log_sd"),
  list(fleet = "Recreational Private", value = "private_numbers", sd = "private_log_sd"),
  list(fleet = "Recreational Shore", value = "shore_numbers", sd = "shore_log_sd")
)
for (series in recreational_discard_series) {
  values <- recreational_discard[[series$value]]
  keep <- !is.na(values)
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", "discard_numbers", values[keep], "fish", "numbers",
    year = recreational_discard$year[keep], fleet = series$fleet,
    partition = "discards",
    source_reference = "SEDAR75_SAR.pdf, Table 7",
    notes = "Pre-dead-discard count in fish as tabulated; assessment text says SS input is in thousands of fish."
  )
  inputs[[length(inputs) + 1L]] <- input_row(
    "catch", "log_catch_sd", recreational_discard[[series$sd]][keep],
    "log scale", "log_scale", year = recreational_discard$year[keep],
    fleet = series$fleet, partition = "discards",
    source_reference = "SEDAR75_SAR.pdf, Table 7",
    notes = "Table 7 log-scale SE. The narrative also describes a fixed 0.3 SE; the difference is retained for source review."
  )
}

inputs <- do.call(rbind, inputs)

assumption <- function(component, setting, value, source_reference, notes = "") {
  pacific_database_row("assumptions", assessment_id = assessment_id,
    component = component, setting = setting, value = value,
    source_reference = source_reference, notes = notes)
}
assumptions <- do.call(rbind, list(
  assumption("assessment", "run_identity",
    "SEDAR 75 Gulf of Mexico Gray Snapper operational Stock Synthesis assessment; data through 2020; accepted for advice by the Gulf SSC in January 2023.",
    "SEDAR75_SAR.pdf, assessment description; Gulf SSC review",
    "NOAA identifies SEDAR 75 as completed in December 2022. A newer external update was scheduled for 2027, not completed at this review."),
  assumption("model", "model_version", "Stock Synthesis 3.30.19",
    "SEDAR75_SAR.pdf, Section 3.1"),
  assumption("population", "dimensions",
    "Annual single-area population model for ages 0-28; composition bins extend through 21+.",
    "SEDAR75_SAR.pdf, Sections 3.1.2-3.1.3",
    "Age compositions are shown as figures, not numeric age-frequency tables. Numeric fitted N-at-age and instantaneous F-at-age were not found."),
  assumption("population", "initial_state",
    "Population is assumed to be at equilibrium at the start of 1945.",
    "SEDAR75_SAR.pdf, Section 3.1.1",
    "The report states removals before 1945 were assumed negligible."),
  assumption("population", "seasonality",
    "One annual period; fishing and data collection are assumed relatively continuous and homogeneous through the year.",
    "SEDAR75_SAR.pdf, Sections 3.1.2-3.1.3",
    "Age-0 FIM sampling is July-December; age-1 FIM sampling is January-December. Other survey timing is not represented as a fractional sampling time in the annual table."),
  assumption("M", "natural_mortality",
    "Fixed base-case age-specific M for ages 0-28; male and female values are assumed equivalent.",
    "SEDAR75_SAR.pdf, Table 3; Section 3.1.4",
    "Upper/lower values in Table 3 are sensitivity bounds, not uncertainty intervals for the base input."),
  assumption("observation", "index_error",
    "Annual standardized indices use lognormal errors; Table 9 reports the log-scale standard errors used for the listed index series.",
    "SEDAR75_SAR.pdf, Tables 8-9; Sections 2.3.9-2.4"),
  assumption("observation", "landings_error_discrepancy",
    "Detailed Tables 14-19 show log-scale SE 0.05 for commercial landings and 0.1 for recreational landings.",
    "SEDAR75_SAR.pdf, Tables 4-5 and 14-19",
    "Table 4's caption states commercial SE 0.05 through 2009 and 0.01 for 2010-2020; Table 5's caption states recreational SE 0.20. The narrative and detailed input tables also differ. Imported SE rows follow the detailed input/expected tables; the discrepancy remains unresolved."),
  assumption("observation", "discard_error_discrepancy",
    "Tables 6-7 report variable log-scale SEs with discard observations.",
    "SEDAR75_SAR.pdf, Tables 6-7; Sections 2.3.3-2.3.4",
    "The narrative says discard log-scale SE was fixed at 0.3. The detailed table values are imported as printed and the difference remains unresolved."),
  assumption("biology", "growth_and_maturity",
    "Growth was estimated externally then one parameter was re-estimated within SS; maturity was updated using a functional-maturity logistic relationship; weight was used as a fecundity proxy.",
    "SEDAR75_SAR.pdf, Sections 2.2.2-2.2.5 and 3.1.4",
    "The report and WP-05 document biological methods, but a complete model-ready age-specific weight and maturity matrix was not available in the sources reviewed.")
))

stock <- pacific_database_row("stocks", stock_id = stock_id,
  charbonneau_id = "", authority = "NOAA Fisheries", authority_stock_id = "10221",
  scientific_name = "Lutjanus griseus",
  common_name = "Gulf of Mexico gray snapper",
  area = "Gulf of Mexico", region = "United States Gulf of Mexico",
  ocean = "Northwest Atlantic",
  notes = "NOAA Stock SMART 10221; distinct Gulf of Mexico management unit.")

assessment <- pacific_database_row("assessments", assessment_id = assessment_id,
  stock_id = stock_id, assessment_year = 2022L, terminal_year = 2020L,
  estimate_terminal_year = 2020L, assessment_type = "full_assessment",
  model_family = "Stock Synthesis", model_version = "3.30.19",
  is_current = TRUE, is_applied = TRUE, framework_year = 2018L,
  assessment_url = "https://sedarweb.org/documents/sedar-75-gulf-of-mexico-gray-snapper-final-stock-assessment-report/",
  framework_url = "https://sedarweb.org/assessments/sedar-51/",
  data_url = "https://sedarweb.org/assessments/sedar-75/",
  model_url = "", repository_url = "",
  assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste("Latest completed detailed age-structured production assessment",
    "located for the Gulf management unit. Accepted by the Gulf SSC in January",
    "2023. Input and output rows are transcribed from SEDAR 75; age-composition",
    "vectors and numeric N-at-age/F-at-age arrays were not published in the",
    "reviewed sources. See the source review for error-setting discrepancies."))

row_signature <- function(data) {
  columns <- intersect(c("assessment_id", "type", "measure", "basis", "fleet", "survey",
    "sex", "region", "season", "year", "year_basis", "age", "value", "se",
    "unit", "source_type", "source_reference", "transformation", "notes"),
    names(data))
  values <- lapply(data[columns], function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  do.call(paste, c(values, sep = "\r"))
}

read_assessment_rows <- function(path, id) {
  prefix <- paste0('"', id, '",')
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(NULL)
  if (status != 0L) stop("Could not read database rows from ", path, call. = FALSE)
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(NULL)
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

update_candidate <- function() {
  path <- file.path(root, "discovery/candidates.csv")
  candidates <- read.csv(path, stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
  i <- which(candidates$candidate_id == candidate_id)
  if (length(i) != 1L) stop("Candidate ID is not unique.", call. = FALSE)
  if (candidates$match_status[i] %in% c("new", "unresolved")) {
    candidates$matched_stock_id[i] <- stock_id
    candidates$match_status[i] <- "matched"
  } else if (!identical(candidates$matched_stock_id[i], stock_id)) {
    stop("Candidate is already matched to another stock.", call. = FALSE)
  }
  candidates$import_status[i] <- "partial"
  append_once <- function(value, text) {
    if (is.na(value)) value <- ""
    if (!grepl(text, value, fixed = TRUE)) value <- paste(value, text)
    value
  }
  candidates$catch_age_evidence[i] <- append_once(candidates$catch_age_evidence[i],
    "Source-cured: SEDAR 75 Tables 14-19 aggregate fleet landings values and log-SEs and Tables 6-7 aggregate discard values and log-SEs were imported; these tables are not catch-at-age vectors.")
  candidates$survey_age_evidence[i] <- append_once(candidates$survey_age_evidence[i],
    "Source-cured: Tables 8-9 annual values and log-SEs for seven standardized abundance indices were imported, including separate age-0 and age-1 FWRI FIM series.")
  candidates$mortality_evidence[i] <- append_once(candidates$mortality_evidence[i],
    "Source-cured: Table 3 fixed base-case M values for ages 0-28 were imported; the report gives identical male and female M.")
  candidates$output_evidence[i] <- append_once(candidates$output_evidence[i],
    "Source-cured: Table 13 total/exploited biomass, SSB, age-2+ abundance, age-0 recruitment, and SSB/B0, plus Table 35 age-2+ harvest rate, were imported for 1945-2020.")
  candidates$notes[i] <- append_once(candidates$notes[i],
    "Source import remains partial: numeric composition vectors, complete model-ready biological surfaces, and fitted N-at-age/F-at-age arrays remain unavailable. Reported catch-error and discard-unit discrepancies are documented in the source review.")
  replace_candidate_register_row(path, i, candidates[i, , drop = FALSE], candidate_id)
}

write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

if (!write_mode) {
  cat("Dry run:", nrow(inputs), "input rows;", nrow(assumptions),
    "assumptions;", nrow(outputs), "output rows for 1945-2020.\n")
  print(table(inputs$type))
} else {
  assessment_rows <- read.csv("database/assessments.csv",
    stringsAsFactors = FALSE, check.names = FALSE)
  if (!assessment_id %in% assessment_rows$assessment_id) {
    if (stock_id %in% read.csv("database/stocks.csv")$stock_id) {
      stop("Stock ID already exists without this assessment; review before importing.",
        call. = FALSE)
    }
    append_pacific_case(stock, assessment, assumptions, inputs, outputs)
  } else {
    existing_inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
    existing_outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
    if (is.null(existing_inputs) || is.null(existing_outputs) ||
        !identical(sort(row_signature(existing_inputs)), sort(row_signature(inputs))) ||
        !identical(sort(row_signature(existing_outputs)), sort(row_signature(outputs)))) {
      stop("Existing SEDAR 75 import differs from the pinned source tables.",
        call. = FALSE)
    }
  }
  update_candidate()
  cat("Imported", assessment_id, ":", nrow(inputs), "input rows and",
    nrow(outputs), "output rows; age-composition vectors remain unavailable.\n")
}
