assessment_id <- "noaa_cowcod_southern_california_2019"
read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to read the focused Cowcod source rows.")
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
stopifnot(nrow(i) == 30072L,
  sum(i$measure == "catch_biomass") == 210L,
  sum(i$measure == "log_catch_sd") == 210L,
  sum(i$measure == "relative_abundance_index") == 41L,
  sum(i$measure == "larval_abundance_index") == 14L,
  sum(i$measure == "total_biomass" & i$type == "index") == 2L,
  sum(i$measure == "log_index_sd") == 57L,
  sum(i$measure == "frequency_at_length") == 60L * 47L,
  sum(i$measure == "conditional_frequency_at_age") == 438L * 61L)

index <- i[i$measure %in% c("relative_abundance_index", "larval_abundance_index", "total_biomass") & i$type == "index", ]
index_sd <- i[i$measure == "log_index_sd", ]
length_comp <- i[i$measure == "frequency_at_length", ]
age_comp <- i[i$measure == "conditional_frequency_at_age", ]
stopifnot(length(unique(index$observation_id)) == 57L,
  length(unique(index_sd$observation_id)) == 57L,
  setequal(index$observation_id, index_sd$observation_id),
  setequal(unique(index$survey[index$measure == "total_biomass"]),
    c("SWFSC_SUB_SURVEY", "SWFSC_ROV_SURVEY")),
  all(index$basis[index$measure == "total_biomass"] == "biomass"),
  all(index$unit[index$measure == "total_biomass"] == "metric tonnes"),
  all(grepl("unit code 1 is biomass", index$notes[index$measure == "total_biomass"])),
  all(grepl("unit code 30", index$notes[index$measure == "larval_abundance_index"])),
  setequal(unique(index$sampling_time), c(0, 0.5)),
  length(unique(length_comp$observation_id)) == 60L,
  sum(!duplicated(length_comp$observation_id) & grepl("negative source year code -", length_comp$notes)) == 23L,
  length(unique(age_comp$observation_id)) == 438L,
  sum(!duplicated(age_comp$observation_id) & grepl("negative source year code -", age_comp$notes)) == 13L,
  setequal(unique(age_comp$age), 0:60),
  setequal(unique(age_comp$age_error), c(1, 2)),
  all(age_comp$length_bin_lower <= age_comp$length_bin_upper))

n <- o[o$type == "population" & o$measure == "numbers_at_age", ]
b <- o[o$type == "biomass" & o$measure == "biomass_at_age", ]
m <- o[o$type == "mortality" & o$measure == "natural_mortality_at_age", ]
f_fleet <- o[o$type == "mortality" & o$measure == "fishing_mortality_at_age" & !is.na(o$fleet) & nzchar(o$fleet), ]
catch_n <- o[o$type == "catch" & o$measure == "numbers_at_age", ]
total_n <- o[o$measure == "total_numbers", ]
spawn <- o[o$measure == "spawning_output", ]
recruit <- o[o$type == "recruitment" & o$measure == "recruitment", ]
stopifnot(nrow(o) == 58550L,
  nrow(n) == 119L * 61L, nrow(b) == 119L * 61L, nrow(m) == 119L * 60L,
  nrow(f_fleet) == 119L * 61L * 2L, nrow(catch_n) == 119L * 61L * 2L,
  setequal(n$year, 1900:2018), setequal(n$age, 0:60),
  all(is.na(n$se) & is.na(n$lwr) & is.na(n$upr)),
  nrow(total_n) == 119L, nrow(spawn) == 120L, nrow(recruit) == 119L)
n_sum <- aggregate(value ~ year, n, sum)
stopifnot(max(abs(total_n$value[match(n_sum$year, total_n$year)] - n_sum$value)) < 1e-8)
spawn_2019 <- spawn[spawn$year == 2019L & spawn$source_type == "official_table", ]
stopifnot(nrow(spawn_2019) == 1L, spawn_2019$value == 163,
  spawn_2019$lwr == 130, spawn_2019$upr == 195,
  grepl("divided by two", spawn$notes[spawn$source_type == "derived_source_output"][1L]))
M_parameter <- o[o$measure == "natural_mortality_average_parameter", ]
stopifnot(nrow(M_parameter) == 1L, M_parameter$value == 0.088, M_parameter$se == 0.011)

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == "noaa_cowcod_southern_california", ]
assessment <- assessments[assessments$assessment_id == assessment_id, ]
candidate <- candidates[candidates$candidate_id == "NOAA:10443", ]
stopifnot(nrow(stock) == 1L, stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$terminal_year == 2018L,
  assessment$estimate_terminal_year == 2019L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$matched_stock_id == stock$stock_id, candidate$import_status == "partial")

cat("NOAA Cowcod 2019 source checks passed.\n")
