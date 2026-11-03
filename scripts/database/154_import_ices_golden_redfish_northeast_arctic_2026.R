base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache/ck_ices_afwg_norvegicus_deep1_2")
assessment_id <- "ices_golden_redfish_northeast_arctic_2026"
stock_id <- "ck_ices_afwg_norvegicus_deep1_2"
advice_url <- "https://doi.org/10.17895/ices.advice.30932315.v1"
report_url <- "https://doi.org/10.17895/ices.pub.32134696"
framework_url <- "https://doi.org/10.17895/ices.pub.32019630"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23725"
verify <- function(file, expected) {
  path <- file.path(cache, file)
  if (!file.exists(path) || digest::digest(readBin(path, "raw", n = file.info(path)$size),
    serialize = FALSE, algo = "sha256") != expected) cli::cli_abort("Cache and verify {file} before importing.")
  path
}
advice <- pdftools::pdf_text(verify("ICES_advice_2026_golden_redfish_1_2.pdf",
  "37731375f501820bf4f5f7c54f5e74b44cbaf01bc8c5579039dedad2bdc340b9"))
report <- pdftools::pdf_text(verify("AFWG_2026_Golden_Redfish.pdf",
  "c4f6b7879c37005bb2bbd5d5dcedd84fd7639035a263876779135bc454e68501"))
verify("WKBWNG_2026_Benchmark_Report.pdf", "415a7d0349f5dbdc849c5f927c054cd4f8417ff7318b1fee998e64d7917f0e18")
verify("WKBWNG_2026_Golden_Redfish_Data_Working_Document.pdf", "389a78f00c97b9286a5e9943fff6d55ad48a84e3ad3159cc3a200aed8e89f89d")
sag <- Filter(function(x) all(c("Year", "SSB", "F", "Catches") %in% names(x)),
  rvest::html_table(rvest::read_html(verify("SAG_23725.html",
    "586ab315ca56e95ef23b90cc8558e280886aafea4f03532bb2febfa122f11faa")), fill = TRUE))
stopifnot(length(sag) == 1L)
sag <- as.data.frame(sag[[1L]])
stopifnot(identical(sag$Year, 1908:2026), sum(!is.na(sag$Catches)) == 118L,
  is.na(sag$Catches[sag$Year == 2026]), is.na(sag$F[sag$Year == 2026]))

# Independently check all seven historical columns against final advice Table 9.
lines <- unlist(strsplit(paste(advice, collapse = "\n"), "\n"))
decimal <- "([0-9]+\\.[0-9]+)"
pattern <- paste0("^\\s*((?:19|20)[0-9]{2})\\s+", paste(rep(decimal, 3), collapse = "\\s+"),
  "\\s+([0-9 ]+)\\s+", paste(rep(decimal, 3), collapse = "\\s+"), "\\s*$")
rows <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
rows <- rows[lengths(rows) == 9L]
printed <- do.call(rbind, lapply(rows, function(x) as.numeric(gsub(" ", "", x[-1L], fixed = TRUE))))
columns <- c("Year", "Low SSB", "SSB", "High SSB", "Catches", "Low F", "F", "High F")
stopifnot(identical(as.integer(printed[, 1]), 1908:2025),
  isTRUE(all.equal(unname(printed), unname(as.matrix(sag[sag$Year <= 2025, columns])), check.attributes = FALSE)))
future <- trimws(lines[grepl("^\\s*2026\\s+0\\.26\\s+0\\.44\\s+0\\.75\\s*$", lines)])
stopifnot(length(future) == 1L,
  identical(as.numeric(unlist(sag[sag$Year == 2026, c("Low SSB", "SSB", "High SSB")])), c(.26, .44, .75)))
catch_lines <- strsplit(report[9], "\n")[[1L]]
catch_rows <- strsplit(trimws(catch_lines[grepl("^\\s*(19|20)[0-9]{2}\\s+", catch_lines)]), "[[:space:]]+")
catch_totals <- do.call(rbind, lapply(catch_rows, function(x) as.numeric(x[c(1L, length(x))])))
stopifnot(identical(as.integer(catch_totals[, 1]), 1989:2025),
  identical(catch_totals[, 2], as.numeric(sag$Catches[match(1989:2025, sag$Year)])))

blank <- function(file, n = 1L) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  x <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(x) <- fields
  if ("assessment_id" %in% fields) x$assessment_id <- assessment_id
  x
}
inputs <- blank("inputs.csv", 118L)
inputs$type <- "catch"; inputs$measure <- "total_biomass"; inputs$basis <- "biomass"
inputs$fleet <- "Combined commercial landings"; inputs$sex <- "combined"
inputs$region <- "ICES subareas 1 and 2"; inputs$season <- "annual"
inputs$year <- 1908:2025; inputs$year_basis <- "calendar_year"
inputs$value <- sag$Catches[sag$Year <= 2025]; inputs$unit <- "tonnes"
inputs$source_type <- "official_machine_readable"
inputs$source_reference <- paste(sag_url, "; final advice Table 9; AFWG Table 7.1 for 1989-2025")
inputs$notes <- paste("Official pooled annual landings used as catches in SPiCT, not catch-at-age.",
  "Discards are excluded and assumed negligible. Pre-1989 catches are historical reconstructions by the source; no new age allocation, species adjustment or correction is applied here.")
inputs$notes[inputs$year == 2025] <- paste(inputs$notes[inputs$year == 2025],
  "Preliminary. The source assumes Russian catch of 2069 t equals 2024 because a 2025 value was unavailable; the published combined total is 11435 t.")
output <- function(measure, value, lower, upper, years, type) {
  x <- blank("outputs.csv", length(years))
  x$type <- type; x$measure <- measure; x$year <- years
  x$value <- value; x$lwr <- lower; x$upr <- upper; x$unit <- "ratio"
  x$sex <- "combined"; x$region <- "ICES subareas 1 and 2"; x$season <- "annual"
  x$source_type <- "official_machine_readable"
  x$source_reference <- paste(sag_url, ";", advice_url, "Table 9")
  x$notes <- paste("Reported relative SPiCT state, not absolute SSB or instantaneous F.",
    "Published Low/High bounds are retained; Table 9 does not state their confidence level or construction. No SE is inferred.")
  x
}
outputs <- rbind(
  output("B_over_Bmsy", sag$SSB, sag[["Low SSB"]], sag[["High SSB"]], sag$Year, "biomass"),
  output("F_over_Fmsy", sag$F[1:118], sag[["Low F"]][1:118], sag[["High F"]][1:118], 1908:2025, "mortality"))
outputs$notes[outputs$year == 2026] <- paste(outputs$notes[outputs$year == 2026],
  "Additional reported 2026 biomass state beyond the terminal catch year 2025; not another observed year or the separate 2027-2028 catch scenario. Exact within-year state timing is not specified in Table 9.")
assumption <- function(component, setting, value, reference, notes = "") {
  x <- blank("assumptions.csv"); x$component <- component; x$setting <- setting
  x$value <- value; x$source_reference <- reference; x$notes <- notes; x
}
assumptions <- rbind(
  assumption("assessment", "official_method", "2026 SPiCT surplus-production assessment, ICES category 2, data through 2025", paste(advice_url, "Table 5"), "Replaces the previous age-length Gadget assessment after the February 2026 benchmark. This is reg.27.1-2, not Iceland/Faroes golden redfish reg.27.561214."),
  assumption("population", "stock_components", "Pooled compound stock in subareas 1 and 2, with at least three populations", paste(advice_url, "p. 2"), "Historical catch and survey data cannot distinguish the populations; no morph proportions, sex allocation or extra regional fleets are invented."),
  assumption("catch", "historical_data", "Annual total landings 1908-2025; pre-1989 catch reconstructed by the assessment", paste(advice_url, "Table 5"), "The complete historical series is retained. Misidentification and unallocated Sebastes catches are acknowledged source uncertainties, not authorization for a new correction."),
  assumption("catch", "2025_russian_catch", "2069 t, assumed equal to 2024; total 2025 catch 11435 t", paste(advice_url, "Table 8 footnote"), "This is the official source's imputation, not a new reconstruction by this importer. The most recent catch year is preliminary."),
  assumption("catch", "discards", "Excluded; assumed negligible", paste(advice_url, "Table 5")),
  assumption("index", "input", "Spatiotemporal sdmTMB bottom-trawl biomass index for fish over 30 cm, 1991-2025", paste(advice_url, "Table 5;", report_url, "section 7.1.7"), "The numerical current index, units and observation-precision vector are not recovered. Benchmark descriptions flag a 1994 sampling gap; exact production rows require the native files. The juvenile index is contextual and is not a second fitted stream."),
  assumption("index", "sampling_time", "No verified numerical population-observation fraction recovered", paste(report_url, "section 7.1.7"), "A compiled multi-survey continuous-time biomass observation is not assigned an invented single survey fraction."),
  assumption("population", "production_curve", "Benchmark model 25; production-shape parameter n fixed at 2", paste(framework_url, "golden redfish working document 4c"), "The annual update uses the benchmark baseline with updated data. Benchmark numerical estimates are not substituted for the annual production run."),
  assumption("population", "reported_priors", "r: mu=0.064, sd=0.5; bkfrac: mu=0.9, sd=0.5; sdb: mu=0.05, sd=0.2", paste(framework_url, "working document 4c, final model"), "These are the published prior descriptions. Their exact native coding/scale, and the complete annual configuration, have not been recovered; do not interpret them as verified natural-scale normal distributions."),
  assumption("assessment", "alternative_solution", "About half of benchmark jitter runs reached an alternative high-biomass state", paste(framework_url, "benchmark conclusions and working document 4c"), "The benchmark retained model 25 after expert review; model 31 had high K, low q and much greater biomass. This documented identifiability issue is not resolved by importing the chosen outputs."),
  assumption("assessment", "output_definitions", "B/Bmsy and F/Fmsy, not absolute SSB, Fbar or mortality-at-age", paste(advice_url, "Table 9;", sag_url), "SAG's generic SSB and F columns must be interpreted using their ratio labels. Missing absolute and age-specific outputs are not filled from the older Gadget model."),
  assumption("assessment", "history_forecast_discrepancy", "Historical Table 9 F2025/Fmsy=1.59; scenario Table 1 calls 1.71 status quo F2025/Fmsy", paste(advice_url, "Tables 1, 2 and 9"), "Retain the historical table and scenario assumption separately. The discrepancy is not silently corrected. AFWG gives 4913 t advice while final advice gives 4912 t; the final advice controls."),
  assumption("assessment", "reported_horizon", "Historical catches end in 2025; relative biomass also reported for 2026", paste(advice_url, "Table 9"), "The additional biomass row is not an observed catch year. Exact within-year state timing is unresolved. Forecast scenarios for 2027/2028 are separate from this state import."),
  assumption("assessment", "source_gaps", "Current fitted SPiCT object, exact software version/configuration and numerical survey index remain unavailable", paste(report_url, "chapter 7;", framework_url, "working document 4c"), "Embedded benchmark links point to local temporary HTML files, not public downloads. The public survey-paper code is not verified as the updated production index. No current age-specific catch or biological surfaces are implied by this aggregate assessment."))
assessment <- blank("assessments.csv"); assessment$stock_id <- stock_id
assessment$assessment_year <- 2026; assessment$terminal_year <- 2025; assessment$estimate_terminal_year <- 2026
assessment$assessment_type <- "annual_update_after_benchmark"; assessment$model_family <- "SPiCT"
assessment$model_version <- "Exact annual software version unverified; benchmark model 25 configuration"
assessment$is_current <- assessment$is_applied <- "TRUE"; assessment$framework_year <- 2026
assessment$assessment_url <- advice_url; assessment$framework_url <- framework_url; assessment$data_url <- sag_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Current detailed production SPiCT assessment through 2025, replacing Gadget after the 2026 benchmark. Relative biomass/fishing pressure and original total catches recovered; numerical survey input, exact annual object and absolute/age-specific state outputs not recovered. Additional 2026 relative biomass is a reported state, not a new observation year; exact within-year timing is unresolved. No historical model data are substituted."
stocks <- read.csv(file.path(database, "stocks.csv"), colClasses = "character", na.strings = "", check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, ]
stopifnot(nrow(stock) == 1L, stock$charbonneau_id == "ICES-AFWG_norvegicus_DEEP1,2", stock$scientific_name == "Sebastes norvegicus")
stock$authority_stock_id <- "reg.27.1-2"; stock$common_name <- "Northeast Arctic golden redfish"
stock$area <- "ICES subareas 1 and 2"; stock$region <- "Barents Sea and Norwegian Sea"
stock$ocean <- "Northeast Atlantic"
stock$notes <- "Verified current identity of Charbonneau-Keith ICES-AFWG_norvegicus_DEEP1,2; stable catalogue stock_id retained. The current 2026 assessment is aggregate SPiCT, not the historical Gadget model. Distinct from beaked redfish reb.27.1-2 and golden redfish reg.27.561214. Source review: source_reviews/ices_golden_redfish_northeast_arctic.md."
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
    if (!identical(selected, seq.int(min(selected), max(selected)))) cli::cli_abort("Existing rows for {id} in {file} are not contiguous.")
    replacement <- paste0(replacement, if (endsWith(lines[selected[1L]], "\r")) "\r" else "")
    lines <- c(head(lines, min(selected) - 1L), replacement, tail(lines, length(lines) - max(selected)))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(contents, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(contents))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stock, stock_id)
for (file in c("assessments", "assumptions", "inputs", "outputs")) {
  write_rows(paste0(file, ".csv"), if (file == "assessments") assessment else get(file))
}
cat("Imported Northeast Arctic golden redfish 2026:", nrow(inputs), "inputs,", nrow(assumptions),
  "assumptions,", nrow(outputs), "relative-state outputs; completeness remains partial.\n")
