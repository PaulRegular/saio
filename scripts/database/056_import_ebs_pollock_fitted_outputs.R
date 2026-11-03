assessment_id <- "afsc_pollock_ebs_2024"
source_revision <- "44e0cb0ac8698e1d3954273e8aaf760d7c76cba5"
source_repo <- "https://github.com/noaa-afsc/EBS_pollock"
report_url <- "https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/EBSpollock.pdf"
root <- "."
cache <- file.path(root, "source_cache", assessment_id)
output_path <- file.path(root, "database", "outputs.csv")
par_path <- file.path(cache, "pm_or.parxx")
sel_path <- file.path(cache, "selvar24.dat")
report_rows_path <- file.path(cache, "report_historical_outputs_raw.csv")

required_files <- c(
  par_path, sel_path, report_rows_path,
  file.path(cache, "source_pm.tpl")
)
if (!all(file.exists(required_files))) {
  stop("Pinned EBS fitted files and report staging must be present in the local source cache.")
}

par_lines <- readLines(par_path, warn = FALSE)
markers <- grep("^# [A-Za-z0-9_]+:$", par_lines)
par_names <- sub("^# ([A-Za-z0-9_]+):$", "\\1", par_lines[markers])
par_values <- lapply(seq_along(markers), function(i) {
  end <- if (i < length(markers)) markers[i + 1L] - 1L else length(par_lines)
  tokens <- unlist(strsplit(trimws(par_lines[(markers[i] + 1L):end]), "[[:space:]]+"))
  values <- suppressWarnings(as.numeric(tokens))
  values[is.finite(values)]
})
names(par_values) <- par_names

years <- 1964:2024
ages <- 1:15
if (length(par_values$log_avg_F) != 1L ||
  length(par_values$log_F_devs) != length(years) ||
  length(par_values$sel_coffs_fsh) != 12L) {
  stop("The pinned fitted-parameter dimensions do not match the source model years and ages.")
}
sel_changes <- as.matrix(read.table(sel_path, header = FALSE))
change_years <- sel_changes[sel_changes[, 2] > 0 & sel_changes[, 1] < max(years), 1]
if (ncol(sel_changes) != 4L ||
  !identical(as.integer(sel_changes[, 1]), years) ||
  length(par_values$sel_devs_fsh) != length(change_years) * length(par_values$sel_coffs_fsh)) {
  stop("Fishery selectivity change years do not match the fitted deviation matrix.")
}

n_selectivity_ages <- length(par_values$sel_coffs_fsh)
sel_devs <- matrix(par_values$sel_devs_fsh, nrow = length(change_years), byrow = TRUE)
log_selectivity <- matrix(NA_real_,
  nrow = length(years), ncol = length(ages),
  dimnames = list(years, ages)
)
current <- c(
  par_values$sel_coffs_fsh,
  rep(tail(par_values$sel_coffs_fsh, 1L), length(ages) - n_selectivity_ages)
)
current <- current - log(mean(exp(current)))
for (i in seq_along(years)) {
  log_selectivity[i, ] <- current
  change_row <- match(years[i], change_years)
  if (!is.na(change_row)) {
    current[seq_len(n_selectivity_ages)] <-
      current[seq_len(n_selectivity_ages)] + sel_devs[change_row, ]
    current[seq.int(n_selectivity_ages + 1L, length(ages))] <-
      current[n_selectivity_ages]
    current <- current - log(mean(exp(current)))
  }
}
f_mortality <- exp(par_values$log_avg_F + par_values$log_F_devs)
f_at_age <- sweep(exp(log_selectivity), 1L, f_mortality, "*")
if (any(!is.finite(f_at_age)) || any(f_at_age <= 0) ||
  max(abs(rowMeans(f_at_age) - f_mortality)) > 1e-10) {
  stop("The reconstructed F surface fails the source selectivity normalization check.")
}

native_report <- read.csv(report_rows_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
expected_report_counts <- c(
  numbers_at_age = 610L, SSB = 61L,
  recruitment = 61L, biomass_at_age = 61L
)
report_counts <- table(factor(native_report$measure,
  levels = names(expected_report_counts)
))
if (!identical(as.integer(report_counts), unname(expected_report_counts)) ||
  !identical(sort(unique(native_report$year)), years)) {
  stop("The staged SAFE output rows do not match the expected historical tables.")
}
native_report$measure[native_report$measure == "biomass_at_age"] <-
  "biomass_by_age_group"
output_type <- c(
  numbers_at_age = "population", SSB = "biomass",
  recruitment = "recruitment", biomass_by_age_group = "biomass"
)
output_source <- data.frame(
  assessment_id = assessment_id,
  type = unname(output_type[native_report$measure]),
  measure = native_report$measure,
  fleet = "", survey = "", sex = "", region = "", season = "",
  year = native_report$year,
  age = native_report$age,
  age_group = native_report$age_group,
  value = native_report$value,
  se = NA_real_, lwr = NA_real_, upr = NA_real_,
  unit = native_report$unit,
  source_type = "official_table",
  source_reference = paste0(report_url, "; Table ", native_report$table),
  notes = ifelse(
    native_report$measure == "numbers_at_age",
    "Historical official-model estimate. SAFE Table 24 reports ages 1-9 individually and ages 10-15 as 10+; this is a reporting group, not the native age-15 model plus group. Printed CV is retained in source staging and is not an absolute SE.",
    ifelse(
      native_report$measure == "biomass_by_age_group",
      "Historical official-model beginning-year biomass summed over ages 3+. This is one reported age group, not age-specific biomass-at-age. Printed CV is not converted to an absolute SE.",
      ifelse(
        native_report$measure == "SSB",
        "Historical official-model female SSB at the source spawning time; unit is thousand tonnes. Printed CV is not converted to an absolute SE.",
        "Historical official-model age-1 recruitment; unit is million fish. Printed CV is not converted to an absolute SE."
      )
    )
  ),
  stringsAsFactors = FALSE
)

f_grid <- expand.grid(age = ages, year = years)
f_values <- as.vector(t(f_at_age))
f_reference <- paste0(
  source_repo, "/blob/", source_revision,
  "/runs/lastyr/pm_or.parxx; ",
  source_repo, "/blob/", source_revision,
  "/runs/data/selvar24.dat; ",
  source_repo, "/blob/", source_revision,
  "/source/pm.tpl"
)
f_note <- paste(
  "Annual fishery F-at-age reconstructed from the pinned official fitted parameters and source implementation.",
  "The source defines F(y,a)=exp(log_avg_F+log_F_devs[y])*exp(log_sel[y,a]);",
  "selectivity coefficients are extended through age 15 and annual deviations are applied in the flagged years.",
  "The source re-normalizes exp(log_sel) to arithmetic mean one across ages each year.",
  "Age 15 is the native model plus group; values are deterministic reconstruction, not digitized output."
)
f_output <- data.frame(
  assessment_id = assessment_id, type = "mortality",
  measure = "fishing_mortality_at_age",
  fleet = "Combined fishery", survey = "", sex = "", region = "", season = "",
  year = f_grid$year, age = f_grid$age,
  age_group = ifelse(f_grid$age == max(ages), "15+", NA_character_),
  value = f_values, se = NA_real_, lwr = NA_real_, upr = NA_real_,
  unit = "per year", source_type = "native_model",
  source_reference = f_reference, notes = f_note,
  stringsAsFactors = FALSE
)

new_rows <- rbind(output_source, f_output)
old_lines <- readLines(output_path, warn = FALSE, encoding = "UTF-8")
old_table <- read.csv(
  text = paste(old_lines, collapse = "\n"),
  stringsAsFactors = FALSE, check.names = FALSE,
  colClasses = "character"
)
if (nrow(old_table) != length(old_lines) - 1L ||
  !identical(names(old_table), names(new_rows))) {
  stop("The canonical outputs table does not match the expected schema.")
}
keep_lines <- old_lines[-1L][old_table$assessment_id != assessment_id]
new_text <- capture.output(write.table(
  new_rows,
  file = "", sep = ",", row.names = FALSE, col.names = FALSE,
  quote = TRUE, na = ""
))
writeLines(c(old_lines[1L], keep_lines, new_text), output_path, useBytes = TRUE)

assessment_path <- file.path(root, "database", "assessments.csv")
assessment_lines <- readLines(assessment_path, warn = FALSE, encoding = "UTF-8")
assessment_row <- grep('"afsc_pollock_ebs_2024",', assessment_lines, fixed = TRUE)
if (length(assessment_row) != 1L) {
  stop("Expected one EBS assessment metadata row.")
}
old_note <- "F-at-age is reconstructed from pinned fitted parameters and source code without reported uncertainty; other output uncertainty and some statistical assumptions remain incomplete;"
new_note <- "The official F-at-age surface is reconstructed from pinned fitted parameters and source code, but uncertainty remains unavailable. Other statistical assumptions and output uncertainty remain incomplete;"
if (grepl(old_note, assessment_lines[assessment_row], fixed = TRUE)) {
  assessment_lines[assessment_row] <- sub(
    old_note, new_note, assessment_lines[assessment_row],
    fixed = TRUE
  )
} else if (!grepl(new_note, assessment_lines[assessment_row], fixed = TRUE)) {
  stop("Assessment notes do not match the expected pre-import wording.")
}
writeLines(assessment_lines, assessment_path, useBytes = TRUE)
cat(
  "Imported", nrow(new_rows), "EBS historical output rows, including",
  nrow(f_output), "source-code-reconstructed F-at-age values.\n"
)
