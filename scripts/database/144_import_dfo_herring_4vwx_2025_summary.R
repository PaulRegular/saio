base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_dfo_mar_harengus_4vwx")
pdf <- file.path(cache, "DFO_2025_026_4VWX_herring_update_2024.pdf")
stopifnot(file.exists(pdf), digest::digest(readBin(pdf, "raw", n = file.info(pdf)$size),
  serialize = FALSE, algo = "sha256") == "609c335ec5b41fc704398ea21c4c2a341033ca24170ebf91e8104dd4f84eb9c3")
assessment_id <- "dfo_herring_4vwx_2025_indicators"
stock_id <- "ck_dfo_mar_harengus_4vwx"
url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4130293x.pdf"
framework <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41087719.pdf"
blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
input <- function(type, measure, basis, values, unit, years, region, reference,
                  survey = "", notes = "", source_type = "official_table") {
  out <- blank("inputs.csv", length(values))
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$value <- values; out$unit <- unit; out$year <- years
  out$year_basis <- "calendar_year"; out$region <- region
  out$survey <- survey; out$source_type <- source_type
  out$source_reference <- paste(url, reference, sep = "; ")
  out$notes <- notes
  out
}
landings <- function(values, unit, years, region, reference, notes = "") {
  out <- input("catch", "total_biomass", "biomass", values, unit, years, region, reference,
    notes = paste("Reported component total landings, not catch-at-age. No gear allocation or age composition is inferred.", notes))
  early <- years < 2020
  out$year_basis[early] <- "model_year"
  out$notes[early] <- paste(out$notes[early],
    "Original report-year labels retained; exact pre-2020 annual period for this component is unresolved. No calendar-year realignment is inferred.")
  out
}
inputs <- rbind(
  landings(c(34.4, 32.6, 23.9, 20.7, 15.7), "kt", 2020:2024,
    "Southwest Nova Scotia/Bay of Fundy", "Table 1",
    "Original rounded kilotonne table values. New Brunswick weir/shut-off landings are excluded from this component."),
  landings(c(5943, 5557, 7353, 8707, 10747, 6355, 6900, 8631, 6900, 5498), "tonnes", 2015:2024,
    "Little Hope/Port Mouton", "Table 2"),
  landings(c(1837, 2259, 2553, 4544, 6871, 5635, 5495, 3487, 5495, 2884), "tonnes", 2015:2024,
    "Halifax/Eastern Shore", "Table 2"),
  landings(c(0, 4, 0, 9, 1, 2, 0, 0, 0, 0), "tonnes", 2015:2024,
    "Glace Bay", "Table 2"),
  landings(rep(0, 10), "tonnes", 2015:2024,
    "Bras d'Or Lakes", "Table 2", "The fishery remained closed."),
  landings(10, "tonnes", 2024, "Offshore Scotian Shelf", "p. 7", "Reported in the text."))
inputs$source_type[inputs$region == "Offshore Scotian Shelf"] <- "official_document"
index <- function(values, years, region, reference, notes = "", source_type = "official_table") {
  input("index", "relative_biomass_index", "index_scale", values, "tonnes", years,
    region, reference, survey = "Acoustic spawning-biomass index",
    notes = paste("Source acoustic index of spawning biomass, not fitted population SSB or an age-specific abundance index.",
      "No sampling fraction is inferred from spawning season. These spawning components must not be pooled without a documented definition.", notes),
    source_type = source_type)
}
inputs <- rbind(inputs,
  index(c(145395, 61408, 66815, 168164, 92019, 35739, 82297, 41383, 68573, 64189),
    2015:2024, "Little Hope/Port Mouton", "Table 3"),
  index(c(68562, 54312, 58681, 42416, 141198, 26205, 18341, 20313, 28057, 15430),
    2015:2024, "Halifax/Eastern Shore", "Table 3"),
  index(50, 2015, "Glace Bay", "Table 3", "No survey in 2016-2024; no zero indices are invented."),
  index(301290, 2024, "German Bank and Scots Bay", "pp. 2 and 5",
    "Combined annual index used in the SWNS/BoF indicator; Seal Island and other spawning grounds are outside this combination.", "official_document"))
outputs <- blank("outputs.csv")
outputs$type <- "biomass"; outputs$measure <- "acoustic_SSB_index_three_year_mean"
outputs$year <- 2024; outputs$region <- "German Bank and Scots Bay"
outputs$value <- 296430; outputs$unit <- "tonnes"
outputs$source_type <- "official_document"; outputs$source_reference <- paste(url, "p. 5", sep = "; ")
outputs$notes <- "Reported 2022-2024 moving mean of the acoustic spawning-biomass index; not a fitted population SSB. No uncertainty is reported. Do not map to the standard SSB comparison."
assumption <- function(component, setting, value, notes, reference = "pp. 2-3") {
  out <- blank("assumptions.csv")
  out$component <- component; out$setting <- setting; out$value <- value
  out$source_reference <- paste(url, reference, sep = "; "); out$notes <- notes
  out
}
assumptions <- rbind(
  assumption("assessment", "scope", "Interim-year component indicators, not a new stock-wide analytical fit", "The 2025 update supplies no catch advice and retains the 2022 MSE framework."),
  assumption("population", "stock_components", "SWNS/BoF; Coastal Nova Scotia; Offshore Scotian Shelf; southwest New Brunswick migrant juveniles", "SW New Brunswick juveniles are considered to originate in NAFO Subarea 5 and are excluded from the SWNS/BoF quota."),
  assumption("assessment", "framework", "2022 MSE for SWNS/BoF; indicators for other components", "The source reference set is an ensemble, not one stock-wide fitted N/F/M surface."),
  assumption("assessment", "native_archive_cutoff", "Recovered pinned input archive ends in 2018; official reference OMs conditioned through 2020", "Older archive input values and reconstructed outputs must not be substituted for the production reference set.", "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41251349.pdf; Evaluation of Candidate Management Procedures; pinned repository 515857664de2719f7fd1b227b41862b82673ac56"),
  assumption("index", "stock_status_indicator", "Three-year moving mean, German Bank and Scots Bay", "Reported 2022-2024 mean is 296430 t; this is an acoustic index rather than a fitted SSB estimate.", "p. 5"),
  assumption("index", "2021_2024_revision", "Scots Bay acoustic estimates corrected for survey turnover", "Use the 2025 update's values; do not append newer values to an unchanged older acoustic series.", "p. 3"),
  assumption("index", "sampling_time", "unknown", "The summary gives spawning-season context but no verified numerical model timing. No midpoint is invented."),
  assumption("assessment", "source_gaps", "Production 2019-2020 inputs, native fitted reference states and complete model configuration unavailable", ""))
assessment <- blank("assessments.csv")
assessment$stock_id <- stock_id; assessment$assessment_year <- 2025
assessment$terminal_year <- assessment$estimate_terminal_year <- 2024
assessment$assessment_type <- "interim-year update"
assessment$model_family <- "MSE and component indicators"
assessment$is_current <- "FALSE"; assessment$is_applied <- "TRUE"
assessment$framework_year <- 2022; assessment$assessment_url <- url
assessment$framework_url <- framework
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Summary-only 2025 component indicator update. No current detailed production run has been populated. Acoustic indices are not fitted SSB/N/F/M states. The pinned public example archive ends in 2018, before the official 2020 conditioning cutoff; its inputs and candidate outputs are not mixed into this record."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
at <- which(stocks$stock_id == stock_id)
stopifnot(length(at) == 1L, stocks$charbonneau_id[at] == "DFO-MAR_harengus_4VWX")
stocks$common_name[at] <- "Atlantic herring (4VWX components)"
stocks$authority[at] <- "DFO"; stocks$authority_stock_id[at] <- "4VWX"
stocks$scientific_name[at] <- "Clupea harengus"
stocks$area[at] <- "NAFO 4VWX management unit and separately identified spawning components"
stocks$region[at] <- "Scotian Shelf and Bay of Fundy"; stocks$ocean[at] <- "Northwest Atlantic"
stocks$notes[at] <- "Charbonneau-Keith DFO-MAR_harengus_4VWX. The management unit contains distinct spawning components; the SWNS/BoF MSE is not a stock-wide analytical fit. Migrant New Brunswick juveniles are considered of NAFO Subarea 5 origin."
write_rows <- function(file, x, id = assessment_id) {
  path <- file.path(database, file)
  contents <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = database); on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (length(selected) != nrow(x)) cli::cli_abort("Existing {file} coverage differs; review before replacing.")
    lines[selected] <- paste0(replacement, ifelse(endsWith(lines[selected], "\r"), "\r", ""))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stocks[at, ], stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)
cat("Imported 4VWX herring 2025 summary:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions and one indicator output; statuses remain partial.\n")
