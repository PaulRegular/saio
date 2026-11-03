source("R/read_database.R")
x <- read_assessment("afsc_pollock_ai_2024")
i <- x$inputs
o <- x$outputs
stopifnot(x$stocks$ocean == "Northeast Pacific", x$assessment$model_version == "Model 15.1",
  i$value[i$type == "catch" & i$measure == "total_biomass" & i$year == 1981] == 31258,
  i$value[i$type == "catch" & i$measure == "total_biomass" & i$year == 2024] == 5106,
  !any(i$type == "M"), !any(i$type == "weight" & is.na(i$survey)),
  i$value[i$type == "maturity" & i$age == 4] == .269,
  all(i$sample_size[i$type == "index" & i$measure == "proportion_at_age" & i$year == 1991] == 1),
  !any(i$type == "index" & i$year < 1991),
  all(is.na(i$sampling_time)),
  o$value[o$measure == "SSB" & o$year == 2024] == 84723,
  o$lwr[o$measure == "SSB" & o$year == 2024] == 63346,
  o$se[o$measure == "recruitment" & o$year == 2024] == 71.1,
  all(o$value[o$measure == "natural_mortality_at_age"] == .206),
  all(o$year[o$measure == "fishing_mortality_at_age"] == 2024),
  abs(mean(o$value[o$measure == "fishing_mortality_at_age"]) - .021) < 1e-12,
  sum(grepl("^age_error_row_", x$assumptions$setting)) == 15)
n <- o[o$measure == "numbers_at_age", ]
r <- o[o$measure == "recruitment", ]
stopifnot(nrow(n) == 47 * 15, all(n$unit == "billion fish"),
  all(r$unit == "million fish"),
  max(abs(n$value[n$age == 1] * 1000 - r$value)) <= .5 + 1e-10)
cat("AI pollock official columns, units, fixed/estimated status and F definition passed.\n")
