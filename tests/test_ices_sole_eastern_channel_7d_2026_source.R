source("R/read_database.R")
x <- read_assessment("ices_sole_eastern_channel_7d_2026")
i <- x$inputs
o <- x$outputs
a <- x$assessment

stopifnot(
  identical(x$stocks$authority_stock_id, "sol.27.7d"),
  identical(x$stocks$scientific_name, "Solea solea"),
  identical(a$terminal_year, 2025L),
  identical(a$inputs_status, "partial"),
  identical(a$assumptions_status, "complete"),
  identical(a$outputs_status, "partial"),
  nrow(x$assumptions) == 25L,
  sum(i$type == "catch" & i$measure == "numbers_at_age") == 44L * 11L,
  sum(i$type == "catch_weight") == 44L * 11L,
  sum(i$type == "weight") == 44L * 11L,
  sum(i$type == "M") == 11L,
  all(i$value[i$type == "M"] == 0.1),
  identical(sort(unique(i$age[i$type == "maturity"])), 0:11),
  sum(i$type == "covariate") == 83L,
  sum(i$type == "index" & i$measure == "relative_biomass_index") == 83L,
  identical(sort(unique(i$year[i$survey == "UK(E&W)-YFS"])), 1987:2006),
  identical(sort(unique(i$year[i$survey == "FR-YFS"])), 1987:2023),
  !2022L %in% unique(i$year[i$survey == "UK(E&W)-BTS-Q3"]),
  sum(o$measure == "numbers_at_age") == 44L * 11L,
  sum(o$measure == "fishing_mortality_at_age") == 44L * 11L,
  sum(o$measure == "mature_biomass_at_age") == 44L * 11L,
  sum(o$measure == "total_numbers") == 44L,
  sum(o$measure == "total_biomass") == 44L,
  sum(o$measure == "SSB" & o$year == 2026L) == 1L,
  all(is.na(o$se[o$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "mature_biomass_at_age")]))
)

n <- o[o$measure == "numbers_at_age", ]
f <- o[o$measure == "fishing_mortality_at_age", ]
ssb_age <- o[o$measure == "mature_biomass_at_age", ]
stopifnot(
  all(n$year >= 1982 & n$year <= 2025),
  all(f$year >= 1982 & f$year <= 2025),
  all(ssb_age$year >= 1982 & ssb_age$year <= 2025),
  all(grepl("do not sum to annual SSB", ssb_age$notes[ssb_age$year >= 2021]))
)

ssb_summary <- o[o$measure == "SSB" & o$year <= 2025, ]
ssb_sum_by_age <- aggregate(value ~ year, ssb_age, sum)
ssb_check <- merge(ssb_summary[c("year", "value")], ssb_sum_by_age, by = "year", suffixes = c("_summary", "_age"))
stopifnot(
  max(abs(ssb_check$value_age[ssb_check$year <= 2020] - ssb_check$value_summary[ssb_check$year <= 2020])) <= 2,
  any(abs(ssb_check$value_age[ssb_check$year >= 2021] - ssb_check$value_summary[ssb_check$year >= 2021]) > 100)
)

cat("Eastern Channel sole source coverage, provenance, derived outputs, and SSB table discrepancy passed.\n")
