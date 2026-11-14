stock_id <- "noaa_red_grouper_gom"
assessment_id <- paste0(stock_id, "_sedar88_2025")
candidate_id <- "NOAA:10331"

read_assessment_rows <- function(path, id) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  connection <- file(path, open = "r")
  on.exit(close(connection))
  readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  found <- list()
  repeat {
    lines <- readLines(connection, n = 50000L, warn = FALSE)
    if (!length(lines)) break
    matching <- lines[startsWith(lines, prefix)]
    if (length(matching)) {
      found[[length(found) + 1L]] <- read.csv(text = paste(matching, collapse = "\n"),
        header = FALSE, col.names = header, stringsAsFactors = FALSE,
        colClasses = "character", na.strings = c("", "NA"), check.names = FALSE)
    }
  }
  if (!length(found)) return(data.frame())
  do.call(rbind, found)
}

near <- function(x, expected, tolerance = 1e-8) {
  isTRUE(abs(as.numeric(x) - expected) <= tolerance)
}
blank <- function(x) is.na(x) | !nzchar(x)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read.csv("database/assumptions.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inputs <- read_assessment_rows("database/inputs.csv", assessment_id)
outputs <- read_assessment_rows("database/outputs.csv", assessment_id)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- assumptions[assumptions$assessment_id == assessment_id, , drop = FALSE]

get_input <- function(measure, year = NULL, age = NULL, fleet = NULL,
                      survey = NULL, partition = NULL, sex = NULL) {
  x <- inputs[inputs$measure == measure, , drop = FALSE]
  for (field in c("year", "age", "fleet", "survey", "partition", "sex")) {
    target <- get(field)
    if (is.null(target)) next
    value <- x[[field]]
    if (is.null(value)) value <- rep(NA_character_, nrow(x))
    blank_value <- blank(value)
    x <- x[if (is.na(target)) blank_value else !blank_value & value == as.character(target), , drop = FALSE]
  }
  x
}

get_output <- function(measure, year = NULL, age = NULL, fleet = NULL) {
  x <- outputs[outputs$measure == measure, , drop = FALSE]
  for (field in c("year", "age", "fleet")) {
    target <- get(field)
    if (is.null(target)) next
    value <- x[[field]]
    blank_value <- blank(value)
    x <- x[if (is.na(target)) blank_value else !blank_value & value == as.character(target), , drop = FALSE]
  }
  x
}

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- inventory[inventory$candidate_ids == candidate_id, , drop = FALSE]
batch <- read.csv("discovery/selected_batch_41_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_red_grouper_gom_2025.md",
  warn = FALSE), collapse = " ")
manifest <- read.csv("provenance/discovery_noaa_red_grouper_gom_2025/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
cache_options <- c("source_cache/discovery_noaa_red_grouper_gom_2025",
  file.path("..", "..", "discovery_noaa_red_grouper_gom_2025"))
cache <- cache_options[dir.exists(cache_options)][1L]
source_row <- manifest[manifest$file == "sedar_88_red_grouper_final_updated_2025.pdf", , drop = FALSE]

commercial_handline <- get_input("landings_biomass", "1986", fleet = "Commercial Handline",
  partition = "assessment_input")
commercial_handline_raw <- get_input("landings_biomass", "1986",
  fleet = "Commercial Handline (reported component)", partition = "reported_component")
commercial_other <- get_input("landings_biomass", "1986",
  fleet = "Commercial Other (reported component)", partition = "reported_component")
recreational_landing <- get_input("landings_numbers", "1986", fleet = "Recreational",
  partition = "aggregate_landings")
recreational_modes <- inputs[inputs$measure == "landings_numbers" &
  inputs$year == "1986" & inputs$fleet == "Recreational" &
  grepl("^mode_component_", inputs$partition), , drop = FALSE]
private_mode <- get_input("landings_biomass", "1986", fleet = "Recreational",
  partition = "SRFS_private_landings")
commercial_discard <- get_input("discard_numbers", "1993", fleet = "Commercial Handline",
  partition = "commercial_discards")
commercial_discard_se <- get_input("catch_se", "1993", fleet = "Commercial Handline",
  partition = "commercial_discard_se")
handline_index <- get_input("relative_abundance_index", "1993",
  survey = "Commercial Handline CPUE")
bottom_longline_2022 <- get_input("relative_abundance_index", "2022",
  survey = "NMFS Bottom Longline Survey")
m_age0 <- get_input("natural_mortality_at_age", age = "0", sex = "Female")
m_age29 <- get_input("natural_mortality_at_age", age = "29", sex = "Female")

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA Fisheries",
  stock$authority_stock_id == "10331",
  stock$scientific_name == "Epinephelus morio",
  stock$region == "Gulf of Mexico",
  stock$ocean == "Northwest Atlantic",
  sum(stocks$authority_stock_id == "10332", na.rm = TRUE) == 1L,
  nrow(assessment) == 1L,
  assessment$assessment_year == 2025,
  assessment$terminal_year == 2022,
  assessment$model_family == "Stock Synthesis",
  assessment$model_version == "3.30.21.0",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 12L,
  nrow(inputs) == 1083L,
  nrow(outputs) == 444L,
  nrow(commercial_handline) == 1L,
  near(commercial_handline$value, 3162271),
  commercial_handline$source_type == "reconstructed_source_input",
  nrow(commercial_handline_raw) == 1L,
  near(commercial_handline_raw$value, 3149753),
  nrow(commercial_other) == 1L,
  near(commercial_other$value, 12518),
  nrow(recreational_landing) == 1L,
  near(recreational_landing$value, 911543),
  nrow(recreational_modes) == 3L,
  sum(as.numeric(recreational_modes$value)) == 911543,
  nrow(private_mode) == 1L,
  near(private_mode$value, 2095625),
  nrow(commercial_discard) == 1L,
  near(commercial_discard$value, 83940),
  nrow(commercial_discard_se) == 1L,
  near(commercial_discard_se$value, 6147),
  nrow(handline_index) == 1L,
  near(handline_index$value, 0.731),
  nrow(bottom_longline_2022) == 1L,
  near(bottom_longline_2022$value, 0.501),
  nrow(get_input("relative_abundance_index")) == 115L,
  nrow(get_input("log_index_sd")) == 115L,
  nrow(get_input("natural_mortality_at_age")) == 30L,
  nrow(m_age0) == 1L,
  near(m_age0$value, 1.09),
  nrow(m_age29) == 1L,
  near(m_age29$value, 0.15),
  nrow(get_output("total_biomass")) == 37L,
  nrow(get_output("exploitable_biomass")) == 37L,
  nrow(get_output("SSB")) == 37L,
  nrow(get_output("total_numbers")) == 37L,
  nrow(get_output("recruitment")) == 37L,
  nrow(get_output("SSB_ratio_to_SSB0")) == 37L,
  nrow(get_output("exploitation_rate")) == 222L,
  nrow(get_output("fishing_mortality_at_age")) == 0L,
  nrow(get_output("numbers_at_age")) == 0L,
  nrow(get_output("SSB", "1986")) == 1L,
  near(get_output("SSB", "1986")$value, 732961),
  nrow(get_output("recruitment", "2022", "0")) == 1L,
  near(get_output("recruitment", "2022", "0")$value, 23646.6),
  all(is.na(outputs$se)),
  nrow(candidate) == 1L,
  candidate$eligibility == "eligible",
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  nrow(inventory) == 1L,
  inventory$matched_stock_id == stock_id,
  inventory$import_status == "partial",
  batch$curation_status == "source_curated_partial",
  grepl("Figure-only age compositions", review, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE),
  nrow(source_row) == 1L,
  as.numeric(source_row$bytes) == file.info(file.path(cache, source_row$file))$size,
  identical(tolower(unname(tools::sha256sum(file.path(cache, source_row$file)))),
    tolower(source_row$sha256)),
  all(!is.na(inputs$source_reference) & nzchar(inputs$source_reference)),
  all(!is.na(outputs$source_reference) & nzchar(outputs$source_reference))
)

cat("NOAA Gulf red grouper SEDAR 88 source records passed.\n")
