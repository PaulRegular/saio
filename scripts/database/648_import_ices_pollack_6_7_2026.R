root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_pollack_67_2026")
register_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_32_2026.csv")
manifest_path <- file.path(root, "provenance", "ices_pollack_67_2026", "sources.csv")

dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")
stock_id <- "ices_pol_27_67"
assessment_id <- "ices_pol_27_67_2026"
candidate_id <- "ICES:pol.27.67"
report_url <- "https://ices-library.figshare.com/articles/report/Working_Group_for_the_Celtic_Seas_Ecoregion_WGCSE_/32625759"
report_file_url <- "https://ndownloader.figshare.com/files/71020092"
annex_url <- "https://doi.org/10.17895/ices.pub.24922131"
benchmark_url <- "https://doi.org/10.17895/ices.pub.28443992"
benchmark_file_url <- "https://ndownloader.figshare.com/files/53956517"
sag_xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/23709"
sag_source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23709"
sag_graph_url <- "https://standardgraphs.ices.dk/ViewCharts.aspx?key=23709"
advice_url <- "https://ices-library.figshare.com/articles/report/Working_Group_for_the_Celtic_Seas_Ecoregion_WGCSE_/32625759"

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
verified_files <- c("stock_graphs_23709.xml", "ICES_Stock_Assessment_Graphs_23709.html",
  "WGCSE_2026_pollack_divisions_6_7.pdf", "Pollack_stock_annex_2026.pdf")
if (!all(verified_files %in% manifest$file))
  stop("The provenance manifest is missing a source used by this import.", call. = FALSE)
manifest <- manifest[manifest$file %in% verified_files, , drop = FALSE]
source_paths <- file.path(cache, manifest$file)
if (!nrow(manifest) || any(!file.exists(source_paths)) ||
    any(file.info(source_paths)$size != manifest$bytes))
  stop("Cached ICES Pollack source files do not match the provenance manifest.", call. = FALSE)
actual_hashes <- vapply(source_paths, sha256_file, character(1L))
if (!identical(tolower(manifest$sha256), unname(actual_hashes)))
  stop("Cached ICES Pollack source files do not match their SHA-256 manifest.", call. = FALSE)

xml_path <- file.path(cache, "stock_graphs_23709.xml")
xml <- paste(readLines(xml_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
xml_value <- function(tag, text = xml) {
  pattern <- paste0("<", tag, ">(.*?)</", tag, ">")
  found <- regmatches(text, regexpr(pattern, text, perl = TRUE))
  if (!length(found)) return(NA_character_)
  sub(pattern, "\\1", found, perl = TRUE)
}
numeric_value <- function(text, tag) {
  value <- xml_value(tag, text)
  if (is.na(value) || !nzchar(value)) NA_real_ else as.numeric(value)
}
blocks <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
if (!length(blocks) || identical(blocks, character(0)))
  stop("No Fish_Data records were found in the ICES XML.", call. = FALSE)
fish <- data.frame(
  year = as.integer(vapply(blocks, numeric_value, numeric(1L), tag = "Year")),
  recruitment_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_Recruitment"),
  recruitment = vapply(blocks, numeric_value, numeric(1L), tag = "Recruitment"),
  recruitment_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_Recruitment"),
  ssb_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_StockSize"),
  ssb = vapply(blocks, numeric_value, numeric(1L), tag = "StockSize"),
  ssb_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_StockSize"),
  landings = vapply(blocks, numeric_value, numeric(1L), tag = "Landings"),
  fbar_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_FishingPressure"),
  fbar = vapply(blocks, numeric_value, numeric(1L), tag = "FishingPressure"),
  fbar_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_FishingPressure"),
  stringsAsFactors = FALSE
)
xml_version <- regmatches(
  paste(readLines(file.path(cache, "ICES_Stock_Assessment_Graphs_23709.html"),
    warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
  regexpr("pol\\.27\\.67_2026_23709_[0-9]+",
    paste(readLines(file.path(cache, "ICES_Stock_Assessment_Graphs_23709.html"),
      warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
)
if (length(xml_version) != 1L || !nzchar(xml_version) ||
    xml_value("StockCode") != "pol.27.67" || xml_value("AssessmentYear") != "2026" ||
    xml_value("Fage") != "3-7" || xml_value("RecruitmentAge") != "0" ||
    xml_value("ConfidenceIntervalDefinition") != "95%" ||
    !identical(fish$year, 1950:2026) || anyDuplicated(fish$year))
  stop("The ICES source does not match the verified 2026 Pollack assessment series.", call. = FALSE)

historical <- fish$year <= 2025L
if (any(!is.finite(fish$landings[historical])) ||
    any(is.finite(fish$landings[!historical])) ||
    any(!is.finite(fish$recruitment)) || any(!is.finite(fish$ssb)) ||
    any(!is.finite(fish$fbar[historical])) || any(is.finite(fish$fbar[!historical])) ||
    any(fish$recruitment_lwr > fish$recruitment | fish$recruitment > fish$recruitment_upr) ||
    any(fish$ssb_lwr > fish$ssb | fish$ssb > fish$ssb_upr) ||
    any(fish$fbar_lwr[historical] > fish$fbar[historical] |
      fish$fbar[historical] > fish$fbar_upr[historical]))
  stop("The Pollack annual estimates, coverage, or interval endpoints failed validation.", call. = FALSE)

blank_rows <- function(file, n) {
  header <- readLines(file.path(database, file), n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(columns)), stringsAsFactors = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns) out$assessment_id <- assessment_id
  out
}
number_text <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15L)

landings <- blank_rows("inputs.csv", sum(historical))
landings$type <- "catch"
landings$measure <- "landings_biomass"
landings$basis <- "biomass"
landings$fleet <- "All reported fisheries"
landings$region <- "ICES subareas 6 and 7"
landings$season <- "annual"
landings$year <- fish$year[historical]
landings$year_basis <- "calendar_year"
landings$value <- number_text(fish$landings[historical])
landings$unit <- "tonnes"
landings$source_type <- "official_machine_readable"
landings$source_reference <- paste0(sag_xml_url, "; Fish_Data/Landings")
landings$notes <- paste(
  "Aggregate annual landings reported for the pol.27.67 assessment area.",
  "WGCSE 2026 states that official landings were used before ICES landings",
  "data became available and that 1973-1977 were interpolated due to missing",
  "data. This is not catch-at-age and is not a complete SS3 input export."
)

ages <- 0:10
mortality_values <- c(0.920, 0.657, 0.534, 0.463, 0.417, 0.385, 0.361, 0.344, 0.330, 0.319, 0.311)
maturity_values <- c(0, 0, 0, 0.9, rep(1, 7))
biology_reference <- paste0(annex_url, "; Pollack Stock Annex, section 2.3")
mortality <- blank_rows("inputs.csv", length(ages))
mortality$type <- "M"
mortality$measure <- "natural_mortality_at_age"
mortality$basis <- "per_year"
mortality$age <- ages
mortality$value <- number_text(mortality_values)
mortality$unit <- "per year"
mortality$source_type <- "official_document"
mortality$source_reference <- biology_reference
mortality$notes <- paste(
  "Fixed Lorenzen natural mortality values reported as agreed at WKBSS3.",
  "The Annex does not establish that this exact vector was retained in the",
  "2026 production configuration; age 10 is the 10+ group."
)
maturity <- blank_rows("inputs.csv", length(ages))
maturity$type <- "biology"
maturity$measure <- "maturity_at_age"
maturity$basis <- "proportion"
maturity$age <- ages
maturity$value <- number_text(maturity_values)
maturity$unit <- "proportion"
maturity$source_type <- "official_document"
maturity$source_reference <- biology_reference
maturity$notes <- paste(
  "Fixed maturity values reported as agreed at WKBSS3: ages 0-2 = 0,",
  "age 3 = 0.9, ages 4+ = 1. The Annex does not establish that this exact",
  "vector was retained in the 2026 production configuration."
)
maturity$notes[ages == 10] <- paste(maturity$notes[ages == 10], "Age 10 is the 10+ group.")

projected_inputs <- blank_rows("inputs.csv", 2L)
projected_inputs$type <- "catch"
projected_inputs$measure <- c("landings_biomass", "catch_biomass")
projected_inputs$basis <- "biomass"
projected_inputs$fleet <- c("All reported fisheries", "Recreational fishery")
projected_inputs$region <- "ICES subareas 6 and 7"
projected_inputs$season <- "annual"
projected_inputs$year <- 2026L
projected_inputs$year_basis <- "calendar_year"
projected_inputs$value <- c("2317", "1561")
projected_inputs$unit <- "tonnes"
projected_inputs$source_type <- "official_document"
projected_inputs$source_reference <- paste0(report_url, "; WGCSE 2026, Table 18.7")
projected_inputs$notes <- c(
  "Projected commercial landings used for the 2026 intermediate year; the report identifies the TAC as the basis.",
  "Projected recreational removals used for the 2026 intermediate year; the report uses 2025 removals."
)
inputs <- rbind(landings, mortality, maturity, projected_inputs)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, lower = rep(NA_real_, length(value)),
                       upper = rep(NA_real_, length(value)), age = "", age_group = "",
                       scenario = "", source_reference = sag_xml_url, note) {
  out <- blank_rows("outputs.csv", length(value))
  out$type <- type
  out$measure <- measure
  out$year <- year
  out$age <- age
  out$age_group <- age_group
  out$value <- number_text(value)
  out$lwr <- ifelse(is.na(lower), "", number_text(lower))
  out$upr <- ifelse(is.na(upper), "", number_text(upper))
  out$unit <- unit
  out$source_type <- if (grepl("sag\\.ices\\.dk", source_reference)) "official_machine_readable" else "official_document"
  out$source_reference <- source_reference
  out$notes <- note
  out$scenario <- scenario
  out
}
output_rows[[1L]] <- add_output("recruitment", "recruitment", fish$recruitment,
  "thousand fish", fish$year, fish$recruitment_lwr, fish$recruitment_upr, age = "0",
  note = paste("Age-0 recruitment; ICES reports 95% interval endpoints, not SEs.",
    "The 2026 intermediate-year value and 2024-2025 recruitments are model estimates,",
    "not observed recruitments; WGCSE notes 2024-2025 are estimated from the stock-recruit relationship."))
output_rows[[2L]] <- add_output("biomass", "SSB", fish$ssb, "tonnes", fish$year,
  fish$ssb_lwr, fish$ssb_upr,
  note = "Spawning-stock biomass; ICES reports 95% interval endpoints, not SEs. 2026 is the intermediate-year estimate.")
fitted_f <- historical & is.finite(fish$fbar)
output_rows[[3L]] <- add_output("mortality", "Fbar", fish$fbar[fitted_f],
  "per year", fish$year[fitted_f], fish$fbar_lwr[fitted_f], fish$fbar_upr[fitted_f],
  age_group = "3-7",
  note = "Unweighted average F at ages 3-7; ICES reports 95% interval endpoints, not SEs.")
output_rows[[4L]] <- add_output("mortality", "Fbar", 0.29, "per year", 2026L,
  age_group = "3-7", scenario = "intermediate_year",
  source_reference = paste0(report_url, "; WGCSE 2026, Table 18.7"),
  note = "Intermediate-year F at ages 3-7 reported in WGCSE Table 18.7; no uncertainty interval reported.")
output_rows[[5L]] <- add_output("biomass", "SSB", 14534, "tonnes", 2027L,
  scenario = "short_term_forecast",
  source_reference = paste0(report_url, "; WGCSE 2026, Table 18.7"),
  note = "Short-term forecast SSB for 2027; no uncertainty interval reported.")
output_rows[[6L]] <- add_output("recruitment", "recruitment", 40624, "thousand fish", 2027L,
  age = "0", scenario = "short_term_forecast",
  source_reference = paste0(report_url, "; WGCSE 2026, Table 18.7"),
  note = "Age-0 recruitment forecast from the stock-recruit relationship; no uncertainty interval reported.")
output_rows[[7L]] <- add_output("catch", "catch_advice", 3216, "tonnes", 2027L,
  scenario = "ICES advice basis",
  source_reference = paste0(report_url, "; WGCSE 2026, Table 18.8"),
  note = "Total removals advice for 2027, including projected commercial landings and recreational removals; retained exactly as reported.")
outputs <- do.call(rbind, output_rows)

assumption_values <- data.frame(
  component = c("model", "model", "model", "model", "recruitment", "mortality",
    "uncertainty", "catch", "catch", "catch", "index", "index", "index",
    "index", "biology", "biology", "biology", "assessment"),
  setting = c("model_type", "model_version", "assessment_terminal_year",
    "estimate_terminal_year", "recruitment_age", "Fbar_age_range",
    "interval_definition", "commercial_fleet_structure", "catch_age_data",
    "recreational_removals", "survey_index_structure", "survey_index_update",
    "commercial_LPUE", "survey_timing", "life_history_source",
    "natural_mortality", "maturity", "SAG_run_version"),
  value = c(
    "Age-structured Stock Synthesis 3 assessment",
    "SS3 3.30.23.1 (Stock Annex benchmark version; exact 2026 run configuration not recovered)",
    "2025", "2026 intermediate year", "0",
    "3-7; unweighted average F",
    "95% confidence interval endpoints in ICES Standard Graphs; SEs unavailable",
    "Gillnets, lines, trawls; plus recreational dead catch",
    "Commercial age data reported from 2010; run-matched numeric age-composition vectors not recovered",
    "Available estimates from 2016; historical series interpolated from zero in 1950 to a 1990 plateau; 28.9% post-release mortality",
    "One combined sdmTMB index from 12 trawl surveys; data since 2003",
    "2026 assessment splits French CGFS into 1998-2014 and 2015-2025 series; numerical index values not recovered",
    "Irish gillnets, UK trawls, French trawls; not updated for 2024-2025",
    "Annual model; exact within-year survey timing not published",
    "WKBSS3-agreed values summarized in the Stock Annex; exact 2026 configuration not recovered",
    "Fixed Lorenzen M-at-age values reported for ages 0-10+; exact 2026 configuration not recovered",
    "Fixed maturity values reported for ages 0-2, age 3, and ages 4+; exact 2026 configuration not recovered",
    xml_version
  ),
  reference = c(
    paste0(report_url, "; WGCSE 2026, section 18.2"),
    paste0(annex_url, "; section 3.1"),
    paste0(report_url, "; WGCSE 2026, section 18.2"),
    paste0(report_url, "; WGCSE 2026, section 18.4"),
    paste0(annex_url, "; section 3.3"),
    paste0(annex_url, "; section 3.3"),
    paste0(sag_xml_url, "; ConfidenceIntervalDefinition and Fage"),
    paste0(annex_url, "; section 3.2"),
    paste0(annex_url, "; section 2.3"),
    paste0(annex_url, "; section 2.2"),
    paste0(annex_url, "; section 2.4"),
    paste0(report_url, "; WGCSE 2026, section 18.3"),
    paste0(report_url, "; WGCSE 2026, section 18.3"),
    paste0(annex_url, "; section 3.2"),
    biology_reference, biology_reference, biology_reference,
    sag_graph_url
  ),
  notes = c(
    "The current assessment is an update using the SS3 model developed at WKBSS3.",
    "Benchmark settings are not proof of the exact current run's configuration.",
    "Historical input data end in 2025.",
    "2026 is an intermediate year; it is not a fitted historical data year.",
    "The 2024 and 2025 values are estimated from the stock-recruit relationship rather than direct observations.",
    "The ICES XML Fage field is 3-7; the Stock Annex identifies the F reporting average as unweighted.",
    "Preserve source interval endpoints; do not convert them to SEs.",
    "The detailed fleet partition of current numeric catches was not recovered.",
    "The current assessment is age-structured but the numerical age-composition vectors were not published in the reviewed current sources.",
    "Recreational removals are an additional fleet and are not commercial landings.",
    "A single aggregate index does not expose the individual survey inputs or an age-specific abundance index.",
    "The French CGFS split was introduced in 2026 because the vessel changed and shallow grounds are not accessible to the newer vessel.",
    "The 2026 report states that the three commercial LPUE series were not updated for 2024 and 2025.",
    "The assessment uses one annual season; no within-year survey fraction was found.",
    "Biological values are imported as source-reported benchmark assumptions, not asserted to match the exact 2026 parameter file.",
    "The Annex's age 10 value is for age 10+.",
    "Maturity is zero at ages 0-2, 0.9 at age 3, and 1 at ages 4+.",
    "SAG run version parsed from the official chart page; this pins the output series used here."
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
existing_stock <- which(stocks_table$stock_id == stock_id |
  stocks_table$authority_stock_id == "pol.27.67" |
  (stocks_table$scientific_name == "Pollachius pollachius" &
    stocks_table$area == "ICES subareas 6 and 7"))
if (length(existing_stock) > 1L || (length(existing_stock) == 1L && !dry_run))
  stop("An ICES Pollack stock row already exists or conflicts with this unit.", call. = FALSE)
if (length(existing_stock) == 1L &&
    (stocks_table$stock_id[existing_stock] != stock_id ||
      stocks_table$authority[existing_stock] != "ICES" ||
      stocks_table$authority_stock_id[existing_stock] != "pol.27.67"))
  stop("The existing ICES Pollack row does not match the verified unit.", call. = FALSE)
stock <- blank_rows("stocks.csv", 1L)
stock$stock_id <- stock_id
stock$authority <- "ICES"
stock$authority_stock_id <- "pol.27.67"
stock$scientific_name <- "Pollachius pollachius"
stock$common_name <- "Pollack"
stock$area <- "ICES subareas 6 and 7"
stock$region <- "Celtic Seas and English Channel"
stock$ocean <- "Northeast Atlantic"
stock$notes <- paste(
  "Current ICES unit pol.27.67. The 2026 WGCSE assessment for 2027 advice",
  "uses an age-structured SS3 model. The recovered numerical records are",
  "partial; see source_reviews/ices_pollack_67_2026.md."
)

assessments_table <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
if (sum(assessments_table$assessment_id == assessment_id) > 1L ||
    (assessment_id %in% assessments_table$assessment_id && !dry_run))
  stop("The ICES 2026 Pollack assessment is already present.", call. = FALSE)
assessment <- blank_rows("assessments.csv", 1L)
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2026"
assessment$assessment_type <- "update"
assessment$model_family <- "Stock Synthesis"
assessment$model_version <- "3.30.23.1; exact 2026 build/configuration not recovered"
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2025"
assessment$assessment_url <- report_url
assessment$framework_url <- benchmark_url
assessment$data_url <- sag_xml_url
assessment$model_url <- ""
assessment$repository_url <- ""
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "2026 WGCSE assessment for 2027 advice; the official 2026 output series is pinned to ICES SAG key 23709.",
  "Aggregate landings, benchmark biological values, selected forecast values, and aggregate recruitment/SSB/F outputs were recovered.",
  "Run-matched catch-at-age, survey-index values, commercial LPUE vectors, fitted N/F-at-age, and native SS3 files were not recovered."
)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L ||
    register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "pol.27.67" ||
    register$inventory_assessment_year[candidate_row] != 2026L ||
    register$match_status[candidate_row] != "new" ||
    register$eligibility[candidate_row] != "eligible")
  stop("The selected ICES Pollack candidate does not uniquely match the verified unit.", call. = FALSE)
register$catch_age_evidence[candidate_row] <- "The current assessment uses commercial catch age data since 2010, but numerical run-matched age-composition vectors were not recovered from the reviewed public sources."
register$survey_age_evidence[candidate_row] <- "One combined sdmTMB index uses 12 surveys and is available since 2003; the current numerical index vector was not recovered and the source does not provide an age-specific survey index."
register$weights_evidence[candidate_row] <- "The Stock Annex reports length-weight parameters; numeric stock- and catch-weight-at-age series were not recovered."
register$maturity_evidence[candidate_row] <- "The Stock Annex reports fixed maturity values by age, agreed at WKBSS3; exact retention in the 2026 run configuration is unconfirmed."
register$mortality_evidence[candidate_row] <- "The Stock Annex reports fixed Lorenzen M-at-age values for ages 0-10+; exact retention in the 2026 run configuration is unconfirmed."
register$timing_evidence[candidate_row] <- "The model is annual with one 12-month season; an exact within-year fraction for the combined survey index was not recovered."
register$output_evidence[candidate_row] <- "ICES SAG key 23709 provides age-0 recruitment, SSB and Fbar ages 3-7 with 95% intervals; no N-at-age or F-at-age series was recovered."
register$import_status[candidate_row] <- "partial"
register$notes[candidate_row] <- paste(
  "Imported the official 2026 aggregate landings and output series, 2026 forecast values, 2027 advice, and Stock Annex biological inputs as benchmark-reported values.",
  "The exact current SS3 configuration and numerical age-composition, survey-index, and LPUE series remain unavailable; see source_reviews/ices_pollack_67_2026.md."
)

source(file.path(root, "scripts", "database", "candidate_register_io.R"))
inventory <- read.csv(inventory_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
inventory_row <- candidate_inventory_row(inventory, candidate_id, stock_id)
if ((!dry_run && inventory$import_status[inventory_row] != "not_started") ||
    (dry_run && !inventory$import_status[inventory_row] %in% c("not_started", "partial")))
  stop("The Pollack inventory unit has already been imported.", call. = FALSE)
inventory$import_status[inventory_row] <- "partial"

selected <- read.csv(selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L ||
    (!dry_run && selected$curation_status[selected_row] != "selected_for_source_curation") ||
    (dry_run && !selected$curation_status[selected_row] %in%
      c("selected_for_source_curation", "partial_source_import")))
  stop("The Pollack selected-batch row is missing, duplicated, or already processed.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  "Imported verified official aggregate outputs, landings and reported benchmark biology.",
  "The current run's numerical catch ages, survey index and native SS3 files remain unavailable; see the source review."
)

append_rows <- function(file, data) {
  path <- file.path(database, file)
  header <- readLines(path, n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  if (!identical(names(data), columns))
    stop("Column mismatch in ", file, call. = FALSE)
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
  cat("Validated ICES Pollack source import:", nrow(inputs), "input rows,",
    nrow(assumptions), "assumptions, and", nrow(outputs), "output rows.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("inputs.csv", inputs)
  append_rows("assumptions.csv", assumptions)
  append_rows("outputs.csv", outputs)
  replace_candidate_register_row(register_path, candidate_row,
    register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_register_row(inventory_path, inventory_row,
    inventory[inventory_row, , drop = FALSE], "unit_key",
    inventory$unit_key[inventory_row])
  replace_csv_register_row(selected_path, selected_row,
    selected[selected_row, , drop = FALSE], "priority", selected$priority[selected_row])
  cat("Imported partial ICES 2026 Pollack source data.\n")
}