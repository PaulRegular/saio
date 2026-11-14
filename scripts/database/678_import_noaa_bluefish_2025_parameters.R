root <- "."
cache <- file.path(root, "source_cache", "discovery_noaa_bluefish_2025")
manifest_path <- file.path(root, "provenance", "discovery_noaa_bluefish_2025", "sources.csv")
stock_id <- "noaa_bluefish_atlantic_coast"
assessment_id <- "noaa_bluefish_atlantic_2025"
candidate_id <- "NOAA:10388"
parameter_count <- 66L
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE) ||
  identical(Sys.getenv("SAIO_IMPORT_WRITE"), "true")

.libPaths(c(file.path(root, "source_cache", "r-lib"), .libPaths()))
if (!requireNamespace("pdftools", quietly = TRUE)) {
  stop("pdftools is required.", call. = FALSE)
}
source(file.path(root, "scripts", "database", "pacific_tables.R"))
source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, colClasses = "character",
    na.strings = c("", "NA"), check.names = FALSE)
}
manifest <- read_csv(manifest_path)
source_name <- "2025_BLF_UNIT_TAB_wham_par_tables.pdf"
source_row <- manifest[basename(manifest$file) == source_name, , drop = FALSE]
pdf_path <- file.path(cache, source_name)
sha256_file <- function(path) tolower(unname(tools::sha256sum(path)))
if (nrow(source_row) != 1L || !file.exists(pdf_path) ||
    as.numeric(source_row$bytes) != file.info(pdf_path)$size ||
    !identical(sha256_file(pdf_path), tolower(source_row$sha256))) {
  stop("Cached NOAA bluefish parameter table does not match its provenance record.",
    call. = FALSE)
}

pages <- pdftools::pdf_text(pdf_path)
if (length(pages) != 12L ||
    !grepl("Table 1. Parameter estimates, standard errors, and confidence intervals",
      pages[[2L]], fixed = TRUE)) {
  stop("Cached file does not contain the reviewed Table 1.", call. = FALSE)
}
lines <- trimws(unlist(lapply(2:6, function(i) {
  strsplit(pages[[i]], "\n", fixed = TRUE)[[1L]]
}), use.names = FALSE))
lines <- lines[nzchar(lines)]

normalize_parameter_text <- function(x) {
  x <- gsub("\u2212", "-", x, fixed = TRUE)
  x <- gsub("\u00D7\\s*10-([0-9]+)", "e-\\1", x, perl = TRUE)
  x <- gsub("([0-9])\\s+(e-[0-9]+)", "\\1\\2", x, perl = TRUE)
  x <- gsub("\u03C3", "sigma", x, fixed = TRUE)
  x <- gsub("\u03C1", "rho", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trimws(x)
}
lines <- normalize_parameter_text(lines)
lines <- gsub("^[0-9]+\\s+", "", lines, perl = TRUE)

number <- "[-+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?"
row_pattern <- paste0("^(.*?)\\s+(", number, ")\\s+(", number,
  ")\\s+(", number, ")\\s+(", number, ")\\s*$")
parse_parameter_row <- function(line) {
  fields <- regmatches(line, regexec(row_pattern, line, perl = TRUE))[[1L]]
  if (length(fields) != 6L) return(NULL)
  data.frame(
    measure = trimws(fields[[2L]]),
    value = as.numeric(fields[[3L]]),
    se = as.numeric(fields[[4L]]),
    lwr = as.numeric(fields[[5L]]),
    upr = as.numeric(fields[[6L]]),
    stringsAsFactors = FALSE
  )
}
parsed <- lapply(lines, parse_parameter_row)
parameters <- do.call(rbind, parsed[!vapply(parsed, is.null, logical(1L))])
row.names(parameters) <- NULL
if (nrow(parameters) != parameter_count ||
    anyDuplicated(parameters$measure) ||
    any(!is.finite(as.matrix(parameters[c("value", "se", "lwr", "upr")]))) ||
    sum(grepl("fully selected q$", parameters$measure)) != 9L) {
  stop("NOAA bluefish parameter rows failed count, uniqueness, or numeric checks.",
    call. = FALSE)
}

age_text <- sub("^.*Selectivity for age ([0-9]+\\+?).*$", "\\1",
  parameters$measure, perl = TRUE)
age_row <- grepl("Selectivity for age [0-9]+\\+?", parameters$measure,
  perl = TRUE)
age <- rep(NA_integer_, nrow(parameters))
age[age_row] <- as.integer(sub("\\+$", "", age_text[age_row]))
age_group <- ifelse(age_row & grepl("age [0-9]+\\+", parameters$measure,
  perl = TRUE), paste0(age, "+"), NA_character_)
fleet <- ifelse(startsWith(parameters$measure, "Comm "),
  "Commercial", ifelse(startsWith(parameters$measure, "Rec "),
    "Recreational", NA_character_))
survey_prefixes <- c("NEFSC Inshore", "Bigelow", "MRIP", "NEAMAP",
  "SEAMAP0", "PSIGN", "Compound YOY", "ChesMMAP", "SEAMAP1")
survey <- rep(NA_character_, nrow(parameters))
for (prefix in survey_prefixes) {
  survey[startsWith(parameters$measure, paste0(prefix, " "))] <- prefix
}
source_reference <- paste0(source_name, ", Table 1, PDF pp. 2-6")
notes <- paste(
  "Estimated parameter and uncertainty as reported.",
  "Most entries are rounded to three decimals; scientific notation for q is represented as an equivalent decimal.",
  "Values are retained on the source-reported parameter scale without back-transformation.",
  "The table does not state parameter units. Fixed entries with no standard error or confidence interval are not included."
)
parameter_outputs <- pacific_database_row(
  "outputs", n = nrow(parameters), assessment_id = assessment_id,
  type = "parameter", measure = parameters$measure, fleet = fleet,
  survey = survey, age = age, age_group = age_group, value = parameters$value,
  se = parameters$se, lwr = parameters$lwr, upr = parameters$upr,
  unit = "native parameter scale", scenario = "Base-run estimate",
  source_type = "official_table", source_reference = source_reference,
  notes = notes
)
if (nrow(parameter_outputs) != parameter_count) {
  stop("Unexpected number of bluefish parameter output rows.", call. = FALSE)
}

cat("NOAA Atlantic bluefish 2025 parameter extraction\n")
cat("  estimated parameters: ", nrow(parameter_outputs), "\n", sep = "")
cat("  standard errors and 95% confidence intervals: source-reported\n")
cat("  fixed parameters without uncertainty: omitted\n")

if (!write_mode) {
  cat("Dry run only. Add --write to append these outputs.\n")
} else {
  stocks <- read_csv(file.path("database", "stocks.csv"))
  assessments <- read_csv(file.path("database", "assessments.csv"))
  candidates <- read_csv(file.path("discovery", "candidates.csv"))
  stock_row <- which(stocks$stock_id == stock_id)
  assessment_row <- which(assessments$assessment_id == assessment_id)
  candidate_row <- which(candidates$candidate_id == candidate_id)
  if (length(stock_row) != 1L || length(assessment_row) != 1L ||
      assessments$stock_id[assessment_row] != stock_id ||
      length(candidate_row) != 1L ||
      candidates$matched_stock_id[candidate_row] != stock_id ||
      candidates$import_status[candidate_row] != "partial") {
    stop("NOAA bluefish assessment identity or partial status changed.",
      call. = FALSE)
  }

  has_parameter_rows <- function(path) {
    connection <- file(path, open = "r")
    on.exit(close(connection), add = TRUE)
    prefix <- paste0('"', assessment_id, '","parameter",')
    repeat {
      chunk <- readLines(connection, n = 250000L, warn = FALSE)
      if (!length(chunk)) return(FALSE)
      if (any(startsWith(chunk, prefix))) return(TRUE)
    }
  }
  outputs_path <- file.path("database", "outputs.csv")
  if (has_parameter_rows(outputs_path)) {
    stop("Parameter outputs already exist for this assessment.", call. = FALSE)
  }
  utils::write.table(parameter_outputs, outputs_path,
    sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE,
    quote = TRUE, na = "", qmethod = "double", eol = "\n")

  candidates$output_evidence[candidate_row] <- paste(
    candidates$output_evidence[candidate_row],
    "Added 66 fitted parameter estimates with standard errors and 95% confidence intervals from Table 1."
  )
  candidates$review_date[candidate_row] <- "2026-11-13"
  replace_candidate_register_row(
    "discovery/candidates.csv", candidate_row,
    candidates[candidate_row, , drop = FALSE], candidate_id
  )
  cat("Appended 66 NOAA Atlantic bluefish parameter outputs. Completeness remains partial.\n")
}