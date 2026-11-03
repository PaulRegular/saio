source("R/read_database.R")

database <- read_database()
vpa <- read_assessment("nefsc_winter_flounder_gb_2022_vpa", database)
wham <- read_assessment("nefsc_winter_flounder_gb_2025_wham", database)

vpa_inputs <- vpa$inputs
vpa_index <- vpa_inputs[vpa_inputs$type == "index", , drop = FALSE]
vpa_outputs <- vpa$outputs
wham_inputs <- subset(wham$inputs, source_type == "official_table")

stopifnot(
  nrow(vpa$stocks) == 1L,
  vpa$stocks$common_name == "Winter flounder",
  vpa$stocks$area == "Georges Bank (NAFO 5Z)",
  vpa$stocks$ocean == "Northwest Atlantic",
  vpa$assessment$is_current,
  !wham$assessment$is_current,
  wham$assessment$is_applied,
  vpa$assessment$terminal_year == 2021L,
  wham$assessment$terminal_year == 2024L,
  nrow(vpa_inputs[vpa_inputs$measure == "numbers_at_age" & vpa_inputs$type == "catch", ]) == 280L,
  nrow(vpa_inputs[vpa_inputs$measure == "weight_at_age" & vpa_inputs$type == "catch_weight", ]) == 280L,
  nrow(vpa_inputs[vpa_inputs$measure == "weight_at_age" & vpa_inputs$type == "weight", ]) == 280L,
  nrow(vpa_inputs[vpa_inputs$measure == "natural_mortality_at_age" & vpa_inputs$type == "M", ]) == 7L,
  nrow(vpa_inputs[vpa_inputs$measure == "maturity_at_age" & vpa_inputs$type == "maturity", ]) == 280L,
  nrow(vpa_index) == 840L,
  identical(as.integer(sort(unique(vpa_index$year))), 1982:2021),
  identical(as.integer(sort(unique(vpa_index$age))), 1:7),
  sum(vpa_index$value == 0) == 99L,
  all(vpa_index$sampling_time == 0),
  all(vpa_index$unit == "native survey index units"),
  all(vpa_index$weight == 1),
  !any(vpa_outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age")),
  any(vpa$assumptions$setting == "MFSPAWN"),
  nrow(wham_inputs[wham_inputs$measure == "total_biomass", ]) == 10L,
  identical(as.integer(sort(unique(wham_inputs$year))), 2015:2024),
  !any(wham_inputs$measure == "numbers_at_age")
)

cat("Georges Bank winter flounder source checks passed.\n")
