root <- "."
assessment_id <- "noaa_south_atlantic_spanish_mackerel_2022"
stock_id <- "noaa_south_atlantic_spanish_mackerel"
candidate_id <- "NOAA:10174"

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stocks <- read_csv("database/stocks.csv")
assessments <- read_csv("database/assessments.csv")
assumptions <- read_csv("database/assumptions.csv")
inputs <- read_csv("database/inputs.csv")
outputs <- read_csv("database/outputs.csv")
candidates <- read_csv("discovery/candidates.csv")

s <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
a <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
i <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
o <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]
h <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
c <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]

stopifnot(
  nrow(s) == 1L,
  s$scientific_name == "Scomberomorus maculatus",
  s$ocean == "Northwest Atlantic",
  nrow(a) == 1L,
  a$assessment_year == 2022L,
  a$terminal_year == 2020L,
  a$estimate_terminal_year == 2021L,
  a$inputs_status == "partial",
  a$outputs_status == "partial",
  nrow(c) == 1L,
  c$matched_stock_id == stock_id,
  c$match_status == "matched",
  c$import_status == "partial",
  nrow(h) == 15L,
  nrow(i) == 1426L,
  nrow(o) == 4484L
)

compositions <- i[i$measure == "proportion_at_age", , drop = FALSE]
composition_samples <- i[i$measure == "composition_sample_count", , drop = FALSE]
stopifnot(
  sum(i$measure == "landings_biomass") == 131L,
  sum(i$measure == "landings_numbers") == 35L,
  sum(i$measure == "discard_numbers") == 70L,
  nrow(compositions) == 825L,
  nrow(composition_samples) == 75L,
  identical(sort(unique(as.integer(compositions$age))), 0:10),
  max(abs(aggregate(value ~ observation_id, compositions, sum)$value - 1)) < 0.001
)

hline <- compositions[compositions$observation_id ==
  "SEDAR78_Table4_cH_pooled_midpoint_2007" & compositions$age == 0, , drop = FALSE]
stopifnot(
  nrow(hline) == 1L,
  is.na(hline$year),
  hline$value == 0.0181,
  hline$sample_size == 2953L,
  hline$source_reference == "SEDAR 78 SAR, Table 4, printed p. 39"
)

idx <- i[i$type == "index" & i$measure %in%
  c("relative_biomass_index", "relative_abundance_index", "recruitment_index"), , drop = FALSE]
stopifnot(
  sum(idx$measure == "relative_biomass_index") == 35L,
  sum(idx$measure == "relative_abundance_index") == 35L,
  sum(idx$measure == "recruitment_index") == 31L,
  sum(i$measure == "biomass_index_cv") == 35L,
  sum(i$measure == "abundance_index_cv") == 35L,
  sum(i$measure == "recruitment_index_cv") == 31L,
  i$value[i$measure == "natural_mortality_at_age" & i$age == 0] == 0.68,
  i$value[i$measure == "natural_mortality_at_age" & i$age == 10] == 0.34,
  i$value[i$measure == "weight_at_age" & i$age == 0 & is.na(i$sex) &
    is.na(i$fleet)] == 0.38,
  i$value[i$measure == "maturity_at_age" & i$age == 1] == 0.94
)

stopifnot(
  sum(o$measure == "numbers_at_age") == 396L,
  sum(o$measure == "biomass_at_age") == 396L,
  sum(o$measure == "total_numbers") == 36L,
  sum(o$measure == "total_biomass_from_age_surface") == 36L,
  sum(o$measure == "fishing_mortality_at_age") == 385L,
  sum(o$measure == "total_mortality_at_age") == 385L,
  sum(o$measure == "landings_numbers_at_age") == 385L,
  sum(o$measure == "discard_numbers_at_age") == 385L,
  !any(i$measure %in% c("landings_numbers_at_age", "discard_numbers_at_age"))
)

n_2021 <- o[o$measure == "numbers_at_age" & o$year == 2021 & o$age == 0, , drop = FALSE]
total_2021 <- o[o$measure == "total_numbers" & o$year == 2021, , drop = FALSE]
stopifnot(
  nrow(n_2021) == 1L,
  n_2021$value == 23015.23,
  n_2021$scenario == "Interim 2021",
  nrow(total_2021) == 1L,
  total_2021$value == 37844.45,
  total_2021$scenario == "Interim 2021"
)

fmsy <- o[o$measure == "Fmsy", , drop = FALSE]
stopifnot(
  nrow(fmsy) == 2L,
  setequal(fmsy$scenario, c("Base-run estimate", "MCBE median")),
  fmsy$value[fmsy$scenario == "Base-run estimate"] == 0.516,
  fmsy$value[fmsy$scenario == "MCBE median"] == 0.523,
  fmsy$se[fmsy$scenario == "MCBE median"] == 0.111,
  all(grepl("Table 22", fmsy$source_reference))
)

stopifnot(
  all(nzchar(i$source_reference)),
  all(nzchar(o$source_reference)),
  all(grepl("SEDAR 78 SAR", i$source_reference)),
  all(grepl("SEDAR 78 SAR", o$source_reference)),
  any(grepl("commercial discard estimates", h$value, ignore.case = TRUE)),
  any(grepl("survey samples in spring, summer, and fall", h$notes, ignore.case = TRUE))
)

cat("NOAA South Atlantic Spanish mackerel source records validated.\n")