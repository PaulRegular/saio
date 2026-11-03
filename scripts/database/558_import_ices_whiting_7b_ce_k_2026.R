root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "ices_whiting_7b_ce_k_2026")
register_path <- file.path(root, "discovery", "candidates.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")
dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")

stock_id <- "ices_whg_27_7b_ce_k"
assessment_id <- "ices_whg_27_7b_ce_k_2026"
candidate_id <- "ICES:whg.27.7b-ce-k"
report_url <- "https://doi.org/10.17895/ices.pub.32625759.v1"
annex_url <- "https://doi.org/10.17895/ices.pub.23501757.v2"
source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23780"
xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/23780"
report_text_path <- file.path(cache, "wgcse_2026_whiting_7bc_ek.txt")
annex_text_path <- file.path(cache, "whg_27_7b_ce_k_stock_annex_v2.txt")
xml_path <- file.path(cache, "stock_graphs_23780.xml")

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("certutil.exe"))) {
    result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    hashes <- tolower(trimws(grep("^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE)))
  } else if (nzchar(Sys.which("sha256sum"))) {
    result <- system2("sha256sum", shQuote(path), stdout = TRUE)
    hashes <- tolower(sub("[[:space:]].*$", "", result))
  } else stop("A SHA-256 utility is required to verify the ICES source cache.", call. = FALSE)
  if (length(hashes) != 1L || !grepl("^[[:xdigit:]]{64}$", hashes))
    stop("Could not calculate SHA-256 for ", basename(path), call. = FALSE)
  hashes
}
manifest <- read.csv(file.path(cache, "sources.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size != manifest$bytes))
  stop("Cached ICES source files do not match their manifest sizes.", call. = FALSE)
actual_hashes <- vapply(source_paths, sha256_file, character(1L))
if (!identical(tolower(manifest$sha256), unname(actual_hashes)))
  stop("Cached ICES source files do not match their SHA-256 manifest.", call. = FALSE)

report_text <- readLines(report_text_path, warn = FALSE, encoding = "UTF-8")
annex_text <- paste(readLines(annex_text_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
xml <- paste(readLines(xml_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
if (!grepl("State-Space Assessment Model", annex_text, ignore.case = TRUE) ||
    !grepl("Landings fraction", annex_text, ignore.case = TRUE) || !grepl("corFlag", annex_text, fixed = TRUE))
  stop("The cached ICES Stock Annex is missing expected method and input descriptions.", call. = FALSE)

parse_age_table <- function(id, ages, expected_years) {
  title <- paste0("^\\s*Table ", gsub("\\.", "\\\\.", id), "\\.")
  start <- grep(title, report_text, perl = TRUE)[1L]
  if (is.na(start)) stop("Missing WGCSE table ", id, call. = FALSE)
  next_table <- grep("^\\s*Table 27\\.", report_text, perl = TRUE)
  next_table <- next_table[next_table > start]
  stop_at <- if (length(next_table)) min(next_table) else length(report_text) + 1L
  lines <- report_text[seq.int(start + 1L, stop_at - 1L)]
  data_lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  values <- lapply(data_lines, function(line) {
    token <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    suppressWarnings(as.numeric(token))
  })
  if (!length(values) || any(lengths(values) != length(ages) + 1L))
    stop("Unexpected year/age layout in WGCSE table ", id, call. = FALSE)
  years <- vapply(values, function(z) z[[1L]], numeric(1L))
  matrix_values <- do.call(rbind, lapply(values, function(z) z[-1L]))
  if (!identical(as.integer(years), as.integer(expected_years)) ||
      any(!is.finite(matrix_values)) || any(matrix_values < 0))
    stop("Unexpected year coverage or values in WGCSE table ", id, call. = FALSE)
  list(year = as.integer(years), age = ages, value = matrix_values)
}
parse_scalar_table <- function(id, expected_years) {
  title <- paste0("^\\s*Table ", gsub("\\.", "\\\\.", id), "\\.")
  start <- grep(title, report_text, perl = TRUE)[1L]
  if (is.na(start)) stop("Missing WGCSE table ", id, call. = FALSE)
  next_table <- grep("^\\s*Table 27\\.", report_text, perl = TRUE)
  next_table <- next_table[next_table > start]
  stop_at <- if (length(next_table)) min(next_table) else length(report_text) + 1L
  lines <- report_text[seq.int(start + 1L, stop_at - 1L)]
  data_lines <- lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)]
  values <- lapply(data_lines, function(line) {
    token <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    suppressWarnings(as.numeric(token))
  })
  if (!length(values) || any(lengths(values) != 2L))
    stop("Unexpected year/value layout in WGCSE table ", id, call. = FALSE)
  years <- vapply(values, function(z) z[[1L]], numeric(1L))
  index <- vapply(values, function(z) z[[2L]], numeric(1L))
  if (!identical(as.integer(years), as.integer(expected_years)) ||
      any(!is.finite(index)) || any(index < 0))
    stop("Unexpected year coverage or values in WGCSE table ", id, call. = FALSE)
  data.frame(year = as.integer(years), value = index)
}
parse_age_vector <- function(label) {
  lines <- grep(paste0("^\\s*", label, "\\s+"), report_text, value = TRUE, perl = TRUE)
  values <- lapply(lines, function(line) {
    token <- strsplit(trimws(line), "\\s+", perl = TRUE)[[1L]]
    suppressWarnings(as.numeric(token[-seq_len(length(strsplit(label, "\\s+", perl = TRUE)[[1L]]))]))
  })
  valid <- vapply(values, function(x) length(x) == 8L && all(is.finite(x)), logical(1L))
  if (sum(valid) != 1L) stop("Could not identify one WGCSE ", label, " vector.", call. = FALSE)
  values[[which(valid)]]
}
report_years <- 1999:2025
ages <- 0:7
catch_numbers <- parse_age_table("27.3", ages, report_years)
catch_weights_source <- parse_age_table("27.4", ages, report_years)
stock_weights_summary <- parse_age_table("27.5", ages, report_years)
stock_weights <- parse_age_table("27.7", ages, report_years)
survey_index <- parse_age_table("27.8", 0:2, 2003:2025)
f_at_age <- parse_age_table("27.10", ages, report_years)
n_at_age <- parse_age_table("27.11", ages, report_years)
commercial_index <- parse_scalar_table("27.9", 2000:2025)
if (!isTRUE(all.equal(stock_weights_summary$value, stock_weights$value, tolerance = 0)))
  stop("WGCSE Tables 27.5 and 27.7 disagree; do not choose a stock-weight series silently.", call. = FALSE)
natural_mortality <- parse_age_vector("Natural mortality")
maturity <- parse_age_vector("Proportion mature")
if (!isTRUE(all.equal(natural_mortality, c(1.22, 0.86, 0.65, 0.50, 0.43, 0.40, 0.38, 0.36))) ||
    !isTRUE(all.equal(maturity, c(0, 0.61, 0.94, 0.97, 0.97, 1, 1, 1))))
  stop("The 2026 WGCSE M or maturity vector differs from the reviewed source.", call. = FALSE)

xml_value <- function(tag, text = xml) {
  pattern <- paste0("<", tag, ">(.*?)</", tag, ">")
  found <- regmatches(text, regexpr(pattern, text, perl = TRUE))
  if (!length(found)) return(NA_character_)
  sub(pattern, "\\1", found, perl = TRUE)
}
numeric_value <- function(tag, text) {
  value <- xml_value(tag, text)
  if (is.na(value) || !nzchar(value)) NA_real_ else as.numeric(value)
}
blocks <- regmatches(xml, gregexpr("(?s)<Fish_Data>.*?</Fish_Data>", xml, perl = TRUE))[[1L]]
if (!length(blocks) || identical(blocks, character(0)))
  stop("No Fish_Data records were found in the ICES XML.", call. = FALSE)
fish <- data.frame(
  year = vapply(blocks, numeric_value, numeric(1L), tag = "Year"),
  recruitment_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_Recruitment"),
  recruitment = vapply(blocks, numeric_value, numeric(1L), tag = "Recruitment"),
  recruitment_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_Recruitment"),
  ssb_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_StockSize"),
  ssb = vapply(blocks, numeric_value, numeric(1L), tag = "StockSize"),
  ssb_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_StockSize"),
  catch = vapply(blocks, numeric_value, numeric(1L), tag = "Catches"),
  landings = vapply(blocks, numeric_value, numeric(1L), tag = "Landings"),
  discards = vapply(blocks, numeric_value, numeric(1L), tag = "Discards"),
  fbar_lwr = vapply(blocks, numeric_value, numeric(1L), tag = "Low_FishingPressure"),
  fbar = vapply(blocks, numeric_value, numeric(1L), tag = "FishingPressure"),
  fbar_upr = vapply(blocks, numeric_value, numeric(1L), tag = "High_FishingPressure"),
  stringsAsFactors = FALSE
)
fish$year <- as.integer(fish$year)
historical <- fish$year <= 2025L
if (xml_value("StockCode") != "whg.27.7b-ce-k" || xml_value("AssessmentYear") != "2026" ||
    xml_value("RecruitmentAge") != "0" || xml_value("StockSizeDescription") != "SSB" ||
    xml_value("ConfidenceIntervalDefinition") != "95%" ||
    !identical(fish$year, 1999:2026) || anyDuplicated(fish$year))
  stop("ICES Standard Graphs key 23780 does not match the expected 2026 whiting assessment.", call. = FALSE)
if (any(!is.finite(fish$recruitment)) || any(!is.finite(fish$ssb)) ||
    any(!is.finite(fish$recruitment_lwr)) || any(!is.finite(fish$recruitment_upr)) ||
    any(!is.finite(fish$ssb_lwr)) || any(!is.finite(fish$ssb_upr)) ||
    any(!is.finite(fish$fbar[historical])) || any(is.finite(fish$fbar[!historical])) ||
    any(fish$recruitment_lwr > fish$recruitment | fish$recruitment > fish$recruitment_upr) ||
    any(fish$ssb_lwr > fish$ssb | fish$ssb > fish$ssb_upr) ||
    any(fish$fbar_lwr[historical] > fish$fbar[historical] | fish$fbar[historical] > fish$fbar_upr[historical]))
  stop("ICES annual estimates or 95% interval endpoints failed validation.", call. = FALSE)
if (any(is.finite(fish$catch)) || !identical(fish$year[historical & is.finite(fish$landings)], 1999:2025) ||
    !identical(fish$year[historical & is.finite(fish$discards)], 1999:2025))
  stop("The XML catch/landing/discard fields differ from the verified source coverage.", call. = FALSE)

blank_rows <- function(file, n) {
  header <- readLines(file.path(database, file), n = 1L, warn = FALSE, encoding = "UTF-8")
  columns <- names(read.csv(text = header, check.names = FALSE))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(columns)), stringsAsFactors = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns) out$assessment_id <- assessment_id
  out
}
format_number <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15L)
long_age_inputs <- function(tab, type, measure, basis, unit, table, notes,
                            source_type = "official_table", transformation = "") {
  n <- length(tab$year) * length(tab$age)
  out <- blank_rows("inputs.csv", n)
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$year <- rep(tab$year, each = length(tab$age)); out$year_basis <- "calendar_year"
  out$age <- rep(tab$age, times = length(tab$year))
  out$value <- format_number(as.vector(t(tab$value))); out$unit <- unit
  out$source_type <- source_type
  out$source_reference <- paste0(report_url, "; WGCSE 2026, chapter 27, Table ", table)
  out$transformation <- transformation; out$notes <- notes
  out
}

catch_input <- long_age_inputs(catch_numbers, "catch", "numbers_at_age", "numbers", "thousand fish", "27.3",
  "Total catch numbers by age, including the age-7+ group. Annex notes SAM estimates discard numbers at ages 5-7+ in 1999-2002; from 2003, discard estimates use InterCatch sampling. This combined series is not a fully observed landings/discards split.")
catch_input$fleet <- "All reported fisheries"
catch_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
catch_input$season <- "annual"

catch_weight_input <- long_age_inputs(catch_weights_source, "catch_weight", "catch_weight_at_age", "kg_per_fish", "kg/fish", "27.4",
  "Catch weight by age. Table 27.4 labels values tonnes; paired with Table 27.3 numbers in thousands, tonnes per thousand fish is numerically kg per fish. No numeric rescaling was applied.",
  transformation = "Table 27.4 values retained numerically and represented as kg/fish; tonnes per thousand fish and kg per fish are numerically equivalent.")
catch_weight_input$fleet <- "All reported fisheries"
catch_weight_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
catch_weight_input$season <- "annual"

stock_weight_input <- long_age_inputs(stock_weights, "weight", "weight_at_age", "kg_per_fish", "kg/fish", "27.7",
  "Q1 stock weights at age, Rivard corrected from annual mean catch weights; described as January 1 stock weights. Table 27.5 was checked and is numerically identical; only explicit Q1 values in Table 27.7 are stored.")
stock_weight_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
stock_weight_input$season <- "Q1"

survey_input <- long_age_inputs(survey_index, "index", "numbers_at_age", "numbers", "No/km2", "27.8",
  "Combined VAST age-specific density index from FR-EVHOE and IE-IGFS Q4 IBTS surveys. The source prints No/Km2. This is an abundance index, not an age-composition sample; exact within-year fraction is not published.")
survey_input$survey <- "Combined FR-EVHOE and IE-IGFS VAST recruitment survey"
survey_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
survey_input$season <- "Q4"

commercial_input <- blank_rows("inputs.csv", nrow(commercial_index))
commercial_input$type <- "index"
commercial_input$measure <- "relative_biomass_index"
commercial_input$basis <- "index_scale"
commercial_input$fleet <- "French commercial trawl (FRA-OTB)"
commercial_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
commercial_input$season <- "annual"
commercial_input$year <- commercial_index$year
commercial_input$year_basis <- "calendar_year"
commercial_input$value <- format_number(commercial_index$value)
commercial_input$unit <- "kg/hour"
commercial_input$source_type <- "official_table"
commercial_input$source_reference <- paste0(report_url, "; WGCSE 2026, chapter 27, Table 27.9")
commercial_input$notes <- "French commercial biomass/LPUE tuning index. The Stock Annex says it was used as a biomass index to avoid reusing age-composition information as a numbers-at-age index. It is not an absolute biomass estimate."

component_catch <- blank_rows("inputs.csv", 54L)
component_data <- rbind(
  data.frame(measure = "landings_biomass", value = fish$landings[historical], field = "Landings"),
  data.frame(measure = "discard_biomass", value = fish$discards[historical], field = "Discards")
)
component_catch$type <- "catch"
component_catch$measure <- component_data$measure
component_catch$basis <- "biomass"
component_catch$fleet <- "All reported fisheries"
component_catch$region <- "ICES divisions 7.b, 7.c and 7.e-k"
component_catch$season <- "annual"
component_catch$year <- rep(fish$year[historical], 2L)
component_catch$year_basis <- "calendar_year"
component_catch$value <- format_number(component_data$value)
component_catch$unit <- "tonnes"
component_catch$source_type <- "official_machine_readable"
component_catch$source_reference <- paste0(xml_url, "; Fish_Data/", component_data$field)
component_catch$notes <- "Annual ICES Standard Graphs total. Overlaps catch-at-age and is retained for source completeness, not as a separate likelihood series. XML Catches field is blank; total catch biomass is not inferred."

biology_input <- blank_rows("inputs.csv", 16L)
biology_input$type <- rep(c("M", "maturity"), each = 8L)
biology_input$measure <- rep(c("natural_mortality_at_age", "maturity_at_age"), each = 8L)
biology_input$basis <- rep(c("per_year", "proportion"), each = 8L)
biology_input$region <- "ICES divisions 7.b, 7.c and 7.e-k"
biology_input$age <- rep(ages, 2L)
biology_input$value <- format_number(c(natural_mortality, maturity))
biology_input$unit <- rep(c("per year", "proportion"), each = 8L)
biology_input$source_type <- "official_document"
biology_input$source_reference <- c(
  rep(paste0(report_url, "; WGCSE 2026, chapter 27, Natural Mortality section"), 8L),
  rep(paste0(report_url, "; WGCSE 2026, chapter 27, Maturity Ogive section"), 8L)
)
biology_input$notes <- c(
  rep("Fixed age-specific M vector printed in the 2026 production chapter. The Stock Annex lists alternate Lorenzen estimates from an earlier method; those are not substituted for the chapter vector.", 8L),
  rep("Survey-derived maturity vector printed in the 2026 production chapter. The Stock Annex also lists a WGCSE knife-edge vector and a slightly different pooled vector; the production chapter values are preserved and the discrepancy is recorded in the source review.", 8L)
)
inputs <- rbind(catch_input, catch_weight_input, stock_weight_input, survey_input,
  commercial_input, component_catch, biology_input)

add_output <- function(type, measure, value, unit, year, age = "", age_group = "",
                       lower = NA_real_, upper = NA_real_, source_type = "official_table",
                       source_reference, notes) {
  out <- blank_rows("outputs.csv", length(value))
  out$type <- type; out$measure <- measure; out$year <- year
  out$age <- age; out$age_group <- age_group
  out$value <- format_number(value)
  out$lwr <- ifelse(is.na(lower), "", format_number(lower))
  out$upr <- ifelse(is.na(upper), "", format_number(upper))
  out$unit <- unit; out$source_type <- source_type
  out$source_reference <- source_reference; out$notes <- notes
  out
}
long_age_outputs <- function(tab, type, measure, unit, table, notes) {
  age <- rep(tab$age, times = length(tab$year))
  add_output(type, measure, as.vector(t(tab$value)), unit,
    rep(tab$year, each = length(tab$age)), age = age,
    age_group = ifelse(age == 7, "7+", ""),
    source_reference = paste0(report_url, "; WGCSE 2026, chapter 27, Table ", table),
    notes = notes)
}
outputs <- rbind(
  long_age_outputs(f_at_age, "mortality", "fishing_mortality_at_age", "per year", "27.10",
    "Assessment-estimated F-at-age; age 7 is the plus group. Age-specific intervals are not reported."),
  long_age_outputs(n_at_age, "population", "numbers_at_age", "thousand fish", "27.11",
    "Assessment-estimated N-at-age; age 7 is the plus group. Age-specific intervals are not reported."),
  add_output("recruitment", "recruitment", fish$recruitment, "thousand fish", fish$year,
    age = rep("0", nrow(fish)), lower = fish$recruitment_lwr, upper = fish$recruitment_upr,
    source_type = "official_machine_readable", source_reference = paste0(xml_url, "; Fish_Data/Recruitment"),
    notes = "Age-0 recruitment with ICES 95% interval endpoints, not SEs. 2026 is a forecast; fitted historical data end in 2025."),
  add_output("biomass", "SSB", fish$ssb, "tonnes", fish$year,
    lower = fish$ssb_lwr, upper = fish$ssb_upr,
    source_type = "official_machine_readable", source_reference = paste0(xml_url, "; Fish_Data/StockSize"),
    notes = "Spawning-stock biomass with ICES 95% interval endpoints, not SEs. 2026 is a forecast; fitted historical data end in 2025."),
  add_output("mortality", "Fbar", fish$fbar[historical], "per year", fish$year[historical],
    age_group = rep("2-5", sum(historical)), lower = fish$fbar_lwr[historical],
    upper = fish$fbar_upr[historical], source_type = "official_machine_readable",
    source_reference = paste0(xml_url, "; Fish_Data/FishingPressure; WGCSE 2026, chapter 27, Table 27.12"),
    notes = "Average F over ages 2-5 as defined by the 2026 WGCSE chapter. ICES 95% interval endpoints, not SEs.")
)

av <- data.frame(
  component = c("model", "model", "population", "population", "recruitment", "mortality", "mortality", "mortality", "biology", "index", "index", "index", "catch", "catch", "uncertainty"),
  setting = c("model_type", "model_age_range", "assessment_year_range", "assessment_data_terminal_year", "recruitment_age", "fishing_mortality_age_coupling", "fishing_mortality_age_correlation", "natural_mortality", "maturity", "survey_index", "survey_observation_variance", "commercial_index", "discard_numbers_at_age", "landings_fraction_at_age", "reported_interval"),
  value = c("State-space assessment model (SAM)", "0-7+, with age 7 as plus group", "1999-2026 estimates", "2025", "0", "F states are bound for ages 6+", "AR(1) correlation across ages (corFlag=2 in Stock Annex configuration)", "Fixed age-specific Lorenzen-based vector supplied in production chapter", "Fixed survey-derived age-specific maturity vector supplied in production chapter", "Combined FR-EVHOE and IE-IGFS Q4 IBTS VAST density index at ages 0-2, 2003-2025", "Age 0 observation error estimated separately; ages 1-2 share an observation-error parameter", "French FRA-OTB commercial biomass index, kg/hour, 2000-2025", "For ages 5-7+ during 1999-2002, SAM estimates discard numbers because the earlier discard series is incomplete", "unknown", "95% interval endpoints for annual recruitment, SSB and Fbar; no SEs for N-at-age or F-at-age"),
  source_reference = c(
    paste0(annex_url, "; section 3"), paste0(annex_url, "; section 3 and Annex 2"),
    xml_url, xml_url, xml_url, paste0(annex_url, "; section 3"),
    paste0(annex_url, "; Annex 2 configuration excerpt saved 2020"),
    paste0(report_url, "; chapter 27, Natural Mortality"),
    paste0(report_url, "; chapter 27, Maturity Ogive"),
    paste0(report_url, "; chapter 27, Table 27.8; ", annex_url, "; section 3"),
    paste0(report_url, "; chapter 27, assessment notes"),
    paste0(report_url, "; chapter 27, Table 27.9; ", annex_url, "; section 3"),
    paste0(annex_url, "; section 2"), paste0(annex_url, "; section 3 input-data table (Lf.dat)"),
    paste0(xml_url, "; ConfidenceIntervalDefinition=95%")
  ),
  notes = c(
    "The 2026 WGCSE assessment was used for 2027 advice; a run-matched native model object/configuration was not recovered.",
    "Annual input ages 0-7+, with age 7 a plus group.",
    "2026 aggregate values are forecasts; historical age-specific tables end in 2025.",
    "Last fitted historical year is 2025.", "Recruitment is at age 0.",
    "Documented by the current Stock Annex; exact 2026 configuration was unavailable.",
    "Annex configuration is dated 2020; it is framework evidence, not a verified 2026 parameter file.",
    "The report vector is retained. The Annex lists alternate earlier Lorenzen estimates; see source review.",
    "The report vector is retained. Annex maturity differs slightly and includes a WGCSE knife-edge row; see source review.",
    "Source notation No/Km2. Both surveys are Q4; exact within-year fraction is not published.",
    "The report states age-0 error is separate and ages 1-2 are bound.",
    "The Annex says the French series is used as a biomass index to avoid reusing age compositions as a numbers-at-age index.",
    "Early older-age discard components are not directly observed catch counts.",
    "The Annex lists Lf.dat by age, but the run-matched numerical series was not recovered.",
    "Intervals remain source-reported endpoints; no standard errors are calculated."
  ), stringsAsFactors = FALSE
)
assumptions <- blank_rows("assumptions.csv", nrow(av))
assumptions[names(av)] <- av
assumptions$notes <- paste(assumptions$notes,
  "The Annex does not include the run-matched 2026 native configuration or all likelihood weights.")
survey_q <- blank_rows("assumptions.csv", 1L)
survey_q$component <- "index"
survey_q$setting <- "survey_catchability_sharing"
survey_q$value <- "Survey catchability for ages 1+ is bound"
survey_q$source_reference <- paste0(annex_url, "; section 3")
survey_q$notes <- "The Stock Annex describes ages 1+ as bound for the survey index. The exact 2026 run configuration was not recovered."
assumptions <- rbind(assumptions, survey_q)
stocks_path <- file.path(database, "stocks.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
existing_stock <- which(stocks$stock_id == stock_id | stocks$authority_stock_id == "whg.27.7b-ce-k")
conflicting_stock <- any(stocks$scientific_name == "Merlangius merlangus" &
  stocks$area == "ICES divisions 7.b, 7.c and 7.e-k" & stocks$stock_id != stock_id, na.rm = TRUE)
if ((length(existing_stock) && !dry_run) || length(existing_stock) > 1L || conflicting_stock)
  stop("The ICES Celtic Sea whiting stock identity is already present or conflicts with another stock row.", call. = FALSE)
if (length(existing_stock) && (stocks$authority[existing_stock] != "ICES" ||
    stocks$authority_stock_id[existing_stock] != "whg.27.7b-ce-k"))
  stop("The existing ICES whiting row does not match the verified unit.", call. = FALSE)
stock <- blank_rows("stocks.csv", 1L)
stock$stock_id <- stock_id
stock$authority <- "ICES"
stock$authority_stock_id <- "whg.27.7b-ce-k"
stock$scientific_name <- "Merlangius merlangus"
stock$common_name <- "Whiting"
stock$area <- "ICES divisions 7.b, 7.c and 7.e-k"
stock$region <- "Celtic Seas"
stock$ocean <- "Northeast Atlantic"
stock$notes <- "Distinct current ICES unit from whiting in division 7.a and from the North Sea unit. The 2026 WGCSE run provides detailed age-specific tables; see the source review for input limits and differences between production-chapter and Stock Annex biological summaries."

assessment_table <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
existing_assessment <- which(assessment_table$assessment_id == assessment_id)
if ((length(existing_assessment) && !dry_run) || length(existing_assessment) > 1L)
  stop("The ICES 2026 whiting assessment is already present.", call. = FALSE)
assessment <- blank_rows("assessments.csv", 1L)
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2026"
assessment$assessment_type <- "update"
assessment$model_family <- "SAM"
assessment$model_version <- "SAM; exact run build not recovered"
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2020"
assessment$assessment_url <- report_url
assessment$framework_url <- annex_url
assessment$data_url <- source_url
assessment$model_url <- ""
assessment$repository_url <- ""
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "2026 WGCSE assessment for 2027 advice; age-specific inputs and outputs are transcribed from report Tables 27.3-27.11 and aggregate estimates/95% intervals from ICES Standard Graphs key 23780.",
  "The production chapter's M and maturity vectors are stored as printed; the Stock Annex contains alternate or slightly different biological summaries. The run-matched configuration, landings-fraction series, exact survey timing, and age-specific output uncertainty were not recovered."
)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L || register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "whg.27.7b-ce-k" ||
    register$inventory_assessment_year[candidate_row] != 2026L ||
    register$match_status[candidate_row] != "new" || register$eligibility[candidate_row] != "eligible")
  stop("The selected ICES whiting candidate does not uniquely match the new source record.", call. = FALSE)
register$catch_age_evidence[candidate_row] <- "The WGCSE 2026 production chapter provides catch numbers-at-age, ages 0-7+, 1999-2025. The Stock Annex notes SAM estimates discard numbers at ages 5-7+ in 1999-2002; later discard estimates use InterCatch sampling."
register$survey_age_evidence[candidate_row] <- "Table 27.8 provides the combined FR-EVHOE and IE-IGFS VAST Q4 survey index at ages 0-2, 2003-2025; Table 27.9 provides a French commercial biomass index for 2000-2025."
register$weights_evidence[candidate_row] <- "Tables 27.4 and 27.7 provide catch and Q1 stock weights-at-age for 1999-2025. The catch-weight unit interpretation and duplicate Tables 27.5/27.7 are documented in the source review."
register$maturity_evidence[candidate_row] <- "The WGCSE 2026 production chapter prints a fixed survey-derived maturity vector at ages 0-7+. Its values differ from alternate summaries in the Stock Annex; see review."
register$mortality_evidence[candidate_row] <- "The WGCSE 2026 production chapter prints a fixed age-specific Lorenzen-based M vector at ages 0-7+. The Stock Annex lists alternative earlier Lorenzen values."
register$timing_evidence[candidate_row] <- "The two VAST surveys are Q4 IBTS surveys. The exact within-year fraction used by the assessment was not recovered."
register$output_evidence[candidate_row] <- "WGCSE Tables 27.10-27.12 and ICES Stock Assessment Graphs key 23780 provide F-at-age, N-at-age, SSB, age-0 recruitment and Fbar ages 2-5; 95% intervals are available only for aggregate outputs."
register$import_status[candidate_row] <- "partial"
register$notes[candidate_row] <- paste(
  "Imported the 2026 ICES WGCSE production assessment age-specific tables and ICES Standard Graphs aggregate series.",
  "Inputs, assumptions, and outputs remain partial because the run-matched configuration, landings-fraction series, exact survey fraction, and age-specific uncertainty were not recovered. See source_reviews/ices_whiting_7b_ce_k_2026.md."
)

selected <- read.csv(selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L || (!dry_run && selected$curation_status[selected_row] != "selected_pending_source_validation") ||
    (dry_run && !selected$curation_status[selected_row] %in% c("selected_pending_source_validation", "partial_source_import")))
  stop("The selected-batch whiting row is missing, duplicated, or already processed.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  "Imported the latest 2026 WGCSE age-specific catch, weights, survey and commercial indices, biological vectors, and F/N-at-age outputs; ICES Standard Graphs supplies aggregate output intervals.",
  "The run-matched landings fraction, exact configuration and timing remain unavailable; see the source review."
)

append_rows <- function(file, data) {
  path <- file.path(database, file)
  columns <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  if (!identical(names(data), columns)) stop("Column mismatch in ", file, call. = FALSE)
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(data, temporary, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  bytes <- readBin(temporary, "raw", n = file.info(temporary)$size)
  needs_newline <- FALSE
  if (file.info(path)$size > 0L) {
    con <- file(path, open = "rb"); seek(con, where = -1L, origin = "end")
    last <- readBin(con, "raw", n = 1L); close(con)
    needs_newline <- !identical(last, as.raw(10L))
  }
  con <- file(path, open = "ab")
  if (needs_newline) writeBin(as.raw(10L), con)
  writeBin(bytes, con)
  close(con)
}
replace_csv_row <- function(path, data, key_column, key_value) {
  table <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  key <- which(as.character(table[[key_column]]) == key_value)
  if (length(key) != 1L || !identical(names(data), names(table)))
    stop("Expected exactly one matching row in ", basename(path), call. = FALSE)
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  starts <- 1L; ends <- integer(); quoted <- FALSE; i <- 1L
  while (i <= length(bytes)) {
    if (identical(bytes[i], as.raw(34L))) {
      if (quoted && i < length(bytes) && identical(bytes[i + 1L], as.raw(34L))) { i <- i + 2L; next }
      quoted <- !quoted
    } else if (identical(bytes[i], as.raw(10L)) && !quoted) {
      ends <- c(ends, i - 1L); starts <- c(starts, i + 1L)
    }
    i <- i + 1L
  }
  if (quoted) stop("CSV has an unclosed quoted field.", call. = FALSE)
  if (tail(starts, 1L) <= length(bytes)) ends <- c(ends, length(bytes)) else starts <- head(starts, -1L)
  if (length(starts) != length(ends)) stop("CSV record boundaries are invalid.", call. = FALSE)
  records <- which(vapply(seq_along(starts), function(row) {
    if (starts[row] > ends[row]) return(FALSE)
    any(!(bytes[starts[row]:ends[row]] %in% as.raw(c(9L, 13L, 32L))))
  }, logical(1L)))
  if (length(records) != nrow(table) + 1L) stop("CSV record count differs from parsed data.", call. = FALSE)
  record <- records[key + 1L]; first <- starts[record]; last <- ends[record]
  lf <- if (record < length(starts)) starts[record + 1L] - 1L else NA_integer_
  ending <- raw()
  if (!is.na(lf) && lf >= first && identical(bytes[lf], as.raw(10L))) {
    ending <- if (last >= first && identical(bytes[last], as.raw(13L))) as.raw(c(13L, 10L)) else as.raw(10L)
    if (length(ending) == 2L) last <- last - 1L
  } else lf <- NA_integer_
  temp <- tempfile(fileext = ".csv"); on.exit(unlink(temp), add = TRUE)
  write.table(data, temp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readBin(temp, "raw", n = file.info(temp)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw()
  after_start <- if (!is.na(lf)) lf + 1L else last + 1L
  after <- if (after_start <= length(bytes)) bytes[after_start:length(bytes)] else raw()
  writeBin(c(before, replacement, ending, after), path)
}
if (dry_run) {
  cat("Validated ICES whiting source import:", nrow(inputs), "input rows,",
    nrow(assumptions), "assumptions, and", nrow(outputs), "output rows.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("assumptions.csv", assumptions)
  append_rows("inputs.csv", inputs)
  append_rows("outputs.csv", outputs)
  source(file.path(root, "scripts", "database", "candidate_register_io.R"))
  replace_candidate_register_row(register_path, candidate_row, register[candidate_row, , drop = FALSE], candidate_id)
  replace_csv_row(selected_path, selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported partial ICES 2026 Celtic Sea whiting source data.\n")
}
