source("R/read_database.R")
x <- read_assessment("dfo_canary_bc_2022")
i <- x$inputs
o <- x$outputs
stopifnot(x$stocks$scientific_name == "Sebastes pinniger", is.na(x$stocks$charbonneau_id),
  x$stocks$ocean == "Northeast Pacific", x$assessment$is_current, x$assessment$is_applied,
  x$assessment$assessment_year == 2022, x$assessment$terminal_year == 2022,
  x$assessment$estimate_terminal_year == 2023,
  all(x$assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"),
  nrow(i) == 8815L, nrow(o) == 10827L, !any(i$type == "M"))

catch <- i[i$type == "catch" & i$measure == "total_biomass", ]
stopifnot(nrow(catch) == 176L, setequal(catch$year, 1935:2022),
  setequal(catch$fleet, c("TRAWL_FISHERY", "OTHER_FISHERY")), all(catch$unit == "t"))
stopifnot(abs(sum(catch$value[catch$year == 2022]) - 780) < 1e-6,
  catch$value[catch$year == 2022 & catch$fleet == "TRAWL_FISHERY"] == 766.6636648,
  catch$value[catch$year == 2022 & catch$fleet == "OTHER_FISHERY"] == 13.33633516)
indices <- i[i$type == "index" & i$measure %in% c("relative_biomass_index", "total_biomass"), ]
stopifnot(nrow(indices) == 78L, length(unique(indices$survey)) == 7L,
  max(abs(indices$sampling_time - 5/12)) < 1e-12,
  all(indices$unit[indices$survey == "TRAWL_CPUE"] == "relative index"),
  all(indices$unit[indices$survey != "TRAWL_CPUE"] == "t"))
p <- i[i$measure == "proportion_at_age", ]
stopifnot(nrow(p) == 7080L, setequal(p$age, 1:60),
  setequal(p$sex, c("female", "male")), length(unique(p$observation_id)) == 59L,
  all(p$sample_size > 0), all(p$age_error %in% 1:5),
  max(abs(tapply(p$value, p$observation_id, sum) - 1)) < 1e-5,
  !any(p$fleet == "OTHER_FISHERY", na.rm = TRUE),
  !any(p$year > 2017 & p$type == "catch"))

# Preserve both the supplied maturity and the actual source spawning weights.
vector <- function(type, measure, season) {
  v <- i[i$type == type & i$measure == measure & i$sex == "female" &
           !is.na(i$season) & i$season == season & is.na(i$survey), ]
  v <- v[order(v$age), ]
  stopifnot(identical(v$age, 0:60), all(is.na(v$year)))
  v$value
}
begin <- vector("weight", "weight_at_age", "begin_year")
mid <- vector("weight", "weight_at_age", "mid_year")
fec <- vector("biology", "maturity_fecundity_at_age", "spawning")
mat <- i[i$type == "maturity", ]; mat <- mat$value[order(i$age[i$type == "maturity"])]
stopifnot(begin[2] == .003657, mid[2] == .0154462, all(begin > 0),
  all(mat[5:10] > 0), all(fec[1:10] == 0),
  max(abs(fec[11:61]/begin[11:61] - mat[11:61])) < 1e-5,
  all(i$source_type[i$type %in% c("weight", "catch_weight", "biology")] == "reconstructed_source_input"))

ssb <- o[o$measure == "SSB", ]
published <- o[o$measure == "published_terminal_SSB", ]
stopifnot(identical(ssb$year, 1935:2023), all(ssb$sex == "female"), all(ssb$unit == "t"),
  all(is.na(o$se)), all(ssb$lwr > 0 & ssb$lwr <= ssb$value & ssb$value <= ssb$upr),
  all(grepl("95% credible", ssb$notes, fixed = TRUE)),
  ssb$value[ssb$year == 2023] == 10516.1,
  published$value == 10761, published$lwr == 7275, published$upr == 17637,
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "recruitment")))
m <- o[o$measure == "natural_mortality_at_age", ]
stopifnot(nrow(m) == 10736L, setequal(m$year, 1935:2022),
  all(m$value[m$sex == "female"] == .09329), all(m$value[m$sex == "male"] == .06543),
  all(grepl("90% credible", m$notes, fixed = TRUE)))
cat("Canary source values, fleet/sex coverage, timing, effective maturity and uncertainty checks passed.\n")
