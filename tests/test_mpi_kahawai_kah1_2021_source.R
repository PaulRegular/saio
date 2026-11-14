source("R/read_database.R")

assessment_id <- "mpi_kahawai_kah1_2021"
x <- read_assessment(assessment_id)
inputs <- x$inputs
catch <- inputs[inputs$measure == "landings_biomass", , drop = FALSE]
compositions <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
indices <- inputs[inputs$measure %in% c(
  "relative_abundance_index", "relative_biomass_index"
), , drop = FALSE]
index_cv <- inputs[inputs$measure %in% c(
  "abundance_index_cv", "biomass_index_cv"
), , drop = FALSE]

stopifnot(
  x$stocks$stock_id == "mpi_kahawai_kah1",
  x$stocks$authority == "Fisheries New Zealand",
  x$stocks$authority_stock_id == "KAH 1",
  x$stocks$ocean == "Southwest Pacific",
  x$assessment$assessment_year == 2021,
  x$assessment$terminal_year == 2020,
  x$assessment$estimate_terminal_year == 2020,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$inputs_status == "complete",
  x$assessment$assumptions_status == "partial",
  x$assessment$outputs_status == "partial",
  nrow(catch) == 819L,
  nrow(compositions) == 975L,
  nrow(indices) == 77L,
  nrow(index_cv) == 77L,
  nrow(inputs) == 1948L,
  setequal(unique(catch$fleet), c(
    "PS", "ST", "SN", "OTHER", "REC_EN", "REC_HG_pre90s",
    "REC_HG_early", "REC_HG_late", "REC_BP"
  )),
  all(catch$year_basis == "model_year"),
  all(catch$unit == "tonnes"),
  all(compositions$basis == "proportion_numbers"),
  all(compositions$unit == "proportion"),
  all(!is.na(compositions$sample_size)),
  !any(inputs$measure == "numbers_at_age"),
  setequal(unique(indices$survey), c(
    "REC_CPUE_EN", "REC_CPUE_HG_early", "REC_CPUE_BP", "BP_SPUE"
  )),
  all(indices$sampling_time == "0.5"),
  all(index_cv$basis == "relative_scale"),
  all(index_cv$unit == "ratio")
)

observations <- unique(compositions[c(
  "fleet", "year", "observation_id", "sample_size"
)])
stopifnot(
  nrow(observations) == 50L,
  all(as.numeric(observations$sample_size) > 0),
  setequal(unique(compositions$age[compositions$fleet == "PS"]), as.character(2:20)),
  setequal(unique(compositions$age[compositions$fleet == "ST"]), as.character(4:20)),
  any(grepl("plus_group=TRUE", compositions$notes, fixed = TRUE)),
  any(grepl("plus_group=FALSE", compositions$notes, fixed = TRUE))
)

rounded <- compositions[
  compositions$fleet == "REC_EN" & compositions$year == "2012", ,
  drop = FALSE
]
stopifnot(
  abs(sum(as.numeric(rounded$value)) - 0.9666) < 1e-8,
  any(grepl("not renormalized", rounded$notes, fixed = TRUE))
)

spue <- indices[indices$survey == "BP_SPUE", , drop = FALSE]
spue_cv <- index_cv[index_cv$survey == "BP_SPUE", , drop = FALSE]
cpue_en <- indices[indices$survey == "REC_CPUE_EN", , drop = FALSE]
stopifnot(
  nrow(spue) == 22L,
  nrow(spue_cv) == 22L,
  all(spue$measure == "relative_biomass_index"),
  all(spue_cv$measure == "biomass_index_cv"),
  all(as.numeric(spue_cv$value) == 0.421),
  nrow(cpue_en) == 22L,
  any(cpue_en$year == "2020" & abs(as.numeric(cpue_en$value) - 0.548701268) < 1e-9),
  all(as.numeric(index_cv$value[index_cv$survey == "REC_CPUE_EN"]) == 0.34)
)

assumptions <- x$assumptions
stopifnot(
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "Fixed M=0.22 per year in the base model; sensitivity models use 0.20 and 0.24",
  assumptions$value[assumptions$setting == "maturity_at_age"] ==
    "Fixed knife-edge maturity at age 4",
  grepl("different numerical a coefficients", assumptions$notes[
    assumptions$setting == "length_weight"
  ], fixed = TRUE),
  assumptions$value[assumptions$setting == "age_composition_likelihood"] ==
    "Multinomial sampled age compositions; effective sample sizes supplied by year and fleet after down-weighting"
)

outputs <- x$outputs
base <- outputs[outputs$scenario == "base; fixed M=0.22", , drop = FALSE]
ssb2020 <- base[base$measure == "spawning_biomass", , drop = FALSE]
ratio <- base[base$measure == "SSB_ratio_to_B0", , drop = FALSE]
stopifnot(
  nrow(outputs) == 15L,
  setequal(unique(outputs$scenario), c(
    "fixed M=0.20", "base; fixed M=0.22", "fixed M=0.24"
  )),
  ssb2020$value == "20880",
  ssb2020$lwr == "17050",
  ssb2020$upr == "26796",
  is.na(ssb2020$se),
  ratio$value == "0.556",
  ratio$lwr == "0.499",
  abs(as.numeric(ratio$upr) - 0.620) < 1e-12,
  !any(outputs$measure %in% c(
    "numbers_at_age", "fishing_mortality_at_age",
    "natural_mortality_at_age", "recruitment"
  ))
)

candidates <- read.csv("discovery/candidates.csv",
  stringsAsFactors = FALSE, colClasses = "character",
  check.names = FALSE
)
candidate <- candidates[candidates$candidate_id == "MPI:KAH1", , drop = FALSE]
manifest <- read.csv("provenance/mpi_kahawai_kah1_2021_sources.csv",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(candidate) == 1L,
  candidate$matched_stock_id == "mpi_kahawai_kah1",
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 2L,
  manifest$sha256[match("source_cache/mpi_kahawai_kah1_2021/FAR2022-54.pdf", manifest$local_file)] == "D3A6DC8BB710AC13CD520BB7D188A15850302C9EB334DA3AC59C0F575EE02DEA",
  manifest$sha256[match("source_cache/mpi_kahawai_kah1_2021/Fisheries-Assessment-Plenary-May-2026-Volume-2.pdf", manifest$local_file)] == "FF026E1C2C1CCB69FEF35F1ACEE60BFC4766D8DDCDA98C1DC02FA5C97681E128"
)

cat("KAH 1 2021 source checks passed.\n")
