# Import the published production-assessment summary, not the constant-M candidate.
base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_dfo_nefsc_ferruginea_gb")
assessment_id <- "nefsc_yellowtail_georges_bank_2025"
stock_id <- "ck_dfo_nefsc_ferruginea_gb"
report_url <- "https://d23h0vhsm26o6d.cloudfront.net/Georges-Bank-Yellowtail-Flounder-Assessment-Update-2025.pdf"
framework_url <- "https://www.fisheries.noaa.gov/s3/2024-12/Panel-Summary-Report_Yellowtail-Flounder_508_final_12_12_2024.pdf"
adoption_url <- "https://d23h0vhsm26o6d.cloudfront.net/260423_Groundfish_FW72_SIR_FINAL-Submission.pdf"
report_file <- file.path(cache, "NOAA_GB_yellowtail_2025.pdf")
review_file <- file.path(cache, "NEFMC_yellowtail_peer_review_2024.pdf")
adoption_file <- file.path(cache, "NEFMC_FW72_SIR_2026.pdf")
required <- c(report_file, review_file, adoption_file)
if (!all(file.exists(required))) cli::cli_abort("Cache the assessment, final peer review and adoption sources before importing.")
sha256 <- function(path) digest::digest(readBin(path, "raw", n = file.info(path)$size),
  algo = "sha256", serialize = FALSE)
expected <- c(
  "508035e37e9467d4de0ba8baab3e7be519ea696be4ce1b0fd7be4f1130d44687",
  "be557aec7f5b8e5a823acbe6f8917a857ffd519a63b086a8b6ec5e995948e707",
  "d961314f6fd146694956a50e8f128277314fe1d103aaa8a24c1236ccd1c72c9c"
)
if (!identical(unname(vapply(required, sha256, character(1))), expected)) {
  cli::cli_abort("A reviewed source changed; verify the assessment identity before importing.")
}
pages <- pdftools::pdf_text(report_file)
lines <- trimws(strsplit(pages[[2L]], "\n", fixed = TRUE)[[1L]])
table_row <- function(label) {
  found <- lines[startsWith(lines, label)]
  if (length(found) != 1L) cli::cli_abort("Expected one Table 1 row for {label}.")
  text <- trimws(substring(found, nchar(label) + 1L))
  values <- suppressWarnings(as.numeric(gsub(",", "", strsplit(text, "[[:space:]]+")[[1L]], fixed = TRUE)))
  if (length(values) != 10L || any(!is.finite(values))) {
    cli::cli_abort("Could not recover ten annual values for {label}.")
  }
  values
}
years <- 2015:2024
ssb <- table_row("Spawning Stock Biomass")
f_full <- table_row("FF ull")
recruitment <- table_row("Recruits (age 1)")
catch <- table_row("Catch for Assessment")
stopifnot(identical(ssb, c(3324, 2330, 1401, 910, 747, 445, 841, 614, 633, 713)),
  tail(f_full, 1L) == 0.017, tail(recruitment, 1L) == 534, tail(catch, 1L) == 12)
# The source total is rounded independently of the four reported components.
parts <- rbind(table_row("US landings"), table_row("US discards"),
  table_row("Canadian landings"), table_row("Canadian discards"))
stopifnot(max(abs(colSums(parts) - catch)) <= 1)

read_db <- function(file) read.csv(file.path(database, file),
  colClasses = "character", na.strings = "", check.names = FALSE)
blank <- function(file, n) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  out <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(out) <- fields
  if ("assessment_id" %in% fields) out$assessment_id <- assessment_id
  out
}
assessment <- blank("assessments.csv", 1)
assessment$stock_id <- stock_id
assessment$assessment_year <- "2025"
assessment$terminal_year <- "2024"
assessment$estimate_terminal_year <- "2028"
assessment$assessment_type <- "management_track"
assessment$model_family <- "WHAM"
assessment$model_version <- "2024 research-track age-based-M model, updated through 2024; software revision not reported"
assessment$is_current <- "FALSE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2024"
assessment$assessment_url <- report_url
assessment$framework_url <- framework_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- paste("Latest production assessment; the published unit report retains a draft-for-peer-review label.",
  "Final Framework 72 documentation confirms the 2025 assessment was approved for management.",
  "Only 2015-2024 aggregate catches and annual summary outputs plus 2025-2028 projections are recovered here.",
  "The cached 2024 constant-M candidate is not the selected age-based-M model and supplies no observations or outputs to this record.",
  "Summary-only record, not marked current detailed; no detailed production run is yet populated for this stock.")

assumption <- function(component, setting, value, reference, notes = "") {
  out <- blank("assumptions.csv", 1)
  out$component <- component; out$setting <- setting; out$value <- value
  out$source_reference <- reference; out$notes <- notes
  out
}
assumptions <- rbind(
  assumption("assessment", "production_status", "2025 WHAM update approved for management",
    adoption_url, "Framework 72 final submission, Section 4.1, confirms management-track peer review approval; preserve the draft label on the unit report."),
  assumption("population", "recruitment_age", "1", paste0(report_url, "; Table 1")),
  assumption("F", "reported_F_definition", "Ffull on fully selected ages 4-6",
    paste0(report_url, "; Table 1"), "Not relabelled as population-weighted Fbar or single-age F."),
  assumption("N", "recruitment_model", "Beverton-Holt with bottom-water-temperature effects on recruitment deviations",
    paste0(report_url, "; p. 1"), "Projection temperature averages conditions since 2009; historical covariate values are not tabulated here."),
  assumption("F", "selectivity_dynamics", "Fishery selectivity correlation structure continued in projections",
    paste0(report_url, "; p. 1"), "Full 2025 fitted selectivity configuration was not recovered."),
  assumption("M", "natural_mortality", "Age-based M selected by the 2024 peer review",
    framework_url, "The earlier constant-M candidate is superseded. Exact numerical production M values are not recovered and are not replaced with candidate values."),
  assumption("biology", "maturity_revision", "Maturity ogive updated in the 2025 assessment",
    paste0(report_url, "; p. 2"), "The report describes a small effect on estimates; the numerical ogive is not provided. 2024 candidate maturity must not fill this gap."),
  assumption("index", "survey_coverage", "NEFSC spring and fall; DFO spring",
    paste0(report_url, "; pp. 2-3; 2024 framework"), "2023 NEFSC spring survey omitted because it sampled only during daylight; calibration unavailable for the 2022 DFO survey."),
  assumption("index", "survey_timing", "unknown", paste0(report_url, "; pp. 2-3"),
    "Exact within-year fractions were not recovered for this production run."),
  assumption("assessment", "retrospective_adjustment", "Native annual estimates and rho-adjusted 2024 values reported separately",
    paste0(report_url, "; p. 2"), "Seven-year Mohn rho: SSB=0.042, F=0.007; adjusted SSB=684 t and F=0.017, within the stated approximate 90% regions."))

inputs <- blank("inputs.csv", 10)
inputs$type <- "catch"; inputs$measure <- "total_biomass"; inputs$basis <- "biomass"
inputs$fleet <- "Combined US-Canada commercial catch"
inputs$year <- years; inputs$year_basis <- "calendar_year"
inputs$value <- catch; inputs$unit <- "tonnes"
inputs$source_type <- "official_table"
inputs$source_reference <- paste0(report_url, "; Table 1, Catch for Assessment")
inputs$notes <- "Native combined catch total, independently rounded in the report. Component landings/discards are not additional fitted fleets. Age compositions are unavailable; no catch-at-age is invented."
output <- function(type, measure, value, unit, year = years, age = "", group = "", notes = "", lwr = "", upr = "", reference = "Table 1", source_type = "official_table") {
  out <- blank("outputs.csv", length(value))
  out$type <- type; out$measure <- measure; out$value <- value; out$unit <- unit
  out$year <- year; out$age <- age; out$age_group <- group
  out$lwr <- lwr; out$upr <- upr
  out$source_type <- source_type; out$source_reference <- paste0(report_url, "; ", reference)
  out$notes <- notes
  out
}
outputs <- rbind(
  output("biomass", "SSB", ssb, "tonnes", notes = "Unadjusted annual model estimate as reported; mean/median convention is not stated. Only the 2024 approximate 90% confidence region is reported in text; no SE is inferred.",
    lwr = c(rep("", 9), "491"), upr = c(rep("", 9), "1034"),
    reference = "Table 1; p. 2 for terminal approximate 90% confidence region"),
  output("mortality", "Ffull", f_full, "per year", group = "4-6",
    notes = "Reported Ffull for fully selected ages 4-6; averaging convention not resolved. Only the 2024 approximate 90% confidence region is provided; no SE is inferred.",
    lwr = c(rep("", 9), "0.012"), upr = c(rep("", 9), "0.025"),
    reference = "Table 1; p. 2 for terminal approximate 90% confidence region"),
  output("recruitment", "recruitment", recruitment, "thousand fish", age = 1,
    notes = "Unadjusted reported age-1 recruitment; no annual uncertainty is tabulated."),
  output("biomass", "SSB_rho_adjusted", 684, "tonnes", year = 2024,
    notes = "Retrospectively adjusted terminal estimate, distinct from native annual SSB=713 t; no separate interval reported.", reference = "p. 2, retrospective-pattern discussion", source_type = "official_document"),
  output("mortality", "Ffull_rho_adjusted", 0.017, "per year", year = 2024, group = "4-6",
    notes = "Retrospectively adjusted terminal Ffull; reported rounding matches unadjusted Ffull but is kept distinct.", reference = "p. 2, retrospective-pattern discussion", source_type = "official_document"),
  output("biomass", "SSB", c(655, 646, 654, 699), "tonnes", year = 2025:2028,
    lwr = c(230, 190, 180, 181), upr = c(1860, 2198, 2374, 2707),
    notes = "Projection, not a fitted annual estimate. 2025 catch assumed 22 t; 2026-2028 fish at Fmsy. Interval level and construction are not stated in Table 3; no SE inferred.", reference = "Table 3"),
  output("mortality", "Ffull", c(0.034, 0.09, 0.09, 0.09), "per year", year = 2025:2028, group = "4-6",
    notes = "Projection, not a fitted annual estimate. 2025 catch assumed 22 t; 2026-2028 fish at Fmsy.", reference = "Table 3"))

stocks <- read_db("stocks.csv")
at <- which(stocks$stock_id == stock_id)
stopifnot(length(at) == 1L, stocks$charbonneau_id[at] == "DFO-NEFSC_ferruginea_GB")
stocks$authority[at] <- "NOAA-NEFSC / DFO"
stocks$common_name[at] <- "Georges Bank yellowtail flounder"
stocks$area[at] <- "Georges Bank, combined US-Canada stock"
stocks$region[at] <- "Georges Bank"
stocks$ocean[at] <- "Northwest Atlantic"
stocks$notes[at] <- paste("Charbonneau-Keith DFO-NEFSC_ferruginea_GB; latest 2025 production assessment uses WHAM with the 2024 age-based-M framework.",
  "The earlier constant-M candidate is not the official model. Summary records are partial; missing age inputs/outputs are not borrowed from candidate runs.")

write_rows <- function(file, x, id = assessment_id) {
  path <- file.path(database, file)
  text <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  selected <- which(startsWith(lines, paste0('"', id, '",')))
  stopifnot(identical(names(x), names(read.csv(path, nrows = 0))))
  tmp <- tempfile(tmpdir = database)
  on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "", fileEncoding = "UTF-8")
  replacement <- readLines(tmp, encoding = "UTF-8", warn = FALSE)
  if (length(selected)) {
    if (length(selected) != nrow(x)) cli::cli_abort("Existing {file} coverage differs; review before replacing.")
    lines[selected] <- paste0(replacement, ifelse(endsWith(lines[selected], "\r"), "\r", ""))
  } else lines <- c(lines, replacement)
  bytes <- charToRaw(paste0(paste(lines, collapse = "\n"), if (endsWith(text, "\n")) "\n" else ""))
  if (identical(bytes, charToRaw(text))) return(invisible(NULL))
  writeBin(bytes, tmp)
  if (!file.copy(tmp, path, overwrite = TRUE)) cli::cli_abort("Could not write {file}.")
}
write_rows("stocks.csv", stocks[at, ], stock_id)
write_rows("assessments.csv", assessment)
write_rows("assumptions.csv", assumptions)
write_rows("inputs.csv", inputs)
write_rows("outputs.csv", outputs)
cat("Imported Georges Bank yellowtail 2025: 10 aggregate catch inputs,",
  nrow(assumptions), "assumptions and", nrow(outputs), "outputs. Source statuses remain partial.\n")
