read_table <- function(name) {
  read.csv(file.path("database", paste0(name, ".csv")),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stock <- subset(read_table("stocks"), stock_id == "mpi_snapper_sna8")
assessment <- subset(read_table("assessments"),
  assessment_id == "mpi_snapper_sna8_2024")
assumptions <- subset(read_table("assumptions"),
  assessment_id == "mpi_snapper_sna8_2024")
inputs <- subset(read_table("inputs"), assessment_id == "mpi_snapper_sna8_2024")
outputs <- subset(read_table("outputs"), assessment_id == "mpi_snapper_sna8_2024")

catch <- subset(inputs, type == "catch" & measure == "total_biomass")
cpue <- subset(inputs, type == "index" & measure == "relative_biomass_index")
survey <- subset(inputs, type == "index" & measure == "numbers_at_age")
age_comp <- subset(inputs, type == "catch" & measure == "proportion_at_age")
age_cv <- subset(inputs, type == "catch" & measure == "relative_standard_error")
weight <- subset(inputs, type == "weight" & measure == "weight_at_age")
weight_cv <- subset(inputs, type == "weight" & measure == "relative_standard_error")

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Chrysophrys auratus",
  stock$common_name == "Snapper",
  stock$area == "SNA 8, west coast of New Zealand North Island",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2024L,
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.22.00",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 17L,
  any(assumptions$setting == "natural_mortality" & assumptions$value == "0.075 per year; fixed"),
  nrow(catch) == 470L,
  identical(sort(unique(as.integer(catch$year))), 1931:2024),
  length(unique(catch$fleet)) == 5L,
  all(catch$unit == "tonnes"),
  catch$value[catch$fleet == "Single trawl (BT)" & catch$year == 2024] == 1760,
  nrow(cpue) == 27L,
  identical(sort(as.integer(cpue$year)), 1997:2023),
  grepl("0.669-0.877", cpue$notes[cpue$year == 1997], fixed = TRUE),
  nrow(survey) == 36L,
  identical(sort(unique(as.integer(survey$year))),
    c(1990L, 1992L, 1995L, 1997L, 2000L, 2019L, 2020L, 2021L, 2023L)),
  identical(sort(unique(as.integer(survey$age))), 2:5),
  survey$value[survey$year == 1990 & survey$age == 2] == 50.1,
  all(survey$unit == "thousands of fish"),
  nrow(age_comp) == 30L,
  identical(sort(as.integer(age_comp$age)), 1:30),
  abs(sum(age_comp$value) - 1) < 1e-10,
  age_comp$value[age_comp$age == 30] == 0.0014,
  age_comp$sample_size[age_comp$age == 2] == 12,
  nrow(age_cv) == 30L,
  age_cv$value[age_cv$age == 2] == 0.41,
  nrow(weight) == 28L,
  weight$value[weight$age == 2] == 0.39,
  weight$value[weight$age == 30] == 5.34,
  all(weight$unit == "kg/fish"),
  nrow(weight_cv) == 28L,
  weight_cv$value[weight_cv$age == 30] == 0.17,
  nrow(outputs) == 5L,
  outputs$value[outputs$measure == "spawning_biomass"] == 49830,
  outputs$lwr[outputs$measure == "spawning_biomass"] == 39807,
  outputs$upr[outputs$measure == "spawning_biomass"] == 62665,
  outputs$value[outputs$measure == "fishing_mortality_ratio_to_target"] == 0.999,
  is.na(outputs$se[outputs$measure == "spawning_biomass"])
)

cat("SNA 8 source coverage and reported values checks passed.\n")
