assessment_id <- "dfo_cod_4t4vn_2024"
cache <- "source_cache/dfo_cod_4t4vn"
database <- "database"
data_file <- "NAFO-4T4VN-Atlantic-Cod-spawning-stock-biomass-estimates-1950-2023.csv"

source <- read.csv(file.path(cache, data_file),
  colClasses = "character",
  na.strings = character(), check.names = FALSE,
  encoding = "UTF-8"
)
outputs <- read.csv(file.path(database, "outputs.csv"),
  colClasses = "character", na.strings = "",
  check.names = FALSE, encoding = "UTF-8"
)
ssb <- outputs[outputs$assessment_id == assessment_id &
  outputs$measure == "SSB", ]
percentiles <- do.call(cbind, unname(lapply(source[2:6], as.numeric)))

stopifnot(
  nrow(ssb) == 74L,
  identical(as.integer(ssb$year), 1950:2023),
  identical(ssb$value, source[[2]]),
  identical(ssb$lwr, source[[3]]),
  identical(ssb$upr, source[[6]]),
  all(ssb$type == "biomass"),
  all(ssb$unit == "kt"),
  all(ssb$source_type == "official_machine_readable"),
  all(percentiles[, 2] <= percentiles[, 3]),
  all(percentiles[, 3] <= percentiles[, 1]),
  all(percentiles[, 1] <= percentiles[, 4]),
  all(percentiles[, 4] <= percentiles[, 5]),
  round(as.numeric(ssb$value[ssb$year == "2023"])) == 12
)

cat("Southern Gulf cod annual SSB output validation passed for 1950-2023.\n")
