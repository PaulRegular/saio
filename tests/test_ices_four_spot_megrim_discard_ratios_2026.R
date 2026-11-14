Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
e <- new.env(parent = globalenv())
sys.source("scripts/database/650_import_ices_four_spot_megrim_discard_ratios_2026.R", envir = e)

inputs <- e$inputs
weight_ratio <- inputs[inputs$measure == "discard_fraction" &
  inputs$basis == "proportion_biomass", , drop = FALSE]
number_ratio <- inputs[inputs$measure == "discard_fraction" &
  inputs$basis == "proportion_numbers", , drop = FALSE]
ratio_cv <- inputs[inputs$measure == "discard_fraction_cv", , drop = FALSE]
num <- function(x) as.numeric(x)

expected_years <- c(1994L, 1997L, 1999L, 2000L, 2003:2025)
expected_weight_ratio <- c(.30, .28, .24, .29, .21, .30, .32, .27, .25,
  .20, .23, .19, .24, .39, .35, .41, .34, .23,
  .21, .10, .21, .10, .13, .16, .10, .07, .05)
expected_number_ratio <- c(.50, .63, .59, .61, .47, .55, .55, .42, .47,
  .42, .39, .62, .50, .52, .63, .67, .60, .47,
  .39, .24, .41, .21, .26, .30, .21, .15, .10)
expected_cv <- c(.232, .112, .144, .165, .102, .231, .240, .484, .183,
  .226, .211, .188, .160, .155, .232, .178, .201, .164, .152,
  rep(NA_real_, 8L))

stopifnot(
  nrow(inputs) == 81L,
  nrow(weight_ratio) == 27L,
  nrow(number_ratio) == 27L,
  nrow(ratio_cv) == 27L,
  identical(as.integer(weight_ratio$year), expected_years),
  identical(as.integer(number_ratio$year), expected_years),
  identical(as.integer(ratio_cv$year), expected_years),
  identical(num(weight_ratio$value), expected_weight_ratio),
  identical(num(number_ratio$value), expected_number_ratio),
  isTRUE(all.equal(num(ratio_cv$value), expected_cv, check.attributes = FALSE)),
  all(weight_ratio$unit == "proportion"),
  all(number_ratio$unit == "proportion"),
  all(ratio_cv$unit == "ratio"),
  sum(is.na(num(ratio_cv$value))) == 8L,
  all(grepl("blank cells remain missing", ratio_cv$notes, fixed = TRUE)),
  grepl("divided by 100", ratio_cv$transformation[1L], fixed = TRUE),
  all(weight_ratio$fleet == "Spanish onboard sampling"),
  all(number_ratio$source_reference == "https://doi.org/10.17895/ices.pub.32790321.v2; WGBIE 2026, Table 6.4.2a"),
  e$register$matched_stock_id[e$candidate_row] == e$stock_id,
  e$register$match_status[e$candidate_row] == "matched",
  e$inventory$matched_stock_id[e$inventory_row] == e$stock_id,
  e$inventory$match_status[e$inventory_row] == "matched",
  nrow(e$missing_inputs) %in% c(0L, 81L)
)

cat("ICES four-spot megrim discard-ratio inputs and candidate crosswalk passed.\n")
