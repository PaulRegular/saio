root <- "."
stock_id <- "iphc_pacific_halibut"
assessment_id <- paste0(stock_id, "_2025")
candidate_ids <- c("NOAA:11082", "DFO:Pacific:Pacific Halibut")
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached IPHC assessment table.", call. = FALSE)
}

cache_candidates <- c(
  file.path(root, "source_cache", "discovery_iphc_pacific_halibut"),
  file.path(root, "..", "..", "discovery_iphc_pacific_halibut")
)
cache <- cache_candidates[dir.exists(cache_candidates)][1L]
if (is.na(cache)) stop("The gitignored IPHC source cache is missing.", call. = FALSE)

manifest_path <- file.path(root, "provenance", "discovery_iphc_pacific_halibut", "sources.csv")
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
verify_source <- function(file) {
  path <- file.path(cache, file)
  row <- which(manifest$file == file)
  if (length(row) != 1L || !file.exists(path) ||
      tolower(unname(tools::sha256sum(path))) != tolower(manifest$sha256[row])) {
    stop("Cached IPHC source differs from its provenance record: ", file,
      call. = FALSE)
  }
  path
}

read_xlsx_sheet <- function(path) {
  temp <- tempfile("iphc_xlsx_")
  dir.create(temp)
  on.exit(unlink(temp, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = temp)
  shared_path <- file.path(temp, "xl", "sharedStrings.xml")
  sheet_path <- file.path(temp, "xl", "worksheets", "sheet1.xml")
  if (!file.exists(sheet_path)) {
    stop("Expected the first worksheet in ", basename(path), call. = FALSE)
  }
  xml_nodes <- function(text, tag) {
    matches <- gregexpr(paste0("<", tag, "\\b[^>]*>.*?</", tag, ">"),
      text, perl = TRUE)
    if (matches[[1L]][1L] < 0L) return(character())
    regmatches(text, matches)[[1L]]
  }
  inner_text <- function(node) {
    node <- gsub("<[^>]+>", "", node, perl = TRUE)
    node <- gsub("&quot;", "\"", node, fixed = TRUE)
    node <- gsub("&apos;", "'", node, fixed = TRUE)
    node <- gsub("&lt;", "<", node, fixed = TRUE)
    node <- gsub("&gt;", ">", node, fixed = TRUE)
    gsub("&amp;", "&", node, fixed = TRUE)
  }
  shared <- character()
  if (file.exists(shared_path)) {
    shared_xml <- paste(readLines(shared_path, warn = FALSE), collapse = "")
    shared_nodes <- xml_nodes(shared_xml, "si")
    shared <- vapply(shared_nodes, function(node) {
      paste(vapply(xml_nodes(node, "t"), inner_text, character(1L)), collapse = "")
    }, character(1L))
  }
  sheet_xml <- paste(readLines(sheet_path, warn = FALSE), collapse = "")
  row_nodes <- xml_nodes(sheet_xml, "row")
  cell_index <- function(reference) {
    letters <- strsplit(gsub("[0-9]", "", reference), "")[[1L]]
    sum(match(letters, LETTERS) * 26^(rev(seq_along(letters)) - 1L))
  }
  parsed <- lapply(row_nodes, function(row_node) {
    row_num <- as.integer(sub(".*\\br=\"([0-9]+)\".*", "\\1", row_node))
    cells <- xml_nodes(row_node, "c")
    lapply(cells, function(cell) {
      reference <- sub(".*\\br=\"([A-Z]+[0-9]+)\".*", "\\1", cell)
      col <- cell_index(reference)
      type <- if (grepl("\\bt=\"s\"", cell)) "s" else
        if (grepl("\\bt=\"inlineStr\"", cell)) "inlineStr" else ""
      value_node <- xml_nodes(cell, "v")
      value <- if (length(value_node)) inner_text(value_node[[1L]]) else ""
      if (type == "s" && nzchar(value)) value <- shared[[as.integer(value) + 1L]]
      if (type == "inlineStr") {
        value <- paste(vapply(xml_nodes(cell, "t"), inner_text, character(1L)),
          collapse = "")
      }
      c(row = row_num, col = col, value = value)
    })
  })
  cells <- unlist(parsed, recursive = FALSE)
  if (!length(cells)) stop("No worksheet cells were read from ", basename(path), call. = FALSE)
  cell_table <- do.call(rbind, cells)
  result <- matrix("", max(as.integer(cell_table[, "row"])),
    max(as.integer(cell_table[, "col"])))
  result[cbind(as.integer(cell_table[, "row"]),
    as.integer(cell_table[, "col"]))] <- cell_table[, "value"]
  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}

source_number <- function(x) {
  x <- trimws(as.character(x))
  x[!is.na(x) & x %in% c("", "NA", "--", "-")] <- NA_character_
  x <- sub("^\\*", "", x)
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

source_year <- function(x) as.integer(source_number(x))

read_header_table <- function(file, header_row, expected_headers) {
  raw <- read_xlsx_sheet(verify_source(file))
  header <- gsub("\\s+", " ",
    trimws(as.character(unlist(raw[header_row, ], use.names = FALSE))))
  columns <- which(nzchar(header))
  if (!identical(header[columns], expected_headers)) {
    stop(file, " table headers changed: ", paste(header[columns], collapse = " | "),
      call. = FALSE)
  }
  out <- raw[seq.int(header_row + 1L, nrow(raw)), columns, drop = FALSE]
  names(out) <- expected_headers
  out
}

fiss <- read_header_table("IPHC-2026-TSD-001.xlsx", 2L,
  c("Year", "IPHC Regulatory Area", "NPUE", "CV", "CI_2.5", "CI_97.5"))
fiss$year <- source_year(fiss$Year)
fiss$region <- trimws(fiss$`IPHC Regulatory Area`)
fiss$index <- source_number(fiss$NPUE)
fiss$cv <- source_number(fiss$CV)
fiss$lwr <- source_number(fiss$CI_2.5)
fiss$upr <- source_number(fiss$CI_97.5)
fiss <- fiss[!is.na(fiss$year), , drop = FALSE]
expected_fiss_areas <- c("2A", "2B", "2C", "3A", "3B", "4A", "4B", "4CDE", "Coastwide")
if (nrow(fiss) != 297L || !setequal(unique(fiss$region), expected_fiss_areas) ||
    any(vapply(split(fiss$year, fiss$region), function(x) {
      !identical(sort(as.integer(x)), 1993:2025)
    }, logical(1L))) || anyNA(fiss[, c("index", "cv", "lwr", "upr")])) {
  stop("TSD-001 must contain nine complete FISS NPUE series for 1993-2025.",
    call. = FALSE)
}

landings <- read_header_table("IPHC-2026-TSD-007.xlsx", 3L,
  c("Year", "2A", "2B", "2C", "3A", "3B", "4", "4A", "4B", "4CDE", "Total"))
landings$year <- source_year(landings$Year)
landings <- landings[!is.na(landings$year), , drop = FALSE]
if (!identical(sort(unique(landings$year)), 1888:2025)) {
  stop("TSD-007 landings coverage changed.", call. = FALSE)
}

mortality <- read_header_table("IPHC-2026-TSD-009.xlsx", 2L,
  c("Year", "Commercial landings(includes FISS)",
    "Directed commercial discard mortality", "Recreational", "Subsistence",
    "Non-directed commercial discard mortality", "Total"))
mortality$year <- source_year(mortality$Year)
mortality <- mortality[!is.na(mortality$year), , drop = FALSE]
if (!identical(sort(unique(mortality$year)), 1888:2025)) {
  stop("TSD-009 mortality-by-source coverage changed.", call. = FALSE)
}

commercial_wpue <- read_header_table("IPHC-2026-TSD-010.xlsx", 2L,
  c("Year", "2A", "2B", "2C", "3A", "3B", "4A", "4B", "4C", "4D", "4E", "Coastwide"))
commercial_wpue$year <- source_year(commercial_wpue$Year)
commercial_wpue <- commercial_wpue[!is.na(commercial_wpue$year), , drop = FALSE]
if (min(commercial_wpue$year) != 1907L || max(commercial_wpue$year) != 2025L ||
    !any(commercial_wpue$Coastwide[commercial_wpue$year == 2025L] == "49.9")) {
  stop("TSD-010 commercial WPUE coverage or 2025 coastwide value changed.",
    call. = FALSE)
}

ssb <- read_xlsx_sheet(verify_source("IPHC-2026-TSD-029.xlsx"))
ssb_header <- trimws(as.character(unlist(ssb[4L, 1:13], use.names = FALSE)))
expected_ssb_header <- c("Year", rep(c("SB", "SB_lowCI", "SB_highCI"), 4L))
if (!identical(ssb_header, expected_ssb_header)) {
  stop("TSD-029 spawning biomass headers changed.", call. = FALSE)
}
ssb <- ssb[seq.int(5L, nrow(ssb)), 1:13, drop = FALSE]
names(ssb) <- c("Year", "value_cw_long", "lwr_cw_long", "upr_cw_long",
  "value_aaf_long", "lwr_aaf_long", "upr_aaf_long",
  "value_cw_short", "lwr_cw_short", "upr_cw_short",
  "value_aaf_short", "lwr_aaf_short", "upr_aaf_short")
ssb$year <- source_year(ssb$Year)
ssb <- ssb[!is.na(ssb$year), , drop = FALSE]
ssb_models <- list(
  "Coastwide long" = c("value_cw_long", "lwr_cw_long", "upr_cw_long"),
  "AAF long" = c("value_aaf_long", "lwr_aaf_long", "upr_aaf_long"),
  "Coastwide short" = c("value_cw_short", "lwr_cw_short", "upr_cw_short"),
  "AAF short" = c("value_aaf_short", "lwr_aaf_short", "upr_aaf_short")
)
if (!identical(sort(ssb$year), 1888:2026)) {
  stop("TSD-029 spawning biomass year coverage changed.", call. = FALSE)
}
for (model in names(ssb_models)) {
  columns <- ssb_models[[model]]
  fitted_years <- ssb$year[!is.na(source_number(ssb[[columns[1L]]]))]
  expected_years <- if (grepl("short", model, fixed = TRUE)) 1992:2026 else 1888:2026
  if (!identical(sort(as.integer(fitted_years)), expected_years)) {
    stop("TSD-029 year coverage changed for ", model, ".", call. = FALSE)
  }
}

assessment_path <- verify_source("IPHC-2026-SA-01.pdf")
assessment_pages <- pdftools::pdf_text(assessment_path)
if (length(assessment_pages) != 38L) stop("The IPHC 2025 assessment page count changed.", call. = FALSE)
table1_lines <- strsplit(assessment_pages[[16L]], "\n", fixed = TRUE)[[1L]]
table1_lines <- table1_lines[grepl("^\\s*(199[2-9]|20[0-2][0-9])\\s+",
  table1_lines, perl = TRUE)]
parse_interval <- function(x, year, label) {
  if (x == "NA") return(c(NA_real_, NA_real_))
  ends <- strsplit(gsub("%", "", x, fixed = TRUE), "-", fixed = TRUE)[[1L]]
  values <- source_number(ends)
  if (length(values) != 2L || anyNA(values)) {
    stop("Table 1 has an unexpected ", label, " interval for ", year, ".", call. = FALSE)
  }
  values
}
parse_table1_row <- function(line) {
  fields <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
  if (length(fields) != 13L) {
    stop("IPHC Table 1 row has unexpected columns: ", trimws(line), call. = FALSE)
  }
  values <- source_number(fields[c(1L, 2L, 6:13)])
  values <- c(values[1:2], source_number(gsub("%", "", fields[4L], fixed = TRUE)),
    values[3:10])
  ssb_interval <- parse_interval(fields[3L], fields[1L], "SSB")
  intensity_interval <- parse_interval(fields[5L], fields[1L], "fishing-intensity")
  c(year = values[1L], ssb = values[2L], ssb_lwr = ssb_interval[1L],
    ssb_upr = ssb_interval[2L], intensity = values[3L],
    intensity_lwr = intensity_interval[1L], intensity_upr = intensity_interval[2L],
    recruitment_cw_long = values[4L], recruitment_cw_short = values[5L],
    recruitment_aaf_long = values[6L], recruitment_aaf_short = values[7L],
    biomass8_cw_long = values[8L], biomass8_cw_short = values[9L],
    biomass8_aaf_long = values[10L], biomass8_aaf_short = values[11L])
}
table1 <- as.data.frame(do.call(rbind, lapply(table1_lines, parse_table1_row)),
  stringsAsFactors = FALSE)
table1[] <- lapply(table1, as.numeric)
if (!identical(as.integer(table1$year), 1992:2026) ||
    sum(!is.na(table1$intensity)) != 34L ||
    any(!is.na(table1$recruitment_cw_long[table1$year > 2020])) ||
    table1$ssb[table1$year == 2026L] != 166 ||
    table1$ssb_lwr[table1$year == 2026L] != 113 ||
    table1$ssb_upr[table1$year == 2026L] != 272) {
  stop("IPHC Table 1 coverage or reported values changed.", call. = FALSE)
}

input_rows <- list()
add_input <- function(type, measure, basis, value, unit, year, fleet = "",
    survey = "", region = "", source_reference, transformation = "", notes = "") {
  input_rows[[length(input_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = fleet, survey = survey, sex = "", region = region, season = "",
    year = as.integer(year), year_basis = "calendar_year", age = NA_integer_,
    value = as.numeric(value), unit = unit, sampling_time = NA_real_,
    source_type = "official_machine_readable", source_reference = source_reference,
    transformation = transformation, notes = notes, observation_id = "",
    length_bin = NA_real_, length_bin_lower = NA_real_, length_bin_upper = NA_real_,
    sample_size = NA_real_, age_error = "", partition = "", weight_bin = "",
    stringsAsFactors = FALSE)
}

for (i in seq_len(nrow(fiss))) {
  note <- paste(
    "Published modelled FISS numbers-per-unit-effort series. IPHC-2026-SA-02",
    "states the 2025 assessment models fit directly to modelled FISS NPUE.",
    "The TSD reports area-specific and Coastwide series as alternative spatial",
    "representations across the assessment ensemble; they are not independent",
    "indices to sum together. TSD-001 was last revised on 6 November 2025, after",
    "the assessment's 31 October data cutoff; exact run-specific values were not",
    "available for row-by-row confirmation.",
    if (fiss$year[i] == 2025L) "2025 is the assessment-cutoff year." else "")
  add_input("index", "relative_abundance_index", "index_scale", fiss$index[i],
    "fish per skate", fiss$year[i], survey = "IPHC FISS modelled NPUE",
    region = fiss$region[i], source_reference = "IPHC-2026-TSD-001, rows 3-299",
    notes = paste(note, "Published 95% interval:", fiss$lwr[i], "to", fiss$upr[i],
      "fish per skate."))
  add_input("index", "abundance_index_cv", "relative_scale", fiss$cv[i] / 100,
    "ratio", fiss$year[i], survey = "IPHC FISS modelled NPUE",
    region = fiss$region[i], source_reference = "IPHC-2026-TSD-001, rows 3-299",
    transformation = "Source CV percent divided by 100 to store a ratio.",
    notes = paste("Source-reported CV:", fiss$cv[i], "percent. Source-reported",
      "95% interval on the index scale:", fiss$lwr[i], "to", fiss$upr[i],
      "fish per skate."))
}

landings_areas <- c("2A", "2B", "2C", "3A", "3B", "4", "4A", "4B", "4CDE")
for (area in landings_areas) {
  values <- source_number(landings[[area]])
  for (i in which(!is.na(values))) {
    preliminary <- landings$year[i] == 2025L
    add_input("catch", "landings_biomass", "biomass", values[i], "t",
      landings$year[i], fleet = "IPHC directed commercial fishery",
      region = area, source_reference = "IPHC-2026-TSD-007, rows 4-142",
      transformation = "Source workbook converted net pounds to tonnes (net lb × 0.000453592) and rounded to whole tonnes.",
      notes = paste("Directed commercial landings by the source's IPHC Regulatory Area.",
        "The area 4/4A/4B/4CDE labels are retained as reported across the historical",
        "area definitions; the Total column is not duplicated here.",
        if (preliminary) "2025 is marked preliminary in the source." else ""))
  }
}

mortality_sources <- c(
  "Directed commercial discard mortality" = "Directed commercial discards",
  "Recreational" = "Recreational fisheries",
  "Subsistence" = "Subsistence fisheries",
  "Non-directed commercial discard mortality" = "Non-directed commercial discards"
)
for (column in names(mortality_sources)) {
  values <- source_number(mortality[[column]])
  for (i in which(!is.na(values))) {
    preliminary <- mortality$year[i] == 2025L
    add_input("catch", "catch_biomass", "biomass", values[i], "t",
      mortality$year[i], fleet = mortality_sources[[column]],
      source_reference = "IPHC-2026-TSD-009, rows 3-140",
      transformation = "Source workbook converted net pounds to tonnes (net lb × 0.000453592) and rounded to whole tonnes.",
      notes = paste("Source-specific annual mortality; commercial landings and",
        "the Total column are omitted here because directed landings are stored",
        "by area from TSD-007 and the totals are not independent components.",
        if (preliminary) "2025 is preliminary; the assessment report says mortality for fisheries operating after 31 October was projected." else ""))
  }
}

commercial_areas <- c("2A", "2B", "2C", "3A", "3B", "4A", "4B", "4C", "4D", "4E", "Coastwide")
for (area in commercial_areas) {
  values <- source_number(commercial_wpue[[area]])
  for (i in which(!is.na(values))) {
    add_input("index", "relative_biomass_index", "index_scale", values[i],
      "kg per skate", commercial_wpue$year[i],
      fleet = "IPHC directed commercial fishery", region = area,
      source_reference = "IPHC-2026-TSD-010, rows 3-119",
      transformation = "Source workbook converted net pounds to kilograms per skate (net lb × 0.453592), rounded to one decimal place.",
      notes = paste("Published commercial fishery WPUE series. The source report",
        "identifies commercial catch-rates as an assessment data source but does",
        "not provide a run-matched likelihood file or CV in this table.",
        if (commercial_wpue$year[i] == 2025L) "2025 is incomplete/preliminary at the 31 October data cutoff." else ""))
  }
}
input_rows <- do.call(rbind, input_rows)

output_rows <- list()
add_output <- function(type, measure, year, value, unit, source_reference,
    scenario = "", sex = "", age = NA_integer_, age_group = "",
    lwr = NA_real_, upr = NA_real_, notes = "") {
  output_rows[[length(output_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, type = type, measure = measure, fleet = "",
    survey = "", sex = sex, region = "", season = "", year = as.integer(year),
    age = as.integer(age), age_group = age_group, value = as.numeric(value),
    se = NA_real_, lwr = as.numeric(lwr), upr = as.numeric(upr), unit = unit,
    source_type = if (grepl("TSD-029", source_reference, fixed = TRUE)) {
      "official_machine_readable"
    } else "official_table",
    source_reference = source_reference, notes = notes, scenario = scenario,
    stringsAsFactors = FALSE)
}

for (model in names(ssb_models)) {
  columns <- ssb_models[[model]]
  value <- source_number(ssb[[columns[1L]]])
  lwr <- source_number(ssb[[columns[2L]]])
  upr <- source_number(ssb[[columns[3L]]])
  for (i in which(!is.na(value))) {
    add_output("biomass", "SSB", ssb$year[i], value[i], "t",
      "IPHC-2026-TSD-029, rows 5-143", scenario = model, sex = "Female",
      lwr = lwr[i], upr = upr[i],
      notes = paste("Model-specific female spawning biomass. TSD-029 values are",
        "rounded tonnes converted from net pounds; the report identifies the",
        "model time series as maximum-likelihood estimates and the shaded ranges",
        "as approximate 95% credible intervals. No SE was reported."))
  }
}

for (i in seq_len(nrow(table1))) {
  row <- table1[i, ]
  add_output("biomass", "SSB", row$year, row$ssb, "million lb",
    "IPHC-2026-SA-01, Table 1, pp. 16-17", scenario = "Ensemble median",
    sex = "Female", lwr = row$ssb_lwr, upr = row$ssb_upr,
    notes = "Ensemble median female spawning biomass; source interval is approximate 95% credibility interval. The assessment reports this annual biomass at the start of each year.")
  if (!is.na(row$intensity)) {
    add_output("management", "fishing_intensity_Fxx_percent", row$year,
      row$intensity, "%", "IPHC-2026-SA-01, Table 1, pp. 16-17",
      scenario = "Ensemble", lwr = row$intensity_lwr, upr = row$intensity_upr,
      notes = "Source Fxx% is SPR-based fishing intensity; smaller percentages indicate greater fishing intensity. It is not instantaneous F or F-at-age. Approximate 95% credibility interval.")
  }
  recruitment_models <- c("Coastwide long", "Coastwide short", "AAF long", "AAF short")
  recruitment_columns <- c("recruitment_cw_long", "recruitment_cw_short",
    "recruitment_aaf_long", "recruitment_aaf_short")
  for (j in seq_along(recruitment_models)) {
    value <- row[[recruitment_columns[j]]]
    if (!is.na(value)) {
      add_output("recruitment", "recruitment", row$year, value,
        "million fish", "IPHC-2026-SA-01, Table 1, pp. 16-17",
        scenario = recruitment_models[j], age = 0L,
        notes = "Model-specific age-0 recruitment; Table 1 reports values through 2020 and no uncertainty interval.")
    }
  }
  biomass_columns <- c("biomass8_cw_long", "biomass8_cw_short",
    "biomass8_aaf_long", "biomass8_aaf_short")
  for (j in seq_along(recruitment_models)) {
    value <- row[[biomass_columns[j]]]
    if (!is.na(value)) {
      add_output("biomass", "biomass_by_age_group", row$year, value,
        "million lb", "IPHC-2026-SA-01, Table 1, pp. 16-17",
        scenario = recruitment_models[j], age_group = "8+",
        notes = "Model-specific age-8+ biomass; Table 1 does not identify a sex-specific biomass for this column and reports no uncertainty interval.")
    }
  }
}
output_rows <- do.call(rbind, output_rows)

assumption_rows <- list()
add_assumption <- function(component, setting, value, source_reference,
    sex = "", notes = "") {
  assumption_rows[[length(assumption_rows) + 1L]] <<- data.frame(
    assessment_id = assessment_id, component = component, fleet = "", survey = "",
    sex = sex, region = "", season = "", setting = setting, value = value,
    source_reference = source_reference, notes = notes,
    stringsAsFactors = FALSE)
}

add_assumption("model", "software_and_version", "Stock Synthesis 3.30.23.1",
  "IPHC-2026-SA-01, pp. 1-2")
add_assumption("model", "assessment_ensemble",
  "Four equally weighted models: Coastwide long, AAF long, Coastwide short, AAF short",
  "IPHC-2026-SA-01, p. 8",
  notes = "The long models reconstruct history from 1888; short models use 1992 onward. AAF means Areas-As-Fleets and fits spatial datasets separately while retaining one aggregate stock.")
add_assumption("model", "data_cutoff", "31 October 2025",
  "IPHC-2026-SA-01, p. 5",
  notes = "Some 2025 commercial WPUE and age-composition inputs were incomplete at the cutoff; mortality for fisheries operating after the cutoff was projected.")
add_assumption("population", "stock_structure", "One aggregate IPHC Convention Area stock",
  "IPHC-2026-SA-01, pp. 4-8",
  notes = "The AAF models fit spatial datasets separately; their areas are not separate population stocks.")
add_assumption("mortality", "female_natural_mortality",
  "Estimated in three models; fixed at 0.15 per year in the Coastwide short model",
  "IPHC-2026-SA-01, p. 8", sex = "Female")
add_assumption("mortality", "male_natural_mortality",
  "Estimated in all four models",
  "IPHC-2026-SA-01, p. 8", sex = "Male")
add_assumption("index", "FISS_NPUE", "Modelled FISS NPUE is fitted directly in the assessment",
  "IPHC-2026-SA-02, pp. 2-3",
  notes = "The modelled series covers 1993-2025, is estimated by IPHC Regulatory Area, and includes NOAA/ADF&G trawl survey data for parts of Regulatory Areas 4A and 4CDE.")
add_assumption("biology", "maturity", "2025 assessment uses an updated histology-based maturity ogive",
  "IPHC-2026-SA-01, p. 2",
  notes = "The exact run-specific maturity-at-age values were not publicly available in the cached data sources.")
add_assumption("biology", "weight_at_age_sources",
  "FISS, commercial fishery, and NOAA Bering Sea trawl data; model input surfaces are smoothed",
  "IPHC-2026-SA-02, pp. 13-20",
  notes = "Public reports describe construction but do not provide a run-matched complete numeric input surface by age, year, sex, and area.")
add_assumption("composition", "age_data_availability",
  "Commercial ages are sampled in proportion to landings; 2025 age data were incomplete at the assessment cutoff",
  "IPHC-2026-SA-01, pp. 5-7; IPHC-2026-SA-02, pp. 39-42",
  notes = "The public TSD-031 workbook was revised in June 2026, after this assessment run, and is not treated as an exact 2025 model input.")
add_assumption("mortality", "annual_mortality_components",
  "Directed commercial landings and discards, recreational, subsistence, and non-directed commercial discard mortality",
  "IPHC-2026-SA-02, pp. 22-31",
  notes = "The source tables contain both area-based landings and source-based mortality. Redundant totals were not imported as independent catch components.")
add_assumption("assessment", "run_specific_input_files",
  "Exact native Stock Synthesis input files not retrieved",
  "IPHC stock assessment webpage",
  notes = "The IPHC page states that raw assessment inputs require permission from the Secretariat. No request was sent; the import uses public assessment tables and marks source completeness partial.")
assumption_rows <- do.call(rbind, assumption_rows)

stock <- data.frame(
  stock_id = stock_id, charbonneau_id = "", authority = "IPHC",
  authority_stock_id = "IPHC Convention Area",
  scientific_name = "Hippoglossus stenolepis", common_name = "Pacific halibut",
  area = "IPHC Convention Area", region = "California to northern Bering Sea",
  ocean = "Northeast Pacific",
  notes = paste("One aggregate transboundary IPHC Convention Area assessment stock.",
    "The unit extends from California to the northern Bering Sea and includes",
    "Canadian and U.S. waters. Discovery records NOAA:11082 and DFO:Pacific:Pacific",
    "Halibut are aliases for this IPHC assessment unit; neither is treated as a",
    "separate stock."),
  stringsAsFactors = FALSE)

assessment <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2025L, estimate_terminal_year = 2026L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "Stock Synthesis 3.30.23.1; four-model ensemble",
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = "https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-01.pdf",
  framework_url = "",
  data_url = "https://www.iphc.int/uploads/2025/12/IPHC-2026-SA-02.pdf",
  model_url = "https://www.iphc.int/research/stock-assessment/",
  repository_url = "", assumptions_status = "partial", inputs_status = "partial",
  outputs_status = "partial",
  notes = paste("Latest completed official production assessment as of 9 November",
    "2026. Data cutoff was 31 October 2025; the four component models are equally",
    "weighted. Reported model outputs extend to the beginning of 2026. Public",
    "tables are not a substitute for the unavailable permission-restricted native",
    "input files; see the source review for series and run-matching limits."),
  stringsAsFactors = FALSE)

for (name in c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
  path <- file.path("database", name)
  expected <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  rows <- switch(name, "stocks.csv" = stock, "assessments.csv" = assessment,
    "assumptions.csv" = assumption_rows, "inputs.csv" = input_rows,
    "outputs.csv" = output_rows)
  if (!identical(names(rows), expected)) stop("Column order differs for ", name, ".", call. = FALSE)
}

cat("IPHC Pacific halibut 2025 source import preview\n")
cat("  Inputs:", nrow(input_rows), "rows\n")
cat("  Assumptions:", nrow(assumption_rows), "rows\n")
cat("  Outputs:", nrow(output_rows), "rows\n")
cat("  FISS NPUE:", nrow(fiss), "area/coastwide series rows; 1993-2025\n")
  cat("  TSD-029 SSB:", sum(!is.na(source_number(ssb[["value_cw_long"]]))),
    "Coastwide long rows; model-specific trajectories\n")

if (!write_mode) {
  cat("Dry run only. Add --write to import the verified source rows.\n")
} else {
  read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE,
    colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
  stream_has_id <- function(path, id) {
    con <- file(path, open = "r")
    on.exit(close(con))
    prefix <- paste0('"', id, '",')
    repeat {
      chunk <- readLines(con, n = 100000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, prefix))) return(TRUE)
    }
  }
  append_csv <- function(path, x) write.table(x, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "", qmethod = "double")
  replace_register_row <- function(path, key, id, values) {
    x <- read_csv(path)
    hit <- which(x[[key]] == id)
    if (length(hit) != 1L) stop("Expected one register row for ", id, ".", call. = FALSE)
    for (name in names(values)) if (name %in% names(x)) x[[name]][hit] <- values[[name]]
    write.csv(x, path, row.names = FALSE, na = "")
  }
  register_env <- new.env(parent = globalenv())
  source(file.path(root, "scripts", "database", "candidate_register_io.R"),
    local = register_env)

  existing_stocks <- read_csv("database/stocks.csv")
  existing_assessments <- read_csv("database/assessments.csv")
  if (stock_id %in% existing_stocks$stock_id || assessment_id %in% existing_assessments$assessment_id ||
      any(vapply(c("database/inputs.csv", "database/assumptions.csv", "database/outputs.csv"),
        stream_has_id, logical(1L), id = assessment_id))) {
    stop("IPHC Pacific halibut rows already exist in the canonical database.", call. = FALSE)
  }
  candidates <- read_csv("discovery/candidates.csv")
  selected <- read_csv("discovery/selected_unworked_2026.csv")
  inventory <- read_csv("discovery/inventory_units.csv")
  candidate_rows <- match(candidate_ids, candidates$candidate_id)
  selected_row <- which(selected$candidate_id == "NOAA:11082")
  inventory_row <- which(inventory$candidate_unit_id == stock_id)
  if (anyNA(candidate_rows) || length(selected_row) != 1L || length(inventory_row) != 1L) {
    stop("IPHC discovery records are not in the expected pre-import state; reconcile before writing.",
      call. = FALSE)
  }
  registered_candidate_ids <- strsplit(inventory$candidate_ids[inventory_row],
    " | ", fixed = TRUE)[[1L]]
  if (!setequal(registered_candidate_ids, sort(candidate_ids)) ||
      any(candidates$import_status[candidate_rows] != "not_started") ||
      selected$curation_status[selected_row] != "selected_for_source_curation" ||
      inventory$import_status[inventory_row] != "not_started" ||
      inventory$match_status[inventory_row] != "new" ||
      (stock_id %in% existing_stocks$stock_id)) {
    stop("IPHC discovery records are not in the expected pre-import state; reconcile before writing.",
      call. = FALSE)
  }
  for (name in c("stocks.csv", "assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
    if (stream_has_id(file.path("database", name), assessment_id)) {
      stop("IPHC assessment identifier already occurs in ", name, ".", call. = FALSE)
    }
  }

  append_csv("database/stocks.csv", stock)
  append_csv("database/assessments.csv", assessment)
  append_csv("database/assumptions.csv", assumption_rows)
  append_csv("database/inputs.csv", input_rows)
  append_csv("database/outputs.csv", output_rows)

  candidates <- read_csv("discovery/candidates.csv")
  for (candidate_row in candidate_rows) {
    candidate <- candidates[candidate_row, , drop = FALSE]
    candidate$matched_stock_id <- stock_id
    candidate$match_status <- "matched"
    candidate$import_status <- "partial"
    if ("latest_assessment_year" %in% names(candidate)) candidate$latest_assessment_year <- "2025"
    if ("catch_age_evidence" %in% names(candidate)) candidate$catch_age_evidence <- paste(
      "Area-specific directed commercial landings and source-specific mortality",
      "components are imported from TSD-007/TSD-009. The exact fitted catch-at-age",
      "numbers and age-composition likelihood inputs are not public/run-matched.")
    if ("survey_age_evidence" %in% names(candidate)) candidate$survey_age_evidence <- paste(
      "Modelled FISS NPUE values and CVs by area and Coastwide are imported from",
      "TSD-001 for 1993-2025. Public age sample summaries are post-run or do not",
      "provide the exact 2025 model likelihood vectors.")
    if ("weights_evidence" %in% names(candidate)) candidate$weights_evidence <- paste(
      "Reports describe FISS, commercial, and NOAA Bering Sea trawl weight-at-age",
      "inputs, but the complete run-specific numeric age/year/sex/area surfaces",
      "were not retrieved.")
    if ("maturity_evidence" %in% names(candidate)) candidate$maturity_evidence <- paste(
      "The 2025 model uses an updated histology-based maturity ogive; exact",
      "run-specific numeric maturity-at-age values were not publicly available.")
    if ("mortality_evidence" %in% names(candidate)) candidate$mortality_evidence <- paste(
      "Female natural mortality is estimated in three models and fixed at 0.15",
      "per year in the Coastwide short model; male natural mortality is estimated",
      "in all four models. Exact male and estimated female M surfaces are not tabulated.")
    if ("timing_evidence" %in% names(candidate)) candidate$timing_evidence <- paste(
      "The public annual series do not provide run-specific within-year timing for",
      "FISS or fishery observations; no sampling_time was inferred.")
    if ("output_evidence" %in% names(candidate)) candidate$output_evidence <- paste(
      "Imported four model-specific SSB series from TSD-029, ensemble SSB and",
      "SPR-based fishing-intensity summaries, age-0 recruitment, and age-8+",
      "biomass from Table 1. Numerical N-at-age, F-at-age, and M-at-age outputs",
      "were not found in the public reports.")
    if ("notes" %in% names(candidate)) candidate$notes <- paste(
      "NOAA:11082 and DFO:Pacific:Pacific Halibut map to one IPHC Convention Area",
      "assessment stock. Imported public time series are partial and do not replace",
      "the exact permission-restricted native assessment files. See the source review.")
    register_env$replace_candidate_register_row("discovery/candidates.csv",
      candidate_row, candidate, candidate$candidate_id)
  }
  replace_register_row("discovery/selected_unworked_2026.csv", "candidate_id", "NOAA:11082",
    list(curation_status = "source_curated_partial",
      selection_basis = paste("The 2025 IPHC production assessment, with a 31 October",
        "2025 data cutoff, remains the latest completed run. Imported public",
        "catch/mortality, FISS NPUE, commercial WPUE,",
        "model-specific SSB, ensemble SSB, fishing-intensity, recruitment and age-8+",
        "biomass tables. Exact model input files, catch/age likelihood vectors, full",
        "age-specific biology and numerical N/F/M-at-age outputs remain unavailable.")))
  replace_register_row("discovery/inventory_units.csv", "candidate_unit_id", stock_id,
    list(unit_key = paste0("stock:", stock_id), matched_stock_id = stock_id,
      match_status = "matched", import_status = "partial"))

  source(file.path(root, "scripts", "database", "195_summarize_discovery.R"),
    local = new.env(parent = globalenv()))
  source(file.path(root, "scripts", "database", "196_summarize_inventory_units.R"),
    local = new.env(parent = globalenv()))
  cat("Imported partial IPHC Pacific halibut 2025 source data.\n")
}
