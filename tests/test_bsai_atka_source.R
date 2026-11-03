source("R/read_database.R")
x <- read_assessment("afsc_atka_mackerel_bsai_2024")
i <- x$inputs
o <- x$outputs
stopifnot(x$stocks$ocean == "Northeast Pacific",
  x$assessment$model_version == "Model 16.0b",
  all(x$assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  i$value[i$type == "catch" & i$measure == "total_biomass" & i$year == 2024] == 72987,
  i$value[i$type == "index" & i$measure == "total_biomass" & i$year == 2024] == 574769,
  i$value[i$measure == "relative_standard_error" & i$year == 2024] == .25,
  all(abs(i$sampling_time[i$type == "index" & i$measure == "total_biomass"] - 6.5 / 12) < 1e-12),
  all(i$value[i$type == "M"] == .3),
  i$value[i$type == "weight" & is.na(i$survey) & i$age == 1] == .058,
  i$value[i$type == "maturity" & i$age == 1] == .005,
  !any(i$type == "catch" & i$measure == "proportion_at_age" & i$year == 1989),
  all(is.na(i$sample_size)),
  o$value[o$measure == "SSB" & o$year == 2024] == 128919,
  o$lwr[o$measure == "SSB" & o$year == 2024] == 84531,
  o$upr[o$measure == "SSB" & o$year == 2024] == 196616,
  o$se[o$measure == "recruitment" & o$year == 2024] == 187,
  all(is.na(o$se[o$measure == "fishing_mortality_at_age"])))
cp <- i[i$measure == "proportion_at_age", ]
stopifnot(all(abs(tapply(cp$value, paste(cp$type, cp$year), sum) - 1) < 1e-10))
n <- o[o$measure == "numbers_at_age", ]
r <- o[o$measure == "recruitment", ]
stopifnot(nrow(n) == 48 * 11,
  identical(n$value[n$age == 1], r$value),
  n$value[n$age == 2 & n$year == 1979] == 1407)
w <- i[i$type == "weight" & is.na(i$survey), ]
b <- o[o$measure == "total_biomass", ]
for (year in b$year) {
  z <- n[n$year == year, ]
  ww <- w$value[match(z$age, w$age)]
  rounded <- sum(z$value * ww) * 1000
  rounding_bound <- sum(.5 * ww + .0005 * z$value + .5 * .0005) * 1000
  stopifnot(abs(rounded - b$value[b$year == year]) <= rounding_bound)
}
f <- matrix(o$value[o$measure == "fishing_mortality_at_age"], 48, 11)
nn <- matrix(n$value, 48, 11)
cohorts <- nn[-48, 1:9] * exp(-.3 - f[-48, 1:9])
stopifnot(max(abs(nn[-1, 2:10] - cohorts)) < 1.6)
cat("Atka source values, timing, native likelihood roles and report rounding passed.\n")
