root <- normalizePath(".", winslash = "/", mustWork = TRUE)
pdf_file <- file.path(root, "analysis", "comp_assessments", "source_cache", "ck_ices_wgbfas_solea_ns_iiia_22_24", "assessment_2026", "WGBFAS_2026_Sole_20-24.pdf")
pdf_pages <- pdftools::pdf_text(pdf_file)
page_lines <- lapply(pdf_pages, function(page) trimws(strsplit(gsub("\\u00a0", " ", page), "\\n")[[1L]]))
year_pattern <- "^(19|20)[0-9]{2}$"
number_pattern <- "^(NA|[-+]?[0-9]+([.][0-9]*)?([eE][-+]?[0-9]+)?)$"
as_number <- function(x) suppressWarnings(as.numeric(ifelse(x == "NA", NA_character_, x)))
years_from_line <- function(line) {
  tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
  hits <- tokens[grepl(year_pattern, tokens)]
  as.integer(hits)
}
age_number <- function(x) {
  if (x == "+gp") return(9L)
  as.integer(gsub("[^0-9]", "", x))
}
extract_transposed <- function(page_range, expected_years, expected_ages, label) {
  current_years <- integer()
  rows <- list()
  for (page in page_range) {
    for (line in page_lines[[page]]) {
      yrs <- years_from_line(line)
      if (length(yrs) >= 2L && (grepl("YEAR", line, ignore.case = TRUE) || length(yrs) == length(strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]))) {
        current_years <- yrs
        next
      }
      if (!length(current_years)) next
      tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
      if (!length(tokens) || !grepl("^(\\.[0-9]+|[0-9]+|\\+gp)$", tokens[[1L]])) next
      vals <- tokens[-1L]
      if (length(vals) != length(current_years) || !all(grepl(number_pattern, vals))) next
      rows[[length(rows) + 1L]] <- data.frame(
        year = current_years, age = age_number(tokens[[1L]]),
        value = as_number(vals), stringsAsFactors = FALSE
      )
    }
  }
  out <- do.call(rbind, rows)
  if (is.null(out)) stop("No rows extracted for ", label)
  if (!identical(sort(unique(out$year)), as.integer(expected_years))) stop(label, " years mismatch: ", paste(sort(unique(out$year)), collapse=","))
  if (!identical(sort(unique(out$age)), as.integer(expected_ages))) stop(label, " ages mismatch: ", paste(sort(unique(out$age)), collapse=","))
  if (anyDuplicated(paste(out$year, out$age))) stop(label, " duplicated year-age rows")
  out[order(out$year, out$age), , drop=FALSE]
}
extract_year_age <- function(page_range, expected_years, expected_ages, label) {
  rows <- list()
  for (page in page_range) {
    for (line in page_lines[[page]]) {
      tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
      if (length(tokens) != length(expected_ages)+1L || !grepl(year_pattern, tokens[[1L]])) next
      if (!all(grepl(number_pattern, tokens[-1L]))) next
      rows[[length(rows)+1L]] <- data.frame(
        year=as.integer(tokens[[1L]]), age=as.integer(expected_ages),
        value=as_number(tokens[-1L]), stringsAsFactors=FALSE
      )
    }
  }
  out <- do.call(rbind, rows)
  if (is.null(out)) stop("No rows extracted for ", label)
  if (!identical(sort(unique(out$year)), as.integer(expected_years))) stop(label, " years mismatch")
  if (!identical(sort(unique(out$age)), as.integer(expected_ages))) stop(label, " ages mismatch")
  if (anyDuplicated(paste(out$year,out$age))) stop(label, " duplicated rows")
  out[order(out$year,out$age), , drop=FALSE]
}
extract_surveys <- function() {
  lines <- unlist(page_lines[13:15], use.names=FALSE)
  specs <- list(
    list(name="Q4 Sole survey", marker="^Q4.*survey", start=2004L, end=2024L, range_end=2025L, ages=1:9, ncols=10L),
    list(name="Gillnet", marker="^Gillnet$", start=1994L, end=2007L, range_end=2007L, ages=2:9, ncols=8L),
    list(name="Trawl", marker="^Trawl$", start=1987L, end=2008L, range_end=2008L, ages=2:6, ncols=6L)
  )
  res <- list()
  for (j in seq_along(specs)) {
    s <- specs[[j]]
    p <- which(grepl(s$marker, lines, ignore.case=TRUE))
    if (length(p)!=1L) stop("Could not locate fleet ", s$name)
    next_p <- if (j<length(specs)) which(grepl(specs[[j+1L]]$marker, lines, ignore.case=TRUE))[1L] else length(lines)+1L
    sec <- lines[p:(next_p-1L)]
    data_start <- which(vapply(sec, function(line) {
      tok <- strsplit(trimws(gsub("\\s+"," ",line)), " ", fixed=TRUE)[[1L]]
      length(tok)==2L && all(grepl(year_pattern,tok)) && as.integer(tok[1L])==s$start && as.integer(tok[2L])==s$range_end
    }, logical(1)))
    if (length(data_start)!=1L) stop("Could not locate year span for ",s$name)
    data <- list()
    for (line in sec[(data_start+1L):length(sec)]) {
      tok <- strsplit(trimws(gsub("\\s+"," ",line)), " ", fixed=TRUE)[[1L]]
      if (length(tok)!=s$ncols || !all(grepl(number_pattern,tok))) next
      data[[length(data)+1L]] <- as_number(tok)
    }
    if (length(data)!=s$end-s$start+1L) stop(s$name," rows: ",length(data)," expected ",s$end-s$start+1L)
    mat <- do.call(rbind,data)
    mat <- mat[, (ncol(mat)-length(s$ages)+1L):ncol(mat), drop=FALSE]
    out <- data.frame(
      year=rep(s$start:s$end, each=length(s$ages)),
      age=rep(s$ages,times=s$end-s$start+1L),
      value=as.vector(t(mat)), stringsAsFactors=FALSE
    )
    res[[s$name]] <- out[is.finite(out$value),,drop=FALSE]
  }
  res
}
catch <- extract_transposed(16:17,1984:2025,2:9,"catch")
weights <- extract_transposed(18:19,1984:2025,2:9,"weights")
f_at_age <- extract_year_age(20:21,1984:2025,1:9,"F")
n_at_age <- extract_year_age(22:23,1984:2025,1:9,"N")
surveys <- extract_surveys()
cat("catch",nrow(catch),range(catch$year),range(catch$age),"\n")
cat("weights",nrow(weights),range(weights$year),range(weights$age),"2024 age 2 raw",weights$value[weights$year==2024 & weights$age==2],"\n")
cat("F",nrow(f_at_age),range(f_at_age$year),range(f_at_age$age),"\n")
cat("N",nrow(n_at_age),range(n_at_age$year),range(n_at_age$age),"\n")
for (n in names(surveys)) cat(n,nrow(surveys[[n]]),range(surveys[[n]]$year),range(surveys[[n]]$age),"\n")





if (!requireNamespace("pdftools", quietly = TRUE) || !requireNamespace("digest", quietly = TRUE)) {
  stop("Install pdftools and digest to import the cached WGBFAS report.", call. = FALSE)
}

report_url <- "https://doi.org/10.17895/ices.pub.32455056.v3"
annex_url <- "https://doi.org/10.17895/ices.pub.29210012.v2"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21317"
model_url <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/sole20_24_2026_new/run/model.RData"
assessment_id <- "ices_sole_20_24_2026_summary"
previous_id <- "ices_sole_20_24_2025"
stock_id <- "ck_ices_wgbfas_solea_ns_iiia_22_24"
report_sha256 <- "AF7427F810B8E42D434FF6370B6649C07F62EEC487615CEC63CDA9289E75AAF7"
actual_sha256 <- digest::digest(readBin(pdf_file, "raw", n = file.info(pdf_file)$size), serialize = FALSE, algo = "sha256")
if (!identical(toupper(actual_sha256), report_sha256)) stop("Cached WGBFAS 2026 report checksum mismatch.", call. = FALSE)

summary_rows <- list()
for (line in unlist(page_lines[24:25], use.names = FALSE)) {
  tokens <- strsplit(trimws(gsub("\\s+", " ", line)), " ", fixed = TRUE)[[1L]]
  if (length(tokens) != 13L || !grepl(year_pattern, tokens[[1L]]) || !all(grepl(number_pattern, tokens[-1L]))) next
  summary_rows[[length(summary_rows) + 1L]] <- data.frame(
    year = as.integer(tokens[[1L]]),
    recruitment = as_number(tokens[[2L]]), recruitment_lwr = as_number(tokens[[3L]]), recruitment_upr = as_number(tokens[[4L]]),
    SSB = as_number(tokens[[5L]]), SSB_lwr = as_number(tokens[[6L]]), SSB_upr = as_number(tokens[[7L]]),
    Fbar = as_number(tokens[[8L]]), Fbar_lwr = as_number(tokens[[9L]]), Fbar_upr = as_number(tokens[[10L]]),
    total_biomass = as_number(tokens[[11L]]), total_biomass_lwr = as_number(tokens[[12L]]), total_biomass_upr = as_number(tokens[[13L]]),
    stringsAsFactors = FALSE
  )
}
summary_data <- do.call(rbind, summary_rows)
if (nrow(summary_data) != 42L || !identical(summary_data$year, 1984:2025)) stop("Unexpected Table 6.10 coverage.", call. = FALSE)

as_input_rows <- function(values, type, measure, basis, unit, fleet = "", survey = "", source_ref, transformation, notes, sampling_time = NA_real_) {
  n <- nrow(values)
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure, basis = basis,
    fleet = rep(fleet, n), survey = rep(survey, n), sex = "", region = "", season = "",
    year = values$year, year_basis = "calendar_year", age = values$age, value = values$value,
    unit = unit, sampling_time = rep(sampling_time, n), source_type = "official_table",
    source_reference = source_ref, transformation = transformation, notes = notes,
    observation_id = "", length_bin = "", length_bin_lower = "", length_bin_upper = "",
    sample_size = "", age_error = "", partition = "",
    stringsAsFactors = FALSE, check.names = FALSE
  )
}

catch_inputs <- as_input_rows(
  catch, "catch", "numbers_at_age", "numbers", "thousand fish", fleet = "Residual catch",
  source_ref = paste0(report_url, "; Table 6.6"),
  transformation = "Copied the reported catch numbers-at-age.",
  notes = "The assessment uses landings only. Age 9 is the 9+ group."
)
weight_inputs <- as_input_rows(
  transform(weights, value = value / 10000), "weight", "weight_at_age", "kg_per_fish", "kg per fish",
  source_ref = paste0(report_url, "; Table 6.7; cross-check: 2025 SAM run data/sw.dat"),
  transformation = "Divided Table 6.7 values by 10,000 to convert the printed scale to kg per fish; the 2024 values match the prior native SAM data.",
  notes = "Stock weight is assumed equal to catch weight. Age 9 is the 9+ group."
)

survey_specs <- list(
  list(key = "Q4 Sole survey", name = "Q4Solesurvey1-9+", ages = 1:9,
    notes = "Reported Q4 sole survey age index. The table's leading field is outside the stated age range and was omitted. Rows are assigned to 2004-2024; the report prints no 2025 row and 2012-2013 are missing."),
  list(key = "Gillnet", name = "Gillnet", ages = 2:9,
    notes = "Commercial gillnet CPUE at ages 2-9, per the stock annex. Sampling time is not labelled in the report table."),
  list(key = "Trawl", name = "Trawl", ages = 2:6,
    notes = "Commercial trawl CPUE at ages 2-6, per the stock annex. The leading field outside the stated age range was omitted; sampling time is not labelled in the report table.")
)
survey_inputs <- do.call(rbind, lapply(survey_specs, function(spec) {
  values <- surveys[[spec$key]]
  as_input_rows(values, "index", "numbers_at_age", "index_scale", "native survey-index units",
    survey = spec$name, source_ref = paste0(report_url, "; Table 6.5; ", annex_url),
    transformation = "Copied finite age-specific index values for the age ranges identified in the stock annex.",
    notes = spec$notes)
}))
inputs_new <- rbind(catch_inputs, weight_inputs, survey_inputs)

as_age_outputs <- function(values, type, measure, unit, source_ref, notes, source_type = "official_table") {
  data.frame(
    assessment_id = assessment_id, type = type, measure = measure,
    fleet = "", survey = "", sex = "", region = "", season = "",
    year = values$year, age = values$age,
    age_group = ifelse(values$age == 9L, "9+", ""), value = values$value,
    se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = unit,
    source_type = source_type, source_reference = source_ref, notes = notes,
    stringsAsFactors = FALSE, check.names = FALSE
  )
}
numbers_output <- as_age_outputs(n_at_age, "population", "numbers_at_age", "thousand fish",
  paste0(report_url, "; Table 6.9"), "Fitted stock numbers at age; age 9 is the 9+ group. The report gives point estimates only.")
f_output <- as_age_outputs(f_at_age, "mortality", "fishing_mortality_at_age", "per year",
  paste0(report_url, "; Table 6.8"), "Fitted fishing mortality at age; ages 6-9 are constrained equal in the source model. The report gives point estimates only.")
total_numbers <- stats::aggregate(value ~ year, numbers_output, sum)
total_output <- data.frame(
  assessment_id = assessment_id, type = "population", measure = "total_numbers",
  fleet = "", survey = "", sex = "", region = "", season = "", year = total_numbers$year,
  age = NA_integer_, age_group = "", value = total_numbers$value,
  se = NA_real_, lwr = NA_real_, upr = NA_real_, unit = "thousand fish",
  source_type = "derived_source_output", source_reference = paste0(report_url, "; Table 6.9"),
  notes = "Derived by summing the reported fitted N-at-age values. No uncertainty is available.",
  stringsAsFactors = FALSE, check.names = FALSE
)
tsb_output <- data.frame(
  assessment_id = assessment_id, type = "biomass", measure = "total_biomass",
  fleet = "", survey = "", sex = "", region = "", season = "", year = summary_data$year,
  age = NA_integer_, age_group = "", value = summary_data$total_biomass,
  se = NA_real_, lwr = summary_data$total_biomass_lwr, upr = summary_data$total_biomass_upr,
  unit = "tonnes", source_type = "official_table", source_reference = paste0(report_url, "; Table 6.10"),
  notes = "Reported total stock biomass and 95% confidence limits.",
  stringsAsFactors = FALSE, check.names = FALSE
)
outputs_new <- rbind(numbers_output, f_output, total_output, tsb_output)

assumption_rows <- data.frame(
  assessment_id = assessment_id, component = c("assessment", "population", "catch", "index", "biology", "biology", "M", "spawning", "assessment"),
  fleet = "", survey = "", sex = "", region = "", season = "",
  setting = c("model_family", "age_structure", "catch_definition", "tuning_series", "maturity_at_age", "stock_weight", "natural_mortality", "pre_spawning_mortality", "native_model_files"),
  value = c("SAM", "Single area, single sex, ages 1-9+", "Landings only", "Q4 survey, gillnet CPUE, trawl CPUE", "Knife-edge maturity at age 3", "Stock weight assumed equal to catch weight", "Fixed M = 0.1 per year at all ages and years", "Fprop = 0 and Mprop = 0", "Not recovered"),
  source_reference = c(report_url, paste0(report_url, "; Table 6.9"), paste0(report_url, "; Table 6.6"), paste0(report_url, "; Table 6.5; ", annex_url), annex_url, annex_url, annex_url, annex_url, model_url),
  notes = c("WGBFAS 2026 identifies the assessment as a SAM update.", "The stock annex describes the fitted population age range; age 9 is the plus group.", "The report identifies residual catch as landings; discards are excluded.", "The report gives the three tuning series and fitted age ranges. Exact sampling times and observation precision settings are not reported in the recovered sources.", "The stock annex states that a knife-edge age-3 maturity is used.", "The stock annex states stock weight is assumed equal to catch weight.", "The stock annex specifies fixed natural mortality of 0.1.", "Both proportions of F and M before spawning are set to zero.", "The documented native SAM run endpoint could not be retrieved; no native data or model object was available for checksum verification."),
  stringsAsFactors = FALSE, check.names = FALSE
)

if (anyDuplicated(paste(inputs_new$assessment_id, inputs_new$type, inputs_new$measure,
  inputs_new$fleet, inputs_new$survey, inputs_new$year, inputs_new$age, sep = "\r"))) stop("Duplicate input keys in new rows.", call. = FALSE)
if (anyDuplicated(paste(outputs_new$assessment_id, outputs_new$type, outputs_new$measure,
  outputs_new$year, outputs_new$age, sep = "\r"))) stop("Duplicate output keys in new rows.", call. = FALSE)
if (any(!is.finite(inputs_new$value)) || any(inputs_new$value < 0) || any(!is.finite(outputs_new$value))) stop("Imported values must be finite and non-negative.", call. = FALSE)

if (identical(tolower(Sys.getenv("TINYAM_IMPORT_DRY_RUN")), "true")) {
  cat("Dry run: inputs", nrow(inputs_new), "outputs", nrow(outputs_new), "assumptions", nrow(assumption_rows), "\n")
  quit(save = "no")
}

database <- file.path(root, "analysis", "comp_assessments", "database")
inputs_file <- file.path(database, "inputs.csv")
outputs_file <- file.path(database, "outputs.csv")
assumptions_file <- file.path(database, "assumptions.csv")
assessments_file <- file.path(database, "assessments.csv")

read_id_rows <- function(path, id) {
  con <- file(path, open = "r")
  on.exit(close(con), add = TRUE)
  header <- readLines(con, n = 1L, warn = FALSE)
  found <- character()
  repeat {
    chunk <- suppressWarnings(readLines(con, n = 50000L, warn = FALSE))
    if (!length(chunk)) break
    found <- c(found, chunk[startsWith(chunk, paste0("\"", id, "\","))])
  }
  if (!length(found)) return(NULL)
  utils::read.csv(text = paste(c(header, found), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
}

if (!is.null(read_id_rows(inputs_file, assessment_id))) stop("Input rows already exist for this assessment; refusing to duplicate them.", call. = FALSE)
existing_outputs <- read_id_rows(outputs_file, assessment_id)
if (is.null(existing_outputs)) stop("Expected the existing SAG summary outputs for this assessment.", call. = FALSE)
new_keys <- paste(outputs_new$type, outputs_new$measure, outputs_new$year, outputs_new$age, sep = "\r")
old_keys <- paste(existing_outputs$type, existing_outputs$measure, existing_outputs$year, existing_outputs$age, sep = "\r")
if (any(new_keys %in% old_keys)) stop("New output rows duplicate an existing key.", call. = FALSE)

append_rows <- function(rows, path) {
  utils::write.table(rows, file = path, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, append = TRUE, na = "")
}

replace_assessment_row <- function(id, new_row) {
  bytes <- readBin(assessments_file, what = "raw", n = file.info(assessments_file)$size)
  feeds <- which(bytes == as.raw(10L))
  starts <- c(1L, feeds + 1L)
  ends <- c(feeds - 1L, length(bytes))
  ends <- ends[seq_along(starts)]
  lines <- lapply(seq_along(starts), function(i) if (starts[i] > ends[i]) raw() else bytes[starts[i]:ends[i]])
  texts <- vapply(lines, rawToChar, character(1))
  target <- which(startsWith(texts, paste0("\"", id, "\",")))
  if (length(target) != 1L) stop("Expected exactly one assessment row for ", id, call. = FALSE)
  con <- textConnection("serialized", "w", local = TRUE)
  utils::write.table(new_row, file = con, sep = ",", quote = TRUE, row.names = FALSE,
    col.names = FALSE, na = "")
  close(con)
  replacement <- charToRaw(serialized[[1L]])
  if (length(lines[[target]]) && tail(lines[[target]], 1L) == as.raw(13L)) replacement <- c(replacement, as.raw(13L))
  before <- if (starts[target] > 1L) bytes[seq_len(starts[target] - 1L)] else raw()
  after_start <- ends[target] + 1L
  after <- if (after_start <= length(bytes)) bytes[after_start:length(bytes)] else raw()
  writeBin(c(before, replacement, after), assessments_file)
}

assessments <- read.csv(assessments_file, colClasses = "character", na.strings = "", check.names = FALSE)
ix_old <- which(assessments$assessment_id == previous_id)
ix_new <- which(assessments$assessment_id == assessment_id)
if (length(ix_old) != 1L || length(ix_new) != 1L) stop("Could not identify the 2025 and 2026 assessment rows.", call. = FALSE)
assessments[ix_old, "is_current"] <- "FALSE"
assessments[ix_old, "notes"] <- "Historical 2025 SAM assessment through 2024. The 2026 detailed assessment is the current run; see the 2026 source review."
replace_assessment_row(previous_id, assessments[ix_old, , drop = FALSE])
assessments <- read.csv(assessments_file, colClasses = "character", na.strings = "", check.names = FALSE)
ix_new <- which(assessments$assessment_id == assessment_id)
assessments[ix_new, c("assessment_type", "model_family", "model_version", "is_current", "is_applied",
  "terminal_year", "estimate_terminal_year", "assessment_url", "framework_url", "data_url", "model_url",
  "repository_url", "assumptions_status", "inputs_status", "outputs_status", "notes")] <- c(
    "annual_assessment", "SAM", "SAM; native software version not recovered", "TRUE", "TRUE",
    "2025", "2026", report_url, annex_url, sag_url, model_url, "", "partial", "partial", "partial",
    "Detailed 2026 assessment tables are now included. The legacy summary identifier is retained because it keys the existing ICES SAG series. The native SAM run could not be retrieved; exact sampling times and observation precision settings remain unresolved."
  )
replace_assessment_row(assessment_id, assessments[ix_new, , drop = FALSE])

input_schema <- names(utils::read.csv(inputs_file, nrows = 0L, check.names = FALSE))
output_schema <- names(utils::read.csv(outputs_file, nrows = 0L, check.names = FALSE))
assumption_schema <- names(utils::read.csv(assumptions_file, nrows = 0L, check.names = FALSE))
inputs_new <- inputs_new[, input_schema, drop = FALSE]
outputs_new <- outputs_new[, output_schema, drop = FALSE]
assumption_rows <- assumption_rows[, assumption_schema, drop = FALSE]
append_rows(inputs_new, inputs_file)
append_rows(outputs_new, outputs_file)
append_rows(assumption_rows, assumptions_file)

cat("Imported Sole 20-24 2026 report data. Inputs:", nrow(inputs_new), "Outputs:", nrow(outputs_new), "Assumptions:", nrow(assumption_rows), "\n")
