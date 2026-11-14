source("R/read_database.R")
source("tests/helper_inventory.R")

assessment_id <- "siofa_orange_roughy_wsr_2025"
x <- read_assessment(assessment_id)

stopifnot(
  x$stocks$stock_id == "siofa_orange_roughy_wsr",
  x$stocks$authority == "SIOFA",
  x$stocks$authority_stock_id == "WSR (assessment area)",
  x$stocks$ocean == "Southern Indian Ocean",
  x$assessment$assessment_year == 2025,
  x$assessment$terminal_year == 2023,
  x$assessment$estimate_terminal_year == 2023,
  x$assessment$is_current,
  !x$assessment$is_applied,
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x$inputs) == 0L,
  nrow(x$assumptions) == 20L,
  nrow(x$outputs) == 9L
)

outputs <- x$outputs
b0 <- outputs[outputs$measure == "unfished_spawning_biomass", , drop = FALSE]
ssb_ratio <- outputs[outputs$measure == "SSB_ratio_to_B0", , drop = FALSE]
catch <- outputs[outputs$measure == "catch_advice", , drop = FALSE]

stopifnot(
  b0$value == 25627,
  b0$lwr == 22409,
  b0$upr == 30034,
  is.na(b0$se),
  ssb_ratio$year == 2023,
  ssb_ratio$value == 59.3,
  ssb_ratio$lwr == 52.4,
  ssb_ratio$upr == 66.1,
  is.na(ssb_ratio$se),
  outputs$value[outputs$measure == "natural_mortality_average_parameter"] == 0.043,
  outputs$value[outputs$measure == "q" & outputs$survey == "Sleeping Beauty"] == 0.28,
  outputs$value[outputs$measure == "F_reference_at_SB40"] == 0.033,
  outputs$value[outputs$measure == "Bmsy"] == 30.8,
  outputs$value[outputs$measure == "Fmsy"] == 0.045,
  setequal(catch$scenario, c("F40", "FMSY")),
  setequal(catch$value, c("513", "685")),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"))
)

assumptions <- x$assumptions
stopifnot(
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "Estimated for males and females combined; R1.4 prior Normal(mean=0.045 per year, CV=0.1)",
  assumptions$value[assumptions$setting == "time_steps"] ==
    "Three annual steps: recruitment, fishing, ageing",
  !anyDuplicated(assumptions$setting)
)

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- candidates[candidates$candidate_id == "SIOFA:ORY-2024-01:WSR", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$match_status == "new",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("not catch-at-age", candidate$catch_age_evidence, fixed = TRUE),
  grepl("overlapping area models", candidate$notes, fixed = TRUE)
)

manifest <- read.csv("provenance/siofa_orange_roughy_2025_sources.csv",
  stringsAsFactors = FALSE)
stopifnot(
  nrow(manifest) == 6L,
  all(manifest$assessment_id == assessment_id),
  !anyDuplicated(manifest$sha256),
  any(grepl("WS2025-PAM3-03", manifest$original_filename, fixed = TRUE))
)

cat("SIOFA WSR 2025 source checks passed.\n")
