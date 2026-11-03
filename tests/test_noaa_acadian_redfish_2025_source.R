root <- "."
source_paths <- c(list.files("database", pattern = "[.]csv$", full.names = TRUE),
  list.files("discovery", pattern = "[.]csv$", full.names = TRUE))
source_hashes <- tools::md5sum(source_paths)
import_env <- new.env(parent = globalenv())
import_env$commandArgs <- function(trailingOnly = FALSE) {
  if (trailingOnly) "--dry-run" else base::commandArgs(trailingOnly = FALSE)
}
source(file.path(root, "scripts", "database", "551_import_noaa_acadian_redfish_2025.R"),
  local = import_env
)

x <- import_env$input_data
y <- import_env$outputs
a <- import_env$assumptions
assessment_id <- "noaa_acadian_redfish_gom_gb_2025"
stock_id <- "noaa_acadian_redfish_gom_gb"

input <- function(type, measure, survey = NULL) {
  out <- x[x$type == type & x$measure == measure, , drop = FALSE]
  if (!is.null(survey)) out <- out[out$survey == survey, , drop = FALSE]
  out
}
output <- function(measure) y[y$measure == measure, , drop = FALSE]
assumption <- function(setting) a[a$setting == setting, , drop = FALSE]

stopifnot(
  nrow(import_env$stock) == 1L,
  import_env$stock$stock_id == stock_id,
  import_env$stock$authority_stock_id == "10455",
  import_env$stock$scientific_name == "Sebastes fasciatus",
  import_env$stock$ocean == "Northwest Atlantic",
  import_env$assessment$assessment_year == 2025L,
  import_env$assessment$terminal_year == 2024L,
  import_env$assessment$estimate_terminal_year == 2028L,
  import_env$assessment$is_current == "TRUE",
  import_env$assessment$is_applied == "TRUE",
  import_env$assessment$assumptions_status == "partial",
  import_env$assessment$inputs_status == "complete",
  import_env$assessment$outputs_status == "partial",
  nrow(x) == 2972L,
  nrow(a) == 24L,
  nrow(y) == 3414L
)

catch_total <- input("catch", "total_biomass")
catch_cv <- input("catch", "relative_standard_error")
catch_age <- input("catch", "proportion_at_age")
fall_index <- input("index", "total_numbers", "NEFSC fall survey")
spring_index <- input("index", "total_numbers", "NEFSC spring survey")
fall_age <- input("index", "proportion_at_age", "NEFSC fall survey")
spring_age <- input("index", "proportion_at_age", "NEFSC spring survey")
stopifnot(
  nrow(catch_total) == 62L,
  identical(as.integer(sort(unique(catch_total$year))), 1963:2024),
  all(catch_total$unit == "metric tons"),
  identical(as.numeric(catch_total$value), import_env$catch[, 27L]),
  nrow(catch_cv) == 62L,
  nrow(catch_age) == 26L * sum(import_env$catch_neff > 0),
  identical(catch_age$year %in% 1963:2024, rep(TRUE, nrow(catch_age))),
  identical(as.integer(sort(unique(catch_age$year))),
    (1963:2024)[import_env$catch_neff > 0]),
  identical(sort(unique(as.integer(catch_age$age))), 1:26),
  all(catch_age$sample_size > 0),
  all(catch_age$sample_size == import_env$catch_neff[
    match(catch_age$year, import_env$years)]),
  all(catch_age$value == import_env$catch[
    cbind(as.integer(match(catch_age$year, import_env$years)),
      as.integer(catch_age$age))]),
  all(vapply(split(catch_age$sample_size, catch_age$year),
    function(z) length(unique(z)) == 1L, logical(1L))),
  nrow(fall_index) == 62L,
  nrow(spring_index) == 62L,
  sum(is.na(fall_index$value)) == sum(import_env$indices[[1L]]$index == -1),
  sum(is.na(spring_index$value)) == sum(import_env$indices[[2L]]$index == -1),
  all(fall_index$basis == "index_scale"),
  all(spring_index$basis == "index_scale"),
  all(abs(as.numeric(fall_index$sampling_time) - (10.5 - 1) / 12) < 1e-12),
  all(abs(as.numeric(spring_index$sampling_time) - (4.5 - 1) / 12) < 1e-12),
  nrow(fall_age) == 26L * sum(import_env$indices[[1L]]$neff > 0),
  nrow(spring_age) == 26L * sum(import_env$indices[[2L]]$neff > 0),
  identical(as.integer(sort(unique(fall_age$year))),
    (1963:2024)[import_env$indices[[1L]]$neff > 0]),
  identical(as.integer(sort(unique(spring_age$year))),
    (1963:2024)[import_env$indices[[2L]]$neff > 0]),
  all(fall_age$sample_size > 0),
  all(spring_age$sample_size > 0),
  all(fall_age$sample_size == import_env$indices[[1L]]$neff[
    match(fall_age$year, import_env$years)]),
  all(spring_age$sample_size == import_env$indices[[2L]]$neff[
    match(spring_age$year, import_env$years)]),
  all(fall_age$value == import_env$indices[[1L]]$composition[
    cbind(as.integer(match(fall_age$year, import_env$years)),
      as.integer(fall_age$age))]),
  all(spring_age$value == import_env$indices[[2L]]$composition[
    cbind(as.integer(match(spring_age$year, import_env$years)),
      as.integer(spring_age$age))]),
  all(grepl("raw fish counts are not supplied", catch_age$notes, fixed = TRUE)),
  !any(x$measure == "composition_sample_count")
)

m <- input("M", "natural_mortality_at_age")
maturity <- input("maturity", "maturity_at_age")
catch_weight <- input("catch_weight", "catch_weight_at_age")
spawn_weight <- input("weight", "spawning_weight_at_age")
start_weight <- input("weight", "start_weight_at_age")
stopifnot(
  nrow(m) == 26L,
  all(m$value == 0.05),
  all(is.na(m$year) | !nzchar(m$year)),
  nrow(maturity) == 26L,
  nrow(catch_weight) == 26L,
  nrow(spawn_weight) == 26L,
  nrow(start_weight) == 26L,
  assumption("spawning_fraction_of_year")$value == "0.4",
  assumption("index_weight_pointers")$value == "Weight Matrix 3 for both surveys"
)

n_at_age <- output("numbers_at_age")
f_at_age <- output("fishing_mortality_at_age")
total_n <- output("total_numbers")
recruitment <- output("recruitment")
ssb <- output("SSB")
q <- output("q")
mean_rec <- output("mean_recruitment")
rho <- output("recruitment_ar1_rho")
stopifnot(
  nrow(n_at_age) == 62L * 26L,
  nrow(f_at_age) == 62L * 26L,
  identical(as.integer(sort(unique(n_at_age$year))), 1963:2024),
  identical(as.integer(sort(unique(f_at_age$year))), 1963:2024),
  all(n_at_age$unit == "thousand fish"),
  all(f_at_age$unit == "yr-1"),
  all(n_at_age$source_type == "official_machine_readable"),
  all(f_at_age$source_type == "official_machine_readable"),
  nrow(total_n) == 62L,
  nrow(recruitment) == 62L,
  all(recruitment$age == 1L),
  nrow(ssb) == 62L,
  all(total_n$source_type == "derived_source_output"),
  all(recruitment$source_type == "derived_source_output"),
  all(ssb$source_type == "derived_source_output"),
  all(vapply(list(total_n$se, recruitment$se, ssb$se), function(z) {
    all(is.na(z) | !nzchar(z))
  }, logical(1L))),
  nrow(q) == 2L,
  nrow(mean_rec) == 1L,
  nrow(rho) == 1L,
  all(is.finite(as.numeric(c(q$se, q$lwr, q$upr, mean_rec$se, mean_rec$lwr,
    mean_rec$upr, rho$se, rho$lwr, rho$upr)))),
  mean_rec$age == 1L,
  all(as.numeric(y$year[!is.na(y$year) & nzchar(y$year)]) <= 2024)
)

derived_ssb <- vapply(1963:2024, function(year) {
  n <- as.numeric(n_at_age$value[n_at_age$year == year])
  f <- as.numeric(f_at_age$value[f_at_age$year == year])
  w <- as.numeric(spawn_weight$value[match(1:26, as.integer(spawn_weight$age))])
  mat <- as.numeric(maturity$value[match(1:26, as.integer(maturity$age))])
  sum(n * w * mat * exp(-(f + 0.05) * 0.4))
}, numeric(1L))
stopifnot(max(abs(as.numeric(ssb$value[match(1963:2024, as.integer(ssb$year))]) - derived_ssb)) < 1e-8)

database <- file.path(root, "database")
stocks <- utils::read.csv(file.path(database, "stocks.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- utils::read.csv(file.path(database, "assessments.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- utils::read.csv(file.path(database, "inputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
outputs <- utils::read.csv(file.path(database, "outputs.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- utils::read.csv(file.path(root, "discovery", "candidates.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- utils::read.csv(file.path(root, "discovery", "inventory_units.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- utils::read.csv(file.path(root, "discovery", "selected_batch_01_2026.csv"), stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines(file.path(root, "discovery", "source_reviews",
  "noaa_acadian_redfish_2025.md"), warn = FALSE), collapse = "\n")
stopifnot(
  sum(stocks$stock_id == stock_id) == 1L,
  sum(assessments$assessment_id == assessment_id) == 1L,
  sum(inputs$assessment_id == assessment_id) == nrow(x),
  sum(outputs$assessment_id == assessment_id) == nrow(y),
  candidate$import_status[candidate$candidate_id == "NOAA:10455"] == "partial",
  inventory$import_status[import_env$candidate_inventory_row(inventory, "NOAA:10455", stock_id)] == "partial",
  selected$curation_status[selected$candidate_unit_id == stock_id] == "partial_source_import",
  grepl("source-supplied effective sample size", review, fixed = TRUE)
)

cat("NOAA Acadian redfish 2025 source, provenance, input/output, and derived-series tests passed.\n")
stopifnot(identical(source_hashes, tools::md5sum(source_paths)))
