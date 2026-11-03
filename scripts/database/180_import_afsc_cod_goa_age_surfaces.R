root <- "."
cache <- file.path(root, "source_cache/afsc_cod_goa_2026")
run_dir <- file.path(cache, "model24_0_native_report_reconstruction")
assessment_id <- "afsc_cod_goa_2026"
outputs_path <- file.path(root, "database", "outputs.csv")
report_path <- file.path(run_dir, "Report.sso")
summary_path <- file.path(run_dir, "ss_summary.sso")
source_par_path <- file.path(cache, "source_ss3.par")

stopifnot(
  file.exists(report_path), file.exists(summary_path), file.exists(source_par_path),
  dir.exists(run_dir)
)

report <- readLines(report_path, warn = FALSE)
summary <- readLines(summary_path, warn = FALSE)
par_header <- readLines(source_par_path, n = 1L, warn = FALSE)
stopifnot(
  grepl("^#V3\\.30\\.22\\.1", summary[1]),
  any(grepl("Final_phase: 7  N_iterations: 1", summary, fixed = TRUE)),
  grepl("Objective function value = 2108.97949000959", par_header, fixed = TRUE),
  grepl("Maximum gradient component = 6.44551037822919e-06", par_header, fixed = TRUE)
)

read_report_rows <- function(header, skip = 1L) {
  i <- which(report == header)
  stopifnot(length(i) == 1L)
  j <- which(seq_along(report) > i & !nzchar(trimws(report)))[1]
  stopifnot(!is.na(j))
  x <- report[seq.int(i + 1L + skip, j - 1L)]
  x <- x[grepl("^[[:space:]]*[0-9]+[[:space:]]", x)]
  strsplit(trimws(x), "[[:space:]]+")
}

n_tokens <- read_report_rows("NUMBERS_AT_AGE report:35")
n_wide <- do.call(rbind, lapply(n_tokens, function(x) {
  stopifnot(length(x) == 23L)
  data.frame(
    area = as.integer(x[1]),
    sex_code = as.integer(x[3]),
    year = as.integer(x[8]),
    season_code = as.integer(x[9]),
    time = as.numeric(x[10]),
    begin_mid = x[11],
    era = x[12],
    as.list(setNames(as.numeric(x[13:23]), paste0("a", 0:10))),
    check.names = FALSE
  )
}))
n_wide <- n_wide[
  n_wide$era == "TIME" & n_wide$begin_mid == "B" &
    n_wide$year %in% 1977:2025,
  , drop = FALSE
]
stopifnot(
  nrow(n_wide) == 49L,
  identical(sort(unique(n_wide$year)), 1977:2025),
  !anyDuplicated(n_wide$year),
  all(vapply(n_wide[paste0("a", 0:10)], function(x) all(is.finite(x) & x >= 0), logical(1)))
)

n_at_age <- do.call(rbind, lapply(seq_len(nrow(n_wide)), function(i) {
  data.frame(
    year = n_wide$year[i],
    age = 0:10,
    value = as.numeric(n_wide[i, paste0("a", 0:10)]),
    stringsAsFactors = FALSE
  )
}))

fleet_header <- "Fleet fleet_type timing area catch_units catch_mult survey_units survey_error Fleet_name"
fleet_tokens <- read_report_rows(fleet_header, skip = 0L)
fleet_table <- do.call(rbind, lapply(fleet_tokens, function(x) {
  stopifnot(length(x) == 9L)
  data.frame(
    fleet_id = as.integer(x[1]),
    fleet_type = as.integer(x[2]),
    fleet_name = x[9],
    stringsAsFactors = FALSE
  )
}))

f_tokens <- read_report_rows("F_AT_AGE report:39")
f_wide <- do.call(rbind, lapply(f_tokens, function(x) {
  stopifnot(length(x) == 18L)
  data.frame(
    area = as.integer(x[1]),
    fleet_id = as.integer(x[2]),
    sex_code = as.integer(x[3]),
    year = as.integer(x[5]),
    season_code = as.integer(x[6]),
    era = x[7],
    as.list(setNames(as.numeric(x[8:18]), paste0("a", 0:10))),
    check.names = FALSE
  )
}))
f_wide <- f_wide[
  f_wide$era == "TIME" & f_wide$year %in% 1977:2025 &
    f_wide$fleet_id %in% fleet_table$fleet_id[fleet_table$fleet_type == 1L],
  , drop = FALSE
]
fleet_map <- fleet_table$fleet_name[match(sort(unique(f_wide$fleet_id)), fleet_table$fleet_id)]
stopifnot(
  setequal(fleet_map, c("FshTrawl", "FshLL", "FshPot")),
  nrow(f_wide) == 49L * 3L,
  !anyDuplicated(f_wide[c("fleet_id", "year")]),
  identical(sort(unique(f_wide$year)), 1977:2025),
  all(vapply(f_wide[paste0("a", 0:10)], function(x) all(is.finite(x) & x >= 0), logical(1)))
)

f_by_fleet <- do.call(rbind, lapply(seq_len(nrow(f_wide)), function(i) {
  data.frame(
    fleet = fleet_table$fleet_name[match(f_wide$fleet_id[i], fleet_table$fleet_id)],
    year = f_wide$year[i],
    age = 0:10,
    value = as.numeric(f_wide[i, paste0("a", 0:10)]),
    stringsAsFactors = FALSE
  )
}))
f_total <- aggregate(value ~ year + age, f_by_fleet, sum)
stopifnot(
  nrow(f_by_fleet) == 49L * 3L * 11L,
  nrow(f_total) == 49L * 11L,
  !anyDuplicated(f_by_fleet[c("fleet", "year", "age")]),
  !anyDuplicated(f_total[c("year", "age")])
)

outputs <- read.csv(outputs_path, stringsAsFactors = FALSE, check.names = FALSE)
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
recruitment <- outputs[
  outputs$measure == "recruitment" & outputs$year %in% 1977:2025,
  , drop = FALSE
]
ssb <- outputs[
  outputs$measure == "SSB" & outputs$year %in% 1977:2025,
  , drop = FALSE
]
ssb_lines <- grep("^SSB_[0-9]{4}[[:space:]]", report, value = TRUE)
ssb_report <- do.call(rbind, lapply(ssb_lines, function(x) {
  fields <- strsplit(trimws(x), "[[:space:]]+")[[1]]
  data.frame(
    year = as.integer(sub("SSB_", "", fields[1], fixed = TRUE)),
    value = as.numeric(fields[2]) / 2,
    stringsAsFactors = FALSE
  )
}))
ssb_report <- ssb_report[ssb_report$year %in% 1977:2025, , drop = FALSE]
recruitment_check <- merge(
  data.frame(year = n_at_age$year[n_at_age$age == 0],
             value = n_at_age$value[n_at_age$age == 0] / 1e6),
  recruitment[, c("year", "value")],
  by = "year", suffixes = c("_native", "_published")
)
ssb_check <- merge(
  ssb_report,
  ssb[, c("year", "value")],
  by = "year", suffixes = c("_native", "_published")
)
stopifnot(
  nrow(recruitment) == 49L,
  nrow(ssb) == 49L,
  nrow(recruitment_check) == 49L,
  nrow(ssb_check) == 49L,
  max(abs(recruitment_check$value_native - recruitment_check$value_published)) <= 0.0051,
  max(abs(ssb_check$value_native - ssb_check$value_published)) <= 0.5
)

archive_url <- paste0(
  "https://github.com/afsc-assessments/goapcod/blob/",
  "e632807e4947686c16caf99b864bfe8466f8dbca/docs/2025_Assessment/January_Model/",
  "model_files/M24.0_SS3_files.zip"
)
parameter_url <- paste0(
  "https://github.com/pete-hulson/goa_pcod/blob/",
  "facf41573f9a0b609d0096611bc9302aaab43abe/2025/mgmt/24.0/ss3.par"
)
source_reference_n <- paste(
  "SS3 3.30.22.1 Report.sso, NUMBERS_AT_AGE report:35, regenerated from",
  archive_url, parameter_url, sep = "; "
)
source_reference_f <- paste(
  "SS3 3.30.22.1 Report.sso, F_AT_AGE report:39, regenerated from",
  archive_url, parameter_url, sep = "; "
)

make_output <- function(x, type, measure, unit, fleet = "", notes,
                        source_reference) {
  data.frame(
    assessment_id = assessment_id,
    type = type,
    measure = measure,
    fleet = fleet,
    survey = "",
    sex = "combined",
    region = "",
    season = "",
    year = as.integer(x$year),
    age = as.integer(x$age),
    age_group = "",
    value = as.numeric(x$value),
    se = NA_real_,
    lwr = NA_real_,
    upr = NA_real_,
    unit = unit,
    source_type = "native_model",
    source_reference = source_reference,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

n_rows <- make_output(
  n_at_age, "population", "numbers_at_age", "thousand fish",
  notes = paste(
    "Beginning-of-year values from the single-sex, single-area SS3 surface.",
    "Age 10 is the model plus group. Age-specific uncertainty was not",
    "produced in the no-estimation run."
  ),
  source_reference = source_reference_n
)
fleet_notes <- paste(
  "Annual instantaneous fishing mortality for this fleet from the saved",
  "Model 24.0 fitted parameters. Age-specific uncertainty was not produced."
)
total_notes <- paste(
  "Sum of FshTrawl, FshLL and FshPot at each year and age.",
  "Fleet-specific rows are overlapping components and are not additive to",
  "this total a second time. Age-specific uncertainty was not produced."
)
f_rows <- do.call(rbind, lapply(sort(unique(f_by_fleet$fleet)), function(name) {
  make_output(
    f_by_fleet[f_by_fleet$fleet == name, , drop = FALSE],
    "mortality", "fishing_mortality_at_age", "per year",
    fleet = name, notes = fleet_notes, source_reference = source_reference_f
  )
}))
f_total_rows <- make_output(
  f_total, "mortality", "fishing_mortality_at_age", "per year",
  notes = total_notes, source_reference = source_reference_f
)
new_rows <- rbind(n_rows, f_rows, f_total_rows)
stopifnot(
  nrow(n_rows) == 49L * 11L,
  nrow(f_rows) == 49L * 3L * 11L,
  nrow(f_total_rows) == 49L * 11L,
  nrow(new_rows) == 2695L,
  all(is.finite(new_rows$value)),
  !anyDuplicated(new_rows[c("measure", "fleet", "year", "age")])
)

existing <- read.csv(outputs_path, stringsAsFactors = FALSE, check.names = FALSE)
existing <- existing[
  existing$assessment_id == assessment_id &
    existing$measure %in% c("numbers_at_age", "fishing_mortality_at_age"),
  , drop = FALSE
]
if (nrow(existing)) {
  stopifnot(nrow(existing) == nrow(new_rows))
  key <- function(x) paste(x$measure, x$fleet, x$year, x$age, sep = "\r")
  old <- existing[order(key(existing)), , drop = FALSE]
  expected <- new_rows[order(key(new_rows)), , drop = FALSE]
  stopifnot(
    identical(key(old), key(expected)),
    max(abs(old$value - expected$value)) < 1e-12,
    all(old$unit == expected$unit),
    all(old$source_type == expected$source_type)
  )
  cat("GOA N-at-age and F-at-age native outputs already match the cached Report.sso.\n")
} else {
  utils::write.table(
    new_rows[names(read.csv(outputs_path, nrows = 0, check.names = FALSE))],
    outputs_path,
    sep = ",", quote = TRUE, row.names = FALSE, col.names = FALSE,
    append = TRUE, na = "", fileEncoding = "UTF-8"
  )
  cat(
    "Recorded 539 beginning-of-year N-at-age values, 1,617 fleet-specific F-at-age values,",
    "and 539 summed F-at-age values for 1977-2025.\n"
  )
}
