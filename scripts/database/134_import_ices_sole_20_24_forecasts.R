root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ices_sole_20_24_2025")
database <- file.path(base, "database")
assessment_id <- "ices_sole_20_24_2025"
report_url <- "https://literatur.thuenen.de/digbib_extern/dn069788.pdf"
report_file <- file.path(cache, "WGBFAS_2025.pdf")
outputs_path <- file.path(database, "outputs.csv")
assessments_path <- file.path(database, "assessments.csv")

have_pdftools <- requireNamespace("pdftools", quietly = TRUE)
if (!have_pdftools || !file.exists(report_file)) {
  stop("Install pdftools and cache the WGBFAS 2025 report before importing forecast tables.", call. = FALSE)
}

# Read the forecast tables
pages <- pdftools::pdf_text(report_file)
page_611 <- grep("Table 6.11. Sole 20-24. Input to short term prediction.",
  pages, fixed = TRUE
)
page_612 <- grep("Table 6.12. Sole 20-24.", pages, fixed = TRUE)
if (length(page_611) != 1L || page_611 >= length(pages) || length(page_612) != 1L) {
  stop("Could not uniquely locate WGBFAS 2025 forecast tables 6.11–6.12.", call. = FALSE)
}

lines <- trimws(unlist(strsplit(
  paste(pages[page_611:(page_611 + 1L)], collapse = "\n"),
  "\n", fixed = TRUE
), use.names = FALSE))
forecast_year <- NA_integer_
forecast_rows <- list()
for (line in lines) {
  if (line %in% c("2025", "2026", "2027")) {
    forecast_year <- as.integer(line)
    next
  }
  cells <- strsplit(gsub("[[:space:]]+", " ", line), " ", fixed = TRUE)[[1L]]
  values <- suppressWarnings(as.numeric(cells))
  if (length(values) == 9L && all(is.finite(values)) &&
    values[[1L]] %in% 1:9 && !is.na(forecast_year)) {
    forecast_rows[[length(forecast_rows) + 1L]] <- data.frame(
      year = forecast_year, age = as.integer(values[[1L]]),
      N = values[[2L]], M = values[[3L]], maturity = values[[4L]],
      fraction_F = values[[5L]], fraction_M = values[[6L]],
      stock_weight = values[[7L]], pF = values[[8L]], catch_weight = values[[9L]]
    )
  }
}
forecast <- do.call(rbind, forecast_rows)
forecast_text <- gsub("[[:space:]]+", " ", pages[[page_612]], perl = TRUE)
forecast_value <- function(pattern, label) {
  match <- regmatches(forecast_text, regexec(pattern, forecast_text, perl = TRUE))[[1L]]
  if (length(match) != 2L) stop("Could not parse Table 6.12 value for ", label, ".", call. = FALSE)
  as.numeric(match[[2L]])
}
summary <- c(
  Fbar = forecast_value("Fages[[:space:]]+4.*?\\(2025\\)[[:space:]]+([0-9.]+)", "Fages 4–8"),
  SSB = forecast_value("SSB[[:space:]]*\\(2026\\)[[:space:]]+([0-9.]+)", "SSB 2026"),
  recruitment = forecast_value("Rage1[[:space:]]*\\(2025[^)]*2026\\)[[:space:]]+([0-9.]+)", "Rage1 2025–2026"),
  landings = forecast_value("Projected landings[[:space:]]+([0-9.]+).*?\\(2025\\)", "landings 2025"),
  discards = forecast_value("Projected discards[[:space:]]+([0-9.]+).*?\\(2025\\)", "discards 2025"),
  total_catch = forecast_value("Total catch[[:space:]]*\\(2025\\)[[:space:]]+([0-9.]+)", "total catch 2025")
)
if (nrow(forecast) != 27L || !identical(sort(unique(forecast$year)), 2025:2027) ||
  any(table(forecast$year) != 9L) || !identical(sort(unique(forecast$age)), 1:9) ||
  any(forecast$M != 0.1) ||
  !identical(forecast$maturity[forecast$year == 2025], c(0, 0, rep(1, 7))) ||
  any(forecast$fraction_F != 0 | forecast$fraction_M != 0) ||
  any(forecast$stock_weight != forecast$catch_weight) ||
  !identical(unname(summary), c(0.175, 1353, 915, 204, 6, 210)) ||
  !all(forecast$N[forecast$age == 1L] == 915)) {
  stop("WGBFAS 2025 forecast values do not match the reviewed report tables.", call. = FALSE)
}

# Add the reported forecast outputs
output_schema <- names(utils::read.csv(outputs_path, nrows = 0L,
  colClasses = "character", check.names = FALSE
))
format_value <- function(x) {
  ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
}
output_rows <- function(type, measure, year, value, unit, age = NA_integer_,
                        age_group = "", source_type = "official_table",
                        source_reference, notes) {
  n <- length(value)
  out <- as.data.frame(matrix("", nrow = n, ncol = length(output_schema)),
    stringsAsFactors = FALSE
  )
  names(out) <- output_schema
  out$assessment_id <- assessment_id
  out$type <- rep_len(type, n)
  out$measure <- rep_len(measure, n)
  out$year <- as.character(rep_len(year, n))
  out$age <- ifelse(is.na(rep_len(age, n)), "", as.character(rep_len(age, n)))
  out$age_group <- rep_len(age_group, n)
  out$value <- format_value(rep_len(value, n))
  out$unit <- rep_len(unit, n)
  out$source_type <- rep_len(source_type, n)
  out$source_reference <- rep_len(source_reference, n)
  out$notes <- rep_len(notes, n)
  out
}

forecast_outputs <- rbind(
  output_rows("population", "numbers_at_age", forecast$year, forecast$N,
    "thousand fish", age = forecast$age,
    age_group = ifelse(forecast$age == 9L, "9+", ""),
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.11, PDF pp. 509–510"),
    notes = "Official short-term forecast input N-at-age, not a fitted historical estimate; age 9 is the 9+ group. Values are in thousands and have no reported forecast uncertainty."
  ),
  output_rows("mortality", "fishing_mortality_at_age", forecast$year, forecast$pF,
    "per year", age = forecast$age,
    age_group = ifelse(forecast$age == 9L, "9+", ""),
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.11, PDF pp. 509–510"),
    notes = "Age-specific forecast F as reported in the source pF column; this is a short-term forecast input, not a fitted historical estimate. Rounded values are retained as printed; the separate Fbar forecast is reported in Table 6.12."
  ),
  output_rows("population", "total_numbers", 2025:2027,
    vapply(2025:2027, function(year) sum(forecast$N[forecast$year == year]), numeric(1)),
    "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(report_url, "; Table 6.11, PDF pp. 509–510"),
    notes = "Derived by summing official forecast N-at-age over ages 1–9; age 9 is the 9+ group. No uncertainty is reported for this sum."
  ),
  output_rows("recruitment", "recruitment", 2025:2026, rep(summary[["recruitment"]], 2L),
    "thousand fish", age = 1L,
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Median resampled age-1 recruitment forecast for 2025–2026; no interval is reported. Kept separate from the later 2026 assessment."
  ),
  output_rows("biomass", "SSB", 2026L, summary[["SSB"]], "tonnes",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Official short-term SSB forecast; this 2025-assessment forecast is distinct from the separate 2026 assessment summary. No interval is reported."
  ),
  output_rows("mortality", "Fbar", 2025L, summary[["Fbar"]], "per year",
    age_group = "4-8",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Official status-quo F forecast for ages 4–8; no interval is reported."
  ),
  output_rows("catch", "landings", 2025L, summary[["landings"]], "tonnes",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Projected 2025 landings under status-quo F."
  ),
  output_rows("catch", "discards", 2025L, summary[["discards"]], "tonnes",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Projected 2025 discards using the reported 2020–2024 average discard rate."
  ),
  output_rows("catch", "total_catch", 2025L, summary[["total_catch"]], "tonnes",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.12, PDF p. 511"),
    notes = "Projected 2025 total catch under status-quo F; equals projected landings plus discards."
  )
)
if (!identical(names(forecast_outputs), output_schema) ||
  anyDuplicated(forecast_outputs[c("assessment_id", "type", "measure", "year", "age", "age_group")])) {
  stop("Forecast output rows do not match the canonical output schema or contain duplicates.", call. = FALSE)
}

key_fields <- c("assessment_id", "type", "measure", "fleet", "survey", "sex", "region", "season", "year", "age", "age_group")
key <- function(x) {
  values <- lapply(x[key_fields], function(value) {
    value <- as.character(value)
    value[is.na(value) | !nzchar(value)] <- ""
    value
  })
  do.call(paste, c(values, sep = "\r"))
}
existing_outputs <- utils::read.csv(outputs_path, colClasses = "character",
  na.strings = c("", "NA"), check.names = FALSE, stringsAsFactors = FALSE
)
expected_key <- key(forecast_outputs)
existing_rows <- existing_outputs[existing_outputs$assessment_id == assessment_id, , drop = FALSE]
matched <- match(expected_key, key(existing_rows))
present <- !is.na(matched)
if (any(present) && !all(present)) {
  stop("Only part of the expected forecast output set is already in outputs.csv.", call. = FALSE)
}
if (all(present)) {
  prior <- existing_rows[matched, , drop = FALSE]
  if (max(abs(as.numeric(prior$value) - as.numeric(forecast_outputs$value))) > 1e-8 ||
    !identical(as.character(prior$unit), as.character(forecast_outputs$unit)) ||
    !identical(as.character(prior$source_type), as.character(forecast_outputs$source_type))) {
    stop("Existing forecast output rows differ from WGBFAS 2025 Tables 6.11–6.12.", call. = FALSE)
  }
}

assessment_rows <- utils::read.csv(assessments_path, colClasses = "character",
  na.strings = c("", "NA"), check.names = FALSE, stringsAsFactors = FALSE
)
assessment_index <- which(assessment_rows$assessment_id == assessment_id)
if (length(assessment_index) != 1L || assessment_rows$is_current[assessment_index] != "TRUE" ||
  assessment_rows$inputs_status[assessment_index] != "complete" ||
  assessment_rows$assumptions_status[assessment_index] != "complete") {
  stop("The detailed ICES sole assessment record is missing or has unexpected status.", call. = FALSE)
}
assessment_rows$outputs_status[assessment_index] <- "complete"
assessment_rows$notes[assessment_index] <- paste(
  "Native fitted inputs, age-specific states, fitted observation predictions, and Tables 6.10–6.12 annual and short-term forecast outputs are recovered. Forecast states and catch summaries are retained as reported; forecast uncertainty is not published. The 2026 summary-only update remains separate."
)

write_assessment_file <- function(path, rows) {
  temporary_path <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(temporary_path), add = TRUE)
  utils::write.table(rows, temporary_path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = TRUE, na = "", eol = "\r\n"
  )
  check <- utils::read.csv(temporary_path, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE, stringsAsFactors = FALSE
  )
  if (!isTRUE(all.equal(check, rows, check.attributes = FALSE))) {
    stop("Assessment CSV failed its write-and-read validation.", call. = FALSE)
  }
  if (!file.copy(temporary_path, path, overwrite = TRUE)) {
    stop("Could not replace the assessment CSV after validation.", call. = FALSE)
  }
}

if (identical(Sys.getenv("TINYAM_DATABASE_DRY_RUN"), "true")) {
  action <- if (all(present)) "already match" else "would be added"
  cat("Dry run passed:", nrow(forecast_outputs), "forecast output rows", action,
    "; outputs_status would be complete.\n"
  )
} else {
  if (!all(present)) {
    utils::write.table(forecast_outputs, outputs_path, sep = ",", quote = TRUE,
      row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
    )
  }
  write_assessment_file(assessments_path, assessment_rows)
  action <- if (all(present)) "Verified" else "Imported"
  cat(action, nrow(forecast_outputs), "forecast output rows; outputs_status is complete.\n")
}
