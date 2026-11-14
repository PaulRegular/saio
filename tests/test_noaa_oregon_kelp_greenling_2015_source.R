read_assessment_rows <- function(path, assessment_id) {
  header <- readLines(path, n = 1L, warn = FALSE)
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status"); if (is.null(status)) status <- 0L
  if (status == 1L) rows <- character() else if (status != 0L) stop("Could not read ", path)
  rows <- rows[startsWith(rows, paste0("\"", assessment_id, "\","))]
  if (!length(rows)) return(read.csv(text = header, nrows = 0L, check.names = FALSE,
    colClasses = "character"))
  read.csv(text = paste(c(header, rows), collapse = "\n"), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
}
id <- "noaa_kelp_greenling_oregon_2015"
stock_id <- "noaa_kelp_greenling_oregon"
i <- read_assessment_rows("database/inputs.csv", id)
o <- read_assessment_rows("database/outputs.csv", id)
a <- read_assessment_rows("database/assumptions.csv", id)
stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, check.names = FALSE)
assessment <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10462", , drop = FALSE]
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE, check.names = FALSE)
inventory <- inventory[inventory$candidate_ids == "NOAA:10462", , drop = FALSE]
selected <- read.csv("discovery/selected_batch_40_2026.csv", stringsAsFactors = FALSE, check.names = FALSE)
selected <- selected[selected$candidate_id == "NOAA:10462", , drop = FALSE]
provenance <- read.csv("provenance/discovery_noaa_oregon_kelp_greenling_2015/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_oregon_kelp_greenling_2015.md"), collapse = " ")

v <- function(measure, ...) {
  x <- i[i$measure == measure, , drop = FALSE]
  filters <- list(...)
  for (name in names(filters)) x <- x[!is.na(x[[name]]) & x[[name]] == as.character(filters[[name]]), , drop = FALSE]
  x
}
out <- function(measure, year) o[o$measure == measure & o$year == as.character(year), , drop = FALSE]
num <- function(x) as.numeric(x$value)
len <- v("frequency_at_length")
age <- v("proportion_at_age")
cal <- v("conditional_proportion_at_age")
mat <- v("maturity_at_length")
m <- v("fixed_mortality_medium")

stopifnot(
  nrow(stock[stock$stock_id == stock_id, , drop = FALSE]) == 1L,
  stock$ocean[stock$stock_id == stock_id] == "Northeast Pacific",
  nrow(assessment[assessment$assessment_id == id, , drop = FALSE]) == 1L,
  assessment$terminal_year[assessment$assessment_id == id] == 2014,
  assessment$estimate_terminal_year[assessment$assessment_id == id] == 2015,
  assessment$inputs_status[assessment$assessment_id == id] == "partial",
  assessment$outputs_status[assessment$assessment_id == id] == "partial",
  nrow(i) == 7247L, nrow(o) == 704L, nrow(a) == 10L,
  candidate$matched_stock_id == stock_id, candidate$match_status == "matched",
  candidate$import_status == "partial", inventory$matched_stock_id == stock_id,
  inventory$unit_key == paste0("candidate:", stock_id),
  selected$curation_status == "partial_source_import",
  nrow(v("catch_biomass")) == 575L,
  num(v("catch_biomass", year = 1900, fleet = "Commercial")) == 0,
  abs(num(v("catch_biomass", year = 1915, fleet = "Recreational Estuary")) - 1.729441593) < 1e-10,
  nrow(v("relative_abundance_index")) == 37L,
  nrow(v("log_index_sd")) == 37L,
  abs(num(v("relative_abundance_index", survey = "Commercial logbook CPUE", year = 2004)) - 0.2287043) < 1e-8,
  abs(num(v("log_index_sd", survey = "Commercial logbook CPUE", year = 2004)) - 0.198689533) < 1e-8,
  all(as.numeric(v("relative_abundance_index")$sampling_time) == 0.5),
  nrow(len) == 3276L,
  length(unique(len$observation_id)) == 100L,
  length(unique(len$length_bin)) == 28L,
  setequal(unique(len$sex), c("combined", "female", "male")),
  all(as.numeric(len$value) >= 0),
  length(unique(as.numeric(len$sample_size))) > 1L,
  nrow(age) == 468L, length(unique(age$observation_id)) == 36L,
  setequal(as.numeric(unique(age$age)), 0:12),
  all(grepl("Negative-fleet", age$notes, fixed = TRUE)),
  nrow(cal) == 2821L, length(unique(cal$observation_id)) == 217L,
  all(as.numeric(cal$length_bin_lower) <= as.numeric(cal$length_bin_upper)),
  all(!is.na(cal$sample_size)), all(!is.na(cal$age_error)),
  identical(as.numeric(mat$value), c(rep(0, 13), .115, .25, .7933, .944, rep(1, 14))),
  identical(as.numeric(mat$length_bin), seq(0, 60, 2)),
  nrow(m) == 2L, setequal(m$sex, c("female", "male")),
  as.numeric(m$value[m$sex == "female"]) == .360,
  as.numeric(m$value[m$sex == "male"]) == .318,
  nrow(out("total_biomass", 1915)) == 1L,
  num(out("total_biomass", 1915)) == 1412,
  num(out("SSB", 1915)) == 397,
  num(out("total_biomass", 2015)) == 835,
  abs(num(out("SSB", 2015)) - 315.98) < 1e-10,
  as.numeric(out("SSB", 2015)$lwr) == 116,
  as.numeric(out("SSB", 2015)$upr) == 516,
  num(out("depletion", 2015)) == .80,
  num(out("recruitment", 2015)) == 1413,
  as.numeric(out("recruitment", 2015)$lwr) == 0,
  as.numeric(out("recruitment", 2015)$upr) == 3318,
  all(is.na(o$se)),
  nrow(o[!is.na(o$age) & o$measure != "recruitment", , drop = FALSE]) == 0L,
  nrow(provenance) == 7L, all(grepl("^[[:xdigit:]]{64}$", provenance$sha256)),
  all(as.numeric(provenance$bytes) > 0),
  grepl("age 12 as the accumulator", review, fixed = TRUE),
  grepl("rather than likelihood observations", review, fixed = TRUE),
  grepl("No values have been fabricated", review, fixed = TRUE)
)
cat("Oregon Kelp Greenling source rows, units, coverage, provenance and limitations passed.\n")

