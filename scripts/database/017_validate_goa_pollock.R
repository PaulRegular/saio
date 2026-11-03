source("scripts/database/002_validate_database.R")
id <- "afsc_pollock_goa_2024"
x <- inputs[inputs$assessment_id == id, ]
y <- outputs[outputs$assessment_id == id, ]
a <- assessments[assessments$assessment_id == id, ]
stopifnot(
  nrow(x) == 5909, nrow(y) == 1134, a$model_version == "23d",
  a$inputs_status == "partial", a$outputs_status == "partial",
  grepl("Partial rounded-output F-at-age", a$notes, fixed = TRUE)
)
index <- x[x$type == "index", ]
totals <- index[index$measure == "total_biomass", ]
stopifnot(
  length(unique(totals$survey)) == 4, nrow(totals) == 90,
  !any(grepl("age-1|age-2", index$survey)),
  all(is.na(index$age[index$measure == "log_index_sd"]))
)
for (label in unique(totals$survey)) {
  z <- totals[totals$survey == label, ]
  s <- index[index$survey == label & index$measure == "log_index_sd", ]
  stopifnot(identical(z$year, s$year), identical(z$sampling_time, s$sampling_time))
}
stopifnot(
  all(totals$sampling_time[totals$survey == "Shelikof winter acoustic"] == .209),
  all(totals$sampling_time[totals$survey == "Summer acoustic"] == .519),
  all(totals$sampling_time[totals$survey == "ADF&G crab/groundfish trawl"] == .60989)
)
comp <- x[x$measure == "proportion_at_age", ]
fsh <- comp[comp$type == "catch", ]
shelikof <- comp[!is.na(comp$survey) & comp$survey == "Shelikof winter acoustic", ]
stopifnot(
  nrow(fsh) == 441, min(fsh$age) == 2, max(fsh$year) == 2023,
  nrow(shelikof) == 248, min(shelikof$age) == 3,
  all(fsh$source_type == "reconstructed_source_input"),
  all(shelikof$source_type == "reconstructed_source_input")
)
catch_numbers <- x[x$type == "catch" & x$measure == "numbers_at_age", ]
catch_numbers_source <- read.csv(
  "source_cache/afsc_pollock_goa_2024/report_catch_numbers_at_age.csv"
)
catch_numbers <- catch_numbers[order(catch_numbers$year, catch_numbers$age), ]
catch_numbers_source <- catch_numbers_source[order(
  catch_numbers_source$year,
  catch_numbers_source$age
), ]
stopifnot(
  nrow(catch_numbers) == 49 * 15,
  identical(catch_numbers$year, catch_numbers_source$year),
  identical(catch_numbers$age, catch_numbers_source$age),
  identical(catch_numbers$value, catch_numbers_source$value),
  all(catch_numbers$unit == "million fish"),
  all(catch_numbers$source_type == "official_table"),
  all(grepl("Table 1.6, p. 37", catch_numbers$source_reference, fixed = TRUE)),
  catch_numbers$value[catch_numbers$year == 2023 & catch_numbers$age == 1] == 0.43,
  catch_numbers$value[catch_numbers$year == 2023 & catch_numbers$age == 2] == 8.57
)
fixed_m <- x[x$type == "M" & x$measure == "natural_mortality_at_age", ]
fixed_maturity <- x[x$type == "maturity" & x$measure == "maturity_at_age", ]
stopifnot(
  nrow(fixed_m) == 10, nrow(fixed_maturity) == 10,
  setequal(fixed_m$age, 1:10), setequal(fixed_maturity$age, 1:10),
  all(is.na(fixed_m$year)), all(is.na(fixed_m$year_basis)),
  all(is.na(fixed_maturity$year)), all(is.na(fixed_maturity$year_basis)),
  nrow(x[x$measure == "spawning_weight_at_age", ]) == 550
)
n <- y[y$measure == "numbers_at_age", ]
r <- y[y$measure == "recruitment", ]
ssb <- y[y$measure == "SSB", ]
total_n <- y[y$measure == "total_numbers", ]
stopifnot(
  nrow(n) == 550, nrow(r) == 55, nrow(ssb) == 55,
  nrow(total_n) == 55,
  identical(n$value[n$age == 1], r$value),
  all(n$age_group[n$age == 10] == "10+"),
  all(r$lwr <= r$value & r$value <= r$upr),
  all(ssb$lwr <= ssb$value & ssb$value <= ssb$upr), all(is.na(y$se))
)
for (year in 1970:2024) {
  z <- n[n$year == year, ]
  stopifnot(total_n$value[total_n$year == year] == sum(z$value))
}
message("GOA pollock survey coverage, detailed catch numbers, grouped compositions, biology and uncertainty checks passed.")

f_at_age <- y[y$measure == "fishing_mortality_at_age" &
  y$source_type == "derived_source_output", ]
n_key <- paste(n$year, n$age, sep = ":")
n_value <- setNames(n$value, n_key)
m_value <- setNames(fixed_m$value, fixed_m$age)
f_source <- n[n$age <= 8 & n$year < 2024, ]
next_n <- unname(n_value[paste(f_source$year + 1, f_source$age + 1, sep = ":")])
rounding_lower <- log((f_source$value - 0.5) / (next_n + 0.5)) -
  unname(m_value[as.character(f_source$age)])
f_source <- f_source[is.finite(rounding_lower) & rounding_lower > 0, ]
expected_f <- log(
  f_source$value / unname(n_value[paste(f_source$year + 1, f_source$age + 1, sep = ":")])
) - unname(m_value[as.character(f_source$age)])
f_at_age <- f_at_age[order(f_at_age$year, f_at_age$age), ]
f_source <- f_source[order(f_source$year, f_source$age), ]
stopifnot(
  nrow(f_at_age) == 371L,
  identical(f_at_age$year, f_source$year),
  identical(f_at_age$age, f_source$age),
  isTRUE(all.equal(f_at_age$value, expected_f, tolerance = 1e-12)),
  all(f_at_age$value > 0),
  all(f_at_age$year %in% 1970:2023),
  all(f_at_age$age %in% 1:8),
  all(f_at_age$unit == "per year"),
  all(f_at_age$source_type == "derived_source_output"),
  all(is.na(f_at_age$se)), all(is.na(f_at_age$lwr)), all(is.na(f_at_age$upr)),
  all(grepl("rounded to the nearest million fish", f_at_age$notes, fixed = TRUE))
)
message("Partial GOA pollock F-at-age reconstruction matches the cohort equation and published rounding limits.")

covariate <- x[x$type == "covariate", ]
native <- read.csv("source_cache/afsc_pollock_goa_2024/native_inputs_raw.csv")
stopifnot(
  nrow(covariate) == 40,
  identical(as.numeric(covariate$year), native$value[native$key == "Ecov_obs_year"]),
  identical(covariate$value, native$value[native$key == "Ecov_obs"]),
  all(covariate$basis == "native_covariate"),
  all(covariate$survey == "Shelikof winter acoustic")
)
message("GOA pollock environmental observations match native input values and years.")

stopifnot(all(is.finite(comp$sample_size)), all(comp$sample_size > 0))
for (label in c("Combined fishery", unique(comp$survey[!is.na(comp$survey)]))) {
  z <- if (label == "Combined fishery") fsh else comp[!is.na(comp$survey) & comp$survey == label, ]
  stopifnot(all(vapply(split(z$sample_size, z$year), function(v) length(unique(v)) == 1, logical(1))))
}
age_transition <- native[native$key == "age_trans", ]
stopifnot(
  nrow(age_transition) == 100, all(age_transition$value >= 0),
  all(abs(tapply(age_transition$value, age_transition$row, sum) - 1) < 0.00011)
)
message("Composition sample sizes and native age-transition dimensions validated.")

source_sizes <- list(
  "Combined fishery" = c("fshyrs", "multN_fsh", "1"),
  "Shelikof winter acoustic" = c("srv_acyrs1", "multN_srv1", "2"),
  "NMFS bottom trawl" = c("srv_acyrs2", "multN_srv2", "1"),
  "ADF&G crab/groundfish trawl" = c("srv_acyrs3", "multN_srv3", "2"),
  "Summer acoustic" = c("srv_acyrs6", "multN_srv6", "2")
)
for (label in names(source_sizes)) {
  keys <- source_sizes[[label]]
  years <- native$value[native$key == keys[1]]
  sizes <- native$value[native$key == keys[2]] * as.numeric(keys[3])
  z <- if (label == "Combined fishery") fsh else comp[!is.na(comp$survey) & comp$survey == label, ]
  stopifnot(identical(z$sample_size, sizes[match(z$year, years)]))
}
record <- assumptions[assumptions$assessment_id == id & assumptions$setting == "age_error_matrix", ]
recorded_matrix <- as.numeric(strsplit(gsub("]", "", gsub("[", "", record$value, fixed = TRUE), fixed = TRUE), ",")[[1]])
source_matrix <- age_transition[order(age_transition$row, age_transition$column), ]
stopifnot(nrow(record) == 1, identical(recorded_matrix, source_matrix$value))
message("All composition weights and recorded age-error cells match native inputs exactly.")

stopifnot(
  length(native$value[native$key == "rwlk_sd"]) == 54,
  all(native$value[native$key == "rwlk_sd"] == 0.05)
)
q_sd <- assumptions$value[assumptions$assessment_id == id & assumptions$setting == "catchability_increment_sd"]
q_sd <- as.numeric(strsplit(gsub("]", "", gsub("[", "", q_sd, fixed = TRUE), fixed = TRUE), ",")[[1]])
stopifnot(identical(q_sd, native$value[native$key == "q3_rwlk_sd"]))
message("Active fishery and survey process-penalty scales match native values.")

biomass <- y[y$measure == "total_biomass", ]
source_biomass <- read.csv("source_cache/afsc_pollock_goa_2024/report_age3plus_biomass.csv")
stopifnot(
  nrow(biomass) == 48, all(biomass$age_group == "3+"),
  identical(biomass$value, as.numeric(source_biomass$value)),
  identical(ssb$value[match(source_biomass$year, ssb$year)], as.numeric(source_biomass$ssb)),
  identical(r$value[match(source_biomass$year, r$year)], as.numeric(source_biomass$recruitment))
)
message("Age-3+ biomass validated; table SSB and recruitment agree with independent published table.")
