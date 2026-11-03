source("R/read_database.R")
source("scripts/database/bc_petrale_posterior.R")
source("R/plot_stock_order.R")
x <- read_assessment("dfo_petrale_bc_2024")
stopifnot(x$stocks$scientific_name == "Eopsetta jordani", is.na(x$stocks$charbonneau_id),
  x$stocks$ocean == "Northeast Pacific", x$assessment$assessment_year == 2024,
  x$assessment$terminal_year == 2023, x$assessment$estimate_terminal_year == 2024,
  !x$assessment$is_current, x$assessment$is_applied,
  all(x$assessment[c("inputs_status", "outputs_status", "assumptions_status")] == "partial"))
metadata <- assessment_plot_stocks(x$assessment, x$stocks, "dfo_petrale_bc_2024")
stopifnot(as.character(metadata$basin) == "Northeast Pacific")

i <- x$inputs
stopifnot(nrow(i) == 3L, all(i$type == "M"), all(i$basis == "per_year"),
  setequal(i$measure, c("fixed_mortality_medium", "fixed_mortality_low", "fixed_mortality_high")),
  identical(i$value[match(c("fixed_mortality_low", "fixed_mortality_medium", "fixed_mortality_high"), i$measure)], c(.124, .154, .184)),
  all(is.na(i$age)), all(is.na(i$year)), all(is.na(i$sex)), all(is.na(i$sampling_time)),
  !any(i$type %in% c("catch", "index", "weight", "maturity")))
o <- x$outputs
ssb <- o[o$measure == "SSB", ]
terminal <- ssb[ssb$year == 2024, ]
published <- o[o$measure == "published_terminal_SSB", ]
stopifnot(nrow(ssb) == 87L, identical(ssb$year, 1938:2024),
  all(ssb$unit == "t"), all(ssb$sex == "female"), all(ssb$region == "BC coast"),
  all(ssb$source_type == "derived_source_output"), all(is.na(o$se)), all(is.na(o$age)),
  all(ssb$lwr > 0 & ssb$lwr <= ssb$value & ssb$value <= ssb$upr),
  all(grepl("95% credible", ssb$notes, fixed = TRUE)),
  abs(terminal$value - 17274.8) < 1e-8,
  abs(terminal$lwr - 10512.465) < 1e-7, abs(terminal$upr - 28107.5375) < 1e-7,
  published$value == 17330, published$lwr == 10830, published$upr == 27977,
  terminal$value != published$value, published$source_type == "official_table",
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "recruitment", "natural_mortality_at_age")))
a <- x$assumptions
stopifnot(setequal(a$survey[!is.na(a$survey)], c("QCS_SYNOPTIC", "HS_SYNOPTIC", "WCVI_SYNOPTIC")),
  all(a$value[a$setting == "sampling_time"] == "unknown"),
  a$value[a$setting == "age_range"] == "unknown",
  a$value[a$setting == "plus_group"] == "unknown",
  a$value[a$setting == "modeled_years"] == "1938-2023")

# Medians and equal-tail intervals are calculated per year, without averaging
# component intervals or replacing subset summaries with published values.
draws <- expand.grid(iter = 1:4, year = 2000:2001)
draws$b <- rep(c(1, 2, 3, 10), 2) * rep(c(1, 2), each = 4)
draws$bmsy <- rep(1:4, 2)
s <- summarize_bc_petrale_posterior(draws, 2000:2001)
stopifnot(identical(s$value, c(2.5, 5)),
  isTRUE(all.equal(s$lwr, c(1.075, 2.15))),
  isTRUE(all.equal(s$upr, c(9.475, 18.95))),
  identical(s, summarize_bc_petrale_posterior(draws[8:1, ], 2000:2001)))
testthat::expect_error(summarize_bc_petrale_posterior(draws[-1, ], 2000:2001), "complete year grid")
testthat::expect_error(summarize_bc_petrale_posterior(rbind(draws, draws[1, ]), 2000:2001), "complete year grid")
bad <- draws; bad$b[1] <- NA_real_
testthat::expect_error(summarize_bc_petrale_posterior(bad, 2000:2001), "positive[[:space:]]+biomass")
bad <- draws; bad$b[1] <- -1
testthat::expect_error(summarize_bc_petrale_posterior(bad, 2000:2001), "positive[[:space:]]+biomass")
bad <- draws; bad$bmsy[1] <- 10
testthat::expect_error(summarize_bc_petrale_posterior(bad, 2000:2001), "constant across years")
testthat::expect_error(summarize_bc_petrale_posterior(draws[, -1], 2000:2001), "require iter")
cat("BC petrale source provenance, subset/published uncertainty, component M scalars and missing-input checks passed.\n")
