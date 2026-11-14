read_id_rows <- function(path, id) {
  con <- file(path, open = "r")
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  prefix <- paste0("\"", id, "\",")
  rows <- character()
  repeat {
    lines <- readLines(con, n = 50000L, warn = FALSE)
    if (!length(lines)) break
    rows <- c(rows, lines[startsWith(lines, prefix)])
  }
  read.csv(text = c(header, rows), stringsAsFactors = FALSE,
    na.strings = c("", "NA"), check.names = FALSE)
}

stock_id <- "mpi_gemfish_southern_ski3_ski7"
assessment_id <- "mpi_gemfish_ski3_ski7_2025"
stock <- read_id_rows("database/stocks.csv", stock_id)
assessment <- read_id_rows("database/assessments.csv", assessment_id)
inputs <- read_id_rows("database/inputs.csv", assessment_id)
assumptions <- read_id_rows("database/assumptions.csv", assessment_id)
outputs <- read_id_rows("database/outputs.csv", assessment_id)
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == "MPI:SKI3+SKI7", , drop = FALSE]
manifest <- read.csv("provenance/mpi_gemfish_ski3_ski7_2025_sources.csv",
  stringsAsFactors = FALSE)

catches <- inputs[inputs$type == "catch" & inputs$measure == "total_biomass", ]
survey <- inputs[inputs$measure == "total_biomass", ]
survey <- survey[survey$type == "index", , drop = FALSE]
index_cv <- inputs[inputs$measure == "biomass_index_cv", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$scientific_name == "Rexea solandri",
  stock$authority_stock_id == "SKI 3 + SKI 7",
  stock$ocean == "Southwest Pacific",
  nrow(assessment) == 1L,
  assessment$is_current,
  assessment$assessment_year == 2025L,
  assessment$terminal_year == 2025L,
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(catches) == 102L,
  identical(sort(unique(catches$year)), 1975:2025),
  setequal(unique(catches$region), c("SKI 3", "SKI 7")),
  catches$value[catches$year == 2025L & catches$region == "SKI 3"] == 1414,
  catches$value[catches$year == 2025L & catches$region == "SKI 7"] == 1173,
  nrow(survey) == 29L,
  nrow(index_cv) == 29L,
  all(index_cv$value >= 0 & index_cv$value <= 1),
  any(survey$observation_id == "KAH9504" & survey$value == 21),
  !any(inputs$measure %in% c("proportion_at_age", "frequency_at_age")),
  any(assumptions$setting == "maturity_at_age" &
    grepl("four values for five ages", assumptions$notes, fixed = TRUE)),
  nrow(outputs) == 25L,
  setequal(outputs$scenario, c("Base", "baseH75", "baseH95", "baseM20", "baseM30")),
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  outputs$value[outputs$scenario == "Base" & outputs$measure == "SSB_ratio_to_B0"] == 1.76,
  outputs$value[outputs$scenario == "Base" & outputs$measure == "exploitation_rate_reference_at_SB40"] == 0.18,
  outputs$value[outputs$scenario == "Base" & outputs$measure == "exploitation_rate"] == 0.036,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(manifest) == 4L,
  setequal(basename(manifest$local_file), c(
    "FAR-2026-39-southern-gemfish-SKI3-SKI7.pdf",
    "FAR-2023-22-southern-gemfish-catch-at-age-2020-21.pdf",
    "FAR-2024-01-southern-gemfish-catch-at-age-2021-22.pdf",
    "FAR-2025-05-southern-gemfish-catch-at-age-2022-23.pdf"
  )),
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256))
)

cat("Southern gemfish 2025 source records and provenance passed.\n")
