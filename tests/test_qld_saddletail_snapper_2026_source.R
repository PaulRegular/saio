source("R/read_database.R")
x <- read_assessment("qld_saddletail_snapper_east_coast_2026")

a <- x$assessment
o <- x$outputs
m <- x$assumptions[x$assumptions$component == "M", ]
steepness <- x$assumptions[x$assumptions$component == "recruitment", ]

stopifnot(
  x$stocks$scientific_name == "Lutjanus malabaricus",
  x$stocks$ocean == "Southwest Pacific",
  a$assessment_year == 2026,
  a$terminal_year == 2025,
  a$estimate_terminal_year == 2026,
  a$model_family == "Stock Synthesis",
  a$model_version == "3.30.23.2",
  a$is_current,
  a$is_applied,
  all(a[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x$inputs) == 0L,
  setequal(m$value, c("0.11 yr^-1", "0.14 yr^-1")),
  !anyDuplicated(m$setting),
  setequal(steepness$value, c("0.65", "0.75", "0.85")),
  !anyDuplicated(steepness$setting),
  nrow(o) == 2L,
  setequal(o$type, c("biomass", "mortality")),
  all(o$source_type == "official_table"),
  all(is.na(o$se)),
  all(grepl("95% credible interval", o$notes, fixed = TRUE)),
  o$value[o$measure == "spawning_biomass_ratio"] == 28,
  o$lwr[o$measure == "spawning_biomass_ratio"] == 19,
  o$upr[o$measure == "spawning_biomass_ratio"] == 42,
  o$year[o$measure == "spawning_biomass_ratio"] == 2026,
  o$value[o$measure == "fishing_pressure_ratio"] == 3.85,
  o$lwr[o$measure == "fishing_pressure_ratio"] == 2.48,
  o$upr[o$measure == "fishing_pressure_ratio"] == 5.84,
  o$year[o$measure == "fishing_pressure_ratio"] == 2025,
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age")),
  all(grepl("Table 3.2", o$source_reference, fixed = TRUE))
)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE)
candidate <- candidate[candidate$candidate_id == "QDAF:QLD_EC_SADDLETAIL_2026", ]
stopifnot(
  nrow(candidate) == 1L,
  candidate$organization == "Queensland DPI",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("conditional age-at-length", candidate$catch_age_evidence, fixed = TRUE)
)

cat("Queensland saddletail snapper 2026 partial-source checks passed.\n")
