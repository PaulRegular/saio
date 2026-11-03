base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_ices_wgbfas_morhua_bs_25_32", "assessment_2024")
stock_id <- "ck_ices_wgbfas_morhua_bs_25_32"
assessment_id <- "ices_cod_eastern_baltic_2024"
report_url <- "https://doi.org/10.17895/ices.pub.25764978"
report_file <- file.path(cache, "WGBFAS_2024.pdf")
expected_sha256 <- "AE2E5188E7AF13A8A5DB913771E83D23164F22BCD9C5B431101FA94F780C7478"
dry_run <- identical(tolower(Sys.getenv("TINYAM_IMPORT_DRY_RUN")), "true")

if (!requireNamespace("digest", quietly = TRUE) || !requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install digest and pdftools to import the cached report tables.", call. = FALSE)
}
if (!file.exists(report_file)) stop("Missing cached WGBFAS 2024 report.", call. = FALSE)

actual_sha256 <- digest::digest(
  readBin(report_file, "raw", n = file.info(report_file)$size),
  serialize = FALSE,
  algo = "sha256"
)
if (!identical(toupper(actual_sha256), expected_sha256)) {
  stop("Cached WGBFAS 2024 report checksum does not match the reviewed source.", call. = FALSE)
}

text_pages <- pdftools::pdf_text(report_file)
page_lines <- lapply(text_pages, function(x) trimws(strsplit(x, "\n", fixed = TRUE)[[1L]]))
table_page <- function(number) {
  heading <- paste0("^Table[[:space:]]+", gsub("\\.", "\\\\.", number), "[.]")
  found <- which(vapply(page_lines, function(x) any(grepl(heading, x)), logical(1)))
  if (length(found) != 1L) stop("Could not uniquely locate table ", number, ".", call. = FALSE)
  found
}

numeric_token <- function(x) grepl("^[0-9]+([.][0-9]+)?$", x)
year_token <- function(x) grepl("^(19|20)[0-9]{2}$", x)

extract_age_table <- function(number, stop_number = NULL, stop_figure = NULL, n_ages) {
  first_page <- table_page(number)
  rows <- list()
  active <- FALSE
  for (page in seq.int(first_page, length(page_lines))) {
    for (line in page_lines[[page]]) {
      if (!active && grepl(paste0("^Table[[:space:]]+", number, "[.]"), line)) {
        active <- TRUE
        next
      }
      if (active && !is.null(stop_number) &&
        grepl(paste0("^Table[[:space:]]+", stop_number, "[.]"), line)) return(rows)
      if (active && !is.null(stop_figure) && grepl(stop_figure, line, ignore.case = TRUE)) return(rows)
      if (!active) next

      cells <- strsplit(line, "[[:space:]]+")[[1L]]
      if (length(cells) != n_ages + 1L || !year_token(cells[[1L]]) ||
        !all(vapply(cells[-1L], numeric_token, logical(1)))) next
      rows[[length(rows) + 1L]] <- data.frame(
        year = as.integer(cells[[1L]]),
        age = seq_len(n_ages),
        value = as.numeric(cells[-1L]),
        stringsAsFactors = FALSE
      )
    }
  }
  rows
}

extract_summary <- function() {
  first_page <- table_page("2.1.11")
  rows <- list()
  active <- FALSE
  for (page in seq.int(first_page, length(page_lines))) {
    for (line in page_lines[[page]]) {
      if (!active && grepl("^Table[[:space:]]+2[.]1[.]11[.]", line)) {
        active <- TRUE
        next
      }
      if (active && grepl("^Table[[:space:]]+2[.]1[.]12[.]", line)) return(do.call(rbind, rows))
      if (!active) next

      cells <- strsplit(line, "[[:space:]]+")[[1L]]
      if (!length(cells) || !year_token(cells[[1L]])) next
      year <- as.integer(cells[[1L]])
      if (year < 1946L || year > 2024L) next
      values <- cells[-1L]
      if (!length(values) || !all(grepl("^[0-9]+([.][0-9]+)?[*]{0,2}$", values))) next
      values_numeric <- as.numeric(gsub("[*]", "", values))
      row <- data.frame(
        year = year,
        relative_recruitment = NA_real_,
        relative_SSB = NA_real_,
        relative_Fbar = NA_real_,
        stringsAsFactors = FALSE
      )
      if (length(values_numeric) == 1L) {
        row$relative_recruitment <- values_numeric[[1L]]
      } else if (length(values_numeric) == 4L) {
        row$relative_recruitment <- values_numeric[[1L]]
        row$relative_SSB <- values_numeric[[2L]]
        row$relative_Fbar <- values_numeric[[4L]]
      } else if (length(values_numeric) == 5L) {
        row$relative_recruitment <- values_numeric[[1L]]
        row$relative_SSB <- values_numeric[[2L]]
        row$relative_Fbar <- values_numeric[[5L]]
      } else {
        next
      }
      rows[[length(rows) + 1L]] <- row
    }
  }
  stop("Could not find the end of Table 2.1.11.", call. = FALSE)
}

age_matrix <- function(rows, expected_years, expected_ages, label) {
  if (!length(rows)) stop("No rows were extracted from ", label, ".", call. = FALSE)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out <- out[order(out$year, out$age), , drop = FALSE]
  if (!identical(sort(unique(out$year)), expected_years) ||
    !identical(sort(unique(out$age)), expected_ages) ||
    nrow(out) != length(expected_years) * length(expected_ages) ||
    any(!is.finite(out$value)) || any(out$value < 0)) {
    stop("Unexpected year-age coverage or values in ", label, ".", call. = FALSE)
  }
  out
}

n_at_age <- age_matrix(
  extract_age_table("2.1.12", stop_number = "2.1.13", n_ages = 8L),
  1946:2024, 1:8, "Table 2.1.12"
)
f_at_age <- age_matrix(
  extract_age_table("2.1.13", stop_figure = "^Figure[[:space:]]+2[.]1[.]2", n_ages = 14L),
  1946:2023, 1:14, "Table 2.1.13"
)
summary <- extract_summary()
summary <- summary[order(summary$year), , drop = FALSE]
if (!identical(summary$year, 1946:2024) ||
  sum(!is.na(summary$relative_recruitment)) != 79L ||
  sum(!is.na(summary$relative_SSB)) != 78L ||
  sum(!is.na(summary$relative_Fbar)) != 78L) {
  stop("Unexpected coverage in Table 2.1.11.", call. = FALSE)
}
if (f_at_age$value[f_at_age$year == 2023L & f_at_age$age == 11L] != 0.4) {
  stop("The 2023 age-11 F value no longer matches the printed report table.", call. = FALSE)
}

number_string <- function(x) ifelse(is.na(x), "", format(x, digits = 15, scientific = FALSE, trim = TRUE))
blank <- function(header, n) {
  out <- as.data.frame(lapply(header, function(x) rep("", n)), stringsAsFactors = FALSE)
  names(out) <- header
  out
}
output_header <- names(utils::read.csv(file.path(database, "outputs.csv"), nrows = 0L, check.names = FALSE))
output_rows <- function(type, measure, year, value, unit, source_table, age = NA_integer_,
                        age_group = "", notes = "", region = "Eastern Baltic cod, ICES SDs 24-32") {
  out <- blank(output_header, length(value))
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- number_string(rep_len(year, length(value)))
  out$age <- number_string(rep_len(age, length(value)))
  out$age_group <- rep_len(age_group, length(value))
  out$value <- number_string(value)
  out$unit <- unit
  out$sex <- "combined"
  out$region <- region
  out$season <- "annual"
  out$source_type <- "official_table"
  out$source_reference <- paste("ICES WGBFAS 2024, Table", source_table, report_url)
  out$notes <- notes
  out
}

outputs <- rbind(
  output_rows(
    "population", "numbers_at_age", n_at_age$year, n_at_age$value,
    "thousand fish", "2.1.12", n_at_age$age,
    notes = paste(
      "Reported stock numbers at the beginning of the year, unchanged from Table 2.1.12.",
      "The report model has ages 0-15+, but this table reports only ages 1-8; age 8 is not identified as a plus group.",
      "No standard errors or intervals are tabulated."
    )
  ),
  output_rows(
    "mortality", "fishing_mortality_at_age", f_at_age$year, f_at_age$value,
    "per year", "2.1.13", f_at_age$age,
    notes = paste(
      "Reported annual fishing mortality at age, unchanged from Table 2.1.13.",
      "The report model has ages 0-15+, but this table reports only ages 1-14; no plus group is shown.",
      "The 2023 age-11 value is printed as 0.4, unlike the adjacent cells; it is retained as printed and should be treated cautiously.",
      "No standard errors or intervals are tabulated."
    )
  ),
  output_rows(
    "recruitment", "relative_recruitment", summary$year[!is.na(summary$relative_recruitment)],
    summary$relative_recruitment[!is.na(summary$relative_recruitment)],
    "ratio to time-series average", "2.1.11",
    notes = paste(
      "Reported recruitment relative to the time-series average; not an absolute recruitment estimate.",
      "The table prints ** on 2023 and 2024 values without defining the marker; the numeric values are preserved and flagged.",
      "No standard errors or intervals are tabulated."
    )
  ),
  output_rows(
    "biomass", "relative_SSB", summary$year[!is.na(summary$relative_SSB)],
    summary$relative_SSB[!is.na(summary$relative_SSB)],
    "ratio to time-series average", "2.1.11",
    notes = "Reported SSB relative to the time-series average; not an absolute biomass estimate. No standard errors or intervals are tabulated."
  ),
  output_rows(
    "mortality", "relative_Fbar", summary$year[!is.na(summary$relative_Fbar)],
    summary$relative_Fbar[!is.na(summary$relative_Fbar)],
    "ratio to time-series average", "2.1.11", age_group = "4-6",
    notes = "Reported relative fishing mortality for ages 4-6; not an absolute Fbar estimate. No standard errors or intervals are tabulated."
  )
)

assumption_header <- names(utils::read.csv(file.path(database, "assumptions.csv"), nrows = 0L, check.names = FALSE))
assumption <- function(component, setting, value, source_reference, notes = "") {
  out <- blank(assumption_header, 1L)
  out$assessment_id <- assessment_id
  out$component <- component
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- notes
  out
}
assumptions <- do.call(rbind, list(
  assumption(
    "assessment", "model_configuration",
    "Stock Synthesis 3.30; one-area quarterly, length-based model; both sexes combined; age range 0-15+",
    paste(report_url, "section 2.1.5.1"),
    "Ages are inferred from length using a von Bertalanffy growth curve; age 15+ is the model plus group."
  ),
  assumption(
    "population", "recruitment_and_timing",
    "Beverton-Holt stock-recruitment relationship; steepness 0.99; recruitment process SD 0.6; spawning time month 5; settlement time month 8",
    paste(report_url, "section 2.1.5.1"),
    "Main recruitment deviations were estimated for 1950-2022."
  ),
  assumption(
    "mortality", "natural_mortality",
    "Age-dependent M; historical age pattern estimated for 1946-1999; age break 5.5 estimated with annual deviations for 2000-2023; other age breaks fixed",
    paste(report_url, "section 2.1.5.2; Table 2.1.9"),
    "The report states that age breakpoints 0.5, 1.5, 5.5, and 15.5 were used."
  ),
  assumption(
    "index", "index_fleets",
    "Nine indices: BITS Q1 and Q4, two historical trawl surveys, three commercial CPUE series, an egg-production SSB index, and a larval abundance index",
    paste(report_url, "section 2.1.4.4"),
    "The report summarizes the series and fitted uncertainty assumptions but does not publish all original annual observation values in machine-readable form."
  ),
  assumption(
    "assessment", "input_data_recovery",
    "Original catches, age/length compositions, survey observations, and full biological input surfaces were not recovered",
    paste(report_url, "Table 2.1.8; section 2.1.4"),
    "The report gives input types and coverage but not the complete numerical series used by the model. No input observations are fabricated or reconstructed from fitted quantities."
  ),
  assumption(
    "assessment", "reported_output_coverage",
    "N-at-age is tabulated for ages 1-8 through 2024; F-at-age for ages 1-14 through 2023; relative recruitment, SSB, and Fbar ages 4-6 are tabulated separately",
    paste(report_url, "Tables 2.1.11-2.1.13"),
    "The age-specific tables omit model ages 0 and 15+ and provide no age-specific uncertainty. Relative aggregate measures are not absolute values."
  )
))

assessment_header <- names(utils::read.csv(file.path(database, "assessments.csv"), nrows = 0L, check.names = FALSE))
assessment <- blank(assessment_header, 1L)
assessment[1L, ] <- list(
  assessment_id = assessment_id,
  stock_id = stock_id,
  assessment_year = 2024,
  terminal_year = 2024,
  estimate_terminal_year = 2024,
  assessment_type = "update assessment",
  model_family = "Stock Synthesis",
  model_version = "3.30",
  is_current = "TRUE",
  is_applied = "TRUE",
  framework_year = 2019,
  assessment_url = report_url,
  framework_url = "https://doi.org/10.17895/ices.pub.4984",
  data_url = "",
  model_url = "",
  repository_url = "",
  assumptions_status = "partial",
  inputs_status = "not_started",
  outputs_status = "partial",
  notes = paste(
    "Latest recovered age-structured output surface for this stock.",
    "The model terminal year is 2024 to include BITS Q1 data; 2024 catch was assumed equal to 2023 catch.",
    "The 2025 WGBFAS report republishes the age-specific tables as not updated in 2024, and no newer numerical N/F-at-age tables were found.",
    "The 2026 advice uses a survey-index trend method and is recorded in the source review; it does not provide an age-structured output surface.",
    "Original observation inputs are not recovered, so this record is not ready for tinyAM fitting."
  )
)
assessment <- assessment[, assessment_header, drop = FALSE]

assessment_file <- file.path(database, "assessments.csv")
assumptions_file <- file.path(database, "assumptions.csv")
outputs_file <- file.path(database, "outputs.csv")
existing_assessments <- utils::read.csv(assessment_file, stringsAsFactors = FALSE, check.names = FALSE)
existing_outputs <- utils::read.csv(outputs_file, skipNul = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
if (assessment_id %in% existing_assessments$assessment_id ||
  any(existing_outputs$assessment_id == assessment_id)) {
  stop("Assessment outputs already exist; refusing to duplicate the import.", call. = FALSE)
}

cat(
  "Verified WGBFAS 2024 output extraction:", nrow(n_at_age), "N-at-age cells;",
  nrow(f_at_age), "F-at-age cells;", sum(!is.na(summary$relative_recruitment)),
  "relative recruitment;", sum(!is.na(summary$relative_SSB)), "relative SSB; and",
  sum(!is.na(summary$relative_Fbar)), "relative Fbar cells.\n"
)
if (dry_run) {
  cat("Dry run: no database files changed.\n")
} else {
  write.table(assessment, assessment_file, sep = ",", append = TRUE, row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "\r\n", fileEncoding = "UTF-8")
  write.table(assumptions, assumptions_file, sep = ",", append = TRUE, row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "\r\n", fileEncoding = "UTF-8")
  write.table(outputs, outputs_file, sep = ",", append = TRUE, row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", eol = "\r\n", fileEncoding = "UTF-8")
  cat("Added the partial Eastern Baltic cod 2024 assessment record and outputs.\n")
}
