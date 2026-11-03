root <- "."
source(file.path(root, "R", "read_database.R"))
assessment_id <- "jrn_afwg_haddock_northeast_arctic_2026"
source_data <- read_assessment(assessment_id, read_database())
inputs <- source_data$inputs
outputs <- source_data$outputs

count <- function(type, measure) {
  sum(inputs$type == type & inputs$measure == measure)
}
one_output <- function(measure, year, age = NA_integer_) {
  x <- outputs[outputs$measure == measure & outputs$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  stopifnot(nrow(x) == 1L)
  x$value[[1L]]
}

numbers <- outputs[outputs$measure == "numbers_at_age", , drop = FALSE]
fishing <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
fixed_m <- outputs[outputs$measure == "natural_mortality_at_age", , drop = FALSE]
q_output <- outputs[outputs$measure == "q", , drop = FALSE]
q_power <- outputs[outputs$measure == "log_q_power", , drop = FALSE]
predicted_catch <- outputs[outputs$measure == "predicted_catch", , drop = FALSE]
predicted_index <- outputs[outputs$measure == "predicted_index", , drop = FALSE]
numeric_column <- function(x, name) suppressWarnings(as.numeric(x[[name]]))
key <- function(x, columns) do.call(paste, c(lapply(x[columns], as.character), sep = "\034"))
catch_input <- inputs[
  inputs$type == "catch" & inputs$measure == "numbers_at_age" &
    inputs$fleet == "Residual catch", , drop = FALSE
]
index_input <- inputs[
  inputs$type == "index" & inputs$measure %in% c("numbers_at_age", "index_by_age_group"),
  , drop = FALSE
]

stopifnot(
  nrow(source_data$stocks) == 1L,
  source_data$stocks$stock_id == "ck_ices_afwg_aeglefinus_nea_1_2",
  source_data$stocks$authority == "JRN-AFWG",
  source_data$stocks$authority_stock_id == "had.27.1-2",
  source_data$assessment$assessment_year == 2026L,
  source_data$assessment$terminal_year == 2026L,
  source_data$assessment$estimate_terminal_year == 2026L,
  source_data$assessment$outputs_status == "complete",
  is.na(source_data$assessment$framework_year),
  source_data$stocks$ocean == "Northeast Atlantic",
  count("catch", "numbers_at_age") == 836L,
  count("catch", "numbers_at_age_for_M_reconstruction") == 836L,
  count("index", "numbers_at_age") == 678L,
  count("index", "index_by_age_group") == 112L,
  count("weight", "weight_at_age") == 847L,
  count("maturity", "maturity_at_age") == 847L,
  count("M", "natural_mortality_at_age") == 847L,
  count("biology", "fraction_F_before_spawning") == 847L,
  count("biology", "fraction_M_before_spawning") == 847L,
  length(unique(inputs$survey[inputs$type == "index"])) == 4L,
  one_output("numbers_at_age", 2025L, 3L) == 494847,
  one_output("recruitment", 2025L) == 494847,
  one_output("SSB", 2025L) == 157942,
  one_output("Fbar", 2025L) == 0.381,
  one_output("total_biomass", 2025L) == 494692,
  one_output("natural_mortality_at_age", 2025L, 7L) == 0.2,
  one_output("natural_mortality_at_age", 2025L, 13L) == 0.2,
  nrow(numbers) == 847L,
  nrow(fishing) == 836L,
  all(is.finite(numeric_column(numbers, "se"))),
  all(is.finite(numeric_column(fishing, "se"))),
  all(numeric_column(numbers, "lwr") < numeric_column(numbers, "value")),
  all(numeric_column(numbers, "value") < numeric_column(numbers, "upr")),
  all(numeric_column(fishing, "lwr") < numeric_column(fishing, "value")),
  all(numeric_column(fishing, "value") < numeric_column(fishing, "upr")),
  all(is.na(numeric_column(fixed_m, "se"))),
  nrow(q_output) == 28L,
  all(is.finite(numeric_column(q_output, "se"))),
  sum(!is.na(q_output$age_group) & nzchar(q_output$age_group)) == 4L,
  nrow(q_power) == 6L,
  all(is.finite(numeric_column(q_power, "se"))),
  nrow(predicted_catch) == 836L,
  nrow(predicted_index) == 790L,
  all(is.finite(numeric_column(predicted_catch, "value"))),
  all(is.finite(numeric_column(predicted_index, "value"))),
  setequal(key(predicted_catch, c("year", "age")), key(catch_input, c("year", "age"))),
  setequal(key(predicted_index, c("survey", "year", "age")), key(index_input, c("survey", "year", "age")))
)

cat("JRN-AFWG Northeast Arctic haddock source records passed.\n")
