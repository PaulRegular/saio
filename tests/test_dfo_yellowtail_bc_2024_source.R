source("R/read_database.R")
case <- read_assessment("dfo_yellowtail_bc_2024")
inputs <- case$inputs
outputs <- case$outputs
years <- 1935:2024
ages <- 0:45

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
surveys <- subset(inputs, type == "index" & measure == "total_biomass")
comps <- subset(inputs, measure == "proportion_at_age")
stopifnot(case$stocks$scientific_name == "Sebastes flavidus",
  case$stocks$ocean == "Northeast Pacific", case$assessment$terminal_year == 2024,
  identical(as.integer(catch$year), years), all(catch$fleet == "TRAWL_FISHERY_BC"),
  tail(catch$value, 1) == tail(catch$value, 2)[1L],
  nrow(surveys) == 57L, length(unique(surveys$survey)) == 6L,
  length(unique(comps$observation_id)) == 62L,
  all(abs(rowsum(comps$value, comps$observation_id) - 1) < 1e-5))

n <- subset(outputs, measure == "numbers_at_age")
f <- subset(outputs, measure == "fishing_mortality_at_age")
m <- subset(outputs, measure == "natural_mortality_at_age")
ssb <- subset(outputs, measure == "SSB")
posterior <- subset(outputs, measure == "spawning_biomass_posterior")
recruitment <- subset(outputs, measure == "recruitment")
abundance <- subset(outputs, measure == "total_numbers")
stopifnot(nrow(n) == 2L * length(years) * length(ages),
  nrow(f) == nrow(n), nrow(m) == nrow(n), all(f$unit == "per year"),
  identical(as.integer(ssb$year), years), all(is.na(ssb$lwr)),
  identical(as.integer(posterior$year), 1935:2025), all(is.finite(posterior$lwr)),
  all(outputs$upr[outputs$measure == "published_terminal_SSB"] == 40388),
  max(abs(rowsum(n$value[n$age == 0], n$year[n$age == 0]) / recruitment$value - 1)) < 1e-5,
  max(abs(rowsum(n$value, n$year) / abundance$value - 1)) < 1e-5)

female <- subset(n, sex == "female")
reproductive <- subset(inputs, measure == "maturity_fecundity_at_age" & sex == "female")
female$weight <- reproductive$value[match(female$age, reproductive$age)]
stopifnot(all(reproductive$value[reproductive$age < 9] == 0),
  reproductive$value[reproductive$age == 9] > 0,
  max(abs(rowsum(female$value * female$weight, female$year) / ssb$value - 1)) < 1e-5)

surface <- function(table, sex) {
  x <- table[table$sex == sex, ]
  key <- expand.grid(age = ages, year = years)
  matrix(x$value[match(paste(key$year, key$age), paste(x$year, x$age))],
    nrow = length(years), byrow = TRUE)
}
for (sex in c("female", "male")) {
  n_at_age <- surface(n, sex)
  survivors <- n_at_age * exp(-surface(f, sex) - surface(m, sex))
  expected <- cbind(survivors[, 1:44], rowSums(survivors[, 45:46]))
  stopifnot(max(abs(expected[-length(years), ] / n_at_age[-1L, -1L] - 1)) < 1e-5)
}
cat("Yellowtail inputs, posterior provenance and all four native trend series verified.\n")
