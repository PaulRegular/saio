source("R/read_database.R")
x <- read_assessment("afsc_pop_bsai_2024")
i <- x$inputs
o <- x$outputs
stopifnot(x$stocks$ocean == "Northeast Pacific", x$stocks$charbonneau_id == "AFSC_alutus_BSAI",
  x$assessment$terminal_year == 2024, x$assessment$is_current,
  sum(i$type == "catch" & i$measure == "total_biomass") == 65L,
  setequal(unique(i$survey[!is.na(i$survey)]), c("AI_survey", "EBS_survey")),
  all(is.na(i$sampling_time)),
  sum(i$type == "weight") == 44L,
  i$value[i$type == "weight" & i$age == 3] == 94,
  all(i$unit[i$type == "weight"] == "g/fish"),
  !any(i$type == "M"), !any(i$type == "maturity"),
  sum(i$measure == "maturity_sample_size") == 44L,
  all(i$sample_size[i$type == "catch" & i$measure == "proportion_at_age" &
                      i$year == 1981] == 23 * 5.74044),
  i$value[i$measure == "composition_sample_count" & i$fleet == "Combined fishery" &
            i$year == 1981 & grepl("proportion_at_age", i$observation_id)] == 510,
  o$value[o$measure == "SSB" & o$year == 2024] == 359278,
  o$value[o$measure == "total_biomass" & o$year == 2024] == 864800,
  all(o$value[o$measure == "natural_mortality_at_age"] == 0.0505762),
  all(o$se[o$measure == "SSB"] > 0),
  all(is.na(o$se[o$measure == "fishing_mortality_at_age"])))
n <- o[o$measure == "numbers_at_age", ]
stopifnot(identical(sort(unique(n$age)), 3:40),
          all(n$age_group[n$age == 40] == "40+"))
abundance <- o[o$measure == "total_abundance", ]
expected_abundance <- aggregate(value ~ year, n, sum)
stopifnot(identical(sort(abundance$year), 1960:2024),
          identical(abundance$source_type, rep("derived_source_output", 65L)),
          all(abundance$unit == "million fish"),
          all(is.na(abundance$se)), all(is.na(abundance$lwr)), all(is.na(abundance$upr)),
          isTRUE(all.equal(
            unname(abundance$value[match(expected_abundance$year, abundance$year)]),
            unname(expected_abundance$value), tolerance = 1e-6
          )))
cat("BSAI POP source values, units, groups and active-input distinctions passed.\n")
