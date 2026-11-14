source("R/read_database.R")

x <- read_assessment("mpi_orh3b_2025")
i <- x$inputs
o <- x$outputs
catch <- subset(i, type == "catch" & measure == "total_biomass")
composition <- subset(i, type == "catch" & measure == "proportion_at_age")
index <- subset(i, type == "index" & measure == "total_biomass")
cv <- subset(i, type == "index" & measure == "biomass_index_cv")

stopifnot(
  x$stocks$stock_id == "mpi_orh3b_chatham_rise",
  x$stocks$authority == "Fisheries New Zealand",
  x$stocks$authority_stock_id == "ORH 3B",
  x$stocks$scientific_name == "Hoplostethus atlanticus",
  x$stocks$ocean == "Southwest Pacific",
  x$assessment$assessment_year == 2025L,
  x$assessment$terminal_year == 2024L,
  x$assessment$estimate_terminal_year == 2025L,
  x$assessment$model_family == "CASAL2",
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$inputs_status == "complete",
  x$assessment$assumptions_status == "partial",
  x$assessment$outputs_status == "partial",
  nrow(i) == 1690L,
  nrow(catch) == 328L,
  setequal(unique(catch$region), c("ESCR", "NWCR")),
  setequal(unique(catch$fleet[catch$region == "ESCR"]),
    c("boxflat", "hills", "andes", "south", "crack", "rekohu")),
  setequal(unique(catch$year[catch$region == "ESCR"]), 1979:2025),
  setequal(unique(catch$year[catch$region == "NWCR"]), 1980:2025),
  all(catch$unit == "tonnes"),
  all(catch$year_basis == "model_year"),
  all(catch$source_type == "native_model"),
  nrow(composition) == 1310L,
  setequal(unique(composition$age[composition$fleet == "AFplumes84_24"]), 18:100),
  setequal(unique(composition$age[composition$fleet == "AFrekohu12_24"]), 20:100),
  setequal(unique(composition$age[composition$fleet == "AFcrack13_24"]), 20:100),
  setequal(unique(composition$year[composition$fleet == "AFplumes84_24"]),
    c(1984, 2003, 2012, 2013, 2016, 2022, 2024)),
  setequal(unique(composition$year[composition$fleet == "AFrekohu12_24"]),
    c(2012, 2013, 2016, 2022, 2024)),
  setequal(unique(composition$year[composition$fleet == "AFcrack13_24"]),
    c(2013, 2016, 2022, 2024)),
  all(composition$basis == "proportion_numbers"),
  all(composition$unit == "proportion"),
  all(composition$sampling_time == 0.75),
  all(grepl("not catch numbers-at-age", composition$notes, fixed = TRUE)),
  all(grepl("not renormalization", composition$notes, fixed = TRUE) |
    grepl("without renormalization", composition$notes, fixed = TRUE)),
  nrow(index) == 26L,
  nrow(cv) == 26L,
  setequal(unique(index$survey), c(
    "ESCR Old Spawning Plume acoustic 38 kHz",
    "ESCR combined acoustic 38 kHz",
    "ESCR combined acoustic 120 kHz",
    "NWCR acoustic 38 kHz", "NWCR acoustic 120 kHz"
  )),
  all(index$unit == "tonnes"),
  all(index$sampling_time == 0.75),
  all(cv$basis == "relative_scale"),
  all(cv$unit == "ratio"),
  any(index$survey == "ESCR Old Spawning Plume acoustic 38 kHz" &
    index$year == 2002 & index$value == 63950),
  any(index$survey == "ESCR combined acoustic 38 kHz" &
    index$year == 2024 & index$value == 41375),
  any(index$survey == "ESCR combined acoustic 120 kHz" &
    index$year == 2024 & index$value == 22723),
  any(index$survey == "NWCR acoustic 38 kHz" &
    index$year == 2021 & index$value == 16332),
  any(index$survey == "NWCR acoustic 120 kHz" &
    index$year == 2022 & index$value == 13680)
)

composition_groups <- split(composition, composition$observation_id)
stopifnot(
  length(composition_groups) == 16L,
  all(vapply(composition_groups, nrow, integer(1)) %in% c(81L, 83L)),
  all(vapply(composition_groups, function(z) {
    abs(sum(as.numeric(z$value)) - 1) < 0.05
  }, logical(1))),
  unique(composition$sample_size[
    composition$fleet == "AFplumes84_24" & composition$year == 2003
  ]) == 2,
  all(unique(composition$sample_size[
    !(composition$fleet == "AFplumes84_24" & composition$year == 2003)
  ]) == 10)
)

for (region in c("ESCR", "NWCR")) {
  z <- catch[catch$region == region, ]
  last <- z[z$year == 2025, c("fleet", "value")]
  prior <- z[z$year == 2024, c("fleet", "value")]
  last <- last[order(last$fleet), ]
  prior <- prior[order(prior$fleet), ]
  stopifnot(identical(last$fleet, prior$fleet), identical(last$value, prior$value))
  stopifnot(all(grepl("not an observed 2025 catch", z$notes[z$year == 2025], fixed = TRUE)))
}

assumptions <- x$assumptions
stopifnot(
  any(assumptions$setting == "natural_mortality" & assumptions$region == "ESCR" &
    grepl("Fixed M=0.045", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "natural_mortality" & assumptions$region == "NWCR" &
    grepl("CV 0.333", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "acoustic_process_error" & assumptions$region == "ESCR" &
    grepl("combined 120 kHz=0.25", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "ageing_error" & grepl("CV=0.1", assumptions$value, fixed = TRUE)),
  any(assumptions$setting == "censored_probability" &
    grepl("<1%", assumptions$value, fixed = TRUE))
)

stopifnot(
  nrow(o) == 35L,
  setequal(unique(o$scenario[o$region == "ESCR" & o$measure != "mean_recruitment"]), c(
    "ESCR Acoustic 38", "ESCR Acoustic 120",
    "ESCR Acoustic 38 + AF", "ESCR Acoustic 120 + AF"
  )),
  setequal(unique(o$scenario[o$region == "NWCR"]),
    c("NWCR Acoustic 38", "NWCR Acoustic 120")),
  nrow(subset(o, measure == "mean_recruitment")) == 8L,
  nrow(subset(o, measure == "spawning_biomass" & year == 2025)) == 6L,
  nrow(subset(o, measure == "SSB_ratio_to_B0" & year == 2025)) == 6L,
  nrow(subset(o, measure == "probability_below_20_percent_B0")) == 4L,
  nrow(subset(o, measure == "probability_below_10_percent_B0")) == 3L,
  nrow(subset(o, measure == "probability_above_30_percent_B0")) == 2L,
  !any(o$measure == "probability_below_10_percent_B0" &
    o$scenario == "ESCR Acoustic 38 + AF"),
  all(is.na(o$se)),
  subset(o, measure == "spawning_biomass" &
    scenario == "ESCR Acoustic 38")$value == 52.0,
  subset(o, measure == "spawning_biomass" &
    scenario == "ESCR Acoustic 38")$lwr == 36.1,
  subset(o, measure == "SSB_ratio_to_B0" &
    scenario == "NWCR Acoustic 120")$value == 34,
  subset(o, measure == "mean_recruitment" &
    grepl("Acoustic 120 R1", scenario, fixed = TRUE))$value == 7.9,
  !any(o$measure %in% c("numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age"))
)

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  colClasses = "character", check.names = FALSE)
candidate <- subset(candidates, candidate_id == "MPI:ORH3B")
manifest <- read.csv("provenance/mpi_orh3b_2025_sources.csv", stringsAsFactors = FALSE)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_orh3b_chatham_rise",
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 4L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(manifest$retrieved_on == "2026-11-06")
)

cat("ORH 3B 2025 source checks passed.\n")
