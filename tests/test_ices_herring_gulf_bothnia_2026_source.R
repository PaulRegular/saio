source("R/read_database.R")
source_data <- read_assessment("ices_herring_gulf_bothnia_2026")

inputs <- source_data$inputs
outputs <- source_data$outputs
assumptions <- source_data$assumptions
catch <- inputs[inputs$type == "catch" & inputs$measure == "numbers_at_age", ]
catch_prop <- inputs[inputs$type == "catch" & inputs$measure == "proportion_at_age", ]
catch_total <- inputs[inputs$type == "catch" & inputs$measure == "total_biomass", ]
catch_weight <- inputs[inputs$type == "catch_weight" & inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$type == "maturity" & inputs$measure == "maturity_at_age", ]
m <- inputs[inputs$type == "M" & inputs$measure == "natural_mortality_at_age", ]
acoustic <- inputs[inputs$type == "index" & inputs$measure == "numbers_at_age", ]
trapnet <- inputs[
  inputs$type == "index" & inputs$measure == "relative_abundance_index", ]
trapnet_assumption <- assumptions[
  assumptions$component == "index" &
    assumptions$setting == "trapnet_index", ]
recruitment <- outputs[outputs$measure == "recruitment", ]
ssb <- outputs[outputs$measure == "SSB", ]
fbar <- outputs[outputs$measure == "Fbar", ]

proportion_sums <- aggregate(value ~ year, catch_prop, sum)

# The final settings table uses age classes; the working document uses midpoints.
break_m <- c(0.563, 0.472, 0.332, 0.290, 0.267, 0.257)
class_m <- approx(c(0.5, 1, 3, 5, 8, 15), break_m, xout = 0:20, rule = 2)$y
midpoint_m <- approx(c(0.5, 1.5, 3.5, 5.5, 8.5, 15.5), break_m,
  xout = (0:20) + 0.5, rule = 2)$y
stopifnot(
  max(abs(class_m - midpoint_m)) < 1e-12,
  identical(sort(m$age), 0:20),
  max(abs(m$value[order(m$age)] - midpoint_m)) < 1e-12,
  abs(m$value[m$age == 1] - 0.472) < 1e-12,
  abs(m$value[m$age == 2] - 0.402) < 1e-12
)

stopifnot(
  source_data$stocks$stock_id == "ices_herring_gulf_bothnia",
  source_data$stocks$authority_stock_id == "her.27.3031",
  source_data$stocks$area == "ICES subdivisions 30 and 31",
  source_data$stocks$ocean == "Northeast Atlantic",
  source_data$assessment$assessment_year == 2026,
  source_data$assessment$terminal_year == 2025,
  source_data$assessment$estimate_terminal_year == 2025,
  source_data$assessment$model_version == "3.30.22.1",
  source_data$assessment$is_current,
  source_data$assessment$is_applied,
  source_data$assessment$assumptions_status == "partial",
  source_data$assessment$inputs_status == "partial",
  source_data$assessment$outputs_status == "partial",
  nrow(catch_total) == 63L,
  identical(sort(unique(catch_total$year)), 1963:2025),
  catch_total$value[catch_total$year == 2025] == 67344,
  nrow(catch) == 46L * 15L,
  identical(sort(unique(catch$year)), 1980:2025),
  identical(sort(unique(catch$age)), 1:15),
  catch$value[catch$year == 2025 & catch$age == 1] == 426132,
  nrow(catch_prop) == 46L * 15L,
  all(abs(proportion_sums$value - 1) < 1e-12),
  all(catch_prop$basis == "proportion_numbers"),
  nrow(catch_weight) == 63L * 18L,
  identical(sort(unique(catch_weight$age)), 0:17),
  catch_weight$value[catch_weight$year == 2025 & catch_weight$age == 1] == 0.00885,
  nrow(maturity) == 46L * 17L,
  identical(sort(unique(maturity$age)), 1:17),
  maturity$value[maturity$year == 2025 & maturity$age == 2] == 0.73,
  nrow(m) == 21L,
  all(is.na(m$year)),
  m$value[m$age == 0] == 0.563,
  m$value[m$age == 15] == 0.257,
  nrow(acoustic) == 19L * 16L,
  identical(sort(unique(acoustic$year)), 2007:2025),
  identical(sort(unique(acoustic$age)), 0:15),
  acoustic$value[acoustic$year == 2007 & acoustic$age == 5] == 5449.22,
  acoustic$value[acoustic$year == 2025 & acoustic$age == 15] == 24.63,
  all(acoustic$unit == "million fish"),
  nrow(trapnet) == 17L,
  identical(sort(unique(trapnet$year)), 1990:2006),
  all(is.na(trapnet$age)),
  all(trapnet$survey == "Commercial trapnet CPUE"),
  all(trapnet$basis == "index_scale"),
  all(trapnet$unit == "relative index units"),
  all(trapnet$source_type == "digitized"),
  nrow(trapnet_assumption) == 1L,
  grepl("exact 2026 production series unresolved", trapnet_assumption$value),
  grepl("no digitization error or likelihood weights were inferred", trapnet_assumption$notes),
  all(grepl("Figure 6", trapnet$source_reference)),
  all(grepl("nearest 0.01", trapnet$transformation)),
  all(grepl("not verified against the final 2026 production input array", trapnet$notes)),
  identical(trapnet$value[order(trapnet$year)],
    c(0.24, 0.29, 0.42, 0.32, 0.39, 0.28, 0.30, 0.24, 0.21,
      0.18, 0.21, 0.27, 0.26, 0.22, 0.25, 0.41, 0.29)),
  nrow(recruitment) == 63L,
  nrow(ssb) == 63L,
  nrow(fbar) == 63L,
  recruitment$value[recruitment$year == 2025] == 24418100,
  recruitment$lwr[recruitment$year == 2025] == 9692671.83925113,
  ssb$value[ssb$year == 2025] == 603383,
  ssb$upr[ssb$year == 2025] == 763375.042,
  fbar$value[fbar$year == 2025] == 0.138778,
  all(is.na(c(recruitment$se, ssb$se, fbar$se))),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age")),
  all(inputs$year[!is.na(inputs$year)] <= 2025),
  all(outputs$year[!is.na(outputs$year)] <= 2025)
)

cat("Gulf of Bothnia herring source identity, coverage, units, transformations, and reported summaries passed.\n")
