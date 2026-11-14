read_matching_rows <- function(path, id) {
  connection <- file(path, open = "rt")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "mpi_snapper_sna1_2023"
stock_id <- "mpi_snapper_sna1"
candidate_id <- "MPI:SNA1"
stock <- read_matching_rows("database/stocks.csv", stock_id)
assessment <- read_matching_rows("database/assessments.csv", assessment_id)
assumptions <- read_matching_rows("database/assumptions.csv", assessment_id)
inputs <- read_matching_rows("database/inputs.csv", assessment_id)
outputs <- read_matching_rows("database/outputs.csv", assessment_id)
candidate <- read_matching_rows("discovery/candidates.csv", candidate_id)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit <- units[units$unit_key == paste0("stock:", stock_id), , drop = FALSE]
selection <- read.csv("discovery/selected_batch_05_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
selection <- selection[selection$candidate_id == candidate_id, , drop = FALSE]
manifest <- read.csv("provenance/mpi_snapper_sna1_2023_sources.csv",
  stringsAsFactors = FALSE)

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "Fisheries New Zealand",
  stock$authority_stock_id == "SNA 1",
  stock$scientific_name == "Chrysophrys auratus",
  stock$ocean == "Southwest Pacific",
  grepl("three distinct modeled areas", stock$notes, fixed = TRUE),
  nrow(assessment) == 1L,
  assessment$assessment_year == 2023L,
  assessment$terminal_year == 2022L,
  assessment$estimate_terminal_year == 2022L,
  assessment$is_current,
  assessment$is_applied,
  assessment$model_family == "Casal2",
  all(assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial",
  grepl(candidate_id, unit$candidate_ids, fixed = TRUE),
  nrow(selection) == 1L,
  selection$curation_status == "source_curated_partial",
  nrow(manifest) == 7L,
  all(grepl("^[A-F0-9]{64}$", toupper(manifest$sha256)))
)

catch <- inputs[inputs$measure == "catch_biomass", ]
stopifnot(
  nrow(catch) == 1845L,
  all(catch$type == "catch"),
  all(catch$basis == "biomass"),
  all(catch$unit == "tonnes"),
  all(catch$year_basis == "model_year"),
  all(catch$source_type == "official_table"),
  setequal(unique(catch$region), c("East Northland", "Hauraki Gulf", "Bay of Plenty")),
  all(vapply(split(catch, catch$region), nrow, integer(1L)) == 615L),
  identical(sort(unique(catch$year)), 1900:2022),
  !any(catch$measure == "numbers_at_age"),
  catch$value[catch$region == "East Northland" & catch$year == 1900 & catch$fleet == "LL"] == 138,
  catch$value[catch$region == "East Northland" & catch$year == 1940 & catch$fleet == "LL"] == 488,
  catch$value[catch$region == "Hauraki Gulf" & catch$year == 2022 & catch$fleet == "REC"] == 2332,
  catch$value[catch$region == "Bay of Plenty" & catch$year == 2022 & catch$fleet == "REC"] == 590
)

proportion <- inputs[inputs$measure == "proportion_at_age", ]
composition_cv <- inputs[inputs$measure == "relative_standard_error" &
  grepl("^SNA1_", inputs$observation_id) & !is.na(inputs$age), ]
stopifnot(
  nrow(proportion) == 120L,
  nrow(composition_cv) == 120L,
  all(proportion$year == 2020L),
  all(proportion$season == "spring-winter"),
  all(proportion$basis == "proportion_numbers"),
  all(proportion$source_type == "official_table"),
  setequal(unique(proportion$age), 1:30),
  setequal(paste(proportion$region, proportion$fleet),
    c("Bay of Plenty BT", "Hauraki Gulf DS", "Bay of Plenty DS", "Bay of Plenty MHS")),
  proportion$value[proportion$region == "Bay of Plenty" &
    proportion$fleet == "BT" & proportion$age == 5] == 0.1924,
  composition_cv$value[composition_cv$region == "Bay of Plenty" &
    composition_cv$fleet == "BT" & composition_cv$age == 5] == 0.10,
  proportion$sample_size[proportion$region == "Bay of Plenty" &
    proportion$fleet == "BT" & proportion$age == 5] == 193,
  grepl(">29", proportion$notes[proportion$age == 30][1L], fixed = TRUE)
)
series <- list(
  c("Bay of Plenty", "BT", 1354, 0.9999),
  c("Hauraki Gulf", "DS", 1365, 1.0000),
  c("Bay of Plenty", "DS", 1354, 0.9999),
  c("Bay of Plenty", "MHS", 1354, 1.0001)
)
for (z in series) {
  rows <- proportion[proportion$region == z[1L] & proportion$fleet == z[2L], ]
  stopifnot(nrow(rows) == 30L,
    sum(rows$sample_size, na.rm = TRUE) == as.numeric(z[3L]),
    abs(sum(rows$value) - as.numeric(z[4L])) < 1e-8)
}

tags <- inputs[inputs$measure == "total_numbers" &
  !is.na(inputs$survey) & inputs$survey == "Petersen tag estimate (25-40 cm)", ]
tag_cv <- inputs[inputs$measure == "relative_standard_error" &
  !is.na(inputs$survey) & inputs$survey == "Petersen tag estimate (25-40 cm)", ]
stopifnot(
  nrow(tags) == 5L,
  nrow(tag_cv) == 5L,
  tags$value[tags$region == "East Northland" & tags$year == 1985] == 4443637,
  tags$value[tags$region == "East Northland" & tags$year == 1994] == 4851992,
  tags$value[tags$region == "Hauraki Gulf" & tags$year == 1984] == 29396763,
  tags$value[tags$region == "Hauraki Gulf" & tags$year == 1995] == 31534555,
  tags$value[tags$region == "Bay of Plenty" & tags$year == 1995] == 12284935,
  setequal(unique(tag_cv$value), c(0.2, 0.3)),
  all(tags$length_bin_lower == 25),
  all(tags$length_bin_upper == 40),
  any(tags$source_type == "reconstructed_source_input")
)

natural_mortality <- inputs[inputs$type == "M" &
  inputs$measure == "natural_mortality_at_age", ]
maturity <- inputs[inputs$type == "maturity" &
  inputs$measure == "maturity_at_age", ]
stopifnot(
  nrow(natural_mortality) == 30L,
  all(natural_mortality$value == 0.075),
  setequal(natural_mortality$age, 1:30),
  nrow(maturity) == 30L,
  identical(maturity$value[order(maturity$age)], c(0, 0, 0, 0.5, rep(1, 26L)))
)

stopifnot(
  nrow(assumptions) == 14L,
  grepl("fixed at zero", assumptions$value[assumptions$setting == "selected_base_model"], fixed = TRUE),
  nrow(outputs) == 28L,
  outputs$value[outputs$source_reference == "FAR 2024/47, Table 36." &
    outputs$measure == "unfished_spawning_biomass"] == 55873,
  outputs$value[outputs$source_reference == "FAR 2024/47, Table 37." &
    outputs$measure == "exploitation_rate"] == 0.057,
  outputs$lwr[outputs$source_reference == "FAR 2024/47, Table 37." &
    outputs$measure == "exploitation_rate"] == 0.039,
  outputs$value[outputs$source_reference == "FAR 2024/47, Table 43." &
    outputs$measure == "SSB" & outputs$region == "Hauraki Gulf"] == 143832,
  outputs$value[outputs$source_reference == "FAR 2024/47, Table 45." &
    outputs$measure == "SSB"] == 142878,
  outputs$value[outputs$source_reference == "FAR 2024/47, Table 47." &
    outputs$measure == "SSB"] == 31685,
  all(is.na(outputs$se)),
  !any(outputs$measure %in% c("numbers_at_age", "fishing_mortality_at_age", "natural_mortality_at_age"))
)

review <- paste(readLines("discovery/source_reviews/mpi_snapper_sna1_2023.md",
  warn = FALSE, encoding = "UTF-8"), collapse = " ")
stopifnot(
  grepl("catch-mass histories, not catch numbers-at-age", review, fixed = TRUE),
  grepl("Bay of Plenty 1983 absolute-biomass tagging input", review, fixed = TRUE),
  grepl("Both published table values are retained under separate scenario labels", review, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)

cat("SNA 1 source coverage, units, mapping, provenance, and reported outputs passed.\n")
