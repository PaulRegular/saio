assessment_id <- "noaa_california_scorpionfish_southern_california_2017"
read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to read the focused scorpionfish source rows.")
  rows <- suppressWarnings(system2(rg, c("--color", "never", "--no-heading", "-F",
    assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L) stop("Could not read ", path)
  rows <- rows[startsWith(rows, paste0("\"", assessment_id, "\","))]
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
}

i <- read_assessment_rows("inputs")
o <- read_assessment_rows("outputs")
stopifnot(nrow(i) == 21387L,
  sum(i$measure == "catch_biomass") == 620L,
  sum(i$measure == "log_catch_sd") == 620L,
  sum(i$measure == "relative_abundance_index") == 141L,
  sum(i$measure == "relative_biomass_index") == 19L,
  sum(i$measure == "log_index_sd") == 160L,
  sum(i$measure == "frequency_at_length") == 11115L,
  sum(i$measure == "conditional_frequency_at_age") == 8712L,
  !any(i$measure %in% c("catch_numbers", "landings_numbers_at_age", "numbers_at_age")))

catch <- i[i$measure == "catch_biomass", , drop = FALSE]
stopifnot(setequal(catch$year, 1916:2016),
  abs(sum(catch$value[catch$year == 2016L]) - 74.18561) < 1e-5,
  all(catch$unit == "metric tonnes"))

index <- i[i$measure %in% c("relative_abundance_index", "relative_biomass_index"), , drop = FALSE]
index_sd <- i[i$measure == "log_index_sd", , drop = FALSE]
stopifnot(nrow(index) == 160L, nrow(index_sd) == 160L,
  setequal(index$observation_id, index_sd$observation_id),
  setequal(unique(index$sampling_time), 0.5),
  sum(index$basis == "numbers") == 141L,
  sum(index$basis == "biomass") == 19L,
  all(grepl("physical scale not stated", index$unit)))

length_comp <- i[i$measure == "frequency_at_length", , drop = FALSE]
length_records <- unique(length_comp[c("source_reference", "sex", "observation_id", "year")])
stopifnot(length(unique(length_comp$source_reference)) == 233L,
  length(unique(length_comp$observation_id)) == 247L,
  setequal(unique(length_comp$length_bin), 1:45),
  sum(!duplicated(length_comp$source_reference) & grepl("Source year code -", length_comp$notes)) == 29L,
  all(length_comp$basis == "native_frequency"),
  all(length_comp$unit == "source frequency"),
  sum(length_records$sex == "combined") == 219L,
  sum(length_records$sex == "female") == 14L,
  sum(length_records$sex == "male") == 14L)

age_comp <- i[i$measure == "conditional_frequency_at_age", , drop = FALSE]
age_by_source_sex <- aggregate(value ~ observation_id, age_comp, sum)
age_source_id <- sub("_[FM]$", "", age_by_source_sex$observation_id)
age_totals <- aggregate(value ~ source_id, data.frame(source_id = age_source_id,
  value = age_by_source_sex$value), sum)
age_sizes <- unique(data.frame(source_id = sub("_[FM]$", "", age_comp$observation_id),
  sample_size = age_comp$sample_size))
age_sizes <- aggregate(sample_size ~ source_id, age_sizes, max)
age_by_source <- merge(age_totals, age_sizes, by = "source_id")
stopifnot(nrow(age_comp) == 8712L,
  length(unique(age_comp$observation_id)) == 396L,
  setequal(unique(age_comp$age), 0:21),
  all(age_comp$basis == "native_frequency"),
  all(age_comp$unit == "fish"),
  all(age_comp$age_error == 1),
  all(age_comp$length_bin_lower <= age_comp$length_bin_upper),
  nrow(age_by_source) == 198L,
  max(abs(age_by_source$value - age_by_source$sample_size)) < 1e-8)

n <- o[o$type == "population" & o$measure == "numbers_at_age", , drop = FALSE]
total_n <- o[o$measure == "total_numbers", , drop = FALSE]
z <- o[o$measure == "total_mortality_at_age", , drop = FALSE]
m <- o[o$measure == "natural_mortality_at_age", , drop = FALSE]
f <- o[o$measure == "fishing_mortality_at_age", , drop = FALSE]
catch_n <- o[o$type == "catch" & o$measure == "numbers_at_age", , drop = FALSE]
ssb <- o[o$measure == "SSB", , drop = FALSE]
biomass <- o[o$measure == "total_biomass", , drop = FALSE]
recruitment <- o[o$type == "recruitment" & o$measure == "recruitment", , drop = FALSE]
stopifnot(nrow(o) == 44238L,
  nrow(n) == 101L * 2L * 22L,
  nrow(z) == 101L * 2L * 21L,
  nrow(m) == 101L * 2L * 21L,
  nrow(f) == 101L * 2L * 21L,
  nrow(catch_n) == 101L * 2L * 6L * 22L,
  nrow(total_n) == 101L, nrow(ssb) == 101L,
  nrow(biomass) == 101L, nrow(recruitment) == 101L,
  setequal(n$year, 1916:2016), setequal(n$age, 0:21),
  setequal(m$age, 0:20), setequal(f$age, 0:20),
  all(abs(m$value - 0.235) < 1e-8),
  all(is.na(o$se) & is.na(o$lwr) & is.na(o$upr)))

total_n_by_year <- aggregate(value ~ year, n, sum)
stopifnot(max(abs(total_n$value[match(total_n_by_year$year, total_n$year)] - total_n_by_year$value)) < 1e-8)
f_check <- merge(f, z[c("year", "sex", "age", "value")], by = c("year", "sex", "age"), suffixes = c("_F", "_Z"))
f_check <- merge(f_check, m[c("year", "sex", "age", "value")], by = c("year", "sex", "age"))
stopifnot(max(abs(f_check$value_F - (f_check$value_Z - f_check$value))) < 1e-8)

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == "noaa_california_scorpionfish_southern_california", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10461", , drop = FALSE]
stopifnot(nrow(stock) == 1L, stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$terminal_year == 2016L,
  assessment$estimate_terminal_year == 2016L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$matched_stock_id == stock$stock_id, candidate$import_status == "partial")

cat("NOAA California scorpionfish 2017 source checks passed.\n")
