assessment_id <- "noaa_quillback_california_2025"
read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to read the focused source rows.")
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

stopifnot(nrow(i) == 17769L,
  sum(i$measure == "catch_biomass") == 218L,
  sum(i$measure == "log_catch_sd") == 218L,
  sum(i$measure == "relative_abundance_index") == 28L,
  sum(i$measure == "log_index_sd") == 28L,
  sum(i$measure == "frequency_at_length") == 2016L,
  sum(i$measure == "conditional_frequency_at_age") == 15180L,
  sum(i$measure == "natural_mortality_at_age" & i$type == "M") == 81L)

len <- i[i$measure == "frequency_at_length", ]
age <- i[i$measure == "conditional_frequency_at_age", ]
stopifnot(length(unique(len$observation_id)) == 96L,
  length(unique(len$observation_id[grepl("negative source year code -", len$notes, ignore.case = TRUE)])) == 8L,
  length(unique(len$observation_id[!grepl("negative source year code -", len$notes, ignore.case = TRUE)])) == 88L,
  setequal(unique(len$length_bin), seq(10, 50, 2)),
  length(unique(age$observation_id)) == 253L,
  length(unique(age$observation_id[grepl("negative source year code -", age$notes, ignore.case = TRUE)])) == 125L,
  length(unique(age$observation_id[!grepl("negative source year code -", age$notes, ignore.case = TRUE)])) == 128L,
  setequal(unique(age$age), 1:60),
  all(age$length_bin_lower %in% 1:21), all(age$length_bin_upper %in% 1:21),
  all(age$age_error == 1), all(age$sample_size > 0),
  all(i$value[i$measure == "natural_mortality_at_age"] == 0.068))

n <- o[o$type == "population" & o$measure == "numbers_at_age", ]
f <- o[o$type == "mortality" & o$measure == "fishing_mortality_at_age", ]
m <- o[o$type == "mortality" & o$measure == "natural_mortality_at_age", ]
b <- o[o$type == "biomass" & o$measure == "biomass_at_age", ]
catch_n <- o[o$type == "catch" & o$measure == "numbers_at_age", ]
stopifnot(nrow(o) == 71179L, nrow(n) == 109L * 81L, nrow(b) == 109L * 81L,
  nrow(m) == 109L * 81L, sum(!is.na(f$fleet)) == 218L * 81L,
  sum(is.na(f$fleet)) == 109L * 81L, nrow(catch_n) == 218L * 81L,
  setequal(n$year, 1916:2024), setequal(n$age, 0:80),
  all(abs(m$value - 0.068) < 1e-12),
  all(is.na(n$se) & is.na(n$lwr) & is.na(n$upr)))

n_sum <- aggregate(value ~ year, n, sum)
total_n <- o[o$measure == "total_numbers", ]
stopifnot(nrow(total_n) == 109L,
  max(abs(total_n$value[match(n_sum$year, total_n$year)] - n_sum$value)) < 1e-8)
spawn <- o[o$measure == "spawning_output", ]
recruit <- o[o$type == "recruitment" & o$measure == "recruitment", ]
spawn_2025 <- spawn[spawn$year == 2025, ]
recruit_2025 <- recruit[recruit$year == 2025, ]
stopifnot(nrow(spawn_2025) == 1L, abs(spawn_2025$value - 42.2558) < 1e-4,
  spawn_2025$lwr == 26.30, spawn_2025$upr == 58.21,
  grepl("not SSB", spawn_2025$notes),
  nrow(recruit_2025) == 1L, abs(recruit_2025$value - 39.9697) < 1e-4,
  recruit_2025$lwr == 13, recruit_2025$upr == 120,
  recruit_2025$scenario == "one-year forecast",
  !any(o$measure == "SSB"))

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
stock <- stocks[stocks$stock_id == "noaa_quillback_rockfish_california", ]
assessment <- assessments[assessments$assessment_id == assessment_id, ]
candidate <- candidates[candidates$candidate_id == "NOAA:15342", ]
stopifnot(nrow(stock) == 1L, stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L, assessment$terminal_year == 2024L,
  assessment$estimate_terminal_year == 2025L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  nrow(candidate) == 1L, candidate$match_status == "matched",
  candidate$matched_stock_id == stock$stock_id, candidate$import_status == "partial")

cat("NOAA California Quillback source checks passed.\n")
