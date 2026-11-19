read_matching_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stock_id <- "mpi_bluenose_nz"
assessment_id <- "mpi_bluenose_nz_2021"
stock <- read_matching_rows("database/stocks.csv", stock_id)
assessment <- read_matching_rows("database/assessments.csv", assessment_id)
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "BNS",
  stock$scientific_name == "Hyperoglyphe antarctica",
  stock$ocean == "Southwest Pacific",
  grepl("one New Zealand-wide", stock$notes, fixed = TRUE),
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2021L,
  assessment$is_current,
  assessment$is_applied,
  assessment$model_family == "Casal2",
  assessment$inputs_status == "complete",
  assessment$outputs_status == "partial",
  nrow(inputs) == 11235L,
  nrow(assumptions) == 65L,
  nrow(outputs) == 13L
)

input_counts <- table(inputs$measure)
stopifnot(
  input_counts[["catch_biomass"]] == 860L,
  input_counts[["relative_biomass_index"]] == 98L,
  input_counts[["biomass_index_cv"]] == 98L,
  input_counts[["proportion_at_age"]] == 879L,
  input_counts[["proportion_at_length"]] == 117L,
  input_counts[["proportion_at_weight"]] == 8817L,
  input_counts[["growth_length_at_age"]] == 122L,
  input_counts[["weight_at_age"]] == 122L,
  input_counts[["maturity_at_age"]] == 122L
)

catch <- inputs[inputs$measure == "catch_biomass", ]
stopifnot(
  all(catch$type == "catch"),
  all(catch$basis == "biomass"),
  all(catch$unit == "tonnes"),
  identical(sort(unique(as.integer(catch$year))), 1936:2021),
  length(unique(catch$fleet)) == 10L,
  all(vapply(split(catch, catch$fleet), nrow, integer(1L)) == 86L),
  all(vapply(split(catch, catch$fleet), function(x) {
    x$value[x$year == 2020] == x$value[x$year == 2021]
  }, logical(1L)))
)

indices <- inputs[inputs$measure == "relative_biomass_index", ]
index_cv <- inputs[inputs$measure == "biomass_index_cv", ]
stopifnot(
  length(unique(indices$survey)) == 12L,
  all(indices$unit == "standardized CPUE index"),
  all(indices$basis == "index_scale"),
  all(as.numeric(indices$sampling_time) == 0.5),
  setequal(paste(indices$survey, indices$year), paste(index_cv$survey, index_cv$year)),
  all(as.numeric(index_cv$value) > 0)
)

for (measure in c("proportion_at_age", "proportion_at_length", "proportion_at_weight")) {
  x <- inputs[inputs$measure == measure, ]
  sums <- vapply(split(as.numeric(x$value), x$observation_id), sum, numeric(1L))
  stopifnot(all(abs(sums - 1) <= 0.01), all(as.numeric(x$value) >= 0))
}

age <- inputs[inputs$measure == "proportion_at_age", ]
stopifnot(
  length(unique(age$observation_id)) == 15L,
  all(age$basis == "proportion_numbers"),
  all(as.numeric(age$sample_size) > 0),
  min(as.numeric(age$age)) == 3,
  max(as.numeric(age$age)) == 61
)

length_comp <- inputs[inputs$measure == "proportion_at_length", ]
male_length <- length_comp[length_comp$sex == "male", ]
female_length <- length_comp[length_comp$sex == "female", ]
stopifnot(
  length(unique(length_comp$observation_id)) == 6L,
  setequal(sort(unique(as.numeric(male_length$length_bin))), seq(39, 93, by = 3)),
  setequal(sort(unique(as.numeric(female_length$length_bin))), seq(39, 96, by = 3)),
  all(as.numeric(length_comp$sample_size) > 0),
  all(grepl("length_plus = F", length_comp$notes, fixed = TRUE))
)

weight_comp <- inputs[inputs$measure == "proportion_at_weight", ]
missing_sizes <- is.na(as.numeric(weight_comp$sample_size))
stopifnot(
  length(unique(sub("_[0-9]{4}$", "", weight_comp$observation_id))) == 4L,
  all(weight_comp$type == "catch_weight"),
  all(weight_comp$basis == "proportion_numbers"),
  all(weight_comp$unit == "proportion"),
  all(as.numeric(weight_comp$weight_bin) >= 0),
  all(vapply(split(weight_comp, weight_comp$observation_id), function(x) {
    length(unique(x$year)) == 1L && length(unique(x$fleet)) == 1L &&
      length(unique(x$region)) == 1L
  }, logical(1L))),
  sum(missing_sizes) == 190L,
  unique(weight_comp$observation_id[missing_sizes]) ==
    "Observed_weight_frequency_features_northland_2020",
  all(grepl("sample_size is left blank", weight_comp$notes[missing_sizes], fixed = TRUE)),
  all(as.numeric(weight_comp$sample_size[!missing_sizes]) > 0)
)

length_age <- inputs[inputs$measure == "growth_length_at_age", ]
weight_age <- inputs[inputs$measure == "weight_at_age", ]
maturity <- inputs[inputs$measure == "maturity_at_age", ]
stopifnot(
  setequal(unique(length_age$sex), c("male", "female")),
  setequal(unique(weight_age$sex), c("male", "female")),
  setequal(unique(maturity$sex), c("male", "female")),
  all(length_age$unit == "cm"),
  all(weight_age$unit == "tonnes/fish"),
  all(weight_age$basis == "tonnes_per_fish"),
  all(as.numeric(weight_age$value) > 0),
  all(as.numeric(maturity$value) >= 0 & as.numeric(maturity$value) <= 1)
)

stopifnot(
  !anyDuplicated(do.call(paste, c(lapply(
    assumptions[c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting")],
    function(x) { x[is.na(x)] <- ""; as.character(x) }
  ), sep = "\r"))),
  any(assumptions$component == "M" & grepl("M = 0.08", assumptions$value, fixed = TRUE)),
  any(assumptions$component == "parameter" &
    grepl("process[Recruitment].b0", assumptions$notes, fixed = TRUE)),
  any(assumptions$component == "uncertainty" & assumptions$setting == "MCMC_settings"),
  any(outputs$measure == "SSB_ratio_to_B0" & outputs$year == 2021L & outputs$value == 25.3),
  any(outputs$measure == "SSB" & outputs$source_type == "derived_source_output"),
  !any(outputs$measure %in% c("N_at_age", "F_at_age", "recruitment_at_age")),
  all(is.na(outputs$se))
)

cat("New Zealand bluenose source records passed validation.\n")
