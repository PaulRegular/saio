source("R/read_database.R")
x <- read_assessment("afsc_alaska_plaice_bsai_2024")
i <- x$inputs
o <- x$outputs
stopifnot(identical(x$stocks$ocean, "Northeast Pacific"),
  identical(x$assessment$model_version, "3.30.22, Model 24.1b"),
  identical(i$value[i$type == "catch" & i$measure == "total_biomass" & i$year == 2024], 13755),
  identical(o$value[o$measure == "SSB" & o$year == 2024], 147511),
  identical(o$value[o$measure == "total_biomass" & o$year == 2024], 394455),
  all(i$value[i$type == "M"] == .13),
  !any(i$type %in% c("weight", "catch_weight")),
  all(i$sampling_time[i$type == "index" & i$measure == "total_biomass"] == .5))
p <- i[i$measure == "proportion_at_age", ]
stopifnot(identical(sort(unique(p$year[p$type == "catch"])), c(2000L, 2002L, 2003L)),
  all(abs(tapply(p$value, p$observation_id, sum) - 1) < 1e-5),
  identical(sort(unique(p$sex)), c("female", "male")))
n <- o[o$measure == "numbers_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
w <- o[o$measure == "weight_at_age", ]
mat <- i[i$type == "maturity", ]
stopifnot(nrow(n) == 50 * 26 * 2, nrow(f) == nrow(n), nrow(w) == 52,
  all(w$year == 2024), all(n$unit == "million fish"),
  all(o$sex[o$measure == "SSB"] == "female"),
  all(o$sex[o$measure == "recruitment"] == "combined"),
  all(is.finite(o$se[o$measure %in% c("SSB","recruitment")])),
  all(is.na(f$se)), all(is.na(w$se)))
for (year in 1975:2024) {
  z <- n[n$year == year, ]
  wt <- w$value[match(paste(z$sex, z$age), paste(w$sex, w$age))]
  b <- sum(z$value * wt)
  stopifnot(abs(b - o$value[o$measure == "total_biomass" & o$year == year]) < 2)
  female <- z$sex == "female"
  ssb <- sum(z$value[female] * wt[female] * mat$value[match(z$age[female],mat$age)])
  stopifnot(abs(ssb - o$value[o$measure == "SSB" & o$year == year]) < 2)
}
cat("Alaska plaice native units, sex structure, biology and biomass identities passed.\n")
