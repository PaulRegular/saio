base <- "."
database <- file.path(base, "database")
cache <- file.path(base, "source_cache", "ck_nefsc_garmiii_saxatilis_gom_chatt")
assessment_id <- "asmfc_striped_bass_atlantic_2018"
stock_id <- "ck_nefsc_garmiii_saxatilis_gom_chatt"
report_url <- "https://repository.library.noaa.gov/view/noaa/23031/noaa_23031_DS1.pdf"
report_file <- file.path(cache, "SAW66_2018_framework.pdf")
report_hash <- "c6136a0a25282e786bc06c4f3ca16797646db7b2862da97450458b9096cc4448"

actual_hash <- digest::digest(
  readBin(report_file, "raw", n = file.info(report_file)$size),
  serialize = FALSE, algo = "sha256"
)
if (!identical(actual_hash, report_hash)) cli::cli_abort("The cached SAW-66 report does not match its reviewed checksum.")
text <- pdftools::pdf_text(report_file)
words <- pdftools::pdf_data(report_file)
years <- 1982:2017
ages <- 1:15

num <- function(x) suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
text_rows <- function(pages, n_values, years = 1982:2017) {
  lines <- unlist(lapply(text[pages], function(x) strsplit(x, "\n", fixed = TRUE)[[1]]))
  lines <- trimws(lines[grepl("^\\s*(19|20)[0-9]{2}\\s", lines, perl = TRUE)])
  rows <- lapply(lines, function(line) {
    cells <- strsplit(gsub(",", "", trimws(line), fixed = TRUE), "[[:space:]]+")[[1]]
    suppressWarnings(as.numeric(cells))
  })
  rows <- rows[vapply(rows, length, integer(1)) == n_values + 1L]
  if (!length(rows)) cli::cli_abort("Could not parse the requested annual table.")
  x <- do.call(rbind, rows)
  x <- x[x[, 1] %in% years, , drop = FALSE]
  x <- x[order(x[, 1]), , drop = FALSE]
  if (!identical(as.integer(x[, 1]), as.integer(years))) cli::cli_abort("Annual table does not cover the expected years.")
  x[, -1, drop = FALSE]
}

age_table <- function(page, columns, years = 1982:2017) {
  d <- words[[page]]
  headers <- d[d$text %in% columns, , drop = FALSE]
  complete_headers <- vapply(split(headers$text, headers$y), function(x) all(columns %in% x), logical(1))
  header_y <- as.numeric(names(complete_headers)[complete_headers])
  if (length(header_y) != 1L) cli::cli_abort("Could not uniquely identify year-age table columns on PDF page {page}.")
  h <- headers[headers$y == header_y, , drop = FALSE]
  h <- h[match(columns, h$text), , drop = FALSE]
  centers <- h$x + h$width / 2
  yr <- d[d$text %in% as.character(years) & d$x < 105 & d$y > header_y, , drop = FALSE]
  rows <- lapply(seq_len(nrow(yr)), function(i) {
    row <- d[d$y == yr$y[i] & d$x > 105, , drop = FALSE]
    values <- rep(NA_real_, length(columns))
    for (j in seq_len(nrow(row))) {
      k <- which.min(abs((row$x[j] + row$width[j] / 2) - centers))
      if (abs((row$x[j] + row$width[j] / 2) - centers[k]) < 15) values[k] <- num(row$text[j])
    }
    c(year = as.numeric(yr$text[i]), values)
  })
  x <- do.call(rbind, rows)
  x <- x[order(x[, 1]), , drop = FALSE]
  if (!identical(as.integer(x[, 1]), as.integer(years))) cli::cli_abort("Year-age table on page {page} does not cover expected years.")
  x[, -1, drop = FALSE]
}

catch_pages <- c(`Chesapeake Bay` = 1101L, Coast = 1102L)
catch <- do.call(rbind, lapply(names(catch_pages), function(fleet) {
  x <- text_rows(catch_pages[[fleet]], 17L)
  data.frame(year = years, fleet = fleet, total = x[, 1], cv = x[, 2],
    x[, 3:17], check.names = FALSE)
}))
colnames(catch)[5:19] <- paste0("age_", ages)

index_names <- list(
  `Age-1+` = c("MRIP CPUE", "CT LISTS", "NY OHS", "NJ OT", "DE SSN", "DE 30'", "MD SSN", "ChesMMAP"),
  Recruitment = c("NY YOY", "NY Age-1", "NJ YOY", "MD YOY", "MD Age-1", "VA YOY", "MDVA YOY")
)
index_pages <- c(`Age-1+` = 596L, Recruitment = 597L)
index_time <- c("MRIP CPUE" = .50, "CT LISTS" = .33, "NY OHS" = .75,
  "NJ OT" = .25, "DE SSN" = .25, "DE 30'" = .90, "MD SSN" = .25,
  "ChesMMAP" = .50, "NY YOY" = 0, "NY Age-1" = 0, "NJ YOY" = 0,
  "MD YOY" = 0, "MD Age-1" = 0, "VA YOY" = 0, "MDVA YOY" = 0)
index_age <- c("NY YOY" = 1, "NY Age-1" = 2, "NJ YOY" = 1,
  "MD YOY" = 1, "MD Age-1" = 2, "VA YOY" = 1, "MDVA YOY" = 1)
index_rows <- list()
for (kind in names(index_names)) {
  d <- words[[index_pages[[kind]]]]
  labels <- d[d$text %in% c("Index", "CV"), , drop = FALSE]
  complete_headers <- vapply(split(labels$text, labels$y), function(x) {
    sum(x == "Index") == length(index_names[[kind]]) && sum(x == "CV") == length(index_names[[kind]])
  }, logical(1))
  header_y <- as.numeric(names(complete_headers)[complete_headers])
  if (length(header_y) != 1L) cli::cli_abort("Could not identify index and CV columns for {kind}.")
  centers <- labels$x[labels$y == header_y] + labels$width[labels$y == header_y] / 2
  centers <- centers[order(labels$x[labels$y == header_y])]
  yr <- d[d$text %in% as.character(years) & d$x < 80 & d$y > header_y, , drop = FALSE]
  for (i in seq_len(nrow(yr))) {
    row <- d[d$y == yr$y[i] & d$x > 65, , drop = FALSE]
    values <- rep(NA_real_, length(centers))
    for (j in seq_len(nrow(row))) {
      k <- which.min(abs((row$x[j] + row$width[j] / 2) - centers))
      if (abs((row$x[j] + row$width[j] / 2) - centers[k]) < 15) values[k] <- num(row$text[j])
    }
    for (j in seq_along(index_names[[kind]])) {
      if (is.finite(values[2 * j - 1])) index_rows[[length(index_rows) + 1L]] <- data.frame(
        survey = index_names[[kind]][j], year = as.integer(yr$text[i]),
        value = values[2 * j - 1], cv = values[2 * j], sampling_time = index_time[index_names[[kind]][j]],
        linked_age = if (kind == "Recruitment") unname(index_age[index_names[[kind]][j]]) else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }
}
indices <- do.call(rbind, index_rows)

age_index_names <- c("MD SSN", "ChesMMAP", "DE SSN", "DE 30 Trawl", "NYOHS", "NJ Trawl", "CT Trawl", "MRIP")
age_index_timing <- c("MD SSN" = .25, "ChesMMAP" = .50, "DE SSN" = .25,
  "DE 30 Trawl" = .90, "NYOHS" = .75, "NJ Trawl" = .25, "CT Trawl" = .33, "MRIP" = .50)
age_index_data <- list(); active_index <- NULL
age_index_labels <- c(MDSSN = "MD SSN", CHESMAP = "ChesMMAP", CHESMMAP = "ChesMMAP",
  DESSN = "DE SSN", DE30TRAWL = "DE 30 Trawl", NYOHS = "NYOHS",
  NJTRAWL = "NJ Trawl", CTTRAWL = "CT Trawl", MRIP = "MRIP")
for (page in 662:665) {
  lines <- trimws(strsplit(text[[page]], "\n", fixed = TRUE)[[1]])
  for (line in lines) {
    line_key <- gsub("[^A-Z0-9]", "", toupper(line))
    label <- names(age_index_labels)[vapply(names(age_index_labels), function(s) startsWith(line_key, s), logical(1))]
    if (length(label)) active_index <- unname(age_index_labels[label[[1]]])
    if (!grepl("^(19|20)[0-9]{2}\\s", line) || is.null(active_index)) next
    cells <- strsplit(gsub(",", "", line), "[[:space:]]+")[[1]]
    if (length(cells) == 1L) next
    if (length(cells) != 16L) cli::cli_abort("Unexpected age-composition row for {active_index}: {line}")
    values <- num(cells[-1])
    keep <- is.finite(values) & values != -1
    if (any(keep)) age_index_data[[length(age_index_data) + 1L]] <- data.frame(
      survey = active_index, year = as.integer(cells[1]), age = unname(ages[keep]),
      value = unname(values[keep]), sampling_time = unname(age_index_timing[active_index]),
      stringsAsFactors = FALSE
    )
  }
}
age_indices <- do.call(rbind, age_index_data)

age_labels <- c(as.character(ages[1:14]), "15+")
weight_catch <- age_table(649L, age_labels)
weight_ssb <- age_table(650L, age_labels)
weight_start <- age_table(651L, age_labels)
F_age <- age_table(1111L, c(as.character(ages[1:14]), "15+"))
N_age <- age_table(1114L, c(as.character(ages[1:14]), "15+", "Total", "8+"))
SSB_age <- age_table(1115L, c(as.character(ages[1:14]), "15+", "Total", "SE"))

female_maturity <- c(0, 0, 0, .09, .32, .45, .84, .89, rep(1, 7))
female_fraction <- c(.53, .56, .56, .52, .57, .65, .73, .81, .88, .92, .95, .97, 1, 1, 1)
M <- c(1.13, .68, .45, .33, .25, .19, rep(.15, 9))
if (!identical(dim(N_age), c(36L, 17L)) || !identical(dim(SSB_age), c(36L, 17L)) ||
  !identical(dim(F_age), c(36L, 15L)) || !identical(dim(weight_start), c(36L, 15L)) ||
  any(abs(rowSums(catch[paste0("age_", ages)]) - 1) > .002) ||
  any(age_indices$value < 0 | age_indices$value > 1, na.rm = TRUE)) {
  cli::cli_abort("Recovered 2018 striped-bass tables failed the expected dimensions or composition checks.")
}

blank <- function(file, n) {
  fields <- names(read.csv(file.path(database, file), nrows = 0, check.names = FALSE))
  out <- as.data.frame(matrix("", n, length(fields)), stringsAsFactors = FALSE)
  names(out) <- fields; out$assessment_id <- assessment_id; out
}
fmt <- function(x) ifelse(is.na(x), "", format(x, digits = 15, trim = TRUE, scientific = FALSE))
input <- function(type, measure, basis, value, unit, year = NA, age = NA,
                  fleet = "", survey = "", sex = "", sampling_time = NA,
                  reference, notes, transformation = "") {
  n <- length(value); out <- blank("inputs.csv", n)
  out$type <- type; out$measure <- measure; out$basis <- basis
  out$value <- fmt(value); out$unit <- unit
  out$year <- ifelse(is.na(rep_len(year, n)), "", rep_len(year, n))
  out$year_basis <- ifelse(nzchar(out$year), "calendar_year", "")
  out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$fleet <- fleet; out$survey <- survey; out$sex <- sex
  out$sampling_time <- fmt(rep_len(sampling_time, n))
  out$source_type <- "official_table"; out$source_reference <- paste(report_url, reference, sep = "; ")
  out$transformation <- transformation; out$notes <- notes
  out
}

inputs <- rbind(
  input("catch", "total_numbers", "numbers", catch$total, "fish", year = catch$year,
    fleet = catch$fleet, reference = "Appendix B10, Table 2, PDF pp. 1101-1102",
    notes = "Total removals by fleet, including the source model's reported removals."),
  input("catch", "relative_standard_error", "relative_scale", catch$cv, "ratio", year = catch$year,
    fleet = catch$fleet, reference = "Appendix B10, Table 2, PDF pp. 1101-1102",
    notes = "Coefficient of variation for annual total removals."),
  input("catch", "proportion_at_age", "proportion_numbers", as.vector(t(as.matrix(catch[paste0("age_", ages)]))),
    "proportion", year = rep(catch$year, each = length(ages)), age = rep(ages, times = nrow(catch)),
    fleet = rep(catch$fleet, each = length(ages)), reference = "Appendix B10, Table 2, PDF pp. 1101-1102",
    notes = "Reported number proportions at age; retained with fleet totals. TinyAM translation multiplies these by the matching total without renormalizing."),
  input("index", "total_numbers", "index_scale", indices$value,
    "source index scale per effort unit", year = indices$year, age = indices$linked_age, survey = indices$survey,
    sampling_time = indices$sampling_time, reference = "Appendix B5, Tables B5.5-B5.6, PDF pp. 596-597",
    notes = "Native total relative-abundance index, not an absolute number of fish."),
  input("index", "abundance_index_cv", "relative_scale", indices$cv, "ratio",
    year = indices$year, survey = indices$survey, sampling_time = indices$sampling_time,
    reference = "Appendix B5, Tables B5.5-B5.6, PDF pp. 596-597",
    notes = "Reported coefficient of variation for the annual relative-abundance index."),
  input("index", "proportion_at_age", "proportion_numbers", age_indices$value, "proportion",
    year = age_indices$year, age = age_indices$age, survey = age_indices$survey,
    sampling_time = age_indices$sampling_time, reference = "Appendix B7, Table B7.5, PDF pp. 662-665",
    notes = "Age composition for an age-specific index. Source -1 cells mean unavailable and are omitted; printed zeros are retained. The published DE 30 Trawl 2017 row sums to 1.105 as printed; tinyAM normalizes available proportions during translation."),
  input("weight", "weight_at_age", "kg_per_fish", as.vector(t(weight_start)), "kg/fish",
    year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
    reference = "Appendix B6, Table B6.34(C), January-1 Rivard weights",
    notes = "January-1 Rivard weight-at-age."),
  input("weight", "spawning_weight_at_age", "kg_per_fish", as.vector(t(weight_ssb)), "kg/fish",
    year = rep(years, each = length(ages)), age = rep(ages, times = length(years)), sex = "female",
    reference = "Appendix B6, Table B6.34(B), spawning Rivard weights",
    notes = "Adjusted Rivard female spawning weight-at-age used to derive source SSB."),
  input("catch_weight", "catch_weight_at_age", "kg_per_fish", as.vector(t(weight_catch)), "kg/fish",
    year = rep(years, each = length(ages)), age = rep(ages, times = length(years)),
    reference = "Appendix B6, Table B6.34(A), catch weights",
    notes = "Catch weight-at-age; distinct from Jan-1 and spawning weights."),
  input("maturity", "maturity_at_age", "proportion", female_maturity, "proportion", age = ages,
    sex = "female", reference = "Main report Table 4, printed p. 13",
    notes = "Fixed female maturity; age 15 denotes 15+. Female fraction is stored separately."),
  input("biology", "proportion_female_at_age", "proportion", female_fraction, "proportion", age = ages,
    reference = "Main report Table 4, printed p. 13",
    notes = "Fixed proportion female in the both-sex population; age 15 denotes 15+."),
  input("M", "natural_mortality_at_age", "per_year", M, "per year", age = ages,
    reference = "Appendix B3, selected Curve Fit M vector; Main report Table 4",
    notes = "Fixed age-specific M; not an estimated output."))

assumption <- function(component, setting, value, notes, reference) {
  out <- blank("assumptions.csv", 1); out$component <- component; out$setting <- setting
  out$value <- value; out$source_reference <- paste(report_url, reference, sep = "; "); out$notes <- notes; out
}
assumptions <- rbind(
  assumption("assessment", "recommended_model", "Single-stock non-migration statistical catch-at-age model",
    "The peer-review panel recommended this model for management; the two-stock model was not accepted for advice.", "SAW-66 report, pp. 17-18 and Appendix B10, PDF pp. 1092-1115"),
  assumption("population", "years_ages_and_sexes", "1982-2017; ages 1-15+; both-sex abundance and female SSB",
    "Recruitment is age 1; abundance is reported at January 1. The plus group begins at 15.", "Appendix B10, Table 1 and Tables 10-11"),
  assumption("F", "fleet_structure", "Chesapeake Bay and Coast fleets",
    "The tinyAM translation pools the two fleet catch-at-age series; the source estimates fleet-specific F and selectivity.", "Appendix B10, Tables 1-2 and 9"),
  assumption("N", "recruitment_process", "IID normal log recruitment deviations with bias and sum constraints",
    "The exact nonlinear constraints and bias correction are not replicated by tinyAM's recruitment process.", "Appendix B10, Table 1"),
  assumption("M", "fixed_age_specific_M", "Fixed selected Curve Fit age-specific M",
    "The displayed vector is fixed, not estimated.", "Appendix B3 and Main report Table 4"),
  assumption("index", "age_index_compositions", "Eight age-specific indices",
    "Table B7.5 provides the published age compositions used for the corresponding survey series. The report does not expose the full run-specific preprocessing or effective sample sizes; compositions are retained as reported and translated with tinyAM's simpler index likelihood.", "Appendix B10, Table 1; Appendix B7, Table B7.5"),
  assumption("index", "recruitment_index_identity", "Six age-specific recruitment indices in the model; one Table 3 label differs from the source index table",
    "Appendix B10 Table 3 labels VA Age 1, while the index table and assessment diagnostics identify NY Age-1. The translation uses NY Age-1 for that series and excludes the separate VA YOY series from fitting; both are preserved in the database.", "Appendix B10, Table 3; Appendix B5, Table B5.6"),
  assumption("index", "survey_timing", "Table B10 mortality fractions before sampling used as sampling-time fractions",
    "These are source-model fractions of annual mortality, not observed survey dates; using them as tinyAM within-year timing is an approximation.", "Appendix B10, Table 3"),
  assumption("biology", "female_SSB", "January-1 N times female fraction, maturity and adjusted Rivard spawning weight",
    "Official SSB-at-age is retained separately. The matching biological calculation is a source consistency check, not a new official estimate.", "Appendix B6, Table B6.34(B); Main report Table 4; Appendix B10, Table 11"),
  assumption("assessment", "translation_limits", "Partial likelihood reconstruction",
    "The published report does not provide final effective composition sample sizes or all source configuration details. tinyAM uses pooled catch, simpler recruitment/F processes and no source-specific likelihood weighting.", "Appendix B10, Tables 1-4"))

output <- function(type, measure, value, unit, year = years, age = NA, group = "", sex = "",
                   se = NA, reference, notes) {
  n <- length(value); out <- blank("outputs.csv", n)
  out$type <- type; out$measure <- measure; out$value <- fmt(value); out$unit <- unit
  out$year <- rep_len(year, n); out$age <- ifelse(is.na(rep_len(age, n)), "", rep_len(age, n))
  out$age_group <- group; out$sex <- sex; out$se <- fmt(rep_len(se, n))
  out$source_type <- "official_table"; out$source_reference <- paste(report_url, reference, sep = "; "); out$notes <- notes
  out
}
grid <- expand.grid(year = years, age = ages, KEEP.OUT.ATTRS = FALSE)
N_out <- output("population", "numbers_at_age", as.vector(N_age[, 1:15]), "fish",
  grid$year, grid$age, group = ifelse(grid$age == 15, "15+", ""),
  reference = "Appendix B10, Table 10, PDF p. 1114", notes = "January-1 both-sex abundance; age 15 is the 15+ group. No age-specific uncertainty is tabulated.")
F_out <- output("mortality", "fishing_mortality_at_age", as.vector(F_age), "per year",
  grid$year, grid$age, group = ifelse(grid$age == 15, "15+", ""),
  reference = "Appendix B10, Table 9, PDF p. 1111", notes = "Total instantaneous F at age, rounded to three decimals; age 15 is the 15+ group.")
SSB_age_out <- output("biomass", "mature_biomass_at_age", as.vector(SSB_age[, 1:15]), "metric tons",
  grid$year, grid$age, group = ifelse(grid$age == 15, "15+", ""), sex = "female",
  reference = "Appendix B10, Table 11, PDF p. 1115", notes = "Official female spawning-biomass contribution by age; source age values are rounded to whole tonnes.")
aggregate_out <- rbind(
  output("population", "total_numbers", N_age[, 16], "fish", reference = "Appendix B10, Table 10, PDF p. 1114", notes = "Reported January-1 abundance total; both sexes."),
  output("population", "total_numbers_age8plus", N_age[, 17], "fish", group = "8+", reference = "Appendix B10, Table 10, PDF p. 1114", notes = "Native total of ages 8 and older."),
  output("recruitment", "recruitment", N_age[, 1], "fish", age = 1, reference = "Appendix B10, Table 10, PDF p. 1114", notes = "Same-year January-1 age-1 abundance; no recruitment uncertainty tabulated."),
  output("biomass", "SSB", SSB_age[, 16], "metric tons", sex = "female", se = SSB_age[, 17], reference = "Appendix B10, Table 11, PDF p. 1115", notes = "Reported female SSB with natural-scale standard error in metric tons; no interval bounds tabulated."))
outputs <- rbind(N_out, F_out, SSB_age_out, aggregate_out)

assessment <- blank("assessments.csv", 1)
assessment$stock_id <- stock_id; assessment$assessment_year <- 2018
assessment$terminal_year <- assessment$estimate_terminal_year <- 2017
assessment$assessment_type <- "benchmark"; assessment$model_family <- "Statistical catch-at-age"
assessment$model_version <- "2018 SAW/SARC-66 recommended single-stock non-migration SCA"
assessment$is_current <- "FALSE"; assessment$is_applied <- "TRUE"; assessment$framework_year <- 2018
assessment$assessment_url <- report_url; assessment$framework_url <- report_url
assessment$assumptions_status <- assessment$inputs_status <- assessment$outputs_status <- "partial"
assessment$notes <- "Historical 2018 recommended single-stock model, distinct from the official 2024 update. Published catch, index, composition, biology and population tables are recovered; effective composition sample sizes and complete native configuration are not. The 2024 record remains the latest assessment event and is not filled with 2018 observations."

read_db <- function(file) read.csv(file.path(database, file), colClasses = "character", na.strings = "", check.names = FALSE)
stocks <- read_db("stocks.csv")
if (sum(stocks$stock_id == stock_id) != 1L) cli::cli_abort("Expected one existing striped-bass stock record.")
write_rows <- function(file, x, id) {
  path <- file.path(database, file)
  names_expected <- names(read.csv(path, nrows = 0, check.names = FALSE))
  if (!identical(names(x), names_expected)) cli::cli_abort("Unexpected columns for {file}.")
  tmp <- tempfile(tmpdir = database); on.exit(unlink(tmp), add = TRUE)
  write.table(x, tmp, sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE, na = "", fileEncoding = "UTF-8")
  rows <- readBin(tmp, "raw", n = file.info(tmp)$size)
  con <- file(path, open = "ab"); on.exit(close(con), add = TRUE)
  size <- file.info(path)$size
  if (size > 0) {
    last_con <- file(path, open = "rb")
    seek(last_con, where = size - 1, origin = "start")
    last_byte <- readBin(last_con, "raw", n = 1L)
    close(last_con)
    if (!identical(last_byte, as.raw(10L))) writeBin(as.raw(10L), con)
  }
  writeBin(rows, con)
}
if (assessment_id %in% read.csv(file.path(database, "assessments.csv"),
  colClasses = "character", check.names = FALSE)$assessment_id) {
  cli::cli_abort("The 2018 assessment record already exists; inspect before reimporting.")
}
write_rows("assessments.csv", assessment, assessment_id)
write_rows("assumptions.csv", assumptions, assessment_id)
write_rows("inputs.csv", inputs, assessment_id)
write_rows("outputs.csv", outputs, assessment_id)
cat("Imported 2018 striped bass:", nrow(inputs), "inputs,", nrow(assumptions), "assumptions and", nrow(outputs), "outputs.\n")



