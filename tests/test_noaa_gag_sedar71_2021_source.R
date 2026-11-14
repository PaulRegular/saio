read_assessment_rows <- function(path, id) {
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", id, path), stdout = TRUE, stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(data.frame())
  if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  prefix <- paste0('"', id, '",')
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(data.frame())
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  read.csv(text = paste(rows, collapse = "\n"), header = FALSE,
    col.names = header, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE)
}

assessment_id <- "noaa_gag_south_atlantic_sedar71_2021"
stock_id <- "noaa_gag_south_atlantic"
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
assumptions <- read_assessment_rows("database/assumptions.csv", assessment_id)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "NOAA:10349", , drop = FALSE]
manifest <- read.csv("provenance/noaa_gag_sedar71_2021/manifest.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_gag_sedar71_2021.md",
  warn = FALSE), collapse = " ")

counts <- inputs[inputs$measure == "frequency_at_age", , drop = FALSE]
proportions <- inputs[inputs$measure == "proportion_at_age", , drop = FALSE]
count_1990_age1 <- counts[counts$year == 1990L & counts$age == 1L, , drop = FALSE]
prop_1990_age1 <- proportions[proportions$year == 1990L &
  proportions$age == 1L, , drop = FALSE]
count_2006_age11 <- counts[counts$year == 2006L & counts$age == 11L, , drop = FALSE]
count_2006_age12 <- counts[counts$year == 2006L & counts$age == 12L, , drop = FALSE]
prop_2006_age12 <- proportions[proportions$year == 2006L &
  proportions$age == 12L, , drop = FALSE]
composition_comparison <- merge(
  counts[c("year", "age", "value", "sample_size")],
  proportions[c("year", "age", "value")], by = c("year", "age"),
  suffixes = c("_count", "_proportion"))
composition_mismatch <- abs(composition_comparison$value_count /
  composition_comparison$sample_size - composition_comparison$value_proportion) > 0.00015
n_1962_age1 <- outputs[outputs$measure == "numbers_at_age" &
  outputs$year == 1962L & outputs$age == 1L, , drop = FALSE]
n_2020_age1 <- outputs[outputs$measure == "numbers_at_age" &
  outputs$year == 2020L & outputs$age == 1L, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10349",
  stock$scientific_name == "Mycteroperca microlepis",
  stock$area == "South Atlantic Coast",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2021L,
  assessment$terminal_year == 2019L,
  assessment$estimate_terminal_year == 2020L,
  assessment$model_family == "Beaufort Assessment Model",
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(assumptions) == 13L,
  nrow(inputs) == 1541L,
  nrow(outputs) == 3990L,
  nrow(counts) == 433L,
  nrow(proportions) == 406L,
  all(counts$type == "index" & counts$basis == "native_frequency" & counts$unit == "fish"),
  all(proportions$type == "index" & proportions$basis == "proportion_numbers" & proportions$unit == "proportion"),
  count_1990_age1$value == 16,
  count_1990_age1$sample_size == 25,
  prop_1990_age1$value == 0.64,
  prop_1990_age1$sample_size == 25,
  count_2006_age11$value == 1,
  count_2006_age12$value == 0,
  prop_2006_age12$value == 1,
  sum(composition_mismatch) == 8L,
  nrow(counts[counts$year == 2017L & counts$age == 1L, , drop = FALSE]) == 0L,
  nrow(counts[counts$year == 2019L & counts$age == 3L, , drop = FALSE]) == 0L,
  n_1962_age1$value == 576.58,
  n_2020_age1$value == 305.17,
  n_2020_age1$scenario == "2020 assessment projection",
  all(is.na(outputs$se)) && all(is.na(outputs$lwr)) && all(is.na(outputs$upr)),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  nrow(manifest) == 5L,
  !anyDuplicated(manifest$file),
  all(grepl("^source_cache/noaa_gag_sedar71_2021/", manifest$file)),
  all(manifest$retrieved_utc == "2026-10-30T04:20:35Z"),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(file.exists(file.path(".", manifest$file))),
  all(tolower(unname(tools::sha256sum(file.path(".", manifest$file)))) ==
    tolower(manifest$sha256)),
  grepl("disagree in eight shared age-year cells", review, fixed = TRUE),
  grepl("Catch-at-age is therefore not reconstructed", review, fixed = TRUE)
)

cat("NOAA South Atlantic gag SEDAR 71 source values, table discrepancies, units, and provenance passed.\n")
