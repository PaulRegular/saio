assessment_id <- "noaa_lingcod_northern_pacific_coast_2021"
.libPaths(c(file.path(".", "source_cache", "r-lib"), .libPaths()))
read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  column_names <- names(read.csv(text = header, check.names = FALSE))
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to read focused assessment rows.")
  rows_file <- tempfile(fileext = ".csv")
  on.exit(unlink(rows_file), add = TRUE)
  status <- suppressWarnings(system2(rg,
    c("--color", "never", "--no-heading", "-F", assessment_id, path),
    stdout = rows_file, stderr = FALSE))
  if (!is.null(status) && status == 1L) return(data.frame())
  if (!is.null(status) && status != 0L) stop("Could not scan ", path)
  if (requireNamespace("data.table", quietly = TRUE)) {
    out <- data.table::fread(rows_file, header = FALSE, col.names = column_names,
      na.strings = c("", "NA"), showProgress = FALSE, data.table = FALSE)
  } else {
    rows <- readLines(rows_file, warn = FALSE)
    rows <- rows[startsWith(rows, paste0('"', assessment_id, '",'))]
    out <- read.csv(text = paste(c(header, rows), collapse = "
"),
      stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
  }
  out[startsWith(out$assessment_id, assessment_id), , drop = FALSE]
}
i <- read_assessment_rows("inputs")
o <- read_assessment_rows("outputs")
stopifnot(nrow(i) == 347150L,
  sum(i$measure == "catch_biomass") == 660L,
  sum(i$measure == "log_catch_sd") == 660L,
  sum(i$measure %in% c("relative_abundance_index", "relative_biomass_index") & i$type == "index") == 137L,
  sum(i$measure == "log_index_sd") == 137L,
  sum(i$measure == "frequency_at_length") == 383L * 61L * 2L,
  sum(i$measure == "conditional_frequency_at_age") == 7115L * 21L * 2L)
index <- i[i$type == "index" & i$measure %in% c("relative_abundance_index", "relative_biomass_index"), ]
index_sd <- i[i$measure == "log_index_sd", ]
length_comp <- i[i$measure == "frequency_at_length", ]
age_comp <- i[i$measure == "conditional_frequency_at_age", ]
stopifnot(length(unique(index$observation_id)) == 137L,
  setequal(index$observation_id, index_sd$observation_id),
  all(index$sampling_time == 0.5),
  all(grepl("relative index", index$notes)),
  length(unique(length_comp$observation_id)) == 383L,
  length(unique(age_comp$observation_id)) == 7115L,
  sum(!duplicated(age_comp$observation_id) & grepl("ghost", age_comp$notes)) == 218L,
  all(age_comp$type == "biology"),
  all(age_comp$age %in% 0:20),
  all(age_comp$age_error == 1),
  sum(grepl("retained but ignored", age_comp$notes)) > 0L,
  sum(grepl("vectors jointly", age_comp$notes)) > 0L,
  all(age_comp$length_bin_lower <= age_comp$length_bin_upper))

N <- o[o$type == "population" & o$measure == "numbers_at_age", ]
B <- o[o$type == "biomass" & o$measure == "biomass_at_age", ]
F_fleet <- o[o$type == "mortality" & o$measure == "fishing_mortality_at_age" & !is.na(o$fleet) & nzchar(o$fleet), ]
F_total <- o[o$type == "mortality" & o$measure == "fishing_mortality_at_age" & (is.na(o$fleet) | !nzchar(o$fleet)), ]
M <- o[o$measure == "natural_mortality_at_age", ]
M_parameters <- o[o$measure == "natural_mortality_average_parameter", ]
weights <- o[o$type == "biology" & o$measure == "weight_at_age", ]
maturity <- o[o$measure == "maturity_at_age", ]
SSB <- o[o$measure == "SSB", ]
recruitment <- o[o$type == "recruitment" & o$measure == "recruitment", ]
total_numbers <- o[o$measure == "total_numbers", ]
stopifnot(nrow(o) == 73285L,
  nrow(N) == 133L * 2L * 26L, nrow(B) == 133L * 2L * 26L,
  nrow(F_fleet) == 133L * 5L * 2L * 26L, nrow(F_total) == 133L * 2L * 26L,
  nrow(M) == 133L * 2L * 26L, nrow(M_parameters) == 2L,
  nrow(weights) == 133L * 2L * 26L, nrow(maturity) == 133L * 26L,
  nrow(SSB) == 133L, nrow(recruitment) == 133L, nrow(total_numbers) == 133L,
  setequal(N$year, 1889:2021), setequal(N$age, 0:25), setequal(N$sex, c("female", "male")),
  setequal(SSB$year[!is.na(SSB$lwr)], 2011:2021),
  setequal(recruitment$year[!is.na(recruitment$lwr)], 2011:2021),
  all(!is.na(SSB$se)), all(!is.na(recruitment$se)),
  all(is.na(total_numbers$se)), all(weights$value > 0),
  all(maturity$value >= 0 & maturity$value <= 1),
  all(is.na(N$se) & is.na(N$lwr) & is.na(N$upr)))
ssb2021 <- SSB[SSB$year == 2021L, ]
rec2021 <- recruitment[recruitment$year == 2021L, ]
stopifnot(nrow(ssb2021) == 1L, ssb2021$value == 11010.2,
  ssb2021$lwr == 7143, ssb2021$upr == 14878,
  nrow(rec2021) == 1L, abs(rec2021$value - 16174.8) < 0.01,
  rec2021$lwr == 5123, rec2021$upr == 51066,
  abs(M_parameters$value[M_parameters$sex == "female"] - 0.417839) < 1e-6,
  abs(M_parameters$value[M_parameters$sex == "male"] - 0.413968) < 1e-6,
  all(!is.na(M_parameters$se)))
N_total <- aggregate(value ~ year, N, sum)
stopifnot(max(abs(total_numbers$value[match(N_total$year, total_numbers$year)] - N_total$value)) < 1e-8)
F_sum <- aggregate(value ~ year + sex + age, F_fleet, sum)
F_join <- merge(F_sum, F_total[, c("year", "sex", "age", "value")], by = c("year", "sex", "age"), suffixes = c("_fleet", "_total"))
stopifnot(nrow(F_join) == nrow(F_total), max(abs(F_join$value_fleet - F_join$value_total)) < 1e-10)

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == "noaa_lingcod_northern_pacific_coast", ]
assessment <- assessments[assessments$assessment_id == assessment_id, ]
candidate <- candidates[candidates$candidate_id == "NOAA:12194", ]
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == "noaa_lingcod_north_pacific_coast_2021", ]
stopifnot(nrow(stock) == 1L, stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$terminal_year == 2020L,
  assessment$estimate_terminal_year == 2021L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$matched_stock_id == stock$stock_id, candidate$import_status == "partial",
  nrow(unit) == 1L, unit$matched_stock_id == stock$stock_id, unit$import_status == "partial")
cat("NOAA northern lingcod 2021 source checks passed.
")
