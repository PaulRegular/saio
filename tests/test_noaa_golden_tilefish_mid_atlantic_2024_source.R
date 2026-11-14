assessment_id <- "noaa_golden_tilefish_mid_atlantic_2024"
stock_id <- "noaa_golden_tilefish_mid_atlantic"

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

stock <- stocks[!is.na(stocks$stock_id) & stocks$stock_id == stock_id, , drop = FALSE]
assessment <- assessments[!is.na(assessments$assessment_id) &
  assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[!is.na(candidates$candidate_id) &
  candidates$candidate_id == "NOAA:10385", , drop = FALSE]
unit <- inventory[!is.na(inventory$unit_key) &
  inventory$unit_key == paste0("candidate:", stock_id), , drop = FALSE]
outputs_ssb <- outputs[outputs$measure == "SSB", , drop = FALSE]
outputs_f <- outputs[outputs$measure == "fishing_mortality_at_age", , drop = FALSE]
outputs_recruitment <- outputs[outputs$measure == "recruitment", , drop = FALSE]

stopifnot(
  nrow(stock) == 1L,
  stock$authority == "NOAA",
  stock$authority_stock_id == "10385",
  stock$scientific_name == "Lopholatilus chamaeleonticeps",
  stock$area == "Mid-Atlantic Coast",
  stock$ocean == "Northwest Atlantic",
  nrow(assessment) == 1L,
  assessment$assessment_year == 2024L,
  assessment$terminal_year == 2023L,
  assessment$estimate_terminal_year == 2023L,
  assessment$model_family == "WHAM",
  assessment$is_current,
  assessment$is_applied,
  assessment$assumptions_status == "partial",
  assessment$inputs_status == "partial",
  assessment$outputs_status == "partial",
  nrow(assumptions) == 8L,
  assumptions$value[assumptions$setting == "N_at_age_process"] ==
    "IID random effects on N-at-age",
  assumptions$value[assumptions$setting == "fully_selected_age"] == "6",
  nrow(inputs) == 10L,
  all(inputs$type == "catch" & inputs$measure == "catch_biomass"),
  all(inputs$unit == "mt" & inputs$source_type == "official_table"),
  setequal(inputs$year, 2014:2023),
  all(is.na(inputs$age)),
  all(inputs$value[match(2014:2023, inputs$year)] ==
    c(837, 630, 522, 717, 751, 720, 657, 751, 709, 681)),
  all(grepl("1 mt in 2016, 2018 and 2022", inputs$notes, fixed = TRUE)),
  nrow(outputs) == 30L,
  setequal(unique(outputs$measure),
    c("SSB", "fishing_mortality_at_age", "recruitment")),
  setequal(unique(outputs$year), 2014:2023),
  all(is.na(outputs$se) & is.na(outputs$lwr) & is.na(outputs$upr)),
  all(outputs$source_type == "official_table"),
  nrow(outputs[outputs$measure == "fishing_mortality_at_age" &
    outputs$age == 6L, ]) == 10L,
  nrow(outputs[outputs$measure == "recruitment" & outputs$age == 1L, ]) == 10L,
  all(outputs_ssb$value[match(2014:2023, outputs_ssb$year)] ==
    c(4032, 3622, 3418, 2900, 3326, 3869, 4455, 4194, 4106, 4390)),
  all(outputs_f$value[match(2014:2023, outputs_f$year)] ==
    c(0.435, 0.391, 0.308, 0.335, 0.251, 0.212, 0.194, 0.255, 0.253, 0.258)),
  all(outputs_recruitment$value[match(2014:2023,
    outputs_recruitment$year)] ==
    c(2721, 1618, 658, 831, 1645, 892, 1096, 1925, 2792, 1113)),
  outputs$value[outputs$measure == "SSB" & outputs$year == 2023L] == 4390,
  outputs$value[outputs$measure == "fishing_mortality_at_age" &
    outputs$year == 2023L] == 0.258,
  outputs$value[outputs$measure == "recruitment" & outputs$year == 2023L] == 1113,
  nrow(candidate) == 1L,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(unit) == 1L,
  unit$matched_stock_id == stock_id,
  unit$import_status == "partial"
)

cat("NOAA Mid-Atlantic Golden Tilefish 2024 source records passed.\n")
