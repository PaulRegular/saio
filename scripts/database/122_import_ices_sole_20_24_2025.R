assessment_id <- "ices_sole_20_24_2025"
summary_assessment_id <- "ices_sole_20_24_2026_summary"
stock_id <- "ck_ices_wgbfas_solea_ns_iiia_22_24"
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
base <- file.path(root, "analysis", "comp_assessments")
cache <- file.path(base, "source_cache", "ices_sole_20_24_2025")
report_file <- file.path(cache, "WGBFAS_2025.pdf")
model_file <- file.path(cache, "run", "model.RData")
data_file <- file.path(cache, "run", "data.RData")
cv_file <- file.path(cache, "data", "Sole2024-CV.csv")
sag_file <- file.path(cache, "SAG_2026.html")
report_url <- "https://literatur.thuenen.de/digbib_extern/dn069788.pdf"
sag_report_url <- "https://literatur.thuenen.de/digbib_extern/dn071152.pdf"
sag_url <- "https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21317"
source_dir <- "https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Sole20_24_2025_new_indicesCV_conf"
data_url <- paste0(source_dir, "/data/")
model_url <- paste0(source_dir, "/run/model.RData")
database <- file.path(base, "database")

if (!requireNamespace("stockassessment", quietly = TRUE)) {
  stop("Install stockassessment to read the cached SAM fitted object.", call. = FALSE)
}
if (!requireNamespace("pdftools", quietly = TRUE) ||
  !requireNamespace("xml2", quietly = TRUE)) {
  stop("Install pdftools and xml2 to read the cached official tables.", call. = FALSE)
}

read_db <- function(name) {
  utils::read.csv(file.path(database, name), colClasses = "character",
    na.strings = "", check.names = FALSE, stringsAsFactors = FALSE
  )
}

replace_stock_row <- function(path, stock_id, row) {
  csv_raw <- readBin(path, what = "raw", n = file.info(path)[["size"]])
  newlines <- which(csv_raw == as.raw(10L))
  starts <- c(1L, newlines + 1L)
  ends <- c(newlines - 1L, length(csv_raw))
  lines <- lapply(seq_along(starts), function(i) {
    if (starts[i] > ends[i]) raw() else csv_raw[starts[i]:ends[i]]
  })
  line_text <- vapply(lines, rawToChar, character(1))
  target <- which(startsWith(line_text, paste0('"', stock_id, '"')))
  if (length(target) != 1L) {
    stop("Expected exactly one stock CSV row for ", stock_id, ".", call. = FALSE)
  }

  serialized <- textConnection("stock_line", open = "w", local = TRUE)
  utils::write.table(row, file = serialized, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, na = ""
  )
  close(serialized)
  replacement <- charToRaw(enc2utf8(stock_line[[1L]]))
  if (length(lines[[target]]) > 0L &&
    tail(lines[[target]], 1L) == as.raw(13L)) {
    replacement <- c(replacement, as.raw(13L))
  }
  line_start <- starts[target]
  line_end <- ends[target]
  prefix <- if (line_start > 1L) csv_raw[seq_len(line_start - 1L)] else raw()
  suffix <- if (line_end < length(csv_raw)) {
    csv_raw[seq.int(line_end + 1L, length(csv_raw))]
  } else {
    raw()
  }
  con <- file(path, open = "wb")
  writeBin(c(prefix, replacement, suffix), con)
  close(con)
}

format_value <- function(x) {
  ifelse(is.finite(x), format(x, digits = 15, scientific = FALSE, trim = TRUE), "")
}

empty_rows <- function(schema, n) {
  out <- as.data.frame(matrix("", nrow = n, ncol = length(schema)),
    stringsAsFactors = FALSE
  )
  names(out) <- schema
  out
}

input_schema <- names(read.csv(file.path(database, "inputs.csv"), nrows = 0,
  colClasses = "character", check.names = FALSE
))
output_schema <- names(read.csv(file.path(database, "outputs.csv"), nrows = 0,
  colClasses = "character", check.names = FALSE
))
assumption_schema <- names(read.csv(file.path(database, "assumptions.csv"), nrows = 0,
  colClasses = "character", check.names = FALSE
))

input_rows <- function(type, measure, basis, year, age, value, unit,
                       fleet = "", survey = "", sampling_time = NA_real_,
                       source_type = "native_model", source_reference,
                       transformation = "Copied from the cached official SAM run.",
                       notes = "") {
  n <- length(value)
  out <- empty_rows(input_schema, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$basis <- rep_len(basis, n)
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$year <- ifelse(is.na(rep_len(year, n)), "", as.character(rep_len(year, n)))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", as.character(rep_len(age, n)))
  out$value <- format_value(rep_len(value, n))
  out$unit <- rep_len(unit, n)
  out$sampling_time <- ifelse(is.finite(rep_len(sampling_time, n)),
    format_value(rep_len(sampling_time, n)), ""
  )
  out$source_type <- rep_len(source_type, n)
  out$source_reference <- rep_len(source_reference, n)
  out$transformation <- rep_len(transformation, n)
  out$notes <- rep_len(notes, n)
  out
}

output_rows <- function(type, measure, year, age = NA_integer_, age_group = "",
                        value, unit, fleet = "", survey = "", se = NA_real_,
                        lwr = NA_real_, upr = NA_real_,
                        source_type = "native_model", source_reference,
                        notes = "") {
  n <- length(value)
  out <- empty_rows(output_schema, n)
  out$assessment_id <- assessment_id
  out$type <- type
  out$measure <- measure
  out$year <- ifelse(is.na(rep_len(year, n)), "", as.character(rep_len(year, n)))
  out$age <- ifelse(is.na(rep_len(age, n)), "", as.character(rep_len(age, n)))
  out$age_group <- rep_len(age_group, n)
  out$fleet <- rep_len(fleet, n)
  out$survey <- rep_len(survey, n)
  out$value <- format_value(rep_len(value, n))
  out$se <- format_value(rep_len(se, n))
  out$lwr <- format_value(rep_len(lwr, n))
  out$upr <- format_value(rep_len(upr, n))
  out$unit <- rep_len(unit, n)
  out$source_type <- rep_len(source_type, n)
  out$source_reference <- rep_len(source_reference, n)
  out$notes <- rep_len(notes, n)
  out
}

assumption_rows <- function(component, setting, value, source_reference, notes = "",
                            survey = "") {
  out <- empty_rows(assumption_schema, length(value))
  out$assessment_id <- assessment_id
  out$component <- component
  out$survey <- rep_len(survey, length(value))
  out$setting <- setting
  out$value <- value
  out$source_reference <- source_reference
  out$notes <- rep_len(notes, length(value))
  out
}

matrix_input <- function(x, type, measure, basis, unit, years, ages,
                         source_reference, transformation, notes = "",
                         fleet = "", survey = "", source_type = "native_model") {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (!identical(dim(x), c(length(years), length(ages)))) {
    stop("Unexpected matrix dimensions for ", measure, ".", call. = FALSE)
  }
  grid <- expand.grid(year = years, age = ages)
  values <- as.vector(x)
  keep <- is.finite(values)
  input_rows(type, measure, basis, grid$year[keep], grid$age[keep], values[keep], unit,
    fleet = fleet, survey = survey, source_type = source_type,
    source_reference = source_reference, transformation = transformation,
    notes = notes
  )
}

constant_age_input <- function(x, type, measure, basis, unit, ages,
                               source_reference, notes = "") {
  if (length(dim(x)) == 3L) x <- x[, , 1L]
  x <- as.matrix(x)
  if (ncol(x) != length(ages) || !all(x == matrix(x[1L, ], nrow(x), ncol(x), byrow = TRUE))) {
    stop("Expected a constant age vector for ", measure, ".", call. = FALSE)
  }
  input_rows(type, measure, basis, NA_integer_, ages, as.numeric(x[1L, ]), unit,
    source_reference = source_reference,
    transformation = "Stored once as the time-invariant age vector supplied to SAM.",
    notes = notes
  )
}

parse_report_summary <- function(path) {
  pages <- pdftools::pdf_text(path)
  page <- grep("Table 6[.]10[.] Sole 20-24[.]", pages, perl = TRUE)
  if (length(page) != 1L || page == length(pages)) {
    stop("Could not uniquely locate WGBFAS 2025 Table 6.10.", call. = FALSE)
  }
  lines <- unlist(strsplit(paste(pages[page:(page + 1L)], collapse = "\n"),
    "\n", fixed = TRUE
  ), use.names = FALSE)
  lines <- lines[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", lines, perl = TRUE)]
  rows <- lapply(lines, function(line) {
    cells <- strsplit(trimws(gsub("[[:space:]]+", " ", line)), " ", fixed = TRUE)[[1L]]
    values <- suppressWarnings(as.numeric(cells))
    if (length(values) != 13L || anyNA(values)) return(NULL)
    values
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) stop("No annual rows parsed from WGBFAS 2025 Table 6.10.", call. = FALSE)
  out <- as.data.frame(do.call(rbind, rows))
  names(out) <- c("year", "recruitment", "recruitment_lwr", "recruitment_upr",
    "ssb", "ssb_lwr", "ssb_upr", "Fbar", "Fbar_lwr", "Fbar_upr",
    "total_biomass", "total_biomass_lwr", "total_biomass_upr"
  )
  out$year <- as.integer(out$year)
  out
}

parse_sag_summary <- function(path) {
  doc <- xml2::read_html(path)
  rows <- xml2::xml_find_all(doc, "//tr")
  cells <- lapply(rows, function(row) {
    value <- trimws(xml2::xml_text(xml2::xml_find_all(row, "./th|./td")))
    value <- gsub("\u00a0", "", value, fixed = TRUE)
    trimws(value)
  })
  expected_header <- c("Year", "Low Recruitment", "Recruitment", "High Recruitment",
    "Low SSB", "SSB", "High SSB", "Landings", "Discards", "Low F", "F", "High F"
  )
  header <- which(vapply(cells, function(x) identical(x, expected_header), logical(1)))
  if (length(header) != 1L) stop("Could not uniquely locate the ICES SAG 2026 fish-data table.", call. = FALSE)
  data <- cells[(header + 1L):length(cells)]
  data <- Filter(function(x) length(x) == 12L && grepl("^(19|20)[0-9]{2}$", x[[1L]]), data)
  if (!length(data)) stop("No annual data rows parsed from ICES SAG 2026.", call. = FALSE)
  values <- lapply(seq_along(data), function(i) {
    raw <- data[[i]]
    numeric <- suppressWarnings(as.numeric(raw))
    invalid <- is.na(numeric[-1L]) & nzchar(raw[-1L])
    if (any(invalid)) {
      stop("Non-numeric cell in the ICES SAG 2026 fish-data table.", call. = FALSE)
    }
    numeric
  })
  out <- as.data.frame(do.call(rbind, values))
  names(out) <- c("year", "recruitment_lwr", "recruitment", "recruitment_upr",
    "ssb_lwr", "ssb", "ssb_upr", "landings", "discards", "F_lwr", "Fbar", "F_upr"
  )
  out$year <- as.integer(out$year)
  out
}

model_env <- new.env(parent = baseenv())
data_env <- new.env(parent = baseenv())
load(model_file, envir = model_env)
load(data_file, envir = data_env)
fit <- model_env$fit
dat <- fit$data
years <- as.integer(dat$years)
ages <- seq_len(ncol(dat$stockMeanWeight))
fleet_names <- attr(dat, "fleetNames")
sample_times <- as.numeric(dat$sampleTimes)
aux <- as.data.frame(dat$aux, stringsAsFactors = FALSE)
names(aux) <- c("year", "fleet", "age")

if (!inherits(fit, "sam") || fit$opt$convergence != 0L ||
  !identical(as.integer(data_env$dat$years), years) ||
  !identical(as.numeric(data_env$dat$logobs), as.numeric(dat$logobs)) ||
  !identical(years, 1984:2024) || !identical(ages, 1:9) ||
  fit$data$nobs != 725L || !identical(as.integer(table(aux$fleet)), c(328L, 189L, 98L, 110L)) ||
  !identical(sample_times, c(0, 0.8754645, 0.56, 0.875)) ||
  !identical(dim(fit$pl$logN), c(9L, 41L)) || !identical(dim(fit$pl$logF), c(5L, 41L))) {
  stop("The cached SAM fit does not match the pinned 2025 assessment structure.", call. = FALSE)
}

report_summary <- parse_report_summary(report_file)
if (!identical(report_summary$year, years)) {
  stop("WGBFAS 2025 Table 6.10 does not cover the native fitted years.", call. = FALSE)
}
native_summary <- as.data.frame(summary(fit))
native_year <- as.integer(rownames(native_summary))
if (!identical(native_year, years) || ncol(native_summary) < 9L ||
  max(abs(native_summary[[1L]] - report_summary$recruitment)) > 1 ||
  max(abs(native_summary[[4L]] - report_summary$ssb)) > 1 ||
  max(abs(native_summary[[7L]] - report_summary$Fbar)) > 0.00051) {
  stop("Native SAM summary does not reproduce the WGBFAS 2025 report table.", call. = FALSE)
}

survey_names <- unname(fleet_names[-1L])
obs_rows <- lapply(seq_along(fleet_names), function(fleet_id) {
  take <- which(aux$fleet == fleet_id)
  if (fleet_id == 1L) {
    input_rows("catch", "numbers_at_age", "numbers", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "thousand fish", fleet = fleet_names[[fleet_id]],
      sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux; data/cn.dat"),
      transformation = "Exponentiated the official SAM log catch observation.",
      notes = "Official landings-only residual catch-at-age; age 9 is the 9+ group. Discards are excluded from the assessment."
    )
  } else {
    input_rows("index", "numbers_at_age", "index_scale", aux$year[take], aux$age[take],
      exp(dat$logobs[take]), "native survey-index units", survey = survey_names[[fleet_id - 1L]],
      sampling_time = sample_times[[fleet_id]],
      source_reference = paste0(model_url, "; fit$data$logobs and fit$data$aux; data/survey.dat"),
      transformation = "Exponentiated the official SAM log index observation; missing years remain blank.",
      notes = "Relative index scale; no physical abundance multiplier is stated in the source."
    )
  }
})

input_parts <- c(obs_rows, list(
  matrix_input(dat$stockMeanWeight, "weight", "weight_at_age", "kg_per_fish",
    "kg per fish", years, ages,
    paste0(model_url, "; fit$data$stockMeanWeight; data/sw.dat"),
    "Copied annual SAM stock-weight observations.",
    notes = "The source SAM estimates a stock-weight process from these annual observations; tinyAM treats the supplied values as fixed weights."
  ),
  matrix_input(dat$catchMeanWeight, "catch_weight", "weight_at_age", "kg_per_fish",
    "kg per fish", years, ages,
    paste0(model_url, "; fit$data$catchMeanWeight; data/cw.dat"),
    "Copied annual SAM catch-weight observations.",
    notes = "The source SAM estimates a catch-weight process from these annual observations; tinyAM treats the supplied values as fixed weights."
  ),
  matrix_input(dat$landMeanWeight, "catch_weight", "landings_weight_at_age", "kg_per_fish",
    "kg per fish", years, ages,
    paste0(model_url, "; fit$data$landMeanWeight; data/lw.dat"),
    "Copied the native landings-weight input array.",
    notes = "Landings are the only removals included in the fitted assessment."
  ),
  matrix_input(dat$disMeanWeight, "catch_weight", "discard_weight_at_age", "kg_per_fish",
    "kg per fish", years, ages,
    paste0(model_url, "; fit$data$disMeanWeight; data/dw.dat"),
    "Copied the native discard-weight input array.",
    notes = "The zero values are SAM data-array placeholders; discards were excluded from the fitted assessment."
  ),
  matrix_input(dat$landFrac, "catch", "landings_fraction_at_age", "proportion",
    "proportion", years, ages,
    paste0(model_url, "; fit$data$landFrac; data/lf.dat"),
    "Copied the native landings-fraction input array.",
    notes = "The assessment uses landings only; the fitted catch is represented as landings."
  ),
  constant_age_input(dat$natMor, "M", "natural_mortality_at_age", "per_year",
    "per year", ages,
    paste0(model_url, "; fit$data$natMor; data/nm.dat"),
    "Natural mortality is fixed at 0.1 per year at all ages and years."
  ),
  constant_age_input(dat$propMat, "maturity", "maturity_at_age", "proportion",
    "proportion", ages,
    paste0(model_url, "; fit$data$propMat; data/mo.dat"),
    "Maturity is fixed at zero through age 2 and one from age 3 onward."
  ),
  constant_age_input(dat$propF, "biology", "fraction_F_before_spawning", "proportion",
    "proportion", ages,
    paste0(model_url, "; fit$data$propF; data/pf.dat"),
    "The source SAM supplies zero fishing mortality before spawning."
  ),
  constant_age_input(dat$propM, "biology", "fraction_M_before_spawning", "proportion",
    "proportion", ages,
    paste0(model_url, "; fit$data$propM; data/pm.dat"),
    "The source SAM supplies zero natural mortality before spawning."
  )
))

cv <- as.matrix(read.table(cv_file, header = TRUE, row.names = 1,
  check.names = FALSE, na.strings = c("NA", ""), stringsAsFactors = FALSE
))
cv_grid <- expand.grid(year = as.integer(rownames(cv)), age = as.integer(colnames(cv)))
cv_values <- as.vector(cv)
cv_keep <- is.finite(cv_values)
cv_rows <- input_rows("index", "relative_standard_error", "relative_scale",
  cv_grid$year[cv_keep], cv_grid$age[cv_keep], cv_values[cv_keep], "proportion",
  survey = survey_names[[1L]], source_reference = paste0(data_url, "Sole2024-CV.csv"),
  transformation = "Copied the original age-year survey CV values.",
  notes = "CVs are preserved on their source proportion scale; missing survey years remain absent."
)
cv_mean <- mean(cv_values, na.rm = TRUE)
survey_take <- which(aux$fleet == 2L & is.finite(dat$weight))
weight_rows <- input_rows("index", "relative_precision_weight", "relative_precision",
  aux$year[survey_take], aux$age[survey_take], dat$weight[survey_take], "relative weight",
  survey = survey_names[[1L]], source_reference = paste0(model_url, "; fit$data$weight"),
  transformation = "SAM normalizes the supplied CV matrix by its overall mean and uses 1/(CV/mean(CV))^2 as a relative precision weight.",
  notes = "fixVarToWeight=0; these weights scale relative precision and do not fix the observation variance."
)
cv_weight <- 1 / (cv_values / cv_mean)^2
cv_index <- match(paste(aux$year[survey_take], aux$age[survey_take]),
  paste(cv_grid$year, cv_grid$age)
)
if (anyNA(cv_index) || max(abs(cv_weight[cv_index] - dat$weight[survey_take])) > 1e-8) {
  stop("The cached CV file does not reproduce the SAM relative survey weights.", call. = FALSE)
}

inputs <- do.call(rbind, c(input_parts, list(cv_rows, weight_rows)))

key_logf <- as.integer(fit$conf$keyLogFsta[1L, ])
logf_keys <- sort(unique(key_logf[key_logf >= 0L]))
if (!identical(logf_keys, 0:4)) stop("Unexpected F-age sharing keys.", call. = FALSE)
log_n <- t(fit$pl$logN)
se_log_n <- t(fit$plsd$logN)
n_surface <- exp(log_n)
log_f <- matrix(NA_real_, nrow = length(years), ncol = length(ages))
se_log_f <- log_f
for (age in ages) {
  key <- key_logf[[age]]
  if (key >= 0L) {
    log_f[, age] <- fit$pl$logF[key + 1L, ]
    se_log_f[, age] <- fit$plsd$logF[key + 1L, ]
  }
}
f_surface <- exp(log_f)

surface_output <- function(x, se, type, measure, unit, slot, notes,
                           source_reference, plus_age = 9L) {
  grid <- expand.grid(year = years, age = ages)
  value <- as.vector(x)
  se_value <- as.vector(se)
  keep <- is.finite(value)
  age_group <- ifelse(grid$age[keep] == plus_age, paste0(plus_age, "+"), "")
  output_rows(type, measure, grid$year[keep], grid$age[keep], age_group,
    value[keep], unit, se = se_value[keep],
    source_reference = paste0(source_reference, "; exp(t(fit$pl$", slot, "))"),
    notes = notes
  )
}

age_outputs <- rbind(
  surface_output(n_surface, se_log_n, "population", "numbers_at_age", "thousand fish",
    "logN", "Native SAM fitted abundance; age 9 is the 9+ group. The reported SE is the Hessian SE of log N on the log scale; the report tables do not publish age-specific intervals.", model_url
  ),
  surface_output(f_surface, se_log_f, "mortality", "fishing_mortality_at_age", "per year",
    "logF", "Native SAM fitted fishing mortality; age 1 is not estimated, ages 2-5 have separate states, and ages 6-9 share one state. The reported SE is on the log-F scale; the report tables do not publish age-specific intervals.", model_url
  )
)

total_abundance <- rowSums(n_surface)
derived_abundance <- output_rows("population", "total_numbers", years,
  value = total_abundance, unit = "thousand fish",
  source_type = "derived_source_output",
  source_reference = paste0(model_url, "; exp(t(fit$pl$logN))"),
  notes = "Derived as the sum of SAM N-at-age over ages 1-9; no uncertainty is available for this sum."
)

summary_outputs <- rbind(
  output_rows("recruitment", "recruitment", report_summary$year, age = 1L,
    value = report_summary$recruitment, unit = "thousand fish",
    lwr = report_summary$recruitment_lwr, upr = report_summary$recruitment_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.10, PDF pp. 507-508"),
    notes = "SAM recruitment at age 1; Table 6.10 states the low/high values are 95% confidence limits."
  ),
  output_rows("biomass", "SSB", report_summary$year,
    value = report_summary$ssb, unit = "tonnes",
    lwr = report_summary$ssb_lwr, upr = report_summary$ssb_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.10, PDF pp. 507-508"),
    notes = "Native SAM spawning stock biomass; Table 6.10 states the low/high values are 95% confidence limits."
  ),
  output_rows("mortality", "Fbar", report_summary$year, age_group = "4-8",
    value = report_summary$Fbar, unit = "per year",
    lwr = report_summary$Fbar_lwr, upr = report_summary$Fbar_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.10, PDF pp. 507-508"),
    notes = "Native mean fishing mortality for ages 4-8; Table 6.10 states the low/high values are 95% confidence limits."
  ),
  output_rows("biomass", "total_biomass", report_summary$year,
    value = report_summary$total_biomass, unit = "tonnes",
    lwr = report_summary$total_biomass_lwr, upr = report_summary$total_biomass_upr,
    source_type = "official_table",
    source_reference = paste0(report_url, "; WGBFAS 2025 Table 6.10, PDF pp. 507-508"),
    notes = "Native SAM total stock biomass; Table 6.10 states the low/high values are 95% confidence limits."
  )
)

predicted_values <- exp(fit$rep$predObs)
predicted_outputs <- lapply(seq_len(4L), function(fleet_id) {
  take <- which(aux$fleet == fleet_id)
  if (fleet_id == 1L) {
    output_rows("catch", "predicted_catch", aux$year[take], aux$age[take],
      ifelse(aux$age[take] == 9L, "9+", ""), predicted_values[take], "thousand fish",
      fleet = fleet_names[[fleet_id]],
      source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
      notes = "Exponentiated SAM fitted catch prediction on the observation scale."
    )
  } else {
    output_rows("index", "predicted_index", aux$year[take], aux$age[take],
      ifelse(aux$age[take] == 9L, "9+", ""), predicted_values[take], "native survey-index units",
      survey = survey_names[[fleet_id - 1L]],
      source_reference = paste0(model_url, "; fit$rep$predObs and fit$data$aux"),
      notes = "Exponentiated SAM fitted index prediction on the native index scale; values are retained for years with missing observations."
    )
  }
})
outputs <- rbind(age_outputs, derived_abundance, summary_outputs,
  do.call(rbind, predicted_outputs)
)

sag <- parse_sag_summary(sag_file)
if (!identical(sag$year, 1984:2026) ||
  sag$recruitment[sag$year == 2024] != 1408 ||
  sag$ssb[sag$year == 2024] != 1469 ||
  sag$ssb[sag$year == 2026] != 1491) {
  stop("ICES SAG 2026 series did not match the archived 2026 summary values.", call. = FALSE)
}
summary_outputs_2026 <- rbind(
  output_rows("recruitment", "recruitment", sag$year[is.finite(sag$recruitment)], age = 1L,
    value = sag$recruitment[is.finite(sag$recruitment)], unit = "thousand fish",
    lwr = sag$recruitment_lwr[is.finite(sag$recruitment)],
    upr = sag$recruitment_upr[is.finite(sag$recruitment)],
    source_type = "official_machine_readable", source_reference = sag_url,
    notes = "ICES SAG 2026 age-1 recruitment and published low/high bounds; the archived source-data page does not identify the interval construction. Kept separate from the 2025 detailed assessment."
  ),
  output_rows("biomass", "SSB", sag$year[is.finite(sag$ssb)],
    value = sag$ssb[is.finite(sag$ssb)], unit = "tonnes",
    lwr = sag$ssb_lwr[is.finite(sag$ssb)], upr = sag$ssb_upr[is.finite(sag$ssb)],
    source_type = "official_machine_readable", source_reference = sag_url,
    notes = "ICES SAG 2026 SSB and published low/high bounds; the archived source-data page does not identify the interval construction. Kept separate from the 2025 detailed assessment."
  ),
  output_rows("mortality", "Fbar", sag$year[is.finite(sag$Fbar)], age_group = "4-8",
    value = sag$Fbar[is.finite(sag$Fbar)], unit = "per year",
    lwr = sag$F_lwr[is.finite(sag$Fbar)], upr = sag$F_upr[is.finite(sag$Fbar)],
    source_type = "official_machine_readable", source_reference = sag_url,
    notes = "ICES SAG 2026 F for ages 4-8 and published low/high bounds; the archived source-data page does not identify the interval construction."
  )
)
summary_outputs_2026$assessment_id <- summary_assessment_id

assumptions <- do.call(rbind, list(
  assumption_rows("model", "model_age_range", "1984-2024; ages 1-9, with age 9 as 9+", paste0(report_url, "; Tables 6.5-6.10")),
  assumption_rows("model", "assessment_area", "ICES stock sol.27.20-24; single assessment unit across subdivisions 20-24", report_url),
  assumption_rows("N", "recruitment", "age 1; stockRecruitmentModelCode=0 (random walk)", paste0(model_url, "; fit$conf$stockRecruitmentModelCode")),
  assumption_rows("N", "process_variance_sharing", "age 1 separate; ages 2-9 share one variance", paste0(model_url, "; fit$conf$keyVarLogN")),
  assumption_rows("F", "process", "random walk with compound-symmetry age correlation", paste0(model_url, "; fit$conf$corFlag and fit$conf$keyVarF")),
  assumption_rows("F", "age_state_sharing", "age 1 not estimated; ages 2-5 separate; ages 6-9 share one state", paste0(model_url, "; fit$conf$keyLogFsta")),
  assumption_rows("F", "Fbar_ages", "4-8", paste0(report_url, "; Table 6.10")),
  assumption_rows("M", "natural_mortality", "fixed at 0.1 per year for all ages and years", paste0(report_url, "; Section 6.2.4 and data/nm.dat")),
  assumption_rows("biology", "maturity", "zero at ages 1-2; one at ages 3-9", paste0(report_url, "; Section 6.2.3 and data/mo.dat")),
  assumption_rows("biology", "weight_process", "stock and catch weights are modeled as observations in SAM", paste0(model_url, "; fit$conf$stockWeightModel and fit$conf$catchWeightModel")),
  assumption_rows("biology", "spawning_timing", "propF=0; propM=0", paste0(model_url, "; fit$data$propF and fit$data$propM")),
  assumption_rows("catch", "removals", "landings only; discards are excluded from the fitted assessment", paste0(report_url, "; Section 6.1.2")),
  assumption_rows("catch", "likelihood", "lognormal; independent age residuals; age-grouped observation variance", paste0(model_url, "; fit$conf$obsLikelihoodFlag, obsCorStruct and keyVarObs")),
  assumption_rows("index", "survey_periods_and_ages", "Q4 Sole survey ages 1-9+ in 2004-2024; gillnet CPUE ages 2-8 in 1994-2007; trawl CPUE ages 2-6 in 1987-2008", paste0(report_url, "; Table 6.5 and Section 6.3.1")),
  assumption_rows("index", "survey_timing", as.character(sample_times[-1L]), paste0(model_url, "; fit$data$sampleTimes"), survey = survey_names),
  assumption_rows("index", "q_age_groups", "Q4: age 1, age 2, age 3, ages 4-9; gillnet: ages 2, 3, 4, ages 5-8; trawl: ages 2, 3, 4, ages 5-6", paste0(model_url, "; fit$conf$keyLogFpar")),
  assumption_rows("index", "likelihood", "lognormal; age-residual structures ID, ID, AR(1), ID across catch, Q4 survey, gillnet and trawl", paste0(model_url, "; fit$conf$obsLikelihoodFlag and fit$conf$obsCorStruct")),
  assumption_rows("index", "Q4_precision_weights", "relative weights = 1/(CV/mean(CV))^2; CV matrix mean is over available age-year cells", paste0(data_url, "Sole2024-CV.csv; fit$data$weight")),
  assumption_rows("fit", "optimizer", fit$opt$message, model_url, paste0("Convergence code ", fit$opt$convergence, "; objective ", signif(fit$opt$objective, 8), "; stockassessment version ", attr(fit, "Version"), "; upstream SHA ", attr(fit, "RemoteSha"), "."))
))

stock_rows <- read_db("stocks.csv")
stock_index <- which(stock_rows$stock_id == stock_id)
if (length(stock_index) != 1L) {
  stop("Expected exactly one existing metadata row for the ICES sole stock.", call. = FALSE)
}
if (!is.na(stock_rows$authority_stock_id[stock_index]) &&
  nzchar(stock_rows$authority_stock_id[stock_index]) &&
  stock_rows$authority_stock_id[stock_index] != "sol.27.20-24") {
  stop("The existing ICES stock identifier conflicts with sol.27.20-24.", call. = FALSE)
}
if (!is.na(stock_rows$common_name[stock_index]) &&
  nzchar(stock_rows$common_name[stock_index]) &&
  stock_rows$common_name[stock_index] != "Common sole") {
  stop("The existing common name conflicts with this ICES stock.", call. = FALSE)
}
stock_rows$authority_stock_id[stock_index] <- "sol.27.20-24"
stock_rows$common_name[stock_index] <- "Common sole"
existing_notes <- stock_rows$notes[stock_index]
if (is.na(existing_notes)) existing_notes <- ""
stock_rows$notes[stock_index] <- paste(
  existing_notes,
  "Verified against the ICES WGBFAS 2025 assessment for stock sol.27.20-24; the 2025 fitted record is based on a cached official SAM run.",
  sep = " "
)
assessment_rows <- read_db("assessments.csv")
if (any(assessment_rows$stock_id == stock_id) ||
  any(assessment_rows$assessment_id %in% c(assessment_id, summary_assessment_id))) {
  stop("Unexpected assessment row already exists for this stock.", call. = FALSE)
}

assessment_2025 <- data.frame(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2024L,
  assessment_type = "annual_assessment", model_family = "SAM",
  model_version = paste0("WGBFAS 2025; stockassessment ", attr(fit, "Version"), "; ", attr(fit, "RemoteSha")),
  is_current = TRUE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = report_url, framework_url = "", data_url = data_url,
  model_url = model_url, repository_url = "",
  assumptions_status = "complete", inputs_status = "complete", outputs_status = "partial",
  notes = "Native fitted inputs, age-specific states, fitted observation predictions, and Table 6.10 annual summaries are recovered for 1984-2024. Forecast tables 6.11-6.12 are not included in the canonical output series. The 2026 summary-only update is stored separately.",
  stringsAsFactors = FALSE, check.names = FALSE
)
assessment_2026 <- data.frame(
  assessment_id = summary_assessment_id, stock_id = stock_id,
  assessment_year = 2026L, terminal_year = 2025L, estimate_terminal_year = 2026L,
  assessment_type = "summary_update", model_family = "SAM", model_version = "WGBFAS 2026 update; detailed native run not recovered",
  is_current = FALSE, is_applied = TRUE, framework_year = NA_integer_,
  assessment_url = sag_report_url, framework_url = "", data_url = sag_url,
  model_url = "", repository_url = "",
  assumptions_status = "not_started", inputs_status = "not_started", outputs_status = "partial",
  notes = "The WGBFAS 2026 report confirms an accepted SAM update for sol.27.20-24; the ICES SAG series provides aggregate recruitment, SSB and Fbar through 2025 and a 2026 summary projection. Detailed native inputs, assumptions, and age-specific outputs were not recovered. The 2026 summary values are kept separate from the 2025 detailed SAM run.",
  stringsAsFactors = FALSE, check.names = FALSE
)

if (!identical(names(assessment_2025), names(assessment_rows)) ||
  !identical(names(assessment_2026), names(assessment_rows)) ||
  !identical(names(inputs), input_schema) || !identical(names(outputs), output_schema) ||
  !identical(names(assumptions), assumption_schema) ||
  nrow(inputs) == 0L || nrow(outputs) == 0L || nrow(assumptions) == 0L) {
  stop("Unexpected database schema or empty imported records.", call. = FALSE)
}

assessment_rows_new <- rbind(assessment_2025, assessment_2026)
append_rows <- function(name, rows) {
  path <- file.path(database, name)
  existing_header <- names(utils::read.csv(path, nrows = 0, colClasses = "character",
    na.strings = "", check.names = FALSE
  ))
  if (!identical(existing_header, names(rows))) {
    stop("Unexpected column schema in ", name, ".", call. = FALSE)
  }
  utils::write.table(rows, path, sep = ",", quote = TRUE,
    row.names = FALSE, col.names = FALSE, append = TRUE, na = ""
  )
}

replace_stock_row(file.path(database, "stocks.csv"), stock_id,
  stock_rows[stock_index, , drop = FALSE]
)

for (table in c("assessments.csv", "assumptions.csv", "inputs.csv", "outputs.csv")) {
  path <- file.path(database, table)
  rows <- switch(table,
    "assessments.csv" = assessment_rows_new,
    "assumptions.csv" = assumptions,
    "inputs.csv" = inputs,
    "outputs.csv" = rbind(outputs, summary_outputs_2026)
  )
  append_rows(table, rows)
}

cat("Imported ICES sole 20-24 2025 fitted data and separate 2026 SAG summaries: ",
  nrow(inputs), " inputs, ", nrow(assumptions), " assumptions, and ",
  nrow(outputs) + nrow(summary_outputs_2026), " outputs.\n", sep = "")
