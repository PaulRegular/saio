assessment_id <- "iphc_pacific_halibut_2025"
stock_id <- "iphc_pacific_halibut"

read_rows <- function(path, id) {
  header <- names(read.csv(path, nrows = 0L, stringsAsFactors = FALSE,
    check.names = FALSE))
  con <- file(path, open = "r")
  on.exit(close(con))
  readLines(con, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  result <- list()
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) break
    matched <- lines[startsWith(lines, prefix)]
    if (length(matched)) result[[length(result) + 1L]] <- read.csv(
      text = paste(matched, collapse = "\n"), header = FALSE,
      col.names = header, stringsAsFactors = FALSE, colClasses = "character",
      na.strings = c("", "NA"), check.names = FALSE)
  }
  if (!length(result)) return(data.frame())
  do.call(rbind, result)
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
assumptions <- read_rows("database/assumptions.csv", assessment_id)
inputs <- read_rows("database/inputs.csv", assessment_id)
outputs <- read_rows("database/outputs.csv", assessment_id)

fiss_index <- inputs[inputs$survey == "IPHC FISS modelled NPUE" &
  inputs$measure == "relative_abundance_index", , drop = FALSE]
fiss_cv <- inputs[inputs$survey == "IPHC FISS modelled NPUE" &
  inputs$measure == "abundance_index_cv", , drop = FALSE]
landings <- inputs[inputs$measure == "landings_biomass", , drop = FALSE]
other_mortality <- inputs[inputs$measure == "catch_biomass", , drop = FALSE]
commercial_wpue <- inputs[inputs$fleet == "IPHC directed commercial fishery" &
  inputs$measure == "relative_biomass_index", , drop = FALSE]
model_ssb <- outputs[outputs$measure == "SSB" &
  outputs$source_reference == "IPHC-2026-TSD-029, rows 5-143", , drop = FALSE]
table_ssb <- outputs[outputs$measure == "SSB" &
  outputs$scenario == "Ensemble median", , drop = FALSE]
intensity <- outputs[outputs$measure == "fishing_intensity_Fxx_percent", , drop = FALSE]
recruitment <- outputs[outputs$measure == "recruitment" & outputs$age == "0", , drop = FALSE]
age8_biomass <- outputs[outputs$measure == "biomass_by_age_group" &
  outputs$age_group == "8+", , drop = FALSE]

candidate_rows <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidates <- candidate_rows[!is.na(candidate_rows$candidate_unit_id) &
  candidate_rows$candidate_unit_id == stock_id, , drop = FALSE]
selection <- read.csv("discovery/selected_unworked_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selection <- selection[selection$candidate_id == "NOAA:11082", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "IPHC",
  stock$authority_stock_id == "IPHC Convention Area",
  stock$scientific_name == "Hippoglossus stenolepis",
  stock$ocean == "Northeast Pacific",
  nrow(assessment) == 1L,
  assessment$assessment_year == "2025",
  assessment$terminal_year == "2025",
  assessment$estimate_terminal_year == "2026",
  assessment$model_family == "Stock Synthesis",
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 12L,
  nrow(fiss_index) == 297L,
  nrow(fiss_cv) == 297L,
  setequal(unique(fiss_index$region), c("2A", "2B", "2C", "3A", "3B", "4A", "4B", "4CDE", "Coastwide")),
  min(as.integer(fiss_index$year)) == 1993L,
  max(as.integer(fiss_index$year)) == 2025L,
  fiss_index$value[fiss_index$year == "2025" & fiss_index$region == "2A"] == "1.34",
  fiss_cv$value[fiss_cv$year == "2025" & fiss_cv$region == "2A"] == "0.21",
  grepl("0.93 to 2.02", fiss_index$notes[fiss_index$year == "2025" & fiss_index$region == "2A"], fixed = TRUE),
  nrow(landings) > 500L,
  min(as.integer(landings$year)) == 1888L,
  max(as.integer(landings$year)) == 2025L,
  landings$value[landings$year == "2025" & landings$region == "2A"] == "372",
  !any(landings$region == "Total"),
  nrow(other_mortality) > 300L,
  setequal(unique(other_mortality$fleet), c("Directed commercial discards", "Recreational fisheries", "Subsistence fisheries", "Non-directed commercial discards")),
  all(!other_mortality$fleet %in% c("Total", "Commercial landings (includes FISS)")),
  other_mortality$value[other_mortality$year == "2025" & other_mortality$fleet == "Directed commercial discards"] == "417",
  nrow(commercial_wpue) > 500L,
  min(as.integer(commercial_wpue$year)) == 1907L,
  max(as.integer(commercial_wpue$year)) == 2025L,
  commercial_wpue$value[commercial_wpue$year == "2025" & commercial_wpue$region == "Coastwide"] == "49.9",
  nrow(model_ssb) == 348L,
  all(!is.na(model_ssb$lwr) & !is.na(model_ssb$upr)),
  nrow(model_ssb[model_ssb$scenario == "Coastwide long", ]) == 139L,
  nrow(model_ssb[model_ssb$scenario == "Coastwide short", ]) == 35L,
  model_ssb$value[model_ssb$scenario == "Coastwide long" & model_ssb$year == "2026"] == "67268",
  model_ssb$lwr[model_ssb$scenario == "Coastwide long" & model_ssb$year == "2026"] == "43681",
  model_ssb$upr[model_ssb$scenario == "Coastwide long" & model_ssb$year == "2026"] == "90854",
  nrow(table_ssb) == 35L,
  table_ssb$value[table_ssb$year == "2026"] == "166",
  table_ssb$lwr[table_ssb$year == "2026"] == "113",
  table_ssb$upr[table_ssb$year == "2026"] == "272",
  nrow(intensity) == 34L,
  intensity$value[intensity$year == "2025"] == "52",
  grepl("not instantaneous F", intensity$notes, fixed = TRUE),
  nrow(recruitment) == 116L,
  min(as.integer(recruitment$year)) == 1992L,
  max(as.integer(recruitment$year)) == 2020L,
  nrow(age8_biomass) == 140L,
  min(as.integer(age8_biomass$year)) == 1992L,
  max(as.integer(age8_biomass$year)) == 2026L,
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age")),
  all(!is.na(inputs$source_reference) & nzchar(inputs$source_reference)),
  all(!is.na(outputs$source_reference) & nzchar(outputs$source_reference)),
  nrow(candidates) == 2L,
  all(candidates$matched_stock_id == stock_id),
  all(candidates$import_status == "partial"),
  nrow(selection) == 1L,
  selection$curation_status == "source_curated_partial",
  file.exists("discovery/source_reviews/iphc_pacific_halibut_2025.md")
)

cat("IPHC Pacific halibut 2025 source records passed.\n")
