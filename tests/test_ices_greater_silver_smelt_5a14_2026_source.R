assessment_id <- "ices_greater_silver_smelt_5a14_2026"
stock_id <- "ices_greater_silver_smelt_5a14"

read_assessment_rows <- function(table) {
  path <- file.path("database", paste0(table, ".csv"))
  header <- readLines(path, n = 1L, warn = FALSE)
  rg <- Sys.which("rg")
  if (!nzchar(rg)) stop("rg is required to read focused assessment rows.")
  rows_path <- tempfile(fileext = ".csv")
  on.exit(unlink(rows_path), add = TRUE)
  status <- suppressWarnings(system2(rg,
    c("--color", "never", "--no-heading", "--no-line-number", "-F",
      assessment_id, path), stdout = rows_path, stderr = FALSE))
  if (!is.null(status) && status == 1L) return(data.frame())
  if (!is.null(status) && status != 0L) stop("Could not scan ", path)
  rows <- readLines(rows_path, warn = FALSE)
  rows <- rows[startsWith(rows, paste0('"', assessment_id, '",'))]
  if (!length(rows)) return(data.frame())
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assumptions <- read_assessment_rows("assumptions")
inputs <- read_assessment_rows("inputs")
outputs <- read_assessment_rows("outputs")
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[!is.na(candidates$candidate_unit_id) &
  candidates$candidate_unit_id == stock_id, , drop = FALSE]
unit <- inventory[!is.na(inventory$unit_key) &
  inventory$unit_key == paste0("candidate:", stock_id), , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "ICES",
  stock$authority_stock_id == "aru.27.5a14",
  stock$scientific_name == "Argentina silus",
  stock$ocean == "Northeast Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2026L,
  assessment$terminal_year == 2025L,
  assessment$estimate_terminal_year == 2025L,
  assessment$model_family == "SAM",
  assessment$framework_year == 2025L,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 7L,
  assumptions$value[assumptions$setting == "natural_mortality"] ==
    "0.1 per year, fixed for all ages.",
  nrow(inputs) == 26L,
  all(inputs$type == "catch" & inputs$measure == "catch_biomass"),
  all(inputs$unit == "tonnes" & inputs$source_type == "official_table"),
  setequal(inputs$year, 2000:2025),
  all(is.na(inputs$age)),
  inputs$value[inputs$year == 2015L] == 6068,
  inputs$value[inputs$year == 2019L] == 3211,
  inputs$value[inputs$year == 2020L] == 3780,
  inputs$value[inputs$year == 2025L] == 9109,
  all(grepl("MFRI", inputs$notes, fixed = TRUE)),
  nrow(outputs) == 104L,
  setequal(unique(outputs$measure), c("recruitment", "total_biomass", "SSB", "Fbar")),
  setequal(unique(outputs$year), 2000:2025),
  !any(outputs$year == 2026L),
  all(is.na(outputs$se)),
  all(!is.na(outputs$lwr) & !is.na(outputs$upr)),
  all(outputs$lwr <= outputs$value & outputs$value <= outputs$upr),
  all(outputs$source_type == "official_table"),
  nrow(outputs[outputs$measure == "recruitment" & outputs$age == 5L, ]) == 26L,
  nrow(outputs[outputs$measure == "Fbar" & outputs$age_group == "6-14" &
    is.na(outputs$age), ]) == 26L,
  outputs$value[outputs$measure == "recruitment" & outputs$year == 2025L] == 40959,
  outputs$lwr[outputs$measure == "recruitment" & outputs$year == 2025L] == 29847,
  outputs$upr[outputs$measure == "recruitment" & outputs$year == 2025L] == 56207,
  outputs$value[outputs$measure == "total_biomass" & outputs$year == 2025L] == 115982,
  outputs$value[outputs$measure == "SSB" & outputs$year == 2025L] == 76868,
  outputs$value[outputs$measure == "Fbar" & outputs$year == 2025L] == 0.092,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial"
)

cat("ICES greater silver smelt 2026 source records passed.\n")
