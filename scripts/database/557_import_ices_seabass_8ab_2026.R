root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_ices_seabass_8ab_2026")
register_path <- file.path(root, "discovery", "candidates.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")

dry_run <- identical(Sys.getenv("TAM_SOURCE_DRY_RUN"), "1")
stock_id <- "ices_seabass_8ab"
assessment_id <- "ices_seabass_8ab_2026"
candidate_id <- "ICES:bss.27.8ab"
source_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22538"
xml_url <- "https://sag.ices.dk/SAG_API/StockXmlDownload/22538"
advice_url <- "https://asd.ices.dk/viewAdvice/6153"
framework_url <- "https://doi.org/10.17895/ices.pub.25002488.v1"
update_report_url <- "https://doi.org/10.17895/ices.pub.32790321.v1"

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

manifest <- read.csv(file.path(cache, "sources.csv"), stringsAsFactors = FALSE)
source_paths <- file.path(cache, manifest$file)
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size != manifest$bytes))
  stop("Cached ICES source files do not match their manifest sizes.", call. = FALSE)
actual_hashes <- vapply(source_paths, sha256_file, character(1L))
if (!identical(tolower(manifest$sha256), unname(actual_hashes)))
  stop("Cached ICES source files do not match their SHA-256 manifest.", call. = FALSE)

xml_path <- file.path(cache, "ICES_StockAssessment_22538.xml")
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

if (xml_value("StockCode") != "bss.27.8ab" || xml_value("AssessmentYear") != "2026" ||
    xml_value("Fage") != "4-15" || xml_value("RecruitmentAge") != "0" ||
    xml_value("StockSizeDescription") != "Combined-sex SSB" ||
    xml_value("ConfidenceIntervalDefinition") != "90%" ||
    !identical(fish$year, 1985:2026) || anyDuplicated(fish$year))
  stop("The ICES source does not match the expected 2026 seabass assessment.", call. = FALSE)

historical <- fish$year <= 2025L
if (any(!is.finite(fish$recruitment)) || any(!is.finite(fish$ssb)) ||
    any(!is.finite(fish$fbar[historical])) || any(is.finite(fish$fbar[!historical])) ||
    any(fish$recruitment_lwr > fish$recruitment | fish$recruitment > fish$recruitment_upr) ||
    any(fish$ssb_lwr > fish$ssb | fish$ssb > fish$ssb_upr) ||
    any(fish$fbar_lwr[historical] > fish$fbar[historical] |
        fish$fbar[historical] > fish$fbar_upr[historical]))
  stop("ICES annual estimates or intervals failed validation.", call. = FALSE)

observed_catch <- !is.na(fish$catch) & !is.na(fish$landings)
if (!identical(fish$year[observed_catch], 1985:2025) ||
    any(abs(fish$catch[observed_catch] - fish$landings[observed_catch] -
      ifelse(is.na(fish$discards[observed_catch]), 0, fish$discards[observed_catch])) > 1))
  stop("The reported annual catch components do not reconcile within rounding.", call. = FALSE)

blank_rows <- function(file, n) {
  columns <- names(read.csv(file.path(database, file), nrows = 0L, check.names = FALSE))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(columns)), stringsAsFactors = FALSE)
  names(out) <- columns
  if ("assessment_id" %in% columns) out$assessment_id <- assessment_id
  out
}

catch_inputs <- blank_rows("inputs.csv", sum(historical) * 3L)
input_series <- rbind(
  data.frame(measure = "total_biomass", value = fish$catch[historical], field = "Catches"),
  data.frame(measure = "landings_biomass", value = fish$landings[historical], field = "Landings"),
  data.frame(measure = "discard_biomass", value = fish$discards[historical], field = "Discards")
)
catch_inputs$type <- "catch"
catch_inputs$measure <- input_series$measure
catch_inputs$basis <- "biomass"
catch_inputs$fleet <- "All reported fisheries"
catch_inputs$region <- "ICES divisions 8.a and 8.b"
catch_inputs$season <- "annual"
catch_inputs$year <- rep(fish$year[historical], 3L)
catch_inputs$year_basis <- "calendar_year"
catch_inputs$value <- ifelse(is.na(input_series$value), "", format(input_series$value, scientific = FALSE, trim = TRUE))
catch_inputs$unit <- "tonnes"
catch_inputs$source_type <- "official_machine_readable"
catch_inputs$source_reference <- paste0(source_url, "; Fish_Data/", input_series$field)
catch_inputs$notes <- paste(
  "Annual aggregate series reported by ICES Standard Graphs. The XML does not",
  "identify fleet coverage or establish that these are the complete Stock",
  "Synthesis likelihood inputs. Total catches overlap their landings and",
  "discard components; do not sum all three series as independent removals."
)
catch_inputs$notes[catch_inputs$measure == "discard_biomass"] <- paste(
  catch_inputs$notes[catch_inputs$measure == "discard_biomass"],
  "Blank source values are preserved as unavailable, not interpreted as zero."
)

mortality_inputs <- blank_rows("inputs.csv", 7L)
mortality_inputs$type <- "M"
mortality_inputs$measure <- "natural_mortality_at_age"
mortality_inputs$basis <- "per_year"
mortality_inputs$region <- "ICES divisions 8.a and 8.b"
mortality_inputs$age <- 0:6
mortality_inputs$value <- c(0.840918, 0.463849, 0.365109, 0.306347, 0.267492, 0.24, 0.24)
mortality_inputs$unit <- "per year"
mortality_inputs$source_type <- "official_document"
mortality_inputs$source_reference <- paste0(update_report_url, "; WGBIE 2026, section 11.2")
mortality_inputs$notes <- c(rep("Fixed natural mortality value reported by the 2026 assessment.", 6L),
  "Fixed 0.24 per year for age 6 and older.")
inputs <- rbind(catch_inputs, mortality_inputs)

output_rows <- list()
add_output <- function(type, measure, value, unit, year, lower = NA_real_, upper = NA_real_, age = "", age_group = "", note) {
  out <- blank_rows("outputs.csv", length(value))
  out$type <- type
  out$measure <- measure
  out$year <- year
  out$age <- age
  out$age_group <- age_group
  out$value <- format(value, scientific = FALSE, trim = TRUE)
  out$lwr <- ifelse(is.na(lower), "", format(lower, scientific = FALSE, trim = TRUE))
  out$upr <- ifelse(is.na(upper), "", format(upper, scientific = FALSE, trim = TRUE))
  out$unit <- unit
  out$source_type <- "official_machine_readable"
  out$source_reference <- paste0(xml_url, "; Fish_Data/", measure)
  out$notes <- note
  out
}
output_rows[[1L]] <- add_output("recruitment", "recruitment", fish$recruitment,
  "thousand fish", fish$year, fish$recruitment_lwr, fish$recruitment_upr,
  age = "0", note = "Age-0 recruitment; the source reports 90% interval endpoints, not standard errors. 2026 is a forecast, not a fitted historical year.")
output_rows[[2L]] <- add_output("biomass", "SSB", fish$ssb,
  "tonnes", fish$year, fish$ssb_lwr, fish$ssb_upr,
  note = "Combined-sex spawning-stock biomass; the source reports 90% interval endpoints, not standard errors. 2026 is a forecast, not a fitted historical year.")
fitted_f <- historical & is.finite(fish$fbar)
output_rows[[3L]] <- add_output("mortality", "Fbar", fish$fbar[fitted_f],
  "per year", fish$year[fitted_f], fish$fbar_lwr[fitted_f], fish$fbar_upr[fitted_f],
  age_group = "4-15", note = "Fishing mortality averaged over ages 4-15; the source reports 90% interval endpoints, not standard errors.")
outputs <- do.call(rbind, output_rows)

assumptions <- blank_rows("assumptions.csv", 9L)
assumptions$component <- c("model", "model", "recruitment", "biomass", "mortality", "uncertainty", "reference_point", "reference_point", "reference_point")
assumptions$setting <- c("model_type", "assessment_data_terminal_year", "recruitment_age", "stock_size_definition", "Fbar_age_range", "interval_definition", "Fmsy", "MSYBtrigger", "Blim")
assumptions$value <- c("Age- and length-structured Stock Synthesis 3 assessment", "2025", "0", "Combined-sex spawning-stock biomass", "4-15", "90% interval endpoints; standard errors unavailable in Standard Graphs export", "0.205 per year", "21782 tonnes", "17273 tonnes")
assumptions$source_reference <- c(xml_url, update_report_url, xml_url, xml_url, xml_url, xml_url, xml_url, xml_url, xml_url)
assumptions$notes <- c(
  "The 2026 assessment update uses the model structure established by the 2025 WKBSEABASS benchmark.",
  "Annual estimates for 2026 are forecasts; fitted data end in 2025.",
  "Recruitment is reported at age 0 in thousands of fish.",
  "The ICES source table explicitly labels the stock-size series combined-sex SSB in tonnes.",
  "F is reported as an average over ages 4-15.",
  "The XML provides lower and upper 90% interval endpoints; no SE is calculated from them.",
  "ICES reference point in the 2026 assessment record.",
  "ICES reference point in the 2026 assessment record.",
  "ICES reference point in the 2026 assessment record."
)

stocks_path <- file.path(database, "stocks.csv")
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
existing_stock <- which(stocks$stock_id == stock_id | stocks$authority_stock_id == "bss.27.8ab")
if ((length(existing_stock) && !dry_run) || length(existing_stock) > 1L ||
    any(stocks$scientific_name == "Dicentrarchus labrax" & stocks$area == "ICES divisions 8.c and 9.a", na.rm = TRUE))
  stop("The Bay of Biscay 8.a-b stock identity conflicts with the existing database.", call. = FALSE)
if (length(existing_stock) && (stocks$stock_id[existing_stock] != stock_id ||
    stocks$authority[existing_stock] != "ICES" ||
    stocks$authority_stock_id[existing_stock] != "bss.27.8ab"))
  stop("The existing ICES seabass row does not match the source stock identity.", call. = FALSE)
assessment_table <- read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE)
existing_assessment <- which(assessment_table$assessment_id == assessment_id)
if ((length(existing_assessment) && !dry_run) || length(existing_assessment) > 1L)
  stop("The ICES seabass assessment is already imported or duplicated.", call. = FALSE)
stock <- blank_rows("stocks.csv", 1L)
stock$stock_id <- stock_id
stock$authority <- "ICES"
stock$authority_stock_id <- "bss.27.8ab"
stock$scientific_name <- "Dicentrarchus labrax"
stock$common_name <- "Seabass - northern and central Bay of Biscay"
stock$area <- "ICES divisions 8.a and 8.b"
stock$region <- "Bay of Biscay and the Iberian Coast"
stock$ocean <- "Northeast Atlantic"
stock$notes <- "Distinct from the southern Bay of Biscay and Atlantic Iberian seabass unit bss.27.8c9a and from the separate western seabass units. Latest detailed source is the ICES 2026 assessment for 2027 advice. See the source review for the partial input record."

assessment <- blank_rows("assessments.csv", 1L)
assessment$assessment_id <- assessment_id
assessment$stock_id <- stock_id
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2026"
assessment$assessment_type <- "update"
assessment$model_family <- "Stock Synthesis"
assessment$model_version <- "SS3; version not recovered"
assessment$is_current <- "TRUE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2025"
assessment$assessment_url <- advice_url
assessment$framework_url <- framework_url
assessment$data_url <- source_url
assessment$model_url <- xml_url
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "Latest detailed official assessment identified: ICES 2026 update for 2027 advice, using data through 2025 and the 2025 WKBSEABASS model framework.",
  "Standard Graphs reports annual aggregate catch series and SSB, age-0 recruitment, and Fbar ages 4-15; 2026 SSB and recruitment are forecasts.",
  "Run-matched age-specific catch/index arrays, exact survey timing, and source age-specific biological inputs were not recovered. Completeness remains partial."
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
    tail_connection <- file(path, open = "rb")
    seek(tail_connection, where = -1L, origin = "end")
    last <- readBin(tail_connection, "raw", n = 1L)
    close(tail_connection)
    needs_newline <- !identical(last, as.raw(10L))
  }
  connection <- file(path, open = "ab")
  on.exit(close(connection), add = TRUE)
  if (needs_newline) writeBin(as.raw(10L), connection)
  writeBin(bytes, connection)
}

replace_csv_row <- function(path, data, key_column, key_value) {
  table <- read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  key <- which(as.character(table[[key_column]]) == key_value)
  if (length(key) != 1L || !identical(names(data), names(table)))
    stop("Expected exactly one matching row in ", basename(path), call. = FALSE)
  table[key, ] <- data
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  starts <- 1L
  ends <- integer()
  quoted <- FALSE
  i <- 1L
  while (i <= length(bytes)) {
    if (identical(bytes[i], as.raw(34L))) {
      if (quoted && i < length(bytes) && identical(bytes[i + 1L], as.raw(34L))) {
        i <- i + 2L
        next
      }
      quoted <- !quoted
    } else if (identical(bytes[i], as.raw(10L)) && !quoted) {
      ends <- c(ends, i - 1L)
      starts <- c(starts, i + 1L)
    }
    i <- i + 1L
  }
  if (quoted) stop("CSV has an unclosed quoted field.", call. = FALSE)
  if (tail(starts, 1L) <= length(bytes)) {
    ends <- c(ends, length(bytes))
  } else {
    starts <- head(starts, -1L)
  }
  if (length(starts) != length(ends)) stop("CSV record boundaries are invalid.", call. = FALSE)
  is_blank <- vapply(seq_along(starts), function(row) {
    if (starts[row] > ends[row]) return(TRUE)
    all(bytes[starts[row]:ends[row]] %in% as.raw(c(9L, 13L, 32L)))
  }, logical(1L))
  records <- which(!is_blank)
  if (length(records) != nrow(table) + 1L)
    stop("CSV record count does not match the parsed table.", call. = FALSE)
  record <- records[key + 1L]
  start <- starts[record]
  content_end <- ends[record]
  lf <- if (record < length(starts)) starts[record + 1L] - 1L else NA_integer_
  terminator <- raw()
  if (!is.na(lf) && lf >= start && identical(bytes[lf], as.raw(10L))) {
    if (content_end >= start && identical(bytes[content_end], as.raw(13L))) {
      terminator <- as.raw(c(13L, 10L))
      content_end <- content_end - 1L
    } else terminator <- as.raw(10L)
  } else lf <- NA_integer_
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  write.table(data, temporary, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readBin(temporary, "raw", n = file.info(temporary)$size)
  if (length(replacement) && identical(replacement[length(replacement)], as.raw(10L)))
    replacement <- replacement[-length(replacement)]
  if (length(replacement) && identical(replacement[length(replacement)], as.raw(13L)))
    replacement <- replacement[-length(replacement)]
  prefix <- if (start > 1L) bytes[seq_len(start - 1L)] else raw()
  suffix_start <- if (!is.na(lf)) lf + 1L else content_end + 1L
  suffix <- if (suffix_start <= length(bytes)) bytes[suffix_start:length(bytes)] else raw()
  writeBin(c(prefix, replacement, terminator, suffix), path)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
candidate_row <- which(register$candidate_id == candidate_id)
if (length(candidate_row) != 1L || register$candidate_unit_id[candidate_row] != stock_id ||
    register$official_stock_id[candidate_row] != "bss.27.8ab" ||
    register$inventory_assessment_year[candidate_row] != 2026L)
  stop("The ICES seabass candidate does not uniquely match the source record.", call. = FALSE)
register$import_status[candidate_row] <- "partial"
register$notes[candidate_row] <- paste(
  "Imported the 2026 ICES Standard Graphs aggregate catch, landing and discard series (1985-2025), fixed M-at-age assumptions, and annual SSB, age-0 recruitment and Fbar ages 4-15 outputs.",
  "The source provides 90% intervals for population outputs. Run-matched age-specific catch/index inputs and exact survey timing remain unavailable; see the stock source review."
)

selected <- read.csv(selected_path, stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selected_row <- which(selected$candidate_id == candidate_id)
if (length(selected_row) != 1L) stop("Selected-batch entry is missing or duplicated.", call. = FALSE)
selected$curation_status[selected_row] <- "partial_source_import"
selected$selection_basis[selected_row] <- paste(
  "Imported the latest 2026 ICES aggregate catch series, fixed M-at-age assumptions, and annual SSB, age-0 recruitment and Fbar outputs with source intervals.",
  "Run-matched age-specific catch/index inputs and exact survey timing remain unavailable."
)

if (dry_run) {
  cat("Validated ICES seabass source import:", nrow(catch_inputs), "aggregate catch rows,",
    nrow(mortality_inputs), "fixed M-at-age rows,", nrow(assumptions), "assumptions, and",
    nrow(outputs), "annual output rows.\n")
} else {
  append_rows("stocks.csv", stock)
  append_rows("assessments.csv", assessment)
  append_rows("assumptions.csv", assumptions)
  append_rows("inputs.csv", inputs)
  append_rows("outputs.csv", outputs)
  replace_csv_row(register_path, register[candidate_row, , drop = FALSE], "candidate_id", candidate_id)
  replace_csv_row(selected_path, selected[selected_row, , drop = FALSE], "candidate_id", candidate_id)
  cat("Imported partial ICES 2026 Bay of Biscay seabass data.\n")
}
