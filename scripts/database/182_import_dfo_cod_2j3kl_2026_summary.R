root <- "."
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "dfo_cod_2j3kl_2025")
assessment_id <- "dfo_cod_2j3kl_2026_summary"
report_file <- "Fs70-6-2026-030-eng.pdf"
report_url <- "https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-030-eng.pdf"
framework_url <- "https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-6/Fs70-6-2024-046-eng.pdf"
report_hash <- "ED7AC40F67775C91B32D64FA03252C0263B223EC731869E335CCB06286E62A80"
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

report_path <- file.path(cache, report_file)
if (!file.exists(report_path)) {
  cli::cli_abort("The cached DFO 2026/030 report is missing: {report_path}")
}
actual_hash <- digest::digest(readBin(report_path, "raw", n = file.info(report_path)$size),
  serialize = FALSE, algo = "sha256")
if (!identical(toupper(actual_hash), report_hash)) {
  cli::cli_abort("The cached DFO 2026/030 report does not match its reviewed SHA-256.")
}
report_text <- paste(pdftools::pdf_text(report_path), collapse = "\n")
if (!grepl("Table 1. Northern cod SSB, recruitment", report_text, fixed = TRUE) ||
  !grepl("Table 2. Reported catch, including bycatch", report_text, fixed = TRUE)) {
  cli::cli_abort("The cached PDF does not contain the reviewed summary tables.")
}

blank_rows <- function(file, id, n) {
  header <- readLines(file.path(database, file), n = 1L, warn = FALSE,
    encoding = "UTF-8")
  fields <- names(read.csv(text = header, nrows = 0L, check.names = FALSE))
  out <- as.data.frame(matrix("", nrow = n, ncol = length(fields)),
    stringsAsFactors = FALSE)
  names(out) <- fields
  out$assessment_id <- id
  out
}

catch_years <- 2016:2025
divisions <- c("2J", "3K", "3L")
catch_by_division <- rbind(
  c(216, 313, 281, 444, 1129, 1314, 1836, 2481, 2960, 5437),
  c(5273, 6335, 4436, 4819, 3767, 4387, 5527, 5611, 6297, 13370),
  c(4618, 6232, 4744, 5241, 5364, 5276, 5112, 4990, 6448, 9438)
)
stopifnot(nrow(catch_by_division) == 3L, ncol(catch_by_division) == 10L,
  all(rowSums(catch_by_division) > 0))
inputs <- do.call(rbind, lapply(seq_along(divisions), function(i) {
  out <- blank_rows("inputs.csv", assessment_id, length(catch_years))
  out$type <- "catch"
  out$measure <- "total_biomass"
  out$basis <- "biomass"
  out$fleet <- "Reported catch including bycatch"
  out$region <- paste("NAFO Division", divisions[i])
  out$year <- catch_years
  out$year_basis <- "calendar_year"
  out$value <- catch_by_division[i, ]
  out$unit <- "t"
  out$source_type <- "official_table"
  out$source_reference <- paste(report_url, "Table 2, p. 6", sep = "; ")
  out$transformation <- "Direct transcription by NAFO division; no aggregate total row added."
  out$notes <- paste(
    "Reported catch including bycatch. The 2025 value is provisional.",
    "This summary table does not document the complete fitted catch input vector or model fleet mapping."
  )
  out
}))

table1 <- data.frame(
  year = 2022:2026,
  ssb = c(284, 291, 338, 449, 542),
  ssb_lwr = c(198, 217, 268, 363, 423),
  ssb_upr = c(410, 389, 426, 554, 696),
  recruitment = c(0.83, 1.00, 1.02, 1.15, 1.23),
  recruitment_lwr = c(0.39, 0.50, 0.50, 0.57, 0.61),
  recruitment_upr = c(1.78, 2.03, 2.07, 2.31, 2.45),
  Mbar = c(0.39, 0.31, 0.22, 0.26, NA_real_),
  Mbar_lwr = c(0.22, 0.16, 0.13, 0.13, NA_real_),
  Mbar_upr = c(0.71, 0.61, 0.39, 0.49, NA_real_),
  Fbar = c(0.03, 0.03, 0.03, 0.04, NA_real_),
  Fbar_lwr = c(0.02, 0.02, 0.03, 0.03, NA_real_),
  Fbar_upr = c(0.04, 0.04, 0.05, 0.06, NA_real_)
)

make_output <- function(type, measure, values, lower, upper, unit,
                         age = "", age_group = "", note) {
  keep <- !is.na(values)
  out <- blank_rows("outputs.csv", assessment_id, sum(keep))
  out$type <- type
  out$measure <- measure
  out$year <- table1$year[keep]
  if (length(age)) out$age <- age
  if (length(age_group)) out$age_group <- age_group
  out$value <- values[keep]
  out$lwr <- lower[keep]
  out$upr <- upper[keep]
  out$unit <- unit
  out$source_type <- "official_table"
  out$source_reference <- paste(report_url, "Table 1, p. 5", sep = "; ")
  out$notes <- note
  out
}
summary_note <- paste(
  "Transcribed from the 2026 summary assessment and kept separate from the 2025 detailed run.",
  "The report gives lower and upper 95% confidence limits; it does not state a separate standard error."
)
outputs <- rbind(
  make_output("biomass", "SSB", table1$ssb, table1$ssb_lwr, table1$ssb_upr,
    "kt", note = paste(summary_note, "Table 1 does not specify the point-estimator convention.")),
  make_output("recruitment", "recruitment", table1$recruitment,
    table1$recruitment_lwr, table1$recruitment_upr, "billion fish", age = "0",
    note = paste(summary_note, "Recruitment is age 0.")),
  make_output("mortality", "Mbar", table1$Mbar, table1$Mbar_lwr,
    table1$Mbar_upr, "yr-1", age_group = "5+",
    note = paste(summary_note, "Population-weighted average natural mortality for ages 5+; 2026 is not yet estimated.")),
  make_output("mortality", "Fbar", table1$Fbar, table1$Fbar_lwr,
    table1$Fbar_upr, "yr-1", age_group = "5+",
    note = paste(summary_note, "Population-weighted average fishing mortality for ages 5+; 2026 is not yet estimated."))
)
stopifnot(nrow(inputs) == 30L, nrow(outputs) == 18L,
  sum(outputs$measure == "SSB") == 5L,
  sum(outputs$measure == "recruitment") == 5L,
  sum(outputs$measure == "Mbar") == 4L,
  sum(outputs$measure == "Fbar") == 4L,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2026] == 542,
  outputs$lwr[outputs$measure == "SSB" & outputs$year == 2026] == 423,
  outputs$upr[outputs$measure == "SSB" & outputs$year == 2026] == 696)

assessment <- blank_rows("assessments.csv", assessment_id, 1L)
assessment$stock_id <- "dfo_cod_2j3kl"
assessment$assessment_year <- "2026"
assessment$terminal_year <- "2025"
assessment$estimate_terminal_year <- "2026"
assessment$assessment_type <- "annual_summary"
assessment$model_family <- "xteNCAM"
assessment$model_version <- "2026 assessment under the 2023 framework; exact production version unavailable"
assessment$is_current <- "FALSE"
assessment$is_applied <- "TRUE"
assessment$framework_year <- "2023"
assessment$assessment_url <- report_url
assessment$framework_url <- framework_url
assessment$assumptions_status <- "partial"
assessment$inputs_status <- "partial"
assessment$outputs_status <- "partial"
assessment$notes <- paste(
  "Summary-only 2026 assessment to 2026; annual aggregate estimates and reported catches are retained separately.",
  "The 2025 detailed assessment remains the selected detailed record (is_current=TRUE).",
  "This summary contains no complete catch-at-age vector, age-specific N/F/M surfaces, or production model files.",
  "Do not blend summary estimates with the 2025 detailed run."
)

write_rows <- function(file, new_rows) {
  path <- file.path(database, file)
  original <- readLines(path, warn = FALSE, encoding = "UTF-8")
  id_rows <- grepl(paste0('^"', assessment_id, '"'), original)
  if (any(id_rows[-1L])) {
    writeLines(original[c(TRUE, !id_rows[-1L])], path, useBytes = TRUE)
  }
  write.table(new_rows, file = path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = "",
    qmethod = "double", fileEncoding = "UTF-8")
}

if (dry_run) {
  cat("Validated DFO 2026/030 summary source and prepared", nrow(inputs),
    "catch rows and", nrow(outputs), "aggregate output rows.\n")
} else {
  write_rows("assessments.csv", assessment)
  write_rows("inputs.csv", inputs)
  write_rows("outputs.csv", outputs)
  cat("Imported DFO 2026/030 as a separate summary-only assessment:",
    nrow(inputs), "catch rows and", nrow(outputs), "aggregate output rows.\n")
}
