source("scripts/database/002_validate_database.R")
id <- "afsc_pollock_ebs_2024"
x <- inputs[inputs$assessment_id == id, ]
y <- outputs[outputs$assessment_id == id, ]
a <- assessments[assessments$assessment_id == id, ]
stopifnot(
  nrow(x) == 5194L, nrow(y) == 1708L,
  a$assessment_year == 2024, a$terminal_year == 2024,
  a$inputs_status == "partial", a$outputs_status == "partial",
  a$assumptions_status == "partial"
)
comp <- x[x$measure == "proportion_at_age", ]
sums <- aggregate(
  value ~ year + type + fleet + survey,
  transform(comp,
    fleet = ifelse(is.na(fleet), "", fleet),
    survey = ifelse(is.na(survey), "", survey)
  ), sum
)
stopifnot(
  all(abs(sums$value - 1) < 1e-10),
  nrow(comp[comp$type == "catch", ]) == 900L,
  !any(comp$year[comp$type == "catch"] == 2024)
)
ats <- x[!is.na(x$survey) & x$survey == "NMFS acoustic-trawl", ]
stopifnot(
  all(ats$age[ats$measure == "proportion_at_age"] >= 2),
  all(ats$sampling_time == 0.5)
)
age1 <- x[!is.na(x$survey) & x$survey == "NMFS acoustic-trawl age-1 index", ]
stopifnot(nrow(age1) == 18L, all(age1$age == 1), !any(age1$year == 2024))
catch <- x[x$type == "catch" & x$measure == "total_biomass", ]
stopifnot(nrow(catch) == 61L, catch$value[catch$year == 2024] == 1300)
maturity <- x[x$type == "maturity", ]
stopifnot(nrow(maturity) == 15L, all(maturity$year == 1964))
n <- y[y$measure == "numbers_at_age", ]
r <- y[y$measure == "recruitment", ]
stopifnot(
  nrow(n) == 610L, nrow(r) == 61L,
  all(n$age_group[n$age == 10] == "10+"),
  all(abs(n$value[n$age == 1] * 1000 - r$value) <= 6),
  all(is.na(y$se)), all(is.na(y$lwr)), all(is.na(y$upr))
)
message("EBS pollock composition, survey timing/exclusion and output-group checks passed.")
m <- x[x$type == "M", ]
stopifnot(
  nrow(m) == 15, identical(m$age, 1:15),
  identical(m$value, c(.9, .45, rep(.3, 13))), all(is.na(m$year)), all(is.na(m$year_basis))
)
message("Fixed age-specific M inputs verified.")
initial <- assumptions[assumptions$assessment_id == id &
  assumptions$setting == "initial_abundance_parameterization", ]
stopifnot(
  nrow(initial) == 1L,
  grepl("log_avginit", initial$notes, fixed = TRUE),
  grepl("ctrl_flag(3)=1", initial$notes, fixed = TRUE),
  grepl("phases below 3", initial$notes, fixed = TRUE)
)

survey_weights <- x[x$type == "weight" & x$measure == "weight_at_age" &
  !is.na(x$survey) & nzchar(x$survey), ]
stopifnot(
  nrow(survey_weights) == 1185L,
  nrow(survey_weights[survey_weights$survey == "NMFS bottom-trawl VAST", ]) == 630L,
  nrow(survey_weights[survey_weights$survey == "NMFS acoustic-trawl", ]) == 285L,
  nrow(survey_weights[survey_weights$survey == "Acoustic vessels of opportunity", ]) == 270L,
  all(survey_weights$age %in% 1:15)
)
index_sd <- x[x$measure == "index_sd", ]
stopifnot(
  nrow(index_sd) == 91L,
  all(index_sd$value > 0),
  nrow(index_sd[index_sd$survey == "Historical fishery CPUE", ]) == 12L,
  nrow(index_sd[index_sd$survey == "Acoustic vessels of opportunity", ]) == 18L,
  nrow(index_sd[index_sd$survey == "NMFS bottom-trawl VAST", ]) == 42L,
  nrow(index_sd[index_sd$survey == "NMFS acoustic-trawl", ]) == 19L
)
length_comp <- x[x$measure == "proportion_at_length", ]
stopifnot(
  nrow(length_comp) == 50L,
  abs(sum(length_comp$value) - 1) < 1e-12,
  all(length_comp$sample_size == 50),
  all(length_comp$length_bin == 20:69)
)
stopifnot(nrow(x[x$measure == "environmental_covariate", ]) == 42L)
message("Survey weights, index SDs, length composition, and temperature rows verified.")

bio_group <- y[y$measure == "biomass_by_age_group", ]
f <- y[y$measure == "fishing_mortality_at_age", ]
stopifnot(
  nrow(bio_group) == 61L,
  all(bio_group$age_group == "3+"),
  all(is.na(bio_group$age)),
  all(bio_group$source_type == "official_table"),
  nrow(f) == 61L * 15L,
  all(f$year %in% 1964:2024),
  all(f$age %in% 1:15),
  all(f$source_type == "native_model"),
  all(is.finite(f$value) & f$value > 0),
  all(f$age_group[f$age == 15] == "15+"),
  all(is.na(f$age_group[f$age < 15])),
  all(grepl("44e0cb0ac8698e1d3954273e8aaf760d7c76cba5", f$source_reference,
    fixed = TRUE
  )),
  all(grepl("reconstructed", f$notes, ignore.case = TRUE))
)

par_path <- file.path("source_cache", id, "pm_or.parxx"
)
par_lines <- readLines(par_path, warn = FALSE)
markers <- grep("^# [A-Za-z0-9_]+:$", par_lines)
par_names <- sub("^# ([A-Za-z0-9_]+):$", "\\1", par_lines[markers])
par_values <- lapply(seq_along(markers), function(i) {
  end <- if (i < length(markers)) markers[i + 1L] - 1L else length(par_lines)
  values <- suppressWarnings(as.numeric(unlist(strsplit(
    trimws(par_lines[(markers[i] + 1L):end]), "[[:space:]]+"
  ))))
  values[is.finite(values)]
})
names(par_values) <- par_names
expected_fmean <- exp(par_values$log_avg_F + par_values$log_F_devs)
observed_fmean <- aggregate(value ~ year, f, mean)
observed_fmean <- observed_fmean$value[match(1964:2024, observed_fmean$year)]
stopifnot(
  length(expected_fmean) == 61L,
  length(observed_fmean) == 61L,
  isTRUE(all.equal(observed_fmean, expected_fmean, tolerance = 1e-10))
)
message("Recovered biomass group and reconstructed F-at-age outputs verified.")
