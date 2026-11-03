source("R/read_database.R")
x <- read_assessment("ices_herring_gulf_riga_2026")
i <- x$inputs
o <- x$outputs

catch <- i[i$type == "catch" & i$measure == "numbers_at_age", ]
index <- i[i$type == "index" & i$measure == "numbers_at_age", ]
m <- i[i$type == "M" & i$measure == "natural_mortality_at_age", ]
prop_f <- i[i$measure == "fraction_F_before_spawning", ]
prop_m <- i[i$measure == "fraction_M_before_spawning", ]
n <- o[o$measure == "numbers_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
ssb <- o[o$measure == "SSB", ]
recruitment <- o[o$measure == "recruitment", ]
fbar <- o[o$measure == "Fbar", ]
total_n <- o[o$measure == "total_numbers", ]
predicted_catch <- o[o$measure == "predicted_catch", ]
predicted_index <- o[o$measure == "predicted_index", ]
a <- x$assumptions

stopifnot(
  x$stocks$common_name == "Gulf of Riga herring",
  x$stocks$authority_stock_id == "her.27.28",
  x$stocks$area == "ICES Subdivision 28.1 (Gulf of Riga)",
  x$assessment$assessment_year == 2026,
  x$assessment$terminal_year == 2025,
  x$assessment$framework_year == 2023,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$assumptions_status == "complete",
  x$assessment$inputs_status == "complete",
  x$assessment$outputs_status == "complete",
  nrow(catch) == 49L * 9L,
  identical(sort(unique(catch$year)), 1977:2025),
  identical(sort(unique(catch$age)), 0:8),
  catch$value[catch$year == 1977 & catch$age == 0] == 800,
  all(catch$unit == "thousand fish"),
  nrow(index) == 27L * 8L,
  identical(sort(unique(index$year)), 1999:2025),
  identical(sort(unique(index$age)), 1:8),
  index$value[index$year == 1999 & index$age == 1] == 5292,
  all(index$survey == "GRAHS"),
  all(index$basis == "index_scale"),
  all(index$sampling_time == 0.675),
  all(grepl("multiplier not stated", index$unit)),
  nrow(m) == 49L * 9L,
  all(m$value[m$year %in% 1979:1983] == 0.25),
  all(m$value[!m$year %in% 1979:1983] == 0.20),
  all(prop_f$value[prop_f$year <= 1998] == 0.10),
  all(prop_f$value[prop_f$year >= 1999] == 0.20),
  all(prop_m$value == 0.30),
  any(a$component == "catch" & a$setting == "observation_variance_sharing" &
    a$value == "Age 0 separate; ages 1-8 share"),
  any(a$component == "index" & a$setting == "observation_variance_sharing" &
    a$value == "Age 1; ages 2-7; age 8+"),
  any(a$component == "index" & a$setting == "observation_correlation" &
    grepl("transitions 1-2 through 4-5", a$notes)),
  nrow(n) == 49L * 9L,
  nrow(f) == 49L * 9L,
  identical(sort(unique(n$age)), 0:8),
  identical(sort(unique(f$age)), 0:8),
  all(is.finite(n$se)),
  all(is.finite(f$se)),
  all(n$se > 0),
  all(f$se > 0),
  max(abs(f$value[f$age == 7] - f$value[f$age == 8])) == 0,
  nrow(ssb) == 49L,
  nrow(recruitment) == 49L,
  nrow(fbar) == 49L,
  all(grepl("95% confidence", c(ssb$notes, recruitment$notes, fbar$notes))),
  all(ssb$lwr < ssb$value & ssb$value < ssb$upr),
  all(recruitment$lwr < recruitment$value & recruitment$value < recruitment$upr),
  all(fbar$lwr < fbar$value & fbar$value < fbar$upr),
  fbar$age_group[fbar$year == 2025] == "2-6",
  abs(ssb$value[ssb$year == 2025] - 157812.5) < 0.1,
  abs(recruitment$value[recruitment$year == 2025] - 2832471) < 1,
  abs(fbar$value[fbar$year == 2025] - 0.2252219) < 1e-6,
  nrow(total_n) == 49L,
  all(total_n$source_type == "derived_source_output"),
  all(is.na(total_n$se)),
  all.equal(
    total_n$value[total_n$year == 2025],
    sum(n$value[n$year == 2025]), tolerance = 1e-12
  ) == TRUE,
  nrow(predicted_catch) == 49L * 9L,
  nrow(predicted_index) == 27L * 8L,
  all(predicted_index$survey == "GRAHS"),
  all(i$year[!is.na(i$year)] <= 2025),
  all(o$year[!is.na(o$year)] <= 2025),
  !anyDuplicated(paste(i$type, i$measure, i$fleet, i$survey, i$year, i$age)),
  !anyDuplicated(paste(o$measure, o$year, o$age, o$survey))
)

cat("Gulf of Riga herring source identity, inputs, fit outputs, units and uncertainty passed.\n")
