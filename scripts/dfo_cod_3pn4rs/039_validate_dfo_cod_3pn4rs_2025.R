assessment_id <- "dfo_cod_3pn4rs_2025"
root <- "."
source_file <- file.path(root, "source_cache", assessment_id, "assessment.txt")
lines <- readLines(source_file, warn = FALSE)

read_table <- function(number, next_number, value_count) {
  start <- grep(paste0("^Table ", number, "\\."), trimws(lines))[[1]]
  end <- grep(paste0("^Table ", next_number, "\\."), trimws(lines))
  end <- end[end > start][[1]]
  rows <- lines[seq.int(start + 1L, end - 1L)]
  rows <- rows[grepl("^[[:space:]]*(19|20)[0-9]{2}[[:space:]]+", rows)]
  values <- strsplit(gsub(",", "", trimws(rows)), "[[:space:]]+")
  if (!length(values) || any(lengths(values) != value_count + 1L)) {
    stop("Unexpected source row structure in Table ", number, ".")
  }
  values <- unlist(values)
  values[values == "-"] <- NA_character_
  matrix(as.numeric(values), ncol = value_count + 1L, byrow = TRUE)
}

tables <- list(
  catch_weight = read_table(24, 25, 10),
  sentinel = read_table(28, 29, 11),
  catch = read_table(30, 31, 10),
  biomass = read_table(32, 33, 12),
  abundance = read_table(33, 34, 12),
  fishing_mortality = read_table(35, 36, 12),
  natural_mortality = read_table(36, 37, 10)
)
database <- file.path(root, "database")
inputs <- read.csv(file.path(database, "inputs.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
outputs <- read.csv(file.path(database, "outputs.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
inputs <- inputs[inputs$assessment_id == assessment_id, , drop = FALSE]
outputs <- outputs[outputs$assessment_id == assessment_id, , drop = FALSE]

same_values <- function(actual, expected) {
  isTRUE(all.equal(as.numeric(actual), as.numeric(expected), tolerance = 0))
}

check_age_surface <- function(measure, source, columns) {
  actual <- outputs[outputs$measure == measure & !is.na(outputs$age), , drop = FALSE]
  actual <- actual[order(actual$year, actual$age), , drop = FALSE]
  expected <- as.vector(t(source[, columns, drop = FALSE]))
  nrow(actual) == length(expected) && same_values(actual$value, expected)
}

check_annual <- function(measure, source, column, age_group = "") {
  actual <- outputs[outputs$measure == measure & outputs$age_group == age_group, ,
    drop = FALSE
  ]
  actual <- actual[order(actual$year), , drop = FALSE]
  nrow(actual) == nrow(source) &&
    same_values(actual$value, source[, column])
}

catch <- inputs[inputs$type == "catch", , drop = FALSE]
catch <- catch[order(catch$year, catch$age), , drop = FALSE]
weights <- inputs[inputs$type == "catch_weight", , drop = FALSE]
weights <- weights[order(weights$year, weights$age), , drop = FALSE]
stock_weights <- inputs[inputs$type == "weight", , drop = FALSE]
stock_weights <- stock_weights[order(stock_weights$year, stock_weights$age), , drop = FALSE]
maturity <- inputs[inputs$type == "maturity", , drop = FALSE]
maturity <- maturity[order(maturity$year, maturity$age), , drop = FALSE]
weight_values <- as.vector(t(tables$catch_weight[, -1, drop = FALSE]))
index <- inputs[inputs$type == "index", , drop = FALSE]
index <- index[order(index$year, index$age), , drop = FALSE]
fixed_m <- inputs[inputs$type == "M", , drop = FALSE]
baseline_m <- fixed_m[fixed_m$source_type == "official_document", , drop = FALSE]
m_estimated <- outputs[outputs$measure == "natural_mortality_at_age", , drop = FALSE]
m_source <- tables$natural_mortality[tables$natural_mortality[, 1] >= 1984,
  c(1, 4:11),
  drop = FALSE
]
m_estimated <- m_estimated[order(m_estimated$year, m_estimated$age), , drop = FALSE]

stopifnot(
  all(tables$catch_weight[, 1] == 1974:2024),
  sum(is.na(weight_values)) == 7L,
  nrow(weights) == 503L,
  same_values(weights$value, weight_values[!is.na(weight_values)]),
  all(weights$unit == "kg"),
  nrow(stock_weights) == 400L,
  setequal(stock_weights$year, 1985:2024),
  setequal(stock_weights$age, 2:11),
  same_values(stock_weights$value[stock_weights$year == 1985 & stock_weights$age == 2], 0.076),
  same_values(stock_weights$value[stock_weights$year == 2024 & stock_weights$age == 2], 0.063),
  all(stock_weights$source_type == "digitized"),
  all(stock_weights$source_reference == "DFO Research Document 2026/010 Figure 90"),
  all(stock_weights$unit == "kg"),
  nrow(maturity) == 672L,
  setequal(maturity$year, 1983:2024),
  setequal(maturity$age, 0:15),
  same_values(maturity$value[maturity$year == 1983 & maturity$age == 5], 0.352),
  all(maturity$value >= 0 & maturity$value <= 1),
  all(vapply(split(maturity, maturity$year), function(x) {
    all(diff(x$value[order(x$age)]) >= 0)
  }, logical(1))),
  all(maturity$source_type == "digitized"),
  all(maturity$source_reference == "DFO Research Document 2026/010 Figure 70"),
  all(tables$sentinel[, 1] == 1995:2024),
  nrow(index) == 330L,
  same_values(index$value, as.vector(t(tables$sentinel[, -1, drop = FALSE]))),
  all(index$survey == "Sentinel mobile"),
  all(index$unit == "mean numbers per tow"),
  all(index$sampling_time == 0.54),
  all(tables$catch[, 1] == 1974:2024),
  all(tables$biomass[, 1] == 1973:2024),
  all(tables$abundance[, 1] == 1973:2024),
  all(tables$fishing_mortality[, 1] == 1973:2024),
  all(tables$natural_mortality[, 1] == 1973:2024),
  nrow(catch) == 510L,
  same_values(catch$value, as.vector(t(tables$catch[, 2:11, drop = FALSE]))),
  nrow(fixed_m) == 520L,
  all(fixed_m$value[fixed_m$age == 2] == 1),
  all(fixed_m$value[fixed_m$age == 3] == 0.65),
  nrow(baseline_m) == 41L * 8L,
  all(baseline_m$year %in% 1984:2024),
  all(baseline_m$value[baseline_m$age == 4] == 0.45),
  all(baseline_m$value[baseline_m$age >= 5] == 0.15),
  all(baseline_m$source_reference == "DFO Research Document 2025/074, pp. 4-5"),
  nrow(m_estimated) == 328L,
  same_values(m_estimated$value, as.vector(t(m_source[, -1, drop = FALSE]))),
  check_age_surface("numbers_at_age", tables$abundance, 2:11),
  check_age_surface("biomass_at_age", tables$biomass, 2:11),
  check_age_surface("fishing_mortality_at_age", tables$fishing_mortality, 2:11),
  check_annual("SSB", tables$biomass, 13),
  check_annual("total_biomass", tables$biomass, 12, "2+"),
  check_annual("total_numbers", tables$abundance, 12, "2+"),
  check_annual("total_numbers", tables$abundance, 13, "5+"),
  check_annual("recruitment", tables$abundance, 2),
  check_annual("Fbar", tables$fishing_mortality, 12, "4-6"),
  check_annual("Fbar", tables$fishing_mortality, 13, "6-9")
)

cat("3Pn4RS source-table validation passed.\n")
