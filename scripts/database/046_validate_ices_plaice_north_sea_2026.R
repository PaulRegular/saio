root <- file.path("database")
assessment_id <- "ices_plaice_north_sea_2026"
read_table <- function(name) {
  read.csv(file.path(root, name),
    stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE
  )
}
inputs <- read_table("inputs.csv")
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- read_table("outputs.csv")
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]

stopifnot(
  nrow(inputs[inputs$type == "catch", ]) == 690L,
  nrow(inputs[inputs$type == "weight", ]) == 690L,
  nrow(inputs[inputs$type == "M", ]) == 10L,
  nrow(inputs[inputs$type == "maturity", ]) == 10L,
  all(is.finite(inputs$value)), all(is.finite(outputs$value))
)

indices <- inputs[inputs$type == "index", , drop = FALSE]
expected_index_rows <- c(
  "BTS-Isis" = 88L, "BTS-IBTS Q3" = 300L,
  SNS1 = 180L, SNS2 = 150L, "IBTS Q1" = 152L
)
index_counts <- table(factor(indices$survey,
  levels = names(expected_index_rows)
))
stopifnot(
  identical(
    as.integer(index_counts),
    as.integer(expected_index_rows)
  ),
  !any(indices$survey == "SNS2" & indices$year == 2003),
  all(indices$sampling_time[indices$survey == "IBTS Q1"] == .125),
  all(indices$sampling_time[indices$survey != "IBTS Q1"] == .75)
)

get_output <- function(type, measure, year, age = NA_integer_) {
  x <- outputs[outputs$type == type & outputs$measure == measure &
    outputs$year == year, , drop = FALSE]
  if (!is.na(age)) x <- x[x$age == age, , drop = FALSE]
  x$value
}
stopifnot(
  identical(
    get_output("population", "numbers_at_age", 1957L, 1L),
    1773664
  ),
  identical(
    get_output("mortality", "fishing_mortality_at_age", 1957L, 1L),
    .027
  ),
  identical(
    get_output("recruitment", "recruitment", 2026L),
    4883772
  ),
  length(get_output("mortality", "Fbar", 2026L)) == 0L
)

historical <- outputs[
  outputs$year <= 2025 &
    outputs$measure %in% c("recruitment", "SSB", "Fbar"), ,
  drop = FALSE
]
stopifnot(all(is.finite(historical$lwr)), all(is.finite(historical$upr)))

cat("North Sea plaice input and output records validated.\n")
