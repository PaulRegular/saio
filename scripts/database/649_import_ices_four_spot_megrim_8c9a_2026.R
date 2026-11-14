root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_four_spot_megrim_8c9a_2026")
manifest_path <- file.path(root, "provenance", "ices_four_spot_megrim_8c9a_2026", "sources.csv")
register_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_33_2026.csv")

dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")
stock_id <- "ices_four_spot_megrim_8c9a"
assessment_id <- paste0(stock_id, "_2026")
candidate_id <- "ICES:ldb.27.8c9a"
report_url <- "https://doi.org/10.17895/ices.pub.32790321.v2"
annex_url <- "https://doi.org/10.17895/ices.pub.23261030.v2"
sag_xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/26018"
sag_page_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26018"

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- tolower(sub("[[:space:]].*$", "", result))
  } else {
    stop("A SHA-256 utility is required to verify the ICES source cache.", call. = FALSE)
  }
  if (length(hashes) != 1L || !grepl("^[[:xdigit:]]{64}$", hashes))
    stop("Could not calculate SHA-256 for ", basename(path), call. = FALSE)
  hashes
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
source_files <- c(
  "WGBIE_2026_four_spot_megrim_8c9a.pdf",
  "WGBIE_2026_four_spot_megrim_8c9a.txt",
  "Four_spot_megrim_stock_annex_2026.pdf",
  "Four_spot_megrim_stock_annex_2026.txt",
  "stock_graphs_26018.xml",
  "ICES_Stock_Assessment_Graphs_26018.html"
)
if (!all(source_files %in% manifest$file))
  stop("The provenance manifest is missing a source used by this import.", call. = FALSE)
manifest <- manifest[match(source_files, manifest$file), , drop = FALSE]
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) ||
    any(file.info(source_paths)$size != manifest$bytes))
  stop("Cached four-spot megrim sources do not match the provenance manifest sizes.", call. = FALSE)
actual_hashes <- vapply(source_paths, sha256_file, character(1L))
if (!identical(tolower(manifest$sha256), unname(actual_hashes)))
  stop("Cached four-spot megrim sources do not match the provenance manifest checksums.", call. = FALSE)

report_text <- paste(readLines(file.path(cache, source_files[2]), warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")
annex_text <- paste(readLines(file.path(cache, source_files[4]), warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")
if (!grepl("Natural mortality is set to 0\\.2", annex_text, ignore.case = TRUE) ||
    !grepl("0\\s+0\\.05\\s+0\\.32\\s+0\\.83\\s+0\\.98\\s+1", annex_text))
  stop("The cached Stock Annex does not verify the imported M and maturity values.", call. = FALSE)

tokenize <- function(x) {
  positions <- gregexpr("\\S+", x, perl = TRUE)[[1L]]
  if (identical(positions, -1L)) return(list(values = character(), positions = integer()))
  list(values = regmatches(x, list(positions))[[1L]], positions = as.integer(positions))
}
year_tokens <- function(x) {
  tokens <- tokenize(x)$values
  years <- sub("\\*$", "", tokens[grepl("^(19|20)[0-9]{2}\\*?$", tokens)])
  as.integer(years)
}

report_lines <- strsplit(report_text, "\\n")[[1L]]
age_title <- grep("Table\\.? 6\\.4\\.2b\\..*Discards in numbers-at-age", report_lines)
if (length(age_title) != 1L)
  stop("Could not uniquely locate the Spanish discard-at-age table.", call. = FALSE)
expected_block_starts <- c(1986L, 1999L, 2012L, 2025L)
header_indices <- which(vapply(report_lines, function(line) {
  years <- year_tokens(line)
  length(years) > 0L && years[1L] %in% expected_block_starts
}, logical(1L)))
age_table_end <- grep("Table\\.? 6\\.4\\.3", report_lines)
age_table_end <- age_table_end[age_table_end > age_title][1L]
header_indices <- header_indices[header_indices > age_title & header_indices < age_table_end]
if (length(header_indices) != length(expected_block_starts) ||
    !identical(unname(vapply(header_indices, function(i) year_tokens(report_lines[i])[1L], integer(1L))),
      expected_block_starts))
  stop("Could not identify the four year blocks in Table 6.4.2b.", call. = FALSE)

age_rows <- list()
for (block in seq_along(header_indices)) {
  header_index <- header_indices[block]
  years <- year_tokens(report_lines[header_index])
  block_end <- if (block < length(header_indices)) header_indices[block + 1L] - 1L else length(report_lines)
  parsed_rows <- list()
  for (i in seq.int(header_index + 1L, block_end)) {
    parts <- tokenize(report_lines[i])
    if (length(parts$values) < 2L || !grepl("^[0-7]$", parts$values[1L])) next
    values <- suppressWarnings(as.numeric(gsub(",", "", parts$values[-1L], fixed = TRUE)))
    if (!length(values) || any(!is.finite(values))) next
    parsed_rows[[length(parsed_rows) + 1L]] <- list(
      age = as.integer(parts$values[1L]), values = values,
      positions = parts$positions[-1L]
    )
  }
  parsed_rows <- parsed_rows[!duplicated(vapply(parsed_rows, `[[`, integer(1L), "age"))]
  if (length(parsed_rows) != 8L || !identical(sort(vapply(parsed_rows, `[[`, integer(1L), "age")), 0:7))
    stop("Table 6.4.2b did not yield one row for each reported age 0-7.", call. = FALSE)
  for (row in parsed_rows) {
    if (length(row$values) > length(years))
      stop("An age row has more values than the year header in Table 6.4.2b.", call. = FALSE)
    columns <- seq_along(row$values)
    if (length(row$values) < length(years)) {
      gaps <- diff(row$positions)
      pitch <- median(gaps)
      steps <- pmax(1L, as.integer(round(gaps / pitch)))
      columns <- c(1L, 1L + cumsum(steps))
      if (anyDuplicated(columns) || any(columns > length(years)))
        stop("Could not align missing cells in Table 6.4.2b.", call. = FALSE)
    }
    values <- rep(NA_real_, length(years))
    values[columns] <- row$values
    age_rows[[length(age_rows) + 1L]] <- data.frame(
      year = years, age = row$age, value = values, stringsAsFactors = FALSE
    )
  }
}
discard_at_age <- do.call(rbind, age_rows)
discard_at_age <- discard_at_age[order(discard_at_age$year, discard_at_age$age), , drop = FALSE]
if (nrow(discard_at_age) != 320L || !identical(sort(unique(discard_at_age$year)), 1986:2025) ||
    !identical(sort(unique(discard_at_age$age)), 0:7) || sum(is.na(discard_at_age$value)) != 5L)
  stop("Spanish discard-at-age coverage or blank-cell alignment failed validation.", call. = FALSE)

summary_title <- grep("Table\\.? 6\\.4\\.5\\..*Summary of catches", report_lines)
if (length(summary_title) != 1L)
  stop("Could not uniquely locate the annual catch and a4a summary table.", call. = FALSE)
summary_rows <- list()
for (i in seq.int(summary_title + 1L, length(report_lines))) {
  line <- report_lines[i]
  match <- regexec("^\\s*((19|20)[0-9]{2})\\*?\\s+(.*)$", line, perl = TRUE)
  fields <- regmatches(line, match)[[1L]]
  if (!length(fields)) next
  year <- as.integer(fields[2L])
  if (year < 1986L || year > 2026L) next
  values <- strsplit(trimws(fields[4L]), "\\s+")[[1L]]
  if (length(values) != 11L)
    stop("An annual row in Table 6.4.5 does not have the expected 11 fields.", call. = FALSE)
  numeric_values <- suppressWarnings(as.numeric(values))
  summary_rows[[length(summary_rows) + 1L]] <- data.frame(
    year = year, landings = numeric_values[1L], discards = numeric_values[2L],
    catch = numeric_values[3L], catch_estimate = numeric_values[4L],
    total_biomass = numeric_values[5L], ssb = numeric_values[6L],
    ssb_cv = numeric_values[7L], recruitment = numeric_values[8L],
    recruitment_cv = numeric_values[9L], fbar = numeric_values[10L],
    fbar_cv = numeric_values[11L], stringsAsFactors = FALSE
  )
}
summary <- do.call(rbind, summary_rows)
summary <- summary[summary$year >= 1986L & summary$year <= 2025L, , drop = FALSE]
summary <- summary[order(summary$year), , drop = FALSE]
if (!identical(as.integer(summary$year), 1986:2025) ||
    summary$landings[summary$year == 2025L] != 689 ||
    summary$discards[summary$year == 2025L] != 36 ||
    summary$catch[summary$year == 2025L] != 725)
  stop("Table 6.4.5 catch values or historical coverage failed validation.", call. = FALSE)

xml <- paste(readLines(file.path(cache, "stock_graphs_26018.xml"), warn = FALSE, encoding = "UTF-8"),
  collapse = "\n")
xml_value <- function(tag, text = xml) {
  pattern <- paste0("<", tag, ">(.*?)</", tag, ">")
  match <- regmatches(text, regexpr(pattern, text, perl = TRUE))
  if (!length(match)) return(NA_character_)
  trimws(sub(pattern, "\\1", match, perl = TRUE))
}
numeric_value <- function(text, tag) {
  value <- xml_value(tag, text)
  if (is.na(value) || !nzchar(value)) NA_real_ else as.numeric(value)
}
blocks <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
fish <- data.frame(
  year = as.integer(vapply(blocks, numeric_value, numeric(1L), tag = "Year")),
  recruitment_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_Recruitment"),
  recruitment = vapply(blocks, numeric_value, numeric(1L), tag = "Recruitment"),
  recruitment_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_Recruitment"),
  ssb_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_StockSize"),
  ssb = vapply(blocks, numeric_value, numeric(1L), tag = "StockSize"),
  ssb_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_StockSize"),
  total_biomass = vapply(blocks, numeric_value, numeric(1L), tag = "TBiomass"),
  fbar_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_FishingPressure"),
  fbar = vapply(blocks, numeric_value, numeric(1L), tag = "FishingPressure"),
  fbar_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_FishingPressure"),
  stringsAsFactors = FALSE
)
graph_html <- paste(readLines(file.path(cache, "ICES_Stock_Assessment_Graphs_26018.html"),
  warn = FALSE, encoding = "UTF-8"), collapse = "\n")
xml_version <- regmatches(graph_html,
  regexpr("ldb\\.27\\.8c9a_2026_26018_[0-9]+", graph_html))
historical <- fish[fish$year >= 1986L & fish$year <= 2025L, , drop = FALSE]
if (!length(blocks) || xml_value("StockCode") != "ldb.27.8c9a" ||
    xml_value("AssessmentYear") != "2026" || xml_value("Fage") != "2-4" ||
    xml_value("RecruitmentAge") != "0" || xml_value("ConfidenceIntervalDefinition") != "90%" ||
    length(xml_version) != 1L || !nzchar(xml_version) ||
    !identical(as.integer(historical$year), 1986:2025) ||
    any(!is.finite(historical$recruitment)) || any(!is.finite(historical$ssb)) ||
    any(!is.finite(historical$total_biomass)) || any(!is.finite(historical$fbar)) ||
    any(historical$recruitment_lwr > historical$recruitment |
      historical$recruitment > historical$recruitment_upr) ||
    any(historical$ssb_lwr > historical$ssb | historical$ssb > historical$ssb_upr) ||
    any(historical$fbar_lwr > historical$fbar | historical$fbar > historical$fbar_upr))
  stop("The ICES SAG identity, interval scale, values, or historical coverage failed validation.", call. = FALSE)
if (max(abs(summary$total_biomass - historical$total_biomass)) > 0.011 ||
    max(abs(summary$ssb - historical$ssb)) > 0.51 ||
    max(abs(summary$recruitment - historical$recruitment)) > 0.011 ||
    max(abs(summary$fbar - historical$fbar)) > 0.00051)
  stop("The WGBIE summary outputs do not agree with the pinned SAG series at reported precision.", call. = FALSE)

blank_rows <- function(file, n) {
  header <- readLines(file.path(database, file), n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(columns)), stringsAsFactors = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns) out$assessment_id <- assessment_id
  out
}
number_text <- function(x) {
  out <- rep("", length(x))
  ok <- !is.na(x)
  out[ok] <- format(x[ok], scientific = FALSE, trim = TRUE, digits = 15L)
  out
}

make_catch_input <- function(measure, values, notes) {
  out <- blank_rows("inputs.csv", length(values))
  out$type <- "catch"
  out$measure <- measure
  out$basis <- "biomass"
  out$region <- "ICES divisions 8.c and 9.a"
  out$season <- "annual"
  out$year <- summary$year
  out$year_basis <- "calendar_year"
  out$value <- number_text(values)
  out$unit <- "tonnes"
  out$source_type <- "official_document"
  out$source_reference <- paste0(report_url, "; WGBIE 2026, section 6.4, Table 6.4.5")
  out$notes <- notes
  out
}
catch_inputs <- rbind(
  make_catch_input("landings_biomass", summary$landings,
    "Reported annual landings in the stock summary; source totals are not fleet-disaggregated here."),
  make_catch_input("discard_biomass", summary$discards,
    "Reported annual discards in the stock summary; source totals are not fleet-disaggregated here."),
  make_catch_input("catch_biomass", summary$catch,
    "Reported total catch in the stock summary; landings and discards are components of the same fishery, not independent fleets.")
)

discard_input <- blank_rows("inputs.csv", nrow(discard_at_age))
discard_input$type <- "catch"
discard_input$measure <- "discard_numbers_at_age"
discard_input$basis <- "numbers"
discard_input$fleet <- "Spanish trawlers"
discard_input$region <- "ICES divisions 8.c and 9.a"
discard_input$season <- "annual"
discard_input$year <- discard_at_age$year
discard_input$year_basis <- "calendar_year"
discard_input$age <- discard_at_age$age
discard_input$value <- number_text(discard_at_age$value)
discard_input$unit <- "thousand fish"
discard_input$source_type <- "official_document"
discard_input$source_reference <- paste0(report_url, "; WGBIE 2026, section 6.4, Table 6.4.2b")
discard_input$notes <- paste(
  "Spanish trawler discard numbers at age as printed. Source-table blanks are retained as missing, not zero.",
  "The report table labels age classes 0-7, while the Stock Annex describes assessment ages 0-6+; the terminal-bin crosswalk is unresolved."
)

ages_m <- 0:6
mortality <- blank_rows("inputs.csv", length(ages_m))
mortality$type <- "M"
mortality$measure <- "natural_mortality_at_age"
mortality$basis <- "per_year"
mortality$age <- ages_m
mortality$value <- "0.2"
mortality$unit <- "per year"
mortality$source_type <- "official_document"
mortality$source_reference <- paste0(annex_url, "; 2026 Stock Annex, section 2.2.3")
mortality$notes <- "Natural mortality fixed at 0.2 for all ages and years; age 6 is the Annex's 6+ group."

maturity_ages <- 0:5
maturity <- blank_rows("inputs.csv", length(maturity_ages))
maturity$type <- "biology"
maturity$measure <- "maturity_at_age"
maturity$basis <- "proportion"
maturity$sex <- "female"
maturity$age <- maturity_ages
maturity$value <- number_text(c(0, 0.05, 0.32, 0.83, 0.98, 1))
maturity$unit <- "proportion"
maturity$source_type <- "official_document"
maturity$source_reference <- paste0(annex_url, "; 2026 Stock Annex, section 2.2.4")
maturity$notes <- "Female maturity-at-age values are fixed over time; age 5 is the 5+ group."

inputs <- rbind(catch_inputs, discard_input, mortality, maturity)

add_output <- function(type, measure, value, year, unit, lower = rep(NA_real_, length(value)),
                       upper = rep(NA_real_, length(value)), age = "", age_group = "",
                       scenario = "", source_reference, note) {
  out <- blank_rows("outputs.csv", length(value))
  out$type <- type
  out$measure <- measure
  out$year <- year
  out$age <- age
  out$age_group <- age_group
  out$value <- number_text(value)
  out$lwr <- number_text(lower)
  out$upr <- number_text(upper)
  out$unit <- unit
  out$source_type <- if (grepl("sag\\.ices\\.dk", source_reference))
    "official_machine_readable" else "official_document"
  out$source_reference <- source_reference
  out$notes <- note
  out$scenario <- scenario
  out
}

historical_note <- "Historical assessment estimate through 2025. ICES Standard Graphs defines the reported lower and upper bounds as a 90% confidence interval; standard errors are not provided."
output_rows <- list(
  add_output("recruitment", "recruitment", historical$recruitment, historical$year,
    "thousand fish", historical$recruitment_lwr, historical$recruitment_upr, age = "0",
    source_reference = paste0(sag_xml_url, "; Fish_Data/Recruitment, Low_Recruitment, High_Recruitment"),
    note = paste("Age-0 recruitment.", historical_note)),
  add_output("biomass", "SSB", historical$ssb, historical$year,
    "tonnes", historical$ssb_lwr, historical$ssb_upr,
    source_reference = paste0(sag_xml_url, "; Fish_Data/StockSize, Low_StockSize, High_StockSize"),
    note = paste("Spawning-stock biomass.", historical_note)),
  add_output("biomass", "total_biomass", historical$total_biomass, historical$year,
    "tonnes", source_reference = paste0(sag_xml_url, "; Fish_Data/TBiomass"),
    note = "Total stock biomass as reported in ICES Standard Graphs; no interval is provided."),
  add_output("mortality", "Fbar", historical$fbar, historical$year,
    "per year", historical$fbar_lwr, historical$fbar_upr, age_group = "2-4",
    source_reference = paste0(sag_xml_url, "; Fish_Data/FishingPressure, Low_FishingPressure, High_FishingPressure"),
    note = paste("Fbar for ages 2-4.", historical_note)),
  add_output("catch", "expected_catch_biomass", summary$catch_estimate, summary$year,
    "tonnes", source_reference = paste0(report_url, "; WGBIE 2026, section 6.4, Table 6.4.5, Cat Est"),
    note = "Assessment-estimated catch; separate from the reported catch input series."),
  add_output("mortality", "Fbar", 0.058, 2026L, "per year", age_group = "2-4",
    scenario = "intermediate_year", source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Intermediate-year Fbar for ages 2-4; no uncertainty interval reported."),
  add_output("biomass", "SSB", 17466, 2027L, "tonnes", scenario = "short_term_forecast",
    source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Short-term forecast spawning-stock biomass; no uncertainty interval reported."),
  add_output("recruitment", "recruitment", c(21243, 21243), c(2026L, 2027L),
    "thousand fish", age = "1", scenario = "short_term_forecast",
    source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Forecast recruitment at age 1 for 2026 and 2027; no uncertainty interval reported."),
  add_output("catch", "expected_catch_biomass", 819, 2026L, "tonnes",
    scenario = "short_term_forecast", source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Total catch short-term forecast; no uncertainty interval reported."),
  add_output("catch", "expected_landings_biomass", 761, 2026L, "tonnes",
    scenario = "short_term_forecast", source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Projected landings; no uncertainty interval reported."),
  add_output("catch", "expected_discard_biomass", 58, 2026L, "tonnes",
    scenario = "short_term_forecast", source_reference = paste0(report_url, "; WGBIE 2026, Table 6.4.6"),
    note = "Projected discards; no uncertainty interval reported.")
)
outputs <- do.call(rbind, output_rows)

assumption_values <- data.frame(
  component = c("model", "model", "assessment", "assessment", "assessment", "catch",
    "survey", "survey", "survey", "biology", "M", "biology", "recruitment", "mortality", "uncertainty"),
  setting = c("model_type", "software", "historical_period", "intermediate_year",
    "terminal_age_group", "catch_at_age_data", "survey_index_structure", "survey_exclusions",
    "survey_timing", "weight_at_age", "natural_mortality", "maturity_at_age",
    "recruitment_age", "Fbar_age_range", "interval_definition"),
  value = c(
    "Age-structured a4a statistical catch-at-age assessment",
    "Fla4a 1.8.2 in R 4.1.2",
    "1986-2025 historical assessment years",
    "2026 intermediate year; 2027 short-term forecast",
    "Stock Annex describes ages 0-6+; Table 6.4.2b labels discard data ages 0-7",
    "The numeric Spanish trawler discard numbers-at-age are available in Table 6.4.2b; complete fleet catch-at-age arrays were not recovered",
    "The production assessment uses age-specific Spanish SpGFS-WIBTS-Q4 (G2784) and Portuguese crustacean (G2913) indices; numeric run-matched age-index matrices were not recovered",
    "The report excludes the Spanish 2003 index due to contradiction and the 2013 abundance value due to a vessel/calibration issue; the Portuguese crustacean series ends in 2018 and 2021-2022 are excluded",
    "Both fitted surveys are fourth-quarter surveys; exact within-year fractions are not reported",
    "Catch weights-at-age are also used as stock weights-at-age; numerical age/year series are not tabulated",
    "Fixed M = 0.2 for all ages and years",
    "Female maturity at ages 0, 1, 2, 3, 4, and 5+ is 0, 0.05, 0.32, 0.83, 0.98, and 1",
    "Historical recruitment is age 0; forecast recruitment is reported at age 1",
    "Fbar is reported for ages 2-4; averaging weights are not specified in the retrieved output source",
    "ICES Standard Graphs reports 90% confidence interval endpoints for recruitment, SSB, and Fbar; table CV values are not stored as standard errors"
  ),
  reference = c(
    paste0(report_url, "; WGBIE 2026, section 6.4"),
    paste0(report_url, "; WGBIE 2026, section 6.4"),
    paste0(report_url, "; WGBIE 2026, section 6.4"),
    paste0(report_url, "; WGBIE 2026, Tables 6.4.5-6.4.6"),
    paste0(annex_url, "; Stock Annex, section 3.1; WGBIE 2026, Table 6.4.2b"),
    paste0(report_url, "; WGBIE 2026, Tables 6.4.1-6.4.2b"),
    paste0(annex_url, "; Stock Annex, section 2.4"),
    paste0(report_url, "; WGBIE 2026, section 6.4.2.3"),
    paste0(annex_url, "; Stock Annex, section 2.4"),
    paste0(report_url, "; WGBIE 2026, section 6.4.2.2"),
    paste0(annex_url, "; Stock Annex, section 2.2.3"),
    paste0(annex_url, "; Stock Annex, section 2.2.4"),
    paste0(sag_xml_url, "; RecruitmentAge; WGBIE 2026, Table 6.4.6"),
    paste0(sag_xml_url, "; Fage; WGBIE 2026, section 6.4.3"),
    paste0(sag_xml_url, "; ConfidenceIntervalDefinition")
  ),
  notes = c(
    "Current 2026 WGBIE assessment for 2027 advice.",
    "The report identifies Fla4a 1.8.2 and R 4.1.2.",
    "The assessment data series ends in 2025.",
    "2026 is not a historical data year.",
    "The source-table and Annex age-bin descriptions are not silently reconciled.",
    "The imported Spanish discard series is partial and does not represent all catches at age.",
    "This does not provide the age-specific numeric observation matrices used by the model.",
    "Omitted or excluded observations are not reconstructed from figures.",
    "Q4 timing is known; the fractional year is unresolved.",
    "Catch-weight numeric values were not recovered.",
    "Fixed across ages and years.",
    "The age 5 category is 5+.",
    "Do not relabel age-1 forecast recruitment as age 0.",
    "Fbar intervals are retained on the source scale; no SE is derived.",
    "The interval definition is 90%, not 95%; annual CV values in Table 6.4.5 remain distinct."
  ),
  stringsAsFactors = FALSE
)
assumptions <- blank_rows("assumptions.csv", nrow(assumption_values))
assumptions$component <- assumption_values$component
assumptions$setting <- assumption_values$setting
assumptions$value <- assumption_values$value
assumptions$source_reference <- assumption_values$reference
assumptions$notes <- assumption_values$notes

stocks_table <- read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments_table <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock_matches <- which(stocks_table$stock_id == stock_id |
  tolower(stocks_table$authority_stock_id) == "ldb.27.8c9a")
assessment_matches <- which(assessments_table$assessment_id == assessment_id)
if (length(stock_matches) > 1L || length(assessment_matches) > 1L ||
    (length(stock_matches) > 0L && length(assessment_matches) == 0L) ||
    (length(stock_matches) == 0L && length(assessment_matches) > 0L) ||
    (!dry_run && length(stock_matches) > 0L))
  stop("A canonical four-spot megrim stock or assessment record already exists.", call. = FALSE)
if (length(stock_matches) == 1L && length(assessment_matches) == 1L &&
    (stocks_table$stock_id[stock_matches] != stock_id ||
      assessments_table$stock_id[assessment_matches] != stock_id))
  stop("The existing four-spot megrim records conflict with the selected stock identity.", call. = FALSE)

stock <- blank_rows("stocks.csv", 1L)
stock$stock_id <- stock_id
stock$authority <- "ICES"
stock$authority_stock_id <- "ldb.27.8c9a"
stock$scientific_name <- "Lepidorhombus boscii"
stock$common_name <- "Four-spot megrim"
stock$area <- "ICES divisions 8.c and 9.a"
stock$region <- "Southern Bay of Biscay and Atlantic Iberian waters East"
stock$ocean <- "Northeast Atlantic"
stock$notes <- "Current ICES unit ldb.27.8c9a. The partial 2026 a4a source import preserves Spanish discard numbers-at-age and aggregate outputs; see source_reviews/ices_four_spot_megrim_8c9a_2026.md."

assessment <- blank_rows("assessments.csv", 1L)
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2026"
assessment$assessment_type <- "update"
assessment$model_family <- "a4a"
assessment$model_version <- "Fla4a 1.8.2; R 4.1.2"
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$assessment_url <- report_url
assessment$framework_url <- annex_url
assessment$data_url <- sag_xml_url
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "2026 WGBIE assessment for 2027 advice; final detailed report version 2 was published in November 2026.",
  "Imported Spanish-trawler discard numbers-at-age, aggregate catch totals, fixed biological inputs, historical total biomass/recruitment/SSB/Fbar outputs, and short-term forecast values.",
  "Full fleet catch-at-age and age-specific survey-index matrices, numerical weights-at-age, and N/F-at-age outputs remain unavailable."
)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L || register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "ldb.27.8c9a" ||
    register$eligibility[candidate_row] != "eligible" ||
    !register$import_status[candidate_row] %in% c("not_started", "partial"))
  stop("The four-spot megrim candidate does not uniquely match the selected import.", call. = FALSE)
register$catch_age_evidence[candidate_row] <- paste(
  "WGBIE 2026 Table 6.4.2b provides Spanish trawler discard numbers-at-age (thousands), reported ages 0-7, in 1986-2025.",
  "Aggregate landings, discards and catch are available in Table 6.4.5; full fleet catch-at-age remains unavailable."
)
register$survey_age_evidence[candidate_row] <- paste(
  "The assessment uses age-specific Spanish G2784 and Portuguese crustacean G2913 indices, but run-matched numeric age-index matrices were not recovered.",
  "Exact within-year timing is not reported."
)
register$output_evidence[candidate_row] <- paste(
  "ICES SAG key 26018 provides historical age-0 recruitment, SSB, total biomass and Fbar ages 2-4 through 2025.",
  "Recruitment, SSB and Fbar have reported 90% interval endpoints; N-at-age and F-at-age were not recovered."
)
register$import_status[candidate_row] <- "partial"
register$review_date[candidate_row] <- "2026-11-12"
register$notes[candidate_row] <- paste(
  "Partial source import completed from the version-2 WGBIE 2026 report, 2026 Stock Annex and ICES SAG key 26018.",
  "The report's discard table age labels 0-7 differ from the Annex's 0-6+ model bins; source blanks are retained as missing.",
  "See source_reviews/ices_four_spot_megrim_8c9a_2026.md."
)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if (!inventory$import_status[inventory_row] %in% c("not_started", "partial"))
  stop("The four-spot megrim inventory unit has an unexpected import status.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"

selected <- read.csv(selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L ||
    !selected$curation_status[selected_row] %in% c("selected_for_source_curation", "partial_source_import") ||
    !selected$candidate_unit_id[selected_row] %in% c(stock_id, "ices_ldb_27_8c9a"))
  stop("The four-spot megrim selected-batch row is missing or conflicts with the candidate register.", call. = FALSE)
selected$candidate_unit_id[selected_row] <- stock_id
selected$detailed_source_url[selected_row] <- paste(
  report_url, annex_url, "https://asd.ices.dk/viewAdvice/7266", sag_page_url, sag_xml_url,
  sep = "; "
)
selected$selection_basis[selected_row] <- paste(
  "Partial source import completed from verified current-run sources. The report table supplies Spanish discard numbers-at-age and aggregate catches; SAG provides aggregate outputs with 90% intervals.",
  "Full catch-at-age and survey age-index matrices remain unavailable."
)
selected$curation_status[selected_row] <- "partial_source_import"

append_rows <- function(file, data) {
  path <- file.path(database, file)
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  if (!identical(names(data), columns)) stop("Column mismatch in ", file, call. = FALSE)
  if (file.info(path)$size > 0L) {
    con <- file(path, open = "rb")
    seek(con, where = -1L, origin = "end")
    last <- readBin(con, "raw", n = 1L)
    close(con)
    if (!identical(last, as.raw(10L))) cat("\n", file = path, append = TRUE)
  }
  write.table(data, file = path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", append = TRUE, qmethod = "double", eol = "\n")
}
if (dry_run) {
  cat("Validated ICES four-spot megrim source import:", nrow(inputs), "input rows,",
    nrow(assumptions), "assumptions, and", nrow(outputs), "output rows.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("inputs.csv", inputs)
  append_rows("assumptions.csv", assumptions)
  append_rows("outputs.csv", outputs)
  replace_candidate_register_row(
    register_path, candidate_row, register[candidate_row, , drop = FALSE], candidate_id
  )
  replace_csv_register_row(
    inventory_path, inventory_row, inventory[inventory_row, , drop = FALSE],
    "unit_key", inventory$unit_key[inventory_row]
  )
  replace_csv_register_row(
    selected_path, selected_row, selected[selected_row, , drop = FALSE],
    "candidate_id", candidate_id
  )
  cat("Imported partial ICES four-spot megrim ldb.27.8c9a source data.\n")
}
