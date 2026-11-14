read_table <- function(name) read.csv(file.path("database", name),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
read_assessment_rows <- function(name, id) {
  path <- file.path("database", name)
  con <- file(path, open = "r")
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  rows <- character()
  prefix <- paste0('"', id, '"')
  repeat {
    chunk <- readLines(con, n = 25000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

assessment_id <- "mpi_hoki_hok1_2025"
stocks <- read_table("stocks.csv")
assessments <- read_table("assessments.csv")
assumptions <- read_assessment_rows("assumptions.csv", assessment_id)
inputs <- read_assessment_rows("inputs.csv", assessment_id)
outputs <- read_assessment_rows("outputs.csv", assessment_id)
candidates <- read.csv(file.path("discovery", "candidates.csv"), stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)

stock <- stocks[stocks$stock_id == "mpi_hoki_hok1", , drop = FALSE]
assessment <- assessments[assessments$assessment_id == assessment_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == "MPI:HOK1", , drop = FALSE]
stopifnot(nrow(stock) == 1L, stock$ocean == "Southwest Pacific",
  stock$authority_stock_id == "HOK 1", nrow(assessment) == 1L,
  assessment$assessment_year == 2025L, assessment$terminal_year == 2024L,
  assessment$estimate_terminal_year == 2025L,
  assessment$inputs_status == "partial", assessment$outputs_status == "partial",
  candidate$matched_stock_id == "mpi_hoki_hok1", candidate$import_status == "partial")

catch <- inputs[inputs$type == "catch" & inputs$measure == "total_biomass", ]
composition <- inputs[inputs$measure == "proportion_at_age", ]
index <- inputs[inputs$type == "index" & inputs$measure == "total_biomass", ]
index_cv <- inputs[inputs$measure == "biomass_index_cv", ]
stopifnot(nrow(catch) == 540L, length(unique(catch$fleet)) == 10L,
  min(as.integer(catch$year)) == 1972L, max(as.integer(catch$year)) == 2025L,
  all(catch$unit == "tonnes"),
  catch$value[catch$fleet == "Chatham Rise deep trawl" & catch$year == 1972] == 3500,
  catch$value[catch$fleet == "Chatham Rise shallow trawl" & catch$year == 1972] == 500)
for (fleet in unique(catch$fleet)) {
  pair <- catch[catch$fleet == fleet & catch$year %in% 2024:2025, ]
  stopifnot(nrow(pair) == 2L, pair$value[pair$year == 2024] == pair$value[pair$year == 2025])
}
stopifnot(nrow(composition) == 9618L,
  length(unique(composition$observation_id)) == 293L,
  length(unique(sub("_[0-9]+$", "", composition$observation_id))) == 16L,
  identical(sort(unique(composition$sex)), c("F", "M")),
  identical(sort(unique(as.numeric(composition$age))), as.numeric(1:18)),
  all(composition$basis == "proportion_numbers"),
  all(composition$unit == "proportion"),
  all(as.numeric(composition$sample_size) > 0))
composition_sums <- tapply(as.numeric(composition$value), composition$observation_id, sum)
composition_sizes <- tapply(as.numeric(composition$sample_size), composition$observation_id,
  function(x) length(unique(x)))
stopifnot(length(composition_sums) == 293L, max(abs(composition_sums - 1)) < 1e-4,
  all(composition_sizes == 1L),
  all(grepl("not catch numbers-at-age", composition$notes, fixed = TRUE)))

stopifnot(nrow(index) == 95L, nrow(index_cv) == 95L,
  length(unique(index$survey)) == 6L, all(index$unit == "tonnes"),
  all(index_cv$basis == "relative_scale"), all(index_cv$unit == "ratio"))
index_key <- function(x) paste(x$survey, x$region, x$season, x$year, sep = "|")
stopifnot(setequal(index_key(index), index_key(index_cv)),
  all(is.finite(as.numeric(index_cv$value))),
  index$value[index$survey == "Cook Strait acoustic spawning survey" & index$year == 1991] == 88247.565,
  index_cv$value[index_cv$survey == "Cook Strait acoustic spawning survey" & index_cv$year == 1991] == .41)

assumption_keys <- c("assessment_id", "component", "fleet", "survey", "sex", "region", "season", "setting")
assumption_key <- do.call(paste, c(lapply(assumptions[assumption_keys], function(x) ifelse(is.na(x), "", x)), sep = "\r"))
stopifnot(nrow(assumptions) == 340L, !anyDuplicated(assumption_key),
  any(assumptions$setting == "ChathamRiseSummerBiomass:likelihood"))

b0 <- outputs[outputs$measure == "unfished_spawning_biomass", ]
ssb <- outputs[outputs$measure == "SSB", ]
fixed_m <- assumptions[assumptions$setting == "fixed_instantaneous_M_by_category", ]
category_order <- assumptions[assumptions$setting == "base_model_category_order", ]
category_map <- assumptions[assumptions$setting == "category_age_length_mapping", ]
assumption_value <- function(setting, region, sex) {
  same_value <- function(x, value) {
    if (identical(value, "")) is.na(x) | x == "" else !is.na(x) & x == value
  }
  rows <- assumptions[!is.na(assumptions$setting) & assumptions$setting == setting &
    same_value(assumptions$region, region) & same_value(assumptions$sex, sex), , drop = FALSE]
  stopifnot(nrow(rows) == 1L)
  rows$value
}
stopifnot(nrow(outputs) == 6L, nrow(b0) == 3L, nrow(ssb) == 3L,
  b0$value[b0$region == "East"] == 727, b0$lwr[b0$region == "East"] == 676,
  ssb$value[ssb$region == "Total"] == 855, ssb$year[ssb$region == "Total"] == 2025,
  ssb$season[ssb$region == "Total"] == "mid-season",
  all(is.na(outputs$se)), nrow(fixed_m) == 1L,
  nrow(category_order) == 1L, nrow(category_map) == 1L,
  length(strsplit(fixed_m$value, "\\s+")[[1L]]) == 16L,
  length(strsplit(category_order$value, "\\s+")[[1L]]) == 16L,
  length(strsplit(category_map$value, "; ")[[1L]]) == 16L,
  assumption_value("AgeLengthEastM:k", "East", "M") == "0.232",
  assumption_value("AgeLengthEastF:Linf", "East", "F") == "101.8",
  assumption_value("AgeLengthWestM:k", "West", "M") == "0.261",
  assumption_value("AgeLengthWestF:Linf", "West", "F") == "104.0",
  assumption_value("LengthWeightEastM:a", "East", "M") == "4.79e-09",
  assumption_value("LengthWeightWestF:b", "West", "F") == "2.89",
  assumption_value("SelectivityEastMaturationM:a50", "East", "M") == "2.0",
  assumption_value("SelectivityWestMaturationF:ato95", "West", "F") == "3.0",
  assumption_value("EastMaturation:from", "East", "") == "East.ChathamRise.Immature.M East.ChathamRise.Immature.F",
  any(assumptions$setting == "WestMaturation:type" & assumptions$value == "transition_category"),
  !any(inputs$type == "catch" & inputs$measure == "numbers_at_age"),
  !any(inputs$measure %in% c("weight_at_age", "maturity_at_age")))

cat("HOK 1 2025 source inputs, assumptions, outputs, units, and partial status passed.\n")



