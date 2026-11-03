root <- "."
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)
database <- file.path(root, "database")
cache <- file.path(root, "source_cache", "discovery_noaa_sablefish_2025")
candidate_path <- file.path(root, "discovery", "candidates.csv")
inventory_path <- file.path(root, "discovery", "inventory_units.csv")
selected_path <- file.path(root, "discovery", "selected_batch_01_2026.csv")

candidate_id <- "NOAA:10466"
candidate_unit_id <- "noaa_stocksmart_10466"
stock_id <- "noaa_sablefish_pacific_coast"
assessment_id <- "noaa_sablefish_pacific_coast_2025"
model_dir <- file.path(cache, "2025_sablefish_model_files")
data_name <- "2025_sablefish_dat.ss"
control_name <- "2025_sablefish_ctl.ss"
weight_name <- "wtatage.ss"
report_name <- "Report.sso"
assessment_pdf <- "assessment_2025.pdf"
model_zip <- "model_files_2025.zip"

source(file.path(root, "scripts", "database", "candidate_register_io.R"))

read_table <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = c("", "NA"))
}

blank_row <- function(fields, values = list()) {
  row <- as.list(rep("", length(fields)))
  names(row) <- fields
  for (name in names(values)) row[[name]] <- as.character(values[[name]])
  as.data.frame(row, stringsAsFactors = FALSE, optional = TRUE)
}

new_row_store <- function() {
  store <- new.env(parent = emptyenv())
  store$count <- 0L
  store$add <- function(row) {
    store$count <- store$count + 1L
    assign(paste0("row", store$count), row, envir = store)
  }
  store$get <- function() {
    if (!store$count) return(list())
    mget(paste0("row", seq_len(store$count)), envir = store, inherits = FALSE)
  }
  store
}

rows_from <- function(fields, rows) {
  if (!length(rows)) return(blank_row(fields)[FALSE, , drop = FALSE])
  columns <- lapply(fields, function(field) vapply(rows, function(row) {
    value <- row[[field]]
    if (is.null(value) || !length(value)) "" else as.character(value)
  }, character(1L), USE.NAMES = FALSE))
  names(columns) <- fields
  as.data.frame(columns, stringsAsFactors = FALSE, optional = TRUE,
    check.names = FALSE)
}

append_rows <- function(path, rows) {
  if (!nrow(rows)) return(invisible(NULL))
  utils::write.table(rows, file = path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "",
    append = TRUE, eol = "\n", fileEncoding = "UTF-8")
}

sha256_file <- function(path) {
  result <- system2("certutil.exe", c("-hashfile", shQuote(path), "SHA256"),
    stdout = TRUE, stderr = TRUE)
  hashes <- tolower(trimws(grep(
    "^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$", result, value = TRUE
  )))
  if (length(hashes) != 1L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  hashes
}

source_manifest <- read_table(file.path(cache, "sources.csv"))
verify_source <- function(file) {
  row <- source_manifest[source_manifest$file == file, , drop = FALSE]
  path <- if (file %in% c(data_name, control_name, weight_name, report_name)) {
    file.path(model_dir, file)
  } else {
    file.path(cache, file)
  }
  if (nrow(row) != 1L || !file.exists(path) ||
      tolower(row$sha256) != sha256_file(path)) {
    stop("The cached NOAA source differs from its manifest: ", file, call. = FALSE)
  }
  invisible(path)
}

for (file in c(assessment_pdf, model_zip)) verify_source(file)
for (file in c(data_name, control_name, weight_name, report_name)) {
  if (!file.exists(file.path(model_dir, file))) {
    stop("Missing extracted model file: ", file, call. = FALSE)
  }
}

read_numeric_block <- function(lines, marker, n_fields) {
  starts <- which(if (startsWith(marker, "^")) grepl(marker, trimws(lines), perl = TRUE) else trimws(lines) == marker)
  if (length(starts) != 1L) stop("Expected one source block: ", marker, call. = FALSE)
  rows <- list()
  for (i in seq.int(starts + 1L, length(lines))) {
    line <- sub("#.*$", "", lines[i])
    tokens <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
    if (!length(tokens) || !nzchar(tokens[1L])) next
    if (tokens[1L] == "-9999") break
    if (length(tokens) != n_fields) {
      stop("Unexpected field count in ", marker, " at source line ", i, ".", call. = FALSE)
    }
    values <- suppressWarnings(as.numeric(tokens))
    if (anyNA(values)) stop("Non-numeric value in ", marker, ".", call. = FALSE)
    rows[[length(rows) + 1L]] <- values
  }
  if (!length(rows)) stop("No records found in ", marker, ".", call. = FALSE)
  as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
}

read_weight_rows <- function(path) {
  lines <- readLines(path, warn = FALSE)
  rows <- lapply(lines, function(line) {
    tokens <- strsplit(trimws(sub("#.*$", "", line)), "[[:space:]]+")[[1L]]
    if (!length(tokens) || !nzchar(tokens[1L])) return(NULL)
    values <- suppressWarnings(as.numeric(tokens))
    if (length(values) == 37L && !anyNA(values) && values[1L] != -9999) values else NULL
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  if (length(rows) != 980L) stop("Unexpected row count in wtatage.ss.", call. = FALSE)
  x <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(x) <- c("year", "season", "sex", "growth_pattern", "birth_season", "fleet",
    as.character(0:30))
  x
}

fleet_names <- c(
  "1" = "Trawl", "2" = "Hook-and-line", "3" = "Pot",
  "4" = "Trawl discard", "5" = "Hook-and-line discard", "6" = "Pot discard",
  "7" = "Early Triennial survey", "8" = "Late Triennial survey",
  "9" = "NWFSC Slope Survey", "10" = "WCGBTS", "11" = "Recruitment index"
)
fleet_name <- function(code) unname(fleet_names[as.character(abs(as.integer(code)))])
month_name <- function(month) month.name[as.integer(round(month))]
sex_name <- function(code) switch(as.character(as.integer(code)),
  "0" = "combined", "1" = "female", "2" = "male", NA_character_)
sex_vectors <- function(code, female, male) {
  switch(as.character(as.integer(code)),
    "0" = list(combined = female),
    "1" = list(female = female),
    "2" = list(male = male),
    "3" = list(female = female, male = male),
    stop("Unexpected source sex code: ", code, call. = FALSE))
}

data_path <- file.path(model_dir, data_name)
data_lines <- readLines(data_path, warn = FALSE)
catch <- read_numeric_block(data_lines, "#_Catch data", 5L)
names(catch) <- c("year", "season", "fleet", "catch", "catch_se")
cpue <- read_numeric_block(data_lines, "#_CPUE_data", 5L)
names(cpue) <- c("year", "month", "fleet", "observation", "se_log")
lencomp <- read_numeric_block(data_lines, "#_lencomp", 80L)
names(lencomp) <- c("year", "month", "fleet", "sex", "partition", "sample_size",
  paste0("f", seq(18, 90, by = 2)), paste0("m", seq(18, 90, by = 2)))
agecomp <- read_numeric_block(data_lines, "^#_year[[:space:]]+month[[:space:]]+fleet[[:space:]]+sex[[:space:]]+part[[:space:]]+ageerr[[:space:]]+Lbin_lo[[:space:]]+Lbin_hi[[:space:]]+Nsamp[[:space:]]+f0[[:space:]]+f1.*f50[[:space:]]+m0.*m50$", 111L)
names(agecomp) <- c("year", "month", "fleet", "sex", "partition", "age_error",
  "length_bin_lower", "length_bin_upper", "sample_size",
  paste0("f", 0:50), paste0("m", 0:50))
weights <- read_weight_rows(file.path(model_dir, weight_name))

if (nrow(catch) != 620L || nrow(cpue) != 40L || nrow(lencomp) != 57L ||
    nrow(agecomp) != 273L ||
    !all(sort(unique(catch$fleet)) == 1:6) ||
    !all(sort(unique(agecomp$sex)) == c(0, 3)) ||
    !all(sort(unique(agecomp$age_error)) == 1)) {
  stop("Source table checks failed: catch=", nrow(catch), "; cpue=", nrow(cpue), "; length=", nrow(lencomp), "; age=", nrow(agecomp), "; catch fleets=", paste(sort(unique(catch$fleet)), collapse = ","), "; age sex codes=", paste(sort(unique(agecomp$sex)), collapse = ","), "; age error codes=", paste(sort(unique(agecomp$age_error)), collapse = ","), call. = FALSE)
}
if (any(catch$catch <= 0) || any(catch$catch_se <= 0) ||
    any(cpue$observation == -9999) || any(cpue$se_log <= 0) ||
    any(lencomp$sample_size <= 0) || any(agecomp$sample_size <= 0)) {
  stop("A native input value is outside its expected range.", call. = FALSE)
}

parse_report_table <- function(name, header_pattern) {
  lines <- readLines(file.path(model_dir, report_name), warn = FALSE)
  marker <- grep(paste0("^", name, " report:"), lines, value = FALSE)
  if (!length(marker)) stop("Missing report table: ", name, call. = FALSE)
  marker <- tail(marker, 1L)
  header <- grep(header_pattern, lines, perl = TRUE)
  header <- header[header > marker][1L]
  end <- grep(" report:", lines, fixed = TRUE)
  end <- end[end > header][1L]
  if (is.na(header) || is.na(end)) stop("Could not locate report-table bounds for ", name, call. = FALSE)
  body <- lines[header:(end - 1L)]
  body <- body[!grepl("^[[:space:]]*#", body)]
  utils::read.table(text = body, header = TRUE, fill = FALSE,
    check.names = FALSE, stringsAsFactors = FALSE, quote = "", comment.char = "")
}

n_report <- parse_report_table("NUMBERS_AT_AGE", "^Area Bio_Pattern Sex")
f_report <- parse_report_table("F_AT_AGE", "^Area Fleet Sex")
m_report <- parse_report_table("Natural_Mortality", "^Area Bio_Pattern Sex")
annual <- parse_report_table("ANNUAL_TIME_SERIES", "^year Era")
output_years <- 1890:2036
era <- c("TIME", "FORE")
n_report <- n_report[n_report$Area == 1 & n_report$Bio_Pattern == 1 &
  n_report$Sex %in% 1:2 & n_report$BirthSeas == 1 & n_report$Settlement == 1 &
  n_report$Platoon == 1 & n_report$Morph == n_report$Sex & n_report$Seas == 1 &
  n_report$`Beg/Mid` == "B" & n_report$Era %in% era & n_report$Yr %in% output_years, ]
f_report <- f_report[f_report$Area == 1 & f_report$Fleet %in% 1:6 &
  f_report$Sex %in% 1:2 & f_report$Morph == f_report$Sex & f_report$Seas == 1 &
  f_report$Era %in% era & f_report$Yr %in% output_years, ]
m_report <- m_report[m_report$Area == 1 & m_report$Bio_Pattern == 1 &
  m_report$Sex %in% 1:2 & m_report$BirthSeas == 1 & m_report$Settlement == 1 &
  m_report$Platoon == 1 & m_report$Morph == m_report$Sex & m_report$Seas == 1 &
  m_report$`Beg/Mid` == "B" & m_report$Era %in% era & m_report$Yr %in% output_years, ]
annual <- annual[annual$Era %in% era & annual$year %in% output_years, ]
if (nrow(n_report) != length(output_years) * 2L ||
    nrow(f_report) != length(output_years) * 12L ||
    nrow(m_report) != length(output_years) * 2L ||
    nrow(annual) != length(output_years)) {
  stop("Report table checks failed: N=", nrow(n_report), "; F=", nrow(f_report), "; M=", nrow(m_report), "; annual=", nrow(annual), "; years N/F/M/annual=", paste(length(unique(n_report$Yr)), length(unique(f_report$Yr)), length(unique(m_report$Yr)), length(unique(annual$year)), sep = "/"), "; era annual=", paste(unique(annual$Era), collapse = ","), call. = FALSE)
}

input_fields <- names(read_table(file.path(database, "inputs.csv")))
output_fields <- names(read_table(file.path(database, "outputs.csv")))
assumption_fields <- names(read_table(file.path(database, "assumptions.csv")))
input_rows <- new_row_store()
output_rows <- new_row_store()
assumption_rows <- new_row_store()
add_input <- function(...) input_rows$add(c(list(assessment_id = assessment_id), list(...)))
add_output <- function(...) output_rows$add(c(list(assessment_id = assessment_id), list(...)))
add_assumption <- function(...) assumption_rows$add(c(list(assessment_id = assessment_id), list(...)))

native_ref <- paste0(model_zip, ", ", data_name, "; ")
weight_ref <- paste0(model_zip, ", ", weight_name, "; ")
report_ref <- paste0(model_zip, ", ", report_name, "; ")
report_url <- source_manifest$url[source_manifest$file == assessment_pdf]
native_url <- source_manifest$url[source_manifest$file == model_zip]

for (i in seq_len(nrow(catch))) {
  fleet <- fleet_name(catch$fleet[i])
  add_input(type = "catch", measure = "total_biomass", basis = "biomass",
    fleet = fleet, year = catch$year[i], year_basis = "calendar_year",
    value = catch$catch[i], unit = "metric tons", source_type = "native_model",
    source_reference = paste0(native_ref, "Catch data; fleet ", catch$fleet[i]),
    notes = "Native annual catch biomass; SS3 catch units code 1 and the assessment report identify metric tons.")
  add_input(type = "catch", measure = "log_catch_sd", basis = "log_scale",
    fleet = fleet, year = catch$year[i], year_basis = "calendar_year",
    value = catch$catch_se[i], unit = "log-scale standard error",
    source_type = "native_model",
    source_reference = paste0(native_ref, "Catch data; catch_se, fleet ", catch$fleet[i]),
    notes = "The native catch_se field is the standard error of log(catch); retained without transformation.")
}

index_names <- c("7" = "Early Triennial survey", "8" = "Late Triennial survey",
  "9" = "NWFSC Slope Survey", "10" = "WCGBTS")
for (i in seq_len(nrow(cpue))) {
  code <- as.character(as.integer(cpue$fleet[i]))
  month <- as.integer(cpue$month[i])
  timing <- (month - 1) / 12
  if (code %in% names(index_names)) {
    survey <- unname(index_names[code])
    add_input(type = "index", measure = "total_biomass", basis = "index_scale",
      survey = survey, season = month_name(month), year = cpue$year[i],
      year_basis = "calendar_year", value = cpue$observation[i],
      unit = "native biomass index units (SS3 units code 1)", sampling_time = timing,
      source_type = "native_model",
      source_reference = paste0(native_ref, "CPUE data; fleet ", code),
      notes = paste0("Aggregate survey biomass index retained on its native scale. Source month ",
        month, "; tinyAM-style sampling-time fraction (month - 1) / 12 = ", timing, "."))
    add_input(type = "index", measure = "log_index_sd", basis = "log_scale",
      survey = survey, season = month_name(month), year = cpue$year[i],
      year_basis = "calendar_year", value = cpue$se_log[i],
      unit = "log-scale standard error", sampling_time = timing,
      source_type = "native_model",
      source_reference = paste0(native_ref, "CPUE data; se_log, fleet ", code),
      notes = "The fleet uses lognormal error (SS3 error type 0); se_log is retained on the log scale.")
  } else if (code == "11") {
    add_input(type = "covariate", measure = "environmental_covariate",
      basis = "native_covariate", survey = "Recruitment index",
      season = month_name(month), year = cpue$year[i], year_basis = "calendar_year",
      value = cpue$observation[i], unit = "native recruitment-deviation index scale",
      sampling_time = timing, source_type = "native_model",
      source_reference = paste0(native_ref, "Recruitment index observations"),
      notes = "SS3 special units code 36 denotes a recruitment-deviation index, not an abundance survey.")
    add_input(type = "covariate", measure = "index_sd", basis = "native_covariate",
      survey = "Recruitment index", season = month_name(month), year = cpue$year[i],
      year_basis = "calendar_year", value = cpue$se_log[i],
      unit = "native arithmetic-scale standard error", sampling_time = timing,
      source_type = "native_model",
      source_reference = paste0(native_ref, "Recruitment index observations; se_log field"),
      notes = "Despite the source column name se_log, SS3 error type -1 is normal and treats this value as an arithmetic-scale SD.")
  } else {
    stop("Unexpected CPUE fleet code: ", code, call. = FALSE)
  }
}

append_compositions <- function(x, age = TRUE) {
  frequency_names <- if (age) paste0("f", 0:50) else paste0("f", seq(18, 90, by = 2))
  male_names <- if (age) paste0("m", 0:50) else paste0("m", seq(18, 90, by = 2))
  for (i in seq_len(nrow(x))) {
    source_fleet <- as.integer(x$fleet[i])
    fleet <- fleet_name(source_fleet)
    month <- as.integer(x$month[i])
    code <- as.integer(x$sex[i])
    vectors <- sex_vectors(code, as.numeric(x[i, frequency_names]),
      as.numeric(x[i, male_names]))
    is_catch <- abs(source_fleet) <= 6L
    observation_type <- if (is_catch) "catch" else "index"
    destination <- if (is_catch) list(fleet = fleet) else list(survey = fleet)
    for (sex in names(vectors)) {
      values <- vectors[[sex]]
      for (j in seq_along(values)) {
        if (age) {
          row <- c(list(type = observation_type, measure = "frequency_at_age",
            basis = "native_frequency"), destination, list(sex = sex,
            season = month_name(month), year = x$year[i], year_basis = "calendar_year",
            age = j - 1L, value = values[j], unit = "source frequency weight",
            sampling_time = (month - 1) / 12, source_type = "native_model",
            source_reference = paste0(native_ref, "Age-composition data; source row ", i),
            notes = paste0("Raw SS3 frequency retained without normalization. Source FltSvy code ",
              source_fleet, "; sex code ", code, "; partition ", x$partition[i],
              "; age-error code ", x$age_error[i], "; age 50 is the terminal accumulator bin.",
              if (source_fleet < 0) " Negative fleet code is retained; this observation is excluded from the total likelihood." else ""),
            observation_id = paste0("agecomp-", i, "-", sex),
            sample_size = x$sample_size[i], age_error = x$age_error[i],
            partition = x$partition[i]))
          do.call(add_input, row)
        } else {
          bins <- seq(18, 90, by = 2)
          row <- c(list(type = observation_type, measure = "frequency_at_length",
            basis = "native_frequency"), destination, list(sex = sex,
            season = month_name(month), year = x$year[i], year_basis = "calendar_year",
            value = values[j], unit = "source frequency weight",
            sampling_time = (month - 1) / 12, source_type = "native_model",
            source_reference = paste0(native_ref, "Length-composition data; source row ", i),
            notes = paste0("Raw SS3 frequency retained without normalization. Source FltSvy code ",
              source_fleet, "; sex code ", code, "; partition ", x$partition[i],
              "; length bin ", bins[j], if (j == length(bins)) "+" else paste0("-<", bins[j + 1L]), ".",
              if (source_fleet < 0) " Negative fleet code is retained; this observation is excluded from the total likelihood." else ""),
            observation_id = paste0("lencomp-", i, "-", sex),
            length_bin = bins[j], length_bin_lower = bins[j],
            length_bin_upper = if (j < length(bins)) bins[j + 1L] else "",
            sample_size = x$sample_size[i], partition = x$partition[i]))
          do.call(add_input, row)
        }
      }
    }
  }
}
append_compositions(lencomp, age = FALSE)
append_compositions(agecomp, age = TRUE)

for (i in seq_len(nrow(weights))) {
  row <- weights[i, ]
  sex <- if (row$sex == 1) "female" else if (row$sex == 2) "male" else NA_character_
  code <- as.integer(row$fleet)
  if (code == -2) {
    type <- "biology"; measure <- "mature_weight_at_age"; fleet <- "mature weight schedule"
  } else if (code == -1) {
    type <- "weight"; measure <- "weight_at_age"; fleet <- "mid-season population"
  } else if (code == 0) {
    type <- "weight"; measure <- "start_weight_at_age"; fleet <- "beginning-season population"
  } else if (code <= 6) {
    type <- "catch_weight"; measure <- "catch_weight_at_age"; fleet <- fleet_name(code)
  } else {
    type <- "weight"; measure <- "weight_at_age"; fleet <- fleet_name(code)
  }
  year_value <- if (row$year == -1890) -1890 else row$year
  year_basis <- if (row$year == -1890) "model_year" else "calendar_year"
  for (age in 0:30) add_input(
    type = type, measure = measure, basis = "kg_per_fish", fleet = fleet,
    sex = sex, year = year_value, year_basis = year_basis, age = age,
    value = row[[as.character(age)]], unit = "kg per fish",
    source_type = "native_model",
    source_reference = paste0(weight_ref, "SS3 fleet code ", code),
    notes = if (row$year == -1890) {
      "Native sentinel year -1890 supplies the baseline schedule used before annual weight observations; it is not a calendar year."
    } else if (row$year > 2024) {
      "Native forecast weight-at-age input. Age 30 is the terminal plus-group weight bin."
    } else {
      "Native empirical weight-at-age input. Age 30 is the terminal plus-group weight bin."
    }
  )
}

report_year <- annual$year
ages <- 0:70
sex_labels <- c("1" = "female", "2" = "male")
output_rows_add <- function(table, measure, type, unit, report_name_text,
                            fleet_column = NULL, sex_column = "Sex") {
  for (i in seq_len(nrow(table))) for (age in ages) {
    add_output(type = type, measure = measure,
      fleet = if (is.null(fleet_column)) "" else fleet_name(table[[fleet_column]][i]),
      sex = unname(sex_labels[as.character(table[[sex_column]][i])]),
      year = table$Yr[i], age = age, value = table[[as.character(age)]][i],
      unit = unit, source_type = "official_machine_readable",
      source_reference = paste0(report_ref, report_name_text),
      notes = if (table$Yr[i] > 2024) "Official forecast projection; historical terminal input year is 2024." else "Official fitted historical estimate.")
  }
  invisible(NULL)
}
output_rows_add(n_report, "numbers_at_age", "population", "thousand fish",
  "NUMBERS_AT_AGE report:35, beginning-of-year values", sex_column = "Sex")
output_rows_add(f_report, "fishing_mortality_at_age", "mortality", "yr-1",
  "F_AT_AGE report:39", fleet_column = "Fleet")
output_rows_add(m_report, "natural_mortality_at_age", "mortality", "yr-1",
  "Natural_Mortality report:43, beginning-of-year values", sex_column = "Sex")

ssb_ci <- data.frame(
  year = 2015:2025,
  lwr = c(19299, 20372, 20865, 24074, 27343, 31457, 37845, 41765, 45705, 48701, 59331),
  upr = c(32133, 33813, 34416, 39218, 43946, 49976, 59020, 64381, 70170, 74308, 89486)
)
recruit_ci <- data.frame(
  year = 2015:2024,
  lwr = c(1327, 55918, 1353, 6610, 17267, 64260, 46157, 2158, 63700, 7603),
  upr = c(4736, 84096, 6020, 12544, 29332, 100523, 77119, 9855, 138343, 166077)
)
for (i in seq_len(nrow(annual))) {
  y <- annual$year[i]
  interval <- ssb_ci[ssb_ci$year == y, , drop = FALSE]
  add_output(type = "biomass", measure = "SSB", year = y,
    value = annual$SSB[i], se = "",
    lwr = if (nrow(interval)) interval$lwr else "",
    upr = if (nrow(interval)) interval$upr else "", unit = "metric tons",
    source_type = if (nrow(interval)) "official_table" else "official_machine_readable",
    source_reference = if (nrow(interval)) {
      paste0(report_ref, "ANNUAL_TIME_SERIES; ", assessment_pdf, ", Table II")
    } else paste0(report_ref, "ANNUAL_TIME_SERIES report:61, SSB"),
    notes = if (nrow(interval)) "Point estimate from the machine-readable annual table; 95% interval from report Table II, rounded as published." else if (y > 2024) "Official forecast projection; no interval imported." else "Official fitted historical estimate; no interval imported.")
  recruit_interval <- recruit_ci[recruit_ci$year == y, , drop = FALSE]
  add_output(type = "recruitment", measure = "recruitment", age = 0, year = y,
    value = annual$recruits[i],
    lwr = if (nrow(recruit_interval)) recruit_interval$lwr else "",
    upr = if (nrow(recruit_interval)) recruit_interval$upr else "",
    unit = "thousand fish",
    source_type = if (nrow(recruit_interval)) "official_table" else "official_machine_readable",
    source_reference = if (nrow(recruit_interval)) {
      paste0(report_ref, "ANNUAL_TIME_SERIES; ", assessment_pdf, ", Table III")
    } else paste0(report_ref, "ANNUAL_TIME_SERIES report:61, recruits"),
    notes = if (nrow(recruit_interval)) "Age-0 recruitment point estimate from the machine-readable annual table; 95% interval from report Table III, rounded as published." else if (y > 2024) "Official forecast recruitment; no interval imported." else "Official fitted historical recruitment; no interval imported.")
}

for (y in report_year) {
  selected <- n_report[n_report$Yr == y, ]
  total <- sum(as.matrix(selected[, as.character(ages)]))
  add_output(type = "population", measure = "total_numbers", year = y,
    value = total, unit = "thousand fish", source_type = "derived_source_output",
    source_reference = paste0(report_ref, "NUMBERS_AT_AGE report:35; sum across ages 0-70 and both sexes"),
    notes = if (y > 2024) "Derived total abundance from projected N-at-age across all ages and both sexes; no uncertainty calculated." else "Derived total abundance from fitted N-at-age across all ages and both sexes; no uncertainty calculated.")
}

assumption_values <- list(
  list(component = "assessment", setting = "model_version", value = "Report states SS3 3.30.24; bundled input echo and Report.sso identify 3.30.23.1"),
  list(component = "population", setting = "modeled_years", value = "1890-2024 historical; forecasts through 2036"),
  list(component = "population", setting = "age_grid", value = "Ages 0-70; age 70 is terminal accumulator"),
  list(component = "population", setting = "sex_structure", value = "Two-sex; females and males"),
  list(component = "age_composition", setting = "observed_age_bins", value = "0-50; age 50 is the terminal accumulator bin"),
  list(component = "age_composition", setting = "native_frequency_scale", value = "Source frequency values retained without normalization; source Nsamp, ageerr, sex, partition, month and signed FltSvy code preserved"),
  list(component = "age_composition", setting = "negative_fleet", value = "Negative FltSvy rows are retained as provisional inputs and excluded from the likelihood"),
  list(component = "length_composition", setting = "observed_length_bins_cm", value = "18-90 cm; 90 cm is the terminal accumulator bin"),
  list(component = "catch", setting = "fleet_structure", value = "Trawl, hook-and-line, pot and corresponding discard fleets; catch biomass in metric tons"),
  list(component = "catch", setting = "catch_error_scale", value = "Native catch_se is SE of log(catch); values are 0.01 for all source catch records"),
  list(component = "index", setting = "aggregate_biomass_series", value = "Early and late Triennial, NWFSC Slope, and WCGBTS; SS3 units code 1; lognormal error"),
  list(component = "index", setting = "sampling_time_conversion", value = "(native month - 1) / 12; month 7 maps to 0.5 and month 8 maps to 0.5833333"),
  list(component = "index", setting = "recruitment_index", value = "Fleet 11 uses special SS3 units code 36 and normal error type -1; it is a recruitment-deviation index, not an abundance index"),
  list(component = "weight", setting = "weight_roles", value = "SS3 fleets -2 (mature weight), -1 (mid-season population), 0 (beginning-season population), 1-11 (fleet-specific)"),
  list(component = "weight", setting = "weight_coverage", value = "Sex-specific ages 0-30; baseline sentinel -1890 and annual values 2003-2036; age 30 is pooled terminal bin"),
  list(component = "biology", setting = "maturity_method", value = "Spatial maturity-at-age estimated outside SS3; coastwide schedule is biomass-weighted using WCGBTS; age at 50% maturity differs north/south"),
  list(component = "biology", setting = "mature_weight_input", value = "wtatage.ss fleet -2 supplies maturity multiplied by weight-at-age; it is not a standalone maturity proportion"),
  list(component = "mortality", setting = "natural_mortality", value = "Estimated constant shared by sexes and ages; Report.sso estimate 0.087777 yr-1"),
  list(component = "mortality", setting = "natural_mortality_prior", value = "Lognormal prior median 0.072 yr-1; SD 0.31"),
  list(component = "biology", setting = "spawning_output", value = "Female spawning output uses external spatial maturity and fecundity assumed proportional to weight; canonical input preserves mature weight-at-age, not maturity proportion"),
  list(component = "outputs", setting = "uncertainty", value = "Recent SSB and recruitment 95% intervals imported from report Tables II-III; age-specific N, F and M uncertainty not published in the extracted machine-readable tables")
)
for (fleet in seq_along(fleet_names)) {
  code <- names(fleet_names)[fleet]
  add_assumption(component = "fleet", fleet = fleet_name(code), setting = "source_fleet_code",
    value = code, source_reference = paste0(native_ref, "fleetinfo"),
    notes = if (as.integer(code) <= 3L) "Retained commercial catch fleet." else if (as.integer(code) <= 6L) "Discard catch fleet." else "Survey/index fleet.")
}
for (row in assumption_values) {
  add_assumption(component = row$component, setting = row$setting, value = row$value,
    source_reference = if (row$component == "outputs") {
      paste0(report_url, "; ", native_url)
    } else paste0(native_ref, "data/control/weight input; ", report_url),
    notes = "Source values and scope are preserved; no tinyAM translation has been started.")
}
for (code in names(index_names)) {
  rows <- cpue[as.character(as.integer(cpue$fleet)) == code, ]
  months <- sort(unique(as.integer(rows$month)))
  add_assumption(component = "index", survey = unname(index_names[code]),
    setting = "source_months", value = paste(months, collapse = ", "),
    source_reference = paste0(native_ref, "CPUE data"),
    notes = "Individual month values are retained on observations; fractions use (month - 1) / 12.")
}

input_data <- rows_from(input_fields, input_rows$get())
outputs <- rows_from(output_fields, output_rows$get())
assumptions <- rows_from(assumption_fields, assumption_rows$get())

candidate <- read_table(candidate_path)
candidate_row <- which(candidate$candidate_id == candidate_id)
inventory <- read_table(inventory_path)
inventory_row <- which(inventory$unit_key == paste0("candidate:", candidate_unit_id))
selected <- read_table(selected_path)
selected_row <- which(selected$candidate_unit_id == candidate_unit_id)
stocks <- read_table(file.path(database, "stocks.csv"))
assessments <- read_table(file.path(database, "assessments.csv"))
inputs_existing <- read_table(file.path(database, "inputs.csv"))
outputs_existing <- read_table(file.path(database, "outputs.csv"))
if (length(candidate_row) != 1L || length(inventory_row) != 1L || length(selected_row) != 1L ||
    candidate$eligibility[candidate_row] != "eligible" ||
    !candidate$import_status[candidate_row] %in% c("not_started", "partial")) {
  stop("NOAA Stock SMART 10466 is missing, duplicated, or not ready for import.", call. = FALSE)
}
if (!dry_run && (any(stocks$stock_id == stock_id) || any(assessments$assessment_id == assessment_id) ||
    any(inputs_existing$assessment_id == assessment_id) || any(outputs_existing$assessment_id == assessment_id))) {
  stop("NOAA West Coast Sablefish records already exist; review before importing.", call. = FALSE)
}

replace_csv_row <- function(path, key_column, key_value, row_index, row) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  bounds <- csv_record_bounds(bytes)
  record_index <- as.integer(row_index) + 1L
  current <- read_table(path)
  if (row_index > nrow(current) || as.character(current[[key_column]][row_index]) != key_value) {
    stop("CSV row identity differs in ", basename(path), call. = FALSE)
  }
  first <- bounds$start[record_index]
  last <- bounds$end[record_index]
  temporary <- tempfile(fileext = ".csv")
  on.exit(unlink(temporary), add = TRUE)
  utils::write.table(row, temporary, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = "", qmethod = "double", eol = "\n")
  replacement <- readBin(temporary, what = "raw", n = file.info(temporary)$size)
  if (length(replacement) && tail(replacement, 1L) == as.raw(10L)) replacement <- replacement[-length(replacement)]
  if (length(replacement) && tail(replacement, 1L) == as.raw(13L)) replacement <- replacement[-length(replacement)]
  next_byte <- last + 1L
  has_cr <- FALSE
  while (next_byte <= length(bytes) && bytes[next_byte] == as.raw(13L)) {
    has_cr <- TRUE; next_byte <- next_byte + 1L
  }
  if (next_byte <= length(bytes) && bytes[next_byte] == as.raw(10L)) {
    replacement <- c(replacement, if (has_cr) as.raw(c(13L, 10L)) else as.raw(10L))
    last <- next_byte
  }
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, replacement, after), path)
  updated <- read_table(path)
  if (nrow(updated) != nrow(current) || sum(as.character(updated[[key_column]]) == key_value) != 1L) {
    stop("Updated CSV failed identity checks: ", basename(path), call. = FALSE)
  }
}

stock <- blank_row(names(stocks), list(
  stock_id = stock_id, charbonneau_id = "", authority = "NOAA-NWFSC/SWFSC",
  authority_stock_id = "10466", scientific_name = "Anoplopoma fimbria",
  common_name = "Sablefish - U.S. West Coast",
  area = "U.S. West Coast (California, Oregon, Washington)",
  region = "U.S. West Coast", ocean = "Northeast Pacific",
  notes = "NOAA Stock SMART 10466. This current U.S. West Coast management unit is distinct from Alaska and British Columbia sablefish units."
))
assessment <- blank_row(names(assessments), list(
  assessment_id = assessment_id, stock_id = stock_id,
  assessment_year = 2025L, terminal_year = 2024L, estimate_terminal_year = 2036L,
  assessment_type = "full_assessment", model_family = "Stock Synthesis",
  model_version = "2025 assessment; report states SS3 3.30.24; bundled Report.sso identifies 3.30.23.1",
  is_current = TRUE, is_applied = TRUE, framework_year = "",
  assessment_url = report_url, framework_url = "",
  data_url = native_url, model_url = native_url,
  repository_url = "https://www.pcouncil.org/documents/sablefish-2025-model-files/",
  assumptions_status = "partial", inputs_status = "partial", outputs_status = "partial",
  notes = paste("Official 2025 assessment through 2024; output files contain forecasts through 2036.",
    "Native catch, aggregate survey indices, length and age compositions, weight schedules, N/F/M surfaces, SSB and recruitment are imported.",
    "Catch-at-age is not supplied directly; maturity proportions are not supplied as a standalone age schedule.",
    "Recent aggregate SSB and recruitment intervals are available from the report, but age-specific uncertainty is not.",
    "The report and model bundle differ in the reported SS3 version." )
))

if (!dry_run) {
  append_rows(file.path(database, "stocks.csv"), stock)
  append_rows(file.path(database, "assessments.csv"), assessment)
  append_rows(file.path(database, "assumptions.csv"), assumptions)
  append_rows(file.path(database, "inputs.csv"), input_data)
  append_rows(file.path(database, "outputs.csv"), outputs)

  candidate$matched_stock_id[candidate_row] <- stock_id
  candidate$match_status[candidate_row] <- "new"
  candidate$import_status[candidate_row] <- "partial"
  candidate$catch_age_evidence[candidate_row] <- paste(
    "The 2025 native SS3 input contains annual catch biomass for six fleets and",
    "native length and age compositions. Catch-at-age is not supplied directly;",
    "sampled catches may be reconstructed only with explicit age-composition and weight transformations.")
  candidate$survey_age_evidence[candidate_row] <- paste(
    "The model includes four aggregate biomass indices and native age compositions",
    "in ages 0-50 (age 50 is the accumulator); the aggregate index and compositions",
    "remain separate source inputs, not an observed age-specific abundance index.")
  candidate$weights_evidence[candidate_row] <- paste(
    "Native wtatage.ss supplies sex-specific beginning-season, mid-season,",
    "mature-weight and fleet-specific schedules for ages 0-30; baseline weights",
    "precede annual schedules for 2003-2024. Age 30 is the plus group.")
  candidate$maturity_evidence[candidate_row] <- paste(
    "The source file contains maturity multiplied by weight-at-age, not maturity",
    "proportions. The report describes a spatial maturity model and a coastwide",
    "biomass-weighted maturity schedule; standalone maturity proportions were not recovered.")
  candidate$mortality_evidence[candidate_row] <- paste(
    "Natural mortality is estimated as a constant shared by sexes and ages;",
    "Report.sso gives 0.087777 yr-1, with a lognormal prior median 0.072 yr-1 and SD 0.31.")
  candidate$timing_evidence[candidate_row] <- paste(
    "The source stores survey and composition months. Aggregate indices are in",
    "July for early Triennial, NWFSC Slope and WCGBTS, and August for late Triennial.",
    "Observation sampling fractions use (month - 1) / 12; source month is retained.")
  candidate$output_evidence[candidate_row] <- paste(
    "Report.sso provides N, fleet-specific F, and M at age for historical and",
    "forecast years. Annual SSB and recruitment are imported; recent 95% intervals",
    "come from report Tables II-III. Total abundance is derived from N-at-age;",
    "age-specific uncertainty is unavailable.")
  candidate$review_date[candidate_row] <- "2026-11-03"
  candidate$decision_reason[candidate_row] <- paste(
    "The current 2025 U.S. West Coast assessment has a matching native SS3 input",
    "bundle and numerical age-specific fitted outputs. It is imported as a partial",
    "source record because catch-at-age and standalone maturity proportions are not supplied.")
  candidate$notes[candidate_row] <- paste(
    "Source files and checksums are cached under the gitignored",
    "discovery_noaa_sablefish_2025 directory. The report says SS3 3.30.24 while",
    "the bundle identifies 3.30.23.1. No tinyAM translation has been started.")
  replace_candidate_register_row(candidate_path, candidate_row,
    candidate[candidate_row, , drop = FALSE], candidate_id)

  inventory$matched_stock_id[inventory_row] <- stock_id
  inventory$import_status[inventory_row] <- "partial"
  replace_csv_row(inventory_path, "unit_key", paste0("candidate:", candidate_unit_id),
    inventory_row, inventory[inventory_row, , drop = FALSE])

  selected$curation_status[selected_row] <- "partial_source_import"
  replace_csv_row(selected_path, "candidate_unit_id", candidate_unit_id,
    selected_row, selected[selected_row, , drop = FALSE])
}

cat(if (dry_run) "Dry run parsed " else "Imported ",
  nrow(input_data), " inputs, ", nrow(assumptions), " assumptions, and ",
  nrow(outputs), " outputs for NOAA West Coast Sablefish.\n", sep = "")
