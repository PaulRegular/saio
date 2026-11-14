read_assessment_rows <- function(path, assessment_id) {
  prefix <- paste0('"', assessment_id, '",')
  rows <- suppressWarnings(system2("rg", c("--color", "never", "--no-heading",
    "--no-line-number", "-F", assessment_id, path), stdout = TRUE,
    stderr = FALSE))
  status <- attr(rows, "status")
  if (is.null(status)) status <- 0L
  if (status == 1L) return(NULL)
  if (status != 0L) stop("Could not read assessment rows from ", path, ".")
  rows <- rows[startsWith(rows, prefix)]
  if (!length(rows)) return(NULL)
  header <- readLines(path, n = 1L, warn = FALSE)
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

read_columns <- function(path, columns) {
  fields <- names(read.csv(path, nrows = 0L, check.names = FALSE))
  classes <- rep("NULL", length(fields))
  names(classes) <- fields
  classes[columns] <- "character"
  read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
    check.names = FALSE, colClasses = classes)
}

stock_id <- "noaa_vermilion_snapper_gulf"
assessment_id <- "noaa_vermilion_snapper_gulf_sedar67_2020"
candidate_id <- "NOAA:10256"

stocks <- read_columns("database/stocks.csv", c("stock_id", "authority_stock_id",
  "scientific_name", "common_name", "area", "ocean"))
assessments <- read_columns("database/assessments.csv", c("assessment_id",
  "stock_id", "assessment_year", "terminal_year", "estimate_terminal_year",
  "assessment_type", "model_family", "model_version", "is_current",
  "is_applied", "framework_year", "assumptions_status", "inputs_status",
  "outputs_status"))
assumptions <- read_columns("database/assumptions.csv", c("assessment_id",
  "component", "setting", "value", "source_reference", "notes"))
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
candidates <- read_columns("discovery/candidates.csv", c("candidate_id",
  "matched_stock_id", "match_status", "eligibility", "import_status",
  "output_evidence", "notes"))
manifest <- read.csv(
  "provenance/discovery_noaa_vermilion_snapper_gom_2020/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE
)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
get_output <- function(measure) outputs[outputs$measure == measure, , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority_stock_id == "10256",
  stock$scientific_name == "Rhomboplites aurorubens",
  stock$area == "Gulf of Mexico",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$stock_id == stock_id,
  assessment$assessment_year == "2020",
  assessment$terminal_year == "2017",
  assessment$estimate_terminal_year == "2017",
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.14.05-safe",
  assessment$is_current == "TRUE",
  assessment$is_applied == "TRUE",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 10L,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("SEDAR 67 Table 18", candidate$output_evidence, fixed = TRUE),
  nrow(manifest) == 6L,
  !anyDuplicated(manifest$file),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  nrow(outputs) == 340L,
  setequal(unique(outputs$year), as.character(1950:2017)),
  all(outputs$source_type == "official_table"),
  all(outputs$source_reference == "SEDAR67_SAR.pdf, Table 18"),
  all(is.na(outputs$se)),
  all(is.na(outputs$lwr)),
  all(is.na(outputs$upr)),
  is.null(inputs),
  all(vapply(c("total_biomass", "spawning_output", "total_abundance",
    "recruitment", "SSB_ratio"), function(x) nrow(get_output(x)) == 68L,
    logical(1L))),
  all(get_output("total_biomass")$unit == "metric tons"),
  all(get_output("spawning_output")$unit == "eggs"),
  all(get_output("total_abundance")$unit == "thousand fish"),
  all(get_output("recruitment")$unit == "thousand fish"),
  all(get_output("SSB_ratio")$unit == "proportion"),
  all(get_output("recruitment")$age == "0")
)

first <- outputs[outputs$year == "1950", , drop = FALSE]
last <- outputs[outputs$year == "2017", , drop = FALSE]
value_at <- function(rows, measure) as.numeric(rows$value[rows$measure == measure])
stopifnot(
  value_at(first, "total_biomass") == 34570,
  value_at(first, "spawning_output") == 6.74e14,
  value_at(first, "total_abundance") == 94019,
  value_at(first, "recruitment") == 27366,
  value_at(first, "SSB_ratio") == 1,
  value_at(last, "total_biomass") == 18868,
  value_at(last, "spawning_output") == 3.53e14,
  value_at(last, "total_abundance") == 83617,
  value_at(last, "recruitment") == 21237,
  value_at(last, "SSB_ratio") == 0.52
)

review <- paste(readLines(
  "discovery/source_reviews/noaa_vermilion_snapper_gulf_2020.md",
  warn = FALSE), collapse = "\n")
stopifnot(
  grepl("Table 18 has been transcribed for 1950-2017", review, fixed = TRUE),
  grepl("No inputs have yet been imported", review, fixed = TRUE),
  grepl("Stock Monitoring", review, fixed = TRUE)
)

cat("NOAA Gulf vermilion snapper 2020 source outputs, units, coverage and provenance passed.\n")
