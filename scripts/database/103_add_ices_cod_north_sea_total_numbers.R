assessment_id <- "ices_cod_north_sea_2025"
database <- file.path("database")
path <- file.path(database, "outputs.csv")
outputs <- read.csv(path, na.strings = c("", "NA"),
  stringsAsFactors = FALSE, check.names = FALSE
)
if (any(outputs$assessment_id == assessment_id &
    outputs$measure == "total_numbers")) {
  stop("Total abundance is already recorded for this assessment.",
    call. = FALSE
  )
}

population <- outputs[outputs$assessment_id == assessment_id &
  outputs$type == "population" & outputs$measure == "numbers_at_age", ,
  drop = FALSE
]
population$year <- as.integer(population$year)
population$age <- as.integer(population$age)
population$value <- as.numeric(population$value)
stopifnot(
  nrow(population) == 43L * 7L * 3L,
  setequal(population$year, 1983:2025),
  setequal(population$age, 1:7),
  setequal(population$region, c("Northwestern", "Southern", "Viking")),
  all(is.finite(population$value)),
  !anyDuplicated(population[c("year", "age", "region")])
)

totals <- aggregate(value ~ year, population, sum)
output <- data.frame(
  assessment_id = assessment_id,
  type = "population",
  measure = "total_numbers",
  fleet = NA_character_,
  survey = NA_character_,
  sex = NA_character_,
  region = NA_character_,
  season = NA_character_,
  year = totals$year,
  age = NA_integer_,
  age_group = NA_character_,
  value = totals$value,
  se = NA_real_,
  lwr = NA_real_,
  upr = NA_real_,
  unit = "thousand_fish",
  source_type = "derived_source_output",
  source_reference = paste(
    "https://ndownloader.figshare.com/files/67087409;",
    "Selectivity Indicators/FLStocks.RData; cod.27.46a7d20;",
    "Northwestern, Southern and Viking; stock.n"
  ),
  notes = paste(
    "Derived by summing official stock.n over ages 1-7+ and all three substocks.",
    "Age 7 is the plus group; uncertainty is not combined."
  ),
  stringsAsFactors = FALSE
)
stopifnot(identical(as.integer(output$year), 1983:2025))
write.table(output, path, sep = ",", quote = TRUE, row.names = FALSE,
  col.names = FALSE, append = TRUE, na = ""
)
