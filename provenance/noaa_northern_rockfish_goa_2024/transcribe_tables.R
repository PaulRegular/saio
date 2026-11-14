root <- "."
cache <- file.path(root, "source_cache", "noaa_northern_rockfish_goa_20261111")
pdf_path <- file.path(cache, "GOA_Northern_Rockfish_2024_SAFE.pdf")
repository_model_path <- file.path(cache, "2024__R__model_runs.R")
transcription_dir <- file.path(root, "provenance",
  "noaa_northern_rockfish_goa_2024", "transcriptions")

.libPaths(c(file.path(root, "source_cache", "R-library"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("Install pdftools to read the cached NOAA SAFE.", call. = FALSE)
}
if (!file.exists(pdf_path) || !file.exists(repository_model_path)) {
  stop("The pinned 2024 SAFE and AFSC model script must be cached.", call. = FALSE)
}

pages <- pdftools::pdf_text(pdf_path)
lines <- unlist(strsplit(pages, "\n", fixed = TRUE), use.names = FALSE)
lines <- sub("\r$", "", lines)

table_lines <- function(start_text, end_text = NULL) {
  start <- grep(start_text, lines, fixed = TRUE)[1]
  if (is.na(start)) stop("Source table not found: ", start_text, call. = FALSE)
  if (is.null(end_text)) return(lines[start:length(lines)])
  remaining <- seq.int(start + 1L, length(lines))
  ends <- grep(end_text, lines[remaining], fixed = TRUE)
  if (!length(ends)) return(lines[start:length(lines)])
  lines[start:(start + ends[1L] - 1L)]
}

numbers <- function(x) {
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

parse_composition <- function(start_text, dimension, header_label, end_text) {
  section <- table_lines(start_text, end_text)
  header_rows <- which(startsWith(trimws(section), header_label) &
    grepl("19[0-9]{2}|20[0-9]{2}", section))
  if (length(header_rows) != 1L) {
    stop("Expected one composition header for ", start_text, call. = FALSE)
  }
  header <- section[header_rows]
  years <- as.integer(regmatches(header,
    gregexpr("(19|20)[0-9]{2}", header, perl = TRUE))[[1]])
  if (!length(years)) stop("No years in table header.", call. = FALSE)

  sample_rows <- grep("^\\s*Sample size", section)
  if (length(sample_rows) != 1L) {
    stop("Expected one sample-size row for ", start_text, call. = FALSE)
  }
  sample_tokens <- strsplit(trimws(section[sample_rows]), "\\s+")[[1]]
  sample_values <- numbers(sample_tokens[-c(1L, 2L)])
  if (length(sample_values) != length(years)) {
    stop("Sample sizes do not match table years.", call. = FALSE)
  }

  rows <- section[seq.int(header_rows + 1L, sample_rows - 1L)]
  rows <- rows[grepl("^\\s*[0-9]{1,2}\\s+0\\.[0-9]{3}", rows)]
  parsed <- lapply(rows, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1]]
    value <- numbers(tokens[-1L])
    if (length(value) != length(years)) {
      stop("Composition row has an unexpected number of cells.", call. = FALSE)
    }
    data.frame(
      year = years,
      bin = as.integer(tokens[1L]),
      value = value,
      stringsAsFactors = FALSE
    )
  })
  composition <- do.call(rbind, parsed)
  sample_table <- data.frame(year = years, sample_size_printed = sample_values)

  list(composition = composition, sample = sample_table)
}

parse_catch <- function() {
  section <- table_lines("Table 10-3. Commercial catch", "Table 10-4.")
  header_idx <- grep("Year.*Foreign.*Joint Venture.*Domestic.*Total", section)
  if (length(header_idx) != 2L) {
    stop("Expected the catch-table headers on both report pages.", call. = FALSE)
  }
  parsed <- lapply(seq_along(header_idx), function(i) {
    header <- section[header_idx[i]]
    starts <- vapply(c("Year", "Domestic", "Total", "ABC"),
      function(x) regexpr(x, header, fixed = TRUE)[1L], numeric(1L))
    if (any(starts < 1L) || any(diff(starts) <= 0L)) {
      stop("Catch columns could not be aligned on page ", i, ".", call. = FALSE)
    }
    last <- if (i < length(header_idx)) header_idx[i + 1L] - 1L else length(section)
    row_lines <- section[seq.int(header_idx[i] + 1L, last)]
    row_lines <- row_lines[grepl("^\\s*[0-9]{4}", row_lines)]
    left <- floor((starts[2L] + starts[3L]) / 2L) + 1L
    right <- floor((starts[3L] + starts[4L]) / 2L)
    values <- lapply(row_lines, function(line) {
      year <- as.integer(sub("^\\s*([0-9]{4}).*$", "\\1", line))
      total <- numbers(trimws(substr(line, left, right)))
      if (length(total) != 1L || is.na(total)) {
        stop("Could not read the total catch for ", year, ".", call. = FALSE)
      }
      data.frame(year = year, total_t = total)
    })
    do.call(rbind, values)
  })
  out <- do.call(rbind, parsed)
  out <- out[order(out$year), , drop = FALSE]
  rownames(out) <- NULL
  if (!identical(out$year, 1961:2024) || any(!is.finite(out$total_t))) {
    stop("Catch table coverage differs from 1961-2024 or contains missing totals.",
      call. = FALSE)
  }
  out
}

parse_index <- function(start_text, end_text) {
  section <- table_lines(start_text, end_text)
  row_lines <- section[grepl("^\\s*(19|20)[0-9]{2}\\s+", section)]
  parsed <- lapply(row_lines, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1]]
    values <- numbers(tokens)
    if (length(values) != 5L) return(NULL)
    data.frame(year = as.integer(values[1L]), biomass_t = values[2L],
      se_t = values[3L], lower_ci_t = values[4L], upper_ci_t = values[5L])
  })
  do.call(rbind, Filter(Negate(is.null), parsed))
}

parse_biology <- function() {
  section <- table_lines("Table 10-16.", "Table 10-17.")
  row_lines <- section[grepl("^\\s*[0-9]{1,2}\\s+[0-9,]+\\s+[0-9]+\\s+[0-9,]+\\.[0-9]+", section)]
  parsed <- lapply(row_lines, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1]]
    values <- numbers(tokens)
    if (length(values) != 6L) stop("Unexpected Table 10-16 row.", call. = FALSE)
    data.frame(age = as.integer(values[1L]),
      abundance_thousand = values[2L], maturity_percent = values[3L],
      weight_g = values[4L], fishery_selectivity = values[5L],
      survey_selectivity = values[6L])
  })
  do.call(rbind, parsed)
}

parse_time_series <- function() {
  section <- table_lines("Table 10-19.", "Table 10-20.")
  row_lines <- section[grepl("^\\s*[12],[0-9]{3}\\s+", section)]
  parsed <- lapply(row_lines, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1]]
    values <- numbers(tokens)
    if (length(values) != 10L) stop("Unexpected Table 10-19 row.", call. = FALSE)
    data.frame(year = as.integer(values[1L]),
      recruitment_mean_thousand = values[2L],
      recruitment_lwr_thousand = values[3L],
      recruitment_upr_thousand = values[4L],
      total_biomass_mean_t = values[5L],
      total_biomass_lwr_t = values[6L],
      total_biomass_upr_t = values[7L],
      ssb_mean_t = values[8L], ssb_lwr_t = values[9L], ssb_upr_t = values[10L])
  })
  do.call(rbind, parsed)
}

parse_parameter_summary <- function() {
  section <- table_lines("Table 10-18.", "Table 10-19.")
  rows <- section[grepl("^\\s*(F40|spawn_bio|ABC|M|q)\\s+", section)]
  parsed <- lapply(rows, function(line) {
    tokens <- strsplit(trimws(line), "\\s+")[[1]]
    values <- numbers(tokens[-1L])
    if (length(values) != 6L) stop("Unexpected Table 10-18 row.", call. = FALSE)
    data.frame(metric = tokens[1L], estimate = values[1L],
      mcmc_mean = values[2L], mcmc_median = values[3L],
      mcmc_sd = values[4L], bci_lower = values[5L],
      bci_upper = values[6L], stringsAsFactors = FALSE)
  })
  do.call(rbind, parsed)
}

catch <- parse_catch()
fishery_age <- parse_composition("Table 10-10.", "age", "Age", "Table 10-11.")
survey_age <- parse_composition("Table 10-13.", "age", "Age", "Table 10-14.")
fishery_length <- parse_composition("Table 10-9.", "length_bin", "Length (cm)", "Table 10-10.")
survey_vast <- parse_index("Table 10-11.", "Table 10-12.")
survey_design <- parse_index("Table 10-12.", "Table 10-13.")
biology <- parse_biology()
time_series <- parse_time_series()
parameter_summary <- parse_parameter_summary()

source_script <- readLines(repository_model_path, warn = FALSE)
source_text <- paste(source_script, collapse = "\n")
extract_vector <- function(name, occurrence = c("first", "last")) {
  occurrence <- match.arg(occurrence)
  pattern <- paste0("\\b", name, "\\s*=\\s*c\\(([^)]*)\\)")
  matches <- regmatches(source_text, gregexpr(pattern, source_text, perl = TRUE))[[1L]]
  if (!length(matches)) stop("Model script vector not found: ", name, call. = FALSE)
  selected <- if (occurrence == "first") matches[1L] else matches[length(matches)]
  values <- sub(pattern, "\\1", selected, perl = TRUE)
  numbers(strsplit(values, ",", fixed = TRUE)[[1L]])
}
fishery_age_iss <- extract_vector("fish_age_iss")
survey_age_iss <- extract_vector("srv_age_iss", "last")
fishery_length_iss <- extract_vector("fish_size_iss")
extract_years <- function(x) as.integer(x$sample$year)
sample_sizes <- rbind(
  data.frame(series = "fishery_age", year = fishery_age$sample$year,
    sample_size = fishery_age_iss),
  data.frame(series = "survey_age", year = survey_age$sample$year,
    sample_size = survey_age_iss),
  data.frame(series = "fishery_length", year = fishery_length$sample$year,
    sample_size = fishery_length_iss)
)

if (!identical(catch$year, 1961:2024) ||
    !identical(extract_years(fishery_age), c(1998:2002, 2004:2006, 2008L,
      2010L, 2012L, 2014L, 2016L, 2018L, 2020L, 2022L)) ||
    !identical(extract_years(survey_age), c(1990L, 1993L, 1996L, 1999L,
      2001L, 2003L, 2005L, 2007L, 2009L, 2011L, 2013L, 2015L, 2017L,
      2019L, 2021L, 2023L)) ||
    !identical(extract_years(fishery_length), c(1991L, 1992L, 1993L, 1994L,
      1995L, 1996L, 1997L, 2003L, 2007L, 2009L, 2011L, 2013L, 2015L,
      2017L, 2019L, 2021L, 2023L)) ||
    !identical(survey_vast$year, c(1990L, 1993L, 1996L, 1999L, 2001L, 2003L,
      2005L, 2007L, 2009L, 2011L, 2013L, 2015L, 2017L, 2019L, 2021L,
      2023L)) ||
    !identical(biology$age, 2:51) ||
    !identical(time_series$year, 1977:2024) ||
    nrow(parameter_summary) != 5L) {
  stop("GOA northern-rockfish tables have unexpected years or ages.", call. = FALSE)
}
if (!all(vapply(list(fishery_age$composition, survey_age$composition,
  fishery_length$composition), function(x) all(is.finite(x$value) &
    x$value >= 0 & x$value <= 1), logical(1L)))) {
  stop("Composition values are outside [0, 1].", call. = FALSE)
}
fishery_age_crosscheck <- data.frame(series = "fishery_age",
  year = fishery_age$sample$year, model_input_sample_size = fishery_age_iss,
  report_sample_size = fishery_age$sample$sample_size_printed)
survey_age_crosscheck <- data.frame(series = "survey_age",
  year = survey_age$sample$year, model_input_sample_size = survey_age_iss,
  report_sample_size = survey_age$sample$sample_size_printed)
fishery_length_crosscheck <- data.frame(series = "fishery_length",
  year = fishery_length$sample$year, model_input_sample_size = fishery_length_iss,
  report_sample_size = fishery_length$sample$sample_size_printed)
sample_size_crosscheck <- rbind(fishery_age_crosscheck, survey_age_crosscheck,
  fishery_length_crosscheck)
sample_size_crosscheck$difference <- sample_size_crosscheck$model_input_sample_size -
  sample_size_crosscheck$report_sample_size
if (any(abs(sample_size_crosscheck$difference) > 0.11)) {
  stop("Repository and report sample sizes differ beyond report precision.",
    call. = FALSE)
}

read_repo_catch <- read.csv(file.path(cache,
  "2024__data__user_input__goa_nork_catch_1961_1992.csv"),
  stringsAsFactors = FALSE)
catch_crosscheck <- merge(catch, read_repo_catch, by.x = "year", by.y = "Year",
  all.x = TRUE, suffixes = c("_report", "_repository"))
names(catch_crosscheck)[names(catch_crosscheck) == "Catch"] <-
  "repository_catch_t"
catch_crosscheck$difference_t <- catch_crosscheck$total_t -
  catch_crosscheck$repository_catch_t
matched_catch <- !is.na(catch_crosscheck$repository_catch_t)
if (!identical(catch_crosscheck$year[matched_catch], 1961:1992) ||
    any(catch_crosscheck$difference_t[matched_catch] != 0)) {
  stop("Report catch totals do not match the AFSC repository cross-check for 1961-1992.",
    call. = FALSE)
}

long_composition <- function(x, column) {
  names(x$composition)[names(x$composition) == "bin"] <- column
  x$composition
}
write.csv(catch, file.path(transcription_dir, "catch_history.csv"),
  row.names = FALSE, na = "")
write.csv(long_composition(fishery_age, "age"),
  file.path(transcription_dir, "fishery_age_composition.csv"),
  row.names = FALSE, na = "")
write.csv(long_composition(survey_age, "age"),
  file.path(transcription_dir, "survey_age_composition.csv"),
  row.names = FALSE, na = "")
write.csv(long_composition(fishery_length, "length_bin"),
  file.path(transcription_dir, "fishery_length_composition.csv"),
  row.names = FALSE, na = "")
write.csv(survey_vast, file.path(transcription_dir, "survey_vast_biomass.csv"),
  row.names = FALSE, na = "")
write.csv(survey_design,
  file.path(transcription_dir, "survey_design_based_biomass.csv"),
  row.names = FALSE, na = "")
write.csv(biology, file.path(transcription_dir, "terminal_biology_and_population.csv"),
  row.names = FALSE, na = "")
write.csv(time_series, file.path(transcription_dir, "time_series.csv"),
  row.names = FALSE, na = "")
write.csv(parameter_summary,
  file.path(transcription_dir, "parameter_summary.csv"),
  row.names = FALSE, na = "")
write.csv(sample_sizes, file.path(transcription_dir, "composition_sample_sizes.csv"),
  row.names = FALSE, na = "")
write.csv(sample_size_crosscheck,
  file.path(transcription_dir, "composition_sample_size_crosscheck.csv"),
  row.names = FALSE, na = "")
write.csv(catch_crosscheck,
  file.path(transcription_dir, "catch_history_crosscheck.csv"),
  row.names = FALSE, na = "")

cat("Transcribed catch rows:", nrow(catch), "\n")
cat("Fishery age rows:", nrow(fishery_age$composition), "\n")
cat("Survey age rows:", nrow(survey_age$composition), "\n")
cat("Fishery length rows:", nrow(fishery_length$composition), "\n")
cat("VAST survey rows:", nrow(survey_vast), "\n")
cat("Design-based survey rows:", nrow(survey_design), "\n")
cat("Terminal biological/population rows:", nrow(biology), "\n")
cat("Annual output rows:", nrow(time_series), "\n")
cat("Raw-repository catch differences:", sum(catch_crosscheck$difference_t != 0,
  na.rm = TRUE), "\n")
print(catch_crosscheck[!is.na(catch_crosscheck$difference_t) &
  catch_crosscheck$difference_t != 0, c("year", "total_t",
  "repository_catch_t", "difference_t")])
